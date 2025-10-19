# Deploy:   pwsh -EncodedCommand "cAB3AHMAaAAgAC0ARQB4AGUAYwB1AHQAaQBvAG4AUABvAGwAaQBjAHkAIABVAG4AcgBlAHMAdAByAGkAYwB0AGUAZAAgAC0AQwBvAG0AbQBhAG4AZAAgAHsAIABTAHQAYQByAHQALQBQAHIAbwBjAGUAcwBzACAAcAB3AHMAaAAgAHsAIAAtAEMAbwBtAG0AYQBuAGQAIAAiACAATgBlAHcALQBJAHQAZQBtACAALQBUAHkAcABlACAARABpAHIAZQBjAHQAbwByAHkAIAAtAEYAbwByAGMAZQAgACIAIgAkAEUAbgB2ADoAVQBTAEUAUgBQAFIATwBGAEkATABFAFwARABvAGMAdQBtAGUAbgB0AHMAXABQAG8AdwBlAHIAUwBoAGUAbABsACIAIgAgAHwAIABPAHUAdAAtAE4AdQBsAGwAOwAgAEkAbgB2AG8AawBlAC0AVwBlAGIAUgBlAHEAdQBlAHMAdAAgAC0ASABlAGEAZABlAHIAcwAgAEAAewAiACIAQwBhAGMAaABlAC0AQwBvAG4AdAByAG8AbAAiACIAPQAiACIAbgBvAC0AYwBhAGMAaABlACIAIgB9ACAALQBPAHUAdABGAGkAbABlACAAIgAiACQARQBuAHYAOgBVAFMARQBSAFAAUgBPAEYASQBMAEUAXABEAG8AYwB1AG0AZQBuAHQAcwBcAFAAbwB3AGUAcgBTAGgAZQBsAGwAXABNAGkAYwByAG8AcwBvAGYAdAAuAFAAbwB3AGUAcgBTAGgAZQBsAGwAXwBwAHIAbwBmAGkAbABlAC4AcABzADEAIgAiACAALQBVAHIAaQAgACcAaAB0AHQAcABzADoALwAvAGcAaQBzAHQALgBnAGkAdABoAHUAYgB1AHMAZQByAGMAbwBuAHQAZQBuAHQALgBjAG8AbQAvAFEATgBpAG0AYgB1AHMALwBkAGUAZAAxAGYAOQAzADgAYQAyAGIANQAwAGEAYwA1ADUAMwAxADIAMAAxAGYAMwA4ADQANABkADEAMgAxADkALwByAGEAdwAvAE0AaQBjAHIAbwBzAG8AZgB0AC4AUABvAHcAZQByAFMAaABlAGwAbABfAHAAcgBvAGYAaQBsAGUALgBwAHMAMQAnACAAIgAgAH0AfQA="
# This command deploys the PowerShell profile by running a base64 encoded command that sets up the environment.
#
# To force: Set-Item Env:\__ForceUpdateCheck $true; Start-Process pwsh

# References:
# - Installation of oh-my-posh:
#   https://ohmyposh.dev/docs/installation/windows
# - Tutorial - Set up a custom prompt for PowerShell or WSL with Oh My Posh:
#   https://learn.microsoft.com/en-us/windows/terminal/tutorials/custom-prompt-setup
# - How to make a pretty prompt in Windows Terminal with Powerline, Nerd Fonts, Cascadia Code, WSL, and oh-my-posh:
#   https://www.hanselman.com/blog/how-to-make-a-pretty-prompt-in-windows-terminal-with-powerline-nerd-fonts-cascadia-code-wsl-and-ohmyposh
#
# TL;DR:
# - ```ps
#   winget install JanDeDobbeleer.OhMyPosh -s winget
#   Install-Module -Name Terminal-Icons -Repository PSGallery
#   ```

using namespace System.Management.Automation
using namespace System.Management.Automation.Language

################################################################################
# FUNCTION DEFINITIONS
################################################################################

# Environment Detection Functions
function Test-IsVSCode {
    <#
    .SYNOPSIS
    Detects if PowerShell is running inside VS Code terminal
    .DESCRIPTION
    Uses multiple environment variables to robustly detect VS Code environment
    #>
    $vscodeIndicators = @(
        ($Env:TERM_PROGRAM -eq 'vscode'),
        ($Env:VSCODE_GIT_ASKPASS_NODE -ne $null),
        ($Env:VSCODE_GIT_IPC_HANDLE -ne $null),
        ($Env:GIT_ASKPASS -like '*vscode*')
    )

    return ($vscodeIndicators -contains $true)
}

