<# : CyberPatriot Windows hardening - just double-click this file.
@echo off
setlocal
title CyberPatriot Windows hardening
rem  This one file is BOTH a batch file and a PowerShell script. cmd.exe runs these first
rem  lines; to PowerShell they are just a comment. It asks for administrator rights,
rem  checks the script below is intact, then runs it in this window.
rem  BEFORE RUNNING: answer the forensics questions and read the README.
rem  If Windows says "Windows protected your PC": More info, then Run anyway.
set CP_SELF=%~f0
fltmc >nul 2>&1
if errorlevel 1 (
  echo Requesting administrator rights - click Yes on the prompt...
  powershell.exe -NoProfile -EncodedCommand UwB0AGEAcgB0AC0AUAByAG8AYwBlAHMAcwAgAC0ARgBpAGwAZQBQAGEAdABoACAAJABlAG4AdgA6AEMAUABfAFMARQBMAEYAIAAtAFYAZQByAGIAIABSAHUAbgBBAHMA
  exit /b
)
cd /d %~dp0
powershell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand JABmACAAPQAgACQAZQBuAHYAOgBDAFAAXwBTAEUATABGAAoAdAByAHkAIAB7ACAAJAB0ACAAPQAgAFsASQBPAC4ARgBpAGwAZQBdADoAOgBSAGUAYQBkAEEAbABsAFQAZQB4AHQAKAAkAGYALAAgAFsAVABlAHgAdAAuAEUAbgBjAG8AZABpAG4AZwBdADoAOgBVAFQARgA4ACkAIAB9ACAAYwBhAHQAYwBoACAAewAgAFcAcgBpAHQAZQAtAEgAbwBzAHQAIAAiAEMAYQBuACcAdAAgAHIAZQBhAGQAIAAkAGYAIAA6ACAAJAAoACQAXwAuAEUAeABjAGUAcAB0AGkAbwBuAC4ATQBlAHMAcwBhAGcAZQApACIAIAAtAEYAbwByAGUAZwByAG8AdQBuAGQAQwBvAGwAbwByACAAUgBlAGQAOwAgAGUAeABpAHQAIAAxACAAfQAKACQAcABhAGkAcgBzACAAPQAgAEAAKABAACgAMAB4ADIAMAAxAEMALAAgACcAIgAnACkALAAgAEAAKAAwAHgAMgAwADEARAAsACAAJwAiACcAKQAsACAAQAAoADAAeAAyADAAMQBFACwAIAAnACIAJwApACwAIABAACgAMAB4ADIAMAAzADMALAAgACcAIgAnACkALAAgAEAAKAAwAHgAMgAwADEAOAAsACAAIgAnACIAKQAsACAAQAAoADAAeAAyADAAMQA5ACwAIAAiACcAIgApACwAIABAACgAMAB4ADIAMAAxAEEALAAgACIAJwAiACkALAAgAEAAKAAwAHgAMgAwADMAMgAsACAAIgAnACIAKQAsACAAQAAoADAAeAAyADAAMQAzACwAIAAnAC0AJwApACwAIABAACgAMAB4ADIAMAAxADQALAAgACcALQAnACkALAAgAEAAKAAwAHgAMgAyADEAMgAsACAAJwAtACcAKQAsACAAQAAoADAAeAAwADAAQQAwACwAIAAnACAAJwApACwAIABAACgAMAB4ADIAMAAyADYALAAgACcALgAuAC4AJwApACwAIABAACgAMAB4AEYARQBGAEYALAAgACcAJwApACkACgAkAG4AIAA9ACAAMAAKAGYAbwByAGUAYQBjAGgAIAAoACQAcAAgAGkAbgAgACQAcABhAGkAcgBzACkAIAB7ACAAJABjACAAPQAgAFsAcwB0AHIAaQBuAGcAXQBbAGMAaABhAHIAXQAkAHAAWwAwAF0AOwAgACQAawAgAD0AIAAoACQAdAAuAEwAZQBuAGcAdABoACAALQAgACQAdAAuAFIAZQBwAGwAYQBjAGUAKAAkAGMALAAgACcAJwApAC4ATABlAG4AZwB0AGgAKQA7ACAAaQBmACAAKAAkAGsAKQAgAHsAIAAkAG4AIAArAD0AIAAkAGsAOwAgACQAdAAgAD0AIAAkAHQALgBSAGUAcABsAGEAYwBlACgAJABjACwAIAAkAHAAWwAxAF0AKQAgAH0AIAB9AAoAaQBmACAAKAAkAG4AKQAgAHsAIABXAHIAaQB0AGUALQBIAG8AcwB0ACAAIgBOAG8AdABlADoAIAByAGUAcABhAGkAcgBlAGQAIAAkAG4AIABzAG0AYQByAHQAIABxAHUAbwB0AGUALwBkAGEAcwBoACAAYwBoAGEAcgBhAGMAdABlAHIAcwAgACgAdABoAGUAIABmAGkAbABlACAAdwBhAHMAIABjAG8AcABpAGUAZAAgAHQAaAByAG8AdQBnAGgAIABHAG8AbwBnAGwAZQAgAEQAbwBjAHMALAAgAFcAbwByAGQAIABvAHIAIABhACAAdwBlAGIAIABwAGEAZwBlACkALgAiACAALQBGAG8AcgBlAGcAcgBvAHUAbgBkAEMAbwBsAG8AcgAgAFkAZQBsAGwAbwB3ACAAfQAKACMAIABGAGkAbgBnAGUAcgBwAHIAaQBuAHQAIABjAGgAZQBjAGsAOgAgAGkAcwAgAHQAaABpAHMAIAB0AGgAZQAgAGMAbwBtAHAAbABlAHQAZQAsACAAdQBuAG0AbwBkAGkAZgBpAGUAZAAgAHMAYwByAGkAcAB0AD8AIAAoAGMAbwBtAHAAYQByAGUAZAAgAGEAZgB0AGUAcgAgAHQAaABlACAAcgBlAHAAYQBpAHIAIABhAGIAbwB2AGUAKQAKACQAbQBhAHIAawAgAD0AIAAnADoAIABlAG4AZAAgAG8AZgAgAHQAaABlACAAYgBhAHQAYwBoACAAcABhAHIAdAAgACMAPgAnADsAIAAkAG0AaQAgAD0AIAAkAHQALgBJAG4AZABlAHgATwBmACgAJABtAGEAcgBrACkAOwAgACQAcwBoAGEAIAA9ACAAJwAnAAoAaQBmACAAKAAkAG0AaQAgAC0AZwBlACAAMAApACAAewAKACAAIAAkAGIAbwBkAHkAIAA9ACAAKAAoACQAdAAuAFMAdQBiAHMAdAByAGkAbgBnACgAJABtAGkAIAArACAAJABtAGEAcgBrAC4ATABlAG4AZwB0AGgAKQAgAC0AcgBlAHAAbABhAGMAZQAgACIAYAByAGAAbgAiACwAIAAiAGAAbgAiACkAIAAtAHMAcABsAGkAdAAgACIAYABuACIAIAB8ACAARgBvAHIARQBhAGMAaAAtAE8AYgBqAGUAYwB0ACAAewAgACQAXwAuAFQAcgBpAG0ARQBuAGQAKAApACAAfQApACAALQBqAG8AaQBuACAAIgBgAG4AIgAKACAAIAAkAHMAaABhACAAPQAgAFsAQgBpAHQAQwBvAG4AdgBlAHIAdABlAHIAXQA6ADoAVABvAFMAdAByAGkAbgBnACgAWwBTAGUAYwB1AHIAaQB0AHkALgBDAHIAeQBwAHQAbwBnAHIAYQBwAGgAeQAuAFMASABBADIANQA2AF0AOgA6AEMAcgBlAGEAdABlACgAKQAuAEMAbwBtAHAAdQB0AGUASABhAHMAaAAoAFsAVABlAHgAdAAuAEUAbgBjAG8AZABpAG4AZwBdADoAOgBVAFQARgA4AC4ARwBlAHQAQgB5AHQAZQBzACgAJABiAG8AZAB5AC4AVAByAGkAbQAoACkAKQApACkAIAAtAHIAZQBwAGwAYQBjAGUAIAAnAC0AJwAsACAAJwAnAAoAfQAKAGkAZgAgACgAJABzAGgAYQAgAC0AbgBlACAAJwAwADUAMwA2ADAANgBBAEMARgA0ADQAQQA4ADAAMQA0ADEAMAAwADQAQgAwADcARABCAEEAMAA2ADIANABDADUAMwBBADMAMwBGADIAMAA3AEYAMwA1ADAARAA2ADQAQgA1ADUAOQBFADMANABFADcAOQBBAEIANABGADUAQQBGACcAKQAgAHsACgAgACAAVwByAGkAdABlAC0ASABvAHMAdAAgACcAVwBBAFIATgBJAE4ARwA6ACAAdABoAGkAcwAgAGMAbwBwAHkAIABpAHMAIABOAE8AVAAgAGkAZABlAG4AdABpAGMAYQBsACAAdABvACAAdABoAGUAIABvAHIAaQBnAGkAbgBhAGwAIABzAGMAcgBpAHAAdAAgACgAbABpAG4AZQBzACAAbQBpAHMAcwBpAG4AZwAgAG8AcgAgAGMAaABhAG4AZwBlAGQAIABpAG4AIAB0AHIAYQBuAHMAZgBlAHIAKQAuACcAIAAtAEYAbwByAGUAZwByAG8AdQBuAGQAQwBvAGwAbwByACAAUgBlAGQACgAgACAAVwByAGkAdABlAC0ASABvAHMAdAAgACcAQgBlAHMAdAAgAGYAaQB4ADoAIABkAG8AdwBuAGwAbwBhAGQAIAB0AGgAZQAgAGYAaQBsAGUAIABpAHQAcwBlAGwAZgAgAGEAZwBhAGkAbgAgACgAZgBvAHIAIABHAGkAdABIAHUAYgA6ACAAdABoAGUAIAAiAEQAbwB3AG4AbABvAGEAZAAgAHIAYQB3ACAAZgBpAGwAZQAiACAAYgB1AHQAdABvAG4AKQAuACcAIAAtAEYAbwByAGUAZwByAG8AdQBuAGQAQwBvAGwAbwByACAAWQBlAGwAbABvAHcACgAgACAAJABhACAAPQAgAFIAZQBhAGQALQBIAG8AcwB0ACAAJwBSAHUAbgAgAGkAdAAgAGEAbgB5AHcAYQB5AD8AIABbAHkALwBuAF0AJwAKACAAIABpAGYAIAAoACQAYQAgAC0AbgBvAHQAbQBhAHQAYwBoACAAJwBeACgAPwBpACkAeQAnACkAIAB7ACAAZQB4AGkAdAAgADEAIAB9AAoAfQAKACQAZQByAHIAcwAgAD0AIAAkAG4AdQBsAGwACgBbAHYAbwBpAGQAXQBbAFMAeQBzAHQAZQBtAC4ATQBhAG4AYQBnAGUAbQBlAG4AdAAuAEEAdQB0AG8AbQBhAHQAaQBvAG4ALgBMAGEAbgBnAHUAYQBnAGUALgBQAGEAcgBzAGUAcgBdADoAOgBQAGEAcgBzAGUASQBuAHAAdQB0ACgAJAB0ACwAIABbAHIAZQBmAF0AJABuAHUAbABsACwAIABbAHIAZQBmAF0AJABlAHIAcgBzACkACgBpAGYAIAAoACQAZQByAHIAcwAuAEMAbwB1AG4AdAApACAAewAKACAAIABXAHIAaQB0AGUALQBIAG8AcwB0ACAAJwBUAGgAaQBzACAAYwBvAHAAeQAgAG8AZgAgAHQAaABlACAAcwBjAHIAaQBwAHQAIABpAHMAIABEAEEATQBBAEcARQBEACwAIABzAG8AIABpAHQAIAB3AGEAcwAgAE4ATwBUACAAcgB1AG4ALgAgAE4AbwB0AGgAaQBuAGcAIABvAG4AIAB0AGgAaQBzACAAYwBvAG0AcAB1AHQAZQByACAAdwBhAHMAIABjAGgAYQBuAGcAZQBkAC4AJwAgAC0ARgBvAHIAZQBnAHIAbwB1AG4AZABDAG8AbABvAHIAIABSAGUAZAAKACAAIABmAG8AcgBlAGEAYwBoACAAKAAkAGUAIABpAG4AIAAoACQAZQByAHIAcwAgAHwAIABTAGUAbABlAGMAdAAtAE8AYgBqAGUAYwB0ACAALQBGAGkAcgBzAHQAIAA1ACkAKQAgAHsAIABXAHIAaQB0AGUALQBIAG8AcwB0ACAAKAAnACAAIAAgAGwAaQBuAGUAIAB7ADAAfQA6ACAAewAxAH0AJwAgAC0AZgAgACQAZQAuAEUAeAB0AGUAbgB0AC4AUwB0AGEAcgB0AEwAaQBuAGUATgB1AG0AYgBlAHIALAAgACQAZQAuAE0AZQBzAHMAYQBnAGUAKQAgAH0ACgAgACAAVwByAGkAdABlAC0ASABvAHMAdAAgACcARwBlAHQAIABhACAAZgByAGUAcwBoACAAYwBvAHAAeQAgAGIAeQAgAGQAbwB3AG4AbABvAGEAZABpAG4AZwAgAHQAaABlACAARgBJAEwARQAgAGkAdABzAGUAbABmACAAKABmAG8AcgAgAEcAaQB0AEgAdQBiADoAIAB0AGgAZQAgACIARABvAHcAbgBsAG8AYQBkACAAcgBhAHcAIABmAGkAbABlACIAIABiAHUAdAB0AG8AbgApAC4AJwAgAC0ARgBvAHIAZQBnAHIAbwB1AG4AZABDAG8AbABvAHIAIABZAGUAbABsAG8AdwAKACAAIABXAHIAaQB0AGUALQBIAG8AcwB0ACAAJwBEAG8AIABuAG8AdAAgAGMAbwBwAHkALwBwAGEAcwB0AGUAIABpAHQAIAB0AGgAcgBvAHUAZwBoACAARwBvAG8AZwBsAGUAIABEAG8AYwBzACwAIABXAG8AcgBkACwAIABlAG0AYQBpAGwAIAB0AGUAeAB0ACAAbwByACAAYQAgAHcAZQBiACAAcABhAGcAZQAgAC0AIAB0AGgAZQB5ACAAYwBoAGEAbgBnAGUAIABjAGgAYQByAGEAYwB0AGUAcgBzAC4AJwAgAC0ARgBvAHIAZQBnAHIAbwB1AG4AZABDAG8AbABvAHIAIABZAGUAbABsAG8AdwAKACAAIABlAHgAaQB0ACAAMQAKAH0ACgAuACAAKABbAHMAYwByAGkAcAB0AGIAbABvAGMAawBdADoAOgBDAHIAZQBhAHQAZQAoACQAdAApACkACgA=
echo.
echo The script has finished. Read the summary above, then press any key to close this window.
pause >nul
exit /b
: end of the batch part #>
<#
===============================================================================
  CyberPatriot Windows Hardening Script
  Windows 10 / 11 and Windows Server 2016 / 2019 / 2022 (incl. domain controllers)

  HOW TO RUN  (in an ADMINISTRATOR PowerShell window)
      Set-ExecutionPolicy -Scope Process Bypass -Force
      Unblock-File .\cyberpatriot_windows.ps1
      .\cyberpatriot_windows.ps1

  BEFORE YOU RUN IT
   1. Answer the FORENSICS QUESTIONS first. This script removes users, software
      and media files those questions often ask about. (It also saves a
      FORENSICS.txt snapshot first, but answer what you can before running.)
   2. Read the README. Have ready: authorized admins, authorized standard users,
      and every service the README calls "critical"/"required".
   3. Keep a SECOND Administrator PowerShell window open until you've confirmed
      you can still log in and run things as admin.

  SAFETY DESIGN
   * Nothing destructive happens without showing you what and asking first.
   * Backups before changes: security policy, audit policy, firewall, the
     registry keys it edits, service start modes, hosts file, plus a System
     Restore point on Windows 10/11.
   * Services the README needs are hardened, never removed; each service
     change is checked and rolled back if the service won't start.
   * Your own account is never deleted, disabled or demoted.
   * Files are QUARANTINED (moved to C:\CP-Quarantine), never deleted.
   * Anything that looks like the CyberPatriot scoring engine, the README,
     forensics files or VM tools is skipped.
===============================================================================
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'
if ($PSVersionTable.PSVersion.Major -lt 5) { Write-Host 'This script needs PowerShell 5.1 or newer.' -ForegroundColor Red; exit 1 }
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Host 'Run this from an ADMINISTRATOR PowerShell window (right-click > Run as administrator).' -ForegroundColor Red; exit 1 }

#---------------------------- who / where -------------------------------------
$Me      = $env:USERNAME
$MeFull  = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$MeSid   = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$Stamp   = Get-Date -Format 'yyyyMMdd-HHmmss'
$Desktop = [Environment]::GetFolderPath('Desktop')
if (-not $Desktop -or -not (Test-Path -LiteralPath $Desktop)) { $Desktop = Join-Path $env:USERPROFILE 'Desktop' }
$Out     = Join-Path $Desktop 'CP-Script'
$LogDir  = Join-Path $Out 'logs'
$Log     = Join-Path $Out 'script.log'
$Report  = Join-Path $Out 'REVIEW-ME.txt'
$ForFile = Join-Path $Out 'FORENSICS.txt'
$Backup  = "C:\CP-Backups\$Stamp"
$Quar    = 'C:\CP-Quarantine'
$RegLog  = Join-Path $Backup 'registry-changes.tsv'
$ScriptPath = $PSCommandPath; if ($env:CP_SELF) { $ScriptPath = $env:CP_SELF }   # the .bat launcher passes its own path
New-Item -ItemType Directory -Force -Path $LogDir, $Backup, $Quar | Out-Null
# Only Administrators/SYSTEM may read the backups and quarantine
foreach ($d in 'C:\CP-Backups', $Quar) { & icacls.exe $d /inheritance:r /grant:r '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-18:(OI)(CI)F' 2>&1 | Out-Null }
Set-Content -LiteralPath $Report -Value @(
  "CyberPatriot script review list (Windows) - $(Get-Date)"
  'Items marked [!] need YOUR attention. Everything else is info for forensics/manual checks.'
  "Backups: $Backup     Quarantined files: $Quar"
  ''
)
"Path`tName`tOldValue`tNewValue" | Set-Content -LiteralPath $RegLog
try { Start-Transcript -LiteralPath (Join-Path $LogDir 'transcript.txt') -Append | Out-Null } catch {}
$StartTime = Get-Date

#-------------------------------- logging -------------------------------------
function Write-LogLine([string]$t) { Add-Content -LiteralPath $Log -Value ('[{0}] {1}' -f (Get-Date -Format 'HH:mm:ss'), $t) }
function Log([string]$m)    { Write-LogLine $m; Write-Host "[+] $m" -ForegroundColor Green }
function Info([string]$m)   { Write-LogLine "    $m"; Write-Host "    $m" }
function Warn([string]$m)   { Write-LogLine "WARNING: $m"; Write-Host "[!] $m" -ForegroundColor Yellow; Add-Content -LiteralPath $Report -Value "[!] $m" }
function Review([string]$m) { Add-Content -LiteralPath $Report -Value $m }
function Section([string]$m) { Write-Host ''; Write-Host "==== $m ====" -ForegroundColor Cyan; Write-LogLine "==== $m ====" }

#------------------------------- prompting ------------------------------------
function Ask-YN([string]$q) {
  while ($true) {
    $a = Read-Host "[?] $q [y/n]"
    if ($null -eq $a) { return $false }
    $a = $a.Trim().ToLower()
    if ($a -eq 'y' -or $a -eq 'yes') { return $true }
    if ($a -eq 'n' -or $a -eq 'no')  { return $false }
    Write-Host '    Please type y or n.'
  }
}
function Ask([string]$q) { $a = Read-Host "[?] $q"; if ($null -eq $a) { return '' }; return $a.Trim() }

#-------------------------------- helpers -------------------------------------
# Anything that looks like the scoring engine / README / forensics files / VM tools is never touched.
$ProtectRe = '(?i)cyberpatriot|ccs|scor(e|ing)|aeacus|phocus|forensic|readme|vmware|vmtools|virtualbox|vbox|qemu|spice|parallels'
function Test-Protected([string]$s) { return ($s -match $ProtectRe) }

# Program locations normal users can write to (a program running from here is suspect)
$UserWritableRe = '(?i)\\Users\\[^\\]+\\(AppData|Downloads|Desktop|Documents|Music|Pictures|Videos)\\|\\Users\\Public\\|\\Windows\\Temp\\|\\ProgramData\\(?!Microsoft\\|Package Cache\\)|^[A-Z]:\\(Temp|tmp)\\|\\\$Recycle\.Bin\\|\\PerfLogs\\'
# Command lines typical of backdoors / downloaders
$SuspCmdRe = '(?i)(\s-e(nc(odedcommand)?)?\s+[A-Za-z0-9+/=]{16,}|-w(indowstyle)?\s+h(idden)?|frombase64string|downloadstring|downloadfile|invoke-expression|\biex\b|invoke-webrequest|\biwr\s|net\.webclient|bitsadmin.*/transfer|certutil.*-urlcache|\bmshta(\.exe)?\s|regsvr32.*/i:|rundll32.*(javascript|http)|\b(nc|ncat|nc64|netcat)(\.exe)?\s+.*-e\s|powercat|https?://)'
# File names of common hacking / remote-control tools
$ToolNameRe = '(?i)^(nc|nc64|ncat|netcat|socat|nmap|zenmap|masscan|mimikatz|mimilib|wce|pwdump\d*|fgdump|gsecdump|lazagne|rubeus|sharphound|bloodhound|kerbrute|john|hashcat|hydra|medusa|cain|abel|ophcrack|l0phtcrack|lc\d|wireshark|tshark|dumpcap|rawcap|netstumbler|ipscan|angryip|advanced_ip_scanner|powercat|plink|chisel|ngrok|frpc|psexec\d*|paexec|rdpwrap|winvnc|tvnserver|keylogger|klogger|revealer|ardamax|cheatengine[^.]*|msfconsole|msfvenom|sqlmap|invoke-mimikatz|powerup|powerview)\.(exe|ps1|py|jar)$'

$SigCache = @{}
function Test-Signed([string]$p) {
  if (-not $p -or -not (Test-Path -LiteralPath $p -PathType Leaf)) { return $false }
  if ($SigCache.ContainsKey($p)) { return $SigCache[$p] }
  $ok = $false
  try { $ok = ((Get-AuthenticodeSignature -LiteralPath $p -ErrorAction Stop).Status -eq 'Valid') } catch {}
  $SigCache[$p] = $ok
  return $ok
}
# Program path out of a command line ("C:\x y\a.exe" -args / C:\a.exe args / %windir%\...)
function Get-ExeFromCommand([string]$cmd) {
  if (-not $cmd) { return $null }
  $c = [Environment]::ExpandEnvironmentVariables($cmd.Trim())
  if ($c -match '^"([^"]+)"') { return $Matches[1] }
  if ($c -match '^(.+?\.(exe|com|bat|cmd|ps1|vbs|js|hta|scr|dll))(\s|,|$)') { return $Matches[1] }
  return ($c -split '\s+')[0]
}

