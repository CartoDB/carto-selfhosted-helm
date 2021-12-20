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
Return the proper Carto ldsApi image name
*/}}
{{- define "carto.ldsApiImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.ldsApi.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Carto importWorker image name
*/}}
{{- define "carto.importWorkerImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.importWorker.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Carto importApi image name
*/}}
{{- define "carto.importApiImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.importApi.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Carto mapsApi image name
*/}}
{{- define "carto.mapsApiImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.mapsApi.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Carto workspaceSubscriber image name
*/}}
{{- define "carto.workspaceSubscriberImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.workspaceSubscriber.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Carto workspaceApi image name
*/}}
{{- define "carto.workspaceApiImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.workspaceApi.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Carto workspaceWWW image name
*/}}
{{- define "carto.workspaceWWWImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.workspaceWWW.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Carto accountsWWW image name
*/}}
{{- define "carto.accountsWWWImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.accountsWWW.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Carto router image name
*/}}
{{- define "carto.routerImage" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.router.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "carto.imagePullSecrets" -}}
{{- include "common.images.pullSecrets" (dict "images" (list .Values.ldsApi.image ) "global" .Values.global) -}}
{{- end -}}

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
Return Carto acc GCP project ID
*/}}
{{- define "configuration.acc.accGCPProjectID" -}}
{{ .Values.configuration.acc.accGCPProjectID }}
{{- end -}}

{{/*
Return Carto acc GCP project region
*/}}
{{- define "configuration.acc.accGCPProjectRegion" -}}
{{ .Values.configuration.acc.accGCPProjectRegion }}
{{- end -}}

{{/*
Return Carto on premise domain
*/}}
{{- define "configuration.onpremDomain" -}}
{{ .Values.configuration.onpremDomain }}
{{- end -}}

{{/*
Return Carto on premise tenant id
*/}}
{{- define "configuration.onpremTenantId" -}}
{{ .Values.configuration.onpremTenantId }}
{{- end -}}

{{/*
Return Carto on premise GCP project ID
*/}}
{{- define "configuration.onpremGCPProjectID" -}}
{{ .Values.configuration.onpremGCPProjectID }}
{{- end -}}

{{/*
Return the common environment variablesproper Docker Image Registry Secret Names
*/}}
{{- define "carto.configure.common" -}}
- name: ONPREM_DOMAIN
  value: {{ include "configuration.onpremDomain" . }}
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
  value: {{ .Values.configuration.postgresql.workspacePostgresHost }}
- name: WORKSPACE_POSTGRES_PORT
  value: {{ .Values.configuration.postgresql.workspacePostgresPort }}
- name: POSTGRES_PASSWORD
  value: {{ .Values.configuration.postgresql.postgresPassword }}
{{- end }}
- name: ONPREM_TENANT_ID
  value: {{ include "configuration.onpremTenantId" . }}
- name: ONPREM_GCP_PROJECT_ID
  value: {{ include "configuration.onpremGCPProjectID" . }}
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
  value: {{ include "configuration.auth0.cartoAuth0ClientID" . }}
- name: CARTO_AUTH0_CUSTOM_DOMAIN
  value: {{ include "configuration.auth0.cartoAuth0CustomDomain" . }}
- name: ACC_DOMAIN
  value: {{ include "configuration.acc.accDomain" . }}
- name: ACC_GCP_PROJECT_ID
  value: {{ include "configuration.acc.accGCPProjectID" . }}
- name: ACC_GCP_PROJECT_REGION
  value: {{ include "configuration.acc.accGCPProjectRegion" . }}
- name: ENCRYPTION_SECRET_KEY
  value: {{ .Values.configuration.encryptionSecretKey }}
- name: WORKSPACE_POSTGRES_PASSWORD
  value: {{ .Values.configuration.postgresql.workspacePostgresPassword }}
- name: CARTO_ONPREMISE_CARTO_DW_LOCATION
  value: {{ .Values.configuration.cartoOnpremiseCartoDWLocation }}
- name: CARTO_ONPREMISE_CUSTOMER_PACKAGE_VERSION
  value: {{ .Values.configuration.cartoOnpremiseCustomerPackageVersion }}
- name: CARTO_ONPREMISE_VERSION
  value: {{ include "configuration.cartoOnpremiseVersion" . }}
- name: GOOGLE_APPLICATION_CREDENTIALS
  value: ../certs/key.json
- name: CARTO3_ONPREM_VOLUMES_BASE_PATH
  value: ./
- name: DOCKER_REGISTRY_BASE_PATH
  value: {{ include "configuration.dockerRegistryBasePath" . }}
- name: CARTO_ONPREMISE_AUTH0_CLIENT_ID
  value: {{ include "configuration.auth0.cartoAuth0ClientID" . }}
