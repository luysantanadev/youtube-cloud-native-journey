---
description: 'Conventions and patterns for the k8s-monitoring observability stack: Prometheus, Loki, Tempo, Pyroscope, Alloy, and Grafana deployed in the monitoring namespace via Helm.'
applyTo: '00.scripts/yamls/**,00.scripts/windows/05*,00.scripts/linux/05*'
---

# Monitoring Stack Conventions

## Stack Overview

All monitoring components live in the `monitoring` namespace. Helm values overrides are stored in [`00.scripts/yamls/`](../../00.scripts/yamls/).

| File | Component | Helm Chart |
|------|-----------|------------|
| `05.01-kube-prometheus-stack.yaml` | Prometheus + Grafana + Node Exporter + kube-state-metrics | `prometheus-community/kube-prometheus-stack` |
| `05.02-loki.yaml` | Log aggregation (SingleBinary mode) | `grafana/loki` |
| `05.03-tempo.yaml` | Distributed tracing | `grafana/tempo-distributed` |
| `05.04-pyroscope.yaml` | Continuous profiling | `grafana/pyroscope` |
| `05.05-alloy.yaml` | OpenTelemetry collector (DaemonSet) | `grafana/alloy` |
| `05.06-grafana-datasource.yaml` | Grafana datasource ConfigMap | kubectl apply |

## Deploying the Stack

Always use the PowerShell/Bash script, never apply values files manually:

```powershell
.\00.scripts\windows\05.setup-monitoring.ps1
```

The script adds required Helm repos, runs `helm upgrade --install --wait` for each component, and applies the datasource ConfigMap at the end.

## Grafana Access

- URL: `http://localhost:3000` (after `kubectl port-forward -n monitoring svc/grafana 3000:80`)
- Default password: `workshop123` (set in `05.01-kube-prometheus-stack.yaml` → `grafana.adminPassword`)
- Pre-configured datasources: Prometheus, Loki, Tempo, Pyroscope

## OpenTelemetry Endpoints (Alloy)

| Protocol | Internal endpoint | External (port-forward) |
|----------|-------------------|------------------------|
| OTLP gRPC | `alloy.monitoring.svc.cluster.local:4317` | `localhost:4317` |
| OTLP HTTP | `alloy.monitoring.svc.cluster.local:4318` | `localhost:4318` |

Applications must use the **internal** endpoint inside the cluster. Use `OTEL_EXPORTER_OTLP_ENDPOINT=http://alloy.monitoring.svc.cluster.local:4318`.

## Instrumenting Applications

Add these environment variables (via ConfigMap) to any app that should emit telemetry:

```yaml
OTEL_SERVICE_NAME: "<service-name>"
OTEL_EXPORTER_OTLP_ENDPOINT: "http://alloy.monitoring.svc.cluster.local:4318"
OTEL_EXPORTER_OTLP_PROTOCOL: "http/protobuf"
NODE_ENV: "production"
```

Add Pyroscope scrape annotations to the Pod:

```yaml
podAnnotations:
  profiles.grafana.com/cpu.scrape: "true"
  profiles.grafana.com/memory.scrape: "true"
```

## Resource Limits (monitoring components)

All monitoring Pods follow this baseline — adjust per component load:

```yaml
resources:
  requests: { cpu: "50m",  memory: "128Mi" }
  limits:   { cpu: "200m", memory: "256Mi" }
```

Prometheus has higher limits: `cpu: 500m / memory: 512Mi`.

## Storage

- All components use **filesystem backend** (no S3/object store) — suitable for local dev only.
- Loki PVC: `2Gi` (TSDB schema v13).
- For production, switch backends to object storage and increase PVC sizes.

## Prometheus Retention

Set to `6h` in `05.01-kube-prometheus-stack.yaml` for local dev. For longer retention, increase `prometheus.prometheusSpec.retention`.

## Adding a New Monitoring Component

1. Create `00.scripts/yamls/05.0N-<component>.yaml` with Helm values.
2. Add the `helm repo add` + `helm upgrade --install --wait` call to **both** `05.setup-monitoring.ps1` and `05.setup-monitoring.sh`.
3. Register the Grafana datasource in `05.06-grafana-datasource.yaml`.
