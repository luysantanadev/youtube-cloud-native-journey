#Requires -Version 7.0
<#
.SYNOPSIS
    Instala HashiCorp Vault (modo dev) no namespace 'vault'.
.NOTES
    Namespace  : vault   | Release: vault
    Storage    : file storage via PVC 1Gi (dados persistidos)
    Root Token : gerado no init, salvo em Secret 'vault-unseal-keys'
    UI         : http://vault.monitoramento.local  (adicionar ao /etc/hosts)
    Metricas   : ServiceMonitor em /v1/sys/metrics
    Idempotente: re-executar e seguro. Unseal automatico via Secret.
#>
$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot

function Write-Step($msg)    { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "    OK: $msg" -ForegroundColor Green }
function Write-Warn($msg)    { Write-Host "    AVISO: $msg" -ForegroundColor Yellow }
function Write-Fail($msg)    { Write-Host "`n    ERRO: $msg" -ForegroundColor Red; exit 1 }

# ---------------------------------------------------------------------------
# 1. Helm repo
# ---------------------------------------------------------------------------
Write-Step "Adicionando repositorio HashiCorp..."
helm repo add hashicorp https://helm.releases.hashicorp.com --force-update 2>&1 | Out-Null
helm repo update hashicorp 2>&1 | Out-Null
Write-Success "Repositorio pronto."

# ---------------------------------------------------------------------------
# 2. Namespace
# ---------------------------------------------------------------------------
Write-Step "Criando namespace 'vault'..."
kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f - | Out-Null
Write-Success "Namespace pronto."

# ---------------------------------------------------------------------------
# 3. Vault
# ---------------------------------------------------------------------------
Write-Step "Instalando HashiCorp Vault 'vault'..."
# Remove webhook config que pode causar conflito de field manager no upgrade
kubectl delete mutatingwebhookconfiguration vault-agent-injector-cfg 2>&1 | Out-Null
helm upgrade --install vault hashicorp/vault `
    --namespace vault `
    --values "$scriptDir/values.yaml"
if ($LASTEXITCODE -ne 0) { Write-Fail "Helm install falhou." }
Write-Success "Vault instalado."

# ---------------------------------------------------------------------------
# 3.5. Init e Unseal automatico
# ---------------------------------------------------------------------------
$rootToken = ""
Write-Step "Aguardando pod vault-0 iniciar..."
$deadline = (Get-Date).AddSeconds(90)
do {
    $phase = kubectl get pod vault-0 -n vault -o jsonpath='{.status.phase}' 2>&1
    if ($phase -eq "Running") { break }
    Start-Sleep 3
} until ((Get-Date) -gt $deadline)
if ($phase -ne "Running") { Write-Fail "Pod vault-0 nao iniciou em 90s." }

Write-Step "Verificando estado do Vault..."
kubectl exec -n vault vault-0 -- vault operator init -status 2>&1 | Out-Null
$vaultInitCode = $LASTEXITCODE
# 0 = unsealed | qualquer outro = precisa de atencao (sealed ou nao inicializado)

if ($vaultInitCode -ne 0) {
    # Verifica se ja existe o Secret com as chaves (reinstall / restart)
    kubectl get secret vault-unseal-keys -n vault 2>&1 | Out-Null
    $secretExists = $LASTEXITCODE -eq 0

    if (-not $secretExists) {
        Write-Step "Inicializando Vault (1 unseal key, threshold 1)..."
        $initOutput = kubectl exec -n vault vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json
        $initJson   = $initOutput | ConvertFrom-Json
        $unsealKey  = $initJson.unseal_keys_b64[0]
        $rootToken  = $initJson.root_token

        # Salvar chaves em Secret para re-unseal automatico (workshop only)
        kubectl create secret generic vault-unseal-keys `
            --namespace vault `
            --from-literal=unseal-key="$unsealKey" `
            --from-literal=root-token="$rootToken" `
            --dry-run=client -o yaml | kubectl apply -f - | Out-Null

        kubectl exec -n vault vault-0 -- vault operator unseal $unsealKey | Out-Null
        Write-Success "Vault inicializado e desselado. Root token: $rootToken"
    } else {
        Write-Step "Vault selado. Lendo chave do Secret 'vault-unseal-keys'..."
        $unsealKeyB64 = kubectl get secret vault-unseal-keys -n vault -o jsonpath='{.data.unseal-key}' 2>&1
        $rootTokenB64 = kubectl get secret vault-unseal-keys -n vault -o jsonpath='{.data.root-token}' 2>&1
        $unsealKey = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($unsealKeyB64))
        $rootToken = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($rootTokenB64))
        kubectl exec -n vault vault-0 -- vault operator unseal $unsealKey | Out-Null
        Write-Success "Vault desselado."
    }
} else {
    Write-Success "Vault ja inicializado e desselado."
    $rootTokenB64 = kubectl get secret vault-unseal-keys -n vault -o jsonpath='{.data.root-token}' 2>&1
    if ($LASTEXITCODE -eq 0 -and $rootTokenB64) {
        $rootToken = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($rootTokenB64))
    }
}

# ---------------------------------------------------------------------------
# 4. Ingress HTTP
# ---------------------------------------------------------------------------
Write-Step "Criando Ingress HTTP para vault.monitoramento.local..."
@"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: vault
  namespace: vault
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  ingressClassName: traefik
  rules:
    - host: vault.monitoramento.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: vault
                port:
                  number: 8200
"@ | kubectl apply -f -
if ($LASTEXITCODE -ne 0) { Write-Warn "Ingress nao aplicado." }
else { Write-Success "Vault UI em http://vault.monitoramento.local." }

# ---------------------------------------------------------------------------
# 5. Secret de metricas + ServiceMonitor
# ---------------------------------------------------------------------------
Write-Step "Criando Secret e ServiceMonitor para metricas..."
@"
apiVersion: v1
kind: Secret
metadata:
  name: vault-metrics-token
  namespace: vault
  labels:
    app.kubernetes.io/instance: vault
type: Opaque
stringData:
  token: "$rootToken"
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: vault
  namespace: vault
  labels:
    release: kube-prometheus-stack
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: vault
      app.kubernetes.io/instance: vault
  endpoints:
    - port: http
      interval: 30s
      path: /v1/sys/metrics
      params:
        format: [prometheus]
      bearerTokenSecret:
        name: vault-metrics-token
        key: token
"@ | kubectl apply -f -
if ($LASTEXITCODE -ne 0) { Write-Warn "Secret/ServiceMonitor nao aplicados." }
else { Write-Success "ServiceMonitor criado." }

# ---------------------------------------------------------------------------
# Resumo
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Vault pronto!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Namespace  : vault"
Write-Host "  Root Token : $rootToken" 
Write-Host "  Chaves     : kubectl get secret vault-unseal-keys -n vault -o yaml"
Write-Host "  UI         : http://vault.monitoramento.local"
Write-Host "  API        : http://vault.monitoramento.local/v1"
Write-Host ""
Write-Host "  Adicionar ao hosts (se necessario):" -ForegroundColor Yellow
Write-Host "    127.0.0.1  vault.monitoramento.local"
Write-Host ""
Write-Host "  Aguardar pronto:" -ForegroundColor Yellow
Write-Host "    kubectl -n vault get pods -w"
Write-Host ""
