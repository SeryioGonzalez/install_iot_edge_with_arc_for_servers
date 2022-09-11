#!/bin/bash

subscription_id=$AZURE_SUBSCRIPTION_ID_TEST
tenant_id=$AZURE_TENANT_ID

public_key_file=$PUBLIC_KEY_FILE
private_key_file=$PRIVATE_KEY_FILE

environment_name="sergioarc"
user_name="sergio"

rg=$environment_name"rg"

az_iot_hub_connection_string=$AZURE_IOT_EDGE_CONNECTION_STRING

region="westeurope"
vm_name="arcvm"
vm_size="Standard_DS2"

nsg_name=$vm_name"nsg"
ssh_port="22222"

arc_install_script="install_linux_azcmagent.sh"
iot_edge_install_script="install_iot_edge.sh"

arc_connected_k8s_cluster_name=$environment_name"-az-arc-k8s-cluster"

storage_account_name_for_installers=$environment_name"blobs"
storage_account_container_name_for_installers="installers"

az_arc_onboarding_principal_name="az_arc_onboarding_principal"
az_arc_onboarding_principal_file=".az_arc_onboarding_principal.json"
az_arc_onboarding_principal_rbac_role="Contributor"

az_iot_hub_connection_string=$AZURE_IOT_EDGE_CONNECTION_STRING

function arc_ssh {
    az ssh arc --resource-group $rg --vm-name $vm_name --port $ssh_port --private-key-file $PRIVATE_KEY_FILE --local-user $user_name -- -A -o StrictHostKeyChecking=no "$1"
}

function push_file_to_blob {
    az storage blob upload -f $1 --account-name $storage_account_name_for_installers -c $storage_account_container_name_for_installers -n $1 -o none 2> /dev/null
}

function get_blob_link {
    echo "https://$storage_account_name_for_installers.blob.core.windows.net/$storage_account_container_name_for_installers/$1"
}

function push_file_to_arc_vm {
    push_file_to_blob $1
    arc_ssh "wget -q $(get_blob_link $1) -O /home/$user_name/$1" && echo "Succedeed"

}

function get_principal_data {
    if ! [ -f $az_arc_onboarding_principal_file ] || ! [ -s $az_arc_onboarding_principal_file ]; then
        az ad sp create-for-rbac --name $az_arc_onboarding_principal_name --role $az_arc_onboarding_principal_rbac_role --scope "/subscriptions/$subscription_id/resourceGroups/$rg" -o json > $az_arc_onboarding_principal_file  
    fi

    principal_app_id=$(jq -r ".appId"    $az_arc_onboarding_principal_file)
    principal_secret=$(jq -r ".password" $az_arc_onboarding_principal_file)

    echo "$principal_app_id $principal_secret"

}

function get_principal_name {
    principal_name=$(get_principal_data | awk '{ print $1 }')
    echo $principal_name
    exit
}

function get_principal_secret {
    principal_secret=$(get_principal_data | awk '{ print $2 }')
    echo $principal_secret
}

function check_env_variables {
    error=false

    if [ "F_F"$subscription_id = "F_F" ]; then error_message="Configure your subscription_id variable";   error=true; fi
    if [ "F_F"$tenant_id = "F_F" ];       then error_message="Configure your tenant_id variable";         error=true; fi
    if [ "F_F"$public_key_file = "F_F" ]; then error_message="Configure your public_key_file variable";   error=true; fi
    if [ "F_F"$private_key_file = "F_F" ]; then error_message="Configure your private_key_file variable"; error=true; fi

    if [ $error = true ]
    then
        echo "ERROR: $error_message"
        exit 1
    fi

}

check_env_variables