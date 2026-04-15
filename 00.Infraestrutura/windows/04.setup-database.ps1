<#
.SYNOPSIS
    Cria o cluster PostgreSQL via CloudNativePG (Helm) e abre um port-forward resiliente para acesso local.

.DESCRIPTION
    - Verifica o CNPG operator.
    - Cria namespace, Secret de credenciais e deploy do cluster via Helm.
    - Testa a conexao via pod interno antes de subir o port-forward permanente.
    - Port-forward se reconecta automaticamente em caso de queda inesperada.

.NOTES
    Pre-requisito: CNPG operator em execucao (03.setup-k3d-multi-node.ps1), kubectl e helm no PATH.
#>

param(
    [string]$Namespace    = "todolist",
    [string]$ReleaseName  = "pg",
    [string]$Database     = "app",
    [string]$Username     = "app",
    [string]$Password     = "senha123456",
    [int]   $Instances    = 1,        # 1 for local dev; 3 for HA
    [string]$StorageSize  = "1Gi",
    [int]   $LocalPort    = 5432,
    [switch]$SkipForward              # deploy only, skip port-forward
)

$ErrorActionPreference = "Stop"

function Write-Step($msg)    { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "    OK: $msg" -ForegroundColor Green }
function Write-Warn($msg)    { Write-Host "    AVISO: $msg" -ForegroundColor Yellow }
function Write-Fail($msg)    { Write-Host "`n    ERRO: $msg" -ForegroundColor Red; exit 1 }

$SecretName  = "$ReleaseName-app-credentials"
$ClusterName = "$ReleaseName-cluster"   # CNPG chart names resources as <release>-cluster
$rwSvc       = "$ClusterName-rw"

# ---------------------------------------------------------------------------
# 1. Verify CNPG operator is present
# ---------------------------------------------------------------------------
Write-Step "Verificando CloudNativePG operator..."

$cnpgReady = kubectl -n cnpg-system get deployment cnpg-cloudnative-pg `
    -o jsonpath='{.status.readyReplicas}' 2>&1
if ([int]$cnpgReady -lt 1) {
    Write-Fail "CNPG operator nao esta pronto (replicas prontas: '$cnpgReady'). Rode '.\scripts\03.setup-k3d-multi-node.ps1' primeiro."
}
Write-Success "CNPG operator pronto ($cnpgReady replica(s) pronta(s))."

# ---------------------------------------------------------------------------
# 2. Create namespace
# ---------------------------------------------------------------------------
Write-Step "Criando namespace '$Namespace'..."
kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f - | Out-Null
Write-Success "Namespace pronto."

# ---------------------------------------------------------------------------
# 3. Create credentials Secret (Kubernetes Secret, not plain-text in values)
#    CNPG expects: username and password keys
# ---------------------------------------------------------------------------
Write-Step "Criando Secret de credenciais '$SecretName'..."

kubectl -n $Namespace create secret generic $SecretName `
    --from-literal=username=$Username `
    --from-literal=password=$Password `
    --dry-run=client -o yaml | kubectl apply -f - | Out-Null

Write-Success "Secret criado."

# ---------------------------------------------------------------------------
# 4. Install / upgrade the CNPG cluster chart
# ---------------------------------------------------------------------------
Write-Step "Instalando cluster PostgreSQL via Helm (release: $ReleaseName)..."

helm repo add cnpg https://cloudnative-pg.github.io/charts 2>$null | Out-Null
helm repo update | Out-Null

helm upgrade --install $ReleaseName cnpg/cluster `
    --namespace $Namespace `
    --set cluster.instances=$Instances `
    --set cluster.storage.size=$StorageSize `
    --set cluster.initdb.database=$Database `
    --set cluster.initdb.owner=$Username `
    --set cluster.initdb.secret.name=$SecretName `
    --set-string cluster.postgresql.parameters.max_connections=200 `
    --wait `
    --timeout 180s

if ($LASTEXITCODE -ne 0) { Write-Fail "Helm install falhou. Verifique os logs acima." }
Write-Success "Cluster PostgreSQL pronto."

# ---------------------------------------------------------------------------
# 5. Show connection info
# ---------------------------------------------------------------------------
Write-Step "Servicos disponiveis no namespace '$Namespace'..."
kubectl -n $Namespace get cluster,pods,svc

Write-Host ""
Write-Host "Connection string (dentro do cluster):" -ForegroundColor Yellow
Write-Host "  postgresql://${Username}:${Password}@${rwSvc}.${Namespace}.svc.cluster.local:5432/${Database}"
Write-Host ""

if ($SkipForward) {
    Write-Host "    Port-forward ignorado (-SkipForward). Para abrir manualmente:" -ForegroundColor Gray
    Write-Host "    kubectl port-forward -n $Namespace svc/$rwSvc ${LocalPort}:5432"
    Write-Host ""
    exit 0
}

# ---------------------------------------------------------------------------
# 6. Teste de conexao via pod interno + port-forward resiliente
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " Iniciando port-forward na porta $LocalPort" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "DATABASE_URL para sua aplicacao:" -ForegroundColor Yellow
Write-Host "  postgresql://${Username}:${Password}@localhost:${LocalPort}/${Database}"
Write-Host ""

# ---------------------------------------------------------------------------
# Teste de conexao via pod dentro do cluster
# ---------------------------------------------------------------------------
Write-Step "Testando conexao de dentro do cluster..."

# kubectl run com --overrides para injetar env PGPASSWORD no container.
$overrides = @{
    spec = @{
        containers = @(@{
            name    = 'pg-test'
            image   = 'postgres:16-alpine'
            command = @('psql', "-h", "${rwSvc}", '-p', '5432', '-U', $Username, '-d', $Database, '-c', "SELECT 'pod ok' AS status;")
            env     = @(@{ name = 'PGPASSWORD'; value = $Password })
        })
    }
} | ConvertTo-Json -Depth 6 -Compress

$podResult = kubectl run pg-test --rm --restart=Never `
    --image=postgres:16-alpine `
    -n $Namespace `
    --overrides=$overrides `
    --attach `
    --quiet 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Success "Conexao interna ao cluster confirmada."
    $podResult | Where-Object { $_ -match 'pod ok|\d row' } |
        ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
} else {
    Write-Warn "Teste interno falhou ou pod ainda nao estava pronto: $($podResult -join ' ')"
    Write-Warn "Voce pode testar manualmente:"
    Write-Host "    kubectl run pg-test --rm --restart=Never --image=postgres:16-alpine -n $Namespace --env=PGPASSWORD=$Password --command -- psql -h $rwSvc -U $Username -d $Database -c `"SELECT 1;`"" -ForegroundColor Gray
}

# Port-forward resiliente como background job vinculado a esta sessao.
# Se o processo cair inesperadamente, o loop reinicia automaticamente.
# Ao fechar o terminal (ou a sessao), o job e encerrado junto.
$pfJob = Start-Job -ScriptBlock {
    param($ns, $svc, $port)
    while ($true) {
        kubectl port-forward -n $ns svc/$svc "${port}:5432"
        if ($LASTEXITCODE -eq 0) { break }
        Start-Sleep -Seconds 3
    }
} -ArgumentList $Namespace, $rwSvc, $LocalPort

Write-Host ""
Write-Success "Port-forward rodando em background (Job ID: $($pfJob.Id))."
Write-Host ""
Write-Host "    Para verificar o status : Receive-Job $($pfJob.Id)" -ForegroundColor Gray
Write-Host "    Para encerrar           : Stop-Job $($pfJob.Id); Remove-Job $($pfJob.Id)" -ForegroundColor Gray
Write-Host ""