- name: ROUTER_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" . }}/router:{{ include "configuration.cartoOnpremiseVersion" . }}
- name: ACCOUNTS_API_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" . }}/accounts-api:{{ include "configuration.cartoOnpremiseVersion" . }}
- name: ACCOUNTS_WWW_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" . }}/accountsWWW:{{ include "configuration.cartoOnpremiseVersion" . }}
- name: WORKSPACE_API_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" . }}/workspaceApi:{{ include "configuration.cartoOnpremiseVersion" . }}
- name: WORKSPACE_WWW_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" . }}/workspaceWWW:{{ include "configuration.cartoOnpremiseVersion" . }}
- name: MAPS_API_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" . }}/mapsApi:{{ include "configuration.cartoOnpremiseVersion" . }}
- name: INTEGRATION_TESTS_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" . }}/integration-tests:{{ include "configuration.cartoOnpremiseVersion" . }}
- name: ACCOUNTS_MIGRATIONS_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" . }}/accounts-db:{{ include "configuration.cartoOnpremiseVersion" . }}
- name: WORKSPACE_MIGRATIONS_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" . }}/workspace-db{{ include "configuration.cartoOnpremiseVersion" . }}
- name: IMPORT_API_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" . }}/importApi:{{ include "configuration.cartoOnpremiseVersion" . }}
- name: LDS_API_DOCKER_IMAGE
  value: {{ include "configuration.dockerRegistryBasePath" . }}/ldsApi:{{ include "configuration.cartoOnpremiseVersion" . }}
- name: REACT_APP_CLIENT_ID
  value: {{ include "configuration.auth0.cartoAuth0ClientID" . }}
- name: REACT_APP_AUTH0_DOMAIN
  value: {{ include "configuration.auth0.cartoAuth0CustomDomain" . }}
- name: REACT_APP_ACCOUNTS_API_URL
  value: https://{{ include "configuration.acc.accDomain" . }}
- name: REACT_APP_ACCOUNTS_URL
  value: https://{{ include "configuration.onpremDomain" . }}/acc/
- name: REACT_APP_WORKSPACE_API_URL
  value: https://{{ include "configuration.onpremDomain" . }}/workspaceApi
- name: REACT_APP_API_BASE_URL
  value: https://{{ include "configuration.onpremDomain" . }}/api
- name: REACT_APP_PUBLIC_MAP_URL
  value: https://{{ include "configuration.onpremDomain" . }}/workspaceApi/maps/public
- name: REACT_APP_AUTH0_AUDIENCE
  value: carto-cloud-native-api
- name: REACT_APP_WORKSPACE_URL_TEMPLATE
  value: https://{tenantDomain}
- name: REACT_APP_CUSTOM_TENANT
  value: {{ include "configuration.onpremTenantId" . }}
- name: REACT_APP_IMPORT_DATASET
  value: carto_dw.carto-dw-{account-id}.shared
- name: REACT_APP_HUBSPOT_ID
  value: 474999
- name: REACT_APP_HUBSPOT_LIMIT_FORM_ID
  value: cd9486fa-5766-4bac-81b9-d8c6cd029b3b
- name: AUTH0_AUDIENCE
  value: carto-cloud-native-api
- name: AUTH0_DOMAIN
  value: {{ include "configuration.auth0.cartoAuth0CustomDomain" . }}
- name: AUTH0_NAMESPACE
  value: http://app.carto.com
- name: LOG_LEVEL
  value: debug
- name: REDIS_CACHE_PREFIX
  value: onprem
- name: REDIS_HOST
  value: redis
- name: REDIS_PORT
  value: 6379
- name: PUBSUB_MODE
  value: pull
- name: PUBSUB_PROJECT_ID
  value: {{ include "configuration.onpremGCPProjectID" . }}
- name: PUBSUB_DATA_UPDATES_TOPICS_TEMPLATE
  value: projects/{project_id}/topics/data-updates
- name: EVENT_BUS_TOPIC
  value: projects/{{ include "configuration.acc.accGCPProjectID" . }}/topics/{{ include "configuration.acc.accGCPProjectRegion" . }}-event-bus
- name: EVENT_BUS_PROJECT_ID
  value: {{ include "configuration.acc.accGCPProjectID" . }}
- name: DO_ENABLED
  value: false
- name: CARTO_ONPREMISE_NAME
  value: {{ include "configuration.onpremTenantId" . }}
- name: CARTO_ONPREMISE_DOMAIN
  value: {{ include "configuration.onpremDomain" . }}
- name: CARTO_ONPREMISE_GCP_PROJECT_ID
  value: {{ include "configuration.onpremGCPProjectID" . }}
- name: WORKSPACE_POSTGRES_USER
  value: workspace_admin
- name: WORKSPACE_POSTGRES_DB
  value: workspace
- name: WORKSPACE_TENANT_ID
  value: {{ include "configuration.onpremTenantId" . }}
- name: WORKSPACE_PUBSUB_DATA_UPDATES_TOPIC
  value: projects/{{ include "configuration.onpremGCPProjectID" . }}/topics/data-updates
- name: WORKSPACE_PUBSUB_DATA_UPDATES_SUBSCRIPTION
  value: projects/{{ include "configuration.onpremGCPProjectID" . }}/subscriptions/data-updates-workspace-sub
- name: MAPS_API_V3_RESOURCE_URL_HOST
  value: {{ include "configuration.onpremDomain" . }}
- name: MAPS_API_V3_RESOURCE_URL_ALLOWED_HOSTS
  value: {{ include "configuration.onpremDomain" . }}
- name: IMPORT_TENANT_ID
  value: {{ include "configuration.onpremTenantId" . }}
- name: IMPORT_WORKER_PROCESSING_DIR
  value: /tmp/importWorker
- name: IMPORT_PUBSUB_TENANT_BUS_TOPIC
  value: projects/{{ include "configuration.onpremGCPProjectID" . }}/topics/tenant-bus
- name: IMPORT_PUBSUB_TENANT_BUS_SUBSCRIPTION
  value: projects/{{ include "configuration.onpremGCPProjectID" . }}/subscriptions/tenant-bus-import-sub
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