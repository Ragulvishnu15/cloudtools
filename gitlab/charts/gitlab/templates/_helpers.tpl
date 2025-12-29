{{/* vim: set filetype=mustache: */}}

{{- define "gitlab.extraContainers" -}}
{{ tpl (default "" .Values.extraContainers) . }}
{{- end -}}

{{- define "gitlab.extraInitContainers" -}}
{{ tpl (default "" .Values.extraInitContainers) . }}
{{- end -}}

{{- define "gitlab.extraVolumes" -}}
{{ tpl (default "" .Values.extraVolumes) . }}
{{- end -}}

{{- define "gitlab.extraVolumeMounts" -}}
{{ tpl (default "" .Values.extraVolumeMounts) . }}
{{- end -}}

{{- define "gitlab.extraEnvFrom" -}}
{{- $global := deepCopy (get .root.Values.global "extraEnvFrom" | default (dict)) -}}
{{- $values := deepCopy (get .root.Values "extraEnvFrom" | default (dict)) -}}
{{- $local  := deepCopy (get .local "extraEnvFrom" | default (dict)) -}}
{{- $allExtraEnvFrom := mergeOverwrite $global $values $local -}}
{{- range $key, $value := $allExtraEnvFrom }}
- name: {{ $key }}
  valueFrom:
{{ toYaml $value | nindent 4 }}
{{- end -}}
{{- end -}}

{{- define "gitlab.extraEnv" -}}
{{- $allExtraEnv := merge (default (dict) .Values.extraEnv) .Values.global.extraEnv -}}
{{- range $key, $value := $allExtraEnv }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}
{{- end -}}

{{- define "gitlab.gitaly.includeInternalResources" -}}
{{- if and .Values.global.gitaly.enabled (or (not .Values.global.praefect.enabled) (and .Values.global.praefect.enabled (not .Values.global.praefect.replaceInternalGitaly))) -}}
{{-   true }}
{{- end -}}
{{- end -}}

{{- define "gitlab.affinity" -}}
{{- $affinityOptions := list "hard" "soft" }}
{{- if or
  (has (default .Values.global.antiAffinity "") $affinityOptions)
  (has (default .Values.antiAffinity "") $affinityOptions)
  (has (default .Values.global.nodeAffinity "") $affinityOptions)
  (has (default .Values.nodeAffinity "") $affinityOptions)
}}
affinity:
  {{- if eq (default .Values.global.antiAffinity .Values.antiAffinity) "hard" }}
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - topologyKey: {{ default .Values.global.affinity.podAntiAffinity.topologyKey .Values.affinity.podAntiAffinity.topologyKey | quote }}
          labelSelector:
            matchLabels:
              {{- if ne .Chart.Name "toolbox" }}
                {{- include "gitlab.selectorLabels" . | nindent 18 }}
              {{- end -}}
              {{- include "gitlab.affinity.selectorLabelsBySubchart" . | nindent 18 }}
  {{- else if eq (default .Values.global.antiAffinity .Values.antiAffinity) "soft" }}
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 1
          podAffinityTerm:
            topologyKey: {{ default .Values.global.affinity.podAntiAffinity.topologyKey .Values.affinity.podAntiAffinity.topologyKey | quote }}
            labelSelector:
              matchLabels:
                {{- if ne .Chart.Name "toolbox" }}
                  {{- include "gitlab.selectorLabels" . | nindent 18 }}
                {{- end -}}
                {{- include "gitlab.affinity.selectorLabelsBySubchart" . | nindent 18 }}
  {{- end -}}
  {{- if eq (default .Values.global.nodeAffinity .Values.nodeAffinity) "hard" }}
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: {{ default .Values.global.affinity.nodeAffinity.key .Values.affinity.nodeAffinity.key | quote }}
                operator: In
                values: {{ default .Values.global.affinity.nodeAffinity.values .Values.affinity.nodeAffinity.values | toYaml | nindent 16 }}
  {{- else if eq (default .Values.global.nodeAffinity .Values.nodeAffinity) "soft" }}
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 1
          preference:
            matchExpressions:
              - key: {{ default .Values.global.affinity.nodeAffinity.key .Values.affinity.nodeAffinity.key | quote }}
                operator: In
                values: {{ default .Values.global.affinity.nodeAffinity.values .Values.affinity.nodeAffinity.values | toYaml | nindent 16 }}
  {{- end -}}
{{- end -}}
{{- end }}

{{- define "gitlab.affinity.selectorLabelsBySubchart" -}}
{{- if eq .Chart.Name "gitaly" }}
{{- if .storage }}
storage: {{ .storage.name }}
{{- end }}
{{- end -}}
{{- if eq .Chart.Name "toolbox" }}
{{- toYaml .Values.antiAffinityLabels.matchLabels }}
release: {{ .Release.Name }}
{{- end }}
{{- end }}

{{- define "gitlab.timeZone.env" -}}
{{- with $.Values.global.time_zone }}
- name: TZ
  value: {{ . | quote }}
{{- end }}
{{- end }}

{{/*
Returns the public GitLab URL.
*/}}
{{- define "gitlab.gitlab.url" -}}
{{- if .Values.global.gitlab.url }}
{{- .Values.global.gitlab.url -}}
{{- else -}}
http://{{ include "gitlab.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}
{{- end }}

{{/*
Returns the full name of the release/chart.
*/}}
{{- define "gitlab.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Standard selector labels.
*/}}
{{- define "gitlab.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gitlab.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Standard chart labels.
*/}}
{{- define "gitlab.standardLabels" -}}
app.kubernetes.io/name: {{ include "gitlab.fullname" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
