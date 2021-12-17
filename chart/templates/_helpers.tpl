{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "carto.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "carto.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Carto lds-api image name
*/}}
{{- define "carto.lds-apiImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.lds-api.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Carto import-worker image name
*/}}
{{- define "carto.import-workerImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.import-worker.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Carto import-api image name
*/}}
{{- define "carto.import-apiImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.import-api.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Carto maps-api image name
*/}}
{{- define "carto.maps-apiImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.maps-api.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Carto workspace-subscriber image name
*/}}
{{- define "carto.workspace-subscriberImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.workspace-subscriber.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Carto workspace-api image name
*/}}
{{- define "carto.workspace-apiImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.workspace-api.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Carto workspace-www image name
*/}}
{{- define "carto.workspace-wwwImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.workspace-www.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Carto accounts-www image name
*/}}
{{- define "carto.accounts-wwwImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.accounts-www.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Carto router image name
*/}}
{{- define "carto.routerImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.router.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Carto Metrics image name
*/}}
{{- define "carto.metrics.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.metrics.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "carto.imagePullSecrets" -}}
{{- include "common.images.pullSecrets" (dict "images" (list .Values.lds-api.image .Values.import-worker.image .Values.import-api.image .Values.maps-api.image .Values.workspace-migrations.image .Values.workspace-subscriber.image .Values.workspace-api.image .Values.workspace-www.image .Values.accounts-www.image Values.router.image .Values.metrics.image) "global" .Values.global) -}}
{{- end -}}

========================
{{/*
Return Carto Auth0 client ID
*/}}
{{- define "configuration.auth0.cartoAuth0ClientID" -}}
{{- .Values.configuration.auth0.cartoAuth0ClientID }}
{{- end -}}

{{/*
Return Carto Docker Registry Base Path
*/}}
{{- define "configuration.dockerRegistryBasePath" -}}
gcr.io/carto-onprem-artifacts
{{- end -}}

{{/*
Return Carto on premise version
*/}}
{{- define "configuration.cartoOnpremiseVersion" -}}
{{ .Values.configuration.cartoOnpremiseVersion }}
{{- end -}}

{{/*
Return Carto Auth0 custom domain
*/}}
{{- define "configuration.auth0.cartoAuth0CustomDomain" -}}
{{ .Values.configuration.auth0.cartoAuth0CustomDomain }}
{{- end -}}

{{/*
Return Carto ACC domain
*/}}
{{- define "configuration.acc.accDomain" -}}
{{ .Values.configuration.acc.accDomain }}
{{- end -}}

{{/*
Return Carto on premise domain
*/}}
{{- define "configuration.onpremDomain" -}}
{{ .Values.configuration.onpremDomain }}
{{- end -}}


{{/*
Return the common environment variablesproper Docker Image Registry Secret Names
*/}}
{{- define "carto.configure.common" -}}
- name: ONPREM_DOMAIN
  value: {{ include "configuration.onpremDomain" }}
{{- if .Values.configuration.reactAppGoogleMapsAPIKey }}
- name: REACT_APP_GOOGLE_MAPS_API_KEY
  value: {{ .Values.configuration.reactAppGoogleMapsAPIKey }}
{{- end }}
{{- if .Values.configuration.externalDatabase.enabled }}
- name: WORKSPACE_POSTGRES_HOST
  value: {{ .Values.configuration.externalDatabase.workspacePostgresHost }}
- name: WORKSPACE_POSTGRES_PORT
  value: {{ .Values.configuration.externalDatabase.workspacePostgresPort }}
- name: POSTGRES_PASSWORD
  {{- if .Values.configuration.externalDatabase.existingSecret }}
  valueFrom:
    secretKeyRef:
      name: {{ include "carto.externalDatabase.secretName" . }}
      key: {{ include "carto.externalDatabase.existingsecret.key" . }}
  {{- else }}
  value: {{ .Values.configuration.externalDatabase.postgresPassword }}
  {{- end }}
{{- else }}
- name: WORKSPACE_POSTGRES_HOST
  value: {{ include "carto.postgresql.host" }}
- name: WORKSPACE_POSTGRES_PORT
  value: {{ include "carto.postgresql.port" }}
- name: POSTGRES_PASSWORD
  value:
{{- end }}
- name: ONPREM_TENANT_ID
  value: {{ .Values.configuration.onpremTenantId }}
- name: ONPREM_GCP_PROJECT_ID
  value: {{ .Values.configuration.onpremGCPProjectID }}
- name: WORKSPACE_GCS_THUMBNAILS_BUCKET
  value: {{ .Values.configuration.workspaceGCSThumbnailsBucket }}
- name: WORKSPACE_GCS_DATASETS_BUCKET
  value: {{ .Values.configuration.workspaceGCSDatasetsBucket }}
- name: IMPORT_GCS_DATA_IMPORTS_BUCKET
  value: {{ .Values.configuration.importGCSDataImportsBucket }}
{{- if .Values.configuration.ssl.enabled }}
- name: ROUTER_SSL_AUTOGENERATE
  value: 1
- name: ROUTER_SSL_CERTIFICATE_PATH
  value: {{ .Values.configuration.ssl.routerSSLCertificatePath }}
- name: ROUTER_SSL_CERTIFICATE_KEY_PATH
  value: {{ .Values.configuration.ssl.routerSSLCertificateKeyPath }}
{{- end }}
- name: CARTO_AUTH0_CLIENT_ID
  value: {{ include "configuration.auth0.cartoAuth0ClientID" }}
- name: CARTO_AUTH0_CUSTOM_DOMAIN
  value: {{ include "configuration.auth0.cartoAuth0CustomDomain" }}
- name: ACC_DOMAIN
  value: {{ include "configuration.acc.accDomain" }}
- name: ACC_GCP_PROJECT_ID
  value: {{ .Values.configuration.acc.accGCPProjectID }}
- name: ACC_GCP_PROJECT_REGION
  value: {{ .Values.configuration.acc.accGCPProjectRegion }}
- name: ENCRYPTION_SECRET_KEY
  value:
- name: WORKSPACE_POSTGRES_PASSWORD
  value:
- name: CARTO_ONPREMISE_CARTO_DW_LOCATION
  value: {{ .Values.configuration.cartoOnpremiseCartoDWLocation }}
- name: CARTO_ONPREMISE_CUSTOMER_PACKAGE_VERSION
  value: {{ .Values.configuration.cartoOnpremiseCustomerPackageVersion }}
- name: CARTO_ONPREMISE_VERSION
  value: {{ include "configuration.cartoOnpremiseVersion" }}
- name: GOOGLE_APPLICATION_CREDENTIALS
  value: ../certs/key.json
- name: CARTO3_ONPREM_VOLUMES_BASE_PATH
  value: ./
- name: DOCKER_REGISTRY_BASE_PATH
  value: {{ include "configuration.dockerRegistryBasePath" }}
- name: CARTO_ONPREMISE_AUTH0_CLIENT_ID
  value: {{ include "configuration.auth0.cartoAuth0ClientID" }}
- name: ROUTER_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" }}/router:{{ include "configuration.cartoOnpremiseVersion" }}
- name: ACCOUNTS_API_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" }}/accounts-api:{{ include "configuration.cartoOnpremiseVersion" }}
- name: ACCOUNTS_WWW_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" }}/accounts-www:{{ include "configuration.cartoOnpremiseVersion" }}
- name: WORKSPACE_API_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" }}/workspace-api:{{ include "configuration.cartoOnpremiseVersion" }}
- name: WORKSPACE_WWW_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" }}/workspace-www:{{ include "configuration.cartoOnpremiseVersion" }}
- name: MAPS_API_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" }}/maps-api:{{ include "configuration.cartoOnpremiseVersion" }}
- name: INTEGRATION_TESTS_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" }}/integration-tests:{{ include "configuration.cartoOnpremiseVersion" }}
- name: ACCOUNTS_MIGRATIONS_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" }}/accounts-db:{{ include "configuration.cartoOnpremiseVersion" }}
- name: WORKSPACE_MIGRATIONS_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" }}/workspace-db{{ include "configuration.cartoOnpremiseVersion" }}
- name: IMPORT_API_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" }}/import-api:{{ include "configuration.cartoOnpremiseVersion" }}
- name: LDS_API_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" }}/lds-api:{{ include "configuration.cartoOnpremiseVersion" }}
- name: REACT_APP_CLIENT_ID
  value: {{ include "configuration.auth0.cartoAuth0ClientID" }}
- name: REACT_APP_AUTH0_DOMAIN
  value: {{ include "configuration.auth0.cartoAuth0CustomDomain" }}
- name: REACT_APP_ACCOUNTS_API_URL
  value: https://{{ include "configuration.acc.accDomain" }}
- name: REACT_APP_ACCOUNTS_URL
  value: https://{{ include "configuration.onpremDomain" }}/acc/
- name: REACT_APP_WORKSPACE_API_URL
  value: https://{{ include "configuration.onpremDomain" }}/workspace-api
- name: REACT_APP_API_BASE_URL
  value: https://${ONPREM_DOMAIN}/api
- name: REACT_APP_PUBLIC_MAP_URL
  value: https://${ONPREM_DOMAIN}/workspace-api/maps/public
- name: REACT_APP_AUTH0_AUDIENCE
  value: carto-cloud-native-api
- name: REACT_APP_WORKSPACE_URL_TEMPLATE
  value: https://{tenantDomain}
- name: REACT_APP_CUSTOM_TENANT
  value: =${ONPREM_TENANT_ID}
- name: REACT_APP_IMPORT_DATASET
  value: =carto_dw.carto-dw-{account-id}.shared
- name: REACT_APP_HUBSPOT_ID
  value: =474999
- name: REACT_APP_HUBSPOT_LIMIT_FORM_ID
  value: =cd9486fa-5766-4bac-81b9-d8c6cd029b3b






{{- end -}}








===============================

{{/*
Create a default fully qualified postgresql name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "carto.postgresql.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "postgresql" "chartValues" .Values.postgresql "context" $) -}}
{{- end -}}

{{/*
Create a default fully qualified redis name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "carto.redis.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "redis" "chartValues" .Values.redis "context" $) -}}
{{- end -}}

{{/*
Get the Redis&trade; credentials secret.
*/}}
{{- define "carto.redis.secretName" -}}
{{- if and (.Values.redis.enabled) (not .Values.redis.auth.existingSecret) -}}
    {{/* Create a include for the redis secret
    We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
    */}}
    {{- $name := default "redis" .Values.redis.nameOverride -}}
    {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- else if and (.Values.redis.enabled) ( .Values.redis.auth.existingSecret) -}}
    {{- printf "%s" .Values.redis.auth.existingSecret -}}
{{- else }}
    {{- if .Values.externalRedis.existingSecret -}}
        {{- printf "%s" .Values.externalRedis.existingSecret -}}
    {{- else -}}
        {{ printf "%s-%s" .Release.Name "externalredis" }}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Get the Postgresql credentials secret.
*/}}
{{- define "carto.postgresql.secretName" -}}
{{- if and (.Values.postgresql.enabled) (not .Values.postgresql.existingSecret) -}}
    {{- printf "%s" (include "carto.postgresql.fullname" .) -}}
{{- else if and (.Values.postgresql.enabled) (.Values.postgresql.existingSecret) -}}
    {{- printf "%s" .Values.postgresql.existingSecret -}}
{{- else }}
    {{- if .Values.externalDatabase.existingSecret -}}
        {{- printf "%s" .Values.externalDatabase.existingSecret -}}
    {{- else -}}
        {{ printf "%s-%s" .Release.Name "externaldb" }}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Get the secret name
