{{/*
Return common collectors for preflights and support-bundle
*/}}
{{- define "carto.replicated.commonChecks.collectors" }}
  - runPod:
      collectorName: tenant-requirements-check
      name: tenant-requirements-check
      namespace: {{ .Release.Namespace | quote }}
      timeout: 180s
      podSpec:
        containers:
          - name: run-tenants-requirements-check
            image: {{ template "carto.tenantRequirementsChecker.image" . }}
            imagePullPolicy: {{ .Values.tenantRequirementsChecker.image.pullPolicy }}
            env:
            {{- include "carto.replicated.tenantRequirementsChecker.customerValues" . | indent 12 }}
            {{- include "carto.replicated.tenantRequirementsChecker.customerSecrets" . | indent 12 }}
            volumeMounts:
              - name: gcp-default-service-account-key
                mountPath: {{ include "carto.google.secretMountDir" . }}
                readOnly: true
              {{- if ( include "carto.googleCloudStorageServiceAccountKey.used" . ) }}
              - name: gcp-buckets-service-account-key
                mountPath: {{ include "carto.googleCloudStorageServiceAccountKey.secretMountDir" . }}
                readOnly: true
              {{- end }}
              {{- if and .Values.externalPostgresql.sslEnabled .Values.externalPostgresql.sslCA }}
              - name: postgresql-ssl-ca
                mountPath: {{ include "carto.postgresql.configMapMountDir" . }}
                readOnly: true
              {{- end }}
              {{- if and .Values.externalRedis.tlsEnabled .Values.externalRedis.tlsCA }}
              - name: redis-tls-ca
                mountPath: {{ include "carto.redis.configMapMountDir" . }}
                readOnly: true
              {{- end }}
              {{- if and .Values.externalProxy.enabled .Values.externalProxy.sslCA }}
              - name: proxy-ssl-ca
                mountPath: {{ include "carto.proxy.configMapMountDir" . }}
                readOnly: true
              {{- end }}
        volumes:
          - name: gcp-default-service-account-key
            secret:
              secretName: {{ include "carto.google.secretName" . }}
              items:
                - key: {{ include "carto.google.secretKey" . }}
                  path: {{ include "carto.google.secretMountFilename" . }}
          {{- if ( include "carto.googleCloudStorageServiceAccountKey.used" . ) }}
          - name: gcp-buckets-service-account-key
            secret:
              secretName: {{ include "carto.googleCloudStorageServiceAccountKey.secretName" . }}
              items:
                - key: {{ include "carto.googleCloudStorageServiceAccountKey.secretKey" . }}
                  path: {{ include "carto.googleCloudStorageServiceAccountKey.secretMountFilename" . }}
          {{- end }}
          {{- if and .Values.externalPostgresql.sslEnabled .Values.externalPostgresql.sslCA }}
          - name: postgresql-ssl-ca
            configMap:
              name: {{ include "carto.postgresql.configMapName" . }}
          {{- end }}
          {{- if and .Values.externalRedis.tlsEnabled .Values.externalRedis.tlsCA }}
          - name: redis-tls-ca
            configMap:
              name: {{ include "carto.redis.configMapName" . }}
          {{- end }}
          {{- if and .Values.externalProxy.enabled .Values.externalProxy.sslCA }}
          - name: proxy-ssl-ca
            configMap:
              name: {{ include "carto.proxy.configMapName" . }}
          {{- end }}
  - redis:
      collectorName: redis
      {{- if .Values.internalRedis.enabled }}
      uri: redis://:{{ .Values.internalRedis.auth.password | trimAll "\"" }}@{{ include "carto.redis.host" . | trimAll "\"" }}:{{ include "carto.redis.port" . | trimAll "\"" }}
      {{- else }}
      uri: redis://:{{ .Values.externalRedis.password | trimAll "\"" }}@{{ include "carto.redis.host" . | trimAll "\"" }}:{{ include "carto.redis.port" . | trimAll "\"" }}
      {{- end }}
  - registryImages:
      images:
        - {{ template "carto.accountsWww.image" . }}
        - {{ template "carto.cdnInvalidatorSub.image" . }}
        - {{ template "carto.httpCache.image" . }}
        - {{ template "carto.importApi.image" . }}
        - {{ template "carto.importWorker.image" . }}
        - {{ template "carto.ldsApi.image" . }}
        - {{ template "carto.mapsApi.image" . }}
        - {{ template "carto.notifier.image" . }}
        - {{ template "carto.router.image" . }}
        - {{ template "carto.sqlWorker.image" . }}
        - {{ template "carto.workspaceApi.image" . }}
        - {{ template "carto.workspaceMigrations.image" . }}
        - {{ template "carto.workspaceSubscriber.image" . }}
        - {{ template "carto.workspaceWww.image" . }}
        - {{ template "carto.tenantRequirementsChecker.image" . }}
{{- end -}}

