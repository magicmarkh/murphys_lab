$ErrorActionPreference = 'Stop'

$logPath = "C:\Scripts\Logs"
if (-not (Test-Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force
}
$scriptName = $MyInvocation.MyCommand.Name
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
Start-Transcript -Path "$logPath\$scriptName-$timestamp.log" -Append

if (-not (Test-Path "C:\Scripts\.domain_joined")) {
    Write-Host "Running domain join script..."
    & "C:\Scripts\rename_and_domain_join.ps1"
    New-Item -Path "C:\Scripts\.domain_joined" -ItemType File -Force
    Restart-Computer -Force
    exit
}

if (-not (Test-Path "C:\Scripts\.connector_registered")) {
    Write-Host "Registering connector with CyberArk..."
    & "C:\Scripts\register_connector.ps1"
    New-Item -Path "C:\Scripts\.connector_registered" -ItemType File -Force
}

Unregister-ScheduledTask -TaskName "RunInitScript" -Confirm:$false

Stop-Transcript
