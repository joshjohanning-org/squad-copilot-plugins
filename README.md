# squad-copilot-plugins

A [GitHub Copilot CLI plugin marketplace](https://docs.github.com/copilot/how-tos/copilot-cli/customize-copilot/plugins-marketplace) that demonstrates **two different ways** to roll out [Squad](https://github.com/bradygaster/squad) across repositories without zipping and sharing `.squad/` folders.

> [!NOTE]
> This is a proof of concept. Squad is alpha software and its commands may change.

## Which approach do I want?

They solve **different problems** and can be used together.

| | **Approach A: Shared decisions** | **Approach B: Starter team** |
|---|---|---|
| Plugin | [`squad-shared-decisions`](plugins/squad-shared-decisions) | [`squad-starter-team`](plugins/squad-starter-team) |
| Skill | `/link-shared-decisions` | `/init-starter-team` |
| Problem it solves | "Every repo should follow the same decisions and rules" | "Every repo should start with the same team" |
| What's shared | `decisions.md`, `routing.md`, `identity/wisdom.md`, `casting/policy.json`, skills | Team roster (`team.md`), agent charters, routing, casting registry |
| Agents / team shared? | ❌ No. Each repo keeps its own team | ✅ Yes, copied once at init |
| Stays in sync? | ✅ Yes. `squad upstream sync` pulls updates | ❌ No. Each repo diverges after init (by design) |
| Where content lives | A separate Git repo or branch: [squad-shared-decisions](https://github.com/joshjohanning-org/squad-shared-decisions) | Bundled in the plugin: [`team-template/`](plugins/squad-starter-team/skills/init-starter-team/team-template/.squad) |
| Writes back to shared? | ❌ Read-only. Change it through a pull request to the shared repo | N/A |
| Needs Squad's state MCP server? | ❌ No | ❌ No |

Install the marketplace once, then either or both plugins:

```bash
copilot plugin marketplace add joshjohanning-org/squad-copilot-plugins
copilot plugin install squad-shared-decisions@squad-copilot-plugins   # Approach A
copilot plugin install squad-starter-team@squad-copilot-plugins       # Approach B
```

Prerequisites: the [Squad CLI](https://github.com/bradygaster/squad#install) and Git.

---

## Approach A: Shared decisions (`squad-shared-decisions`)

Links a repository **read-only** to a shared repository of Squad decisions and rules, using `squad upstream`.

```text
squad-shared-decisions (repo or branch)       your-app (any repo, any branch)
└── .squad/                                   ├── .squad/
    ├── decisions.md                          │   ├── upstream.json      ← committed pointer
    ├── routing.md        squad upstream sync │   ├── _upstream_repos/   ← gitignored cache
    ├── identity/wisdom.md  ───────────────►  │   └── team.md, agents/…  ← project-local team
    ├── casting/policy.json                   └── .github/instructions/
    └── skills/*/SKILL.md                         └── squad-upstream.instructions.md
```

### Use

From inside any git repository, start Copilot CLI and run `/link-shared-decisions`, or ask naturally:

| Scenario | Prompt |
|----------|--------|
| Default shared decisions repo | `link this repo to the shared squad decisions` |
| Your own shared decisions repo | `link shared squad decisions from https://github.com/my-org/my-squad-decisions.git` |
| Decisions branch in the **same** repo | `link shared squad decisions from the squad-config branch of this repo` |
| Skip Squad's GitHub Actions workflows | `link shared squad decisions without workflows` |

The skill runs [`link-shared-decisions.sh`](plugins/squad-shared-decisions/skills/link-shared-decisions/scripts/link-shared-decisions.sh) (macOS/Linux) or [`link-shared-decisions.ps1`](plugins/squad-shared-decisions/skills/link-shared-decisions/scripts/link-shared-decisions.ps1) (Windows), which:

1. Runs `squad init` if `.squad/` doesn't exist.
2. Runs `squad upstream add <source> --name shared --ref <ref>` (skipped if already configured).
3. Runs `squad upstream sync`.
4. Writes `.github/instructions/squad-upstream.instructions.md` so the Squad coordinator loads the inherited content. As of Squad v0.13, the `squad` Copilot agent doesn't read `upstream.json` on its own.
5. Runs `squad doctor`.

### Scenarios

- **Colleague in a different repository.** Run `/link-shared-decisions` in that repository. Both repositories inherit the same decisions.
- **Colleague in the same repository on a different branch.** Commit `.squad/upstream.json` once. Every branch reads the shared decisions through `squad upstream sync`, so nobody has to rebase. To keep the decisions inside the same repository, put them on an orphan `squad-config` branch and use `--source self --ref squad-config`.
- **Updating shared decisions.** Merge a pull request to the shared repository or branch, then run `squad upstream sync` and start a new session.

### Limits

- Read-only. Decisions an agent records in a consuming repo stay in that repo's `.squad/decisions.md` until someone promotes them to the shared repo with a pull request.
- `.squad/` must be at the root of the shared repository or branch; `squad upstream` doesn't support subfolders.
- Squad's native cross-branch decision sharing (`stateBackend: orphan` or `two-layer`) writes back automatically, but needs the `squad_state` MCP server. Approach A is the workaround when that MCP server can't be used.

---

## Approach B: Starter team (`squad-starter-team`)

Lays down a pre-built base team in a repository. It's like `squad init`, but you start with a real team instead of an empty roster.

| Member | Role |
|--------|------|
| `lead` | Technical Lead |
| `developer` | Software Engineer |
| `tester` | Test Engineer |
| `reviewer` | Code Reviewer |
| `security` | Security Engineer |
| `docs` | Documentation Specialist |

Squad's system agents (`scribe`, `ralph`, `Rai`, `fact-checker`) are added by `squad init` as usual.

### Use

Start Copilot CLI and run `/init-starter-team`, or ask `set up the starter squad team in ~/repos/my-app`. The skill asks which repository to set up (default: the current one) and runs [`init-starter-team.sh`](plugins/squad-starter-team/skills/init-starter-team/scripts/init-starter-team.sh) or [`init-starter-team.ps1`](plugins/squad-starter-team/skills/init-starter-team/scripts/init-starter-team.ps1), which:

1. Stops if the repository already has `.squad/`, unless you pass `--force`.
2. Runs `squad init` for the scaffolding: the `.github/agents/squad.agent.md` coordinator, system agents, templates, and MCP config.
3. Copies the [team template](plugins/squad-starter-team/skills/init-starter-team/team-template/.squad) on top: `team.md`, `routing.md`, `casting/registry.json`, and one charter per member. It fills in the project name and date.
4. Runs `squad doctor`.

The template intentionally has no `decisions.md`, histories, or memory, so every repository starts clean.

### Changing the starter team

Edit the files under [`team-template/.squad/`](plugins/squad-starter-team/skills/init-starter-team/team-template/.squad), bump the plugin version, and push. Users get the new template with `copilot plugin update squad-starter-team`. Repositories that were already initialized aren't changed.

---

## Running the scripts without Copilot

All scripts are idempotent or safe to re-run and work standalone:

```bash
# Approach A
./plugins/squad-shared-decisions/skills/link-shared-decisions/scripts/link-shared-decisions.sh --source self --ref squad-config

# Approach B
./plugins/squad-starter-team/skills/init-starter-team/scripts/init-starter-team.sh --target ~/repos/my-app
```

## Adapting for your organization

- **Approach A:** fork [squad-shared-decisions](https://github.com/joshjohanning-org/squad-shared-decisions), then change the default source URL in both `link-shared-decisions` scripts and in its [`SKILL.md`](plugins/squad-shared-decisions/skills/link-shared-decisions/SKILL.md).
- **Approach B:** edit the charters, `team.md`, `routing.md`, and `casting/registry.json` in the team template.
