---
name: craft
description: Use when asset candidates, prompt packages, generation manifests, style QA, regeneration decisions, or feedback to curate are needed from an approved Style Contract and asset request.
---

# Craft

## Overview

Use `craft` to produce and evaluate asset candidates from an approved Style Contract. `craft` applies the current contract, generates candidates, performs QA, and returns either accepted candidates, regeneration guidance, or feedback for `curate`.

This is a loop, not a terminal production step. `craft` may discover that an asset prompt is weak, the generator drifted, or the Style Contract is underspecified. It reports those findings, but it does not revise the contract itself.

Use the currently available Codex image-generation capability for asset candidate generation. Record the generation tool and model when the environment reports them. Do not assert a specific model name when it is not exposed. If image generation is unavailable or fails, return the blocked manifest described below instead of inventing image outputs.

## Required Inputs

Before generating, confirm these exist:

- An approved Style Contract with `approval_status: approved`, non-empty `approved_by`, and non-empty `approved_at`.
- A user-provided asset request.
- Any hard constraints such as count, view, background, size, transparency, editability, or intended use.

If there is no Style Contract with `approval_status: approved`, non-empty `approved_by`, and non-empty `approved_at`, stop and tell the user to run `curate` first or provide an existing approved contract. Do not approve drafts inside `craft`, mutate approval fields, or invent style rules.

## State Model

When the repository is writable, store durable workflow state under `artifacts/` unless the user asks for an inline-only run. Read `artifacts/state.yaml` before generating when it exists, and create or update it after each state transition.

```text
artifacts/state.yaml
artifacts/assets/
  briefs/       Asset Briefs
  generations/  prompt packages and Generation Manifests
  qa/           style QA notes and feedback packets for curate
  feedback/     Style Feedback Packets
```

Use stable IDs. Link every generation to `style_contract_id`, `style_contract_version`, and `asset_brief_id`.

Use the naming and promotion rules in `docs/schemas.md` when writing durable artifacts.

## State Transitions

`craft` may move the state through these phases:

- `contract_approved -> crafting`: user supplies an asset request.
- `crafting -> qa`: candidates are generated or a prompt package is ready for QA.
- `qa -> contract_approved`: user accepts a candidate and continues with the same contract.
- `qa -> crafting`: regeneration is appropriate within the current contract.
- `qa -> feedback`: style drift or contract gap requires `curate`; set `workflow_state.active_feedback_packet` when durable state is in use.
- Any phase -> `blocked`: image generation or required inputs are unavailable.

Set `pending_user_action` when the next step requires the user: `select_asset` or `approve_feedback_resolution`.

## Workflow

### 1. Brief

Create an Asset Brief from the user's request. Ask a clarification only when a missing field would materially change the generated image. Otherwise state the assumption and continue.

Use `references/contracts.md` for the Asset Brief schema.

If using durable state, write `artifacts/assets/briefs/AB-####.yaml` and update `artifacts/state.yaml` to `current_phase: crafting`.

### 2. Compose

Build the generation instruction from:

1. Style Contract rules.
2. User's asset subject description.
3. Asset Brief constraints.

Keep style and subject separate. The subject description tells the image-generation tool what to make; the Style Contract tells it how the result should look.

### 3. Generate

Use the available Codex image-generation capability. Generate the requested number of candidates, or 3-6 candidates when the user did not specify a count.

If image generation is unavailable or the generation call fails, return the composed prompt package and a blocked manifest using `generation_status: blocked`, then state that generation is blocked by image tooling availability or failure. Do not invent image paths, visual QA, strengths, risks, or recommended edits for images that were not generated.

If using durable state, write `artifacts/assets/generations/GB-####.yaml` and update `artifacts/state.yaml` to `current_phase: qa` when candidates exist or `blocked` when generation is unavailable or failed.

### 4. QA

Check each candidate against the Style Contract. Label each candidate:

- `recommended`: strong fit for the request and contract.
- `usable_with_edits`: useful but needs user cleanup.
- `reference_only`: informative but not suitable as a direct asset candidate.
- `rejected`: violates the contract or request.

Separate failures into:

- `subject_prompt_issue`: candidate does not match the asset request.
- `generation_quality_issue`: artifacting, unusable rendering, or tool failure.
- `style_drift`: candidate violates existing contract rules.
- `contract_gap`: candidate exposes an ambiguity or missing rule in the contract.

If every candidate is rejected for subject or generation quality, regenerate once with a tighter prompt. If the second batch also fails, return the failure manifest and explain which checks are failing.

If the dominant failure is `style_drift` or `contract_gap`, do not keep regenerating blindly. Create a Style Feedback Packet and recommend returning to `curate`.

If using durable state and QA details would clutter the manifest, write `artifacts/assets/qa/QA-####.yaml`.

### 5. Manifest

Return a Generation Manifest with candidate IDs, file paths or attachment labels, QA status, strengths, risks, recommended user edits, and `next_step_recommendation`.

Allowed next steps:

- `user_select`: candidates are ready for user selection.
- `regenerate`: prompt or generation settings should be adjusted within the same contract.
- `edit_candidate`: one or more candidates are usable with edits.
- `return_to_curate`: the Style Contract needs review or revision.
- `blocked`: image generation or required inputs are unavailable.

Keep raw prompt logs out of the main response unless the user asks for them.

If the next step is `return_to_curate`, write `artifacts/assets/feedback/FB-####.yaml` and update `artifacts/state.yaml` to `current_phase: feedback` with `active_feedback_packet` pointing to that file.

## Guardrails

- Do not edit the Style Contract.
- Do not introduce new style names, genre names, project names, or asset taxonomies.
- Do not use the asset subject as a reason to change style rules.
- Do not convert QA findings into new style rules; package them for `curate`.
- Do not claim final production readiness unless the user explicitly requested finalization and the output passed QA.
- Do not modify project files, engine/editor settings, import settings, or runtime assets unless the user explicitly asks for that separate task.

## GPT-5.5 Prompting Shape

State the desired state transition first, then style source, subject, generation count, and QA criteria. For example:

```text
Outcome: produce 4 asset candidates for the user's described object.
Style source: approved Style Contract v3; treat it as read-only.
Subject: use only the user's asset description.
Image generation: use the available Codex image-generation capability; record the tool and model only when reported; if unavailable or failed, return generation_status: blocked.
QA: return candidate IDs, failure class if any, and whether to select, regenerate, edit, or return to curate.
```

## References

- Read `references/contracts.md` before writing an Asset Brief, Generation Manifest, QA Record, or Style Feedback Packet.
- Read `docs/schemas.md` when writing durable artifacts or updating `artifacts/state.yaml`.
- Read `docs/architecture.md` when the user asks about the overall system design.
