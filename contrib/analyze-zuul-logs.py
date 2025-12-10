#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "anthropic>=0.40.0",
#     "httpx>=0.27.0",
# ]
# ///
"""
OSISM Testbed Log Analyzer

This script analyzes logs from OSISM Testbed runs using Claude
and identifies errors, warnings, and unexpected states.

Usage:
    # With uv (recommended):
    uv run contrib/analyze-zuul-logs.py <log-url-or-file>

    # Or directly with Python (after installing dependencies):
    python analyze-zuul-logs.py <log-url-or-file>

Examples:
    uv run contrib/analyze-zuul-logs.py https://logs.services.osism.tech/.../job-output.txt
    uv run contrib/analyze-zuul-logs.py /path/to/local/logfile.txt
    uv run contrib/analyze-zuul-logs.py --output report.md <log-url>

Requirements:
    - ANTHROPIC_API_KEY environment variable OR claude CLI installed
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Optional
from urllib.parse import urlparse

try:
    import anthropic

    HAS_ANTHROPIC = True
except ImportError:
    HAS_ANTHROPIC = False

import httpx


# Known false positives - tasks that are expected to fail during initial deployment
# These are filtered out from the failed_tasks list before analysis
# Format: List of regex patterns that match task names or error messages
KNOWN_FALSE_POSITIVES = [
    # Service checks that fail before services are deployed (these have "...ignoring" after them)
    r"TASK \[Check RabbitMQ service\].*?fatal:.*?\.\.\.ignoring",
    r"TASK \[Check MariaDB service\].*?fatal:.*?\.\.\.ignoring",
    r"TASK \[.*?Check MariaDB service port liveness\].*?fatal:.*?\.\.\.ignoring",
    # Generic pattern for any task that fails but is ignored
    r"fatal:.*?FAILED!.*?\n.*?\.\.\.ignoring",
]

# Compile patterns for efficiency
KNOWN_FALSE_POSITIVE_PATTERNS = [
    re.compile(pattern, re.DOTALL | re.IGNORECASE) for pattern in KNOWN_FALSE_POSITIVES
]


def is_false_positive(context: str) -> bool:
    """Check if a failed task context matches a known false positive pattern."""
    for pattern in KNOWN_FALSE_POSITIVE_PATTERNS:
        if pattern.search(context):
            return True
    return False


class Severity(Enum):
    """Severity level of a detected issue."""

    CRITICAL = "critical"
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"


@dataclass
class LogIssue:
    """Represents a detected issue in the log."""

    severity: Severity
    category: str
    message: str
    context: str
    line_number: Optional[int] = None
    suggestion: Optional[str] = None


@dataclass
class AnalysisResult:
    """Result of the log analysis."""

    success: bool
    summary: str
    issues: list[LogIssue] = field(default_factory=list)
    ansible_recap: Optional[dict] = None
    failed_tasks: list[str] = field(default_factory=list)
    failed_tasks_context: list[str] = field(default_factory=list)
    ignored_tasks_context: list[str] = field(default_factory=list)
    tempest_failures_context: list[str] = field(default_factory=list)
    python_tracebacks_context: list[str] = field(default_factory=list)
    raw_analysis: str = ""


class LogFetcher:
    """Fetches logs from URLs or local files."""

    @staticmethod
    def fetch(source: str) -> str:
        """Fetches log content from URL or file."""
        parsed = urlparse(source)

        if parsed.scheme in ("http", "https"):
            return LogFetcher._fetch_url(source)
        else:
            return LogFetcher._fetch_file(source)

    @staticmethod
    def _fetch_url(url: str) -> str:
        """Fetches log from URL."""
        try:
            with httpx.Client(timeout=60.0, follow_redirects=True) as client:
                response = client.get(url)
                response.raise_for_status()
                return response.text
        except httpx.HTTPError as e:
            raise RuntimeError(f"Error fetching URL: {e}")

    @staticmethod
    def _fetch_file(path: str) -> str:
        """Fetches log from local file."""
        file_path = Path(path)
        if not file_path.exists():
            raise FileNotFoundError(f"File not found: {path}")
        return file_path.read_text(encoding="utf-8", errors="replace")


class LogPreprocessor:
    """Preprocessing and extraction of relevant log sections."""

    # ANSI Escape Code Pattern for removing colors
    ANSI_ESCAPE_PATTERN = re.compile(r"\x1b\[[0-9;]*m")

    # Zuul Timestamp Pattern (e.g., "2025-12-10 00:00:06.994484 | ")
    ZUUL_TIMESTAMP_PATTERN = re.compile(
        r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+ \| (?:[\w-]+ \| )?"
    )

    # Patterns for various log types
    ANSIBLE_TASK_PATTERN = re.compile(r"TASK \[([^\]]+)\]", re.MULTILINE)
    ANSIBLE_PLAY_PATTERN = re.compile(r"PLAY \[([^\]]+)\]", re.MULTILINE)
    # Zuul format: "PLAY RECAP" followed by host statistics
    # Matches both "PLAY RECAP" and "PLAY RECAP *****"
    ANSIBLE_RECAP_PATTERN = re.compile(
        r"PLAY RECAP[\s\*]*\n((?:.*?(?:ok[=:]|changed[=:]|failed[=:]|unreachable[=:]).*?\n)+)",
        re.MULTILINE,
    )
    ANSIBLE_FAILED_PATTERN = re.compile(
        r"(?:fatal|failed):\s*\[([^\]]+)\]", re.MULTILINE | re.IGNORECASE
    )
    # More specific error patterns (avoids false positives like "failed=0")
    ERROR_PATTERN = re.compile(
        r"^.*(?:(?<![=])error(?![=])|exception|traceback|fatal:).*$",
        re.MULTILINE | re.IGNORECASE,
    )
    WARNING_PATTERN = re.compile(
        r"^.*(?:\[WARNING\]|\[warn\]|DEPRECATION WARNING).*$",
        re.MULTILINE | re.IGNORECASE,
    )
    CONTAINER_ERROR_PATTERN = re.compile(
        r"(?:docker|podman|container).*(?:error|failed|exited\s+with)", re.IGNORECASE
    )
    SERVICE_FAILED_PATTERN = re.compile(
        r"(?:systemctl|service).*(?:failed|inactive \(dead\))", re.IGNORECASE
    )
    # Tempest Test Failures
    TEMPEST_FAILURE_PATTERN = re.compile(
        r"(?:FAILED|ERROR).*tempest\.|setUpClass.*Error", re.IGNORECASE
    )
    # Ceph Health Warnings/Errors
    CEPH_HEALTH_PATTERN = re.compile(
        r"HEALTH_(?:WARN|ERR)|ceph.*(?:error|warning|failed)", re.IGNORECASE
    )
    # Python Tracebacks (critical errors from Python tools like openstack-image-manager)
    PYTHON_TRACEBACK_PATTERN = re.compile(
        r"Traceback \(most recent call last\)", re.IGNORECASE
    )

    def __init__(self, log_content: str):
        # Remove ANSI color codes for better pattern matching
        self.log_content = self.ANSI_ESCAPE_PATTERN.sub("", log_content)
        self.lines = self.log_content.splitlines()

    def _clean_line(self, line: str) -> str:
        """Removes Zuul timestamps and ANSI codes from a line."""
        line = self.ANSI_ESCAPE_PATTERN.sub("", line)
        line = self.ZUUL_TIMESTAMP_PATTERN.sub("", line)
        return line.strip()

    def extract_summary_sections(self) -> dict:
        """Extracts important sections for the summary."""
        sections = {
            "ansible_recaps": [],
            "failed_tasks": [],
            "ignored_tasks": [],  # Tasks that failed but were ignored (false positives)
            "errors": [],
            "warnings": [],
            "container_issues": [],
            "service_issues": [],
            "tempest_failures": [],
            "ceph_issues": [],
            "python_tracebacks": [],  # Python tracebacks from tools
        }

        # Find Ansible PLAY RECAPs
        for match in self.ANSIBLE_RECAP_PATTERN.finditer(self.log_content):
            recap_text = match.group(0)
            sections["ansible_recaps"].append(recap_text)

        # Find failed tasks
        for match in self.ANSIBLE_FAILED_PATTERN.finditer(self.log_content):
            # Extract context around the error
            start = max(0, match.start() - 500)
            end = min(len(self.log_content), match.end() + 1000)
            context = self.log_content[start:end]

            # Check if this is a known false positive (ignored task)
            if is_false_positive(context):
                sections["ignored_tasks"].append(context)
            else:
                sections["failed_tasks"].append(context)

        # General errors (limited to most important)
        error_matches = list(self.ERROR_PATTERN.finditer(self.log_content))
        for match in error_matches[:50]:  # Max 50 errors
            line = match.group(0).strip()
            if len(line) < 500:  # Ignore overly long lines
                sections["errors"].append(line)

        # Warnings (limited)
        warning_matches = list(self.WARNING_PATTERN.finditer(self.log_content))
        for match in warning_matches[:30]:  # Max 30 warnings
            line = match.group(0).strip()
            if len(line) < 500:
                sections["warnings"].append(line)

        # Container issues
        for match in self.CONTAINER_ERROR_PATTERN.finditer(self.log_content):
            start = max(0, match.start() - 200)
            end = min(len(self.log_content), match.end() + 200)
            sections["container_issues"].append(self.log_content[start:end].strip())

        # Service issues
        for match in self.SERVICE_FAILED_PATTERN.finditer(self.log_content):
            start = max(0, match.start() - 200)
            end = min(len(self.log_content), match.end() + 200)
            sections["service_issues"].append(self.log_content[start:end].strip())

        # Tempest test failures
        for match in self.TEMPEST_FAILURE_PATTERN.finditer(self.log_content):
            start = max(0, match.start() - 300)
            end = min(len(self.log_content), match.end() + 500)
            sections["tempest_failures"].append(self.log_content[start:end].strip())

        # Ceph health issues
        for match in self.CEPH_HEALTH_PATTERN.finditer(self.log_content):
            start = max(0, match.start() - 200)
            end = min(len(self.log_content), match.end() + 300)
            sections["ceph_issues"].append(self.log_content[start:end].strip())

        # Python tracebacks (capture more context - tracebacks can be long)
        for match in self.PYTHON_TRACEBACK_PATTERN.finditer(self.log_content):
            start = max(0, match.start() - 500)
            end = min(len(self.log_content), match.end() + 4000)
            sections["python_tracebacks"].append(self.log_content[start:end].strip())

        return sections

    def get_log_chunks(self, chunk_size: int = 100000) -> list[str]:
        """Splits the log into chunks for analysis."""
        chunks = []
        current_chunk = []
        current_size = 0

        for line in self.lines:
            line_size = len(line) + 1
            if current_size + line_size > chunk_size and current_chunk:
                chunks.append("\n".join(current_chunk))
                current_chunk = []
                current_size = 0
            current_chunk.append(line)
            current_size += line_size

        if current_chunk:
            chunks.append("\n".join(current_chunk))

        return chunks

    def extract_final_status(self) -> str:
        """Extracts the final status of the testbed run."""
        # Search for the last PLAY RECAP
        recaps = list(self.ANSIBLE_RECAP_PATTERN.finditer(self.log_content))
        if recaps:
            return recaps[-1].group(0)

        # Search for Zuul job status
        if "Job succeeded" in self.log_content:
            return "Job succeeded"
        elif "Job failed" in self.log_content:
            return "Job failed"

        return "Status unknown"


class BaseAnalyzer:
    """Base class for log analyzers."""

    SYSTEM_PROMPT = """You are an expert analyzing OSISM Testbed logs. Be concise.

