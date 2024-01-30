{{/*
Return common collectors for preflights and support-bundle
*/}}
{{- define "carto.replicated.commonChecks.collectors" }}
  - postgres:
      collectorName: workspace-db
      {{- if .Values.externalPostgresql.adminUser }}
      uri: postgresql://{{ include "carto.postgresql.adminUser" . | trimAll "\"" }}:{{ .Values.externalPostgresql.adminPassword | trimAll "\"" }}@{{ include "carto.postgresql.host" . | trimAll "\"" }}:{{ include "carto.postgresql.port" . | trimAll "\"" }}/{{ include "carto.postgresql.adminDatabase" . | trimAll "\"" }}
      {{- else }}
      uri: postgresql://{{ include "carto.postgresql.user" . | trimAll "\"" }}:{{ .Values.externalPostgresql.password | trimAll "\"" }}@{{ include "carto.postgresql.host" . | trimAll "\"" }}:{{ include "carto.postgresql.port" . | trimAll "\"" }}/{{ include "carto.postgresql.databaseName" . | trimAll "\"" }}
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
  - runPod:
      collectorName: support-run-health-on-maps-api
      name: support-run-health-on-maps-api
      namespace: {{ .Release.Namespace | quote }}
      timeout: 180s
      podSpec:
        containers:
          - name: run-health
            image: {{ template "carto.mapsApi.image" . }}
            imagePullPolicy: IfNotPresent
            command: ["bash"]
            args: ["-exc", "npm run ready-to-run:built"]
            env:
            {{- include "carto.replicated.commonChecks.customerValues" . | indent 12 }}
            {{- include "carto.replicated.commonChecks.customerSecrets" . | indent 12 }}
{{- end -}}

{{/*
Return common analyzers for preflights and support-bundle
*/}}
{{- define "carto.replicated.commonChecks.analyzers" }}
  - postgres:
      checkName: PostgreSQL is available
      collectorName: workspace-db
      outcomes:
        - fail:
            when: connected == false
            message: Cannot connect to PostgreSQL server
        - pass:
            when: connected == true
            message: The PostgreSQL server is available
  - postgres:
      checkName: PostgreSQL must be v14.x or later
      collectorName: workspace-db
      outcomes:
        - fail:
            when: connected == false
            message: Cannot connect to PostgreSQL server
        - fail:
            when: version < 14.x
            message: The PostgreSQL server must be at least version 14
        - pass:
            message: The PostgreSQL verion checks out
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
            when: "== kurl"
            message: kURL is a supported distribution.
        - pass:
            when: "== digitalocean"
            message: DigitalOcean is a supported distribution.
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
            when: "sum(allocatableMemory) < 16Gi"
            message: The cluster must contain at least 16Gi. ➡️ Ignore if you have auto-scale enabled in your cluster.
        - warn:
            when: "sum(allocatableMemory) < 17Gi"
            message: The cluster should contain at least 17Gi. ➡️ Ignore if you have auto-scale enabled in your cluster.
        - pass:
            message: There are at least 16 Gi in the cluster.
{{- end -}}

{{/*
Return customer values to use in preflights and support-bundle
*/}}
{{- define "carto.replicated.commonChecks.customerValues" }}
  - name: WORKSPACE_POSTGRES_HOST
    value: {{ include "carto.postgresql.host" . }}
  - name: WORKSPACE_POSTGRES_PORT
    value: {{ include "carto.postgresql.port" . }}
  - name: WORKSPACE_POSTGRES_DB
    value: {{ include "carto.postgresql.databaseName" . }}
  - name: WORKSPACE_POSTGRES_USER
    value: {{ include "carto.postgresql.user" . }}
  - name: MAPS_API_V3_TENANT_ID
    value: {{ .Values.cartoConfigValues.selfHostedTenantId | quote }}
  - name: CARTO_SELFHOSTED_VERSION
    value: {{ .Chart.AppVersion | quote }}
  - name: REDIS_CACHE_PREFIX
    value: "onprem"
  - name: REDIS_HOST
    value: {{ include "carto.redis.host" . }}
  - name: AUTH0_DOMAIN
    value: {{ .Values.cartoConfigValues.cartoAuth0CustomDomain | quote }}
  - name: AUTH0_AUDIENCE
    value: "carto-cloud-native-api"
  - name: PUBSUB_PROJECT_ID
    value: {{ .Values.cartoConfigValues.selfHostedGcpProjectId | quote }}
  - name: MAPS_API_V3_PUBSUB_TENANT_BUS_TOPIC
    value: "projects/{{ .Values.cartoConfigValues.selfHostedGcpProjectId }}/topics/tenant-bus"
{{- end -}}

{{/*
Return customer secrets to use in preflights and support-bundle
*/}}
{{- define "carto.replicated.commonChecks.customerSecrets" }}
  - name: WORKSPACE_POSTGRES_PASSWORD
    value: {{ .Values.externalPostgresql.password | quote }}
  - name: REDIS_PASSWORD
    {{- if .Values.internalRedis.enabled }}
    value: {{ .Values.internalRedis.auth.password | quote }}
    {{- end }}
    {{- if not .Values.internalRedis.enabled }}
    value: {{ .Values.externalRedis.password | quote }}
    {{- end }}
  - name: MAPS_API_V3_JWT_SECRET
    value: {{ .Values.cartoSecrets.jwtApiSecret.value | quote }}
{{- end -}}
