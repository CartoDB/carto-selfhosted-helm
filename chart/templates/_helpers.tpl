{{/* vim: set filetype=mustache: */}}

{{/*
Return the version of the chart without removing `-*` from the version
*/}}
{{- define "chart.version" -}}
{{- regexReplaceAll "-*" .Chart.Version "" -}}
{{- end -}}

{{/*
Get the user defined LoadBalancerIP for this release.
Note, returns 127.0.0.1 if using ClusterIP.
*/}}
{{- define "carto.serviceIP" -}}
{{- if eq .Values.router.service.type "ClusterIP" -}}
127.0.0.1
{{- else -}}
{{- .Values.router.service.loadBalancerIP | default "" -}}
{{- end -}}
{{- end -}}

{{/*
Gets the host to be used for this application.
If not using ClusterIP, or if a host or LoadBalancerIP is not defined, the value will be empty.
*/}}
{{- define "carto.baseUrl" -}}
{{- $host := include "carto.serviceIP" . -}}

{{- $port := "" -}}
{{- $servicePortString := printf "%v" .Values.router.service.ports.http -}}
{{- if and (ne $servicePortString "80") (ne $servicePortString "443") -}}
  {{- $port = printf ":%s" $servicePortString -}}
{{- end -}}

{{- $defaultUrl := "" -}}
{{- if $host -}}
  {{- $defaultUrl = printf "%s%s" $host $port -}}
{{- end -}}

{{- default $defaultUrl (printf "%s" .Values.appConfigValues.selfHostedDomain) -}}
{{- end -}}

{{/*
Association between env secret and path of the secret in values.yaml
*/}}
{{- define "carto._utils.secretAssociation" -}}
ENCRYPTION_SECRET_KEY: cartoSecrets.encryptionSecretKey
IMPORT_ACCESSKEYID: appSecrets.awsAccessKeyId
IMPORT_SECRETACCESSKEY: appSecrets.awsAccessKeySecret
IMPORT_STORAGE_ACCESSKEY: appSecrets.azureStorageAccessKey
REACT_APP_GOOGLE_MAPS_API_KEY: appSecrets.googleMapsApiKey
VARNISH_DEBUG_SECRET: cartoSecrets.varnishDebugSecret
VARNISH_PURGE_SECRET: cartoSecrets.varnishPurgeSecret
WORKSPACE_IMPORTS_ACCESSKEYID: appSecrets.awsAccessKeyId
WORKSPACE_IMPORTS_SECRETACCESSKEY: appSecrets.awsAccessKeySecret
WORKSPACE_IMPORTS_STORAGE_ACCESSKEY: appSecrets.azureStorageAccessKey
WORKSPACE_THUMBNAILS_ACCESSKEYID: appSecrets.awsAccessKeyId
WORKSPACE_THUMBNAILS_SECRETACCESSKEY: appSecrets.awsAccessKeySecret
WORKSPACE_THUMBNAILS_STORAGE_ACCESSKEY: appSecrets.azureStorageAccessKey
{{- end -}}

{{/*
Generate secret file content for a variable if a existingSecret.name is not provided
*/}}
{{- define "carto._utils.generateSecretObject" -}}
{{- $var := .var -}}
{{- $context := .context -}}
{{- $mapSecrets := include "carto._utils.secretAssociation" . | fromYaml -}}
{{- $key := get $mapSecrets $var -}}
{{- $secretGroupName := regexReplaceAll "\\..*" $key "" -}}
{{- $secretEntryName := regexReplaceAll ".*\\." $key "" -}}
{{- $secretGroup := get $context.Values $secretGroupName -}}
{{- $secretEntry := get $secretGroup $secretEntryName -}}
{{- $secretValue := $secretEntry.value -}}
{{- $secretExistingName := $secretEntry.existingSecret.name -}}
{{- $secretExistingKey := $secretEntry.existingSecret.key -}}

{{/*
{{ get $mapSecrets $key }}({{ $key }})={{ $secretValue }}:{{ $secretExistingName }}:{{ $secretExistingKey }}:
*/}}
{{- if not $secretExistingName }}
{{ $var }}: {{ $secretValue | b64enc | quote }}  # {{ $key }}.value
{{- end }}
{{- end -}}

{{/*
Generate a secret file content for multiple variables
*/}}
{{- define "carto._utils.generateSecretObjects" -}}
{{- $vars := .vars -}}
{{- $context := .context -}}
{{- range $vars -}}
{{ include "carto._utils.generateSecretObject" (dict "var" . "context" $context ) }}
{{- end }}
{{- end -}}

{{/*
Generate the secret def of one secret to be used in pods definitions
*/}}
{{- define "carto._utils.generateSecretDef" -}}
{{- $var := .var -}}
{{- $context := .context -}}
{{- $mapSecrets := include "carto._utils.secretAssociation" . | fromYaml -}}
{{- $key := get $mapSecrets $var -}}
{{- $secretGroupName := regexReplaceAll "\\..*" $key "" -}}
{{- $secretEntryName := regexReplaceAll ".*\\." $key "" -}}
{{- $secretGroup := get $context.Values $secretGroupName -}}
{{- $secretEntry := get $secretGroup $secretEntryName -}}
{{- $secretValue := $secretEntry.value -}}
{{- $secretExistingName := $secretEntry.existingSecret.name -}}
{{- $secretExistingKey := $secretEntry.existingSecret.key -}}

