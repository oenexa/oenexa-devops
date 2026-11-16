<#
.SYNOPSIS
    Starts the OENEXA Ecosystem locally using the Master Orchestrator.
.DESCRIPTION
    Launches services via Docker Compose profiles:
      - ai         : Launches AI Core (Java 25) + AI Web (React 18) + Postgres + Redis
      - blockchain : Launches oenexa-node (Go L1) + oenexa-explorer (React 18)
      - portal     : Launches oenexa-ui (Trading Portal & Exchange)
      - commerce   : Launches oengo-api + oengo-web (Next.js Storefront)
      - all        : Launches the entire OENEXA enterprise stack under Caddy reverse proxy
#>
param(
    [ValidateSet("all", "ai", "blockchain", "portal", "commerce")]
    [string]$Profile = "all"
)

$ScriptDir = if (Test-Path "$PSScriptRoot\oenexa-ai-core") { $PSScriptRoot } else { Split-Path -Parent $PSScriptRoot }

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "       OENEXA Master Ecosystem Local Launcher (Profile: $Profile) " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan

Push-Location $ScriptDir
try {
    Write-Host "Launching containers via Docker Compose with profile: [$Profile]..." -ForegroundColor Yellow
    docker compose --profile $Profile up -d --build

    Write-Host "`n✓ Services launched successfully!" -ForegroundColor Green
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "🌐 Unified Single-Domain Endpoints (routed via Caddy on :80):" -ForegroundColor White
    Write-Host "  🏠 Main Portal & Markets UI : http://localhost/" -ForegroundColor White
    Write-Host "  ⚡ AI Operating System      : http://localhost/ai/" -ForegroundColor White
    Write-Host "  🧠 AI Core Backend REST API : http://localhost/api/v4/" -ForegroundColor White
    Write-Host "  🔍 Blockchain Explorer      : http://localhost/explorer/" -ForegroundColor White
    Write-Host "  ⛓️ L1 Blockchain RPC Node   : http://localhost/rpc" -ForegroundColor White
    Write-Host "  🍔 D-Commerce Food Portal   : http://localhost/food/" -ForegroundColor White
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "To view container status : .\oenexa-cli.ps1 ps" -ForegroundColor Yellow
    Write-Host "To view live logs        : .\oenexa-cli.ps1 logs" -ForegroundColor Yellow
    Write-Host "To stop services cleanly : .\stop-ecosystem-local.ps1" -ForegroundColor Yellow
    Write-Host "=================================================================" -ForegroundColor Cyan
} finally {
    Pop-Location
}
