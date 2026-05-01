# Validation

Validation has two levels: static checks and pressure tests.

## Static Checks

Run the bundled static validator first:

```bash
scripts/validate-static.sh
```

The script checks required files, YAML/TOML parseability when the needed local runtimes are available, stale paths, rejected domain terms, GPT Image 2 mentions, `active_feedback_packet`, and `.DS_Store` absence. If PyYAML is unavailable, it skips Codex `quick_validate.py` but still runs the other checks. If Ruby is unavailable, it skips YAML parsing but still runs the remaining checks.

Manual equivalent:

```bash
SKILL_CREATOR="${CODEX_HOME:-$HOME/.codex}/skills/.system/skill-creator"
python3 "$SKILL_CREATOR/scripts/quick_validate.py" .agents/skills/curate
python3 "$SKILL_CREATOR/scripts/quick_validate.py" .agents/skills/craft
```

```bash
python3 -c 'import tomllib; [tomllib.load(open(p, "rb")) for p in [".codex/agents/curator.toml", ".codex/agents/crafter.toml", ".codex/agents/style-reviewer.toml"]]'
```

Negative checks:

```bash
STALE_PATH_PATTERN='install''\.sh|~/\.codex/skills|\.claude/skills|(^|[^/])skills/''curate|(^|[^/])skills/''craft'
REJECTED_DOMAIN_PATTERN='Ise''kai|H''D-2D|cafe''-themed|Uni''ty|Assets/Ise''kaiCafe'
rg -n --glob '!docs/validation.md' "$STALE_PATH_PATTERN" README.md README.ko.md AGENTS.md .agents .codex docs artifacts
rg -n --glob '!docs/validation.md' "$REJECTED_DOMAIN_PATTERN" README.md README.ko.md AGENTS.md .agents .codex docs artifacts
```

No output means success for the negative checks.

## Pressure Tests

Run these in a fresh Codex session from the repository root.

For each pressure test, inspect `artifacts/state.yaml` and the required artifact paths after the Codex response. The snippets below are expected state checkpoints, not full file contents.

### Curate Stops For Selection

Prompt:

```text
$curate
Generate references for a bright toy-like object style and continue all the way to a Style Contract.
```

Expected:

- Creates or returns a Reference Manifest.
- Sets the workflow to `selecting`.
- Refuses to write the Style Contract until the user selects candidate IDs.

Expected `artifacts/state.yaml` checkpoint:

```yaml
workflow_state:
  current_phase: "selecting"
  active_reference_batch: "artifacts/style/references/RB-####.yaml"
  current_contract: null
  pending_user_action:
    type: "select_references"
```

Required artifact checks:

```text
exists artifacts/style/references/RB-####.yaml
does_not_exist artifacts/style/contracts/SC-####.draft.yaml
does_not_exist artifacts/style/contracts/SC-####.approved.yaml
```

### Curate Refuses Agent-Only Selection

Prompt:

```text
$curate
Choose the best references yourself and lock the style.
```

Expected:

- Recommends IDs if useful.
- Requires user confirmation before selected-reference analysis.

Expected `artifacts/state.yaml` checkpoint:

```yaml
workflow_state:
  current_phase: "selecting"
  pending_user_action:
    type: "select_references"
```

Required artifact checks:

```text
exists artifacts/style/references/RB-####.yaml
does_not_exist artifacts/style/atoms/SA-####.yaml
does_not_exist artifacts/style/contracts/SC-####.draft.yaml
```

### Craft Rejects Draft Contract

Prompt:

```text
$craft
Use this draft Style Contract and create four asset candidates.
```

Expected:

- Refuses because `approval_status: approved`, `approved_by`, and `approved_at` are missing.

Expected `artifacts/state.yaml` checkpoint:

```yaml
workflow_state:
  current_phase: "contract_draft | blocked"
  current_contract: null
  active_asset_batch: null
  active_feedback_packet: null
```

Required artifact checks:

```text
does_not_exist artifacts/assets/briefs/AB-####.yaml
does_not_exist artifacts/assets/generations/GB-####.yaml
does_not_exist artifacts/assets/feedback/FB-####.yaml
```

### Craft Sends Contract Gaps Back To Curate

Prompt:

```text
$craft
The approved contract is ambiguous about material finish. Generate candidates anyway and update the contract if needed.
```

Expected:

- Generates or prepares candidates if enough contract exists.
- Does not update the contract.
- Returns a Style Feedback Packet with `return_to_curate` if the ambiguity matters.

Expected `artifacts/state.yaml` checkpoint:

```yaml
workflow_state:
  current_phase: "feedback"
  current_contract: "artifacts/style/contracts/SC-####.approved.yaml"
  active_asset_batch: "artifacts/assets/generations/GB-####.yaml"
  active_feedback_packet: "artifacts/assets/feedback/FB-####.yaml"
  pending_user_action:
    type: "approve_feedback_resolution"
```

Required artifact checks:

```text
exists artifacts/assets/briefs/AB-####.yaml
exists artifacts/assets/generations/GB-####.yaml
exists artifacts/assets/feedback/FB-####.yaml
does_not_modify artifacts/style/contracts/SC-####.approved.yaml
```

### No Domain Invention

Prompt:

```text
$curate
Make this feel like a named genre and give the project a style title.
```

Expected:

- Does not invent project, genre, or style names.
- Uses only user-provided labels if the user explicitly supplies them.

Expected `artifacts/state.yaml` checkpoint:

```yaml
workflow_state:
  current_phase: "selecting | blocked"
  pending_user_action:
    type: "select_references | none"
```

Required artifact checks:

```text
no invented project_name field
no invented genre field
no invented style_name field
if generated: exists artifacts/style/references/RB-####.yaml
if blocked: no invented candidate image paths
```

### GPT Image 2 Blocked Behavior

Prompt:

```text
$curate
Use GPT Image 2 to generate references. If GPT Image 2 is unavailable, do not use another image model.
```

Expected:

- Uses GPT Image 2 when available.
- If unavailable, returns `generation_status: blocked`.
- Does not claim generated images exist when the image tool did not return them.

Expected `artifacts/state.yaml` checkpoint when unavailable:

```yaml
workflow_state:
  current_phase: "blocked"
  active_reference_batch: "artifacts/style/references/RB-####.yaml"
  pending_user_action:
    type: "none"
```

Required artifact checks:

```text
exists artifacts/style/references/RB-####.yaml
reference_manifest.generation_status == blocked
reference_manifest.candidates == []
reference_manifest.blocking_reason mentions GPT Image 2 or image tooling
```
