bats_require_minimum_version 1.7.0

setup() {
    export HOME="$BATS_TEST_TMPDIR"
    export SETTINGS_DIR="$BATS_TEST_TMPDIR/settings"
    mkdir -p "$HOME/.claude"
    mkdir -p "$SETTINGS_DIR"
}

run_merge() {
    "$PWD/merge-settings.py"
}

assert_settings() {
    local expected="$1"
    jq empty "$HOME/.claude/settings.json"
    diff -u <(echo "$expected" | jq -S .) <(jq -S . "$HOME/.claude/settings.json")
}

@test "creates .claude directory if it does not exist" {
    export HOME="$BATS_TEST_TMPDIR/fresh"
    [ ! -d "$HOME/.claude" ]
    echo 'model = "claude-sonnet-4-5-20250929"' > $SETTINGS_DIR/base.toml

    run run_merge
    [ $status -eq 0 ]
    [ -d "$HOME/.claude" ]
    assert_settings '{"model": "claude-sonnet-4-5-20250929"}'
}

@test "replaces existing settings.json with source" {
    echo '{"model": "claude-sonnet-4-5-20250929", "other": "ignored"}' > "$HOME/.claude/settings.json"
    sed -e 's/^        //' <<-EOF > $SETTINGS_DIR/permissions.toml
        [permissions]
        allow = ["Bash(npm test)"]
        deny = ["Read(.env)"]
	EOF

    run run_merge
    [ $status -eq 0 ]
    sed -e 's/^        //' <<-EOF | assert_settings "$(cat)"
        {
          "permissions": {
            "allow": ["Bash(npm test)"],
            "deny": ["Read(.env)"]
          }
        }
	EOF
}

@test "source hooks completely replace target hooks" {
    sed -e 's/^        //' <<-EOF > "$HOME/.claude/settings.json"
        {
          "hooks": {
            "SessionStart": [{"matcher": "", "hooks": [{"type": "command", "command": "old.sh"}]}]
          }
        }
	EOF
    sed -e 's/^        //' <<-EOF > $SETTINGS_DIR/hooks.toml
        [[hooks.SessionStart]]
        matcher = ""
        hooks = [
          { type = "command", command = "new.sh" }
        ]
	EOF

    run run_merge
    [ $status -eq 0 ]
    sed -e 's/^        //' <<-EOF | assert_settings "$(cat)"
        {
          "hooks": {
            "SessionStart": [
              {
                "matcher": "",
                "hooks": [
                  {
                    "type": "command",
                    "command": "new.sh"
                  }
                ]
              }
            ]
          }
        }
	EOF
}

@test "removing hook from source removes it from target" {
    sed -e 's/^        //' <<-EOF > "$HOME/.claude/settings.json"
        {
          "model": "claude-sonnet-4-5-20250929",
          "hooks": {
            "SessionStart": [{"matcher": "", "hooks": [{"type": "command", "command": "existing.sh"}]}]
          }
        }
	EOF
    echo 'model = "claude-sonnet-4-5-20250929"' > $SETTINGS_DIR/base.toml

    run run_merge
    [ $status -eq 0 ]
    sed -e 's/^        //' <<-EOF | assert_settings "$(cat)"
        {
          "model": "claude-sonnet-4-5-20250929"
        }
	EOF
}

@test "writes statusLine configuration" {
    echo '{"model": "claude-sonnet-4-5-20250929"}' > "$HOME/.claude/settings.json"
    sed -e 's/^        //' <<-EOF > $SETTINGS_DIR/statusline.toml
        [statusLine]
        type = "command"
        command = "~/.claude/statusline.sh"
	EOF

    run run_merge
    [ $status -eq 0 ]
    sed -e 's/^        //' <<-EOF | assert_settings "$(cat)"
        {
          "statusLine": {
            "type": "command",
            "command": "~/.claude/statusline.sh"
          }
        }
	EOF
}

@test "writes env variables" {
    echo '{"model": "claude-sonnet-4-5-20250929"}' > "$HOME/.claude/settings.json"
    sed -e 's/^        //' <<-EOF > $SETTINGS_DIR/env.toml
        [env]
        DEBUG = "true"
        LOG_LEVEL = "verbose"
	EOF

    run run_merge
    [ $status -eq 0 ]
    sed -e 's/^        //' <<-EOF | assert_settings "$(cat)"
        {
          "env": {
            "DEBUG": "true",
            "LOG_LEVEL": "verbose"
          }
        }
	EOF
}

