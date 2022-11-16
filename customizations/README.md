<!-- omit in toc -->

# Table of Contents

- [Table of Contents](#table-of-contents)
- [Customizations](#customizations)
  - [Production Ready](#production-ready)
  - [Custom Service Account](#custom-service-account)
  - [How to apply the configurations](#how-to-apply-the-configurations)
  - [Available Configurations](#available-configurations)
    - [Configure the domain of your Self Hosted](#configure-the-domain-of-your-self-hosted)
    - [Access to CARTO from outside the cluster](#access-to-carto-from-outside-the-cluster)
      - [Expose CARTO with the Carto Router service in `LoadBalancer` mode](#expose-carto-with-the-carto-router-service-in-loadbalancer-mode)
      - [Expose CARTO with Ingress and your own TLS certificates](#expose-carto-with-ingress-and-your-own-tls-certificates)
      - [Expose CARTO with Ingress and GCP SSL Managed Certificates](#expose-carto-with-ingress-and-gcp-ssl-managed-certificates)
    - [Configure TLS termination in the CARTO router service](#configure-tls-termination-in-the-carto-router-service)
      - [Disable internal HTTPS](#disable-internal-https)
      - [Use your own TLS certificate](#use-your-own-tls-certificate)
    - [Configure external Postgres](#configure-external-postgres)
      - [Setup Postgres creating secrets](#setup-postgres-creating-secrets)
      - [Setup Postgres with automatic secret creation](#setup-postgres-with-automatic-secret-creation)
      - [Setup Azure Postgres](#setup-azure-postgres)
      - [Setup Google Cloud SQL for Postgres with Cloud SQL Auth Proxy](#setup-google-cloud-sql-for-postgres-with-cloud-sql-auth-proxy)
      - [Configure Postgres SSL with custom CA](#configure-postgres-ssl-with-custom-ca)
    - [Configure external Redis](#configure-external-redis)
      - [Setup Redis creating secrets](#setup-redis-creating-secrets)
      - [Setup Redis with automatic secret creation](#setup-redis-with-automatic-secret-creation)
      - [Configure Redis TLS](#configure-redis-tls)
    - [Custom Buckets](#custom-buckets)
      - [Pre-requisites](#pre-requisites)
      - [Google Cloud Storage](#google-cloud-storage)
      - [AWS S3](#aws-s3)
      - [Azure Storage](#azure-storage)
    - [Enable BigQuery OAuth connections](#enable-bigquery-oauth-connections)
    - [Google Maps](#google-maps)
  - [Components scaling](#components-scaling)
    - [Autoscaling](#autoscaling)
      - [Prerequisites](#prerequisites)
      - [Enable Carto autoscaling feature](#enable-carto-autoscaling-feature)
    - [Enable static scaling](#enable-static-scaling)
  - [High Availability](#high-availability)
  - [Capacity planning](#capacity-planning)
  - [Redshift imports](#redshift-imports)
  - [Advanced configuration](#advanced-configuration)
  - [Tips for creating the customization Yaml file](#tips-for-creating-the-customization-yaml-file)
  - [Troubleshooting](#troubleshooting)
    - [Diagnosis tool](#diagnosis-tool)
    - [Ingress](#ingress)
    - [Helm upgrade fails: another operation (install/upgrade/rollback) is in progress](#helm-upgrade-fails-another-operation-installupgraderollback-is-in-progress)

# Customizations

This file explains how to configure CARTO Self Hosted to meet your needs. In this folder you will find also
examples _yaml_ files that you can pass to `helm` to adapt CARTO Self Hosted to your needs.

## Production Ready

The default Helm configuration provided by CARTO works out of the box, but it's **not production ready**.
There are several things to prepare to make it production ready:

1. [Configure the domain](#configure-the-domain-of-your-self-hosted) that will be used.
2. [Expose service](#access-to-carto-from-outside-the-cluster) to be accessed from outside the cluster.
   - [Configure TLS termination](#configure-tls-termination-in-the-service)
3. [Use external Databases](#configure-external-postgres). Our recommendation is to use managed DBs with backups and so on.

Optional configurations:

- [Configure scale of the components](#components-scaling)
- [Use your own bucket to store the data](#custom-buckets) (by default, GCP CARTO buckets are used)

## Custom Service Account

CARTO deploys a dedicated infrastructure for every self hosted installation, including a Service Account key that is required to use some of the services deployed.

If you prefer using your own GCP Service Account, please do the following prior to the Self Hosted installation:

1. Create a dedicated Service Account for the CARTO Self Hosted.
2. Contact CARTO support team and provide them the service account email.

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

> Follow [these steps](#tips-for-creating-the-customization-yaml-file) to create a well structured yaml file

And add the following at the end of ALL the `helm install` or `helm upgrade` command:

```bash
helm install .. -f customizations.yaml
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

The entry point to the CARTO Self Hosted is through the `router` Service. By default, it is configured in `ClusterIP` mode. That means it's only usable from inside the cluster. If you want to connect to your deployment with this mode, you need to use
[kubectl port-forward](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/).
But this only makes it accessible to your machine.

**Requirements when exposing the service:**

- CARTO only works with HTTPS. TLS termination can be done in the CARTO application level (Router component), or in a load balancer that gets the request before sending it back to the application.
- The connection timeout of all incoming connections must be at least `605` seconds.
- Configure a domain pointing to the exposed service.

**We recommend two ways to make your Carto application accessible from outside the Kubernetes network:**

- `LoadBalancer` mode in Carto Router Service

  This is the easiest way to open your CARTO Self Hosted to the world on cloud providers which support external load balancers. You need to change the `router` Service type to `LoadBalancer`. This provides an externally-accessible IP address that sends traffic to the correct component on your cluster nodes.

  The actual creation of the load balancer happens asynchronously, and information about the provisioned balancer is published in the Service's `.status.loadBalancer` field.

- Expose your Carto Application with an `Ingress` (**This is currently supported only for GKE**).

  Ingress exposes HTTP and HTTPS routes from outside the cluster to services within the cluster. Traffic routing is controlled by rules defined on the Ingress resource, you can find more documentation [here](https://kubernetes.io/docs/concepts/services-networking/ingress/).

  Within this option you could either use your own TLS certificates, or GCP SSL Managed Certificates.

  > :warning: if you are running a GKE cluster 1.17.6-gke.7 version or lower, please check [Cluster IP configuration](#troubleshooting)

  **Useful links**

  - [google-managed-certs](https://cloud.google.com/load-balancing/docs/ssl-certificates/google-managed-certs#caa)
  - [creating_an_ingress_with_a_google-managed_certificate](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs#creating_an_ingress_with_a_google-managed_certificate)

#### Expose CARTO with the Carto Router service in `LoadBalancer` mode

You can find an example [here](service_loadBalancer/config.yaml). Also, we have prepared a few specifics for different Kubernetes flavors, just add the config that you need in your `customizations.yaml`:

- [AWS EKS](service_loadBalancer/aws_eks/config.yaml)
- [AWS EKS](service_loadBalancer/aws_eks_tls_offloading/config.yaml) Note you need to [import your certificate in AWS ACM](https://docs.aws.amazon.com/acm/latest/userguide/import-certificate.html)
- [GCP GKE](service_loadBalancer/config.yaml)
- [AZU AKS](service_loadBalancer/azu_aks/config.yaml)

> Note that with this config a [Load Balancer](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer) resource is going to be created in your cloud provider, you can find more documentation about this kind of service [here](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer)

#### Expose CARTO with Ingress and your own TLS certificates

- [GKE Ingress example config for CARTO with custom certificates](ingress/gke/custom_cert_config.yaml)

  > :point_right: Note that you need to create the TLS secret certificate in your kubernetes cluster, you could use the following command to create it

  ```bash
  kubectl create secret tls -n <namespace> carto-tls-cert --cert=cert.crt --key=cert.key
  ```

  > :warning: The certificate created in the kubernetes tls secret should also have the chain certificates complete. If your certificate has been signed by a intermediate CA, this issuer has to be included in your ingress certificate.

#### Expose CARTO with Ingress and GCP SSL Managed Certificates

- [GKE Ingress example config for CARTO with GCP Managed Certificates](ingress/gke/gcp_managed_cert_config.yaml)

  You can configure your Ingress controller to use [Google Managed Certificates](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs) on the load balancer side.

  > :warning: The certificate and LB can take several minutes to be configured, so be patient

  **Prerequisites**

  - You must own the domain for the Ingress (the one defined at `appConfigValues.selfHostedDomain`)
  - You must have created your own [Reserved static external IP address](https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address)
  - You must create an A DNS record that relates your domain to the just created static external IP address
  - Check also [this requirements](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs#prerequisites)

  :point_right: You can easily create a static external IP address with

  ```bash
  gcloud compute addresses create my_carto_ip --global
  ```

**Troubleshooting**

Please see our [troubleshooting](#troubleshooting) section if you have problems with your ingress resource.

### Configure TLS termination in the CARTO router service

> :point_right: Do not use this configuration if you are exposing CARTO services with an Ingress

#### Disable internal HTTPS

> ⚠️ CARTO Self Hosted only works if the final client use HTTPS protocol. ⚠️

If you need to disable `HTTPS` in the Carto router, [add the following lines](#how-to-apply-the-configurations) to your `customizations.yaml`:

```yaml
tlsCerts:
  httpsEnabled: false
```

> ⚠️ Remember that CARTO only works with `HTTPS`, so if you disable this protocol in the Carto Router component you should configure it in a higher layer like a Load Balancer (service or ingress) to make the redirection from `HTTP` to `HTTPS` ⚠️

#### Use your own TLS certificate

By default, the package generates a self-signed certificate with a validity of 365 days.

If you want to add your own certificate you need:

- Create a kubernetes secret with following content:

  ```bash
  kubectl create secret tls -n <namespace> <certificate name> \
    --cert=path/to/cert/file \
    --key=path/to/key/file
  ```

- Add the following lines to your `customizations.yaml`:

  ```yaml
  tlsCerts:
    httpsEnabled: true
    autoGenerate: false
    existingSecret:
      name: "mycarto-custom-tls-certificate"
      keyKey: "tls.key"
      certKey: "tls.crt"
  ```

### Configure external Postgres

CARTO Self Hosted requires a Postgres (version 11+) to work. This package comes with an internal Postgres but it is **not recommended for production**. It does not have any logic for backups or any other monitoring.

This Postgres is used to store some CARTO internal metadata.

Here are some Terraform examples of databases created in different providers:

- [GCP Cloud SQL](https://github.com/CartoDB/carto-selfhosted/tree/master/examples/terraform/gcp/postgresql.tf).
- [AWS RDS](https://github.com/CartoDB/carto-selfhosted/tree/master/examples/terraform/aws/postgresql-rds.tf).
- [Azure Database](https://github.com/CartoDB/carto-selfhosted/tree/master/examples/terraform/azure/postgresql.tf).

> :warning: This Postgres has nothing to do with the ones that the user configures and connect through CARTO workspace.

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
   Add the following lines to your `customizations.yaml` to connect to the external Postgres:

   ```yaml
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

#### Setup Postgres with automatic secret creation

1. Configure the package:
   Add the following lines to your `customizations.yaml` to connect to the external Postgres:

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

#### Setup Google Cloud SQL for Postgres with Cloud SQL Auth Proxy

The [Cloud SQL Auth Proxy] ([https://](https://cloud.google.com/sql/docs/postgres/sql-proxy) provides secure access to your instances without a need for Authorized networks, configuring SSL or public ip.

Cloud SQL Auth Proxy will run in your cluster as a deployment with a Cluster IP service. You need a [service account](https://cloud.google.com/sql/docs/postgres/connect-admin-proxy#create-service-account) with one of the following roles:

- Cloud SQL > Cloud SQL Client
- Cloud SQL > Cloud SQL Editor
- Cloud SQL > Cloud SQL Admin

You need to provide this Service Account as a secret:

```bash
kubectl create secret generic carto-cloudsql-proxy-sa-key --from-file=service_account.json=key.json
```

Then you need the connection name of your instance.

```bash
gcloud sql instances describe [INSTANCE_NAME] | grep connectionName
```

Add the config below to your customizations.yaml file using this connection name as `<CONNECTION_NAME>`

```yaml
#####
# Configure External Postgresql with CloudSQL Auth Proxy
#
# In this example we create:
#  * A deployment with configured CloudSQL Auth Proxy
#  * A ClusterIP service to serve CloudSQL Auth Proxy
#  * External Postgresql configuration for the chart
#      - https://github.com/CartoDB/carto-selfhosted-helm/tree/main/customizations#setup-postgres-creating-secrets
#

internalPostgresql:
  # Disable the internal Postgres
  enabled: false
externalPostgresql:
  # this is the service name configured below
  host: carto-cloudsql-proxy
  # database user Will be created by Workspace Migrations
  user: "workspace_admin"
  #Admin user, postgres as default in cloud SQL
  adminUser: "postgres"
  #Secret Name that storage database credentials
  existingSecret:
    "cloudsql-secret"
    #Secret key with user password
  existingSecretPasswordKey: "carto-password"
  #Secret key with admin password
  existingSecretAdminPasswordKey: "admin-password"
  # Database name, will be created by Workspace Migrations
  database: "workspace"
  port: "5432"
  sslEnabled: false #not needed because traffic is internal and the connection is encripted from the Cloud sql proxy

# Run configured cloud sql proxy as deployment and expose intenrally on 5432 port
# REMEMBER to create the secret for your service account with Cloud SQL Client role
#    i.e kubectl create secret generic carto-cloudsql-proxy-sa-key --from-file=service_account.json=mykey.json
#  and change <CONNECTION_NAME> in the pod commands (below)

extraDeploy:
  - |
    apiVersion: {{ include "common.capabilities.deployment.apiVersion" . }}
    kind: Deployment
    metadata:
      name: carto-cloudsql-proxy
      labels: {{- include "common.labels.standard" . | nindent 4 }}
        app.kubernetes.io/component: cloudsql-proxy
        {{- if .Values.commonLabels }}
        {{- include "common.tplvalues.render" ( dict "value" .Values.commonLabels "context" $ ) | nindent 4 }}
        {{- end }}
      annotations:
        {{- if .Values.commonAnnotations }}
        {{- include "common.tplvalues.render" ( dict "value" .Values.commonAnnotations "context" $ ) | nindent 4 }}
        {{- end }}
      namespace: {{ .Release.Namespace | quote }}
    spec:
      replicas: 1
      strategy:
        type: RollingUpdate
      selector:
        matchLabels: {{- include "common.labels.matchLabels" . | nindent 6 }}
          app.kubernetes.io/component: carto-cloudsql-proxy
      template:
        metadata:
          annotations:
          labels: {{- include "common.labels.standard" . | nindent 8 }}
            app.kubernetes.io/component: carto-cloudsql-proxy
        spec:
          {{- include "carto.imagePullSecrets" . | nindent 6 }}
          securityContext:
            fsGroup: 65532
            supplementalGroups: [2345]
          containers:
            - name: carto-cloudsql-proxy
              image: gcr.io/cloudsql-docker/gce-proxy:1.27.1-alpine
              imagePullPolicy: IfNotPresent
              securityContext:
                runAsUser: 65532
                runAsGroup: 65532
                runAsNonRoot: false
                allowPrivilegeEscalation: false
                capabilities:
                  drop:
              resources:
                limits:
                  memory: "512Mi"
                  cpu: "350m"
                requests:
                  memory: "124Mi"
                  cpu: "100m"
              ports:
                - name: postgresql
                  containerPort: 5432
              readinessProbe:
                tcpSocket:
                  port: 5432
                initialDelaySeconds: 5
                periodSeconds: 10
              livenessProbe:
                tcpSocket:
                  port: 5432
                initialDelaySeconds: 15
                periodSeconds: 20
              volumeMounts:
                # GCP Service Account with Cloud SQL Client role
                - name: carto-cloudsql-proxy-sa-key
                  mountPath: "/secrets"
                  readOnly: true
              command:
                - "/cloud_sql_proxy"

                # If connecting from a VPC-native GKE cluster, you can use the
                # following flag to have the proxy connect over private IP
                - "-ip_address_types=PRIVATE"

                # By default, the proxy will write all logs to stderr. In some
                # environments, anything printed to stderr is consider an error. To
                # disable this behavior and write all logs to stdout (except errors
                # which will still go to stderr), use:
                - "-log_debug_stdout"

                # Replace <CONNECTION_NAME> with your CloudSQL connection name
                - "-instances=<CONNECTION_NAME>=tcp:0.0.0.0:5432"

                # This flag specifies where the service account key can be found
                # This volume ions mounted below with an existing secret
                - "-credential_file=/secrets/service_account.json"
          volumes:
          - name: carto-cloudsql-proxy-sa-key
            # This secret should be created
            # i.e kubectl create secret generic carto-cloudsql-proxy-sa-key --from-file=service_account.json=mykey.json
            secret:
              secretName: carto-cloudsql-proxy-sa-key
              optional: false
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: carto-cloudsql-proxy
      namespace: {{ .Release.Namespace | quote }}
      labels: {{- include "common.labels.standard" . | nindent 4 }}
        app.kubernetes.io/component: carto-cloudsql-proxy
        {{- if .Values.commonLabels }}
        {{- include "common.tplvalues.render" ( dict "value" .Values.commonLabels "context" $ ) | nindent 4 }}
        {{- end }}
      annotations:
        {{- if .Values.commonAnnotations }}
        {{- include "common.tplvalues.render" ( dict "value" .Values.commonAnnotations "context" $ ) | nindent 4 }}
        {{- end }}
    spec:
      type: ClusterIP
      ports:
      - port: 5432
        targetPort: postgresql
        protocol: TCP
        name: postgresql
      selector:
        {{- include "common.labels.matchLabels" . | nindent 4 }}
        app.kubernetes.io/component: carto-cloudsql-proxy
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

This package comes with an internal Redis but it is not recommended for production. It lacks any logic for backups or monitoring.

Here are some Terraform examples of databases created in different providers:

- [GCP Redis](https://github.com/CartoDB/carto-selfhosted/tree/master/examples/terraform/gcp/redis.tf).
- [AWS Redis](https://github.com/CartoDB/carto-selfhosted/tree/master/examples/terraform/aws/redis.tf).
- [Azure Redis](https://github.com/CartoDB/carto-selfhosted/tree/master/examples/terraform/azure/redis.tf).

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

Add the following lines to your `customizations.yaml` to connect to the external Redis:

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
   Add the following lines to your `customizations.yaml` to connect to the external Redis:

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

### Custom Buckets

For every CARTO Self Hosted installation, we create GCS buckets on our side as part of the required infrastructure for importing data, map thumbnails and customization assets (custom logos and markers).

You can create and use your own storage buckets in any of the following supported storage providers:

- Google Cloud Storage. [Terraform code example](https://github.com/CartoDB/carto-selfhosted/blob/master/examples/terraform/gcp/storage.tf).
- AWS S3. [Terraform code example](https://github.com/CartoDB/carto-selfhosted/blob/master/examples/terraform/aws/storage.tf).
- Azure Storage. [Terraform code example](https://github.com/CartoDB/carto-selfhosted/blob/master/examples/terraform/azure/storage.tf).

> :warning: You can only set one provider at a time.

#### Pre-requisites

1. Create 3 buckets in your preferred Cloud provider:
   - Import Bucket
   - Client Bucket
   - Thumbnails Bucket

   > :warning: Map thumbnails storage objects (.png files) can be configured to be `public` (default) or `private`. In order to change this, set `appConfigValues.workspaceThumbnailsPublic: "false"`. For the default configuration to work, the bucket must allow public objects/blobs. Some features, such as branding and custom markers, won't work unless the bucket is public. However, there's a workaround to avoid making the whole bucket public, which requires allowing public objects, allowing ACLs (or non-uniform permissions) and disabling server-side encryption.

   > There're no name constraints.

2. CORS configuration: Thumbnails and Import buckets require having the following CORS headers configured.
   - Allowed origins: `*`
   - Allowed methods: `GET`, `PUT`, `POST`
   - Allowed headers (common): `Content-Type`, `Content-MD5`, `Content-Disposition`, `Cache-Control`
     - GCS (extra): `x-goog-content-length-range`, `x-goog-meta-filename`
     - Azure (extra): `Access-Control-Request-Headers`, `X-MS-Blob-Type`
   - Max age: `3600`

   > CORS is configured at bucket level in GCS and S3, and at storage account level in Azure.

   > How do I setup CORS configuration? Check the provider docs: [GCS](https://cloud.google.com/storage/docs/configuring-cors), [AWS S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/enabling-cors-examples.html), [Azure Storage](https://docs.microsoft.com/en-us/rest/api/storageservices/cross-origin-resource-sharing--cors--support-for-the-azure-storage-services#enabling-cors-for-azure-storage).

3. Generate credentials with Read/Write permissions to access those buckets, our supported authentication methods are:

   - GCS: Service Account Key
   - AWS: Access Key ID and Secret Access Key
   - Azure: Access Key

#### Google Cloud Storage

In order to use Google Cloud Storage custom buckets you need to:

1. Create the buckets.

   > :warning: If you enable `Prevent public access` in the bucket properties, then set `appConfigValues.workspaceThumbnailsPublic` and `appConfigValues.workspaceImportsPublic` to `false`.

2. Configure the required [CORS settings](#pre-requisites).

3. Add the following lines to your `customizations.yaml` and replace the `<values>` with your own settings:

   ```yaml
   appConfigValues:
     storageProvider: "gcp"
     importBucket: <import_bucket_name>
     workspaceImportsBucket: <client_bucket_name>
     workspaceImportsPublic: <false|true>
     workspaceThumbnailsBucket: <thumbnails_bucket_name>
     workspaceThumbnailsPublic: <false|true>
     thumbnailsBucketExternalURL: <public or authenticated external bucket URL>
     googleCloudStorageProjectId: <gcp_project_id>
   ```

   > Note that thumbnailsBucketExternalURL could be https://storage.googleapis.com/<thumbnails_bucket_name>/ for public access or https://storage.cloud.google.com/<thumbnails_bucket_name>/ for authenticated access.

4. Select a **Service Account** that will be used by the application to interact with the buckets. There are three options:

   - using a [custom Service Account](#custom-service-account), that will be used not only for the buckets, but for the services deployed by CARTO as well. If you are using Workload Identity, that's your option.
   - using a dedicated Service Account **only for the buckets**

5. Grant the selected Service Account with the role `roles/iam.serviceAccountTokenCreator` in the GCP project where it was created.

   > :warning: We don't recommend granting this role at project IAM level, but instead at the Service Account permissions level (IAM > Service Accounts > `your_service_account` > Permissions).

6. Grant the selected Service Account with the role `roles/storage.admin` to the buckets created.

7. [OPTIONAL] Pass your GCP credentials as secrets: **This is only required if you are going to use a dedicated Service Account only for the buckets** (option 4.2).

   - **Option 1: Automatically create the secret:**

     ```yaml
     appSecrets:
       googleCloudStorageServiceAccountKey:
         value: |
           <REDACTED>
     ```

     > `appSecrets.googleCloudStorageServiceAccountKey.value` should be in plain text, preserving the multiline and correctly tabulated.

   - **Option 2: Using existing secret:**
     Create a secret running the command below, after replacing the `<PATH_TO_YOUR_SECRET.json>` value with the path to the file of the Service Account:

     ```bash
     kubectl create secret generic \
       [-n my-namespace] \
       mycarto-google-storage-service-account \
       --from-file=key=<PATH_TO_YOUR_SECRET.json>
     ```

     Add the following lines to your `customizations.yaml`, without replacing any value:

     ```yaml
     appSecrets:
       googleCloudStorageServiceAccountKey:
         existingSecret:
           name: mycarto-google-storage-service-account
           key: key
     ```

#### AWS S3

In order to use AWS S3 custom buckets you need to:

1. Create the buckets.

   > :warning: If you enable `Block public access` in the bucket properties, then set `appConfigValues.workspaceThumbnailsPublic` and `appConfigValues.workspaceImportsPublic` to `false`.

2. Configure the required [CORS settings](#pre-requisites).

3. Create an IAM user and generate a programmatic key ID and secret.

4. Grant this user with read/write access permissions over the buckets.

5. Add the following lines to your `customizations.yaml` and replace the `<values>` with your own settings:

```yaml
appConfigValues:
  storageProvider: "s3"
  importBucket: <import_bucket_name>
  workspaceImportsBucket: <client_bucket_name>
  workspaceImportsPublic: <false|true>
  workspaceThumbnailsBucket: <thumbnails_bucket_name>
  workspaceThumbnailsPublic: <false|true>
  thumbnailsBucketExternalURL: <external bucket URL>
  awsS3Region: <s3_buckets_region>
```

> Note that thumbnailsBucketExternalURL should be https://<thumbnails_bucket_name>.s3.amazonaws.com/

6. Pass your AWS credentials as secrets by using one of the options below:

   - **Option 1: Automatically create a secret:**

   Add the following lines to your `customizations.yaml` replacing it with your access key values:

   ```yaml
   appSecrets:
     awsAccessKeyId:
       value: "<REDACTED>"
     awsAccessKeySecret:
       value: "<REDACTED>"
   ```

   > `appSecrets.awsAccessKeyId.value` and `appSecrets.awsAccessKeySecret.value` should be in plain text

   - **Option 2: Using an existing secret:**
     Create a secret running the command below, after replacing the `<REDACTED>` values with your key values:

   ```bash
   kubectl create secret generic \
     [-n my-namespace] \
     mycarto-custom-s3-secret \
     --from-literal=awsAccessKeyId=<REDACTED> \
     --from-literal=awsSecretAccessKey=<REDACTED>
   ```

   > Use the same namespace where you are installing the helm chart

   Add the following lines to your `customizations.yaml`, without replacing any value:

   ```yaml
   appSecrets:
     awsAccessKeyId:
       existingSecret:
         name: mycarto-custom-s3-secret
         key: awsAccessKeyId
     awsAccessKeySecret:
       existingSecret:
         name: mycarto-custom-s3-secret
         key: awsSecretAccessKey
   ```

#### Azure Storage

In order to use Azure Storage buckets (aka containers) you need to:

1. Create an storage account if you don't have one already.

2. Configure the required [CORS settings](#pre-requisites).

3. Create the storage buckets. If you set the `Public Access Mode` to `private` in the bucket properties, make sure you set `appConfigValues.workspaceThumbnailsPublic` to `false`.

   > :warning: If you set the `Public Access Mode` to `private` in the bucket properties, then set `appConfigValues.workspaceThumbnailsPublic` and `appConfigValues.workspaceImportsPublic` to `false`.

4. Generate an Access Key, from the storage account's Security properties.

5. Add the following lines to your `customizations.yaml` and replace the `<values>` with your own settings:

```yaml
appConfigValues:
  storageProvider: "azure-blob"
  azureStorageAccount: <storage_account_name>
  importBucket: <import_bucket_name>
  workspaceImportsBucket: <client_bucket_name>
  workspaceImportsPublic: <false|true>
  workspaceThumbnailsBucket: <thumbnails_bucket_name>
  thumbnailsBucketExternalURL: <external bucket URL>
  workspaceThumbnailsPublic: <false|true>
```

> Note that thumbnailsBucketExternalURL should be https://<azure_resource_group>.blob.core.windows.net/<thumbnails_bucket_name>/

6. Pass your credentials as secrets by using one of the options below:

   - **Option 1: Automatically create the secret:**

   ```yaml
   appSecrets:
     azureStorageAccessKey:
       value: "<REDACTED>"
   ```

   > `appSecrets.azureStorageAccessKey.value` should be in plain text

   - **Option 2: Using existing secret:**
     Create a secret running the command below, after replacing the `<REDACTED>` values with your key values:

   ```bash
   kubectl create secret generic \
     [-n my-namespace] \
     mycarto-custom-azure-secret \
     --from-literal=azureStorageAccessKey=<REDACTED>
   ```

   > Use the same namespace where you are installing the helm chart

   Add the following lines to your `customizations.yaml`, without replacing any value:

   ```yaml
   appSecrets:
     awsAccessKeyId:
       existingSecret:
         name: mycarto-custom-azure-secret
         key: azureStorageAccessKey
   ```

### Enable BigQuery OAuth connections

This feature allows users to create a BigQuery connection using `Sign in with Google` instead of providing a service account key.

> :warning: Connections created with OAuth cannot be shared with other organization users.

1. Create an OAuth consent screen inside the desired GCP project:

   - Introduce an app name and a user support email.
   - Add an authorized domain (the one used in your email).
   - Add another email as dev contact info (it can be the same).
   - Add the following scopes: `./auth/userinfo.email`, `./auth/userinfo.profile` & `./auth/bigquery`.

2. Create the OAuth credentials:

   - Type: Web application.
   - Authorized JavaScript origins: `https://<your_selfhosted_domain>`.
   - Authorized redirect URIs: `https://<your_selfhosted_domain>/connections/bigquery/oauth`.
   - Download the credentials file.

3. Follow [these guidelines](https://github.com/CartoDB/carto-selfhosted-helm/blob/main/customizations/README.md#how-to-apply-the-configurations) to add the following lines to your `customizations.yaml` populating them with the credential's file corresponding values:

```yaml
appConfigValues:
  bigqueryOauth2ClientId: "<value_from_credentials_web_client_id>"

appSecrets:
  bigqueryOauth2ClientSecret:
    value: "<value_from_credentials_web_client_secret>"
```

### Google Maps

In order to enable Google Maps basemaps inside CARTO Self Hosted, you need to own a Google Maps API key and add one of the options below to your `customizations.yaml` following [these guidelines](https://github.com/CartoDB/carto-selfhosted-helm/blob/main/customizations/README.md#how-to-apply-the-configurations):

- **Option 1: Automatically create the secret:**

```yaml
appSecrets:
  googleMapsApiKey:
    value: "<REDACTED>"
```

> `appSecrets.googleMapsApiKey.value` should be in plain text

- **Option 2: Using existing secret:**
  Create a secret running the command below, after replacing the `<REDACTED>` values with your key values:

```bash
  kubectl create secret generic \
  [-n my-namespace] \
  mycarto-google-maps-api-key \
  --from-literal=googleMapsApiKey=<REDACTED>
```

Add the following lines to your `customizations.yaml`, without replacing any value:

```yaml
appSecrets:
  googleMapsApiKey:
    existingSecret:
      name: mycarto-google-maps-api-key
      key: googleMapsApiKey
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

You can set statically set the number of pods should be running. To do it, use [static scale config](scale_components/development.yaml) adding it with `-f customizations/scale_components/development.yaml` to the `install` or `upgrade` commands.

> Although we recommend the autoscaling configuration, you could choose the autoscaling feature for some components and the static configuration for the others. Remember that autoscaling override the static configuration, so if one component has both configurations, autoscaling will take precedence.

## High Availability

In some cases, you may want to ensure **some critical services have replicas deployed across different worker nodes** in order to provide high availability against a node failure. You can achieve this by applying one of the [high availability configurations](high_availability) that we recommend.

> Note that you should enable static scaling or autoscaling for this setup to work as expected.

> In order to provide high availability across regions/zones, it's recommended to deploy each worker node in a different cloud provider regions/zones.

- [Standard HA](high_availability/standard): configuration for an HA deployment
- [Standard HA with upgrades](high_availability/standard_with_upgrades): configuration for an HA deployment, taking into account application upgrades.
- [High traffic HA](high_availability/high_traffic): configuration for an HA deployment in high traffic environments.

## Capacity planning

Aligned with the [high availability configurations](high_availability), please check the required cluster resources for each of the configurations:

- [Standard HA](high_availability/standard/README.md#capacity-planning)
- [Standard HA with upgrades](high_availability/standard_with_upgrades/README.md#capacity-planning)
- [High traffic HA](high_availability/high_traffic/README.md#capacity-planning)

## Redshift imports

> :warning: This is currently a feature flag and it's disabled by default. Please, contact support if you are interested on using it.

CARTO selfhosted supports importing data to a Redshift cluster or serverless. Follow these instructions to setup your Redshift integration:

> :warning: This requires access to an AWS account and an existing accessible Redshift endpoint.

1. Create an AWS IAM user with programmatic access. Take note of the user's aren, key id and key secret.

2. Create an AWS S3 Bucket.

3. Create an AWS IAM role with the following settings:
   1. Trusted entity type: `Custom trust policy`.
   2. Custom trust policy: Make sure to replace `<your_aws_user_arn>`.
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
         {
             "Effect": "Allow",
             "Principal": {
                 "AWS": "<your_aws_user_arn>"
             },
             "Action": [
                 "sts:AssumeRole",
                 "sts:TagSession"
             ]
         }
     ]
   }
   ```
   3. Add permissions: Create a new permissions policy, replacing `<your_aws_s3_bucket_name>`.
   ```json
   {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": "s3:ListBucket",
              "Resource": "arn:aws:s3:::<your_aws_s3_bucket_name>"
          },
          {
              "Effect": "Allow",
              "Action": "s3:*Object",
              "Resource": "arn:aws:s3:::<your_aws_s3_bucket_name>/*"
          }
      ]
   }
   ```

4. Add the following lines to your `customizations.yaml` file:
```yaml
appConfigValues:
  importAwsRoleArn: "<your_aws_user_arn>"

appSecrets:
  importAwsAccessKeyId:
    value: "<your_aws_user_access_key_id>"
  importAwsSecretAccessKey:
    value: "<your_aws_user_access_key_secret>"
```

5. Perform a `helm upgrade` before continuing with the following steps.

6. Log into your CARTO selfhosted, go to `Data Explorer > Connections > Add new connection` and create a new Redshift connection.

7. Then go to `Settings > Advanced > Integrations > Redshift > New`, introduce your S3 Bucket name and region and copy the policy generated.

8. From the AWS console, go to your `S3 > Bucket > Permissions > Bucket policy` and paste the policy obtained in the previous step in the policy editor.

9. Go back to the CARTO Selfhosted (Redshift integration page) and check the `I have already added the S3 bucket policy` box and click on the `Validate and save button`.

10. Go to `Data Exporer > Import data > Redshift connection` and you should be able to import a local dataset to Redshift.

## Advanced configuration

If you need a more advanced configuration you can check the [full chart documentation](../chart/README.md) with all the available [parameters](../chart/README.md#parameters) or contact [support@carto.com](mailto:support@carto.com)

## Tips for creating the customization Yaml file

Here you can find some basic instructions in order to create the config yaml file for your environment:

- The configuration file `customizations.yaml` will be composed of keys and their value, please do not define the same key several times, because they will be overridden between them. Each key in the yaml file would have subkeys for different configurations, so all of them should be inside the root key. Example:

  ```yaml
  mapsApi:
    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 3
      targetCPUUtilizationPercentage: 75
  ```

- Check the text values of the `customizations.yaml` keys, they have to be set between quotes. Example:

  ```yaml
  appConfigValues:
    selfHostedDomain: "my.domain.com"
  ```

  Note that integers and booleans values are set without quotes.

- Once we have the config files ready, we would be able to check the values that are going to be used by the package with this command:

  ```bash
  helm template \
  mycarto \
  carto/carto \
  --namespace <your_namespace> \
  -f carto-values.yaml \
  -f carto-secrets.yaml \
  -f customizations.yaml
  ```

## Troubleshooting

### Diagnosis tool

If you need to open a support ticket, please execute our [carto-support-tool](../tools/) to obtain all the necessary information and attach it to the ticket.

### Ingress

- The ingress creation can take several minutes, once finished you should see this status:

  ```bash
  kubectl get ingress -n <namespace>
  kubectl describe ingress <name>
  ```

  ```bash
  Events:
    Type     Reason     Age                  From                     Message
    ----     ------     ----                 ----                     -------
    Normal   Sync       9m35s                loadbalancer-controller  UrlMap "k8s2-um-carto-router-zzud3" created
    Normal   Sync       9m29s                loadbalancer-controller  TargetProxy "k8s2-tp-carto-router-zzud3" created
    Normal   Sync       9m19s                loadbalancer-controller  ForwardingRule "k8s2-fr-carto-router-zzud3" created
    Normal   Sync       9m11s                loadbalancer-controller  TargetProxy "k8s2-ts--carto-router-zzud3" created
    Normal   Sync       9m1s                 loadbalancer-controller  ForwardingRule "k8s2-fs-carto-router-zzud3" created
    Normal   IPChanged  9m1s                 loadbalancer-controller  IP is now 34.149.xxx.xx
  ```

- A common error could be that the certificate creation for the Load Balancer in GCP will be in a failed status, you could execute these commands to debug it:

  ```bash
    kubectl get ingress carto-router -n <namespace>
    kubectl describe ingress carto-router -n <namespace>
    export SSL_CERT_ID=$(kubectl get ingress carto-router -n <namespace> -o jsonpath='{.metadata.annotations.ingress\.kubernetes\.io/ssl-cert}')
    gcloud --project <project> compute ssl-certificates list
    gcloud --project <project> compute ssl-certificates describe ${SSL_CERT_ID}
  ```

- `500 Code Error`

  You have configured your Ingress with your own certificate and you are seeing this error:

  ```bash
    Request URL: https://carto.example.com/workspace-api/accounts/ac_XXXXX/check
    Request Method: GET
    Status Code: 500

    Response: {"error":"unable to verify the first certificate","status":500,"code":"UNABLE_TO_VERIFY_LEAF_SIGNATURE"}
  ```

  This error means that your cert has not the certificate chain complete. Probably your cert has been signed by a intermediate CA, and this issuer needs to be added to your cert. In this case, you have to recreate your kubernetes tls secret certificate again with all the issuers and recreate the installation with `helm delete` and `helm install`. Please see the [uninstall steps](https://github.com/CartoDB/carto-selfhosted-helm#update)

  These steps could be useful for you:

  - Get the PEM or CRT file and split the certificate chain in multiple files

    ```bash
    cat carto.example.crt | \
      awk 'split_after == 1 {n++;split_after=0} \
      /-----END CERTIFICATE-----/ {split_after=1} \
      {print > "cert_chain" n ".crt"}'
    ```

    ```bash
    ls -ltr cert_chain*
    ```

  - Get who is the signer / issuer of each of the certificate chain certs

    ```bash
    for CERT in $(ls cert_chain*.crt); do echo -e "------------------------\n";openssl x509 -in ${CERT} -noout -text | egrep "Issuer:|Subject:"; echo -e "------------------------\n";  done
    ```

    ```yaml
    ------------------------

            Issuer: C = US, ST = New Jersey, L = Jersey City, O = The USERTRUST Network, CN = USERTrust RSA Certification Authority
            Subject: C = GB, ST = Greater Manchester, L = Salford, O = Sectigo Limited, CN = Sectigo RSA Domain Validation Secure Server CA
    ------------------------

    ------------------------

            Issuer: C = GB, ST = Greater Manchester, L = Salford, O = Sectigo Limited, CN = Sectigo RSA Domain Validation Secure Server CA
            Subject: CN = *.carto.example
    ------------------------
    ```

  - Identify the issuer that is missing in your Ingress certificate file.

  - Include the missing certificate in the chain and validate it with the certificate key. Usually it should go to the bottom of the file.

    **NOTE**: this certificates use to come with the bundle sent when the certificate was renewed. In this example the missing certificate is the `USERTrust`

    ```bash
    cat carto.example.crt USERTrustRSAAAACA.crt > carto.example.new.crt
    ```

  - Verify the md5

    ```bash
    openssl x509 -noout -modulus -in carto.example.new.crt | openssl md5
    openssl rsa -noout -modulus -in carto.example.key | openssl md5
    ```

    **NOTE**: If both `modulus md5` does not match (the output of both commands should be exactly the same), the certificate that you have updated won't be valid. From here, you need to iterate with the certificate update operation (previous step), until both `modulus md5` match.

  - Create your new certificate in a kubernetes tls secret

    ```bash
    kubectl create secret tls -n <namespace> carto-example-new --cert=carto.example.new.crt --key=carto.example.key
    ```

  - Reinstall your environment

    [uninstall steps](https://github.com/CartoDB/carto-selfhosted-helm#update)

    [install steps](https://github.com/CartoDB/carto-selfhosted-helm#installation-steps)

- Message ` type "ClusterIP", expected "NodePort" or "LoadBalancer"`

  This message is related to how is configured your cluster. To use ClusterIP the service needs to point to a NEG. This can be done using `cloud.google.com/neg: '{"ingress": true}'`annotation in router service. Container-native load balancing is enabled by default for Services when all of the following conditions are true:

  - For Services created in GKE clusters 1.17.6-gke.7 and up
  - Using VPC-native clusters
  - Not using a Shared VPC
  - Not using GKE Network Policy
    If this is not your case you must add it in your customization.yaml file. in the example in this repository this value is commented, if you are using it just uncomment it and reinstall.

  ```yaml
  service:
    annotations:
      ## Same BackendConfig for all Service ports
      ## https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#same_backendconfig_for_all_service_ports
      cloud.google.com/backend-config: '{"default": "carto-service-backend-config"}'
      ## https://cloud.google.com/kubernetes-engine/docs/how-to/container-native-load-balancing if your
      ## installation do not match with the configuration below:
      ## For Services created in GKE clusters 1.17.6-gke.7 and up
      ##  * Using VPC-native clusters
      ##  * Not using a Shared VPC
      ##  * Not using GKE Network Policy
      ## If it is not your case, uncomment the line below
      cloud.google.com/neg: '{"ingress": true}'
  ```
### Helm upgrade fails: another operation (install/upgrade/rollback) is in progress

If you face a problem like the one below while you are updating your CARTO selfhosted installation```
```bash
helm upgrade my-release carto/carto --namespace my namespace -f carto-values.yaml -f carto-secrets.yaml -f customizations.yml 
Error: UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress
```

Probably an upgrade operation wasn't killed gracefully. The fix is to rollback to a previous deployment:

```bash
helm history my-release                                                                                                                               

REVISION	UPDATED                 	STATUS         	CHART             	APP VERSION	DESCRIPTION
19      	Fri Aug 26 11:10:20 2022	superseded     	carto-1.40.6-beta 	2022.8.19-2	Upgrade complete
20      	Fri Sep 16 12:00:57 2022	superseded     	carto-1.42.1-beta 	2022.9.16  	Upgrade complete
21      	Mon Sep 19 16:46:46 2022	superseded     	carto-1.42.3-beta 	2022.9.19  	Upgrade complete
22      	Wed Sep 21 11:05:32 2022	superseded     	carto-1.42.5-beta 	2022.9.20  	Upgrade complete
23      	Wed Sep 21 11:16:34 2022	superseded     	carto-1.42.5-beta 	2022.9.20  	Upgrade complete
24      	Wed Sep 21 16:26:33 2022	superseded     	carto-1.42.5-beta 	2022.9.20  	Upgrade complete
25      	Wed Sep 28 15:28:53 2022	superseded     	carto-1.42.10-beta	2022.9.28  	Upgrade complete
26      	Fri Sep 30 14:14:29 2022	superseded     	carto-1.42.10-beta	2022.9.28  	Upgrade complete
27      	Fri Sep 30 14:37:41 2022	deployed       	carto-1.42.10-beta	2022.9.28  	Upgrade complete
28      	Fri Sep 30 15:07:06 2022	pending-upgrade	carto-1.42.10-beta	2022.9.28  	Preparing upgrade
helm rollback my-release 27                                                                                                                                              
Rollback was a success! Happy Helming!

helm history my-release   

REVISION	UPDATED                 	STATUS         	CHART             	APP VERSION	DESCRIPTION
20      	Fri Sep 16 12:00:57 2022	superseded     	carto-1.42.1-beta 	2022.9.16  	Upgrade complete
21      	Mon Sep 19 16:46:46 2022	superseded     	carto-1.42.3-beta 	2022.9.19  	Upgrade complete
22      	Wed Sep 21 11:05:32 2022	superseded     	carto-1.42.5-beta 	2022.9.20  	Upgrade complete
23      	Wed Sep 21 11:16:34 2022	superseded     	carto-1.42.5-beta 	2022.9.20  	Upgrade complete
24      	Wed Sep 21 16:26:33 2022	superseded     	carto-1.42.5-beta 	2022.9.20  	Upgrade complete
25      	Wed Sep 28 15:28:53 2022	superseded     	carto-1.42.10-beta	2022.9.28  	Upgrade complete
26      	Fri Sep 30 14:14:29 2022	superseded     	carto-1.42.10-beta	2022.9.28  	Upgrade complete
27      	Fri Sep 30 14:37:41 2022	superseded     	carto-1.42.10-beta	2022.9.28  	Upgrade complete
28      	Fri Sep 30 15:07:06 2022	pending-upgrade	carto-1.42.10-beta	2022.9.28  	Preparing upgrade
29      	Tue Oct  4 10:58:22 2022	deployed       	carto-1.42.10-beta	2022.9.28  	Rollback to 27
``` 
Now you can run the upgrade operation again
