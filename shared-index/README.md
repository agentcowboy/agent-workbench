# Shared-index warning

`shared-index-warn.sh` warns when the hook-visible staged diff contains both `writer-a` and `writer-b` paths. Starting at each file's parent, the nearest directory named exactly `writer-a` or `writer-b` wins. Other paths are neutral; similarly named files or directories do not count.

The helper uses NUL-delimited paths and disables rename detection, so a rename is inspected as its removed and added paths. It always exits zero, including when inspection fails. It detects directory ownership only: no identity, lock, authorship or concurrency tracking. A mixed-owner merge can produce an accepted advisory warning.

The hook compares the index with `HEAD`, so `git commit --amend` that adds only the other writer's change to a single-writer commit does not warn.

## Install and remove

`writer-a` and `writer-b` are placeholder directory names. Change the two `case` labels and the names in the warning message in `shared-index-warn.sh` to the two directory names you care about; otherwise the hook never warns about your directories. The bundled tests use the placeholder names, so run them on an unedited copy.

Copy the helper into your repository, then add this call to your existing Bash `pre-commit` hook, adjusting the relative path:

```bash
bash shared-index/shared-index-warn.sh || :
```

For a repository with no existing hook, put that call below `#!/usr/bin/env bash` in `.git/hooks/pre-commit` and make the hook executable. Keep any other commit checks after the call. The helper is advisory; those checks keep their own exit behaviour. Remove the call to disable it. No hook is installed by `ACCEPTANCE` into your checkout.

## Commit advice

Inspect the candidate diff and coordinate before committing. A plain commit uses staged content. `git commit -a` also stages modified or deleted tracked files for that commit. The helper inspects the candidate index Git gives the hook.

`git commit -- <paths>` takes the selected paths' **working-tree content**, even if their staged content differs; another path's staged change is preserved for a later commit. It does not select only previously staged hunks. Review the working-tree diff before using it. [Git's commit documentation](https://git-scm.com/docs/git-commit) describes these modes.

## Verify

Run `bash shared-index/test-shared-index-warn.sh` or `bash ACCEPTANCE`. Fresh synthetic repositories exercise initial, mixed, single, `-a`, amend, nearest-owner, neutral, unusual-filename, inspection-failure and pathspec cases. The pathspec case deliberately uses different staged and working-tree text, reads back the commit, and checks the preserved staged change. Every assertion must run; there are no skips.

Scratch directories use `mktemp -d` under `${TMPDIR:-/tmp}` and are cleaned on exit. That location must permit executable Git hooks. The test hook calls the exported helper directly; it needs no external installation.
