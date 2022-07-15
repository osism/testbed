"""Rule definition for usage of fully qualified collection names for FQCN."""
import sys
import yaml
import os
from typing import Any, Dict, Optional, Union

from ansiblelint.file_utils import Lintable
from ansiblelint.rules import AnsibleLintRule


class OsismFQCNRule(AnsibleLintRule):
    """Use FQCN for all actions."""

    id = "osism-fqcn"
    severity = "MEDIUM"
    description = (
        "Check whether the long version is used in the playbook"
    )
    tags = ["formatting", "experimental"]

    def matchtask(
        self, task: Dict[str, Any], file: Optional[Lintable] = None
    ) -> Union[bool, str]:

        with open(f"{os.getcwd()}/.ansible-lint-rules/osism_fqcn_list.yaml", 'r') as fileStream:
            try:
                osism_fqcn_list = yaml.safe_load(fileStream)
            except yaml.YAMLError as exception:
                print(exception)
                sys.exit(0)

        for category in osism_fqcn_list:
            if task["action"]["__ansible_module_original__"] in osism_fqcn_list[category]:
                return False
        return True
