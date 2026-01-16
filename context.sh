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
            print_header "$(basename "${file%.*}")" 1
            cat "$file"
            echo
        fi
    done

    for entry in "$INSTRUCTIONS_DIR"/*; do
        if [ -d "$entry" ]; then
            process_dir "$entry" 1
        fi
    done
}

function print_header {
    local name="$1"
    local depth="$2"
    printf '%*s' "$depth" '' | tr ' ' '#'
    echo " $(titlecase "$name")"
    echo
}

function process_dir {
    local dir="$1"
    local depth="$2"
    local has_subdir=0
    local files=()
    local output
    local outputs=()
    local successful_files=()

    for entry in "$dir"/*; do
        [ -e "$entry" ] || continue
        if [ -d "$entry" ]; then
            has_subdir=1
        elif [ -x "$entry" ] || [[ "$entry" == *.md ]]; then
            files+=("$entry")
        fi
    done

    for file in "${files[@]}"; do
        if [ -x "$file" ]; then
            if output=$("$file" 2>&1); then
                successful_files+=("$file")
                outputs+=("$output")
            fi
        else
            successful_files+=("$file")
            outputs+=("")
        fi
    done

    [ ${#successful_files[@]} -eq 0 ] && [ "$has_subdir" -eq 0 ] && return

    print_header "$(basename "$dir")" "$depth"
    ((depth++))

    for index in "${!successful_files[@]}"; do
        file="${successful_files[$index]}"
        print_header "$(basename "${file%.*}")" "$depth"
        if [ -x "$file" ]; then
            echo "${outputs[$index]}"
        else
            cat "$file"
        fi
        echo
    done

    for subdir in "$dir"/*; do
        [ -d "$subdir" ] || continue
        process_dir "$subdir" "$depth"
    done
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
