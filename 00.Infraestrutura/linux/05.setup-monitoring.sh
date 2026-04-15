#!/usr/bin/env bash
# ==============================================================================
# SYNOPSIS
#   Instala o stack de observabilidade (Prometheus, Loki, Tempo, Pyroscope,
#   Alloy e Grafana) no namespace 'monitoring' e abre o port-forward do Grafana.
#
# DESCRIPTION
#   - Cria namespace monitoring.
#   - Adiciona e atualiza os repos Helm necessários.
#   - Instala/atualiza kube-prometheus-stack, Loki, Tempo, Pyroscope e Alloy
#     usando os arquivos de values presentes no mesmo diretório.
#   - Aplica o ConfigMap de datasources do Grafana.
#   - Abre port-forward do Grafana na porta 3000 em background.
#
# NOTES
#   Pré-requisito: cluster k3d 'workshop' em execução, kubectl e helm no PATH.
#   Os arquivos de values (05.01-*.yaml … 05.06-*.yaml) devem estar no mesmo
#   diretório deste script.
# ==============================================================================

set -euo pipefail

# Resolve o diretório deste script para referenciar os arquivos de values
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cores ANSI
CYAN='\033[0;36m'
GREEN='\033[0;32m'
GRAY='\033[0;37m'
RESET='\033[0m'

write_step()    { echo -e "\n${CYAN}==> $1${RESET}"; }
write_success() { echo -e "    ${GREEN}OK: $1${RESET}"; }

# ---------------------------------------------------------------------------
# 1. Namespace
# ---------------------------------------------------------------------------
write_step "Criando namespace monitoring..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f - >/dev/null
write_success "Namespace pronto."

# ---------------------------------------------------------------------------
# 2. Repositórios Helm
# ---------------------------------------------------------------------------
write_step "Adicionando repositórios Helm..."

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update >/dev/null

write_success "Repositórios atualizados."

# ---------------------------------------------------------------------------
# 3. kube-prometheus-stack (Prometheus + Alertmanager + Grafana)
# ---------------------------------------------------------------------------
write_step "Instalando kube-prometheus-stack..."

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values "${SCRIPT_DIR}/05.01-kube-prometheus-stack.yaml" \
  --wait

write_success "kube-prometheus-stack instalado."

# ---------------------------------------------------------------------------
# 4. Loki
# ---------------------------------------------------------------------------
write_step "Instalando Loki..."

helm upgrade --install loki grafana/loki \
  --namespace monitoring \
  --values "${SCRIPT_DIR}/05.02-loki.yaml" \
  --wait

write_success "Loki instalado."

# ---------------------------------------------------------------------------
# 5. Tempo
# ---------------------------------------------------------------------------
write_step "Instalando Tempo (distributed)..."

helm upgrade --install tempo grafana/tempo-distributed \
  --namespace monitoring \
  --values "${SCRIPT_DIR}/05.03-tempo.yaml" \
  --wait

write_success "Tempo instalado."

# ---------------------------------------------------------------------------
# 6. Pyroscope
# ---------------------------------------------------------------------------
write_step "Instalando Pyroscope..."

helm upgrade --install pyroscope grafana/pyroscope \
  --namespace monitoring \
  --values "${SCRIPT_DIR}/05.04-pyroscope.yaml" \
  --wait

write_success "Pyroscope instalado."

# ---------------------------------------------------------------------------
# 7. Alloy
# ---------------------------------------------------------------------------
write_step "Instalando Alloy..."

helm upgrade --install alloy grafana/alloy \
  --namespace monitoring \
  --values "${SCRIPT_DIR}/05.05-alloy.yaml" \
  --wait

write_success "Alloy instalado."

# ---------------------------------------------------------------------------
# 8. Datasources do Grafana
# ---------------------------------------------------------------------------
write_step "Aplicando datasources do Grafana..."

kubectl apply -f "${SCRIPT_DIR}/05.06-grafana-datasource.yaml"
write_success "Datasources aplicados."

# ---------------------------------------------------------------------------
# 9. Port-forward do Grafana em background
# ---------------------------------------------------------------------------
write_step "Iniciando port-forward do Grafana (porta 3000)..."

# Encerra port-forward anterior para a porta 3000, se existir
if [[ -f /tmp/pf-grafana.pid ]]; then
  old_pid=$(cat /tmp/pf-grafana.pid)
  kill "$old_pid" 2>/dev/null || true
  rm -f /tmp/pf-grafana.pid
fi

kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 &
PF_PID=$!
echo "$PF_PID" > /tmp/pf-grafana.pid

echo ""
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN} Stack de monitoramento pronto!${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo ""
echo "Grafana:  http://localhost:3000"
echo "          Usuário padrão: admin"
echo "          Senha padrão : prom-operator  (ou conforme values)"
echo ""
echo -e "    ${GRAY}Port-forward PID: ${PF_PID}${RESET}"
echo -e "    ${GRAY}Para encerrar: kill \$(cat /tmp/pf-grafana.pid)${RESET}"
echo ""
