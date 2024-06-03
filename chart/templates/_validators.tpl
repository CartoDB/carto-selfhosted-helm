{{- define "carto.tlsCerts.duplicatedValueValidator" -}}
  {{- if and (.Values.router.tlsCertificates.existingSecret.name) (not (empty .Values.router.tlsCertificates.certificateValueBase64)) -}}
      {{- fail "You cannot define both router.tlsCertificates.existingSecret.name and router.tlsCertificates.certificateValueBase64" -}}
  {{- end -}}
{{- end -}}
