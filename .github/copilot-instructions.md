# GitHub Copilot — Workspace Instructions

Full project context is in [AGENTS.md](../AGENTS.md). Read it before making any changes.

## Behavioral Preferences

- Respond in **Portuguese (Brazil)** when the user writes in Portuguese; English otherwise.
- Prefer editing existing files over creating new ones.
- After any file or directory rename/move, follow the checklist in [path-references.instructions.md](instructions/path-references.instructions.md).
- When generating Kubernetes manifests or Helm templates, apply conventions from [kubernetes-manifests.instructions.md](instructions/kubernetes-manifests.instructions.md).
- When touching monitoring Helm values (`00.scripts/yamls/`), apply [monitoring-stack.instructions.md](instructions/monitoring-stack.instructions.md).
- When generating GitHub Actions workflows or ArgoCD manifests, apply [cicd-argocd.instructions.md](instructions/cicd-argocd.instructions.md).

## Cross-Platform Requirement

Every script change in `00.scripts/windows/` requires an equivalent change in `00.scripts/linux/`, and vice-versa.

## Never Do

- Commit plaintext secrets or hardcoded credentials.
- Use `latest` as an image tag in production manifests.
- Create a Windows-only path in any YAML or Helm file.
- Skip `resources.requests` / `resources.limits` on any container.
