# NanoClaw Installation Guide (Windows)

## Prerequisites

| Software | Version | Download |
|----------|---------|----------|
| Node.js | 20+ | https://nodejs.org/ |
| Docker Desktop | Latest | https://www.docker.com/products/docker-desktop/ |
| Claude Code | Latest | https://claude.ai/download |
| WhatsApp | Active account with phone nearby | - |

### Important Notes

- Docker Desktop must be **running** before installation. Wait for the whale icon in system tray to stop animating.
- Your WhatsApp number can only have **one** web connection at a time. If you have another bot (e.g. OpenClaw) using the same number, disconnect it first or use a different number.
- The script stores credentials in `.env` (git-ignored). Never commit this file.

## Quick Install

```powershell
powershell -ExecutionPolicy Bypass -File installnanoclaw.ps1
```

This runs all steps below automatically.

## Manual Steps

### 1. Install npm dependencies

```powershell
cd D:\nanoclaw
npm install
```

### 2. Build TypeScript

```powershell
npm run build
```

### 3. Build the agent container image

```powershell
docker build -t nanoclaw-agent:latest .\container\
```

This builds a Linux container with Node.js 22, Chromium (for browser automation), and Claude Code. Takes a few minutes on first build.

### 4. Configure environment variables

Create `.env` in the project root:

```env
# Choose ONE authentication method:
CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-xxxxxxxx
# OR
ANTHROPIC_API_KEY=sk-ant-xxxxxxxx

# Optional: change assistant name (default: Andy)
ASSISTANT_NAME=Andy
```

**How to get credentials:**
- **OAuth token**: Run `claude setup-token` in Claude Code, it opens a browser for login.
- **API key**: Go to https://console.anthropic.com/ → API Keys → Create Key.

### 5. Create directory structure

The following directories are needed:

```
store/auth/          # WhatsApp auth credentials
groups/main/         # Main channel memory
groups/global/       # Shared memory across all groups
data/ipc/            # Inter-process communication
logs/                # Application logs
~/.config/nanoclaw/  # Mount security allowlist (outside project)
```

Create them:

```powershell
mkdir store\auth, groups\main, groups\global, data\ipc, logs -Force
mkdir "$env:USERPROFILE\.config\nanoclaw" -Force
```

### 6. Authenticate WhatsApp

```powershell
npm run auth
```

A QR code appears in the terminal. On your phone:

1. Open **WhatsApp**
2. Go to **Settings → Linked Devices → Link a Device**
3. Scan the QR code

Auth credentials are saved to `store/auth/`. You only need to do this once unless you unlink the device.

### 7. Register your main channel

Create `data/registered_groups.json`. Replace `YOUR_PHONE_NUMBER` with your number (country code, no + or spaces):

```json
{
  "YOUR_PHONE_NUMBER@s.whatsapp.net": {
    "name": "main",
    "folder": "main",
    "trigger": "@Andy",
    "requiresTrigger": false,
    "added_at": "2025-01-01T00:00:00.000Z"
  }
}
```

- `@s.whatsapp.net` = personal chat (self-chat as admin channel)
- `@g.us` = group chat
- `requiresTrigger: false` = responds to all messages (recommended for main channel)

**Tip**: If you don't know your chat JID, start NanoClaw briefly with `npm run dev`, send a message, and check the logs for the JID.

### 8. Start NanoClaw

```powershell
npm run dev       # Development mode (hot reload, recommended for first run)
npm start         # Production mode (uses compiled dist/)
```

Send a message in your registered WhatsApp chat. If `requiresTrigger` is true, start the message with `@Andy` (or your chosen trigger).

## Verifying Installation

| Check | Command |
|-------|---------|
| Node.js installed | `node --version` (should be 20+) |
| Docker running | `docker info` |
| Container image built | `docker images nanoclaw-agent` |
| WhatsApp authenticated | `store/auth/creds.json` exists |
| Groups registered | `data/registered_groups.json` exists |

## Troubleshooting

### QR code expired
Re-run `npm run auth`. The QR refreshes every ~20 seconds; scan quickly.

### "Docker is not running"
Start Docker Desktop and wait for it to fully initialize before running the script.

### WhatsApp disconnects
Another device or bot is using the same number. Only one web session is allowed per number. Unlink the other device from WhatsApp settings.

### Container build fails
Check Docker Desktop has enough disk space and memory (at least 4GB RAM allocated). The image is ~1GB.

### Agent doesn't respond
1. Check the terminal for error logs.
2. Verify `.env` has a valid Claude token or API key.
3. Confirm `data/registered_groups.json` has the correct chat JID.
4. Make sure the trigger word matches if `requiresTrigger` is true.

## File Reference

| File | Purpose |
|------|---------|
| `.env` | Credentials and config (git-ignored) |
| `store/auth/` | WhatsApp session credentials |
| `store/messages.db` | SQLite message database (auto-created) |
| `data/registered_groups.json` | Which chats the bot monitors |
| `groups/main/CLAUDE.md` | Main channel agent memory |
| `groups/global/CLAUDE.md` | Shared memory for all groups |
| `~/.config/nanoclaw/mount-allowlist.json` | Security: allowed external directory mounts |
