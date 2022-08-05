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
      - [Requirements when exposing the service](#requirements-when-exposing-the-service)
      - [Enable and configure LoadBalancer mode](#enable-and-configure-loadbalancer-mode)
      - [Expose your application with an Ingress](#expose-your-application-with-an-ingress)
        - [Use Google's managed certificates for Ingress](#use-googles-managed-certificates-for-ingress)
      - [Configure TLS termination in the service](#configure-tls-termination-in-the-service)
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
      - [Requirements](#requirements)
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
  - [Advanced configuration](#advanced-configuration)
  - [Tips for creating the customization Yaml file](#tips-for-creating-the-customization-yaml-file)

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

The entry point to the CARTO Self Hosted is through the `router` Service. By default, it is configured in `ClusterIP` mode. That means it's
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

This is the easiest way to open your CARTO Self Hosted to the world on cloud providers which support external load balancers. You need to change the `router` Service type to `LoadBalancer`. This provides an externally-accessible IP address that sends traffic to the correct component on your cluster nodes.

The actual creation of the load balancer happens asynchronously, and information about the provisioned balancer is published in the Service's `.status.loadBalancer` field.

You can find an example [here](service_loadBalancer/config.yaml). Also, we have prepared a few specifics for different Kubernetes flavors, just add the config that you need in your `customizations.yaml`:

- [AWS EKS](service_loadBalancer/aws_eks/config.yaml)
- [GCP GKE](service_loadBalancer/config.yaml)
- [AZU AKS](service_loadBalancer/azu_aks/config.yaml)

> Note that with this config a [Load Balancer](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer) resource is going to be created in your cloud provider, you can find more documentation about this kind of service [here](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer)

#### Expose your application with an Ingress

Ingress exposes HTTP and HTTPS routes from outside the cluster to services within the cluster. Traffic routing is controlled by rules defined on the Ingress resource, you can find more documentation [here](https://kubernetes.io/docs/concepts/services-networking/ingress/).

Depending on the Ingress controller used, a variety of configurations can be made, here you have an example using [GKE Ingress controller](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress) with [TLS offloading](https://en.wikipedia.org/wiki/TLS_termination_proxy)

- [GKE Ingress example config for CARTO](ingress/gke/config.yaml)

##### Use Google's managed certificates for Ingress

You can configure your Ingress controller to use [Google Managed Certificates](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs) on the load balancer side.

**Prerequisites**

- You must own the domain for the Ingress (the one defined at `appConfigValues.selfHostedDomain`)
- You must have created your own [Reserved static external IP address](https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address)
- You must create an A DNS record that relates your domain to the just created static external IP address
- Check also [this requirements](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs#prerequisites)

:point_right: You can easily create a static external IP address with

```bash
gcloud compute addresses create my_carto_ip --global
```

**Steps**

Having as base configuration the [GKE Ingress config](ingress/gke/config.yaml) file, add the next configuration to your `customization.yaml` file

> :warning: The `my_carto_ip` defined in the `kubernetes.io/ingress.global-static-ip-name` annotation is the name of your Reserved static external IP address previously created

```diff
+ appConfigValues:
+   selfHostedDomain: "<your-carto-domain-name>"
+
tlsCerts:
  httpsEnabled: false

router:
  ingress:
    enabled: true
-    tls: true
+   annotations:
+     kubernetes.io/ingress.class: "gce"
+     kubernetes.io/ingress.global-static-ip-name: "my_carto_ip"
+     networking.gke.io/managed-certificates: "carto-google-managed-cert"
      networking.gke.io/v1beta1.FrontendConfig: "carto-ingress-frontend-config"

  service:
    annotations:
      cloud.google.com/backend-config: '{"default": "carto-service-backend-config"}'
extraDeploy:
  - |
    apiVersion: cloud.google.com/v1
    kind: BackendConfig
    ...
    ---
    apiVersion: networking.gke.io/v1beta1
    kind: FrontendConfig
    ...
+   ---
+   ## In case you want to use Google Managed Certificate for Ingress you will
+   ## need to deploy the ManagedCertified object
+   ## https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs#setting_up_a_google-managed_certificate
+   apiVersion: networking.gke.io/v1
+   kind: ManagedCertificate
+   metadata:
+     name: carto-google-managed-cert
+     labels: {{- include "common.labels.standard" . | nindent 4 }}
+       app.kubernetes.io/component: carto
+       {{- if .Values.commonLabels }}
+       {{- include "common.tplvalues.render" ( dict "value" .Values.commonLabels "context" $ ) | nindent 4 }}
+       {{- end }}
+     annotations:
+       {{- if .Values.commonAnnotations }}
+       {{- include "common.tplvalues.render" ( dict "value" .Values.commonAnnotations "context" $ ) | nindent 4 }}
+       {{- end }}
+     namespace: {{ .Release.Namespace | quote }}
+   spec:
+     domains:
+       - {{ .Values.appConfigValues.selfHostedDomain }}
```

> :warning: Google certificate provisioning can take several minutes, so be patient

**Related configuration**

- [Configure the domain of your Self Hosted](#configure-the-domain-of-your-self-hosted)
- [Use your own TLS certificate](#use-your-own-tls-certificate)

**Useful links**

- [google-managed-certs](https://cloud.google.com/load-balancing/docs/ssl-certificates/google-managed-certs#caa)
- [creating_an_ingress_with_a_google-managed_certificate](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs#creating_an_ingress_with_a_google-managed_certificate)

#### Configure TLS termination in the service

##### Disable internal HTTPS

> ⚠️ CARTO Self Hosted only works if the final client use HTTPS protocol. ⚠️

If you need to disable `HTTPS` in the Carto router, [add the following lines](#how-to-apply-the-configurations) to your `customizations.yaml`:

```yaml
tlsCerts:
  httpsEnabled: false
```

> ⚠️ Remember that CARTO only works with `HTTPS`, so if you disable this protocol in the Carto Router component you should configure it in a higher layer like a Load Balancer (service or ingress) to make the redirection from `HTTP` to `HTTPS` ⚠️

##### Use your own TLS certificate

By default, the package generates a self-signed certificate with a validity of 365 days.

If you want to add your own certificate you need:

- Create a kubernetes secret with following content:

  ```bash
  kubectl create secret tls \
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

* Cloud SQL > Cloud SQL Client
* Cloud SQL > Cloud SQL Editor
* Cloud SQL > Cloud SQL Admin

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
  existingSecret: "cloudsql-secret"
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

For every CARTO Self Hosted installation, we create GCS buckets in our side as part of the required infrastructure for importing data, map thumbnails and other internal data.

You can create and use your own storage buckets in any of the following supported storage providers:

- Google Cloud Storage. [Terraform code example](https://github.com/CartoDB/carto-selfhosted/blob/master/examples/terraform/gcp/storage.tf).
- AWS S3. [Terraform code example](https://github.com/CartoDB/carto-selfhosted/blob/master/examples/terraform/aws/storage.tf).
- Azure Storage. [Terraform code example](https://github.com/CartoDB/carto-selfhosted/blob/master/examples/terraform/azure/storage.tf).

> :warning: You can only set one provider at a time.

#### Requirements

- You need to create 3 buckets in your preferred Cloud provider:
  - Import Bucket
  - Client Bucket
  - Thumbnails Bucket

> There's no name constraints.

> :warning: Map thumbnails storage objects (.png files) can be configured to be `public` (default) or `private`. In order to change this, set `appConfigValues.workspaceThumbnailsPublic: "false"` (see the examples below). For the default configuration to work, the bucket must allow public objects/blobs.

- CORS configuration: Thumbnails and Import buckets require having the following CORS headers.
  - Allowed origins: `*`
  - Allowed methods: `GET`, `PUT`, `POST`
  - Allowed headers (common): `Content-Type`, `Content-MD5`, `Content-Disposition`, `Cache-Control`
    - GCS (extra): `x-goog-content-length-range`, `x-goog-meta-filename`
    - Azure (extra): `Access-Control-Request-Headers`, `X-MS-Blob-Type`
  - Max age: `3600`

> CORS is configured at bucket level in GCS and S3, and at storage account level in Azure.

> How do I setup CORS configuration? Check the provider docs: [GCS](https://cloud.google.com/storage/docs/configuring-cors), [AWS S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/enabling-cors-examples.html), [Azure Storage](https://docs.microsoft.com/en-us/rest/api/storageservices/cross-origin-resource-sharing--cors--support-for-the-azure-storage-services#enabling-cors-for-azure-storage).

- Generate credentials to access those buckets, our supported authentication methods are:

  - GCS: Service Account Key
  - AWS: Access Key ID and Secret Access Key
  - Azure: Access Key

- Grant Read/Write permissions over the buckets to the credentials mentioned above.

#### Google Cloud Storage

In order to use Google Cloud Storage custom buckets you need to:

1. Create the buckets.

   > :warning: If you enable `Prevent public access` in the bucket properties, then set `appConfigValues.workspaceThumbnailsPublic` and `appConfigValues.workspaceImportsPublic` to `false`.

2. Configure the required [CORS settings](#requirements).

3. Add the following lines to your `customizations.yaml` and replace the `<values>` with your own settings:

   ```yaml
   appConfigValues:
     storageProvider: "gcp"
     importBucket: <import_bucket_name>
     workspaceImportsBucket: <client_bucket_name>
     workspaceImportsPublic: <false|true>
     workspaceThumbnailsBucket: <thumbnails_bucket_name>
     workspaceThumbnailsPublic: <false|true>
     googleCloudStorageProjectId: <gcp_project_id>
   ```

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

2. Configure the required [CORS settings](#requirements).

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
  awsS3Region: <s3_buckets_region>
```

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

2. Configure the required [CORS settings](#requirements).

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
  workspaceThumbnailsPublic: <false|true>
```

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

You can set statically set the number of pods should be running. To do it, use [static scale config](scale_components/static.yaml) adding it with `-f customizations/scale_components/static.yaml` to the `install` or `upgrade` commands.

> Although we recommend the autoscaling configuration, you could choose the autoscaling feature for some components and the static configuration for the others. Remember that autoscaling override the static configuration, so if one component has both configurations, autoscaling will take precedence.

## High Availability

In some cases, you may want to ensure some critical services have replicas deployed across different worker nodes in order to provide high availability against a node failure. You can achieve this by applying the [high availability config](high_availability/customizations.yaml). Note that you should enable static scaling or autoscaling for this setup to work as expected.

> In order to provide high availability accross regions/zones, it's recommended to deploy each worker node in a different cloud provider regions/zones.

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
