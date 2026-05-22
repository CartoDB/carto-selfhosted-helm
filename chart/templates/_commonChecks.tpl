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
        {{- if include "carto.podIdentity.enabled" . }}
        serviceAccountName: {{ template "carto.commonSA.serviceAccountName" . }}
        {{- end }}
        restartPolicy: Never
        securityContext: {{- toYaml .Values.tenantRequirementsChecker.podSecurityContext | nindent 10 }}
        initContainers:
          - name: init-tenant-requirements-check
            image: {{ template "carto.tenantRequirementsChecker.image" . }}
            imagePullPolicy: {{ .Values.tenantRequirementsChecker.image.pullPolicy }}
            securityContext: {{- toYaml .Values.tenantRequirementsChecker.containerSecurityContext | nindent 14 }}
            resources: {{- toYaml .Values.tenantRequirementsChecker.resources | nindent 14 }}
            command: ["/bin/bash", "-c"]
            args:
              - |
                #!/bin/bash

                set -ex

                # This script is used to transform environment variables in files
                # How to use it?
                # 1. Set the environment variables with the content of the files you want to create (e.g. MY__FILE_CONTENT="my content")
                # 2. Set the environment variables with the path of the files you want to create (e.g. MY__FILE_PATH="/path/to/my/file")
                # 3. Run the script

                # Extract the list of unique prefixes variables to transform in files (All ended with _FILE_CONTENT but only pick before the __FILE_CONTENT)
                PREFIXES=$(env | grep __FILE_CONTENT | awk -F__ '{print $1}' | sort | uniq)


                # Check that all prefixes have a corresponding __FILE_PATH
                for PREFIX in $PREFIXES; do
                  if [ -z "$(env | grep ${PREFIX}__FILE_PATH)" ]; then
                    echo "No path found for prefix $PREFIX"
                    exit 1
                  fi
                done

                # Transform the variables into files
                for PREFIX in $PREFIXES; do
                  FILE_PATH=$(env | grep "${PREFIX}__FILE_PATH" | awk -F= '{print $2}')
                  FILE_CONTENT=""

                  if [ "$(env | grep -c "${PREFIX}__FILE_CONTENT")" -eq 1 ]; then
                    FILE_CONTENT_VAR="${PREFIX}__FILE_CONTENT"
                    FILE_CONTENT=$(eval "echo \$$FILE_CONTENT_VAR")
                  else
                    for VAR_NAME in $(env | grep "${PREFIX}__FILE_CONTENT" | awk -F= '{print $1}' | sort -V); do
                      FILE_CONTENT="${FILE_CONTENT}$(eval "echo \$$VAR_NAME")"
                    done
                  fi

                  # Try decoding the content; if it succeeds, write decoded; else write raw
                  if echo "$FILE_CONTENT" | base64 -d >/dev/null 2>&1; then
                    echo "$FILE_CONTENT" | base64 -d > "$FILE_PATH"
                  else
                    echo "$FILE_CONTENT" > "$FILE_PATH"
                  fi
                done
            env:
              {{- if not .Values.commonBackendServiceAccount.enableGCPWorkloadIdentity }}
              {{- if eq .Values.cartoSecrets.defaultGoogleServiceAccount.existingSecret.name "" }}
              - name: DEFAULT_SERVICE_ACCOUNT_KEY__FILE_CONTENT
                value: {{ .Values.cartoSecrets.defaultGoogleServiceAccount.value | b64enc | quote }}
              {{- else }}
              - name: DEFAULT_SERVICE_ACCOUNT_KEY__FILE_CONTENT
                valueFrom:
                  secretKeyRef:
                    name: {{ .Values.cartoSecrets.defaultGoogleServiceAccount.existingSecret.name | quote }}
                    key: {{ .Values.cartoSecrets.defaultGoogleServiceAccount.existingSecret.key | quote }}
              {{- end }}
              - name: DEFAULT_SERVICE_ACCOUNT_KEY__FILE_PATH
                value: {{ include "carto.google.secretMountAbsolutePath" . }}
              {{- if ( include "carto.googleCloudStorageServiceAccountKey.used" . ) }}
              {{- if eq .Values.appSecrets.googleCloudStorageServiceAccountKey.existingSecret.name "" }}
              - name: STORAGE_SERVICE_ACCOUNT_KEY__FILE_CONTENT
                value: {{ .Values.appSecrets.googleCloudStorageServiceAccountKey.value | b64enc | quote }}
              {{- else }}
              - name: STORAGE_SERVICE_ACCOUNT_KEY__FILE_CONTENT
                valueFrom:
                  secretKeyRef:
                    name: {{ .Values.appSecrets.googleCloudStorageServiceAccountKey.existingSecret.name | quote }}
                    key: {{ .Values.appSecrets.googleCloudStorageServiceAccountKey.existingSecret.key | quote }}
              {{- end }}
              - name: STORAGE_SERVICE_ACCOUNT_KEY__FILE_PATH
                value: {{ include "carto.googleCloudStorageServiceAccountKey.secretMountAbsolutePath" . }}
              {{- end }}
              {{- end }}
              {{- if and .Values.externalPostgresql.sslEnabled .Values.externalPostgresql.sslCA }}
              {{/* We need to split the SSL CA content in chunks of 10000 characters */}}
              {{- include "carto.tenantRequirementsChecker.externalPostgresql.sslCA" . }}
              - name: POSTGRES_SSL_CA__FILE_PATH
                value: {{ include "carto.postgresql.configMapMountAbsolutePath" . }}
              {{- end }}
              {{- if and .Values.externalRedis.tlsEnabled .Values.externalRedis.tlsCA }}
              - name: REDIS_TLS_CA__FILE_CONTENT
                value: {{ .Values.externalRedis.tlsCA | b64enc | quote }}
              - name: REDIS_TLS_CA__FILE_PATH
                value: {{ include "carto.redis.configMapMountAbsolutePath" . }}
              {{- end }}
              {{- if and .Values.externalProxy.enabled .Values.externalProxy.sslCA }}
              - name: PROXY_SSL_CA__FILE_CONTENT
                value: {{ .Values.externalProxy.sslCA | b64enc | quote }}
              - name: PROXY_SSL_CA__FILE_PATH
                value: {{ include "carto.proxy.configMapMountAbsolutePath" . }}
              {{- end }}
              {{- if and .Values.router.tlsCertificates.certificateValueBase64 .Values.router.tlsCertificates.privateKeyValueBase64 }}
              - name: ROUTER_SSL_CERT__FILE_CONTENT
                value: {{ .Values.router.tlsCertificates.certificateValueBase64 | quote }}
              - name: ROUTER_SSL_CERT__FILE_PATH
                value: "/etc/ssl/certs/cert.crt"
              - name: ROUTER_SSL_CERT_KEY__FILE_CONTENT
                value: {{ .Values.router.tlsCertificates.privateKeyValueBase64 | quote }}
              - name: ROUTER_SSL_CERT_KEY__FILE_PATH
                value: "/etc/ssl/certs/cert.key"
              {{- end }}
            volumeMounts:
              - name: gcp-default-service-account-key
                mountPath: {{ include "carto.google.secretMountDir" . }}
                readOnly: false
              {{- if ( include "carto.googleCloudStorageServiceAccountKey.used" . ) }}
              - name: gcp-buckets-service-account-key
                mountPath: {{ include "carto.googleCloudStorageServiceAccountKey.secretMountDir" . }}
                readOnly: false
              {{- end }}
              {{- if and .Values.externalPostgresql.sslEnabled .Values.externalPostgresql.sslCA }}
              - name: postgresql-ssl-ca
                mountPath: {{ include "carto.postgresql.configMapMountDir" . }}
                readOnly: false
              {{- end }}
              {{- if and .Values.externalRedis.tlsEnabled .Values.externalRedis.tlsCA }}
              - name: redis-tls-ca
                mountPath: {{ include "carto.redis.configMapMountDir" . }}
                readOnly: false
              {{- end }}
              {{- if and .Values.externalProxy.enabled .Values.externalProxy.sslCA }}
              - name: proxy-ssl-ca
                mountPath: {{ include "carto.proxy.configMapMountDir" . }}
                readOnly: false
              {{- end }}
              {{- if and .Values.router.tlsCertificates.certificateValueBase64 .Values.router.tlsCertificates.privateKeyValueBase64 }}
              - name: router-tls-cert-and-key
                mountPath: /etc/ssl/certs/
                readOnly: false
              {{- end }}
        containers:
          - name: run-tenants-requirements-check
            image: {{ template "carto.tenantRequirementsChecker.image" . }}
            imagePullPolicy: {{ .Values.tenantRequirementsChecker.image.pullPolicy }}
            securityContext: {{- toYaml .Values.tenantRequirementsChecker.containerSecurityContext | nindent 14 }}
            resources: {{- toYaml .Values.tenantRequirementsChecker.resources | nindent 14 }}
            env:
              {{- if .Values.externalPostgresql.awsEksPodIdentityEnabled }}
              - name: CARTO_SELFHOSTED_AWS_EKS_POD_IDENTITY_METADATA_DB_ENABLED
                value: "true"
              - name: CARTO_SELFHOSTED_AWS_RDS_METADATA_REGION
                value: {{ .Values.externalPostgresql.awsRdsRegion | quote }}
              {{- end }}
              {{- if .Values.appConfigValues.awsEksPodIdentityBucketsEnabled }}
              - name: CARTO_SELFHOSTED_AWS_EKS_POD_IDENTITY_S3_ENABLED
                value: "true"
              {{- end }}
              {{- if .Values.cartoConfigValues.featureFlagsOverrides }}
              - name: OVERRIDDEN_FEATURE_FLAGS
                value: {{ include "carto.featureFlags.overriddenFeatureFlags" . | quote }}
              {{- end }}
              - name: PUBSUB_PROJECT_ID
                value: {{ .Values.cartoConfigValues.selfHostedGcpProjectId | quote }}
              - name: PUBSUB_CUSTOM_DOMAIN
                value: {{ .Values.cartoConfigValues.pubsubDomain | quote }}
              - name: TENANT_REQUIREMENTS_CHECKER_PUBSUB_TENANT_BUS_TOPIC
                value: projects/{{ .Values.cartoConfigValues.selfHostedGcpProjectId }}/topics/tenant-bus
              - name: TENANT_REQUIREMENTS_CHECKER_PUBSUB_TENANT_BUS_SUBSCRIPTION
                value: projects/{{ .Values.cartoConfigValues.selfHostedGcpProjectId }}/subscriptions/tenant-bus-tenant-requirements-checker-sub
            {{- include "carto.replicated.tenantRequirementsChecker.customerValues" . | nindent 12 }}
            {{- include "carto.replicated.tenantRequirementsChecker.customerSecrets" . | nindent 12 }}
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
              {{- if and .Values.externalProxy.enabled (or .Values.externalProxy.sslCA .Values.externalProxy.sslCAConfigmap.name) }}
              - name: proxy-ssl-ca
                mountPath: {{ include "carto.proxy.configMapMountDir" . }}
                readOnly: true
              {{- end }}
              {{- if and .Values.router.tlsCertificates.certificateValueBase64 .Values.router.tlsCertificates.privateKeyValueBase64 }}
              - name: router-tls-cert-and-key
                mountPath: /etc/ssl/certs/
                readOnly: true
              {{- end }}
        volumes:
          - name: gcp-default-service-account-key
            emptyDir:
              sizeLimit: 8Mi
          {{- if ( include "carto.googleCloudStorageServiceAccountKey.used" . ) }}
          - name: gcp-buckets-service-account-key
            emptyDir:
              sizeLimit: 8Mi
          {{- end }}
          {{- if and .Values.externalPostgresql.sslEnabled .Values.externalPostgresql.sslCA }}
          - name: postgresql-ssl-ca
            emptyDir:
              sizeLimit: 8Mi
          {{- end }}
          {{- if and .Values.externalRedis.tlsEnabled .Values.externalRedis.tlsCA }}
          - name: redis-tls-ca
            emptyDir:
              sizeLimit: 8Mi
          {{- end }}
          {{- if .Values.externalProxy.sslCAConfigmap.name }}
          - name: proxy-ssl-ca
            configMap:
              name: {{ .Values.externalProxy.sslCAConfigmap.name }}
          {{- end }}
          {{- if and .Values.externalProxy.enabled .Values.externalProxy.sslCA }}
          - name: proxy-ssl-ca
            emptyDir:
              sizeLimit: 1Mi
          {{- end }}
          {{- if and .Values.router.tlsCertificates.certificateValueBase64 .Values.router.tlsCertificates.privateKeyValueBase64 }}
          - name: router-tls-cert-and-key
            emptyDir:
              sizeLimit: 1Mi
          {{- end }}
  - registryImages:
      namespace: {{ .Release.Namespace | quote }}
      {{/*
        We cannot use the imagePullSecrets template that we have because the registryImages collector needs a single imagePullSecret.
        As we just include the preflights if using Replicated the carto-registry secret should be present always!
      */}}
      imagePullSecret:
        name: carto-registry
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
Return common analyzers for preflights and support-bundle.
NOTE: Remember that with the ingress testing mode the components are not deployed, so take it into account when adding a new preflight!!
*/}}
{{- define "carto.replicated.commonChecks.analyzers" }}
  {{- $preflightsDict := dict
      "WorkspaceDatabaseValidator" (list "Check_database_connection" "Check_database_encoding" "Check_user_has_right_permissions" "Check_database_version") 
      "ServiceAccountValidator" (list "Check_valid_service_account")
      "BucketsValidator" (list "Check_assets_bucket" "Check_temp_bucket")
      "EgressRequirementsValidator" (list "Check_CARTO_Auth_connectivity" "Check_PubSub_connectivity" "Check_Google_Storage_connectivity" "Check_release_channels_connectivity" "Check_Google_Storage_connectivity" "Check_CARTO_images_registry_connectivity" "Check_TomTom_connectivity" "Check_TravelTime_connectivity")
      "PubSubValidator" (list "Check_publish_and_listen_to_topic")
  }}
  
  {{/* Add optional analyzers to the preflightsDict */}}

  {{- $preflightOptionalList := list
      "Check_TravelTime_connectivity"
      "Check_TomTom_connectivity"
  }}

  {{/*
  We push conditionally new analyzers for the feature flags if the customer defined overridden feature flags
  */}}
  {{- if .Values.cartoConfigValues.featureFlagsOverrides }}
  {{- $_ := set $preflightsDict "FeatureFlagsValidator" (list "Check_valid_feature_flags") -}}
  {{- end }}
  {{/*
  */}}
  {{/*
  We push conditionally new analyzers for the certs provided if they're provided for: Postgres, Redis and Router SSL
  */}}
  {{- $certChecks := list }}
  {{- if and .Values.router.tlsCertificates.certificateValueBase64 .Values.router.tlsCertificates.privateKeyValueBase64 }}
  {{- $certChecks = append $certChecks "Check_Router_certificate" }}
  {{- end }}
  {{- if and .Values.externalPostgresql.sslEnabled .Values.externalPostgresql.sslCA }}
  {{- $certChecks = append $certChecks "Check_Postgres_certificate" }}
  {{- end }}
  {{- if and .Values.externalRedis.tlsEnabled .Values.externalRedis.tlsCA }}
  {{- $certChecks = append $certChecks "Check_Redis_certificate" }}
  {{- end }}
  {{- if gt (len $certChecks) 0 }}
  {{- $_ := set $preflightsDict "CertificatesValidator" $certChecks -}}
  {{- end }}
  {{/*
  We just need to add the RedisValidator to the preflightsDict if the externalRedis is enabled
  */}}
  {{- if not .Values.internalRedis.enabled }}
  {{- $_ := set $preflightsDict "RedisValidator" (list "Check_redis_connection" "Check_redis_multiple_databases_support") }}
  {{- end }}
  {{- range $preflight, $preflightChecks  := $preflightsDict }}
  {{- range $preflightCheckName := $preflightChecks }}
  - jsonCompare:
      checkName: {{ $preflightCheckName | replace "_" " " }}
      fileName: tenant-requirements-check/tenant-requirements-check.log
      path: "{{ $preflight }}.{{ $preflightCheckName }}.status"
      value: |
        "passed"
      outcomes:
        - pass:
            when: "true"
            message: "{{ printf "{{ .%s.%s.info }}" $preflight $preflightCheckName }}"
      {{- if has $preflightCheckName $preflightOptionalList}}
        - warn:
            when: "false"
            message: "{{ printf "{{ .%s.%s.info }}" $preflight $preflightCheckName }}"
      {{- else }}
        - fail:
            when: "false"
            message: "{{ printf "{{ .%s.%s.info }}" $preflight $preflightCheckName }}"
      {{- end }}  
  {{- end }}
  {{- end }}
  {{/*
  Commented until replicated fixes this: https://github.com/replicated-collab/carto-replicated/issues/30
  */}}
  # - registryImages:
  #   checkName: Carto Registry Images
  #    outcomes:
  #      - fail:
  #          when: "missing > 0"
  #          message: Images are missing from registry
  #      - warn:
  #          when: "errors > 0"
  #          message: Failed to check if images are present in registry
  #      - pass:
  #          message: All Carto images are available
  {{/*
  We only can run the following preflight checks and get the platform distribution when a cluster role is created.
  Otherwise, we cannot obtain this info
  */}}
  {{- if ne .Values.replicated.platformDistribution "" }}
  - clusterVersion:
      outcomes:
        - fail:
            when: "< 1.29.0"
            message: The application requires Kubernetes 1.29.0 or later, and recommends 1.30.0 or later.
            uri: https://kubernetes.io/releases
        - warn:
            when: "< 1.30.0"
            message: Your cluster meets the minimum version of Kubernetes, but we recommend you update to 1.30.0 or later.
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
        - pass:
            when: "== openShift"
            message: OpenShift is a supported distribution.
        # Will be supported in the future
        - pass:
            when: "== embedded-cluster"
            message: Using single VM deployment.
        - warn:
            message: Unable to determine the distribution of Kubernetes.
  - nodeResources:
      checkName: The cluster should contain at least 6 cores
      outcomes:
        - fail:
            when: "sum(cpuCapacity) < 6"
            message: The cluster must contain at least 6 cores. ➡️ Ignore if you have auto-scale enabled in your cluster.
        - pass:
            message: There are at least 6 cores in the cluster.
  - nodeResources:
      checkName: The cluster should contain at least 16 Gi of RAM memory
      outcomes:
        - fail:
            when: "sum(memoryAllocatable) < 16Gi"
            message: The cluster must contain at least 16Gi of RAM memory. ➡️ Ignore if you have auto-scale enabled in your cluster.
        - pass:
            message: There are at least 16 Gi in the cluster.
  {{- end }}
  {{- if .Values.gateway.enabled }}
  - customResourceDefinition:
      checkName: Gateway API available
      customResourceDefinitionName: gateways.gateway.networking.k8s.io
      outcomes:
        - fail:
            message: Gateway API is not enabled for your cluster. Please enable it to continue.
        - pass:
            message: Gateway API is enabled for your cluster.
  {{- end }}
{{- end -}}

