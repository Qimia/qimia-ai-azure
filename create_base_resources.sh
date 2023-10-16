#!/bin/bash
set -e
die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 3 ] || die "This scripts needs to be run with three parameters. See README.md"

LOCATION=$1
RESOURCE_GROUP_NAME=$2
STORAGE_ACCOUNT_NAME=$3
echo "STORAGE_ACCOUNT_NAME $STORAGE_ACCOUNT_NAME"
az group create --location "$LOCATION" --name "$RESOURCE_GROUP_NAME"
az storage account create -n "$STORAGE_ACCOUNT_NAME" -g "$RESOURCE_GROUP_NAME" -l "$LOCATION" --sku Standard_LRS
az storage container create --name tfstate --account-name "$STORAGE_ACCOUNT_NAME"
az storage container create --name llm-foundation-models --account-name "$STORAGE_ACCOUNT_NAME"