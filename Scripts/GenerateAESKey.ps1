param (
    [Alias("k")]
    [string]$KeyPath = "C:\SecureLogs\CopilotChats\aes.key"
)

# === Generate AES Key ===
[System.IO.Directory]::CreateDirectory((Split-Path $keyPath))
[System.IO.File]::WriteAllBytes($keyPath, [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
Write-Host "🔐  AES key saved to $keyPath"
