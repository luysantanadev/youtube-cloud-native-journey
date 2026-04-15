Set-Location $PSScriptRoot
$ErrorActionPreference = "Stop"

# Registry nativo do k3d: sem autenticacao, sem daemon.json, sem port-forward.
# Docker já trata 127.0.0.0/8 como insecure por padrao — localhost:5001 funciona direto.
$Registry    = "localhost:5001"
$LocalImage  = "workshop:0.1.0"
$RemoteImage = "$Registry/workshop:0.1.0"

# ---------------------------------------------------------------------------
# 1. Verificar Docker daemon
# ---------------------------------------------------------------------------
Write-Host "`n==> Verificando Docker daemon..." -ForegroundColor Cyan
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Docker nao esta rodando. Abra o Docker Desktop e tente novamente." -ForegroundColor Red
    exit 1
}
Write-Host "    OK: Docker rodando." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 2. Verificar registry k3d
# Invoke-WebRequest pode travar no PowerShell; curl.exe retorna imediatamente.
# ---------------------------------------------------------------------------
Write-Host "`n==> Verificando registry em $Registry..." -ForegroundColor Cyan
$status = curl.exe -s -o NUL -w "%{http_code}" --max-time 5 "http://$Registry/v2/" 2>&1
if ($status -ne "200") {
    Write-Host "ERRO: Registry nao acessivel em http://$Registry/v2/ (status: $status)" -ForegroundColor Red
    Write-Host "      Recrie o cluster: .\scripts\03.setup-k3d-multi-node.ps1" -ForegroundColor Yellow
    exit 1
}
Write-Host "    OK: Registry respondendo." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 3. Build da imagem local
# ---------------------------------------------------------------------------
Write-Host "`n==> Build: $LocalImage" -ForegroundColor Cyan
docker build --pull -t $LocalImage -f .\Dockerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERRO: Build falhou." -ForegroundColor Red
    exit 1
}
Write-Host "    OK: Imagem construida." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 4. Tag para o registry local
# ---------------------------------------------------------------------------
Write-Host "`n==> Tag: $LocalImage -> $RemoteImage" -ForegroundColor Cyan
docker tag $LocalImage $RemoteImage
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERRO: Tag falhou." -ForegroundColor Red
    exit 1
}
Write-Host "    OK: Tag aplicada." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 5. Push para o registry k3d
# Sem docker login — o registry e aberto sem autenticacao.
# ---------------------------------------------------------------------------
Write-Host "`n==> Push: $RemoteImage" -ForegroundColor Cyan
docker push $RemoteImage
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERRO: Push falhou." -ForegroundColor Red
    exit 1
}
Write-Host "    OK: Imagem enviada." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 6. Resumo
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "  Imagem disponivel no registry k3d!        " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Push (host)    : $RemoteImage" -ForegroundColor Yellow
Write-Host "  Pull (pods k8s): k3d-workshop-registry.localhost:5001/workshop:0.1.0" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Para usar em um Deployment Kubernetes:" -ForegroundColor Gray
Write-Host "    image: k3d-workshop-registry.localhost:5001/workshop:0.1.0" -ForegroundColor White
Write-Host ""
