Use `diff` in tests not equality or substring matching, so that when things
fail it shows up in the test runner output. Check `$status` last.

Heredocs are used with sed to strip the indentation, and a tabbed EOF.

```bash
@test "some test" {
    expected_output=$(sed -e 's/^        //' <<-EOF
        5-11 > sections/section_one.md
        14-20 > sections/section_two.md
        23-27 > sections/section_three.md
	EOF
    )

    run ./breakdown.sh -e "$BATS_TEST_TMPDIR/source.md"
    diff -u <(echo "$expected_output") <(echo "$output")
    [ $status -eq 0 ]
}
```
