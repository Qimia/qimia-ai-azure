# Azure Terraform
This repo contains the Terraform code to deploy your Qimia AI infrastructure to Azure.
The configuration requires an Azure subscription and a Resource Group already created.
The user or service principal to deploy this code needs full access on the Resource Group. 
Right now only dev environment is supported and consists of several steps:
1. Install terraform v1.5.7 from the terraform
   - Or install `tfenv`, and then run `tfenv use 1.5.7` which will automatically download the version 1.5.7 and will be active for the rest of the terminal session.
2. Generate or reuse an SSH key pair.
   Put the public and private key pair as  [qimia-ai](qimia-ai) and [qimia-ai.pub](qimia-ai.pub) in the project root.
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
3. This step is only necessary for the initial deployment of the Terraform stack and when updating the Email credentials.
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