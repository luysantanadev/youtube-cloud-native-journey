# INC002 — MongoDB StatefulSet órfão: `0/1 Ready` em loop por 2 dias

**Status:** Resolved  
**Component:** MongoDB Community Operator  
**Tags:** `#mongodb` `#statefulset` `#operator` `#rbac` `#helm` `#install-order`  
**Detected:** 2026-04-17 (sintoma imediato após instalação inicial)  
**Resolved:** 2026-04-20

---

## Sintoma

O `StatefulSet/mongodb` fica em `0/1 Ready` indefinidamente. O pod `mongodb-0` nunca é criado. O evento no StatefulSet repete a cada poucos segundos:

```
create Pod mongodb-0 in StatefulSet mongodb failed error: pods "mongodb-0" is forbidden:
error looking up service account mongodb/mongodb-database: serviceaccount "mongodb-database" not found
```

O `MongoDBCommunity` fica em phase `Pending`:

```bash
kubectl get mongodbcommunity -n mongodb
# NAME      PHASE     VERSION
# mongodb   Pending
```

---

## Diagnóstico

```bash
# 1. Verificar se o operator está instalado
helm list --all-namespaces | grep -i mongo

# 2. Verificar se a ServiceAccount existe
kubectl get serviceaccounts -n mongodb

# 3. Ver eventos do StatefulSet
kubectl get events -n mongodb --sort-by='.lastTimestamp' | grep FailedCreate

# 4. Ver logs do operator (se estiver rodando)
kubectl logs -n mongodb deployment/mongodb-kubernetes-operator --tail=20
```

---

## Causa Raiz

**Ordem de instalação incorreta**: o `manifest.yaml` (que cria `MongoDBCommunity` e consequentemente o `StatefulSet`) foi aplicado **antes** do Helm release `community-operator` ser instalado.

Sem o operator:
1. A `ServiceAccount mongodb-database` nunca é criada (o operator é responsável por isso)
2. O StatefulSet tenta criar `mongodb-0` a cada poucos segundos e falha
3. O Kubernetes entra em **backoff exponencial** de criação

Quando o operator foi instalado dias depois, a `ServiceAccount` foi criada, mas o StatefulSet já estava em estado interno corrompido (`status.replicas: 0` mesmo com `spec.replicas: 1`) — o controller não tentou mais criar o pod.

---

## Resolução

### Passo 1 — Instalar o operator (se ausente)

```bash
helm list --all-namespaces | grep community-operator || \
  bash 00.Infraestrutura/servicos/mongodb/instalar.sh
```

### Passo 2 — Deletar o StatefulSet órfão

O operator recria automaticamente em ~10 segundos:

```bash
kubectl delete statefulset -n mongodb mongodb
kubectl wait pod/mongodb-0 -n mongodb --for=condition=Ready --timeout=180s
```

### Verificação

```bash
kubectl get mongodbcommunity -n mongodb
# NAME      PHASE     VERSION
# mongodb   Running   7.0.14
```

---

## Prevenção

O script `instalar.sh` foi corrigido para detectar e remover StatefulSets órfãos automaticamente (passo adicionado antes da instalação do operator):

```bash
# Se StatefulSet existe mas o Helm release do operator NÃO existe → órfão
if kubectl get statefulset -n mongodb mongodb &>/dev/null && \
   ! helm list -n mongodb -q 2>/dev/null | grep -q '^community-operator$'; then
    kubectl delete statefulset -n mongodb mongodb
fi
```

**Regra geral**: sempre instalar o operator **antes** de aplicar CRs que dependem dele.

---

## Arquivos Modificados

- [00.Infraestrutura/servicos/mongodb/instalar.sh](../../../00.Infraestrutura/servicos/mongodb/instalar.sh) — adicionado passo 2 de limpeza de StatefulSet órfão
- [00.Infraestrutura/servicos/mongodb/instalar.ps1](../../../00.Infraestrutura/servicos/mongodb/instalar.ps1) — mesmo fix para PowerShell
