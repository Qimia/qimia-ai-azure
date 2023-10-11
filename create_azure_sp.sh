#!/bin/bash
set -e
die () {
    echo >&2 "$@"
    exit 1
}
[ "$#" -eq 2 ] || die "2 arguments required (subscription id and resource group name), $# provided"
subscription_id=$1
resource_group_name=$2

appId=$(az ad app create --display-name gitlab-qimia-ai-dev --query appId -otsv)

objectId=$(az ad app show --id $appId --query id -otsv)

declare -a branches=("dev" "main")

## now loop through the above array
for branch in "${branches[@]}"
do
  cat <<EOF > fedIdCreds.json
  {
    "name": "gitlab-$branch",
    "issuer": "https://gitlab.com",
    "subject": "project_path:qimiaio/qimia-ai-dev/infra/azure_terraform:ref_type:branch:ref:$branch",
    "description": "GitLab service account federated identity for the main branch",
    "audiences": [
      "https://gitlab.com"
    ]
  }
EOF
  echo branch: $branch
  az rest --method DELETE --uri "https://graph.microsoft.com/beta/applications/$objectId/federatedIdentityCredentials/gitlab-$branch" || true
  az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$objectId/federatedIdentityCredentials" --body @fedIdCreds.json
  rm fedIdCreds.json
done

resource_group_id="/subscriptions/$subscription_id/resourceGroups/$resource_group_name"


az role assignment create \
 --role "Contributor"\
 --assignee $appId\
 --scope "$resource_group_id"

az role assignment create \
 --role "Key Vault Administrator"\
 --assignee $appId\
 --scope "$resource_group_id"
