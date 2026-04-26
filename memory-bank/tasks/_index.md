# Tasks Index

## In Progress

- [TASK003] Deploy MonitoringDotNet ao cluster e validar E2E — Pyroscope nativo corrigido (2026-04-25); pendente: rebuild imagem, re-import dashboard v9 no Grafana, validação E2E (logs, métricas, traces, profiling)

## Completed

- [TASK000] Create progressive-commits skill — Completed
- [TASK001] Establish project context persistence — Memory Bank + session-handoff skill criados
- [TASK006] Fix observabilidade MonitoringDotNet — `.env` criado, queries Loki corrigidas (`detected_level`), `$log_level` corrigida, todos identificadores renomeados para `monitoring-dotnet-mvc`
- [TASK007] Fix Pyroscope .NET native CLR profiler — `ENV` no Dockerfile + ConfigMap no Helm; `SetEnvironmentVariable()` runtime removido; 5 arquivos alterados (2026-04-25)
- [TASK008] Add ArgoCD service — `instalar.ps1`, `instalar.sh`, `values.yaml` criados em `00.Infraestrutura/servicos/argocd/`; namespace `argocd`, modo insecure, hostname `argocd.monitoramento.local` (2026-04-25)
- [TASK009] Fix RabbitMQ install scripts — `instalar.ps1` corrigido (cleanup + rollout wait + ingressClassName); `instalar.sh` reescrito com Operator approach; ambos com PVC finalizer cleanup automático; validado HTTP 200 OK (2026-04-25)
- [TASK010] Vault standalone mode — migrado de `dev` para `standalone+PVC`; scripts corrigidos (webhook delete + Secret-based init/unseal); vault-0 1/1 Running, PVC Bound, Initialized=true, Sealed=false (2026-04-25)

## Pending

- [TASK002] Validate all Linux scripts 01-09 end-to-end — Not started
- [TASK004] Validate full observability signal flow (4 signals) — Parcialmente bloqueado por TASK003
- [TASK005] Add missing Linux install scripts for services — Not started

## Abandoned

_(none)_
