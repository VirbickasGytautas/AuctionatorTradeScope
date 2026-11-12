$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$tocPath = Join-Path $root 'AuctionatorTradeScope.toc'
$corePath = Join-Path $root 'Core.lua'
if (!(Test-Path $tocPath) -or !(Test-Path $corePath)) {
    throw 'The TOC and Core.lua must be in the repository root.'
}
$toc = Get-Content $tocPath -Raw
$core = Get-Content $corePath -Raw
if ($toc -notmatch '(?m)^## Version:\s*([^\r\n]+)') { throw 'Missing TOC version.' }
$tocVersion = $Matches[1].Trim()
if ($core -notmatch 'ATS\s*=\s*\{\s*version\s*=\s*"([^"]+)"') { throw 'Missing Core.lua version.' }
$coreVersion = $Matches[1]
if ($tocVersion -ne $coreVersion) { throw "Version mismatch: TOC=$tocVersion, Core.lua=$coreVersion" }
Write-Host "TradeScope version consistent: $tocVersion" -ForegroundColor Green
Write-Host 'Check your changelog and create a new git tag before publishing.'
