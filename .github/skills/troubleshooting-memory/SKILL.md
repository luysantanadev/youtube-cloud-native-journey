---
name: troubleshooting-memory
description: 'Records and retrieves known incident solutions for the k8s-monitoring cluster. Use when diagnosing pod restarts, failed installs, operator issues, CNI errors, StatefulSet problems, or any cluster incident. Prevents re-diagnosing known issues and builds a searchable knowledge base. Triggers on: "why is X failing", "pod is restarting", "not starting", "debug this error", "record this fix", "INC", "known issue", "troubleshoot".'
license: MIT
---

# Troubleshooting Memory — Record & Retrieve Incident Solutions

This skill manages the `memory-bank/troubleshooting/` knowledge base: look up known solutions before diagnosing, and record new solutions after fixing.

---

## When to Use This Skill

- User reports a pod restarting, failing to start, or stuck in a bad state
- User asks "why is X failing" or "X is not working"
- User asks to diagnose a cluster error or Helm install failure
- User says "record this fix", "save this solution", or "add to troubleshooting memory"
- User mentions `INC` numbers or references a known issue
- After resolving any incident in the current session

---

## Workflow A — Diagnose (check before investigating)

Use the todo list to show progress to the user.

```
- [ ] Step 1: Read _index.md
- [ ] Step 2: Search for matching record
- [ ] Step 3: Apply known fix OR proceed to investigate
```

### Step 1 — Read the index

```
read_file: memory-bank/troubleshooting/_index.md
```

### Step 2 — Match symptom to existing record

Scan the **Resolved** table in `_index.md` for:
- Component name (mongodb, flannel, traefik, prometheus…)
- Tag keywords from the error message
- Symptom description

If a match is found → **read that INC file** and apply the resolution.

If no match is found → proceed with normal investigation, then use **Workflow B** to record.

### Step 3 — Apply or investigate

**Known issue found:**
> "This matches [INC<NNN>](memory-bank/troubleshooting/INC<NNN>-*.md). Applying the documented fix."

Apply the resolution steps from the INC file. After applying, verify the fix still works and note any differences.

**No match found:**
Proceed with investigation using standard kubectl diagnostics:

```bash
# Events in the affected namespace
kubectl get events -n <namespace> --sort-by='.lastTimestamp' | tail -20

# Pod details
kubectl describe pod -n <namespace> <pod>

# Container logs
kubectl logs -n <namespace> <pod> --tail=50

# Helm releases
helm list --all-namespaces | grep <service>

# Resource status
kubectl get all -n <namespace>
```

After resolving → run **Workflow B**.

---

## Workflow B — Record (after resolving an incident)

Use the todo list to show progress to the user.

```
- [ ] Step 1: Determine next INC number
- [ ] Step 2: Create INC file
- [ ] Step 3: Update _index.md
```

### Step 1 — Determine next INC number

Read `memory-bank/troubleshooting/_index.md` and find the highest existing INC number. Increment by 1, zero-padded to 3 digits.

### Step 2 — Create the INC file

File name: `memory-bank/troubleshooting/INC<NNN>-<kebab-slug>.md`

Slug rules: lowercase, hyphens, component first, then issue type.
Examples: `mongodb-statefulset-orphan`, `flannel-wsl2-restart`, `prometheus-pvc-pending`

Use this exact template:

```markdown
# INC<NNN> — <Short descriptive title>

**Status:** Resolved  
**Component:** <service/namespace>  
**Tags:** `#tag1` `#tag2`  
**Detected:** <YYYY-MM-DD>  
**Resolved:** <YYYY-MM-DD>

---

## Sintoma

<Exact error messages and observable behavior — verbatim kubectl/helm output>

---

## Diagnóstico

<Commands used to identify the root cause>

---

## Causa Raiz

<Clear explanation of WHY the problem occurred>

---

## Resolução

<Step-by-step fix with verification commands>

---

## Prevenção

<What was changed to prevent recurrence, or why it is unavoidable>

---

## Arquivos Modificados

<Links to files changed as part of the fix>
```

### Step 3 — Update _index.md

Add a new row to the **Resolved** table:

```markdown
| [INC<NNN>](INC<NNN>-<slug>.md) | Component | One-line symptom | One-line root cause | YYYY-MM-DD |
```

If the issue is a new **Recurring Pattern**, add it to the "Recurring Patterns" section as well.

---

## Workflow C — Search by keyword

When the user asks "do we have a known fix for X" or "have we seen this before":

1. Read `memory-bank/troubleshooting/_index.md`
2. Search the tags and symptom column for the keyword
3. If found: read that INC file and summarise the fix
4. If not found: report "No known record for X"

---

## Tag Reference

| Tag | Use for |
|-----|---------|
| `#k3d` | k3d cluster lifecycle |
| `#wsl2` | WSL2/Docker Desktop host restarts |
| `#cni` `#flannel` | Network plugin issues |
| `#statefulset` | StatefulSet stuck or not scaling |
| `#operator` | Kubernetes operator missing/misconfigured |
| `#rbac` | ServiceAccount/Role issues |
| `#helm` | Helm release ownership/order problems |
| `#install-order` | Dependencies installed in wrong sequence |
| `#probe` | Liveness/readiness probe failures |
| `#mongodb` `#postgresql` `#redis` `#rabbitmq` | Database services |
| `#monitoring` | Prometheus/Grafana/Loki/Tempo/Pyroscope |
| `#ingress` | Traefik routing |
| `#pvc` | PersistentVolumeClaim |

---

## Gotchas

- **Do not invent root causes.** If you cannot confirm the cause from logs/events, write "Under investigation" in the Causa Raiz field.
- **Include verbatim error strings** in the Sintoma section — future keyword searches depend on them.
- **INC numbers are never reused.** If a record is no longer relevant, mark `Status: Obsolete` but keep the file.
- **Always update `_index.md`** after creating an INC file — an unindexed INC will never be found.
