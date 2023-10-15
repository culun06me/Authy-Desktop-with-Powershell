<#
.SYNOPSIS
    This script performs the installation or uninstallation of Authy Desktop.
    # LICENSE #
    PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
    Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
    This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
    You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
    The script is provided as a template to perform an install or uninstall of an application(s).
    The script either performs an "Install" deployment type or an "Uninstall" deployment type.
    The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
    The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
    The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
    Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
    Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
    Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
    Disables logging to file for the script. Default is: $false.
.EXAMPLE
    PowerShell.exe .\Deploy-AuthyDesktop.ps1 -DeploymentType "Install" -DeployMode "NonInteractive"
.EXAMPLE
    PowerShell.exe .\Deploy-AuthyDesktop.ps1 -DeploymentType "Install" -DeployMode "Silent"
.EXAMPLE
    PowerShell.exe .\Deploy-AuthyDesktop.ps1 -DeploymentType "Install" -DeployMode "Interactive"
.EXAMPLE
    PowerShell.exe .\Deploy-AuthyDesktop.ps1 -DeploymentType "Uninstall" -DeployMode "NonInteractive"
.EXAMPLE
    PowerShell.exe .\Deploy-AuthyDesktop.ps1 -DeploymentType "Uninstall" -DeployMode "Silent"
.EXAMPLE
    PowerShell.exe .\Deploy-AuthyDesktop.ps1 -DeploymentType "Uninstall" -DeployMode "Interactive"
.NOTES
    Toolkit Exit Code Ranges:
    60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
    69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
    70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK
    http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [ValidateSet('Install','Uninstall','Repair')]
    [string]$DeploymentType = 'Install',
    [Parameter(Mandatory=$false)]
    [ValidateSet('Interactive','Silent','NonInteractive')]
    [string]$DeployMode = 'Interactive',
    [Parameter(Mandatory=$false)]
    [switch]$AllowRebootPassThru = $false,
    [Parameter(Mandatory=$false)]
    [switch]$TerminalServerMode = $false,
    [Parameter(Mandatory=$false)]
    [switch]$DisableLogging = $false
)