{{/*
{{ get $mapSecrets $key }}({{ $key }})={{ $secretValue }}:{{ $secretExistingName }}:{{ $secretExistingKey }}:
*/}}
{{- if $secretExistingName }}
- name: {{ $var }}
  valueFrom:
    secretKeyRef:
      name: {{ $secretExistingName | quote }}  # {{ $key }}.existingSecret.name
      key: {{ $secretExistingKey | quote }}    # {{ $key }}.existingSecret.key
{{- end }}
{{- end -}}

{{/*
Generate the secret def to be used in pods definitions
*/}}
{{- define "carto._utils.generateSecretDefs" -}}
{{- $vars := .vars -}}
{{- $context := .context -}}
{{- range $vars -}}
{{ include "carto._utils.generateSecretDef" (dict "var" . "context" $context ) }}
{{- end }}
{{- end -}}

{{/*
As a replacement for "common.images.image" that forces you to set image.tag value
*/}}
{{- define "carto.images.image" -}}
{{- $registryName := .imageRoot.registry -}}
{{- $repositoryName := .imageRoot.repository -}}
{{- $tag := (coalesce .imageRoot.tag .Chart.AppVersion) | toString -}}
{{- if .global }}
    {{- if .global.imageRegistry }}
     {{- $registryName = .global.imageRegistry -}}
    {{- end -}}
{{- end -}}
{{- if $registryName }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- else -}}
{{- printf "%s:%s" $repositoryName $tag -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a `appSecrets.gcpBucketsServiceAccountKey` is specified in any way
*/}}
{{- define "carto.gcpBucketsServiceAccountKey.used" -}}
{{- if or (.Values.appSecrets.gcpBucketsServiceAccountKey.existingSecret.name) (.Values.appSecrets.gcpBucketsServiceAccountKey.value) }}
true
{{- end -}}
{{- end -}}

{{/*
Return the proper GCP Buckets Service Account Key Secret name
*/}}
{{- define "carto.gcpBucketsServiceAccountKey.secretName" -}}
{{- if .Values.appSecrets.gcpBucketsServiceAccountKey.existingSecret.name }}
{{- .Values.cartoSecrets.defaultGoogleServiceAccount.existingSecret.name -}}
{{- else -}}
{{- printf "%s-gcp-buckets-service-account" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper GCP Buckets Service Account Key Secret key
*/}}
{{- define "carto.gcpBucketsServiceAccountKey.secretKey" -}}
{{- if .Values.cartoSecrets.defaultGoogleServiceAccount.existingSecret.key -}}
{{- .Values.cartoSecrets.defaultGoogleServiceAccount.existingSecret.key -}}
{{- else -}}
{{- print "key.json" -}}
{{- end -}}
{{- end -}}

{{/*
Return the directory where the GCP Buckets Service Account Key Secret will  be mounted
*/}}
{{- define "carto.gcpBucketsServiceAccountKey.secretMountDir" -}}
{{- print "/usr/src/certs/gcp-buckets-service-account" -}}
{{- end -}}

{{/*
Return the filename where the GCP Buckets Service Account Key Secret will be mounted
*/}}
{{- define "carto.gcpBucketsServiceAccountKey.secretMountFilename" -}}
{{- print "key.json" -}}
{{- end -}}

{{/*
Return the absolute path where the GCP Buckets Service Account Key Secret will be mounted
*/}}
{{- define "carto.gcpBucketsServiceAccountKey.secretMountAbsolutePath" -}}
{{- printf "%s/%s" (include "carto.gcpBucketsServiceAccountKey.secretMountDir" .) (include "carto.gcpBucketsServiceAccountKey.secretMountFilename" .) -}}
{{- end -}}

{{/*
Return the proper Carto lds-api full name
*/}}
{{- define "carto.ldsApi.fullname" -}}
{{- printf "%s-lds-api" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Carto lds-api image name
*/}}
{{- define "carto.ldsApi.image" -}}
{{- include "carto.images.image" (dict "imageRoot" .Values.ldsApi.image "global" .Values.global "Chart" .Chart) -}}
{{- end -}}

