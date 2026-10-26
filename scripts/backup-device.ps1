<#
.SYNOPSIS
  Collect hardware/firmware info from the box and, if root is available,
  dump every eMMC partition.
.DESCRIPTION
  Text info goes to device-info/<label>/ (committed to git).
  Partition images go to backup/<label>/ (git-ignored).
.EXAMPLE
  .\scripts\backup-device.ps1 -Ip 192.168.1.50
  .\scripts\backup-device.ps1 -Ip 192.168.1.50 -Label gtv -SkipPartitions
#>
param(
    [Parameter(Mandatory)] [string] $Ip,
    [int] $Port = 5555,
    [string] $Label = 'stock',
    [switch] $SkipPartitions
)

$ErrorActionPreference = 'Stop'
$target = "${Ip}:$Port"
$root = Split-Path $PSScriptRoot -Parent
$infoDir = Join-Path $root "device-info\$Label"
$backupDir = Join-Path $root "backup\$Label"

adb connect $target | Out-Null
if ((adb -s $target get-state 2>&1) -ne 'device') {
    Write-Error "Not connected to $target. Run scripts\adb-connect.ps1 first."
    exit 1
}

New-Item -ItemType Directory -Force $infoDir | Out-Null

function Save-Shell([string] $file, [string] $cmd) {
    Write-Host "  $file"
    adb -s $target shell $cmd 2>&1 | Out-File -Encoding utf8 (Join-Path $infoDir $file)
}

Write-Host "Collecting device info -> $infoDir"
Save-Shell 'getprop.txt'    'getprop'
Save-Shell 'cpuinfo.txt'    'cat /proc/cpuinfo'
Save-Shell 'meminfo.txt'    'cat /proc/meminfo'
Save-Shell 'partitions.txt' 'cat /proc/partitions; echo; ls -l /dev/block/by-name/ 2>/dev/null || ls -l /dev/block/platform/*/by-name/'
Save-Shell 'wifi.txt'       'cat /sys/bus/sdio/devices/*/vendor /sys/bus/sdio/devices/*/device 2>/dev/null; ls /vendor/etc/firmware /vendor/modules 2>/dev/null'
Save-Shell 'lsmod.txt'      'lsmod 2>/dev/null || cat /proc/modules'
Save-Shell 'kernel.txt'     'uname -a; cat /proc/cmdline'
Save-Shell 'display.txt'    'dumpsys display | head -n 60'
Save-Shell 'packages.txt'   'pm list packages -f'

if ($SkipPartitions) { exit 0 }

# Root: try adbd as root first (common on Allwinner userdebug builds), then su.
adb -s $target root 2>&1 | Out-Null
Start-Sleep -Seconds 3
adb connect $target | Out-Null
$su = ''
if ((adb -s $target shell id) -notmatch 'uid=0') {
    if ((adb -s $target shell 'su -c id' 2>&1) -match 'uid=0') {
        $su = 'su -c '
    } else {
        Write-Warning "No root access - skipping partition dump. Device info was saved."
        Write-Warning "Get a stock firmware image from Tanix/the ROM thread before flashing."
        exit 0
    }
}

# Wrap a device command for su only when adbd itself is not root.
function As-Root([string] $cmd) { if ($su) { "su -c '$cmd'" } else { $cmd } }

function Dump([string] $name, [string] $ddArgs) {
    $out = Join-Path $backupDir "$name.img"
    Write-Host "  dumping $name"
    # cmd.exe redirection keeps the raw bytes; PowerShell's '>' may re-encode them.
    cmd /c "adb -s $target exec-out ""$(As-Root "dd $ddArgs 2>/dev/null")"" > ""$out"""
}

New-Item -ItemType Directory -Force $backupDir | Out-Null
$byName = (adb -s $target shell (As-Root 'ls -d /dev/block/by-name /dev/block/platform/*/by-name 2>/dev/null') | Select-Object -First 1).Trim()
$parts = adb -s $target shell (As-Root "ls $byName") | ForEach-Object { $_.Trim() } | Where-Object { $_ }

# Raw start of the eMMC: partition table plus Allwinner boot0 / u-boot (toc0/toc1),
# which are not exposed as by-name partitions.
Dump 'mmcblk0-head-40M' 'if=/dev/block/mmcblk0 bs=1M count=40'

# userdata/UDISK is huge and holds no firmware; mmcblk0* are whole-disk/boot-area
# nodes that some Allwinner builds also list under by-name - skip them.
foreach ($p in $parts | Where-Object { $_ -notin 'userdata', 'UDISK' -and $_ -notlike 'mmcblk*' }) {
    Dump $p "if=$byName/$p bs=1M"
}

Get-ChildItem $backupDir -Filter *.img |
    Get-FileHash -Algorithm SHA256 |
    ForEach-Object { "{0}  {1}" -f $_.Hash.ToLower(), (Split-Path $_.Path -Leaf) } |
    Out-File -Encoding utf8 (Join-Path $infoDir 'backup-sha256.txt')

Write-Host "Partition backup done -> $backupDir" -ForegroundColor Green
