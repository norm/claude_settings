#!/usr/bin/env python

import json
import sys

DIM = '\033[2m'
DIM_GREEN = f'{DIM}\033[32m'
DIM_YELLOW = f'{DIM}\033[33m'
DIM_CYAN = f'{DIM}\033[36m'
DIM_MAGENTA = f'{DIM}\033[35m'
RESET = '\033[0m'


def unavailable(name):
    return f'{DIM_YELLOW}({name} unavailable){RESET}'


raw = sys.stdin.read()
with open('/tmp/statusline.json', 'w') as handle:
    handle.write(raw)

try:
    data = json.loads(raw)
except json.JSONDecodeError:
    print(f'{DIM_YELLOW}(statusline JSON invalid){RESET}')
    sys.exit(0)

try:
    model = data['model']['display_name']
except KeyError:
    model = unavailable('model')

try:
    cost_data = data['cost']
    cost = f"${cost_data['total_cost_usd']:.4f}"
    duration = f"{cost_data['total_duration_ms'] / 1000:.1f}s"
    lines = f"+{cost_data['total_lines_added']}/-{cost_data['total_lines_removed']}"
except KeyError:
    cost = unavailable('cost')
    duration = unavailable('time')
    lines = unavailable('lines')

try:
    percentage = data['context_window']['used_percentage']
    if percentage < 50:
        colour = DIM_GREEN
    elif percentage < 80:
        colour = DIM_CYAN
    else:
        colour = DIM_MAGENTA
    context = f'{colour}{percentage}%{RESET}'
except KeyError:
    context = unavailable('context')

print(f"{model} | {cost} | {duration} | {lines} | {context}")
