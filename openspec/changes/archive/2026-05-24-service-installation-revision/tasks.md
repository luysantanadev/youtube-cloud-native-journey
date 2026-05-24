## 1. Aligning ingress manifests

- [x] 1.1 Update HTTP ingress manifests and chart values to use the current Traefik ingress class and the correct service names/ports
- [x] 1.2 Update TCP ingress routes for database and broker services so they match the current exposed entrypoints

## 2. Hardening reruns

- [x] 2.1 Make the revised installers idempotent so they can be rerun after cluster recreation without manual cleanup
- [x] 2.2 Prefer current upstream chart values and normalize only the ingress settings required by the cluster

## 3. Validation

- [x] 3.1 Reinstall the affected services on the recreated cluster and verify each service responds on its expected host or TCP port
