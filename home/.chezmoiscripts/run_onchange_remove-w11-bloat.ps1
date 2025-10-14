# --- Self-elevate ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
  $argsLine = "-ExecutionPolicy Bypass -NoProfile -File `"$($MyInvocation.MyCommand.Path)`" " + $MyInvocation.UnboundArguments
  Start-Process -Wait -FilePath PowerShell.exe -Verb RunAs -ArgumentList $argsLine
  exit
}

# Tidy output (optional)
$ProgressPreference = 'SilentlyContinue'

# --- Helpers ---
function Remove-AppxByName {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Name,
    [switch]$AllUsers
  )
  $getArgs = @{ ErrorAction = 'SilentlyContinue' }
  if ($AllUsers) { $getArgs['AllUsers'] = $true }

  $pkgs = Get-AppxPackage @getArgs | Where-Object { $_.Name -eq $Name }
  if (-not $pkgs) { Write-Host "Skipping $Name (not installed)"; return }

  foreach ($pkg in $pkgs) {
    Write-Host "Removing $($pkg.Name)"
    try {
      $remArgs = @{ Package = $pkg.PackageFullName; ErrorAction = 'Stop' }
      if ($AllUsers) { $remArgs['AllUsers'] = $true }
      Remove-AppxPackage @remArgs
    } catch {
      Write-Host "  ⚠️ $($pkg.Name): $($_.Exception.Message)"
    }
  }
}

function Remove-AppxMatching {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Pattern, # regex
    [switch]$AllUsers
  )
  $getArgs = @{ ErrorAction = 'SilentlyContinue' }
  if ($AllUsers) { $getArgs['AllUsers'] = $true }

  $pkgs = Get-AppxPackage @getArgs |
          Where-Object { $_.Name -match $Pattern -and $_.NonRemovable -eq $false }

  if (-not $pkgs) {
    Write-Host "No Appx packages match pattern '$Pattern' for " + ($(if($AllUsers){"all users"}else{"current user"}))
    return
  }

  foreach ($pkg in $pkgs) {
    Write-Host "Removing $($pkg.Name)"
    try {
      $remArgs = @{ Package = $pkg.PackageFullName; ErrorAction = 'Stop' }
      if ($AllUsers) { $remArgs['AllUsers'] = $true }
      Remove-AppxPackage @remArgs
    } catch {
      Write-Host "  ⚠️ $($pkg.Name): $($_.Exception.Message)"
    }
  }
}

function Remove-ProvisionedByDisplayName {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$DisplayNamePattern # regex
  )
  $prov = Get-AppxProvisionedPackage -Online |
          Where-Object { $_.DisplayName -match $DisplayNamePattern }
  if (-not $prov) { Write-Host "No provisioned apps match '$DisplayNamePattern'"; return }

  foreach ($p in $prov) {
    Write-Host "Removing provisioned $($p.DisplayName)"
    try {
      Remove-AppxProvisionedPackage -Online -AllUsers -PackageName $p.PackageName -ErrorAction Stop | Out-Null
    } catch {
      Write-Host "  ⚠️ $($p.DisplayName): $($_.Exception.Message)"
    }
  }
}

# --- Specific per-app removals (quiet if missing) ---
$apps = @(
  'Clipchamp.Clipchamp',
  'Microsoft.549981C3F5F10',
  'Microsoft.BingNews',
  'Microsoft.BingWeather',
  'Microsoft.GamingApp',
  'Microsoft.GetHelp',
  'Microsoft.Getstarted',
  'Microsoft.Microsoft3DViewer',
  'Microsoft.MicrosoftOfficeHub',
  'Microsoft.MicrosoftSolitaireCollection',
  'Microsoft.MicrosoftStickyNotes',
  'Microsoft.MixedReality.Portal',
  'Microsoft.MSPaint',
  'Microsoft.OutlookForWindows',
  'Microsoft.Paint',
  'Microsoft.People',
  'Microsoft.ScreenSketch',
  'Microsoft.SkypeApp',
  'Microsoft.StorePurchaseApp',
  'Microsoft.Windows.Photos',
  'Microsoft.WindowsAlarms',
  'Microsoft.WindowsCamera',
  'Microsoft.WindowsCommunicationsApps',
  'Microsoft.WindowsFeedbackHub',
  'Microsoft.WindowsMaps',
  'Microsoft.WindowsSoundRecorder',
  'Microsoft.ZuneMusic',
  'Microsoft.ZuneVideo'
)
foreach ($name in $apps) { Remove-AppxByName -Name $name -AllUsers }

# --- Pattern-based cleanup (case-insensitive) ---
$Junk = '(?i)xbox|phone|disney|skype|spotify|groove|solitaire|zune|mixedreality|tiktok|adobe|prime|soundrecorder|bingweather|3dviewer'

Write-Host "`nRemoving apps for this user only."
Remove-AppxMatching -Pattern $Junk

Write-Host "`nRemoving apps for all users."
Remove-AppxMatching -Pattern $Junk -AllUsers

Write-Host "`nRemoving provisioned apps."
Remove-ProvisionedByDisplayName -DisplayNamePattern $Junk

# Wait 10 seconds of a keypress before closing
Write-Host ""
Write-Host "Done. (Press any key to close, or wait 10 seconds...)"
$timeout = 10
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
