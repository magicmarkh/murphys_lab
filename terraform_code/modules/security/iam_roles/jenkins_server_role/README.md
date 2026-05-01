# Jenkins Server Role

Defines an IAM role for the Jenkins automation server. The role allows Jenkins to manage EC2 instances and access Secrets Manager for pulling credentials during build steps.

## Usage
```hcl
module "jenkins_server_role" {
  source = "./modules/security/iam_roles/jenkins_server_role"
}
```
After applying, attach the role to the Jenkins EC2 instance so it can perform deployments and automation tasks.
