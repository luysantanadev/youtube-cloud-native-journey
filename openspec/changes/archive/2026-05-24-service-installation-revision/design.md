## Context

The service installers under `00.Infraestrutura/servicos/` mix Helm-based installs, raw manifests, HTTP ingresses, and TCP passthrough routes. The current cluster already exposes Traefik through an `IngressClass` named `traefik` and a `LoadBalancer` service with the local debug ports published, so the installers must match that model instead of assuming older routing behavior.

## Goals / Non-Goals

**Goals:**
- Keep Linux installers aligned with the current Traefik ingress controller and exposed ports.
- Make service installs safely rerunnable after cluster recreation.
- Keep external debug access working for HTTP and TCP services.

**Non-Goals:**
- Rewriting the application workloads themselves.
- Replacing Traefik or the k3d-based debug platform.
- Updating Windows PowerShell installers unless a parity gap is found.

## Decisions

1. **Keep Linux as the primary path and avoid WSL variants unless a concrete difference appears later.**  
   Rationale: the installers already work with the current access model, so extra `.wsl.sh` files would add duplication without solving a real problem.  
   Alternatives considered: duplicating every script for WSL, or merging WSL detection into one file. Both would add maintenance cost without benefit right now.

2. **Standardize ingress behavior on Traefik `ingressClassName: traefik` and named entrypoints.**  
   Rationale: the cluster already has Traefik configured and serving the debug ports; services should declare their ingress intent explicitly rather than relying on defaults.  
   Alternatives considered: switching some services to NodePort or port-forwarding. That would diverge from the existing local platform and make access inconsistent.

3. **Keep TCP services on `IngressRouteTCP` and HTTP services on `Ingress`.**  
   Rationale: database and broker services already model direct TCP entrypoints, while UIs and APIs use HTTP routing.  
   Alternatives considered: exposing everything through HTTP or mixing protocols through the same ingress kind. That would not match service semantics and can break clients.

4. **Use idempotent install operations (`helm upgrade --install`, `kubectl apply`).**  
   Rationale: the cluster is recreated frequently during debug, so installers must converge cleanly without manual cleanup.  
   Alternatives considered: uninstall/reinstall flows. Those are more destructive and can introduce unnecessary downtime.

## Risks / Trade-offs

- Misaligned service names/ports across charts → Mitigation: validate the generated Service/Ingress names against the rendered chart values and the current cluster exposure.
- Divergence between Linux and WSL installers → Mitigation: keep shared behavior identical and isolate only host/runtime differences.
- A service may still fail if the upstream chart changes defaults → Mitigation: prefer current upstream values and revalidate on rerun.

## Migration Plan

1. Update the affected Linux installers and manifests to use the current Traefik ingress model.
2. Add `.wsl.sh` counterparts only if a concrete WSL-only difference appears later.
3. Re-run the install scripts against a recreated cluster and verify each service responds on its expected host/port.
4. Keep the previous scripts available until the revised installers are validated.

Rollback: restore the previous script/manifests from git if a service regresses, then re-run only the affected installer.

## Open Questions

None at this time.
