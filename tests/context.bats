bats_require_minimum_version 1.7.0

setup() {
    export TEST_INSTRUCTIONS="$BATS_TEST_TMPDIR/instructions"
    mkdir -p "$TEST_INSTRUCTIONS"
}

run_context() {
    INSTRUCTIONS_DIR="$TEST_INSTRUCTIONS" "$PWD/context.sh" -s
}

@test "empty instructions produces no output" {
    run run_context
    [ -z "$output" ]
    [ $status -eq 0 ]
}

@test "file in instructions outputs file contents" {
    expected_output=$(sed -e 's/^        //' <<-EOF
        # Test

        hello world
	EOF
    )

    echo "hello world" > "$TEST_INSTRUCTIONS/test.md"

    run run_context
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "directory without script outputs Markdown file contents" {
    expected_output=$(sed -e 's/^        //' <<-EOF
        # Test

        ## Readme

        from subdir
	EOF
    )

    mkdir -p "$TEST_INSTRUCTIONS/test"
    echo "from subdir" > "$TEST_INSTRUCTIONS/test/readme.md"
    echo "should not appear" > "$TEST_INSTRUCTIONS/test/notes.txt"

    run run_context
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "directory with script and markdown outputs both alphabetically" {
    expected_output=$(sed -e 's/^        //' <<-EOF
        # Test

        ## Readme

        from markdown

        ## Run

        from script
	EOF
    )

    mkdir -p "$TEST_INSTRUCTIONS/test"
    echo "from markdown" > "$TEST_INSTRUCTIONS/test/readme.md"
    sed -e 's/^        //' <<-EOF > "$TEST_INSTRUCTIONS/test/run.sh"
        #!/bin/sh
        echo "from script"
	EOF
    chmod +x "$TEST_INSTRUCTIONS/test/run.sh"

    run run_context
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "root files come before directories" {
    expected_output=$(sed -e 's/^        //' <<-EOF
        # General Orders

        first file

        # Specific Orders

        second file

        # Zulu

        from file

        # Alpha

        ## Content

        from dir
	EOF
    )

    mkdir -p "$TEST_INSTRUCTIONS/alpha"
    echo "from dir" > "$TEST_INSTRUCTIONS/alpha/content.md"
    echo "from txt" > "$TEST_INSTRUCTIONS/notes.txt"
    echo "first file" > "$TEST_INSTRUCTIONS/00_general_orders.md"
    echo "second file" > "$TEST_INSTRUCTIONS/01 specific orders.md"
    echo "from file" > "$TEST_INSTRUCTIONS/zulu.md"

    run run_context
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "top-level executables are not run" {
    expected_output=$(sed -e 's/^        //' <<-EOF
        # Content

        from markdown
	EOF
    )

    echo "from markdown" > "$TEST_INSTRUCTIONS/content.md"
    sed -e 's/^        //' <<-EOF > "$TEST_INSTRUCTIONS/script.sh"
        #!/bin/sh
        echo "should not appear"
	EOF
    chmod +x "$TEST_INSTRUCTIONS/script.sh"

    run run_context
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "all scripts in subdirectory are run" {
    expected_output=$(sed -e 's/^        //' <<-EOF
        # Test

        ## First

        first

        ## Second

        second
	EOF
    )

    mkdir -p "$TEST_INSTRUCTIONS/test"
    sed -e 's/^        //' <<-EOF > "$TEST_INSTRUCTIONS/test/01_first.sh"
        #!/bin/sh
        echo "first"
	EOF
    chmod +x "$TEST_INSTRUCTIONS/test/01_first.sh"
    sed -e 's/^        //' <<-EOF > "$TEST_INSTRUCTIONS/test/02_second.sh"
        #!/bin/sh
        echo "second"
	EOF
    chmod +x "$TEST_INSTRUCTIONS/test/02_second.sh"

    run run_context
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "nested directories use deeper headings" {
    expected_output=$(sed -e 's/^        //' <<-EOF
        # Alpha

        ## Beta

        ### File

        nested content
	EOF
    )

    mkdir -p "$TEST_INSTRUCTIONS/alpha/beta"
    echo "nested content" > "$TEST_INSTRUCTIONS/alpha/beta/file.md"

    run run_context
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "git pull runs in script directory not current directory" {
    script_dir="$PWD"

    mock_bin="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$mock_bin"
    sed -e 's/^        //' <<-EOF > "$mock_bin/git"
        #!/bin/sh
        echo "\$@" > "$BATS_TEST_TMPDIR/git_args"
	EOF
    chmod +x "$mock_bin/git"

    run_dir="$BATS_TEST_TMPDIR/elsewhere"
    mkdir -p "$run_dir"
    cd "$run_dir"

    PATH="$mock_bin:$PATH" \
    INSTRUCTIONS_DIR="$TEST_INSTRUCTIONS" \
        "$script_dir/context.sh" \
            2>/dev/null

    diff -u <(echo "-C $script_dir pull --quiet") <(cat "$BATS_TEST_TMPDIR/git_args")
}

@test "failing script does not exit early" {
    expected_output=$(sed -e 's/^        //' <<-EOF
        # Test

        ## Before

        before

        ## After

        after
	EOF
    )

    mkdir -p "$TEST_INSTRUCTIONS/test"
    sed -e 's/^        //' <<-EOF > "$TEST_INSTRUCTIONS/test/01_before.sh"
        #!/bin/sh
        echo "before"
	EOF
    chmod +x "$TEST_INSTRUCTIONS/test/01_before.sh"
    sed -e 's/^        //' <<-EOF > "$TEST_INSTRUCTIONS/test/02_fail.sh"
        #!/bin/sh
        exit 1
	EOF
    chmod +x "$TEST_INSTRUCTIONS/test/02_fail.sh"
    sed -e 's/^        //' <<-EOF > "$TEST_INSTRUCTIONS/test/03_after.sh"
        #!/bin/sh
        echo "after"
	EOF
    chmod +x "$TEST_INSTRUCTIONS/test/03_after.sh"

    run run_context
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}

@test "directory with only failing script produces no output" {
    mkdir -p "$TEST_INSTRUCTIONS/test"
    sed -e 's/^        //' <<-EOF > "$TEST_INSTRUCTIONS/test/fail.sh"
        #!/bin/sh
        exit 1
	EOF
    chmod +x "$TEST_INSTRUCTIONS/test/fail.sh"

    run run_context
    [ -z "$output" ]
    [ $status -eq 0 ]
}

@test "stdin is saved to /tmp/sessionstart.json" {
    expected_file=$(sed -e 's/^        //' <<-EOF
        {
          "session_id": "abc123",
          "model": "claude"
        }
	EOF
    )
    rm -f /tmp/sessionstart.json

    echo '{"session_id":"abc123","model":"claude"}' | run_context

    diff -u <(echo "$expected_file") <(cat /tmp/sessionstart.json)
}

@test "stdin is echoed to output" {
    expected_output=$(sed -e 's/^        //' <<-EOF
        {"session_id":"abc123"}
	EOF
    )

    run bash -c 'echo "{\"session_id\":\"abc123\"}" | INSTRUCTIONS_DIR="'"$TEST_INSTRUCTIONS"'" '"$PWD"'/context.sh -s'
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}
