# INC006 — Namespace travado em `Terminating` após delete com PVC de StatefulSet

**Status:** Resolved  
**Component:** `rabbitmq` namespace (padrão válido para qualquer namespace com StatefulSet + PVC)  
**Tags:** `#pvc` `#rabbitmq` `#k3d` `#statefulset`  
**Detected:** 2026-04-25  
**Resolved:** 2026-04-25

---

## Sintoma

Após `kubectl delete namespace rabbitmq --timeout=60s`, o namespace fica preso em estado `Terminating` indefinidamente.

```
kubectl get namespace rabbitmq
NAME       STATUS        AGE
rabbitmq   Terminating   2m
```

O pod do StatefulSet também pode ficar `Terminating`:

```
kubectl get pods -n rabbitmq
NAME                 READY   STATUS        RESTARTS
rabbitmq-server-0    1/1     Terminating   0
```

---

## Diagnóstico

```bash
kubectl get pvc -n rabbitmq
# persistence-rabbitmq-server-0   Bound   ...

kubectl get pvc persistence-rabbitmq-server-0 -n rabbitmq -o json | jq '.metadata.finalizers'
# ["kubernetes.io/pvc-protection"]
```

O finalizer `kubernetes.io/pvc-protection` impede que o PVC seja deletado enquanto o namespace está sendo terminado.

---

## Causa Raiz

O controller `pvc-protection` do Kubernetes adiciona o finalizer `kubernetes.io/pvc-protection` em todos os PVCs que estão em uso. Quando o namespace é deletado, o StatefulSet tenta remover o pod, mas o pod fica `Terminating` enquanto aguarda terminação graciosa. O PVC não pode ser removido porque o finalizer bloqueia, e o namespace não termina porque o PVC ainda existe — deadlock.

---

## Resolução

Antes de deletar o namespace, remover o finalizer de todos os PVCs:

```bash
# Listar PVCs no namespace
kubectl get pvc -n rabbitmq --no-headers -o custom-columns=":metadata.name"

# Remover finalizer de cada PVC
kubectl patch pvc persistence-rabbitmq-server-0 -n rabbitmq \
  -p '{"metadata":{"finalizers":[]}}' --type=merge

# Se o pod também estiver stuck, forçar remoção
kubectl delete pod rabbitmq-server-0 -n rabbitmq --force --grace-period=0

# Agora o namespace termina
kubectl delete namespace rabbitmq --wait=true --timeout=60s
```

**Verificação:**
```bash
kubectl get namespace rabbitmq
# Error from server (NotFound): namespaces "rabbitmq" not found
```

---

## Prevenção

Ambos os scripts de instalação (`instalar.ps1` e `instalar.sh`) agora executam automaticamente no Step 0 (cleanup):

1. Listam todos os PVCs no namespace
2. Fazem `patch` com `finalizers: []` em cada um
3. Só então executam `kubectl delete namespace`

Padrão idêntico deve ser aplicado em qualquer outro script que delete um namespace com StatefulSets (MongoDB, PostgreSQL, Redis, etc.).

---

## Arquivos Modificados

- [00.Infraestrutura/servicos/rabbitmq/instalar.ps1](../../00.Infraestrutura/servicos/rabbitmq/instalar.ps1) — Step 0 com loop PVC patch
- [00.Infraestrutura/servicos/rabbitmq/instalar.sh](../../00.Infraestrutura/servicos/rabbitmq/instalar.sh) — Step 0 com loop PVC patch
