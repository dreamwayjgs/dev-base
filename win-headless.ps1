#requires -Version 7
# Semi-automatic tmt headless runner for Windows (tmt-cli #103). Runs in the owner's console, no Task Scheduler.
# Every intervalSec it starts `tmt headless --once` for each registered umbrella that has no run in flight.
# Usage: pwsh -NoProfile -File <dev-base>/win-headless.ps1 [-Config <path>]. Stop with Ctrl+C or by closing the window.
# Setup and troubleshooting: prompts/tmt-headless-setup.md, section "Windows (pwsh 러너)".
param([string]$Config = (Join-Path $HOME '.config/tmt/win-headless-repos.json'))
$ErrorActionPreference = 'Stop'

$example = @'
{
  "intervalSec": 120,
  "repos": [
    { "path": "C:/Users/<you>/<...>/<project>-tmt", "env": { "CLAUDE_CONFIG_DIR": "C:/Users/<you>/.claude-worker" } }
  ]
}
'@
if (-not (Test-Path -LiteralPath $Config)) {
  Write-Host "win-headless: config not found: $Config"
  Write-Host "Create it (machine-local, not tracked) like this; env is optional:"
  Write-Host $example
  exit 1
}

$cfg = Get-Content -LiteralPath $Config -Raw | ConvertFrom-Json
$interval = [int]($cfg.intervalSec ?? 120)
if ($interval -lt 30) { throw "win-headless: intervalSec must be >= 30, got $interval" }
if (-not $cfg.repos -or @($cfg.repos).Count -eq 0) { throw "win-headless: repos is empty in $Config" }
$repos = foreach ($r in @($cfg.repos)) {
  $path = [string]$r.path
  if (-not (Test-Path -LiteralPath (Join-Path $path 'tmt.json'))) { throw "win-headless: no tmt.json in $path" }
  $envMap = [ordered]@{}
  if ($r.env) { foreach ($p in $r.env.PSObject.Properties) { $envMap[$p.Name] = [string]$p.Value } }
  [pscustomobject]@{ Path = $path; Name = (Split-Path $path -Leaf); Env = $envMap; Log = (Join-Path $path '.scratch/win-headless.log') }
}
if (-not (Get-Command tmt -ErrorAction SilentlyContinue)) { throw 'win-headless: tmt not on PATH' }

function Get-Stamp { Get-Date -Format 'yyyy-MM-dd HH:mm:ss' }
function Quote([string]$s) { "'" + $s.Replace("'", "''") + "'" }

# One child pwsh per run: sets the repo env, appends a header and all tmt output to the repo log.
function Start-Once($r) {
  New-Item -ItemType Directory -Force (Split-Path $r.Log) | Out-Null
  $lines = @(foreach ($k in $r.Env.Keys) { "`$env:$k = $(Quote $r.Env[$k])" })
  $lines += "`"=== `$(Get-Date -Format o) tmt headless --once`" | Out-File -Append -LiteralPath $(Quote $r.Log)"
  $lines += "tmt headless --once *>> $(Quote $r.Log)"
  $lines += 'exit $LASTEXITCODE'
  $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($lines -join "`n"))
  # Same console (-NoNewWindow): Ctrl+C and window close reach the whole tree.
  $p = Start-Process pwsh -ArgumentList '-NoProfile', '-NonInteractive', '-EncodedCommand', $enc `
    -WorkingDirectory $r.Path -NoNewWindow -PassThru
  $null = $p.Handle  # keep the handle so ExitCode is readable after exit
  $p
}

function Get-LastLine($log) {
  try { (Get-Content -LiteralPath $log -Tail 1 -ErrorAction Stop) } catch { '' }
}

$procs = @{}
Write-Host "$(Get-Stamp) win-headless: $(@($repos).Count) repo(s), every $interval s, config $Config. Ctrl+C stops."
try {
  while ($true) {
    $tick = Get-Date
    foreach ($r in $repos) {
      $p = $procs[$r.Path]
      if ($p -and -not $p.HasExited) { Write-Host "$(Get-Stamp) $($r.Name): still running (pid $($p.Id)), skipped"; continue }
      if ($p) {
        $last = Get-LastLine $r.Log
        if ($last.Length -gt 160) { $last = $last.Substring(0, 160) + '…' }
        Write-Host "$(Get-Stamp) $($r.Name): previous run exit $($p.ExitCode): $last"
      }
      $procs[$r.Path] = Start-Once $r
      Write-Host "$(Get-Stamp) $($r.Name): started (pid $($procs[$r.Path].Id))"
    }
    $wait = $interval - [int]((Get-Date) - $tick).TotalSeconds
    Start-Sleep -Seconds ([Math]::Max(1, $wait))
  }
} finally {
  # Anything that ignored Ctrl+C: kill its tree. Orphans whose parent already died are not reached (see setup doc).
  foreach ($r in $repos) {
    $p = $procs[$r.Path]
    if ($p -and -not $p.HasExited) {
      Write-Host "$(Get-Stamp) $($r.Name): killing tree of pid $($p.Id)"
      & taskkill /T /F /PID $p.Id | Out-Null
    }
  }
  Write-Host "$(Get-Stamp) win-headless: stopped. Check: tmt headless status (lock, running) in each repo."
}
