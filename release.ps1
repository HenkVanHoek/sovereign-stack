# Sovereign Stack - Release & Tagging Assistant (v4.2.1)
# Use this script AFTER updating version.py and performing a CTRL+K commit in PyCharm.

Write-Host "=== Sovereign Stack Release Procedure ===" -ForegroundColor Cyan
Write-Host "1. Ensure version.py is updated with the new version number." -ForegroundColor White
Write-Host "2. Perform your multiline commit in PyCharm (CTRL+K)." -ForegroundColor White
Write-Host ""

$versionFile = "version.py"
if (Test-Path $versionFile) {
    $currentContent = Get-Content $versionFile
    $currentVer = ([regex]::Match($currentContent, '(?<=")\d+\.\d+\.\d+(?=")')).Value
    Write-Host "Detected version in $versionFile: v$currentVer" -ForegroundColor Yellow
}

$confirm = Read-Host "Have you completed the commit and want to create the Git Tag now? (y/n)"
if ($confirm -eq 'y') {
    $tagMsg = Read-Host "Enter a short tag description (e.g., Release v$currentVer)"

    # Git Tagging
    git tag -a "v$currentVer" -m "$tagMsg"
    Write-Host "[OK] Tag v$currentVer created locally." -ForegroundColor Green

    Write-Host ""
    Write-Host "FINAL STEP: Push your changes and tags to GitHub:" -ForegroundColor Cyan
    Write-Host "git push origin main --tags" -ForegroundColor Yellow
} else {
    Write-Host "Action cancelled. Please complete your PyCharm commit first." -ForegroundColor Red
