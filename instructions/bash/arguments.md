Use `getopts`, and keep args sorted in alphabetical order. True/false flags
are stored as `0` and `1`.

```bash
while getopts "as" opt; do
    case "$opt" in
        a)  always=1 ;;
        s)  skip_restore=1 ;;
        *)  echo "Usage: $0 [-s] ..." >&2
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))
```
