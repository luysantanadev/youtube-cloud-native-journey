# Jornada Cloud-Native

> Repositório de apoio ao canal **[@luysantanadev](https://www.youtube.com/@luysantanadev)** no YouTube.
> A proposta é construir, evoluir e operar aplicações cloud-native modernas em Kubernetes, com foco em **segurança**, **performance**, **eficiência**, **DevOps** e **CI/CD**.

---

## Sobre o Projeto

O **youtube-cloud-native-journey** é uma jornada prática de desenvolvimento em nuvem. A ideia do repositório não é cobrir apenas observabilidade, mas mostrar como times de engenharia constroem aplicações reais para rodar em Kubernetes, desde a base de infraestrutura local até operação, automação, entrega contínua e qualidade de software.

O ponto de partida continua sendo um ambiente local com **k3d (Kubernetes no Docker)**, com suporte cross-platform para **Windows (PowerShell)** e **Linux (Bash)**. A partir dele, o projeto evolui para temas como:

- provisionamento e setup do cluster local;
- deploy de serviços de apoio e bancos de dados;
- observabilidade com métricas, logs, traces e profiling;
- aplicações instrumentadas e preparadas para Kubernetes;
- práticas de segurança, performance e eficiência operacional;
- automação, GitOps e pipelines de CI/CD.

Em outras palavras: observabilidade segue importante, mas agora como parte de uma jornada maior de **desenvolvimento cloud-native moderno**.

---

## O Que Você Vai Encontrar Aqui

| Área | Objetivo |
|------|----------|
| Kubernetes local | Criar um ambiente reproduzível com k3d para desenvolvimento e estudos |
| Infraestrutura base | Instalar ingress, banco de dados, mensageria, secrets manager e serviços de apoio |
| Observabilidade | Coletar métricas, logs, traces e profiles de apps e serviços |
| Aplicações | Desenvolver e evoluir apps preparados para rodar em Kubernetes |
| DevOps | Automatizar build, deploy, validação e operação do ambiente |
| Segurança e eficiência | Aplicar boas práticas de runtime, manifests, imagens e pipelines |

---

## Stack Atual

| Camada | Tecnologia |
|--------|-----------|
| Cluster local | [k3d](https://k3d.io) (Kubernetes in Docker) |
| Ingress | [Traefik](https://traefik.io) |
| Observabilidade | [Prometheus](https://prometheus.io), [Grafana](https://grafana.com), [Loki](https://grafana.com/oss/loki/), [Tempo](https://grafana.com/oss/tempo/), [Pyroscope](https://grafana.com/oss/pyroscope/), [Grafana Alloy](https://grafana.com/oss/alloy/) |
| Bancos de dados | [CloudNativePG](https://cloudnative-pg.io), [Redis](https://github.com/bitnami/charts/tree/main/bitnami/redis), [MongoDB Community Operator](https://github.com/mongodb/mongodb-kubernetes-operator), [RavenDB](https://ravendb.net) |
| Serviços de plataforma | [RabbitMQ](https://www.rabbitmq.com/kubernetes/operator/operator-overview), [HashiCorp Vault](https://developer.hashicorp.com/vault), [ArgoCD](https://argo-cd.readthedocs.io), [SonarQube](https://www.sonarsource.com/products/sonarqube/) |
| Aplicações | ASP.NET, Nuxt, Prisma e instrumentação com OpenTelemetry |
| Automação | Scripts PowerShell e Bash, Helm e workflows de CI/CD em evolução |

---

## Estrutura do Repositório

```text
00.Infraestrutura/   # Cluster local, scripts de setup, serviços e manifests auxiliares
01.Aplicacoes/       # Aplicações de exemplo e experimentos de desenvolvimento cloud-native
.github/             # Instruções do agente, skills, automações e memory bank do projeto
```

Conforme a jornada evolui, o repositório tende a incorporar mais exemplos de aplicação, automação, deploy e operação.

---

## Começo Rápido

O fluxo inicial do projeto continua sendo preparar o laboratório local e instalar os serviços-base em Kubernetes. Execute os scripts em ordem. Eles foram pensados para serem idempotentes, então reexecuções são seguras.

### Windows (PowerShell 7+)

```powershell
.\00.Infraestrutura\windows\01.instalar-dependencias.ps1
.\00.Infraestrutura\windows\02.verificar-instalacoes.ps1
.\00.Infraestrutura\windows\03.criar-cluster-k3d.ps1
```

### Linux (Bash)

```bash
bash 00.Infraestrutura/linux/01.instalar-dependencias.sh
bash 00.Infraestrutura/linux/02.verificar-instalacoes.sh
bash 00.Infraestrutura/linux/03.criar-cluster-k3d.sh
```

Depois disso, você pode instalar os blocos de infraestrutura e plataforma de forma incremental, conforme o tema estudado:

- monitoramento e observabilidade;
- PostgreSQL, Redis, MongoDB e RavenDB;
- RabbitMQ, Vault, ArgoCD e SonarQube;
- aplicações instrumentadas e publicadas no cluster.

---

## Ambiente Base do Cluster

| Configuração | Valor |
|---|---|
| Nome do cluster | `monitoramento` |
| Worker nodes | 2 |
| Registry local | `monitoramento-registry.localhost:5001` |
| Portas expostas | `80`, `443`, `4317`, `4318`, `5432`, `6379`, `27017` |

Esse ambiente serve como base para experimentar deploy, observabilidade, integrações e automação sem depender de cloud pública logo no início.

---

## Observabilidade no Contexto da Jornada

Observabilidade continua sendo um dos pilares do projeto. Hoje, o laboratório já permite subir um stack com:

- **Grafana** para visualização;
- **Prometheus** para métricas;
- **Loki** para logs;
- **Tempo** para traces;
- **Pyroscope** para profiling;
- **Alloy** como collector e roteador de sinais.

Fluxo atual:

```text
Aplicação → OpenTelemetry SDK → Alloy → {Loki, Tempo, Pyroscope} → Grafana
```

Além disso, os serviços de dados podem ser monitorados automaticamente via Prometheus para compor um ambiente mais próximo do que existe em produção.

---

## Serviços de Plataforma

O repositório já inclui automação para subir componentes que fazem parte de uma stack cloud-native moderna:

| Serviço | Papel no ambiente |
|---------|-------------------|
| PostgreSQL | Banco relacional para aplicações e experimentos |
| Redis | Cache, mensageria leve e suporte a cenários de performance |
| MongoDB | Banco orientado a documentos |
| RavenDB | Banco NoSQL/documento com setup para laboratório |
| RabbitMQ | Mensageria assíncrona |
| Vault | Gestão de segredos |
| ArgoCD | GitOps e entrega contínua |
| SonarQube | Qualidade e análise estática de código |

Esses serviços ajudam a mostrar o ciclo completo: desenvolver, empacotar, publicar, observar, operar e melhorar uma aplicação em ambiente Kubernetes.

---

## Pré-requisitos

- Docker Desktop (Windows) ou Docker Engine (Linux)
- 8 GB de RAM disponíveis para o cluster local
- Windows: PowerShell 7+
- Linux: Bash 4+, `curl` e `python3`

---

## Direção do Repositório

Os próximos módulos e evoluções do projeto seguem esta linha:

- aplicações cloud-native instrumentadas e prontas para Kubernetes;
- boas práticas de manifests, imagens e runtime;
- segurança de workloads e da cadeia de entrega;
- performance, profiling e troubleshooting orientado por dados;
- pipelines de CI/CD com GitHub Actions;
- GitOps com ArgoCD;
- arquitetura, automação e operação de serviços de apoio.

O objetivo é transformar o repositório em uma referência prática de **como construir software cloud-native de forma moderna**, e não apenas como instalar ferramentas isoladas.

---

## Licença

[MIT](LICENSE) · Conteúdo produzido por [@luysantanadev](https://www.youtube.com/@luysantanadev)