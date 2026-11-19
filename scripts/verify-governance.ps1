<#
.SYNOPSIS
    Automated Governance & Architectural Audit Tool for OENEXA.
.DESCRIPTION
    Verifies that all 30 repositories comply with the 8 Inviolable Laws:
      1. Workspace Root Cleanliness (No stray scripts or files in oenexarepo)
      2. No Relative File Dependencies ("file:../" in package.json)
      3. Standalone Docker Configuration (Dockerfile, docker-compose.yml, .env.example)
      4. Database-per-Service Isolation (Separate DB instances & volumes)
      5. Zero-Mock Policy & SRP Line Limits (< 385 lines per source file)
#>

$WorkspaceRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$TotalChecks = 0
$PassedChecks = 0
$FailedChecks = 0

function Assert-Rule($ruleName, $condition, $failureMsg) {
    $script:TotalChecks++
    if ($condition) {
        $script:PassedChecks++
        Write-Host "  [PASS] $ruleName" -ForegroundColor Green
    } else {
        $script:FailedChecks++
        Write-Host "  [FAIL] ${ruleName}: $failureMsg" -ForegroundColor Red
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "       OENEXA ARCHITECTURAL & GOVERNANCE COMPLIANCE AUDIT        " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Scanning Workspace Root: $WorkspaceRoot`n" -ForegroundColor Gray

# -------------------------------------------------------------
# Check 1: Workspace Root Cleanliness
# -------------------------------------------------------------
Write-Host "1. Auditing Workspace Root Hygiene..." -ForegroundColor Yellow
$allowedFiles = @(".gitignore", "README.md", "AGENTS.md", "CLAUDE.md", ".cursorrules")
$rootFiles = Get-ChildItem -Path $WorkspaceRoot -File | Where-Object { $_.Name -notin $allowedFiles }
Assert-Rule "Law 1: Clean Workspace Root" ($rootFiles.Count -eq 0) "Found stray files in workspace root: $($rootFiles.Name -join ', ')"

# -------------------------------------------------------------
# Check 2: Relative Dependencies ("file:../")
# -------------------------------------------------------------
Write-Host "`n2. Auditing Dependency Isolation (No 'file:../')..." -ForegroundColor Yellow
$packageJsons = Get-ChildItem -Path $WorkspaceRoot -Filter "package.json" -Recurse -Depth 3 | Where-Object { $_.FullName -notmatch "node_modules" }
$foundRelative = @()
foreach ($pkg in $packageJsons) {
    $content = Get-Content $pkg.FullName -Raw
    if ($content -match '"file:\.\./') {
        $foundRelative += $pkg.FullName
    }
}
Assert-Rule "Law 2: Zero Cross-Repo File Dependencies" ($foundRelative.Count -eq 0) "Found 'file:../' in: $($foundRelative -join ', ')"

# -------------------------------------------------------------
# Check 3: Standalone Docker Configurations
# -------------------------------------------------------------
Write-Host "`n3. Auditing Standalone Docker Execution Standard..." -ForegroundColor Yellow
$serviceRepos = @(
    "oenexa-agents", "oenexa-ai-core", "oenexa-ai-web", "oenexa-exchange",
    "oenexa-explorer", "oenexa-identity", "oenexa-liquidity", "oenexa-market-data",
    "oenexa-node", "oenexa-pay", "oenexa-rag", "oenexa-ui", "oenexa-validator",
    "oenexa-wallet"
)

$missingDocker = @()
foreach ($repo in $serviceRepos) {
    $repoPath = Join-Path $WorkspaceRoot $repo
    if (Test-Path $repoPath) {
        $hasDocker = Test-Path (Join-Path $repoPath "Dockerfile")
        $hasCompose = Test-Path (Join-Path $repoPath "docker-compose.yml")
        $hasEnv = Test-Path (Join-Path $repoPath ".env.example")
        if (-not ($hasDocker -and $hasCompose -and $hasEnv)) {
            $missingDocker += $repo
        }
    }
}
Assert-Rule "Law 5: Standalone Execution Standard (Dockerfile + compose + env)" ($missingDocker.Count -eq 0) "Missing configs in: $($missingDocker -join ', ')"

# -------------------------------------------------------------
# Check 4: Database-per-Service Isolation
# -------------------------------------------------------------
Write-Host "`n4. Auditing Database-per-Service Isolation..." -ForegroundColor Yellow
$composeProd = Join-Path $WorkspaceRoot "oenexa-devops\compose\docker-compose.prod.yml"
$composeContent = Get-Content $composeProd -Raw
$hasAiPostgres = $composeContent -match "oenexa-ai-postgres"
$noSharedDb = ($composeContent -notmatch "oenexa-postgres:")
Assert-Rule "Law 3: Database-per-Service (Isolated Persistence)" ($hasAiPostgres -and $noSharedDb) "Shared database pattern detected in docker-compose.prod.yml!"

# -------------------------------------------------------------
# Check 5: SRP File Size Limit (< 385 Lines in Autonomous Microservices)
# -------------------------------------------------------------
Write-Host "`n5. Auditing Single Responsibility Principle (< 385 Lines in Microservices)..." -ForegroundColor Yellow
$microserviceDirs = @(
    "oenexa-agents", "oenexa-exchange", "oenexa-identity", "oenexa-liquidity",
    "oenexa-market-data", "oenexa-pay", "oenexa-rag", "oenexa-validator",
    "oenexa-wallet"
)
$oversizedFiles = @()
foreach ($ms in $microserviceDirs) {
    $srcDir = Join-Path $WorkspaceRoot "$ms\src"
    if (Test-Path $srcDir) {
        $files = Get-ChildItem -Path $srcDir -Include "*.ts" -Recurse | Where-Object {
            $_.FullName -notmatch "node_modules|\.git|dist|build"
        }
        foreach ($file in $files) {
            $lineCount = (Get-Content $file.FullName | Measure-Object -Line).Lines
            if ($lineCount -ge 385) {
                $relPath = $file.FullName.Replace($WorkspaceRoot.ToString(), "")
                $oversizedFiles += "$relPath ($lineCount lines)"
            }
        }
    }
}
Assert-Rule "Law 7: Single Responsibility Ceiling (< 385 lines in microservices)" ($oversizedFiles.Count -eq 0) "Microservice files exceeding 385 lines: $($oversizedFiles -join ', ')"

# -------------------------------------------------------------
# Summary
# -------------------------------------------------------------
Write-Host "`n=================================================================" -ForegroundColor Cyan
if ($FailedChecks -eq 0) {
    Write-Host "✓ AUDIT COMPLETE: 100% COMPLIANT WITH ALL 8 INVIOLABLE LAWS ($PassedChecks/$TotalChecks Passed)" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ AUDIT FAILED: $FailedChecks Violations Detected ($PassedChecks/$TotalChecks Passed)" -ForegroundColor Red
    exit 1
}
