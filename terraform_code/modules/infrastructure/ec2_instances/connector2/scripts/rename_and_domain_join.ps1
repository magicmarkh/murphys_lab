$ErrorActionPreference = 'Stop'

$logPath = "C:\Scripts\Logs"
if (-not (Test-Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force
}
$scriptName = $MyInvocation.MyCommand.Name
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
Start-Transcript -Path "$logPath\$scriptName-$timestamp.log" -Append

$hostname   = "${hostname}"
$region     = "${region}"
$secretArn  = "${domain_join_secret_arn}"
$domainName = "${domain_name}"

try {
    Write-Host "Renaming computer to $hostname..."
    Rename-Computer -NewName $hostname -Force

    Write-Host "Retrieving domain join credentials from Secrets Manager..."
    $secretJson = (Get-SECSecretValue -SecretId $secretArn -Region $region).SecretString | ConvertFrom-Json
    $username = $secretJson.username
    $password = $secretJson.password | ConvertTo-SecureString -AsPlainText -Force
    $creds = New-Object System.Management.Automation.PSCredential($username, $password)

    Write-Host "Joining domain $domainName..."
    Add-Computer -DomainName $domainName -Credential $creds -Restart
} catch {
    Write-Error "Domain join failed: $_"
    throw
}

Stop-Transcript
