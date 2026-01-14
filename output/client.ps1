# ==========================================================
# WireGuard - Client Installer (Windows)
# ==========================================================

$InterfaceName = "O3_Cloud"
$ClientIP = "172.25.10.2"
$DNS = "1.1.1.1, 8.8.8.8"

$PeerPublicKey = "eSb924lQ4GtWhI5e+GXFo+HpAPoJpYA5EPekd9jFRiA="
$AllowedIPs = "172.25.10.0/24, 192.168.2.0/24"
$Endpoint = "strixrp.o3utm.com.br:1920"
$KeepAlive = 15

$WGBase = "C:\Program Files\WireGuard"
$WGExe  = "$WGBase\wireguard.exe"
$WGCmd  = "$WGBase\wg.exe"

$WorkDir = "C:\ConfWireGuard"
$WGConfDir = "$WGBase\Data\Configurations"

$WorkConf  = "$WorkDir\$InterfaceName.conf"
$FinalConf = "$WGConfDir\$InterfaceName.conf"

$PrivateKeyPath = "$WorkDir\$InterfaceName-private.key"
$PublicKeyPath  = "$WorkDir\$InterfaceName-public.key"

function Write-FileNoBOM {
    param ($Path, $Content)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

# VERIFICA ADMIN
$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute como administrador." -ForegroundColor Red
    exit 1
}

# CRIA PASTAS
foreach ($dir in @($WorkDir, $WGConfDir)) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

# INSTALA WIREGUARD SE NECESSÁRIO
if (!(Test-Path $WGExe)) {
    Write-Host "Instalando WireGuard..." -ForegroundColor Yellow
    $Installer = "$env:TEMP\wireguard-installer.exe"

    Invoke-WebRequest `
        -Uri "https://download.wireguard.com/windows-client/wireguard-installer.exe" `
        -OutFile $Installer

    Start-Process $Installer -ArgumentList "/install /quiet" -Wait
    Start-Sleep -Seconds 5
}

# GERA CHAVES
$PrivateKey = & $WGCmd genkey
$PublicKey = $PrivateKey | & $WGCmd pubkey

Write-FileNoBOM $PrivateKeyPath $PrivateKey
Write-FileNoBOM $PublicKeyPath $PublicKey

# GERA CONFIG
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

# REMOVE SE EXISTIR
& $WGExe /uninstalltunnelservice $InterfaceName 2>$null

# IMPORTA TÚNEL
& $WGExe /installtunnelservice $FinalConf

Write-Host "============================================"
Write-Host " WireGuard instalado com sucesso!"
Write-Host " Interface : $InterfaceName"
Write-Host " PubKey    : $PublicKey"
Write-Host "============================================"

Write-Output "CLIENT_PUBLIC_KEY=$PublicKey"