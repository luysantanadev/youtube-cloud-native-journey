## Why

The current `00.Infraestrutura/linux/` scripts assume a dedicated Linux machine and fail or behave inconsistently when run from WSL. This blocks a common local workflow and makes the environment bootstrap harder to repeat safely.

## What Changes

- Add WSL-friendly copies of the Linux scripts using the `.wsl.sh` suffix.
- Adjust installation steps to work in WSL, including Docker Engine usage when appropriate.
- Correct cluster LoadBalancer port references for services installed through these scripts.
- Make the scripts idempotent so reruns do not duplicate state or fail on already-configured resources.

## Capabilities

### New Capabilities
- `wsl-linux-bootstrap`: WSL-compatible Linux bootstrap scripts for k3d, Docker Engine, cluster setup, and service installation.

### Modified Capabilities
- None

## Impact

Affected scripts in `00.Infraestrutura/linux/`, cluster bootstrap behavior, Docker runtime assumptions, and port mappings used by the local k3d environment.

## Non-goals

- Rewriting the Windows scripts.
- Changing application behavior inside the cluster beyond what is needed to fix local bootstrap and service access.
