<powershell>
# Set known local Administrator password via EC2Launch
Set-ItemProperty -Path "HKLM:\SOFTWARE\Amazon\Ec2Launch\Settings" -Name "Password" -Value "Set"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Amazon\Ec2Launch\Settings" -Name "Random" -Value 0
Set-LocalUser -Name "Administrator" -Password (ConvertTo-SecureString "${local_admin_password}" -AsPlainText -Force)

# Enable WinRM (HTTP for lab)
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Enable-PSRemoting -Force
</powershell>