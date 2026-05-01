# Craft Contracts

## State Pointer

Read `artifacts/state.yaml` before using the current approved contract when durable state exists. Create it on the first durable workflow transition if it is missing. Store paths in state, not full artifact bodies.

```yaml
workflow_state:
  current_phase: "contract_approved | crafting | qa | feedback | blocked"
  current_contract: "<path to approved Style Contract>"
  active_asset_batch: "<path to Generation Manifest or null>"
  active_feedback_packet: "<path to Style Feedback Packet or null>"
  pending_user_action:
    type: "none | select_asset | approve_feedback_resolution"
    prompt: "<what the user must decide or null>"
```

## Required Style Contract Fields

`craft` can work with any approved contract that provides enough visual rules to guide generation. Do not require project name, genre, style name, or asset taxonomy.

```yaml
style_contract:
  contract_id: "<stable contract id>"
  contract_version: "<date or increment>"
  supersedes_contract_id: "<prior approved contract id or null>"
  source_reference_batch_id: "<reference_manifest.batch_id>"
  source_style_atom_ledger_id: "<style_atom_ledger.ledger_id>"
  approval_status: "approved"
  approved_by: "<user identifier>"
  approved_at: "<ISO-8601 timestamp>"
  selection_mode: "user_selected"
  selected_references:
    - id: "<reference id>"
      file: "<image path, attachment label, or tool output id>"
      role: "<why this reference matters>"
  visual_rules:
    - "<observable rule to preserve>"
  composition_rules:
    - "<framing, layout, or spatial rule>"
  color_rules:
    - "<palette, contrast, saturation, lighting, or accent rule>"
  shape_language:
    - "<silhouette, proportion, geometry, line, or form rule>"
  rendering_rules:
    - "<texture, material, finish, edge, or detail rule>"
  detail_density:
    summary: "<how much detail is appropriate>"
    simplify_when:
      - "<condition that requires simplification>"
  must_avoid:
    - "<style drift, artifact, or unwanted direction>"
  image_generation_rules:
    prompt_prefix: "<reusable style instruction block>"
    prompt_negative: "<avoidance block>"
    reference_usage: "<how to use selected references when generating>"
  qa_checklist:
    - "<yes/no check for future candidates>"
```

## Asset Brief

Use this before image generation. Fill unknown optional fields only when the user gave enough information. Otherwise omit them or mark an explicit assumption.

```yaml
asset_brief:
  brief_id: "<stable id>"
  source_request: "<short restatement of the user's request>"
  subject:
    description: "<what to generate>"
    required_elements:
      - "<must include>"
    avoid_elements:
      - "<must avoid>"
  generation:
    candidate_count: 4
    transparent_background: "<true | false | unspecified>"
    view: "<front | side | 3/4 | top | unspecified>"
    format_constraints:
      - "<size, aspect, editability, or background constraint>"
  intended_use:
    notes: "<only if user supplied it>"
  assumptions:
    - "<assumption made instead of asking a question>"
```

## Generation Manifest

Use this after image generation and QA. Do not use SVG, vector, HTML/CSS, canvas, or code-authored placeholder files as candidates. When generation is blocked before any image output exists, set `generation_status: blocked`, write `blocking_reason`, and use `candidates: []`.

```yaml
generation_manifest:
  batch_id: "<stable batch id>"
  generation_status: "generated | blocked"
  blocking_reason: "<required when generation_status is blocked>"
  generation_tool: "<tool name when known, or unknown>"
  generation_model: "<model name when reported, or unknown>"
  style_contract_id: "<contract id used>"
  style_contract_version: "<contract version used>"
  asset_brief_id: "<brief id>"
  candidates:
    - id: "A01"
      file: "<image path, attachment label, tool output id, or null when blocked; never a hand-authored SVG/vector/code placeholder>"
      status: "recommended | usable_with_edits | reference_only | rejected"
      failure_class: "none | subject_prompt_issue | generation_quality_issue | style_drift | contract_gap"
      strengths:
        - "<why this candidate works>"
      risks:
        - "<style, usability, or cleanup concern>"
      recommended_user_edits:
        - "<specific edit if useful>"
      failed_checks:
        - "<only for rejected or reference_only candidates>"
  next_step_recommendation: "user_select | regenerate | edit_candidate | return_to_curate | blocked"
```

## QA Record

Use this when detailed QA would clutter the Generation Manifest.

```yaml
qa_record:
  qa_id: "<stable id>"
  generation_batch_id: "<generation_manifest.batch_id>"
  style_contract_id: "<contract id>"
  checks:
    - check: "<contract qa checklist item>"
      result: "pass | fail | uncertain"
      candidate_ids:
        - "A01"
      notes: "<brief observation>"
  aggregate:
    recommended_count: 0
    usable_with_edits_count: 0
    reference_only_count: 0
    rejected_count: 0
  dominant_failure_class: "none | subject_prompt_issue | generation_quality_issue | style_drift | contract_gap"
```

## Style Feedback Packet

Use this only when `next_step_recommendation` is `return_to_curate`.

```yaml
style_feedback_packet:
  feedback_id: "<stable id>"
  source_generation_batch_id: "<generation_manifest.batch_id>"
  style_contract_id: "<contract used by craft>"
  classification: "style_drift | contract_gap"
  evidence:
    - candidate_id: "A01"
      observation: "<visible problem>"
      related_contract_check: "<existing check or null>"
  recommended_curate_action: "add_qa_check | revise_prompt_negative | draft_contract_revision"
  requires_user_approval: true
```

## QA Discipline

- Judge candidates against the approved contract, not against new taste preferences.
- Refuse contracts missing `approval_status: approved`, `approved_by`, or `approved_at`.
- Do not write visual QA, strengths, risks, or recommended edits for blocked image generations.
- Do not use SVG, vector, HTML/CSS, canvas, or code-authored placeholders as generated assets.
- Keep subject errors separate from style errors.
- Prefer concrete visual fixes over vague comments.
- If a candidate suggests the contract is underspecified, return a Style Feedback Packet instead of patching style inside `craft`.
