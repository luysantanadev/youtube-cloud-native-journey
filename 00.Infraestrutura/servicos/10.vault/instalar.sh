#!/usr/bin/env bash
# Instala HashiCorp Vault (modo standalone) no namespace 'vault'.
#
# Namespace  : vault   | Release: vault
# Storage    : file storage via PVC 1Gi (dados persistidos)
# Root Token : gerado no init, salvo em Secret 'vault-unseal-keys'
# UI         : http://vault.monitoramento.local
# Metricas   : ServiceMonitor em /v1/sys/metrics
# Idempotente: re-executar e seguro. Unseal automatico via Secret.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
step() { echo -e "\n${CYAN}==> $1${NC}"; }
ok()   { echo -e "    ${GREEN}OK: $1${NC}"; }
warn() { echo -e "    ${YELLOW}AVISO: $1${NC}"; }
fail() { echo -e "\n    ${RED}ERRO: $1${NC}"; exit 1; }

# 1. Helm repo
step "Adicionando repositorio HashiCorp..."
helm repo add hashicorp https://helm.releases.hashicorp.com --force-update 2>/dev/null || true
helm repo update hashicorp 2>/dev/null
ok "Repositorio pronto."

# 2. Namespace
step "Criando namespace 'vault'..."
kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f - >/dev/null
ok "Namespace pronto."

# 3. Vault
step "Instalando HashiCorp Vault 'vault'..."
# Remove webhook config que pode causar conflito de field manager no upgrade
kubectl delete mutatingwebhookconfiguration vault-agent-injector-cfg 2>/dev/null || true
helm upgrade --install vault hashicorp/vault \
    --namespace vault \
    --values "$SCRIPT_DIR/values.yaml" \
    || fail "Helm install falhou."
ok "Vault instalado."

# 3.5. Init e Unseal automatico
ROOT_TOKEN=""
step "Aguardando pod vault-0 iniciar..."
deadline=$((SECONDS + 90))
while [[ $SECONDS -lt $deadline ]]; do
    phase=$(kubectl get pod vault-0 -n vault -o jsonpath='{.status.phase}' 2>/dev/null || true)
    [[ "$phase" == "Running" ]] && break
    sleep 3
done
[[ "$(kubectl get pod vault-0 -n vault -o jsonpath='{.status.phase}' 2>/dev/null)" == "Running" ]] \
    || fail "Pod vault-0 nao iniciou em 90s."

step "Verificando estado do Vault..."
set +e
kubectl exec -n vault vault-0 -- vault operator init -status >/dev/null 2>&1
VAULT_INIT_CODE=$?
set -e
# 0 = unsealed | qualquer outro = precisa de atencao (sealed ou nao inicializado)

if [[ $VAULT_INIT_CODE -ne 0 ]]; then
    # Verifica se ja existe o Secret com as chaves (reinstall / restart)
    if kubectl get secret vault-unseal-keys -n vault >/dev/null 2>&1; then
        step "Vault selado. Lendo chave do Secret 'vault-unseal-keys'..."
        UNSEAL_KEY=$(kubectl get secret vault-unseal-keys -n vault \
            -o jsonpath='{.data.unseal-key}' 2>/dev/null | base64 -d 2>/dev/null || true)
        ROOT_TOKEN=$(kubectl get secret vault-unseal-keys -n vault \
            -o jsonpath='{.data.root-token}' 2>/dev/null | base64 -d 2>/dev/null || true)
        kubectl exec -n vault vault-0 -- vault operator unseal "$UNSEAL_KEY" >/dev/null
        ok "Vault desselado."
    else
        step "Inicializando Vault (1 unseal key, threshold 1)..."
        INIT_JSON=$(kubectl exec -n vault vault-0 -- vault operator init \
            -key-shares=1 -key-threshold=1 -format=json)
        UNSEAL_KEY=$(echo "$INIT_JSON" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['unseal_keys_b64'][0])")
        ROOT_TOKEN=$(echo "$INIT_JSON" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['root_token'])")

        # Salvar chaves em Secret para re-unseal automatico (workshop only)
        kubectl create secret generic vault-unseal-keys \
            --namespace vault \
            --from-literal=unseal-key="$UNSEAL_KEY" \
            --from-literal=root-token="$ROOT_TOKEN" \
            --dry-run=client -o yaml | kubectl apply -f - >/dev/null

        kubectl exec -n vault vault-0 -- vault operator unseal "$UNSEAL_KEY" >/dev/null
        ok "Vault inicializado e desselado. Root token: $ROOT_TOKEN"
    fi
else
    ok "Vault ja inicializado e desselado."
    ROOT_TOKEN=$(kubectl get secret vault-unseal-keys -n vault \
        -o jsonpath='{.data.root-token}' 2>/dev/null | base64 -d 2>/dev/null || true)
fi

# 4. Ingress HTTP
step "Criando Ingress HTTP para vault.monitoramento.local..."
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: vault
  namespace: vault
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  ingressClassName: traefik
  rules:
    - host: vault.monitoramento.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: vault
                port:
                  number: 8200
EOF
ok "Vault UI em http://vault.monitoramento.local."

# 5. Secret de metricas + ServiceMonitor
step "Criando Secret e ServiceMonitor para metricas..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: vault-metrics-token
  namespace: vault
  labels:
    app.kubernetes.io/instance: vault
type: Opaque
stringData:
  token: "$ROOT_TOKEN"
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: vault
  namespace: vault
  labels:
    release: kube-prometheus-stack
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: vault
      app.kubernetes.io/instance: vault
  endpoints:
    - port: http
      interval: 30s
      path: /v1/sys/metrics
      params:
        format: [prometheus]
      bearerTokenSecret:
        name: vault-metrics-token
        key: token
EOF
ok "ServiceMonitor criado."

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Vault pronto!${NC}"
echo -e "${GREEN}============================================${NC}"
echo "  Namespace  : vault"
echo "  Root Token : $ROOT_TOKEN"
echo "  Chaves     : kubectl get secret vault-unseal-keys -n vault -o yaml"
echo "  UI         : http://vault.monitoramento.local"
echo "  API        : http://vault.monitoramento.local/v1"
echo ""
echo -e "  ${YELLOW}Adicionar ao hosts (se necessario):${NC}"
echo "    127.0.0.1  vault.monitoramento.local"
echo ""
echo -e "  ${YELLOW}Aguardar pronto:${NC}"
echo "    kubectl -n vault get pods -w"
echo ""
