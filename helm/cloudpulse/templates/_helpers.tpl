{{/*
CloudPulse Helm Chart - Helper Templates
These are reusable snippets called across all template files.
Usage: {{ include "cloudpulse.labels" . }}
*/}}

{{/*
Common labels added to every resource.
- helm.sh/chart: lets you see which chart version deployed this resource
- app.kubernetes.io/managed-by: marks the resource as managed by Helm
*/}}
{{- define "cloudpulse.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels used in matchLabels and Service selectors.
These must stay stable — changing them would break pod selection.
*/}}
{{- define "cloudpulse.selectorLabels" -}}
app: {{ .name }}
{{- end }}

{{/*
Build a full image string from a repository + tag.
Usage: {{ include "cloudpulse.image" .Values.images.frontend }}
Output: 3takle1212/cloudpulse-frontend:latest
*/}}
{{- define "cloudpulse.image" -}}
{{ .repository }}:{{ .tag }}
{{- end }}

{{/*
Standard liveness probe for HTTP services.
Usage: {{ include "cloudpulse.livenessProbe" (dict "path" "/health" "port" 3001) }}
*/}}
{{- define "cloudpulse.livenessProbe" -}}
livenessProbe:
  httpGet:
    path: {{ .path }}
    port: {{ .port }}
  initialDelaySeconds: 10
  periodSeconds: 10
{{- end }}

{{/*
Standard readiness probe for HTTP services.
*/}}
{{- define "cloudpulse.readinessProbe" -}}
readinessProbe:
  httpGet:
    path: {{ .path }}
    port: {{ .port }}
  initialDelaySeconds: 5
  periodSeconds: 5
{{- end }}
