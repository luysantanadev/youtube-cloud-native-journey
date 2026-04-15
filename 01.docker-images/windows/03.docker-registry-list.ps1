Set-Location $PSScriptRoot
$ErrorActionPreference = "Stop"

$Registry = "localhost:5001"

# ---------------------------------------------------------------------------
# 1. Verificar registry
# ---------------------------------------------------------------------------
$status = curl.exe -s -o NUL -w "%{http_code}" --max-time 5 "http://$Registry/v2/" 2>&1
if ($status -ne "200") {
    Write-Host "ERRO: Registry nao acessivel em http://$Registry/v2/ (status: $status)" -ForegroundColor Red
    Write-Host "      Recrie o cluster: .\scripts\03.setup-k3d-multi-node.ps1" -ForegroundColor Yellow
    exit 1
}

# ---------------------------------------------------------------------------
# 2. Listar repositorios e tags via API OCI Distribution
#    GET /v2/_catalog           -> lista todos os repositorios
#    GET /v2/<repo>/tags/list   -> lista as tags de cada repositorio
# ---------------------------------------------------------------------------
$catalogJson = curl.exe -s "http://$Registry/v2/_catalog" 2>&1 | ConvertFrom-Json
$repos       = $catalogJson.repositories

if (-not $repos -or $repos.Count -eq 0) {
    Write-Host "`nNenhuma imagem encontrada no registry $Registry." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Registry: http://$Registry" -ForegroundColor Cyan
Write-Host ("-" * 45)

foreach ($repo in $repos) {
    $tagsJson = curl.exe -s "http://$Registry/v2/$repo/tags/list" 2>&1 | ConvertFrom-Json
    $tags     = $tagsJson.tags ?? @()
    foreach ($tag in $tags) {
        Write-Host "  ${repo}:${tag}" -ForegroundColor White
    }
}

Write-Host ("-" * 45)
Write-Host ""
