<powershell>
# Set known local Administrator password via EC2Launch
Set-ItemProperty -Path "HKLM:\SOFTWARE\Amazon\Ec2Launch\Settings" -Name "Password" -Value "Set"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Amazon\Ec2Launch\Settings" -Name "Random" -Value 0
Set-LocalUser -Name "Administrator" -Password (ConvertTo-SecureString "${local_admin_password}" -AsPlainText -Force)

# Enable WinRM (HTTP for lab env)
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Enable-PSRemoting -Force

# Create script directory and logs
New-Item -ItemType Directory -Path "C:\Scripts"
New-Item -ItemType Directory -Path "C:\Scripts\Logs"

# Decode and write scripts from base64
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("${rename_join_script_b64}")) | Set-Content -Path "C:\Scripts\rename_and_domain_join.ps1"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("${register_script_b64}"))    | Set-Content -Path "C:\Scripts\register_connector.ps1"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("${init_script_b64}"))        | Set-Content -Path "C:\Scripts\init.ps1"

# Register scheduled task to ensure init.ps1 runs at reboot
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Scripts\init.ps1"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName "RunInitScript" -Force

# Start init script now
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File C:\Scripts\init.ps1"
</powershell>
