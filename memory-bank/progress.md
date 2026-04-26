# Progress — k8s-monitoring

> Track what's done, what works, what's pending, and known issues.
> Update after every significant change.

---

## What Works ✅

### Infrastructure Scripts (Windows)

| Script                         | Status    | Notes                                  |
| ------------------------------ | --------- | -------------------------------------- |
| `01.instalar-dependencias.ps1` | ✅ Exists | Installs k3d, kubectl, helm via winget |
| `02.verificar-instalacoes.ps1` | ✅ Exists | Sanity checks                          |
| `03.criar-cluster-k3d.ps1`     | ✅ Exists | Creates cluster + Traefik              |

### Infrastructure Scripts (Linux)

| Script                           | Status    | Notes                 |
| -------------------------------- | --------- | --------------------- |
| `01.instalar-dependencias.sh`    | ✅ Exists |                       |
| `02.verificar-instalacoes.sh`    | ✅ Exists |                       |
| `03.criar-cluster-k3d.sh`        | ✅ Exists |                       |
| `04.configurar-monitoramento.sh` | ✅ Exists | Full monitoring stack |
| `09.atualizar-hosts.sh`          | ✅ Exists |                       |

### Services (under `00.Infraestrutura/servicos/`)

| Service   | ps1 | sh  | values/manifest   |
| --------- | --- | --- | ----------------- |
| argocd    | ✅  | ✅  | ✅ values.yaml    |
| grafana   | ✅  | —   | ✅ (7 yaml files) |
| keycloak  | ✅  | ✅  | ✅ manifest.yaml  |
| mongodb   | ✅  | ✅  | ✅ manifest.yaml  |
| pgsql     | ✅  | ✅  | ✅ values.yaml    |
| rabbitmq  | ✅  | ✅  | ✅ manifest.yaml (Operator) |
| ravendb   | ✅  | ✅  | ✅ values.yaml    |
| redis     | ✅  | ✅  | ✅ values.yaml    |
| sonarqube | ✅  | ✅  | ✅ values.yaml    |
| vault     | ✅  | ✅  | ✅ values.yaml    |

### Demo Applications

| App                     | Status                         | Notes                                                                                            |
| ----------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------ |
| MonitoringDotNet (.NET) | ✅ Código + observabilidade OK | `01.apps/MonitoringDotNet/` — MVC, `.env` criado, dashboard `monitoring-dotnet-mvc.json` fixado |
| nuxt-workshop           | ✅ Source + Helm chart exists  | `05.helm-chart/`                                                                                 |

### GitHub Copilot Skills

| Skill                        | Status                            |
| ---------------------------- | --------------------------------- |
| `acquire-codebase-knowledge` | ✅ Created                        |
| `progressive-commits`        | ✅ Created this session           |
| `session-handoff`            | ✅ Created this session           |
| All other skills (30+)       | ✅ Inherited from awesome-copilot |

### Tempo — Observability Stack

| Item | Status | Notes |
|------|--------|---------|
| `metricsGenerator` habilitado | ✅ Corrigido (2026-04-21) | `05.03-tempo.yaml` — resolve `empty ring` no Drilldown > Traces |
| `spanMetrics` habilitado | ✅ Corrigido (2026-04-21) | Permite `rate()` e latência por serviço no TraceQL |
| `serviceGraphs` habilitado | ✅ Corrigido (2026-04-21) | Service graph view no Grafana Tempo datasource |
| `remoteWriteUrl` → Prometheus | ✅ Configurado | `kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090/api/v1/write` |

### MonitoringDotNet — Observability Pipeline

| Item | Status | Notes |
|------|--------|-------|
| `WorkshopLokiHttpClient` com `X-Scope-OrgID: workshop` | ✅ Implementado | `ObservabilityExtensions.cs` |
| `.env` criado em `src/Mvc/` | ✅ Criado | Era a causa raiz — `DotNetEnv` não carregava nada sem o arquivo |
| Queries Loki corrigidas no dashboard (`detected_level`) | ✅ Corrigido | `level` stream label não existe; usar `detected_level` |
| Variável `$log_level` corrigida no dashboard | ✅ Corrigido | Valores: `debug,info,warn,error,fatal` (não `information,warning`) |
| Identificadores renomeados para `-mvc` | ✅ Renomeado | `appsettings.json`, `.env`, `.env.example`, dashboard JSON e arquivo |
| Panel 80 (Trace Explorer) corrigido | ✅ Corrigido (2026-04-25) | `type:"table"` + `queryType:"traceql"` + `tableType:"traces"` — Grafana 12.4.3 não renderiza plugin `traces` com frames `traceqlSearch` |
| Dashboard v9 gerado | ✅ Gerado (2026-04-25) | `monitoring-dotnet-mvc.json` v9 salvo em `grafana/dashboards/` |
| Dashboard re-importado no Grafana | ⏳ Pendente | Usuário precisa importar `monitoring-dotnet-mvc.json` (v9) |
| Validação E2E com novo service name | ⏳ Pendente | Reiniciar app, confirmar `app="monitoring-dotnet-mvc"` no Loki |
| Pyroscope native CLR profiler configurado | ✅ Corrigido (2026-04-25) | `Dockerfile` com `CORECLR_*` + `LD_PRELOAD` + `DOTNET_EnableDiagnostics_*`; `PYROSCOPE_*` em `helm/values.yaml` configMap |
| `SetEnvironmentVariable` em runtime removido | ✅ Corrigido (2026-04-25) | `ObservabilityExtensions.cs` — CLR profiler lê vars antes do código gerenciado; config DEVE vir do processo |
| `appsettings.Development.json` e `.env.example` atualizados | ✅ Corrigido (2026-04-25) | Vars `Observability__Pyroscope__*` removidas; usar `PYROSCOPE_*` nativas |
| Imagem rebuilt após correção Pyroscope | ⏳ Pendente | Rebuild + push para registry antes do `helm upgrade` |

