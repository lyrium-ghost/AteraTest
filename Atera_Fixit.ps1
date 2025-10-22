<# Install, Upgrade or Fix Atera Agent

Check Atera Installed
YES: 
    Agent.EXE Exist > Service Running? 
        YES: Start Service 
        NO: Start Service
Remove Remains
Install Atera

#>

# FUNCTIONS AND VARIABLES

param (
    [Parameter(Mandatory=$true)]
    [string]$ateraUri
)

function Install-AteraAgent {
    $wc = New-Object System.Net.WebClient
    $downloadUrl = $ateraUri
    $installerPath = "$env:TEMP\AteraAgentSetup.msi"
    Write-Host "Downloading Atera Agent installer..."
    $wc.DownloadFile($downloadUrl, $installerPath)
    Write-Host "Installing Atera Agent..."
    $process = Start-Process "msiexec.exe" -ArgumentList "/i `"$installerPath`" /qn" -Wait -NoNewWindow -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Host "Atera Agent installed successfully."
    } else {
        Write-Host "Atera Agent installation failed with exit code $($process.ExitCode)."
    }
    Remove-Item $installerPath -Force
}

function Remove-AteraRemnants {
    $WhatToLookFor = 'Atera'
    $ClassesRootAltKey = 'HKLM:\SOFTWARE\Classes\Installer\Products\'
    Get-ChildItem $ClassesRootAltKey -Rec -EA SilentlyContinue | ForEach-Object {
    $CurrentKey = (Get-ItemProperty -Path $_.PsPath)
    If ($CurrentKey -match $WhatToLookFor){
    $CurrentKey|Remove-Item -Force
    }
    }

    $UninstallKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\'
    Get-ChildItem $UninstallKey -Rec -EA SilentlyContinue | ForEach-Object {
    $CurrentKey = (Get-ItemProperty -Path $_.PsPath)
    If ($CurrentKey -match $WhatToLookFor){
    $CurrentKey|Remove-Item -Force
    }
    }

    Stop-Service -Name "AteraAgent" -Force
    Start-Sleep -Seconds 10

    $Processes = "TicketingTray.exe", "AteraAgent.exe", "AgentPackageMonitoring.exe", "AgentPackageInformation.exe", "AgentPackageRunCommand.exe", "AgentPackageRunCommandInteractive.exe", "AgentPackageEventViewer.exe", "AgentPackageSTRemote.exe", "AgentPackageInternalPoller.exe", "AgentPackageWindowsUpdate.exe", "AgentPackageFileExplorer.exe" , "AgentPackageHeartbeat.exe", "AgentPackageNetworkDiscovery.exe", "AgentPackageProgramManagement.exe", "AgentPackageRegistryExplorer.exe", "AgentPackageServicesCommands.exe", "AgentPackageSystemTools.exe", "AgentPackageTaskManagement.exe", "AgentPackageTaskScheduler.exe", "AgentPackageUpgradeAgent.exe", "AgentPackageWebrootManager.exe", "TicketNotifications.exe ";
    $KillAllProcesses = foreach ($Process in $Processes){
    Stop-Process -Name $process -Force 
    }
    Remove-Service -Name "AteraAgent"
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "AlphaHelpdeskAgent" -Force
    Remove-Item -Path "HKCU:\Software\ATERA Networks\*" -Recurse -Force
    Remove-Item -Path "HKLM:\Software\ATERA Networks\*" -Recurse -Force
    Remove-Item -Path "C:\Program Files\ATERA Networks" -Recurse -Force
    Remove-Item -Path "C:\Program Files (x86)\ATERA Networks" -Recurse -Force
    Remove-Item -Path ($Env:Tmp, "eo.webbrowser.cache.19.0.69.0.1.1" -join "\") -Recurse -Force
    Remove-Item -Path ($ENV:Tmp, "TicketingAgentPackage" -join "\")-Recurse -Force
    Remove-Item -Path ($ENV:Tmp, "TrayIconCaching" -join "\") -Recurse -Force
    Remove-Item -Path "C:\Windows\Temp\AteraUpgradeAgentPackage" -Recurse -Force
}
function Uninstall-Atera {
    Function Get-UninstallCodes ([string]$DisplayName) {
    'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | ForEach-Object {
    Get-ChildItem -Path $_ -ErrorAction SilentlyContinue | ForEach-Object {
    If ( $(Get-ItemProperty -Path $_.PSPath -Name 'DisplayName' -ErrorAction SilentlyContinue) -and ($(Get-ItemPropertyValue -Path $_.PSPath -Name 'DisplayName' -ErrorAction SilentlyContinue) -eq $DisplayName) ) {
    $str = (Get-ItemPropertyValue -Path $_.PSPath -Name 'UninstallString')
    $UninstallCodes.Add($str.Substring(($str.Length - 37),36)) | Out-Null
    }
    }
    }
    }

    Function Get-ProductKeys ([string]$ProductName) {
    Get-ChildItem -Path 'HKCR:Installer\Products' | ForEach-Object {
    If ( $(Get-ItemProperty -Path $_.PSPath -Name 'ProductName' -ErrorAction SilentlyContinue) -and ($(Get-ItemPropertyValue -Path $_.PSPath -Name 'ProductName' -ErrorAction SilentlyContinue) -eq $ProductName) ) {
    $ProductKeys.Add($_.PSPath.Substring(($_.PSPath.Length - 32))) | Out-Null
    }
    }
    }

    Function Get-ServiceStatus ([string]$Name) { (Get-Service -Name $Name -ErrorAction SilentlyContinue).Status }

    Function Stop-RunningService ([string]$Name) {
    If ( $(Get-ServiceStatus -Name $Name) -eq "Running" ) { Write-Output "Stopping : ${Name} service" ; Stop-Service -Name $Name -Force }
    }

    Function Remove-StoppedService ([string]$Name) {
    $s = (Get-ServiceStatus -Name $Name)
    If ( $s ) {
    If ( $s -eq "Stopped" ) {
    Write-Output "Deleting : ${Name} service"
    Start-Process "sc.exe" -ArgumentList "delete ${Name}" -Wait
    }
    } Else { Write-Output "Not Found: ${Name} service" }
    }
    Function Stop-RunningProcess ([string]$Name) {
    $p = (Get-Process -Name $_ -ErrorAction SilentlyContinue)
    If ( $p ) { Write-Output "Stopping : ${Name}.exe" ; $p | Stop-Process -Force }
    Else { Write-Output "Not Found: ${Name}.exe is not running"}
    }

    Function Remove-Path ([string]$Path) {
    If ( Test-Path $Path ) {
    Write-Output "Deleting : ${Path}"
    Remove-Item $Path -Recurse -Force
    } Else { Write-Output "Not Found: ${Path}" }
    }

    Function Get-AllExeFiles ([string]$Path) {
    If ( Test-Path $Path ) {
    Get-ChildItem -Path $Path -Filter *.exe -Recurse | ForEach-Object { $ExeFiles.Add($_.BaseName) | Out-Null }
    }
    }

    # Mount HKEY_CLASSES_ROOT registry hive
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null

    #######
    # START: Information gathering
    #######

    # Get MSI package codes from the uninstall key
    $UninstallCodes = New-Object System.Collections.ArrayList
    'AteraAgent', 'Splashtop for RMM', 'Splashtop Streamer' | ForEach-Object { Get-UninstallCodes -DisplayName $_ }

    # Get product keys from the list of installed products
    $ProductKeys = New-Object System.Collections.ArrayList
    'AteraAgent', 'Splashtop for RMM', 'Splashtop Streamer' | ForEach-Object { Get-ProductKeys -ProductName $_ }

    # Define all the directories we'll need to cleanup at the end of this script
    $Directories = @(
    "${Env:ProgramFiles}\ATERA Networks",
    "${Env:ProgramFiles(x86)}\ATERA Networks",
    "${Env:ProgramFiles}\Splashtop\Splashtop Remote\Server",
    "${Env:ProgramFiles(x86)}\Splashtop\Splashtop Remote\Server",
    "${Env:ProgramFiles}\Splashtop\Splashtop Software Updater",
    "${Env:ProgramFiles(x86)}\Splashtop\Splashtop Software Updater",
    "${Env:ProgramData}\Splashtop\Splashtop Software Updater"
    )

    # Get all possible relevant exe files so we can make sure they're closed later on
    $ExeFiles = New-Object System.Collections.ArrayList
    "${Env:ProgramFiles}\ATERA Networks" | ForEach-Object { Get-AllExeFiles -Path $_ }

    # Define a list of services we need to stop and delete (if necessary)
    $ServiceList = @(
    'AteraAgent',
    'SplashtopRemoteService',
    'SSUService'
    )

    # Define a list of registry keys we'll delete
    $RegistryKeys = @(
    'HKLM:SOFTWARE\ATERA Networks',
    'HKLM:SOFTWARE\Splashtop Inc.',
    'HKLM:SOFTWARE\WOW6432Node\Splashtop Inc.'
    )

    #######
    # END: Information gathering
    #######

    # Uninstall each MSI package code in $UninstallCodes
    $UninstallCodes | ForEach-Object { Write-Output "Uninstall: ${_}" ; Start-Process "msiexec.exe" -ArgumentList "/X{${_}} /qn" -Wait }

    # Stop services if they're still running
    $ServiceList | ForEach-Object { Stop-RunningService -Name $_ }

    # Terminate all relevant processes that may still be running
    $ExeFiles.Add('reg') | Out-Null
    $ExeFiles | ForEach-Object { Stop-RunningProcess $_ }

    # Delete services if they're still present
    $ServiceList | ForEach-Object { Remove-StoppedService -Name $_ }

    # Delete products from MSI installer registry
    $ProductKeys | ForEach-Object { Remove-Path -Path "HKCR:Installer\Products\${_}" }

    # Unmount HKEY_CLASSES_ROOT registry hive
    Remove-PSDrive -Name HKCR

    # Delete registry keys
    $RegistryKeys | ForEach-Object { Remove-Path -Path $_ }

    # Delete remaining directories
    #Write-Host "Waiting for file locks to be freed" ; Start-Sleep -Seconds 4
    $Directories | ForEach-Object { Remove-Path -Path $_ }
}


$atera1 = 'C:\Program Files\ATERA Networks\AteraAgent\Agent\AteraAgent.exe'
$atera2 = 'C:\Program Files\ATERA Networks\AteraAgent\AteraAgent.exe'

$atera = if (Test-Path $atera1) {
    $atera1
} elseif (Test-Path $atera2) {
    $atera2
} else {
    $null
}
if($atera){ # If AteraAgent.exe exists
    Write-Host "Atera Agent installation found."
    if(Get-Service 'AteraAgent'){
        Start-Service -Name 'AteraAgent'
        Write-Host "Starting AteraAgent Service..."
    }
    else {
        Write-Host "AteraAgent Service not found. Installing Service..."
        Try{
            $process = Start-Process "C:\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe" -ArgumentList "`"$atera`"" -Wait -NoNewWindow -PassThru
            Start-Service -Name 'AteraAgent'
        }
        else {
            Write-Host "Failed to install AteraAgent Service. Proceeding to uninstall and reinstall Atera Agent."
            $exitCode = $process.ExitCode
            Uninstall-Atera
            Remove-AteraRemnants
            Install-AteraAgent
        }

    }
}
else{
    if(Test-Path "C:\Program Files\ATERA Networks"){
        Write-Host "Atera Agent installation found but AteraAgent.exe is missing or corrupted. Proceeding to uninstall and reinstall."
        .\Remove_Atera.ps1
        Start-Sleep -Seconds 10
    }
    else {
        Write-Host "Atera Agent not found. Proceeding to install."
    }
}