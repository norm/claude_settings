bats_require_minimum_version 1.7.0

DIM_GREEN=$'\033[2m\033[32m'
DIM_YELLOW=$'\033[2m\033[33m'
DIM_CYAN=$'\033[2m\033[36m'
DIM_MAGENTA=$'\033[2m\033[35m'
RESET=$'\033[0m'

@test "outputs formatted status line" {
    expected_output='claude-sonnet-4-5-20250929 | $0.0123 | 5.5s | +10/-5 | 45%'

    input=$(sed -e 's/^        //' <<-EOF
        {
          "model": {"display_name": "claude-sonnet-4-5-20250929"},
          "cost": {"total_cost_usd": 0.0123, "total_duration_ms": 5500, "total_lines_added": 10, "total_lines_removed": 5},
          "exceeds_200k_tokens": false,
          "context_window": {"used_percentage": 45}
        }
	EOF
    )

    run ./scripts/statusline.py <<< "$input"
    diff -u <(echo "$expected_output") <(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')
    [ $status -eq 0 ]
}

@test "green colour at 49% context" {
    expected_output="model | \$0.0000 | 0.0s | +0/-0 | ${DIM_GREEN}49%${RESET}"

    input=$(sed -e 's/^        //' <<-EOF
        {
          "model": {"display_name": "model"},
          "cost": {"total_cost_usd": 0, "total_duration_ms": 0, "total_lines_added": 0, "total_lines_removed": 0},
          "exceeds_200k_tokens": false,
          "context_window": {"used_percentage": 49}
        }
	EOF
    )

    run ./scripts/statusline.py <<< "$input"
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "cyan colour at 50% context" {
    expected_output="model | \$0.0000 | 0.0s | +0/-0 | ${DIM_CYAN}50%${RESET}"

    input=$(sed -e 's/^        //' <<-EOF
        {
          "model": {"display_name": "model"},
          "cost": {"total_cost_usd": 0, "total_duration_ms": 0, "total_lines_added": 0, "total_lines_removed": 0},
          "exceeds_200k_tokens": false,
          "context_window": {"used_percentage": 50}
        }
	EOF
    )

    run ./scripts/statusline.py <<< "$input"
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "cyan colour at 79% context" {
    expected_output="model | \$0.0000 | 0.0s | +0/-0 | ${DIM_CYAN}79%${RESET}"

    input=$(sed -e 's/^        //' <<-EOF
        {
          "model": {"display_name": "model"},
          "cost": {"total_cost_usd": 0, "total_duration_ms": 0, "total_lines_added": 0, "total_lines_removed": 0},
          "exceeds_200k_tokens": false,
          "context_window": {"used_percentage": 79}
        }
	EOF
    )

    run ./scripts/statusline.py <<< "$input"
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "magenta colour at 80% context" {
    expected_output="model | \$0.0000 | 0.0s | +0/-0 | ${DIM_MAGENTA}80%${RESET}"

    input=$(sed -e 's/^        //' <<-EOF
        {
          "model": {"display_name": "model"},
          "cost": {"total_cost_usd": 0, "total_duration_ms": 0, "total_lines_added": 0, "total_lines_removed": 0},
          "exceeds_200k_tokens": false,
          "context_window": {"used_percentage": 80}
        }
	EOF
    )

    run ./scripts/statusline.py <<< "$input"
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "cost rounds to 4 decimal places" {
    expected_output="model | \$0.0001 | 0.0s | +0/-0 | ${DIM_GREEN}0%${RESET}"

    input=$(sed -e 's/^        //' <<-EOF
        {
          "model": {"display_name": "model"},
          "cost": {"total_cost_usd": 0.00005, "total_duration_ms": 0, "total_lines_added": 0, "total_lines_removed": 0},
          "exceeds_200k_tokens": false,
          "context_window": {"used_percentage": 0}
        }
	EOF
    )

    run ./scripts/statusline.py <<< "$input"
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "duration rounds to 1 decimal place" {
    expected_output="model | \$0.0000 | 1.6s | +0/-0 | ${DIM_GREEN}0%${RESET}"

    input=$(sed -e 's/^        //' <<-EOF
        {
          "model": {"display_name": "model"},
          "cost": {"total_cost_usd": 0, "total_duration_ms": 1550, "total_lines_added": 0, "total_lines_removed": 0},
          "exceeds_200k_tokens": false,
          "context_window": {"used_percentage": 0}
        }
	EOF
    )

    run ./scripts/statusline.py <<< "$input"
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "long duration shows seconds not minutes" {
    expected_output="model | \$0.0000 | 3600.0s | +0/-0 | ${DIM_GREEN}0%${RESET}"

    input=$(sed -e 's/^        //' <<-EOF
        {
          "model": {"display_name": "model"},
          "cost": {"total_cost_usd": 0, "total_duration_ms": 3600000, "total_lines_added": 0, "total_lines_removed": 0},
          "exceeds_200k_tokens": false,
          "context_window": {"used_percentage": 0}
        }
	EOF
    )

    run ./scripts/statusline.py <<< "$input"
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "missing model key shows placeholder" {
    expected_output="${DIM_YELLOW}(model unavailable)${RESET} | \$0.0000 | 0.0s | +0/-0 | ${DIM_GREEN}0%${RESET}"

    input=$(sed -e 's/^        //' <<-EOF
        {
          "cost": {"total_cost_usd": 0, "total_duration_ms": 0, "total_lines_added": 0, "total_lines_removed": 0},
          "exceeds_200k_tokens": false,
          "context_window": {"used_percentage": 0}
        }
	EOF
    )

    run ./scripts/statusline.py <<< "$input"
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "missing cost key shows placeholders" {
    expected_output="model | ${DIM_YELLOW}(cost unavailable)${RESET} | ${DIM_YELLOW}(time unavailable)${RESET} | ${DIM_YELLOW}(lines unavailable)${RESET} | ${DIM_GREEN}0%${RESET}"

    input=$(sed -e 's/^        //' <<-EOF
        {
          "model": {"display_name": "model"},
          "exceeds_200k_tokens": false,
          "context_window": {"used_percentage": 0}
        }
	EOF
    )

    run ./scripts/statusline.py <<< "$input"
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "missing context_window shows placeholder" {
    expected_output="model | \$0.0000 | 0.0s | +0/-0 | ${DIM_YELLOW}(context unavailable)${RESET}"

    input=$(sed -e 's/^        //' <<-EOF
        {
          "model": {"display_name": "model"},
          "cost": {"total_cost_usd": 0, "total_duration_ms": 0, "total_lines_added": 0, "total_lines_removed": 0},
          "exceeds_200k_tokens": false
        }
	EOF
    )

    run ./scripts/statusline.py <<< "$input"
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "malformed JSON shows error" {
    expected_output="${DIM_YELLOW}(statusline JSON invalid)${RESET}"

    run ./scripts/statusline.py <<< "not json"
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}