{{/*
Return the proper Carto lds-api ConfigMap name
*/}}
{{- define "carto.ldsApi.configmapName" -}}
{{- if .Values.ldsApi.existingConfigMap -}}
{{- .Values.ldsApi.existingConfigMap -}}
{{- else -}}
{{- include "carto.ldsApi.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto lds-api Secret name
*/}}
{{- define "carto.ldsApi.secretName" -}}
{{- if .Values.ldsApi.existingSecret -}}
{{- .Values.ldsApi.existingSecret -}}
{{- else -}}
{{- include "carto.ldsApi.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the lds-api deployment
*/}}
{{- define "carto.ldsApi.serviceAccountName" -}}
{{- if .Values.ldsApi.serviceAccount.create -}}
{{ default (include "carto.ldsApi.fullname" .) .Values.ldsApi.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.ldsApi.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto import-worker full name
*/}}
{{- define "carto.importWorker.fullname" -}}
{{- printf "%s-import-worker" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Carto import-worker image name
*/}}
{{- define "carto.importWorker.image" -}}
{{- include "carto.images.image" (dict "imageRoot" .Values.importWorker.image "global" .Values.global "Chart" .Chart) -}}
{{- end -}}

{{/*
Return the proper Carto import-worker ConfigMap name
*/}}
{{- define "carto.importWorker.configmapName" -}}
{{- if .Values.importWorker.existingConfigMap -}}
{{- .Values.importWorker.existingConfigMap -}}
{{- else -}}
{{- include "carto.importWorker.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto import-worker Secret name
*/}}
{{- define "carto.importWorker.secretName" -}}
{{- if .Values.importWorker.existingSecret -}}
{{- .Values.importWorker.existingSecret -}}
{{- else -}}
{{- include "carto.importWorker.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the import-worker deployment
*/}}
{{- define "carto.importWorker.serviceAccountName" -}}
{{- if .Values.importWorker.serviceAccount.create -}}
{{ default (include "carto.importWorker.fullname" .) .Values.importWorker.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.importWorker.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto import-api full name
*/}}
{{- define "carto.importApi.fullname" -}}
{{- printf "%s-import-api" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Carto import-api image name
*/}}
{{- define "carto.importApi.image" -}}
{{- include "carto.images.image" (dict "imageRoot" .Values.importApi.image "global" .Values.global "Chart" .Chart) -}}
{{- end -}}

{{/*
Return the proper Carto import-api ConfigMap name
*/}}
{{- define "carto.importApi.configmapName" -}}
{{- if .Values.importApi.existingConfigMap -}}
{{- .Values.importApi.existingConfigMap -}}
{{- else -}}
{{- include "carto.importApi.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto import-api Secret name
*/}}
{{- define "carto.importApi.secretName" -}}
{{- if .Values.importApi.existingSecret -}}
{{- .Values.importApi.existingSecret -}}
{{- else -}}
{{- include "carto.importApi.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the import-api deployment
*/}}
{{- define "carto.importApi.serviceAccountName" -}}
{{- if .Values.importApi.serviceAccount.create -}}
{{ default (include "carto.importApi.fullname" .) .Values.importApi.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.importApi.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto maps-api full name
*/}}
{{- define "carto.mapsApi.fullname" -}}
{{- printf "%s-maps-api" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Carto maps-api image name
*/}}
{{- define "carto.mapsApi.image" -}}
{{- include "carto.images.image" (dict "imageRoot" .Values.mapsApi.image "global" .Values.global "Chart" .Chart) -}}
{{- end -}}

{{/*
Return the proper Carto maps-api ConfigMap name
*/}}
{{- define "carto.mapsApi.configmapName" -}}
{{- if .Values.mapsApi.existingConfigMap -}}
{{- .Values.mapsApi.existingConfigMap -}}
{{- else -}}
{{- include "carto.mapsApi.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto maps-api Secret name
*/}}
{{- define "carto.mapsApi.secretName" -}}
{{- if .Values.mapsApi.existingSecret -}}
{{- .Values.mapsApi.existingSecret -}}
{{- else -}}
{{- include "carto.mapsApi.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the maps-api deployment
*/}}
{{- define "carto.mapsApi.serviceAccountName" -}}
{{- if .Values.mapsApi.serviceAccount.create -}}
{{ default (include "carto.mapsApi.fullname" .) .Values.mapsApi.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.mapsApi.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto workspace-subscriber full name
*/}}
{{- define "carto.workspaceSubscriber.fullname" -}}
{{- printf "%s-workspace-subscriber" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Carto workspace-subscriber image name
*/}}
{{- define "carto.workspaceSubscriber.image" -}}
{{- include "carto.images.image" (dict "imageRoot" .Values.workspaceSubscriber.image "global" .Values.global "Chart" .Chart) -}}
{{- end -}}

{{/*
Return the proper Carto workspace-subscriber ConfigMap name
*/}}
{{- define "carto.workspaceSubscriber.configmapName" -}}
{{- if .Values.workspaceSubscriber.existingConfigMap -}}
{{- .Values.workspaceSubscriber.existingConfigMap -}}
{{- else -}}
{{- include "carto.workspaceSubscriber.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto workspace-subscriber Secret name
*/}}
{{- define "carto.workspaceSubscriber.secretName" -}}
{{- if .Values.workspaceSubscriber.existingSecret -}}
{{- .Values.workspaceSubscriber.existingSecret -}}
{{- else -}}
{{- include "carto.workspaceSubscriber.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the workspace-subscriber deployment
*/}}
{{- define "carto.workspaceSubscriber.serviceAccountName" -}}
{{- if .Values.workspaceSubscriber.serviceAccount.create -}}
{{ default (include "carto.workspaceSubscriber.fullname" .) .Values.workspaceSubscriber.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.workspaceSubscriber.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto workspace-api full name
*/}}
{{- define "carto.workspaceApi.fullname" -}}
{{- printf "%s-workspace-api" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Carto workspaceApi image name
*/}}
{{- define "carto.workspaceApi.image" -}}
{{- include "carto.images.image" (dict "imageRoot" .Values.workspaceApi.image "global" .Values.global "Chart" .Chart) -}}
{{- end -}}