# Registry edits are logged (old value -> new value) to $RegLog so anything can be put back.
function Set-Reg {
  param([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord')
  try {
    if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force -ErrorAction Stop | Out-Null }
    $old = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue
    $oldv = '(not set)'; if ($old) { $oldv = [string](@($old.$Name) -join ',') }
    Add-Content -LiteralPath $RegLog -Value "$Path`t$Name`t$oldv`t$Value"
    New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
    return $true
  } catch { Warn "Couldn't set $Path\$Name ($($_.Exception.Message))"; return $false }
}
function Get-RegValue([string]$Path, [string]$Name) { return (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue).$Name }
function Remove-RegValue([string]$Path, [string]$Name) {
  $old = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue
  if (-not $old) { return $false }
  Add-Content -LiteralPath $RegLog -Value "$Path`t$Name`t$(@($old.$Name) -join ',')`t(removed)"
  Remove-ItemProperty -LiteralPath $Path -Name $Name -Force -ErrorAction SilentlyContinue
  return $true
}

# Quarantine = move (not delete) to C:\CP-Quarantine\files\<drive>\<original path>
function Move-ToQuarantine([string]$f) {
  if (-not $f -or -not (Test-Path -LiteralPath $f)) { return $false }
  if (Test-Protected $f) { Info "Not touching $f (scoring engine / README / VM tools)"; return $false }
  if ($ScriptPath -and $f -eq $ScriptPath) { return $false }
  $dest = Join-Path (Join-Path $Quar 'files') ($f -replace '^([A-Za-z]):', '$1')
  try {
    New-Item -ItemType Directory -Force -Path (Split-Path -Path $dest -Parent) | Out-Null
    Move-Item -LiteralPath $f -Destination $dest -Force -ErrorAction Stop
    return $true
  } catch { Warn "Couldn't quarantine $f ($($_.Exception.Message))"; return $false }
}
# Lists files, then asks: all / each / none
function Invoke-QuarantineList([string]$Desc, [string[]]$Files) {
  $Files = @($Files | Where-Object { $_ -and -not (Test-Protected $_) } | Sort-Object -Unique)
  if ($Files.Count -eq 0) { Info "No $Desc found."; return }
  Write-Host ("Found {0} {1}:" -f $Files.Count, $Desc) -ForegroundColor White
  $Files | Select-Object -First 40 | ForEach-Object { Write-Host "   $_" }
  if ($Files.Count -gt 40) { Write-Host ("   ... and {0} more (full list in REVIEW-ME.txt)" -f ($Files.Count - 40)) }
  Review "--- $Desc ---"; foreach ($f in $Files) { Review "   $f" }; Review ''
  do {
    $a = Read-Host '[?] Quarantine them? [a]ll / [e]ach (ask per file) / [n]one'
    if ($null -eq $a) { $a = 'n' }
    $a = $a.Trim().ToLower()
  } while ($a -ne 'a' -and $a -ne 'e' -and $a -ne 'n')
  if ($a -eq 'n') { Info 'Left in place - listed in REVIEW-ME.txt'; return }
  $n = 0
  foreach ($f in $Files) {
    if (-not (Test-Path -LiteralPath $f)) { continue }
    if ($a -eq 'e') {
      $kb = [math]::Round(((Get-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue).Length) / 1KB)
      if (-not (Ask-YN "   Quarantine $f ($kb KB)?")) { continue }
    }
    if (Move-ToQuarantine $f) { $n++ }
  }
  Log "Quarantined $n $Desc (originals kept under $Quar\files)"
}


#-------------------------------- services ------------------------------------
function Disable-Svc([string[]]$Names) {
  foreach ($n in $Names) {
    $s = Get-Service -Name $n -ErrorAction SilentlyContinue
    if (-not $s) { continue }
    if (Test-Protected "$($s.Name) $($s.DisplayName)") { continue }
    if ($s.StartType -eq 'Disabled' -and $s.Status -ne 'Running') { continue }
    try { Stop-Service -Name $n -Force -ErrorAction Stop } catch {}
    try { Set-Service -Name $n -StartupType Disabled -ErrorAction Stop; Log "Stopped & disabled service: $($s.DisplayName) ($n)" }
    catch {
      & sc.exe config $n start= disabled 2>&1 | Out-Null
      if ($LASTEXITCODE -eq 0) { Log "Stopped & disabled service: $($s.DisplayName) ($n)" } else { Warn "Couldn't disable service $n" }
    }
  }
}
function Enable-Svc([string]$Name, [string]$Mode = 'Automatic') {
  $s = Get-Service -Name $Name -ErrorAction SilentlyContinue
  if (-not $s) { return $false }
  try { Set-Service -Name $Name -StartupType $Mode -ErrorAction Stop } catch { & sc.exe config $Name start= auto 2>&1 | Out-Null }
  try { Start-Service -Name $Name -ErrorAction Stop } catch {}
  Start-Sleep -Seconds 1
  return ((Get-Service -Name $Name -ErrorAction SilentlyContinue).Status -eq 'Running')
}

#------------------------- local group membership -----------------------------
# ADSI instead of Get-LocalGroupMember: that cmdlet fails when a group holds the
# orphaned SID of a deleted user, which is common on these images.
function Get-GroupMembersSafe([string]$GroupName) {
  $out = @()
  try {
    $g = [ADSI]"WinNT://$env:COMPUTERNAME/$GroupName,group"
    foreach ($m in @($g.psbase.Invoke('Members'))) {
      $path = $m.GetType().InvokeMember('ADsPath', 'GetProperty', $null, $m, $null)
      $name = $m.GetType().InvokeMember('Name', 'GetProperty', $null, $m, $null)
      $parts = @(($path -replace '^WinNT://', '') -split '/')
      $isLocal = ($parts.Count -ge 2 -and $parts[$parts.Count - 2] -eq $env:COMPUTERNAME)
      $out += [pscustomobject]@{ Name = $name; Path = $path; IsLocal = $isLocal; IsOrphan = ($name -match '^S-1-5-') }
    }
  } catch {}
  return $out
}
function Remove-GroupMemberSafe([string]$GroupName, $Member) {
  try { $g = [ADSI]"WinNT://$env:COMPUTERNAME/$GroupName,group"; $g.Remove($Member.Path); return $true } catch { return $false }
}
function Get-GroupNameBySid([string]$sid) { $g = Get-LocalGroup -SID $sid -ErrorAction SilentlyContinue; if ($g) { return $g.Name }; return $null }

###############################################################################
#  PHASE 1 - QUESTIONS (asked up front so the rest runs mostly unattended)
###############################################################################
$OS       = Get-CimInstance -ClassName Win32_OperatingSystem
$IsServer = ($OS.ProductType -ne 1)
$IsDC     = ($OS.ProductType -eq 2)
$OSName   = $OS.Caption
if ($IsDC) {
  try { Import-Module ActiveDirectory -ErrorAction Stop }
  catch { Write-Host 'This is a domain controller, but the ActiveDirectory PowerShell module is missing.' -ForegroundColor Red; exit 1 }
}
function Get-Rid([string]$sid) { return [int](($sid -split '-')[-1]) }
function Split-Names([string]$s) { return @(($s -replace ',', ' ') -split '\s+' | Where-Object { $_ } | Sort-Object -Unique) }

Clear-Host
Write-Host '=========================================================================' -ForegroundColor Cyan
Write-Host '   CyberPatriot Windows hardening script' -ForegroundColor Cyan
Write-Host '=========================================================================' -ForegroundColor Cyan
Write-Host " Detected OS : $OSName  ($(if ($IsDC) { 'DOMAIN CONTROLLER' } elseif ($IsServer) { 'server' } else { 'workstation' }))"
Write-Host " Your account: $MeFull"
if ($OS.ProductType -ne 1) { Write-Host " Server type : $([string](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).InstallationType)  (build $($OS.BuildNumber))" }
Write-Host " Logs/report : $Out"
Write-Host " Backups     : $Backup"
Write-Host ''
Write-Host 'STOP: answer the FORENSICS QUESTIONS before running this.' -ForegroundColor Red
Write-Host 'This script removes users, software and media files they may ask about.' -ForegroundColor Red
if (-not (Ask-YN 'Forensics questions answered (or answers saved) and README read?')) { Write-Host "Run it again when you're ready."; exit 0 }

#--------------------------------- users --------------------------------------
Section 'Authorized users (copy them from the README)'
$AdminGroup = Get-GroupNameBySid 'S-1-5-32-544'
$UsersGroup = Get-GroupNameBySid 'S-1-5-32-545'
if ($IsDC) {
  $Dom        = Get-ADDomain
  $DomSid     = $Dom.DomainSID.Value
  $AdminSids  = @("$DomSid-512", "$DomSid-519", "$DomSid-518", 'S-1-5-32-544')   # Domain/Enterprise/Schema Admins, Administrators
  $AllAD      = @(Get-ADUser -Filter * -Properties Enabled)
  $HumanUsers = @($AllAD | Where-Object { (Get-Rid $_.SID.Value) -ge 1000 } | ForEach-Object { $_.SamAccountName })
  $BuiltinAdmin = ($AllAD | Where-Object { $_.SID.Value -eq "$DomSid-500" }).SamAccountName
} else {
  $HumanUsers = @(Get-LocalUser | Where-Object { (Get-Rid $_.SID.Value) -ge 1000 } | ForEach-Object { $_.Name })
  $BuiltinAdmin = (Get-LocalUser | Where-Object { $_.SID.Value -like '*-500' }).Name
}
# current admins: a list of {Name, Path, IsLocal, IsOrphan}
function Get-CurrentAdmins {
  if ($IsDC) {
    $r = @()
    foreach ($gs in $AdminSids) {
      try { foreach ($m in @(Get-ADGroupMember -Identity $gs -ErrorAction Stop)) {
        if ($m.objectClass -eq 'user') { $r += [pscustomobject]@{ Name = $m.SamAccountName; Path = $gs; IsLocal = $true; IsOrphan = $false } } } } catch {}
    }
    return $r
  }
  return @(Get-GroupMembersSafe $AdminGroup)
}
Write-Host "Human accounts currently on this machine$(if ($IsDC) { ' (domain)' }):"
$HumanUsers | ForEach-Object { Write-Host "   $_" }

while ($true) {
  $AuthAdmins = Split-Names (Ask 'AUTHORIZED ADMINISTRATORS (space/comma separated, include yourself):')
  $AuthStd    = Split-Names (Ask 'AUTHORIZED STANDARD USERS (space/comma separated, Enter if none):')
  if ($AuthAdmins -notcontains $Me) { $AuthAdmins += $Me }
  $AuthStd = @($AuthStd | Where-Object { $AuthAdmins -notcontains $_ })
  $AuthAll = @($AuthAdmins + $AuthStd)

  $ToDelete  = @($HumanUsers | Where-Object { $AuthAll -notcontains $_ -and $_ -ne $Me })
  $ToCreate  = @($AuthAll | Where-Object { $HumanUsers -notcontains $_ -and $_ -ne $BuiltinAdmin })
  $CurAdmins = @(Get-CurrentAdmins)
  $ToDemote  = @($CurAdmins | Where-Object { $_.IsLocal -and -not $_.IsOrphan -and $AuthAdmins -notcontains $_.Name -and
                                             $_.Name -ne $BuiltinAdmin -and $_.Name -ne $Me -and $ToDelete -notcontains $_.Name } |
                 ForEach-Object { $_.Name } | Sort-Object -Unique)
  $Orphans   = @($CurAdmins | Where-Object { $_.IsOrphan })
  $ToPromote = @($AuthAdmins | Where-Object { ($CurAdmins | ForEach-Object { $_.Name }) -notcontains $_ })

  Write-Host ''
  Write-Host '----------------------------- USER PLAN -----------------------------' -ForegroundColor White
  Write-Host " Administrators       : $($AuthAdmins -join ' ')"
  Write-Host " Standard users       : $(if ($AuthStd.Count) { $AuthStd -join ' ' } else { '(none)' })"
  Write-Host " DELETE (not in README): $(if ($ToDelete.Count) { $ToDelete -join ' ' } else { '(none)' })" -ForegroundColor Red
  Write-Host " Remove admin rights  : $(if ($ToDemote.Count) { $ToDemote -join ' ' } else { '(none)' })"
  Write-Host " Give admin rights    : $(if ($ToPromote.Count) { $ToPromote -join ' ' } else { '(none)' })"
  Write-Host " CREATE (missing)     : $(if ($ToCreate.Count) { $ToCreate -join ' ' } else { '(none)' })"
  if ($Orphans.Count) { Write-Host " Leftover SIDs in Administrators (deleted accounts): $($Orphans.Count) -> removed" }
  foreach ($c in $ToCreate) { foreach ($d in $ToDelete) {
    if ((Get-Lev $c.ToLower() $d.ToLower()) -le 2) { Write-Host " !! You typed '$c' (doesn't exist) but '$d' exists and would be DELETED. Typo?" -ForegroundColor Red } } }
  Write-Host '----------------------------------------------------------------------' -ForegroundColor White
  if (Ask-YN 'Is this plan EXACTLY right?') { break }
  Write-Host 'OK, enter the lists again.'
}
$DisableBuiltinAdmin = $false
if ($BuiltinAdmin -and $BuiltinAdmin -ne $Me -and $AuthAll -notcontains $BuiltinAdmin) {
  $ba = if ($IsDC) { Get-ADUser -Identity $BuiltinAdmin } else { Get-LocalUser -Name $BuiltinAdmin }
  if ($ba.Enabled) { $DisableBuiltinAdmin = Ask-YN "The built-in '$BuiltinAdmin' account is ENABLED. Disable it? (usually yes - you log in with your own admin account)" }
}
$GroupSpecs = @((Ask 'Groups the README wants created? Format group:user1,user2 (space between groups), Enter for none:') -split '\s+' | Where-Object { $_ })

#-------------------------------- password ------------------------------------
function ConvertTo-Plain([securestring]$s) {
  $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)
  try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) }
}
$DefaultPW = 'Cyb3rP@triot!2026'
while ($true) {
  $p1 = ConvertTo-Plain (Read-Host "[?] New password for all OTHER authorized users (Enter = $DefaultPW)" -AsSecureString)
  if (-not $p1) { $PlainPW = $DefaultPW; break }
  if ($p1.Length -lt 12 -or $p1 -cnotmatch '[A-Z]' -or $p1 -cnotmatch '[a-z]' -or $p1 -notmatch '[0-9]' -or $p1 -notmatch '[^A-Za-z0-9]') {
    Write-Host '    Needs 12+ characters with upper, lower, digit and symbol.'; continue }
  $p2 = ConvertTo-Plain (Read-Host '    Confirm' -AsSecureString)
  if ($p1 -ceq $p2) { $PlainPW = $p1; break }
  Write-Host "    Passwords didn't match."
}
$SecurePW = ConvertTo-SecureString $PlainPW -AsPlainText -Force
$ChangeMyPW = Ask-YN "Also change YOUR password ($Me)? Only if the README calls it weak - you MUST remember it."

#-------------------------------- services ------------------------------------
Section 'Critical services (answer from the README)'
function Ask-Svc([string]$q, [string[]]$svcs) {
  $tag = ''
  if ($svcs) {
    $tag = '(not installed)'
    foreach ($s in $svcs) { if (Get-Service -Name $s -ErrorAction SilentlyContinue) { $tag = '(installed)'; break } }
  }
  return (Ask-YN "$q $tag")
}
$NeedRDP   = Ask-Svc 'Remote Desktop (RDP) required?' @('TermService')
$NeedSMB   = Ask-Svc 'File sharing (SMB shared folders) required?' @()
$SmbEncrypt = $false
if ($NeedSMB) { $SmbEncrypt = Ask-YN '   ...REQUIRE encrypted SMB connections? (more secure; very old clients cannot connect)' }
$NeedWeb   = Ask-Svc 'Web server (IIS) required?' @('W3SVC')
$NeedFTP   = Ask-Svc 'FTP server (IIS FTP / FileZilla Server) required?' @('ftpsvc', 'filezilla-server', 'FileZilla Server')
$NeedDNS   = $false; if ($IsServer) { $NeedDNS = Ask-Svc 'DNS Server role required?' @('DNS') }
$NeedPrint = Ask-Svc 'Printing (Print Spooler) required?' @('Spooler')
$NeedSSH   = Ask-Svc 'OpenSSH server required?' @('sshd')
$SshAllowUsers = $false
if ($NeedSSH) { $SshAllowUsers = Ask-YN '   ...allow SSH logins ONLY for the authorized users you entered (AllowUsers)? (usually yes)' }
$NeedWinRM = $true
if (-not $IsServer) { $NeedWinRM = Ask-Svc 'PowerShell Remoting / WinRM required? (almost never on a workstation)' @('WinRM') }
$NeedSNMP  = Ask-Svc 'SNMP service required?' @('SNMP')

# Every other installed server role: keep it only if the README needs it
$RoleRemove = @(); $KeptRoles = @(); $NeedDHCP = $false; $EnforceGPO = $false; $SetMAQ = $false; $InstallType = ''
if ($IsServer) {
  Section 'Server roles (answer from the README)'
  $InstallType = [string](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).InstallationType
  $covered = @('FileAndStorage-Services', 'DNS', 'Web-Server', 'Print-Services')      # decided by the questions above
  if ($IsDC) { $covered += 'AD-Domain-Services' }
  $roles = @(Get-WindowsFeature -ErrorAction SilentlyContinue | Where-Object { $_.Installed -and $_.FeatureType -eq 'Role' -and $covered -notcontains $_.Name })
  foreach ($r in $roles) {
    if (Ask-YN "Server role '$($r.DisplayName)' is installed. Is it REQUIRED by the README?") { $KeptRoles += $r.Name; if ($r.Name -eq 'DHCP') { $NeedDHCP = $true } }
    else { $RoleRemove += $r }
  }
  if (-not $roles.Count) { Write-Host '   (no other server roles are installed)' }
}
if ($IsDC) {
  if (Get-Module -ListAvailable -Name GroupPolicy) {
    $EnforceGPO = Ask-YN 'Also write the security settings into Group Policy so the next policy refresh cannot undo them? (recommended on a domain controller)'
  } else { Write-Host '   (GroupPolicy PowerShell module missing - settings are applied locally only)' -ForegroundColor Yellow }
  $SetMAQ = Ask-YN 'Stop normal users from adding computers to the domain (machine account quota = 0)? (usually yes)'
}
$HardenTLS = Ask-YN 'Turn off old SSL/TLS (SSL 3.0, TLS 1.0/1.1) and weak ciphers like RC4/3DES? (recommended; only very old programs break)'
$DisableUSB = Ask-YN 'Disable USB storage? (blocks USB flash drives - safe in a contest VM)'
Write-Host ''
Write-Host 'Install Windows Updates at the END of the script?'
Write-Host '   f = ALL available updates (best for points; can take 30+ minutes)'
Write-Host '   c = security, critical and Defender updates only'
Write-Host '   s = skip'
do { $UpdateMode = (Ask 'Choice [f/c/s]:').ToLower() } while ($UpdateMode -ne 'f' -and $UpdateMode -ne 'c' -and $UpdateMode -ne 's')
$RunScan = Ask-YN 'Run a Windows Defender QUICK scan at the end? (5-15 minutes)'

# README-critical services that must end up enabled AND running: name -> service names to try
$Crit = [ordered]@{}
if ($NeedRDP)   { $Crit['Remote Desktop'] = @('TermService') }
if ($NeedSMB)   { $Crit['File sharing']   = @('LanmanServer') }
if ($NeedWeb)   { $Crit['IIS web server'] = @('W3SVC', 'WAS') }
if ($NeedFTP)   { $Crit['FTP server']     = @('ftpsvc', 'filezilla-server', 'FileZilla Server') }
if ($NeedDNS)   { $Crit['DNS server']     = @('DNS') }
if ($NeedPrint) { $Crit['Print Spooler']  = @('Spooler') }
if ($NeedSSH)   { $Crit['OpenSSH server'] = @('sshd') }
if ($NeedSNMP)  { $Crit['SNMP']           = @('SNMP') }
# services behind server roles the README keeps
$RoleSvc = @{ 'DHCP' = 'DHCPServer'; 'RemoteAccess' = 'RemoteAccess'; 'Fax' = 'Fax'; 'WDS' = 'WDSServer'; 'UpdateServices' = 'WsusService'; 'NPAS' = 'IAS'; 'AD-Certificate' = 'CertSvc'; 'Hyper-V' = 'vmms' }
foreach ($kr in $KeptRoles) { if ($RoleSvc.ContainsKey($kr)) { $Crit["Server role $kr"] = @($RoleSvc[$kr]) } }

Write-Host ''
Write-Host ("Summary: RDP={0} SMB={1} IIS={2} FTP={3} DNS={4} Print={5} SSH={6} WinRM={7} SNMP={8} Updates={9}" -f $NeedRDP, $NeedSMB, $NeedWeb, $NeedFTP, $NeedDNS, $NeedPrint, $NeedSSH, $NeedWinRM, $NeedSNMP, $UpdateMode) -ForegroundColor White
if (-not (Ask-YN 'Start hardening now?')) { exit 0 }
Review ("Answers: RDP={0} SMB={1} IIS={2} FTP={3} DNS={4} Print={5} SSH={6} WinRM={7} SNMP={8}" -f $NeedRDP, $NeedSMB, $NeedWeb, $NeedFTP, $NeedDNS, $NeedPrint, $NeedSSH, $NeedWinRM, $NeedSNMP)
Review ''

###############################################################################
#  PHASE 2 - HARDENING
###############################################################################

# Fast recursive file walk that never follows junctions (old "Application Data"-style
# junctions loop forever / spam access-denied in Windows PowerShell 5.1).
function Get-FilesSafe([string]$Root, [string[]]$SkipDirNames = @(), [int]$Max = 200000) {
  if (-not (Test-Path -LiteralPath $Root)) { return }
  $stack = New-Object System.Collections.Stack
  $stack.Push($Root); $count = 0
  while ($stack.Count -gt 0) {
    $d = [string]$stack.Pop()
    try { $entries = (New-Object System.IO.DirectoryInfo $d).GetFileSystemInfos() } catch { continue }
    foreach ($e in $entries) {
      if ($e.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
      if ($e -is [IO.DirectoryInfo]) { if ($SkipDirNames -notcontains $e.Name) { $stack.Push($e.FullName) } }
      else { $e; $count++; if ($count -ge $Max) { return } }
    }
  }
}
$UserDirs = @(Get-ChildItem -LiteralPath 'C:\Users' -Directory -Force -ErrorAction SilentlyContinue |
              Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -and $_.Name -ne 'Default' } |
              ForEach-Object { $_.FullName })
$PersonalSub = @('Desktop', 'Documents', 'Downloads', 'Music', 'Pictures', 'Videos', 'Favorites', 'OneDrive')

#------------------------------ FORENSICS SNAPSHOT ----------------------------
# Taken BEFORE anything changes, so the answers survive user deletion, file
# quarantine and uninstalls. Everything in this block only READS.
Section 'Forensics snapshot (read-only, before any changes)'
Write-Host '   Collecting (a minute or two)...'
function FSec([string]$t) { Add-Content -LiteralPath $ForFile -Value "`r`n==================== $t ====================" }
function FOut { param([Parameter(ValueFromPipeline = $true)]$InputObject)
  begin { $buf = New-Object System.Collections.ArrayList } process { [void]$buf.Add($InputObject) }
  end { if ($buf.Count) { ($buf | Out-String -Width 320).TrimEnd() | Add-Content -LiteralPath $ForFile } } }
function FTry([string]$title, [scriptblock]$sb) { FSec $title; try { & $sb 2>$null | FOut } catch { "(could not collect: $($_.Exception.Message))" | FOut } }

