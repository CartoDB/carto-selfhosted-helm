# CARTO self-hosted [Helm chart]

This repository contains the [Kubernetes Helm](https://github.com/helm/helm) chart files for CARTO Platform. Run CARTO Self Hosted in your own cloud infrastructre.

If you are looking for another installation method, please refer to [carto-selfhosted repository](https://github.com/CartoDB/carto-selfhosted).

## Installation

### Prerequisites

- Kubernetes 1.12+
- Helm 3.1.0

Currently the only Kubernetes that have been tested are EKS, GKE and AKS.

#### Setup a Kubernetes Cluster

For setting up Kubernetes on other cloud platforms or bare-metal servers refer to the Kubernetes [getting started guide](http://kubernetes.io/docs/getting-started-guides/).

#### Install Helm

Helm is a tool for managing Kubernetes charts. Charts are packages of pre-configured Kubernetes resources.

To install Helm, refer to the [Helm install guide](https://github.com/helm/helm#install) and ensure that the `helm` binary is in the `PATH` of your shell.

### Installation Steps

1. Authenticate and connect to your cluster

2. Add Carto repository to helm:

```bash
helm repo add carto-selfhosted-charts https://carto-selfhosted-charts.storage.googleapis.com
```

  Update dependecies

  ```bash
  helm repo update
  ```

3. Configure your deployment

Open the file `carto-values.yaml` that you have received and configure the needed things:

- Set your domain name in `selfHostedDomain`
- Configure [TLS certificates](#tls-certificate)
- Configure [external DBs](#external-databases)
- Configure external buckets

4. Deploy CARTO

```bash
helm install carto-selfhosted-v1 carto-selfhosted-charts/carto -f carto-values.yaml -f carto-secrets.yaml
```

5. Configure your DNS to point to the deployment:

  In GKE:

  Create an A record pointing to the IP:

  ```bash
  kubectl get svc carto-selfhosted-v1-router -o jsonpath='{.status.loadBalancer.ingress.*.ip}'
  ```
  
  In EKS:

  Create a CNAME record poiting to:

  ```bash
  kubectl get svc carto-selfhosted-v1-router -o jsonpath='{.status.loadBalancer.ingress.*.hostname}'
  ```

6. Go to the configured domain and follow the process

## Update

1. Authenticate and connect to your cluster

2. Update the helm chart:

  ```bash
  helm repo update
  ```
  
3. Update CARTO

```bash
helm upgrade carto-selfhosted-v1 carto-selfhosted-charts/carto -f carto-values.yaml -f carto-secrets.yaml
```

## Unistallation

To remove CARTO from your cluster you need to run:

```bash
helm uninstall carto-selfhosted-v1 --wait
```

If you were using the internal Postgres, to delete the data you need:

```bash
# ⚠️ This is going to delete the data of the postgres inside the cluster ⚠️
kubectl delete pvc data-carto-selfhosted-v1-postgresql-0
```

## Configuration options

### TLS Certificate

By default, CARTO deployment will generate self-signed TLS certificates. You should configure it to use your
certificates. To do so, follow these steps:
  
- Change the `routerSslAutogenerate` value to `"1"` in `carto-values.yaml`

- Create a kubernetes secret with following content:

  ```yaml
  apiVersion: v1
  kind: Secret
  metadata:
    name: tls-certificate
  type: Opaque
  data:
    tls.key: "<base64 encoded key>"
    tls.crt: "<base64 encoded certificate>"
    ca.crt: "<base64 encoded public ca file>"
  ```

  Note that the content of certs should be formatted in base64 in one line, e.g:

  ```bash
  cat certificate.crt | base64 -w0
  ```

- Then create the object in kubernetes with `kubectl apply -f <secret-tls-file> -n <namespace>`

- Finally, you have to add the following lines to `carto-secrets.yaml`:

  ```yaml
  tlsCerts:
    autoGenerate: false
    existingSecret:
      name: "tls-certificate"
      caKey: "ca.crt"
      keyKey: "tls.key"
      certKey: "tls.crt"
  ```

### External Databases

CARTO Platform needs to databases to operate, Postgres and Redis. Default option is to run with them inside the Kubernetes deployment,
but it is recommended to use a managed version, with backups, high availability, etc.

#### External Postgres

By default, Carto-Selfhosted is provisioned with a Postgresl statefulset kubernetes object. But it is recommended to use an external
managed Postges (13+) installation. To configure it you need to:

- Edit `carto-values.yaml`. Uncomment the following lines you will find:

  ```yaml
  postgresql:
    enabled: false
  ```

- Create one secret in kubernetes with the Postgres passwords:

  ```bash
  kubectl create secret generic carto-postgres-config --from-literal=carto-password=<password> --from-literal=admin-password=<password>

  ```

- Edit the `carto-secrets.yaml` adding something like this to configure Postgres IP/hostname:

  ```yaml
  externalDatabase:
    host: <Postgres IP/Hostname>
    user: carto
    password: ""
    adminUser: postgres
    adminPassword: ""
    existingSecret: "carto-postgres-config"
    existingSecretPasswordKey: "carto-password"
    existingSecretAdminPasswordKey: "admin-password"
    database: workspace_db
    port: 5432
  ```

- Note: `carto` user and `workspace_db` database inside the Postgres instance are going to be created automatically
  during the installation process, they do not need to be pre-created. The `carto-password` indicated in the kubernetes
  secret created before is with which this user will be created

#### External Redis

By default, CARTO is provisioned with a Redis statefulset kubernetes object, but you could connect this environment
with your own Cloud Redis instance, follow this steps to make it possible:

- Edit `carto-values.yaml`. Uncomment the following lines you will find:

  ```yaml
  redis:
    enabled: false
  ```

- Create one secret in kubernetes with the Redis AUTH string:

  ```bash
  kubectl create secret generic carto-redis-config --from-literal=password=<AUTH string password>
  ```

- Edit the `carto-secrets.yaml` adding something like this to configure Redis IP/hostname:

  ```yaml
  externalRedis:
    host: <Redis IP/Hostname>
    port: 6379
    password: ""
    existingSecret: "carto-redis-config"
    existingSecretPasswordKey: "password"
  ```

## Before you begin

### Prerequisites

- Kubernetes 1.12+
- Helm 3.1.0
- (Optional) PV provisioner support in the underlying infrastructure. Required only for non-production deployment without external and managed databases (Postgres and Redis).

### Setup a Kubernetes Cluster

For setting up Kubernetes on other cloud platforms or bare-metal servers refer to the Kubernetes [getting started guide](http://kubernetes.io/docs/getting-started-guides/).

### Install Helm

Helm is a tool for managing Kubernetes charts. Charts are packages of pre-configured Kubernetes resources.

To install Helm, refer to the [Helm install guide](https://github.com/helm/helm#install) and ensure that the `helm` binary is in the `PATH` of your shell.



## Installation

### Basic installation

1. Obtain the configuration files provided by Carto.
That files are unique per self-hosted (**couldn't be shared between multiple installations**) and one could be public but the other one is private so please, be careful sharing it.

2. Add our Carto helm repository with the next commands:
```bash
# Add the carto-selfhosted repo.
helm repo add carto-selfhosted https://carto-selfhosted-charts.storage.googleapis.com

# Retrieve the latests version of the packages. REQUIRED before update to a new version.
helm repo update

# List the available versions of the package
helm search repo carto-selfhosted -l
```

3. Configure your deployment. ¡¡ PENDING !!

4. Install your deployment:
```bash
helm install <your_release_name> carto-selfhosted/carto --namespace <your_namespace> -f carto-values.yaml -f carto-secrets.yaml <other_custom_files>
```

5. Follow the instructions provided by the command.

## Uninstall

```bash
helm uninstall carto-selfhosted-v1 --wait

# ⚠️ This is going to delete the data of the postgres inside the cluster ⚠️
kubectl delete pvc data-carto-selfhosted-v1-postgresql-0
```