{{/*
Return the proper Carto workspace-api ConfigMap name
*/}}
{{- define "carto.workspaceApi.configmapName" -}}
{{- if .Values.workspaceApi.existingConfigMap -}}
{{- .Values.workspaceApi.existingConfigMap -}}
{{- else -}}
{{- include "carto.workspaceApi.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto workspace-api Secret name
*/}}
{{- define "carto.workspaceApi.secretName" -}}
{{- if .Values.workspaceApi.existingSecret -}}
{{- .Values.workspaceApi.existingSecret -}}
{{- else -}}
{{- include "carto.workspaceApi.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the workspace-api deployment
*/}}
{{- define "carto.workspaceApi.serviceAccountName" -}}
{{- if .Values.workspaceApi.serviceAccount.create -}}
{{ default (include "carto.workspaceApi.fullname" .) .Values.workspaceApi.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.workspaceApi.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
In case you're using an Azure Postgres as an external database you should add two additional parameters
- internalUser: the same as regular user but without the "@db-name" suffix required by Azure connection
- internalAdminuser: the same as adminUser but without the "@db-name" suffix required by Azure connection
Return default user and adminUser values in case the connection it's NOT to an Azure Postgres
*/}}
{{- define "carto.postgresql.internalUser" -}}
{{ default .Values.externalPostgresql.user .Values.externalPostgresql.internalUser }}
{{- end -}}
{{- define "carto.postgresql.internalAdminUser" -}}
{{ default .Values.externalPostgresql.adminUser .Values.externalPostgresql.internalAdminUser }}
{{- end -}}

{{/*
Return the proper Carto workspace-www full name
*/}}
{{- define "carto.workspaceWww.fullname" -}}
{{- printf "%s-workspace-www" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Carto workspace-www image name
*/}}
{{- define "carto.workspaceWww.image" -}}
{{- include "carto.images.image" (dict "imageRoot" .Values.workspaceWww.image "global" .Values.global "Chart" .Chart) -}}
{{- end -}}

{{/*
Return the proper Carto workspace-www ConfigMap name
*/}}
{{- define "carto.workspaceWww.configmapName" -}}
{{- if .Values.workspaceWww.existingConfigMap -}}
{{- .Values.workspaceWww.existingConfigMap -}}
{{- else -}}
{{- include "carto.workspaceWww.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto workspace-www Secret name
*/}}
{{- define "carto.workspaceWww.secretName" -}}
{{- if .Values.workspaceWww.existingSecret -}}
{{- .Values.workspaceWww.existingSecret -}}
{{- else -}}
{{- include "carto.workspaceWww.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the workspace-www deployment
*/}}
{{- define "carto.workspaceWww.serviceAccountName" -}}
{{- if .Values.workspaceWww.serviceAccount.create -}}
{{ default (include "carto.workspaceWww.fullname" .) .Values.workspaceWww.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.workspaceWww.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto accounts-www full name
*/}}
{{- define "carto.accountsWww.fullname" -}}
{{- printf "%s-accounts-www" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Carto accounts-www image name
*/}}
{{- define "carto.accountsWww.image" -}}
{{- include "carto.images.image" (dict "imageRoot" .Values.accountsWww.image "global" .Values.global "Chart" .Chart) -}}
{{- end -}}

{{/*
Return the proper Carto accounts-www ConfigMap name
*/}}
{{- define "carto.accountsWww.configmapName" -}}
{{- if .Values.accountsWww.existingConfigMap -}}
{{- .Values.accountsWww.existingConfigMap -}}
{{- else -}}
{{- include "carto.accountsWww.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto accounts-www Secret name
*/}}
{{- define "carto.accountsWww.secretName" -}}
{{- if .Values.accountsWww.existingSecret -}}
{{- .Values.accountsWww.existingSecret -}}
{{- else -}}
{{- include "carto.accountsWww.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the accounts-www deployment
*/}}
{{- define "carto.accountsWww.serviceAccountName" -}}
{{- if .Values.accountsWww.serviceAccount.create -}}
{{ default (include "carto.accountsWww.fullname" .) .Values.accountsWww.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.accountsWww.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto router full name
*/}}
{{- define "carto.router.fullname" -}}
{{- printf "%s-router" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Carto router image name
*/}}
{{- define "carto.router.image" -}}
{{- include "carto.images.image" (dict "imageRoot" .Values.router.image "global" .Values.global "Chart" .Chart) -}}
{{- end -}}

