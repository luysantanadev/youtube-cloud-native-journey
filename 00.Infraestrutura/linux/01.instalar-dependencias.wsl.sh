#!/usr/bin/env bash
# ==============================================================================
# SYNOPSIS
#   Instala ou atualiza as ferramentas necessárias para Kubernetes local no WSL.
#
# DESCRIPTION
#   - Docker Engine/Docker Desktop → precisa estar disponível no host WSL.
#   - k3d, kubectl e Helm → instalam via curl/apt se ausentes.
#   - Ferramentas já instaladas → prossegue sem alteração.
#
# USAGE
#   sudo ./01.install-dependencies.wsl.sh   # Docker runtime já ativo no host + k3d, kubectl e Helm
#
# NOTES
#   Execute com sudo se o ambiente exigir instalação em /usr/local/bin.
#   Este script não instala Docker dentro do WSL; apenas valida o runtime.
# ==============================================================================

set -euo pipefail

REQUESTED_DOCKER_MODE="runtime"
for arg in "$@"; do
  case "$arg" in
    --install-docker-desktop) REQUESTED_DOCKER_MODE="desktop" ;;
    --no-docker)              REQUESTED_DOCKER_MODE="runtime" ;;
  esac
done

# Cores ANSI
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/wsl-common.sh"

write_step()    { echo -e "\n${CYAN}==> $1${RESET}"; }
write_success() { echo -e "    ${GREEN}OK: $1${RESET}"; }
write_warn()    { echo -e "    ${YELLOW}AVISO: $1${RESET}"; }
write_fail()    { echo -e "\n    ${RED}ERRO: $1${RESET}"; exit 1; }

# ---------------------------------------------------------------------------
# Docker Runtime — requerido no host WSL
# ---------------------------------------------------------------------------
install_docker() {
  write_step "Docker Runtime"

  if ! is_wsl; then
    write_warn "Ambiente WSL não detectado. O fluxo continua, mas este script foi pensado para WSL."
  fi

  if command_exists docker && docker info &>/dev/null; then
    write_success "Docker disponível ($(docker --version 2>&1 | head -1)). Pulando."
    return
  fi

  write_fail "Docker não está pronto no host WSL. Inicie o Docker Engine/Docker Desktop antes de rodar o bootstrap."
}

# ---------------------------------------------------------------------------
# Docker Desktop — não instala nada no WSL; apenas valida o runtime
# ---------------------------------------------------------------------------
install_docker_desktop() {
  write_warn "Docker Desktop não é instalado por este fluxo WSL; validando o runtime do host."
  install_docker
}

# ---------------------------------------------------------------------------
# k3d — instala via script oficial (https://k3d.io)
# ---------------------------------------------------------------------------
install_k3d() {
  write_step "k3d"

  if command_exists k3d; then
    write_success "k3d já instalado ($(k3d --version 2>&1 | head -1)). Pulando."
    return
  fi

  write_step "Instalando k3d..."
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
  write_success "k3d instalado."
}

# ---------------------------------------------------------------------------
# kubectl — instala via binário oficial do Kubernetes
# ---------------------------------------------------------------------------
install_kubectl() {
  write_step "kubectl"

  if command_exists kubectl; then
    write_success "kubectl já instalado ($(kubectl version --client 2>&1 | head -1)). Pulando."
    return
  fi

  write_step "Instalando kubectl..."
  local ARCH
  ARCH=$(uname -m)
  [[ "$ARCH" == "x86_64" ]] && ARCH="amd64"
  [[ "$ARCH" == "aarch64" ]] && ARCH="arm64"

  local KUBE_VERSION
  KUBE_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)

  curl -fsSLo /usr/local/bin/kubectl \
    "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kubectl"
  chmod +x /usr/local/bin/kubectl
  write_success "kubectl ${KUBE_VERSION} instalado."
}

# ---------------------------------------------------------------------------
# Helm — instala via script oficial (https://helm.sh)
# ---------------------------------------------------------------------------
install_helm() {
  write_step "Helm"

  if command_exists helm; then
    write_success "Helm já instalado ($(helm version --short 2>&1 | head -1)). Pulando."
    return
  fi

  write_step "Instalando Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash
  write_success "Helm instalado."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
write_step "Verificando pré-requisitos (curl)..."
if ! command_exists curl; then
  write_fail "curl não encontrado. Instale com: sudo apt-get install -y curl"
fi
write_success "curl disponível."

if [[ "$REQUESTED_DOCKER_MODE" == "desktop" ]]; then
  write_warn "O parâmetro --install-docker-desktop é aceito por compatibilidade, mas não instala Docker dentro do WSL."
  install_docker_desktop
else
  install_docker
fi

install_k3d
install_kubectl
install_helm

echo ""
echo -e "${GREEN}============================================================${RESET}"
echo -e "${GREEN}  Ferramentas instaladas/atualizadas com sucesso!${RESET}"
echo -e "${GREEN}============================================================${RESET}"
echo ""
echo -e "${YELLOW}PRÓXIMOS PASSOS:${RESET}"
echo -e "${YELLOW}  1. Recarregue o terminal: source ~/.bashrc${RESET}"
echo -e "${YELLOW}  2. Garanta que o Docker Engine do host esteja ativo e acessível no WSL${RESET}"
echo -e "${YELLOW}  3. Execute: ./02.verificar-instalacoes.wsl.sh${RESET}"
echo ""
