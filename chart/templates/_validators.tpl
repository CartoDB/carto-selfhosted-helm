{{/*
Validate external Valkey / Redis-compatible cache config
*/}}
{{- define "carto.validateValues.redis" -}}
{{- if and (not .Values.internalRedis.enabled) (not .Values.externalRedis.host) (not .Values.cartoConfigValues.onlyRunRouter) -}}
CARTO: Missing Valkey / Redis-compatible cache

If internalRedis.enabled=false you need to specify the host of an external Valkey or Redis-compatible instance setting externalRedis.host
{{- end -}}
{{- end -}}

{{/*
Validate external Postgres config
*/}}
{{- define "carto.validateValues.postgresql" -}}
{{- if and (not .Values.internalPostgresql.enabled) (not .Values.externalPostgresql.host) -}}
CARTO: Missing PostgreSQL

If internalPostgresql.enabled=false you need to specify the host of an external PostgreSQL instance setting externalPostgresql.host
{{- end -}}
{{- end -}}

{{/*
Validate external Proxy config
*/}}
{{- define "carto.validateValues.proxy" -}}
{{- if and .Values.externalProxy.enabled .Values.externalProxy.sslCA .Values.externalProxy.sslCAConfigmap.name -}}
CARTO: Duplicated SSL CA

If externalProxy.enabled=true you need to specify either externalProxy.sslCA or externalProxy.sslCAConfigmap, not both.
{{- end -}}
{{- end -}}

{{/*
Validate log level
*/}}
{{- define "carto.validateValues.logLevel" -}}
{{- $validLevels := list "info" "debug" "error" -}}
{{- if not (has .Values.appConfigValues.logLevel $validLevels) -}}
{{- printf "Invalid logLevel: %s. Must be one of %v" .Values.appConfigValues.logLevel $validLevels -}}
{{- end -}}
{{- end -}}

{{/*
Validate ServiceAccount configuration when Pod Identity features are enabled
*/}}
{{- define "carto.validateValues.serviceAccount" -}}
{{- $podIdentityEnabled := include "carto.podIdentity.enabled" . -}}
{{- $saConfigured := or .Values.commonBackendServiceAccount.create .Values.commonBackendServiceAccount.name -}}
{{- if and $podIdentityEnabled (not $saConfigured) -}}
CARTO: ServiceAccount misconfiguration for Pod Identity

When using a Pod Identity feature, you must either create a new Service Account (commonBackendServiceAccount.create=true) or specify an existing one (commonBackendServiceAccount.name).

One or more Pod Identity features are enabled:
  - GCP Workload Identity: {{ .Values.commonBackendServiceAccount.enableGCPWorkloadIdentity }}
  - AWS EKS Pod Identity (PostgreSQL): {{ .Values.externalPostgresql.awsEksPodIdentityEnabled }}
  - AWS EKS Pod Identity (S3 Buckets): {{ .Values.appConfigValues.awsEksPodIdentityBucketsEnabled }}

Review CARTO public docs: 
  https://docs.carto.com/carto-self-hosted/guides/guides-helm/use-workload-identity-in-gcp
  https://docs.carto.com/carto-self-hosted/guides/guides-helm/use-eks-pod-identity-in-aws
{{- end -}}
{{- end -}}

{{/*
Validate S3-compatible values are only set when the storage provider is s3
*/}}
{{- define "carto.validateValues.s3Compatible" -}}
{{- if ne .Values.appConfigValues.storageProvider "s3" -}}
{{-   if or .Values.appConfigValues.s3Endpoint .Values.appConfigValues.s3ExternalUrl .Values.appConfigValues.s3ForcePathStyle -}}
CARTO: S3-compatible values ignored

s3Endpoint, s3ExternalUrl and s3ForcePathStyle only apply when appConfigValues.storageProvider is "s3" (current: {{ .Values.appConfigValues.storageProvider }}). Remove them or set storageProvider=s3.
{{-   end -}}
{{- end -}}
{{- end -}}

