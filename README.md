# Infrastructure Genesis

In creating a software project, one needs a place to which to run it. To run it, we need to deploy it. To deploy it, we need something on which we can deploy it.

To this end, one wants infrastructure. Cloud providers make infrastructure approachable, maintainable, scalable, affordable, and manageable.

Kubernets offerings in cloud providers come with the above benefits and add standardized portability, self-management and automation.

For purposes of projects created here, [Azure Kubernetes Service (AKS)](https://azure.microsoft.com/en-us/products/kubernetes-service) will be the choice for how to run compute workloads and other Azure offerings will be used for additional resources like data management, secrets, storage, and more. [Azure Service Operator](https://azure.github.io/azure-service-operator/).

## Why

Among cloud computing providers, there are many options. They all have offerings of various flavors for the many things a software operation will want. There are many good reasons to choose one over another.

I'll be using Azure because I am most familiar with it and I am fond of how Azure Service Operator works for creating Azure Resources by using custom Kubernetes resoruces. This model makes for a minimization of the types of languages and tools one needs to know. Tools like Terraform are great for creating infrastructure and I use them frequently, but I find the approach of using custom resource definitions in Kubernetes to represent resrouces in Azure to be superior for management of infrastructure.

There are other options for this approach, including [Crossplane](https://www.crossplane.io/). Crossplane is great and if you want to be able to use a multi-cloud strategy, it's your best bet becuase of using a provider model, similar to Terraform, for suppporting multiple clouds. I want to use Azure Service Operator here, though, because it is generated from the Azure API, meaning it keeps up very well with what Azure has to offer and does not leave one at the mercy of developers to create updates or accept pull requests for supporting new features or new options on existing features.

## How

This project aims to make it easy to leverage tools to script out the use of Azure Service Operator to create Azure infrastructure.

It does this by attacking the problem of the chicken and the egg, meaning that there's a question in using Azure Service Operator to create infrastructure of how to get started. In order to use Kubernetes resources to create Azure Resources, one needs to have a Kubernetes cluster. In order to create a Kubernetes cluster when dealing with Azure, ideally, one would use Azure Kubernetes Service. But to create a cluster in Azure Kubernetes Service in order to create Azure infrastructure, one would ideally want to use Azure Service Operator in a Kubernetes cluster.

You see the problem.

The approach here is to create a lightweight cluster on the workstation, install Azure Service Operator in it, and use Azure Service Operator in that cluster to create a cluster in Azure that can then be used going forward for the creation of further resources.

## Getting Started

### Dependencies

To use the scripts in this repository, a few tools and other dependencies are necessary:

- [Powershell (Core or Windows)](https://learn.microsoft.com/en-us/powershell/)
- [Docker (likely Docker Desktop on Windows or MacOS)](https://www.docker.com/)
- [kubectl - The Kubernetes Command-Line Interface](https://kubernetes.io/docs/reference/kubectl/)
- [kind (Kubernetes in Docker)](https://kind.sigs.k8s.io/)
- [Helm](https://helm.sh/)
- [The Azure Command-Line Interface](https://learn.microsoft.com/en-us/cli/azure/)
- An Azure Account with the Azure Command-Line Interface logged into it

It's not obvious that Powershell should be necessary for such a project, given that it's far more standard and expected to use a standard POSIX-style shell. The reason the scripts in this repository use Powershell is that it's the most easily available cross-platform shell. It ships with standard Windows (in a form that is Windows-specific - typically in the form of a binary called powershell.exe) and is avaliable for install (in a cross-platform form, typically in the form of a binary called pwsh) on Windows, Linux, MacOS. So Powershell will work straightforwardly on whatever you use and it's a little less straightforward with other shells.

So the scripts here are in Powershell and therefore Powershell must be installed. They do make use of a shebang for pwsh, so in standard shells, the scripts can just be executed and will run in a Powershell Core process such that they should work transparently, as long and Powershell Core is installed and in the path on the system.

### Execution

There are two scripts in the root of this repository:

- [up.ps1](up.ps1)
- [down.ps1](down.ps1)

The former will create a cluster on the local workstation via kind, install Azure Service Operator into it, and use Azure Service Operator to create a cluster in Azure using Azure Kubernetes Service. The latter will tear down all of the resources created by the former.