Set-Content -LiteralPath $ForFile -Value @(
  "FORENSICS SNAPSHOT - $(Get-Date)"
  "Host: $env:COMPUTERNAME   OS: $OSName ($($OS.Version))   Installed: $($OS.InstallDate)   Last boot: $($OS.LastBootUpTime)"
  'Taken before the hardening script changed anything. Use it to answer forensics questions.'
)
FTry 'User accounts' {
  if ($IsDC) { Get-ADUser -Filter * -Properties Enabled, LastLogonDate, PasswordLastSet, PasswordNeverExpires, PasswordNotRequired, DoesNotRequirePreAuth, AllowReversiblePasswordEncryption, Description, whenCreated |
               Select-Object SamAccountName, Enabled, whenCreated, LastLogonDate, PasswordLastSet, PasswordNeverExpires, PasswordNotRequired, DoesNotRequirePreAuth, AllowReversiblePasswordEncryption, Description | Format-Table -AutoSize }
  else { Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordLastSet, PasswordRequired, PasswordExpires, UserMayChangePassword, Description, SID | Format-Table -AutoSize }
}
FTry 'Groups and their members' {
  if ($IsDC) {
    foreach ($g in Get-ADGroup -Filter *) { $m = @(Get-ADGroupMember -Identity $g -ErrorAction SilentlyContinue | ForEach-Object { $_.SamAccountName })
      if ($m.Count) { '{0}: {1}' -f $g.Name, ($m -join ', ') } }
  } else {
    foreach ($g in Get-LocalGroup) { $m = @(Get-GroupMembersSafe $g.Name | ForEach-Object { $_.Name })
      if ($m.Count) { '{0}: {1}' -f $g.Name, ($m -join ', ') } }
  }
}
FTry 'Accounts hidden from the login screen (SpecialAccounts\UserList)' { Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList' -ErrorAction Stop | Select-Object * -ExcludeProperty PS* | Format-List }
FTry 'Logged on now' { & quser.exe 2>&1 }
FTry 'PowerShell command history (what users typed)' {
  foreach ($u in $UserDirs) { $h = Join-Path $u 'AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt'
    if (Test-Path -LiteralPath $h) { "---------- $h  (modified $((Get-Item -LiteralPath $h -Force).LastWriteTime))"; Get-Content -LiteralPath $h -Tail 400 } }
}
FTry 'Recently opened files (Recent folder, newest first)' {
  foreach ($u in $UserDirs) { $r = Join-Path $u 'AppData\Roaming\Microsoft\Windows\Recent'
    if (Test-Path -LiteralPath $r) { "-- $u"; Get-ChildItem -LiteralPath $r -Filter *.lnk -Force -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 60 | ForEach-Object { '   {0:yyyy-MM-dd HH:mm}  {1}' -f $_.LastWriteTime, $_.BaseName } } }
}
$UserFiles = New-Object System.Collections.ArrayList
foreach ($u in $UserDirs) { foreach ($f in Get-FilesSafe $u @('AppData', 'node_modules') 60000) { [void]$UserFiles.Add($f) } }
FTry 'Files in user folders changed in the last 30 days (newest first, AppData skipped)' {
  $cut = (Get-Date).AddDays(-30)
  $UserFiles | Where-Object { $_.LastWriteTime -gt $cut } | Sort-Object LastWriteTime -Descending | Select-Object -First 400 | ForEach-Object { '{0:yyyy-MM-dd HH:mm}  {1}' -f $_.LastWriteTime, $_.FullName }
}
FTry 'Hidden files in user folders (beyond the usual ones)' {
  $UserFiles | Where-Object { ($_.Attributes -band [IO.FileAttributes]::Hidden) -and $_.Name -notmatch '^(?i)(desktop\.ini|ntuser.*|thumbs\.db|usrclass.*|iconcache.*)$' } | ForEach-Object { $_.FullName }
}
$Personal = @($UserFiles | Where-Object { $p = $_.FullName; ($PersonalSub | Where-Object { $p -match ('\\Users\\[^\\]+\\' + [regex]::Escape($_) + '\\') }) } | Where-Object { $_.FullName -notlike "$Out*" })
FTry 'Alternate data streams (hidden data) and download sources (Zone.Identifier)' {
  foreach ($f in ($Personal | Select-Object -First 3000)) {
    foreach ($s in @(Get-Item -LiteralPath $f.FullName -Stream * -ErrorAction SilentlyContinue)) {
      if ($s.Stream -eq ':$DATA') { continue }
      if ($s.Stream -eq 'Zone.Identifier') {
        $z = (Get-Content -LiteralPath $f.FullName -Stream 'Zone.Identifier' -ErrorAction SilentlyContinue | Where-Object { $_ -match '^(HostUrl|ReferrerUrl)=' }) -join '  '
        if ($z) { "DOWNLOADED  $($f.FullName)  $z" }
      } else { "HIDDEN STREAM  $($f.FullName):$($s.Stream)  ($($s.Length) bytes)" }
    }
  }
}
FTry 'File hashes of personal files (MD5 / SHA1 / SHA256)' {
  foreach ($f in ($Personal | Where-Object { $_.Length -lt 25MB } | Select-Object -First 300)) {
    "{0}   ({1} bytes, modified {2:yyyy-MM-dd HH:mm:ss})" -f $f.FullName, $f.Length, $f.LastWriteTime
    foreach ($alg in 'MD5', 'SHA1', 'SHA256') { '   {0,-7}{1}' -f $alg, (Get-FileHash -LiteralPath $f.FullName -Algorithm $alg -ErrorAction SilentlyContinue).Hash }
  }
}
FTry 'Recycle Bin contents (original paths)' {
  foreach ($i in Get-ChildItem -LiteralPath 'C:\$Recycle.Bin' -Recurse -Force -Filter '$I*' -ErrorAction SilentlyContinue) {
    try { $b = [IO.File]::ReadAllBytes($i.FullName); $ver = [BitConverter]::ToInt64($b, 0)
      $when = [DateTime]::FromFileTime([BitConverter]::ToInt64($b, 16))
      if ($ver -ge 2) { $len = [BitConverter]::ToInt32($b, 24); $path = [Text.Encoding]::Unicode.GetString($b, 28, ($len - 1) * 2) }
      else { $path = ([Text.Encoding]::Unicode.GetString($b, 24, 520)).TrimEnd([char]0) }
      '{0:yyyy-MM-dd HH:mm}  deleted: {1}   (sid folder {2})' -f $when, $path, $i.Directory.Name } catch {}
  }
}
$UninstallKeys = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*')
FTry 'Installed programs' { Get-ItemProperty $UninstallKeys -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName } | Sort-Object DisplayName | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation | Format-Table -AutoSize }
FTry 'Services (non-Microsoft first)' { Get-CimInstance Win32_Service | Sort-Object { $_.PathName -match '\\Windows\\' }, Name | Select-Object Name, State, StartMode, StartName, PathName | Format-Table -AutoSize }
FTry 'Scheduled tasks outside \Microsoft\' { Get-ScheduledTask | Where-Object { $_.TaskPath -notlike '\Microsoft\*' } | ForEach-Object {
  '{0}{1}  [{2}]  author={3}  created={4}' -f $_.TaskPath, $_.TaskName, $_.State, $_.Author, $_.Date
  foreach ($a in $_.Actions) { '      runs: {0} {1}' -f $a.Execute, $a.Arguments } } }
FTry 'Run keys (programs started at login)' {
  foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce') {
    $p = Get-ItemProperty -LiteralPath $k -ErrorAction SilentlyContinue
    if ($p) { $p.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object { '{0}  {1} = {2}' -f $k, $_.Name, $_.Value } } }
  foreach ($u in $UserDirs + 'C:\ProgramData') { $s = Join-Path $u 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup'
    if ($u -eq 'C:\ProgramData') { $s = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp' }
    Get-ChildItem -LiteralPath $s -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' } | ForEach-Object { "Startup folder: $($_.FullName)" } }
}
FTry 'Listening ports and the program behind each' {
  Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Sort-Object LocalPort | ForEach-Object {
    $pr = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    'TCP {0,-6} {1,-16} pid {2,-6} {3}  {4}' -f $_.LocalPort, $_.LocalAddress, $_.OwningProcess, $pr.ProcessName, $pr.Path }
  Get-NetUDPEndpoint -ErrorAction SilentlyContinue | Sort-Object LocalPort | ForEach-Object {
    $pr = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    'UDP {0,-6} {1,-16} pid {2,-6} {3}  {4}' -f $_.LocalPort, $_.LocalAddress, $_.OwningProcess, $pr.ProcessName, $pr.Path }
}
FTry 'Established network connections' { Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | ForEach-Object {
  '{0}:{1} -> {2}:{3}  pid {4} {5}' -f $_.LocalAddress, $_.LocalPort, $_.RemoteAddress, $_.RemotePort, $_.OwningProcess, (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName } }
FTry 'Running processes (with command lines)' { Get-CimInstance Win32_Process | Sort-Object Name | Select-Object ProcessId, ParentProcessId, Name, ExecutablePath, CommandLine | Format-Table -AutoSize -Wrap }
FTry 'Shared folders and their permissions' { foreach ($s in Get-SmbShare -ErrorAction SilentlyContinue) {
  '{0}  ->  {1}   {2}' -f $s.Name, $s.Path, $s.Description
  Get-SmbShareAccess -Name $s.Name -ErrorAction SilentlyContinue | ForEach-Object { '      {0} {1} {2}' -f $_.AccountName, $_.AccessControlType, $_.AccessRight } } }
FTry 'Custom inbound firewall ALLOW rules (not part of a Windows group)' {
  Get-NetFirewallRule -Direction Inbound -Action Allow -Enabled True -ErrorAction SilentlyContinue | Where-Object { -not $_.Group } | ForEach-Object {
    $app = ($_ | Get-NetFirewallApplicationFilter).Program; $port = ($_ | Get-NetFirewallPortFilter)
    '{0}  program={1}  protocol={2}  ports={3}' -f $_.DisplayName, $app, $port.Protocol, ($port.LocalPort -join ',') } }
FTry 'Windows Defender status and exclusions' {
  Get-MpComputerStatus -ErrorAction Stop | Select-Object AMServiceEnabled, AntivirusEnabled, RealTimeProtectionEnabled, BehaviorMonitorEnabled, AntivirusSignatureLastUpdated | Format-List
  $mp = Get-MpPreference -ErrorAction Stop
  'ExclusionPath: {0}' -f ($mp.ExclusionPath -join '; '); 'ExclusionProcess: {0}' -f ($mp.ExclusionProcess -join '; '); 'ExclusionExtension: {0}' -f ($mp.ExclusionExtension -join '; ') }
FTry 'hosts file (active lines)' { Get-Content -LiteralPath "$env:SystemRoot\System32\drivers\etc\hosts" | Where-Object { $_ -and $_ -notmatch '^\s*#' } }
FTry 'DNS cache' { Get-DnsClientCache -ErrorAction SilentlyContinue | Select-Object Entry, Data | Format-Table -AutoSize }
FTry 'Security log: account changes, group changes, failed logons, lockouts (newest first)' {
  Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4720, 4722, 4723, 4724, 4725, 4726, 4728, 4732, 4738, 4740, 4756, 4625, 4648 } -MaxEvents 300 -ErrorAction Stop |
    ForEach-Object { '{0:yyyy-MM-dd HH:mm:ss}  {1}  {2}' -f $_.TimeCreated, $_.Id, (($_.Message -replace '\s+', ' ').Substring(0, [Math]::Min(300, ($_.Message -replace '\s+', ' ').Length))) } }
FTry 'Remote Desktop logons (4624 type 10)' {
  Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4624 } -MaxEvents 3000 -ErrorAction Stop | Where-Object { $_.Properties[8].Value -eq 10 } | Select-Object -First 50 |
    ForEach-Object { '{0:yyyy-MM-dd HH:mm:ss}  user={1}\{2}  from={3}' -f $_.TimeCreated, $_.Properties[6].Value, $_.Properties[5].Value, $_.Properties[18].Value } }
FTry 'New services installed (System log 7045)' { Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 7045 } -MaxEvents 60 -ErrorAction Stop |
  ForEach-Object { '{0:yyyy-MM-dd HH:mm}  {1}' -f $_.TimeCreated, (($_.Message -replace '\s+', ' ').Substring(0, [Math]::Min(260, ($_.Message -replace '\s+', ' ').Length))) } }
