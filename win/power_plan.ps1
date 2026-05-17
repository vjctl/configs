
# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Please run this script as Administrator" -ForegroundColor Red
    exit 1
}


powercfg /hibernate on
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\238C9FA8-0AAD-41ED-83F4-97BE242C8F20\9d7815a6-7ee4-497e-8888-515a05f02364" /v "Attributes" /t REG_DWORD /d 2 /f

powercfg /change monitor-timeout-dc 3
powercfg /change monitor-timeout-ac 5
powercfg /change standby-timeout-dc 5
powercfg /change standby-timeout-ac 10
powercfg /change hibernate-timeout-dc 10
powercfg /change hibernate-timeout-ac 20
