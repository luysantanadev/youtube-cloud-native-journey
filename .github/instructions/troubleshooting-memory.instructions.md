---
description: 'Guidelines for recording and reusing troubleshooting knowledge in the k8s-monitoring project. Consult before diagnosing any incident. Record after resolving any incident.'
applyTo: '**'
---

# Troubleshooting Memory

The Troubleshooting Memory is a companion to the Memory Bank that captures **incidents, root causes, and proven fixes** so they are never diagnosed twice.

## Location

```
.github/memory-bank/troubleshooting/
├── _index.md          ← Searchable registry of all incidents
├── INC001-*.md        ← Individual incident records
├── INC002-*.md
└── INCNNN-*.md
```

## MANDATORY: Check Before Diagnosing

Before spending any time investigating a reported error or pod issue, **read `.github/memory-bank/troubleshooting/_index.md`** and search for matching tags or symptom keywords.

If a matching record exists:
1. Apply the documented resolution steps
2. Verify they still apply (cluster version, config may differ)
3. Note any differences in the incident file

If no matching record exists, proceed with investigation and **record the solution afterward**.

## MANDATORY: Record After Resolving

After every resolved incident, create a new `INC<NNN>-<slug>.md` file and update `_index.md`. Use the next available INC number.

## Incident File Format

```markdown
# INC<NNN> — <Short descriptive title>

**Status:** Resolved | Open | Investigating  
**Component:** <service/namespace affected>  
**Tags:** `#tag1` `#tag2` `#tag3`  
**Detected:** YYYY-MM-DD  
**Resolved:** YYYY-MM-DD  (omit if Open/Investigating)

---

## Sintoma

Exact error messages, kubectl output, or observable behavior that signals this issue.
Always include the verbatim error string so future searches can match it.

---

## Diagnóstico

Shell commands used to confirm the root cause.

---

## Causa Raiz

Clear explanation of WHY the problem occurred.

---

## Resolução

Step-by-step commands to fix, with verification.

---

## Prevenção

What was changed in scripts/manifests to prevent recurrence, or why it cannot be prevented.

---

## Arquivos Modificados

Links to files changed as part of the fix.
```

## Tag Conventions

Use consistent tags so `_index.md` searches work reliably:

| Tag | Use for |
|-----|---------|
| `#k3d` | k3d cluster lifecycle issues |
| `#wsl2` | WSL2 or Docker Desktop host restarts |
| `#cni` | Flannel, Calico, or other CNI issues |
| `#flannel` | Flannel-specific |
| `#statefulset` | StatefulSet not scaling or stuck |
| `#operator` | Kubernetes operator missing or misconfigured |
| `#rbac` | ServiceAccount, Role, or ClusterRole issues |
| `#helm` | Helm release ownership or install-order problems |
| `#install-order` | Dependency installed in wrong sequence |
| `#probe` | Liveness/readiness probe failures |
| `#mongodb` | MongoDB Community Operator |
| `#postgresql` | CloudNativePG |
| `#redis` | Redis |
| `#rabbitmq` | RabbitMQ |
| `#monitoring` | Prometheus, Grafana, Loki, Tempo, Pyroscope |
| `#ingress` | Traefik IngressRoute or IngressRouteTCP |
| `#pvc` | PersistentVolumeClaim issues |

## Index Entry Format

Each row in `_index.md` must follow this pattern:

```markdown
| [INC<NNN>](INC<NNN>-<slug>.md) | Component | One-line symptom | One-line root cause | YYYY-MM-DD |
```

## Naming Convention

File names: `INC<NNN>-<kebab-case-slug>.md`
- NNN is zero-padded to 3 digits: `INC001`, `INC002`, ..., `INC010`, `INC100`
- Slug summarises the component and issue: `mongodb-statefulset-orphan`, `flannel-wsl2-restart`
