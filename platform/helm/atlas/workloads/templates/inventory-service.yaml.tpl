apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.inventoryService.name }}
  annotations:
    argocd.argoproj.io/sync-wave: "2"
  labels:
    {{- include "atlas-workloads.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.inventoryService.replicas }}
  minReadySeconds: {{ .Values.inventoryService.minReadySeconds }}
  progressDeadlineSeconds: {{ .Values.inventoryService.progressDeadlineSeconds }}
  revisionHistoryLimit: {{ .Values.inventoryService.revisionHistoryLimit }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  selector:
    matchLabels:
      app: {{ .Values.inventoryService.name }}
  template:
    metadata:
      labels:
        app: {{ .Values.inventoryService.name }}
    spec:
      automountServiceAccountToken: false
      terminationGracePeriodSeconds: 30
      securityContext:
        seccompProfile:
          type: RuntimeDefault
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app: {{ .Values.inventoryService.name }}
      containers:
        - name: {{ .Values.inventoryService.name }}
          image: {{ include "atlas-workloads.image" .Values.inventoryService.image | quote }}
          imagePullPolicy: {{ .Values.inventoryService.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.inventoryService.containerPort }}
          env:
            - name: INVENTORY_DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: inventory-secrets
                  key: INVENTORY_DATABASE_URL
            - name: INVENTORY_APP_ENV
              valueFrom:
                configMapKeyRef:
                  name: inventory-config
                  key: INVENTORY_APP_ENV
            - name: RUN_MIGRATIONS_ON_STARTUP
              valueFrom:
                configMapKeyRef:
                  name: inventory-config
                  key: RUN_MIGRATIONS_ON_STARTUP
          resources:
            {{- toYaml .Values.inventoryService.resources | nindent 12 }}
          securityContext:
            allowPrivilegeEscalation: false
            runAsNonRoot: true
            runAsUser: 10001
            runAsGroup: 10001
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
          volumeMounts:
            - name: tmp
              mountPath: /tmp
          readinessProbe:
            httpGet:
              path: {{ .Values.inventoryService.probes.readiness.path }}
              port: {{ .Values.inventoryService.containerPort }}
            initialDelaySeconds: {{ .Values.inventoryService.probes.readiness.initialDelaySeconds }}
            periodSeconds: {{ .Values.inventoryService.probes.readiness.periodSeconds }}
            timeoutSeconds: {{ .Values.inventoryService.probes.readiness.timeoutSeconds }}
            failureThreshold: {{ .Values.inventoryService.probes.readiness.failureThreshold }}
          livenessProbe:
            httpGet:
              path: {{ .Values.inventoryService.probes.liveness.path }}
              port: {{ .Values.inventoryService.containerPort }}
            initialDelaySeconds: {{ .Values.inventoryService.probes.liveness.initialDelaySeconds }}
            periodSeconds: {{ .Values.inventoryService.probes.liveness.periodSeconds }}
            timeoutSeconds: {{ .Values.inventoryService.probes.liveness.timeoutSeconds }}
            failureThreshold: {{ .Values.inventoryService.probes.liveness.failureThreshold }}
          startupProbe:
            httpGet:
              path: {{ .Values.inventoryService.probes.startup.path }}
              port: {{ .Values.inventoryService.containerPort }}
            periodSeconds: {{ .Values.inventoryService.probes.startup.periodSeconds }}
            failureThreshold: {{ .Values.inventoryService.probes.startup.failureThreshold }}
      volumes:
        - name: tmp
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.inventoryService.serviceName }}
  labels:
    app: {{ .Values.inventoryService.name }}
    {{- include "atlas-workloads.labels" . | nindent 4 }}
spec:
  selector:
    app: {{ .Values.inventoryService.name }}
  ports:
    - name: http
      port: {{ .Values.inventoryService.servicePort }}
      targetPort: {{ .Values.inventoryService.containerPort }}
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .Values.inventoryService.name }}
  annotations:
    argocd.argoproj.io/sync-wave: "2"
  labels:
    {{- include "atlas-workloads.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .Values.inventoryService.name }}
  minReplicas: {{ .Values.inventoryService.hpa.minReplicas }}
  maxReplicas: {{ .Values.inventoryService.hpa.maxReplicas }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.inventoryService.hpa.averageCpuUtilization }}
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ .Values.inventoryService.pdbName }}
  annotations:
    argocd.argoproj.io/sync-wave: "2"
  labels:
    {{- include "atlas-workloads.labels" . | nindent 4 }}
spec:
  minAvailable: {{ .Values.inventoryService.pdb.minAvailable }}
  selector:
    matchLabels:
      app: {{ .Values.inventoryService.name }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ .Values.inventoryService.name }}
  labels:
    {{- include "atlas-workloads.labels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      app: {{ .Values.inventoryService.name }}
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: {{ .Values.web.name }}
      ports:
        - protocol: TCP
          port: {{ .Values.inventoryService.servicePort }}