{{/*
Return customer values to use in preflights and support-bundle
*/}}
{{- define "carto.replicated.tenantRequirementsChecker.customerValues" }}
  - name: CARTO_SELFHOSTED_VERSION
    value: {{ .Chart.AppVersion | quote }}
  - name: REDIS_CACHE_PREFIX 
    value: "onprem"
  - name: REDIS_HOST
    value: {{ include "carto.redis.host" . | quote }}
  - name: REDIS_PORT
    value: {{ include "carto.redis.port" . | quote }}
  - name: REDIS_DB
    value: "0"
  - name: LITELLM_REDIS_DB
    value: "1"
  - name: REDIS_TLS_ENABLED
    value: {{ .Values.externalRedis.tlsEnabled | quote }}
  {{- if and .Values.externalRedis.tlsEnabled .Values.externalRedis.tlsCA }}
  - name: REDIS_TLS_CA
    value: {{ include "carto.redis.configMapMountAbsolutePath" . }}
  {{- end }}
  - name: WORKSPACE_POSTGRES_HOST
    value: {{ include "carto.postgresql.host" . | quote }}
  - name: WORKSPACE_POSTGRES_PORT
    value: {{ include "carto.postgresql.port" . | quote }}
  - name: WORKSPACE_POSTGRES_DB
    value: {{ include "carto.postgresql.databaseName" . | quote }}
  - name: WORKSPACE_POSTGRES_USER
    value: {{ include "carto.postgresql.user" . | quote }}
  - name: WORKSPACE_POSTGRES_SSL_ENABLED
    value: {{ .Values.externalPostgresql.sslEnabled | quote }}
  {{- if and .Values.externalPostgresql.sslEnabled .Values.externalPostgresql.sslCA }}
  - name: WORKSPACE_POSTGRES_SSL_CA
    value: {{ include "carto.postgresql.configMapMountAbsolutePath" . }}
  {{- end }}
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
  {{- if .Values.externalProxy.enabled }}
  - name: HTTP_PROXY
    value: {{ include "carto.proxy.computedConnectionString" . | quote }}
  - name: http_proxy
    value: {{ include "carto.proxy.computedConnectionString" . | quote }}
  - name: HTTPS_PROXY
    value: {{ include "carto.proxy.computedConnectionString" . | quote }}
  - name: https_proxy
    value: {{ include "carto.proxy.computedConnectionString" . | quote }}
  - name: GRPC_PROXY
    value: {{ include "carto.proxy.computedConnectionString" . | quote }}
  - name: grpc_proxy
    value: {{ include "carto.proxy.computedConnectionString" . | quote }}
  - name: NODE_TLS_REJECT_UNAUTHORIZED
    value: {{ ternary "1" "0" .Values.externalProxy.sslRejectUnauthorized | quote }}
  {{- if gt (len .Values.externalProxy.excludedDomains) 0 }}
  - name: NO_PROXY
    value: {{ join "," .Values.externalProxy.excludedDomains | quote }}
  - name: no_proxy
    value: {{ join "," .Values.externalProxy.excludedDomains | quote }}
  {{- end }}
  {{- if (or .Values.externalProxy.sslCA .Values.externalProxy.sslCAConfigmap.name) }}
  - name: NODE_EXTRA_CA_CERTS
    value: {{ include "carto.proxy.configMapMountAbsolutePath" . | quote }}
  {{- end }}
  {{- end }}
  {{- if and .Values.router.tlsCertificates.certificateValueBase64 .Values.router.tlsCertificates.privateKeyValueBase64 }}
  - name: ROUTER_SSL_CERT
    value: "/etc/ssl/certs/cert.crt"
  - name: ROUTER_SSL_CERT_KEY
    value: "/etc/ssl/certs/cert.key"
  {{- end }}
{{- end -}}

