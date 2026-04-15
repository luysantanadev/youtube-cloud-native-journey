#!/bin/bash
# ==============================================================================
# Roda os exemplos do Docker Compose do workshop.
# Execute este script a partir de qualquer diretório — ele navega sozinho.
# ==============================================================================

set -euo pipefail

cd "$(dirname "$0")"

# Verifica se o Docker daemon está acessível antes de tentar qualquer coisa.
if ! docker info > /dev/null 2>&1; then
    echo "ERRO: Docker não está rodando. Inicie o Docker e tente novamente." >&2
    exit 1
fi

# ==============================================================================
# Exemplo 1 — compose.yml (3 serviços: dev, homologation, production)
# Demonstra variáveis inline, env_file e combinação dos dois.
#
# Sobe todos os serviços em foreground (Ctrl+C para encerrar):
#   http://localhost:3001  -> dev
#   http://localhost:3002  -> homologation
#   http://localhost:8080  -> production
# ==============================================================================
echo ""
echo "==> Subindo compose.yml (dev / homologation / production)..."
docker compose -f compose.yml up

# ==============================================================================
# Exemplo 2 — compose.yml em background (-d)
# Sobe os serviços desanexados do terminal; use 'docker compose logs -f' para acompanhar.
# Descomente o bloco abaixo para usar no lugar do Exemplo 1.
# ==============================================================================
# echo ""
# echo "==> Subindo compose.yml em background..."
# docker compose -f compose.yml up -d
# echo "    Serviços rodando. Acompanhe com: docker compose logs -f"

# ==============================================================================
# Exemplo 3 — compose.networks.yml (isolamento de rede entre ambientes)
# Demonstra múltiplas redes (dev / tst / hom) com bancos Postgres separados.
# Os clientes psql executam queries e encerram; acompanhe pelos logs.
# Descomente o bloco abaixo para usar.
# ==============================================================================
# echo ""
# echo "==> Subindo compose.networks.yml (redes isoladas por ambiente)..."
# docker compose -f compose.networks.yml up

# ==============================================================================
# Exemplo 4 — derruba e remove containers, redes e volumes
# Use após o Exemplo 2 ou 3 (background). Descomente o bloco desejado.
# ==============================================================================
# echo ""
# echo "==> Derrubando compose.yml..."
# docker compose -f compose.yml down

# echo ""
# echo "==> Derrubando compose.networks.yml (incluindo volumes)..."
# docker compose -f compose.networks.yml down -v
