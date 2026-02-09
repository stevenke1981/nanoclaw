# NanoClaw Installation Script for Windows
# Run: powershell -ExecutionPolicy Bypass -File installnanoclaw.ps1

$ErrorActionPreference = "Stop"
$NanoClawDir = "D:\nanoclaw"

Write-Host "=== NanoClaw Installation ===" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------
# Step 1: Check prerequisites
# ------------------------------------------------------------------
Write-Host "[1/8] Checking prerequisites..." -ForegroundColor Yellow

# Node.js
$env:PATH = "C:\Program Files\nodejs;" + $env:PATH
try {
    $nodeVersion = & node --version 2>&1
    Write-Host "  Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Node.js not found. Install from https://nodejs.org/ (v20+)" -ForegroundColor Red
    exit 1
}

# Docker
try {
    & docker info *>$null
    Write-Host "  Docker: running" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Docker is not running. Start Docker Desktop first." -ForegroundColor Red
    Write-Host "  Download from https://www.docker.com/products/docker-desktop/" -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------------
# Step 2: Install npm dependencies
# ------------------------------------------------------------------
Write-Host ""
Write-Host "[2/8] Installing npm dependencies..." -ForegroundColor Yellow
Set-Location $NanoClawDir
& npm install 2>&1
if ($LASTEXITCODE -ne 0) { Write-Host "ERROR: npm install failed" -ForegroundColor Red; exit 1 }
Write-Host "  Dependencies installed" -ForegroundColor Green

# ------------------------------------------------------------------
# Step 3: Build TypeScript
# ------------------------------------------------------------------
Write-Host ""
Write-Host "[3/8] Building TypeScript..." -ForegroundColor Yellow
& npm run build 2>&1
if ($LASTEXITCODE -ne 0) { Write-Host "ERROR: TypeScript build failed" -ForegroundColor Red; exit 1 }
Write-Host "  Build complete" -ForegroundColor Green

# ------------------------------------------------------------------
# Step 4: Build agent container image
# ------------------------------------------------------------------
Write-Host ""
Write-Host "[4/8] Building agent container image..." -ForegroundColor Yellow
& docker build -t nanoclaw-agent:latest "$NanoClawDir\container" 2>&1
if ($LASTEXITCODE -ne 0) { Write-Host "ERROR: Container build failed" -ForegroundColor Red; exit 1 }
Write-Host "  Container image built: nanoclaw-agent:latest" -ForegroundColor Green

# ------------------------------------------------------------------
# Step 5: Set up environment variables
# ------------------------------------------------------------------
Write-Host ""
Write-Host "[5/8] Configuring environment..." -ForegroundColor Yellow

$envFile = Join-Path $NanoClawDir ".env"
if (Test-Path $envFile) {
    Write-Host "  .env already exists, skipping" -ForegroundColor Green
} else {
    Write-Host "  Choose Claude authentication method:"
    Write-Host "    1) Claude Code OAuth token (CLAUDE_CODE_OAUTH_TOKEN)"
    Write-Host "    2) Anthropic API key (ANTHROPIC_API_KEY)"
    $authChoice = Read-Host "  Enter 1 or 2"

    if ($authChoice -eq "1") {
        $token = Read-Host "  Enter your CLAUDE_CODE_OAUTH_TOKEN"
        "CLAUDE_CODE_OAUTH_TOKEN=$token" | Out-File -FilePath $envFile -Encoding utf8NoBOM
    } else {
        $apiKey = Read-Host "  Enter your ANTHROPIC_API_KEY"
        "ANTHROPIC_API_KEY=$apiKey" | Out-File -FilePath $envFile -Encoding utf8NoBOM
    }

    $assistantName = Read-Host "  Enter assistant name (default: Andy)"
    if ($assistantName) {
        Add-Content -Path $envFile -Value "ASSISTANT_NAME=$assistantName"
    }

    Write-Host "  .env created" -ForegroundColor Green
}

# ------------------------------------------------------------------
# Step 6: Create directory structure
# ------------------------------------------------------------------
Write-Host ""
Write-Host "[6/8] Creating directory structure..." -ForegroundColor Yellow

$dirs = @(
    "$NanoClawDir\store\auth",
    "$NanoClawDir\groups\main",
    "$NanoClawDir\groups\global",
    "$NanoClawDir\data\ipc",
    "$NanoClawDir\logs",
    "$env:USERPROFILE\.config\nanoclaw"
)
foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

# Create global CLAUDE.md if missing
$globalClaude = "$NanoClawDir\groups\global\CLAUDE.md"
if (-not (Test-Path $globalClaude)) {
    "# Global Memory`n`nShared context visible to all groups." | Out-File -FilePath $globalClaude -Encoding utf8NoBOM
}

# Create mount allowlist if missing
$allowlistPath = "$env:USERPROFILE\.config\nanoclaw\mount-allowlist.json"
if (-not (Test-Path $allowlistPath)) {
    '{"allowedRoots":[],"blockedPatterns":[".ssh",".gnupg",".aws","credentials",".env","private_key"],"nonMainReadOnly":true}' | Out-File -FilePath $allowlistPath -Encoding utf8NoBOM
}

Write-Host "  Directories and config created" -ForegroundColor Green

# ------------------------------------------------------------------
# Step 7: WhatsApp authentication
# ------------------------------------------------------------------
Write-Host ""
Write-Host "[7/8] WhatsApp authentication..." -ForegroundColor Yellow

$credsFile = "$NanoClawDir\store\auth\creds.json"
if (Test-Path $credsFile) {
    Write-Host "  WhatsApp already authenticated, skipping" -ForegroundColor Green
} else {
    Write-Host "  A QR code will appear. Scan it with WhatsApp:"
    Write-Host "    Phone -> Settings -> Linked Devices -> Link a Device"
    Write-Host ""
    & npm run auth 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  WARNING: WhatsApp auth may have failed. Re-run: npm run auth" -ForegroundColor Yellow
    } else {
        Write-Host "  WhatsApp authenticated" -ForegroundColor Green
    }
}

