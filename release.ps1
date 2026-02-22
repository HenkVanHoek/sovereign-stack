# Sovereign Stack - Windows Release Utility (v4.2.0)
$versionFile = "version.py"

# 1. Haal huidige versie op
$currentContent = Get-Content $versionFile
$currentVer = ([regex]::Match($currentContent, '(?<=")\d+\.\d+\.\d+(?=")')).Value
Write-Host "Huidige versie: v$currentVer" -ForegroundColor Cyan

# 2. Vraag om nieuwe info
$newVer = Read-Host "Voer nieuwe versie in (bijv. 4.2.1)"
$msg = Read-Host "Commit message (feat/fix/docs)"

# 3. Update version.py
(Get-Content $versionFile) -replace "__version__ = `".*`"","__version__ = `"$newVer`"" | Set-Content $versionFile
Write-Host "Updated $versionFile naar v$newVer" -ForegroundColor Green

# 4. Git acties
git add .
git commit -m "$msg"
git tag -a "v$newVer" -m "Release v$newVer: $msg"

Write-Host "Klaar! Voer nu uit: git push origin main --tags" -ForegroundColor Yellow
