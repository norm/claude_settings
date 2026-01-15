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
            file_header "$file" 1
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

function file_header {
    local path="$1"
    local depth="$2"
    local name
    name=$(basename "$path")
    name="${name%.*}"

    printf '%*s' "$depth" '' | tr ' ' '#'
    echo " $(titlecase "$name")"
    echo
}

function process_dir {
    local dir="$1"
    local depth="$2"
    local has_subdir=0
    local script_files=()
    local success_files=()
    local success_outputs=()

    for entry in "$dir"/*; do
        [ -e "$entry" ] || continue
        if [ -d "$entry" ]; then
            has_subdir=1
        elif [ -x "$entry" ]; then
            script_files+=("$entry")
        fi
    done

    if [ ${#script_files[@]} -gt 0 ]; then
        for file in "${script_files[@]}"; do
            if output=$("$file" 2>&1); then
                success_files+=("$file")
                success_outputs+=("$output")
            fi
        done

        [ ${#success_files[@]} -eq 0 ] && return

        dir_header "$dir" "$depth" "${#success_files[@]}" "$has_subdir"
        ((depth++))

        for i in "${!success_files[@]}"; do
            file_header "${success_files[$i]}" "$depth"
            echo "${success_outputs[$i]}"
            echo
        done
        return
    fi

    local md_files=()
    for file in "$dir"/*.md; do
        [ -e "$file" ] || continue
        md_files+=("$file")
    done

    dir_header "$dir" "$depth" "${#md_files[@]}" "$has_subdir"
    ((depth++))

    for file in "${md_files[@]}"; do
        file_header "$file" "$depth"
        cat "$file"
        echo
    done
    for subdir in "$dir"/*; do
        [ -d "$subdir" ] || continue
        process_dir "$subdir" "$depth"
    done
}

function dir_header {
    local dir="$1"
    local depth="$2"
    local child_count="$3"
    local has_subdir="$4"

    printf '%*s' "$depth" '' | tr ' ' '#'
    echo " $(titlecase "$(basename "$dir")")"

    if [ "$depth" -gt 1 ] || [ "$child_count" -gt 1 ] || [ "$has_subdir" -eq 1 ]; then
        echo
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
