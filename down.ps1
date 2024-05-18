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

TeardownGensisCluster
