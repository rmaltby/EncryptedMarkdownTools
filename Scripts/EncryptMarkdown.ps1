param (
    [Alias("k")]
    [string]$KeyPath = "C:\SecureLogs\CopilotChats\aes.key",

    [Alias("o")]
    [string]$OutputFilePath,

    [Alias("i")]
    [string]$InputFilePath
)

# === Detect PowerShell Version ===
$useGcm = $PSVersionTable.PSVersion.Major -ge 7

# === Load AES Key ===
if (-not (Test-Path $KeyPath)) {
    Write-Error "❌ AES key not found at: $KeyPath"
    exit 1
}
$key = [System.IO.File]::ReadAllBytes($KeyPath)
if ($key.Length -ne 32) {
    Write-Error "❌ Invalid AES key length. Expected 256-bit key."
    exit 1
}

# === Get and Format Text ===
if ($InputFilePath) {
    if (-not (Test-Path $InputFilePath)) {
        Write-Error "❌ Input file not found: $InputFilePath"
        exit 1
    }
    $inputText = Get-Content $InputFilePath -Raw
} else {
    $inputText = Get-Clipboard -Raw
}

# Normalize line endings to Windows-style (optional but consistent)
$inputText = $inputText -replace "`r?`n", "`r`n"

$markdown = $inputText -replace '^User:', '### 👤 **User**' `
                        -replace '^Assistant:', '### 🧠 **Copilot**'
$plaintextBytes = [System.Text.Encoding]::UTF8.GetBytes($markdown)

# === Encrypt ===
if ($useGcm) {
    # --- AES-GCM (PowerShell 7+)
    $nonce = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(12)
    $tag = [byte[]]::new(16)
    $ciphertext = [byte[]]::new($plaintextBytes.Length)

    $aesGcm = [System.Security.Cryptography.AesGcm]::new($key)
    $aesGcm.Encrypt($nonce, $plaintextBytes, $ciphertext, $tag)

    $finalBytes = @(0x01) + $nonce + $tag + $ciphertext
} else {
    # --- AES-CBC (Fallback for PowerShell <7)
    $iv = [byte[]]::new(16)
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($iv)

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $key
    $aes.IV = $iv
    $aes.Mode = 'CBC'
    $aes.Padding = 'PKCS7'

    $encryptor = $aes.CreateEncryptor()
    $ciphertext = $encryptor.TransformFinalBlock($plaintextBytes, 0, $plaintextBytes.Length)

    $finalBytes = @(0x02) + $iv + $ciphertext
}

# === Determine Output Path ===
if (-not $OutputFilePath) {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $defaultDir = Split-Path $KeyPath
    $OutputFilePath = Join-Path $defaultDir "Copilot_Chat_$timestamp.md.enc"
}

# === Save Encrypted File ===
try {
    [System.IO.File]::WriteAllBytes($OutputFilePath, $finalBytes)
    Write-Host "🔐 Encrypted file saved to: $OutputFilePath"
    if (-not $useGcm) {
        Write-Warning "⚠️ AES-CBC fallback used due to PowerShell version < 7"
    }
} catch {
    Write-Error "❌ Failed to write encrypted file: $_"
}
