{{/*
Ingest Job Spec. Reuse in initial job and crobjob
*/}}
{{- define "knowledgebase-slackbot.ingest-job-spec" -}}
spec:
  template:
    spec:
      containers:
      - name: ingest
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        command: ["python", "-m", "knowledge_base_gpt.apps.ingest.ingest"]
        volumeMounts:
        - name: embedding
          mountPath: "/db"
        - name: service-json
          mountPath: /usr/app/
        env:
        - name: PERSIST_DIRECTORY
          value: "/db"
        - name: GOOGLE_DRIVE_FOLDER_ID
          valueFrom:
            secretKeyRef:
              name: {{ include "knowledgebase-slackbot.folder-id-secret" . }}
              key: folder-id
        - name: SERVICE_KEY_FILE
          value: /usr/app/service.json
        securityContext:
          runAsUser: 0
      volumes:
      - name: embedding
        persistentVolumeClaim:
          claimName: {{ include "knowledgebase-slackbot.embedding-pvc" . }}
      - name: service-json
        secret:
          secretName: {{ include "knowledgebase-slackbot.service-json-secret" . }}
      restartPolicy: Never
  backoffLimit: 4
{{- end }}