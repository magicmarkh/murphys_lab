# Setting Up AL2023 Terraform Automation Host

This playbook configures an Amazon Linux 2023 instance as a Terraform automation host with support for Windows host management.

## What Gets Installed

- Python 3 and pip
- Ansible
- pywinrm (for WinRM/Windows management)
- pywinrm[credssp] (for CredSSP authentication)
- boto3/botocore (AWS SDK for Python)
- Terraform (latest from HashiCorp repo)

## Usage Options

### Option 1: Setup a Remote EC2 Instance

```bash
cd ansible

ansible-playbook \
  -i '<ec2-instance-ip>,' \
  -e 'ansible_user=ec2-user' \
  --private-key=/path/to/your-key.pem \
  playbooks/setup_al2023_terraform_host.yml
```

### Option 2: Setup Localhost (if already on AL2023)

```bash
cd ansible

ansible-playbook \
  -i 'localhost,' \
  -c local \
  playbooks/setup_al2023_terraform_host.yml
```

### Option 3: Using an Inventory File

1. Copy the example inventory:
   ```bash
   cp inventory.example inventory
   ```

2. Edit `inventory` with your host details

3. Run the playbook:
   ```bash
   ansible-playbook -i inventory playbooks/setup_al2023_terraform_host.yml
   ```

## Verification

After the playbook completes, verify installations:

```bash
python3 --version
ansible --version
terraform --version
python3 -c "import winrm; print('pywinrm is installed')"
```

## Notes

- The playbook will fail if not run on Amazon Linux 2023
- Requires sudo/root access (uses `become: yes`)
- HashiCorp repository is added to install Terraform
- All Python packages are installed system-wide