{{/*
Return the proper Carto router ConfigMap name
*/}}
{{- define "carto.router.configmapName" -}}
{{- if .Values.router.existingConfigMap -}}
{{- .Values.router.existingConfigMap -}}
{{- else -}}
{{- include "carto.router.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto router Secret name
*/}}
{{- define "carto.router.secretName" -}}
{{- if .Values.router.existingSecret -}}
{{- .Values.router.existingSecret -}}
{{- else -}}
{{- include "carto.router.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the router deployment
*/}}
{{- define "carto.router.serviceAccountName" -}}
{{- if .Values.router.serviceAccount.create -}}
{{ default (include "carto.router.fullname" .) .Values.router.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.router.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto http-cache full name
*/}}
{{- define "carto.httpCache.fullname" -}}
{{- printf "%s-http-cache" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Carto http-cache image name
*/}}
{{- define "carto.httpCache.image" -}}
{{- include "carto.images.image" (dict "imageRoot" .Values.httpCache.image "global" .Values.global "Chart" .Chart) -}}
{{- end -}}

{{/*
Return the proper Carto http-cache ConfigMap name
*/}}
{{- define "carto.httpCache.configmapName" -}}
{{- if .Values.httpCache.existingConfigMap -}}
{{- .Values.httpCache.existingConfigMap -}}
{{- else -}}
{{- include "carto.httpCache.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto http-cache Secret name
*/}}
{{- define "carto.httpCache.secretName" -}}
{{- if .Values.httpCache.existingSecret -}}
{{- .Values.httpCache.existingSecret -}}
{{- else -}}
{{- include "carto.httpCache.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the http-cache deployment
*/}}
{{- define "carto.httpCache.serviceAccountName" -}}
{{- if .Values.httpCache.serviceAccount.create -}}
{{ default (include "carto.httpCache.fullname" .) .Values.httpCache.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.httpCache.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto cdn-invalidator-sub full name
*/}}
{{- define "carto.cdnInvalidatorSub.fullname" -}}
{{- printf "%s-cdn-invalidator-sub" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Carto cdn-invalidator-sub image name
*/}}
{{- define "carto.cdnInvalidatorSub.image" -}}
{{- include "carto.images.image" (dict "imageRoot" .Values.cdnInvalidatorSub.image "global" .Values.global "Chart" .Chart) -}}
{{- end -}}

{{/*
Return the proper Carto cdn-invalidator-sub ConfigMap name
*/}}
{{- define "carto.cdnInvalidatorSub.configmapName" -}}
{{- if .Values.cdnInvalidatorSub.existingConfigMap -}}
{{- .Values.cdnInvalidatorSub.existingConfigMap -}}
{{- else -}}
{{- include "carto.cdnInvalidatorSub.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto cdn-invalidator-sub Secret name
*/}}
{{- define "carto.cdnInvalidatorSub.secretName" -}}
{{- if .Values.cdnInvalidatorSub.existingSecret -}}
{{- .Values.cdnInvalidatorSub.existingSecret -}}
{{- else -}}
{{- include "carto.cdnInvalidatorSub.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the cdn-invalidator-sub deployment
*/}}
{{- define "carto.cdnInvalidatorSub.serviceAccountName" -}}
{{- if .Values.cdnInvalidatorSub.serviceAccount.create -}}
{{ default (include "carto.cdnInvalidatorSub.fullname" .) .Values.cdnInvalidatorSub.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.cdnInvalidatorSub.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto workspace-db image name
*/}}
{{- define "carto.workspaceMigrations.image" -}}
{{- include "carto.images.image" (dict "imageRoot" .Values.workspaceMigrations.image "global" .Values.global "Chart" .Chart) -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "carto.imagePullSecrets" -}}
{{- include "common.images.pullSecrets" (dict "images" (dict .Values.accountsWww.image .Values.importApi.image .Values.importWorker.image .Values.ldsApi.image .Values.mapsApi.image .Values.router.image .Values.httpCache.image .Values.cdnInvalidatorSub.image  .Values.workspaceApi.image .Values.workspaceSubscriber.image .Values.workspaceWww.image .Values.workspaceMigrations.image) "global" .Values.global) -}}
{{- end -}}

{{/*
Google Secret => Default Google Service Account
*/}}

{{/*
Return the proper Carto Google Secret name
*/}}
{{- define "carto.google.secretName" -}}
{{- if .Values.cartoSecrets.defaultGoogleServiceAccount.existingSecret.name -}}
{{- .Values.cartoSecrets.defaultGoogleServiceAccount.existingSecret.name -}}
{{- else -}}
{{- printf "%s-gcp-default-service-account" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto Google Secret key
*/}}
{{- define "carto.google.secretKey" -}}
{{- if .Values.cartoSecrets.defaultGoogleServiceAccount.existingSecret.name -}}
{{- .Values.cartoSecrets.defaultGoogleServiceAccount.existingSecret.key -}}
{{- else -}}
{{- print "key.json" -}}
{{- end -}}
{{- end -}}