{{/*
Return customer secrets to use in preflights and support-bundle
*/}}
{{- define "carto.replicated.tenantRequirementsChecker.customerSecrets" }}
  {{- if eq .Values.externalPostgresql.existingSecret "" }}
  - name: WORKSPACE_POSTGRES_PASSWORD
    value: {{ .Values.externalPostgresql.password | quote }}
  {{- else }}
  - name: WORKSPACE_POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ include "carto.postgresql.secretName" . }}
        key: {{ include "carto.postgresql.secret.key" . }}
  {{- end -}}
  {{- if eq .Values.externalRedis.existingSecret "" }}
  - name: REDIS_PASSWORD
    value: {{ .Values.externalRedis.password | quote }}
  {{- else }}
  - name: REDIS_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ include "carto.redis.secretName" . }}
        key: {{ include "carto.redis.existingsecret.key" . | quote }}
  {{- end -}}
  {{- if eq .Values.cartoSecrets.launchDarklySdkKey.existingSecret.name "" }}
  - name: LAUNCHDARKLY_SDK_KEY
    value: {{ .Values.cartoSecrets.launchDarklySdkKey.value | quote }}
  {{- else -}}
  {{ include "carto._utils.generateSecretDef" (dict "var" "LAUNCHDARKLY_SDK_KEY" "context" .) | nindent 2 }}
  {{- end -}}
  {{- if eq .Values.appConfigValues.storageProvider "s3" -}}
  {{- if eq .Values.appSecrets.awsAccessKeyId.existingSecret.name "" }}
  - name: WORKSPACE_THUMBNAILS_ACCESSKEYID
    value: {{ .Values.appSecrets.awsAccessKeyId.value | quote }}
  {{- else -}}
  {{ include "carto._utils.generateSecretDef" (dict "var" "WORKSPACE_THUMBNAILS_ACCESSKEYID" "context" .) | nindent 2 }}
  {{- end -}}
  {{- if eq .Values.appSecrets.awsAccessKeyId.existingSecret.name "" }}
  - name: WORKSPACE_IMPORTS_ACCESSKEYID
    value: {{ .Values.appSecrets.awsAccessKeyId.value | quote }}
  {{- else -}}
  {{ include "carto._utils.generateSecretDef" (dict "var" "WORKSPACE_IMPORTS_ACCESSKEYID" "context" .) | nindent 2 }}
  {{- end -}}
  {{- if eq .Values.appSecrets.awsAccessKeySecret.existingSecret.name "" }}
  - name: WORKSPACE_THUMBNAILS_SECRETACCESSKEY
    value: {{ .Values.appSecrets.awsAccessKeySecret.value | quote }}
  {{- else -}}
  {{ include "carto._utils.generateSecretDef" (dict "var" "WORKSPACE_THUMBNAILS_SECRETACCESSKEY" "context" .) | nindent 2 }}
  {{- end -}}
  {{- if eq .Values.appSecrets.awsAccessKeySecret.existingSecret.name "" }}
  - name: WORKSPACE_IMPORTS_SECRETACCESSKEY
    value: {{ .Values.appSecrets.awsAccessKeySecret.value | quote }}
  {{- else -}}
  {{ include "carto._utils.generateSecretDef" (dict "var" "WORKSPACE_IMPORTS_SECRETACCESSKEY" "context" .) | nindent 2 }}
  {{- end -}}
  {{- end -}}
  {{- if eq .Values.appConfigValues.storageProvider "azure-blob" }}
  {{- if eq .Values.appSecrets.azureStorageAccessKey.existingSecret.name "" }}
  - name: WORKSPACE_THUMBNAILS_STORAGE_ACCESSKEY
    value: {{ .Values.appSecrets.azureStorageAccessKey.value | quote }}
  {{- else -}}
  {{ include "carto._utils.generateSecretDef" (dict "var" "WORKSPACE_THUMBNAILS_STORAGE_ACCESSKEY" "context" .) | nindent 2 }}
  {{- end -}}
  {{- if eq .Values.appSecrets.azureStorageAccessKey.existingSecret.name "" }}
  - name: WORKSPACE_IMPORTS_STORAGE_ACCESSKEY
    value: {{ .Values.appSecrets.azureStorageAccessKey.value | quote }}
  {{- else -}}
  {{ include "carto._utils.generateSecretDef" (dict "var" "WORKSPACE_IMPORTS_STORAGE_ACCESSKEY" "context" .) | nindent 2 }}
  {{- end -}}
  {{- end -}}
{{- end -}}


