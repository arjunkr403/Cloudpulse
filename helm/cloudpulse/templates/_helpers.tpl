{{- define "cloudpulse.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{- define "cloudpulse.selectorLabels" -}}
app: {{ .name }}
{{- end }}


{{- define "cloudpulse.image" -}}
{{ .repository }}:{{ .tag }}
{{- end }}


{{- define "cloudpulse.livenessProbe" -}}
livenessProbe:
  httpGet:
    path: {{ .path }}
    port: {{ .port }}
  initialDelaySeconds: 10
  periodSeconds: 10
{{- end }}


{{- define "cloudpulse.readinessProbe" -}}
readinessProbe:
  httpGet:
    path: {{ .path }}
    port: {{ .port }}
  initialDelaySeconds: 5
  periodSeconds: 5
{{- end }}
