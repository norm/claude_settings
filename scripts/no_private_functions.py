#!/usr/bin/env python

import json
import sys
import re

input_data = json.load(sys.stdin)
tool_input = input_data.get("tool_input", {})
content = tool_input.get("content", "") or tool_input.get("new_string", "")

if re.search(r"\bdef\s+_(?!_)\w+\s*\(", content):
    print("Rejected: do not create private functions (def _...)", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
