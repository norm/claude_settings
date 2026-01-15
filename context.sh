#!/usr/bin/env -S bash -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$BASH_SOURCE")")
INSTRUCTIONS_DIR="${INSTRUCTIONS_DIR:-$SCRIPT_DIR/instructions}"

skip_pull=0
while getopts "s" opt; do
    case "$opt" in
        s)  skip_pull=1 ;;
        *)  echo "Usage: $0 [-s]" >&2
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))


function main {
    [ "$skip_pull" -eq 0 ] && update_repo
    update_settings
    output_instructions
}

function update_settings {
    "$SCRIPT_DIR/merge-settings.py"
}

function update_repo {
    timeout 3 \
        git -C "$SCRIPT_DIR" pull --quiet \
            2>/dev/null || true
}

function output_instructions {
    for file in "$INSTRUCTIONS_DIR"/*.md; do
        if [ -e "$file" ]; then
            header "$file"
            cat "$file"
            echo
        fi
    done

    for entry in "$INSTRUCTIONS_DIR"/*; do
        if [ -d "$entry" ]; then
            process_dir "$entry"
        fi
    done
}

function header {
    local path="$1"
    local relative="${path#$INSTRUCTIONS_DIR/}"
    local name="${relative%.*}"
    local depth=1

    IFS='/' read -ra parts <<< "$name"
    for part in "${parts[@]}"; do
        printf '%*s' "$depth" '' | tr ' ' '#'
        echo " $(titlecase "$part")"
        ((depth++))
    done
    echo
}

function process_dir {
    local dir="$1"
    local has_script=0

    for file in "$dir"/*; do
        [ -e "$file" ] || continue
        [ -d "$file" ] && continue
        if [ -x "$file" ]; then
            has_script=1
            header "$file"
            "$file" || true
            echo
        fi
    done

    if [ "$has_script" -eq 0 ]; then
        for file in "$dir"/*.md; do
            [ -e "$file" ] || continue
            header "$file"
            cat "$file"
            echo
        done
        for subdir in "$dir"/*; do
            [ -d "$subdir" ] || continue
            process_dir "$subdir"
        done
    fi
}

function titlecase {
    echo "$1" | awk '
        {
            gsub(/_/, " ")
            gsub(/^[0-9 ]*/, "")

            for (i = 1; i <= NF; i++)
                $i = toupper(substr($i, 1, 1)) substr($i, 2)
        }
        1
    '
}

main
