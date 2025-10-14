# --- Self-elevate ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
  $argsLine = "-ExecutionPolicy Bypass -NoProfile -File `"$($MyInvocation.MyCommand.Path)`" " + $MyInvocation.UnboundArguments
  Start-Process -Wait -FilePath PowerShell.exe -Verb RunAs -ArgumentList $argsLine
  exit
}

# Tidy output (optional)
# $ProgressPreference = 'SilentlyContinue'

New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force
New-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "EnableDynamicContentInWSB" -PropertyType DWORD -Value 0

# Wait 5 seconds of a keypress before closing
Write-Host ""
Write-Host "Done. (Press any key to close, or wait 5 seconds...)"
Write-Host ""
$timeout = 5
$start = Get-Date
while ($true) {
    if ($host.UI.RawUI.KeyAvailable) {
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        break
    }
    if ((Get-Date) - $start -gt (New-TimeSpan -Seconds $timeout)) {
        break
    }
    Start-Sleep -Milliseconds 100
}
