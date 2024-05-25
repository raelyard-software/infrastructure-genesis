#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

function CaptureAzureSubscriptionId {
    $subscriptionId = az account show --query id -o tsv
    return $subscriptionId
}

function EnsureGensisCluster {
    $clusterName = "genesis"
    $clusterStatus = kind get clusters | Select-String -Pattern $clusterName
    if ($null -eq $clusterStatus) {
        kind create cluster --name $clusterName
    }
}

function EnsureCertManager {
    $chartStatus = helm list -n cert-manager | Select-String -Pattern "cert-manager"
    if ($null -ne $chartStatus) {
        return
    }
    # check if repo already exists
    $repoStatus = helm repo list | Select-String -Pattern "jetstack"
    if ($null -eq $repoStatus) {
        helm repo add jetstack https://charts.jetstack.io
    }
    helm repo update jetstack
    helm upgrade --install cert-manager jetstack/cert-manager --create-namespace --namespace cert-manager ` --set installCRDs=true
}

function EnsureAzureServiceOperator {
    $chartStatus = helm list -n azureserviceoperator-system | Select-String -Pattern "aso2"
    if ($null -ne $chartStatus) {
        return
    }
    $repoStatus = helm repo list | Select-String -Pattern "aso2"
    if ($null -eq $repoStatus) {
        helm repo add aso2 https://raw.githubusercontent.com/Azure/azure-service-operator/main/v2/charts
    }
    helm repo update aso2
    helm upgrade --install aso2 aso2/azure-service-operator --create-namespace --namespace=azureserviceoperator-system `
        --set crdPattern='resources.azure.com/*;containerservice.azure.com/*;keyvault.azure.com/*;managedidentity.azure.com/*;eventhub.azure.com/*'
}

function EnsureServicePrincipal {
    param (
        [string]$subsciptionId
    )

    $spStatus = az ad sp list --display-name "Genesis" | Select-String -Pattern "Genesis"
    if ($null -ne $spStatus) {
        return
    }

    Write-Output "Creating Service Principal in subscription $subsciptionId"
    $sp = az ad sp create-for-rbac --name "Genesis" --role contributor --scopes "/subscriptions/$subsciptionId"
    $appId = $sp | ConvertFrom-Json | Select-Object -ExpandProperty appId
    $secret = $sp | ConvertFrom-Json | Select-Object -ExpandProperty password
}

$subsciptionId = CaptureAzureSubscriptionId
EnsureGensisCluster
EnsureCertManager
EnsureAzureServiceOperator
EnsureServicePrincipal $subsciptionId