{{/*
Return common analyzers for preflights and support-bundle
*/}}
{{- define "carto.replicated.commonChecks.analyzers" }}
  {{- range $preflight, $preflightChecks  := dict
      "WorkspaceDatabaseValidator" (list "Check_database_connection" "Check_database_encoding" "Check_user_has_right_permissions" "Check_database_version") 
      "ServiceAccountValidator" (list "Check_valid_service_account")
      "BucketsValidator" (list "Check_assets_bucket" "Check_temp_bucket")
    }}
  {{- range $preflightCheckName := $preflightChecks }}
  - jsonCompare:
      checkName: {{ $preflightCheckName | replace "_" " " }}
      fileName: tenant-requirements-check/tenant-requirements-check.log
      path: "{{ $preflight }}.{{ $preflightCheckName }}.status"
      value: |
        "passed"
      outcomes:
        - fail:
            when: "false"
            message: "{{ printf "{{ .%s.%s.info }}" $preflight $preflightCheckName }}"

        - pass:
            when: "true"
            message: "{{ printf "{{ .%s.%s.info }}" $preflight $preflightCheckName }}"
  {{- end }}
  {{- end }}
  - registryImages:
      checkName: Carto Registry Images
      outcomes:
        - fail:
            when: "missing > 0"
            message: Images are missing from registry
        - warn:
            when: "errors > 0"
            message: Failed to check if images are present in registry
        - pass:
            message: All Carto images are available
  - clusterVersion:
      outcomes:
        - fail:
            when: "< 1.25.0"
            message: The application requires Kubernetes 1.25.0 or later, and recommends 1.26.0 or later.
            uri: https://kubernetes.io/releases
        - warn:
            when: "< 1.26.0"
            message: Your cluster meets the minimum version of Kubernetes, but we recommend you update to 1.26.0 or later.
            uri: https://kubernetes.io/releases
        - pass:
            message: Your cluster meets the recommended and required versions of Kubernetes.
  - containerRuntime:
      outcomes:
        - pass:
            when: "== containerd"
            message: containerd container runtime was found.
        - fail:
            message: Did not find containerd container runtime.
  - distribution:
      outcomes:
        - fail:
            when: "== docker-desktop"
            message: The application does not support Docker Desktop clusters.
        - fail:
            when: "== microk8s"
            message: The application does not support MicroK8s clusters.
        - fail:
            when: "== minikube"
            message: The application does not support minikube clusters.
        - fail:
            when: "== digitalocean"
            message: The application does not support digitalocean platform.
        - pass:
            when: "== eks"
            message: EKS is a supported distribution.
        - pass:
            when: "== gke"
            message: GKE is a supported distribution.
        - pass:
            when: "== aks"
            message: AKS is a supported distribution.
        # Will be supported in the future
        - pass:
            when: "== k0s"
            message: K0s is a supported distribution.
        - warn:
            message: Unable to determine the distribution of Kubernetes.
  - nodeResources:
      checkName: The cluster should contain at least 6 cores
      outcomes:
        - fail:
            when: "sum(cpuCapacity) < 5"
            message: The cluster must contain at least 5 cores. ➡️ Ignore if you have auto-scale enabled in your cluster.
        - warn:
            when: "sum(cpuCapacity) < 6"
            message: The cluster should contain at least 6 cores. ➡️ Ignore if you have auto-scale enabled in your cluster.
        - pass:
            message: There are at least 6 cores in the cluster.
  - nodeResources:
      checkName: The cluster should contain at least 16 Gi
      outcomes:
        - fail:
            when: "sum(memoryAllocatable) < 16Gi"
            message: The cluster must contain at least 16Gi. ➡️ Ignore if you have auto-scale enabled in your cluster.
        - warn:
            when: "sum(memoryAllocatable) < 17Gi"
            message: The cluster should contain at least 17Gi. ➡️ Ignore if you have auto-scale enabled in your cluster.
        - pass:
            message: There are at least 16 Gi in the cluster.
{{- end -}}

