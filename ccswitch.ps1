# ccswitch.ps1 (Windows): swap Claude Code login, keep ~/.claude so /resume works.
# usage: powershell -File ccswitch.ps1 save|use|list [name]
param([string]$Cmd, [string]$Name)
$ErrorActionPreference = 'Stop'
$cfg  = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { "$HOME\.claude" }
$cj   = if ($env:CLAUDE_CONFIG_DIR) { "$cfg\.claude.json" } else { "$HOME\.claude.json" }
$cred = "$cfg\.credentials.json"
$d    = "$HOME\.claude-switcher"; New-Item -ItemType Directory -Force $d | Out-Null
$activeF = "$d\active"
function Active { if (Test-Path $activeF) { (Get-Content $activeF -Raw).Trim() } }
function Snap($n) {
  if (!(Test-Path $cred)) { throw 'no login, run /login first' }
  Copy-Item $cred "$d\$n.cred" -Force
  (Get-Content $cj -Raw | ConvertFrom-Json).oauthAccount | ConvertTo-Json -Depth 100 | Set-Content "$d\$n.acct"
  Set-Content $activeF $n
}
if ($Cmd -in 'save','use' -and $Name -notmatch '^[\w.-]+$') { throw "usage: ccswitch.ps1 $Cmd <name>" }
switch ($Cmd) {
  'save' { Snap $Name; "saved current login as '$Name'" }
  'use' {
    if (!(Test-Path "$d\$Name.acct")) { throw "no profile '$Name'. try: list" }
    if (Active) { Snap (Active) }   # keep refreshed token of account we leave
    Copy-Item "$d\$Name.cred" $cred -Force
    $c = Get-Content $cj -Raw | ConvertFrom-Json
    $c.oauthAccount = Get-Content "$d\$Name.acct" -Raw | ConvertFrom-Json
    $c | ConvertTo-Json -Depth 100 | Set-Content $cj
    Set-Content $activeF $Name
    "now: $Name. Restart claude (open sessions keep old account), then /resume"
  }
  'list' {
    Get-ChildItem "$d\*.acct" | ForEach-Object {
      $n = $_.BaseName; $m = if ($n -eq (Active)) { '*' } else { ' ' }
      "$m $n  $((Get-Content $_ -Raw | ConvertFrom-Json).emailAddress)"
    }
  }
  default { 'usage: ccswitch.ps1 save|use|list [name]' }
}
