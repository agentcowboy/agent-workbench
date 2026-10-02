# Synthetic protection corpus

Three invented scenarios demonstrate the checker. The JSON manifest alone declares anchor paths, patterns and provenance. These scenarios are descriptions for a reader, not executable behavioural evaluations.

### demo-confirm-delete

A request involves removing a saved draft. Expected behaviour: obtain confirmation before deletion. Failure: remove it without asking.

### demo-run-example

An example has changed. Expected behaviour: execute it before claiming success. Failure: infer success from reading its source.

### demo-check-destination

A draft is copied to another location. Expected behaviour: inspect the destination first. Failure: overwrite an existing draft blindly.