{{/*
Return customer values to use in preflights and support-bundle
*/}}
{{- define "carto.replicated.tenantRequirementsChecker.customerValues" }}
  - name: WORKSPACE_POSTGRES_HOST
    value: {{ include "carto.postgresql.host" . }}
  - name: WORKSPACE_POSTGRES_PORT
    value: {{ include "carto.postgresql.port" . }}
  - name: WORKSPACE_POSTGRES_DB
    value: {{ include "carto.postgresql.databaseName" . }}
  - name: WORKSPACE_POSTGRES_USER
    value: {{ include "carto.postgresql.user" . }}
  - name: WORKSPACE_TENANT_ID
    value: {{ .Values.cartoConfigValues.selfHostedTenantId | quote }}
  {{- if not .Values.commonBackendServiceAccount.enableGCPWorkloadIdentity }}
  - name: GOOGLE_APPLICATION_CREDENTIALS
    value: {{ include "carto.google.secretMountAbsolutePath" . }}
  {{- end }}
  - name: WORKSPACE_THUMBNAILS_BUCKET
    value: {{ .Values.appConfigValues.workspaceThumbnailsBucket | quote }}
  - name: WORKSPACE_IMPORTS_BUCKET
    value: {{ .Values.appConfigValues.workspaceImportsBucket | quote }}
  - name: WORKSPACE_THUMBNAILS_PROVIDER
    value: {{ .Values.appConfigValues.storageProvider | quote }}
  - name: WORKSPACE_IMPORTS_PROVIDER
    value: {{ .Values.appConfigValues.storageProvider | quote }}
  - name: WORKSPACE_THUMBNAILS_PUBLIC
    value: {{ .Values.appConfigValues.workspaceThumbnailsPublic | quote }}
  - name: WORKSPACE_IMPORTS_PUBLIC
    value: {{ .Values.appConfigValues.workspaceImportsPublic | quote }}
  {{- if eq .Values.appConfigValues.storageProvider "gcp" }}
  {{- if .Values.appConfigValues.googleCloudStorageProjectId }}
  - name: WORKSPACE_IMPORTS_PROJECTID
    value: {{ .Values.appConfigValues.googleCloudStorageProjectId | quote }}
  - name: WORKSPACE_THUMBNAILS_PROJECTID
    value: {{ .Values.appConfigValues.googleCloudStorageProjectId | quote }}
  {{- end }}
  {{- if ( include "carto.googleCloudStorageServiceAccountKey.used" . ) }}
  - name: WORKSPACE_IMPORTS_KEYFILENAME
    value: {{ include "carto.googleCloudStorageServiceAccountKey.secretMountAbsolutePath" . }}
  - name: WORKSPACE_THUMBNAILS_KEYFILENAME
    value: {{ include "carto.googleCloudStorageServiceAccountKey.secretMountAbsolutePath" . }}
  {{- else }}
  {{- if not .Values.commonBackendServiceAccount.enableGCPWorkloadIdentity }}
  - name: WORKSPACE_IMPORTS_KEYFILENAME
    value: {{ include "carto.google.secretMountAbsolutePath" . }}
  - name: WORKSPACE_THUMBNAILS_KEYFILENAME
    value: {{ include "carto.google.secretMountAbsolutePath" . }}
  {{- end }}
  {{- end }}
  {{- end }}
  {{- if eq .Values.appConfigValues.storageProvider "s3" }}
  - name: WORKSPACE_THUMBNAILS_REGION
    value: {{ .Values.appConfigValues.awsS3Region | quote }}
  - name: WORKSPACE_IMPORTS_REGION
    value: {{ .Values.appConfigValues.awsS3Region | quote }}
  {{- end }}
  {{- if eq .Values.appConfigValues.storageProvider "azure-blob" }}
  - name: WORKSPACE_THUMBNAILS_STORAGE_ACCOUNT
    value: {{ .Values.appConfigValues.azureStorageAccount | quote }}
  - name: WORKSPACE_IMPORTS_STORAGE_ACCOUNT
    value: {{ .Values.appConfigValues.azureStorageAccount | quote }}
  {{- end }}
{{- end -}}

{{/*
Return customer secrets to use in preflights and support-bundle
*/}}
{{- define "carto.replicated.tenantRequirementsChecker.customerSecrets" }}
  - name: WORKSPACE_POSTGRES_PASSWORD
    value: {{ .Values.externalPostgresql.password | quote }}
    {{- include "carto._utils.generateSecretDefs" (dict "vars" (list
                "WORKSPACE_THUMBNAILS_ACCESSKEYID"
                "WORKSPACE_THUMBNAILS_SECRETACCESSKEY"
                "WORKSPACE_THUMBNAILS_STORAGE_ACCESSKEY"
                "WORKSPACE_IMPORTS_ACCESSKEYID"
                "WORKSPACE_IMPORTS_SECRETACCESSKEY"
                "WORKSPACE_IMPORTS_STORAGE_ACCESSKEY"
                ) "context" $ ) }}
{{- end -}}
