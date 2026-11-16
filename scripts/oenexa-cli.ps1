<#
.SYNOPSIS
    OENEXA Master Unified Developer CLI & Orchestrator Tool.
.DESCRIPTION
    Provides a single ergonomic interface for developers, DevOps, and SREs:
      - up [profile]  : Launch services via Docker Profiles (ai, blockchain, portal, commerce, all)
      - down          : Stop all active ecosystem containers cleanly
      - status        : Git status across all 30 polyrepo repositories
      - sync          : Synchronize commits to dual remotes (origin GitHub + server VPS)
      - test [target] : Run zero-mock test suites (core, web, all)
      - logs [svc]    : Stream unified live container logs
      - routes        : Display all Single-Domain URL paths under oenexa.com
#>
param(
    [Parameter(Position=0)]
    [ValidateSet("up", "down", "status", "sync", "test", "logs", "routes", "ps", "deploy", "help")]
    [string]$Command = "help",

    [Parameter(Position=1)]
    [string]$Target = "all",

    [Parameter(Position=2)]
    [ValidateSet("prod", "dev")]
    [string]$Env = "prod"
)

$ErrorActionPreference = "Continue"
$Root = $PSScriptRoot

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "       OENEXA UNIFIED ECOSYSTEM MASTER ORCHESTRATOR CLI          " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan

switch ($Command) {
    "up" {
        $profile = if ($Target) { $Target } else { "all" }
        Write-Host "Starting ecosystem containers with profile: [$profile]..." -ForegroundColor Yellow
        docker compose --profile $profile up -d --build
        Write-Host "`n✓ Services launched successfully! Run '.\oenexa-cli.ps1 routes' to view URL endpoints." -ForegroundColor Green
    }

    "down" {
        Write-Host "Stopping all ecosystem containers cleanly..." -ForegroundColor Yellow
        docker compose down
        Write-Host "✓ All containers stopped." -ForegroundColor Green
    }

    "ps" {
        docker compose ps
    }

    "status" {
        Write-Host "Checking git status across all 30 repositories..." -ForegroundColor Yellow
        & "$Root\scripts\git-sync.ps1" -Action status
    }

    "sync" {
        Write-Host "Synchronizing all 30 repositories to origin (GitHub) and server (VPS)..." -ForegroundColor Yellow
        & "$Root\scripts\git-sync.ps1" -Action push
    }

    "test" {
        Write-Host "Executing test suite for scope: [$Target]..." -ForegroundColor Yellow
        if ($Target -in @("core", "backend")) {
            Push-Location "$Root\oenexa-ai-core"
            .\gradlew.bat test
            Pop-Location
        } elseif ($Target -in @("web", "frontend")) {
            Push-Location "$Root\oenexa-ai-web"
            npm test -- --run
            Pop-Location
        } else {
            & "$Root\scripts\run-tests.ps1" -Scope all
        }
    }

    "logs" {
        if ($Target -and $Target -ne "all") {
            docker compose logs -f $Target
        } else {
            docker compose logs -f --tail=50
        }
    }

    "routes" {
        Write-Host @"
🌐 OENEXA Unified Single-Domain Routing Table (http://localhost or https://oenexa.com):
-----------------------------------------------------------------
  🏠 Main Portal, Markets & Trading UI : http://localhost/           (oenexa-ui:80)
  ⚡ AI Operating System Studio Cockpit : http://localhost/ai/       (oenexa-ai-web:80)
  🧠 AI Core Central Intelligence API  : http://localhost/api/v4/    (oenexa-ai-core:8080)
  🔍 L1 Post-Quantum Block Explorer    : http://localhost/explorer/  (oenexa-explorer:80)
  ⛓️ Layer-1 Blockchain Node JSON-RPC   : http://localhost/rpc        (oenexa-node:8545)
  🍔 D-Commerce Food Storefront        : http://localhost/food/      (oengo-web:3000)
  💳 Escrow Relayer & Banking API      : http://localhost/oengo-api/ (oengo-api:3001)
-----------------------------------------------------------------
"@ -ForegroundColor White
    }

    "deploy" {
        if (-not $Target -or $Target -eq "all") {
            Write-Host "Error: You must specify an exact service to deploy independently!" -ForegroundColor Red
            Write-Host "Example: .\oenexa-cli.ps1 deploy oenexa-ai-web" -ForegroundColor Yellow
            Write-Host "Services: oenexa-ai-web, oenexa-ai-core, oenexa-node, oenexa-explorer, oenexa-ui, oengo-api, oengo-web, caddy" -ForegroundColor Cyan
            return
        }
        $composeFile = if ($Env -eq "prod") { "docker-compose.prod.yml" } else { "docker-compose.yml" }
        Write-Host "Independent Zero-Downtime Deployment for [$Target] ($Env)..." -ForegroundColor Yellow
        Write-Host "Step 1: Rebuilding image for [$Target]..." -ForegroundColor Cyan
        docker compose -f $composeFile build $Target
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to build container for $Target. Deployment aborted." -ForegroundColor Red
            return
        }
        Write-Host "Step 2: Performing hot-swap with --no-deps (zero disruption to other services)..." -ForegroundColor Cyan
        docker compose -f $composeFile up -d --no-deps $Target
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ [$Target] successfully updated and redeployed!" -ForegroundColor Green
            docker compose -f $composeFile ps $Target
        } else {
            Write-Host "Deployment failed for $Target." -ForegroundColor Red
        }
    }

    "help" {
        Write-Host @"
Available Commands:
  .\oenexa-cli.ps1 up [profile]           Launch containers (profiles: ai, blockchain, portal, commerce, all)
  .\oenexa-cli.ps1 down                   Stop all containers
  .\oenexa-cli.ps1 ps                     View running container status and ports
  .\oenexa-cli.ps1 deploy <service> [env] Independently build and hot-swap a single service (--no-deps)
  .\oenexa-cli.ps1 routes                 Display single-domain path routing map
  .\oenexa-cli.ps1 status                 Show git status across all 30 polyrepo repositories
  .\oenexa-cli.ps1 sync                   Push all commits to origin (GitHub) and server (VPS)
  .\oenexa-cli.ps1 test [target]          Run test suites (core, web, all)
  .\oenexa-cli.ps1 logs [service]         Follow container logs in real time
"@ -ForegroundColor Yellow
    }
}
