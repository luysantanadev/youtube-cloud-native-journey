#!/bin/bash
# ==============================================================================
# Faz o build da imagem workshop-nginx e sobe um container local para teste.
# ==============================================================================

set -euo pipefail

# Muda para o diretório pai onde estão o Dockerfile e os assets.
cd "$(dirname "$0")/.."

readonly IMAGE="workshop:0.1.0"
readonly PORT=8090

# Verifica se o Docker daemon está acessível antes de tentar qualquer coisa.
if ! docker info > /dev/null 2>&1; then
    echo "ERRO: Docker não está rodando. Inicie o Docker e tente novamente." >&2
    exit 1
fi

# Para e remove um container anterior com o mesmo nome, se existir.
# Evita erro "container name already in use" em execuções repetidas.
if docker ps -aq --filter "name=workshop-nginx" | grep -q .; then
    echo "Removendo container anterior..."
    docker rm -f workshop-nginx > /dev/null
fi

echo ""
echo "==> Build: ${IMAGE}"
docker build --pull -t "${IMAGE}" -f ./Dockerfile .
echo "    OK: Imagem construída com sucesso."

echo ""
echo "==> Iniciando container na porta ${PORT}..."
echo "    Acesse: http://localhost:${PORT}"
echo "    Pressione Ctrl+C para encerrar."
echo ""

# --name permite identificar e parar o container facilmente.
# --rm remove o container automaticamente ao encerrar.
docker run --rm --name workshop-nginx -p "${PORT}:8080" "${IMAGE}"
