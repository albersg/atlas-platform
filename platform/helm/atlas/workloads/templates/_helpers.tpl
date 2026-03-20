{{- define "atlas-workloads.labels" -}}
app.kubernetes.io/managed-by: Helm
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | quote }}
{{- end -}}

{{- define "atlas-workloads.image" -}}
{{- printf "%s:%s" .repository .tag -}}
{{- end -}}
