<#
.SYNOPSIS
    Stops all locally running OENEXA ecosystem containers and processes cleanly.
#>

$ScriptDir = if (Test-Path "$PSScriptRoot\oenexa-ai-core") { $PSScriptRoot } else { Split-Path -Parent $PSScriptRoot }
$PidsFile = Join-Path $ScriptDir ".ecosystem-pids.json"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "       Stopping OENEXA Master Ecosystem (Containers & Ports)     " -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Stop Docker Compose containers if active
Push-Location $ScriptDir
try {
    docker compose down 2>$null
    Write-Host "  ✓ Docker Compose containers stopped" -ForegroundColor Green
} catch {}
finally {
    Pop-Location
}

# 2. Stop PID file processes if present
if (Test-Path $PidsFile) {
    $pids = Get-Content $PidsFile | ConvertFrom-Json
    foreach ($prop in $pids.PSObject.Properties) {
        $name = $prop.Name
        $pidNum = $prop.Value
        try {
            Stop-Process -Id $pidNum -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Stopped $name (PID $pidNum)" -ForegroundColor Green
        } catch {}
    }
    Remove-Item $PidsFile -Force -ErrorAction SilentlyContinue
}

# 3. Ensure ecosystem ports are freed
$ports = @(80, 443, 8080, 8545, 5173, 5174, 3000, 3001, 3002)
foreach ($port in $ports) {
    $lines = netstat -ano 2>$null | findstr ":$port"
    foreach ($line in $lines) {
        if ($line -match 'LISTENING\s+(\d+)') {
            $p = $matches[1]
            try {
                Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
                Write-Host "  ✓ Freed port $port (PID $p)" -ForegroundColor Gray
            } catch {}
        }
    }
}

Write-Host "✓ All OENEXA ecosystem services stopped cleanly." -ForegroundColor Green
