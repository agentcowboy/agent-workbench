# agent-workbench v0.1

Two small tools from a solo operator running AI coding agents: a present text anchor checker for instruction edits, and an advisory Git hook helper for a shared index. [The case study](case-study.md) gives archived size measurements and the failures that shaped these tools.

## Run the example

```bash
git clone https://github.com/agentcowboy/agent-workbench.git && cd agent-workbench && bash ACCEPTANCE
```

After cloning, acceptance needs no network or credentials. It checks three synthetic protections, removes one anchor in a temporary copy to prove failure, restores it, and rejects a duplicate handle. It also runs the shared-index tests through real hooks in fresh synthetic Git repositories. Success prints six lines ending in `R1 ACCEPTANCE PASS`; any failed assertion exits nonzero. It works from another working directory and does not modify the checkout.

Requirements: Python 3 (standard library only), Bash, Git, and coreutils. The temporary location `${TMPDIR:-/tmp}` must permit executing Git hooks. No package installation is required.

## Use the tools

```bash
python3 coverage/protection-coverage-check.py
python3 coverage/protection-coverage-check.py --manifest coverage/protection-coverage-manifest.json --corpus coverage/protection-corpus.md
bash shared-index/test-shared-index-warn.sh
```

The manifest maps each corpus handle to one or more literal anchors. Relative anchor paths resolve against the manifest's directory. A protection passes when any anchor has readable matching text and an allowed provenance label: `active-rule`, `active-skill`, or `cold-incident`. Duplicate or unmatched handles fail. The corpus contains scenario descriptions, with no second copy of the anchor declarations. Replace the synthetic fixtures with your own inventory to use the checker on real instructions; invoke it manually or wire it into your own checks.

See [shared-index setup and commit advice](shared-index/README.md) before installing the advisory helper.

## Limits and alternatives

Anchor present ≠ loaded ≠ obeyed. Literal rewording can break an anchor; unchanged wording can survive while its meaning or use changes. Provenance labels are declarations, not verified source classifications. Acceptance tests the mechanics of the tools, not agent adherence or the historical inventory.

The warning classifies directory names, not authorship. It neither blocks commits nor reserves files, and cannot detect two writers changing the same file or area. Mixed-owner merges may warn. Inspection failure warns and exits zero.

Nearby tools address broader needs: [agnix](https://github.com/agent-sh/agnix) validates agent configuration; [promptfoo](https://github.com/promptfoo/promptfoo) evaluates prompts and outputs; [agentlocks](https://github.com/simke9445/agentlocks) provides advisory file locks and commit coordination. Separate [Git worktrees](https://git-scm.com/docs/git-worktree) avoid sharing an index. These are alternatives to consider when a literal check or directory warning is insufficient.

## Maintenance

This is a small, best-effort release. Re-run `bash ACCEPTANCE` after changing either tool, and review anchor mappings whenever instructions change. No scheduled checks or support commitment are bundled. Adapting it to your own setup is up to you.

Built with AI coding agents; tested as described in ACCEPTANCE.

MIT licensed; see [LICENSE](LICENSE).
