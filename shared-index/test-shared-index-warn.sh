#!/usr/bin/env bash
set -euo pipefail
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE
HERE="$(cd -- "$(dirname -- "$0")" && pwd)"
export AW_HELPER="$HERE/shared-index-warn.sh"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=fixture GIT_COMMITTER_NAME=fixture
export GIT_AUTHOR_EMAIL=fixture.invalid GIT_COMMITTER_EMAIL=fixture.invalid
scratch="$(mktemp -d "${TMPDIR:-/tmp}/shared-index-tests.XXXXXX")"
trap 'rm -rf -- "$scratch"' EXIT
assertions=0

assert() {
    if ! "$@"; then
        printf 'SHARED_INDEX FAIL case=%s assertion=%s\n' "$case_name" "$((assertions + 1))" >&2
        exit 1
    fi
    assertions=$((assertions + 1))
}

new_repo() {
    case_name="$1"
    repo="$scratch/$case_name"
    mkdir -p -- "$repo"
    git init --quiet "$repo"
    git -C "$repo" config core.hooksPath "$repo/.git/hooks"
    git -C "$repo" config commit.gpgsign false
    cat >"$repo/.git/hooks/pre-commit" <<'HOOK'
#!/usr/bin/env bash
exec bash "$AW_HELPER"
HOOK
    chmod +x "$repo/.git/hooks/pre-commit"
    mkdir -p "$repo/writer-a" "$repo/writer-b"
}

seed() {
    printf 'original-a\n' >"$repo/writer-a/a"
    printf 'original-b\n' >"$repo/writer-b/b"
    git -C "$repo" add .
    git -C "$repo" commit -qm seed >"$scratch/seed-output" 2>&1
}

commit_case() {
    if ! git -C "$repo" commit "$@" >"$scratch/commit-output" 2>&1; then
        cat "$scratch/commit-output" >&2
        printf 'SHARED_INDEX FAIL case=%s commit failed\n' "$case_name" >&2
        exit 1
    fi
}

warning_is() {
    local output
    output="$(cat "$scratch/commit-output")"
    if [ "$1" = yes ]; then
        assert test "${output#*'[shared-index] WARN: staged paths span writer-a and writer-b.'}" != "$output"
    else
        assert test "${output#*'[shared-index] WARN:'}" = "$output"
    fi
}

new_repo initial
assert test "$(git -C "$repo" rev-list --all --count)" = 0
printf 'first-a\n' >"$repo/writer-a/a"
printf 'first-b\n' >"$repo/writer-b/b"
git -C "$repo" add .
commit_case -qm initial
warning_is yes
assert test "$(git -C "$repo" show HEAD:writer-b/b)" = first-b

new_repo mixed
seed
printf 'changed-a\n' >"$repo/writer-a/a"
printf 'changed-b\n' >"$repo/writer-b/b"
git -C "$repo" add .
commit_case -qm mixed
warning_is yes
assert test "$(git -C "$repo" show HEAD:writer-a/a)" = changed-a
assert test "$(git -C "$repo" show HEAD:writer-b/b)" = changed-b

new_repo diff-config
seed
git -C "$repo" config diff.relative true
git -C "$repo" config diff.ignoreSubmodules all
printf 'configured-a\n' >"$repo/writer-a/a"
printf 'configured-b\n' >"$repo/writer-b/b"
git -C "$repo" add .
assert bash -c 'cd -- "$1/writer-a" && bash "$AW_HELPER"' bash "$repo" >"$scratch/commit-output" 2>&1
warning_is yes

new_repo single
seed
printf 'single-a\n' >"$repo/writer-a/a"
git -C "$repo" add writer-a/a
commit_case -qm single
warning_is no
assert test "$(git -C "$repo" show HEAD:writer-a/a)" = single-a

new_repo all
seed
printf 'all-a\n' >"$repo/writer-a/a"
printf 'all-b\n' >"$repo/writer-b/b"
commit_case -qam all
warning_is yes
assert test "$(git -C "$repo" show HEAD:writer-a/a)" = all-a
assert test "$(git -C "$repo" show HEAD:writer-b/b)" = all-b

new_repo amend
seed
printf 'amended-a\n' >"$repo/writer-a/a"
printf 'amended-b\n' >"$repo/writer-b/b"
git -C "$repo" add .
commit_case --amend --no-edit --quiet
warning_is yes
assert test "$(git -C "$repo" rev-list HEAD --count)" = 1
assert test "$(git -C "$repo" show HEAD:writer-b/b)" = amended-b

