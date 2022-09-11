#!/bin/bash

source config.sh

echo "Setting subscription to $subscription_id"
az account set -s $subscription_id

echo "Creating RG $rg"
az group create --name $rg --location $region -o none

echo "Creating NSG for VM $vm_name"
az network nsg create -g $rg -n $nsg_name -o none

echo "Creating NSG rule for arc VM on alternative ssh port: $ssh_port"
az network nsg rule create -g $rg --nsg-name $nsg_name -n ssh_alternative --priority 200 --source-address-prefixes '*' --destination-port-ranges $ssh_port --access Allow --protocol Tcp --description "Allow ssh on ports $ssh_port" -o none

echo "Creating VM $vm_name"
az vm create -g $rg --name $vm_name --image UbuntuLTS --size $vm_size \
  --public-ip-sku Standard --nsg $nsg_name \
  --admin-username $user_name --ssh-key-value $public_key_file -o none

echo "Changing VM SSH daemon from port 22 to port $ssh_port for avoiding issues with AzPolicies"
az vm run-command invoke -g $rg --name $vm_name --command-id RunShellScript --scripts "sed -i 's/#Port 22/Port 22222/' /etc/ssh/sshd_config; systemctl restart sshd" -o none

echo "Creating storage account $storage_account_name_for_installers"
az storage account create -n $storage_account_name_for_installers -g $rg --location $region -o none

echo "Creating container $storage_account_container_name_for_installers in storage account $storage_account_name_for_installers"
az storage container create -n $storage_account_container_name_for_installers --account-name $storage_account_name_for_installers --public-access blob -o none 2> /dev/null