{{- define "java-app.fullname" -}}
{{- if .Values.nameOverride -}}
{{- printf "%s" .Values.nameOverride -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "java-app.labels" -}}
app.kubernetes.io/name: {{ include "java-app.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: Helm
{{- end -}}