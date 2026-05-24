## Context

The Linux bootstrap scripts in `00.Infraestrutura/linux/` were written for dedicated Linux hosts. In WSL, package installation, Docker access, and host networking behave differently, so the same scripts can fail or leave the environment half-configured. This change adds WSL-specific variants and aligns service port references with the cluster exposure model used by k3d.

## Goals / Non-Goals

**Goals:**
- Provide `.wsl.sh` script copies for the Linux bootstrap flow.
- Make WSL execution reliable with a Docker Engine-compatible runtime.
- Keep service installation aligned with the actual LoadBalancer ports exposed by the cluster.
- Make reruns safe and predictable.

**Non-Goals:**
- Changing the Windows PowerShell workflow.
- Reworking application manifests beyond what is needed for local bootstrap connectivity.
- Introducing a new orchestration system or replacing k3d.

## Decisions

1. **Use parallel `.wsl.sh` scripts instead of branching the existing Linux scripts.**  
   Rationale: WSL-specific behavior is isolated from native Linux behavior, keeping the default path stable while making the new workflow explicit.  
   Alternatives considered: a single script with runtime detection, or a wrapper layer. Both would increase branching and make idempotency harder to reason about.

2. **Treat Docker Engine as the WSL runtime dependency.**  
   Rationale: k3d needs a reachable container runtime, and Docker Engine is the most compatible option for local WSL usage in this repository.  
   Alternatives considered: Docker Desktop integration or other runtimes. Those add more host-specific branching and are harder to document consistently.

3. **Centralize port values in the WSL script flow.**  
   Rationale: the exposed LoadBalancer ports are part of the cluster contract, so the scripts should reference the cluster-facing values instead of repeating ad hoc numbers.  
   Alternatives considered: hardcoding ports in each install script or resolving them dynamically from the cluster. Hardcoding is brittle; dynamic discovery adds complexity without enough benefit here.

4. **Recreate the WSL cluster on each run to apply new configuration deterministically.**  
   Rationale: the WSL bootstrap is being used as a debug environment, so the safest way to guarantee new port mappings and Traefik settings is to delete and recreate the cluster.  
   Alternatives considered: in-place patching of the cluster or preserving the existing cluster. Those approaches can leave stale settings behind and make debug sessions inconsistent.

5. **Extract shared helper logic later, while keeping `.wsl.sh` as the WSL entrypoints.**  
   Rationale: the user confirmed the scripts should share logic where possible, but WSL-specific entrypoints still help keep host-dependent behavior explicit.  
   Alternatives considered: fully merging WSL and native Linux scripts into one path, which would reintroduce branching and make WSL-specific fixes harder to isolate.

## Risks / Trade-offs

- Duplicated script surface area → Keep shared logic minimal and make the `.wsl.sh` files thin and explicit.
- Docker runtime misconfiguration in WSL → Fail fast with a clear preflight check before cluster creation.
- Port mapping drift between scripts and cluster config → Keep the exposed ports documented in the scripts and treat mismatches as a bug.
- Cluster recreation causing longer bootstrap time → Accept the extra time in exchange for deterministic configuration and fresh port mappings.

## Migration Plan

1. Add `.wsl.sh` variants next to the current Linux scripts.
2. Update WSL-specific install and bootstrap steps to use Docker Engine checks.
3. Align cluster/service port references in the WSL scripts.
4. Validate reruns on a clean WSL environment and on an already-provisioned environment, confirming the cluster is recreated each time.
5. Keep the native Linux scripts untouched unless a shared bug is found.

Rollback: remove the `.wsl.sh` files and restore the prior Linux script usage if the WSL path proves unstable.

## Open Questions

None at this time.
