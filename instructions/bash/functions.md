Functions are added only when needed, not automatically. When a script grows
unwieldy, or needs to call the same code repeatedly, functions are added. The
body of the script should go in `function main`, and `main` must be kept at
the very top.

```bash
function do_thing {
    local arg="$1"
    # do stuff
}
```