{{ define "carto.tenantRequirementsChecker.externalPostgresql.sslCA" }}
  {{- $value := .Values.externalPostgresql.sslCA -}}
  {{- $maxLength := 10000 -}}
  {{- if gt (len $value) $maxLength -}}
    {{- $neededChunks := int (div (len $value) $maxLength | ceil) -}}
    {{- range $i, $chunk := until (add $neededChunks 1 | int) -}}
      {{- $envVarName := printf "POSTGRES_SSL_CA__FILE_CONTENT_%02d" (add $i 1) }}
      {{- $chunk := substr (mul $i $maxLength | int) (mul (add $i 1) $maxLength | int) $value }}
              - name: {{$envVarName}}
                value: {{ $chunk | b64enc }}
    {{- end -}}
  {{- else -}}
  - name: POSTGRES_SSL_CA__FILE_CONTENT
    {{ printf "value: %s" ($value | b64enc | quote) | indent 12 }}
  {{- end -}}
{{ end }}


{{/*
Return redactor specs for the preflight and support-bundle collectors.

Replicated Troubleshoot applies these redactors in-stream, *before* the
support bundle tar.gz is written and before anything leaves the cluster.
Any byte that matches a `mask` capture group is replaced with `***HIDDEN***`
in the captured artifact.

This is the primary leak control for the chart, layered on top of the
built-in redactors that Replicated/KOTS ships (env vars named *PASSWORD*,
*TOKEN*, *ACCESS_KEY_ID, *SECRET_ACCESS_KEY, *OWNER_ACCOUNT, and
protocol://user:pass@host connection strings).

Patterns are scoped narrowly to known credential shapes to minimise
false-positive redaction in debug bundles. Add a new pattern when a new
credential shape is introduced. Verify by running:

  helm template chart -f values.yaml \
    | yq '.stringData."support-bundle.yaml"' \
    | troubleshoot redact < a-real-captured-bundle.tar.gz

against a fixture and confirming known plaintext sentinels (BEGIN PRIVATE
KEY, AKIA, AIzaSy, sk-, sdk-) do not appear in the output.

The leak surfaces this set targets, derived from 24 real support bundles:
  - PodSpec env captures by the clusterResources collector
  - tenant-requirements-check runPod pod definition snapshot
  - Replicated SDK license-info stdout dump, which leaks
    cartoPlatformDefaultSA private_key, openAiApiKey, geminiApiKey,
    vitallyToken, cartoFeaturesFlagSdkKey, and other license entitlements
    in plaintext
*/}}
{{- define "carto.replicated.commonChecks.redactors" }}
# IMPORTANT: redactor order matters. Replicated Troubleshoot applies them
# sequentially, so any outer/longer container must be redacted BEFORE its
# inner/shorter substrings. Specifically, the GCP service-account JSON
# (when base64-wrapped) contains a base64-encoded PEM private key inside
# it. If we redact the inner PEM first, the GCP outer match no longer has
# enough remaining bytes to satisfy its length requirement and leaks.

