# carto

[The CARTO Helm chart](https://github.com/CartoDB/carto-selfhosted) deploys CARTO in a self hosted environment.

## Introduction

This chart bootstraps a [CARTO self hosted](https://github.com/CartoDB/carto-selfhosted) Deployment in a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Install, upgrade & uninstall

To install, upgrade or uninstall this chart, please refer to [the root README.md](../README.md) of this repository.

## Parameters

### Custom config parameters

| Name                                        | Description                                                                                | Value                  |
| ------------------------------------------- | ------------------------------------------------------------------------------------------ | ---------------------- |
| `appConfigValues.selfHostedDomain`          | Domain that is going to be used to access to the CARTO self-hosted.                        | `carto-selfhosted.lan` |
| `appConfigValues.storageProvider`           | Indicate the storage provider for the bucket. Valid values are: `gcp`, `s3` & `azure-blob` | `gcp`                  |
| `appConfigValues.httpCacheEnabled`          | Enable the internal httpCache                                                              | `true`                 |
| `appConfigValues.importBucket`              | Bucket to be used to store the import files                                                | `""`                   |
| `appConfigValues.workspaceImportsBucket`    | Bucket to be used to store metadata of the workspace                                       | `""`                   |
| `appConfigValues.workspaceThumbnailsBucket` | Bucket to be used to store the thumbnails generated in the app                             | `""`                   |
| `appConfigValues.workspaceThumbnailsPublic` | Indicate if the thumbnails could be accessed publicly                                      | `true`                 |
| `appConfigValues.gcpBucketsProjectId`       | If the bucket is GCP, the ProjectId to be used                                             | `""`                   |
| `appConfigValues.awsS3Region`               | If the bucket is S3, the region to be used                                                 | `""`                   |


### CARTO config parameters

| Name                                          | Description                                                         | Value |
| --------------------------------------------- | ------------------------------------------------------------------- | ----- |
| `cartoConfigValues.cartoAccApiDomain`         | Domain of the Account API of Carto.                                 | `""`  |
| `cartoConfigValues.cartoAccGcpProjectId`      | GCP project ID of the Carto Accounts.                               | `""`  |
| `cartoConfigValues.cartoAccGcpProjectRegion`  | GCP project region of the Carto Accounts.                           | `""`  |
| `cartoConfigValues.cartoAuth0ClientId`        | Client ID of Auth0.                                                 | `""`  |
| `cartoConfigValues.cartoAuth0CustomDomain`    | Custom Domain of Auth0.                                             | `""`  |
| `cartoConfigValues.cartoSelfhostedDwLocation` | Location of the Carto Data Warehouse.                               | `""`  |
| `cartoConfigValues.selfHostedGcpProjectId`    | GCP project id used in the installation.                            | `""`  |
| `cartoConfigValues.selfHostedTenantId`        | Carto internal tenantId used in the installation.                   | `""`  |
| `cartoConfigValues.launchDarklyClientSideId`  | LaunchDarkly ClientSideId (by www) used to enable/disable features. | `""`  |


### App secret

| Name                                                         | Description                                                                                                                                                                                                                                                     | Value |
| ------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| `appSecrets.googleMapsApiKey`                                | Google maps api-key value.                                                                                                                                                                                                                                      |       |
| `appSecrets.googleMapsApiKey.value`                          | Value of the secret `Google maps api-key`. One of `appSecrets.googleMapsApiKey.value` or `appSecrets.googleMapsApiKey.existingSecret` could be defined.                                                                                                         | `""`  |
| `appSecrets.googleMapsApiKey.existingSecret.name`            | Name of the pre-existent secret containing the `appSecrets.googleMapsApiKey.existingSecret.key`. If `appSecrets.googleMapsApiKey.value` is defined, this value is going to be ignored and not used.                                                             | `""`  |
| `appSecrets.googleMapsApiKey.existingSecret.key`             | Key to find in `appSecrets.googleMapsApiKey.existingSecret.name` where the value of `appSecrets.googleMapsApiKey` is found. If `appSecrets.googleMapsApiKey.value` is defined, this value is going to be ignored and not used.                                  | `""`  |
| `appSecrets.gcpBucketsServiceAccountKey`                     | If GCP is used in self-hosted, the AccessKey Secret.                                                                                                                                                                                                            |       |
| `appSecrets.gcpBucketsServiceAccountKey.value`               | Value of the secret `AccessKey Secret` (Only required if GCP is used). One of `appSecrets.gcpBucketsServiceAccountKey.value` or `appSecrets.gcpBucketsServiceAccountKey.existingSecret` could be defined.                                                       | `""`  |
| `appSecrets.gcpBucketsServiceAccountKey.existingSecret.name` | Name of the pre-existent secret containing the `appSecrets.gcpBucketsServiceAccountKey.existingSecret.key`. If `appSecrets.gcpBucketsServiceAccountKey.value` is defined, this value is going to be ignored and not used.                                       | `""`  |
| `appSecrets.gcpBucketsServiceAccountKey.existingSecret.key`  | Key to find in `appSecrets.gcpBucketsServiceAccountKey.existingSecret.name` where the value of `appSecrets.gcpBucketsServiceAccountKey` is found. If `appSecrets.gcpBucketsServiceAccountKey.value` is defined, this value is going to be ignored and not used. | `""`  |
| `appSecrets.awsAccessKeyId`                                  | If AWS is used in self-hosted, the AccessKey Id.                                                                                                                                                                                                                |       |
| `appSecrets.awsAccessKeyId.value`                            | Value of the secret `AccessKey Id` (Only required if AWS is used). One of `appSecrets.awsAccessKeyId.value` or `appSecrets.awsAccessKeyId.existingSecret` could be defined.                                                                                     | `""`  |
| `appSecrets.awsAccessKeyId.existingSecret.name`              | Name of the pre-existent secret containing the `appSecrets.awsAccessKeyId.existingSecret.key`. If `appSecrets.awsAccessKeyId.value` is defined, this value is going to be ignored and not used.                                                                 | `""`  |
| `appSecrets.awsAccessKeyId.existingSecret.key`               | Key to find in `appSecrets.awsAccessKeyId.existingSecret.name` where the value of `appSecrets.awsAccessKeyId` is found. If `appSecrets.awsAccessKeyId.value` is defined, this value is going to be ignored and not used.                                        | `""`  |
| `appSecrets.awsAccessKeySecret`                              | If AWS is used in self-hosted, the AccessKey Secret.                                                                                                                                                                                                            |       |
| `appSecrets.awsAccessKeySecret.value`                        | Value of the secret `AccessKey Secret` (Only required if AWS is used). One of `appSecrets.awsAccessKeySecret.value` or `appSecrets.awsAccessKeySecret.existingSecret` could be defined.                                                                         | `""`  |
| `appSecrets.awsAccessKeySecret.existingSecret.name`          | Name of the pre-existent secret containing the `appSecrets.awsAccessKeySecret.existingSecret.key`. If `appSecrets.awsAccessKeySecret.value` is defined, this value is going to be ignored and not used.                                                         | `""`  |
| `appSecrets.awsAccessKeySecret.existingSecret.key`           | Key to find in `appSecrets.awsAccessKeySecret.existingSecret.name` where the value of `appSecrets.awsAccessKeySecret` is found. If `appSecrets.awsAccessKeySecret.value` is defined, this value is going to be ignored and not used.                            | `""`  |
| `appSecrets.azureStorageAccessKey`                           | If Azure is used in self-hosted, the AccessKey Secret.                                                                                                                                                                                                          |       |
| `appSecrets.azureStorageAccessKey.value`                     | Value of the secret `AccessKey Secret` (Only required if Azure is used). One of `appSecrets.azureStorageAccessKey.value` or `appSecrets.azureStorageAccessKey.existingSecret` could be defined.                                                                 | `""`  |
| `appSecrets.azureStorageAccessKey.existingSecret.name`       | Name of the pre-existent secret containing the `appSecrets.azureStorageAccessKey.existingSecret.key`. If `appSecrets.azureStorageAccessKey.value` is defined, this value is going to be ignored and not used.                                                   | `""`  |
| `appSecrets.azureStorageAccessKey.existingSecret.key`        | Key to find in `appSecrets.azureStorageAccessKey.existingSecret.name` where the value of `appSecrets.azureStorageAccessKey` is found. If `appSecrets.azureStorageAccessKey.value` is defined, this value is going to be ignored and not used.                   | `""`  |


### CARTO secrets

| Name                                                           | Description                                                                                                                                                                                                                                                           | Value     |
| -------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| `cartoSecrets.encryptionSecretKey`                             | The secret used to encrypt the clients Carto connections stored in the database.                                                                                                                                                                                      |           |
| `cartoSecrets.encryptionSecretKey.value`                       | Value of the secret used to encrypt the clients Carto connections stored in the database. One of `cartoSecrets.encryptionSecretKey.value` or `cartoSecrets.encryptionSecretKey.existingSecret` could be defined.                                                      | `""`      |
| `cartoSecrets.encryptionSecretKey.existingSecret.name`         | Name of the pre-existent secret containing the `cartoSecrets.encryptionSecretKey.existingSecret.key`. If `cartoSecrets.encryptionSecretKey.value` is defined, this value is going to be ignored and not used.                                                         | `""`      |
| `cartoSecrets.encryptionSecretKey.existingSecret.key`          | Key to find in `cartoSecrets.encryptionSecretKey.existingSecret.name` where the value of `cartoSecrets.encryptionSecretKey` is found. If `cartoSecrets.encryptionSecretKey.value` is defined, this value is going to be ignored and not used.                         | `""`      |
| `cartoSecrets.varnishPurgeSecret`                              | The secret used (by the app) to exec purge request.                                                                                                                                                                                                                   |           |
| `cartoSecrets.varnishPurgeSecret.value`                        | Value of the secret used (by the app) to exec purge request. One of `cartoSecrets.varnishPurgeSecret.value` or `cartoSecrets.varnishPurgeSecret.existingSecret` could be defined.                                                                                     | `""`      |
| `cartoSecrets.varnishPurgeSecret.existingSecret.name`          | Name of the pre-existent secret containing the `cartoSecrets.varnishPurgeSecret.existingSecret.key`. If `cartoSecrets.varnishPurgeSecret.value` is defined, this value is going to be ignored and not used.                                                           | `""`      |
| `cartoSecrets.varnishPurgeSecret.existingSecret.key`           | Key to find in `cartoSecrets.varnishPurgeSecret.existingSecret.name` where the value of `cartoSecrets.varnishPurgeSecret` is found. If `cartoSecrets.varnishPurgeSecret.value` is defined, this value is going to be ignored and not used.                            | `""`      |
| `cartoSecrets.varnishDebugSecret`                              | The secret used if someone would like to debug Varnish.                                                                                                                                                                                                               |           |
| `cartoSecrets.varnishDebugSecret.value`                        | Value of the secret used if someone would like to debug Varnish. One of `cartoSecrets.varnishDebugSecret.value` or `cartoSecrets.varnishDebugSecret.existingSecret` could be defined.                                                                                 | `""`      |
| `cartoSecrets.varnishDebugSecret.existingSecret.name`          | Name of the pre-existent secret containing the `cartoSecrets.varnishDebugSecret.existingSecret.key`. If `cartoSecrets.varnishDebugSecret.value` is defined, this value is going to be ignored and not used.                                                           | `""`      |
| `cartoSecrets.varnishDebugSecret.existingSecret.key`           | Key to find in `cartoSecrets.varnishDebugSecret.existingSecret.name` where the value of `cartoSecrets.varnishDebugSecret` is found. If `cartoSecrets.varnishDebugSecret.value` is defined, this value is going to be ignored and not used.                            | `""`      |
| `cartoSecrets.defaultGoogleServiceAccount`                     | The secret used by the app to connect to google services. This couldn't be changed.                                                                                                                                                                                   |           |
| `cartoSecrets.defaultGoogleServiceAccount.value`               | Value of the secret used by the app to connect to google services. This couldn't be changed. One of `cartoSecrets.defaultGoogleServiceAccount.value` or `cartoSecrets.defaultGoogleServiceAccount.existingSecret` could be defined.                                   | `""`      |
| `cartoSecrets.defaultGoogleServiceAccount.existingSecret.name` | Name of the pre-existent secret containing the `cartoSecrets.defaultGoogleServiceAccount.existingSecret.key`. If `cartoSecrets.defaultGoogleServiceAccount.value` is defined, this value is going to be ignored and not used.                                         | `""`      |
| `cartoSecrets.defaultGoogleServiceAccount.existingSecret.key`  | Key to find in `cartoSecrets.defaultGoogleServiceAccount.existingSecret.name` where the value of `cartoSecrets.defaultGoogleServiceAccount` is found. If `cartoSecrets.defaultGoogleServiceAccount.value` is defined, this value is going to be ignored and not used. | `""`      |
| `tlsCerts.autoGenerate`                                        | Generate self-signed TLS certificates                                                                                                                                                                                                                                 | `true`    |
| `tlsCerts.existingSecret.name`                                 | Name of a secret containing the certificate                                                                                                                                                                                                                           | `""`      |
| `tlsCerts.existingSecret.certKey`                              | Key of the certificate inside the secret                                                                                                                                                                                                                              | `tls.crt` |
| `tlsCerts.existingSecret.keyKey`                               | Key of the certificate key inside the secret                                                                                                                                                                                                                          | `tls.key` |


### Global parameters

| Name                      | Description                                     | Value |
| ------------------------- | ----------------------------------------------- | ----- |
| `global.imageRegistry`    | Global Docker image registry                    | `""`  |
| `global.imagePullSecrets` | Global Docker registry secret names as an array | `[]`  |
| `global.storageClass`     | Global StorageClass for Persistent Volume(s)    | `""`  |


### Common parameters

| Name                        | Description                                                                             | Value           |
| --------------------------- | --------------------------------------------------------------------------------------- | --------------- |
| `kubeVersion`               | Override Kubernetes version                                                             | `""`            |
| `nameOverride`              | String to partially override common.names.fullname                                      | `""`            |
| `fullnameOverride`          | String to fully override common.names.fullname                                          | `""`            |
| `commonLabels`              | Labels to add to all deployed objects                                                   | `{}`            |
| `commonAnnotations`         | Annotations to add to all deployed objects                                              | `{}`            |
| `clusterDomain`             | Kubernetes cluster domain name                                                          | `cluster.local` |
| `extraDeploy`               | Array of extra objects to deploy with the release                                       | `[]`            |
| `diagnosticMode.enabled`    | Enable diagnostic mode (all probes will be disabled and the command will be overridden) | `false`         |
| `diagnosticMode.command`    | Command to override all containers in the deployment                                    | `["sleep"]`     |
| `diagnosticMode.args`       | Args to override all containers in the deployment                                       | `["999d"]`      |
| `commonConfiguration`       | Configuration script that will be run in all Carto instances                            | `{}`            |
| `commonSecretConfiguration` | Sensitive configuration script that will be run in all CARTO deployments                | `{}`            |


### accounts-www Deployment Parameters

| Name                                                     | Description                                                                                           | Value                           |
| -------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------- |
| `accountsWww.image.registry`                             | accounts-www image registry                                                                           | `gcr.io/carto-onprem-artifacts` |
| `accountsWww.image.repository`                           | accounts-www image repository                                                                         | `accounts-www`                  |
| `accountsWww.image.tag`                                  | accounts-www image tag (immutable tags are recommended)                                               | `""`                            |
| `accountsWww.image.pullPolicy`                           | accounts-www image pull policy                                                                        | `IfNotPresent`                  |
| `accountsWww.image.pullSecrets`                          | accounts-www image pull secrets                                                                       | `[]`                            |
| `accountsWww.replicaCount`                               | Number of accounts-www replicas to deploy                                                             | `1`                             |
| `accountsWww.containerPorts.http`                        | accounts-www HTTP container port                                                                      | `8080`                          |
| `accountsWww.livenessProbe.enabled`                      | Enable livenessProbe on accounts-www containers                                                       | `true`                          |
| `accountsWww.livenessProbe.initialDelaySeconds`          | Initial delay seconds for livenessProbe                                                               | `10`                            |
| `accountsWww.livenessProbe.periodSeconds`                | Period seconds for livenessProbe                                                                      | `30`                            |
| `accountsWww.livenessProbe.timeoutSeconds`               | Timeout seconds for livenessProbe                                                                     | `5`                             |
| `accountsWww.livenessProbe.failureThreshold`             | Failure threshold for livenessProbe                                                                   | `5`                             |
| `accountsWww.livenessProbe.successThreshold`             | Success threshold for livenessProbe                                                                   | `1`                             |
| `accountsWww.readinessProbe.enabled`                     | Enable readinessProbe on accounts-www containers                                                      | `true`                          |
| `accountsWww.readinessProbe.initialDelaySeconds`         | Initial delay seconds for readinessProbe                                                              | `10`                            |
| `accountsWww.readinessProbe.periodSeconds`               | Period seconds for readinessProbe                                                                     | `30`                            |
| `accountsWww.readinessProbe.timeoutSeconds`              | Timeout seconds for readinessProbe                                                                    | `5`                             |
| `accountsWww.readinessProbe.failureThreshold`            | Failure threshold for readinessProbe                                                                  | `5`                             |
| `accountsWww.readinessProbe.successThreshold`            | Success threshold for readinessProbe                                                                  | `1`                             |
| `accountsWww.startupProbe.enabled`                       | Enable startupProbe on accounts-www containers                                                        | `false`                         |
| `accountsWww.startupProbe.initialDelaySeconds`           | Initial delay seconds for startupProbe                                                                | `10`                            |
| `accountsWww.startupProbe.periodSeconds`                 | Period seconds for startupProbe                                                                       | `30`                            |
| `accountsWww.startupProbe.timeoutSeconds`                | Timeout seconds for startupProbe                                                                      | `5`                             |
| `accountsWww.startupProbe.failureThreshold`              | Failure threshold for startupProbe                                                                    | `5`                             |
| `accountsWww.startupProbe.successThreshold`              | Success threshold for startupProbe                                                                    | `1`                             |
| `accountsWww.customLivenessProbe`                        | Custom livenessProbe that overrides the default one                                                   | `{}`                            |
| `accountsWww.customReadinessProbe`                       | Custom readinessProbe that overrides the default one                                                  | `{}`                            |
| `accountsWww.customStartupProbe`                         | Custom startupProbe that overrides the default one                                                    | `{}`                            |
| `accountsWww.autoscaling.enabled`                        | Enable autoscaling for the accounts-www containers                                                    | `false`                         |
| `accountsWww.autoscaling.minReplicas`                    | The minimal number of containters for the accounts-www deployment                                     | `1`                             |
| `accountsWww.autoscaling.maxReplicas`                    | The maximum number of containers for the accounts-www deployment                                      | `2`                             |
| `accountsWww.autoscaling.targetCPUUtilizationPercentage` | The CPU utilization percentage used for scale up containers in accounts-www deployment                | `75`                            |
| `accountsWww.resources.limits`                           | The resources limits for the accounts-www containers                                                  | `{}`                            |
| `accountsWww.resources.requests`                         | The requested resources for the accounts-www containers                                               | `{}`                            |
| `accountsWww.podSecurityContext.enabled`                 | Enabled accounts-www pods' Security Context                                                           | `true`                          |
| `accountsWww.podSecurityContext.fsGroup`                 | Set accounts-www pod's Security Context fsGroup                                                       | `0`                             |
| `accountsWww.containerSecurityContext.enabled`           | Enabled accounts-www containers' Security Context                                                     | `true`                          |
| `accountsWww.containerSecurityContext.runAsUser`         | Set accounts-www containers' Security Context runAsUser                                               | `0`                             |
| `accountsWww.containerSecurityContext.runAsNonRoot`      | Set accounts-www containers' Security Context runAsNonRoot                                            | `false`                         |
| `accountsWww.configuration`                              | Configuration settings (env vars) for accounts-www                                                    | `{}`                            |
| `accountsWww.secretConfiguration`                        | Configuration settings (env vars) for accounts-www                                                    | `""`                            |
| `accountsWww.existingConfigMap`                          | The name of an existing ConfigMap with your custom configuration for accounts-www                     | `""`                            |
| `accountsWww.existingSecret`                             | The name of an existing ConfigMap with your custom configuration for accounts-www                     | `""`                            |
| `accountsWww.command`                                    | Override default container command (useful when using custom images)                                  | `[]`                            |
| `accountsWww.args`                                       | Override default container args (useful when using custom images)                                     | `[]`                            |
| `accountsWww.hostAliases`                                | accounts-www pods host aliases                                                                        | `[]`                            |
| `accountsWww.podLabels`                                  | Extra labels for accounts-www pods                                                                    | `{}`                            |
| `accountsWww.podAnnotations`                             | Annotations for accounts-www pods                                                                     | `{}`                            |
| `accountsWww.podAffinityPreset`                          | Pod affinity preset. Ignored if `accountsWww.affinity` is set. Allowed values: `soft` or `hard`       | `""`                            |
| `accountsWww.podAntiAffinityPreset`                      | Pod anti-affinity preset. Ignored if `accountsWww.affinity` is set. Allowed values: `soft` or `hard`  | `soft`                          |
| `accountsWww.nodeAffinityPreset.type`                    | Node affinity preset type. Ignored if `accountsWww.affinity` is set. Allowed values: `soft` or `hard` | `""`                            |
| `accountsWww.nodeAffinityPreset.key`                     | Node label key to match. Ignored if `accountsWww.affinity` is set                                     | `""`                            |
| `accountsWww.nodeAffinityPreset.values`                  | Node label values to match. Ignored if `accountsWww.affinity` is set                                  | `[]`                            |
| `accountsWww.affinity`                                   | Affinity for accounts-www pods assignment                                                             | `{}`                            |
| `accountsWww.nodeSelector`                               | Node labels for accounts-www pods assignment                                                          | `{}`                            |
| `accountsWww.tolerations`                                | Tolerations for accounts-www pods assignment                                                          | `[]`                            |
| `accountsWww.updateStrategy.type`                        | accounts-www statefulset strategy type                                                                | `RollingUpdate`                 |
| `accountsWww.priorityClassName`                          | accounts-www pods' priorityClassName                                                                  | `""`                            |
| `accountsWww.schedulerName`                              | Name of the k8s scheduler (other than default) for accounts-www pods                                  | `""`                            |
| `accountsWww.lifecycleHooks`                             | for the accounts-www container(s) to automate configuration before or after startup                   | `{}`                            |
| `accountsWww.extraEnvVars`                               | Array with extra environment variables to add to accounts-www nodes                                   | `[]`                            |
| `accountsWww.extraEnvVarsCM`                             | Name of existing ConfigMap containing extra env vars for accounts-www nodes                           | `""`                            |
| `accountsWww.extraEnvVarsSecret`                         | Name of existing Secret containing extra env vars for accounts-www nodes                              | `""`                            |
| `accountsWww.extraVolumes`                               | Optionally specify extra list of additional volumes for the accounts-www pod(s)                       | `[]`                            |
| `accountsWww.extraVolumeMounts`                          | Optionally specify extra list of additional volumeMounts for the accounts-www container(s)            | `[]`                            |
| `accountsWww.sidecars`                                   | Add additional sidecar containers to the accounts-www pod(s)                                          | `{}`                            |
| `accountsWww.initContainers`                             | Add additional init containers to the accounts-www pod(s)                                             | `{}`                            |


### accounts-www Service Parameters

| Name                                           | Description                                                                             | Value       |
| ---------------------------------------------- | --------------------------------------------------------------------------------------- | ----------- |
| `accountsWww.service.type`                     | accounts-www service type                                                               | `ClusterIP` |
| `accountsWww.service.ports.http`               | accounts-www service HTTP port                                                          | `80`        |
| `accountsWww.service.nodePorts.http`           | Node port for HTTP                                                                      | `""`        |
| `accountsWww.service.clusterIP`                | accounts-www service Cluster IP                                                         | `""`        |
| `accountsWww.service.loadBalancerIP`           | accounts-www service Load Balancer IP                                                   | `""`        |
| `accountsWww.service.labelSelectorsOverride`   | Selector for accounts-www service                                                       | `{}`        |
| `accountsWww.service.loadBalancerSourceRanges` | accounts-www service Load Balancer sources                                              | `[]`        |
| `accountsWww.service.externalTrafficPolicy`    | accounts-www service external traffic policy                                            | `Cluster`   |
| `accountsWww.service.annotations`              | Additional custom annotations for accounts-www service                                  | `{}`        |
| `accountsWww.service.extraPorts`               | Extra ports to expose in accounts-www service (normally used with the `sidecars` value) | `[]`        |


### accounts-www ServiceAccount configuration

| Name                                                      | Description                                          | Value   |
| --------------------------------------------------------- | ---------------------------------------------------- | ------- |
| `accountsWww.serviceAccount.create`                       | Specifies whether a ServiceAccount should be created | `true`  |
| `accountsWww.serviceAccount.name`                         | The name of the ServiceAccount to use.               | `""`    |
| `accountsWww.serviceAccount.automountServiceAccountToken` | Mount service account token in the deployment        | `false` |


### import-api Deployment Parameters

| Name                                                   | Description                                                                                         | Value                           |
| ------------------------------------------------------ | --------------------------------------------------------------------------------------------------- | ------------------------------- |
| `importApi.image.registry`                             | import-api image registry                                                                           | `gcr.io/carto-onprem-artifacts` |
| `importApi.image.repository`                           | import-api image repository                                                                         | `import-api`                    |
| `importApi.image.tag`                                  | import-api image tag (immutable tags are recommended)                                               | `""`                            |
| `importApi.image.pullPolicy`                           | import-api image pull policy                                                                        | `IfNotPresent`                  |
| `importApi.image.pullSecrets`                          | import-api image pull secrets                                                                       | `[]`                            |
| `importApi.replicaCount`                               | Number of import-api replicas to deploy                                                             | `1`                             |
| `importApi.containerPorts.http`                        | import-api HTTP container port                                                                      | `8003`                          |
| `importApi.livenessProbe.enabled`                      | Enable livenessProbe on import-api containers                                                       | `true`                          |
| `importApi.livenessProbe.initialDelaySeconds`          | Initial delay seconds for livenessProbe                                                             | `10`                            |
| `importApi.livenessProbe.periodSeconds`                | Period seconds for livenessProbe                                                                    | `30`                            |
| `importApi.livenessProbe.timeoutSeconds`               | Timeout seconds for livenessProbe                                                                   | `5`                             |
| `importApi.livenessProbe.failureThreshold`             | Failure threshold for livenessProbe                                                                 | `5`                             |
| `importApi.livenessProbe.successThreshold`             | Success threshold for livenessProbe                                                                 | `1`                             |
| `importApi.readinessProbe.enabled`                     | Enable readinessProbe on import-api containers                                                      | `true`                          |
| `importApi.readinessProbe.initialDelaySeconds`         | Initial delay seconds for readinessProbe                                                            | `10`                            |
| `importApi.readinessProbe.periodSeconds`               | Period seconds for readinessProbe                                                                   | `30`                            |
| `importApi.readinessProbe.timeoutSeconds`              | Timeout seconds for readinessProbe                                                                  | `5`                             |
| `importApi.readinessProbe.failureThreshold`            | Failure threshold for readinessProbe                                                                | `5`                             |
| `importApi.readinessProbe.successThreshold`            | Success threshold for readinessProbe                                                                | `1`                             |
| `importApi.startupProbe.enabled`                       | Enable startupProbe on import-api containers                                                        | `false`                         |
| `importApi.startupProbe.initialDelaySeconds`           | Initial delay seconds for startupProbe                                                              | `10`                            |
| `importApi.startupProbe.periodSeconds`                 | Period seconds for startupProbe                                                                     | `30`                            |
| `importApi.startupProbe.timeoutSeconds`                | Timeout seconds for startupProbe                                                                    | `5`                             |
| `importApi.startupProbe.failureThreshold`              | Failure threshold for startupProbe                                                                  | `5`                             |
| `importApi.startupProbe.successThreshold`              | Success threshold for startupProbe                                                                  | `1`                             |
| `importApi.customLivenessProbe`                        | Custom livenessProbe that overrides the default one                                                 | `{}`                            |
| `importApi.customReadinessProbe`                       | Custom readinessProbe that overrides the default one                                                | `{}`                            |
| `importApi.customStartupProbe`                         | Custom startupProbe that overrides the default one                                                  | `{}`                            |
| `importApi.autoscaling.enabled`                        | Enable autoscaling for the import-api containers                                                    | `false`                         |
| `importApi.autoscaling.minReplicas`                    | The minimal number of containters for the import-api deployment                                     | `1`                             |
| `importApi.autoscaling.maxReplicas`                    | The maximum number of containers for the import-api deployment                                      | `2`                             |
| `importApi.autoscaling.targetCPUUtilizationPercentage` | The CPU utilization percentage used for scale up containers in import-api deployment                | `75`                            |
| `importApi.resources.limits`                           | The resources limits for the import-api containers                                                  | `{}`                            |
| `importApi.resources.requests`                         | The requested resources for the import-api containers                                               | `{}`                            |
| `importApi.podSecurityContext.enabled`                 | Enabled import-api pods' Security Context                                                           | `true`                          |
| `importApi.podSecurityContext.fsGroup`                 | Set import-api pod's Security Context fsGroup                                                       | `0`                             |
| `importApi.containerSecurityContext.enabled`           | Enabled import-api containers' Security Context                                                     | `true`                          |
| `importApi.containerSecurityContext.runAsUser`         | Set import-api containers' Security Context runAsUser                                               | `0`                             |
| `importApi.containerSecurityContext.runAsNonRoot`      | Set import-api containers' Security Context runAsNonRoot                                            | `false`                         |
| `importApi.configuration`                              | Configuration settings (env vars) for import-api                                                    | `{}`                            |
| `importApi.secretConfiguration`                        | Configuration settings (env vars) for import-api                                                    | `""`                            |
| `importApi.existingConfigMap`                          | The name of an existing ConfigMap with your custom configuration for import-api                     | `""`                            |
| `importApi.existingSecret`                             | The name of an existing ConfigMap with your custom configuration for import-api                     | `""`                            |
| `importApi.command`                                    | Override default container command (useful when using custom images)                                | `[]`                            |
| `importApi.args`                                       | Override default container args (useful when using custom images)                                   | `[]`                            |
| `importApi.hostAliases`                                | import-api pods host aliases                                                                        | `[]`                            |
| `importApi.podLabels`                                  | Extra labels for import-api pods                                                                    | `{}`                            |
| `importApi.podAnnotations`                             | Annotations for import-api pods                                                                     | `{}`                            |
| `importApi.podAffinityPreset`                          | Pod affinity preset. Ignored if `importApi.affinity` is set. Allowed values: `soft` or `hard`       | `""`                            |
| `importApi.podAntiAffinityPreset`                      | Pod anti-affinity preset. Ignored if `importApi.affinity` is set. Allowed values: `soft` or `hard`  | `soft`                          |
| `importApi.nodeAffinityPreset.type`                    | Node affinity preset type. Ignored if `importApi.affinity` is set. Allowed values: `soft` or `hard` | `""`                            |
| `importApi.nodeAffinityPreset.key`                     | Node label key to match. Ignored if `importApi.affinity` is set                                     | `""`                            |
| `importApi.nodeAffinityPreset.values`                  | Node label values to match. Ignored if `importApi.affinity` is set                                  | `[]`                            |
| `importApi.affinity`                                   | Affinity for import-api pods assignment                                                             | `{}`                            |
| `importApi.nodeSelector`                               | Node labels for import-api pods assignment                                                          | `{}`                            |
| `importApi.tolerations`                                | Tolerations for import-api pods assignment                                                          | `[]`                            |
| `importApi.updateStrategy.type`                        | import-api statefulset strategy type                                                                | `RollingUpdate`                 |
| `importApi.priorityClassName`                          | import-api pods' priorityClassName                                                                  | `""`                            |
| `importApi.schedulerName`                              | Name of the k8s scheduler (other than default) for import-api pods                                  | `""`                            |
| `importApi.lifecycleHooks`                             | for the import-api container(s) to automate configuration before or after startup                   | `{}`                            |
| `importApi.extraEnvVars`                               | Array with extra environment variables to add to import-api nodes                                   | `[]`                            |
| `importApi.extraEnvVarsCM`                             | Name of existing ConfigMap containing extra env vars for import-api nodes                           | `""`                            |
| `importApi.extraEnvVarsSecret`                         | Name of existing Secret containing extra env vars for import-api nodes                              | `""`                            |
| `importApi.extraVolumes`                               | Optionally specify extra list of additional volumes for the import-api pod(s)                       | `[]`                            |
| `importApi.extraVolumeMounts`                          | Optionally specify extra list of additional volumeMounts for the import-api container(s)            | `[]`                            |
| `importApi.sidecars`                                   | Add additional sidecar containers to the import-api pod(s)                                          | `{}`                            |
| `importApi.initContainers`                             | Add additional init containers to the import-api pod(s)                                             | `{}`                            |


### import-api Service Parameters

| Name                                         | Description                                                                           | Value       |
| -------------------------------------------- | ------------------------------------------------------------------------------------- | ----------- |
| `importApi.service.type`                     | import-api service type                                                               | `ClusterIP` |
| `importApi.service.ports.http`               | import-api service HTTP port                                                          | `80`        |
| `importApi.service.nodePorts.http`           | Node port for HTTP                                                                    | `""`        |
| `importApi.service.clusterIP`                | import-api service Cluster IP                                                         | `""`        |
| `importApi.service.loadBalancerIP`           | import-api service Load Balancer IP                                                   | `""`        |
| `importApi.service.labelSelectorsOverride`   | Selector for import-api service                                                       | `{}`        |
| `importApi.service.loadBalancerSourceRanges` | import-api service Load Balancer sources                                              | `[]`        |
| `importApi.service.externalTrafficPolicy`    | import-api service external traffic policy                                            | `Cluster`   |
| `importApi.service.annotations`              | Additional custom annotations for import-api service                                  | `{}`        |
| `importApi.service.extraPorts`               | Extra ports to expose in import-api service (normally used with the `sidecars` value) | `[]`        |


### import-api ServiceAccount configuration

| Name                                                    | Description                                          | Value   |
| ------------------------------------------------------- | ---------------------------------------------------- | ------- |
| `importApi.serviceAccount.create`                       | Specifies whether a ServiceAccount should be created | `true`  |
| `importApi.serviceAccount.name`                         | The name of the ServiceAccount to use.               | `""`    |
| `importApi.serviceAccount.automountServiceAccountToken` | Mount service account token in the deployment        | `false` |


### import-worker Deployment Parameters

| Name                                                 | Description                                                                                            | Value                           |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------ | ------------------------------- |
| `importWorker.image.registry`                        | import-worker image registry                                                                           | `gcr.io/carto-onprem-artifacts` |
| `importWorker.image.repository`                      | import-worker image repository                                                                         | `import-api`                    |
| `importWorker.image.tag`                             | import-worker image tag (immutable tags are recommended)                                               | `""`                            |
| `importWorker.image.pullPolicy`                      | import-worker image pull policy                                                                        | `IfNotPresent`                  |
| `importWorker.image.pullSecrets`                     | import-worker image pull secrets                                                                       | `[]`                            |
| `importWorker.replicaCount`                          | Number of import-worker replicas to deploy                                                             | `1`                             |
| `importWorker.customLivenessProbe`                   | Custom livenessProbe that overrides the default one                                                    | `{}`                            |
| `importWorker.customReadinessProbe`                  | Custom readinessProbe that overrides the default one                                                   | `{}`                            |
| `importWorker.customStartupProbe`                    | Custom startupProbe that overrides the default one                                                     | `{}`                            |
| `importWorker.resources.limits`                      | The resources limits for the import-worker containers                                                  | `{}`                            |
| `importWorker.resources.requests`                    | The requested resources for the import-worker containers                                               | `{}`                            |
| `importWorker.podSecurityContext.enabled`            | Enabled import-worker pods' Security Context                                                           | `true`                          |
| `importWorker.podSecurityContext.fsGroup`            | Set import-worker pod's Security Context fsGroup                                                       | `0`                             |
| `importWorker.containerSecurityContext.enabled`      | Enabled import-worker containers' Security Context                                                     | `true`                          |
| `importWorker.containerSecurityContext.runAsUser`    | Set import-worker containers' Security Context runAsUser                                               | `0`                             |
| `importWorker.containerSecurityContext.runAsNonRoot` | Set import-worker containers' Security Context runAsNonRoot                                            | `false`                         |
| `importWorker.configuration`                         | Configuration settings (env vars) for import-worker                                                    | `{}`                            |
| `importWorker.secretConfiguration`                   | Configuration settings (env vars) for import-worker                                                    | `""`                            |
| `importWorker.existingConfigMap`                     | The name of an existing ConfigMap with your custom configuration for import-worker                     | `""`                            |
| `importWorker.existingSecret`                        | The name of an existing ConfigMap with your custom configuration for import-worker                     | `""`                            |
| `importWorker.command`                               | Override default container command (useful when using custom images)                                   | `[]`                            |
| `importWorker.args`                                  | Override default container args (useful when using custom images)                                      | `[]`                            |
| `importWorker.hostAliases`                           | import-worker pods host aliases                                                                        | `[]`                            |
| `importWorker.podLabels`                             | Extra labels for import-worker pods                                                                    | `{}`                            |
| `importWorker.podAnnotations`                        | Annotations for import-worker pods                                                                     | `{}`                            |
| `importWorker.podAffinityPreset`                     | Pod affinity preset. Ignored if `importWorker.affinity` is set. Allowed values: `soft` or `hard`       | `""`                            |
| `importWorker.podAntiAffinityPreset`                 | Pod anti-affinity preset. Ignored if `importWorker.affinity` is set. Allowed values: `soft` or `hard`  | `soft`                          |
| `importWorker.nodeAffinityPreset.type`               | Node affinity preset type. Ignored if `importWorker.affinity` is set. Allowed values: `soft` or `hard` | `""`                            |
| `importWorker.nodeAffinityPreset.key`                | Node label key to match. Ignored if `importWorker.affinity` is set                                     | `""`                            |
| `importWorker.nodeAffinityPreset.values`             | Node label values to match. Ignored if `importWorker.affinity` is set                                  | `[]`                            |
| `importWorker.affinity`                              | Affinity for import-worker pods assignment                                                             | `{}`                            |
| `importWorker.nodeSelector`                          | Node labels for import-worker pods assignment                                                          | `{}`                            |
| `importWorker.tolerations`                           | Tolerations for import-worker pods assignment                                                          | `[]`                            |
| `importWorker.updateStrategy.type`                   | import-worker statefulset strategy type                                                                | `RollingUpdate`                 |
| `importWorker.priorityClassName`                     | import-worker pods' priorityClassName                                                                  | `""`                            |
| `importWorker.schedulerName`                         | Name of the k8s scheduler (other than default) for import-worker pods                                  | `""`                            |
| `importWorker.lifecycleHooks`                        | for the import-worker container(s) to automate configuration before or after startup                   | `{}`                            |
| `importWorker.extraEnvVars`                          | Array with extra environment variables to add to import-worker nodes                                   | `[]`                            |
| `importWorker.extraEnvVarsCM`                        | Name of existing ConfigMap containing extra env vars for import-worker nodes                           | `""`                            |
| `importWorker.extraEnvVarsSecret`                    | Name of existing Secret containing extra env vars for import-worker nodes                              | `""`                            |
| `importWorker.extraVolumes`                          | Optionally specify extra list of additional volumes for the import-worker pod(s)                       | `[]`                            |
| `importWorker.extraVolumeMounts`                     | Optionally specify extra list of additional volumeMounts for the import-worker container(s)            | `[]`                            |
| `importWorker.sidecars`                              | Add additional sidecar containers to the import-worker pod(s)                                          | `{}`                            |
| `importWorker.initContainers`                        | Add additional init containers to the import-worker pod(s)                                             | `{}`                            |


### import-worker ServiceAccount configuration

| Name                                                       | Description                                          | Value   |
| ---------------------------------------------------------- | ---------------------------------------------------- | ------- |
| `importWorker.serviceAccount.create`                       | Specifies whether a ServiceAccount should be created | `true`  |
| `importWorker.serviceAccount.name`                         | The name of the ServiceAccount to use.               | `""`    |
| `importWorker.serviceAccount.automountServiceAccountToken` | Mount service account token in the deployment        | `false` |


### lds-api Deployment Parameters

| Name                                                | Description                                                                                      | Value                           |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------- |
| `ldsApi.image.registry`                             | lds-api image registry                                                                           | `gcr.io/carto-onprem-artifacts` |
| `ldsApi.image.repository`                           | lds-api image repository                                                                         | `lds-api`                       |
| `ldsApi.image.tag`                                  | lds-api image tag (immutable tags are recommended)                                               | `""`                            |
| `ldsApi.image.pullPolicy`                           | lds-api image pull policy                                                                        | `IfNotPresent`                  |
| `ldsApi.image.pullSecrets`                          | lds-api image pull secrets                                                                       | `[]`                            |
| `ldsApi.replicaCount`                               | Number of lds-api replicas to deploy                                                             | `1`                             |
| `ldsApi.containerPorts.http`                        | lds-api HTTP container port                                                                      | `8004`                          |
| `ldsApi.livenessProbe.enabled`                      | Enable livenessProbe on lds-api containers                                                       | `true`                          |
| `ldsApi.livenessProbe.initialDelaySeconds`          | Initial delay seconds for livenessProbe                                                          | `10`                            |
| `ldsApi.livenessProbe.periodSeconds`                | Period seconds for livenessProbe                                                                 | `30`                            |
| `ldsApi.livenessProbe.timeoutSeconds`               | Timeout seconds for livenessProbe                                                                | `5`                             |
| `ldsApi.livenessProbe.failureThreshold`             | Failure threshold for livenessProbe                                                              | `5`                             |
| `ldsApi.livenessProbe.successThreshold`             | Success threshold for livenessProbe                                                              | `1`                             |
| `ldsApi.readinessProbe.enabled`                     | Enable readinessProbe on lds-api containers                                                      | `true`                          |
| `ldsApi.readinessProbe.initialDelaySeconds`         | Initial delay seconds for readinessProbe                                                         | `10`                            |
| `ldsApi.readinessProbe.periodSeconds`               | Period seconds for readinessProbe                                                                | `30`                            |
| `ldsApi.readinessProbe.timeoutSeconds`              | Timeout seconds for readinessProbe                                                               | `5`                             |
| `ldsApi.readinessProbe.failureThreshold`            | Failure threshold for readinessProbe                                                             | `5`                             |
| `ldsApi.readinessProbe.successThreshold`            | Success threshold for readinessProbe                                                             | `1`                             |
| `ldsApi.startupProbe.enabled`                       | Enable startupProbe on lds-api containers                                                        | `false`                         |
| `ldsApi.startupProbe.initialDelaySeconds`           | Initial delay seconds for startupProbe                                                           | `10`                            |
| `ldsApi.startupProbe.periodSeconds`                 | Period seconds for startupProbe                                                                  | `30`                            |
| `ldsApi.startupProbe.timeoutSeconds`                | Timeout seconds for startupProbe                                                                 | `5`                             |
| `ldsApi.startupProbe.failureThreshold`              | Failure threshold for startupProbe                                                               | `5`                             |
| `ldsApi.startupProbe.successThreshold`              | Success threshold for startupProbe                                                               | `1`                             |
| `ldsApi.customLivenessProbe`                        | Custom livenessProbe that overrides the default one                                              | `{}`                            |
| `ldsApi.customReadinessProbe`                       | Custom readinessProbe that overrides the default one                                             | `{}`                            |
| `ldsApi.customStartupProbe`                         | Custom startupProbe that overrides the default one                                               | `{}`                            |
| `ldsApi.autoscaling.enabled`                        | Enable autoscaling for the lds-api containers                                                    | `false`                         |
| `ldsApi.autoscaling.minReplicas`                    | The minimal number of containters for the workspldsace-api deployment                            | `1`                             |
| `ldsApi.autoscaling.maxReplicas`                    | The maximum number of containers for the lds-api deployment                                      | `2`                             |
| `ldsApi.autoscaling.targetCPUUtilizationPercentage` | The CPU utilization percentage used for scale up containers in lds-api deployment                | `75`                            |
| `ldsApi.resources.limits`                           | The resources limits for the lds-api containers                                                  | `{}`                            |
| `ldsApi.resources.requests`                         | The requested resources for the lds-api containers                                               | `{}`                            |
| `ldsApi.podSecurityContext.enabled`                 | Enabled lds-api pods' Security Context                                                           | `true`                          |
| `ldsApi.podSecurityContext.fsGroup`                 | Set lds-api pod's Security Context fsGroup                                                       | `0`                             |
| `ldsApi.containerSecurityContext.enabled`           | Enabled lds-api containers' Security Context                                                     | `true`                          |
| `ldsApi.containerSecurityContext.runAsUser`         | Set lds-api containers' Security Context runAsUser                                               | `0`                             |
| `ldsApi.containerSecurityContext.runAsNonRoot`      | Set lds-api containers' Security Context runAsNonRoot                                            | `false`                         |
| `ldsApi.configuration`                              | Configuration settings (env vars) for lds-api                                                    | `{}`                            |
| `ldsApi.secretConfiguration`                        | Configuration settings (env vars) for lds-api                                                    | `""`                            |
| `ldsApi.existingConfigMap`                          | The name of an existing ConfigMap with your custom configuration for lds-api                     | `""`                            |
| `ldsApi.existingSecret`                             | The name of an existing ConfigMap with your custom configuration for lds-api                     | `""`                            |
| `ldsApi.command`                                    | Override default container command (useful when using custom images)                             | `[]`                            |
| `ldsApi.args`                                       | Override default container args (useful when using custom images)                                | `[]`                            |
| `ldsApi.hostAliases`                                | lds-api pods host aliases                                                                        | `[]`                            |
| `ldsApi.podLabels`                                  | Extra labels for lds-api pods                                                                    | `{}`                            |
| `ldsApi.podAnnotations`                             | Annotations for lds-api pods                                                                     | `{}`                            |
| `ldsApi.podAffinityPreset`                          | Pod affinity preset. Ignored if `ldsApi.affinity` is set. Allowed values: `soft` or `hard`       | `""`                            |
| `ldsApi.podAntiAffinityPreset`                      | Pod anti-affinity preset. Ignored if `ldsApi.affinity` is set. Allowed values: `soft` or `hard`  | `soft`                          |
| `ldsApi.nodeAffinityPreset.type`                    | Node affinity preset type. Ignored if `ldsApi.affinity` is set. Allowed values: `soft` or `hard` | `""`                            |
| `ldsApi.nodeAffinityPreset.key`                     | Node label key to match. Ignored if `ldsApi.affinity` is set                                     | `""`                            |
| `ldsApi.nodeAffinityPreset.values`                  | Node label values to match. Ignored if `ldsApi.affinity` is set                                  | `[]`                            |
| `ldsApi.affinity`                                   | Affinity for lds-api pods assignment                                                             | `{}`                            |
| `ldsApi.nodeSelector`                               | Node labels for lds-api pods assignment                                                          | `{}`                            |
| `ldsApi.tolerations`                                | Tolerations for lds-api pods assignment                                                          | `[]`                            |
| `ldsApi.updateStrategy.type`                        | lds-api statefulset strategy type                                                                | `RollingUpdate`                 |
| `ldsApi.priorityClassName`                          | lds-api pods' priorityClassName                                                                  | `""`                            |
| `ldsApi.schedulerName`                              | Name of the k8s scheduler (other than default) for lds-api pods                                  | `""`                            |
| `ldsApi.lifecycleHooks`                             | for the lds-api container(s) to automate configuration before or after startup                   | `{}`                            |
| `ldsApi.extraEnvVars`                               | Array with extra environment variables to add to lds-api nodes                                   | `[]`                            |
| `ldsApi.extraEnvVarsCM`                             | Name of existing ConfigMap containing extra env vars for lds-api nodes                           | `""`                            |
| `ldsApi.extraEnvVarsSecret`                         | Name of existing Secret containing extra env vars for lds-api nodes                              | `""`                            |
| `ldsApi.extraVolumes`                               | Optionally specify extra list of additional volumes for the lds-api pod(s)                       | `[]`                            |
| `ldsApi.extraVolumeMounts`                          | Optionally specify extra list of additional volumeMounts for the lds-api container(s)            | `[]`                            |
| `ldsApi.sidecars`                                   | Add additional sidecar containers to the lds-api pod(s)                                          | `{}`                            |
| `ldsApi.initContainers`                             | Add additional init containers to the lds-api pod(s)                                             | `{}`                            |


### lds-api Service Parameters

| Name                                      | Description                                                                        | Value       |
| ----------------------------------------- | ---------------------------------------------------------------------------------- | ----------- |
| `ldsApi.service.type`                     | lds-api service type                                                               | `ClusterIP` |
| `ldsApi.service.ports.http`               | lds-api service HTTP port                                                          | `80`        |
| `ldsApi.service.nodePorts.http`           | Node port for HTTP                                                                 | `""`        |
| `ldsApi.service.clusterIP`                | lds-api service Cluster IP                                                         | `""`        |
| `ldsApi.service.loadBalancerIP`           | lds-api service Load Balancer IP                                                   | `""`        |
| `ldsApi.service.labelSelectorsOverride`   | Selector for lds-api service                                                       | `{}`        |
| `ldsApi.service.loadBalancerSourceRanges` | lds-api service Load Balancer sources                                              | `[]`        |
| `ldsApi.service.externalTrafficPolicy`    | lds-api service external traffic policy                                            | `Cluster`   |
| `ldsApi.service.annotations`              | Additional custom annotations for lds-api service                                  | `{}`        |
| `ldsApi.service.extraPorts`               | Extra ports to expose in lds-api service (normally used with the `sidecars` value) | `[]`        |


### lds-api ServiceAccount configuration

| Name                                                 | Description                                          | Value   |
| ---------------------------------------------------- | ---------------------------------------------------- | ------- |
| `ldsApi.serviceAccount.create`                       | Specifies whether a ServiceAccount should be created | `true`  |
| `ldsApi.serviceAccount.name`                         | The name of the ServiceAccount to use.               | `""`    |
| `ldsApi.serviceAccount.automountServiceAccountToken` | Mount service account token in the deployment        | `false` |


### maps-api Deployment Parameters

| Name                                                 | Description                                                                                       | Value                           |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ------------------------------- |
| `mapsApi.image.registry`                             | maps-api image registry                                                                           | `gcr.io/carto-onprem-artifacts` |
| `mapsApi.image.repository`                           | maps-api image repository                                                                         | `maps-api`                      |
| `mapsApi.image.tag`                                  | maps-api image tag (immutable tags are recommended)                                               | `""`                            |
| `mapsApi.image.pullPolicy`                           | maps-api image pull policy                                                                        | `IfNotPresent`                  |
| `mapsApi.image.pullSecrets`                          | maps-api image pull secrets                                                                       | `[]`                            |
| `mapsApi.replicaCount`                               | Number of maps-api replicas to deploy                                                             | `1`                             |
| `mapsApi.containerPorts.http`                        | maps-api HTTP container port                                                                      | `8002`                          |
| `mapsApi.livenessProbe.enabled`                      | Enable livenessProbe on maps-api containers                                                       | `true`                          |
| `mapsApi.livenessProbe.initialDelaySeconds`          | Initial delay seconds for livenessProbe                                                           | `10`                            |
| `mapsApi.livenessProbe.periodSeconds`                | Period seconds for livenessProbe                                                                  | `30`                            |
| `mapsApi.livenessProbe.timeoutSeconds`               | Timeout seconds for livenessProbe                                                                 | `5`                             |
| `mapsApi.livenessProbe.failureThreshold`             | Failure threshold for livenessProbe                                                               | `5`                             |
| `mapsApi.livenessProbe.successThreshold`             | Success threshold for livenessProbe                                                               | `1`                             |
| `mapsApi.readinessProbe.enabled`                     | Enable readinessProbe on maps-api containers                                                      | `true`                          |
| `mapsApi.readinessProbe.initialDelaySeconds`         | Initial delay seconds for readinessProbe                                                          | `10`                            |
| `mapsApi.readinessProbe.periodSeconds`               | Period seconds for readinessProbe                                                                 | `30`                            |
| `mapsApi.readinessProbe.timeoutSeconds`              | Timeout seconds for readinessProbe                                                                | `5`                             |
| `mapsApi.readinessProbe.failureThreshold`            | Failure threshold for readinessProbe                                                              | `5`                             |
| `mapsApi.readinessProbe.successThreshold`            | Success threshold for readinessProbe                                                              | `1`                             |
| `mapsApi.startupProbe.enabled`                       | Enable startupProbe on maps-api containers                                                        | `false`                         |
| `mapsApi.startupProbe.initialDelaySeconds`           | Initial delay seconds for startupProbe                                                            | `10`                            |
| `mapsApi.startupProbe.periodSeconds`                 | Period seconds for startupProbe                                                                   | `30`                            |
| `mapsApi.startupProbe.timeoutSeconds`                | Timeout seconds for startupProbe                                                                  | `5`                             |
| `mapsApi.startupProbe.failureThreshold`              | Failure threshold for startupProbe                                                                | `5`                             |
| `mapsApi.startupProbe.successThreshold`              | Success threshold for startupProbe                                                                | `1`                             |
| `mapsApi.customLivenessProbe`                        | Custom livenessProbe that overrides the default one                                               | `{}`                            |
| `mapsApi.customReadinessProbe`                       | Custom readinessProbe that overrides the default one                                              | `{}`                            |
| `mapsApi.customStartupProbe`                         | Custom startupProbe that overrides the default one                                                | `{}`                            |
| `mapsApi.autoscaling.enabled`                        | Enable autoscaling for the maps-api containers                                                    | `false`                         |
| `mapsApi.autoscaling.minReplicas`                    | The minimal number of containters for the maps-api deployment                                     | `2`                             |
| `mapsApi.autoscaling.maxReplicas`                    | The maximum number of containers for the maps-api deployment                                      | `3`                             |
| `mapsApi.autoscaling.targetCPUUtilizationPercentage` | The CPU utilization percentage used for scale up containers in maps-api deployment                | `75`                            |
| `mapsApi.resources.limits`                           | The resources limits for the maps-api containers                                                  | `{}`                            |
| `mapsApi.resources.requests`                         | The requested resources for the maps-api containers                                               | `{}`                            |
| `mapsApi.podSecurityContext.enabled`                 | Enabled maps-api pods' Security Context                                                           | `true`                          |
| `mapsApi.podSecurityContext.fsGroup`                 | Set maps-api pod's Security Context fsGroup                                                       | `0`                             |
| `mapsApi.containerSecurityContext.enabled`           | Enabled maps-api containers' Security Context                                                     | `true`                          |
| `mapsApi.containerSecurityContext.runAsUser`         | Set maps-api containers' Security Context runAsUser                                               | `0`                             |
| `mapsApi.containerSecurityContext.runAsNonRoot`      | Set maps-api containers' Security Context runAsNonRoot                                            | `false`                         |
| `mapsApi.configuration`                              | Configuration settings (env vars) for maps-api                                                    | `{}`                            |
| `mapsApi.secretConfiguration`                        | Configuration settings (env vars) for maps-api                                                    | `""`                            |
| `mapsApi.existingConfigMap`                          | The name of an existing ConfigMap with your custom configuration for maps-api                     | `""`                            |
| `mapsApi.existingSecret`                             | The name of an existing ConfigMap with your custom configuration for maps-api                     | `""`                            |
| `mapsApi.command`                                    | Override default container command (useful when using custom images)                              | `[]`                            |
| `mapsApi.args`                                       | Override default container args (useful when using custom images)                                 | `[]`                            |
| `mapsApi.hostAliases`                                | maps-api pods host aliases                                                                        | `[]`                            |
| `mapsApi.podLabels`                                  | Extra labels for maps-api pods                                                                    | `{}`                            |
| `mapsApi.podAnnotations`                             | Annotations for maps-api pods                                                                     | `{}`                            |
| `mapsApi.podAffinityPreset`                          | Pod affinity preset. Ignored if `mapsApi.affinity` is set. Allowed values: `soft` or `hard`       | `""`                            |
| `mapsApi.podAntiAffinityPreset`                      | Pod anti-affinity preset. Ignored if `mapsApi.affinity` is set. Allowed values: `soft` or `hard`  | `soft`                          |
| `mapsApi.nodeAffinityPreset.type`                    | Node affinity preset type. Ignored if `mapsApi.affinity` is set. Allowed values: `soft` or `hard` | `""`                            |
| `mapsApi.nodeAffinityPreset.key`                     | Node label key to match. Ignored if `mapsApi.affinity` is set                                     | `""`                            |
| `mapsApi.nodeAffinityPreset.values`                  | Node label values to match. Ignored if `mapsApi.affinity` is set                                  | `[]`                            |
| `mapsApi.affinity`                                   | Affinity for maps-api pods assignment                                                             | `{}`                            |
| `mapsApi.nodeSelector`                               | Node labels for maps-api pods assignment                                                          | `{}`                            |
| `mapsApi.tolerations`                                | Tolerations for maps-api pods assignment                                                          | `[]`                            |
| `mapsApi.updateStrategy.type`                        | maps-api statefulset strategy type                                                                | `RollingUpdate`                 |
| `mapsApi.priorityClassName`                          | maps-api pods' priorityClassName                                                                  | `""`                            |
| `mapsApi.schedulerName`                              | Name of the k8s scheduler (other than default) for maps-api pods                                  | `""`                            |
| `mapsApi.lifecycleHooks`                             | for the maps-api container(s) to automate configuration before or after startup                   | `{}`                            |
| `mapsApi.extraEnvVars`                               | Array with extra environment variables to add to maps-api nodes                                   | `[]`                            |
| `mapsApi.extraEnvVarsCM`                             | Name of existing ConfigMap containing extra env vars for maps-api nodes                           | `""`                            |
| `mapsApi.extraEnvVarsSecret`                         | Name of existing Secret containing extra env vars for maps-api nodes                              | `""`                            |
| `mapsApi.extraVolumes`                               | Optionally specify extra list of additional volumes for the maps-api pod(s)                       | `[]`                            |
| `mapsApi.extraVolumeMounts`                          | Optionally specify extra list of additional volumeMounts for the maps-api container(s)            | `[]`                            |
| `mapsApi.sidecars`                                   | Add additional sidecar containers to the maps-api pod(s)                                          | `{}`                            |
| `mapsApi.initContainers`                             | Add additional init containers to the maps-api pod(s)                                             | `{}`                            |


### maps-api Service Parameters

| Name                                       | Description                                                                         | Value       |
| ------------------------------------------ | ----------------------------------------------------------------------------------- | ----------- |
| `mapsApi.service.type`                     | maps-api service type                                                               | `ClusterIP` |
| `mapsApi.service.ports.http`               | maps-api service HTTP port                                                          | `80`        |
| `mapsApi.service.nodePorts.http`           | Node port for HTTP                                                                  | `""`        |
| `mapsApi.service.clusterIP`                | maps-api service Cluster IP                                                         | `""`        |
| `mapsApi.service.loadBalancerIP`           | maps-api service Load Balancer IP                                                   | `""`        |
| `mapsApi.service.labelSelectorsOverride`   | Selector for maps-api service                                                       | `{}`        |
| `mapsApi.service.loadBalancerSourceRanges` | maps-api service Load Balancer sources                                              | `[]`        |
| `mapsApi.service.externalTrafficPolicy`    | maps-api service external traffic policy                                            | `Cluster`   |
| `mapsApi.service.annotations`              | Additional custom annotations for maps-api service                                  | `{}`        |
| `mapsApi.service.extraPorts`               | Extra ports to expose in maps-api service (normally used with the `sidecars` value) | `[]`        |


### maps-api ServiceAccount configuration

| Name                                                  | Description                                          | Value   |
| ----------------------------------------------------- | ---------------------------------------------------- | ------- |
| `mapsApi.serviceAccount.create`                       | Specifies whether a ServiceAccount should be created | `true`  |
| `mapsApi.serviceAccount.name`                         | The name of the ServiceAccount to use.               | `""`    |
| `mapsApi.serviceAccount.automountServiceAccountToken` | Mount service account token in the deployment        | `false` |


### router Deployment Parameters

| Name                                                | Description                                                                                      | Value                           |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------- |
| `router.image.registry`                             | router image registry                                                                            | `gcr.io/carto-onprem-artifacts` |
| `router.image.repository`                           | router image repository                                                                          | `router`                        |
| `router.image.tag`                                  | router image tag (immutable tags are recommended)                                                | `""`                            |
| `router.image.pullPolicy`                           | router image pull policy                                                                         | `IfNotPresent`                  |
| `router.image.pullSecrets`                          | router image pull secrets                                                                        | `[]`                            |
| `router.replicaCount`                               | Number of router replicas to deploy                                                              | `1`                             |
| `router.containerPorts.http`                        | router HTTP container port                                                                       | `8080`                          |
| `router.containerPorts.https`                       | router HTTPS container port                                                                      | `8443`                          |
| `router.livenessProbe.enabled`                      | Enable livenessProbe on router containers                                                        | `true`                          |
| `router.livenessProbe.initialDelaySeconds`          | Initial delay seconds for livenessProbe                                                          | `10`                            |
| `router.livenessProbe.periodSeconds`                | Period seconds for livenessProbe                                                                 | `30`                            |
| `router.livenessProbe.timeoutSeconds`               | Timeout seconds for livenessProbe                                                                | `5`                             |
| `router.livenessProbe.failureThreshold`             | Failure threshold for livenessProbe                                                              | `5`                             |
| `router.livenessProbe.successThreshold`             | Success threshold for livenessProbe                                                              | `1`                             |
| `router.readinessProbe.enabled`                     | Enable readinessProbe on router containers                                                       | `true`                          |
| `router.readinessProbe.initialDelaySeconds`         | Initial delay seconds for readinessProbe                                                         | `10`                            |
| `router.readinessProbe.periodSeconds`               | Period seconds for readinessProbe                                                                | `30`                            |
| `router.readinessProbe.timeoutSeconds`              | Timeout seconds for readinessProbe                                                               | `5`                             |
| `router.readinessProbe.failureThreshold`            | Failure threshold for readinessProbe                                                             | `5`                             |
| `router.readinessProbe.successThreshold`            | Success threshold for readinessProbe                                                             | `1`                             |
| `router.startupProbe.enabled`                       | Enable startupProbe on router containers                                                         | `false`                         |
| `router.startupProbe.initialDelaySeconds`           | Initial delay seconds for startupProbe                                                           | `10`                            |
| `router.startupProbe.periodSeconds`                 | Period seconds for startupProbe                                                                  | `30`                            |
| `router.startupProbe.timeoutSeconds`                | Timeout seconds for startupProbe                                                                 | `5`                             |
| `router.startupProbe.failureThreshold`              | Failure threshold for startupProbe                                                               | `5`                             |
| `router.startupProbe.successThreshold`              | Success threshold for startupProbe                                                               | `1`                             |
| `router.customLivenessProbe`                        | Custom livenessProbe that overrides the default one                                              | `{}`                            |
| `router.customReadinessProbe`                       | Custom readinessProbe that overrides the default one                                             | `{}`                            |
| `router.customStartupProbe`                         | Custom startupProbe that overrides the default one                                               | `{}`                            |
| `router.autoscaling.enabled`                        | Enable autoscaling for the router containers                                                     | `false`                         |
| `router.autoscaling.minReplicas`                    | The minimal number of containters for the router deployment                                      | `1`                             |
| `router.autoscaling.maxReplicas`                    | The maximum number of containers for the router deployment                                       | `2`                             |
| `router.autoscaling.targetCPUUtilizationPercentage` | The CPU utilization percentage used for scale up containers in router deployment                 | `75`                            |
| `router.resources.limits`                           | The resources limits for the router containers                                                   | `{}`                            |
| `router.resources.requests`                         | The requested resources for the router containers                                                | `{}`                            |
| `router.podSecurityContext.enabled`                 | Enabled router pods' Security Context                                                            | `true`                          |
| `router.podSecurityContext.fsGroup`                 | Set router pod's Security Context fsGroup                                                        | `0`                             |
| `router.containerSecurityContext.enabled`           | Enabled router containers' Security Context                                                      | `true`                          |
| `router.containerSecurityContext.runAsUser`         | Set router containers' Security Context runAsUser                                                | `0`                             |
| `router.containerSecurityContext.runAsNonRoot`      | Set router containers' Security Context runAsNonRoot                                             | `false`                         |
| `router.configuration`                              | Configuration settings (env vars) for router                                                     | `{}`                            |
| `router.secretConfiguration`                        | Configuration settings (env vars) for router                                                     | `""`                            |
| `router.existingConfigMap`                          | The name of an existing ConfigMap with your custom configuration for router                      | `""`                            |
| `router.existingSecret`                             | The name of an existing ConfigMap with your custom configuration for router                      | `""`                            |
| `router.command`                                    | Override default container command (useful when using custom images)                             | `[]`                            |
| `router.args`                                       | Override default container args (useful when using custom images)                                | `[]`                            |
| `router.hostAliases`                                | router pods host aliases                                                                         | `[]`                            |
| `router.podLabels`                                  | Extra labels for router pods                                                                     | `{}`                            |
| `router.podAnnotations`                             | Annotations for router pods                                                                      | `{}`                            |
| `router.podAffinityPreset`                          | Pod affinity preset. Ignored if `router.affinity` is set. Allowed values: `soft` or `hard`       | `""`                            |
| `router.podAntiAffinityPreset`                      | Pod anti-affinity preset. Ignored if `router.affinity` is set. Allowed values: `soft` or `hard`  | `soft`                          |
| `router.nodeAffinityPreset.type`                    | Node affinity preset type. Ignored if `router.affinity` is set. Allowed values: `soft` or `hard` | `""`                            |
| `router.nodeAffinityPreset.key`                     | Node label key to match. Ignored if `router.affinity` is set                                     | `""`                            |
| `router.nodeAffinityPreset.values`                  | Node label values to match. Ignored if `router.affinity` is set                                  | `[]`                            |
| `router.affinity`                                   | Affinity for router pods assignment                                                              | `{}`                            |
| `router.nodeSelector`                               | Node labels for router pods assignment                                                           | `{}`                            |
| `router.tolerations`                                | Tolerations for router pods assignment                                                           | `[]`                            |
| `router.updateStrategy.type`                        | router statefulset strategy type                                                                 | `RollingUpdate`                 |
| `router.priorityClassName`                          | router pods' priorityClassName                                                                   | `""`                            |
| `router.schedulerName`                              | Name of the k8s scheduler (other than default) for router pods                                   | `""`                            |
| `router.lifecycleHooks`                             | for the router container(s) to automate configuration before or after startup                    | `{}`                            |
| `router.extraEnvVars`                               | Array with extra environment variables to add to router nodes                                    | `[]`                            |
| `router.extraEnvVarsCM`                             | Name of existing ConfigMap containing extra env vars for router nodes                            | `""`                            |
| `router.extraEnvVarsSecret`                         | Name of existing Secret containing extra env vars for router nodes                               | `""`                            |
| `router.extraVolumes`                               | Optionally specify extra list of additional volumes for the router pod(s)                        | `[]`                            |
| `router.extraVolumeMounts`                          | Optionally specify extra list of additional volumeMounts for the router container(s)             | `[]`                            |
| `router.sidecars`                                   | Add additional sidecar containers to the router pod(s)                                           | `{}`                            |
| `router.initContainers`                             | Add additional init containers to the router pod(s)                                              | `{}`                            |


### router Service Parameters

| Name                                      | Description                                                                       | Value       |
| ----------------------------------------- | --------------------------------------------------------------------------------- | ----------- |
| `router.service.type`                     | router service type                                                               | `ClusterIP` |
| `router.service.ports.http`               | router service HTTP port                                                          | `80`        |
| `router.service.ports.https`              | router service HTTPS port                                                         | `443`       |
| `router.service.nodePorts.http`           | Node port for HTTP                                                                | `""`        |
| `router.service.nodePorts.https`          | Node port for HTTPS                                                               | `""`        |
| `router.service.clusterIP`                | router service Cluster IP                                                         | `""`        |
| `router.service.loadBalancerIP`           | router service Load Balancer IP                                                   | `""`        |
| `router.service.labelSelectorsOverride`   | Selector for router service                                                       | `{}`        |
| `router.service.loadBalancerSourceRanges` | router service Load Balancer sources                                              | `[]`        |
| `router.service.externalTrafficPolicy`    | router service external traffic policy                                            | `Cluster`   |
| `router.service.annotations`              | Additional custom annotations for router service                                  | `{}`        |
| `router.service.extraPorts`               | Extra ports to expose in router service (normally used with the `sidecars` value) | `[]`        |


### router ServiceAccount configuration

| Name                                                 | Description                                          | Value   |
| ---------------------------------------------------- | ---------------------------------------------------- | ------- |
| `router.serviceAccount.create`                       | Specifies whether a ServiceAccount should be created | `true`  |
| `router.serviceAccount.name`                         | The name of the ServiceAccount to use.               | `""`    |
| `router.serviceAccount.automountServiceAccountToken` | Mount service account token in the deployment        | `false` |


### httpCache Deployment Parameters

| Name                                              | Description                                                                                         | Value                           |
| ------------------------------------------------- | --------------------------------------------------------------------------------------------------- | ------------------------------- |
| `httpCache.image.registry`                        | http-cache image registry                                                                           | `gcr.io/carto-onprem-artifacts` |
| `httpCache.image.repository`                      | http-cache image repository                                                                         | `http-cache`                    |
| `httpCache.image.tag`                             | http-cache image tag (immutable tags are recommended)                                               | `""`                            |
| `httpCache.image.pullPolicy`                      | http-cache image pull policy                                                                        | `IfNotPresent`                  |
| `httpCache.image.pullSecrets`                     | http-cache image pull secrets                                                                       | `[]`                            |
| `httpCache.replicaCount`                          | Number of http-cache replicas to deploy                                                             | `1`                             |
| `httpCache.containerPorts.http`                   | http-cache HTTP container port                                                                      | `6081`                          |
| `httpCache.livenessProbe.enabled`                 | Enable livenessProbe on http-cache containers                                                       | `true`                          |
| `httpCache.livenessProbe.initialDelaySeconds`     | Initial delay seconds for livenessProbe                                                             | `10`                            |
| `httpCache.livenessProbe.periodSeconds`           | Period seconds for livenessProbe                                                                    | `30`                            |
| `httpCache.livenessProbe.timeoutSeconds`          | Timeout seconds for livenessProbe                                                                   | `5`                             |
| `httpCache.livenessProbe.failureThreshold`        | Failure threshold for livenessProbe                                                                 | `5`                             |
| `httpCache.livenessProbe.successThreshold`        | Success threshold for livenessProbe                                                                 | `1`                             |
| `httpCache.readinessProbe.enabled`                | Enable readinessProbe on http-cache containers                                                      | `true`                          |
| `httpCache.readinessProbe.initialDelaySeconds`    | Initial delay seconds for readinessProbe                                                            | `10`                            |
| `httpCache.readinessProbe.periodSeconds`          | Period seconds for readinessProbe                                                                   | `30`                            |
| `httpCache.readinessProbe.timeoutSeconds`         | Timeout seconds for readinessProbe                                                                  | `5`                             |
| `httpCache.readinessProbe.failureThreshold`       | Failure threshold for readinessProbe                                                                | `5`                             |
| `httpCache.readinessProbe.successThreshold`       | Success threshold for readinessProbe                                                                | `1`                             |
| `httpCache.startupProbe.enabled`                  | Enable startupProbe on http-cache containers                                                        | `false`                         |
| `httpCache.startupProbe.initialDelaySeconds`      | Initial delay seconds for startupProbe                                                              | `10`                            |
| `httpCache.startupProbe.periodSeconds`            | Period seconds for startupProbe                                                                     | `30`                            |
| `httpCache.startupProbe.timeoutSeconds`           | Timeout seconds for startupProbe                                                                    | `5`                             |
| `httpCache.startupProbe.failureThreshold`         | Failure threshold for startupProbe                                                                  | `5`                             |
| `httpCache.startupProbe.successThreshold`         | Success threshold for startupProbe                                                                  | `1`                             |
| `httpCache.customLivenessProbe`                   | Custom livenessProbe that overrides the default one                                                 | `{}`                            |
| `httpCache.customReadinessProbe`                  | Custom readinessProbe that overrides the default one                                                | `{}`                            |
| `httpCache.customStartupProbe`                    | Custom startupProbe that overrides the default one                                                  | `{}`                            |
| `httpCache.resources.limits`                      | The resources limits for the http-cache containers                                                  | `{}`                            |
| `httpCache.resources.requests`                    | The requested resources for the http-cache containers                                               | `{}`                            |
| `httpCache.podSecurityContext.enabled`            | Enabled http-cache pods' Security Context                                                           | `true`                          |
| `httpCache.podSecurityContext.fsGroup`            | Set http-cache pod's Security Context fsGroup                                                       | `0`                             |
| `httpCache.containerSecurityContext.enabled`      | Enabled http-cache containers' Security Context                                                     | `true`                          |
| `httpCache.containerSecurityContext.runAsUser`    | Set http-cache containers' Security Context runAsUser                                               | `0`                             |
| `httpCache.containerSecurityContext.runAsNonRoot` | Set http-cache containers' Security Context runAsNonRoot                                            | `false`                         |
| `httpCache.configuration`                         | Configuration settings (env vars) for http-cache                                                    | `{}`                            |
| `httpCache.secretConfiguration`                   | Configuration settings (env vars) for http-cache                                                    | `""`                            |
| `httpCache.existingConfigMap`                     | The name of an existing ConfigMap with your custom configuration for http-cache                     | `""`                            |
| `httpCache.existingSecret`                        | The name of an existing ConfigMap with your custom configuration for http-cache                     | `""`                            |
| `httpCache.command`                               | Override default container command (useful when using custom images)                                | `[]`                            |
| `httpCache.args`                                  | Override default container args (useful when using custom images)                                   | `[]`                            |
| `httpCache.hostAliases`                           | http-cache pods host aliases                                                                        | `[]`                            |
| `httpCache.podLabels`                             | Extra labels for http-cache pods                                                                    | `{}`                            |
| `httpCache.podAnnotations`                        | Annotations for http-cache pods                                                                     | `{}`                            |
| `httpCache.podAffinityPreset`                     | Pod affinity preset. Ignored if `httpCache.affinity` is set. Allowed values: `soft` or `hard`       | `""`                            |
| `httpCache.podAntiAffinityPreset`                 | Pod anti-affinity preset. Ignored if `httpCache.affinity` is set. Allowed values: `soft` or `hard`  | `soft`                          |
| `httpCache.nodeAffinityPreset.type`               | Node affinity preset type. Ignored if `httpCache.affinity` is set. Allowed values: `soft` or `hard` | `""`                            |
| `httpCache.nodeAffinityPreset.key`                | Node label key to match. Ignored if `httpCache.affinity` is set                                     | `""`                            |
| `httpCache.nodeAffinityPreset.values`             | Node label values to match. Ignored if `httpCache.affinity` is set                                  | `[]`                            |
| `httpCache.affinity`                              | Affinity for http-cache pods assignment                                                             | `{}`                            |
| `httpCache.nodeSelector`                          | Node labels for http-cache pods assignment                                                          | `{}`                            |
| `httpCache.tolerations`                           | Tolerations for http-cache pods assignment                                                          | `[]`                            |
| `httpCache.updateStrategy.type`                   | http-cache statefulset strategy type                                                                | `RollingUpdate`                 |
| `httpCache.priorityClassName`                     | http-cache pods' priorityClassName                                                                  | `""`                            |
| `httpCache.schedulerName`                         | Name of the k8s scheduler (other than default) for http-cache pods                                  | `""`                            |
| `httpCache.lifecycleHooks`                        | for the http-cache container(s) to automate configuration before or after startup                   | `{}`                            |
| `httpCache.extraEnvVars`                          | Array with extra environment variables to add to http-cache nodes                                   | `[]`                            |
| `httpCache.extraEnvVarsCM`                        | Name of existing ConfigMap containing extra env vars for http-cache nodes                           | `""`                            |
| `httpCache.extraEnvVarsSecret`                    | Name of existing Secret containing extra env vars for http-cache nodes                              | `""`                            |
| `httpCache.extraVolumes`                          | Optionally specify extra list of additional volumes for the http-cache pod(s)                       | `[]`                            |
| `httpCache.extraVolumeMounts`                     | Optionally specify extra list of additional volumeMounts for the http-cache container(s)            | `[]`                            |
| `httpCache.sidecars`                              | Add additional sidecar containers to the http-cache pod(s)                                          | `{}`                            |
| `httpCache.initContainers`                        | Add additional init containers to the http-cache pod(s)                                             | `{}`                            |


### http-cache Service Parameters

| Name                                         | Description                                                                           | Value       |
| -------------------------------------------- | ------------------------------------------------------------------------------------- | ----------- |
| `httpCache.service.type`                     | http-cache service type                                                               | `ClusterIP` |
| `httpCache.service.ports.http`               | http-cache service HTTP port                                                          | `80`        |
| `httpCache.service.nodePorts.http`           | Node port for HTTP                                                                    | `""`        |
| `httpCache.service.clusterIP`                | http-cache service Cluster IP                                                         | `""`        |
| `httpCache.service.loadBalancerIP`           | http-cache service Load Balancer IP                                                   | `""`        |
| `httpCache.service.labelSelectorsOverride`   | Selector for http-cache service                                                       | `{}`        |
| `httpCache.service.loadBalancerSourceRanges` | http-cache service Load Balancer sources                                              | `[]`        |
| `httpCache.service.externalTrafficPolicy`    | http-cache service external traffic policy                                            | `Cluster`   |
| `httpCache.service.annotations`              | Additional custom annotations for http-cache service                                  | `{}`        |
| `httpCache.service.extraPorts`               | Extra ports to expose in http-cache service (normally used with the `sidecars` value) | `[]`        |


### http-cache ServiceAccount configuration

| Name                                                    | Description                                          | Value   |
| ------------------------------------------------------- | ---------------------------------------------------- | ------- |
| `httpCache.serviceAccount.create`                       | Specifies whether a ServiceAccount should be created | `true`  |
| `httpCache.serviceAccount.name`                         | The name of the ServiceAccount to use.               | `""`    |
| `httpCache.serviceAccount.automountServiceAccountToken` | Mount service account token in the deployment        | `false` |


### cdnInvalidatorSub Deployment Parameters

| Name                                                      | Description                                                                                                 | Value                           |
| --------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------------------------------- |
| `cdnInvalidatorSub.image.registry`                        | cdn-invalidator-sub image registry                                                                          | `gcr.io/carto-onprem-artifacts` |
| `cdnInvalidatorSub.image.repository`                      | cdn-invalidator-sub image repository                                                                        | `consumers/cdn-invalidator-sub` |
| `cdnInvalidatorSub.image.tag`                             | cdn-invalidator-sub image tag (immutable tags are recommended)                                              | `""`                            |
| `cdnInvalidatorSub.image.pullPolicy`                      | cdn-invalidator-sub image pull policy                                                                       | `IfNotPresent`                  |
| `cdnInvalidatorSub.image.pullSecrets`                     | cdn-invalidator-sub image pull secrets                                                                      | `[]`                            |
| `cdnInvalidatorSub.replicaCount`                          | Number of cdnInvalidatorSub replicas to deploy                                                              | `1`                             |
| `cdnInvalidatorSub.containerPorts.http`                   | cdnInvalidatorSub HTTP container port                                                                       | `3000`                          |
| `cdnInvalidatorSub.livenessProbe.enabled`                 | Enable livenessProbe on cdnInvalidatorSub containers                                                        | `false`                         |
| `cdnInvalidatorSub.livenessProbe.initialDelaySeconds`     | Initial delay seconds for livenessProbe                                                                     | `10`                            |
| `cdnInvalidatorSub.livenessProbe.periodSeconds`           | Period seconds for livenessProbe                                                                            | `30`                            |
| `cdnInvalidatorSub.livenessProbe.timeoutSeconds`          | Timeout seconds for livenessProbe                                                                           | `5`                             |
| `cdnInvalidatorSub.livenessProbe.failureThreshold`        | Failure threshold for livenessProbe                                                                         | `5`                             |
| `cdnInvalidatorSub.livenessProbe.successThreshold`        | Success threshold for livenessProbe                                                                         | `1`                             |
| `cdnInvalidatorSub.readinessProbe.enabled`                | Enable readinessProbe on cdnInvalidatorSub containers                                                       | `false`                         |
| `cdnInvalidatorSub.readinessProbe.initialDelaySeconds`    | Initial delay seconds for readinessProbe                                                                    | `10`                            |
| `cdnInvalidatorSub.readinessProbe.periodSeconds`          | Period seconds for readinessProbe                                                                           | `30`                            |
| `cdnInvalidatorSub.readinessProbe.timeoutSeconds`         | Timeout seconds for readinessProbe                                                                          | `5`                             |
| `cdnInvalidatorSub.readinessProbe.failureThreshold`       | Failure threshold for readinessProbe                                                                        | `5`                             |
| `cdnInvalidatorSub.readinessProbe.successThreshold`       | Success threshold for readinessProbe                                                                        | `1`                             |
| `cdnInvalidatorSub.startupProbe.enabled`                  | Enable startupProbe on cdnInvalidatorSub containers                                                         | `false`                         |
| `cdnInvalidatorSub.startupProbe.initialDelaySeconds`      | Initial delay seconds for startupProbe                                                                      | `10`                            |
| `cdnInvalidatorSub.startupProbe.periodSeconds`            | Period seconds for startupProbe                                                                             | `30`                            |
| `cdnInvalidatorSub.startupProbe.timeoutSeconds`           | Timeout seconds for startupProbe                                                                            | `5`                             |
| `cdnInvalidatorSub.startupProbe.failureThreshold`         | Failure threshold for startupProbe                                                                          | `5`                             |
| `cdnInvalidatorSub.startupProbe.successThreshold`         | Success threshold for startupProbe                                                                          | `1`                             |
| `cdnInvalidatorSub.customLivenessProbe`                   | Custom livenessProbe that overrides the default one                                                         | `{}`                            |
| `cdnInvalidatorSub.customReadinessProbe`                  | Custom readinessProbe that overrides the default one                                                        | `{}`                            |
| `cdnInvalidatorSub.customStartupProbe`                    | Custom startupProbe that overrides the default one                                                          | `{}`                            |
| `cdnInvalidatorSub.resources.limits`                      | The resources limits for the cdnInvalidatorSub containers                                                   | `{}`                            |
| `cdnInvalidatorSub.resources.requests`                    | The requested resources for the cdnInvalidatorSub containers                                                | `{}`                            |
| `cdnInvalidatorSub.podSecurityContext.enabled`            | Enabled cdnInvalidatorSub pods' Security Context                                                            | `true`                          |
| `cdnInvalidatorSub.podSecurityContext.fsGroup`            | Set cdnInvalidatorSub pod's Security Context fsGroup                                                        | `0`                             |
| `cdnInvalidatorSub.containerSecurityContext.enabled`      | Enabled cdnInvalidatorSub containers' Security Context                                                      | `true`                          |
| `cdnInvalidatorSub.containerSecurityContext.runAsUser`    | Set cdnInvalidatorSub containers' Security Context runAsUser                                                | `0`                             |
| `cdnInvalidatorSub.containerSecurityContext.runAsNonRoot` | Set cdnInvalidatorSub containers' Security Context runAsNonRoot                                             | `false`                         |
| `cdnInvalidatorSub.configuration`                         | Configuration settings (env vars) for cdnInvalidatorSub                                                     | `{}`                            |
| `cdnInvalidatorSub.secretConfiguration`                   | Configuration settings (env vars) for cdnInvalidatorSub                                                     | `""`                            |
| `cdnInvalidatorSub.existingConfigMap`                     | The name of an existing ConfigMap with your custom configuration for cdnInvalidatorSub                      | `""`                            |
| `cdnInvalidatorSub.existingSecret`                        | The name of an existing ConfigMap with your custom configuration for cdnInvalidatorSub                      | `""`                            |
| `cdnInvalidatorSub.command`                               | Override default container command (useful when using custom images)                                        | `[]`                            |
| `cdnInvalidatorSub.args`                                  | Override default container args (useful when using custom images)                                           | `[]`                            |
| `cdnInvalidatorSub.hostAliases`                           | cdnInvalidatorSub pods host aliases                                                                         | `[]`                            |
| `cdnInvalidatorSub.podLabels`                             | Extra labels for cdnInvalidatorSub pods                                                                     | `{}`                            |
| `cdnInvalidatorSub.podAnnotations`                        | Annotations for cdnInvalidatorSub pods                                                                      | `{}`                            |
| `cdnInvalidatorSub.podAffinityPreset`                     | Pod affinity preset. Ignored if `cdnInvalidatorSub.affinity` is set. Allowed values: `soft` or `hard`       | `""`                            |
| `cdnInvalidatorSub.podAntiAffinityPreset`                 | Pod anti-affinity preset. Ignored if `cdnInvalidatorSub.affinity` is set. Allowed values: `soft` or `hard`  | `soft`                          |
| `cdnInvalidatorSub.nodeAffinityPreset.type`               | Node affinity preset type. Ignored if `cdnInvalidatorSub.affinity` is set. Allowed values: `soft` or `hard` | `""`                            |
| `cdnInvalidatorSub.nodeAffinityPreset.key`                | Node label key to match. Ignored if `cdnInvalidatorSub.affinity` is set                                     | `""`                            |
| `cdnInvalidatorSub.nodeAffinityPreset.values`             | Node label values to match. Ignored if `cdnInvalidatorSub.affinity` is set                                  | `[]`                            |
| `cdnInvalidatorSub.affinity`                              | Affinity for cdnInvalidatorSub pods assignment                                                              | `{}`                            |
| `cdnInvalidatorSub.nodeSelector`                          | Node labels for cdnInvalidatorSub pods assignment                                                           | `{}`                            |
| `cdnInvalidatorSub.tolerations`                           | Tolerations for cdnInvalidatorSub pods assignment                                                           | `[]`                            |
| `cdnInvalidatorSub.updateStrategy.type`                   | cdnInvalidatorSub statefulset strategy type                                                                 | `RollingUpdate`                 |
| `cdnInvalidatorSub.priorityClassName`                     | cdnInvalidatorSub pods' priorityClassName                                                                   | `""`                            |
| `cdnInvalidatorSub.schedulerName`                         | Name of the k8s scheduler (other than default) for cdnInvalidatorSub pods                                   | `""`                            |
| `cdnInvalidatorSub.lifecycleHooks`                        | for the cdnInvalidatorSub container(s) to automate configuration before or after startup                    | `{}`                            |
| `cdnInvalidatorSub.extraEnvVars`                          | Array with extra environment variables to add to cdnInvalidatorSub nodes                                    | `[]`                            |
| `cdnInvalidatorSub.extraEnvVarsCM`                        | Name of existing ConfigMap containing extra env vars for cdnInvalidatorSub nodes                            | `""`                            |
| `cdnInvalidatorSub.extraEnvVarsSecret`                    | Name of existing Secret containing extra env vars for cdnInvalidatorSub nodes                               | `""`                            |
| `cdnInvalidatorSub.extraVolumes`                          | Optionally specify extra list of additional volumes for the cdnInvalidatorSub pod(s)                        | `[]`                            |
| `cdnInvalidatorSub.extraVolumeMounts`                     | Optionally specify extra list of additional volumeMounts for the cdnInvalidatorSub container(s)             | `[]`                            |
| `cdnInvalidatorSub.sidecars`                              | Add additional sidecar containers to the cdnInvalidatorSub pod(s)                                           | `{}`                            |
| `cdnInvalidatorSub.initContainers`                        | Add additional init containers to the cdnInvalidatorSub pod(s)                                              | `{}`                            |


### cdnInvalidatorSub Service Parameters

| Name                                                 | Description                                                                                  | Value       |
| ---------------------------------------------------- | -------------------------------------------------------------------------------------------- | ----------- |
| `cdnInvalidatorSub.service.type`                     | cdnInvalidatorSub service type                                                               | `ClusterIP` |
| `cdnInvalidatorSub.service.ports.http`               | cdnInvalidatorSub service HTTP port                                                          | `80`        |
| `cdnInvalidatorSub.service.nodePorts.http`           | Node port for HTTP                                                                           | `""`        |
| `cdnInvalidatorSub.service.nodePorts.https`          | Node port for HTTPS                                                                          | `""`        |
| `cdnInvalidatorSub.service.clusterIP`                | cdnInvalidatorSub service Cluster IP                                                         | `""`        |
| `cdnInvalidatorSub.service.loadBalancerIP`           | cdnInvalidatorSub service Load Balancer IP                                                   | `""`        |
| `cdnInvalidatorSub.service.labelSelectorsOverride`   | Selector for cdnInvalidatorSub service                                                       | `{}`        |
| `cdnInvalidatorSub.service.loadBalancerSourceRanges` | cdnInvalidatorSub service Load Balancer sources                                              | `[]`        |
| `cdnInvalidatorSub.service.externalTrafficPolicy`    | cdnInvalidatorSub service external traffic policy                                            | `Cluster`   |
| `cdnInvalidatorSub.service.annotations`              | Additional custom annotations for cdnInvalidatorSub service                                  | `{}`        |
| `cdnInvalidatorSub.service.extraPorts`               | Extra ports to expose in cdnInvalidatorSub service (normally used with the `sidecars` value) | `[]`        |


### cdnInvalidatorSub ServiceAccount configuration

| Name                                                            | Description                                          | Value   |
| --------------------------------------------------------------- | ---------------------------------------------------- | ------- |
| `cdnInvalidatorSub.serviceAccount.create`                       | Specifies whether a ServiceAccount should be created | `true`  |
| `cdnInvalidatorSub.serviceAccount.name`                         | The name of the ServiceAccount to use.               | `""`    |
| `cdnInvalidatorSub.serviceAccount.automountServiceAccountToken` | Mount service account token in the deployment        | `false` |


### workspace-api Deployment Parameters

| Name                                                      | Description                                                                                            | Value                           |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ | ------------------------------- |
| `workspaceApi.image.registry`                             | workspace-api image registry                                                                           | `gcr.io/carto-onprem-artifacts` |
| `workspaceApi.image.repository`                           | workspace-api image repository                                                                         | `workspace-api`                 |
| `workspaceApi.image.tag`                                  | workspace-api image tag (immutable tags are recommended)                                               | `""`                            |
| `workspaceApi.image.pullPolicy`                           | workspace-api image pull policy                                                                        | `IfNotPresent`                  |
| `workspaceApi.image.pullSecrets`                          | workspace-api image pull secrets                                                                       | `[]`                            |
| `workspaceApi.replicaCount`                               | Number of workspace-api replicas to deploy                                                             | `1`                             |
| `workspaceApi.containerPorts.http`                        | workspace-api HTTP container port                                                                      | `8001`                          |
| `workspaceApi.livenessProbe.enabled`                      | Enable livenessProbe on workspace-api containers                                                       | `true`                          |
| `workspaceApi.livenessProbe.initialDelaySeconds`          | Initial delay seconds for livenessProbe                                                                | `10`                            |
| `workspaceApi.livenessProbe.periodSeconds`                | Period seconds for livenessProbe                                                                       | `30`                            |
| `workspaceApi.livenessProbe.timeoutSeconds`               | Timeout seconds for livenessProbe                                                                      | `5`                             |
| `workspaceApi.livenessProbe.failureThreshold`             | Failure threshold for livenessProbe                                                                    | `5`                             |
| `workspaceApi.livenessProbe.successThreshold`             | Success threshold for livenessProbe                                                                    | `1`                             |
| `workspaceApi.readinessProbe.enabled`                     | Enable readinessProbe on workspace-api containers                                                      | `true`                          |
| `workspaceApi.readinessProbe.initialDelaySeconds`         | Initial delay seconds for readinessProbe                                                               | `10`                            |
| `workspaceApi.readinessProbe.periodSeconds`               | Period seconds for readinessProbe                                                                      | `30`                            |
| `workspaceApi.readinessProbe.timeoutSeconds`              | Timeout seconds for readinessProbe                                                                     | `5`                             |
| `workspaceApi.readinessProbe.failureThreshold`            | Failure threshold for readinessProbe                                                                   | `5`                             |
| `workspaceApi.readinessProbe.successThreshold`            | Success threshold for readinessProbe                                                                   | `1`                             |
| `workspaceApi.startupProbe.enabled`                       | Enable startupProbe on workspace-api containers                                                        | `false`                         |
| `workspaceApi.startupProbe.initialDelaySeconds`           | Initial delay seconds for startupProbe                                                                 | `10`                            |
| `workspaceApi.startupProbe.periodSeconds`                 | Period seconds for startupProbe                                                                        | `30`                            |
| `workspaceApi.startupProbe.timeoutSeconds`                | Timeout seconds for startupProbe                                                                       | `5`                             |
| `workspaceApi.startupProbe.failureThreshold`              | Failure threshold for startupProbe                                                                     | `5`                             |
| `workspaceApi.startupProbe.successThreshold`              | Success threshold for startupProbe                                                                     | `1`                             |
| `workspaceApi.customLivenessProbe`                        | Custom livenessProbe that overrides the default one                                                    | `{}`                            |
| `workspaceApi.customReadinessProbe`                       | Custom readinessProbe that overrides the default one                                                   | `{}`                            |
| `workspaceApi.customStartupProbe`                         | Custom startupProbe that overrides the default one                                                     | `{}`                            |
| `workspaceApi.autoscaling.enabled`                        | Enable autoscaling for the workspace-api containers                                                    | `false`                         |
| `workspaceApi.autoscaling.minReplicas`                    | The minimal number of containters for the workspace-api deployment                                     | `2`                             |
| `workspaceApi.autoscaling.maxReplicas`                    | The maximum number of containers for the workspace-api deployment                                      | `3`                             |
| `workspaceApi.autoscaling.targetCPUUtilizationPercentage` | The CPU utilization percentage used for scale up containers in workspace-api deployment                | `75`                            |
| `workspaceApi.resources.limits`                           | The resources limits for the workspace-api containers                                                  | `{}`                            |
| `workspaceApi.resources.requests`                         | The requested resources for the workspace-api containers                                               | `{}`                            |
| `workspaceApi.podSecurityContext.enabled`                 | Enabled workspace-api pods' Security Context                                                           | `true`                          |
| `workspaceApi.podSecurityContext.fsGroup`                 | Set workspace-api pod's Security Context fsGroup                                                       | `0`                             |
| `workspaceApi.containerSecurityContext.enabled`           | Enabled workspace-api containers' Security Context                                                     | `true`                          |
| `workspaceApi.containerSecurityContext.runAsUser`         | Set workspace-api containers' Security Context runAsUser                                               | `0`                             |
| `workspaceApi.containerSecurityContext.runAsNonRoot`      | Set workspace-api containers' Security Context runAsNonRoot                                            | `false`                         |
| `workspaceApi.configuration`                              | Configuration settings (env vars) for workspace-api                                                    | `{}`                            |
| `workspaceApi.secretConfiguration`                        | Configuration settings (env vars) for workspace-api                                                    | `""`                            |
| `workspaceApi.existingConfigMap`                          | The name of an existing ConfigMap with your custom configuration for workspace-api                     | `""`                            |
| `workspaceApi.existingSecret`                             | The name of an existing ConfigMap with your custom configuration for workspace-api                     | `""`                            |
| `workspaceApi.command`                                    | Override default container command (useful when using custom images)                                   | `[]`                            |
| `workspaceApi.args`                                       | Override default container args (useful when using custom images)                                      | `[]`                            |
| `workspaceApi.hostAliases`                                | workspace-api pods host aliases                                                                        | `[]`                            |
| `workspaceApi.podLabels`                                  | Extra labels for workspace-api pods                                                                    | `{}`                            |
| `workspaceApi.podAnnotations`                             | Annotations for workspace-api pods                                                                     | `{}`                            |
| `workspaceApi.podAffinityPreset`                          | Pod affinity preset. Ignored if `workspaceApi.affinity` is set. Allowed values: `soft` or `hard`       | `""`                            |
| `workspaceApi.podAntiAffinityPreset`                      | Pod anti-affinity preset. Ignored if `workspaceApi.affinity` is set. Allowed values: `soft` or `hard`  | `soft`                          |
| `workspaceApi.nodeAffinityPreset.type`                    | Node affinity preset type. Ignored if `workspaceApi.affinity` is set. Allowed values: `soft` or `hard` | `""`                            |
| `workspaceApi.nodeAffinityPreset.key`                     | Node label key to match. Ignored if `workspaceApi.affinity` is set                                     | `""`                            |
| `workspaceApi.nodeAffinityPreset.values`                  | Node label values to match. Ignored if `workspaceApi.affinity` is set                                  | `[]`                            |
| `workspaceApi.affinity`                                   | Affinity for workspace-api pods assignment                                                             | `{}`                            |
| `workspaceApi.nodeSelector`                               | Node labels for workspace-api pods assignment                                                          | `{}`                            |
| `workspaceApi.tolerations`                                | Tolerations for workspace-api pods assignment                                                          | `[]`                            |
| `workspaceApi.updateStrategy.type`                        | workspace-api statefulset strategy type                                                                | `RollingUpdate`                 |
| `workspaceApi.priorityClassName`                          | workspace-api pods' priorityClassName                                                                  | `""`                            |
| `workspaceApi.schedulerName`                              | Name of the k8s scheduler (other than default) for workspace-api pods                                  | `""`                            |
| `workspaceApi.lifecycleHooks`                             | for the workspace-api container(s) to automate configuration before or after startup                   | `{}`                            |
| `workspaceApi.extraEnvVars`                               | Array with extra environment variables to add to workspace-api nodes                                   | `[]`                            |
| `workspaceApi.extraEnvVarsCM`                             | Name of existing ConfigMap containing extra env vars for workspace-api nodes                           | `""`                            |
| `workspaceApi.extraEnvVarsSecret`                         | Name of existing Secret containing extra env vars for workspace-api nodes                              | `""`                            |
| `workspaceApi.extraVolumes`                               | Optionally specify extra list of additional volumes for the workspace-api pod(s)                       | `[]`                            |
| `workspaceApi.extraVolumeMounts`                          | Optionally specify extra list of additional volumeMounts for the workspace-api container(s)            | `[]`                            |
| `workspaceApi.sidecars`                                   | Add additional sidecar containers to the workspace-api pod(s)                                          | `{}`                            |
| `workspaceApi.initContainers`                             | Add additional init containers to the workspace-api pod(s)                                             | `{}`                            |


### workspace-api Service Parameters

| Name                                            | Description                                                                              | Value       |
| ----------------------------------------------- | ---------------------------------------------------------------------------------------- | ----------- |
| `workspaceApi.service.type`                     | workspace-api service type                                                               | `ClusterIP` |
| `workspaceApi.service.ports.http`               | workspace-api service HTTP port                                                          | `80`        |
| `workspaceApi.service.nodePorts.http`           | Node port for HTTP                                                                       | `""`        |
| `workspaceApi.service.clusterIP`                | workspace-api service Cluster IP                                                         | `""`        |
| `workspaceApi.service.loadBalancerIP`           | workspace-api service Load Balancer IP                                                   | `""`        |
| `workspaceApi.service.labelSelectorsOverride`   | Selector for workspace-api service                                                       | `{}`        |
| `workspaceApi.service.loadBalancerSourceRanges` | workspace-api service Load Balancer sources                                              | `[]`        |
| `workspaceApi.service.externalTrafficPolicy`    | workspace-api service external traffic policy                                            | `Cluster`   |
| `workspaceApi.service.annotations`              | Additional custom annotations for workspace-api service                                  | `{}`        |
| `workspaceApi.service.extraPorts`               | Extra ports to expose in workspace-api service (normally used with the `sidecars` value) | `[]`        |


### workspace-api ServiceAccount configuration

| Name                                                       | Description                                          | Value   |
| ---------------------------------------------------------- | ---------------------------------------------------- | ------- |
| `workspaceApi.serviceAccount.create`                       | Specifies whether a ServiceAccount should be created | `true`  |
| `workspaceApi.serviceAccount.name`                         | The name of the ServiceAccount to use.               | `""`    |
| `workspaceApi.serviceAccount.automountServiceAccountToken` | Mount service account token in the deployment        | `false` |


### workspace-subscriber Deployment Parameters

| Name                                                        | Description                                                                                                   | Value                           |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| `workspaceSubscriber.image.registry`                        | workspace-subscriber image registry                                                                           | `gcr.io/carto-onprem-artifacts` |
| `workspaceSubscriber.image.repository`                      | workspace-subscriber image repository                                                                         | `workspace-api`                 |
| `workspaceSubscriber.image.tag`                             | workspace-subscriber image tag (immutable tags are recommended)                                               | `""`                            |
| `workspaceSubscriber.image.pullPolicy`                      | workspace-subscriber image pull policy                                                                        | `IfNotPresent`                  |
| `workspaceSubscriber.image.pullSecrets`                     | workspace-subscriber image pull secrets                                                                       | `[]`                            |
| `workspaceSubscriber.replicaCount`                          | Number of workspace-subscriber replicas to deploy                                                             | `1`                             |
| `workspaceSubscriber.customLivenessProbe`                   | Custom livenessProbe that overrides the default one                                                           | `{}`                            |
| `workspaceSubscriber.customReadinessProbe`                  | Custom readinessProbe that overrides the default one                                                          | `{}`                            |
| `workspaceSubscriber.customStartupProbe`                    | Custom startupProbe that overrides the default one                                                            | `{}`                            |
| `workspaceSubscriber.resources.limits`                      | The resources limits for the workspace-subscriber containers                                                  | `{}`                            |
| `workspaceSubscriber.resources.requests`                    | The requested resources for the workspace-subscriber containers                                               | `{}`                            |
| `workspaceSubscriber.podSecurityContext.enabled`            | Enabled workspace-subscriber pods' Security Context                                                           | `true`                          |
| `workspaceSubscriber.podSecurityContext.fsGroup`            | Set workspace-subscriber pod's Security Context fsGroup                                                       | `0`                             |
| `workspaceSubscriber.containerSecurityContext.enabled`      | Enabled workspace-subscriber containers' Security Context                                                     | `true`                          |
| `workspaceSubscriber.containerSecurityContext.runAsUser`    | Set workspace-subscriber containers' Security Context runAsUser                                               | `0`                             |
| `workspaceSubscriber.containerSecurityContext.runAsNonRoot` | Set workspace-subscriber containers' Security Context runAsNonRoot                                            | `false`                         |
| `workspaceSubscriber.configuration`                         | Configuration settings (env vars) for workspace-subscriber                                                    | `{}`                            |
| `workspaceSubscriber.secretConfiguration`                   | Configuration settings (env vars) for workspace-subscriber                                                    | `""`                            |
| `workspaceSubscriber.existingConfigMap`                     | The name of an existing ConfigMap with your custom configuration for workspace-subscriber                     | `""`                            |
| `workspaceSubscriber.existingSecret`                        | The name of an existing ConfigMap with your custom configuration for workspace-subscriber                     | `""`                            |
| `workspaceSubscriber.command`                               | Override default container command (useful when using custom images)                                          | `[]`                            |
| `workspaceSubscriber.args`                                  | Override default container args (useful when using custom images)                                             | `[]`                            |
| `workspaceSubscriber.hostAliases`                           | workspace-subscriber pods host aliases                                                                        | `[]`                            |
| `workspaceSubscriber.podLabels`                             | Extra labels for workspace-subscriber pods                                                                    | `{}`                            |
| `workspaceSubscriber.podAnnotations`                        | Annotations for workspace-subscriber pods                                                                     | `{}`                            |
| `workspaceSubscriber.podAffinityPreset`                     | Pod affinity preset. Ignored if `workspaceSubscriber.affinity` is set. Allowed values: `soft` or `hard`       | `""`                            |
| `workspaceSubscriber.podAntiAffinityPreset`                 | Pod anti-affinity preset. Ignored if `workspaceSubscriber.affinity` is set. Allowed values: `soft` or `hard`  | `soft`                          |
| `workspaceSubscriber.nodeAffinityPreset.type`               | Node affinity preset type. Ignored if `workspaceSubscriber.affinity` is set. Allowed values: `soft` or `hard` | `""`                            |
| `workspaceSubscriber.nodeAffinityPreset.key`                | Node label key to match. Ignored if `workspaceSubscriber.affinity` is set                                     | `""`                            |
| `workspaceSubscriber.nodeAffinityPreset.values`             | Node label values to match. Ignored if `workspaceSubscriber.affinity` is set                                  | `[]`                            |
| `workspaceSubscriber.affinity`                              | Affinity for workspace-subscriber pods assignment                                                             | `{}`                            |
| `workspaceSubscriber.nodeSelector`                          | Node labels for workspace-subscriber pods assignment                                                          | `{}`                            |
| `workspaceSubscriber.tolerations`                           | Tolerations for workspace-subscriber pods assignment                                                          | `[]`                            |
| `workspaceSubscriber.updateStrategy.type`                   | workspace-subscriber statefulset strategy type                                                                | `RollingUpdate`                 |
| `workspaceSubscriber.priorityClassName`                     | workspace-subscriber pods' priorityClassName                                                                  | `""`                            |
| `workspaceSubscriber.schedulerName`                         | Name of the k8s scheduler (other than default) for workspace-subscriber pods                                  | `""`                            |
| `workspaceSubscriber.lifecycleHooks`                        | for the workspace-subscriber container(s) to automate configuration before or after startup                   | `{}`                            |
| `workspaceSubscriber.extraEnvVars`                          | Array with extra environment variables to add to workspace-subscriber nodes                                   | `[]`                            |
| `workspaceSubscriber.extraEnvVarsCM`                        | Name of existing ConfigMap containing extra env vars for workspace-subscriber nodes                           | `""`                            |
| `workspaceSubscriber.extraEnvVarsSecret`                    | Name of existing Secret containing extra env vars for workspace-subscriber nodes                              | `""`                            |
| `workspaceSubscriber.extraVolumes`                          | Optionally specify extra list of additional volumes for the workspace-subscriber pod(s)                       | `[]`                            |
| `workspaceSubscriber.extraVolumeMounts`                     | Optionally specify extra list of additional volumeMounts for the workspace-subscriber container(s)            | `[]`                            |
| `workspaceSubscriber.sidecars`                              | Add additional sidecar containers to the workspace-subscriber pod(s)                                          | `{}`                            |
| `workspaceSubscriber.initContainers`                        | Add additional init containers to the workspace-subscriber pod(s)                                             | `{}`                            |


### workspace-subscriber ServiceAccount configuration

| Name                                                              | Description                                          | Value   |
| ----------------------------------------------------------------- | ---------------------------------------------------- | ------- |
| `workspaceSubscriber.serviceAccount.create`                       | Specifies whether a ServiceAccount should be created | `true`  |
| `workspaceSubscriber.serviceAccount.name`                         | The name of the ServiceAccount to use.               | `""`    |
| `workspaceSubscriber.serviceAccount.automountServiceAccountToken` | Mount service account token in the deployment        | `false` |


### workspace-www Deployment Parameters

| Name                                                      | Description                                                                                            | Value                           |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ | ------------------------------- |
| `workspaceWww.image.registry`                             | workspace-www image registry                                                                           | `gcr.io/carto-onprem-artifacts` |
| `workspaceWww.image.repository`                           | workspace-www image repository                                                                         | `workspace-www`                 |
| `workspaceWww.image.tag`                                  | workspace-www image tag (immutable tags are recommended)                                               | `""`                            |
| `workspaceWww.image.pullPolicy`                           | workspace-www image pull policy                                                                        | `IfNotPresent`                  |
| `workspaceWww.image.pullSecrets`                          | workspace-www image pull secrets                                                                       | `[]`                            |
| `workspaceWww.replicaCount`                               | Number of workspace-www replicas to deploy                                                             | `1`                             |
| `workspaceWww.containerPorts.http`                        | workspace-www HTTP container port                                                                      | `8080`                          |
| `workspaceWww.livenessProbe.enabled`                      | Enable livenessProbe on workspace-www containers                                                       | `true`                          |
| `workspaceWww.livenessProbe.initialDelaySeconds`          | Initial delay seconds for livenessProbe                                                                | `10`                            |
| `workspaceWww.livenessProbe.periodSeconds`                | Period seconds for livenessProbe                                                                       | `30`                            |
| `workspaceWww.livenessProbe.timeoutSeconds`               | Timeout seconds for livenessProbe                                                                      | `5`                             |
| `workspaceWww.livenessProbe.failureThreshold`             | Failure threshold for livenessProbe                                                                    | `5`                             |
| `workspaceWww.livenessProbe.successThreshold`             | Success threshold for livenessProbe                                                                    | `1`                             |
| `workspaceWww.readinessProbe.enabled`                     | Enable readinessProbe on workspace-www containers                                                      | `true`                          |
| `workspaceWww.readinessProbe.initialDelaySeconds`         | Initial delay seconds for readinessProbe                                                               | `10`                            |
| `workspaceWww.readinessProbe.periodSeconds`               | Period seconds for readinessProbe                                                                      | `30`                            |
| `workspaceWww.readinessProbe.timeoutSeconds`              | Timeout seconds for readinessProbe                                                                     | `5`                             |
| `workspaceWww.readinessProbe.failureThreshold`            | Failure threshold for readinessProbe                                                                   | `5`                             |
| `workspaceWww.readinessProbe.successThreshold`            | Success threshold for readinessProbe                                                                   | `1`                             |
| `workspaceWww.startupProbe.enabled`                       | Enable startupProbe on workspace-www containers                                                        | `false`                         |
| `workspaceWww.startupProbe.initialDelaySeconds`           | Initial delay seconds for startupProbe                                                                 | `10`                            |
| `workspaceWww.startupProbe.periodSeconds`                 | Period seconds for startupProbe                                                                        | `30`                            |
| `workspaceWww.startupProbe.timeoutSeconds`                | Timeout seconds for startupProbe                                                                       | `5`                             |
| `workspaceWww.startupProbe.failureThreshold`              | Failure threshold for startupProbe                                                                     | `5`                             |
| `workspaceWww.startupProbe.successThreshold`              | Success threshold for startupProbe                                                                     | `1`                             |
| `workspaceWww.customLivenessProbe`                        | Custom livenessProbe that overrides the default one                                                    | `{}`                            |
| `workspaceWww.customReadinessProbe`                       | Custom readinessProbe that overrides the default one                                                   | `{}`                            |
| `workspaceWww.customStartupProbe`                         | Custom startupProbe that overrides the default one                                                     | `{}`                            |
| `workspaceWww.autoscaling.enabled`                        | Enable autoscaling for the workspace-www containers                                                    | `false`                         |
| `workspaceWww.autoscaling.minReplicas`                    | The minimal number of containters for the workspace-www deployment                                     | `1`                             |
| `workspaceWww.autoscaling.maxReplicas`                    | The maximum number of containers for the workspace-www deployment                                      | `2`                             |
| `workspaceWww.autoscaling.targetCPUUtilizationPercentage` | The CPU utilization percentage used for scale up containers in workspace-www deployment                | `75`                            |
| `workspaceWww.resources.limits`                           | The resources limits for the workspace-www containers                                                  | `{}`                            |
| `workspaceWww.resources.requests`                         | The requested resources for the workspace-www containers                                               | `{}`                            |
| `workspaceWww.podSecurityContext.enabled`                 | Enabled workspace-www pods' Security Context                                                           | `true`                          |
| `workspaceWww.podSecurityContext.fsGroup`                 | Set workspace-www pod's Security Context fsGroup                                                       | `0`                             |
| `workspaceWww.containerSecurityContext.enabled`           | Enabled workspace-www containers' Security Context                                                     | `true`                          |
| `workspaceWww.containerSecurityContext.runAsUser`         | Set workspace-www containers' Security Context runAsUser                                               | `0`                             |
| `workspaceWww.containerSecurityContext.runAsNonRoot`      | Set workspace-www containers' Security Context runAsNonRoot                                            | `false`                         |
| `workspaceWww.configuration`                              | Configuration settings (env vars) for workspace-www                                                    | `{}`                            |
| `workspaceWww.secretConfiguration`                        | Configuration settings (env vars) for workspace-www                                                    | `""`                            |
| `workspaceWww.existingConfigMap`                          | The name of an existing ConfigMap with your custom configuration for workspace-www                     | `""`                            |
| `workspaceWww.existingSecret`                             | The name of an existing ConfigMap with your custom configuration for workspace-www                     | `""`                            |
| `workspaceWww.command`                                    | Override default container command (useful when using custom images)                                   | `[]`                            |
| `workspaceWww.args`                                       | Override default container args (useful when using custom images)                                      | `[]`                            |
| `workspaceWww.hostAliases`                                | workspace-www pods host aliases                                                                        | `[]`                            |
| `workspaceWww.podLabels`                                  | Extra labels for workspace-www pods                                                                    | `{}`                            |
| `workspaceWww.podAnnotations`                             | Annotations for workspace-www pods                                                                     | `{}`                            |
| `workspaceWww.podAffinityPreset`                          | Pod affinity preset. Ignored if `workspaceWww.affinity` is set. Allowed values: `soft` or `hard`       | `""`                            |
| `workspaceWww.podAntiAffinityPreset`                      | Pod anti-affinity preset. Ignored if `workspaceWww.affinity` is set. Allowed values: `soft` or `hard`  | `soft`                          |
| `workspaceWww.nodeAffinityPreset.type`                    | Node affinity preset type. Ignored if `workspaceWww.affinity` is set. Allowed values: `soft` or `hard` | `""`                            |
| `workspaceWww.nodeAffinityPreset.key`                     | Node label key to match. Ignored if `workspaceWww.affinity` is set                                     | `""`                            |
| `workspaceWww.nodeAffinityPreset.values`                  | Node label values to match. Ignored if `workspaceWww.affinity` is set                                  | `[]`                            |
| `workspaceWww.affinity`                                   | Affinity for workspace-www pods assignment                                                             | `{}`                            |
| `workspaceWww.nodeSelector`                               | Node labels for workspace-www pods assignment                                                          | `{}`                            |
| `workspaceWww.tolerations`                                | Tolerations for workspace-www pods assignment                                                          | `[]`                            |
| `workspaceWww.updateStrategy.type`                        | workspace-www statefulset strategy type                                                                | `RollingUpdate`                 |
| `workspaceWww.priorityClassName`                          | workspace-www pods' priorityClassName                                                                  | `""`                            |
| `workspaceWww.schedulerName`                              | Name of the k8s scheduler (other than default) for workspace-www pods                                  | `""`                            |
| `workspaceWww.lifecycleHooks`                             | for the workspace-www container(s) to automate configuration before or after startup                   | `{}`                            |
| `workspaceWww.extraEnvVars`                               | Array with extra environment variables to add to workspace-www nodes                                   | `[]`                            |
| `workspaceWww.extraEnvVarsCM`                             | Name of existing ConfigMap containing extra env vars for workspace-www nodes                           | `""`                            |
| `workspaceWww.extraEnvVarsSecret`                         | Name of existing Secret containing extra env vars for workspace-www nodes                              | `""`                            |
| `workspaceWww.extraVolumes`                               | Optionally specify extra list of additional volumes for the workspace-www pod(s)                       | `[]`                            |
| `workspaceWww.extraVolumeMounts`                          | Optionally specify extra list of additional volumeMounts for the workspace-www container(s)            | `[]`                            |
| `workspaceWww.sidecars`                                   | Add additional sidecar containers to the workspace-www pod(s)                                          | `{}`                            |
| `workspaceWww.initContainers`                             | Add additional init containers to the workspace-www pod(s)                                             | `{}`                            |


### workspace-www Service Parameters

| Name                                            | Description                                                                              | Value       |
| ----------------------------------------------- | ---------------------------------------------------------------------------------------- | ----------- |
| `workspaceWww.service.type`                     | workspace-www service type                                                               | `ClusterIP` |
| `workspaceWww.service.ports.http`               | workspace-www service HTTP port                                                          | `80`        |
| `workspaceWww.service.nodePorts.http`           | Node port for HTTP                                                                       | `""`        |
| `workspaceWww.service.clusterIP`                | workspace-www service Cluster IP                                                         | `""`        |
| `workspaceWww.service.loadBalancerIP`           | workspace-www service Load Balancer IP                                                   | `""`        |
| `workspaceWww.service.labelSelectorsOverride`   | Selector for workspace-www service                                                       | `{}`        |
| `workspaceWww.service.loadBalancerSourceRanges` | workspace-www service Load Balancer sources                                              | `[]`        |
| `workspaceWww.service.externalTrafficPolicy`    | workspace-www service external traffic policy                                            | `Cluster`   |
| `workspaceWww.service.annotations`              | Additional custom annotations for workspace-www service                                  | `{}`        |
| `workspaceWww.service.extraPorts`               | Extra ports to expose in workspace-www service (normally used with the `sidecars` value) | `[]`        |


### workspace-www ServiceAccount configuration

| Name                                                       | Description                                          | Value   |
| ---------------------------------------------------------- | ---------------------------------------------------- | ------- |
| `workspaceWww.serviceAccount.create`                       | Specifies whether a ServiceAccount should be created | `true`  |
| `workspaceWww.serviceAccount.name`                         | The name of the ServiceAccount to use.               | `""`    |
| `workspaceWww.serviceAccount.automountServiceAccountToken` | Mount service account token in the deployment        | `false` |


### Init Container Parameters

| Name                                                        | Description                                                          | Value                           |
| ----------------------------------------------------------- | -------------------------------------------------------------------- | ------------------------------- |
| `workspaceMigrations.image.registry`                        | workspace-db image registry                                          | `gcr.io/carto-onprem-artifacts` |
| `workspaceMigrations.image.repository`                      | workspace-db image repository                                        | `workspace-db`                  |
| `workspaceMigrations.image.tag`                             | workspace-db image tag (immutable tags are recommended)              | `""`                            |
| `workspaceMigrations.image.pullPolicy`                      | workspace-db image pull policy                                       | `IfNotPresent`                  |
| `workspaceMigrations.image.pullSecrets`                     | workspace-db image pull secrets                                      | `[]`                            |
| `workspaceMigrations.command`                               | Override default container command (useful when using custom images) | `[]`                            |
| `workspaceMigrations.args`                                  | Override default container args (useful when using custom images)    | `[]`                            |
| `workspaceMigrations.resources.limits`                      | The resources limits for the init container                          | `{}`                            |
| `workspaceMigrations.resources.requests`                    | The requested resources for the init container                       | `{}`                            |
| `workspaceMigrations.containerSecurityContext.enabled`      | Enable container security context                                    | `true`                          |
| `workspaceMigrations.containerSecurityContext.runAsUser`    | Set init container's Security Context runAsUser                      | `0`                             |
| `workspaceMigrations.containerSecurityContext.runAsNonRoot` | Force the init container to run as non root                          | `false`                         |


### Internal Redis&trade; subchart parameters

| Name                                        | Description                                                                                  | Value        |
| ------------------------------------------- | -------------------------------------------------------------------------------------------- | ------------ |
| `internalRedis.enabled`                     | Switch to enable or disable the Redis&trade; helm                                            | `true`       |
| `internalRedis.tlsEnabled`                  | Whether or not connect to Redis via TLS                                                      | `false`      |
| `internalRedis.auth.enabled`                | Switch to enable or disable authentication                                                   | `true`       |
| `internalRedis.auth.password`               | Redis&trade; password                                                                        | `""`         |
| `internalRedis.auth.existingSecret`         | Name of existing secret object containing the password                                       | `""`         |
| `internalRedis.architecture`                | Cluster settings                                                                             | `standalone` |
| `internalRedis.master.persistence.enabled`  | Enable master persistent volumes                                                             | `false`      |
| `internalRedis.replica.persistence.enabled` | Enable replica persistent volumes                                                            | `false`      |
| `internalRedis.nameOverride`                | String to partially override common.names.fullname template (will maintain the release name) | `redis`      |


### External Redis parameters

| Name                                      | Description                                                                                 | Value       |
| ----------------------------------------- | ------------------------------------------------------------------------------------------- | ----------- |
| `externalRedis.host`                      | Redis host                                                                                  | `localhost` |
| `externalRedis.port`                      | Redis port number                                                                           | `6379`      |
| `externalRedis.password`                  | Redis password                                                                              | `""`        |
| `externalRedis.tlsEnabled`                | Whether or not connect to Redis via TLS                                                     | `false`     |
| `externalRedis.tlsCA`                     | CA certificate in case Redis TLS cert it's selfsigned                                       | `""`        |
| `externalRedis.existingSecret`            | Name of an existing secret resource containing the Redis password in a 'redis-password' key | `""`        |
| `externalRedis.existingSecretPasswordKey` | Key of the existing secret                                                                  | `""`        |


### Internal PostgreSQL subchart parameters

| Name                                        | Description                                                                                     | Value                  |
| ------------------------------------------- | ----------------------------------------------------------------------------------------------- | ---------------------- |
| `internalPostgresql.enabled`                | Switch to enable or disable the PostgreSQL helm chart                                           | `true`                 |
| `internalPostgresql.auth.username`          | CARTO Postgresql username                                                                       | `workspace_admin`      |
| `internalPostgresql.auth.password`          | CARTO Postgresql password                                                                       | `""`                   |
| `internalPostgresql.auth.postgresPassword`  | CARTO Postgresql password for the postgres user                                                 | `""`                   |
| `internalPostgresql.auth.database`          | CARTO Postgresql database                                                                       | `workspace`            |
| `internalPostgresql.sslEnabled`             | Whether or not connect to CARTO Postgresql via TLS                                              | `false`                |
| `internalPostgresql.auth.existingSecret`    | Name of an existing secret containing the CARTO Postgresql password ('postgresql-password' key) | `""`                   |
| `internalPostgresql.image.tag`              | Tag of the PostgreSQL image                                                                     | `13.5.0-debian-10-r84` |
| `internalPostgresql.nameOverride`           | String to partially override common.names.fullname template (will maintain the release name)    | `postgresql`           |
| `internalPostgresql.primary.initdb.scripts` | Scripts for initializing the database                                                           | `[]`                   |


### External PostgreSQL parameters

| Name                                                | Description                                                                                                                            | Value             |
| --------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | ----------------- |
| `externalPostgresql.host`                           | Database host                                                                                                                          | `localhost`       |
| `externalPostgresql.user`                           | non-root Username for CARTO Database (seen from outside the database)                                                                  | `workspace_admin` |
| `externalPostgresql.internalUser`                   | non-root Username for CARTO Database (seen from inside the database). If this value is not defined, `externalPostgresql.user` is used. | `""`              |
| `externalPostgresql.password`                       | Database password                                                                                                                      | `""`              |
| `externalPostgresql.adminUser`                      | Database admin user (seen from outside the database)                                                                                   | `postgres`        |
| `externalPostgresql.internalAdminUser`              | Database admin user (seen from inside the database). If this value is not defined, `externalPostgresql.adminUser` is used.             | `""`              |
| `externalPostgresql.adminPassword`                  | Database admin password                                                                                                                | `""`              |
| `externalPostgresql.existingSecret`                 | Name of an existing secret resource containing the DB password                                                                         | `""`              |
| `externalPostgresql.existingSecretPasswordKey`      | Name of the key inside the secret containing the DB password                                                                           | `""`              |
| `externalPostgresql.existingSecretAdminPasswordKey` | Name of the key inside the secret containing the DB admin password                                                                     | `""`              |
| `externalPostgresql.database`                       | Database name                                                                                                                          | `workspace`       |
| `externalPostgresql.port`                           | Database port number                                                                                                                   | `5432`            |
| `externalPostgresql.sslEnabled`                     | Whether or not connect to CARTO Postgresql via TLS                                                                                     | `false`           |
| `externalPostgresql.sslCA`                          | CA certificate in case CARTO Postgresql TLS cert it's selfsigned                                                                       | `""`              |


## Configuration and installation details

### [Rolling VS Immutable tags](https://docs.bitnami.com/containers/how-to/understand-rolling-tags-containers/)

It is strongly recommended to use immutable tags in a production environment. This ensures your deployment does not change automatically if the same tag is updated with a different image.

### Additional environment variables

In case you want to add extra environment variables (useful for advanced operations like custom init scripts), you can use the `*.extraEnvVars` property. For instance, to add extra environment variables on lds-api containers:

```yaml
ldsApi:
  extraEnvVars:
    - name: LOG_LEVEL
      value: error
```

Alternatively, you can use a ConfigMap or a Secret with the environment variables. To do so, use the `*.extraEnvVarsCM` or the `*.extraEnvVarsSecret` values.

### Sidecars

If additional containers are needed in the any component's pods (such as additional metrics or logging exporters), they can be defined using the `*.sidecars` parameter. If these sidecars export extra ports, extra port definitions can be added using the `*.service.extraPorts` parameter.

### Pod affinity

This chart allows you to set your custom affinity using the `*.affinity` parameter. Find more information about Pod affinity in the [kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity).

As an alternative, use one of the preset configurations for pod affinity, pod anti-affinity, and node affinity available at the [bitnami/common](https://github.com/bitnami/charts/tree/master/bitnami/common#affinities) chart. To do so, set the `*.podAffinityPreset`, `*.podAntiAffinityPreset`, or `*.nodeAffinityPreset` parameters.

### Deploying extra resources

There are cases where you may want to deploy extra objects, such a ConfigMap containing your app's configuration or some extra deployment with a micro service used by your app. For covering this case, the chart allows adding the full specification of other objects using the `extraDeploy` parameter.

## Troubleshooting

Find more information about how to deal with common errors related to CARTO Helm chart in [this repository](https://github.com/cartoDB/carto-selfhosted-helm).

## Update this file

```bash
git clone https://github.com/bitnami-labs/readme-generator-for-helm
docker build -t helm-readme-generator readme-generator-for-helm/
docker run --rm -it \
  -v ${PWD}:/my_helm \
  -w /my_helm \
  helm-readme-generator \
  readme-generator \
    --readme README.md \
    --values values.yaml
```
