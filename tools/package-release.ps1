$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression.FileSystem

$projectRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$buildRoot = [System.IO.Path]::GetFullPath((Join-Path $projectRoot 'build'))
$stage = [System.IO.Path]::GetFullPath((Join-Path $buildRoot 'release-stage'))
$dist = [System.IO.Path]::GetFullPath((Join-Path $projectRoot 'dist'))

if (-not $stage.StartsWith($buildRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Unexpected staging path: $stage"
}
if (-not $dist.StartsWith($projectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Unexpected distribution path: $dist"
}

$manifestPath = Join-Path $projectRoot 'manifest.json'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$version = [string]$manifest.version
if ($version -notmatch '^\d+\.\d+\.\d+(?:\.\d+)?$') {
  throw "Manifest version is missing or invalid: $version"
}

New-Item -ItemType Directory -Force -Path $dist | Out-Null
if (Test-Path -LiteralPath $stage) {
  Remove-Item -LiteralPath $stage -Recurse -Force
}
New-Item -ItemType Directory -Force -Path (Join-Path $stage 'icons'), (Join-Path $stage 'popup'), (Join-Path $stage 'rules') | Out-Null

Copy-Item -LiteralPath $manifestPath -Destination $stage
$iconFiles = @(
  (Join-Path $projectRoot 'icons\icon16.png')
  (Join-Path $projectRoot 'icons\icon32.png')
  (Join-Path $projectRoot 'icons\icon48.png')
  (Join-Path $projectRoot 'icons\icon128.png')
)
Copy-Item -LiteralPath $iconFiles -Destination (Join-Path $stage 'icons')

$popupFiles = @(
  (Join-Path $projectRoot 'popup\popup.html')
  (Join-Path $projectRoot 'popup\popup.css')
  (Join-Path $projectRoot 'popup\popup.js')
)
Copy-Item -LiteralPath $popupFiles -Destination (Join-Path $stage 'popup')
Copy-Item -LiteralPath (Join-Path $projectRoot 'rules\web-mode.json') -Destination (Join-Path $stage 'rules')

$zipPath = Join-Path $dist "web-please-v$version.zip"
if (Test-Path -LiteralPath $zipPath) {
  Remove-Item -LiteralPath $zipPath -Force
}
[System.IO.Compression.ZipFile]::CreateFromDirectory(
  $stage,
  $zipPath,
  [System.IO.Compression.CompressionLevel]::Optimal,
  $false
)

$archive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
try {
  $manifestCount = @($archive.Entries | Where-Object FullName -eq 'manifest.json').Count
  if ($manifestCount -ne 1) {
    throw "Release ZIP must contain exactly one manifest.json; found $manifestCount."
  }
} finally {
  $archive.Dispose()
}

Get-ChildItem -LiteralPath $dist -Filter 'web-please-v*.zip' -File |
  Where-Object FullName -ne $zipPath |
  ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }

Remove-Item -LiteralPath $stage -Recurse -Force
if ((Get-ChildItem -LiteralPath $buildRoot -Force | Measure-Object).Count -eq 0) {
  Remove-Item -LiteralPath $buildRoot -Force
}

$hash = Get-FileHash -LiteralPath $zipPath -Algorithm SHA256
[pscustomobject]@{
  Path = $zipPath
  Version = $version
  Bytes = (Get-Item -LiteralPath $zipPath).Length
  SHA256 = $hash.Hash
}
