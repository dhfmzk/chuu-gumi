# Schemas

Use these schemas when writing durable artifacts. Keep artifacts YAML unless the user requests another format.

## Naming

| Artifact | Directory | Pattern |
| --- | --- | --- |
| Reference Manifest | `artifacts/style/references/` | `RB-0001.yaml` |
| Style Atom Ledger | `artifacts/style/atoms/` | `SA-0001.yaml` |
| Style Contract draft | `artifacts/style/contracts/` | `SC-0001.draft.yaml` |
| Style Contract approved | `artifacts/style/contracts/` | `SC-0001.approved.yaml` |
| Decision Record | `artifacts/style/decisions/` | `DR-0001.yaml` |
| Asset Brief | `artifacts/assets/briefs/` | `AB-0001.yaml` |
| Generation Manifest | `artifacts/assets/generations/` | `GB-0001.yaml` |
| QA Record | `artifacts/assets/qa/` | `QA-0001.yaml` |
| Style Feedback Packet | `artifacts/assets/feedback/` | `FB-0001.yaml` |

Increment IDs by reading existing artifact filenames. Do not reuse IDs.

## State Pointer

`artifacts/state.yaml` is the only current-state pointer when durable state exists. Create it on the first durable workflow transition if it is missing. It should reference artifact paths, not embed full artifacts.

```yaml
workflow_state:
  schema_version: "1"
  current_phase: "idle | exploring | selecting | analyzing | contract_draft | contract_approved | crafting | qa | feedback | blocked"
  current_contract: "artifacts/style/contracts/SC-0001.approved.yaml | null"
  current_style_atoms: "artifacts/style/atoms/SA-0001.yaml | null"
  active_reference_batch: "artifacts/style/references/RB-0001.yaml | null"
  active_asset_batch: "artifacts/assets/generations/GB-0001.yaml | null"
  active_feedback_packet: "artifacts/assets/feedback/FB-0001.yaml | null"
  pending_user_action:
    type: "none | select_references | approve_contract | revise_contract | select_asset | approve_feedback_resolution"
    prompt: "<what the user must decide or null>"
  last_updated_by: "<agent or user label>"
  last_updated_at: "<ISO-8601 timestamp>"
```

## Promotion Rules

- Reference candidates become selected evidence only after user-selected IDs.
- Selected evidence becomes style atoms before it becomes a Style Contract.
- A draft Style Contract becomes approved only after explicit user approval.
- A generated asset QA finding becomes a Style Feedback Packet, not a contract change.
- A Style Feedback Packet becomes a draft contract revision only through `curate`.
- Approved contracts are immutable. Revisions create new draft files.

## Required Cross References

- `style_contract.source_reference_batch_id` must match a Reference Manifest.
- `style_contract.source_style_atom_ledger_id` must match a Style Atom Ledger.
- `generation_manifest.style_contract_id` and `style_contract_version` must match the approved contract used.
- `qa_record.generation_batch_id` must match a Generation Manifest.
- `style_feedback_packet.source_generation_batch_id` must match a Generation Manifest.
- `workflow_state.active_feedback_packet` must point to a Style Feedback Packet whenever `current_phase` is `feedback`.
- `decision_record.affected_ids` should include every artifact changed by the user decision.
