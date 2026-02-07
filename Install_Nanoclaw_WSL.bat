@echo off
:: [SYSTEM RULE: ENGLISH PRIMARY FOR CONSOLE]
CHCP 65001 > NUL
echo ==========================================
echo    Nanoclaw WSL2 Node.js 20+ Upgrade
echo ==========================================
echo.

echo [1/5] Upgrading Linux repository to NodeSource v20...
wsl -d Ubuntu -- bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"

echo.
echo [2/5] Installing Node.js v20 (Native Linux)...
wsl -d Ubuntu -- bash -c "sudo apt-get install -y nodejs"

echo.
echo [3/5] Verifying Node version...
wsl -d Ubuntu -- bash -c "node -v"

echo.
echo [4/5] Cleaning and Installing Nanoclaw Core...
wsl -d Ubuntu -- bash -c "cd ~/nanoclaw && rm -rf node_modules package-lock.json && npm install"

echo.
echo [5/5] Re-finishing environment config...
wsl -d Ubuntu -- bash -c "cd ~/nanoclaw/container/agent-runner && npm install"

echo.
echo ==========================================
echo    [SUCCESS] Linux Upgraded and Ready!
echo ==========================================
echo.
pause
