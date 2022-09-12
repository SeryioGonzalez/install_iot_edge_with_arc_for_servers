#!/bin/bash

source config.sh

echo "Setting subscription to $subscription_id"
az account set -s $subscription_id

echo "Deleting RG $rg"
az group delete --name $rg -o none --no-wait -y 
