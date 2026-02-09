# NanoClaw 安裝指南（Windows）

## 需要的軟體

| 軟體 | 版本 | 下載連結 |
|------|------|----------|
| Node.js | 20 以上 | https://nodejs.org/ |
| Docker Desktop | 最新版 | https://www.docker.com/products/docker-desktop/ |
| Claude Code | 最新版 | https://claude.ai/download |
| WhatsApp | 可用的帳號，手機需在旁邊 | - |

### 注意事項

- Docker Desktop 必須在安裝前**啟動完成**，等系統匣的鯨魚圖示停止跳動再開始。
- 同一個 WhatsApp 號碼**只能有一個** Web 連線。如果你有其他機器人（例如 OpenClaw）佔用同一個號碼，需要先斷開或使用不同號碼。
- 認證資訊存在 `.env`（已加入 git-ignore），**絕對不要 commit 這個檔案**。

## 快速安裝

```powershell
powershell -ExecutionPolicy Bypass -File installnanoclaw.ps1
```

這會自動執行以下所有步驟。

## 手動安裝步驟

### 1. 安裝 npm 套件

```powershell
cd D:\nanoclaw
npm install
```

### 2. 編譯 TypeScript

```powershell
npm run build
```

### 3. 建置 Agent 容器映像

```powershell
docker build -t nanoclaw-agent:latest .\container\
```

這會建置一個包含 Node.js 22、Chromium（瀏覽器自動化）和 Claude Code 的 Linux 容器。首次建置需要幾分鐘。

### 4. 設定環境變數

在專案根目錄建立 `.env` 檔案：

```env
# 選擇一種認證方式：
CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-xxxxxxxx
# 或
ANTHROPIC_API_KEY=sk-ant-xxxxxxxx

# 選填：更改助理名稱（預設為 Andy）
ASSISTANT_NAME=Andy
```

**如何取得認證：**
- **OAuth token**：在 Claude Code 中執行 `claude setup-token`，會開啟瀏覽器登入。
- **API key**：前往 https://console.anthropic.com/ → API Keys → Create Key。

### 5. 建立目錄結構

需要以下目錄：

```
store/auth/          # WhatsApp 認證資料
groups/main/         # 主頻道記憶
groups/global/       # 所有群組共用的記憶
data/ipc/            # 程序間通訊
logs/                # 應用程式日誌
~/.config/nanoclaw/  # 掛載安全白名單（在專案外）
```

建立指令：

```powershell
mkdir store\auth, groups\main, groups\global, data\ipc, logs -Force
mkdir "$env:USERPROFILE\.config\nanoclaw" -Force
```

### 6. WhatsApp 認證

```powershell
npm run auth
```

終端機會顯示 QR Code。在手機上：

1. 開啟 **WhatsApp**
2. 進入 **設定 → 已連結的裝置 → 連結裝置**
3. 掃描終端機上的 QR Code

認證資料會儲存在 `store/auth/`。只需做一次，除非你解除裝置連結。

### 7. 註冊主頻道

建立 `data/registered_groups.json`。將 `YOUR_PHONE_NUMBER` 替換為你的號碼（國碼 + 號碼，不含 + 號或空格）：

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

- `@s.whatsapp.net` = 個人聊天（自己跟自己聊天作為管理頻道）
- `@g.us` = 群組聊天
- `requiresTrigger: false` = 回應所有訊息（建議主頻道使用）

**提示**：如果你不知道聊天的 JID，先用 `npm run dev` 短暫啟動 NanoClaw，發送一則訊息，然後從日誌中找到 JID。

### 8. 啟動 NanoClaw

```powershell
npm run dev       # 開發模式（自動重載，建議首次使用）
npm start         # 正式模式（使用編譯後的 dist/）
```

在已註冊的 WhatsApp 聊天中發送訊息。如果 `requiresTrigger` 為 true，訊息開頭需要加上 `@Andy`（或你設定的觸發詞）。

## 驗證安裝

| 檢查項目 | 指令 |
|----------|------|
| Node.js 已安裝 | `node --version`（應為 20+） |
| Docker 執行中 | `docker info` |
| 容器映像已建置 | `docker images nanoclaw-agent` |
| WhatsApp 已認證 | `store/auth/creds.json` 檔案存在 |
| 群組已註冊 | `data/registered_groups.json` 檔案存在 |

## 常見問題

### QR Code 過期
重新執行 `npm run auth`。QR Code 大約每 20 秒刷新一次，請儘快掃描。

### 「Docker is not running」
啟動 Docker Desktop，等待它完全初始化完成後再執行安裝腳本。

### WhatsApp 斷線
另一個裝置或機器人正在使用同一個號碼。每個號碼只允許一個 Web 連線。請到 WhatsApp 設定中解除其他裝置的連結。

### 容器建置失敗
確認 Docker Desktop 有足夠的磁碟空間和記憶體（至少分配 4GB RAM）。映像大約 1GB。

### Agent 沒有回應
1. 檢查終端機的錯誤日誌。
2. 確認 `.env` 中有正確的 Claude token 或 API key。
3. 確認 `data/registered_groups.json` 中的聊天 JID 正確。
4. 如果 `requiresTrigger` 為 true，確認訊息開頭有觸發詞。

## 檔案說明

| 檔案 | 用途 |
|------|------|
| `.env` | 認證資訊與設定（不會被 git 追蹤） |
| `store/auth/` | WhatsApp 連線認證資料 |
| `store/messages.db` | SQLite 訊息資料庫（自動建立） |
| `data/registered_groups.json` | 機器人監控的聊天清單 |
| `groups/main/CLAUDE.md` | 主頻道的 Agent 記憶 |
| `groups/global/CLAUDE.md` | 所有群組共用的記憶 |
| `~/.config/nanoclaw/mount-allowlist.json` | 安全設定：允許掛載的外部目錄 |
