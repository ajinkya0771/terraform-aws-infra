🌩️ Terraform AWS Infrastructure Project — EC2 + RDS + Nginx (Final Version)

This project demonstrates an end-to-end AWS Infrastructure automation using Terraform, deploying:

A secure EC2 instance (Ubuntu)

A managed RDS MySQL database

A running Nginx web server displaying a simple web page

It’s a production-style setup showing Infrastructure as Code (IaC) with modular Terraform components.

🧱 Project Architecture
        ┌────────────────────┐
        │      VPC           │
        │ ┌───────────────┐  │
        │ │ Public Subnet │──┼──> EC2 Instance (Nginx)
        │ └───────────────┘  │
        │ ┌───────────────┐  │
        │ │ Private Subnet│──┼──> RDS MySQL Database
        │ └───────────────┘  │
        └────────────────────┘

🧩 Key Terraform Files
File	Description
main.tf	Core infrastructure resources (EC2, RDS, networking)
variables.tf	Input variables for modular configuration
outputs.tf	Exposed outputs like web_public_ip and rds_endpoint
provider.tf	AWS provider configuration
terraform.tfvars	Variable values (region, instance type, etc.)
screenshots/	Execution proof with Terraform CLI logs and web output
⚙️ Terraform Workflow Commands
# Initialize Terraform environment
terraform init

# Validate configuration
terraform validate

# Preview the deployment plan
terraform plan -out=tfplan

# Apply and create AWS resources
terraform apply "tfplan"

# Destroy resources (optional cleanup)
terraform destroy

🖼️ Screenshots (Execution Proof)
Step	Screenshot
AWS Configure Identity	screenshots/00_aws_configure_identity.png
Terraform Init	screenshots/01_terraform_init_success.png
Terraform Validate	screenshots/Terraform validate success.png
Terraform Plan	screenshots/02_terraform_plan.png
Terraform Apply Complete	screenshots/03_terraform_apply_complete.png
Final Web Page (Nginx Output)	screenshots/final_web_page.png
🧠 Key Learnings

Provisioning multi-tier AWS infrastructure using Terraform IaC

Managing Terraform state, plans, and outputs effectively

Understanding provider plugins and modular configuration

Automating server setup with Nginx on EC2

Using RDS for secure database hosting

🧾 Author

Ajinkya Dhote
Cloud & DevOps Engineer | AWS + Terraform + CI/CD
🔗 GitHub Profile

🌐 Tags

#Terraform #AWS #InfrastructureAsCode #DevOps #Nginx #RDS #EC2