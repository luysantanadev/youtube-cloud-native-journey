#!/usr/bin/env bash
# ==============================================================================
# SYNOPSIS
#   Cria o cluster k3d 'workshop' com Traefik e CloudNativePG para o
#   laboratório local de Kubernetes.
#
# DESCRIPTION
#   - Remove cluster anterior 'workshop' se existir.
#   - Cria cluster k3d multi-node com loadbalancer nas portas 80/443.
#   - Cria o registry local junto com o cluster (--registry-create), conforme
#     o padrão da documentação k3d. O k3d configura automaticamente o
#     registries.yaml em todos os nós — nenhum passo manual necessário.
#   - Instala Traefik (ingress) e CloudNativePG operator via Helm.
#   - Idempotente: pode ser reexecutado a qualquer momento para resetar o ambiente.
#
# NOTES
#   Pré-requisito: Docker em execução, k3d, kubectl e helm no PATH.
#   Execute após 02.verify-installs.sh confirmar tudo verde.
# ==============================================================================

set -euo pipefail

# Cores ANSI
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

write_step()    { echo -e "\n${CYAN}==> $1${RESET}"; }
write_success() { echo -e "    ${GREEN}OK: $1${RESET}"; }
write_warn()    { echo -e "    ${YELLOW}AVISO: $1${RESET}"; }
write_fail()    { echo -e "\n    ${RED}ERRO: $1${RESET}"; exit 1; }

# ---------------------------------------------------------------------------
# 0. Pré-checks
# ---------------------------------------------------------------------------
write_step "Verificando pré-requisitos..."

for tool in docker k3d kubectl helm; do
  if ! command -v "$tool" &>/dev/null; then
    write_fail "$tool não encontrado. Instale antes de continuar."
  fi
done

if ! docker info &>/dev/null; then
  write_fail "Docker não está rodando. Inicie com: sudo systemctl start docker"
fi

write_success "Todos os pré-requisitos encontrados."

# ---------------------------------------------------------------------------
# 1. Limpar cluster anterior (se existir)
# ---------------------------------------------------------------------------
write_step "Verificando cluster existente..."

if k3d cluster list 2>/dev/null | grep -q "^workshop"; then
  echo -e "    ${YELLOW}Cluster 'workshop' encontrado. Deletando...${RESET}"
  k3d cluster delete workshop || write_fail "Falha ao deletar o cluster anterior."
fi

# ---------------------------------------------------------------------------
# 2. Criar cluster
# ---------------------------------------------------------------------------
write_step "Criando cluster k3d 'workshop'..."

k3d cluster create workshop \
  --port "80:80@loadbalancer" \
  --port "443:443@loadbalancer" \
  --agents 2 \
  --k3s-arg "--disable=traefik@server:0" \
  --registry-create workshop-registry.localhost:0.0.0.0:5001 \
  --kubeconfig-update-default \
  --kubeconfig-switch-context \
  --wait

write_success "Cluster criado."

# ---------------------------------------------------------------------------
# 3. Corrigir kubeconfig
# ---------------------------------------------------------------------------
write_step "Corrigindo endpoint do kubeconfig..."

current_server=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
api_port=$(echo "$current_server" | grep -oP ':\K\d+$') || \
  write_fail "Não foi possível extrair a porta do API server. Server: $current_server"

new_server="https://127.0.0.1:${api_port}"
kubectl config set-cluster k3d-workshop --server="$new_server" || \
  write_fail "Falha ao corrigir o kubeconfig."

write_success "Kubeconfig corrigido: $new_server"

# ---------------------------------------------------------------------------
# 4. Aguardar nodes ficarem prontos
# ---------------------------------------------------------------------------
write_step "Aguardando nodes ficarem prontos (timeout: 90s)..."

kubectl wait --for=condition=Ready nodes --all --timeout=90s || \
  write_fail "Nodes não ficaram prontos a tempo."

write_success "Todos os nodes prontos."

# ---------------------------------------------------------------------------
# 5. Instalar Traefik via Helm
# ---------------------------------------------------------------------------
write_step "Adicionando repo do Traefik..."

helm repo add traefik https://traefik.github.io/charts >/dev/null
helm repo update >/dev/null

write_step "Instalando Traefik..."

helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --set deployment.replicas=1 \
  --set ports.web.hostPort=80 \
  --set ports.websecure.hostPort=443 \
  --set providers.kubernetesCRD.enabled=true \
  --set providers.kubernetesCRD.allowCrossNamespace=true \
  --set providers.kubernetesIngress.enabled=true \
  --set service.type=ClusterIP \
  --wait \
  --timeout 120s

write_success "Traefik instalado."

# ---------------------------------------------------------------------------
# 6. Instalar CloudNativePG operator
# ---------------------------------------------------------------------------
write_step "Adicionando repo do CloudNativePG..."

helm repo add cnpg https://cloudnative-pg.github.io/charts >/dev/null
helm repo update >/dev/null

write_step "Instalando CloudNativePG operator..."

helm upgrade --install cnpg cnpg/cloudnative-pg \
  --namespace cnpg-system \
  --create-namespace \
  --wait \
  --timeout 120s

write_success "CloudNativePG operator instalado."

# ---------------------------------------------------------------------------
# 7. Verificação final do cluster
# ---------------------------------------------------------------------------
write_step "Verificando cluster..."

kubectl get nodes
echo ""
kubectl get pods -n traefik
echo ""
kubectl get pods -n cnpg-system

# ---------------------------------------------------------------------------
# 8. Resumo final
# ---------------------------------------------------------------------------
node_count=$(kubectl get nodes --no-headers | wc -l)

echo ""
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN} Cluster pronto para o workshop!${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo ""
echo "Nodes:         ${node_count} node(s) prontos"
echo "API Server:    ${new_server}"
echo "Traefik:       http://localhost  (porta 80)"
echo "               https://localhost (porta 443)"
echo "CloudNativePG: instalado em cnpg-system"
echo ""
echo "Registry local:"
echo "  Push do host     : localhost:5001"
echo "  Dentro dos pods  : k3d-workshop-registry.localhost:5001"
echo "  Sem autenticação. Sem alteração no daemon.json."
echo ""
echo "Próximo passo:"
echo "  kubectl apply -f scripts/teste.yaml"
echo ""
echo "Para resetar o cluster a qualquer momento:"
echo "  ./03.setup-k3d-multi-node.sh"
echo ""
