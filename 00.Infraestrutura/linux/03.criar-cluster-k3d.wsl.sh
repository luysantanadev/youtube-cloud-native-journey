#!/usr/bin/env bash
# ==============================================================================
# SYNOPSIS
#   Recria o cluster k3d 'monitoramento' com Traefik para WSL.
#
# DESCRIPTION
#   - Recria o cluster 'monitoramento' a cada execução para aplicar novas configs.
#   - Cria cluster k3d multi-node com loadbalancer nas portas 80/443 + TCP.
#   - Instala Traefik (ingress + entrypoints TCP) via Helm.
#   - Reexecutável: remove o cluster anterior e sobe uma instância nova.
#
# NOTES
#   Pré-requisito: Docker em execução, k3d, kubectl e helm no PATH.
# ==============================================================================

set -euo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/wsl-common.sh"

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

require_docker_runtime

write_success "Todos os pré-requisitos encontrados."

# ---------------------------------------------------------------------------
# 1. Detectar hardware e memória disponível para reservas do kubelet
# ---------------------------------------------------------------------------
total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
total_gb=$(( total_kb / 1024 / 1024 ))
total_cpus=$(nproc)

if   (( total_gb >= 24 )); then sys_reserved_mem="1024Mi"
elif (( total_gb >= 12 )); then sys_reserved_mem="512Mi"
else                            sys_reserved_mem="256Mi"
fi

write_step "Hardware detectado"
echo "  CPUs detectadas : ${total_cpus}"
echo "  RAM total       : ~${total_gb} GB"
echo "  system-reserved : ${sys_reserved_mem}"

# ---------------------------------------------------------------------------
# 2. Recriar cluster
# ---------------------------------------------------------------------------
write_step "Removendo cluster existente (se houver)..."
if k3d cluster list 2>/dev/null | grep -q "^monitoramento"; then
    k3d cluster delete monitoramento
    write_success "Cluster anterior removido."
else
    write_success "Nenhum cluster anterior encontrado."
fi

write_step "Criando cluster k3d 'monitoramento'..."

port_args=()
for port in 80 443 4317 4318 5432 6379 27017 5672; do
    port_args+=(--port "${port}:${port}@loadbalancer")
done

k3d cluster create monitoramento \
    "${port_args[@]}"              \
    --agents 3                     \
    --k3s-arg "--disable=traefik@server:0" \
    --k3s-arg "--kubelet-arg=system-reserved=cpu=100m,memory=${sys_reserved_mem}@server:0" \
    --k3s-arg "--kubelet-arg=kube-reserved=cpu=100m,memory=128Mi@server:0"              \
    --k3s-arg "--kubelet-arg=eviction-hard=memory.available<300Mi@server:0"             \
    --k3s-arg "--kubelet-arg=system-reserved=cpu=100m,memory=${sys_reserved_mem}@agent:*" \
    --k3s-arg "--kubelet-arg=kube-reserved=cpu=100m,memory=128Mi@agent:*"              \
    --k3s-arg "--kubelet-arg=eviction-hard=memory.available<300Mi@agent:*"             \
    --registry-create monitoramento-registry.localhost:0.0.0.0:5001 \
    --kubeconfig-update-default \
    --kubeconfig-switch-context \
    --wait

write_success "Cluster recriado."

# ---------------------------------------------------------------------------
# 3. Corrigir kubeconfig (127.0.0.1 em vez de 0.0.0.0)
# ---------------------------------------------------------------------------
write_step "Corrigindo endpoint do kubeconfig..."

k3d kubeconfig merge monitoramento >/dev/null

current_server=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
api_port=$(echo "$current_server" | sed 's/.*://') || \
    write_fail "Não foi possível extrair a porta do API server. Server: $current_server"

new_server="https://127.0.0.1:${api_port}"
kubectl config set-cluster k3d-monitoramento --server="$new_server" || \
    write_fail "Falha ao corrigir o kubeconfig."

write_success "Kubeconfig corrigido: $new_server"

