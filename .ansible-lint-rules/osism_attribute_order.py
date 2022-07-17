import sys
import os
import yaml
from typing import Any, Dict, Optional, Union

from ansiblelint.file_utils import Lintable
from ansiblelint.rules import AnsibleLintRule


class OsismAttributeOrderRule(AnsibleLintRule):
    """Ensure specific order of attributes in mappings."""

    id = "osism-attribute-order"
    shortdesc = __doc__
    severity = "LOW"
    tags = ["formatting", "experimental"]
    needs_raw_task = True

    def matchtask(
        self, task: Dict[str, Any], file: Optional[Lintable] = None
    ) -> Union[bool, str]:

        with open(f"{os.getcwd()}/.ansible-lint-rules/osism_attribute_order_list.yaml", 'r') as fileStream:
            try:
                osism_attribute_order_list = yaml.safe_load(fileStream)
            except yaml.YAMLError as exception:
                print(exception)
                sys.exit(0)

        raw_task = task["__raw_task__"]
        counter = 0
        counter_prev = 0
        for attribute in osism_attribute_order_list["osism_attribute_order_list"]:
            if attribute in raw_task:
                attribute_list = [*raw_task]
                counter = attribute_list.index(attribute)
                if counter < counter_prev:
                    return f"{attribute_list[counter_prev]} is not at the right place"
                else:
                    counter_prev = counter
        return False
