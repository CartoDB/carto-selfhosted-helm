{{/*
Throw error if someone both defined the tlsCert secret and added it through plain text
*/}}
{{- define "carto.tlsCerts.duplicatedValueValidator" -}}
  {{- if and (.Values.tlsCerts.existingSecret) (not ( empty .Values.router.tlsCertificates.certificateValueBase64)) -}}
    {{- fail "You cannot define both tlsCerts.existingSecret.name and router.tlsCertificates.certificateValueBase64" -}}
  {{- end -}}
{{- end -}}
