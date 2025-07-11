<powershell>
# Set known local Administrator password via EC2Launch
Set-ItemProperty -Path "HKLM:\SOFTWARE\Amazon\Ec2Launch\Settings" -Name "Password" -Value "Set"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Amazon\Ec2Launch\Settings" -Name "Random" -Value 0
Set-LocalUser -Name "Administrator" -Password (ConvertTo-SecureString "${local_admin_password}" -AsPlainText -Force)

# Enable WinRM (HTTP for lab env)
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Enable-PSRemoting -Force

# Create script directory and write out all scripts
New-Item -ItemType Directory -Path "C:\Scripts"

Set-Content -Path "C:\Scripts\rename_and_domain_join.ps1" -Value @'
${rename_join_script}
'@

Set-Content -Path "C:\Scripts\register_connector.ps1" -Value @'
${register_script}
'@

Set-Content -Path "C:\Scripts\init.ps1" -Value @'
${init_script}
'@

# Register scheduled task to ensure init.ps1 runs at reboot
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Scripts\init.ps1"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "RunInitScript" -RunLevel Highest -Force

# Start init script now
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File C:\Scripts\init.ps1"
</powershell>
