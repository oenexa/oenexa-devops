# =====================================================================
# OENEXA ECOSYSTEM - Master Ecosystem Test Runner
# Orchestrates Unit, BDD, and TDD execution across Core (Java 25) & Web (React 18)
# =====================================================================
param(
    [Alias("Target", "Repo")]
    [ValidateSet("all", "core", "backend", "web", "frontend")]
    [string]$Scope = "all",

    [Alias("T", "Category")]
    [ValidateSet("all", "unit", "bdd", "tdd", "separate")]
    [string]$Type = "unit",

    [Alias("M")]
    [ValidateSet("all", "domain", "application", "infrastructure", "api")]
    [string]$Module = "all",

    [switch]$Coverage,
    [switch]$Cached,
    [switch]$Help
)

$Root = if (Test-Path "$PSScriptRoot\oenexa-ai-core") { $PSScriptRoot } else { Split-Path -Parent $PSScriptRoot }

if (-not (Test-Path -Path $env:JAVA_HOME)) {
    $UserJava = [System.Environment]::GetEnvironmentVariable('JAVA_HOME', 'User')
    $MachineJava = [System.Environment]::GetEnvironmentVariable('JAVA_HOME', 'Machine')
    if ($UserJava -and (Test-Path $UserJava)) {
        $env:JAVA_HOME = $UserJava
    } elseif ($MachineJava -and (Test-Path $MachineJava)) {
        $env:JAVA_HOME = $MachineJava
    }
}

if ($Help) {
    Write-Host @"
OENEXA Master Ecosystem Test Runner:
  Usage: .\run-tests.ps1 [-Scope <all|core|web>] [-Type <unit|bdd|tdd|separate|all>] [-Module <all|domain|application|infrastructure|api>] [-Coverage] [-Cached]

Options:
  -Scope, -Target : Repository scope ('all', 'core'/'backend', 'web'/'frontend') - [Default: 'all']
  -Type, -T       : Test category for core:
                      'unit'     : Fast isolated unit tests (excludes BDD and TDD) - [Default]
                      'bdd'      : Behavior-Driven Development (Cucumber Gherkin scenarios)
                      'tdd'      : Test-Driven Development (Invariants, memory algorithms, contracts)
                      'separate' : Executes Unit, BDD, and TDD in distinct separate phases
                      'all'      : Executes all tests in a unified run
  -Module, -M     : Target hexagonal module for oenexa-ai-core (default: 'all')
  -Coverage       : Generate JaCoCo HTML & XML code coverage reports
  -Cached         : Use build cache instead of forcing fresh test execution
"@
    exit 0
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  OENEXA ECOSYSTEM TEST SUITE - Scope: $Scope | Mode: $Type" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$OverallFailed = $false
$CoreRunner = Join-Path $Root "oenexa-ai-core\test-runner.ps1"
$WebDir = Join-Path $Root "oenexa-ai-web"

# 1. Core Backend (Java 25 Hexagonal Architecture)
if ($Scope -in @("all", "core", "backend")) {
    Write-Host "`n>>> [ECOSYSTEM: 1/2] Executing OENEXA-AI-CORE Test Suite..." -ForegroundColor Yellow
    if (-not (Test-Path $CoreRunner)) {
        Write-Error "Test runner script not found at $CoreRunner"
        exit 1
    }

    $params = @{
        Type   = $Type
        Module = $Module
    }
    if ($Coverage) { $params["Coverage"] = $true }
    if ($Cached) { $params["Cached"] = $true }

    & $CoreRunner @params
    if ($LASTEXITCODE -ne 0) {
        $OverallFailed = $true
        Write-Host ">>> OENEXA-AI-CORE tests FAILED" -ForegroundColor Red
    } else {
        Write-Host ">>> OENEXA-AI-CORE tests PASSED" -ForegroundColor Green
    }
}

# 2. Web Frontend (React 18 + Vite + Vitest)
if ($Scope -in @("all", "web", "frontend")) {
    Write-Host "`n>>> [ECOSYSTEM: 2/2] Executing OENEXA-AI-WEB Test Suite..." -ForegroundColor Yellow
    if (-not (Test-Path $WebDir)) {
        Write-Error "Web directory not found at $WebDir"
        exit 1
    }

    Push-Location $WebDir
    try {
        & npm test
        if ($LASTEXITCODE -ne 0) {
            $OverallFailed = $true
            Write-Host ">>> OENEXA-AI-WEB tests FAILED" -ForegroundColor Red
        } else {
            Write-Host ">>> OENEXA-AI-WEB tests PASSED" -ForegroundColor Green
        }
    } finally {
        Pop-Location
    }
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
if ($OverallFailed) {
    Write-Host "  OENEXA ECOSYSTEM EXECUTION RESULT: FAILED" -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 1
} else {
    Write-Host "  OENEXA ECOSYSTEM EXECUTION RESULT: ALL SUITES PASSED" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 0
}
