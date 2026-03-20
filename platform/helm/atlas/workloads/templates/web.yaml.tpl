apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.web.name }}
  annotations:
    argocd.argoproj.io/sync-wave: "2"
  labels:
    {{- include "atlas-workloads.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.web.replicas }}
  minReadySeconds: {{ .Values.web.minReadySeconds }}
  progressDeadlineSeconds: {{ .Values.web.progressDeadlineSeconds }}
  revisionHistoryLimit: {{ .Values.web.revisionHistoryLimit }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  selector:
    matchLabels:
      app: {{ .Values.web.name }}
  template:
    metadata:
      labels:
        app: {{ .Values.web.name }}
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
              app: {{ .Values.web.name }}
      containers:
        - name: {{ .Values.web.name }}
          image: {{ include "atlas-workloads.image" .Values.web.image | quote }}
          imagePullPolicy: {{ .Values.web.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.web.containerPort }}
          resources:
            {{- toYaml .Values.web.resources | nindent 12 }}
          securityContext:
            allowPrivilegeEscalation: false
            runAsNonRoot: true
            runAsUser: 101
            runAsGroup: 101
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
          volumeMounts:
            - name: tmp
              mountPath: /tmp
            - name: nginx-cache
              mountPath: /var/cache/nginx
            - name: nginx-run
              mountPath: /var/run
          readinessProbe:
            httpGet:
              path: {{ .Values.web.probes.readiness.path }}
              port: {{ .Values.web.containerPort }}
            initialDelaySeconds: {{ .Values.web.probes.readiness.initialDelaySeconds }}
            periodSeconds: {{ .Values.web.probes.readiness.periodSeconds }}
            timeoutSeconds: {{ .Values.web.probes.readiness.timeoutSeconds }}
          livenessProbe:
            httpGet:
              path: {{ .Values.web.probes.liveness.path }}
              port: {{ .Values.web.containerPort }}
            initialDelaySeconds: {{ .Values.web.probes.liveness.initialDelaySeconds }}
            periodSeconds: {{ .Values.web.probes.liveness.periodSeconds }}
            timeoutSeconds: {{ .Values.web.probes.liveness.timeoutSeconds }}
          startupProbe:
            httpGet:
              path: {{ .Values.web.probes.startup.path }}
              port: {{ .Values.web.containerPort }}
            periodSeconds: {{ .Values.web.probes.startup.periodSeconds }}
            failureThreshold: {{ .Values.web.probes.startup.failureThreshold }}
      volumes:
        - name: tmp
          emptyDir: {}
        - name: nginx-cache
          emptyDir: {}
        - name: nginx-run
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.web.serviceName }}
  labels:
    app: {{ .Values.web.name }}
    {{- include "atlas-workloads.labels" . | nindent 4 }}
spec:
  selector:
    app: {{ .Values.web.name }}
  ports:
    - name: http
      port: {{ .Values.web.servicePort }}
      targetPort: {{ .Values.web.containerPort }}
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .Values.web.name }}
  annotations:
    argocd.argoproj.io/sync-wave: "2"
  labels:
    {{- include "atlas-workloads.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .Values.web.name }}
  minReplicas: {{ .Values.web.hpa.minReplicas }}
  maxReplicas: {{ .Values.web.hpa.maxReplicas }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.web.hpa.averageCpuUtilization }}
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ .Values.web.pdbName }}
  annotations:
    argocd.argoproj.io/sync-wave: "2"
  labels:
    {{- include "atlas-workloads.labels" . | nindent 4 }}
spec:
  minAvailable: {{ .Values.web.pdb.minAvailable }}
  selector:
    matchLabels:
      app: {{ .Values.web.name }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ .Values.web.name }}
  labels:
    {{- include "atlas-workloads.labels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      app: {{ .Values.web.name }}
  policyTypes:
    - Ingress
    - Egress
  ingress: []
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: {{ .Values.inventoryService.name }}
      ports:
        - protocol: TCP
          port: {{ .Values.inventoryService.servicePort }}