Try {
    ## Set the script execution policy for this process
    Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}

    ##*===============================================
    ##* VARIABLE DECLARATION
    ##*===============================================
    ## Variables: Application
    [string]$appVendor = 'Twilio Inc.'
    [string]$appName = 'Authy Desktop'
    [string]$appVersion = ''
    [string]$appArch = ''
    [string]$appLang = ''
    [string]$appRevision = ''

    ##*===============================================
    ## Variables: Install Titles (Only set here to override defaults set by the toolkit)
    [string]$installName = ''
    [string]$installTitle = 'Twilio Inc. Authy Desktop'

    ##* Do not modify section below
    #region DoNotModify

    ## Variables: Exit Code
    [int32]$mainExitCode = 0

    ## Variables: Script
    [string]$deployAppScriptFriendlyName = 'Deploy Application'
    [version]$deployAppScriptVersion = [version]'3.9.3'
    [hashtable]$deployAppScriptParameters = $psBoundParameters

    ## Variables: Environment
    If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
    [string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

    ## Dot source the required App Deploy Toolkit Functions
    Try {
        [string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
        If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
        If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
    }
    Catch {
        If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
        Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
        ## Exit the script, returning the exit code to SCCM
        If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
    }

    #endregion
    ##* Do not modify section above
    ##*===============================================
    ##* END VARIABLE DECLARATION
    ##*===============================================

    If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
        ##*===============================================
        ##* PRE-INSTALLATION
        ##*===============================================
        [string]$installPhase = 'Pre-Installation'

        ## Microsoft Intune Win32 App Workaround - Check If Running 32-bit Powershell on 64-bit OS, Restart as 64-bit Process
        If (!([Environment]::Is64BitProcess)){
        If([Environment]::Is64BitOperatingSystem){
        Write-Log -Message "Running 32-bit Powershell on 64-bit OS, Restarting as 64-bit Process..." -Severity 2

        $Arguments = "-NoProfile -ExecutionPolicy ByPass -WindowStyle Hidden -File `"" + $myinvocation.mycommand.definition + "`""
        $Path = (Join-Path $Env:SystemRoot -ChildPath "\sysnative\WindowsPowerShell\v1.0\powershell.exe")
        Start-Process $Path -ArgumentList $Arguments -Wait
        Write-Log -Message "Finished Running x64 version of PowerShell"
        Exit

        }Else{
        Write-Log -Message "Running 32-bit Powershell on 32-bit OS"
        }
        }

        ## Show Welcome Message, Close Authy Desktop With a 60 Second Countdown Before Automatically Closing
        Show-InstallationWelcome -CloseApps 'Authy Desktop' -CloseAppsCountdown 60

        ## Show Progress Message (with the default message)
        Show-InstallationProgress

        ## Remove Authy Desktop (User Profile)
        $Users = Get-ChildItem C:\Users
        foreach ($user in $Users){

        $AuthyLocal = "$($user.fullname)\AppData\Local\authy"
        If (Test-Path $AuthyLocal) {

        $UninstPath = Get-ChildItem -Path "$AuthyLocal\Update.exe" -ErrorAction SilentlyContinue
        If($UninstPath.Exists)
        {
        Write-Log -Message "Found $($UninstPath.FullName), now attempting to uninstall $installTitle."
        Execute-ProcessAsUser -Path "$UninstPath" -Parameters "--uninstall -s" -Wait
        Start-Sleep -Seconds 5

        ## Cleanup User Profile Registry
        [scriptblock]$HKCURegistrySettings = {
        Remove-RegistryKey -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\authy' -SID $UserProfile.SID
        }
        Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings -ErrorAction SilentlyContinue

        ## Cleanup Authy Desktop (Local User Profile) Directory
        If (Test-Path $AuthyLocal) {
        Write-Log -Message "Cleanup ($AuthyLocal) Directory."
        Remove-Item -Path "$AuthyLocal" -Force -Recurse -ErrorAction SilentlyContinue 
        }
        }
        }
        }
        ## Remove Authy Desktop Start Menu Shortcut From All Profiles
        $Users = Get-ChildItem C:\Users
        foreach ($user in $Users){

        $StartMenuSC = "$($user.fullname)\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Twilio Inc"
        If (Test-Path $StartMenuSC) {
        Remove-Item $StartMenuSC -Recurse -Force -ErrorAction SilentlyContinue
        }
        ## Remove Authy Desktop Shortcuts From All Profiles
        $DesktopSC = "$($user.fullname)\Desktop\Authy Desktop.lnk"
        If (Test-Path $DesktopSC) {
        Remove-Item $DesktopSC -Recurse -Force -ErrorAction SilentlyContinue
        }
        }
  
        ##*===============================================
        ##* INSTALLATION
        ##*===============================================
        [string]$installPhase = 'Installation'

        If ($ENV:PROCESSOR_ARCHITECTURE -eq 'x86'){
        Write-Log -Message "Detected 32-bit OS Architecture." -Severity 1 -Source $deployAppScriptFriendlyName

        ## Install Authy Desktop (32-bit)
        $ExePath32 = Get-ChildItem -Path "$dirFiles\x86" -Include "Authy Desktop Setup*.exe" -File -Recurse -ErrorAction SilentlyContinue
        If($ExePath32.Exists)
        {
        Write-Log -Message "Found $($ExePath32.FullName), now attempting to install $installTitle (32-bit)."
        Show-InstallationProgress "Installing Authy Desktop (32-bit). This may take some time. Please wait..."
        Execute-ProcessAsUser -Path "$ExePath32" -Parameters "-s" -Wait
        Get-Process -Name "*Authy Desktop Setup*" -ErrorAction SilentlyContinue | Wait-Process
        }

        }
        Else
        {
        Write-Log -Message "Detected 64-bit OS Architecture" -Severity 1 -Source $deployAppScriptFriendlyName

        ## Install Authy Desktop (64-bit)
        $ExePath64 = Get-ChildItem -Path "$dirFiles\x64" -Include "Authy*Desktop*Setup*.exe" -File -Recurse -ErrorAction SilentlyContinue
        If($ExePath64.Exists)
        {
        Write-Log -Message "Found $($ExePath64.FullName), now attempting to install $installTitle (64-bit)."
        Show-InstallationProgress "Installing Authy Desktop (64-bit). This may take some time. Please wait..."
        Execute-ProcessAsUser -Path "$ExePath64" -Parameters "-s" -Wait
        Get-Process -Name "*Authy Desktop Setup*" -ErrorAction SilentlyContinue | Wait-Process
        }
        }

        ##*===============================================
        ##* POST-INSTALLATION
        ##*===============================================
        [string]$installPhase = 'Post-Installation'

    }
    ElseIf ($deploymentType -ieq 'Uninstall')
    {
        ##*===============================================
        ##* PRE-UNINSTALLATION
        ##*===============================================
        [string]$installPhase = 'Pre-Uninstallation'

        ## Show Welcome Message, Close Authy Desktop With a 60 Second Countdown Before Automatically Closing
        Show-InstallationWelcome -CloseApps 'Authy Desktop' -CloseAppsCountdown 60

        ## Show Progress Message (With a Message to Indicate the Application is Being Uninstalled)
        Show-InstallationProgress -StatusMessage "Uninstalling the $installTitle Application. Please Wait..."

        ##*===============================================
        ##* UNINSTALLATION
        ##*===============================================
        [string]$installPhase = 'Uninstallation'

        ## Uninstall Authy Desktop (User Profile)
        $Users = Get-ChildItem C:\Users
        foreach ($user in $Users){

        $AuthyLocal = "$($user.fullname)\AppData\Local\authy"
        If (Test-Path $AuthyLocal) {

        $UninstPath = Get-ChildItem -Path "$AuthyLocal\Update.exe" -ErrorAction SilentlyContinue
        If($UninstPath.Exists)
        {
        Write-Log -Message "Found $($UninstPath.FullName), now attempting to uninstall $installTitle."
        Execute-ProcessAsUser -Path "$UninstPath" -Parameters "--uninstall -s" -Wait
        Start-Sleep -Seconds 5

        ## Cleanup User Profile Registry
        [scriptblock]$HKCURegistrySettings = {
        Remove-RegistryKey -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\authy' -SID $UserProfile.SID
        }
        Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings -ErrorAction SilentlyContinue

        ## Cleanup Authy Desktop (Local User Profile) Directory
        If (Test-Path $AuthyLocal) {
        Write-Log -Message "Cleanup ($AuthyLocal) Directory."
        Remove-Item -Path "$AuthyLocal" -Force -Recurse -ErrorAction SilentlyContinue 
        }
        }
        }
        }
        ## Remove Authy Desktop Start Menu Shortcut From All Profiles
        $Users = Get-ChildItem C:\Users
        foreach ($user in $Users){

        $StartMenuSC = "$($user.fullname)\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Twilio Inc"
        If (Test-Path $StartMenuSC) {
        Remove-Item $StartMenuSC -Recurse -Force -ErrorAction SilentlyContinue
        }
        ## Remove Authy Desktop Shortcuts From All Profiles
        $DesktopSC = "$($user.fullname)\Desktop\Authy Desktop.lnk"
        If (Test-Path $DesktopSC) {
        Remove-Item $DesktopSC -Recurse -Force -ErrorAction SilentlyContinue
        }
        }

        ##*===============================================
        ##* POST-UNINSTALLATION
        ##*===============================================
        [string]$installPhase = 'Post-Uninstallation'


    }
    ElseIf ($deploymentType -ieq 'Repair')
    {
        ##*===============================================
        ##* PRE-REPAIR
        ##*===============================================
        [string]$installPhase = 'Pre-Repair'


        ##*===============================================
        ##* REPAIR
        ##*===============================================
        [string]$installPhase = 'Repair'


        ##*===============================================
        ##* POST-REPAIR
        ##*===============================================
        [string]$installPhase = 'Post-Repair'


    }
    ##*===============================================
    ##* END SCRIPT BODY
    ##*===============================================

    ## Call the Exit-Script function to perform final cleanup operations
    Exit-Script -ExitCode $mainExitCode
}
Catch {
    [int32]$mainExitCode = 60001
    [string]$mainErrorMessage = "$(Resolve-Error)"
    Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
    Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
    Exit-Script -ExitCode $mainExitCode
}