# GCP service account JSON — base64-wrapped whole object. The three prefixes
# cover {"type":"service_account" with three common whitespace layouts.
# DEFAULT_SERVICE_ACCOUNT_KEY__FILE_CONTENT and STORAGE_SERVICE_ACCOUNT_KEY
# inline as base64 of this JSON (~3000+ chars in real bundles).
# MUST run before pem-private-keys-base64.
- name: gcp-sa-json-base64
  removals:
    regex:
      - redactor: '(?P<mask>(?:eyAidHlwZSI6|ewogICJ0eXBlIjogInNlcnZpY2VfYWNjb3VudCI|eyJ0eXBlIjoic2VydmljZV9hY2NvdW50)[A-Za-z0-9+/=]{50,})'
# GCP service account JSON — private_key field inside any JSON object.
- name: gcp-sa-private-key-field
  removals:
    regex:
      - redactor: '"private_key"\s*:\s*"(?P<mask>-----BEGIN[^"]+)"'

# PEM private keys — raw form (e.g. inside replicated-sdk license dump's
# cartoPlatformDefaultSA JSON private_key field after JSON unescaping in logs).
- name: pem-private-keys-raw
  removals:
    regex:
      - redactor: '(?P<mask>-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----)'
# PEM private keys — base64-wrapped form (ROUTER_SSL_CERT_KEY__FILE_CONTENT
# inlines as base64 of "-----BEGIN ... PRIVATE KEY-----", which starts with
# LS0tLS1CRUdJTi...). Bounded length keeps it from over-matching short blobs.
- name: pem-private-keys-base64
  removals:
    regex:
      - redactor: '(?P<mask>LS0tLS1CRUdJTi[A-Za-z0-9+/=]{200,})'