FTry 'USB storage devices ever connected' { Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR' -ErrorAction Stop | ForEach-Object { Get-ChildItem $_.PSPath | ForEach-Object { (Get-ItemProperty $_.PSPath).FriendlyName } } }
FTry 'Programs recently run (Prefetch)' { Get-ChildItem 'C:\Windows\Prefetch\*.pf' -ErrorAction Stop | Sort-Object LastWriteTime -Descending | Select-Object -First 120 | ForEach-Object { '{0:yyyy-MM-dd HH:mm}  {1}' -f $_.LastWriteTime, ($_.BaseName -replace '-[0-9A-F]{8}$', '') } }
FTry 'Network configuration' { Get-NetIPAddress -ErrorAction SilentlyContinue | Select-Object InterfaceAlias, IPAddress, PrefixLength | Format-Table -AutoSize; Get-DnsClientServerAddress -ErrorAction SilentlyContinue | Where-Object { $_.ServerAddresses } | Select-Object InterfaceAlias, ServerAddresses | Format-Table -AutoSize; & netsh.exe interface portproxy show all }
FTry 'Audit policy (before)' { & auditpol.exe /get /category:* }
if ($IsServer) {
  FTry 'Server roles & features installed' { Get-WindowsFeature | Where-Object { $_.Installed } | Select-Object Name, DisplayName, FeatureType | Format-Table -AutoSize }
  FTry 'IIS web / FTP sites (bindings and folders)' { $ac = "$env:windir\System32\inetsrv\appcmd.exe"; if (Test-Path $ac) { & $ac list site; & $ac list vdir; & $ac list apppool } }
  FTry 'DNS zones and records' { foreach ($z in @(Get-DnsServerZone -ErrorAction Stop | Where-Object { -not $_.IsAutoCreated })) {
    "-- zone $($z.ZoneName)  type=$($z.ZoneType)  AD-integrated=$($z.IsDsIntegrated)  transfers=$($z.SecureSecondaries)  dynamic-update=$($z.DynamicUpdate)"
    Get-DnsServerResourceRecord -ZoneName $z.ZoneName -ErrorAction SilentlyContinue | Select-Object -First 80 | ForEach-Object { '   {0,-30} {1,-6} {2}' -f $_.HostName, $_.RecordType, (($_.RecordData.PSObject.Properties | Where-Object { $_.Name -notlike 'Cim*' -and $_.Name -ne 'PSComputerName' } | ForEach-Object { $_.Value }) -join ' ') } } }
  FTry 'DHCP scopes and leases' { foreach ($sc in @(Get-DhcpServerv4Scope -ErrorAction Stop)) { "-- scope $($sc.ScopeId) $($sc.Name) $($sc.StartRange)-$($sc.EndRange) state=$($sc.State)"
    Get-DhcpServerv4Lease -ScopeId $sc.ScopeId -ErrorAction SilentlyContinue | ForEach-Object { '   {0,-16} {1,-20} {2}' -f $_.IPAddress, $_.ClientId, $_.HostName } } }
}
if ($IsDC) {
  FTry 'AD: domain password policy and fine-grained password policies' { Get-ADDefaultDomainPasswordPolicy | Format-List *; Get-ADFineGrainedPasswordPolicy -Filter * -ErrorAction SilentlyContinue | Format-List Name, Precedence, MinPasswordLength, ComplexityEnabled, ReversibleEncryptionEnabled, LockoutThreshold, AppliesTo }
  FTry 'AD: computers' { Get-ADComputer -Filter * -Properties OperatingSystem, LastLogonDate, TrustedForDelegation, whenCreated | Select-Object Name, OperatingSystem, whenCreated, LastLogonDate, TrustedForDelegation | Format-Table -AutoSize }
  FTry 'AD: OUs, trusts, krbtgt, accounts with SPNs / delegation' {
    Get-ADOrganizationalUnit -Filter * | ForEach-Object { "OU: $($_.DistinguishedName)" }
    Get-ADTrust -Filter * -ErrorAction SilentlyContinue | ForEach-Object { "Trust: $($_.Name) direction=$($_.Direction)" }
    "krbtgt password last set: $((Get-ADUser krbtgt -Properties PasswordLastSet).PasswordLastSet)"
    Get-ADUser -Filter { ServicePrincipalName -like '*' } -Properties ServicePrincipalName | Where-Object { $_.SamAccountName -ne 'krbtgt' } | ForEach-Object { "SPN user (Kerberoastable): $($_.SamAccountName)  $($_.ServicePrincipalName -join ', ')" }
    Get-ADObject -Filter { msDS-AllowedToDelegateTo -like '*' } -Properties msDS-AllowedToDelegateTo -ErrorAction SilentlyContinue | ForEach-Object { "Constrained delegation: $($_.Name) -> $($_.'msDS-AllowedToDelegateTo' -join ', ')" } }
  FTry 'Group Policy objects (name, status, last modified, where linked)' {
    Import-Module GroupPolicy -ErrorAction Stop
    foreach ($g in Get-GPO -All) { '{0}  status={1}  modified={2}  id={3}' -f $g.DisplayName, $g.GpoStatus, $g.ModificationTime, $g.Id }
    foreach ($t in @($Dom.DistinguishedName, $Dom.DomainControllersContainer) + @(Get-ADOrganizationalUnit -Filter * | ForEach-Object { $_.DistinguishedName })) {
      $l = @((Get-GPInheritance -Target $t -ErrorAction SilentlyContinue).GpoLinks); if ($l.Count) { "-- linked at $t : $(($l | ForEach-Object { "$($_.DisplayName)$(if (-not $_.Enabled) { ' (disabled)' })" }) -join ', ')" } }
    Get-GPOReport -All -ReportType Html -Path (Join-Path $LogDir 'gpo-report-before.html') -ErrorAction SilentlyContinue; "Full GPO report: $LogDir\gpo-report-before.html"
  }
}
Log "Forensics snapshot saved: $ForFile  (open it while you answer the forensics questions)"

#--------------------------------- BACKUPS ------------------------------------
Section 'Backups'
& secedit.exe /export /cfg "$Backup\secpol-before.inf" /quiet 2>&1 | Out-Null
& auditpol.exe /backup /file:"$Backup\auditpol-before.csv" 2>&1 | Out-Null
& netsh.exe advfirewall export "$Backup\firewall-before.wfw" 2>&1 | Out-Null
$RegBackups = [ordered]@{
  'Policies'          = 'HKLM\SOFTWARE\Policies'
  'PoliciesCurVer'    = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies'
  'Lsa'               = 'HKLM\SYSTEM\CurrentControlSet\Control\Lsa'
  'LanmanServer'      = 'HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
  'LanmanWorkstation' = 'HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters'
  'Winlogon'          = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
  'TerminalServer'    = 'HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server'
  'Run'               = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
  'IFEO'              = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
}
foreach ($k in $RegBackups.Keys) { & reg.exe export $RegBackups[$k] "$Backup\reg-$k.reg" /y 2>&1 | Out-Null }
Get-Service | Select-Object Name, DisplayName, Status, StartType | Export-Csv -LiteralPath "$Backup\services-before.csv" -NoTypeInformation
if ($IsServer) { Get-WindowsFeature -ErrorAction SilentlyContinue | Where-Object { $_.Installed } | Select-Object Name, DisplayName | Export-Csv -LiteralPath "$Backup\features-before.csv" -NoTypeInformation }
if ($IsDC -and (Get-Module -ListAvailable -Name GroupPolicy)) {
  try { Import-Module GroupPolicy -ErrorAction Stop; New-Item -ItemType Directory -Force -Path "$Backup\GPO" | Out-Null
        Backup-GPO -All -Path "$Backup\GPO" -ErrorAction Stop | Out-Null
        Log "All Group Policy objects backed up to $Backup\GPO  (undo with: Restore-GPO -All -Path $Backup\GPO)" }
  catch { Warn "Couldn't back up the GPOs ($($_.Exception.Message)) - Group Policy will NOT be edited"; $EnforceGPO = $false }
}
Copy-Item -LiteralPath "$env:SystemRoot\System32\drivers\etc\hosts" -Destination "$Backup\hosts-before" -ErrorAction SilentlyContinue
if (-not $IsServer) {
  try {
    Enable-ComputerRestore -Drive 'C:\' -ErrorAction SilentlyContinue
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' 'SystemRestorePointCreationFrequency' 0 | Out-Null
    Checkpoint-Computer -Description "Before CyberPatriot script $Stamp" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    Log 'System Restore point created (Control Panel > Recovery can roll everything back)'
  } catch { Warn "Couldn't create a restore point ($($_.Exception.Message))" }
}
Log "Backups saved in $Backup (security policy, audit policy, firewall, registry, services, hosts)"

#---------------------------------- USERS -------------------------------------
Section 'Users & groups'
$PrivGroupSids = @('S-1-5-32-551', 'S-1-5-32-547', 'S-1-5-32-556', 'S-1-5-32-569', 'S-1-5-32-578', 'S-1-5-32-579', 'S-1-5-32-580')   # Backup/Power/NetConfig/Crypto Operators, Hyper-V & Access-Control admins, Remote Management
if ($IsDC) {
  #---------------- domain controller: Active Directory accounts ----------------
  foreach ($u in $ToCreate) {
    try { New-ADUser -Name $u -SamAccountName $u -AccountPassword $SecurePW -Enabled $true -PasswordNeverExpires $false -ChangePasswordAtLogon $false -ErrorAction Stop; Log "Created domain user $u (listed in README)" }
    catch { Warn "Couldn't create domain user $u ($($_.Exception.Message))" }
  }
  foreach ($u in $ToDelete) {
    if ($u -eq $Me) { continue }
    try { Get-ADUser -Identity $u | Set-ADObject -ProtectedFromAccidentalDeletion $false -ErrorAction SilentlyContinue
          Remove-ADUser -Identity $u -Confirm:$false -ErrorAction Stop; Log "Deleted unauthorized domain user $u" } catch { Warn "Couldn't delete $u ($($_.Exception.Message))" }
  }
  foreach ($gs in $AdminSids + @('S-1-5-32-548', 'S-1-5-32-549', 'S-1-5-32-550', 'S-1-5-32-551', "$DomSid-520")) {
    foreach ($m in @(Get-ADGroupMember -Identity $gs -ErrorAction SilentlyContinue | Where-Object { $_.objectClass -eq 'user' })) {
      if ($AuthAdmins -contains $m.SamAccountName -or $m.SamAccountName -eq $BuiltinAdmin -or $m.SamAccountName -eq $Me) { continue }
      try { Remove-ADGroupMember -Identity $gs -Members $m -Confirm:$false -ErrorAction Stop; Log "Removed $($m.SamAccountName) from privileged group $((Get-ADGroup -Identity $gs).Name)" } catch {}
    }
  }
  # Groups planted inside admin groups (e.g. Domain Users in Domain Admins) make everyone an admin
  $okNested = @("$DomSid-512", "$DomSid-519")      # Administrators normally contains Domain Admins + Enterprise Admins
  foreach ($gs in $AdminSids) {
    foreach ($m in @(Get-ADGroupMember -Identity $gs -ErrorAction SilentlyContinue | Where-Object { $_.objectClass -ne 'user' })) {
      if ($gs -eq 'S-1-5-32-544' -and $okNested -contains $m.SID.Value) { continue }
      $gname = (Get-ADGroup -Identity $gs).Name
      Warn "'$($m.Name)' ($($m.objectClass)) is a member of the admin group '$gname' - everyone in it is an admin"
      if (Ask-YN "   Remove '$($m.Name)' from '$gname'?") { try { Remove-ADGroupMember -Identity $gs -Members $m -Confirm:$false -ErrorAction Stop; Log "Removed $($m.Name) from $gname" } catch { Warn "Couldn't remove it ($($_.Exception.Message))" } }
    }
  }
  foreach ($u in $AuthAdmins) {
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$u'" -ErrorAction SilentlyContinue)) { continue }
    $inDA = @(Get-ADGroupMember -Identity "$DomSid-512" | ForEach-Object { $_.SamAccountName }) -contains $u
    if (-not $inDA) { try { Add-ADGroupMember -Identity "$DomSid-512" -Members $u -ErrorAction Stop; Log "Made $u a Domain Admin" } catch { Warn "Couldn't add $u to Domain Admins" } }
  }
  foreach ($u in $AuthAll) {
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$u'" -ErrorAction SilentlyContinue)) { continue }
    if ($u -ne $Me -or $ChangeMyPW) {
      try { Set-ADAccountPassword -Identity $u -Reset -NewPassword $SecurePW -ErrorAction Stop } catch { Warn "Couldn't set password for $u ($($_.Exception.Message))" }
    }
    try {
      Set-ADUser -Identity $u -PasswordNeverExpires $false -PasswordNotRequired $false -AllowReversiblePasswordEncryption $false -ErrorAction Stop
      Set-ADAccountControl -Identity $u -DoesNotRequirePreAuth $false -ErrorAction Stop
    } catch {}
  }
  Log 'Domain users: secure passwords set; "password never expires", "password not required", reversible encryption and "no Kerberos pre-auth" turned off'
  try { Disable-ADAccount -Identity "$DomSid-501" -ErrorAction Stop; Log 'Domain Guest account disabled' } catch {}
  if ($DisableBuiltinAdmin) { try { Disable-ADAccount -Identity "$DomSid-500" -ErrorAction Stop; Log "Built-in $BuiltinAdmin disabled" } catch { Warn "Couldn't disable $BuiltinAdmin" } }
  foreach ($spec in $GroupSpecs) {
    $g = ($spec -split ':')[0]; $want = @(); if ($spec -like '*:*') { $want = Split-Names (($spec -split ':', 2)[1]) }
    if (-not $g) { continue }
    if (-not (Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue)) { try { New-ADGroup -Name $g -GroupScope Global -ErrorAction Stop; Log "Created domain group $g" } catch { Warn "Couldn't create group $g"; continue } }
    $have = @(Get-ADGroupMember -Identity $g | ForEach-Object { $_.SamAccountName })
    foreach ($m in $have) { if ($want -notcontains $m) { Remove-ADGroupMember -Identity $g -Members $m -Confirm:$false; Log "Removed $m from group $g" } }
    foreach ($m in $want) { if ($have -notcontains $m) { try { Add-ADGroupMember -Identity $g -Members $m -ErrorAction Stop; Log "Added $m to group $g" } catch { Warn "Couldn't add $m to $g" } } }
  }
} else {
  #---------------- workstation / member server: local accounts ----------------
  foreach ($u in $ToCreate) {
    try {
      New-LocalUser -Name $u -Password $SecurePW -PasswordNeverExpires:$false -AccountNeverExpires -ErrorAction Stop | Out-Null
      Add-LocalGroupMember -Group $UsersGroup -Member $u -ErrorAction SilentlyContinue
      Log "Created user $u (listed in README)"
    } catch { Warn "Couldn't create user $u ($($_.Exception.Message))" }
  }
  foreach ($u in $ToDelete) {
    if ($u -eq $Me) { continue }
    try { Remove-LocalUser -Name $u -ErrorAction Stop; Log "Deleted unauthorized user: $u (profile folder kept for forensics)" } catch { Warn "Couldn't delete $u ($($_.Exception.Message))" }
  }
  foreach ($u in $ToDemote) {
    try { Remove-LocalGroupMember -Group $AdminGroup -Member $u -ErrorAction Stop; Log "Removed $u from $AdminGroup" } catch { Warn "Couldn't remove $u from $AdminGroup" }
  }
  # Broad groups (Everyone, Users, Authenticated Users, Domain Users, ...) planted inside Administrators
  foreach ($m in @(Get-GroupMembersSafe $AdminGroup | Where-Object { $_.Name -match '^(?i)(Everyone|Users|Authenticated Users|INTERACTIVE|NETWORK|ANONYMOUS LOGON|Guests|Domain Users|Domain Guests|Remote Desktop Users)$' })) {
    Warn "The group '$($m.Name)' is inside $AdminGroup - that makes all of its members administrators"
    if (Ask-YN "   Remove '$($m.Name)' from $AdminGroup?") { if (Remove-GroupMemberSafe $AdminGroup $m) { Log "Removed $($m.Name) from $AdminGroup" } else { Warn "Couldn't remove $($m.Name)" } }
  }
  foreach ($m in @(Get-GroupMembersSafe $AdminGroup | Where-Object { $_.IsOrphan })) {
    if (Remove-GroupMemberSafe $AdminGroup $m) { Log "Removed leftover SID $($m.Name) from $AdminGroup" }
  }
  foreach ($u in $AuthAdmins) {
    if (-not (Get-LocalUser -Name $u -ErrorAction SilentlyContinue)) { continue }
    if (@(Get-GroupMembersSafe $AdminGroup | ForEach-Object { $_.Name }) -notcontains $u) {
      try { Add-LocalGroupMember -Group $AdminGroup -Member $u -ErrorAction Stop; Log "Made $u an administrator" } catch { Warn "Couldn't add $u to $AdminGroup" }
    }
  }
  # Everyone authorized belongs to Users (needed to log in) and NOT to Guests (Guests get "deny log on" below)
  $GuestsGroup = Get-GroupNameBySid 'S-1-5-32-546'
  foreach ($u in $AuthAll) {
    if (-not (Get-LocalUser -Name $u -ErrorAction SilentlyContinue)) { continue }
    if (@(Get-GroupMembersSafe $UsersGroup | ForEach-Object { $_.Name }) -notcontains $u) { Add-LocalGroupMember -Group $UsersGroup -Member $u -ErrorAction SilentlyContinue; Log "Added $u to $UsersGroup" }
    if ($GuestsGroup -and @(Get-GroupMembersSafe $GuestsGroup | ForEach-Object { $_.Name }) -contains $u) { Remove-LocalGroupMember -Group $GuestsGroup -Member $u -ErrorAction SilentlyContinue; Log "Removed $u from $GuestsGroup" }
  }
  # Other privileged groups: only authorized admins
  foreach ($sid in $PrivGroupSids) {
    $gn = Get-GroupNameBySid $sid; if (-not $gn) { continue }
    foreach ($m in @(Get-GroupMembersSafe $gn | Where-Object { $_.IsLocal -or $_.IsOrphan })) {
      if ($AuthAdmins -contains $m.Name) { continue }
      if (Remove-GroupMemberSafe $gn $m) { Log "Removed $($m.Name) from privileged group '$gn'" }
    }
  }
  $RdpGroup = Get-GroupNameBySid 'S-1-5-32-555'
  if ($RdpGroup) { Review ("Remote Desktop Users members: {0}  (only README-approved users should be here)" -f ((Get-GroupMembersSafe $RdpGroup | ForEach-Object { $_.Name }) -join ', ')) }
  # README groups get EXACTLY the listed members
  foreach ($spec in $GroupSpecs) {
    $g = ($spec -split ':')[0]; $want = @(); if ($spec -like '*:*') { $want = Split-Names (($spec -split ':', 2)[1]) }
    if (-not $g) { continue }
    if (-not (Get-LocalGroup -Name $g -ErrorAction SilentlyContinue)) { try { New-LocalGroup -Name $g -ErrorAction Stop | Out-Null; Log "Created group $g" } catch { Warn "Couldn't create group $g"; continue } }
    $have = @(Get-GroupMembersSafe $g)
    foreach ($m in $have) { if ($want -notcontains $m.Name) { if (Remove-GroupMemberSafe $g $m) { Log "Removed $($m.Name) from group $g" } } }
    foreach ($m in $want) { if (@($have | ForEach-Object { $_.Name }) -notcontains $m) { try { Add-LocalGroupMember -Group $g -Member $m -ErrorAction Stop; Log "Added $m to group $g" } catch { Warn "Couldn't add $m to $g (does the user exist?)" } } }
  }
  # Passwords (set BEFORE the stricter policy below, so they can't be rejected by it)
  $changed = @()
  foreach ($u in $AuthAll) {
    $lu = Get-LocalUser -Name $u -ErrorAction SilentlyContinue; if (-not $lu) { continue }
    if ($u -ne $Me -or $ChangeMyPW) {
      try { Set-LocalUser -Name $u -Password $SecurePW -ErrorAction Stop; $changed += $u } catch { Warn "Couldn't set password for $u ($($_.Exception.Message))" }
    }
    $recent = ($u -ne $Me -or $ChangeMyPW -or ($lu.PasswordLastSet -and $lu.PasswordLastSet -gt (Get-Date).AddDays(-80)))
    if ($recent) { Set-LocalUser -Name $u -PasswordNeverExpires $false -UserMayChangePassword $true -ErrorAction SilentlyContinue }
    else { Review "[!] Your password is older than 80 days, so 'password never expires' was left as-is for $u (it would force a change at your next login). Change your password, then untick it." }
    & net.exe user $u /passwordreq:yes 2>&1 | Out-Null
  }
  if ($changed.Count) { Log "Secure password set for: $($changed -join ', ')" }
  Log 'Authorized users: "password never expires" off, "password required" on'
  foreach ($lu in Get-LocalUser | Where-Object { $_.SID.Value -match '-(501|503|504)$' -and $_.Enabled }) {
    Disable-LocalUser -SID $lu.SID -ErrorAction SilentlyContinue; Log "Disabled built-in account $($lu.Name)"
  }
  if ($DisableBuiltinAdmin) { try { Disable-LocalUser -Name $BuiltinAdmin -ErrorAction Stop; Log "Disabled the built-in $BuiltinAdmin account" } catch { Warn "Couldn't disable $BuiltinAdmin" } }
}
$ul = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList' -ErrorAction SilentlyContinue
if ($ul) { foreach ($p in $ul.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' -and $_.Value -eq 0 }) { Review "[!] Account '$($p.Name)' is HIDDEN from the login screen (Winlogon\SpecialAccounts\UserList) - check it" } }
Review '--- Accounts after changes ---'
if ($IsDC) { Get-ADUser -Filter * | ForEach-Object { Review ("   {0}  enabled={1}" -f $_.SamAccountName, $_.Enabled) } }
else { Get-LocalUser | ForEach-Object { Review ("   {0}  enabled={1}" -f $_.Name, $_.Enabled) }; Review ("   {0}: {1}" -f $AdminGroup, ((Get-GroupMembersSafe $AdminGroup | ForEach-Object { $_.Name }) -join ', ')) }
Review ''

#------------------------ PASSWORD / LOCKOUT / RIGHTS -------------------------
Section 'Password, lockout and user-rights policy'
# Applied with secedit so "Local Security Policy" shows the same values the scoring engine reads.
$SecInf = @'
[Unicode]
Unicode=yes
[Version]
signature="$CHICAGO$"
Revision=1
[System Access]
MinimumPasswordAge = 7
MaximumPasswordAge = 90
MinimumPasswordLength = 12
PasswordComplexity = 1
PasswordHistorySize = 24
ClearTextPassword = 0
LockoutBadCount = 5
LockoutDuration = 30
ResetLockoutCount = 30
EnableGuestAccount = 0
LSAAnonymousNameLookup = 0
[Event Audit]
AuditSystemEvents = 3
AuditLogonEvents = 3
AuditObjectAccess = 3
AuditPrivilegeUse = 3
AuditPolicyChange = 3
AuditAccountManage = 3
AuditProcessTracking = 3
AuditDSAccess = 3
AuditAccountLogon = 3
[Privilege Rights]
SeTcbPrivilege =
SeCreateTokenPrivilege =
SeTrustedCredManAccessPrivilege =
SeCreatePermanentPrivilege =
SeLockMemoryPrivilege =
SeDebugPrivilege = *S-1-5-32-544
SeTakeOwnershipPrivilege = *S-1-5-32-544
SeLoadDriverPrivilege = *S-1-5-32-544
SeSecurityPrivilege = *S-1-5-32-544
SeSystemEnvironmentPrivilege = *S-1-5-32-544
SeBackupPrivilege = *S-1-5-32-544,*S-1-5-32-551
SeRestorePrivilege = *S-1-5-32-544,*S-1-5-32-551
SeRemoteShutdownPrivilege = *S-1-5-32-544
SeDenyNetworkLogonRight = *S-1-5-32-546
SeDenyInteractiveLogonRight = *S-1-5-32-546
SeDenyRemoteInteractiveLogonRight = *S-1-5-32-546
SeDenyBatchLogonRight = *S-1-5-32-546
SeDenyServiceLogonRight = *S-1-5-32-546
SeRemoteInteractiveLogonRight = *S-1-5-32-544,*S-1-5-32-555
'@
$infPath = Join-Path $Backup 'cp-secpol.inf'
[IO.File]::WriteAllText($infPath, $SecInf, [Text.Encoding]::Unicode)
# On a domain controller user rights come from Group Policy - only the account policy is applied locally.
$areas = 'SECURITYPOLICY USER_RIGHTS'; if ($IsDC) { $areas = 'SECURITYPOLICY' }
& secedit.exe /configure /db (Join-Path $Backup 'cp-secpol.sdb') /cfg $infPath /areas $areas.Split(' ') /quiet 2>&1 | Out-Null
$seRc = $LASTEXITCODE
# Read the policy back to prove it took effect
& secedit.exe /export /cfg (Join-Path $Backup 'secpol-after.inf') /quiet 2>&1 | Out-Null
$after = Get-Content -LiteralPath (Join-Path $Backup 'secpol-after.inf') -ErrorAction SilentlyContinue
$want = @{ MinimumPasswordAge = '7'; MaximumPasswordAge = '90'; MinimumPasswordLength = '12'; PasswordComplexity = '1'; PasswordHistorySize = '24'; ClearTextPassword = '0'; LockoutBadCount = '5'; LockoutDuration = '30'; ResetLockoutCount = '30' }
$bad = @(); foreach ($k in $want.Keys) { $line = $after | Where-Object { $_ -match "^$k\s*=" } | Select-Object -First 1; if (-not $line -or ($line -split '=')[1].Trim() -ne $want[$k]) { $bad += $k } }
if ($bad.Count -eq 0) { Log 'Password policy: 12+ chars, complexity on, history 24, max age 90 / min age 7, no reversible encryption; lockout 5 tries / 30 min' }
else { Warn "These policy values didn't stick (secedit exit $seRc; a domain GPO may override them - see %windir%\security\logs\scesrv.log): $($bad -join ', ')" }
if (-not $IsDC) { Log 'User rights: nobody may act as part of the OS / create tokens; only Administrators may debug, load drivers, take ownership; Guests denied all logon types' }
if ($IsDC) {
  try {
    Set-ADDefaultDomainPasswordPolicy -Identity $Dom.DistinguishedName -MinPasswordLength 12 -PasswordHistoryCount 24 -ComplexityEnabled $true -ReversibleEncryptionEnabled $false `
      -MaxPasswordAge '90.00:00:00' -MinPasswordAge '7.00:00:00' -LockoutThreshold 5 -LockoutDuration '00:30:00' -LockoutObservationWindow '00:30:00' -ErrorAction Stop
    Log 'Domain password & lockout policy set (Default Domain Policy)'
  } catch { Warn "Couldn't set the domain password policy ($($_.Exception.Message))" }
}
# Report any OTHER dangerous user right granted to someone who isn't an admin
$danger = 'SeTcbPrivilege|SeDebugPrivilege|SeBackupPrivilege|SeRestorePrivilege|SeTakeOwnershipPrivilege|SeLoadDriverPrivilege|SeImpersonatePrivilege|SeAssignPrimaryTokenPrivilege|SeCreateTokenPrivilege|SeSecurityPrivilege|SeSystemEnvironmentPrivilege|SeManageVolumePrivilege'
$okSids = '\*S-1-5-32-544|\*S-1-5-32-551|\*S-1-5-19|\*S-1-5-20|\*S-1-5-6|\*S-1-5-18|\*S-1-5-32-568|\*S-1-5-90-0|\*S-1-5-82-'
foreach ($line in ($after | Where-Object { $_ -match "^($danger)\s*=" })) {
  $who = @((($line -split '=', 2)[1]).Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -notmatch "^($okSids)" })
  if ($who.Count) { Review "[!] User right $(($line -split '=')[0].Trim()) is also granted to: $($who -join ', ')  (secpol.msc > Local Policies > User Rights Assignment)" }
}

#----------------------------- SECURITY OPTIONS -------------------------------
Section 'Security options (UAC, credentials, SMB signing, anonymous access, logon screen)'
$Lsa = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
$PolSys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$SrvP = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
$WksP = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters'
$TSPol = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
$SecOpts = @(
  @($Lsa, 'LimitBlankPasswordUse', 1, 'DWord'),               # blank passwords only at the console
  @($Lsa, 'NoLMHash', 1, 'DWord'),                            # don't store LAN Manager hashes
  @($Lsa, 'LmCompatibilityLevel', 5, 'DWord'),                # NTLMv2 only, refuse LM & NTLM
  @($Lsa, 'RestrictAnonymous', 1, 'DWord'),                   # no anonymous enumeration of shares
  @($Lsa, 'RestrictAnonymousSAM', 1, 'DWord'),                # no anonymous enumeration of accounts
  @($Lsa, 'EveryoneIncludesAnonymous', 0, 'DWord'),
  @($Lsa, 'DisableDomainCreds', 1, 'DWord'),                  # don't store network passwords
  @($Lsa, 'SCENoApplyLegacyAuditPolicy', 1, 'DWord'),         # use the detailed audit policy below
  @("$Lsa\MSV1_0", 'NTLMMinClientSec', 537395200, 'DWord'),   # NTLM: require NTLMv2 + 128-bit
  @("$Lsa\MSV1_0", 'NTLMMinServerSec', 537395200, 'DWord'),
  @("$Lsa\MSV1_0", 'allownullsessionfallback', 0, 'DWord'),
  @($SrvP, 'RequireSecuritySignature', 1, 'DWord'),           # SMB server: always sign
  @($SrvP, 'EnableSecuritySignature', 1, 'DWord'),
  @($SrvP, 'RestrictNullSessAccess', 1, 'DWord'),
  @($SrvP, 'SMB1', 0, 'DWord'),
  @($WksP, 'RequireSecuritySignature', 1, 'DWord'),           # SMB client: always sign
  @($WksP, 'EnableSecuritySignature', 1, 'DWord'),
  @($WksP, 'EnablePlainTextPassword', 0, 'DWord'),
  @($PolSys, 'EnableLUA', 1, 'DWord'),                        # UAC on
  @($PolSys, 'ConsentPromptBehaviorAdmin', 2, 'DWord'),       # UAC: always notify (secure desktop)
  @($PolSys, 'ConsentPromptBehaviorUser', 0, 'DWord'),        # standard users can't elevate
  @($PolSys, 'PromptOnSecureDesktop', 1, 'DWord'),
  @($PolSys, 'FilterAdministratorToken', 1, 'DWord'),         # Admin Approval Mode for built-in Administrator
  @($PolSys, 'EnableInstallerDetection', 1, 'DWord'),
  @($PolSys, 'EnableSecureUIAPaths', 1, 'DWord'),
  @($PolSys, 'EnableVirtualization', 1, 'DWord'),
  @($PolSys, 'LocalAccountTokenFilterPolicy', 0, 'DWord'),
  @($PolSys, 'DontDisplayLastUserName', 1, 'DWord'),          # don't show last signed-in user
  @($PolSys, 'DisableCAD', 0, 'DWord'),                       # require Ctrl+Alt+Del
  @($PolSys, 'InactivityTimeoutSecs', 900, 'DWord'),          # lock after 15 min idle
  @($PolSys, 'LegalNoticeCaption', 'Authorized use only', 'String'),
  @($PolSys, 'LegalNoticeText', 'This system is for authorized users only. Activity is monitored and logged.', 'String'),
  @('HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest', 'UseLogonCredential', 0, 'DWord'),   # no plain-text passwords in memory
  @('HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient', 'EnableMulticast', 0, 'DWord'),               # LLMNR off
  @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\System', 'EnableSmartScreen', 1, 'DWord'),
  @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\System', 'ShellSmartScreenLevel', 'Block', 'String'),
  @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer', 'NoDriveTypeAutoRun', 255, 'DWord'),   # AutoRun off
  @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer', 'NoAutorun', 1, 'DWord'),
  @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer', 'NoAutoplayfornonVolume', 1, 'DWord'),
  @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer', 'AlwaysInstallElevated', 0, 'DWord'),            # classic privilege-escalation hole
  @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer', 'EnableUserControl', 0, 'DWord'),
  @('HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer', 'AlwaysInstallElevated', 0, 'DWord'),
  @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging', 'EnableScriptBlockLogging', 1, 'DWord'),
  @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation', 'AllowInsecureGuestAuth', 0, 'DWord'),
  @('HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint', 'RestrictDriverInstallationToAdministrators', 1, 'DWord'),
  @('HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance', 'fAllowToGetHelp', 0, 'DWord'),
  @($TSPol, 'fAllowToGetHelp', 0, 'DWord'),
  @($TSPol, 'fAllowUnsolicited', 0, 'DWord')
)
if (-not $IsDC) { $SecOpts += , @($Lsa, 'RestrictRemoteSAM', 'O:BAG:BAD:(A;;RC;;;BA)', 'String') }   # only admins may query SAM remotely
$okCount = 0; foreach ($s in $SecOpts) { if (Set-Reg $s[0] $s[1] $s[2] $s[3]) { $okCount++ } }
Log "Security options applied ($okCount settings): UAC always-notify, NTLMv2 only, SMB signing, no anonymous enumeration, Ctrl+Alt+Del, 15-min lock, AutoRun off, LLMNR off, SmartScreen on"
# Auto-logon stores a password in clear text in the registry
$WL = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
if ((Get-RegValue $WL 'AutoAdminLogon') -eq '1' -or (Get-RegValue $WL 'DefaultPassword')) { Warn 'Automatic logon was configured (password stored in the registry) - turned off' }
Set-Reg $WL 'AutoAdminLogon' '0' 'String' | Out-Null
Remove-RegValue $WL 'DefaultPassword' | Out-Null; Remove-RegValue $WL 'AutoLogonCount' | Out-Null
# Remote Desktop
$TS = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
if ($NeedRDP) {
  Set-Reg $TS 'fDenyTSConnections' 0 | Out-Null; Set-Reg $TSPol 'fDenyTSConnections' 0 | Out-Null
  foreach ($k in "$TS\WinStations\RDP-Tcp", $TSPol) { Set-Reg $k 'UserAuthentication' 1 | Out-Null; Set-Reg $k 'MinEncryptionLevel' 3 | Out-Null }
  Set-Reg "$TS\WinStations\RDP-Tcp" 'SecurityLayer' 2 | Out-Null
  Set-Reg $TSPol 'fPromptForPassword' 1 | Out-Null; Set-Reg $TSPol 'fEncryptRPCTraffic' 1 | Out-Null
  Log 'Remote Desktop kept ON (README): Network Level Authentication, TLS, high encryption, always ask for password'
} else {
  Set-Reg $TS 'fDenyTSConnections' 1 | Out-Null; Set-Reg $TSPol 'fDenyTSConnections' 1 | Out-Null
  Log 'Remote Desktop turned OFF (not required by the README)'
}
if ($DisableUSB) { Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR' 'Start' 4 | Out-Null; Log 'USB storage disabled' }

#------------------------------- AUDIT POLICY ---------------------------------
Section 'Audit policy & event logs'
& auditpol.exe /set /category:* /success:enable /failure:enable 2>&1 | Out-Null
# the two noisiest subcategories (every network packet) - keep failures only / off
& auditpol.exe /set /subcategory:'{0CCE9225-69AE-11D9-BED3-505054503030}' /success:disable /failure:disable 2>&1 | Out-Null
& auditpol.exe /set /subcategory:'{0CCE9226-69AE-11D9-BED3-505054503030}' /success:disable /failure:enable 2>&1 | Out-Null
& wevtutil.exe sl Security /ms:209715200 2>&1 | Out-Null
& wevtutil.exe sl System /ms:33554432 2>&1 | Out-Null
& wevtutil.exe sl Application /ms:33554432 2>&1 | Out-Null
$aud = & auditpol.exe /get /category:* 2>&1 | Out-String
if ($aud -match 'Success and Failure') { Log 'Audit policy: success + failure auditing for every category; Security log raised to 200 MB' }
else { Warn 'Audit policy may not have applied - check: auditpol /get /category:*' }

#--------------------------------- FIREWALL -----------------------------------
Section 'Windows Firewall'
Enable-Svc 'BFE' | Out-Null; Enable-Svc 'MpsSvc' | Out-Null
foreach ($p in 'DomainProfile', 'StandardProfile', 'PublicProfile') {
  $k = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\$p"
  if ((Get-RegValue $k 'EnableFirewall') -eq 0) { Set-Reg $k 'EnableFirewall' 1 | Out-Null; Warn "A policy had turned the firewall OFF ($p) - fixed" }
}
try {
  Set-NetFirewallProfile -Profile Domain, Private, Public -Enabled True -DefaultInboundAction Block -DefaultOutboundAction Allow -NotifyOnListen True -LogBlocked True -LogMaxSizeKilobytes 16384 -ErrorAction Stop
  Log 'Firewall ON for Domain/Private/Public: inbound blocked unless allowed, logging of dropped packets'
} catch { Warn "Couldn't configure the firewall ($($_.Exception.Message))" }
$FwGroups = [ordered]@{
  'Remote Desktop'                         = $NeedRDP
  'File and Printer Sharing'               = ($NeedSMB -or $NeedPrint -or $IsDC)
  'World Wide Web Services (HTTP)'         = $NeedWeb
  'Secure World Wide Web Services (HTTPS)' = $NeedWeb
  'FTP Server'                             = $NeedFTP
  'DNS Service'                            = ($NeedDNS -or $IsDC)
  'Windows Remote Management'              = $NeedWinRM
  'Remote Assistance'                      = $false
}
foreach ($g in $FwGroups.Keys) {
  $rules = @(Get-NetFirewallRule -DisplayGroup $g -ErrorAction SilentlyContinue | Where-Object { $_.Direction -eq 'Inbound' })
  if (-not $rules.Count) { continue }
  if ($FwGroups[$g]) { $rules | Enable-NetFirewallRule -ErrorAction SilentlyContinue; Info "Firewall: '$g' allowed (required)" }
  else { $on = @($rules | Where-Object { $_.Enabled -eq 'True' }); if ($on.Count) { $on | Disable-NetFirewallRule -ErrorAction SilentlyContinue; Log "Firewall: '$g' inbound rules disabled (not required)" } }
}
$sshRule = Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue
if ($sshRule) { if ($NeedSSH) { $sshRule | Enable-NetFirewallRule } else { $sshRule | Disable-NetFirewallRule } }
# Custom allow rules (not part of any Windows rule group) - attackers add these
foreach ($r in @(Get-NetFirewallRule -Direction Inbound -Action Allow -Enabled True -ErrorAction SilentlyContinue | Where-Object { -not $_.Group })) {
  if (Test-Protected "$($r.DisplayName) $($r.Name)") { continue }
  $app = [string](($r | Get-NetFirewallApplicationFilter -ErrorAction SilentlyContinue).Program)
  $pf = $r | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue
  $ra = [string]((($r | Get-NetFirewallAddressFilter -ErrorAction SilentlyContinue).RemoteAddress) -join ',')
  $ports = [string](@($pf.LocalPort) -join ',')
  $why = @()
  if ($app -eq 'Any' -and $ports -eq 'Any') { $why += 'allows ALL inbound traffic' }
  if ($app -and $app -ne 'Any' -and [Environment]::ExpandEnvironmentVariables($app) -match $UserWritableRe) { $why += 'program in a user-writable folder' }
  if ($app -and $app -ne 'Any' -and (Split-Path -Path $app -Leaf) -match $ToolNameRe) { $why += 'hacking / remote-control tool' }
  if (@($pf.LocalPort) | Where-Object { $_ -match '^(4444|1337|31337|5555|6666|6667|9001|12345|54321)$' }) { $why += 'classic backdoor port' }
  $desc = '{0}  (program: {1}; {2} port {3}; from {4})' -f $r.DisplayName, $app, $pf.Protocol, $ports, $ra
  if ($why.Count) {
    Warn "Suspicious firewall rule: $desc -- $($why -join '; ')"
    if (Ask-YN '   Disable this firewall rule?') { Disable-NetFirewallRule -Name $r.Name; Log "Disabled firewall rule $($r.DisplayName)" }
  } else { Review "Custom inbound allow rule (check it): $desc" }
}

#--------------------------------- SERVICES -----------------------------------
Section 'Services'
$AlwaysOff = @('RemoteRegistry', 'TlntSvr', 'SSDPSRV', 'upnphost', 'SharedAccess', 'RemoteAccess', 'RpcLocator', 'simptcp', 'SNMPTRAP', 'Fax',
               'XblAuthManager', 'XblGameSave', 'XboxNetApiSvc', 'XboxGipSvc', 'WMPNetworkSvc', 'icssvc', 'NetTcpPortSharing',
               'p2psvc', 'p2pimsvc', 'PNRPsvc', 'PNRPAutoReg', 'HomeGroupListener', 'HomeGroupProvider', 'Browser', 'irmon', 'WebClient')
$AlwaysOff = @($AlwaysOff | Where-Object { -not (($_ -eq 'RemoteAccess' -and $KeptRoles -contains 'RemoteAccess') -or ($_ -eq 'Fax' -and $KeptRoles -contains 'Fax')) })
Disable-Svc $AlwaysOff
if (-not $NeedRDP)   { Disable-Svc @('TermService', 'UmRdpService', 'SessionEnv') }
if (-not $NeedWeb)   { Disable-Svc @('W3SVC', 'WMSvc'); if (-not $NeedFTP) { Disable-Svc @('WAS', 'IISADMIN') } }   # IIS FTP still needs WAS/IISADMIN
if (-not $NeedFTP)   { Disable-Svc @('ftpsvc', 'MSFTPSVC', 'filezilla-server', 'FileZilla Server') }
if (-not $NeedPrint) { Disable-Svc @('Spooler') }
if (-not $NeedSSH)   { Disable-Svc @('sshd') }
if (-not $NeedWinRM) { Disable-Svc @('WinRM') }
if (-not $NeedSNMP)  { Disable-Svc @('SNMP') }
if (-not $NeedDNS -and -not $IsDC) { Disable-Svc @('DNS') }
# Security services must be ON (attackers disable them)
foreach ($s in 'wuauserv', 'UsoSvc', 'WinDefend', 'MpsSvc', 'BFE', 'EventLog', 'wscsvc', 'CryptSvc', 'SecurityHealthService') {
  $sv = Get-Service -Name $s -ErrorAction SilentlyContinue; if (-not $sv) { continue }
  if ($sv.StartType -eq 'Disabled' -or $sv.Status -ne 'Running') {
    if (Enable-Svc $s 'Automatic') { Log "Security service $($sv.DisplayName) is enabled and running" }
    elseif ($sv.StartType -eq 'Disabled') { Warn "Security service $($sv.DisplayName) is DISABLED and couldn't be re-enabled - fix it in services.msc" }
  }
}
foreach ($s in 'BITS') { $sv = Get-Service -Name $s -ErrorAction SilentlyContinue; if ($sv -and $sv.StartType -eq 'Disabled') { Enable-Svc $s 'Manual' | Out-Null; Log "Re-enabled $s" } }

# Required services: hardened config + enabled & running
if ($NeedWeb -and (Test-Path "$env:windir\System32\inetsrv\appcmd.exe")) {
  $appcmd = "$env:windir\System32\inetsrv\appcmd.exe"
  & $appcmd set config /section:system.webServer/directoryBrowse /enabled:false /commit:apphost 2>&1 | Out-Null
  & $appcmd set config /section:system.webServer/security/requestFiltering /removeServerHeader:true /commit:apphost 2>&1 | Out-Null
  & $appcmd set config /section:system.webServer/httpProtocol "/-customHeaders.[name='X-Powered-By']" /commit:apphost 2>&1 | Out-Null
  & $appcmd set config /section:system.webServer/security/requestFiltering "/+verbs.[verb='TRACE',allowed='false']" /commit:apphost 2>&1 | Out-Null
  & $appcmd set config /section:system.webServer/httpErrors /errorMode:DetailedLocalOnly /commit:apphost 2>&1 | Out-Null
  & $appcmd set config /section:system.applicationHost/sites /siteDefaults.logFile.enabled:true /commit:apphost 2>&1 | Out-Null
  foreach ($ap in @(& $appcmd list apppool /processModel.identityType:LocalSystem /text:name 2>$null)) { if ($ap) { Review "[!] IIS application pool '$ap' runs as LocalSystem (full control of the server) - use ApplicationPoolIdentity unless the README says otherwise" } }
  Log 'IIS: directory browsing off, Server/X-Powered-By headers removed, TRACE blocked, detailed errors local-only, logging on'
}
if ($NeedFTP -and (Test-Path "$env:windir\System32\inetsrv\appcmd.exe")) {
  $appcmd = "$env:windir\System32\inetsrv\appcmd.exe"
  & $appcmd set config /section:system.applicationHost/sites /siteDefaults.ftpServer.security.authentication.anonymousAuthentication.enabled:false /commit:apphost 2>&1 | Out-Null
  foreach ($site in @(& $appcmd list site /text:name 2>$null)) { & $appcmd set site $site /ftpServer.security.authentication.anonymousAuthentication.enabled:false 2>&1 | Out-Null }
  Log 'IIS FTP: anonymous logins disabled'
}
if ($NeedSSH -and (Test-Path 'C:\ProgramData\ssh\sshd_config')) {
  $sc = 'C:\ProgramData\ssh\sshd_config'; Copy-Item -LiteralPath $sc -Destination "$Backup\sshd_config-before" -Force
  $lines = [System.Collections.ArrayList]@(Get-Content -LiteralPath $sc)
  function Set-SshOpt([string]$k, [string]$v) {
    $match = -1; $idx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
      $t = ([string]$lines[$i]).Trim()
      if ($t -match '^(?i)match\s') { $match = $i; break }
      if ($t -match ("^(?i)" + [regex]::Escape($k) + '\s')) { $idx = $i }
    }
    if ($idx -ge 0) { $lines[$idx] = "$k $v" } elseif ($match -ge 0) { $lines.Insert($match, "$k $v") } else { [void]$lines.Add("$k $v") }
  }
  Set-SshOpt 'PermitEmptyPasswords' 'no'; Set-SshOpt 'MaxAuthTries' '3'; Set-SshOpt 'LoginGraceTime' '60'
  Set-SshOpt 'PasswordAuthentication' 'yes'; Set-SshOpt 'PubkeyAuthentication' 'yes'; Set-SshOpt 'AllowTcpForwarding' 'no'
  if ($SshAllowUsers) { Set-SshOpt 'AllowUsers' (($AuthAll | ForEach-Object { $_.ToLower() }) -join ' ') }
  $tmp = "$sc.cptest"; [IO.File]::WriteAllLines($tmp, [string[]]$lines)
  & "$env:windir\System32\OpenSSH\sshd.exe" -t -f $tmp 2>&1 | Out-Null
  if ($LASTEXITCODE -eq 0) { Move-Item -LiteralPath $tmp -Destination $sc -Force; Restart-Service sshd -ErrorAction SilentlyContinue; Log 'OpenSSH server hardened (no empty passwords, 3 tries, no tunnels)' }
  else { Remove-Item -LiteralPath $tmp -Force; Warn 'New sshd_config failed sshd -t - left unchanged' }
}
if ($NeedDNS -and (Get-Command Get-DnsServerZone -ErrorAction SilentlyContinue)) {
  foreach ($z in @(Get-DnsServerZone -ErrorAction SilentlyContinue | Where-Object { $_.ZoneType -eq 'Primary' -and -not $_.IsAutoCreated })) {
    try { Set-DnsServerPrimaryZone -Name $z.ZoneName -SecureSecondaries NoTransfer -Notify NoNotify -ErrorAction Stop
          if ($z.IsDsIntegrated) { Set-DnsServerPrimaryZone -Name $z.ZoneName -DynamicUpdate Secure -ErrorAction SilentlyContinue } } catch {}
  }
  Log 'DNS server: zone transfers off; AD-integrated zones accept secure updates only'
}
foreach ($name in $Crit.Keys) {
  $found = $false
  foreach ($svc in $Crit[$name]) {
    if (-not (Get-Service -Name $svc -ErrorAction SilentlyContinue)) { continue }
    $found = $true
    if (Enable-Svc $svc 'Automatic') { Log "Critical service $name ($svc) is enabled and running" } else { Warn "Critical service $name ($svc) would not start - check services.msc" }
  }
  if (-not $found) { Warn "README needs $name, but its service isn't installed - install it!" }
}

#------------------------------ WINDOWS FEATURES ------------------------------
Section 'Windows features (Telnet, TFTP, SMBv1, PowerShell 2.0, ...)'
if ($IsServer) {
  $off = @('Telnet-Client', 'Telnet-Server', 'TFTP-Client', 'FS-SMB1', 'Simple-TCPIP', 'PowerShell-V2')
  # FTP is part of the IIS role, so IIS stays whenever FTP is required
  if (-not $NeedWeb -and -not $NeedFTP) { $off += 'Web-Server' } elseif (-not $NeedFTP) { $off += 'Web-Ftp-Server' }
  if ($NeedWeb) { $off += 'Web-DAV-Publishing' }                 # WebDAV lets visitors write files to the site
  if (-not $NeedPrint) { $off += 'Print-Services' }
  if (-not $NeedDNS -and -not $IsDC) { $off += 'DNS' }
  $off += @('SMTP-Server', 'WebDAV-Redirector')                  # old IIS6 mail relay, WebDAV client
  if (-not $NeedSNMP) { $off += 'SNMP-Service' }
  foreach ($f in @(Get-WindowsFeature -ErrorAction SilentlyContinue | Where-Object { $_.Installed -and $off -contains $_.Name })) {
    try { Uninstall-WindowsFeature -Name $f.Name -ErrorAction Stop | Out-Null; Log "Removed Windows feature $($f.DisplayName)" } catch { Warn "Couldn't remove feature $($f.Name)" }
  }
} else {
  $off = @('TelnetClient', 'TelnetServer', 'TFTP', 'SMB1Protocol', 'SimpleTCP', 'MicrosoftWindowsPowerShellV2Root', 'MicrosoftWindowsPowerShellV2')
  $feats = @(Get-WindowsOptionalFeature -Online -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Enabled' })
  $targets = @($feats | Where-Object { $off -contains $_.FeatureName })
  # FTP is part of IIS, so IIS stays whenever FTP is required
  if (-not $NeedWeb -and -not $NeedFTP) { $targets += @($feats | Where-Object { $_.FeatureName -like 'IIS-*' }) }
  elseif (-not $NeedFTP) { $targets += @($feats | Where-Object { $_.FeatureName -like 'IIS-FTP*' }) }
  foreach ($f in @($targets | Where-Object { $_.FeatureName -notlike 'IIS-*' })) {
    try { Disable-WindowsOptionalFeature -Online -FeatureName $f.FeatureName -NoRestart -ErrorAction Stop | Out-Null; Log "Turned off Windows feature $($f.FeatureName)" } catch { Warn "Couldn't turn off feature $($f.FeatureName)" }
  }
  $iis = @($targets | Where-Object { $_.FeatureName -like 'IIS-*' } | ForEach-Object { $_.FeatureName })
  if ($iis.Count) {   # one call, so Windows handles the parent/child order of the IIS pieces
    try { Disable-WindowsOptionalFeature -Online -FeatureName $iis -NoRestart -ErrorAction Stop | Out-Null; Log "Turned off IIS ($($iis.Count) features) - not required by the README" } catch { Warn "Couldn't turn off IIS ($($_.Exception.Message))" }
  }
}

#----------------------------------- SMB --------------------------------------
Section 'File sharing (SMB) and shared folders'
try {
  Set-SmbServerConfiguration -EnableSMB1Protocol $false -EnableSMB2Protocol $true -RequireSecuritySignature $true -EnableSecuritySignature $true -Force -ErrorAction Stop
  if ($SmbEncrypt) { Set-SmbServerConfiguration -EncryptData $true -Force -ErrorAction Stop }
  Log "SMB: version 1 off, signing required$(if ($SmbEncrypt) { ', encryption required' })"
} catch { Warn "Couldn't change the SMB server settings ($($_.Exception.Message))" }
$shares = @(Get-SmbShare -ErrorAction SilentlyContinue | Where-Object { -not $_.Special -and $_.Name -notin 'print$', 'NETLOGON', 'SYSVOL' })
foreach ($s in $shares) {
  $acc = @(Get-SmbShareAccess -Name $s.Name -ErrorAction SilentlyContinue)
  $everyoneFull = $acc | Where-Object { $_.AccountName -match '^(Everyone|.*\\Everyone)$' -and $_.AccessRight -eq 'Full' -and $_.AccessControlType -eq 'Allow' }
  $desc = '{0} -> {1}  [{2}]' -f $s.Name, $s.Path, (($acc | ForEach-Object { "$($_.AccountName):$($_.AccessRight)" }) -join ', ')
  if (Test-Protected "$($s.Name) $($s.Path)") { continue }
  if (-not $NeedSMB) {
    Warn "Shared folder: $desc"
    if (Ask-YN "   Stop sharing '$($s.Name)'? (the folder itself is kept; yes unless the README needs it)") { Remove-SmbShare -Name $s.Name -Force; Log "Stopped sharing $($s.Name)" }
  } else {
    Review "Shared folder (README needs file sharing - check permissions): $desc"
    try { Set-SmbShare -Name $s.Name -FolderEnumerationMode AccessBased -Force -ErrorAction Stop; Info "Share $($s.Name): access-based enumeration on (users only see what they may open)" } catch {}
    # NTFS: Everyone / Anonymous should never be able to change files in a share
    if ($s.Path -and (Test-Path -LiteralPath $s.Path)) {
      $wr = [Security.AccessControl.FileSystemRights]::Write -bor [Security.AccessControl.FileSystemRights]::Modify -bor [Security.AccessControl.FileSystemRights]::Delete
      $badAce = @((Get-Acl -LiteralPath $s.Path).Access | Where-Object { $_.AccessControlType -eq 'Allow' -and ($_.FileSystemRights -band $wr) -and
                 $(try { $_.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value -in 'S-1-1-0', 'S-1-5-7' } catch { $false }) })
      if ($badAce.Count) {
        Warn "Folder $($s.Path) lets Everyone/Anonymous CHANGE files (NTFS: $(($badAce | ForEach-Object { "$($_.IdentityReference) $($_.FileSystemRights)$(if ($_.IsInherited) { ' (inherited)' })" }) -join '; '))"
        if (Ask-YN "   Make it read-only for Everyone? (yes unless the README says everyone may edit it)") {
          & icacls.exe $s.Path /remove:g '*S-1-1-0' '*S-1-5-7' 2>&1 | Out-Null
          & icacls.exe $s.Path /grant '*S-1-1-0:(OI)(CI)RX' 2>&1 | Out-Null
          if (@($badAce | Where-Object { $_.IsInherited }).Count) { Warn "Some of that access is inherited from a parent folder of $($s.Path) - fix it there too" }
          Log "Folder $($s.Path): Everyone now read-only (NTFS)" }
      }
    }
    if ($everyoneFull) {
      Warn "Share '$($s.Name)' gives Everyone FULL control"
      if (Ask-YN "   Change Everyone to READ-only on '$($s.Name)'?") {
        Revoke-SmbShareAccess -Name $s.Name -AccountName 'Everyone' -Force | Out-Null; Grant-SmbShareAccess -Name $s.Name -AccountName 'Everyone' -AccessRight Read -Force | Out-Null
        Log "Share $($s.Name): Everyone now read-only" }
    }
  }
}

#--------------------------------- DEFENDER -----------------------------------
Section 'Windows Defender'
$wdPol = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'
foreach ($n in 'DisableAntiSpyware', 'DisableAntiVirus', 'DisableRoutinelyTakingAction') { if ((Get-RegValue $wdPol $n) -eq 1) { Remove-RegValue $wdPol $n | Out-Null; Warn "A policy had turned Defender off ($n) - removed" } }
foreach ($n in 'DisableRealtimeMonitoring', 'DisableBehaviorMonitoring', 'DisableOnAccessProtection', 'DisableScanOnRealtimeEnable', 'DisableIOAVProtection') {
  if ((Get-RegValue "$wdPol\Real-Time Protection" $n) -eq 1) { Remove-RegValue "$wdPol\Real-Time Protection" $n | Out-Null; Warn "A policy had turned off Defender real-time protection ($n) - removed" } }
if (Get-Command Set-MpPreference -ErrorAction SilentlyContinue) {
  Enable-Svc 'WinDefend' | Out-Null
  try {
    $mp = Get-MpPreference -ErrorAction Stop
    foreach ($kind in 'ExclusionPath', 'ExclusionProcess', 'ExclusionExtension', 'ExclusionIpAddress') {
      foreach ($x in @($mp.$kind | Where-Object { $_ })) {
        Warn "Defender is told to IGNORE ($kind): $x"
        if (Ask-YN '   Remove this exclusion? (yes unless the README needs it)') {
          $arg = @{ $kind = $x }; Remove-MpPreference @arg -ErrorAction SilentlyContinue; Log "Removed Defender exclusion $x" }
      }
    }
    Set-MpPreference -DisableRealtimeMonitoring $false -DisableBehaviorMonitoring $false -DisableIOAVProtection $false -DisableScriptScanning $false `
      -DisableBlockAtFirstSeen $false -PUAProtection Enabled -MAPSReporting Advanced -SubmitSamplesConsent SendSafeSamples -ErrorAction SilentlyContinue
    Update-MpSignature -ErrorAction SilentlyContinue
    $st = Get-MpComputerStatus -ErrorAction Stop
    if ($st.RealTimeProtectionEnabled) { Log 'Defender: real-time, behavior and script scanning on, cloud protection + PUA blocking on, signatures updated' }
    else { Warn 'Defender real-time protection is still OFF (Tamper Protection or another antivirus?) - turn it on in Windows Security' }
  } catch { Warn "Couldn't configure Defender ($($_.Exception.Message))" }
} else { Warn 'Windows Defender cmdlets not found (feature removed / third-party antivirus?) - check Windows Security by hand' }

#------------------------------ WINDOWS UPDATE --------------------------------
Section 'Windows Update settings'
$WU = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; $AU = "$WU\AU"
foreach ($n in 'DisableWindowsUpdateAccess', 'SetDisableUXWUAccess', 'DoNotConnectToWindowsUpdateInternetLocations') { if (Remove-RegValue $WU $n) { Warn "A policy blocked Windows Update ($n) - removed" } }
$wsus = Get-RegValue $WU 'WUServer'
if ($wsus) {
  Warn "Windows Update is pointed at an update server: $wsus"
  if (Ask-YN '   Remove it so updates come straight from Microsoft? (yes unless the README mentions a WSUS server)') {
    Remove-RegValue $WU 'WUServer' | Out-Null; Remove-RegValue $WU 'WUStatusServer' | Out-Null; Set-Reg $AU 'UseWUServer' 0 | Out-Null; Log 'Removed the WSUS redirection' }
}
Set-Reg $AU 'NoAutoUpdate' 0 | Out-Null
Set-Reg $AU 'AUOptions' 4 | Out-Null                       # auto download + scheduled install
Set-Reg $AU 'ScheduledInstallDay' 0 | Out-Null
Set-Reg $AU 'ScheduledInstallTime' 3 | Out-Null
Set-Reg $AU 'NoAutoRebootWithLoggedOnUsers' 1 | Out-Null   # never reboot on its own during the round
Log 'Windows Update: automatic download & install, no automatic reboot while you are logged in'

#------------------------ SERVER ROLES & SERVER SETTINGS ----------------------
if ($IsServer) {
  Section 'Server roles & server settings'
  foreach ($r in $RoleRemove) {
    try {
      $res = Uninstall-WindowsFeature -Name $r.Name -ErrorAction Stop
      Log ("Removed server role {0}{1}" -f $r.DisplayName, $(if ([string]$res.RestartNeeded -eq 'Yes') { ' (finishes after a restart)' }))
    } catch { Warn "Couldn't remove the $($r.DisplayName) role ($($_.Exception.Message)) - use Server Manager > Manage > Remove Roles and Features" }
  }
  $wdf = Get-WindowsFeature -Name 'Windows-Defender' -ErrorAction SilentlyContinue
  if ($wdf -and -not $wdf.Installed) {
    Warn 'The Microsoft Defender Antivirus feature has been REMOVED from this server'
    if (Ask-YN '   Reinstall it? (finishes after a restart)') {
      try { Install-WindowsFeature -Name 'Windows-Defender' -ErrorAction Stop | Out-Null; Log 'Defender reinstalled - restart to finish' } catch { Warn "Couldn't reinstall Defender ($($_.Exception.Message))" } }
  }
  if ($NeedDHCP -and (Get-Command Set-DhcpServerAuditLog -ErrorAction SilentlyContinue)) {
    try { Set-DhcpServerAuditLog -Enable $true -ErrorAction Stop; Log 'DHCP: audit logging on' } catch {}
    $fr = @(Get-NetFirewallRule -DisplayGroup 'DHCP Server' -ErrorAction SilentlyContinue | Where-Object { $_.Direction -eq 'Inbound' })
    if ($fr.Count) { $fr | Enable-NetFirewallRule -ErrorAction SilentlyContinue }
    if ($IsDC) { Review 'DHCP runs on a domain controller: in the DHCP console set "DNS dynamic update registration credentials" to a dedicated low-privilege account.' }
  }
}
# WinRM (PowerShell remoting / Server Manager): no Basic/Digest auth, no unencrypted traffic
$WinRMPol = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM'
foreach ($kv in @(@('Service', 'AllowBasic', 0), @('Service', 'AllowUnencryptedTraffic', 0), @('Service', 'DisableRunAs', 1),
                  @('Client', 'AllowBasic', 0), @('Client', 'AllowUnencryptedTraffic', 0), @('Client', 'AllowDigest', 0))) {
  Set-Reg "$WinRMPol\$($kv[0])" $kv[1] $kv[2] | Out-Null }
Log 'WinRM: Basic/Digest authentication and unencrypted traffic not allowed'

#----------------------------- TLS / SSL (all) --------------------------------
# .NET registry calls: cipher key names contain '/', which the PowerShell registry provider can't create.
function Set-RegHKLM([string]$SubKey, [string]$Name, [int]$Value) {
  try {
    $k = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($SubKey)
    Add-Content -LiteralPath $RegLog -Value "HKLM\$SubKey`t$Name`t$($k.GetValue($Name, '(not set)'))`t$Value"
    $k.SetValue($Name, $Value, [Microsoft.Win32.RegistryValueKind]::DWord); $k.Close(); return $true
  } catch { Warn "Couldn't set HKLM\$SubKey\$Name ($($_.Exception.Message))"; return $false }
}
if ($HardenTLS) {
  Section 'TLS / SSL protocols and ciphers'
  $Sch = 'SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL'
  foreach ($p in 'SSL 2.0', 'SSL 3.0', 'TLS 1.0', 'TLS 1.1') { foreach ($side in 'Server', 'Client') {
    Set-RegHKLM "$Sch\Protocols\$p\$side" 'Enabled' 0 | Out-Null; Set-RegHKLM "$Sch\Protocols\$p\$side" 'DisabledByDefault' 1 | Out-Null } }
  foreach ($side in 'Server', 'Client') { Set-RegHKLM "$Sch\Protocols\TLS 1.2\$side" 'Enabled' 1 | Out-Null; Set-RegHKLM "$Sch\Protocols\TLS 1.2\$side" 'DisabledByDefault' 0 | Out-Null }
  foreach ($c in 'NULL', 'DES 56/56', 'RC2 40/128', 'RC2 56/128', 'RC2 128/128', 'RC4 40/128', 'RC4 56/128', 'RC4 64/128', 'RC4 128/128', 'Triple DES 168') { Set-RegHKLM "$Sch\Ciphers\$c" 'Enabled' 0 | Out-Null }
  foreach ($n in 'SOFTWARE\Microsoft\.NETFramework\v4.0.30319', 'SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319', 'SOFTWARE\Microsoft\.NETFramework\v2.0.50727', 'SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727') {
    Set-RegHKLM $n 'SchUseStrongCrypto' 1 | Out-Null; Set-RegHKLM $n 'SystemDefaultTlsVersions' 1 | Out-Null }
  Log 'TLS: SSL 2.0/3.0 and TLS 1.0/1.1 off, TLS 1.2 on, NULL/DES/RC2/RC4/3DES ciphers off, .NET apps use strong TLS (applies after a restart)'
}

#------------------------- GROUP POLICY FILE HELPERS --------------------------
# A GPO's security settings live in SYSVOL as GptTmpl.inf (UTF-16). These helpers edit it
# section by section, keeping everything they don't touch exactly as it was.
function Read-Inf([string]$Path) {
  $sec = [ordered]@{}; $cur = $null
  if (Test-Path -LiteralPath $Path) {
    foreach ($line in Get-Content -LiteralPath $Path) {
      if ($line -match '^\s*\[(.+?)\]\s*$') { $cur = $Matches[1]; if (-not $sec.Contains($cur)) { $sec[$cur] = New-Object System.Collections.ArrayList }; continue }
      if ($null -ne $cur -and $line.Trim()) { [void]$sec[$cur].Add($line) }
    }
  }
  if (-not $sec.Contains('Version')) { $v = New-Object System.Collections.ArrayList; [void]$v.Add('signature="$CHICAGO$"'); [void]$v.Add('Revision=1'); $sec.Insert(0, 'Version', $v) }
  if (-not $sec.Contains('Unicode')) { $u = New-Object System.Collections.ArrayList; [void]$u.Add('Unicode=yes'); $sec.Insert(0, 'Unicode', $u) }
  return $sec
}
function Write-Inf($Sec, [string]$Path) {
  $out = New-Object System.Collections.ArrayList
  foreach ($s in $Sec.Keys) { [void]$out.Add("[$s]"); foreach ($l in $Sec[$s]) { [void]$out.Add($l) } }
  New-Item -ItemType Directory -Force -Path (Split-Path -Path $Path -Parent) | Out-Null
  [IO.File]::WriteAllLines($Path, [string[]]$out, [Text.Encoding]::Unicode)     # UTF-16 with BOM, no line wrapping
}
# Replace the line for KEY in SECTION (or add it, unless -OnlyIfPresent). Returns $true if anything changed.
function Set-InfLine($Sec, [string]$Section, [string]$Key, [string]$Line, [bool]$OnlyIfPresent) {
  if (-not $Sec.Contains($Section)) { if ($OnlyIfPresent) { return $false }; $Sec[$Section] = New-Object System.Collections.ArrayList }
  $list = $Sec[$Section]
  for ($i = 0; $i -lt $list.Count; $i++) {
    if ((([string]$list[$i]) -split '=', 2)[0].Trim() -ieq $Key) {
      if (([string]$list[$i]).Trim() -ieq $Line) { return $false }
      $list[$i] = $Line; return $true
    }
  }
  if ($OnlyIfPresent) { return $false }
  [void]$list.Add($Line); return $true
}
# Remove holders that aren't allowed from dangerous user rights. Returns what was (or would be) removed.
$DangerRights = @('SeTcbPrivilege', 'SeCreateTokenPrivilege', 'SeDebugPrivilege', 'SeTakeOwnershipPrivilege', 'SeLoadDriverPrivilege', 'SeBackupPrivilege',
                  'SeRestorePrivilege', 'SeSystemEnvironmentPrivilege', 'SeSecurityPrivilege', 'SeImpersonatePrivilege', 'SeAssignPrimaryTokenPrivilege',
                  'SeTrustedCredManAccessPrivilege', 'SeEnableDelegationPrivilege', 'SeCreatePermanentPrivilege', 'SeLockMemoryPrivilege', 'SeManageVolumePrivilege')
$RightsAllowRe = '(?i)^(\*S-1-5-(32-(544|549|550|551|568)|18|19|20|6|9|90-0|80-[\d-]+|82-[\d-]+|21-\d+-\d+-\d+-(512|516|519|498))|(BUILTIN\\)?(Administrators|Backup Operators|Server Operators|Print Operators|IIS_IUSRS)|NT AUTHORITY\\(SYSTEM|LOCAL SERVICE|NETWORK SERVICE|SERVICE|ENTERPRISE DOMAIN CONTROLLERS))$'
function Remove-RightHolders($Sec) {
  $changes = @()
  if (-not $Sec.Contains('Privilege Rights')) { return $changes }
  $list = $Sec['Privilege Rights']
  for ($i = 0; $i -lt $list.Count; $i++) {
    $parts = ([string]$list[$i]) -split '=', 2; $k = $parts[0].Trim()
    if ($DangerRights -notcontains $k -or $parts.Count -lt 2) { continue }
    $holders = @($parts[1].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $drop = @($holders | Where-Object { $_ -notmatch $RightsAllowRe })
    if ($drop.Count) { $list[$i] = "$k = $(@($holders | Where-Object { $_ -match $RightsAllowRe }) -join ',')"; $changes += ('{0}: {1}' -f $k, ($drop -join ', ')) }
  }
  return $changes
}
# Bump the computer half of the GPO version (in GPT.INI and in AD) so every machine re-applies it.
function Step-GpoVersion([string]$Guid, [string]$GpoDir) {
  $ini = Join-Path $GpoDir 'GPT.INI'
  $adDn = "CN={$Guid},CN=Policies,CN=System,$($Dom.DistinguishedName)"
  $adV = 0; try { $adV = [int](Get-ADObject -Identity $adDn -Properties versionNumber -ErrorAction Stop).versionNumber } catch {}
  $lines = @(Get-Content -LiteralPath $ini -ErrorAction SilentlyContinue)
  $iniV = 0; foreach ($l in $lines) { if ($l -match '^\s*Version\s*=\s*(\d+)') { $iniV = [int]$Matches[1] } }
  $new = [Math]::Max($adV, $iniV) + 1
  if (@($lines | Where-Object { $_ -match '^\s*Version\s*=' }).Count) { $lines = @($lines | ForEach-Object { if ($_ -match '^\s*Version\s*=') { "Version=$new" } else { $_ } }) }
  else { if (-not @($lines | Where-Object { $_ -match '^\s*\[General\]' }).Count) { $lines = @('[General]') + $lines }; $lines += "Version=$new" }
  Set-Content -LiteralPath $ini -Value $lines -Encoding ASCII
  try { Set-ADObject -Identity $adDn -Replace @{ versionNumber = $new } -ErrorAction Stop } catch { Warn "Couldn't update the AD version of GPO {$Guid} ($($_.Exception.Message))" }
  return $new
}
# Advanced audit settings stored in a GPO (audit.csv): every subcategory -> Success and Failure,
# except the two per-packet Filtering Platform ones. Keeps the file's own encoding.
function Update-GpoAuditCsv([string]$Csv) {
  if (-not (Test-Path -LiteralPath $Csv)) { return $false }
  $bytes = [IO.File]::ReadAllBytes($Csv)
  $enc = New-Object System.Text.UTF8Encoding $false
  if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { $enc = [Text.Encoding]::Unicode }
  elseif ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { $enc = New-Object System.Text.UTF8Encoding $true }
  $lines = @($enc.GetString($bytes).TrimStart([char]0xFEFF) -split "`r?`n")
  $changed = $false
  $new = foreach ($l in $lines) {
    $c = $l -split ','
    if ($c.Count -ge 7 -and $c[3] -match '^\{0cce' -and $c[3] -notmatch '0cce922[56]' -and $c[6] -ne '3') { $c[4] = 'Success and Failure'; $c[6] = '3'; $changed = $true; $c -join ',' } else { $l }
  }
  if ($changed) { [IO.File]::WriteAllText($Csv, (($new -join "`r`n").TrimEnd() + "`r`n"), $enc) }
  return $changed
}

#--------------------------- ACTIVE DIRECTORY (DC) ----------------------------
if ($IsDC) {
  Section 'Active Directory hardening'
  $Ntds = 'HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters'; $Nlp = 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters'
  Set-Reg $Ntds 'LDAPServerIntegrity' 2 | Out-Null                 # require signed LDAP
  Set-Reg $Ntds 'LdapEnforceChannelBinding' 1 | Out-Null           # LDAPS channel binding when the client supports it
  foreach ($kv in @(@('RequireSignOrSeal', 1), @('SealSecureChannel', 1), @('SignSecureChannel', 1), @('RequireStrongKey', 1), @('RefusePasswordChange', 0), @('FullSecureChannelProtection', 1))) { Set-Reg $Nlp $kv[0] $kv[1] | Out-Null }
  if (Remove-RegValue $Nlp 'VulnerableChannelAllowList') { Warn 'Removed a Zerologon exception list (Netlogon VulnerableChannelAllowList)' }
  Log 'Domain controller: LDAP signing required, channel binding on, Netlogon secure channel signed/sealed, Zerologon protection enforced'

  # Pre-Windows 2000 Compatible Access containing Everyone / Anonymous = anyone can read the directory
  $pre = Get-ADGroup -Identity 'S-1-5-32-554' -Properties member -ErrorAction SilentlyContinue
  foreach ($dn in @($pre.member | Where-Object { $_ -match '^CN=(S-1-1-0|S-1-5-7),' })) {
    $who = 'ANONYMOUS LOGON'; if ($dn -match 'S-1-1-0') { $who = 'Everyone' }
    Warn "'$who' is in 'Pre-Windows 2000 Compatible Access' (anyone can read the whole directory without logging in)"
    if (Ask-YN "   Remove '$who' from it?") { try { Set-ADGroup -Identity 'S-1-5-32-554' -Remove @{ member = $dn } -ErrorAction Stop; Log "Removed $who from Pre-Windows 2000 Compatible Access" } catch { Warn "Couldn't remove it ($($_.Exception.Message))" } }
  }
  foreach ($u in $AuthAdmins) { try { Set-ADUser -Identity $u -AccountNotDelegated $true -ErrorAction Stop } catch {} }
  Log 'Authorized admin accounts marked "sensitive and cannot be delegated"'
  $deleg = @(Get-ADComputer -Filter { TrustedForDelegation -eq $true } -Properties TrustedForDelegation, PrimaryGroupID -ErrorAction SilentlyContinue | Where-Object { $_.PrimaryGroupID -ne 516 }) +
           @(Get-ADUser -Filter { TrustedForDelegation -eq $true } -ErrorAction SilentlyContinue)
  foreach ($o in $deleg) {
    Warn "$($o.Name) is trusted for UNCONSTRAINED delegation (it can impersonate anyone who connects to it)"
    if (Ask-YN '   Turn that off?') { try { Set-ADAccountControl -Identity $o -TrustedForDelegation $false -ErrorAction Stop; Log "Unconstrained delegation removed from $($o.Name)" } catch { Warn "Couldn't change $($o.Name) ($($_.Exception.Message))" } }
  }
  foreach ($s in @(Get-ADUser -Filter { ServicePrincipalName -like '*' } -Properties ServicePrincipalName -ErrorAction SilentlyContinue | Where-Object { $_.SamAccountName -ne 'krbtgt' })) {
    Review "[!] User $($s.SamAccountName) has a service principal name (Kerberoastable) - give it a long random password: $($s.ServicePrincipalName -join ', ')" }
  # Fine-grained password policies override the domain policy for whoever they apply to
  foreach ($pso in @(Get-ADFineGrainedPasswordPolicy -Filter * -ErrorAction SilentlyContinue)) {
    $weak = @()
    if ($pso.MinPasswordLength -lt 12) { $weak += "min length $($pso.MinPasswordLength)" }
    if (-not $pso.ComplexityEnabled) { $weak += 'no complexity' }
    if ($pso.ReversibleEncryptionEnabled) { $weak += 'reversible encryption' }
    if ($pso.PasswordHistoryCount -lt 24) { $weak += "history $($pso.PasswordHistoryCount)" }
    if ($pso.LockoutThreshold -eq 0 -or $pso.LockoutThreshold -gt 10) { $weak += "lockout threshold $($pso.LockoutThreshold)" }
    if ($pso.MaxPasswordAge.TotalDays -eq 0 -or $pso.MaxPasswordAge.TotalDays -gt 90) { $weak += 'passwords never/rarely expire' }
    if (-not $weak.Count) { continue }
    $who = @(Get-ADFineGrainedPasswordPolicySubject -Identity $pso -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }) -join ', '
    Warn "Fine-grained password policy '$($pso.Name)' is weaker than the domain policy ($($weak -join ', ')) and overrides it for: $who"
    if (Ask-YN '   Make it match the secure domain policy?') {
      try { Set-ADFineGrainedPasswordPolicy -Identity $pso -MinPasswordLength 12 -ComplexityEnabled $true -ReversibleEncryptionEnabled $false -PasswordHistoryCount 24 `
              -LockoutThreshold 5 -LockoutDuration '00:30:00' -LockoutObservationWindow '00:30:00' -MaxPasswordAge '90.00:00:00' -MinPasswordAge '7.00:00:00' -ErrorAction Stop
            Log "Fine-grained password policy $($pso.Name) fixed" } catch { Warn "Couldn't change $($pso.Name) ($($_.Exception.Message))" } }
  }
  if ($SetMAQ) { try { Set-ADDomain -Identity $Dom.DistinguishedName -Replace @{ 'ms-DS-MachineAccountQuota' = 0 } -ErrorAction Stop; Log 'Machine account quota = 0 (only admins can join computers to the domain)' } catch { Warn "Couldn't set the machine account quota ($($_.Exception.Message))" } }
  $kt = (Get-ADUser -Identity 'krbtgt' -Properties PasswordLastSet -ErrorAction SilentlyContinue).PasswordLastSet
  if ($kt -and $kt -lt (Get-Date).AddDays(-180)) { Review "krbtgt password last changed $kt. If the domain may be compromised, reset it twice (Microsoft's New-KrbtgtKeys.ps1)." }
  # The domain needs these firewall rules on its DC
  foreach ($g in 'Active Directory Domain Services', 'Kerberos Key Distribution Center', 'DFS Replication', 'Netlogon Service', 'DNS Service',
                 'Active Directory Web Services', 'File and Printer Sharing', 'Windows Remote Management', 'Core Networking') {
    $fr = @(Get-NetFirewallRule -DisplayGroup $g -ErrorAction SilentlyContinue | Where-Object { $_.Direction -eq 'Inbound' })
    if ($fr.Count) { $fr | Enable-NetFirewallRule -ErrorAction SilentlyContinue }
  }
  Log 'Firewall: Active Directory, Kerberos, DNS, replication and Netlogon rules allowed (the domain needs them)'

  #------------------- GROUP POLICY: make the settings stick -------------------
  if ($EnforceGPO) {
    Section 'Group Policy: writing the settings into the GPOs that apply to this DC'
    try {
      Import-Module GroupPolicy -ErrorAction Stop
      $SysvolPolicies = "\\$($Dom.DNSRoot)\SYSVOL\$($Dom.DNSRoot)\Policies"
      if (-not (Test-Path -LiteralPath $SysvolPolicies)) { $sv = (Get-SmbShare -Name 'SYSVOL' -ErrorAction SilentlyContinue).Path; if ($sv) { $SysvolPolicies = Join-Path $sv "$($Dom.DNSRoot)\Policies" } }
      $DDP = '31B2F340-016D-11D2-945F-00C04FB984F9'; $DDCP = '6AC1786C-016F-11D2-945F-00C04FB984F9'
      $RootLinks = @((Get-GPInheritance -Target $Dom.DistinguishedName).GpoLinks | Where-Object { $_.Enabled } | ForEach-Object { $_.GpoId.ToString().ToUpper() })
      $DcLinks   = @((Get-GPInheritance -Target $Dom.DomainControllersContainer).GpoLinks | Where-Object { $_.Enabled } | ForEach-Object { $_.GpoId.ToString().ToUpper() })
      $PwdPolicy = [ordered]@{ MinimumPasswordAge = 7; MaximumPasswordAge = 90; MinimumPasswordLength = 12; PasswordComplexity = 1; PasswordHistorySize = 24
                               ClearTextPassword = 0; LockoutBadCount = 5; LockoutDuration = 30; ResetLockoutCount = 30 }
      $DcAccess  = [ordered]@{ EnableGuestAccount = 0; LSAAnonymousNameLookup = 0 }
      $EvAudit   = [ordered]@{}; foreach ($c in 'AuditSystemEvents', 'AuditLogonEvents', 'AuditObjectAccess', 'AuditPrivilegeUse', 'AuditPolicyChange', 'AuditAccountManage', 'AuditProcessTracking', 'AuditDSAccess', 'AuditAccountLogon') { $EvAudit[$c] = 3 }
      $L = 'MACHINE\System\CurrentControlSet\Control\Lsa'; $S = 'MACHINE\System\CurrentControlSet\Services'; $P = 'MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System'
      $DcReg = [ordered]@{
        "$L\LmCompatibilityLevel" = 5; "$L\NoLMHash" = 1; "$L\RestrictAnonymous" = 1; "$L\RestrictAnonymousSAM" = 1; "$L\EveryoneIncludesAnonymous" = 0
        "$L\LimitBlankPasswordUse" = 1; "$L\SCENoApplyLegacyAuditPolicy" = 1; "$L\DisableDomainCreds" = 1
        "$L\MSV1_0\NTLMMinClientSec" = 537395200; "$L\MSV1_0\NTLMMinServerSec" = 537395200
        "$S\LanManServer\Parameters\RequireSecuritySignature" = 1; "$S\LanManServer\Parameters\EnableSecuritySignature" = 1; "$S\LanManServer\Parameters\RestrictNullSessAccess" = 1
        "$S\LanmanWorkstation\Parameters\RequireSecuritySignature" = 1; "$S\LanmanWorkstation\Parameters\EnableSecuritySignature" = 1; "$S\LanmanWorkstation\Parameters\EnablePlainTextPassword" = 0
        "$S\NTDS\Parameters\LDAPServerIntegrity" = 2
        "$S\Netlogon\Parameters\RequireSignOrSeal" = 1; "$S\Netlogon\Parameters\SealSecureChannel" = 1; "$S\Netlogon\Parameters\SignSecureChannel" = 1; "$S\Netlogon\Parameters\RequireStrongKey" = 1; "$S\Netlogon\Parameters\RefusePasswordChange" = 0
        "$P\EnableLUA" = 1; "$P\ConsentPromptBehaviorAdmin" = 2; "$P\PromptOnSecureDesktop" = 1; "$P\FilterAdministratorToken" = 1; "$P\DontDisplayLastUserName" = 1; "$P\DisableCAD" = 0; "$P\InactivityTimeoutSecs" = 900
      }
      $Targets = @(@($DDP, $DDCP) + $RootLinks + $DcLinks | Sort-Object -Unique)
      foreach ($g in $Targets) {
        $gpo = Get-GPO -Guid $g -ErrorAction SilentlyContinue; if (-not $gpo) { continue }
        $dir = Join-Path $SysvolPolicies "{$g}"; if (-not (Test-Path -LiteralPath $dir)) { continue }
        $inf = Join-Path $dir 'MACHINE\Microsoft\Windows NT\SecEdit\GptTmpl.inf'
        $isDDP = ($g -eq $DDP); $isDDCP = ($g -eq $DDCP); $atRoot = ($isDDP -or $RootLinks -contains $g)
        if (-not (Test-Path -LiteralPath $inf) -and -not $isDDP -and -not $isDDCP) { continue }    # GPO has no security settings to override
        $existed = Test-Path -LiteralPath $inf
        $sec = Read-Inf $inf; $changed = @()
        # password/lockout only counts from GPOs linked at the domain root; DDP always gets the full set
        if ($atRoot) { foreach ($k in $PwdPolicy.Keys) { if (Set-InfLine $sec 'System Access' $k "$k = $($PwdPolicy[$k])" (-not $isDDP)) { $changed += "$k=$($PwdPolicy[$k])" } } }
        # everything below applies to this DC; the Default Domain Controllers Policy gets the full set, other GPOs only have their own values corrected
        foreach ($k in $DcAccess.Keys) { if (Set-InfLine $sec 'System Access' $k "$k = $($DcAccess[$k])" (-not $isDDCP)) { $changed += "$k=$($DcAccess[$k])" } }
        foreach ($k in $EvAudit.Keys)  { if (Set-InfLine $sec 'Event Audit' $k "$k = 3" (-not $isDDCP)) { $changed += "$k=3" } }
        foreach ($k in $DcReg.Keys)    { if (Set-InfLine $sec 'Registry Values' $k "$k=4,$($DcReg[$k])" (-not $isDDCP)) { $changed += (Split-Path -Path $k -Leaf) } }
        $preview = Remove-RightHolders (Read-Inf $inf)
        if ($preview.Count) {
          Warn "GPO '$($gpo.DisplayName)' gives dangerous rights to: $($preview -join ' | ')"
          if (Ask-YN '   Remove those accounts from the rights? (yes unless the README needs them)') { Remove-RightHolders $sec | Out-Null; $changed += 'dangerous user rights cleaned' } }
        $csvChanged = Update-GpoAuditCsv (Join-Path $dir 'MACHINE\Microsoft\Windows NT\Audit\audit.csv')
        if ($csvChanged) { $changed += 'advanced audit (audit.csv) -> success and failure' }
        if (-not $changed.Count) { Info "GPO '$($gpo.DisplayName)': already secure"; continue }
        if ($existed) { Copy-Item -LiteralPath $inf -Destination (Join-Path $Backup "GptTmpl-$g.inf") -Force }
        Write-Inf $sec $inf
        if (-not $existed) {   # a brand-new security template only runs if the GPO lists the Security extension
          $gdn = "CN={$g},CN=Policies,CN=System,$($Dom.DistinguishedName)"; $cse = '[{827D319E-6EAC-11D2-A4EA-00C04F79F83A}{803E14A0-B4FB-11D0-A0D0-00A0C90F574B}]'
          $ext = [string](Get-ADObject -Identity $gdn -Properties gPCMachineExtensionNames).gPCMachineExtensionNames
          if ($ext -notmatch '827D319E-6EAC-11D2-A4EA-00C04F79F83A') { Set-ADObject -Identity $gdn -Replace @{ gPCMachineExtensionNames = ($cse + $ext) } }
        }
        $ver = Step-GpoVersion $g $dir
        $summary = ($changed | Select-Object -First 12) -join ', '
        if ($changed.Count -gt 12) { $summary += " (+$($changed.Count - 12) more)" }
        Log "GPO '$($gpo.DisplayName)' updated (version $ver): $summary"
      }
      foreach ($gp in @(Get-GPO -All | Where-Object { $_.Id.ToString().ToUpper() -notin @($DDP, $DDCP) })) {
        Review "[!] Non-default GPO '$($gp.DisplayName)' (modified $($gp.ModificationTime)) - open gpmc.msc and check what it sets (full report: $LogDir\gpo-report-before.html)" }
      Log "Group Policy updated. Every GPO was backed up first: Restore-GPO -All -Path $Backup\GPO undoes it"
    } catch { Warn "Group Policy editing stopped ($($_.Exception.Message)). Restore with: Restore-GPO -All -Path $Backup\GPO" }
  }
}

#----------------------------- PROHIBITED SOFTWARE ----------------------------
Section 'Prohibited software (hacking tools, P2P, remote access, games)'
$BadApps = [ordered]@{
  'hacking tool'   = '(?i)wireshark|npcap|winpcap|\bnmap\b|zenmap|angry ip|advanced (ip|port) scanner|\bcain\b|ophcrack|john the ripper|hashcat|l0phtcrack|\bhydra\b|metasploit|burp suite|cheat engine|netstumbler|netcat|\bncat\b|nessus|maltego|aircrack|lazagne|mimikatz|ettercap|nikto|sqlmap'
  'P2P / torrent'  = '(?i)utorrent|bittorrent|qbittorrent|\bvuze\b|azureus|deluge|frostwire|limewire|bitcomet|shareaza|\bemule\b|\bares\b|kazaa|tixati|transmission|bitlord'
  'remote access'  = '(?i)teamviewer|anydesk|rustdesk|realvnc|tightvnc|ultravnc|tigervnc|\bradmin\b|logmein|ammyy|splashtop|remote utilities'
  'game'           = '(?i)\bsteam\b|epic games|minecraft|roblox|\borigin\b|battle\.net|league of legends|fortnite|valorant|riot client|chess titans|pinball'
  'other unwanted' = '(?i)tor browser|ccleaner|ccproxy|driver booster|iobit|webcompanion|search protect|babylon toolbar|conduit'
}
function Get-InstalledApps { return @(Get-ItemProperty $UninstallKeys -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 }) }
function Uninstall-App($app) {
  $name = [string]$app.DisplayName; $u = [string]$app.UninstallString; $q = [string]$app.QuietUninstallString; $cmd = $null
  if ($u -match '(?i)msiexec' -and $u -match '(\{[0-9A-Fa-f-]{36}\})') { $cmd = "msiexec.exe /x $($Matches[1]) /qn /norestart" }
  elseif ($q) { $cmd = $q }
  elseif ($u) {
    $leaf = Split-Path -Path (Get-ExeFromCommand $u) -Leaf
    if ($leaf -match '(?i)^unins\d+\.exe$') { $cmd = "$u /VERYSILENT /SUPPRESSMSGBOXES /NORESTART" }            # Inno Setup
    elseif ($leaf -match '(?i)^(uninst|uninstall|uninstaller)[-_\w]*\.exe$' -and $u -notmatch '\s/S(\s|$)') { $cmd = "$u /S" }   # NSIS
    else { $cmd = $u; Write-Host "   The uninstaller for $name may open a window - finish it, then come back here." -ForegroundColor White }
  }
  if (-not $cmd) { Warn "No uninstaller found for $name - remove it from Settings > Apps"; return }
  try { Start-Process -FilePath 'cmd.exe' -ArgumentList "/s /c `"$cmd`"" -Wait -ErrorAction Stop } catch { Warn "Uninstaller for $name didn't start ($($_.Exception.Message))"; return }
  # many uninstallers re-launch themselves and exit at once, so wait for the entry to disappear
  for ($i = 0; $i -lt 45; $i++) {
    if (-not (Get-InstalledApps | Where-Object { $_.DisplayName -eq $name })) { Log "Uninstalled $name"; return }
    Start-Sleep -Seconds 2
  }
  Warn "$name still shows as installed - finish its uninstaller or remove it from Settings > Apps"
}
$seenApps = @{}
foreach ($app in (Get-InstalledApps | Sort-Object DisplayName)) {
  $dn = [string]$app.DisplayName
  if ($seenApps.ContainsKey($dn) -or (Test-Protected "$dn $($app.Publisher)")) { continue }
  $cat = $null; foreach ($c in $BadApps.Keys) { if ($dn -match $BadApps[$c]) { $cat = $c; break } }
  if (-not $cat) { continue }
  $seenApps[$dn] = $true
  Warn ("Installed {0}: {1} {2} ({3})" -f $cat, $dn, $app.DisplayVersion, $app.Publisher)
  if (Ask-YN "   Uninstall $dn? (yes unless the README requires it)") { Uninstall-App $app }
}
if ($seenApps.Count -eq 0) { Info 'No known prohibited programs found in Programs and Features.' }
Review '[!] Also look through Settings > Apps yourself - the README may name other prohibited software.'

#------------------------------ STARTUP PERSISTENCE ---------------------------
# Why a command / program looks malicious (empty = looks fine)
function Get-SuspicionReason([string]$cmd, [string]$exe) {
  $why = @(); $leaf = ''
  if ($exe) { try { $leaf = Split-Path -Path $exe -Leaf } catch {} }
  if ($leaf -and $leaf -notmatch '\.') { $leaf = "$leaf.exe" }      # 'powershell -c ...' / 'nc -e ...' written without .exe
  $isInterp = $leaf -match '(?i)^(cmd|powershell|pwsh|wscript|cscript|mshta|rundll32|regsvr32|certutil|bitsadmin|python\w*|java|javaw|node)\.exe$'
  if ($isInterp -and $cmd -match $SuspCmdRe) { $why += 'command looks like a backdoor / downloader' }
  if ($isInterp -and $cmd -match $UserWritableRe) { $why += 'runs a script from a user-writable folder' }
  if ($leaf -match $ToolNameRe) { $why += 'hacking / remote-control tool' }
  if ($exe -and $exe -match $UserWritableRe -and (Test-Path -LiteralPath $exe -PathType Leaf) -and -not (Test-Signed $exe)) { $why += 'unsigned program in a user-writable folder' }
  return ($why -join '; ')
}
$Hives = @(); $script:MountedHives = @()
function Mount-UserHives {
  $res = @()
  foreach ($p in @(Get-CimInstance Win32_UserProfile -ErrorAction SilentlyContinue | Where-Object { -not $_.Special -and $_.SID -match '^S-1-5-21-' })) {
    try { (New-Object System.Security.Principal.SecurityIdentifier($p.SID)).Translate([System.Security.Principal.NTAccount]) | Out-Null } catch { continue }   # deleted account
    $user = Split-Path -Path $p.LocalPath -Leaf
    if ($p.Loaded) { $res += [pscustomobject]@{ User = $user; Root = "Registry::HKEY_USERS\$($p.SID)" }; continue }
    $dat = Join-Path $p.LocalPath 'NTUSER.DAT'; if (-not (Test-Path -LiteralPath $dat)) { continue }
    $mn = "CP_$($p.SID)"
    & reg.exe load "HKU\$mn" $dat 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $script:MountedHives = @($script:MountedHives) + $mn; $res += [pscustomobject]@{ User = $user; Root = "Registry::HKEY_USERS\$mn" } }
  }
  $dd = 'C:\Users\Default\NTUSER.DAT'      # template for accounts created later
  if (Test-Path -LiteralPath $dd) { & reg.exe load 'HKU\CP_DEFAULT' $dd 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $script:MountedHives = @($script:MountedHives) + 'CP_DEFAULT'; $res += [pscustomobject]@{ User = '(new users)'; Root = 'Registry::HKEY_USERS\CP_DEFAULT' } } }
  return $res
}
function Dismount-UserHives {
  [GC]::Collect(); [GC]::WaitForPendingFinalizers(); Start-Sleep -Milliseconds 500
  foreach ($mn in $script:MountedHives) {
    $ok = $false
    for ($i = 0; $i -lt 5 -and -not $ok; $i++) { & reg.exe unload "HKU\$mn" 2>&1 | Out-Null; $ok = ($LASTEXITCODE -eq 0); if (-not $ok) { [GC]::Collect(); Start-Sleep -Seconds 1 } }
    if (-not $ok) { Warn "Couldn't unload registry hive HKU\$mn - REBOOT before that user logs in" }
  }
  $script:MountedHives = @()
}

try {
  $Hives = @(Mount-UserHives)
  Section 'Startup programs (Run keys, Startup folders)'
  $RunPaths = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
                'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce',
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run')
  foreach ($h in $Hives) { foreach ($sub in 'Run', 'RunOnce', 'Policies\Explorer\Run') { $RunPaths += "$($h.Root)\Software\Microsoft\Windows\CurrentVersion\$sub" } }
  $runHits = 0
  foreach ($k in $RunPaths) {
    $p = Get-ItemProperty -LiteralPath $k -ErrorAction SilentlyContinue; if (-not $p) { continue }
    foreach ($v in @($p.PSObject.Properties | Where-Object { $_.Name -notin 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider' })) {
      $cmd = [string]$v.Value; if (Test-Protected "$($v.Name) $cmd") { continue }
      $why = Get-SuspicionReason $cmd (Get-ExeFromCommand $cmd)
      if ($why) {
        $runHits++; Warn "Startup entry '$($v.Name)' ($k): $why`n        $cmd"
        if (Ask-YN '   Remove this startup entry?') { Remove-RegValue $k $v.Name | Out-Null; Log "Removed startup entry $($v.Name)" }
      } else { Review "Startup entry (looks normal): $($v.Name) = $cmd" }
    }
  }
  $StartupDirs = @('C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp') + @($UserDirs | ForEach-Object { Join-Path $_ 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup' })
  $wsh = New-Object -ComObject WScript.Shell
  foreach ($d in $StartupDirs) {
    foreach ($i in @(Get-ChildItem -LiteralPath $d -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' })) {
      if (Test-Protected $i.FullName) { continue }
      $target = ''; if ($i.Extension -eq '.lnk') { try { $sc = $wsh.CreateShortcut($i.FullName); $target = "$($sc.TargetPath) $($sc.Arguments)".Trim() } catch {} }
      $why = Get-SuspicionReason $(if ($target) { $target } else { $i.FullName }) (Get-ExeFromCommand $(if ($target) { $target } else { $i.FullName }))
      $runHits++
      Warn "Startup-folder item: $($i.FullName)$(if ($target) { "  ->  $target" })$(if ($why) { "  ($why)" })"
      if (Ask-YN '   Quarantine it so it stops running at login? (no if it is a normal app you recognize)') { if (Move-ToQuarantine $i.FullName) { Log "Quarantined startup item $($i.Name)" } }
    }
  }
  if ($runHits -eq 0) { Info 'No suspicious startup entries.' }

  Section 'Winlogon, Image File Execution Options and accessibility backdoors'
  $shell = [string](Get-RegValue $WL 'Shell'); $ui = [string](Get-RegValue $WL 'Userinit')
  if ($shell -and $shell -notmatch '^(?i)explorer\.exe$') {
    Warn "Winlogon Shell is '$shell' (should be explorer.exe) - runs at every login"
    if (Ask-YN '   Reset it to explorer.exe?') { Set-Reg $WL 'Shell' 'explorer.exe' 'String' | Out-Null; Log 'Winlogon Shell reset' } }
  if ($ui -and $ui -notmatch '^(?i)(C:\\Windows\\system32\\|%SystemRoot%\\system32\\)?userinit\.exe,?$') {
    Warn "Winlogon Userinit is '$ui' (should be C:\Windows\system32\userinit.exe,)"
    if (Ask-YN '   Reset it?') { Set-Reg $WL 'Userinit' 'C:\Windows\system32\userinit.exe,' 'String' | Out-Null; Log 'Winlogon Userinit reset' } }
  foreach ($h in $Hives) {
    $uw = "$($h.Root)\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $us = [string](Get-RegValue $uw 'Shell')
    if ($us) { Warn "User $($h.User) has a personal Winlogon Shell override: $us"; if (Ask-YN '   Remove it?') { Remove-RegValue $uw 'Shell' | Out-Null; Log "Removed Shell override for $($h.User)" } }
  }
  foreach ($IFEO in 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\Image File Execution Options') {
    foreach ($k in @(Get-ChildItem -LiteralPath $IFEO -ErrorAction SilentlyContinue)) {
      $dbg = (Get-ItemProperty -LiteralPath $k.PSPath -ErrorAction SilentlyContinue).Debugger
      if (-not $dbg) { continue }
      Warn "$($k.PSChildName) is hijacked: starting it runs '$dbg' instead (Image File Execution Options)"
      if (Ask-YN '   Remove the hijack?') { Remove-ItemProperty -LiteralPath $k.PSPath -Name 'Debugger' -Force; Log "Removed IFEO Debugger hijack on $($k.PSChildName)" }
    }
  }
  # Sticky-Keys-style backdoor: an accessibility program replaced by a copy of cmd.exe gives
  # a SYSTEM command prompt at the login screen.
  $cmdHash = (Get-FileHash -LiteralPath "$env:windir\System32\cmd.exe" -ErrorAction SilentlyContinue).Hash
  $psHash  = (Get-FileHash -LiteralPath "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe" -ErrorAction SilentlyContinue).Hash
  foreach ($b in 'sethc.exe', 'utilman.exe', 'osk.exe', 'Magnify.exe', 'Narrator.exe', 'DisplaySwitch.exe', 'AtBroker.exe') {
    $p = Join-Path "$env:windir\System32" $b; if (-not (Test-Path -LiteralPath $p)) { continue }
    $orig = ([string](Get-Item -LiteralPath $p).VersionInfo.OriginalFilename) -replace '\.mui$', ''
    $hash = (Get-FileHash -LiteralPath $p -ErrorAction SilentlyContinue).Hash
    if ($hash -eq $cmdHash -or $hash -eq $psHash -or $orig -match '^(?i)(cmd|powershell|pwsh|explorer|taskmgr|regedit|mmc)\.exe$' -or -not (Test-Signed $p)) {
      Warn "$p is NOT the real $b (looks like '$orig') - login-screen backdoor"
      if (Ask-YN "   Restore the real $b with System File Checker?") {
        & sfc.exe "/scanfile=$p" 2>&1 | Out-Null
        $h2 = (Get-FileHash -LiteralPath $p -ErrorAction SilentlyContinue).Hash
        if ($h2 -ne $cmdHash -and $h2 -ne $psHash) { Log "Restored $b" } else { Warn "SFC couldn't restore $b - replace it from another Windows machine or run: DISM /Online /Cleanup-Image /RestoreHealth" }
      }
    }
  }
  foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\Windows') {
    $v = [string](Get-RegValue $k 'AppInit_DLLs')
    if ($v.Trim()) { Warn "AppInit_DLLs loads '$v' into every program ($k)"; if (Ask-YN '   Clear it?') { Set-Reg $k 'AppInit_DLLs' '' 'String' | Out-Null; Set-Reg $k 'LoadAppInit_DLLs' 0 | Out-Null; Log 'Cleared AppInit_DLLs' } }
  }

  Section 'Per-user settings (screen saver lock, installer elevation)'
  foreach ($h in $Hives) {
    $dk = "$($h.Root)\Software\Policies\Microsoft\Windows\Control Panel\Desktop"
    Set-Reg $dk 'ScreenSaveActive' '1' 'String' | Out-Null
    Set-Reg $dk 'ScreenSaverIsSecure' '1' 'String' | Out-Null
    Set-Reg $dk 'ScreenSaveTimeOut' '900' 'String' | Out-Null
    Set-Reg "$($h.Root)\Software\Policies\Microsoft\Windows\Installer" 'AlwaysInstallElevated' 0 | Out-Null
  }
  Log "Screen saver with password after 15 min set for: $(($Hives | ForEach-Object { $_.User }) -join ', ')"
} finally { Dismount-UserHives }

Section 'Scheduled tasks'
$taskHits = 0
foreach ($t in @(Get-ScheduledTask -ErrorAction SilentlyContinue)) {
  $acts = @($t.Actions | Where-Object { $_.Execute })
  if (-not $acts.Count) { continue }
  $cmd = ($acts | ForEach-Object { "$($_.Execute) $($_.Arguments)".Trim() }) -join ' ; '
  $full = "$($t.TaskPath)$($t.TaskName)"
  if (Test-Protected "$full $cmd") { continue }
  $exe = Get-ExeFromCommand $acts[0].Execute
  $why = Get-SuspicionReason $cmd $exe
  $isMs = $t.TaskPath -like '\Microsoft\*'
  if (-not $why -and -not $isMs -and $exe -and (Test-Path -LiteralPath $exe -PathType Leaf) -and -not (Test-Signed $exe)) { $why = 'runs an unsigned program' }
  if ($why) {
    $taskHits++
    Warn "Scheduled task $full ($why) runs as $($t.Principal.UserId): $cmd"
    if (Ask-YN '   Disable and remove this task? (a copy is saved in the backups)') {
      try { Export-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath | Out-File -LiteralPath (Join-Path $Backup ("task-" + ($full -replace '[\\/:*?"<>|]', '_') + '.xml')) -Encoding Unicode } catch {}
      Stop-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction SilentlyContinue
      Unregister-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -Confirm:$false -ErrorAction SilentlyContinue
      Log "Removed scheduled task $full"
    }
  } elseif (-not $isMs) { Review "Scheduled task (check it): $full -> $cmd" }
}
if ($taskHits -eq 0) { Info 'No suspicious scheduled tasks.' }

Section 'Services running unusual programs'
foreach ($s in @(Get-CimInstance Win32_Service -ErrorAction SilentlyContinue)) {
  $pn = [string]$s.PathName; if (-not $pn) { continue }
  if (Test-Protected "$($s.Name) $($s.DisplayName) $pn") { continue }
  $exe = Get-ExeFromCommand $pn
  $why = Get-SuspicionReason $pn $exe
  $inWin = $exe -match '(?i)^[A-Z]:\\Windows\\'
  if (-not $why -and -not $inWin -and (Test-Path -LiteralPath $exe -PathType Leaf) -and -not (Test-Signed $exe)) { $why = 'unsigned service program' }
  if ($why) {
    Warn "Service '$($s.DisplayName)' ($($s.Name)): $why`n        $pn"
    if (Ask-YN '   Stop and disable this service? (no if the README needs it)') { Disable-Svc @($s.Name) }
  }
  # unquoted path with a space = privilege-escalation hole
  if ($pn -notmatch '^\s*"' -and $exe -match ' ' -and -not $inWin) {
    Warn "Unquoted service path (privilege-escalation hole): $($s.Name) -> $pn"
    if ($pn.StartsWith($exe, [StringComparison]::OrdinalIgnoreCase) -and (Ask-YN '   Add the missing quotes?')) {
      $rest = $pn.Substring([Math]::Min($pn.Length, $exe.Length))
      Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\$($s.Name)" 'ImagePath' ('"' + $exe + '"' + $rest) 'ExpandString' | Out-Null; Log "Quoted the path of service $($s.Name)" }
  }
}

Section 'WMI event subscriptions (hidden persistence)'
$consumers = @(Get-CimInstance -Namespace root\subscription -ClassName CommandLineEventConsumer -ErrorAction SilentlyContinue) +
             @(Get-CimInstance -Namespace root\subscription -ClassName ActiveScriptEventConsumer -ErrorAction SilentlyContinue)
foreach ($c in $consumers) {
  if (Test-Protected $c.Name) { continue }
  $what = [string]$c.CommandLineTemplate; if (-not $what) { $what = "script $($c.ScriptFileName) $([string]$c.ScriptText)" }
  Warn "WMI event subscription '$($c.Name)' runs: $($what.Substring(0, [Math]::Min(300, $what.Length)))"
  if (Ask-YN '   Remove it (and its trigger)?') {
    foreach ($b in @(Get-CimInstance -Namespace root\subscription -ClassName __FilterToConsumerBinding -ErrorAction SilentlyContinue | Where-Object { $_.Consumer.Name -eq $c.Name })) {
      $fname = $b.Filter.Name; Remove-CimInstance -InputObject $b -ErrorAction SilentlyContinue
      Get-CimInstance -Namespace root\subscription -ClassName __EventFilter -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $fname } | Remove-CimInstance -ErrorAction SilentlyContinue
    }
    Remove-CimInstance -InputObject $c -ErrorAction SilentlyContinue; Log "Removed WMI subscription $($c.Name)"
  }
}
if (-not $consumers.Count) { Info 'No WMI command/script subscriptions.' }

#------------------------- BACKDOOR PROCESSES & PORTS -------------------------
Section 'Backdoor processes & listening ports'
Write-Host '   Each hit is shown with the reason. Only say yes to things you recognize as malicious.'
$myParent = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID" -ErrorAction SilentlyContinue).ParentProcessId
$Listen = @{}
foreach ($c in @(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue)) { $Listen[[int]$c.OwningProcess] = @($Listen[[int]$c.OwningProcess]) + "TCP $($c.LocalPort)" }
foreach ($c in @(Get-NetUDPEndpoint -ErrorAction SilentlyContinue)) { $Listen[[int]$c.OwningProcess] = @($Listen[[int]$c.OwningProcess]) + "UDP $($c.LocalPort)" }
$procHits = 0
foreach ($p in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)) {
  $procId = [int]$p.ProcessId
  if ($procId -le 4 -or $procId -eq $PID -or $procId -eq $myParent) { continue }
  $exe = [string]$p.ExecutablePath; $cmd = [string]$p.CommandLine; $name = [string]$p.Name
  if (Test-Protected "$name $exe $cmd") { continue }
  $why = @()
  $r = Get-SuspicionReason $cmd $exe; if ($r) { $why += $r }
  if ($Listen.ContainsKey($procId) -and $name -match '(?i)^(cmd|powershell|pwsh|python\w*|wscript|cscript|java|javaw|node|perl|ruby)\.exe$') { $why += 'script interpreter listening on the network' }
  if (-not $why.Count) { continue }
  if ($Listen.ContainsKey($procId)) { $why += "LISTENING on $((@($Listen[$procId] | Where-Object { $_ }) | Sort-Object -Unique) -join ', ')" }
  $procHits++
  Warn "PID $procId $name : $($why -join '; ')`n        $(if ($cmd) { $cmd.Substring(0, [Math]::Min(250, $cmd.Length)) } else { $exe })"
  if (Ask-YN "   Kill it$(if ($exe -and $exe -notmatch '(?i)^[A-Z]:\\(Windows|Program Files)') { ' and quarantine ' + $exe })? (NO unless you're sure - the wrong kill can log you out)") {
    Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue; Start-Sleep -Milliseconds 500
    if ($exe -and $exe -notmatch '(?i)^[A-Z]:\\(Windows|Program Files)') { if (Move-ToQuarantine $exe) { Log "Quarantined $exe" } }
    Log "Killed process $procId ($name)"
  }
}
if ($procHits -eq 0) { Info 'No suspicious processes or listening backdoors found.' }

#--------------------------- MEDIA, ARCHIVES & TOOLS --------------------------
Section 'Media, archives, hacking tools & scripts'
$SkipRoots = @($Out, $Quar, 'C:\CP-Backups')
if ($NeedWeb -or $NeedFTP) { $SkipRoots += 'C:\inetpub' }      # a required site's own files
if ($NeedSMB) { $SkipRoots += @(Get-SmbShare -ErrorAction SilentlyContinue | Where-Object { -not $_.Special -and $_.Path } | ForEach-Object { $_.Path }) }
$OddRoots = @(Get-ChildItem -LiteralPath 'C:\' -Directory -Force -ErrorAction SilentlyContinue | Where-Object {
  -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -and $_.Name -notin 'Windows', 'Program Files', 'Program Files (x86)', 'ProgramData', 'Users', '$Recycle.Bin', 'Recovery', 'System Volume Information', '$WinREAgent', 'Config.Msi', 'CP-Backups', 'CP-Quarantine', 'MSOCache', 'OneDriveTemp', '$SysReset', '$Windows.~BT', '$Windows.~WS' } | ForEach-Object { $_.FullName }) + @('C:\Windows\Temp')
function Test-Skipped([string]$p) { foreach ($s in $SkipRoots) { if ($s -and $p.StartsWith($s, [StringComparison]::OrdinalIgnoreCase)) { return $true } }; return $false }
$Scan = New-Object System.Collections.ArrayList
foreach ($u in $UserDirs) { foreach ($f in Get-FilesSafe $u @('AppData', 'node_modules') 80000) { if (-not (Test-Skipped $f.FullName)) { [void]$Scan.Add($f) } } }
foreach ($r in $OddRoots) { foreach ($f in Get-FilesSafe $r @('node_modules') 50000) { if (-not (Test-Skipped $f.FullName)) { [void]$Scan.Add($f) } } }
$MediaExt   = '.mp3 .mp4 .m4a .m4b .aac .flac .ogg .oga .opus .wav .wma .aif .aiff .mid .midi .mov .avi .mkv .flv .wmv .mpg .mpeg .webm .m4v .3gp .vob'.Split(' ')
$PicExt     = '.jpg .jpeg .png .gif .bmp .tif .tiff .heic .webp'.Split(' ')
$ArchExt    = '.zip .rar .7z .tar .gz .tgz .bz2 .xz .iso .jar .apk .msi .exe'.Split(' ')
$ScriptExt  = '.ps1 .psm1 .bat .cmd .vbs .vbe .js .jse .wsf .hta .py .scr'.Split(' ')
Invoke-QuarantineList 'media files (audio/video)' @($Scan | Where-Object { $MediaExt -contains $_.Extension.ToLower() } | ForEach-Object { $_.FullName })
Invoke-QuarantineList 'picture files (only quarantine ones the README prohibits - pick [e]ach or [n]one if unsure)' @($Scan | Where-Object { $PicExt -contains $_.Extension.ToLower() -and $_.FullName -notmatch '\\(AppData|Microsoft)\\' } | ForEach-Object { $_.FullName })
$ToolFiles = @($Scan | Where-Object { $_.Name -match $ToolNameRe } | ForEach-Object { $_.FullName })
foreach ($pf in 'C:\Program Files', 'C:\Program Files (x86)', 'C:\ProgramData') { foreach ($f in Get-FilesSafe $pf @('WindowsApps', 'Microsoft', 'Windows Defender', 'Package Cache') 200000) { if ($f.Name -match $ToolNameRe -and -not (Test-Protected $f.FullName)) { $ToolFiles += $f.FullName } } }
Invoke-QuarantineList 'hacking / remote-control tools on disk' $ToolFiles
Invoke-QuarantineList 'archives & installers in user / odd folders (tools hide in these)' @($Scan | Where-Object { $ArchExt -contains $_.Extension.ToLower() -and $ToolFiles -notcontains $_.FullName } | ForEach-Object { $_.FullName })
$sysScripts = @($Scan | Where-Object { $ScriptExt -contains $_.Extension.ToLower() -and $_.FullName -match '(?i)^C:\\(Users\\Public\\|Windows\\Temp\\)|^C:\\(?!Users\\)' -and $_.FullName -ne $ScriptPath } | ForEach-Object { $_.FullName })
foreach ($f in Get-FilesSafe 'C:\ProgramData' @('Microsoft', 'Package Cache', 'chocolatey', 'regid.1991-06.com.microsoft') 50000) {
  if ($ScriptExt -contains $f.Extension.ToLower() -and -not (Test-Protected $f.FullName) -and -not (Test-Signed $f.FullName)) { $sysScripts += $f.FullName } }
Invoke-QuarantineList 'scripts in shared / system folders (backdoor scripts live here)' $sysScripts
$oddExe = @(foreach ($r in @('C:\Users\Public', 'C:\Windows\Temp') + $OddRoots) { foreach ($f in Get-FilesSafe $r @() 20000) { if ($f.Extension -in '.exe', '.dll', '.scr' -and -not (Test-Signed $f.FullName) -and -not (Test-Skipped $f.FullName)) { $f.FullName } } })
Invoke-QuarantineList 'unsigned programs in shared / temp folders' $oddExe
Review '--- Scripts in personal folders (your own scripts are normal; look for hacking tools / backdoors) ---'
$Scan | Where-Object { $ScriptExt -contains $_.Extension.ToLower() -and $_.FullName -match '(?i)^C:\\Users\\(?!Public\\)' -and $_.FullName -ne $ScriptPath } | Select-Object -First 100 | ForEach-Object { Review "   $($_.FullName)" }

#--------------------------------- BROWSERS -----------------------------------
Section 'Web browsers'
$Edge = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
foreach ($kv in @(@('SmartScreenEnabled', 1), @('SmartScreenPuaEnabled', 1), @('PreventSmartScreenPromptOverride', 1), @('PreventSmartScreenPromptOverrideForFiles', 1),
                  @('PasswordManagerEnabled', 0), @('DefaultPopupsSetting', 2), @('DownloadRestrictions', 1), @('AutofillCreditCardEnabled', 0), @('AutofillAddressEnabled', 0), @('TyposquattingCheckerEnabled', 1))) {
  Set-Reg $Edge $kv[0] $kv[1] | Out-Null }
Log 'Edge: SmartScreen + PUA blocking on, pop-ups blocked, dangerous downloads blocked, no saved passwords'
$Chrome = 'HKLM:\SOFTWARE\Policies\Google\Chrome'
foreach ($kv in @(@('SafeBrowsingProtectionLevel', 2), @('DefaultPopupsSetting', 2), @('PasswordManagerEnabled', 0), @('DownloadRestrictions', 1), @('AutofillCreditCardEnabled', 0), @('AutofillAddressEnabled', 0))) { Set-Reg $Chrome $kv[0] $kv[1] | Out-Null }
Log 'Chrome: enhanced Safe Browsing, pop-ups blocked, dangerous downloads blocked, no saved passwords (chrome://policy to confirm)'
$FFPolicy = @'
{
  "policies": {
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "EnableTrackingProtection": { "Value": true, "Locked": true, "Cryptomining": true, "Fingerprinting": true },
    "OfferToSaveLogins": false,
    "PasswordManagerEnabled": false,
    "DisablePocket": true,
    "PopupBlocking": { "Default": true, "Locked": true },
    "AppAutoUpdate": true,
    "ExtensionUpdate": true,
    "Preferences": {
      "browser.safebrowsing.malware.enabled": { "Value": true, "Status": "locked" },
      "browser.safebrowsing.phishing.enabled": { "Value": true, "Status": "locked" },
      "browser.safebrowsing.downloads.enabled": { "Value": true, "Status": "locked" },
      "browser.safebrowsing.downloads.remote.block_potentially_unwanted": { "Value": true, "Status": "locked" },
      "browser.safebrowsing.downloads.remote.block_uncommon": { "Value": true, "Status": "locked" },
      "dom.disable_open_during_load": { "Value": true, "Status": "locked" },
      "xpinstall.whitelist.required": { "Value": true, "Status": "locked" }
    }
  }
}
'@
$NoBom = New-Object System.Text.UTF8Encoding $false
foreach ($ff in 'C:\Program Files\Mozilla Firefox', 'C:\Program Files (x86)\Mozilla Firefox') {
  if (-not (Test-Path -LiteralPath (Join-Path $ff 'firefox.exe'))) { continue }
  $dd = Join-Path $ff 'distribution'; New-Item -ItemType Directory -Force -Path $dd | Out-Null
  $pj = Join-Path $dd 'policies.json'; if (Test-Path -LiteralPath $pj) { Copy-Item -LiteralPath $pj -Destination "$Backup\firefox-policies-before.json" -Force }
  [IO.File]::WriteAllText($pj, $FFPolicy, $NoBom)
  Log "Firefox policy installed in $dd (about:policies to confirm)"
}
$FFPrefs = [ordered]@{
  'browser.safebrowsing.malware.enabled' = 'true'; 'browser.safebrowsing.phishing.enabled' = 'true'; 'browser.safebrowsing.downloads.enabled' = 'true'
  'browser.safebrowsing.downloads.remote.block_potentially_unwanted' = 'true'; 'browser.safebrowsing.downloads.remote.block_uncommon' = 'true'
  'dom.disable_open_during_load' = 'true'; 'xpinstall.whitelist.required' = 'true'; 'signon.rememberSignons' = 'false'
  'privacy.donottrackheader.enabled' = 'true'; 'privacy.trackingprotection.enabled' = 'true'; 'datareporting.healthreport.uploadEnabled' = 'false'; 'toolkit.telemetry.enabled' = 'false'
}
$nprof = 0
foreach ($u in $UserDirs) {
  foreach ($prof in @(Get-ChildItem -LiteralPath (Join-Path $u 'AppData\Roaming\Mozilla\Firefox\Profiles') -Directory -ErrorAction SilentlyContinue)) {
    $pjs = Join-Path $prof.FullName 'prefs.js'; if (-not (Test-Path -LiteralPath $pjs)) { continue }
    foreach ($f in $pjs, (Join-Path $prof.FullName 'user.js')) {
      $lines = @(); if (Test-Path -LiteralPath $f) { Copy-Item -LiteralPath $f -Destination (Join-Path $Backup ("ff-" + $prof.Name + '-' + (Split-Path $f -Leaf))) -Force; $lines = @(Get-Content -LiteralPath $f -Encoding UTF8) }
      $lines = @($lines | Where-Object { $l = $_; -not ($FFPrefs.Keys | Where-Object { $l.StartsWith("user_pref(""$_"",") }) })
      foreach ($k in $FFPrefs.Keys) { $lines += "user_pref(""$k"", $($FFPrefs[$k]));" }
      [IO.File]::WriteAllLines($f, [string[]]$lines, $NoBom)
    }
    $nprof++
  }
}
if ($nprof) { Log "Firefox: safe browsing, pop-up blocking, add-on warnings, no saved passwords set in $nprof profile(s)"; if (Get-Process firefox -ErrorAction SilentlyContinue) { Warn 'Firefox is open - close it, or it may overwrite these settings when it exits.' } }

#--------------------------------- HOSTS FILE ---------------------------------
Section 'hosts file'
$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hl = @(Get-Content -LiteralPath $HostsPath -ErrorAction SilentlyContinue); $hch = 0
for ($i = 0; $i -lt $hl.Count; $i++) {
  $t = ([string]$hl[$i] -replace '#.*$', '').Trim(); if (-not $t) { continue }
  $parts = @($t -split '\s+'); $ip = $parts[0]; $names = @($parts | Select-Object -Skip 1)
  if (($ip -eq '127.0.0.1' -or $ip -eq '::1') -and @($names | Where-Object { $_ -notmatch '^(?i)localhost$' }).Count -eq 0) { continue }
  Warn "Unusual hosts entry: $($hl[$i])   (redirects or blocks those sites)"
  if (Ask-YN '   Comment it out? (yes unless the README needs it)') { $hl[$i] = "# $($hl[$i])   # disabled by CP script"; $hch++ }
}
if ($hch) {
  try { (Get-Item -LiteralPath $HostsPath -Force).Attributes = 'Normal'; Set-Content -LiteralPath $HostsPath -Value $hl -Encoding ASCII -ErrorAction Stop; & ipconfig.exe /flushdns | Out-Null; Log "Disabled $hch hosts entr(ies) and flushed the DNS cache" }
  catch { Warn "Couldn't write the hosts file ($($_.Exception.Message))" }
} else { Info 'hosts file has no unusual entries.' }

#---------------------------------- UPDATES -----------------------------------
if ($UpdateMode -ne 's') {
  Section 'Installing Windows Updates (this can take a while)'
  try {
    $sess = New-Object -ComObject Microsoft.Update.Session
    Write-Host '   Searching for updates (a few minutes)...'
    $res = $sess.CreateUpdateSearcher().Search("IsInstalled=0 and IsHidden=0 and Type='Software'")
    $coll = New-Object -ComObject Microsoft.Update.UpdateColl
    foreach ($up in $res.Updates) {
      $cats = @($up.Categories | ForEach-Object { $_.Name }) -join ' '
      if ($UpdateMode -eq 'c' -and $cats -notmatch 'Security Updates|Critical Updates|Definition Updates') { continue }
      if ($up.InstallationBehavior.CanRequestUserInput) { continue }
      if (-not $up.EulaAccepted) { $up.AcceptEula() }
      [void]$coll.Add($up)
    }
    if ($coll.Count -eq 0) { Log 'Windows Update: nothing to install' }
    else {
      Write-Host "   Downloading $($coll.Count) update(s)..."; $dl = $sess.CreateUpdateDownloader(); $dl.Updates = $coll; [void]$dl.Download()
      Write-Host '   Installing...'; $ins = $sess.CreateUpdateInstaller(); $ins.Updates = $coll; $r = $ins.Install()
      Log "Windows Update: $($coll.Count) update(s) processed (result code $($r.ResultCode): 2 = OK, 3 = some failed); reboot needed: $($r.RebootRequired)"
    }
  } catch { Warn "Windows Update failed ($($_.Exception.Message)) - run it from Settings > Windows Update" }
  Review 'Also update Firefox / Chrome / other apps from inside each app (Windows Update only covers Microsoft software).'
}
if ($RunScan -and (Get-Command Start-MpScan -ErrorAction SilentlyContinue)) {
  Section 'Windows Defender quick scan'
  try { Start-MpScan -ScanType QuickScan -ErrorAction Stop
        $th = @(Get-MpThreatDetection -ErrorAction SilentlyContinue)
        if ($th.Count) { foreach ($x in $th) { Warn "Defender found: $(($x.Resources) -join ', ')" } } else { Log 'Defender quick scan: no threats found' } }
  catch { Warn "Defender scan failed ($($_.Exception.Message))" }
}

#-------------------------------- FINAL CHECKS --------------------------------
Section 'Final sanity checks'
$Problems = 0
if ($IsDC) { $amAdmin = @(Get-ADGroupMember -Identity "$DomSid-512" -ErrorAction SilentlyContinue | ForEach-Object { $_.SamAccountName }) + @(Get-ADGroupMember -Identity 'S-1-5-32-544' -ErrorAction SilentlyContinue | ForEach-Object { $_.SamAccountName }) }
else { $amAdmin = @(Get-GroupMembersSafe $AdminGroup | ForEach-Object { $_.Name }) }
$meLocal = $null; if (-not $IsDC) { $meLocal = Get-LocalUser -Name $Me -ErrorAction SilentlyContinue }
if ($meLocal -and -not $meLocal.Enabled) { Warn "Your account $Me is disabled!"; $Problems++ }
if (($IsDC -or $meLocal) -and $amAdmin -notcontains $Me) { Warn "YOU ($Me) are not an administrator any more! Fix it now in your second admin window."; $Problems++ }
foreach ($fp in @(Get-NetFirewallProfile -ErrorAction SilentlyContinue)) { if (-not $fp.Enabled) { Warn "Firewall profile $($fp.Name) is OFF"; $Problems++ } }
if ((Get-RegValue $PolSys 'EnableLUA') -ne 1) { Warn 'UAC is not enabled'; $Problems++ }
try { if (-not (Get-MpComputerStatus -ErrorAction Stop).RealTimeProtectionEnabled) { Warn 'Defender real-time protection is OFF'; $Problems++ } } catch {}
foreach ($name in $Crit.Keys) {
  $up = $false; foreach ($svc in $Crit[$name]) { if ((Get-Service -Name $svc -ErrorAction SilentlyContinue).Status -eq 'Running') { $up = $true } }
  if (-not $up) { Warn "README-critical service '$name' is NOT running - penalty risk! Check services.msc"; $Problems++ }
}
if ($IsDC) {
  Write-Host '   Refreshing Group Policy to make sure it does not undo anything...'
  & cmd.exe /c 'echo N| gpupdate /target:computer /force' 2>&1 | Out-Null
  & secedit.exe /export /cfg "$Backup\secpol-final.inf" /quiet 2>&1 | Out-Null
  $fin = @(Get-Content -LiteralPath "$Backup\secpol-final.inf" -ErrorAction SilentlyContinue)
  $finLen = [int](($fin | Where-Object { $_ -match '^MinimumPasswordLength\s*=' } | Select-Object -First 1) -replace '\D', '')
  $dpp = Get-ADDefaultDomainPasswordPolicy -ErrorAction SilentlyContinue
  if (($dpp -and ($dpp.MinPasswordLength -lt 12 -or $dpp.LockoutThreshold -eq 0)) -or $finLen -lt 12) {
    Warn "After a Group Policy refresh the password policy is weak again (length $($dpp.MinPasswordLength)) - a GPO overrides it. Open gpmc.msc; see $LogDir\gpo-report-before.html"; $Problems++ }
  else { Log 'Group Policy refreshed - password policy is still secure' }
  try { Get-GPResultantSetOfPolicy -ReportType Html -Path (Join-Path $LogDir 'gpresult-after.html') -ErrorAction Stop | Out-Null; Info "Resulting policy report: $LogDir\gpresult-after.html" } catch {}
}
Review ''
Review '=== QUICK MANUAL CHECKLIST (things a script shouldn''t automate) ==='
Review ' [ ] Re-read the README; do every FORENSICS question and scored task it lists.'
Review ' [ ] Confirm the admin / standard-user split matches the README exactly.'
Review ' [ ] Settings > Apps: remove anything else the README prohibits.'
Review ' [ ] Update Firefox / Chrome / Notepad++ / other apps from inside each app.'
Review ' [ ] Check every required service works the way the README describes.'
Review ' [ ] Reboot when done (many settings apply only after a restart).'

$mins = [int]((Get-Date) - $StartTime).TotalMinutes
Section 'Done'
Write-Host ''
Write-Host '================= SCRIPT COMPLETE =================' -ForegroundColor Green
Write-Host " Took             : $mins minutes"
Write-Host " Report (READ IT) : $Report"
Write-Host " Forensics notes  : $ForFile   (snapshot from BEFORE any changes)"
Write-Host " Full log         : $Log"
Write-Host " Backups          : $Backup   (registry-changes.tsv lists every value changed)"
Write-Host " Quarantine       : $Quar"
if ($Problems) { Write-Host " $Problems CRITICAL ISSUE(S) - fix them before you log out (see above)." -ForegroundColor Red }
else { Write-Host ' No critical issues detected by the self-check.' -ForegroundColor Green }
Write-Host ''
Write-Host 'DO THIS NOW, before logging out:' -ForegroundColor Yellow
Write-Host '   1. Open REVIEW-ME.txt and work through it - a lot of points live there.'
Write-Host '      FORENSICS.txt has histories, hashes, recent files and logins for the forensics questions.'
Write-Host '   2. In your second admin window, run:  whoami /groups | findstr /i admin   (you should still be an admin).'
Write-Host '   3. Reboot when you are finished: many policies (UAC, SMBv1, features) apply after a restart.'
Write-Host '      5 wrong passwords now lock an account for 30 minutes. Unlock early: lusrmgr.msc > Users > untick Account is locked out (domain: Unlock-ADAccount NAME)'
Write-Host ''
Write-Host 'Reminder: the biggest point gains are the README''s scored tasks and forensics' -ForegroundColor Cyan
Write-Host 'questions - this script handles the generic hardening, not the scenario-specific items.' -ForegroundColor Cyan
try { Stop-Transcript | Out-Null } catch {}
