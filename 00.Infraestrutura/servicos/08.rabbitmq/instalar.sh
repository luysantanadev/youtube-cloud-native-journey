#!/usr/bin/env bash
# Instala RabbitMQ via RabbitMQ Cluster Operator (oficial) no namespace 'rabbitmq'.
#
# Operator   : rabbitmq-system (instalado via manifest oficial do GitHub)
# Namespace  : rabbitmq
# Usuario    : user      | Senha: Workshop123rabbit
# AMQP TCP   : localhost:5672  (entrypoint 'amqp' no Traefik)
# UI         : http://rabbitmq.monitoramento.local
# Metricas   : ServiceMonitor porta prometheus (15692)
# Idempotente: re-executar e seguro.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
step() { echo -e "\n${CYAN}==> $1${NC}"; }
ok()   { echo -e "    ${GREEN}OK: $1${NC}"; }
warn() { echo -e "    ${YELLOW}AVISO: $1${NC}"; }
fail() { echo -e "\n    ${RED}ERRO: $1${NC}"; exit 1; }

# ---------------------------------------------------------------------------
# 0. Cleanup — remove instalação anterior (idempotência)
# ---------------------------------------------------------------------------
step "Verificando instalação anterior..."
if kubectl get namespace rabbitmq >/dev/null 2>&1; then
    step "Removendo namespace 'rabbitmq' existente..."
    # 0a. Remove finalizers de PVCs (evita namespace preso em Terminating por pvc-protection)
    kubectl get pvc -n rabbitmq --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null \
        | while read -r pvc; do
            [[ -z "$pvc" ]] && continue
            kubectl patch pvc "$pvc" -n rabbitmq -p '{"metadata":{"finalizers":[]}}' --type=merge >/dev/null 2>&1 || true
          done

    # 0b. Força remoção dos pods para liberar PVCs imediatamente
    kubectl delete pods --all -n rabbitmq --force --grace-period=0 >/dev/null 2>&1 || true

    # 0c. Dispara delete do namespace sem bloquear
    kubectl delete namespace rabbitmq --wait=false >/dev/null 2>&1 || true

    # 0d. Poll loop — aguarda namespace desaparecer completamente (até 120s)
    echo "    Aguardando namespace ser removido..."
    deadline=$((SECONDS + 120))
    removed=false
    while [[ $SECONDS -lt $deadline ]]; do
        sleep 3
        if ! kubectl get namespace rabbitmq >/dev/null 2>&1; then
            removed=true
            break
        fi
    done
    [[ "$removed" == "true" ]] || fail "Timeout: namespace 'rabbitmq' ainda em Terminating apos 120s."
    ok "Namespace anterior removido."
else
    ok "Nenhuma instalação anterior encontrada."
fi

# ---------------------------------------------------------------------------
# 1. RabbitMQ Cluster Operator
# ---------------------------------------------------------------------------
step "Instalando RabbitMQ Cluster Operator..."
kubectl apply -f "https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml" \
    || fail "Falha ao aplicar cluster-operator.yml."

step "Aguardando operator ficar pronto..."
kubectl rollout status deployment/rabbitmq-cluster-operator -n rabbitmq-system --timeout=120s \
    || fail "Operator nao ficou pronto a tempo."
ok "Operator pronto."

# ---------------------------------------------------------------------------
# 2. Namespace
# ---------------------------------------------------------------------------
step "Criando namespace 'rabbitmq'..."
kubectl create namespace rabbitmq --dry-run=client -o yaml | kubectl apply -f - >/dev/null
ok "Namespace pronto."

# ---------------------------------------------------------------------------
# 3. RabbitmqCluster
# ---------------------------------------------------------------------------
step "Aplicando RabbitmqCluster (manifest.yaml)..."
kubectl apply -f "$SCRIPT_DIR/manifest.yaml" || fail "Falha ao aplicar manifest.yaml."

step "Aguardando operator criar StatefulSet (processamento assincrono)..."
deadline=$((SECONDS + 120))
while [[ $SECONDS -lt $deadline ]]; do
    if kubectl get statefulset rabbitmq-server -n rabbitmq >/dev/null 2>&1; then
        break
    fi
    sleep 5
done
kubectl get statefulset rabbitmq-server -n rabbitmq >/dev/null 2>&1 \
    || fail "Timeout: operator nao criou StatefulSet em 120s."

step "Aguardando pods ficarem prontos..."
kubectl rollout status statefulset/rabbitmq-server -n rabbitmq --timeout=180s \
    || fail "RabbitmqCluster nao ficou pronto a tempo."
ok "RabbitmqCluster pronto."

# ---------------------------------------------------------------------------
# 4. Ingress — UI de gerenciamento (porta 15672)
# ---------------------------------------------------------------------------
step "Aplicando Ingress para management UI..."
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rabbitmq-management
  namespace: rabbitmq
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  ingressClassName: traefik
  rules:
    - host: rabbitmq.monitoramento.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: rabbitmq
                port:
                  name: management
EOF
ok "UI acessivel em http://rabbitmq.monitoramento.local"

# ---------------------------------------------------------------------------
# 5. IngressRouteTCP — expoe localhost:5672 (AMQP)
# ---------------------------------------------------------------------------
step "Aplicando IngressRouteTCP AMQP (porta 5672)..."
kubectl apply -f - <<'EOF'
apiVersion: traefik.io/v1alpha1
kind: IngressRouteTCP
metadata:
  name: rabbitmq-amqp
  namespace: rabbitmq
spec:
  entryPoints:
    - amqp
  routes:
    - match: HostSNI(`*`)
      services:
        - name: rabbitmq
          port: 5672
EOF
ok "RabbitMQ AMQP acessivel em localhost:5672."

# ---------------------------------------------------------------------------
# 6. ServiceMonitor — Prometheus scrape (porta prometheus/15692)
# ---------------------------------------------------------------------------
step "Aplicando ServiceMonitor..."
if kubectl apply -f - <<'EOF'; then
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: rabbitmq
  namespace: rabbitmq
  labels:
    release: kube-prometheus-stack
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: rabbitmq
  endpoints:
    - port: prometheus
      interval: 30s
      path: /metrics
EOF
    ok "ServiceMonitor aplicado."
else
    warn "ServiceMonitor nao aplicado (CRD ausente?)."
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  RabbitMQ pronto!${NC}"
echo -e "${GREEN}============================================${NC}"
echo "  Namespace  : rabbitmq"
echo "  Operator   : rabbitmq-system"
echo "  Usuario    : user"
echo "  Senha      : Workshop123rabbit"
echo "  AMQP       : amqp://user:Workshop123rabbit@localhost:5672"
echo "  UI         : http://rabbitmq.monitoramento.local"
echo "  Metricas   : porta prometheus (15692)"
echo ""
echo -e "  ${YELLOW}Adicionar ao hosts (se necessario):${NC}"
echo "    127.0.0.1  rabbitmq.monitoramento.local"
echo ""
echo -e "  ${YELLOW}Verificar cluster:${NC}"
echo "    kubectl -n rabbitmq get rabbitmqcluster rabbitmq"
echo "    kubectl -n rabbitmq get pods -w"
echo ""
