# Sets up Squad in the current git repository and links it to a shared Squad
# config repository via `squad upstream`. Safe to re-run.
[CmdletBinding()]
param(
    [string]$Source = $(if ($env:SQUAD_SHARED_SOURCE) { $env:SQUAD_SHARED_SOURCE } else { "https://github.com/joshjohanning-org/squad-shared-config.git" }),
    [string]$Name = $(if ($env:SQUAD_SHARED_NAME) { $env:SQUAD_SHARED_NAME } else { "shared" }),
    [string]$Ref = $(if ($env:SQUAD_SHARED_REF) { $env:SQUAD_SHARED_REF } else { "main" }),
    [switch]$NoWorkflows
)

$ErrorActionPreference = "Stop"

function Invoke-Checked {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "'$Command $($Arguments -join ' ')' failed with exit code $LASTEXITCODE."
    }
}

if (-not (Get-Command squad -ErrorAction SilentlyContinue)) {
    Write-Error @"
The 'squad' CLI is not installed. Install it with one of:
  npm install -g @bradygaster/squad-cli
  winget install --id bradygaster.Squad --exact
  brew install --cask bradygaster/squad/squad
"@
    exit 1
}

$repoRoot = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) {
    Write-Error "Run this from inside a git repository."
    exit 1
}
Set-Location $repoRoot

if ($Source -eq "self") {
    $Source = git remote get-url origin 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $Source) {
        Write-Error "-Source self requires an 'origin' remote."
        exit 1
    }
}

Write-Host "==> Repository: $repoRoot"
Write-Host "==> Shared config: $Source (ref: $Ref, name: $Name)"

if (Test-Path ".squad" -PathType Container) {
    Write-Host "==> Squad already initialized; skipping 'squad init'."
} else {
    Write-Host "==> Running 'squad init'..."
    $initArgs = @("init")
    if ($NoWorkflows) { $initArgs += "--no-workflows" }
    Invoke-Checked squad $initArgs
}

$upstreamFile = ".squad/upstream.json"
$existing = $null
if (Test-Path $upstreamFile) {
    $config = Get-Content $upstreamFile -Raw | ConvertFrom-Json
    $existing = $config.upstreams | Where-Object { $_.name -eq $Name } | Select-Object -First 1
}

if ($existing) {
    Write-Host "==> Upstream '$Name' already configured; skipping 'squad upstream add'."
    if ($existing.source -ne $Source) {
        Write-Warning "Existing upstream '$Name' points to '$($existing.source)'. Leaving it unchanged."
        Write-Warning "To change it: squad upstream remove $Name, then re-run this script."
    }
} else {
    Write-Host "==> Adding upstream '$Name'..."
    Invoke-Checked squad @("upstream", "add", $Source, "--name", $Name, "--ref", $Ref)
}

Write-Host "==> Syncing upstreams..."
Invoke-Checked squad @("upstream", "sync")

# Squad's Copilot coordinator prompt does not (as of v0.13) load upstream
# content by itself, so add an always-on instruction that tells it to.
$instructionsFile = ".github/instructions/squad-upstream.instructions.md"
New-Item -ItemType Directory -Force -Path (Split-Path $instructionsFile) | Out-Null
$instructions = @'
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
'@
[System.IO.File]::WriteAllText((Join-Path $repoRoot $instructionsFile), ($instructions -replace "`r`n", "`n") + "`n")
Write-Host "==> Wrote $instructionsFile"

Write-Host "==> Running 'squad doctor'..."
& squad doctor
if ($LASTEXITCODE -ne 0) { Write-Warning "'squad doctor' reported issues (see above)." }

Write-Host ""
Write-Host "Done. Next steps:"
Write-Host "  1. Review and commit: .squad/ (including upstream.json), .gitignore, $instructionsFile"
Write-Host "     (.squad/_upstream_repos/ is gitignored automatically.)"
Write-Host "  2. Start a new session: copilot --agent squad"
Write-Host "  3. Pull shared config updates later with: squad upstream sync"
