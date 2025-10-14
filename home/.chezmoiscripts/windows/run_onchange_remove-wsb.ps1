# --- Self-elevate ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
  $argsLine = "-ExecutionPolicy Bypass -NoProfile -File `"$($MyInvocation.MyCommand.Path)`" " + $MyInvocation.UnboundArguments
  Start-Process -Wait -FilePath PowerShell.exe -Verb RunAs -ArgumentList $argsLine
  exit
}

# Tidy output (optional)
$ProgressPreference = 'SilentlyContinue'

New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force
New-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "EnableDynamicContentInWSB" -PropertyType DWORD -Value 0