*/}}
{{- define "carto.secretName" -}}
{{- if .Values.auth.existingSecret -}}
  {{- printf "%s" .Values.auth.existingSecret -}}
{{- else -}}
  {{- printf "%s" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Get the configmap name
*/}}
{{- define "carto.configMapName" -}}
{{- if .Values.configurationConfigMap -}}
  {{- printf "%s" .Values.configurationConfigMap -}}
{{- else -}}
  {{- printf "%s-configuration" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Should use config from the configmap
*/}}
{{- define "carto.shouldUseConfigFromConfigMap" -}}
{{- if or .Values.config .Values.configurationConfigMap -}}
  true
{{- else -}}{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "carto.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "carto.database.host" -}}
{{- ternary (include "carto.postgresql.fullname" .) .Values.externalDatabase.host .Values.postgresql.enabled | quote -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "carto.database.user" -}}
{{- ternary .Values.postgresql.postgresqlUsername .Values.externalDatabase.user .Values.postgresql.enabled | quote -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "carto.database.name" -}}
{{- ternary .Values.postgresql.postgresqlDatabase .Values.externalDatabase.database .Values.postgresql.enabled | quote -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "carto.database.existingsecret.key" -}}
{{- if .Values.postgresql.enabled -}}
    {{- printf "%s" "postgresql-password" -}}
{{- else -}}
    {{- if .Values.externalDatabase.existingSecret -}}
        {{- if .Values.externalDatabase.existingSecretPasswordKey -}}
            {{- printf "%s" .Values.externalDatabase.existingSecretPasswordKey -}}
        {{- else -}}
            {{- printf "%s" "postgresql-password" -}}
        {{- end -}}
    {{- else -}}
        {{- printf "%s" "postgresql-password" -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "carto.database.port" -}}
{{- ternary "5432" .Values.externalDatabase.port .Values.postgresql.enabled | quote -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "carto.configure.database" -}}
- name: AIRFLOW_DATABASE_NAME
  value: {{ include "carto.database.name" . }}
- name: AIRFLOW_DATABASE_USERNAME
  value: {{ include "carto.database.user" . }}
- name: AIRFLOW_DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "carto.postgresql.secretName" . }}
      key: {{ include "carto.database.existingsecret.key" . }}
