Set-Location $PSScriptRoot
$ErrorActionPreference = "Stop"

# Verifica se o Docker daemon está acessível antes de tentar qualquer coisa.
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Docker não está rodando. Abra o Docker Desktop e tente novamente." -ForegroundColor Red
    exit 1
}

# ==============================================================================
# Exemplo 1 — compose.yml (3 serviços: dev, homologation, production)
# Demonstra variáveis inline, env_file e combinação dos dois.
#
# Sobe todos os serviços em foreground (Ctrl+C para encerrar):
#   http://localhost:3001  -> dev
#   http://localhost:3002  -> homologation
#   http://localhost:8080  -> production
# ==============================================================================
Write-Host "`n==> Subindo compose.yml (dev / homologation / production)..." -ForegroundColor Cyan
docker compose -f compose.yml up

# ==============================================================================
# Exemplo 2 — compose.yml em background (-d)
# Sobe os serviços desanexados do terminal; use 'docker compose logs -f' para acompanhar.
# Descomente o bloco abaixo para usar no lugar do Exemplo 1.
# ==============================================================================
# Write-Host "`n==> Subindo compose.yml em background..." -ForegroundColor Cyan
# docker compose -f compose.yml up -d
# Write-Host "    Serviços rodando. Acompanhe com: docker compose logs -f" -ForegroundColor Gray

# ==============================================================================
# Exemplo 3 — compose.networks.yml (isolamento de rede entre ambientes)
# Demonstra múltiplas redes (dev / tst / hom) com bancos Postgres separados.
# Os clientes psql executam queries e encerram; acompanhe pelos logs.
# Descomente o bloco abaixo para usar.
# ==============================================================================
# Write-Host "`n==> Subindo compose.networks.yml (redes isoladas por ambiente)..." -ForegroundColor Cyan
# docker compose -f compose.networks.yml up

# ==============================================================================
# Exemplo 4 — derruba e remove containers, redes e volumes
# Use após o Exemplo 2 ou 3 (background). Descomente o bloco desejado.
# ==============================================================================
# Write-Host "`n==> Derrubando compose.yml..." -ForegroundColor Yellow
# docker compose -f compose.yml down

# Write-Host "`n==> Derrubando compose.networks.yml (incluindo volumes)..." -ForegroundColor Yellow
# docker compose -f compose.networks.yml down -v
