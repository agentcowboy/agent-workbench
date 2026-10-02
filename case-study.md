# Smaller instructions, narrower claims

A solo operator running AI coding agents trimmed an instruction set and used a protection inventory to watch for missing guidance. This account reports archived measurements of anonymised surfaces, not fresh measurements of today's instructions. The runnable [coverage demo](coverage/protection-corpus.md) uses three synthetic protections; the [acceptance run](ACCEPTANCE) tests tool mechanics.

## Archived byte measurements

| Anonymised surface | Before | After | Saved | Reduction |
|---|---:|---:|---:|---:|
| Boot document | 15,841 B | 8,431 B | 7,410 B | **46.8%** |
| Operating document | 20,078 B | 11,327 B | 8,751 B | 43.6% |
| Local rules | 23,423 B | 17,094 B | 6,329 B | 27.0% |
| Per-turn helper, separate from boot | 4,205 B | 950 B | 3,255 B | 77.4% |

Local rules here means always-on local rules; path-scoped rules are excluded. The per-turn helper is separate from boot. These byte reductions do not measure behavioural equivalence or agent reliability.

There were 43 protections at the trim and 42 in the current private inventory. A later rule consolidation renamed two entries and removed one scenario about dispatching a complete delegated task rather than fragmenting it. The old source rule was retired as routing guidance was merged. This is a later inventory change, not proof that every historical protection remains semantically covered. The public demo's three synthetic protections are a separate inventory.

## Current rule excerpts

These are real excerpts from the operator's rule set, in its current wording. They are not historical before/after examples. The completion excerpt ends at a sentence boundary; `…` marks omitted text.

**Tested rollback — excerpt from the operator's rule set:**

> - **Tested rollback:** snapshot every touched surface and run the restore path.
> A dry-run, `--check`, untested backup, or incomplete snapshot is not rollback.

**Completion from the consumer's position — excerpt from the operator's rule set:**

> Scope every `PASS`, `done`, `complete`, `isolated`, `zero-X`, or `all-N` claim.
> Re-derive the full set from the consumer's actual position; enumerate or scan it, exercise the real per-item transaction, and distinguish observed facts from inference.
> State what was seen, where, and by whom; label inference. …

**Credential tripwire — excerpt from the operator's rule set:**

> **Credential tripwire.** For a verification or read, first use the lightest read that proves it:
> a read-only panel or narrow `info`/`get`/status query. Never reset, regenerate, broaden, or elevate a credential for a read;
> if the narrow path cannot prove it, surface that limit rather than reaching for a master credential.

## Where the check failed

The early coverage net was vacuously green: it checked nothing in the surfaces being trimmed. Later, the checker drifted to 40/42. It was not wired to any hook, and its anchors were literal strings; rewording broke those matches. A passing check could not establish that an instruction was loaded or followed.

Anchor present ≠ loaded ≠ obeyed.

The public checker therefore calls its result a present text anchor check. Its negative control removes only one anchor's text while keeping valid provenance, requires the named orphan and `2/3`, then restores `3/3`. A separate duplicate-handle control checks the inventory mapping. Before another trim, update that mapping, run the checks, and assess behaviour separately; a green text check alone is insufficient.
