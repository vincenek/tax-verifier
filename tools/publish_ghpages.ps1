# Build and publish Flutter web to gh-pages (manual)
# Usage: Open PowerShell in project root and run: .\tools\publish_ghpages.ps1

param(
    [string]$BaseHref = '/tax-verifier/'
)

Write-Host "Building Flutter web (base-href=$BaseHref)"
flutter build web --release --base-href $BaseHref
if ($LASTEXITCODE -ne 0) { Write-Error "Build failed"; exit $LASTEXITCODE }

# create a temporary worktree to push build artifacts to gh-pages
$tmp = Join-Path $env:TEMP "plv-ghpages-$(Get-Random)"
Write-Host "Preparing temporary folder: $tmp"
New-Item -ItemType Directory -Path $tmp | Out-Null

git worktree add -B gh-pages $tmp origin/gh-pages 2>$null || git worktree add -B gh-pages $tmp

Write-Host "Copying build files"
robocopy build\web $tmp /MIR | Out-Null

Push-Location $tmp
git add -A
git commit -m "gh-pages: automated publish from local script" -a 2>$null || Write-Host "No changes to commit"
git push origin gh-pages --force
Pop-Location

Write-Host "Cleaning up"
# optionally remove worktree
# git worktree remove $tmp
Write-Host "Published build/web to gh-pages"
