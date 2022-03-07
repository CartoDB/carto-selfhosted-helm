# Helm chart and Docker compose for Carto 3

This repository contains the Helm chart files for Carto 3, ready to launch on Kubernetes using [Kubernetes Helm](https://github.com/helm/helm).

## Deploy CARTO in a self hosted environment

- Create new SelfHosted environment in [carto3-onprem-customers](https://github.com/CartoDB/carto3-onprem-customers)

- Download customer package files, they will be placed in the package folder

```bash
./tools/download_k8s_secrets.sh customers/YOUR-CUSTOMER-ID
```

- Create the service account secret inside kubernetes
```bash
kubectl apply -f k8s-google-serviceaccount-secret.yaml --namespace=<namespace>
```

- Add Carto repository to helm:

```bash
helm repo add carto3-selfhosted-charts https://carto3-selfhosted-helm-charts-repository.storage.googleapis.com
```

- Check the repositories:

```bash
helm repo list
NAME                     URL                                          
bitnami                  https://charts.bitnami.com/bitnami           
carto3-selfhosted-charts https://carto3-selfhosted-helm-charts-repository.storage.googleapis.com

helm search repo carto3-selfhosted-charts -l
NAME                             CHART VERSION   APP   VERSION   DESCRIPTION                                       
carto3-selfhosted-charts/carto   1.3.14          2022.02.10   CARTO is the world's leading Location Intellige...
carto3-selfhosted-charts/carto   0.0.1           2022.02.10   CARTO is the world's leading Location Intellige...
```

- Update repo if you have new chart versions
```bash
helm repo update
```

- Install Carto SelfHosted
```bash
helm install carto-selfhosted-v1 carto3-selfhosted-charts/carto -f carto-values.yaml -f carto-secrets.yaml
```

- Add the Kubernetes Load Balancer IP to your DNS with your Domain:

  In GKE:
  ```bash
  kubectl get svc <carto3-selfhosted-v1>-router -o jsonpath='{.status.loadBalancer.ingress.*.ip}'
  ```
  
  In EKS:
  ```bash
  nslookup $(kubectl get svc <carto3-selfhosted-v1>-router -o jsonpath='{.status.loadBalancer.ingress.*.hostname}')
  ```

## Before you begin

### Prerequisites

- Kubernetes 1.12+
- Helm 3.1.0
- PV provisioner support in the underlying infrastructure

### Setup a Kubernetes Cluster

For setting up Kubernetes on other cloud platforms or bare-metal servers refer to the Kubernetes [getting started guide](http://kubernetes.io/docs/getting-started-guides/).

### Install Docker

Docker is an open source containerization technology for building and containerizing your applications.

To install Docker, refer to the [Docker install guide](https://docs.docker.com/engine/install/).

### Install Helm

Helm is a tool for managing Kubernetes charts. Charts are packages of pre-configured Kubernetes resources.

To install Helm, refer to the [Helm install guide](https://github.com/helm/helm#install) and ensure that the `helm` binary is in the `PATH` of your shell.

