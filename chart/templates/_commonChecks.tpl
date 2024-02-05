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
  {{- range list 
        "Check_database_connection"
        "Check_database_encoding"
        "Check_user_has_right_permissions"
        "Check_database_version"
    }}
  - jsonCompare:
      checkName: {{ . | replace "_" " " }}
      fileName: tenant-requirements-check/tenant-requirements-check.log
      path: "WorkspaceDatabaseValidator.{{ . }}.status"
      value: |
        "passed"
      outcomes:
        - fail:
            when: "false"
            message: "fail"
        - pass:
            when: "true"
            message: "pass"
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
{{- define "carto.replicated.tenantRequirementsChecker.customerValues" }}
  - name: WORKSPACE_POSTGRES_HOST
    value: {{ include "carto.postgresql.host" . }}
  - name: WORKSPACE_POSTGRES_PORT
    value: {{ include "carto.postgresql.port" . }}
  - name: WORKSPACE_POSTGRES_DB
    value: {{ include "carto.postgresql.databaseName" . }}
  - name: WORKSPACE_POSTGRES_USER
    value: {{ include "carto.postgresql.user" . }}
{{- end -}}

{{/*
Return customer secrets to use in preflights and support-bundle
*/}}
{{- define "carto.replicated.tenantRequirementsChecker.customerSecrets" }}
  - name: WORKSPACE_POSTGRES_PASSWORD
    value: {{ .Values.externalPostgresql.password | quote }}
{{- end -}}
