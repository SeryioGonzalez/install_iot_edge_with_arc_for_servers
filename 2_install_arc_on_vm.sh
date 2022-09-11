#!/bin/bash

source config.sh

echo "Setting subscription to $subscription_id"
az account set -s $subscription_id

echo "Deleting existing public key identities for VM $vm_name"
ssh-keygen -q -f "/home/$user_name/.ssh/known_hosts" -R "$vm_name" > /dev/null

echo "WARNING - We need to disable azure capabilites for installing ARC on an Azure VM"
echo "WARNING - From now on, we cannot keep using azure vm run-command, since the VM will be 'de-Azurized'. This is just a demo"

echo "Getting VM public IP for SSH/SCP access"
VM_PUBLIC_IP=$(az vm list-ip-addresses -g $rg --name $vm_name --query "[].virtualMachine.network.publicIpAddresses[].ipAddress" -o tsv)

echo "Shutting down walinuxagent"
ssh -p $ssh_port -o 'StrictHostKeyChecking no' $VM_PUBLIC_IP "sudo systemctl stop walinuxagent.service; sudo systemctl disable walinuxagent.service" && echo "Succedeed"

echo "Blocking outgoing IMDS connection from VM"
ssh -p $ssh_port -o 'StrictHostKeyChecking no' $VM_PUBLIC_IP "sudo iptables -A OUTPUT -d 169.254.169.254 -j DROP" && echo "Succedeed"

echo "WARNING - At this stage, Azure Compute is not able to manage this VM anymore"

echo "Downloading ARC installation script script on target server $vm_name"
ssh -p $ssh_port -o 'StrictHostKeyChecking no' $VM_PUBLIC_IP "wget -q https://aka.ms/azcmagent -O /home/$user_name/$arc_install_script" -o none

echo "Executing ARC agent installation script on target server $vm_name"
ssh -p $ssh_port -o 'StrictHostKeyChecking no' $VM_PUBLIC_IP "sudo bash /home/$user_name/$arc_install_script > /dev/null" && echo "Succedeed"

echo "Connect to ARC with service principal"
principal_app_id=$(get_principal_name)
principal_secret=$(get_principal_secret)

set -x
ssh -p $ssh_port -o 'StrictHostKeyChecking no' $VM_PUBLIC_IP "sudo azcmagent connect -t $tenant_id -s $subscription_id -g $rg -l $region -i $principal_app_id -p \"$principal_secret\"" && echo "Succedeed"
set +x

echo "Set port for ARC lead SSH VM access"
ssh -p $ssh_port -o 'StrictHostKeyChecking no' $VM_PUBLIC_IP "sudo azcmagent config set incomingconnections.ports $ssh_port" && echo "Succedeed"

echo "Enable ARC VM endpoint on Azure ARM"
az rest --method put \
    --uri "https://management.azure.com/subscriptions/$subscription_id/resourceGroups/$rg/providers/Microsoft.HybridCompute/machines/$vm_name/providers/Microsoft.HybridConnectivity/endpoints/default?api-version=2021-10-06-preview" \
    --body '{"properties": {"type": "default"}}' -o none

echo "At this point, VM $vm_name is onboarded on ARC and with ARC SSH access enabled"