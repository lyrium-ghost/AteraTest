$atera1 = 'C:\Program Files\ATERA Networks\AteraAgent\Agent\AteraAgent.exe'
$atera2 = 'C:\Program Files\ATERA Networks\AteraAgent\AteraAgent.exe'
$ateraService = Get-Service 'AteraAgent' -ErrorAction SilentlyContinue

$atera = if (Test-Path $atera1 -ErrorAction SilentlyContinue) {
    $atera1
} elseif (Test-Path $atera2 -ErrorAction SilentlyContinue) {
    $atera2
} else {
    $null
}

if($ateraService.Status -eq 'Running'){
    Write-Host "AteraAgent Service is already running."
}
else{
    Write-Host "AteraAgent Service is not running."
    if($atera){ # If AteraAgent.exe exists
        Write-Host "Atera Agent installation found."
        if($ateraService){
            Write-Host "Starting AteraAgent Service..."
            Start-Service -Name 'AteraAgent'
        }
        else {
            Write-Host "AteraAgent Service not found. Installing Service..."
            Try{
                $process = Start-Process "C:\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe" -ArgumentList "`"$atera`"" -Wait -NoNewWindow -PassThru
                Start-Service -Name 'AteraAgent'
            }
            Catch {
                Write-Host "Failed to install AteraAgent Service. Exit Code: $($process.ExitCode)."
                exit 1
            }

        }
    }
    else{
        Write-Host "AteraAgent.exe not found."
    }
}