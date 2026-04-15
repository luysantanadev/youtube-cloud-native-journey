#!/bin/bash
# ==============================================================================
# Faz o build, tag e push da imagem para o registry local do k3d.
# Registry nativo do k3d: sem autenticação, sem daemon.json, sem port-forward.
# Docker já trata 127.0.0.0/8 como insecure por padrão — localhost:5001 funciona direto.
# ==============================================================================

set -euo pipefail

# Muda para o diretório pai onde estão o Dockerfile e os assets.
cd "$(dirname "$0")/.."

readonly REGISTRY="localhost:5001"
readonly LOCAL_IMAGE="workshop:0.1.0"
readonly REMOTE_IMAGE="${REGISTRY}/workshop:0.1.0"

# ---------------------------------------------------------------------------
# 1. Verificar Docker daemon
# ---------------------------------------------------------------------------
echo ""
echo "==> Verificando Docker daemon..."
if ! docker info > /dev/null 2>&1; then
    echo "ERRO: Docker não está rodando. Inicie o Docker e tente novamente." >&2
    exit 1
fi
echo "    OK: Docker rodando."

# ---------------------------------------------------------------------------
# 2. Verificar registry k3d
# curl retorna imediatamente; evita travamentos de Invoke-WebRequest no PS.
# ---------------------------------------------------------------------------
echo ""
echo "==> Verificando registry em ${REGISTRY}..."
status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://${REGISTRY}/v2/")
if [[ "${status}" != "200" ]]; then
    echo "ERRO: Registry não acessível em http://${REGISTRY}/v2/ (status: ${status})" >&2
    echo "      Recrie o cluster: ./00.scripts/linux/03.setup-k3d-multi-node.sh" >&2
    exit 1
fi
echo "    OK: Registry respondendo."

# ---------------------------------------------------------------------------
# 3. Build da imagem local
# ---------------------------------------------------------------------------
echo ""
echo "==> Build: ${LOCAL_IMAGE}"
docker build --pull -t "${LOCAL_IMAGE}" -f ./Dockerfile .
echo "    OK: Imagem construída."

# ---------------------------------------------------------------------------
# 4. Tag para o registry local
# ---------------------------------------------------------------------------
echo ""
echo "==> Tag: ${LOCAL_IMAGE} -> ${REMOTE_IMAGE}"
docker tag "${LOCAL_IMAGE}" "${REMOTE_IMAGE}"
echo "    OK: Tag aplicada."

# ---------------------------------------------------------------------------
# 5. Push para o registry k3d
# Sem docker login — o registry é aberto sem autenticação.
# ---------------------------------------------------------------------------
echo ""
echo "==> Push: ${REMOTE_IMAGE}"
docker push "${REMOTE_IMAGE}"
echo "    OK: Imagem enviada."

# ---------------------------------------------------------------------------
# 6. Resumo
# ---------------------------------------------------------------------------
echo ""
echo "============================================="
echo "  Imagem disponível no registry k3d!        "
echo "============================================="
echo ""
echo "  Push (host)    : ${REMOTE_IMAGE}"
echo "  Pull (pods k8s): k3d-workshop-registry.localhost:5001/workshop:0.1.0"
echo ""
echo "  Para usar em um Deployment Kubernetes:"
echo "    image: k3d-workshop-registry.localhost:5001/workshop:0.1.0"
echo ""
