#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

function EnsureGensisCluster {
    $clusterName = "genesis"
    $clusterStatus = kind get clusters | Select-String -Pattern $clusterName
    if ($clusterStatus -eq $null) {
        kind create cluster --name $clusterName
    }
}

EnsureGensisCluster
