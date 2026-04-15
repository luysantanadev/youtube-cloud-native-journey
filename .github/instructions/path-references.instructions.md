---
description: 'When files or directories are renamed, moved, or deleted, update every cross-reference across the project. Apply whenever a file or directory path changes.'
applyTo: '**'
---

# Path Reference Consistency

## Rule

**Whenever a file or directory is renamed, moved, or deleted, you must also update every reference to the old path across the whole project before finishing the task.**

This is mandatory — leaving stale paths causes broken links, failed scripts, and broken `applyTo` globs.

## Where References Live in This Project

Scan all of the following locations for the old path before declaring done:

| Location | What to look for |
|----------|-----------------|
| `AGENTS.md` | Markdown links `[text](path)`, code blocks with paths, prose references |
| `.github/instructions/*.instructions.md` | `applyTo:` frontmatter globs, Markdown links, code examples |
| `.github/workflows/*.yml` | `path:` triggers, `working-directory:`, script invocations |
| `README.md`, `*/README.md` | Markdown links, code blocks |
| `00.scripts/windows/*.ps1` | Hardcoded relative paths passed to `helm`, `kubectl`, `k3d`, etc. |
| `00.scripts/linux/*.sh` | Same as above |
| `argocd/**` (when created) | `spec.source.path` in Application manifests |
| `05.helm-chart/helm/values.yaml` | Any path values |

## Checklist for Path Changes

When you rename or move a path, work through this list in order:

1. **Perform the rename/move** (use `mv` or the editor).
2. **Search for all occurrences** of the old path (both slash styles `foo/bar` and backslash `foo\bar`):
   ```
   grep_search: "<old-path>"  (isRegexp: false, across whole workspace)
   ```
3. **Update each match** — change every occurrence to the new path.
4. **Update `applyTo` globs** in any `.instructions.md` whose glob matched the old location.
5. **Verify no broken Markdown links** remain by checking that the new path actually exists.
6. **Confirm script invocations still resolve** — look for `.\path\to\script.ps1` or `bash path/to/script.sh` references.

## Path Formats

This project uses paths in multiple formats — update all of them:

```
# Markdown link (relative from repo root)
[label](00.scripts/yamls/05.01-kube-prometheus-stack.yaml)

# PowerShell (backslash)
.\00.scripts\windows\05.setup-monitoring.ps1

# Bash / YAML (forward slash)
00.scripts/linux/05.setup-monitoring.sh

# Glob in applyTo frontmatter
applyTo: '00.scripts/yamls/**,00.scripts/windows/05*'
```

## Special Cases

### Renaming a numbered directory (e.g. `04.fundamentos-kubernetes` → `04.kubernetes-basics`)
The numbered prefix appears in:
- `AGENTS.md` layout table
- `kubernetes-manifests.instructions.md` `applyTo` glob and prose
- Any `kubectl apply -f` commands in scripts

### Adding a new top-level directory
Add it to the **Project Layout** section in `AGENTS.md` with a one-line description.

### Deleting a file referenced in `AGENTS.md` or an instruction
Remove the reference entirely — do not leave dead links pointing to non-existent files.
