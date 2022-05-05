# Customizations

This file explains how to configure CARTO Self Hosted to meet your needs. In this folder you will find also
examples _yaml_ files that you can pass to `helm` to adapt CARTO Self Hosted to your needs.

## Production Ready

The default Helm configuration provided by CARTO works out of the box, but it's **not production ready**.
There are several things to prepare to make it production ready:

1. [Configure the domain](#configure-the-domain-of-your-self-hosted) that will be used.
2. [Expose service](#access-to-carto-from-outside-the-cluster) to be accessed from outside the cluster.
   - [Configure TLS termination](#configure-tls-termination-in-the-service)
3. [Use external Databases](#use-external-databases). Our recommendation is to use managed DBs with backups and so on.

Optional configurations:

- [Configure scale of the components](#components-scaling)
- [Use your own bucket to store the data](#custom-buckets) (by default, GCP CARTO buckets are used)

## How to apply the configurations

Create a dedicated [yaml](https://yaml.org/) file `customizations.yaml` for your configuration. For example, you could create a file with the next content:

```yaml
appConfigValues:
  selfHostedDomain: "my.domain.com"
# appSecrets:
#   googleMapsApiKey:
#     value: "<google-maps-api-key>"
#   # Other secrets, like buckets' configuration
```

And add the following at the end of ALL the `helm install` or `helm upgrade` command:

```bash
helm instal .. -f customizations.yaml
```

You can also override values through the command-line to `helm`. Adding the argument: `--set key=value[,key=value]`

## Available Configurations

There are several things that you can configure in you CARTO Self Hosted:

### Configure the domain of your Self Hosted

The most important step to have your CARTO Self Hosted ready to be used is to configure the domain to be used.

> ⚠️ CARTO Self Hosted is not designed to be used in the path of a URL, it needs a full domain or subdomain. ⚠️

To do this you need to [add the following customization](#how-to-apply-the-configurations):

```yaml
appConfigValues:
  selfHostedDomain: "my.domain.com"
```

Don't forget to upgrade your chart after the change.

### Access to CARTO from outside the cluster

The entry point to the CARTO Self Hosted is through the `router` Service. By default it is configured in `ClusterIP` mode. That means it's
only usable from inside the cluster. If you want to connect to your deployment with this mode, you need to use
[kubectl port-forward](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/).
But this only makes it accessible to your machine.

In order to make it accessible from the outside of the Kubernetes network, the [easiest way](#enable-and-configure-loadbalancer-mode)
is to use the `LoadBalancer` mode.

Probably you would need to [configure the HTTPS/TLS](#configure-tls-termination-in-the-service) if you are not terminating the TLS
sessions before.

#### Requirements when exposing the service

- CARTO only works with HTTPS. TLS termination can be in the application (and configure it in the helm chart) or in a load balancer prior to the application.
- The connection timeout of all incoming connections must be at least `605` seconds.
- Configure a domain pointing to the exposed service.

#### Enable and configure LoadBalancer mode

This is the easiest way of open your CARTO Self Hosted to the world. You need to change the `router` Service type to `LoadBalancer`.
You can find an [example](service_loadBalancer/config.yaml). But we have prepared also a few specifics for different Kubernetes flavours:

- [AWS EKS](service_loadBalancer/aws_eks/config.yaml)
<!--
TODO: Add the other providers
-->

#### Configure TLS termination in the service

By default, the package generates a self-signed certificate with a validity of 365 days.

> ⚠️ CARTO Self Hosted only works if the final client use HTTPS protocol. ⚠️

<!--
#### Disable internal HTTPS
TODO: Document and add the ability to do it
-->

To add your own certificate you need:

- Create a kubernetes secret with following content:

  ```bash
  kubectl create secret tls \
    -n <namespace> \
    mycarto-custom-tls-certificate \
    --cert=path/to/cert/file \
    --key=path/to/key/file
  ```

- Add the following lines to your `customizations.yaml`:

  ```yaml
  tlsCerts:
    autoGenerate: false
    existingSecret:
      name: "mycarto-custom-tls-certificate"
      keyKey: "tls.key"
      certKey: "tls.crt"
  ```

### Configure external Postgres

CARTO Self Hosted requires a Postgres (version 11+) to work. This package comes with an internal Postgres but it is **not recommended for production**. It does not have any logic for backups or any other monitoring.

This Postgres is used to store some CARTO internal metadata.

> ⚠️ This Postgres has nothing to do with the ones that the user configures and connect through CARTO workspace. ⚠️

There are alternatives on how to configure Postgres. [Set the secrets manually](#setup-postgres-creating-secrets) and point to them
from the configuration, or let the chart to create the [secrets automatically](#setup-postgres-with-automatic-secret-creation).

#### Setup Postgres creating secrets

1. Add the secret:

   ```bash
   kubectl create secret generic \
     -n <namespace> \
     mycarto-custom-postgres-secret \
     --from-literal=carto-password=<password> \
     --from-literal=admin-password=<password>
   ```

> Note: `externalPostgresql.user` and `externalPostgresql.database` inside the Postgres instance are going to be created automatically during the installation process. Do not create then manually.

2. Configure the package:
   Add the following lines to you `customizations.yaml` to connect to the external Postgres:

   ````yaml
     internalPostgresql:
       # Disable the internal Postgres
       enabled: false
     externalPostgresql:
       host: <Postgres IP/Hostname>
       user: "workspace_admin"
       adminUser: "postgres"
       existingSecret: "mycarto-custom-postgres-secret"
       existingSecretPasswordKey: "carto-password"
       existingSecretAdminPasswordKey: "admin-password"
       database: "workspace"
       port: "5432"
       sslEnabled: true
       # Only applies if your Postgresql SSL certificate it's self-signed
       # sslCA: |
       #   -----BEGIN CERTIFICATE-----
       #   ...
       #   -----END CERTIFICATE-----
     ```
   ````

#### Setup Postgres with automatic secret creation

1. Configure the package:
   Add the following lines to you `customizations.yaml` to connect to the external Postgres:

   ```yaml
   internalPostgresql:
     # Disable the internal Postgres
     enabled: false
   externalPostgresql:
     host: <Postgres IP/Hostname>
     user: "workspace_admin"
     password: ""
     adminUser: "postgres"
     adminPassword: ""
     database: "workspace"
     port: "5432"
     sslEnabled: true
     # Only applies if your Postgresql SSL certificate it's self-signed
     # sslCA: |
     #   -----BEGIN CERTIFICATE-----
     #   ...
     #   -----END CERTIFICATE-----
   ```

   > Note: One kubernetes secret is going to be created automatically during the installation process with the `externalPostgresql.password` and `externalPostgresql.adminPassword` that you set in previous lines.

#### Setup Azure Postgres

In case you are using an Azure Postgres as an external database you should add two additional parameters to the `externalPostgresql` block

- `internalUser`: it is the same as `user` but without the `@database-name` prefix required to connect to Azure Postgres
- `internalAdminUser`: it is the same as `adminUser` but without the `@database-name` prefix required to connect to Azure Postgres

```yaml
externalPostgresql:
  ...
  user: "workspace_admin@database-name"
  internalUser: "workspace_admin"
  ...
  adminUser: "postgres@database-name"
  internalAdminUser: "postgres"
  ...
```

#### Configure Postgres SSL with custom CA

By default CARTO will try to connect to your Postgresql without SSL. In case you want to connect via SSL, you can configure it via the `externalPostgresql.sslEnabled` parameter

```yaml
externalPostgresql:
  ...
  sslEnabled: true
```

> :warning: In case you are connecting to a Postgresql where the SSL certificate is selfsigned or from a custom CA you can configure it via the `externalPostgresql.sslCA` parameter

```yaml
externalPostgresql:
  ...
  sslEnabled: true
  sslCA: |
    #   -----BEGIN CERTIFICATE-----
    #   ...
    #   -----END CERTIFICATE-----
```

### Configure external Redis

CARTO Self Hosted require a Redis (version 5+) to work. This Redis instance does not need persistance as it is used as a cache.
This package comes with an internal Redis but it is not recommended for production. It does not have any logic for backups or any other monitoring.

In the same way as with Postgres, there are two alternatives regarding the secrets,
[set the secrets manually](#setup-redis-creating-secrets) and point to them from the configuration,
or let the chart to create the [secrets automatically](#setup-redis-with-automatic-secret-creation).

#### Setup Redis creating secrets

1. Add the secret:

```bash
kubectl create secret generic \
  -n <namespace> \
  mycarto-custom-redis-secret \
  --from-literal=password=<AUTH string password>
```

2. Configure the package:

Add the following lines to you `customizations.yaml` to connect to the external Postgres:

```yaml
internalRedis:
  # Disable the internal Redis
  enabled: false
externalRedis:
  host: <Redis IP/Hostname>
  port: "6379"
  existingSecret: "mycarto-custom-redis-secret"
  existingSecretPasswordKey: "password"
  tlsEnabled: true
  # Only applies if your Redis TLS certificate it's self-signed
  # tlsCA: |
  #   -----BEGIN CERTIFICATE-----
  #   ...
  #   -----END CERTIFICATE-----
```

#### Setup Redis with automatic secret creation

1. Configure the package:
   Add the following lines to you `customizations.yaml` to connect to the external Postgres:

```yaml
internalRedis:
  # Disable the internal Redis
  enabled: false
externalRedis:
  host: <Redis IP/Hostname>
  port: "6379"
  password: ""
  tlsEnabled: true
  # Only applies if your Redis TLS certificate it's self-signed
  # tlsCA: |
  #   -----BEGIN CERTIFICATE-----
  #   ...
  #   -----END CERTIFICATE-----
```

> Note: One kubernetes secret is going to be created automatically during the installation process with the `externalRedis.password` that you set in previous lines.

#### Configure Redis TLS

By default CARTO will try to connect to your Redis without TLS. In case you want to connect via TLS, you can configure it via the `externalRedis.tlsEnabled` parameter

```yaml
externalRedis:
  ...
  tlsEnabled: true
```

> :warning: In case you are connecting to a Redis where the TLS certificate is selfsigned or from a custom CA you can configure it via the `externalRedis.tlsCA` parameter

```yaml
externalRedis:
  ...
  tlsEnabled: true
  tlsCA: |
    #   -----BEGIN CERTIFICATE-----
    #   ...
    #   -----END CERTIFICATE-----
```

## Components scaling

### Autoscaling

It is recommended to enable autoscaling in your installation. This will allow the cluster to adapt dynamically to the needs of the service
and maximize the use of the resources of your cluster.

This feature is based on [Kubernetes Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) functionality.

#### Prerequisites

To enable the autoscaling feature, you need to use a cluster that has a [Metrics Server](https://github.com/kubernetes-sigs/metrics-server#readme) deployed and configured.

The Kubernetes Metrics Server collects resource metrics from the kubelets in your cluster, and exposes those metrics through the [Kubernetes API](https://kubernetes.io/docs/concepts/overview/kubernetes-api/), using an [APIService](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/apiserver-aggregation/) to add new kinds of resource that represent metric readings.

- Verify that Metrics Server is installed and returning metrics by completing the following steps:

  - Verify the installation by issuing the following command:

    ```bash
    kubectl get deploy,svc -n kube-system | egrep metrics-server
    ```

  - If Metrics Server is installed, the output is similar to the following example:

    ```bash
    deployment.extensions/metrics-server   1/1     1            1           3d4h
    service/metrics-server   ClusterIP   198.51.100.0   <none>        443/TCP         3d4h
    ```

  - Verify that Metrics Server is returning data for pods by issuing the following command:

    ```bash
    kubectl get --raw "/apis/metrics.k8s.io/v1beta1/pods"
    ```

To learn how to deploy the Metrics Server, see the [metrics-server installation guide](https://github.com/kubernetes-sigs/metrics-server#installation).

#### Enable Carto autoscaling feature

You can find an autoscaling config file example in [autoscaling config](scale_components/autoscaling.yaml). Adding it with `-f customizations/scale_components/autoscaling.yaml` the `install` or `upgrade` is enough to start using the autoscaling feature.

You can edit the file to set your own scaling needs by modifying the minimum and maximum values.

### Enable static scaling

You can set statically set the number of pods should be running. To do it, use [static scale config](scale_components/static.yaml) adding it with `-f customizations/scale_components/static.yaml` to the `install` or `upgrade` commands.

> Although we recommend the autoscaling configuration, you could choose the autoscaling feature for some components and the static configuration for the others. Remember that autoscaling override the static configuration, so if one component has both configurations, autoscaling will take precedence.

## Custom Buckets

If you want to keep as much data as possible in your infrastructure you can configure CARTO Self Hosted to use your own cloud storage. Supported storage services are:

- Google Compute Storage
- AWS S3
- Azure Storage

> :warning: You can only set one provider at a time. These buckets are used as temporary storage when importing data, for map thumbnails, and other internal data.

<!--
TODO: Add the code related to Terraform
-->

### Requirements

You need to create 3 buckets in your preferred Cloud provider

- Import Bucket
- Client Bucket
- Thumbnails Bucket

> There's no name constraints

It's mandatory to have credentials for those buckets, our supported credentials methods are

- GCP: Service Account Key
- AWS: Access Key ID and Secret Access Key
- Azure: Storage Access Key

> :warning: Those credentials should have permissions to interact (read/write) with the above buckets

### Google Compute Storage

Add the following lines to your `customizations.yaml`:

```yaml
appConfigValues:
  storageProvider: "gcp"
  importBucket: "carto-import-bucket"
  workspaceImportsBucket: "carto-client-bucket"
  workspaceThumbnailsBucket: "carto-thumbnails-bucket"
  workspaceThumbnailsPublic: false

appSecrets:
  gcpBucketsServiceAccountKey:
    value: |
      {
      <REDACTED_JSON_SERVICE_ACCOUNT>
      }
```

> `appSecrets.gcpBucketsServiceAccountKey.value` should be in plain text

### AWS S3

Add the following lines to your `customizations.yaml`:

```yaml
appConfigValues:
  storageProvider: "s3"
  importBucket: "carto-import-bucket"
  workspaceImportsBucket: "carto-client-bucket"
  workspaceThumbnailsBucket: "carto-thumbnails-bucket"
  workspaceThumbnailsPublic: false

appSecrets:
  awsAccessKeyId:
    value: "<REDACTED>"
  awsAccessKeySecret:
    value: "<REDACTED>"
```

> `appSecrets.awsAccessKeyId.value` and `appSecrets.awsAccessKeySecret.value` should be in plain text

### Azure Storage

Add the following lines to your `customizations.yaml`:

```yaml
appConfigValues:
  storageProvider: "azure-blob"
  importBucket: "carto-import-bucket"
  workspaceImportsBucket: "carto-client-bucket"
  workspaceThumbnailsBucket: "carto-thumbnails-bucket"
  workspaceThumbnailsPublic: false

appSecrets:
  azureStorageAccessKey:
    value: "<REDACTED>"
```

> `appSecrets.azureStorageAccessKey.value` should be in plain text

## Advanced configuration

If you need a more advanced configuration you can check the [full chart documentation](../chart/README.md) with all the available [parameters](../chart/README.md#parameters) or contact [support@carto.com](mailto:support@carto.com)
