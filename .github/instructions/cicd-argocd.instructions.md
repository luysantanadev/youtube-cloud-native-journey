---
description: 'Conventions for GitHub Actions CI/CD pipelines and ArgoCD GitOps sync in the k8s-monitoring project. Apply when creating workflows, ArgoCD Application manifests, or deployment automation.'
applyTo: '.github/workflows/**,argocd/**,gitops/**'
---

# CI/CD & ArgoCD Conventions

## CI/CD Architecture

```
Developer push
    └── GitHub Actions (build + test + push image)
            └── updates image tag in Helm values
                    └── ArgoCD detects drift → syncs to k3d cluster
```

## GitHub Actions Workflows

### Workflow file location
All workflows live in `.github/workflows/`. Name files descriptively: `build-push-<service>.yml`, `deploy-<env>.yml`.

### Required jobs for a container build pipeline

```yaml
jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write          # for GHCR or registry push
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Security rules
- Pin all actions to a full commit SHA (not just a tag): `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683`
- Use `GITHUB_TOKEN` for registry auth — never store long-lived credentials as secrets when OIDC is available.
- Set `permissions` block explicitly on every job; default to `contents: read`.
- Scan images with a vulnerability scanner (Trivy) before push:
  ```yaml
  - uses: aquasecurity/trivy-action@master
    with:
      image-ref: ${{ env.IMAGE }}
      exit-code: '1'
      severity: 'CRITICAL,HIGH'
  ```

### Updating the Helm chart image tag (GitOps trigger)
After a successful push, update `05.helm-chart/helm/values.yaml` with the new tag and commit back. ArgoCD watches this file.

```yaml
- name: Update Helm values image tag
  run: |
    sed -i "s|tag:.*|tag: \"${{ github.sha }}\"|" 05.helm-chart/helm/values.yaml
    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git add 05.helm-chart/helm/values.yaml
    git commit -m "chore: bump nuxt-workshop image to ${{ github.sha }}"
    git push
```

---

## ArgoCD Conventions

### Installation (in-cluster)

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Access UI: `kubectl port-forward svc/argocd-server -n argocd 8080:443`

### Application manifest pattern

Store ArgoCD `Application` manifests in `argocd/` at the repository root.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nuxt-workshop
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/<org>/k8s-monitoring
    targetRevision: HEAD
    path: 05.helm-chart/helm
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Sync strategy rules
- Always enable `selfHeal: true` — reverts manual `kubectl` changes.
- Enable `prune: true` — removes resources deleted from Git.
- Use `syncOptions: [CreateNamespace=true]` so ArgoCD creates namespaces automatically.
- For monitoring components, set `syncPolicy: {}` (manual sync) until the stack is stable, then enable automated sync.

### Secrets with ArgoCD
Never commit plaintext secrets to Git. Use one of:
- **Sealed Secrets** (`kubeseal`) — encrypt with cluster public key, safe to commit.
- **External Secrets Operator** — pull from a secret manager at sync time.

The `secret.yaml` template in the Helm chart uses `base64` encoded values in `values.yaml` — replace this with one of the above approaches before going to production.

---

## Local Registry vs CI Registry

| Environment | Registry | How to push |
|-------------|----------|-------------|
| Local k3d | `workshop-registry.localhost:5001` | `docker push workshop-registry.localhost:5001/<img>:<tag>` |
| CI/CD | GitHub Container Registry (`ghcr.io`) or Docker Hub | GitHub Actions `docker/build-push-action` |

ArgoCD running inside k3d can pull from `ghcr.io` if the cluster has an `imagePullSecret`. For local development, continue using the k3d registry.
