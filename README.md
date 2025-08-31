# 🔐 Copilot Chat Encryption Toolkit

A PowerShell toolkit for securely encrypting and decrypting sensitive markdown or clipboard content.

---

## 📦 Included Scripts

| Script Name              | Purpose                                                  |
|--------------------------|----------------------------------------------------------|
| `GenerateAESKey.ps1`     | Generates a 256-bit AES key and saves it to disk         |
| `EncryptMarkdown.ps1`    | Encrypts clipboard or markdown file input using AES-GCM or AES-CBC |
| `DecryptMarkdownFile.ps1`| Decrypts `.md.enc` files back to readable markdown       |

---

## 🚀 Quick Start

### 🔑 Generate AES Key

```powershell
.\GenerateAESKey.ps1 -k "C:\SecureLogs\CopilotChats\aes.key"
```

### 🔒 Encrypt Markdown

```powershell
.\EncryptMarkdown.ps1 -i "C:\Logs\chat.md" -o "C:\Logs\chat.enc" -k "C:\SecureLogs\CopilotChats\aes.key"
```

Or encrypt clipboard content:

```powershell
.\EncryptMarkdown.ps1 -o "C:\Logs\chat.enc"
```

### 🔓 Decrypt Markdown

```powershell
.\DecryptMarkdownFile.ps1 -i "C:\Logs\chat.enc" -o "C:\Logs\chat.md"
```

---

## 🧠 Features

- AES-256 encryption using GCM (PowerShell 7+) or CBC fallback
- Input from clipboard or markdown file
- Output to encrypted `.md.enc` file with timestamped naming
- Markdown formatting for chat logs (`User:` → 👤, `Assistant:` → 🧠)
- Short and long parameter aliases for ergonomic CLI usage
- Graceful error handling and version-aware encryption logic

---

## ⚙️ Parameters

### `GenerateAESKey.ps1`

| Parameter     | Alias | Description                          |
|---------------|-------|--------------------------------------|
| `-KeyPath`    | `-k`  | Path to save the generated AES key   |

### `EncryptMarkdown.ps1`

| Parameter         | Alias | Description                                      |
|------------------|-------|--------------------------------------------------|
| `-KeyPath`       | `-k`  | Path to AES key file                             |
| `-OutputFilePath`| `-o`  | Path to save encrypted output                    |
| `-InputFilePath` | `-i`  | Path to markdown file (optional, defaults to clipboard) |

### `DecryptMarkdownFile.ps1`

| Parameter         | Alias | Description                                      |
|------------------|-------|--------------------------------------------------|
| `-KeyPath`       | `-k`  | Path to AES key file                             |
| `-InputFilePath` | `-i`  | Path to encrypted `.md.enc` file                 |
| `-OutputFilePath`| `-o`  | Path to save decrypted markdown (optional)       |

---

## 🛡️ Security Model

- AES key is 256-bit and stored locally
- GCM mode preferred for integrity; CBC fallback for compatibility
- Input never logged in plaintext
- Output includes scheme byte for version-aware decryption
- Scripts avoid wildcards and enforce strict path validation

---

## 📁 Output Format

Encrypted files begin with a scheme byte:
- `0x01` → AES-GCM
- `0x02` → AES-CBC

Followed by:
- Nonce + Tag + Ciphertext (GCM)
- IV + Ciphertext (CBC)

Decrypted output is UTF-8 markdown with normalized line endings.

---

## 🧾 Requirements

- PowerShell 5.1+ (AES-CBC)
- PowerShell 7+ (AES-GCM support)
- Admin privileges recommended for secure environments

---

## 📬 Contributions & Feedback

Feel free to fork, adapt, or extend this toolkit. Suggestions for improving traceability, ACL integration, or multi-user workflows are welcome.

---

## 📜 License

GNU General Public License v3.0