OSISM Testbed deploys OpenStack with Ceph storage via Ansible/Kolla containers.
Logs are from Zuul CI/CD. PLAY RECAPs show: ok, changed, failed, unreachable counts.

Output format (skip empty sections):

## Summary
- Key findings as bullet points (max 3)
- Do NOT include status here (it is shown separately)

## Critical Errors
- Bullet list only, no explanations unless essential

## Warnings
- Bullet list of important warnings only

## Failed Tasks
- Task name: error (one line each)
- ONLY include tasks that actually failed (failed>0 in RECAP)

## Tempest Failures
- Test name: reason (one line each)

Rules:
- No tables, no lengthy explanations
- Skip sections with no issues
- Be terse: prefer "MariaDB timeout on node-0" over full sentences
- Ignore deprecation warnings unless critical
- Do NOT include context logs - they will be appended separately
- Tasks with "...ignoring" are expected and MUST be completely ignored everywhere
- Service checks (RabbitMQ/MariaDB) that timeout before deployment are expected - NEVER mention them
- Summary MUST only contain actual unexpected problems, never expected behavior
- Do NOT include recommendations
- Do NOT use markdown formatting like **bold** or *italic* - plain text only"""

    def _build_analysis_prompt(self, preprocessed: dict) -> str:
        """Creates the analysis prompt."""
        prompt_parts = [
            "Analyze the following OSISM Testbed log for errors and unexpected states.\n\n"
        ]

        # Add Ansible RECAPs (most important information)
        if preprocessed.get("ansible_recaps"):
            prompt_parts.append("=== ANSIBLE PLAY RECAPS ===\n")
            for recap in preprocessed["ansible_recaps"][-5:]:  # Last 5 RECAPs
                prompt_parts.append(recap + "\n\n")

        # Failed tasks (real failures, not ignored ones)
        if preprocessed.get("failed_tasks"):
            prompt_parts.append("\n=== FAILED TASKS ===\n")
            for task in preprocessed["failed_tasks"][:10]:  # Max 10 tasks
                prompt_parts.append(task + "\n---\n")

        # Note about ignored tasks (false positives)
        ignored_count = len(preprocessed.get("ignored_tasks", []))
        if ignored_count > 0:
            prompt_parts.append("\n=== NOTE: IGNORED TASKS ===\n")
            prompt_parts.append(
                f"{ignored_count} task(s) failed but were intentionally ignored.\n"
            )
            prompt_parts.append(
                "These are expected failures during initial deployment "
            )
            prompt_parts.append(
                "(e.g., service checks before services are deployed).\n"
            )
            prompt_parts.append(
                "They are NOT real errors and should not be reported as issues.\n\n"
            )

        # Error lines
        if preprocessed.get("errors"):
            prompt_parts.append("\n=== ERROR LINES ===\n")
            # Deduplicate and limit
            unique_errors = list(dict.fromkeys(preprocessed["errors"]))[:30]
            for error in unique_errors:
                prompt_parts.append(f"- {error}\n")

        # Container issues
        if preprocessed.get("container_issues"):
            prompt_parts.append("\n=== CONTAINER ISSUES ===\n")
            unique_issues = list(dict.fromkeys(preprocessed["container_issues"]))[:10]
            for issue in unique_issues:
                prompt_parts.append(issue + "\n---\n")

        # Service issues
        if preprocessed.get("service_issues"):
            prompt_parts.append("\n=== SERVICE ISSUES ===\n")
            unique_issues = list(dict.fromkeys(preprocessed["service_issues"]))[:10]
            for issue in unique_issues:
                prompt_parts.append(issue + "\n---\n")

        # Tempest test failures
        if preprocessed.get("tempest_failures"):
            prompt_parts.append("\n=== TEMPEST TEST FAILURES ===\n")
            unique_failures = list(dict.fromkeys(preprocessed["tempest_failures"]))[:10]
            for failure in unique_failures:
                prompt_parts.append(failure + "\n---\n")

        # Ceph issues
        if preprocessed.get("ceph_issues"):
            prompt_parts.append("\n=== CEPH ISSUES ===\n")
            unique_issues = list(dict.fromkeys(preprocessed["ceph_issues"]))[:10]
            for issue in unique_issues:
                prompt_parts.append(issue + "\n---\n")

        # Python tracebacks (critical errors from tools)
        if preprocessed.get("python_tracebacks"):
            prompt_parts.append("\n=== PYTHON TRACEBACKS ===\n")
            unique_tracebacks = list(dict.fromkeys(preprocessed["python_tracebacks"]))[
                :5
            ]
            for tb in unique_tracebacks:
                # Truncate very long tracebacks for the prompt
                if len(tb) > 3000:
                    tb = tb[:3000] + "\n[...truncated...]"
                prompt_parts.append(tb + "\n---\n")

        # Warnings (if space allows)
        if preprocessed.get("warnings"):
            prompt_parts.append("\n=== WARNINGS (Selection) ===\n")
            unique_warnings = list(dict.fromkeys(preprocessed["warnings"]))[:15]
            for warning in unique_warnings:
                prompt_parts.append(f"- {warning}\n")

        return "".join(prompt_parts)

    def _parse_analysis(self, raw_analysis: str, preprocessed: dict) -> AnalysisResult:
        """Parses the Claude analysis into structured format."""
        issues = []

        # Try to extract sections
        sections = {
            "critical": self._extract_section(raw_analysis, "Critical Errors"),
            "warnings": self._extract_section(raw_analysis, "Warnings"),
            "failed_tasks": self._extract_section(raw_analysis, "Failed"),
            "recommendations": self._extract_section(raw_analysis, "Recommendations"),
        }

        # Critical errors as issues
        if sections["critical"]:
            for line in sections["critical"].split("\n"):
                if line.strip() and line.strip().startswith("-"):
                    issues.append(
                        LogIssue(
                            severity=Severity.CRITICAL,
                            category="Ansible/Deployment",
                            message=line.strip("- ").strip(),
                            context="",
                        )
                    )

        # Determine success based on RECAPs - check ALL recaps for any failures
        success = True
        ansible_recap = {}
        if preprocessed.get("ansible_recaps"):
            for recap in preprocessed["ansible_recaps"]:
                # Handle both formats: "failed=1" and "failed: 1"
                failed_match = re.search(r"failed[=:]\s*(\d+)", recap)
                if failed_match and int(failed_match.group(1)) > 0:
                    success = False
                    break
            ansible_recap["raw"] = preprocessed["ansible_recaps"][-1]

        # Extract summary
        summary = self._extract_section(raw_analysis, "Summary")
        if not summary:
            summary = (
                raw_analysis.split("\n")[0] if raw_analysis else "Analysis completed"
            )

        # Deduplicate context logs by extracting key identifiers
        def dedupe_by_task_name(contexts: list[str]) -> list[str]:
            """Deduplicate contexts by extracting TASK name."""
            seen_tasks = set()
            result = []
            for ctx in contexts:
                # Extract task name from "TASK [name]" (including role prefix like "mariadb :")
                task_match = re.search(r"TASK \[([^\]]+)\]", ctx)
                if task_match:
                    key = task_match.group(1)
                    if key not in seen_tasks:
                        seen_tasks.add(key)
                        result.append(ctx)
                # Skip contexts without TASK header - they are likely partial duplicates
            return result

        def dedupe_by_content(contexts: list[str]) -> list[str]:
            """Deduplicate by checking content similarity (ignoring timestamps)."""
            seen_keys = set()
            result = []
            # Pattern to extract key content (error type + message)
            error_pattern = re.compile(
                r"(MismatchError|Error|Exception|FAILED).*?$", re.MULTILINE
            )
            for ctx in contexts:
                # Try to extract error signature
                match = error_pattern.search(ctx)
                if match:
                    key = match.group(0)[:150]
                else:
                    # Fallback: use content without timestamps
                    clean = re.sub(r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+", "", ctx)
                    key = clean[:200]
                if key not in seen_keys:
                    seen_keys.add(key)
                    result.append(ctx)
            return result

        return AnalysisResult(
            success=success,
            summary=summary,
            issues=issues,
            ansible_recap=ansible_recap,
            failed_tasks=preprocessed.get("failed_tasks", []),
            failed_tasks_context=dedupe_by_task_name(
                preprocessed.get("failed_tasks", [])
            ),
            ignored_tasks_context=dedupe_by_task_name(
                preprocessed.get("ignored_tasks", [])
            ),
            tempest_failures_context=dedupe_by_content(
                preprocessed.get("tempest_failures", [])
            ),
            python_tracebacks_context=dedupe_by_content(
                preprocessed.get("python_tracebacks", [])
            ),
            raw_analysis=raw_analysis,
        )

    def _extract_section(self, text: str, section_name: str) -> str:
        """Extracts a section from the analysis."""
        pattern = rf"##\s*{section_name}[^\n]*\n(.*?)(?=\n##|\Z)"
        match = re.search(pattern, text, re.DOTALL | re.IGNORECASE)
        if match:
            return match.group(1).strip()
        return ""


class ClaudeAPIAnalyzer(BaseAnalyzer):
    """Analyzes logs with Claude API."""

    def __init__(self, api_key: str):
        self.api_key = api_key
        self.client = anthropic.Anthropic(api_key=self.api_key)

    def analyze(self, preprocessed: dict) -> AnalysisResult:
        """Performs the log analysis using the API."""
        analysis_prompt = self._build_analysis_prompt(preprocessed)

        # Truncate if necessary (API limit)
        if len(analysis_prompt) > 150000:
            analysis_prompt = (
                analysis_prompt[:150000] + "\n\n[Log truncated due to size limit]"
            )

        try:
            response = self.client.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=8192,
                system=self.SYSTEM_PROMPT,
                messages=[{"role": "user", "content": analysis_prompt}],
            )

            raw_analysis = response.content[0].text
            return self._parse_analysis(raw_analysis, preprocessed)

        except anthropic.APIError as e:
            return AnalysisResult(
                success=False,
                summary=f"API error during analysis: {e}",
                raw_analysis="",
            )


class ClaudeCLIAnalyzer(BaseAnalyzer):
    """Analyzes logs using the Claude CLI with batched prompts."""

    # Maximum characters per batch to stay within context window
    # Claude CLI typically has ~100k token limit, ~4 chars per token = ~400k chars
    # We use a conservative limit to account for system prompt and response
    MAX_BATCH_SIZE = 80000

    def __init__(self):
        # Check if claude CLI is available
        self.claude_path = shutil.which("claude")
        if not self.claude_path:
            raise RuntimeError(
                "Claude CLI not found. Please install it or set ANTHROPIC_API_KEY."
            )

    def analyze(self, preprocessed: dict) -> AnalysisResult:
        """Performs the log analysis using Claude CLI with batching."""
        # Build batches from preprocessed data
        batches = self._create_batches(preprocessed)

        if len(batches) == 1:
            # Single batch - direct analysis
            raw_analysis = self._run_claude_cli(batches[0], is_final=True)
        else:
            # Multiple batches - analyze each and then summarize
            batch_results = []

            for i, batch in enumerate(batches, 1):
                result = self._run_claude_cli(batch, is_final=False, batch_num=i)
                batch_results.append(result)

            # Final summary of all batches
            raw_analysis = self._create_final_summary(batch_results)

        return self._parse_analysis(raw_analysis, preprocessed)

    def _create_batches(self, preprocessed: dict) -> list[str]:
        """Creates batches from preprocessed data that fit within context limits."""
        batches = []
        current_batch_parts = []
        current_size = 0

        # Priority order for sections
        sections_order = [
            ("ansible_recaps", "ANSIBLE PLAY RECAPS", -5),  # Last 5
            ("failed_tasks", "FAILED TASKS", 10),
            ("errors", "ERROR LINES", 30),
            ("tempest_failures", "TEMPEST TEST FAILURES", 10),
            ("ceph_issues", "CEPH ISSUES", 10),
            ("container_issues", "CONTAINER ISSUES", 10),
            ("service_issues", "SERVICE ISSUES", 10),
            ("warnings", "WARNINGS", 15),
        ]

        base_prompt = "Analyze the following OSISM Testbed log section for errors and unexpected states.\n\n"

        for section_key, section_title, limit in sections_order:
            items = preprocessed.get(section_key, [])
            if not items:
                continue

            # Handle negative limit (from end)
            if limit < 0:
                items = items[limit:]
            else:
                items = items[:limit]

            # Deduplicate
            items = list(dict.fromkeys(items))

            section_header = f"=== {section_title} ===\n"

            for item in items:
                item_text = (
                    f"- {item}\n"
                    if section_key in ["errors", "warnings"]
                    else f"{item}\n---\n"
                )
                item_size = (
                    len(section_header) + len(item_text)
                    if not current_batch_parts
                    else len(item_text)
                )

                # Check if adding this item would exceed batch size
                if (
                    current_size + item_size > self.MAX_BATCH_SIZE
                    and current_batch_parts
                ):
                    # Save current batch and start new one
                    batches.append(base_prompt + "".join(current_batch_parts))
                    current_batch_parts = []
                    current_size = 0

                # Add section header if this is the first item of this section in the batch
                if not current_batch_parts or not any(
                    section_title in p for p in current_batch_parts
                ):
                    current_batch_parts.append(section_header)
                    current_size += len(section_header)

                current_batch_parts.append(item_text)
                current_size += len(item_text)

        # Add remaining items as final batch
        if current_batch_parts:
            batches.append(base_prompt + "".join(current_batch_parts))

        # If no batches created, create a minimal one
        if not batches:
            batches.append(
                base_prompt + "No significant issues found in preprocessing.\n"
            )

        return batches

    def _run_claude_cli(
        self, prompt: str, is_final: bool = True, batch_num: int = 0
    ) -> str:
        """Runs Claude CLI with the given prompt."""
        if is_final:
            full_prompt = f"{self.SYSTEM_PROMPT}\n\n{prompt}"
        else:
            full_prompt = f"""You are analyzing OSISM Testbed logs. This is batch {batch_num} of a larger log.
