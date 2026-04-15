#!/bin/bash
# ==============================================================================
# Lista todos os repositórios e tags presentes no registry local do k3d.
# Usa a API OCI Distribution:
#   GET /v2/_catalog         -> lista todos os repositórios
#   GET /v2/<repo>/tags/list -> lista as tags de cada repositório
# Requer: curl, jq
# ==============================================================================

set -euo pipefail

readonly REGISTRY="localhost:5001"

# jq é necessário para interpretar as respostas JSON da API do registry.
if ! command -v jq > /dev/null 2>&1; then
    echo "ERRO: 'jq' não encontrado. Instale com: sudo apt-get install jq" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 1. Verificar registry
# ---------------------------------------------------------------------------
status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://${REGISTRY}/v2/")
if [[ "${status}" != "200" ]]; then
    echo "ERRO: Registry não acessível em http://${REGISTRY}/v2/ (status: ${status})" >&2
    echo "      Recrie o cluster: ./00.scripts/linux/03.setup-k3d-multi-node.sh" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. Listar repositórios e tags via API OCI Distribution
# ---------------------------------------------------------------------------
repos=$(curl -s "http://${REGISTRY}/v2/_catalog" | jq -r '.repositories[]? // empty')

if [[ -z "${repos}" ]]; then
    echo ""
    echo "Nenhuma imagem encontrada no registry ${REGISTRY}."
    exit 0
fi

echo ""
echo "Registry: http://${REGISTRY}"
echo "---------------------------------------------"

while IFS= read -r repo; do
    tags=$(curl -s "http://${REGISTRY}/v2/${repo}/tags/list" | jq -r '.tags[]? // empty')
    while IFS= read -r tag; do
        echo "  ${repo}:${tag}"
    done <<< "${tags}"
done <<< "${repos}"

echo "---------------------------------------------"
echo ""
