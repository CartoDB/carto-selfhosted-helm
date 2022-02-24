# Helm chart and Docker compose for Carto 3

This repository contains the Helm chart files for Carto 3, ready to launch on Kubernetes using [Kubernetes Helm](https://github.com/helm/helm).

## Temp: Deploy CARTO in a self hosted environment

- Create new SelfHosted environment in https://github.com/CartoDB/carto3-onprem-customers

* Note: Set the remote onprem module branch to create-selfhosted-customer-package-k8s like in https://github.com/CartoDB/carto3-onprem-customers/blob/master/customers/alv-k8s-helm/config.hcl#L3

- Download customer package:
```bash
gcloud secrets versions access latest --secret="selfhosted-k8s-customer-package" --project="carto-tnt-onp-$ONPREM_ID" > carto-values.yaml
gcloud secrets versions access latest --secret="selfhosted-k8s-customer-package-secrets" --project="carto-tnt-onp-$ONPREM_ID" > carto-secrets.yaml
gcloud secrets versions access latest --secret="selfhosted-k8s-secret-sa-key" --project="carto-tnt-onp-$ONPREM_ID" > k8s-google-serviceaccount-secret.yaml
```
- Clone https://github.com/CartoDB/carto3-helm repository and create new branch

- Copy `carto-values.yaml` and `carto-secrets.yaml` inside charts folder

- Create the service account secret inside kubernetes
```bash
kubectl apply -f k8s-google-serviceaccount-secret.yaml --namespace=<namespace>
```
- Install Carto SelfHosted
```bash
helm dependency build
helm install carto3-selfhosted-v1 . -f carto-values.yaml -f carto-secrets.yaml
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

