#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
}

require_dir() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    echo "Missing required directory: $path" >&2
    exit 1
  fi
}

require_file ".agents/skills/curate/SKILL.md"
require_file ".agents/skills/craft/SKILL.md"
require_file ".agents/skills/curate/agents/openai.yaml"
require_file ".agents/skills/craft/agents/openai.yaml"
require_file ".codex/agents/curator.toml"
require_file ".codex/agents/crafter.toml"
require_file ".codex/agents/style-reviewer.toml"
require_file "artifacts/state.yaml"
require_file "docs/architecture.md"
require_file "docs/schemas.md"
require_file "docs/usage.md"
require_file "docs/validation.md"

require_dir "artifacts/style/references"
require_dir "artifacts/style/atoms"
require_dir "artifacts/style/contracts"
require_dir "artifacts/style/decisions"
require_dir "artifacts/assets/briefs"
require_dir "artifacts/assets/generations"
require_dir "artifacts/assets/qa"
require_dir "artifacts/assets/feedback"

if command -v ruby >/dev/null 2>&1; then
  ruby -e 'require "yaml"; YAML.load_file("artifacts/state.yaml"); Dir[".agents/skills/*/agents/openai.yaml"].each { |p| YAML.load_file(p) }'
else
  echo "ruby not found; skipped YAML parse check" >&2
fi
python3 -c 'import tomllib; [tomllib.load(open(p, "rb")) for p in [".codex/agents/curator.toml", ".codex/agents/crafter.toml", ".codex/agents/style-reviewer.toml"]]'

if find . -name ".DS_Store" -print | grep -q .; then
  echo "Found .DS_Store files" >&2
  find . -name ".DS_Store" -print >&2
  exit 1
fi

if command -v rg >/dev/null 2>&1; then
  STALE_PATH_PATTERN='install''\.sh|~/\.codex/skills|\.claude/skills|(^|[^/])skills/''curate|(^|[^/])skills/''craft'
  REJECTED_DOMAIN_PATTERN='Ise''kai|H''D-2D|cafe''-themed|Uni''ty|Assets/Ise''kaiCafe'
  if rg -n --glob '!docs/validation.md' --glob '!scripts/validate-static.sh' "$STALE_PATH_PATTERN" README.md README.ko.md AGENTS.md .agents .codex docs artifacts scripts; then
    echo "Found stale path references" >&2
    exit 1
  fi
  if rg -n --glob '!docs/validation.md' --glob '!scripts/validate-static.sh' "$REJECTED_DOMAIN_PATTERN" README.md README.ko.md AGENTS.md .agents .codex docs artifacts scripts; then
    echo "Found rejected domain terms" >&2
    exit 1
  fi
else
  echo "rg not found; skipped stale-path and rejected-domain scans" >&2
fi

grep -R "GPT Image 2" README.md README.ko.md AGENTS.md .agents .codex docs >/dev/null
grep -R "active_feedback_packet" artifacts/state.yaml docs .agents >/dev/null

SKILL_CREATOR="${CODEX_HOME:-$HOME/.codex}/skills/.system/skill-creator/scripts/quick_validate.py"
if [[ -f "$SKILL_CREATOR" ]]; then
  if python3 -c 'import yaml' >/dev/null 2>&1; then
    python3 "$SKILL_CREATOR" .agents/skills/curate
    python3 "$SKILL_CREATOR" .agents/skills/craft
  else
    echo "PyYAML not available for quick_validate.py; skipped skill validator" >&2
  fi
else
  echo "Codex skill quick_validate.py not found; skipped skill validator" >&2
fi

echo "Static validation passed"
