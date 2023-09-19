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

> **Note**
> The `externalPostgresql.user` and `externalPostgresql.database` inside the Postgres instance are going to be created automatically during the installation process. Do not create then manually.

> **Note**
> By default, CARTO will try to connect to the `postgres` database with the `postgres` user. If you want to use a different user, you can configure it via the `externalPostgresql.adminUser`, and `externalPostgresql.adminDatabase` parameters.

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