- name: AIRFLOW_DATABASE_HOST
  value: {{ include "carto.database.host" . }}
- name: AIRFLOW_DATABASE_PORT_NUMBER
  value: {{ include "carto.database.port" . }}
{{- end -}}

{{/*
Add environment variables to configure redis values
*/}}
{{- define "carto.configure.redis" -}}
{{- if (not (eq .Values.executor "KubernetesExecutor" )) }}
- name: REDIS_HOST
  value: {{ ternary (include "carto.redis.fullname" .) .Values.externalRedis.host .Values.redis.enabled | quote }}
- name: REDIS_PORT_NUMBER
  value: {{ ternary "6379" .Values.externalRedis.port .Values.redis.enabled | quote }}
{{- if and (not .Values.redis.enabled) .Values.externalRedis.username }}
- name: REDIS_USER
  value: {{ .Values.externalRedis.username | quote }}
{{- end }}
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "carto.redis.secretName" . }}
      key: redis-password
{{- end }}
{{- end -}}

{{/*
Add environment variables to configure carto common values
*/}}
{{- define "carto.configure.carto.common" -}}
- name: AIRFLOW_FERNET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "carto.secretName" . }}
      key: carto-fernetKey
- name: AIRFLOW_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "carto.secretName" . }}
      key: carto-secretKey
