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
{{- if (include "carto.disconnected.enabled" .) -}}
{{- $messages := list -}}
{{- if not (has .Values.appConfigValues.disconnected.protocol (list "oidc" "saml")) -}}
{{- $messages = append $messages "CARTO: Invalid auth-api protocol\n\nIf appConfigValues.disconnected.enabled=true you need to set appConfigValues.disconnected.protocol to \"oidc\" or \"saml\"" -}}
{{- end -}}
{{- if and (eq .Values.appConfigValues.disconnected.protocol "oidc") (or (not .Values.appConfigValues.disconnected.oidc.issuerUrl) (not .Values.appConfigValues.disconnected.oidc.clientId) (and (not .Values.appSecrets.authApiOidcClientSecret.value) (not .Values.appSecrets.authApiOidcClientSecret.existingSecret.name))) -}}
{{- $messages = append $messages "CARTO: Missing auth-api OIDC configuration\n\nIf appConfigValues.disconnected.protocol=oidc you need to set appConfigValues.disconnected.oidc.issuerUrl, appConfigValues.disconnected.oidc.clientId and one of appSecrets.authApiOidcClientSecret.value or appSecrets.authApiOidcClientSecret.existingSecret" -}}
{{- end -}}
{{- if and (eq .Values.appConfigValues.disconnected.protocol "saml") (not .Values.appConfigValues.disconnected.saml.metadataUrl) (not (trim (default "" .Values.appConfigValues.disconnected.saml.metadataXml))) -}}
{{- $messages = append $messages "CARTO: Missing auth-api SAML configuration\n\nIf appConfigValues.disconnected.protocol=saml you need to set one of appConfigValues.disconnected.saml.metadataUrl or appConfigValues.disconnected.saml.metadataXml" -}}
{{- end -}}
{{- if and (not .Values.cartoSecrets.authApiInternalServiceToken.value) (not .Values.cartoSecrets.authApiInternalServiceToken.existingSecret.name) -}}
{{- $messages = append $messages "CARTO: Missing auth-api internal service token\n\nIf appConfigValues.disconnected.enabled=true you need to set one of cartoSecrets.authApiInternalServiceToken.value or cartoSecrets.authApiInternalServiceToken.existingSecret" -}}
{{- end -}}
{{- if not .Values.appConfigValues.disconnected.spaClient.clientId -}}
{{- $messages = append $messages "CARTO: Missing platform SPA client ID\n\nIf appConfigValues.disconnected.enabled=true you need to set appConfigValues.disconnected.spaClient.clientId" -}}
{{- end -}}
{{- if and (not .Values.cartoSecrets.encryptionSecretKey.value) (not .Values.cartoSecrets.encryptionSecretKey.existingSecret.name) -}}
{{- $messages = append $messages "CARTO: Missing encryption secret key for auth-api\n\nIf appConfigValues.disconnected.enabled=true you need to set one of cartoSecrets.encryptionSecretKey.value or cartoSecrets.encryptionSecretKey.existingSecret" -}}
{{- end -}}
{{- $pgPasswordSet := or .Values.externalPostgresql.authApiPassword (and .Values.externalPostgresql.existingSecret .Values.externalPostgresql.existingSecretAuthApiPasswordKey) -}}
{{- if or (and .Values.externalPostgresql.authApiUser (not $pgPasswordSet)) (and $pgPasswordSet (not .Values.externalPostgresql.authApiUser)) -}}
{{- $messages = append $messages "CARTO: Incomplete auth-api dedicated PostgreSQL credentials\n\nTo give auth-api a dedicated PostgreSQL role set BOTH externalPostgresql.authApiUser and one of externalPostgresql.authApiPassword or externalPostgresql.existingSecretAuthApiPasswordKey. Leave all of them empty to reuse the shared platform user." -}}
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
