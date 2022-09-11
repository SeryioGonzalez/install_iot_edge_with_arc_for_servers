#!/bin/bash

source config.sh

echo "Setting subscription to $subscription_id"
az account set -s $subscription_id

echo "Deleting existing public key identities for VM $vm_name"
ssh-keygen -q -f "/home/$user_name/.ssh/known_hosts" -R "$vm_name" > /dev/null

echo "This script uses Azure ARC-enabled server capabilities"
echo "Pushing IoT Edge installer to $vm_name"
push_file_to_arc_vm $iot_edge_install_script

echo "Running IoT Edge installation script"
arc_ssh "iotedge version || sudo bash /home/$user_name/$iot_edge_install_script" && echo "Succedeed"

echo "Configure AzIoT Hub connection string"
if [ "  "$az_iot_hub_connection_string = "  " ]
then
    echo "ERROR: IoT Edge connection string variable is empty"
    echo "ERROR: Define variable az_iot_hub_connection_string"
    exit 1
fi
arc_ssh "sudo iotedge config mp --force --connection-string \"$az_iot_hub_connection_string\"; sudo iotedge config apply" && echo "Succedeed"