- name: AIRFLOW_LOAD_EXAMPLES
  value: {{ ternary "yes" "no" .Values.loadExamples | quote }}
{{- if .Values.web.image.debug }}
- name: BASH_DEBUG
  value: "1"
- name: BITNAMI_DEBUG
  value: "true"
{{- end }}
{{- end -}}

{{/*
Add environment variables to configure carto kubernetes executor
*/}}
{{- define "carto.configure.carto.kubernetesExecutor" -}}
{{- if or (eq .Values.executor "KubernetesExecutor") (eq .Values.executor "CeleryKubernetesExecutor") }}
- name: AIRFLOW__KUBERNETES__NAMESPACE
  value: {{ .Release.Namespace }}
- name: AIRFLOW__KUBERNETES__WORKER_CONTAINER_REPOSITORY
  value: {{ printf "%s/%s" .Values.worker.image.registry .Values.worker.image.repository }}
- name: AIRFLOW__KUBERNETES__WORKER_CONTAINER_TAG
  value: {{ .Values.worker.image.tag }}
- name: AIRFLOW__KUBERNETES__IMAGE_PULL_POLICY
  value: {{ .Values.worker.image.pullPolicy }}
- name: AIRFLOW__KUBERNETES__DAGS_IN_IMAGE
  value: "True"
- name: AIRFLOW__KUBERNETES__DELETE_WORKER_PODS
  value: "True"
- name: AIRFLOW__KUBERNETES__DELETE_WORKER_PODS_ON_FAILURE
  value: "False"
- name: AIRFLOW__KUBERNETES__WORKER_SERVICE_ACCOUNT_NAME
  value: {{ include "carto.serviceAccountName" . }}
- name: AIRFLOW__KUBERNETES__POD_TEMPLATE_FILE
  value: "/opt/bitnami/carto/pod_template.yaml"
{{- end }}
{{- end -}}

{{/*
Get the user defined LoadBalancerIP for this release.
Note, returns 127.0.0.1 if using ClusterIP.
*/}}
{{- define "carto.serviceIP" -}}
{{- if eq .Values.service.type "ClusterIP" -}}
127.0.0.1
{{- else -}}
{{- .Values.service.loadBalancerIP | default "" -}}
{{- end -}}
{{- end -}}

{{/*
Gets the host to be used for this application.
If not using ClusterIP, or if a host or LoadBalancerIP is not defined, the value will be empty.
*/}}
{{- define "carto.baseUrl" -}}
{{- $host := include "carto.serviceIP" . -}}

{{- $port := "" -}}
{{- $servicePortString := printf "%v" .Values.service.port -}}
{{- if and (not (eq $servicePortString "80")) (not (eq $servicePortString "443")) -}}
  {{- $port = printf ":%s" $servicePortString -}}
{{- end -}}

