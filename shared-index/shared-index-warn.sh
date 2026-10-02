#!/usr/bin/env bash
# Advisory: every outcome, including inspection failure, exits zero.
set -u

warn_and_continue() {
    printf '[shared-index] WARN: %s\n' "$1" >&2
    exit 0
}

git rev-parse --show-toplevel >/dev/null 2>&1 \
    || warn_and_continue 'unable to resolve repository; inspection skipped.'
scratch="$(mktemp -d "${TMPDIR:-/tmp}/shared-index.XXXXXX")" \
    || warn_and_continue 'unable to create scratch directory; inspection skipped.'
trap 'rm -rf -- "$scratch" || :' EXIT
if ! git diff --cached -z --no-renames --name-only --no-ext-diff >"$scratch/paths" 2>/dev/null; then
    warn_and_continue 'unable to inspect staged paths; inspection skipped.'
fi

a_seen=0
b_seen=0
while IFS= read -r -d '' path; do
    case "$path" in
        */*) directory="${path%/*}" ;;
        *) continue ;;
    esac
    # Classify directories only; the nearest exact owner wins.
    while :; do
        segment="${directory##*/}"
        case "$segment" in
            writer-a) a_seen=1; break ;;
            writer-b) b_seen=1; break ;;
        esac
        [ "$directory" != "$segment" ] || break
        directory="${directory%/*}"
    done
    [ "$a_seen" -eq 0 ] || [ "$b_seen" -eq 0 ] || break
done <"$scratch/paths"

if [ "$a_seen" -eq 1 ] && [ "$b_seen" -eq 1 ]; then
    printf '%s\n' \
        '[shared-index] WARN: staged paths span writer-a and writer-b.' \
        '[shared-index] Inspect the candidate diff and coordinate before committing.' >&2
fi
exit 0