# LaunchDarkly SDK and mobile keys (well-known shape).
- name: launchdarkly-sdk-keys
  removals:
    regex:
      - redactor: '(?P<mask>\bsdk-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b)'
- name: launchdarkly-mobile-keys
  removals:
    regex:
      - redactor: '(?P<mask>\bmob-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b)'

# AWS access key IDs (production + STS temporary).
- name: aws-access-key-ids
  removals:
    regex:
      - redactor: '(?P<mask>\b(?:AKIA|ASIA)[0-9A-Z]{16}\b)'

# OpenAI / Anthropic-style `sk-`-prefixed API keys, including sk-svcacct- and
# sk-proj- variants observed in real license dumps.
- name: openai-sk-keys
  removals:
    regex:
      - redactor: '(?P<mask>\bsk-(?:svcacct-|proj-|None-)?[A-Za-z0-9_-]{20,}\b)'

# Google API keys (AIzaSy...) — geminiApiKey, googleMapsApiKey.
- name: google-api-keys
  removals:
    regex:
      - redactor: '(?P<mask>\bAIza[0-9A-Za-z_-]{35}\b)'

# JWT tokens — raw header.payload.signature form.
- name: jwt-tokens
  removals:
    regex:
      - redactor: '(?P<mask>\beyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b)'