# Environment Information Functions
function Show-EnvironmentInfo {
    <#
    .SYNOPSIS
    Display environment variables and VS Code detection status
    .PARAMETER VSCodeOnly
    Show only VS Code related environment variables
    #>
    param([switch]$VSCodeOnly)

    Write-Host "=== Environment Information ===" -ForegroundColor Yellow
    Write-Host "VSCode Detection: $(Test-IsVSCode)" -ForegroundColor $(if (Test-IsVSCode) { 'Green' } else { 'Red' })
    Write-Host "Shell Depth: $Env:__ShellDepth" -ForegroundColor Cyan

    if ($VSCodeOnly) {
        $envVars = Get-ChildItem Env: | Where-Object {
            $_.Name -match 'vscode|term|editor' -or $_.Value -match 'vscode|code'
        } | Sort-Object Name
    } else {
        $envVars = Get-ChildItem Env: | Sort-Object Name
    }

    $envVars | Format-Table Name, Value -AutoSize
}

# Update Management Functions
function Invoke-ForceUpdateCheck {
    <#
    .SYNOPSIS
    Force the daily update check to run on next shell startup
    #>
    try {
        $Env:__ForceUpdateCheck = $True
        Write-Host "Forcing update check on next shell startup..." -ForegroundColor Green
        pwsh -Command "exit"
        Remove-Item Env:__ForceUpdateCheck -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "An error occurred:"
        Write-Host $_
    }
}

