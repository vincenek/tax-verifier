# Creates a ZIP of the extension folder for distribution
param(
  [string]$Out = "extension.zip"
)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $root '.'
if (Test-Path $Out) { Remove-Item $Out }
Compress-Archive -Path (Join-Path $src '*') -DestinationPath $Out
Write-Host "Created $Out in $root"