{{/*
Validate auth-api (internal authentication) config
*/}}
{{- define "carto.validateValues.authApi" -}}
{{- if .Values.appConfigValues.authApiEnabled -}}
{{- $messages := list -}}
{{- if not (has .Values.authApi.protocol (list "oidc" "saml")) -}}
{{- $messages = append $messages "CARTO: Invalid auth-api protocol\n\nIf appConfigValues.authApiEnabled=true you need to set authApi.protocol to \"oidc\" or \"saml\"" -}}
{{- end -}}
{{- if and (eq .Values.authApi.protocol "oidc") (or (not .Values.authApi.oidc.issuerUrl) (not .Values.authApi.oidc.clientId) (and (not .Values.authApi.oidc.clientSecret) (not .Values.authApi.oidc.existingSecret.name))) -}}
{{- $messages = append $messages "CARTO: Missing auth-api OIDC configuration\n\nIf authApi.protocol=oidc you need to set authApi.oidc.issuerUrl, authApi.oidc.clientId and one of authApi.oidc.clientSecret or authApi.oidc.existingSecret" -}}
{{- end -}}
{{- if and (eq .Values.authApi.protocol "saml") (not .Values.authApi.saml.metadataUrl) (not (trim (default "" .Values.authApi.saml.metadataXml))) -}}
{{- $messages = append $messages "CARTO: Missing auth-api SAML configuration\n\nIf authApi.protocol=saml you need to set one of authApi.saml.metadataUrl or authApi.saml.metadataXml" -}}
{{- end -}}
{{- if not .Values.authApi.allowedOrigins -}}
{{- $messages = append $messages "CARTO: Missing auth-api allowed origins\n\nIf appConfigValues.authApiEnabled=true you need to set authApi.allowedOrigins with the browser origins allowed to call auth-api (e.g. https://<appConfigValues.selfHostedDomain>)" -}}
{{- end -}}
{{- if and (not .Values.authApi.internalServiceToken.value) (not .Values.authApi.internalServiceToken.existingSecret.name) -}}
{{- $messages = append $messages "CARTO: Missing auth-api internal service token\n\nIf appConfigValues.authApiEnabled=true you need to set one of authApi.internalServiceToken.value or authApi.internalServiceToken.existingSecret" -}}
{{- end -}}
{{- if and (not .Values.cartoSecrets.encryptionSecretKey.value) (not .Values.cartoSecrets.encryptionSecretKey.existingSecret.name) -}}
{{- $messages = append $messages "CARTO: Missing encryption secret key for auth-api\n\nIf appConfigValues.authApiEnabled=true you need to set one of cartoSecrets.encryptionSecretKey.value or cartoSecrets.encryptionSecretKey.existingSecret" -}}
{{- end -}}
{{- join "\n" $messages -}}
{{- end -}}
{{- end -}}

{{/*
Compile all warnings into a single message, and call fail.
*/}}
{{- define "carto.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "carto.validateValues.redis" .) -}}
{{- $messages := append $messages (include "carto.validateValues.postgresql" .) -}}
{{- $messages := append $messages (include "carto.validateValues.proxy" .) -}}
{{- $messages := append $messages (include "carto.validateValues.logLevel" .) -}}
{{- $messages := append $messages (include "carto.validateValues.serviceAccount" .) -}}
{{- $messages := append $messages (include "carto.validateValues.s3Compatible" .) -}}
{{- $messages := append $messages (include "carto.validateValues.authApi" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{- define "carto.tlsCerts.duplicatedValueValidator" -}}
  {{- if and (.Values.tlsCerts.existingSecret.name) (not (empty .Values.router.tlsCertificates.certificateValueBase64)) -}}
      {{- fail "You cannot define both tlsCerts.existingSecret.name and router.tlsCertificates.certificateValueBase64" -}}
  {{- end -}}
{{- end -}}
