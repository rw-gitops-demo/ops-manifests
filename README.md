# Ops Manifests

This repository is one of a set providing a demonstration of a [GitOps](https://www.weave.works/technologies/gitops/) approach using [Argo CD](https://argo-cd.readthedocs.io/en/stable/) as the deployment tool and Kustomise for defining the Kubernetes manifests.
The full set of repositories in the demo are:
- [ops-manifests](https://github.com/rw-gitops-demo/ops-manifests) - the Kubernetes ops manifests, including Argo CD
- [app-manifests](https://github.com/rw-gitops-demo/app-manifests) - the Kubernetes application manifests
- [apples-service](https://github.com/rw-gitops-demo/apples-service) - an example Node.js application deployed via the GitOps workflow
- [bananas-service](https://github.com/rw-gitops-demo/bananas-service) - an example Node.js application with a traditional push deployment for comparison
- [gitops-scripts](https://github.com/rw-gitops-demo/gitops-scripts) - a set of scripts installed into the manifests repos as a git submodule

The purpose of this repository is to manage the ops tools for the Kubernetes cluster in each environment.
Currently, the only ops tool that is defined is Argo CD itself, but other tools such as Prometheus and Istio could also be managed here.

The repository is composed of a set of Argo CD Applications, which are a set of Custom Resource Definitions (CRDs) to instruct Argo CD where to find the Kubernetes manifests to be installed into the cluster.
The repo uses the [Argo CD app of apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/), with an `ops` application to manage the ops tools,
and an `apps` application to manage microservices defined in the [app-manifests](https://github.com/rw-gitops-demo/app-manifests) repository.

## Setting up the demo

To fully interact with the GitOps workflows provided in this demo, you will need to fork each of the repositories above to your own GitHub organisation (which are free to create).
Then replace occurrences of this organisation name, `rw-gitops-demo`, with that of your own.

The [app-manifests](https://github.com/rw-gitops-demo/app-manifests) README details further setup steps required for the GitHub action defined in that repo.
However, you may first continue to run the cluster as outlined further below.  

### Cloning this repository

This repo has a git submodule pointing to the [gitops-scripts](https://github.com/rw-gitops-demo/gitops-scripts) repo.
To clone the repo and pull the files in the module at the same time, execute:
```shell
git clone --recurse-submodules git@github.com:rw-gitops-demo/ops-manifests.git
```
You will then need to run the following to set up the git hooks:
```shell
npx husky install
```

## Running the demo

The demo can be run on a local Kubernetes cluster.
The following steps assumes using Colima as the container runtime, but alternatives could be used.

### Prerequisites

Install the Kubernetes toolchain on your local machine.
```shell
brew install docker colima kubectl kubeconform 
```
You can optionally install the Argo CD CLI, kustomize and kubeconform.
```shell
brew install argocd kustomize
```
Start a Kubernetes cluster.
```shell
colima start --kubernetes --cpu 4 --memory 8
```
Create the following namespaces in the cluster.
```shell
kubectl create namespace argocd
kubectl create namespace ops
kubectl create namespace apps
```

### Installing Argo CD

The demo utilises the [Argo CD app of apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/) so that all applications, including Argo CD itself, can be managed using a GitOps workflow.
However, this first requires that Argo CD itself is installed into the cluster in order for the cluster to understand the Argo CD CRDs.

Firstly, install Argo CD.
```shell
kubectl apply -k argo-cd/envs/dev
```
Once complete, use port forwarding to allow the Argo CD server to be accessed on port 8080.
```shell
kubectl port-forward --namespace=argocd svc/argocd-server 8080:443
```
Next, retrieve the admin password for Argo CD.
```shell
kubectl get secret --namespace=argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
Open a browser tab to http://localhost:8080/, and enter the above password with `admin` as the username.

With Argo CD installed and accessible, the final step is to install the `dev` environment manifests.
```shell
kubectl apply -k ops/envs/dev
```
This will install the `ops` app in the app of apps pattern and deploy all child applications.
The deployments can be monitored in Argo CD.
The cluster is now ready to be managed using a GitOps workflow!
Argo CD will poll both this repository and the [apps-manifests](https://github.com/rw-gitops-demo/apps-manifests) repository every three minutes and sync any changes that have been committed.

### Useful commands

To see the manifests for an environment.
```shell
kustomize build ops/envs/dev
```
To validate the manifests for all environments.
```shell
make validate
```
To see the diff between the local branch and `origin/main`.
```shell
make diff
```

## References

This demo was bootstrapped using the approach outlined in [this blog post](https://www.arthurkoziel.com/setting-up-argocd-with-helm/), which uses helm to define the Kubernetes manifests.

This repository uses the "environment-per-folder" approach as described in [this blog post](https://codefresh.io/blog/how-to-model-your-gitops-environments-and-promote-releases-between-them/).
The blog post describes the advantages of this approach over the often used "environment-per-branch" approach as well as considerations for carefully propagating changes through each environment.