---

### Missing Linux Scripts

- `05.configurar-cnpg-criar-base-pgsql.sh` (only `.ps1` exists at top level)
- `06.configurar-redis.sh`
- `07.configurar-mongodb.sh`
- `08.configurar-ravendb.sh`
  > Note: Services now live under `00.Infraestrutura/servicos/` with `instalar.sh` — confirm if numbered scripts are still needed at top level

### Validation / Testing

- [ ] End-to-end test: run all scripts on fresh Linux environment
- [ ] Confirm Grafana dashboards receive data from all 4 signals (metrics, logs, traces, profiling)
- [ ] **Re-importar dashboard `monitoring-dotnet-mvc.json` no Grafana** (uid: `monitoring-dotnet-mvc-v1`)
- [ ] **Validar E2E MonitoringDotNet**: reiniciar app, confirmar logs com `app="monitoring-dotnet-mvc"` no Loki
- [ ] Validate MonitoringDotNet produces OTLP traces visible in Tempo
- [x] ~~Verify RabbitMQ `instalar.sh` work and ServiceMonitor is active~~ ✅ Validado 2026-04-25
- [ ] Verify Keycloak `instalar.sh` work and ServiceMonitor is active

### Documentation

- [ ] README for MonitoringDotNet explaining endpoints and how to observe
- [ ] Architecture diagram in README

---

## Known Issues ⚠️

| Issue                                            | Severity | Notes                                                                      |
| ------------------------------------------------ | -------- | -------------------------------------------------------------------------- |
| `00.Infraestrutura/linux/` missing scripts 05-08 | Medium   | May be in `servicos/*/instalar.sh` instead                                 |
| `rtk` CLI must be installed separately           | Low      | Not in script 01                                                           |
| Dashboard `monitoring-dotnet-mvc` não importado  | Medium   | Importar v9: `grafana.monitoramento.local` → Dashboards → Import → upload JSON |
| Logs históricos em Loki com `app=monitoring-dotnet-api` | Low | Apenas visíveis via Explore; dashboard novo aponta para `-mvc`        |
| ~~Grafana Drilldown > Traces — `empty ring`~~    | ~~Critical~~ | ✅ **Resolvido 2026-04-21** — `metricsGenerator` habilitado no Tempo  |
| ~~RabbitMQ UI inacessível (not found)~~ | ~~High~~ | ✅ **Resolvido 2026-04-25** — `ingressClassName: traefik` ausente; rollout wait prematuro; `instalar.sh` usava Bitnami em vez do Operator |
| Namespace travado em `Terminating` após delete com PVC | Low | Workaround automático nos scripts: patch finalizer `kubernetes.io/pvc-protection` antes de deletar namespace |
| ~~RabbitMQ UI não acessível (not found)~~ | ~~High~~ | ✅ **Resolvido 2026-04-25** — Ingress faltava `ingressClassName: traefik`; rollout wait era prematuro; `instalar.sh` usava Bitnami em vez de Operator |
| Namespace `Terminating` stuck com PVC finalizer | Low | Workaround: `kubectl patch pvc <name> -n <ns> -p '{"metadata":{"finalizers":[]}}' --type=merge`; ambos scripts já incluem esta lógica automaticamente |

---

## Current Status

**Phase**: ArgoCD adicionado; MonitoringDotNet — dashboard v9 finalizado (todos os panels corrigidos), pendente: validação do ArgoCD no cluster, re-import dashboard e validação E2E  
**Overall Progress**: ~80% — Core monitoring stack OK; ArgoCD scripts criados; Tempo metrics-generator + spanMetrics ativos; dashboard `monitoring-dotnet-mvc` v9 com todos os panels corrigidos; aguardando validação ArgoCD + rebuild + re-import + E2E
