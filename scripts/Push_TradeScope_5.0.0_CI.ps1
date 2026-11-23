# Send exact, staged 5.0.0 sources to a non-publishing CI branch.
# No tags and no writes to main.
$ErrorActionPreference = 'Stop'
$Project = 'E:\Projects\AuctionatorTradeScope'
$Zip = Join-Path $env:USERPROFILE 'Downloads\TradeScope_5.0.0_Stable_Source.zip'
$Branch = 'beta/5.0.0-ci'
$Stage = Join-Path $env:TEMP ('ATS_CI_Source_' + [guid]::NewGuid().ToString('N'))
$Tree = Join-Path $env:TEMP ('ATS_CI_Tree_' + [guid]::NewGuid().ToString('N'))
$success = $false

function Git([string[]]$Arg) {
    & git @Arg
    if ($LASTEXITCODE -ne 0) { throw "git failed: $($Arg -join ' ')" }
}
if (!(Test-Path -LiteralPath $Project -PathType Container)) { throw "Project missing: $Project" }
if (!(Test-Path -LiteralPath $Zip -PathType Leaf)) { throw "ZIP missing: $Zip" }
$origin = (& git -C $Project remote get-url origin).Trim()
if ($LASTEXITCODE -ne 0 -or $origin -notmatch 'VirbickasGytautas/AuctionatorTradeScope(?:\.git)?$') {
    throw "Unexpected origin remote: $origin"
}
try {
    Expand-Archive -LiteralPath $Zip -DestinationPath $Stage
    $toc = Join-Path $Stage 'AuctionatorTradeScope.toc'
    if (!(Test-Path $toc) -or !(Select-String -LiteralPath $toc -Pattern '^## Version: 5\.0\.0$' -Quiet)) {
        throw 'Source ZIP is not exactly 5.0.0'
    }
    if (!(Test-Path (Join-Path $Stage 'Engine\Combat.lua'))) { throw 'Incomplete addon sources' }
    if (!(Select-String -LiteralPath (Join-Path $Stage '.github\workflows\curseforge-beta-dryrun.yml') -Pattern 'beta/5.0.0-ci' -Quiet)) {
        throw 'Missing CI branch trigger'
    }
    Git @('-C', $Project, 'fetch', 'origin', 'main')
    & git -C $Project ls-remote --exit-code --heads origin ('refs/heads/' + $Branch) | Out-Null
    if ($LASTEXITCODE -eq 0) { throw "Remote branch already exists: $Branch. Refusing duplicate push." }
    if ($LASTEXITCODE -ne 2) { throw 'Could not establish remote branch absence' }
    & git -C $Project show-ref --verify --quiet ('refs/heads/' + $Branch)
    if ($LASTEXITCODE -eq 0) { throw "Local branch already exists: $Branch" }
    Git @('-C', $Project, 'worktree', 'add', '-b', $Branch, $Tree, 'origin/main')
    # Delete only Git-tracked paths that the exact source ZIP no longer contains.
    $old = & git -C $Tree ls-files
    if ($LASTEXITCODE -ne 0) { throw 'Cannot enumerate tracked paths' }
    foreach ($name in $old) {
        if (!(Test-Path -LiteralPath (Join-Path $Stage $name))) {
            $dest = Join-Path $Tree $name
            if (Test-Path -LiteralPath $dest -PathType Leaf) { Remove-Item -LiteralPath $dest -Force }
        }
    }
    & robocopy $Stage $Tree /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw 'Failed to copy exact sources into worktree' }
    Git @('-C', $Tree, 'add', '-A')
    & git -C $Tree diff --cached --quiet
    if ($LASTEXITCODE -eq 0) { throw 'Unexpectedly no changes relative to origin/main' }
    Git @('-C', $Tree, 'commit', '-m', 'build: stage TradeScope 5.0.0 for Lua 5.1 CI (no tag)')
    Git @('-C', $Tree, 'push', '-u', 'origin', $Branch)
    $success = $true
    Write-Host 'Pushed 5.0.0 source to nonpublishing CI branch.' -ForegroundColor Green
    Write-Host 'Review: https://github.com/VirbickasGytautas/AuctionatorTradeScope/actions'
}
finally {
    if (Test-Path -LiteralPath $Stage) { Remove-Item -LiteralPath $Stage -Recurse -Force }
    if ($success) {
        & git -C $Project worktree remove $Tree --force
        Write-Host 'Temporary worktree cleaned up.'
    } elseif (Test-Path -LiteralPath $Tree) {
        Write-Warning "Push failed. Worktree preserved for inspection: $Tree"
    }
}