# JWT tokens — base64-wrapped form (vitallyToken in license dumps is base64 of
# a JWT, so it starts with ZXlK which is base64 of "eyJ").
- name: jwt-tokens-base64-wrapped
  removals:
    regex:
      - redactor: '(?P<mask>\bZXlK[A-Za-z0-9+/=]{50,}\b)'

# Replicated license entitlement scrub. Scoped to the license-info file only,
# so the regex does not redact unrelated `"value":"..."` JSON fields elsewhere.
# Catches any future entitlement we forget to add a shape rule for, plus the
# ones with no recognisable shape (databaseEncryptionKey, jwtEncryptionKey,
# instanceId, cartoAuthClientId).
- name: carto-license-sensitive-entitlements
  fileSelector:
    files:
      - "**/replicated-sdk/**/replicated-license-info-stdout.txt"
      - "**/replicated-sdk/**/replicated-license-info-stderr.txt"
  removals:
    regex:
      - redactor: '"(?:cartoPlatformDefaultSA|cartoFeaturesFlagSdkKey|openAiApiKey|geminiApiKey|vitallyToken|databaseEncryptionKey|jwtEncryptionKey|ldsConfiguration|cartoAuthClientId|instanceId)"[^}]*"value"\s*:\s*"(?P<mask>[^"]+)"'

# Final fallback: scrub every env value in the tenant-requirements-check pod
# definition. Scoped via fileSelector so it does NOT redact env values across
# the rest of the bundle (which would break debugging of LOG_LEVEL, NODE_ENV,
# bucket names, etc.). Covers values with no recognisable shape — Azure
# storage keys (WORKSPACE_*_STORAGE_ACCESSKEY, 88-char base64), unusual
# Postgres passwords that escape the built-in *PASSWORD* env name match, and
# anything else added here in the future.
- name: tenant-requirements-check-env-fallback
  fileSelector:
    files:
      - "**/tenant-requirements-check/tenant-requirements-check.json"
  removals:
    yamlPath:
      - "spec.containers.*.env.*.value"
      - "spec.initContainers.*.env.*.value"
{{- end -}}
