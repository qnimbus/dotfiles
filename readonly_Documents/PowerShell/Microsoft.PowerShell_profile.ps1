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

# Variable to determine how many shells 'deep' we are
if (-not $Env:__ShellDepth) {
    $Env:__ShellDepth = 0
}
$Env:__ShellDepth = [int] $Env:__ShellDepth + 1

# Timestamp of file to use to determine if code section has to be run
$dailyFile = $PROFILE
# Skip if we're in MS VSCode or if this is a subshell
$forceUpdate = $Env:__ForceUpdateCheck -eq $True
$isFirstShell = $Env:__ShellDepth -eq 1
$isNotVSCode = $Env:TERM_PROGRAM -ne 'vscode'
$isDailyCheckDue = ((Get-Date) - (Get-Item $dailyFile).LastWriteTime).TotalHours -ge 24

# Skip if we're in MS VSCode or if this is a subshell
if ($forceUpdate -Or ($isFirstShell -And $isNotVSCode -And $isDailyCheckDue)) {
    # Update timestamp of $PROFILE file
    (Get-Item $dailyFile).LastWriteTime = Get-Date

    Write-Host "Daily check for packages that can be updated..."

    # Packages not to update
    $skipUpdate = @(
        'Microsoft.DotNet.SDK.6',
        'Microsoft.WindowsSDK'
    )

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
        $Software.Name = $_.Substring(0, $idStart - 1)
        $info = $_.Substring($idStart) -split '\s+'
        $Software.Id = $info[0]
        $Software.Version = $info[1]
        $Software.AvailableVersion = $info[2]
        $Software.Source = $info[3]

        $upgrades += $Software
    }

    if ($upgrades.Length -ge 1) {
        # View list
        $upgrades | Format-Table

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
            # Loop through the list, compare with the skip list and execute the upgrade (could be done in the upper foreach as well)
            $upgrades | ForEach-Object -Process {
                if ($skipUpdate -contains $_.Id) {
                    Write-Host "Skipped upgrade to package $($_.id)"
                    return
                }

                winget upgrade --include-unknown --source $($_.Source) $($_.Id)
            }      
        }
        else {
            # Loop through the list, compare with the skip list and execute the upgrade (could be done in the upper foreach as well)
            $upgrades | ForEach-Object -Process {
                if ($skipUpdate -contains $_.Id) {
                    Write-Host "Skipped upgrade to package $($_.id)"
                    return
                }

                Write-Host "To upgrade $($_.Id), type : " -NoNewLine
                'winget upgrade --include-unknown --source {0} {1}' -f $($_.Source), $_.Id
            }

            Write-Host "To force a re-run of this profile script, type : " -NoNewLine
            '"Set-Item Env:\__ForceUpdateCheck $true; Start-Process pwsh"'
        }
    }
}

# Useful functions
function which($command) { 
    Get-Command -Name $command -ErrorAction SilentlyContinue | 
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue 
}

function Set-Location-Directory-Opus([string] $path = $(Get-Location)) {
    & "${Env:ProgramFiles}\GPSoftware\Directory Opus\dopus.exe" $path
}

function ForceUpdateCheck() {
    try {
        $Env:__ForceUpdateCheck = $True ; pwsh -Command  "exit" ; Remove-Item Env:__ForceUpdateCheck
    }
    catch {
        Write-Host "An error occurred:"
        Write-Host $_
    }
}

# Useful functions for Linux-like behavior

# Enhanced ls function to handle common Linux flags
function Get-LSListing {
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

# Useful aliases
Set-Alias ls Get-LSListing
Set-Alias ll Get-ChildItem
Set-Alias grep findstr
function touch { New-Item -ItemType File @args -Force }
function mkdir { New-Item -ItemType Directory @args }
function rm { Remove-Item @args }
function cat { Get-Content @args }
function dopus { Set-Location-Directory-Opus @args }
function pbpaste { Get-Clipboard @args }

# Chezmoi functions for multi-word commands
Set-Alias cz chezmoi
function cze { chezmoi edit @args }
function cza { chezmoi apply @args }

# Prompt setup - Starship has priority, then Oh My Posh
if (Get-Command starship -ErrorAction SilentlyContinue -and $Env:TERM_PROGRAM -ne 'vscode') {
    # Starship prompt
    Invoke-Expression (& starship init powershell)
}
elseif ($env:USE_OH_MY_POSH -eq 'true' -and $Env:TERM_PROGRAM -ne 'vscode') {
    # Oh My Posh
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/nordtron.omp.json" | Invoke-Expression
}
else {
    # Vanilla PowerShell
    Write-Host "Using vanilla PowerShell without starship or oh-my-posh."
}