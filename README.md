# squad-copilot-plugins

A [GitHub Copilot CLI plugin marketplace](https://docs.github.com/copilot/how-tos/copilot-cli/customize-copilot/plugins-marketplace) with a plugin that onboards any repository to a shared [Squad](https://github.com/bradygaster/squad) configuration, instead of zipping and sharing `.squad/` folders.

> [!NOTE]
> This is a proof of concept. Squad is alpha software and its commands may change.

## How it works

```text
squad-shared-config (repo or branch)          your-app (any repo, any branch)
└── .squad/                                   ├── .squad/
    ├── decisions.md                          │   ├── upstream.json      ← committed pointer
    ├── routing.md        squad upstream sync │   ├── _upstream_repos/   ← gitignored cache
    ├── identity/wisdom.md  ───────────────►  │   └── team.md, agents/…  ← project-local state
    ├── casting/policy.json                   └── .github/instructions/
    └── skills/*/SKILL.md                         └── squad-upstream.instructions.md
```

- The **shared config** lives in Git: [joshjohanning-org/squad-shared-config](https://github.com/joshjohanning-org/squad-shared-config) (or a branch of your own repo).
- The **`squad-setup` plugin** only automates onboarding. It doesn't bundle any config, so config changes never need a plugin release.

## Install

```bash
copilot plugin marketplace add joshjohanning-org/squad-copilot-plugins
copilot plugin install squad-setup@squad-copilot-plugins
```

Prerequisites: the [Squad CLI](https://github.com/bradygaster/squad#install) and Git.

## Use

From inside any git repository, start Copilot CLI and run:

```text
/init-shared-squad
```

Or ask naturally:

| Scenario | Prompt |
|----------|--------|
| Default shared config repo | `set up the shared squad` |
| Your own shared config repo | `set up the shared squad from https://github.com/my-org/my-squad-config.git` |
| Config branch in the **same** repo | `set up the shared squad from the squad-config branch of this repo` |
| Skip Squad's GitHub Actions workflows | `set up the shared squad without workflows` |

The skill runs [`setup-shared-squad.sh`](plugins/squad-setup/skills/init-shared-squad/scripts/setup-shared-squad.sh) (macOS/Linux) or [`setup-shared-squad.ps1`](plugins/squad-setup/skills/init-shared-squad/scripts/setup-shared-squad.ps1) (Windows), which:

1. Runs `squad init` if `.squad/` doesn't exist.
2. Runs `squad upstream add <source> --name shared --ref <ref>` (skipped if already configured).
3. Runs `squad upstream sync`.
4. Writes `.github/instructions/squad-upstream.instructions.md` so the Squad coordinator loads the inherited content (as of Squad v0.13, the `squad` Copilot agent doesn't read `upstream.json` on its own).
5. Runs `squad doctor`.

The scripts are idempotent, and can also be run directly without Copilot:

```bash
./plugins/squad-setup/skills/init-shared-squad/scripts/setup-shared-squad.sh --source self --ref squad-config
```

## Scenarios

**Colleague in a different repository.** Run `/init-shared-squad` in that repository. Both repositories inherit from the same shared config.

**Colleague in the same repository on a different branch.** Commit `.squad/upstream.json` once; each branch reads the shared config through `squad upstream sync`, so nobody has to rebase to pick up config changes. To keep the shared config inside the same repository, put it on an orphan `squad-config` branch and use `--source self --ref squad-config`.

**Updating shared config.** Merge a pull request to the shared config repo or branch, then run `squad upstream sync` and start a new session.

## Adapting for your organization

Change the default source URL in both setup scripts and in [`SKILL.md`](plugins/squad-setup/skills/init-shared-squad/SKILL.md) to point at your organization's shared config repository.
