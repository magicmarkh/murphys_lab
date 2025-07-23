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

# Decode and write connector registration script
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("${register_script_b64}")) | Set-Content -Path "C:\Scripts\register_connector.ps1"
</powershell>