{{/*
Return the directory where the Google Secret will be mounted
*/}}
{{- define "carto.google.secretMountDir" -}}
{{- print "/usr/src/certs/gcp-default-service-account" -}}
{{- end -}}

{{/*
Return the filename where the Google Secret will be mounted
*/}}
{{- define "carto.google.secretMountFilename" -}}
{{- print "key.json" -}}
{{- end -}}

{{/*
Return the absolute path where the Google Secret will be mounted
*/}}
{{- define "carto.google.secretMountAbsolutePath" -}}
{{- printf "%s/%s" (include "carto.google.secretMountDir" .) (include "carto.google.secretMountFilename" .) -}}
{{- end -}}

{{/*
Return the proper Carto TLS Secret name
*/}}
{{- define "carto.tlsCerts.secretName" -}}
{{- if .Values.tlsCerts.existingSecret.name -}}
{{- .Values.tlsCerts.existingSecret.name -}}
{{- else -}}
{{- printf "%s-tls" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto TLS secret key for the TLS cert
*/}}
{{- define "carto.tlsCerts.secretCertKey" -}}
{{- if .Values.tlsCerts.existingSecret.name -}}
{{- .Values.tlsCerts.existingSecret.certKey -}}
{{- else -}}
{{- print "tls.crt" -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Carto TLS secret key for the TLS key
*/}}
{{- define "carto.tlsCerts.secretKeyKey" -}}
{{- if .Values.tlsCerts.existingSecret.name -}}
{{- .Values.tlsCerts.existingSecret.keyKey -}}
{{- else -}}
{{- print "tls.key" -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified postgresql name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "carto.postgresql.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "postgresql" "chartValues" .Values.internalPostgresql "context" $) -}}
{{- end -}}

{{/*
Get the Postgresql credentials secret.
*/}}
{{- define "carto.postgresql.secretName" -}}
{{- if and (.Values.internalPostgresql.enabled) (not .Values.internalPostgresql.auth.existingSecret) -}}
    {{- printf "%s" (include "carto.postgresql.fullname" .) -}}
{{- else if and (.Values.internalPostgresql.enabled) (.Values.internalPostgresql.auth.existingSecret) -}}
    {{- printf "%s" .Values.internalPostgresql.auth.existingSecret -}}
{{- else }}
    {{- if .Values.externalPostgresql.existingSecret -}}
        {{- printf "%s" .Values.externalPostgresql.existingSecret -}}
    {{- else -}}
        {{ printf "%s-%s" .Release.Name "externalpostgresql" }}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "carto.postgresql.host" -}}
{{- ternary (include "carto.postgresql.fullname" .) .Values.externalPostgresql.host .Values.internalPostgresql.enabled | quote -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "carto.postgresql.user" -}}
{{- ternary .Values.internalPostgresql.auth.username .Values.externalPostgresql.user .Values.internalPostgresql.enabled | quote -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "carto.postgresql.adminUser" -}}
{{- ternary "postgres" .Values.externalPostgresql.adminUser .Values.internalPostgresql.enabled | quote -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "carto.postgresql.databaseName" -}}
{{- ternary .Values.internalPostgresql.auth.database .Values.externalPostgresql.database .Values.internalPostgresql.enabled | quote -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "carto.postgresql.secret.key" -}}
{{- if .Values.internalPostgresql.enabled -}}
    {{- printf "%s" "password" -}}
{{- else -}}
    {{- if .Values.externalPostgresql.existingSecret -}}
        {{- if .Values.externalPostgresql.existingSecretPasswordKey -}}
            {{- printf "%s" .Values.externalPostgresql.existingSecretPasswordKey -}}
        {{- else -}}
            {{- printf "%s" "db-password" -}}
        {{- end -}}
    {{- else -}}
        {{- printf "%s" "db-password" -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "carto.postgresql.secret.adminKey" -}}
{{- if .Values.internalPostgresql.enabled -}}
    {{- print "postgres-password" -}}
{{- else -}}
    {{- if .Values.externalPostgresql.existingSecret -}}
        {{- if .Values.externalPostgresql.existingSecretAdminPasswordKey -}}
            {{- printf "%s" .Values.externalPostgresql.existingSecretAdminPasswordKey -}}
        {{- else -}}
            {{- print "db-admin-password" -}}
        {{- end -}}
    {{- else -}}
        {{- print "db-admin-password" -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "carto.postgresql.port" -}}
{{- ternary "5432" .Values.externalPostgresql.port .Values.internalPostgresql.enabled | quote -}}
{{- end -}}

{{/*
Get the Postgresql config map name
*/}}
{{- define "carto.postgresql.configMapName" -}}
{{- if .Values.internalPostgresql.enabled -}}
  {{- include "carto.postgresql.fullname" . -}}
{{- else }}
  {{- printf "%s-%s" .Release.Name "externalpostgresql" -}}
{{- end -}}
{{- end -}}

{{/*
Return the directory where the Postgresql CA cert will  be mounted
*/}}
{{- define "carto.postgresql.configMapMountDir" -}}
{{- print "/usr/src/certs/postgresql-ssl-ca" -}}
{{- end -}}

