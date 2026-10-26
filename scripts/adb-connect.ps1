<#
.SYNOPSIS
  Connect to the Tanix box over the network with ADB.
.EXAMPLE
  .\scripts\adb-connect.ps1 -Ip 192.168.1.50
#>
param(
    [Parameter(Mandatory)] [string] $Ip,
    [int] $Port = 5555
)

$target = "${Ip}:$Port"

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Write-Error "adb not found. Install Android platform-tools and add it to PATH."
    exit 1
}

# Quick TCP probe (Test-NetConnection is slow and leaves its progress bar on screen).
$tcp = [System.Net.Sockets.TcpClient]::new()
$open = $tcp.ConnectAsync($Ip, $Port).Wait(3000) -and $tcp.Connected
$tcp.Dispose()
if (-not $open) {
    Write-Error "$target is not reachable. Check the IP and that network/USB debugging is enabled (docs/01-enable-adb.md)."
    exit 1
}

adb connect $target | Out-Host
$state = (adb -s $target get-state 2>&1) -join ''

switch -Wildcard ($state) {
    'device' {
        Write-Host "Connected to $target" -ForegroundColor Green
        adb -s $target shell getprop ro.product.model
        adb -s $target shell getprop ro.board.platform
        adb -s $target shell getprop ro.build.version.release
    }
    '*unauthorized*' {
        Write-Warning "Accept 'Allow USB debugging?' on the TV (tick 'Always allow'), then run again."
        exit 2
    }
    default {
        Write-Error "Unexpected state: $state"
        exit 1
    }
}
