# Oenexa Ecosystem Polyrepo Manager & Synchronizer
param(
    [ValidateSet("status", "pull", "push", "fetch", "clean", "test", "build")]
    [string]$Action = "status"
)

$ErrorActionPreference = "Continue"
$Root = if (Test-Path "$PSScriptRoot\oenexa-ai-core") { $PSScriptRoot } else { Split-Path -Parent $PSScriptRoot }

$Repos = Get-ChildItem -Path $Root -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName ".git")
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  OENEXA REPO MANAGER - Action: $Action" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$Results = @()

foreach ($repo in $Repos) {
    $repoPath = $repo.FullName
    $repoName = $repo.Name
    $branch = (git -C $repoPath branch --show-current 2>$null)
    $remote = (git -C $repoPath remote get-url origin 2>$null)

    switch ($Action) {
        "status" {
            $statusShort = (git -C $repoPath status --short 2>$null)
            $dirty = if ($statusShort) { "MODIFIED" } else { "CLEAN" }
            $ahead = (git -C $repoPath rev-list --count "origin/$branch..$branch" 2>$null)
            if (-not $ahead) { $ahead = "0" }

            $behind = (git -C $repoPath rev-list --count "$branch..origin/$branch" 2>$null)
            if (-not $behind) { $behind = "0" }

            $Results += [PSCustomObject]@{
                Repository = $repoName
                Branch     = $branch
                Status     = $dirty
                Ahead      = $ahead
                Behind     = $behind
                Remote     = $remote
            }
        }
        "fetch" {
            Write-Host "Fetching $repoName..." -ForegroundColor Yellow
            git -C $repoPath fetch origin
        }
        "pull" {
            Write-Host "Pulling $repoName ($branch)..." -ForegroundColor Yellow
            git -C $repoPath pull origin $branch
        }
        "push" {
            Write-Host "Pushing $repoName ($branch) -> origin..." -ForegroundColor Yellow
            git -C $repoPath push -u origin $branch
            $hasServer = (git -C $repoPath remote get-url server 2>$null)
            if ($hasServer) {
                Write-Host "Pushing $repoName ($branch) -> server..." -ForegroundColor Yellow
                git -C $repoPath push server $branch
            }
        }
        "clean" {
            Write-Host "Cleaning build artifacts in $repoName..." -ForegroundColor Yellow
            # Clean build outputs safely
            if (Test-Path "$repoPath\dist") { Remove-Item -Path "$repoPath\dist" -Recurse -Force -ErrorAction SilentlyContinue }
            if (Test-Path "$repoPath\.next") { Remove-Item -Path "$repoPath\.next" -Recurse -Force -ErrorAction SilentlyContinue }
            if (Test-Path "$repoPath\coverage") { Remove-Item -Path "$repoPath\coverage" -Recurse -Force -ErrorAction SilentlyContinue }
            if (Test-Path "$repoPath\build") { Remove-Item -Path "$repoPath\build" -Recurse -Force -ErrorAction SilentlyContinue }
            if (Test-Path "$repoPath\gradlew.bat") {
                & "$repoPath\gradlew.bat" --project-dir "$repoPath" clean 2>$null
            }
            Write-Host "Cleaned $repoName." -ForegroundColor Green
        }
        "test" {
            Write-Host "`n>>> Running tests for $repoName ($branch) <<<" -ForegroundColor Cyan
            if (Test-Path "$repoPath\gradlew.bat") {
                & "$repoPath\gradlew.bat" --project-dir "$repoPath" test
            } elseif (Test-Path "$repoPath\go.mod") {
                go test -C "$repoPath" ./... -short
            } elseif (Test-Path "$repoPath\package.json") {
                npm --prefix "$repoPath" test -- --run 2>$null
            }
        }
        "build" {
            Write-Host "`n>>> Building $repoName ($branch) <<<" -ForegroundColor Cyan
            if (Test-Path "$repoPath\gradlew.bat") {
                & "$repoPath\gradlew.bat" --project-dir "$repoPath" build -x test
            } elseif (Test-Path "$repoPath\go.mod") {
                go build -C "$repoPath" ./...
            } elseif (Test-Path "$repoPath\package.json") {
                npm --prefix "$repoPath" run build
            }
        }
    }
}

if ($Action -eq "status") {
    $Results | Format-Table -AutoSize
}

Write-Host "`nDone." -ForegroundColor Green
