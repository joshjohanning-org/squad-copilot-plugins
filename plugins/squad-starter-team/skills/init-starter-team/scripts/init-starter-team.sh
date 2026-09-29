#!/usr/bin/env bash
# Lays down a starter Squad team (bundled in ../team-template) in a target
# git repository: runs `squad init`, then copies the team roster, charters,
# routing, and casting registry on top. No link to any shared repo is kept.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$SKILL_DIR/team-template/.squad"
TARGET="$PWD"
FORCE=false
INIT_ARGS=()

usage() {
  cat <<EOF
Usage: init-starter-team.sh [--target <path>] [--force] [--no-workflows]

  --target        Git repository to set up. Default: current directory.
  --force         Overwrite the team files (team.md, routing.md, charters,
                  casting registry) even if the repository already has a squad.
  --no-workflows  Pass --no-workflows to 'squad init' (skip GitHub Actions workflows).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --force) FORCE=true; shift ;;
    --no-workflows) INIT_ARGS+=("--no-workflows"); shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if ! command -v squad >/dev/null 2>&1; then
  echo "ERROR: The 'squad' CLI is not installed. Install it with one of:" >&2
  echo "  npm install -g @bradygaster/squad-cli" >&2
  echo "  brew install --cask bradygaster/squad/squad" >&2
  echo "  winget install --id bradygaster.Squad --exact" >&2
  exit 1
fi

if [[ ! -d "$TARGET" ]]; then
  echo "ERROR: Target directory does not exist: $TARGET" >&2
  exit 1
fi

if ! REPO_ROOT="$(git -C "$TARGET" rev-parse --show-toplevel 2>/dev/null)"; then
  echo "ERROR: $TARGET is not inside a git repository. Run 'git init' there first." >&2
  exit 1
fi
cd "$REPO_ROOT"

echo "==> Repository: $REPO_ROOT"

if [[ -d .squad ]]; then
  if [[ "$FORCE" != true ]]; then
    echo "ERROR: This repository already has a squad (.squad/ exists)." >&2
    echo "       Re-run with --force to overwrite its team roster, charters, routing, and casting registry." >&2
    exit 3
  fi
  echo "==> Squad already initialized; --force set, overwriting team files."
else
  echo "==> Running 'squad init'..."
  squad init ${INIT_ARGS[@]+"${INIT_ARGS[@]}"}
fi

PROJECT_NAME="$(basename "$REPO_ROOT")"
DATE="$(date +%Y-%m-%d)"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
escape_sed() { printf '%s' "$1" | sed 's/[&/\]/\\&/g'; }
PROJECT_NAME_ESC="$(escape_sed "$PROJECT_NAME")"

echo "==> Copying starter team into .squad/..."
(cd "$TEMPLATE_DIR" && find . -type f) | while read -r rel; do
  rel="${rel#./}"
  dest=".squad/$rel"
  mkdir -p "$(dirname "$dest")"
  sed -e "s/{{PROJECT_NAME}}/$PROJECT_NAME_ESC/g" \
      -e "s/{{DATE}}/$DATE/g" \
      -e "s/{{TIMESTAMP}}/$TIMESTAMP/g" \
      "$TEMPLATE_DIR/$rel" > "$dest"
  echo "    $dest"
done

echo "==> Running 'squad doctor'..."
squad doctor || echo "WARNING: 'squad doctor' reported issues (see above)." >&2

echo
echo "Done. Starter team: lead, developer, tester, reviewer, security, docs."
echo "Next steps:"
echo "  1. Review and commit .squad/ and the other files 'squad init' created."
echo "  2. Start a session: copilot --agent squad"
echo "  3. Customize freely - this repo's team is now independent of the template."
