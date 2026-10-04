# agent-workbench

Two small tools from a solo operator running AI coding agents. The coverage checker tells you when an instruction you rely on no longer appears in the files you edited; it checks literal text, not whether the instruction is loaded or followed. The shared-index warning warns when one commit is about to include changes from two different writers' directories in a shared working tree, such as two agents staging in one checkout. [The case study](case-study.md) gives archived size measurements and the failures that shaped the coverage checker.

## Run the example

```bash
git clone https://github.com/agentcowboy/agent-workbench.git && cd agent-workbench && bash ACCEPTANCE
```

After cloning, acceptance needs no network or credentials. It checks three synthetic protections, removes one anchor in a temporary copy to prove failure, restores it, and rejects a duplicate handle. It also runs the shared-index tests through real hooks in fresh synthetic Git repositories. Success prints six lines ending in `ACCEPTANCE PASS`; any failed assertion exits nonzero. It works from another working directory and does not modify the checkout.

Requirements: Python 3.7+ (standard library only), Bash, Git 2.32+ (the tests isolate Git config with `GIT_CONFIG_GLOBAL`), and coreutils. The temporary location `${TMPDIR:-/tmp}` must permit executing Git hooks. No package installation is required.

## Use the tools

```bash
python3 coverage/protection-coverage-check.py
python3 coverage/protection-coverage-check.py --manifest coverage/protection-coverage-manifest.json --corpus coverage/protection-corpus.md
bash shared-index/test-shared-index-warn.sh
```

The manifest maps each corpus handle to one or more literal anchors. Relative anchor paths resolve against the manifest's directory. A protection passes when any anchor has readable matching text and an allowed provenance label: `active-rule`, `active-skill`, or `cold-incident`. Duplicate or unmatched handles fail; exit codes are 0 when every protection has at least one present anchor, 1 for an orphan or inventory mismatch, and 2 for an input error. The corpus contains scenario descriptions, with no second copy of the anchor declarations. Handle headings allow up to three leading spaces before `###`, followed by one or more spaces or tabs, a handle matching `[a-z0-9][a-z0-9-]*`, and optional trailing spaces or tabs; CRLF line endings are accepted. Malformed `###` headings are input errors; other heading levels are ignored. Replace the synthetic fixtures with your own inventory to use the checker on real instructions; invoke it manually or wire it into your own checks.

See [shared-index setup and commit advice](shared-index/README.md) before installing the advisory helper.

## Limits and alternatives

Anchor present ≠ loaded ≠ obeyed. Literal rewording can break an anchor; unchanged wording can survive while its meaning or use changes. Provenance labels are declarations, not verified source classifications. Acceptance tests the mechanics of the tools, not agent adherence or the historical inventory.

The warning classifies directory names, not authorship. It neither blocks commits nor reserves files, and cannot detect two writers changing the same file or area. Mixed-owner merges may warn. Inspection failure warns and exits zero.

Nearby tools address broader needs: [agnix](https://github.com/agent-sh/agnix) validates agent configuration; [promptfoo](https://github.com/promptfoo/promptfoo) evaluates prompts and outputs; [agentlocks](https://github.com/simke9445/agentlocks) provides advisory file locks and commit coordination. Separate [Git worktrees](https://git-scm.com/docs/git-worktree) avoid sharing an index. These are alternatives to consider when a literal check or directory warning is insufficient.

## Maintenance

This is a small, best-effort release. Re-run `bash ACCEPTANCE` after changing either tool, and review anchor mappings whenever instructions change. No scheduled checks or support commitment are bundled. Adapting it to your own setup is up to you.

v0.1.1: a `###` heading that isn't a valid handle is now an input error (exit 2) instead of being ignored, and headings with trailing or up to three leading spaces are recognised.

v0.1.2: shared-index tests isolate caller Git environment, warnings ignore diff config, and malformed manifest entries are input errors (exit 2).

Built with AI coding agents; tested as described in ACCEPTANCE.

MIT licensed; see [LICENSE](LICENSE).
