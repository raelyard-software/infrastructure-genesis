#!/usr/bin/env pwsh

function TeardownGensisCluster {
    $clusterName = "genesis"
    $clusterStatus = kind get clusters | Select-String -Pattern $clusterName
    if ($clusterStatus) {
        try {
            kind delete cluster --name genesis
        }
        catch {
            # The first ateempt to delete the cluster may fail on trying to kill container - retry generally works
            kind delete cluster --name genesis
        }
    }
}

function TeardownServicePrincipal {
    $existingServicePrincipalId = az ad sp list --display-name "Genesis" | ConvertFrom-Json | Select-Object -ExpandProperty id
    $existingAppId = az ad app list --display-name "Genesis" | ConvertFrom-Json | Select-Object -ExpandProperty id
    if ($existingServicePrincipalId) {
        az ad sp delete --id $existingServicePrincipalId
    }
    if ($existingAppId) {
        az ad app delete --id $existingAppId
    }
}

TeardownServicePrincipal
TeardownGensisCluster
