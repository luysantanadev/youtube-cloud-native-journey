Set-Location $PSScriptRoot
$ErrorActionPreference = "Stop"

$Image = "workshop:0.1.0"
$Port  = 8090

# Verifica se o Docker daemon esta acessivel antes de tentar qualquer coisa.
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Docker nao esta rodando. Abra o Docker Desktop e tente novamente." -ForegroundColor Red
    exit 1
}

# Para e remove um container anterior com o mesmo nome, se existir.
# Evita erro "container name already in use" em execucoes repetidas.
$existing = docker ps -aq --filter "name=workshop-nginx" 2>$null
if ($existing) {
    Write-Host "Removendo container anterior..." -ForegroundColor Yellow
    docker rm -f workshop-nginx | Out-Null
}

Write-Host "`n==> Build: $Image" -ForegroundColor Cyan
docker build --pull -t $Image -f .\Dockerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERRO: Build falhou. Corrija os erros acima e tente novamente." -ForegroundColor Red
    exit 1
}
Write-Host "    OK: Imagem construida com sucesso." -ForegroundColor Green

Write-Host "`n==> Iniciando container na porta $Port..." -ForegroundColor Cyan
Write-Host "    Acesse: http://localhost:$Port" -ForegroundColor Gray
Write-Host "    Pressione Ctrl+C para encerrar.`n" -ForegroundColor Gray

# --name permite identificar e parar o container facilmente.
# --rm remove o container automaticamente ao encerrar.
docker run --rm --name workshop-nginx -p "${Port}:8080" $Image