{{/*
Return the filename where the Postgresql CA will be mounted
*/}}
{{- define "carto.postgresql.configMapMountFilename" -}}
{{- print "ca.crt" -}}
{{- end -}}

{{/*
Return the absolute path where the Postgresql CA cert will be mounted
*/}}
{{- define "carto.postgresql.configMapMountAbsolutePath" -}}
{{- printf "%s/%s" (include "carto.postgresql.configMapMountDir" .) (include "carto.postgresql.configMapMountFilename" .) -}}
{{- end -}}

{{/*
Return YAML for the PostgreSQL init container
Usage:
Non-admin user
{{ include "carto.postgresql-init-container" (dict "context" $) }}
Admin user
{{ include "carto.postgresql-init-container" (dict "context" $ "admin" "true") }}
*/}}
{{- define "carto.postgresql-init-container" -}}
# NOTE: The value internalPostgresql.image is not available unless internalPostgresql.enabled is not set. We could change this to use bitnami-shell if
# it had the binary wait-for-port.
# This init container is for avoiding CrashLoopback errors in the main container because the PostgreSQL container is not ready
- name: wait-for-db
  image: {{ include "common.images.image" (dict "imageRoot" .context.Values.internalPostgresql.image "global" .context.Values.global) }}
  imagePullPolicy: {{ .context.Values.internalPostgresql.image.pullPolicy  }}
  command:
    - /bin/bash
  args:
    - -ec
    - |
      #!/bin/bash

      set -o errexit
      set -o nounset
      set -o pipefail

      . /opt/bitnami/scripts/libos.sh
      . /opt/bitnami/scripts/liblog.sh
      . /opt/bitnami/scripts/libpostgresql.sh

      check_postgresql_connection() {
          echo "SELECT 1" | postgresql_remote_execute "$POSTGRESQL_CLIENT_DATABASE_HOST" "$POSTGRESQL_CLIENT_DATABASE_PORT_NUMBER" "$POSTGRESQL_CLIENT_DATABASE_NAME" "$POSTGRESQL_CLIENT_POSTGRES_USER" "$POSTGRESQL_CLIENT_CREATE_DATABASE_PASSWORD"
      }

      info "Connecting to the PostgreSQL instance $POSTGRESQL_CLIENT_DATABASE_HOST:$POSTGRESQL_CLIENT_DATABASE_PORT_NUMBER"
      if ! retry_while "check_postgresql_connection" {{- if not .admin }} 100{{- end }}; then
          error "Could not connect to the database server"
          exit 1
      else
          info "Connected to the PostgreSQL instance"
      fi
  {{- if .context.Values.workspaceMigrations.containerSecurityContext.enabled }}
  securityContext: {{- omit .context.Values.workspaceMigrations.containerSecurityContext "enabled" | toYaml | nindent 12 }}
  {{- end }}
  env:
    - name: POSTGRESQL_CLIENT_DATABASE_HOST
      value: {{ include "carto.postgresql.host" .context }}
    - name: POSTGRESQL_CLIENT_DATABASE_PORT_NUMBER
      value: {{ include "carto.postgresql.port" .context }}
    {{- if .admin }}
    - name: POSTGRESQL_CLIENT_CREATE_DATABASE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "carto.postgresql.secretName" .context }}
          key: {{ include "carto.postgresql.secret.adminKey" .context }}
    - name: POSTGRESQL_CLIENT_POSTGRES_USER
      value: {{ include "carto.postgresql.adminUser" .context }}
    - name: POSTGRESQL_CLIENT_DATABASE_NAME
      value: "postgres"
    {{- else }}
    - name: POSTGRESQL_CLIENT_CREATE_DATABASE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "carto.postgresql.secretName" .context }}
          key: {{ include "carto.postgresql.secret.key" .context  }}
    - name: POSTGRESQL_CLIENT_POSTGRES_USER
      value: {{ include "carto.postgresql.user" .context }}
    - name: POSTGRESQL_CLIENT_DATABASE_NAME
      value: {{ include "carto.postgresql.databaseName" .context }}
    {{- end }}
{{- end -}}

{{/*
Create a default fully qualified redis name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "carto.redis.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "redis" "chartValues" .Values.internalRedis "context" $) -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "carto.redis.host" -}}
{{- ternary (printf "%s-master" (include "carto.redis.fullname" .)) .Values.externalRedis.host .Values.internalRedis.enabled | quote -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "carto.redis.port" -}}
{{- ternary "6379" .Values.externalRedis.port .Values.internalRedis.enabled | quote -}}
{{- end -}}

{{/*
Add environment variables to configure Redis values
*/}}
{{- define "carto.redis.existingsecret.key" -}}
{{- if .Values.internalRedis.enabled -}}
    {{- print "redis-password" -}}
{{- else -}}
    {{- if .Values.externalRedis.existingSecret -}}
        {{- if .Values.externalRedis.existingSecretPasswordKey -}}
            {{- printf "%s" .Values.externalRedis.existingSecretPasswordKey -}}
        {{- else -}}
            {{- print "redis-password" -}}
        {{- end -}}
    {{- else -}}
        {{- print "redis-password" -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Get the Redis credentials secret.
*/}}
{{- define "carto.redis.secretName" -}}
{{- if and (.Values.internalRedis.enabled) (not .Values.internalRedis.existingSecret) -}}
    {{- printf "%s" (include "carto.redis.fullname" .) -}}
{{- else if and (.Values.internalRedis.enabled) (.Values.internalRedis.existingSecret) -}}
    {{- printf "%s" .Values.internalRedis.existingSecret -}}
{{- else }}
    {{- if .Values.externalRedis.existingSecret -}}
        {{- printf "%s" .Values.externalRedis.existingSecret -}}
    {{- else -}}
        {{ printf "%s-%s" .Release.Name "externalredis" }}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Get the Redis config map name
