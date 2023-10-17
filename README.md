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
## Locally with a User account
The user or service principal to deploy this code needs `Contributor` and `Key Vault Administrator` access on the Resource Group. 
Right now only `dev` environment is supported and consists of several steps:
1. Install terraform v1.6.0 from the terraform
   - Or install `tfenv`, and then run `tfenv use 1.6.0` which will automatically download the version 1.6.0 and will be active for the rest of the terminal session.
2. Generate or reuse an SSH key pair.
   Put the public and private key pair as  [qimia-ai](qimia-ai) and [qimia-ai.pub](qimia-ai.pub) in the project root.
   3. Create a file called `<ENV>.tfvars` under [infrastructure](infrastructure). Append the following options to it as follows.
      1. The resources need to be created under a Virtual Network. 
         1. If you want to use an existing VNet, you can If you want to create a new Virtual Network add the following lines to the file
            ```hcl
            create_vnet = 0
            vnet_name = "<YOUR_EXISTING_VNET_NAME>" # Put the name of your existing VNet
            ```
         2. You can also create a new VNet for yourself, you can either set these values yourself as below or not set the values at all as they have default values already.
            ```hcl
            create_vnet = 1 
            vnet_name = "qimia-ai" # You can give any name
            vnet_cidr = "10.0.0.0/16"
            ```
      2. Subnet creation is also optional but recommended as otherwise you'd need to create the subnets externally and provide the names
         1. If you want to create the subnets with this repo, then you can add these lines. These are default values and you don't have to define them if you don't want to make changes.
            ```hcl
            create_subnet=1  # Set to 0 if you already created them manually
            # The values below are optional and have default values
            db_subnet = "10.0.129.0/24"  # Optional, and you can give any CIDR.
            db_subnet_name = "database"  # You can give any name. If you want to use existing subnets, give its name instead.
            public_subnet = "10.0.1.0/24"  # You can give any CIDR. If you want to use existing subnets, this parameter is ineffective
            public_subnet_name = "public"  # You can give any name. If you want to use existing subnets, give its name instead.
            private_subnet = "10.0.128.0/24"  # You can give any CIDR. If you want to use existing subnets, this parameter is ineffective
            private_subnet_name = "private"  # You can give any name. If you want to use existing subnets, give its name instead.
            ```
         2. If you already externally created the subnets:
            ```hcl
            create_subnet=0
            db_subnet_name="<YOUR_DATABASE_SUBNET_NAME>"
            private_subnet_name="<YOUR_PRIVATE_SUBNET_NAME>"
            public_subnet_name="<YOUR_PUBLIC_SUBNET_NAME>"
            ```
1. Make a plan of the changes to the infrastructure:
    ```bash
   sh ci_cd/plan.sh <ENV> infrastructure <RESOURCE_GROUP_NAME> <STORAGE_ACCOUNT_NAME>
   ```
   This will print a list of changes to be made by Terraform. In place of `<ENV>` you can put any one of the environment names `dev`, `preprod`, `prod`. At the moment only `dev` is tested and works.
   If the resources to be created are fine, you can skip to the next step.
2. The previous step has created some plan file which is then used by this step to apply the changes.
   Run
   ```bash
   sh ci_cd/deploy.sh dev infrastructure <RESOURCE_GROUP_NAME> <STORAGE_ACCOUNT_NAME>
   ```
   If the changes are applied successfully, Terraform will exit with a successful message.
   In addition, you'll get the name of the Key Vault created by terraform. 
   As the name has to be globally unique, you will get the   
3. This step is only necessary for the initial deployment of the Terraform stack and when updating the Email credentials.
   In a future version, this file will be moved to the backend deployment.
   Create a file called .manual-secrets-config in the root of this project. 
   This file is added in the [.gitignore](.gitignore) so that it's not added to git at all.
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

## Gitlab CI (Optional but recommended)
The proper way to deploy the infrastructure is to use a CI pipeline such as Gitlab CI.

### Creation of an Azure Service Principal
In order to allow the Gitlab CI pipeline to deploy resources a Service principal needs to be created.
Simply run the following command to create a service principal
```bash
./create_azure_sp.sh <SUBSCRIPTION_ID> <RESOURCE_GROUP_NAME> <SERVICE_PRINCIPAL_NAME>
```
In order to deploy, the following CI Variables need to be set on the repo level, ideally environment specific:
* AZURE_CLIENT_ID: The UUID of the service principal
* AZURE_SUBSCRIPTION_ID: The subscription
* AZURE_TENANT_ID: The Microsoft Entra ID's Tenant ID.
* DEVOPS_STORAGE_ACCOUNT_NAME: The storage account name
* TF_VAR_create_vnet: 0 or 1. Only necessary if you want to use an existing VNet. If 0, then you need to provide the name of the VNet to use with the `TF_VAR_` prefix. 
* TF_VAR_create_subnet: 0 or 1. Only necessary if you want to use an existing subnet. If 0, then you need to provide the names of the subnet that you want to use with the `TF_VAR_` prefix.
* Other custom Terraform variables can be defined with `TF_VAR_<variable_name>`.
* VM_PUB_KEY: A public part of SSH key pair defined as a file.


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