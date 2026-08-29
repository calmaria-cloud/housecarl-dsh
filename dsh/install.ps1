#requires -Version 5.1
<#
  install.ps1 - build houseCARL-mcp for DeepSeek Harness (DSH) and print the mount config.

  houseCARL-mcp is a stdio MCP server by default (see src/housecarl-mcp/Program.cs). This script:
    1. regenerates the reflection schema (corpus.json) via housecarl-generator
    2. publishes the server (net10.0, win-x64, framework-dependent, trimming OFF)
    3. copies corpus.json beside the exe and strips the dev-only appsettings.json
    4. prints the cordis.patch.yml snippet for @deepseek-ai/dsh-mcp-client

  Requires the .NET 10 SDK. This fork retargets upstream's net9.0 -> net10.0.
  See dsh/README.md for the full DeepSeek Harness setup.
#>
$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$GenProj   = Join-Path $RepoRoot 'src\housecarl-generator'
$McpProj   = Join-Path $RepoRoot 'src\housecarl-mcp'
$GenDir    = Join-Path $RepoRoot 'generated'
$RefDir    = Join-Path $RepoRoot '.claude\skills\mutagen-reference\references'
$OutDir    = Join-Path $RepoRoot 'dsh\server'

Write-Host '[1/3] regenerate corpus.json (schema generator)' -ForegroundColor Cyan
dotnet run --project $GenProj -c Release -- $GenDir $RefDir
if ($LASTEXITCODE -ne 0) { throw "generator failed (exit $LASTEXITCODE)" }

Write-Host '[2/3] publish housecarl-mcp (Release, win-x64, framework-dependent)' -ForegroundColor Cyan
dotnet publish $McpProj -c Release -r win-x64 --self-contained false -o $OutDir
if ($LASTEXITCODE -ne 0) { throw "publish failed (exit $LASTEXITCODE)" }

Write-Host '[3/3] place corpus.json beside the exe + strip dev appsettings' -ForegroundColor Cyan
Copy-Item (Join-Path $GenDir 'corpus.json') (Join-Path $OutDir 'corpus.json') -Force
Get-ChildItem $OutDir -Filter 'appsettings*.json' -ErrorAction SilentlyContinue | Remove-Item -Force

$Exe = Join-Path $OutDir 'housecarl-mcp.exe'
if (-not (Test-Path $Exe)) { throw "server exe not produced at $Exe" }

Write-Host ''
Write-Host "Server built at: $Exe" -ForegroundColor Green
Write-Host ''
Write-Host 'Add this to ~/.dsh/profiles/<profile>/cordis.patch.yml (edit the MO2 root to match yours):' -ForegroundColor Yellow
Write-Host ''
Write-Host '- insert:'
Write-Host '    - id: housecarl'
Write-Host "      name: '@deepseek-ai/dsh-mcp-client'"
Write-Host '      config:'
Write-Host '        serverName: housecarl'
Write-Host '        transport: stdio'
Write-Host "        command: $Exe"
Write-Host '        env:'
Write-Host "          HouseCarl__Mo2InstanceDir: 'E:\Game\mo2'"
Write-Host ''
Write-Host 'Reload the DSH session; houseCARL tools appear as mcp__housecarl__<tool>.'