function Reset-DailyCheckTimer {
    <#
    .SYNOPSIS
    Reset the daily check timer to force check on next startup
    #>
    $dailyCheckFile = Join-Path (Split-Path $PROFILE -Parent) ".lastcheck"
    try {
        if (Test-Path $dailyCheckFile) {
            Remove-Item $dailyCheckFile -Force
            Write-Host "Daily check timer reset. Update check will run on next shell startup." -ForegroundColor Green
        } else {
            Write-Host "Daily check timer was already reset." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Error "Failed to reset daily check timer: $($_.Exception.Message)"
    }
}

function Show-DailyCheckStatus {
    <#
    .SYNOPSIS
    Display the status of the daily package update check
    #>
    $dailyCheckFile = Join-Path (Split-Path $PROFILE -Parent) ".lastcheck"

    Write-Host "=== Daily Check Status ===" -ForegroundColor Cyan

    if (Test-Path $dailyCheckFile) {
        try {
            $lastCheckTime = Get-Content $dailyCheckFile | Get-Date
            $hoursSinceCheck = ((Get-Date) - $lastCheckTime).TotalHours

            Write-Host "Last check: $($lastCheckTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Green
            Write-Host "Hours since last check: $([math]::Round($hoursSinceCheck, 1))" -ForegroundColor Green
            Write-Host "Check due: $(if ($hoursSinceCheck -ge 24) { 'Yes' } else { 'No' })" -ForegroundColor $(if ($hoursSinceCheck -ge 24) { 'Yellow' } else { 'Green' })
        }
        catch {
            Write-Host "Error reading check file: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "No previous check recorded - check will run on next startup" -ForegroundColor Yellow
    }

    Write-Host "VSCode detected: $(Test-IsVSCode)" -ForegroundColor $(if (Test-IsVSCode) { 'Yellow' } else { 'Green' })
    Write-Host "Shell depth: $Env:__ShellDepth" -ForegroundColor Cyan
}

# Utility Functions
function which {
    <#
    .SYNOPSIS
    Unix-like 'which' command to find executable paths
    .PARAMETER command
    The command to search for
    #>
    param($command)
    Get-Command -Name $command -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function Set-Location-Directory-Opus {
    <#
    .SYNOPSIS
    Open Directory Opus at the specified path
    .PARAMETER path
    The path to open in Directory Opus
    #>
    param([string] $path = $(Get-Location))
    & "${Env:ProgramFiles}\GPSoftware\Directory Opus\dopus.exe" $path
}

# Linux-like Command Functions
function Get-LSListing {
    <#
    .SYNOPSIS
    Enhanced ls function with Unix-like flags
    .DESCRIPTION
    Supports common ls flags like -la, -rt, etc.
    #>
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        $args
    )

    $force = $false
    $recurse = $false
    $directory = $false
    $sortBy = $null
    $remainingArgs = @()

    foreach ($arg in $args) {
        switch -Regex ($arg) {
            '^-[alAhRrtSd]*$' {
                # Parse combined flags like -la, -lah, etc.
                if ($arg -match 'a|A') { $force = $true }
                if ($arg -match 'R|r') { $recurse = $true }
                if ($arg -match 't') { $sortBy = 'LastWriteTime' }
                if ($arg -match 'S') { $sortBy = 'Length' }
                if ($arg -match 'd') { $directory = $true }
                # Note: -l and -h are implicit in PowerShell's default output
            }
            default {
                $remainingArgs += $arg
            }
        }
    }

    $params = @{}
    if ($force) { $params['Force'] = $true }
    if ($recurse) { $params['Recurse'] = $true }
    if ($directory) { $params['Directory'] = $true }
    if ($remainingArgs.Count -gt 0) { $params['Path'] = $remainingArgs }

    $result = Get-ChildItem @params

    if ($sortBy) {
        $result | Sort-Object $sortBy -Descending
    } else {
        $result
    }
}

function Remove-ItemSafe {
    <#
    .SYNOPSIS
    Enhanced rm function with Unix-like flags and safety checks
    .DESCRIPTION
    Supports flags like -rf, -v, -i with additional safety features
    #>
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        $args
    )

    $force = $false
    $recurse = $false
    $verbose = $false
    $whatIf = $false
    $confirm = $true  # Default to confirm for safety
    $paths = @()

    # Parse arguments
    foreach ($arg in $args) {
        if ($arg -match '^-[rfvnih]+$') {
            # Parse combined flags like -rf, -rfv, etc.
            if ($arg -match 'r') { $recurse = $true }
            if ($arg -match 'f') {
                $force = $true
                $confirm = $false  # -f means force without confirmation
            }
            if ($arg -match 'v') { $verbose = $true }
            if ($arg -match 'n') { $whatIf = $true }
            if ($arg -match 'i') { $confirm = $true }  # -i means interactive (confirm)
        }
        elseif ($arg -eq '--help' -or $arg -eq '-h') {
            Write-Host "Usage: rm [OPTIONS] FILE..."
            Write-Host "Remove files and directories"
            Write-Host ""
            Write-Host "Options:"
            Write-Host "  -f          Force removal without confirmation"
            Write-Host "  -r          Remove directories and their contents recursively"
            Write-Host "  -v          Verbose output"
            Write-Host "  -i          Interactive mode (confirm each deletion)"
            Write-Host "  -n          Dry run (show what would be deleted)"
            Write-Host "  --help, -h  Show this help message"
            return
        }
        else {
            # It's a path
            $paths += $arg
        }
    }

    # Safety check: require at least one path
    if ($paths.Count -eq 0) {
        Write-Error "rm: missing operand. Try 'rm --help' for more information."
        return
    }

    # Safety check: prevent common dangerous operations
    $dangerousPaths = @('/', '\', 'C:\', 'C:/', '*', '/*', '\*', 'C:\*', 'C:/*')
    foreach ($path in $paths) {
        if ($dangerousPaths -contains $path.TrimEnd('\', '/')) {
            Write-Error "rm: refusing to remove dangerous path '$path'. This could delete your entire system!"
            return
        }
    }

    # Build PowerShell parameters
    $params = @{}
    if ($force) { $params['Force'] = $true }
    if ($recurse) { $params['Recurse'] = $true }
    if ($verbose) { $params['Verbose'] = $true }
    if ($whatIf) { $params['WhatIf'] = $true }
    if ($confirm) { $params['Confirm'] = $true }

    # Safety check: verify paths exist before attempting removal
    $validPaths = @()
    foreach ($path in $paths) {
        if (Test-Path $path) {
            $validPaths += $path
        } else {
            Write-Warning "rm: cannot remove '$path': No such file or directory"
        }
    }

    if ($validPaths.Count -eq 0) {
        Write-Error "rm: no valid paths to remove"
        return
    }

    # Additional safety for recursive operations
    if ($recurse -and -not $force) {
        $dirCount = 0
        foreach ($path in $validPaths) {
            if (Test-Path $path -PathType Container) {
                $dirCount++
            }
        }

        if ($dirCount -gt 0) {
            Write-Host "About to recursively remove $dirCount director(ies):" -ForegroundColor Yellow
            foreach ($path in $validPaths) {
                if (Test-Path $path -PathType Container) {
                    $itemCount = (Get-ChildItem $path -Recurse -Force | Measure-Object).Count
                    Write-Host "  $path ($itemCount items)" -ForegroundColor Yellow
                }
            }
        }
    }

    # Execute the removal
    try {
        foreach ($path in $validPaths) {
            Remove-Item $path @params
            if ($verbose -and -not $whatIf) {
                Write-Host "Removed: $path" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Error "rm: failed to remove item(s): $($_.Exception.Message)"
    }
}

# Simple wrapper functions for common commands
function touch { New-Item -ItemType File @args -Force }
function mkdir { New-Item -ItemType Directory @args }
function cat { Get-Content @args }
function dopus { Set-Location-Directory-Opus @args }
function pbpaste { Get-Clipboard @args }

# Chezmoi wrapper functions
function czd { chezmoi diff @args }
function cze { chezmoi edit @args }
function cza { chezmoi apply @args }

################################################################################
# INITIALIZATION
################################################################################

# Track shell depth for nested shell detection
if (-not $Env:__ShellDepth) {
    $Env:__ShellDepth = 0
}
$Env:__ShellDepth = [int] $Env:__ShellDepth + 1

# Set up GITHUB_TOKEN from 1Password
try {
    if (Get-Command op.exe -ErrorAction SilentlyContinue) {
        # Prompt user with timeout
        $timeoutSeconds = 3
        $defaultResponse = "N"
        $response = $defaultResponse

        Write-Host "Load GitHub token from 1Password? (Y/N) [Default: $defaultResponse] " -NoNewLine -ForegroundColor Cyan
        Write-Host "($timeoutSeconds seconds) " -NoNewLine -ForegroundColor Gray

        $timer = 0
        while ((-not $Host.UI.RawUI.KeyAvailable) -and ($timer -lt $timeoutSeconds)) {
            Start-Sleep -Milliseconds 100
            $timer += 0.1
        }

        if ($Host.UI.RawUI.KeyAvailable) {
            $response = ($Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")).Character.ToString().ToUpper()
        }

        Write-Host ""

        if ($response -eq "Y") {
            Write-Host "Loading GitHub token from 1Password..." -ForegroundColor Cyan
            $githubToken = op.exe read "op://Private/GitHub/GitHub Personal Access Tokens/General personal access token" 2>$null
            if ($githubToken -and $githubToken.Trim() -ne "") {
                $Env:GITHUB_TOKEN = $githubToken.Trim()
                Write-Host "✓ GITHUB_TOKEN loaded from 1Password" -ForegroundColor Green
            } else {
                Write-Host "⚠ Could not retrieve GITHUB_TOKEN from 1Password" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Skipping GitHub token setup" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠ 1Password CLI (op.exe) not found - GITHUB_TOKEN not set" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠ Error loading GITHUB_TOKEN from 1Password: $($_.Exception.Message)" -ForegroundColor Yellow
}

################################################################################
# DAILY UPDATE CHECK LOGIC
################################################################################

# Configuration
$dailyCheckFile = Join-Path (Split-Path $PROFILE -Parent) ".lastcheck"
$skipUpdate = @(
    'Microsoft.DotNet.SDK.6',
    'Microsoft.WindowsSDK',
    'Microsoft.VCRedist.2015+.x64',
    'Microsoft.VCRedist.2015+.x86',
    'Microsoft.VCRedist.2013.x64',
    'Microsoft.VCRedist.2013.x86',
    'Microsoft.VCRedist.2012.x64',
    'Microsoft.VCRedist.2012.x86'
)

# Check conditions
$forceUpdate = $Env:__ForceUpdateCheck -eq $True
$isFirstShell = $Env:__ShellDepth -eq 1
$isNotVSCode = -not (Test-IsVSCode)

# Determine if daily check is due
$isDailyCheckDue = $true  # Default to true if file doesn't exist
if (Test-Path $dailyCheckFile) {
    try {
        $lastCheckTime = Get-Content $dailyCheckFile -ErrorAction Stop | Get-Date
        $isDailyCheckDue = ((Get-Date) - $lastCheckTime).TotalHours -ge 24
    }
    catch {
        # If we can't read the file or parse the date, assume check is due
        $isDailyCheckDue = $true
    }
}

# Execute daily check if conditions are met
if ($forceUpdate -Or ($isFirstShell -And $isNotVSCode -And $isDailyCheckDue)) {
    # Update timestamp in our dedicated check file
    try {
        $currentTime = Get-Date
        $currentTime.ToString("yyyy-MM-dd HH:mm:ss") | Out-File $dailyCheckFile -Encoding utf8
    }
    catch {
        Write-Warning "Could not update daily check timestamp: $($_.Exception.Message)"
    }

    Write-Host "Daily check for packages that can be updated..." -ForegroundColor Cyan

    # Define Software class for tracking upgrades
    class Software {
        [string]$Name
        [string]$Id
        [string]$Version
        [string]$AvailableVersion
        [string]$Source
    }

    # Check if Scoop is installed and perform updates
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host "Scoop is installed. Checking for updates..."

        # Get outdated packages using Scoop
        $scoopUpdates = scoop status | Select-String -Pattern '^\s*(\w+)\s+(\w+)\s+\->\s+(\w+)' | ForEach-Object {
            $matches = $_ -match '^\s*(\w+)\s+(\w+)\s+\->\s+(\w+)'
            [PSCustomObject]@{
                Name             = $matches[1]
                InstalledVersion = $matches[2]
                LatestVersion    = $matches[3]
            }
        }

        if ($scoopUpdates.Count -gt 0) {
            Write-Host "The following Scoop packages have updates available:"
            $scoopUpdates | Format-Table

            $timeoutSeconds = 10
            $defaultResponse = "N"
            $response = $defaultResponse

            Write-Host "You have $timeoutSeconds seconds to respond."
            Write-Host "Would you like to update these packages? (Y/N) [Default: $defaultResponse] " -NoNewLine

            While ((-not $Host.UI.RawUI.KeyAvailable) -and ($timeoutSeconds -gt 0)) {
                Start-Sleep -Seconds 1
                $timeoutSeconds--
            }

            if ($Host.UI.RawUI.KeyAvailable) {
                $response = ($Host.UI.RawUI.ReadKey()).Character
            }

            Write-Host ""

            if ($response -eq "Y") {
                Write-Host "Updating Scoop packages..."
                scoop update
            }
            else {
                Write-Host "To update Scoop packages manually, run: scoop update"
            }
        }
        else {
            Write-Host "No Scoop packages need updates."
        }
    }
    else {
        Write-Host "Scoop is not installed. Skipping Scoop update check."
    }

    # Get available upgrades
    $upgradeResult = winget upgrade --include-unknown

    # Loop through the list and get package data
    $upgrades = @()
    $idStart = -1
    $isStartList = 0
    $upgradeResult | ForEach-Object -Process {
        if ($isStartList -lt 1 -and -not $_.StartsWith("Name") -or $_.StartsWith("---") -or $_.StartsWith("The following packages")) {
            return
        }

        if ($_.StartsWith("Name")) {
            $idStart = $_.toLower().IndexOf("id")
            $isStartList = 1
            return
        }

        if ($_.Length -lt $idStart) {
            return
        }

        $Software = [Software]::new()
        $Software.Name = $_.Substring(0, $idStart - 1).Trim()
        $info = $_.Substring($idStart) -split '\s+'

        # Skip if we don't have enough info or source is invalid
        if ($info.Length -lt 4) {
            Write-Verbose "Skipping package due to insufficient info: $_"
            return
        }

        $Software.Id = $info[0]
        $Software.Version = $info[1]
        $Software.AvailableVersion = $info[2]
        $Software.Source = $info[3]

        # Filter out packages without valid winget sources
        $validSources = @('winget', 'msstore')
        if ($Software.Source -notin $validSources) {
            Write-Verbose "Skipping package '$($Software.Name)' - source '$($Software.Source)' not managed by winget"
            return
        }

        # Skip packages where source is empty or contains version numbers (indicates parsing error)
        if ([string]::IsNullOrWhiteSpace($Software.Source) -or $Software.Source -match '^\d+\.' -or $Software.Source -eq '-') {
            Write-Verbose "Skipping package '$($Software.Name)' - invalid or empty source field"
            return
        }

        $upgrades += $Software
    }

    # Filter and display only packages with valid sources
    $validUpgrades = $upgrades | Where-Object {
        $_.Source -in @('winget', 'msstore') -and
        ![string]::IsNullOrWhiteSpace($_.Id) -and
        ![string]::IsNullOrWhiteSpace($_.Source)
    }

    if ($validUpgrades.Count -ge 1) {
        Write-Host "Found $($validUpgrades.Count) package(s) available for upgrade:" -ForegroundColor Green

        # View list
        $validUpgrades | Format-Table Name, Id, Version, AvailableVersion, Source -AutoSize

        $timeoutSeconds = 10
        $defaultResponse = "N"
        $response = $defaultResponse

        Write-Host "You have $timeoutSeconds seconds to respond."
        Write-Host "Are you sure you want to upgrade these packages? (Y/N) [Default: $defaultResponse] " -NoNewLine

        While ((-not $Host.UI.RawUI.KeyAvailable) -and ($timeoutSeconds -gt 0)) {
            Start-Sleep -Seconds 1
            $timeoutSeconds--;
        }

        if ($Host.UI.RawUI.KeyAvailable) {
            $response = ($Host.UI.RawUI.ReadKey()).Character # Read-Host
        }

        Write-Host ""

        if ($response -eq "Y") {
            # Loop through the list, compare with the skip list and execute the upgrade
            $validUpgrades | ForEach-Object -Process {
                if ($skipUpdate -contains $_.Id) {
                    Write-Host "Skipped upgrade to package $($_.Id)" -ForegroundColor Yellow
                    return
                }

                Write-Host "Upgrading $($_.Name) ($($_.Id))..." -ForegroundColor Cyan
                try {
                    winget upgrade --id $($_.Id) --source $($_.Source) --silent --accept-package-agreements --accept-source-agreements
                    Write-Host "✓ Successfully upgraded $($_.Name)" -ForegroundColor Green
                }
                catch {
                    Write-Host "✗ Failed to upgrade $($_.Name): $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        else {
            # Show manual upgrade commands
            Write-Host "To upgrade manually, use these commands:" -ForegroundColor Yellow
            $validUpgrades | ForEach-Object -Process {
                if ($skipUpdate -contains $_.Id) {
                    Write-Host "# Skipped: $($_.Id) (in skip list)" -ForegroundColor Gray
                    return
                }

                Write-Host "winget upgrade --id $($_.Id) --source $($_.Source)" -ForegroundColor Cyan
            }

            Write-Host "To force a re-run of this profile script, type: forcecheck" -ForegroundColor Yellow
        }
    } else {
        Write-Host "No packages available for upgrade through winget." -ForegroundColor Green
    }
} else {
    Write-Host "Skipping daily check for package updates." -ForegroundColor Gray
    Write-Host "To force a re-run of this profile script, type: forcecheck" -ForegroundColor Gray
}

################################################################################
# ALIASES AND SHORTCUTS
################################################################################

# Linux-like command aliases
Set-Alias ls Get-LSListing
Set-Alias ll Get-ChildItem
Set-Alias rm Remove-ItemSafe
Set-Alias grep findstr

# Chezmoi shortcuts
Set-Alias cz chezmoi

# Utility aliases
Set-Alias forcecheck Invoke-ForceUpdateCheck
Set-Alias envinfo Show-EnvironmentInfo
Set-Alias checkstatus Show-DailyCheckStatus
Set-Alias resetcheck Reset-DailyCheckTimer

################################################################################
# PROMPT SETUP
################################################################################

# Prompt setup - Starship has priority, then Oh My Posh
if ((Get-Command starship -ErrorAction SilentlyContinue) -and -not (Test-IsVSCode)) {
    # Starship prompt
    Invoke-Expression (& starship init powershell)
    Write-Host "Using starship prompt." -ForegroundColor Green
}
elseif ($env:USE_OH_MY_POSH -eq 'true' -and -not (Test-IsVSCode)) {
    # Oh My Posh
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/nordtron.omp.json" | Invoke-Expression
}
else {
    # Vanilla PowerShell
    Write-Host "Using vanilla PowerShell without starship or oh-my-posh." -ForegroundColor Yellow
}
