if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$drives = (Get-BitLockerVolume).MountPoint
Write-Host "Drives: $($drives -join ', ')"

$encrypted = Get-BitLockerVolume | Where-Object { $_.VolumeStatus -ne 'FullyDecrypted' }
if (-not $encrypted) { Write-Host "No encrypted drives found"; exit }

for ($i = 0; $i -lt $encrypted.Count; $i++) {
    Write-Host "[$i] $($encrypted[$i].MountPoint) - $($encrypted[$i].VolumeStatus), Protection $($encrypted[$i].ProtectionStatus)"
}
$selection = Read-Host "Enter drive numbers to disable (comma-separated, or 'q' to quit)"
if ($selection -eq 'q') { exit }

$indices = $selection -split ',' | ForEach-Object { [int]$_.Trim() }
$selected = $indices | ForEach-Object { $encrypted[$_] }

foreach ($vol in $selected) {
    Disable-BitLocker -MountPoint $vol.MountPoint
}

Write-Host "`nWaiting for decryption"
do {
    Start-Sleep -Seconds 5
    $still = $selected | Where-Object { (Get-BitLockerVolume -MountPoint $_.MountPoint).VolumeStatus -match 'Decryption' }
} while ($still)

Write-Host "BitLocker disabled on selected drives"
Get-BitLockerVolume | Format-Table MountPoint, VolumeStatus, ProtectionStatus -AutoSize
