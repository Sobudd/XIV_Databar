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

foreach ($name in $exports.Keys) {
  $url = $exports[$name]
  $target = Join-Path -Path .\Libs -ChildPath $name
  Write-Host "Exporting $name from $url -> $target"
  svn export $url $target --force
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "svn export failed for $name"
  }
}

Write-Host "Done. Review .\Libs and commit to git if satisfied."