new_repo nearest
seed
mkdir -p "$repo/writer-a/writer-b" "$repo/writer-b/writer-a"
printf 'inner-b\n' >"$repo/writer-a/writer-b/one"
printf 'outer-b\n' >"$repo/writer-b/b"
git -C "$repo" add .
commit_case -qm nearer-b
warning_is no
printf 'inner-a\n' >"$repo/writer-b/writer-a/two"
printf 'outer-a\n' >"$repo/writer-a/a"
git -C "$repo" add .
commit_case -qm nearer-a
warning_is no

new_repo neutral
seed
mkdir -p "$repo/writer-a-notes" "$repo/notes"
printf 'neutral\n' >"$repo/writer-a-notes/one"
printf 'neutral\n' >"$repo/notes/writer-a"
printf 'neutral\n' >"$repo/writer-b-notes.md"
printf 'only-b\n' >"$repo/writer-b/b"
git -C "$repo" add .
commit_case -qm neutral
warning_is no

new_repo unusual
seed
# Blank, tab, newline, quote, dash and non-ASCII bytes remain literal paths.
unusual_a=$'writer-a/-a b\tline\n"é'
unusual_b=$'writer-b/-b\n\t\047'
printf 'odd-a\n' >"$repo/$unusual_a"
printf 'odd-b\n' >"$repo/$unusual_b"
git -C "$repo" add -- "$unusual_a" "$unusual_b"
commit_case -qm unusual
warning_is yes
assert test "$(git -C "$repo" show "HEAD:$unusual_a")" = odd-a
assert test "$(git -C "$repo" show "HEAD:$unusual_b")" = odd-b
# A newline inside a neutral directory must not invent an owner segment.
neutral_directory=$'notes/literal\nwriter-a'
mkdir -p "$repo/$neutral_directory"
printf 'still-neutral\n' >"$repo/$neutral_directory/pretend"
printf 'only-b-again\n' >"$repo/writer-b/b"
git -C "$repo" add .
commit_case -qm unusual-neutral
warning_is no
assert test "$(git -C "$repo" show "HEAD:$neutral_directory/pretend")" = still-neutral

new_repo inspection-failure
seed
printf 'failure-a\n' >"$repo/writer-a/a"
printf 'failure-b\n' >"$repo/writer-b/b"
git -C "$repo" add .
# Fail only the helper's inspection, while letting Git run the real commit.
git() {
    if [ "${1:-}" = diff-index ]; then return 7; fi
    command git "$@"
}
export -f git
commit_case -qm inspection-failure
unset -f git
output="$(cat "$scratch/commit-output")"
assert test "${output#*'unable to inspect staged paths; inspection skipped.'}" != "$output"
assert test "$(git -C "$repo" show HEAD:writer-b/b)" = failure-b
assert bash -c 'cd -- "$1" && bash "$AW_HELPER"' bash "$scratch" >"$scratch/no-repo-output" 2>&1
output="$(cat "$scratch/no-repo-output")"
assert test "${output#*'unable to resolve repository; inspection skipped.'}" != "$output"
assert env TMPDIR="$scratch/missing" bash -c 'cd -- "$1" && bash "$AW_HELPER"' bash "$repo" >"$scratch/no-temp-output" 2>&1
output="$(cat "$scratch/no-temp-output")"
assert test "${output#*'unable to create scratch directory; inspection skipped.'}" != "$output"

new_repo pathspec
seed
printf 'staged-a\n' >"$repo/writer-a/a"
printf 'held-b\n' >"$repo/writer-b/b"
git -C "$repo" add .
printf 'working-a\n' >"$repo/writer-a/a"
assert test "$(git -C "$repo" show :writer-a/a)" = staged-a
commit_case -qm pathspec -- writer-a/a
warning_is no
assert test "$(git -C "$repo" show HEAD:writer-a/a)" = working-a
assert test "$(git -C "$repo" show HEAD:writer-b/b)" = original-b
assert test "$(git -C "$repo" show :writer-b/b)" = held-b
assert test "$(git -C "$repo" diff --cached --name-only)" = writer-b/b

printf 'SHARED_INDEX assertions=%s pass skips=0\n' "$assertions"