Extract and summarize any errors, warnings, failed tasks, and issues found in this section.
Be concise but capture all important details.

{prompt}"""

        try:
            # Use stdin to pass the prompt to avoid command line length limits
            result = subprocess.run(
                [self.claude_path, "-p", full_prompt],
                capture_output=True,
                text=True,
                timeout=300,  # 5 minute timeout per batch
            )

            if result.returncode != 0:
                return f"Error running Claude CLI: {result.stderr}"

            return result.stdout.strip()

        except subprocess.TimeoutExpired:
            return "Error: Claude CLI timed out"
        except Exception as e:
            return f"Error running Claude CLI: {e}"

    def _create_final_summary(self, batch_results: list[str]) -> str:
        """Creates a final summary from multiple batch results."""
        combined = "\n\n---\n\n".join(
            [
                f"Batch {i+1} findings:\n{result}"
                for i, result in enumerate(batch_results)
            ]
        )

        summary_prompt = f"""{self.SYSTEM_PROMPT}

The following are analysis results from multiple batches of a large OSISM Testbed log.
Please combine these into a single coherent analysis following the standard format.

{combined}"""

        try:
            result = subprocess.run(
                [self.claude_path, "-p", summary_prompt],
                capture_output=True,
                text=True,
                timeout=300,
            )

            if result.returncode != 0:
                # Fall back to concatenated results
                return (
                    f"## Summary\nAnalysis completed in {len(batch_results)} batches.\n\n"
                    + combined
                )

            return result.stdout.strip()

        except Exception:
            return (
                f"## Summary\nAnalysis completed in {len(batch_results)} batches.\n\n"
                + combined
            )


class ReportGenerator:
    """Generates formatted reports."""

    @staticmethod
    def _format_context_logs(result: AnalysisResult) -> list[str]:
        """Formats context logs for failed/ignored tasks and tempest failures."""
        lines = []

        # Add context logs for failed tasks (real failures)
        if result.failed_tasks_context:
            lines.append("")
            lines.append("=" * 80)
            lines.append("CONTEXT LOGS: FAILED TASKS")
            lines.append("=" * 80)
            for i, context in enumerate(result.failed_tasks_context[:5], 1):  # Max 5
                lines.append(f"\n--- Failed Task {i} ---")
                if len(context) > 2000:
                    context = context[:2000] + "\n[...truncated...]"
                lines.append(context)

        # Add context logs for ignored tasks (expected failures)
        if result.ignored_tasks_context:
            lines.append("")
            lines.append("=" * 80)
            lines.append("CONTEXT LOGS: IGNORED TASKS (expected failures)")
            lines.append("=" * 80)
            for i, context in enumerate(result.ignored_tasks_context[:5], 1):  # Max 5
                lines.append(f"\n--- Ignored Task {i} ---")
                if len(context) > 2000:
                    context = context[:2000] + "\n[...truncated...]"
                lines.append(context)

        # Add context logs for tempest failures
        if result.tempest_failures_context:
            lines.append("")
            lines.append("=" * 80)
            lines.append("CONTEXT LOGS: TEMPEST FAILURES")
            lines.append("=" * 80)
            for i, context in enumerate(
                result.tempest_failures_context[:5], 1
            ):  # Max 5
                lines.append(f"\n--- Tempest Failure {i} ---")
                if len(context) > 2000:
                    context = context[:2000] + "\n[...truncated...]"
                lines.append(context)

        # Add context logs for Python tracebacks
        if result.python_tracebacks_context:
            lines.append("")
            lines.append("=" * 80)
            lines.append("CONTEXT LOGS: PYTHON TRACEBACKS")
            lines.append("=" * 80)
            for i, context in enumerate(
                result.python_tracebacks_context[:3], 1
            ):  # Max 3
                lines.append(f"\n--- Python Traceback {i} ---")
                if len(context) > 4000:
                    context = context[:4000] + "\n[...truncated...]"
                lines.append(context)

        return lines

    @staticmethod
    def generate_console_report(result: AnalysisResult, source: str) -> str:
        """Generates a console report."""
        lines = [
            "=" * 80,
            "OSISM TESTBED LOG ANALYSIS",
            "=" * 80,
            "",
            f"Source: {source}",
            "",
        ]

        # Status indicator
        status = "SUCCESS" if result.success else "FAILED"
        lines.append(f"Status: {status}")
        lines.append("")

        # Full Claude analysis
        if result.raw_analysis:
            lines.append(result.raw_analysis)

        lines.append("")
        lines.append("=" * 80)

        # Append context logs
        lines.extend(ReportGenerator._format_context_logs(result))

        return "\n".join(lines)

    @staticmethod
    def generate_markdown_report(result: AnalysisResult, source: str) -> str:
        """Generates a Markdown report."""
        lines = [
            "# OSISM Testbed Log Analysis",
            "",
            f"**Source:** `{source}`",
            "",
            f"**Status:** {'Success' if result.success else 'Failed'}",
            "",
            "---",
            "",
        ]

        if result.raw_analysis:
            lines.append(result.raw_analysis)

        # Append context logs as code blocks
        if result.failed_tasks_context:
            lines.append("")
            lines.append("## Context Logs: Failed Tasks")
            for i, context in enumerate(result.failed_tasks_context[:5], 1):
                lines.append(f"\n### Failed Task {i}")
                lines.append("```")
                if len(context) > 2000:
                    context = context[:2000] + "\n[...truncated...]"
                lines.append(context)
                lines.append("```")

        if result.ignored_tasks_context:
            lines.append("")
            lines.append("## Context Logs: Ignored Tasks (expected failures)")
            for i, context in enumerate(result.ignored_tasks_context[:5], 1):
                lines.append(f"\n### Ignored Task {i}")
                lines.append("```")
                if len(context) > 2000:
                    context = context[:2000] + "\n[...truncated...]"
                lines.append(context)
                lines.append("```")

        if result.tempest_failures_context:
            lines.append("")
            lines.append("## Context Logs: Tempest Failures")
            for i, context in enumerate(result.tempest_failures_context[:5], 1):
                lines.append(f"\n### Tempest Failure {i}")
                lines.append("```")
                if len(context) > 2000:
                    context = context[:2000] + "\n[...truncated...]"
                lines.append(context)
                lines.append("```")

        if result.python_tracebacks_context:
            lines.append("")
            lines.append("## Context Logs: Python Tracebacks")
            for i, context in enumerate(result.python_tracebacks_context[:3], 1):
                lines.append(f"\n### Python Traceback {i}")
                lines.append("```")
                if len(context) > 4000:
                    context = context[:4000] + "\n[...truncated...]"
                lines.append(context)
                lines.append("```")

        return "\n".join(lines)


def get_analyzer(api_key: Optional[str] = None) -> BaseAnalyzer:
    """Returns the appropriate analyzer based on available credentials."""
    # Check for API key
    effective_api_key = api_key or os.environ.get("ANTHROPIC_API_KEY")

    if effective_api_key and HAS_ANTHROPIC:
        return ClaudeAPIAnalyzer(effective_api_key)

    # Fall back to CLI
    return ClaudeCLIAnalyzer()


def main():
    """Main function."""
    parser = argparse.ArgumentParser(
        description="Analyzes OSISM Testbed logs with Claude",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s https://logs.services.osism.tech/.../job-output.txt
  %(prog)s /path/to/local/job-output.txt
  %(prog)s --output report.md https://logs.services.osism.tech/.../job-output.txt

Authentication (in order of precedence):
  1. --api-key argument
  2. ANTHROPIC_API_KEY environment variable
  3. Claude CLI (claude -p) as fallback
        """,
    )
    parser.add_argument("source", metavar="SOURCE", help="URL or path to the log file")
    parser.add_argument(
        "--output", "-o", help="Output file for Markdown report (optional)"
    )
    parser.add_argument(
        "--api-key",
        help="Anthropic API key (alternative: ANTHROPIC_API_KEY environment variable)",
    )
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")

    args = parser.parse_args()

    try:
        # Load log
        log_content = LogFetcher.fetch(args.source)

        # Preprocessing
        preprocessor = LogPreprocessor(log_content)
        sections = preprocessor.extract_summary_sections()

        if args.verbose:
            print(f"Log loaded: {len(log_content)} characters", file=sys.stderr)
            print("Preprocessing completed:", file=sys.stderr)
            print(
                f"  - Ansible RECAPs: {len(sections['ansible_recaps'])}",
                file=sys.stderr,
            )
            print(f"  - Error lines: {len(sections['errors'])}", file=sys.stderr)
            print(f"  - Warnings: {len(sections['warnings'])}", file=sys.stderr)
            print(f"  - Failed tasks: {len(sections['failed_tasks'])}", file=sys.stderr)
            print(
                f"  - Ignored tasks (false positives): {len(sections['ignored_tasks'])}",
                file=sys.stderr,
            )
            print(
                f"  - Tempest failures: {len(sections['tempest_failures'])}",
                file=sys.stderr,
            )
            print(f"  - Ceph issues: {len(sections['ceph_issues'])}", file=sys.stderr)

        # Get appropriate analyzer
        analyzer = get_analyzer(api_key=args.api_key)
        result = analyzer.analyze(sections)

        # Output report
        console_report = ReportGenerator.generate_console_report(result, args.source)
        print(console_report)

        # Save Markdown report (if requested)
        if args.output:
            md_report = ReportGenerator.generate_markdown_report(result, args.source)
            Path(args.output).write_text(md_report, encoding="utf-8")
            print(f"Markdown report saved: {args.output}", file=sys.stderr)

        # Exit code based on result
        sys.exit(0 if result.success else 1)

    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(2)
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(2)
    except ValueError as e:
        print(f"Configuration error: {e}", file=sys.stderr)
        sys.exit(2)
    except KeyboardInterrupt:
        print("\nAborted.", file=sys.stderr)
        sys.exit(130)


if __name__ == "__main__":
    main()
