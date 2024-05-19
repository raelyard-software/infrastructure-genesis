#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

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

EnsureGensisCluster
EnsureCertManager
EnsureAzureServiceOperator
