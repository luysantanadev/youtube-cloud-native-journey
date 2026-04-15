<#
.SYNOPSIS
    Cria o cluster k3d 'workshop' com Traefik e CloudNativePG para o laboratório local de Kubernetes.

.DESCRIPTION
    - Remove cluster anterior 'workshop' se existir.
    - Cria cluster k3d multi-node com loadbalancer nas portas 80/443.
    - Cria o registry local junto com o cluster (--registry-create), conforme
      o padrao da documentacao k3d. O k3d configura automaticamente o
      registries.yaml em todos os nos — nenhum passo manual necessario.
    - Instala Traefik (ingress) e CloudNativePG operator via Helm.
    - Idempotente: pode ser reexecutado a qualquer momento para resetar o ambiente.

.NOTES
    Pré-requisito: Docker Desktop em execução, k3d, kubectl e helm no PATH.
    Execute após 02.verify-installs.ps1 confirmar tudo verde.
#>

$ErrorActionPreference = "Stop"

function Write-Step($msg)    { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "    OK: $msg" -ForegroundColor Green }
function Write-Warn($msg)    { Write-Host "    AVISO: $msg" -ForegroundColor Yellow }
function Write-Fail($msg)    { Write-Host "`n    ERRO: $msg" -ForegroundColor Red; exit 1 }

# ---------------------------------------------------------------------------
# 0. Pre-checks
# ---------------------------------------------------------------------------
Write-Step "Verificando pre-requisitos..."

@("docker", "k3d", "kubectl", "helm") | ForEach-Object {
    if (-not (Get-Command $_ -ErrorAction SilentlyContinue)) {
        Write-Fail "$_ nao encontrado. Instale antes de continuar."
    }
}

docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Docker Desktop nao esta rodando. Abra o Docker Desktop e tente novamente."
}

Write-Success "Todos os pre-requisitos encontrados."

# ---------------------------------------------------------------------------
# 1. Limpar cluster anterior (se existir)
# ---------------------------------------------------------------------------
Write-Step "Verificando cluster existente..."

$existing = k3d cluster list -o json | ConvertFrom-Json | Where-Object { $_.name -eq "workshop" }
if ($existing) {
    Write-Host "    Cluster 'workshop' encontrado. Deletando..." -ForegroundColor Yellow
    k3d cluster delete workshop
    if ($LASTEXITCODE -ne 0) { Write-Fail "Falha ao deletar o cluster anterior." }
}

# ---------------------------------------------------------------------------
# 2. Criar cluster
# ---------------------------------------------------------------------------
Write-Step "Criando cluster k3d 'workshop'..."

k3d cluster create workshop `
    --port "80:80@loadbalancer" `
    --port "443:443@loadbalancer" `
    --agents 2 `
    --k3s-arg "--disable=traefik@server:0" `
    --registry-create workshop-registry.localhost:0.0.0.0:5001 `
    --kubeconfig-update-default `
    --kubeconfig-switch-context `
    --wait

if ($LASTEXITCODE -ne 0) { Write-Fail "Falha ao criar o cluster." }
Write-Success "Cluster criado."

# ---------------------------------------------------------------------------
# 3. Corrigir kubeconfig
# ---------------------------------------------------------------------------
Write-Step "Corrigindo endpoint do kubeconfig..."

$currentServer = kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
if ($currentServer -match ':(\d+)$') {
    $apiPort = $Matches[1]
} else {
    Write-Fail "Nao foi possivel extrair a porta do API server. Server: $currentServer"
}

$newServer = "https://127.0.0.1:$apiPort"
kubectl config set-cluster k3d-workshop --server=$newServer

if ($LASTEXITCODE -ne 0) { Write-Fail "Falha ao corrigir o kubeconfig." }
Write-Success "Kubeconfig corrigido: $newServer"

# ---------------------------------------------------------------------------
# 4. Aguardar nodes ficarem prontos
# ---------------------------------------------------------------------------
Write-Step "Aguardando nodes ficarem prontos (timeout: 90s)..."

kubectl wait --for=condition=Ready nodes --all --timeout=90s

if ($LASTEXITCODE -ne 0) { Write-Fail "Nodes nao ficaram prontos a tempo." }
Write-Success "Todos os nodes prontos."

# ---------------------------------------------------------------------------
# 5. Instalar Traefik via Helm
# ---------------------------------------------------------------------------
Write-Step "Adicionando repo do Traefik..."

helm repo add traefik https://traefik.github.io/charts | Out-Null
helm repo update | Out-Null

Write-Step "Instalando Traefik..."

helm upgrade --install traefik traefik/traefik `
    --namespace traefik `
    --create-namespace `
    --set deployment.replicas=1 `
    --set ports.web.hostPort=80 `
    --set ports.websecure.hostPort=443 `
    --set providers.kubernetesCRD.enabled=true `
    --set providers.kubernetesCRD.allowCrossNamespace=true `
    --set providers.kubernetesIngress.enabled=true `
    --set service.type=ClusterIP `
    --wait `
    --timeout 120s

if ($LASTEXITCODE -ne 0) { Write-Fail "Falha ao instalar o Traefik." }
Write-Success "Traefik instalado."

# ---------------------------------------------------------------------------
# 6. Instalar CloudNativePG operator
# ---------------------------------------------------------------------------
Write-Step "Adicionando repo do CloudNativePG..."

helm repo add cnpg https://cloudnative-pg.github.io/charts | Out-Null
helm repo update | Out-Null

Write-Step "Instalando CloudNativePG operator..."

helm upgrade --install cnpg cnpg/cloudnative-pg `
    --namespace cnpg-system `
    --create-namespace `
    --wait `
    --timeout 120s

if ($LASTEXITCODE -ne 0) { Write-Fail "Falha ao instalar o CloudNativePG operator." }
Write-Success "CloudNativePG operator instalado."

# ---------------------------------------------------------------------------
# 7. Verificação final do cluster
# ---------------------------------------------------------------------------
Write-Step "Verificando cluster..."

kubectl get nodes
Write-Host ""
kubectl get pods -n traefik
Write-Host ""
kubectl get pods -n cnpg-system

# ---------------------------------------------------------------------------
# 8. Resumo final
# ---------------------------------------------------------------------------
$nodeCount = @(kubectl get nodes --no-headers).Count

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " Cluster pronto para o workshop!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Nodes:        $nodeCount node(s) prontos"
Write-Host "API Server:   $newServer"
Write-Host "Traefik:      http://localhost  (porta 80)"
Write-Host "              https://localhost (porta 443)"
Write-Host "CloudNativePG: instalado em cnpg-system"
Write-Host ""
Write-Host "Registry local:"
Write-Host "  Push do host    : localhost:5001"
Write-Host "  Dentro dos pods : k3d-workshop-registry.localhost:5001"
Write-Host "  Sem autenticacao. Sem alteracao no daemon.json."
Write-Host ""
Write-Host "Proximo passo:"
Write-Host "  kubectl apply -f scripts/teste.yaml"
Write-Host ""
Write-Host "Para resetar o cluster a qualquer momento:"
Write-Host "  .\scripts\03.setup-k3d-multi-node.ps1"
Write-Host ""