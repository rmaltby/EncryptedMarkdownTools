param (
    [Parameter(Mandatory = $true)]
    [Alias("i")]
    [string]$InputFilePath,

    [Alias("k")]
    [string]$KeyPath = "C:\SecureLogs\CopilotChats\aes.key",

    [Alias("o")]
    [string]$OutputFilePath
)

# === Detect PowerShell Version ===
$psMajor = $PSVersionTable.PSVersion.Major
$supportsGcm = $psMajor -ge 7

# === Validate Input File ===
if (-not (Test-Path $InputFilePath)) {
    Write-Error "❌ Encrypted file not found: $InputFilePath"
    exit 1
}

# === Validate Key File ===
if (-not (Test-Path $KeyPath)) {
    Write-Error "❌ AES key not found at: $KeyPath"
    exit 1
}
$key = [System.IO.File]::ReadAllBytes($KeyPath)
if ($key.Length -ne 32) {
    Write-Error "❌ Invalid AES key length. Expected 256-bit key."
    exit 1
}

# === Load Encrypted File ===
$encryptedBytes = [System.IO.File]::ReadAllBytes($InputFilePath)
$schemeByte = $encryptedBytes[0]
$dataBytes = $encryptedBytes[1..($encryptedBytes.Length - 1)]

switch ($schemeByte) {
    0x01 {
        if (-not $supportsGcm) {
            throw "❌ This file uses AES-GCM encryption, which requires PowerShell 7+. Current version: $psMajor"
        }

        # === AES-GCM Decryption ===
        $nonce = $dataBytes[0..11]
        $tag = $dataBytes[12..27]
        $ciphertext = $dataBytes[28..($dataBytes.Length - 1)]

        $plaintextBytes = [byte[]]::new($ciphertext.Length)
        $aesGcm = [System.Security.Cryptography.AesGcm]::new($key)
        $aesGcm.Decrypt($nonce, $ciphertext, $tag, $plaintextBytes)
    }

    0x02 {
        # === AES-CBC Decryption ===
        $iv = $dataBytes[0..15]
        $ciphertext = $dataBytes[16..($dataBytes.Length - 1)]

        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = $key
        $aes.IV = $iv
        $aes.Mode = 'CBC'
        $aes.Padding = 'PKCS7'

        $decryptor = $aes.CreateDecryptor()
        $plaintextBytes = $decryptor.TransformFinalBlock($ciphertext, 0, $ciphertext.Length)
    }

    default {
        throw "❌ Unknown encryption scheme byte: 0x{0:X2}. File may be corrupted or unsupported." -f $schemeByte
    }
}

# === Convert to Markdown ===
$markdown = [System.Text.Encoding]::UTF8.GetString($plaintextBytes)

# Optional: normalize back to `r\n` if needed
$markdown = $markdown -replace "`r?`n", "`r`n"

# === Output
if ($OutputFilePath) {
    try {
        [System.IO.File]::WriteAllText($OutputFilePath, $markdown)
        Write-Host "✅ Decrypted Markdown saved to: $OutputFilePath"
    } catch {
        Write-Error "❌ Failed to write output file: $_"
    }
} else {
    Write-Output $markdown
}