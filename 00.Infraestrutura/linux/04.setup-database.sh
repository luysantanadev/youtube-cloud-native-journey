#!/usr/bin/env bash
# ==============================================================================
# SYNOPSIS
#   Cria o cluster PostgreSQL via CloudNativePG (Helm) e abre um port-forward
#   resiliente para acesso local.
#
# DESCRIPTION
#   - Verifica o CNPG operator.
#   - Cria namespace, Secret de credenciais e deploy do cluster via Helm.
#   - Testa a conexão via pod interno antes de subir o port-forward permanente.
#   - Port-forward se reconecta automaticamente em caso de queda inesperada.
#
# USAGE
#   ./04.setup-database.sh [OPÇÕES]
#
# OPÇÕES
#   --namespace    NAMESPACE    Namespace Kubernetes  (padrão: todolist)
#   --release      RELEASE      Nome do Helm release  (padrão: pg)
#   --database     DATABASE     Nome do banco          (padrão: app)
#   --username     USERNAME     Usuário do banco       (padrão: app)
#   --password     PASSWORD     Senha do banco         (padrão: senha123456)
#   --instances    N            Instâncias CNPG        (padrão: 1)
#   --storage      SIZE         Tamanho do PVC         (padrão: 1Gi)
#   --local-port   PORT         Porta local do forward (padrão: 5432)
#   --skip-forward              Apenas deploy; pula port-forward
#
# NOTES
#   Pré-requisito: CNPG operator em execução (03.setup-k3d-multi-node.sh),
#   kubectl e helm no PATH.
# ==============================================================================

set -euo pipefail

# Valores padrão dos parâmetros
NAMESPACE="todolist"
RELEASE_NAME="pg"
DATABASE="app"
USERNAME="app"
PASSWORD="senha123456"
INSTANCES=1
STORAGE_SIZE="1Gi"
LOCAL_PORT=5432
SKIP_FORWARD=false

# Parse dos argumentos nomeados
while [[ $# -gt 0 ]]; do
  case "$1" in
    --namespace)   NAMESPACE="$2";    shift 2 ;;
    --release)     RELEASE_NAME="$2"; shift 2 ;;
    --database)    DATABASE="$2";     shift 2 ;;
    --username)    USERNAME="$2";     shift 2 ;;
    --password)    PASSWORD="$2";     shift 2 ;;
    --instances)   INSTANCES="$2";    shift 2 ;;
    --storage)     STORAGE_SIZE="$2"; shift 2 ;;
    --local-port)  LOCAL_PORT="$2";   shift 2 ;;
    --skip-forward) SKIP_FORWARD=true; shift ;;
    *) echo "Argumento desconhecido: $1"; exit 1 ;;
  esac
done

SECRET_NAME="${RELEASE_NAME}-app-credentials"
CLUSTER_NAME="${RELEASE_NAME}-cluster"   # CNPG chart nomeia recursos como <release>-cluster
RW_SVC="${CLUSTER_NAME}-rw"

# Cores ANSI
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GRAY='\033[0;37m'
RED='\033[0;31m'
RESET='\033[0m'

write_step()    { echo -e "\n${CYAN}==> $1${RESET}"; }
write_success() { echo -e "    ${GREEN}OK: $1${RESET}"; }
write_warn()    { echo -e "    ${YELLOW}AVISO: $1${RESET}"; }
write_fail()    { echo -e "\n    ${RED}ERRO: $1${RESET}"; exit 1; }

# ---------------------------------------------------------------------------
# 1. Verificar CNPG operator
# ---------------------------------------------------------------------------
write_step "Verificando CloudNativePG operator..."

