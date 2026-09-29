# Lays down a starter Squad team (bundled in ../team-template) in a target
# git repository: runs `squad init`, then copies the team roster, charters,
# routing, and casting registry on top. No link to any shared repo is kept.
[CmdletBinding()]
param(
    [string]$Target = (Get-Location).Path,
    [switch]$Force,
    [switch]$NoWorkflows
)

$ErrorActionPreference = "Stop"
$templateDir = Join-Path (Split-Path $PSScriptRoot -Parent) "team-template/.squad"

if (-not (Get-Command squad -ErrorAction SilentlyContinue)) {
    Write-Error @"
The 'squad' CLI is not installed. Install it with one of:
  npm install -g @bradygaster/squad-cli
  winget install --id bradygaster.Squad --exact
  brew install --cask bradygaster/squad/squad
"@
    exit 1
}

if (-not (Test-Path $Target -PathType Container)) {
    Write-Error "Target directory does not exist: $Target"
    exit 1
}

$repoRoot = git -C $Target rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) {
    Write-Error "$Target is not inside a git repository. Run 'git init' there first."
    exit 1
}
Set-Location $repoRoot

Write-Host "==> Repository: $repoRoot"

if (Test-Path ".squad" -PathType Container) {
    if (-not $Force) {
        Write-Host "ERROR: This repository already has a squad (.squad/ exists)." -ForegroundColor Red
        Write-Host "       Re-run with -Force to overwrite its team roster, charters, routing, and casting registry." -ForegroundColor Red
        exit 3
    }
    Write-Host "==> Squad already initialized; -Force set, overwriting team files."
} else {
    Write-Host "==> Running 'squad init'..."
    $initArgs = @("init")
    if ($NoWorkflows) { $initArgs += "--no-workflows" }
    & squad @initArgs
    if ($LASTEXITCODE -ne 0) { throw "'squad init' failed with exit code $LASTEXITCODE." }
}

$projectName = Split-Path $repoRoot -Leaf
$date = (Get-Date).ToString("yyyy-MM-dd")
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.000Z")

Write-Host "==> Copying starter team into .squad/..."
Get-ChildItem $templateDir -Recurse -File | ForEach-Object {
    $rel = [System.IO.Path]::GetRelativePath($templateDir, $_.FullName)
    $dest = Join-Path (Join-Path $repoRoot ".squad") $rel
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    $content = [System.IO.File]::ReadAllText($_.FullName)
    $content = $content.Replace("{{PROJECT_NAME}}", $projectName).Replace("{{DATE}}", $date).Replace("{{TIMESTAMP}}", $timestamp)
    [System.IO.File]::WriteAllText($dest, $content)
    Write-Host "    .squad/$($rel -replace '\\', '/')"
}

Write-Host "==> Running 'squad doctor'..."
& squad doctor
if ($LASTEXITCODE -ne 0) { Write-Warning "'squad doctor' reported issues (see above)." }

Write-Host ""
Write-Host "Done. Starter team: lead, developer, tester, reviewer, security, docs."
Write-Host "Next steps:"
Write-Host "  1. Review and commit .squad/ and the other files 'squad init' created."
Write-Host "  2. Start a session: copilot --agent squad"
Write-Host "  3. Customize freely - this repo's team is now independent of the template."
