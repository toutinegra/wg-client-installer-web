# ==========================================================
# WireGuard - Client Installer (Windows)
# ==========================================================

# ---------------- VARIÁVEIS ----------------
$InterfaceName = "O3_Cloud"

$ClientIP = "172.25.10.2"
$DNS = "1.1.1.1, 8.8.8.8"

$PeerPublicKey = "eSb924lQ4GtWhI5e+GXFo+HpAPoJpYA5EPekd9jFRiA="
$AllowedIPs = "172.25.10.0/24, 192.168.2.0/24"
$Endpoint = "strixrp.o3utm.com.br:1920"
$KeepAlive = 15

# ---------------- ADMIN CHECK ----------------
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent() `
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "Execute como ADMINISTRADOR." -ForegroundColor Red
    exit 1
}

# ---------------- CAMINHOS ----------------
$WGBase = "C:\Program Files\WireGuard"
$WGExe  = Join-Path $WGBase "wireguard.exe"
$WGCmd  = Join-Path $WGBase "wg.exe"

$WorkDir   = "C:\ConfWireGuard"
$WGConfDir = Join-Path $WGBase "Data\Configurations"

$WorkConf  = Join-Path $WorkDir "$InterfaceName.conf"
$FinalConf = Join-Path $WGConfDir "$InterfaceName.conf"

# ---------------- UTF8 SEM BOM ----------------
function Write-FileNoBOM {
    param ($Path, $Content)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

# ---------------- PASTAS ----------------
foreach ($dir in @($WorkDir, $WGConfDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

# ---------------- INSTALA WIREGUARD ----------------
if (-not (Test-Path $WGExe)) {
    Write-Host "Instalando WireGuard..."
    $Installer = "$env:TEMP\wireguard-installer.exe"

    Invoke-WebRequest `
        -Uri "https://download.wireguard.com/windows-client/wireguard-installer.exe" `
        -OutFile $Installer

    Start-Process $Installer -ArgumentList "/install /quiet" -Wait
    Start-Sleep -Seconds 5
}

# ---------------- GERA CHAVES ----------------
$PrivateKey = & $WGCmd genkey
$PublicKey  = $PrivateKey | & $WGCmd pubkey

# ---------------- CONF ----------------
$Config = @"
[Interface]
PrivateKey = $PrivateKey
Address = $ClientIP
DNS = $DNS

[Peer]
PublicKey = $PeerPublicKey
AllowedIPs = $AllowedIPs
Endpoint = $Endpoint
PersistentKeepalive = $KeepAlive
"@

Write-FileNoBOM $WorkConf $Config
Copy-Item $WorkConf $FinalConf -Force

# ---------------- IMPORTA ----------------
& $WGExe /uninstalltunnelservice $InterfaceName 2>$null
& $WGExe /installtunnelservice $FinalConf

# ---------------- SAÍDA ----------------
Write-Host "WireGuard instalado com sucesso!"
Write-Host "Interface: $InterfaceName"
Write-Host "Client Public Key: $PublicKey"

Write-Output "CLIENT_PUBLIC_KEY=$PublicKey"