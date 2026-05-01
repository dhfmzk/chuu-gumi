---
name: curate
description: Use when visual style direction, reference candidates, selected-reference analysis, style memory, Style Contract drafts, or contract revisions are needed before or after asset production.
---

# Curate

## Overview

Use `curate` to maintain the evolving style baseline. This is not a one-way pipeline. It creates reference batches, waits for user selection, extracts reusable style atoms, drafts or revises Style Contracts, and accepts feedback from `craft` when generated assets reveal drift or contract gaps.

`curate` owns style decisions. `craft` may report evidence, but it must not rewrite the Style Contract.

Use the currently available Codex image-generation capability for reference candidate generation. Record the generation tool and model when the environment reports them. Do not assert a specific model name when it is not exposed. Do not hand-author SVG, vector, HTML/CSS, canvas, or other code-native placeholders as reference candidates. If image generation is unavailable or fails, return the blocked manifest described below instead of inventing image outputs.

## State Model

When the repository is writable, store durable workflow state under `artifacts/` unless the user asks for an inline-only run. Read `artifacts/state.yaml` before changing state when it exists, and create or update it after each state transition.

```text
artifacts/state.yaml
artifacts/style/
  references/   Reference Manifests and selected-reference notes
  atoms/        Style Atom Ledgers
  contracts/    Style Contract drafts and approved versions
  decisions/    user approvals, rejected directions, and revision notes
```

Never overwrite an approved contract in place. Create a new draft version, ask for approval, then mark the new version approved only after explicit user approval.

Use the naming and promotion rules in `docs/schemas.md` when writing durable artifacts.

## State Transitions

`curate` may move the state through these phases:

- `idle -> exploring`: user asks for style exploration.
- `exploring -> selecting`: Reference Manifest exists and user must choose candidate IDs.
- `selecting -> analyzing`: user selected candidate IDs.
- `analyzing -> contract_draft`: Style Atom Ledger exists and a contract draft is ready.
- `contract_draft -> contract_approved`: user explicitly approved the draft.
- `feedback -> analyzing`: craft feedback needs style analysis; read `workflow_state.active_feedback_packet` first when durable state is in use.
- Any phase -> `blocked`: image generation or required inputs are unavailable.

Set `pending_user_action` whenever the next step requires the user: `select_references`, `approve_contract`, `revise_contract`, or `approve_feedback_resolution`.

## Operating Modes

### 1. Explore References

1. Restate the user's visual intent, constraints, and any provided references.
2. Do not invent project names, genre labels, style names, output paths, or lore.
3. Define 3-5 exploration axes from the user's words, such as color, shape language, rendering, composition, or detail density.
4. Use the available Codex image-generation capability to create a broad reference batch.
5. Assign stable IDs like `R01`, `R02`, `R03`.
6. Create a `reference_manifest` with file paths or attachment labels, short reads, strengths, risks, and recommended use.
7. If using durable state, write `artifacts/style/references/RB-####.yaml` and update `artifacts/state.yaml` to `current_phase: selecting`.
8. Return the manifest and ask the user to choose candidate IDs.
9. Stop. Do not analyze deeply or write the Style Contract until the user selects references.

If image generation is unavailable or the generation call fails, produce the prompt matrix and a blocked manifest using `generation_status: blocked`, then tell the user that generation is blocked by image tooling availability or failure. SVG, vector, HTML/CSS, canvas, or code-authored assets are not substitutes for generated reference candidates. Do not invent image paths, visual reads, strengths, risks, or QA results for images that were not generated.

### 2. User Selection Gate

Selection is a human checkpoint. The agent may recommend candidates, but the user chooses which references enter the contract.

Accept selection in forms like:

```text
R02, R05, R07
```

If the user asks the agent to choose, return recommended IDs and ask the user to confirm the exact candidate IDs. Do not enter Pass 2 until the user confirms the selection.

### 3. Study Selected References

1. Load only the selected references and their manifest entries.
2. Analyze observable visual traits: composition, color behavior, shape language, rendering treatment, material cues, detail density, camera/framing, and recurring avoidances.
3. Separate style rules from subject matter. A selected image's object, character, outfit, or scene content is not automatically a style rule.
4. Produce `style_atoms` before drafting a contract. A style atom is a small, reusable visual rule with evidence.
5. If using durable state, write `artifacts/style/atoms/SA-####.yaml`.
6. Mark uncertain interpretations as hypotheses and ask the user to confirm only when the uncertainty changes future generation.

### 4. Draft Or Revise Style Contract

1. Read `references/contracts.md`.
2. If no approved contract exists, create a draft Style Contract.
3. If an approved contract exists, create a new draft revision that cites the prior `contract_id` and the evidence that justifies the change.
4. Set `approval_status: draft`.
5. If using durable state, write `artifacts/style/contracts/SC-####.draft.yaml` and update `artifacts/state.yaml` to `current_phase: contract_draft`.
6. Ask the user to approve, reject, or revise the draft.
7. After explicit user approval, write a corresponding `SC-####.approved.yaml`, set `approval_status: approved`, `approved_by`, and `approved_at`, and update `artifacts/state.yaml` to `current_phase: contract_approved`.
8. Do not send work to `craft` until the relevant contract version is approved.

### 5. Absorb Craft Feedback

Use this mode when `craft` returns `next_step_recommendation: return_to_curate`, style drift, or a contract gap.

1. Read the Generation Manifest and any Style Feedback Packet. If using durable state, load the packet from `artifacts/state.yaml` `workflow_state.active_feedback_packet`.
2. Classify the issue as one of:
   - `subject_prompt_issue`: the requested asset was misunderstood; keep the contract unchanged.
   - `generation_quality_issue`: the output failed mechanically; keep the contract unchanged.
   - `style_drift`: the output violated existing rules; add a clearer QA check or prompt negative.
   - `contract_gap`: the contract lacks a rule needed for future assets; draft a contract revision.
3. Ask the user before converting craft feedback into a contract change.
4. Preserve the feedback as a decision record even when no contract change is made.
5. If using durable state, update `artifacts/state.yaml` to `analyzing`, `contract_draft`, or `contract_approved` depending on the chosen resolution.

## Output Rules

- Keep long image-generation logs out of the main response.
- Prefer concise manifests over raw prompt dumps.
- Use stable candidate IDs across all follow-up turns.
- Preserve user language in summaries when practical.
- Do not claim a generated image exists unless the image tool returned it.
- Do not create SVG, vector, HTML/CSS, canvas, or code-native placeholder files as reference candidates.
- Do not silently change the user's chosen references.
- Do not treat generated asset QA as a style rule without user approval.
- Keep a visible version trail for every approved Style Contract.

## GPT-5.5 Prompting Shape

State the desired state transition first, then evidence, constraints, and checkpoint. For example:

```text
Outcome: create a new reference batch and update style memory only after user selection.
Evidence: use the user's visual intent and any provided references.
Image generation: use the available Codex image-generation capability; record the tool and model only when reported; do not use SVG or code-authored substitutes; if unavailable or failed, return generation_status: blocked.
Constraints: use only the user's stated visual intent; do not invent a project, genre, or style name.
Checkpoint: stop after the manifest and wait for selected candidate IDs.
```

## References

- Read `references/contracts.md` when writing a Reference Manifest, Style Atom Ledger, Style Contract, Decision Record, or feedback classification.
- Read `docs/schemas.md` when writing durable artifacts or updating `artifacts/state.yaml`.
- Read `docs/architecture.md` when the user asks about the overall system design.
