#!/usr/bin/env python

import json
import os
import sys
from pathlib import Path

import toml


def expand_paths(data, script_dir):
    if isinstance(data, dict):
        return {k: expand_paths(v, script_dir) for k, v in data.items()}
    elif isinstance(data, list):
        return [expand_paths(item, script_dir) for item in data]
    elif isinstance(data, str):
        return data.replace("{SCRIPT_DIR}", str(script_dir))
    else:
        return data


def load_toml_fragments(script_dir):
    result = {}
    for toml_file in sorted(
        Path(os.getenv('SETTINGS_DIR', script_dir / 'settings')).glob("*.toml")
    ):
        try:
            with open(toml_file) as handle:
                data = toml.load(handle)
                data = expand_paths(data, script_dir)
                result = deep_merge(result, data)
        except Exception as e:
            print(f"Error loading {toml_file}: {e}", file=sys.stderr)
            sys.exit(1)

    return result


def deep_merge(target, source):
    result = target.copy()

    for key, value in source.items():
        if (
            key in result
            and isinstance(result[key], dict)
            and isinstance(value, dict)
        ):
            result[key] = deep_merge(result[key], value)
        elif (
            key in result
            and isinstance(result[key], list)
            and isinstance(value, list)
        ):
            result[key] = result[key] + value
        else:
            result[key] = value

    return result


def main():
    script_dir = Path(__file__).parent.resolve()
    target_path = Path.home() / ".claude" / "settings.json"
    target_path.parent.mkdir(parents=True, exist_ok=True)

    source = load_toml_fragments(script_dir)

    with open(target_path, 'w') as handle:
        json.dump(source, handle, indent=2)
        handle.write('\n')


if __name__ == '__main__':
    main()
