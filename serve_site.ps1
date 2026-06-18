<#
.SYNOPSIS
    AMSI Raccoon Lab - Local Website Preview (Windows)

.DESCRIPTION
    Starts a local Jekyll development server to preview the
    GitHub Pages site before pushing.

.PARAMETER Install
    Install Ruby/Jekyll dependencies first.

.PARAMETER Port
    Custom port number (default: 4000).

.PARAMETER Docker
    Use Docker instead of local Ruby installation.

.EXAMPLE
    .\serve_site.ps1
    .\serve_site.ps1 -Install
    .\serve_site.ps1 -Port 8080
    .\serve_site.ps1 -Docker
#>

param(
    [switch]$Install,
    [int]$Port = 4000,
    [switch]$Docker,
    [switch]$Help
)

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  AMSI Raccoon Lab - Local Site Preview" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

if ($Help) {
    Write-Host "Usage: .\serve_site.ps1 [-Install] [-Port <number>] [-Docker]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Install    Install dependencies (Ruby gems via Bundler)"
    Write-Host "  -Port       Custom port (default: 4000)"
    Write-Host "  -Docker     Use Docker instead of local Ruby"
    Write-Host "  -Help       Show this help"
    Write-Host ""
    Write-Host "Prerequisites (pick one):"
    Write-Host "  Option A: Install Ruby from https://rubyinstaller.org/ (Ruby+Devkit)"
    Write-Host "  Option B: Use Docker Desktop"
    exit 0
}

# === Docker Mode ===
if ($Docker) {
    Write-Host "[*] Using Docker mode..." -ForegroundColor Cyan

    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "[ERROR] Docker is not installed or not in PATH." -ForegroundColor Red
        Write-Host ""
        Write-Host "Install Docker Desktop from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "[OK] Docker found" -ForegroundColor Green
    Write-Host ""
    Write-Host "--------------------------------------------"
    Write-Host "  Starting Jekyll via Docker..."
    Write-Host "  URL: http://localhost:${Port}/MostShittyAV/"
    Write-Host "  Press Ctrl+C to stop"
    Write-Host "--------------------------------------------"
    Write-Host ""

    docker run --rm `
        -v "${PWD}:/srv/jekyll" `
        -p "${Port}:4000" `
        -e "JEKYLL_ENV=development" `
        jekyll/jekyll:latest `
        jekyll serve --port 4000 --baseurl "/MostShittyAV" --livereload --force_polling

    exit $LASTEXITCODE
}

# === Local Ruby Mode ===

# Check Ruby
$ruby = Get-Command ruby -ErrorAction SilentlyContinue
if (-not $ruby) {
    Write-Host "[ERROR] Ruby is not installed." -ForegroundColor Red
    Write-Host ""
    Write-Host "Options to install:" -ForegroundColor Yellow
    Write-Host "  1. RubyInstaller (recommended): https://rubyinstaller.org/" -ForegroundColor Yellow
    Write-Host "     Download 'Ruby+Devkit' version, run installer with MSYS2" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  2. winget:" -ForegroundColor Yellow
    Write-Host "     winget install RubyInstallerTeam.RubyWithDevKit.3.2" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  3. Use Docker instead:" -ForegroundColor Yellow
    Write-Host "     .\serve_site.ps1 -Docker" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

$rubyVersion = ruby --version
Write-Host "[OK] $rubyVersion" -ForegroundColor Green

# Check Bundler
$bundler = Get-Command bundle -ErrorAction SilentlyContinue
if (-not $bundler) {
    Write-Host "[!] Bundler not found. Installing..." -ForegroundColor Yellow
    gem install bundler
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to install Bundler." -ForegroundColor Red
        exit 1
    }
}

$bundlerVersion = bundle --version
Write-Host "[OK] $bundlerVersion" -ForegroundColor Green

# Install dependencies
if ($Install -or -not (Test-Path "vendor\bundle")) {
    Write-Host ""
    Write-Host "[*] Installing dependencies..." -ForegroundColor Cyan
    bundle config set --local path 'vendor/bundle'
    bundle install

    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Bundle install failed." -ForegroundColor Red
        Write-Host ""
        Write-Host "Common fixes:" -ForegroundColor Yellow
        Write-Host "  - Run 'ridk install' if using RubyInstaller (choose option 3)" -ForegroundColor Yellow
        Write-Host "  - Ensure MSYS2 is installed for native gem compilation" -ForegroundColor Yellow
        Write-Host "  - Try: gem install jekyll bundler" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "[OK] Dependencies installed" -ForegroundColor Green
}

Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host "  Starting Jekyll development server..." -ForegroundColor Cyan
Write-Host "  URL: http://localhost:${Port}/MostShittyAV/" -ForegroundColor White
Write-Host "  Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host ""

# Open browser after short delay
Start-Job -ScriptBlock {
    Start-Sleep -Seconds 3
    Start-Process "http://localhost:$using:Port/MostShittyAV/"
} | Out-Null

# Serve the site
bundle exec jekyll serve `
    --port $Port `
    --livereload `
    --baseurl "/MostShittyAV" `
    --watch
