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
    - [Post-installation checks](#post-installation-checks)
    - [Troubleshooting](#troubleshooting)
      - [Diagnosis tool](#diagnosis-tool)
  - [Update](#update)
  - [Uninstall](#uninstall)
  - [Best Practices for Disaster Recovery](#best-practices-for-disaster-recovery)
    - [General recommendations](#general-recommendations)
    - [Database failure](#database-failure)
    - [Kubernetes outage](#kubernetes-outage)
      - [Cluster Replacement](#cluster-replacement)
      - [Kubernetes objects](#kubernetes-objects)

# CARTO Self Hosted [Helm chart]

This repository contains the [Kubernetes Helm](https://github.com/helm/helm) chart files for CARTO Platform. Run CARTO Self Hosted in your own cloud infrastructure.

To be able to run CARTO Self Hosted you need to have a license. [Contact CARTO](https://carto.com/request-live-demo/) to get one.

Running CARTO in your Kubernetes cluster is easy as long as you know how to manage Kubernetes. If you do not have K8's experience inside the
organization, we recommend you to use the [SaaS version](https://carto.com).

If you are looking for another installation method, please refer to [carto-selfhosted repository](https://github.com/CartoDB/carto-selfhosted).

## Installation

### Prerequisites

- Kubernetes 1.12+
- Helm 3.6.0
- Configuration and license files received from CARTO
- Internet HTTP/HTTPS access from the cluster to the [whitelisted domains list](doc/whitelisted_domains).
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

### Deployment customizations

Please, read the available [customization](customizations/README.md) options.

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

4. Configure your deployment. Please, read the available [customizations](customizations/README.md) options. At least you will need to configure the domain name.

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

### Post-installation checks

In order to verify CARTO Self Hosted was correctly installed and it's functional, we recommend performing the following checks:

1. Check the Helm installation status:
   ```bash
   helm list
   ```

2. Check all pods are up and running:
   ```bash
   kubectl get pods
   ```

3. Sign in to your Self Hosted, create a user and a new organization.

4. Go to the `Connections` page, in the left-hand menu, create a new connection to one of the available providers.

5. Go to the `Data Explorer` page, click on the `Upload` button right next to the `Connections` panel. Import a dataset from a local file.

6. Go back to the `Maps` page, and create a new map.

7. In this new map, add a new layer from a table using the connection created in step 3.

8. Create a new layer from a SQL Query to the same table. You can use a simple query like:
   ```bash
   SELECT * FROM <dataset_name.table_name> LIMIT 100;
   ```

9. Create a new layer from the dataset imported in step 4.

10. Make the map public, copy the sharing URL and open it in a new incognito window.

11. Go back to the `Maps` page, and verify your map appears there and the map thumbnail represents the latest changes you made to the map.

### Troubleshooting

[Troubleshooting section](customizations/README.md#troubleshooting)
  
:warning: On install and upgrade, before applying changes, a pre-hook will check that your customer package values use a version compatible with current helm chart. It it fails, it will dump the following message
```bash
Error: INSTALLATION FAILED: failed pre-install: job failed: BackoffLimitExceeded
```
If you see this error you can get the reason running the following command:

```bash
 kubectl logs --selector=job-name=<your_release_name>-pre-install
```

#### Diagnosis tool

If you need to open a support ticket, please execute our [carto-support-tool](tools/) to obtain all the necessary information and attach it to the ticket.

## Update

1. Authenticate and connect to your cluster

2. Update the helm chart:

  ```bash
  helm repo update
  ```

3. Download the latest customer package (containing `carto-values.yaml` and `carto-secrets.yaml` files) using [this tool](tools/carto-download-customer-package.sh).

4. Update CARTO

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

## Best Practices for Disaster Recovery

### General recommendations

Maintain an up-to-date copy of all _values files_ passed to the CARTO Helm Chart installation, we strongly recommend using a VSC (GitHub, BitBucket, etc) for this purpose. These values files contain at least

+ The `carto-secrets.yaml` file provided by CARTO
+ The `carto-values.yaml` file provided by CARTO
+ All the different `customizations.yaml` files used to customize the CARTO stack.

### Database failure

Maintain an up-to-date copy of all database objects required by the CARTO stack, including

+ The database admin user (along with its credentials)
+ The CARTO database user (together with his credentials)
+ The CARTO database schema

If you do a backup restore to a new database, remember to update your customization files with (if necessary)

+ The database connection string (host and port)
+ The database admin credentials (username and password)
+ The TLS configuration, you may need to update the SSL CA certificate

Redis state is not critical for the proper operation of the CARTO stack, so no backup is required

### Kubernetes outage

#### Cluster Replacement

+ In the case of a full cluster replacement, make sure that the new cluster meets the same resource requirements as the previous one, otherwise, some components required by the CARTO stack may not start up. 
+ If you applied any custom networking configuration in order to make the CARTO stack work remember to apply it in the new cluster if necessary.
+ Remember that CARTO stack Docker images are hosted publicly, your new cluster must be able to download those images from the Internet

#### Kubernetes objects

As a rule of thumb, you should keep a backup of all Secrets created outside the CARTO Helm Chart but referenced in it via the `.existingSecret` property, which you can find in the various customizations of the Chart, for example,

+ The external database credentials defined in `externalPostgresql.existingSecret`
+ The custom TLS certificate for the external domain, defined at `tlsCerts.existingSecret`

No additional Kubernetes Object backup is required
