---
name: init-shared-squad
description: Set up Squad in the current repository and link it to a shared Squad configuration repository (team decisions, routing, wisdom, casting policy, and skills) using `squad upstream`. Use when the user asks to set up, initialize, onboard, or connect a shared/team/org Squad, or to use Squad config from another repository or branch.
---

# Initialize a shared Squad

Link the current git repository to a shared Squad configuration so the whole team inherits the same decisions, routing, wisdom, casting policy, and skills without copying `.squad/` around.

The setup is performed by a script in the `scripts/` directory next to this `SKILL.md`. Always use the script instead of running the steps by hand; it is idempotent and safe to re-run.

## 1. Determine the options

| Option | Default | When to change |
|--------|---------|----------------|
| Source | `https://github.com/joshjohanning-org/squad-shared-config.git` | The user names a different shared config repo URL. Use `self` when the shared config lives on a branch of **this** repository. |
| Ref | `main` | The user names a branch or tag, for example a `squad-config` branch in the same repo. |
| Name | `shared` | The user wants a different upstream name, or is adding a second upstream. |
| No workflows | off | The user does not want Squad's GitHub Actions workflows added. |

Use the defaults unless the user specified otherwise. Do not ask for confirmation just to accept defaults.

## 2. Run the script from the repository root

On macOS or Linux:

```bash
bash <skill-dir>/scripts/setup-shared-squad.sh [--source <url|self>] [--ref <branch>] [--name <name>] [--no-workflows]
```

On Windows:

```powershell
pwsh -NoProfile -File <skill-dir>/scripts/setup-shared-squad.ps1 [-Source <url|self>] [-Ref <branch>] [-Name <name>] [-NoWorkflows]
```

Replace `<skill-dir>` with the absolute path of the directory containing this `SKILL.md`. If `pwsh` is unavailable on Windows, use `powershell` instead.

The script:

1. Verifies the `squad` CLI is installed and the working directory is inside a git repository.
2. Runs `squad init` if `.squad/` does not exist.
3. Runs `squad upstream add` (skipped if an upstream with that name already exists).
4. Runs `squad upstream sync` to clone or update the shared config into `.squad/_upstream_repos/<name>/` (gitignored).
5. Writes `.github/instructions/squad-upstream.instructions.md`, which tells the Squad coordinator to load the inherited content at session start.
6. Runs `squad doctor`.

## 3. Handle failures

- **`squad` not installed**: show the install commands printed by the script and stop. Do not install software without the user's approval.
- **Not a git repository**: tell the user to run from inside a repository.
- **Clone or sync fails**: the repository may be private or the URL wrong. Suggest checking `gh auth status`, repository access, or an SSH URL (`git@github.com:owner/repo.git`).
- **Existing upstream points elsewhere**: report the warning; only run `squad upstream remove <name>` if the user asks.

## 4. Report back

Summarize briefly:

- The upstream name, source, and ref that are now configured.
- Files to review and commit: `.squad/` (including `upstream.json`), `.gitignore`, and `.github/instructions/squad-upstream.instructions.md`. Do not commit unless the user asks.
- Next step: start a new session with `copilot --agent squad`.
- To pull future shared config changes: `squad upstream sync`, then start a new session.
