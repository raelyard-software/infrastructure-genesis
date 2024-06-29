#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

function CaptureAzureSubscriptionId {
    $subscriptionId = az account show --query id -o tsv
    return $subscriptionId
}

function CaptureAzureTenantId {
    $tenantId = az account show --query tenantId -o tsv
    return $tenantId
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

function EnsureArgoCd {
    $chartStatus = helm list -n argocd | Select-String -Pattern "argocd"
    if ($null -ne $chartStatus) {
        return
    }
    $repoStatus = helm repo list | Select-String -Pattern "argocd"
    if ($null -eq $repoStatus) {
        helm repo add argo https://argoproj.github.io/argo-helm
    }
    helm repo update argo
    helm upgrade --install argocd argo/argo-cd --create-namespace --namespace argocd
}

function MakeServicePrincipalClusterSecret {
    param (
        [string]$subsciptionId,
        [string]$tenantId,
        [string]$appId,
        [string]$secret
    )

@"
apiVersion: v1
kind: Secret
metadata:
    name: aso-credential
    namespace: default
stringData:
    AZURE_SUBSCRIPTION_ID: "$subsciptionId"
    AZURE_TENANT_ID: "$tenantId"
    AZURE_CLIENT_ID: "$appId"
    AZURE_CLIENT_SECRET: "$secret"
"@ | kubectl apply -f -
}

function EnsureServicePrincipal {
    param (
        [string]$tenantId,
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

    MakeServicePrincipalClusterSecret $subsciptionId $tenantId $appId $secret
}

$subsciptionId = CaptureAzureSubscriptionId
$tenantId = CaptureAzureTenantId
EnsureGensisCluster
EnsureCertManager
EnsureAzureServiceOperator
EnsureArgoCd
EnsureServicePrincipal $tenantId $subsciptionId