# ---------------------------------------------------------------------------
# 5. Aguardar nodes
# ---------------------------------------------------------------------------
write_step "Aguardando nodes ficarem prontos (timeout: 90s)..."

kubectl wait --for=condition=Ready nodes --all --timeout=90s || \
    write_fail "Nodes não ficaram prontos a tempo."

write_success "Todos os nodes prontos."

# ---------------------------------------------------------------------------
# 6. Instalar Traefik via Helm
#    Entrypoints TCP adicionais necessários para IngressRouteTCP dos bancos:
#    otlpgrpc (4317), otlphttp (4318), postgres (5432), redis (6379), mongodb (27017), amqp (5672)
# ---------------------------------------------------------------------------
write_step "Adicionando repositório do Traefik..."

helm repo add traefik https://traefik.github.io/charts 2>/dev/null || true
helm repo update >/dev/null

write_step "Instalando Traefik (pode demorar ~60s)..."

helm upgrade --install traefik traefik/traefik \
    --namespace traefik \
    --create-namespace \
    --set deployment.replicas=1 \
    --set providers.kubernetesCRD.enabled=true \
    --set providers.kubernetesCRD.allowCrossNamespace=true \
    --set providers.kubernetesIngress.enabled=true \
    --set service.type=LoadBalancer \
    --set "ports.otlpgrpc.port=4317" \
    --set "ports.otlpgrpc.expose.default=true" \
    --set "ports.otlpgrpc.exposedPort=4317" \
    --set "ports.otlphttp.port=4318" \
    --set "ports.otlphttp.expose.default=true" \
    --set "ports.otlphttp.exposedPort=4318" \
    --set "ports.postgres.port=5432" \
    --set "ports.postgres.expose.default=true" \
    --set "ports.postgres.exposedPort=5432" \
    --set "ports.redis.port=6379" \
    --set "ports.redis.expose.default=true" \
    --set "ports.redis.exposedPort=6379" \
    --set "ports.mongodb.port=27017" \
    --set "ports.mongodb.expose.default=true" \
    --set "ports.mongodb.exposedPort=27017" \
    --set "ports.amqp.port=5672" \
    --set "ports.amqp.expose.default=true" \
    --set "ports.amqp.exposedPort=5672" \
    --wait \
    --timeout 120s

write_success "Traefik instalado."

# ---------------------------------------------------------------------------
# 7. Verificação final
# ---------------------------------------------------------------------------
write_step "Verificando cluster..."

kubectl get nodes
echo ""
kubectl get pods -n traefik

# ---------------------------------------------------------------------------
# 8. Resumo
# ---------------------------------------------------------------------------
node_count=$(kubectl get nodes --no-headers | wc -l)

echo ""
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN} Cluster pronto para o laboratório!${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo ""
echo "Nodes:        ${node_count} node(s) prontos"
echo "API Server:   ${new_server}"
echo "Traefik:      http://localhost        (porta 80)"
echo "              https://localhost       (porta 443)"
echo "              otlp-grpc              (porta 4317)"
echo "              otlp-http              (porta 4318)"
echo "              postgres               (porta 5432)"
echo "              redis                  (porta 6379)"
echo "              mongodb                (porta 27017)"
echo "              amqp                   (porta 5672)"
echo ""
echo "Reservas por node (kubelet):"
echo "  system-reserved : cpu=100m, memory=${sys_reserved_mem}"
echo "  kube-reserved   : cpu=100m, memory=128Mi"
echo "  eviction-hard   : memory.available < 300Mi"
echo ""
echo "Registry local:"
echo "  Push do host    : localhost:5001"
echo "  Dentro dos pods : monitoramento-registry.localhost:5001"
echo ""
echo "Próximos passos:"
echo "  bash 00.Infraestrutura/servicos/01.grafana/instalar.sh"
echo ""
echo "Para resetar o cluster a qualquer momento:"
echo "  bash 03.criar-cluster-k3d.wsl.sh"
echo ""
