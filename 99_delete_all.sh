#!/bin/bash

source config.sh

echo "Setting subscription to $subscription_id"
az account set -s $subscription_id

echo "Deleting RG $rg"
az group delete --name $rg -o none --no-wait -y 

#echo "Deleting SP $az_arc_onboarding_principal_name"
#az ad sp delete --id "$(jq -r '.appId' $az_arc_onboarding_principal_file)"