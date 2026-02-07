@echo off
:: [SYSTEM RULE: ENGLISH PRIMARY FOR CONSOLE]
CHCP 65001 > NUL
echo ==========================================
echo    Nanoclaw WSL2 Repair ^& Installation
echo ==========================================
echo.

echo [1/4] Checking/Installing Linux-native Node.js...
wsl -d Ubuntu -- bash -c "sudo apt update && sudo apt install -y nodejs npm"

echo.
echo [2/4] Cleaning up previous failed Windows-lock files...
wsl -d Ubuntu -- bash -c "cd ~/nanoclaw && rm -rf node_modules package-lock.json"

echo.
echo [3/4] Installing Nanoclaw Core (via Linux npm)...
wsl -d Ubuntu -- bash -c "cd ~/nanoclaw && npm install"

echo.
echo [4/4] Installing Agent-Runner drivers...
wsl -d Ubuntu -- bash -c "cd ~/nanoclaw/container/agent-runner && npm install"

echo.
echo [5/5] Re-generating environment configuration (.env)...
wsl -d Ubuntu -- bash -c "echo 'ASSISTANT_NAME=Tiger-Nanoclaw' > ~/nanoclaw/.env"
wsl -d Ubuntu -- bash -c "echo 'OPENAI_BASE_URL=http://host.docker.internal:11434/v1' >> ~/nanoclaw/.env"
wsl -d Ubuntu -- bash -c "echo 'OPENAI_API_KEY=ollama-local' >> ~/nanoclaw/.env"
wsl -d Ubuntu -- bash -c "echo 'NANOCLAW_PROVIDER=ollama' >> ~/nanoclaw/.env"
wsl -d Ubuntu -- bash -c "echo 'NANOCLAW_MODEL=qwen2.5-coder:7b' >> ~/nanoclaw/.env"

echo.
echo ==========================================
echo    [SUCCESS] Linux environment repaired!
echo ==========================================
echo.
pause
