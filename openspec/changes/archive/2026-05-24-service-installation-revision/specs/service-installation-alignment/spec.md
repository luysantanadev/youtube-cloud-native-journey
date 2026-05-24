## ADDED Requirements

### Requirement: Service installers must target the current Traefik ingress model
Service installation scripts MUST create ingress resources that use the `traefik` ingress class and the correct HTTP or TCP entrypoints exposed by the current k3d cluster.

#### Scenario: HTTP services are reachable through Traefik
- **WHEN** a service installer applies an HTTP ingress
- **THEN** the ingress MUST reference `ingressClassName: traefik` and route to the service port exposed by the chart or manifest

#### Scenario: TCP services are reachable through Traefik
- **WHEN** a service installer applies a TCP route
- **THEN** the route MUST target the named Traefik entrypoint that matches the exposed host port for that protocol

### Requirement: Service installers must be safe to rerun
Service installation scripts MUST be idempotent so that rerunning them does not duplicate resources or require manual cleanup before reinstalling a service.

#### Scenario: Re-running an installer does not duplicate resources
- **WHEN** an installer is executed again for the same service
- **THEN** it MUST reuse or update the existing Kubernetes resources instead of creating duplicates

### Requirement: Service manifests must align with current externally exposed ports
Service manifests and chart values MUST align with the current cluster-exposed ports used for local debug access.

#### Scenario: External ports match the service contract
- **WHEN** a service exposes HTTP or TCP access for local development
- **THEN** its manifest or values MUST use the port and service names expected by the current cluster exposure model
