apiVersion: v1
kind: ConfigMap
metadata:
  name: inventory-config
  labels:
    {{- include "atlas-workloads.labels" . | nindent 4 }}
data:
  INVENTORY_APP_ENV: {{ .Values.config.inventoryAppEnv | quote }}
  RUN_MIGRATIONS_ON_STARTUP: {{ .Values.config.runMigrationsOnStartup | quote }}
