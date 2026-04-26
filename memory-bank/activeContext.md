# Active Context — k8s-monitoring

> **Update this file at the START and END of every session.**
> It is the first file read to resume work. Keep it focused on the present.

## Current Focus

Vault instalado e validado ✅ (standalone + PVC + auto-init/unseal). Próximo: Instalar ArgoCD + rebuild/deploy MonitoringDotNet com validação E2E dos 4 sinais.

## Recent Changes

- **2026-04-25** *(esta sessão)*: Vault — migrado de `dev` (in-memory) para `standalone` com `storage "file"` + PVC 1Gi; `instalar.ps1` e `instalar.sh` corrigidos (delete webhook `vault-agent-injector-cfg` antes do helm + lógica init/unseal via Secret-existence); Vault 1/1 Running, Initialized=true, Sealed=false, PVC Bound, Secret `vault-unseal-keys` criado.
- **2026-04-25**: RabbitMQ — `instalar.ps1` corrigido (Step 0 cleanup + loop wait StatefulSet + Ingress `ingressClassName: traefik`); `instalar.sh` reescrito do zero com approach Operator; validado HTTP 200 em `http://rabbitmq.monitoramento.local`.
- **2026-04-25**: ArgoCD scripts completados — `instalar.sh` criado, `instalar.ps1` preenchido, `values.yaml` criado. Paridade total. Scripts **não executados** ainda.

## Next Steps

- [ ] **Instalar ArgoCD**: `.\servicos\02.argocd\instalar.ps1` (Windows); confirmar `kubectl get pods -n argocd` todos `Running`
- [ ] **Rebuild e push da imagem MonitoringDotNet**: `docker build`, tag `0.1.0`, push para `monitoramento-registry.localhost:5001/dotnet/mvc`
- [ ] **Re-importar dashboard v9** no Grafana (`grafana.monitoramento.local` → Import → `monitoring-dotnet-mvc.json`)
- [ ] **Validar E2E completo**: logs `detected_level`, métricas RED, traces panel 80, profiling Pyroscope
- [ ] **Revisar scripts restantes**: Keycloak — executar e validar

## Active Decisions

- CLR profiler lê env vars antes do código gerenciado — configuração Pyroscope DEVE ser via `ENV` no Dockerfile ou ConfigMap, nunca via `Environment.SetEnvironmentVariable()` em runtime
- ArgoCD usa modo `--insecure` porque Traefik faz HTTP termination — não usar TLS interno
- Panel `type:"table"` + `queryType:"traceql"` + `tableType:"traces"` é o formato correto para Grafana 12.4.3
- UIDs de datasource hardcoded: `prometheus`, `loki`, `tempo`, `pyroscope`
- RabbitMQ usa Cluster Operator oficial (não Bitnami Helm) — namespace `rabbitmq`, credenciais `user/Workshop123rabbit`
- Cleanup de namespace com PVC: sempre remover finalizer `kubernetes.io/pvc-protection` antes de `kubectl delete namespace`

## Blockers / Open Questions

- [ ] ArgoCD — scripts criados mas não executados; pods ainda não verificados
- [ ] Imagem MonitoringDotNet ainda não rebuilt após correção do Pyroscope
- [ ] Dashboard v9 ainda não re-importado no Grafana