# ------------------------------------------------------------------
# Step 8: Register main channel
# ------------------------------------------------------------------
Write-Host ""
Write-Host "[8/8] Main channel registration..." -ForegroundColor Yellow

$registeredGroups = "$NanoClawDir\data\registered_groups.json"
if (Test-Path $registeredGroups) {
    Write-Host "  registered_groups.json already exists, skipping" -ForegroundColor Green
} else {
    Write-Host "  You need to register your main WhatsApp channel."
    Write-Host "  Start NanoClaw briefly to discover your chats, then use /setup in Claude Code."
    Write-Host "  Or manually create data/registered_groups.json with your chat JID."
    Write-Host ""
    Write-Host "  Example format:" -ForegroundColor Gray
    Write-Host '  {' -ForegroundColor Gray
    Write-Host '    "YOUR_NUMBER@s.whatsapp.net": {' -ForegroundColor Gray
    Write-Host '      "name": "main",' -ForegroundColor Gray
    Write-Host '      "folder": "main",' -ForegroundColor Gray
    Write-Host '      "trigger": "@Andy",' -ForegroundColor Gray
    Write-Host '      "requiresTrigger": false,' -ForegroundColor Gray
    Write-Host '      "added_at": "2025-01-01T00:00:00.000Z"' -ForegroundColor Gray
    Write-Host '    }' -ForegroundColor Gray
    Write-Host '  }' -ForegroundColor Gray
}

# ------------------------------------------------------------------
# Done
# ------------------------------------------------------------------
Write-Host ""
Write-Host "=== Installation Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "To start NanoClaw:" -ForegroundColor White
Write-Host "  npm run dev      # development (hot reload)" -ForegroundColor Gray
Write-Host "  npm start        # production" -ForegroundColor Gray
Write-Host ""
Write-Host "To register your main channel interactively:" -ForegroundColor White
Write-Host "  claude  then  /setup" -ForegroundColor Gray
