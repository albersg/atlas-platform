apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Values.inventoryMigration.name }}
  annotations:
    argocd.argoproj.io/hook: Sync
    argocd.argoproj.io/hook-delete-policy: BeforeHookCreation,HookSucceeded
    argocd.argoproj.io/sync-wave: "1"
  labels:
    {{- include "atlas-workloads.labels" . | nindent 4 }}
spec:
  completions: 1
  parallelism: 1
  backoffLimit: {{ .Values.inventoryMigration.backoffLimit }}
  ttlSecondsAfterFinished: {{ .Values.inventoryMigration.ttlSecondsAfterFinished }}
  activeDeadlineSeconds: {{ .Values.inventoryMigration.activeDeadlineSeconds }}
  template:
    metadata:
      labels:
        app: {{ .Values.inventoryMigration.name }}
    spec:
      automountServiceAccountToken: false
      restartPolicy: OnFailure
      securityContext:
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: {{ .Values.inventoryMigration.name }}
          image: {{ include "atlas-workloads.image" .Values.inventoryMigration.image | quote }}
          imagePullPolicy: {{ .Values.inventoryMigration.image.pullPolicy }}
          command:
            {{- toYaml .Values.inventoryMigration.command | nindent 12 }}
          env:
            - name: INVENTORY_DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: inventory-secrets
                  key: INVENTORY_DATABASE_URL
            - name: DB_WAIT_MAX_ATTEMPTS
              value: {{ .Values.inventoryMigration.dbWaitMaxAttempts | quote }}
            - name: DB_WAIT_SLEEP_SECONDS
              value: {{ .Values.inventoryMigration.dbWaitSleepSeconds | quote }}
          resources:
            {{- toYaml .Values.inventoryMigration.resources | nindent 12 }}
          securityContext:
            allowPrivilegeEscalation: false
            runAsNonRoot: true
            runAsUser: 10001
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
          volumeMounts:
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: tmp
          emptyDir: {}
