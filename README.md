<!-- omit in toc -->
# Table of Contents
- [CARTO Self Hosted [Helm chart]](#carto-self-hosted-helm-chart)
  - [Installation](#installation)
    - [Prerequisites](#prerequisites)
      - [Setup a Kubernetes Cluster](#setup-a-kubernetes-cluster)
      - [Install Helm](#install-helm)
    - [Deployment options](#deployment-options)
      - [GKE Autopilot](#gke-autopilot)
      - [GKE Workload Identity](#gke-workload-identity)
    - [Deployment customizations](#deployment-customizations)
    - [Installation Steps](#installation-steps)
    - [Troubleshooting](#troubleshooting)
  - [Update](#update)
  - [Uninstall](#uninstall)

# CARTO Self Hosted [Helm chart]

This repository contains the [Kubernetes Helm](https://github.com/helm/helm) chart files for CARTO Platform. Run CARTO Self Hosted in your own cloud infrastructure.

To be able to run CARTO Self Hosted you need to have a license. [Contact CARTO](https://carto.com/request-live-demo/) to get one.

If you are looking for another installation method, please refer to [carto-selfhosted repository](https://github.com/CartoDB/carto-selfhosted).

## Installation

### Prerequisites

- Kubernetes 1.12+
- Helm 3.1.0
- Configuration and license files received from CARTO
- (Optional) PV provisioner support in the underlying infrastructure. Required only for non-production deployment without external and managed databases (Postgres and Redis).

<!--
Currently the only Kubernetes that have been tested are EKS, GKE and AKS.
-->

#### Setup a Kubernetes Cluster

For setting up Kubernetes on other cloud platforms or bare-metal servers refer to the Kubernetes [getting started guide](http://kubernetes.io/docs/getting-started-guides/).

#### Install Helm

Helm is a tool for managing Kubernetes charts. Charts are packages of pre-configured Kubernetes resources.

To install Helm, refer to the [Helm install guide](https://github.com/helm/helm#install) and ensure that the `helm` binary is in the `PATH` of your shell.

### Deployment options

#### GKE Autopilot

For GKE Autopilot cluster, please check [these](doc/gke/gke-autopilot.md) recommendations.

#### GKE Workload Identity

For GKE Workload Identity, please check [these](doc/gke/gke-workload-identity.md) instructions.

### Installation Steps

1. Authenticate and connect to your cluster

2. Obtain the configuration files provided by Carto.
These files are unique per Self Hosted (**they cannot be shared between multiple installations**) and contain secrets, be careful storing and sharing them.

3. Add CARTO helm repository:

  ```bash
  # Add the carto repo.
  helm repo add carto https://helm.carto.com

  # Retrieve the latests version of the packages. REQUIRED before update to a new version.
  helm repo update

  # List the available versions of the package
  helm search repo carto -l
  ```

4. Configure your deployment. Please, read the available [customizations](customizations/README.md) options. At least you will need
to configure the domain name.

5. Install CARTO:

  ```bash
  helm install \
    mycarto \
    carto/carto \
    --namespace <your_namespace> \
    -f carto-values.yaml \
    -f carto-secrets.yaml \
    -f customizations.yaml
  ```

  > Note: You can specify the '-f' flag multiple times. The priority will be given to the last (right-most) file specified. For example, if both `carto-values.yaml` and `customizations.yaml` contained a key called 'Test', the value set in `customizations.yaml` would take precedence. For this reason, please follow the order describe in the above example.

6. Read and follow the instructions provided by the previous command (eg: what you need to configure your DNS).

### Deployment customizations

Please, read the available [customization](customizations/README.md) options.

### Post installation checks

In order to verify CARTO Self Hosted was correctly installed and it's functional, we recommend performing the following checks:

1. Check all pods are up and running:
   ```bash
   kubectl get pods
   ```

2. Sign in to your Self Hosted, create a user and a new organization.

3. Go to the `Connections` page, in the left-hand menu, create a new connection to one of the available providers.

4. Go to the `Data Explorer` page, click on the `Upload` button right next to the `Connections` panel. Import a dataset from a local file.

5. Go back to the `Maps` page, and create a new map.

6. In this new map, add a new layer from a table using the connection created in step 3.

7. Create a new layer from a SQL Query to the same table. You can use a simple query like:
   ```bash
   SELECT * FROM <dataset_name.table_name> LIMIT 100;
   ```

8. Create a new layer from the dataset imported in step 4.

9. Make the map public, copy the sharing url and open it in a new incognito window.

10. Go back to the `Maps` page, and verify your map appears there and the map thumbnail represents the latest changes you made on the map.

### Troubleshooting
  
:warning: On install and upgrade, before applying changes, a pre-hook will check that your customer package values use a version compatible with current helm chart. It it fails, it will dump the following message
```bash
Error: INSTALLATION FAILED: failed pre-install: job failed: BackoffLimitExceeded
```
If you see this error you can get the reason running the following command:

```bash
 kubectl logs --selector=job-name=<your_release_name>-pre-install
```

## Update

1. Authenticate and connect to your cluster

2. Update the helm chart:

  ```bash
  helm repo update
  ```

3. Update CARTO

  ```bash
  helm upgrade \
    mycarto \
    carto/carto \
    --namespace <your_namespace> \
    -f carto-values.yaml \
    -f carto-secrets.yaml \
    -f customizations.yaml
  ```

## Uninstall

To remove CARTO from your cluster you need to run:

```bash
helm uninstall mycarto --wait
```

If you were using the internal Postgres, to delete the data you need:

```bash
# ⚠️ This is going to delete the data of the postgres inside the cluster ⚠️
kubectl delete pvc data-mycarto-postgresql-0
```

> In case you are running a local Postgres database (which is not recommended for Production environments), take into account that removing the docker volumes will delete the database information and your CARTO Self Hosted users information with it.