$ErrorActionPreference = 'Stop'

$logPath = "C:\Scripts\Logs"
if (-not (Test-Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force
}
$scriptName = $MyInvocation.MyCommand.Name
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
Start-Transcript -Path "$logPath\$scriptName-$timestamp.log" -Append

$Region               = "${region}"
$SecretArn            = "${identity_secret_arn}"
$PoolName             = "${connector_pool_name}"
$CyberArkUrl          = "${cyberark_url}"
$Identity_Tenant_Id   = "${identity_tenant_id}"
$Platform_Tenant_Name = "${platform_tenant_name}"

$secretJson = (Get-SECSecretValue -SecretId $SecretArn -Region $Region).SecretString | ConvertFrom-Json
$client_id = $secretJson.client_id
$client_secret = $secretJson.client_secret

$token = (Invoke-RestMethod -Uri "https://$Identity_Tenant_Id.id.cyberark.cloud/api/oauth2/token" -Method POST -Body @{
  grant_type    = "client_credentials"
  client_id     = $client_id
  client_secret = $client_secret
}).access_token

$pools = Invoke-RestMethod -Uri "https://$Platform_Tenant_Name.connectormanagement.cyberark.cloud/api/connector-pools" -Headers @{
  Authorization = "Bearer $token"
}
$pool = $pools | Where-Object { $_.name -eq $PoolName }

$success = $false
for ($i = 0; $i -lt 5; $i++) {
    try {
        Write-Host "Attempt $($i+1): Fetching setup script..."
        $setupScriptResp = Invoke-RestMethod -Uri "https://$Platform_Tenant_Name-jit.cyberark.cloud/api/connectors/setup-script?connectorPoolId=$($pool.id)" `
          -Headers @{ Authorization = "Bearer $token" }

        Invoke-Expression $setupScriptResp.scriptContent
        $success = $true
        break
    } catch {
        Write-Warning "Attempt $($i+1) failed: $_"
        Start-Sleep -Seconds 15
    }
}

if (-not $success) {
    throw "CyberArk registration failed after multiple attempts."
}

Invoke-RestMethod -Uri "https://$Identity_Tenant_Id.id.cyberark.cloud/security/logout" `
  -Method Post -Headers @{ Authorization = "Bearer $token" } -SkipCertificateCheck

Stop-Transcript
