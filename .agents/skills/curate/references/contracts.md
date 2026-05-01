# Curate Contracts

## Style State Index

Use `artifacts/state.yaml` as the durable map of the current style system. Keep it compact and store paths, not full artifacts.

```yaml
workflow_state:
  schema_version: "1"
  current_phase: "idle | exploring | selecting | analyzing | contract_draft | contract_approved | crafting | qa | feedback | blocked"
  current_contract: "<path to approved contract or null>"
  current_style_atoms: "<path to Style Atom Ledger or null>"
  active_reference_batch: "<path to Reference Manifest or null>"
  active_asset_batch: "<path to Generation Manifest or null>"
  active_feedback_packet: "<path to Style Feedback Packet or null>"
  pending_user_action:
    type: "none | select_references | approve_contract | revise_contract | select_asset | approve_feedback_resolution"
    prompt: "<what the user must decide or null>"
  last_updated_by: "<agent or user label>"
  last_updated_at: "<ISO-8601 timestamp>"
```

## Reference Manifest

Use this after reference exploration. Keep it compact enough for the main Codex session. Use GPT Image 2 for generated reference candidates. When GPT Image 2 generation is blocked before any image output exists, set `generation_status: blocked`, write `blocking_reason`, and use `candidates: []`.

```yaml
reference_manifest:
  batch_id: "<stable batch id>"
  generation_status: "generated | blocked"
  blocking_reason: "<required when generation_status is blocked>"
  source_intent: "<brief restatement of the user's request>"
  candidates:
    - id: "R01"
      file: "<image path, attachment label, tool output id, or null when blocked>"
      short_read: "<one sentence visual read; omit when blocked>"
      strengths:
        - "<why this candidate may be useful>"
      risks:
        - "<why this candidate may not fit>"
      recommended_for:
        - "<what aspect this candidate helps evaluate>"
  agent_recommendation:
    preferred_ids:
      - "R02"
    reason: "<brief reason>"
  user_selection_required: true
```

## Style Atom Ledger

Use this after the user selects references and before drafting or revising a Style Contract.

```yaml
style_atom_ledger:
  ledger_id: "<stable ledger id>"
  source_reference_batch_id: "<reference_manifest.batch_id>"
  selected_reference_ids:
    - "R02"
  atoms:
    - id: "S01"
      rule: "<small reusable visual rule>"
      evidence:
        - reference_id: "R02"
          observation: "<visible trait supporting the rule>"
      confidence: "high | medium | low"
      applies_to:
        - "<asset type or broad condition, only if user supplied or evident>"
      does_not_imply:
        - "<subject matter that should not become a style rule>"
  hypotheses:
    - id: "H01"
      statement: "<uncertain interpretation>"
      needs_user_confirmation: true
```

## Style Contract

Use this after selected-reference study. Do not require project name, genre, style name, or asset taxonomy.

```yaml
style_contract:
  contract_id: "<stable contract id>"
  contract_version: "<date or increment>"
  supersedes_contract_id: "<prior approved contract id or null>"
  source_reference_batch_id: "<reference_manifest.batch_id>"
  source_style_atom_ledger_id: "<style_atom_ledger.ledger_id>"
  approval_status: "draft | approved"
  approved_by: "<user identifier or null while draft>"
  approved_at: "<ISO-8601 timestamp or null while draft>"
  selection_mode: "user_selected"
  selected_references:
    - id: "R02"
      file: "<image path, attachment label, or tool output id>"
      role: "<why this reference is part of the contract>"
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

## Style Feedback Packet

Use this when `craft` returns evidence that may affect style memory or a contract revision.

```yaml
style_feedback_packet:
  feedback_id: "<stable id>"
  source_generation_batch_id: "<generation_manifest.batch_id>"
  style_contract_id: "<contract used by craft>"
  classification: "subject_prompt_issue | generation_quality_issue | style_drift | contract_gap"
  evidence:
    - candidate_id: "A01"
      observation: "<what happened>"
      related_contract_check: "<existing check or null>"
  recommended_curate_action: "no_contract_change | add_qa_check | revise_prompt_negative | draft_contract_revision"
  requires_user_approval: true
```

## Decision Record

Use this for approvals, rejected directions, selected references, and contract revision decisions.

```yaml
decision_record:
  decision_id: "<stable id>"
  decided_at: "<ISO-8601 timestamp>"
  decided_by: "<user identifier>"
  decision_type: "reference_selection | contract_approval | revision_request | direction_rejection | feedback_resolution"
  summary: "<short decision>"
  affected_ids:
    - "<reference batch, contract, feedback, or generation id>"
  rationale: "<why this decision was made>"
```

## Analysis Discipline

- Write only traits visible in selected references or explicitly requested by the user.
- Emit `approval_status: draft` until the user explicitly approves the contract.
- Set `approval_status: approved` only after explicit user approval.
- Preserve prior approved contracts and create a new draft for revisions.
- Use `selection_mode: user_selected`; agent recommendations are not a substitute for user-confirmed candidate IDs.
- Do not write visual reads, strengths, risks, or QA results for blocked image generations.
- Mark uncertain interpretations as hypotheses.
- Keep content and style separate.
- Prefer reusable rules over taste adjectives.
- Do not add names, genres, or world details to make the contract feel complete.
- Treat craft feedback as evidence, not as an automatic style change.