{{- $defaultUrl := "" -}}
{{- if $host -}}
  {{- $defaultUrl = printf "http://%s%s" $host $port -}}
{{- end -}}

{{- default $defaultUrl .Values.web.baseUrl -}}
{{- end -}}

{{/*
Compile all warnings into a single message, and call fail.
*/}}
{{- define "carto.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "carto.validateValues.dags.repositories" .) -}}
{{- $messages := append $messages (include "carto.validateValues.dags.repository_details" .) -}}
{{- $messages := append $messages (include "carto.validateValues.plugins.repositories" .) -}}
{{- $messages := append $messages (include "carto.validateValues.plugins.repository_details" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/* Validate values of Carto - At least one repository details must be provided when "git.dags.enabled" is "true" */}}
{{- define "carto.validateValues.dags.repositories" -}}
  {{- if and .Values.git.dags.enabled (empty .Values.git.dags.repositories) -}}
carto: git.dags.repositories
    At least one repository must be provided when enabling downloading DAG files
    from git repository (--set git.dags.repositories[0].repository="xxx"
    --set git.dags.repositories[0].name="xxx"
    --set git.dags.repositories[0].branch="name")
  {{- end -}}
{{- end -}}

{{/* Validate values of Carto - "git.dags.repositories.repository", "git.dags.repositories.name", "git.dags.repositories.branch" must be provided when "git.dags.enabled" is "true" */}}
{{- define "carto.validateValues.dags.repository_details" -}}
{{- if .Values.git.dags.enabled -}}
{{- range $index, $repository_detail := .Values.git.dags.repositories }}
{{- if empty $repository_detail.repository -}}
carto: git.dags.repositories[$index].repository
    The repository must be provided when enabling downloading DAG files
    from git repository (--set git.dags.repositories[$index].repository="xxx")
{{- end -}}
{{- if empty $repository_detail.branch -}}
carto: git.dags.repositories[$index].branch
    The branch must be provided when enabling downloading DAG files
    from git repository (--set git.dags.repositories[$index].branch="xxx")
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Validate values of Carto - "git.plugins.repositories" must be provided when "git.plugins.enabled" is "true" */}}
{{- define "carto.validateValues.plugins.repositories" -}}
  {{- if and .Values.git.plugins.enabled (empty .Values.git.plugins.repositories) -}}
carto: git.plugins.repositories
    At least one repository must be provided when enabling downloading DAG files
    from git repository (--set git.plugins.repositories[0].repository="xxx"
    --set git.plugins.repositories[0].name="xxx"
    --set git.plugins.repositories[0].branch="name")
  {{- end -}}
{{- end -}}

{{/* Validate values of Carto - "git.plugins.repositories.repository", "git.plugins.repositories.name", "git.plugins.repositories.branch" must be provided when "git.plugins.enabled" is "true" */}}
{{- define "carto.validateValues.plugins.repository_details" -}}
{{- if .Values.git.plugins.enabled -}}
{{- range $index, $repository_detail := .Values.git.plugins.repositories }}
{{- if empty $repository_detail.repository -}}
carto: git.plugins.repositories[$index].repository
    The repository must be provided when enabling downloading DAG files
    from git repository (--set git.plugins.repositories[$index].repository="xxx")
{{- end -}}
{{- if empty $repository_detail.branch -}}
carto: git.plugins.repositories[$index].branch
    The branch must be provided when enabling downloading DAG files
    from git repository (--set git.plugins.repositories[$index].branch="xxx")
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Check if there are rolling tags in the images */}}
{{- define "carto.checkRollingTags" -}}
{{- include "common.warnings.rollingTag" .Values.web.image }}
{{- include "common.warnings.rollingTag" .Values.scheduler.image }}
{{- include "common.warnings.rollingTag" .Values.worker.image }}
{{- include "common.warnings.rollingTag" .Values.git.image }}
{{- include "common.warnings.rollingTag" .Values.metrics.image }}
{{- end -}}

{{/*
In Carto version 2.1.0, the CeleryKubernetesExecutor requires setting workers with CeleryExecutor in order to work properly.
This is a workaround and is subject to Carto official resolution.
Ref: https://github.com/bitnami/charts/pull/6096#issuecomment-856499047
*/}}
{{- define "carto.worker.executor" -}}
{{- if eq .Values.executor "CeleryKubernetesExecutor" -}}
{{- printf "CeleryExecutor" -}}
{{- else -}}
{{- .Values.executor -}}
{{- end -}}
{{- end -}}
