## Why

Several service installers in `00.Infraestrutura/servicos/` were written against older ingress assumptions and are no longer responding consistently in the current k3d/Traefik setup. The cluster now exposes Traefik through a `LoadBalancer` Service with `ingressClassName: traefik`, so the service manifests and scripts need to be aligned to that contract across Linux and WSL.

## What Changes

- Align Linux service installers with the current Traefik ingress controller and exposed TCP ports.
- Update service manifests and chart values so HTTP and TCP endpoints resolve through the current ingress/load-balancer model.
- Keep installers idempotent so they can be rerun after cluster recreation without manual cleanup.

## Capabilities

### New Capabilities
- `service-installation-alignment`: service installers and manifests follow the current k3d/Traefik exposure model.

### Modified Capabilities
- None

## Impact

Affected scripts and manifests under `00.Infraestrutura/servicos/`, including Grafana, ArgoCD, Keycloak, MongoDB, PostgreSQL, Redis, RabbitMQ, RavenDB, SonarQube, and Vault. The change also depends on the current k3d Traefik port mappings and ingress class configuration.

## Non-goals

- Changing the application code deployed by these services.
- Revisiting the Windows PowerShell installers unless a parity gap is discovered.
- Replacing Traefik or the current k3d-based local platform.
