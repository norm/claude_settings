#!/usr/bin/env python

import json
import sys

DIM_GREEN = f'{DIM}\033[32m'
DIM_CYAN = f'{DIM}\033[36m'
DIM_MAGENTA = f'{DIM}\033[35m'
RESET = '\033[0m'

raw = sys.stdin.read()
with open('/tmp/statusline.json', 'w') as handle:
    handle.write(raw)
data = json.loads(raw)

model = data['model']['display_name']
cost = data['cost']['total_cost_usd']
duration = data['cost']['total_duration_ms'] / 1000
lines_added = data['cost']['total_lines_added']
lines_removed = data['cost']['total_lines_removed']
exceeds_200k = data['exceeds_200k_tokens']
percentage = data["context_window"]["used_percentage"]
if percentage < 50:
    colour = DIM_GREEN
elif percentage < 80:
    colour = DIM_CYAN
else:
    colour = DIM_MAGENTA

print(
    f"{model} | ${cost:.4f} | {duration:.1f}s | "
    f"+{lines_added}/-{lines_removed} | "
    f"{colour}{percentage}%{RESET}"
)
