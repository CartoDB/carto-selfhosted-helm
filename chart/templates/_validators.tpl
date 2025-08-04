{{/*
Validate external Redis config
*/}}
{{- define "carto.validateValues.redis" -}}
{{- if and (not .Values.internalRedis.enabled) (not .Values.externalRedis.host) (not .Values.cartoConfigValues.onlyRunRouter) -}}
CARTO: Missing Redis(TM)

If internalRedis.enabled=false you need to specify the host of an external Redis(TM) instance setting externalRedis.host
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
Compile all warnings into a single message, and call fail.
*/}}
{{- define "carto.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "carto.validateValues.redis" .) -}}
{{- $messages := append $messages (include "carto.validateValues.postgresql" .) -}}
{{- $messages := append $messages (include "carto.validateValues.proxy" .) -}}
{{- $messages := append $messages (include "carto.validateValues.logLevel" .) -}}
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
