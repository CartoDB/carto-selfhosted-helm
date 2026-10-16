{{/*
The workspace-api container's env and envFrom, shared by its Deployment and the maps-purge CronJob.
Rendered at the Deployment's container indentation; other callers re-indent it.
*/}}
{{- define "carto.workspaceApi.containerEnv" }}
          env:
            - name: WORKSPACE_POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "carto.postgresql.secretName" . }}
                  key: {{ include "carto.postgresql.secret.key" . }}
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "carto.redis.secretName" . }}
                  key: {{ include "carto.redis.existingsecret.key" . | quote }}
            {{- include "carto._utils.generateSecretDefs" (dict "vars" (concat (list
              "BIGQUERY_OAUTH2_CLIENT_SECRET"
              "ENCRYPTION_SECRET_KEY"
              "LAUNCHDARKLY_SDK_KEY"
              "WORKSPACE_JWT_SECRET"
              "WORKSPACE_THUMBNAILS_ACCESSKEYID"
              "WORKSPACE_THUMBNAILS_SECRETACCESSKEY"
              "WORKSPACE_THUMBNAILS_STORAGE_ACCESSKEY"
              "WORKSPACE_IMPORTS_ACCESSKEYID"
              "WORKSPACE_IMPORTS_SECRETACCESSKEY"
              "WORKSPACE_IMPORTS_STORAGE_ACCESSKEY"
              ) (include "carto.workspaceApi.disconnectedSecretVars" $ | fromYamlArray)) "context" $ ) | nindent 12 }}
            {{- with (include "carto.nats.clientEnv" (dict "context" $)) }}{{ . | nindent 12 }}{{- end }}
            {{- if .Values.workspaceApi.extraEnvVars }}
            {{- include "common.tplvalues.render" (dict "value" .Values.workspaceApi.extraEnvVars "context" $) | nindent 12 }}
            {{- end }}
          envFrom:
            - configMapRef:
                name: {{ template "carto.workspaceApi.configmapName" . }}
            {{- $secretContent := include "carto._utils.generateSecretObjects" (dict "vars" (concat (list
              "BIGQUERY_OAUTH2_CLIENT_SECRET"
              "ENCRYPTION_SECRET_KEY"
              "LAUNCHDARKLY_SDK_KEY"
              "WORKSPACE_JWT_SECRET"
              "WORKSPACE_THUMBNAILS_ACCESSKEYID"
              "WORKSPACE_THUMBNAILS_SECRETACCESSKEY"
              "WORKSPACE_THUMBNAILS_STORAGE_ACCESSKEY"
              "WORKSPACE_IMPORTS_ACCESSKEYID"
              "WORKSPACE_IMPORTS_SECRETACCESSKEY"
              "WORKSPACE_IMPORTS_STORAGE_ACCESSKEY"
            ) (include "carto.workspaceApi.disconnectedSecretVars" $ | fromYamlArray)) "context" $ ) -}}
            {{- if $secretContent }}
            - secretRef:
                name: {{ include "carto.workspaceApi.secretName" . }}
            {{- end }}
            {{- if .Values.workspaceApi.extraEnvVarsCM }}
            - configMapRef:
                name: {{ include "common.tplvalues.render" (dict "value" .Values.workspaceApi.extraEnvVarsCM "context" $) }}
            {{- end }}
            {{- if .Values.workspaceApi.extraEnvVarsSecret }}
            - secretRef:
                name: {{ include "common.tplvalues.render" (dict "value" .Values.workspaceApi.extraEnvVarsSecret "context" $) }}
            {{- end }}
{{- end }}

{{/*
The workspace-api container's volumeMounts, shared like carto.workspaceApi.containerEnv.
*/}}
{{- define "carto.workspaceApi.volumeMounts" }}
          volumeMounts:
            - name: wif-credentials
              mountPath: /tmp/wif-credentials
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
            {{- if (include "carto.trustedCACerts.enabled" .) }}
            - name: trusted-ca-certs
              mountPath: {{ include "carto.trustedCACerts.configMapMountDir" . }}
              readOnly: true
            {{- end }}
            {{- if (include "carto.featureFlags.enabled" .) }}
            - name: feature-flags
              mountPath: {{ include "carto.featureFlags.configMapMountDir" . }}
              subPath: custom-feature-flags.yaml
              readOnly: true
            {{- end }}
          {{- if .Values.workspaceApi.extraVolumeMounts }}
          {{- include "common.tplvalues.render" (dict "value" .Values.workspaceApi.extraVolumeMounts "context" $) | nindent 12 }}
          {{- end }}
{{- end }}

{{/*
The workspace-api pod's volumes, shared like carto.workspaceApi.containerEnv.
*/}}
{{- define "carto.workspaceApi.volumes" }}
      volumes:
        - name: wif-credentials
          emptyDir: {}
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
        {{- if (include "carto.trustedCACerts.enabled" .) }}
        - name: trusted-ca-certs
          configMap:
            name: {{ include "carto.trustedCACerts.configMapName" . }}
        {{- end }}
        {{- if (include "carto.featureFlags.enabled" .) }}
        - name: feature-flags
          configMap:
            name: {{ template "carto.featureFlags.configMapName" . }}
            items:
              - key: custom-feature-flags.yaml
                path: custom-feature-flags.yaml
        {{- end }}
        {{- if .Values.workspaceApi.extraVolumes }}
        {{- include "common.tplvalues.render" (dict "value" .Values.workspaceApi.extraVolumes "context" $) | nindent 8 }}
        {{- end }}
{{- end }}
