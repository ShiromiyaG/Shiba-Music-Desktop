#!/usr/bin/env pwsh
# Automatic version bump script
# Usage: .\bump-version.ps1 1.0.1

param(
    [Parameter(Mandatory=$true)]
    [string]$NewVersion
)

# Validate version format (X.Y.Z)
if ($NewVersion -notmatch '^\d+\.\d+\.\d+$') {
    Write-Host "Error: Version must be in format X.Y.Z (ex: 1.0.1)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Automatic Version Bump                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 1. Update version.txt
Write-Host "→ Updating version.txt to $NewVersion..." -ForegroundColor Yellow
Set-Content -Path "version.txt" -Value $NewVersion -NoNewline

# Verify the file was updated
$currentVersion = Get-Content -Path "version.txt" -Raw
if ($currentVersion -eq $NewVersion) {
    Write-Host "  ✓ Version file updated successfully" -ForegroundColor Green
} else {
    Write-Host "  ✗ Failed to update version file" -ForegroundColor Red
    exit 1
}

# 2. Git add
Write-Host "→ Adding to Git..." -ForegroundColor Yellow
git add version.txt
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ✗ Git add failed" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ File added" -ForegroundColor Green

# 3. Git commit
Write-Host "→ Creating commit..." -ForegroundColor Yellow
git commit -m "Bump version to $NewVersion"
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ✗ Git commit failed" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ Commit created" -ForegroundColor Green

# 4. Ask if should push
Write-Host ""
Write-Host "✓ Version successfully updated locally to $NewVersion!" -ForegroundColor Green
Write-Host ""
Write-Host "When you push, GitHub Actions will:" -ForegroundColor Cyan
Write-Host "  1. Automatically create tag v$NewVersion" -ForegroundColor White
Write-Host "  2. Compile the project" -ForegroundColor White
Write-Host "  3. Create a release with the executable" -ForegroundColor White
Write-Host ""
$pushAnswer = Read-Host "Do you want to push now? (y/N)"

if ($pushAnswer -eq 'y' -or $pushAnswer -eq 'Y') {
    Write-Host ""
    Write-Host "→ Pushing to GitHub..." -ForegroundColor Yellow
    git push
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║  ✓ Version $NewVersion published!       ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "GitHub Actions will automatically:" -ForegroundColor Cyan
        Write-Host "  → Create tag v$NewVersion" -ForegroundColor White
        Write-Host "  → Build the project" -ForegroundColor White
        Write-Host "  → Publish the release" -ForegroundColor White
        Write-Host ""
        Write-Host "Monitor at: https://github.com/<user>/<repo>/actions" -ForegroundColor Blue
        Write-Host ""
        Write-Host "Estimated time:" -ForegroundColor Cyan
        Write-Host "  • Tag creation: ~30 seconds" -ForegroundColor White
        Write-Host "  • Full build: ~5-10 minutes" -ForegroundColor White
        Write-Host "  • Release published: ~15 minutes total" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "  ✗ Push failed" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "Commit created locally." -ForegroundColor Yellow
    Write-Host "Execute when ready:" -ForegroundColor Yellow
    Write-Host "  git push" -ForegroundColor White
    Write-Host ""
    Write-Host "This will automatically start the tag and release process." -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "Done! 🎉" -ForegroundColor Green
Write-Host ""