cnpg_ready=$(kubectl -n cnpg-system get deployment cnpg-cloudnative-pg \
  -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")

if [[ "${cnpg_ready:-0}" -lt 1 ]]; then
  write_fail "CNPG operator não está pronto (réplicas prontas: '${cnpg_ready}'). Rode './03.setup-k3d-multi-node.sh' primeiro."
fi
write_success "CNPG operator pronto (${cnpg_ready} réplica(s) pronta(s))."

# ---------------------------------------------------------------------------
# 2. Criar namespace
# ---------------------------------------------------------------------------
write_step "Criando namespace '${NAMESPACE}'..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
write_success "Namespace pronto."

# ---------------------------------------------------------------------------
# 3. Criar Secret de credenciais
#    CNPG espera as chaves: username e password
# ---------------------------------------------------------------------------
write_step "Criando Secret de credenciais '${SECRET_NAME}'..."

kubectl -n "$NAMESPACE" create secret generic "$SECRET_NAME" \
  --from-literal=username="$USERNAME" \
  --from-literal=password="$PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null

write_success "Secret criado."

# ---------------------------------------------------------------------------
# 4. Instalar / atualizar o chart do cluster CNPG via Helm
# ---------------------------------------------------------------------------
write_step "Instalando cluster PostgreSQL via Helm (release: ${RELEASE_NAME})..."

helm repo add cnpg https://cloudnative-pg.github.io/charts 2>/dev/null || true
helm repo update >/dev/null

helm upgrade --install "$RELEASE_NAME" cnpg/cluster \
  --namespace "$NAMESPACE" \
  --set cluster.instances="$INSTANCES" \
  --set cluster.storage.size="$STORAGE_SIZE" \
  --set cluster.initdb.database="$DATABASE" \
  --set cluster.initdb.owner="$USERNAME" \
  --set cluster.initdb.secret.name="$SECRET_NAME" \
  --set-string cluster.postgresql.parameters.max_connections=200 \
  --wait \
  --timeout 180s

write_success "Cluster PostgreSQL pronto."

# ---------------------------------------------------------------------------
# 5. Exibir informações de conexão
# ---------------------------------------------------------------------------
write_step "Serviços disponíveis no namespace '${NAMESPACE}'..."
kubectl -n "$NAMESPACE" get cluster,pods,svc

echo ""
echo -e "${YELLOW}Connection string (dentro do cluster):${RESET}"
echo "  postgresql://${USERNAME}:${PASSWORD}@${RW_SVC}.${NAMESPACE}.svc.cluster.local:5432/${DATABASE}"
echo ""

if $SKIP_FORWARD; then
  echo -e "    ${GRAY}Port-forward ignorado (--skip-forward). Para abrir manualmente:${RESET}"
  echo -e "    ${GRAY}kubectl port-forward -n ${NAMESPACE} svc/${RW_SVC} ${LOCAL_PORT}:5432${RESET}"
  echo ""
  exit 0
fi

# ---------------------------------------------------------------------------
# 6. Teste de conexão via pod interno
# ---------------------------------------------------------------------------
write_step "Testando conexão de dentro do cluster..."

if kubectl run pg-test --rm --restart=Never \
  --image=postgres:16-alpine \
  -n "$NAMESPACE" \
  --env="PGPASSWORD=${PASSWORD}" \
  --command \
  --attach \
  --quiet \
  -- psql -h "$RW_SVC" -p 5432 -U "$USERNAME" -d "$DATABASE" -c "SELECT 'pod ok' AS status;" 2>&1; then
  write_success "Conexão interna ao cluster confirmada."
else
  write_warn "Teste interno falhou ou pod ainda não estava pronto."
  write_warn "Você pode testar manualmente:"
  echo -e "    ${GRAY}kubectl run pg-test --rm --restart=Never --image=postgres:16-alpine -n ${NAMESPACE} --env=PGPASSWORD=${PASSWORD} --command -- psql -h ${RW_SVC} -U ${USERNAME} -d ${DATABASE} -c \"SELECT 1;\"${RESET}"
fi

# ---------------------------------------------------------------------------
# 7. Port-forward resiliente em background
#    O loop reinicia o port-forward automaticamente se o processo cair.
#    Use 'kill $(cat /tmp/pf-workshop.pid)' para encerrar.
# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN} Iniciando port-forward na porta ${LOCAL_PORT}${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo ""
echo -e "${YELLOW}DATABASE_URL para sua aplicação:${RESET}"
echo "  postgresql://${USERNAME}:${PASSWORD}@localhost:${LOCAL_PORT}/${DATABASE}"
echo ""

# Loop de reconexão em subshell — continua rodando mesmo após erros transitórios
(
  while true; do
    kubectl port-forward -n "$NAMESPACE" "svc/${RW_SVC}" "${LOCAL_PORT}:5432" || true
    sleep 3
  done
) &

PF_PID=$!
echo "$PF_PID" > /tmp/pf-workshop.pid

write_success "Port-forward rodando em background (PID: ${PF_PID})."
echo ""
echo -e "    ${GRAY}Para verificar o status : ps -p ${PF_PID}${RESET}"
echo -e "    ${GRAY}Para encerrar           : kill \$(cat /tmp/pf-workshop.pid)${RESET}"
echo ""
