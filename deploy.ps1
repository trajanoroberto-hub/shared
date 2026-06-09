# deploy.ps1 — Gato Preto Shared Assets deploy script
# Usage: .\deploy.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoDir = "D:\basket\Trajano\Apps\shared"
$VpsDir  = "/opt/shared"

# ── Read version + build from version.json, then increment ────────────────────
$verPath  = Join-Path $RepoDir "version.json"
$ver      = Get-Content $verPath -Raw | ConvertFrom-Json
$version  = $ver.version
$build    = $ver.build
$newBuild = $build + 1
$ver.build = $newBuild
$json = ($ver | ConvertTo-Json).Replace("`r`n", "`n")
[System.IO.File]::WriteAllText($verPath, $json)

Write-Host ""
Write-Host "=== Shared Assets Deploy ===" -ForegroundColor Cyan
Write-Host "  Deploying : v$version  build $newBuild"
Write-Host ""

# ── 1. git add -A ─────────────────────────────────────────────────────────────
Write-Host "--- 1. git add -A ---" -ForegroundColor Yellow
git -C $RepoDir add -A
if ($LASTEXITCODE -ne 0) { Write-Host "git add failed." -ForegroundColor Red; exit 1 }

# ── 2. git commit ─────────────────────────────────────────────────────────────
Write-Host "--- 2. git commit ---" -ForegroundColor Yellow
$commitOut = git -C $RepoDir commit -m "v$version build $newBuild" 2>&1
Write-Host $commitOut
if ($LASTEXITCODE -ne 0) {
    if ($commitOut -match 'nothing to commit') {
        Write-Host "  (nothing to commit - skipping)" -ForegroundColor DarkGray
    } else {
        Write-Host "git commit failed." -ForegroundColor Red; exit 1
    }
}

# ── 3. git push origin main ───────────────────────────────────────────────────
Write-Host "--- 3. git push ---" -ForegroundColor Yellow
git -C $RepoDir push origin main
if ($LASTEXITCODE -ne 0) { Write-Host "git push failed." -ForegroundColor Red; exit 1 }

# ── 4. VPS: git pull ─────────────────────────────────────────────────────────
Write-Host "--- 4. VPS git pull ---" -ForegroundColor Yellow
$sshExe  = "C:\Windows\System32\OpenSSH\ssh.exe"
$keyFile = "C:\kitty\singer_magpie_deploy"
$vpsHost = "root@10.11.102.20"

icacls $keyFile /inheritance:r | Out-Null
icacls $keyFile /grant:r "${env:USERNAME}:(R)" | Out-Null

& $sshExe -i $keyFile -o StrictHostKeyChecking=no -o BatchMode=yes $vpsHost "cd $VpsDir && git pull"
if ($LASTEXITCODE -ne 0) { Write-Host "VPS deploy failed." -ForegroundColor Red; exit 1 }

# ── Done ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "DEPLOY COMPLETE - Shared Assets v$version build $newBuild" -ForegroundColor Green
Write-Host ""
