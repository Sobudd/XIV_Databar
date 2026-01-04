<#
Update Libs from CurseForge externals listed in .pkgmeta

Run from the addon root (where .pkgmeta lives):
  .\scripts\update-libs.ps1

This script requires an `svn` client on PATH.
#>

Write-Host "Checking for svn..."
$svn = Get-Command svn -ErrorAction SilentlyContinue
if (-not $svn) {
  Write-Error "svn not found. Install Subversion (SlikSVN/TortoiseSVN) and ensure svn.exe is on PATH."
  exit 1
}

Write-Host "Creating Libs directory..."
New-Item -ItemType Directory -Force -Path .\Libs | Out-Null

Write-Host "Exporting libraries from CurseForge..."

function Export-WithRetry {
  param(
    [string]$url,
    [string]$target,
    [int]$tries = 3
  )

  for ($i = 1; $i -le $tries; $i++) {
    Write-Host "Exporting $target from $url (attempt $i of $tries)"
    svn export $url $target --force
    $exit = $LASTEXITCODE
    if ($exit -eq 0) {
      return $true
    }
    Write-Warning "svn export attempt $i failed for $target (exit $exit)"
    Start-Sleep -Seconds ([math]::Pow(2, $i))
  }
  return $false
}

# Mapping of target folder => SVN URL
$exports = @{
  'LibStub' = 'https://repos.curseforge.com/wow/libstub/trunk'
  'CallbackHandler-1.0' = 'https://repos.curseforge.com/wow/callbackhandler/trunk/CallbackHandler-1.0'
  'LibDataBroker-1.1' = 'https://repos.curseforge.com/wow/libdatabroker-1-1/trunk'
  'AceAddon-3.0' = 'https://repos.curseforge.com/wow/ace3/trunk/AceAddon-3.0'
  'AceConfig-3.0' = 'https://repos.curseforge.com/wow/ace3/trunk/AceConfig-3.0'
  'AceConsole-3.0' = 'https://repos.curseforge.com/wow/ace3/trunk/AceConsole-3.0'
  'AceDB-3.0' = 'https://repos.curseforge.com/wow/ace3/trunk/AceDB-3.0'
  'AceDBOptions-3.0' = 'https://repos.curseforge.com/wow/ace3/trunk/AceDBOptions-3.0'
  'AceEvent-3.0' = 'https://repos.curseforge.com/wow/ace3/trunk/AceEvent-3.0'
  'AceGUI-3.0' = 'https://repos.curseforge.com/wow/ace3/trunk/AceGUI-3.0'
  'AceGUI-3.0-SharedMediaWidgets' = 'https://repos.curseforge.com/wow/ace-gui-3-0-shared-media-widgets/trunk'
  'AceHook-3.0' = 'https://repos.curseforge.com/wow/ace3/trunk/AceHook-3.0'
  'AceLocale-3.0' = 'https://repos.curseforge.com/wow/ace3/trunk/AceLocale-3.0'
  'LibQTip-1.0' = 'https://repos.curseforge.com/wow/libqtip-1-0/trunk'
  'LibSharedMedia-3.0' = 'https://repos.curseforge.com/wow/libsharedmedia-3-0/trunk/LibSharedMedia-3.0'
}
 $failed = @()

foreach ($name in $exports.Keys) {
  $url = $exports[$name]
  $target = Join-Path -Path .\Libs -ChildPath $name
  $ok = Export-WithRetry -url $url -target $target -tries 3
  if (-not $ok) {
    Write-Warning "svn export failed for $name after multiple attempts"
    $failed += $name
  }
}

Write-Host "Done. Review .\Libs and commit to git if satisfied."
if ($failed.Count -gt 0) {
  Write-Warning "The following libraries failed to export: $($failed -join ', ')"
  Write-Warning "You can re-run the script later or fetch those libraries from alternative sources (GitHub) if CurseForge is unavailable."
  # Do not fail the workflow; return success so packaging can continue.
  exit 0
}

exit 0
