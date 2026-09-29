#!/usr/bin/env bash
# Sets up Squad in the current git repository and links it to a shared Squad
# config repository via `squad upstream`. Safe to re-run.
set -euo pipefail

DEFAULT_SOURCE="https://github.com/joshjohanning-org/squad-shared-config.git"
SOURCE="${SQUAD_SHARED_SOURCE:-$DEFAULT_SOURCE}"
NAME="${SQUAD_SHARED_NAME:-shared}"
REF="${SQUAD_SHARED_REF:-main}"
INIT_ARGS=()

usage() {
  cat <<EOF
Usage: setup-shared-squad.sh [--source <git-url|self>] [--name <name>] [--ref <branch>] [--no-workflows]

  --source   Git URL of the shared Squad config repo, or "self" to use this
             repo's origin remote (for a config branch in the same repo).
             Default: $DEFAULT_SOURCE
  --name     Upstream name. Default: shared
  --ref      Branch or tag to track. Default: main
  --no-workflows  Pass --no-workflows to 'squad init' (skip GitHub Actions workflows).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) SOURCE="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --ref) REF="$2"; shift 2 ;;
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

if ! REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "ERROR: Run this from inside a git repository." >&2
  exit 1
fi
cd "$REPO_ROOT"

if [[ "$SOURCE" == "self" ]]; then
  if ! SOURCE="$(git remote get-url origin 2>/dev/null)"; then
    echo "ERROR: --source self requires an 'origin' remote." >&2
    exit 1
  fi
fi

echo "==> Repository: $REPO_ROOT"
echo "==> Shared config: $SOURCE (ref: $REF, name: $NAME)"

if [[ -d .squad ]]; then
  echo "==> Squad already initialized; skipping 'squad init'."
else
  echo "==> Running 'squad init'..."
  squad init ${INIT_ARGS[@]+"${INIT_ARGS[@]}"}
fi

UPSTREAM_FILE=".squad/upstream.json"
if [[ -f "$UPSTREAM_FILE" ]] && grep -q "\"name\": \"$NAME\"" "$UPSTREAM_FILE"; then
  echo "==> Upstream '$NAME' already configured; skipping 'squad upstream add'."
  if ! grep -qF "\"source\": \"$SOURCE\"" "$UPSTREAM_FILE"; then
    echo "WARNING: Existing upstream '$NAME' points to a different source. Leaving it unchanged." >&2
    echo "         To change it: squad upstream remove $NAME, then re-run this script." >&2
  fi
else
  echo "==> Adding upstream '$NAME'..."
  squad upstream add "$SOURCE" --name "$NAME" --ref "$REF"
fi

echo "==> Syncing upstreams..."
squad upstream sync

# Squad's Copilot coordinator prompt does not (as of v0.13) load upstream
# content by itself, so add an always-on instruction that tells it to.
INSTRUCTIONS_FILE=".github/instructions/squad-upstream.instructions.md"
mkdir -p "$(dirname "$INSTRUCTIONS_FILE")"
cat > "$INSTRUCTIONS_FILE" <<'EOF'
---
applyTo: "**"
---

# Squad upstream inheritance

This repository inherits shared Squad configuration from the upstreams listed in `.squad/upstream.json`.

At the start of every Squad session, and before spawning or briefing any team member:

1. Read `.squad/upstream.json`. Process upstreams in order; later entries override earlier ones.
2. For each upstream, locate its Squad directory:
   - `git` type: `.squad/_upstream_repos/<name>/.squad/`
   - `local` type: `<source>/.squad/`
3. Load these files from each upstream Squad directory when present:
   - `decisions.md` - shared decisions all members must follow
   - `routing.md` - shared routing rules
   - `identity/wisdom.md` - shared patterns and anti-patterns
   - `casting/policy.json` - casting policy
   - `skills/<skill>/SKILL.md` - shared skills (also check `<upstream root>/.copilot/skills/`)
4. Treat this repository's own `.squad/` files as overrides: when a local decision or rule conflicts with an inherited one, the local one wins.
5. Include the relevant inherited decisions, wisdom, and skills in every team member's context.
6. When greeting the user, list the inherited upstreams and what each provided. If `.squad/_upstream_repos/<name>` is missing, tell the user to run `squad upstream sync`.

Never edit files under `.squad/_upstream_repos/`; change shared configuration through a pull request to the upstream repository.
EOF
echo "==> Wrote $INSTRUCTIONS_FILE"

echo "==> Running 'squad doctor'..."
squad doctor || echo "WARNING: 'squad doctor' reported issues (see above)." >&2

echo
echo "Done. Next steps:"
echo "  1. Review and commit: .squad/ (including upstream.json), .gitignore, $INSTRUCTIONS_FILE"
echo "     (.squad/_upstream_repos/ is gitignored automatically.)"
echo "  2. Start a new session: copilot --agent squad"
echo "  3. Pull shared config updates later with: squad upstream sync"
