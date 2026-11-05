# dotenv helper (POSIX shell / bash / zsh)
# Usage:  . /path/to/dotenv.sh
#         dotenv_get <file> <key>
#         dotenv_keys <file>
#         dotenv_check <file> <key> [key...]
#
# Reads KEY=value, "#" comments, "export KEY=value", optional surrounding quotes,
# preserves "=" inside values, strips CR from CRLF files.
# Exit codes: 0 ok, 1 not found, 2 bad arguments.

dotenv_get() {
    [ $# -ge 2 ] || return 2
    [ -f "$1" ] || return 1

    awk -v want="$2" '
        { sub(/\r$/, "") }
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*$/ { next }
        {
            line = $0
            sub(/^[[:space:]]*export[[:space:]]+/, "", line)
            eq = index(line, "=")
            if (eq == 0) next
            k = substr(line, 1, eq - 1)
            gsub(/^[[:space:]]+/, "", k)
            gsub(/[[:space:]]+$/, "", k)
            if (k != want) next
            v = substr(line, eq + 1)
            gsub(/^[[:space:]]+/, "", v)
            gsub(/[[:space:]]+$/, "", v)
            if (length(v) >= 2) {
                f = substr(v, 1, 1)
                l = substr(v, length(v), 1)
                if ((f == "\"" && l == "\"") || (f == "\047" && l == "\047")) {
                    v = substr(v, 2, length(v) - 2)
                }
            }
            print v
            found = 1
            exit
        }
        END { exit(found ? 0 : 1) }
    ' "$1"
}

dotenv_keys() {
    [ $# -ge 1 ] || return 2
    [ -f "$1" ] || return 1

    awk '
        { sub(/\r$/, "") }
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*$/ { next }
        {
            line = $0
            sub(/^[[:space:]]*export[[:space:]]+/, "", line)
            eq = index(line, "=")
            if (eq == 0) next
            k = substr(line, 1, eq - 1)
            gsub(/^[[:space:]]+/, "", k)
            gsub(/[[:space:]]+$/, "", k)
            if (k != "") print k
        }
    ' "$1" | sort -u
}

# Returns 0 when every key exists and is non-empty; prints missing keys to stdout.
dotenv_check() {
    [ $# -ge 2 ] || return 2
    _dotenv_file="$1"
    shift
    _dotenv_missing=""
    for _dotenv_k in "$@"; do
        if [ -z "$(dotenv_get "$_dotenv_file" "$_dotenv_k")" ]; then
            _dotenv_missing="$_dotenv_missing $_dotenv_k"
        fi
    done
    if [ -n "$_dotenv_missing" ]; then
        printf '%s\n' "${_dotenv_missing# }"
        return 1
    fi
    return 0
}
