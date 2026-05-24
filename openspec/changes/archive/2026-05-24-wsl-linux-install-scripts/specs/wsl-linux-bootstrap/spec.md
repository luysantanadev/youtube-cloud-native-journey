## ADDED Requirements

### Requirement: WSL-specific Linux script variants
The system SHALL provide WSL-compatible copies of the Linux bootstrap and service-installation scripts using the `.wsl.sh` suffix.

#### Scenario: WSL script variants are available
- **WHEN** a contributor inspects `00.Infraestrutura/linux/`
- **THEN** they SHALL find `.wsl.sh` counterparts for the scripts that need WSL-specific behavior

### Requirement: WSL bootstrap uses a compatible Docker runtime
The system SHALL support WSL execution by using Docker Engine or another compatible container runtime that can be reached from the WSL environment.

#### Scenario: Docker runtime is prepared for k3d
- **WHEN** the WSL bootstrap script prepares the cluster environment
- **THEN** it SHALL verify that the container runtime is available before cluster creation continues

### Requirement: LoadBalancer ports match installed services
The system SHALL use the correct LoadBalancer port mappings for the services installed by the Linux scripts.

#### Scenario: Service ports are exposed correctly
- **WHEN** a service installation script configures cluster access
- **THEN** it SHALL reference the same exposed ports that the k3d cluster publishes for that service

### Requirement: Linux bootstrap scripts are idempotent
The system SHALL allow repeated execution of the WSL Linux scripts without duplicating resources or failing when the target state already exists.

#### Scenario: Existing resources do not break reruns
- **WHEN** a script is executed more than once on the same environment
- **THEN** it SHALL detect existing dependencies, installed packages, and cluster resources and skip only the already-satisfied steps

