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

{{- define "carto.tlsCerts.duplicatedValueValidator" -}}
  {{- if and (.Values.tlsCerts.existingSecret.name) (not (empty .Values.router.tlsCertificates.certificateValueBase64)) -}}
      {{- fail "You cannot define both tlsCerts.existingSecret.name and router.tlsCertificates.certificateValueBase64" -}}
  {{- end -}}
{{- end -}}
