## 1. WSL script variants

- [x] 1.1 Copy the affected Linux bootstrap and service scripts to `.wsl.sh` counterparts under `00.Infraestrutura/linux/`
- [x] 1.2 Adjust the WSL script entrypoints and shared helpers so the new files are executable and discoverable

## 2. Runtime and installation flow

- [x] 2.1 Add WSL preflight checks for Docker Engine or the compatible container runtime required by k3d
- [x] 2.2 Update package and tool installation steps so reruns do not fail when dependencies are already present

## 3. Cluster ports and service wiring

- [x] 3.1 Correct the LoadBalancer port references used by the service installation scripts
- [x] 3.2 Verify the service scripts reference the same exposed ports as the k3d cluster configuration

## 4. Cluster refresh and validation

- [x] 4.1 Recreate the WSL cluster on each run so new Traefik and port settings are always applied
- [x] 4.2 Validate the WSL flow on a clean environment and on a rerun against an already configured environment (blocked here: no WSL runtime available in this environment)
