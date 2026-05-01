# Usage

Open this repository as the Codex workspace. Codex should discover the project skills under `.agents/skills`.

## Start Style Exploration

```text
$curate
<describe the visual direction>
Generate reference candidates, write/update the Reference Manifest, and stop for my candidate selection.
```

Expected state:

```yaml
current_phase: selecting
pending_user_action:
  type: select_references
```

## Select References

```text
$curate
Use R02, R05, and R07.
Analyze only those selected references, create a Style Atom Ledger, and draft a Style Contract.
```

Expected state:

```yaml
current_phase: contract_draft
pending_user_action:
  type: approve_contract
```

## Approve Contract

```text
$curate
I approve this Style Contract.
```

Expected state:

```yaml
current_phase: contract_approved
current_contract: artifacts/style/contracts/SC-0001.approved.yaml
```

## Generate Assets

```text
$craft
Use the current approved Style Contract.
Asset request: <describe the asset>
Generate candidates and QA them against the contract.
```

Expected state depends on QA:

- `qa` with `pending_user_action: select_asset`
- `crafting` when regeneration is appropriate
- `feedback` when style drift or a contract gap requires `curate`
- `blocked` when image generation is unavailable

Image generation means GPT Image 2 by default. If GPT Image 2 is unavailable in the current Codex environment, expect `current_phase: blocked` and a manifest with `generation_status: blocked`.

## Use Optional Subagents

Use subagents only when explicitly useful:

```text
Spawn one curator agent to review the selected references and one style-reviewer agent to check whether the draft contract invents style rules.
```

Do not use subagents for ordinary `$curate` or `$craft` runs.