*/}}
{{- define "carto.redis.configMapName" -}}
{{- if .Values.internalRedis.enabled -}}
  {{- include "carto.redis.fullname" . -}}
{{- else }}
  {{- printf "%s-%s" .Release.Name "externalredis" -}}
{{- end -}}
{{- end -}}

{{/*
Return the directory where the Redis CA cert will  be mounted
*/}}
{{- define "carto.redis.configMapMountDir" -}}
{{- print "/usr/src/certs/redis-tls-ca" -}}
{{- end -}}

{{/*
Return the filename where the Redis CA will be mounted
*/}}
{{- define "carto.redis.configMapMountFilename" -}}
{{- print "ca.crt" -}}
{{- end -}}

{{/*
Return the absolute path where the Redis CA cert will be mounted
*/}}
{{- define "carto.redis.configMapMountAbsolutePath" -}}
{{- printf "%s/%s" (include "carto.redis.configMapMountDir" .) (include "carto.redis.configMapMountFilename" .) -}}
{{- end -}}

{{/*
Return YAML for the Redis init container
*/}}
{{- define "carto.redis-init-container" -}}
# NOTE: The value redis.image is not available unless redis.enabled is not set. We could change this to use bitnami-shell if
# it had the binary wait-for-port.
# This init container is for avoiding CrashLoopback errors in the main container because the PostgreSQL container is not ready
- name: wait-for-redis
  image: {{ include "common.images.image" (dict "imageRoot" .Values.internalRedis.image "global" .Values.global) }}
  imagePullPolicy: {{ .Values.internalRedis.image.pullPolicy  }}
  command:
    - /bin/bash
  args:
    - -ec
    - |
      #!/bin/bash

      set -o errexit
      set -o nounset
      set -o pipefail

      . /opt/bitnami/scripts/libos.sh
      . /opt/bitnami/scripts/liblog.sh
      . /opt/bitnami/scripts/libredis.sh

      check_redis_connection() {
          echo "INFO" | redis-cli -a "$REDIS_CLIENT_PASSWORD" -p "$REDIS_CLIENT_PORT_NUMBER" -h "$REDIS_CLIENT_HOST"
      }

      info "Connecting to the Redis instance $REDIS_CLIENT_HOST:$REDIS_CLIENT_PORT_NUMBER"
      if ! retry_while "check_redis_connection"; then
          error "Could not connect to the Redis server"
          exit 1
      else
          info "Connected to the Redis instance"
      fi
  {{- if .Values.workspaceMigrations.containerSecurityContext.enabled }}
  securityContext: {{- omit .Values.workspaceMigrations.containerSecurityContext "enabled" | toYaml | nindent 4 }}
  {{- end }}
  env:
    - name: REDIS_CLIENT_HOST
      value: {{ ternary (include "carto.redis.fullname" .) .Values.externalRedis.host .Values.internalRedis.enabled }}
    - name: REDIS_CLIENT_PORT_NUMBER
      value: {{ ternary "6379" .Values.externalRedis.port .Values.internalRedis.enabled | quote }}
    - name: REDIS_CLIENT_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "carto.redis.secretName" . }}
          key: "redis-password"
{{- end -}}

{{/*
Validate external Redis config
*/}}
{{- define "carto.validateValues.redis" -}}
{{- if and (not .Values.internalRedis.enabled) (not .Values.externalRedis.host) -}}
CARTO: Missing Redis(TM)

If internalRedis.enabled=false you need to specify the host of an external Redis(TM) instance setting externalRedis.host
{{- end -}}
{{- end -}}

{{/*
Validate external Redis config
*/}}
{{- define "carto.validateValues.postgresql" -}}
{{- if and (not .Values.internalRedis.enabled) (not .Values.externalRedis.host) -}}
CARTO: Missing PostgreSQL

If internalPostgresql.enabled=false you need to specify the host of an external PostgreSQL instance setting externalPostgresql.host
{{- end -}}
{{- end -}}

{{/*
Compile all warnings into a single message, and call fail.
*/}}
{{- define "carto.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "carto.validateValues.redis" .) -}}
{{- $messages := append $messages (include "carto.validateValues.postgresql" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}
