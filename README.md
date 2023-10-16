# Creating Base Resources
The creation of the base resources is a one time thing, and it only creates the resource group.
In addition, a storage account and a container will be created inside.
You need to do this locally from the CLI script [create_base_resources.sh](create_base_resources.sh)
* Make sure Azure CLI installed on your machine
* An Azure Tenant must exist
  * login with Azure CLI
* A subscription must exist
  * change the active subscription with [https://learn.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli#change-the-active-subscription]
* Decide on a location to create the resources in for example: `germanywestcentral`
* Decide on a resource group name unique within the subscription you're going to create
* Decide on a **globally unique** storage account name
* Run the script with `./create_base_resources.sh <LOCATION> <RESOURCE_GROUP_NAME> <STORAGE_ACCOUNT_NAME>`


# Deployment
## Locally
This repo contains the Terraform code to deploy your Qimia AI infrastructure to Azure.
The configuration requires an Azure subscription and a Resource Group already created.
The user or service principal to deploy this code needs `Contributor` access on the Resource Group. 
Right now only dev environment is supported and consists of several steps:
1. Install terraform v1.5.7 from the terraform
   - Or install `tfenv`, and then run `tfenv use 1.5.7` which will automatically download the version 1.5.7 and will be active for the rest of the terminal session.
2. Generate or reuse an SSH key pair.
   Put the public and private key pair as  [qimia-ai](qimia-ai) and [qimia-ai.pub](qimia-ai.pub) in the project root.
3. Create a file called `terraform.tfvars` under [infrastructure](infrastructure).
   1. If you want to create a new Virtual Network add the following lines to the file
   ```hcl
   create_vnet = 1 # Set to 0 if you don't want to use an existing one.
   vnet_name = "qimia-ai-dev" # You can give any name. If you want to use an existing Virtual Network, give its name instead.
   vnet_cidr = "10.0.0.0/16" # Optional, ineffective if a VNet already exists.
   ```
   2. If you need to create the subnets, append the following lines to the file
   ```hcl
   create_subnet=1  # Set to 0 if created them manually
   db_subnet = var.db_subnet  # You can give any CIDR. If you want to use existing subnets, this parameter is ineffective
   db_subnet_name = var.db_subnet_name  # You can give any name. If you want to use existing subnets, give its name instead.
   public_subnet = var.public_subnet  # You can give any CIDR. If you want to use existing subnets, this parameter is ineffective
   public_subnet_name = var.public_subnet_name  # You can give any name. If you want to use existing subnets, give its name instead.
   private_subnet = var.private_subnet  # You can give any CIDR. If you want to use existing subnets, this parameter is ineffective
   private_subnet_name = var.private_subnet_name  # You can give any name. If you want to use existing subnets, give its name instead.
   ```
1. Make a plan of the changes to the infrastructure:
    ```bash
   sh ci_cd/plan.sh <ENV> infrastructure <RESOURCE_GROUP_NAME> <STORAGE_ACCOUNT_NAME>.
   ```
   This will print a list of changes to be made by Terraform. In place of `<ENV>` you can put any one of the environment names `dev`, `preprod`, `prod`. At the moment only `dev` is tested and works.
   If the resources to be created are fine, you can skip to the next step.
2. The previous step has created some plan file which is then used by this step to apply the changes.
   Run
   ```bash
   sh ci_cd/deploy.sh dev infrastructure
   ```
   If the changes are applied successfully, Terraform will exit with a successful message.


## Gitlab CI
The proper way to deploy the infrastructure is to use a CI pipeline such as Gitlab CI.
### Creation of an Azure Service Principal
In order to allow the Gitlab CI pipeline to deploy resources a Service principal needs to be created.
Simply run the following command to create a service principal
```bash
./create_azure_sp.sh <SUBSCRIPTION_ID> <RESOURCE_GROUP_NAME> <SERVICE_PRINCIPAL_NAME>
```
The following CI variables need to be defined on Gitlab






# Setting application credentials
This step is only necessary for the initial deployment of the Terraform stack and when updating the Email credentials.
In a future version, this file should be moved to the backend deployment.
   Create a file called .manual-secrets-config in the root of this project. 
   The content of this file has the email credentials for the service to send emails to customers and should look like below:
   ```bash
   EMAIL_ADDRESS="SOME_ADDRESS@SOME_DOMAIN.com"
   EMAIL_PASSWORD="<the password for the email>"
   SMTP_SEND_ADDRESS="<SMTP server send address like send.asd.com:456>"
   KEY_VAULT_NAME="<The Azure Key Vault name as created by the terraform to place the secrets in>"
   ```
   The characters `<>` need to be removed.
   Upload the secrets to Azure with `sh ci_cd/deploy-secrets.sh` 
   The secrets that are skipped inside [.manual-secrets-config](.manual-secrets-config) will **not** be overwritten. 
   Only `KEY_VAULT_NAME` is mandatory.