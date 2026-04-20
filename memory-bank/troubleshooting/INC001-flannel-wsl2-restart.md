# INC001 — Flannel CNI perde configuração após reinicialização do WSL2/Docker

**Status:** Resolved  
**Component:** k3d / Flannel CNI  
**Tags:** `#cni` `#k3d` `#wsl2` `#flannel` `#restart`  
**Detected:** 2026-04-20  
**Resolved:** 2026-04-20

---

## Sintoma

Após reiniciar o WSL2 ou o Docker Desktop, **todos os pods do cluster entram em CrashLoop ou são recriados em cascata** com 3–6 restarts por pod no espaço de 5 minutos. Todos se recuperam automaticamente.

Evento nos pods afetados:

```
Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network
for sandbox "...": plugin type="flannel" failed (add): loadFlannelSubnetEnv failed:
open /run/flannel/subnet.env: no such file or directory
```

---

## Diagnóstico

```bash
# Confirmar que os containers k3d subiram há pouco (tempo menor que a idade do cluster)
docker ps --filter "name=k3d-monitoramento" --format "table {{.Names}}\t{{.Status}}"

# Ver o evento nos pods afetados
kubectl describe pod -n <namespace> <pod> | grep -A 5 "FailedCreatePodSandBox"
```

---

## Causa Raiz

O k3d roda cada nó Kubernetes como um container Docker. O Flannel armazena a configuração de subnet em `/run/flannel/subnet.env` **dentro do container**, que é um path efêmero (tmpfs no Linux). Quando o Docker/WSL2 reinicia, esse arquivo desaparece por alguns segundos até o Flannel reinicializar. Durante esse intervalo, nenhum pod consegue criar sandbox de rede, gerando o `FailedCreatePodSandBox`.

O Flannel se recupera automaticamente em ~30–60 segundos e todos os pods voltam ao normal.

---

## Resolução

**Nenhuma ação necessária.** O cluster se recupera automaticamente.

Aguardar 2–3 minutos após o reinicio do Docker/WSL2 antes de interagir com o cluster.

Para monitorar a recuperação:

```bash
watch -n 5 'kubectl get pods -A | grep -v Running | grep -v Completed'
```

---

## Prevenção

Este comportamento é **inerente ao k3d em WSL2**. Não é configurável sem substituir o CNI (ex.: usar Calico em vez de Flannel).

Para ambientes de produção, usar uma instalação nativa de Kubernetes (não k3d).

---

## Referências

- Flannel subnet env: https://github.com/flannel-io/flannel/blob/master/Documentation/configuration.md
- k3d networking: https://k3d.io/v5.8.3/usage/networking/
