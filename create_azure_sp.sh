resource_group_name=$1

appId=$(az ad app create --display-name gitlab-qimia-ai-dev --query appId -otsv)
# appId=93a39f91-061c-4d9d-b57b-74971d7dfe1d
#
#az ad sp create --id $appId --query appId -otsv
#
objectId=$(az ad app show --id $appId --query id -otsv)

cat <<EOF > fedIdCreds.json
{
  "name": "gitlab-federated-identity",
  "issuer": "https://gitlab.com",
  "subject": "project_path:qimiaio/qimia-ai-dev/infra/azure_terraform:ref_type:branch:ref:feat/azure_ci",
  "description": "GitLab service account federated identity",
  "audiences": [
    "https://gitlab.com"
  ]
}
EOF
echo o $objectId
az rest --method DELETE --uri "https://graph.microsoft.com/beta/applications/$objectId/federatedIdentityCredentials/gitlab-federated-identity" || true
az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$objectId/federatedIdentityCredentials" --body @fedIdCreds.json

az role assignment create \
 --role "Contributor"\
 --assignee $appId\
 --resource-group $resource_group_name

az role assignment create \
 --role "Key Vault Administrator"\
 --assignee $appId\
 --resource-group $resource_group_name