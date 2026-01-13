# ==========================================================
# WireGuard - Client Installer (Windows)
# Desenvolvido por Wilgner Kleyton Corrêa
# ==========================================================

# ---------------- VARIÁVEIS ----------------
$InterfaceName = "{{INTERFACE_NAME}}"
$ClientIP = "{{CLIENT_IP}}"
$DNS = "{{DNS}}"

$PeerPublicKey = "{{SERVER_PUBLIC_KEY}}"
$AllowedIPs = "{{ALLOWED_IPS}}"
$Endpoint = "{{ENDPOINT}}"
$KeepAlive = {{KEEPALIVE}}

# ---------------- CAMINHOS ----------------
$WGBase = "C:\Program Files\WireGuard"
$WGExe  = "$WGBase\wireguard.exe"
$WGCmd  = "$WGBase\wg.exe"

$WorkDir   = "C:\ConfWireGuard"
$WGConfDir = "$WGBase\Data\Configurations"

$WorkConf  = "$WorkDir\$InterfaceName.conf"
$FinalConf = "$WGConfDir\$InterfaceName.conf"

# ---------------- ADMIN ----------------
$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como Administrador." -ForegroundColor Red
    exit 1
}

# ---------------- FUNÇÃO ----------------
function Write-FileNoBOM {
    param ($Path, $Content)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

# ---------------- PASTAS ----------------
foreach ($dir in @($WorkDir, $WGConfDir)) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

# ---------------- INSTALA WG ----------------
if (!(Test-Path $WGExe)) {
    Write-Host "Instalando WireGuard..." -ForegroundColor Yellow
    $Installer = "$env:TEMP\wireguard-installer.exe"

    Invoke-WebRequest `
        -Uri "https://download.wireguard.com/windows-client/wireguard-installer.exe" `
        -OutFile $Installer

    Start-Process $Installer -ArgumentList "/install /quiet" -Wait
    Start-Sleep -Seconds 5
}

# ---------------- CHAVES ----------------
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

Write-Host "WireGuard instalado com sucesso!" -ForegroundColor Green
Write-Host "Public Key do cliente: $PublicKey"