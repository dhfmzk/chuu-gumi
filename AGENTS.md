# chuu-gumi Agent Instructions

This repository is intended to work project-locally. Do not install or copy these
skills into global agent directories unless the user explicitly asks for that.

## Local Skill Routing

When the user asks for `curate`, `$curate`, "use curate", or a style-reference
curation workflow:

1. Read `.agents/skills/curate/SKILL.md`.
2. Follow it as the active workflow.
3. Load files under `.agents/skills/curate/references/` only when the skill asks for
   them or the task needs their schema.

When the user asks for `craft`, `$craft`, "use craft", or asset production from
an approved Style Contract:

1. Read `.agents/skills/craft/SKILL.md`.
2. Follow it as the active workflow.
3. Load files under `.agents/skills/craft/references/` only when the skill asks for
   them or the task needs their schema.

## Cyclic System

This workflow is cyclic, not a one-way pipeline. `artifacts/state.yaml` is the current-state pointer.

```text
curate -> user selection -> style atoms -> Style Contract
craft -> generated candidates -> QA -> accept/regenerate/return to curate
```

Use `artifacts/` when state should persist:

- `artifacts/state.yaml` for current phase, current contract, active batches,
  active feedback, and pending user action.
- `artifacts/style/` for reference manifests, style atoms, contracts, and
  decisions.
- `artifacts/assets/` for asset briefs, generation manifests, QA records, and
  style feedback packets.

Use `.codex/agents/*.toml` only when the user explicitly asks for subagents,
parallel review, or delegated specialist work.

## Operating Rules

- Treat `curate` and `craft` as repo-local workflows, not global installed
  skills.
- Keep the user's wording for project, work, genre, and style. Do not invent
  names, genres, style labels, lore, output paths, or asset taxonomies.
- Use GPT Image 2 as the default image-generation capability when a workflow
  reaches an image-generation step. If GPT Image 2 is unavailable in the current
  Codex environment, follow the blocked manifest behavior in the relevant skill.
- `curate` must stop after the Reference Manifest and wait for user-selected
  candidate IDs.
- `craft` must refuse to run unless the Style Contract is approved with
  `approval_status: approved`, `approved_by`, and `approved_at`.
- `craft` must send style drift and contract gaps back to `curate`; it must not
  revise the Style Contract itself.
- Approved Style Contracts are immutable. Revisions are new draft versions until
  explicitly approved by the user.
- Follow `docs/schemas.md` for artifact filenames, phase values, and promotion
  rules.
- Use `docs/validation.md` when checking whether the system behaves as designed.
