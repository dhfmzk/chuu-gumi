# Workflow Artifacts

This directory is the optional durable state store for the cyclic visual asset
workflow. Use it when the user wants decisions, contracts, feedback, and QA
results preserved across turns or sessions.

`state.yaml` is the current-state pointer. It stores the active phase and paths
to current artifacts, including the active feedback packet during feedback
loops. Do not embed full artifact bodies in `state.yaml`.

## Layout

```text
artifacts/
  state.yaml
  style/
    references/    Reference Manifests and selected-reference analysis
    atoms/         Style Atom Ledgers
    contracts/     Style Contract drafts and approved versions
    decisions/     user approvals, rejected directions, and feedback resolutions
  assets/
    briefs/        Asset Briefs
    generations/   prompt packages and Generation Manifests
    qa/            QA Records and Style Feedback Packets
    feedback/      Style Feedback Packets for curate
```

## Rules

- Keep approved Style Contracts immutable. Create a new draft version for
  revisions.
- Use the naming patterns in `docs/schemas.md`.
- Record user selection and approval decisions explicitly.
- Keep style rules separate from asset subject matter.
- Route contract gaps and style drift from `craft` back to `curate`.
- Do not invent project names, genre labels, style names, lore, output paths, or
  asset taxonomies to make records feel complete.
