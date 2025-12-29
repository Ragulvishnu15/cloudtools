{{- define "elastic-stack.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "efk-stack.labels" -}}
app.kubernetes.io/name: {{ include "efk-stack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "efk-stack.name" -}}
efk
{{- end }}


