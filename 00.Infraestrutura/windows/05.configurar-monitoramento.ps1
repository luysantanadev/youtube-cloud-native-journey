#Requires -Version 7.0
<#
.SYNOPSIS
    Instala o stack de monitoramento completo no cluster Kubernetes.
.DESCRIPTION
    Instala kube-prometheus-stack, Loki, Tempo, Pyroscope e Alloy via Helm
    no namespace monitoring. Ao final aplica os datasources extras do Grafana.
.NOTES
    Arquivo : 05.configurar-monitoramento.ps1
    Prereqs : cluster monitoramento em execucao (03.criar-cluster-k3d.ps1)
    Proximo : kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$YamlsDir = Join-Path $PSScriptRoot '..\yamls'

# ── 1. Namespace ──────────────────────────────────────────────────────────────
Write-Host "`n[1/7] Criando namespace monitoring..." -ForegroundColor Cyan
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# ── 2. Helm repos ─────────────────────────────────────────────────────────────
Write-Host "`n[2/7] Adicionando repositorios Helm..." -ForegroundColor Cyan
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# ── 3. kube-prometheus-stack (Prometheus + Grafana + exporters) ───────────────
Write-Host "`n[3/7] Instalando kube-prometheus-stack..." -ForegroundColor Cyan
$ValuesFile = Join-Path $YamlsDir '05.01-kube-prometheus-stack.yaml'
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack `
    --namespace monitoring `
    --values $ValuesFile

# ── 4. Loki ───────────────────────────────────────────────────────────────────
Write-Host "`n[4/7] Instalando Loki..." -ForegroundColor Cyan
$ValuesFile = Join-Path $YamlsDir '05.02-loki.yaml'
helm upgrade --install loki grafana/loki `
    --namespace monitoring `
    --values $ValuesFile

# ── 5. Tempo ──────────────────────────────────────────────────────────────────
Write-Host "`n[5/7] Instalando Tempo..." -ForegroundColor Cyan
$ValuesFile = Join-Path $YamlsDir '05.03-tempo.yaml'
helm upgrade --install tempo grafana/tempo `
    --namespace monitoring `
    --values $ValuesFile

# ── 6. Pyroscope ──────────────────────────────────────────────────────────────
Write-Host "`n[6/7] Instalando Pyroscope..." -ForegroundColor Cyan
$ValuesFile = Join-Path $YamlsDir '05.04-pyroscope.yaml'
helm upgrade --install pyroscope grafana/pyroscope `
    --namespace monitoring `
    --values $ValuesFile

# ── 7. Alloy (coletor OpenTelemetry) ──────────────────────────────────────────
Write-Host "`n[7/7] Instalando Alloy..." -ForegroundColor Cyan
$ValuesFile = Join-Path $YamlsDir '05.05-alloy.yaml'
helm upgrade --install alloy grafana/alloy `
    --namespace monitoring `
    --values $ValuesFile

# ── Datasources extras (Loki, Tempo, Pyroscope no Grafana) ────────────────────
Write-Host "`nAplicando datasources extras no Grafana..." -ForegroundColor Cyan
$DatasourceFile = Join-Path $YamlsDir '05.06-grafana-datasource.yaml'
kubectl apply -f $DatasourceFile

# ── Resumo ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " Stack de monitoramento instalado com sucesso!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host " Para acessar o Grafana execute:" -ForegroundColor Yellow
Write-Host "   kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80" -ForegroundColor White
Write-Host ""
Write-Host " Grafana: http://localhost:3000" -ForegroundColor Cyan
Write-Host " Usuario: admin  |  Senha: workshop123" -ForegroundColor Cyan
Write-Host ""