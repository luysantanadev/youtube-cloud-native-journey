<#
.SYNOPSIS
    Verifica se todas as ferramentas do workshop estão instaladas e o Docker Desktop está em execução.

.DESCRIPTION
    Checa a presença de docker, k3d, kubectl e helm no PATH, exibe as versões instaladas
    e confirma que o daemon do Docker está respondendo.

.NOTES
    Execute em um novo terminal após rodar 01.install-dependencies.ps1 e abrir o Docker Desktop.
#>

$ok = $true

# Flags de versão por ferramenta — cada uma tem sua própria convenção.
$versionArgs = @{
    docker  = @('--version')
    k3d     = @('--version')
    kubectl = @('version', '--client', '--short')
    helm    = @('version', '--short')
}

function Write-Check {
    param([bool]$Passed, [string]$Label, [string]$Detail = "")
    $status = if ($Passed) { " OK  " } else { " FALTANDO " }
    $color  = if ($Passed) { "Green" } else { "Red" }
    $suffix = if ($Detail) { "  ($Detail)" } else { "" }
    Write-Host "  [$status]  $Label$suffix" -ForegroundColor $color
}

Write-Host ""
Write-Host "==> Ferramentas no PATH" -ForegroundColor Cyan

foreach ($cmd in @("docker", "k3d", "kubectl", "helm")) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        $ver = & $cmd @($versionArgs[$cmd]) 2>&1 | Select-Object -First 1
        Write-Check -Passed $true -Label $cmd -Detail $ver
    } else {
        Write-Check -Passed $false -Label $cmd
        $ok = $false
    }
}

Write-Host ""
Write-Host "==> Docker Desktop" -ForegroundColor Cyan

$null = docker info 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Check -Passed $true -Label "daemon respondendo"
} else {
    Write-Check -Passed $false -Label "daemon nao esta rodando — abra o Docker Desktop primeiro"
    $ok = $false
}

Write-Host ""
if ($ok) {
    Write-Host "  Tudo pronto! Pode rodar: .\scripts\03.setup-k3d-multi-node.ps1" -ForegroundColor Green
} else {
    Write-Host "  Corrija os itens acima antes de continuar." -ForegroundColor Red
    exit 1
}
Write-Host ""