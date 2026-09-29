---
name: init-starter-team
description: "Approach B (starter team copy): lay down a pre-built base Squad team (lead, developer, tester, reviewer, security, docs) in a repository by running `squad init` and copying the bundled team roster, charters, routing, and casting registry. Use when the user asks to set up, initialize, or bootstrap a starter/base/default Squad team in a repo. Each repo gets its own independent copy; nothing stays linked to a shared repo."
---

# Initialize a starter Squad team

Copy a pre-built base team into a git repository so the user starts with a ready-to-use Squad instead of an empty roster. After setup the repository owns its team and can customize it freely; nothing stays linked to this plugin or any shared repo.

The team template is in `team-template/.squad/` next to this `SKILL.md`. The copy is done by a script in the `scripts/` directory. Always use the script instead of copying files by hand.

## 1. Determine the target repository

Ask the user which repository folder to set up, unless they already said. Offer the current working directory's repository as the default. The target must be inside a git repository; the script sets up the repository root.

Options:

| Option | Default | When to change |
|--------|---------|----------------|
| Target | current directory | The user names another folder or repository path. |
| Force | off | The repository already has `.squad/` and the user confirms they want its team roster, charters, routing, and casting registry overwritten. Never set this without explicit confirmation. |
| No workflows | off | The user does not want Squad's GitHub Actions workflows added. |

## 2. Run the script

On macOS or Linux:

```bash
bash <skill-dir>/scripts/init-starter-team.sh [--target <path>] [--force] [--no-workflows]
```

On Windows:

```powershell
pwsh -NoProfile -File <skill-dir>/scripts/init-starter-team.ps1 [-Target <path>] [-Force] [-NoWorkflows]
```

Replace `<skill-dir>` with the absolute path of the directory containing this `SKILL.md`. If `pwsh` is unavailable on Windows, use `powershell` instead.

The script:

1. Verifies the `squad` CLI is installed and the target is inside a git repository.
2. Stops if `.squad/` already exists (exit code 3), unless `--force` is set.
3. Runs `squad init` to create the Squad scaffolding (coordinator agent file, system agents, templates, MCP config).
4. Copies the starter team on top: `team.md`, `routing.md`, `casting/registry.json`, and charters for `lead`, `developer`, `tester`, `reviewer`, `security`, and `docs`, filling in the project name and date.
5. Runs `squad doctor`.

## 3. Handle failures

- **`squad` not installed**: show the install commands printed by the script and stop. Do not install software without the user's approval.
- **Not a git repository**: tell the user to run `git init` in the folder or choose another folder.
- **Squad already exists (exit code 3)**: tell the user, and ask whether to overwrite the team files with `--force`. Mention that decisions, history, and other state are not touched.

## 4. Report back

Summarize briefly:

- The repository that was set up and the team members added.
- Files to review and commit: `.squad/`, `.github/agents/squad.agent.md`, `.gitignore`, and any other files `squad init` created. Do not commit unless the user asks.
- Next step: start a new session with `copilot --agent squad`.
- The team is now independent: edit charters or add members directly in this repository.