@test "merges arrays from multiple TOML files" {
    sed -e 's/^        //' <<-EOF > $SETTINGS_DIR/a_commands.toml
        [permissions]
        allow = ["Bash(npm test)"]
	EOF
    sed -e 's/^        //' <<-EOF > $SETTINGS_DIR/b_web.toml
        [permissions]
        allow = ["WebSearch"]
	EOF

    run run_merge
    [ $status -eq 0 ]
    sed -e 's/^        //' <<-EOF | assert_settings "$(cat)"
        {
          "permissions": {
            "allow": ["Bash(npm test)", "WebSearch"]
          }
        }
	EOF
}

@test "merges sandbox configuration" {
    echo '{}' > "$HOME/.claude/settings.json"
    sed -e 's/^        //' <<-EOF > $SETTINGS_DIR/sandbox.toml
        [sandbox]
        enabled = true
        excludedCommands = ["docker", "git"]
	EOF

    run run_merge
    [ $status -eq 0 ]
    sed -e 's/^        //' <<-EOF | assert_settings "$(cat)"
        {
          "sandbox": {
            "enabled": true,
            "excludedCommands": ["docker", "git"]
          }
        }
	EOF
}

@test "merges attribution settings" {
    echo '{}' > "$HOME/.claude/settings.json"
    sed -e 's/^        //' <<-EOF > $SETTINGS_DIR/attribution.toml
        [attribution]
        commit = "Generated with Claude Code"
        pr = "AI-assisted PR"
	EOF

    run run_merge
    [ $status -eq 0 ]
    sed -e 's/^        //' <<-EOF | assert_settings "$(cat)"
        {
          "attribution": {
            "commit": "Generated with Claude Code",
            "pr": "AI-assisted PR"
          }
        }
	EOF
}

@test "source with multiple hook types replaces all target hooks" {
    sed -e 's/^        //' <<-EOF > "$HOME/.claude/settings.json"
        {
          "hooks": {
            "SessionStart": [{"matcher": "", "hooks": [{"type": "command", "command": "old-start.sh"}]}]
          }
        }
	EOF
    sed -e 's/^        //' <<-EOF > $SETTINGS_DIR/hooks.toml
        [[hooks.SessionStart]]
        matcher = ""
        hooks = [
          { type = "command", command = "new-start.sh" }
        ]

        [[hooks.PreToolUse]]
        matcher = ""
        hooks = [
          { type = "command", command = "pre.sh" }
        ]
	EOF

    run run_merge
    [ $status -eq 0 ]
    sed -e 's/^        //' <<-EOF | assert_settings "$(cat)"
        {
          "hooks": {
            "SessionStart": [
              {
                "matcher": "",
                "hooks": [
                  {
                    "type": "command",
                    "command": "new-start.sh"
                  }
                ]
              }
            ],
            "PreToolUse": [
              {
                "matcher": "",
                "hooks": [
                  {
                    "type": "command",
                    "command": "pre.sh"
                  }
                ]
              }
            ]
          }
        }
	EOF
}

@test "handles TOML with trailing commas in arrays" {
    echo '{"model": "claude-sonnet-4-5-20250929"}' > "$HOME/.claude/settings.json"
    sed -e 's/^        //' <<-EOF > $SETTINGS_DIR/permissions.toml
        [permissions]
        allow = [
            "Bash(make test)",
        ]
	EOF

    run run_merge
    [ $status -eq 0 ]
    sed -e 's/^        //' <<-EOF | assert_settings "$(cat)"
        {
          "permissions": {
            "allow": ["Bash(make test)"]
          }
        }
	EOF
}

@test "expands {SCRIPT_DIR} in hook commands" {
    echo '{}' > "$HOME/.claude/settings.json"
    sed -e 's/^        //' <<-EOF > $SETTINGS_DIR/hooks.toml
        [[hooks.SessionStart]]
        matcher = ""
        hooks = [
          { type = "command", command = "{SCRIPT_DIR}/scripts/test.sh" }
        ]
	EOF

    run run_merge
    [ $status -eq 0 ]
    sed -e 's/^        //' <<-EOF | assert_settings "$(cat)"
        {
          "hooks": {
            "SessionStart": [
              {
                "matcher": "",
                "hooks": [
                  {
                    "type": "command",
                    "command": "$PWD/scripts/test.sh"
                  }
                ]
              }
            ]
          }
        }
	EOF
}
