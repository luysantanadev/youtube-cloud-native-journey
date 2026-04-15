# ==============================================================================
# ROTEIRO DE EXPLORAÇÃO — kubectl
# ==============================================================================
# Este arquivo é um roteiro de estudo.
# Copie um comando por vez e cole no terminal para executar.
# Pré-requisito: cluster workshop rodando + aplicação deployada.
# ==============================================================================


# ==============================================================================
# 1. CONTEXTO E CLUSTER
# ==============================================================================

# Ver todos os contextos disponíveis no kubeconfig
kubectl config get-contexts

# Ver qual contexto está ativo agora
kubectl config current-context

# Trocar para o contexto do workshop
kubectl config use-context k3d-workshop

# Informações gerais do cluster (API server, CoreDNS, etc.)
kubectl cluster-info

# Versão do cliente kubectl e do servidor Kubernetes
kubectl version

# Ver todos os tipos de recursos disponíveis no cluster
kubectl api-resources

# Filtrar recursos por categoria
kubectl api-resources --categories=workloads


# ==============================================================================
# 2. NODES
# ==============================================================================

# Listar todos os nodes do cluster
kubectl get nodes

# Listar nodes com IPs, roles e versão do OS
kubectl get nodes -o wide

# Ver capacidade e recursos alocados em um node
kubectl describe node k3d-workshop-agent-0

# Ver consumo real de CPU e memória por node (requer metrics-server)
kubectl top nodes

# Ver os labels aplicados nos nodes
kubectl get nodes --show-labels


# ==============================================================================
# 3. NAMESPACES
# ==============================================================================

# Listar todos os namespaces
kubectl get namespaces

# Criar um namespace para testes
kubectl create namespace workshop-teste

# Definir o namespace padrão da sessão (evita digitar -n toda hora)
kubectl config set-context --current --namespace=default

# Listar todos os recursos de todos os namespaces de uma vez
kubectl get all --all-namespaces

# Forma curta: -A equivale a --all-namespaces
kubectl get pods -A


# ==============================================================================
# 4. PODS
# ==============================================================================

# Listar todos os Pods do namespace default
kubectl get pods

# Listar Pods com IP, node e status detalhado
kubectl get pods -o wide

# Listar Pods de um namespace específico
kubectl get pods -n kube-system

# Filtrar Pods por label
kubectl get pods -l app=nuxt-workshop

# Ver detalhes completos de um Pod (eventos, volumes, probes, etc.)
kubectl describe pod -l app=nuxt-workshop

# Ver o YAML completo de um Pod gerado pelo cluster
kubectl get pod -l app=nuxt-workshop -o yaml

# Saída em formato JSON
kubectl get pod -l app=nuxt-workshop -o json

# Extrair apenas o IP do Pod com JSONPath
kubectl get pod -l app=nuxt-workshop -o jsonpath="{.items[0].status.podIP}"

# Acompanhar o ciclo de vida dos Pods em tempo real (Ctrl+C para sair)
kubectl get pods -w

# Forçar a exclusão de um Pod — o Deployment recria automaticamente
kubectl delete pod -l app=nuxt-workshop


# ==============================================================================
# 5. DEPLOYMENTS
# ==============================================================================

# Listar todos os Deployments
kubectl get deployments

# Listar Deployments com número de réplicas e imagem
kubectl get deployments -o wide

# Ver detalhes de um Deployment
kubectl describe deployment workshop-deployment-completo

# Ver o YAML do Deployment
kubectl get deployment workshop-deployment-completo -o yaml

# Escalar o Deployment para 3 réplicas
kubectl scale deployment workshop-deployment-completo --replicas=3

# Voltar para 2 réplicas
kubectl scale deployment workshop-deployment-completo --replicas=2

# Atualizar a imagem do container
kubectl set image deployment/workshop-deployment-completo nuxt-workshop=workshop-registry.localhost:5001/nuxt-workshop:1.0.1

# Anotar a causa da mudança para aparecer no histórico de rollout
kubectl annotate deployment workshop-deployment-completo kubernetes.io/change-cause="atualiza para versao 1.0.1" --overwrite


# ==============================================================================
# 6. REPLICASETS
# ==============================================================================

# Listar ReplicaSets (criados automaticamente pelo Deployment)
kubectl get replicasets

# Ver detalhes dos ReplicaSets do Deployment
kubectl describe replicaset -l app=nuxt-workshop

# Observação: o Kubernetes mantém ReplicaSets antigos (com 0 réplicas)
# para permitir rollback. Cada update do Deployment cria um novo RS.


# ==============================================================================
# 7. SERVICES E ENDPOINTS
# ==============================================================================

# Listar todos os Services
kubectl get services

# Listar Services com IP do cluster e portas
kubectl get services -o wide

# Ver detalhes de um Service (selector, endpoints, etc.)
kubectl describe service workshop-app-service

# Ver os Endpoints — IPs reais dos Pods que o Service está roteando
kubectl get endpoints workshop-app-service

# Verificar se o selector do Service bate com os labels dos Pods
kubectl get pods -l app=nuxt-workshop --show-labels


# ==============================================================================
# 8. CONFIGMAPS E SECRETS
# ==============================================================================

# Listar todos os ConfigMaps
kubectl get configmaps

# Ver o conteúdo de um ConfigMap
kubectl describe configmap workshop-app-config

# Ver o YAML completo do ConfigMap
kubectl get configmap workshop-app-config -o yaml

# Listar todos os Secrets
kubectl get secrets

# Ver os campos de um Secret (valores ficam ocultos por padrão)
kubectl describe secret workshop-app-secret

# Decodificar o valor de um Secret em base64
[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($(kubectl get secret workshop-app-secret -o jsonpath="{.data.DATABASE_URL}")))

# Criar um ConfigMap direto pelo terminal (sem YAML)
kubectl create configmap workshop-teste-cm --from-literal=CHAVE=valor --from-literal=OUTRA=coisa

# Criar um Secret direto pelo terminal (sem YAML)
kubectl create secret generic workshop-teste-secret --from-literal=senha=super-secreta


# ==============================================================================
# 9. LOGS E EVENTOS
# ==============================================================================

# Ver logs dos Pods com o label app=nuxt-workshop
kubectl logs -l app=nuxt-workshop

# Acompanhar logs em tempo real (Ctrl+C para sair)
kubectl logs -l app=nuxt-workshop -f

# Ver as últimas 50 linhas de log
kubectl logs -l app=nuxt-workshop --tail=50

# Ver logs das últimas 5 minutos
kubectl logs -l app=nuxt-workshop --since=5m

# Ver logs de um container específico (útil em Pods com múltiplos containers)
kubectl logs -l app=nuxt-workshop -c nuxt-workshop

# Pegar o nome do primeiro Pod (necessário para --previous)
$POD = kubectl get pod -l app=nuxt-workshop -o jsonpath="{.items[0].metadata.name}"

# Ver logs de um Pod que já crashou (container da execução anterior)
kubectl logs $POD --previous

# Ver eventos do namespace ordenados por tempo (erros de scheduling, pull, etc.)
kubectl get events --sort-by=".lastTimestamp"

# Filtrar apenas eventos de Warning
kubectl get events --field-selector type=Warning


# ==============================================================================
# 10. EXECUÇÃO DENTRO DE CONTAINERS
# ==============================================================================

# Pegar o nome do primeiro Pod (necessário para exec)
$POD = kubectl get pod -l app=nuxt-workshop -o jsonpath="{.items[0].metadata.name}"

# Abrir um shell interativo dentro do Pod (digite 'exit' para sair)
kubectl exec -it $POD -- sh

# Executar um comando único sem abrir shell
kubectl exec $POD -- env

# Verificar a resolução DNS de um Service de dentro do cluster
kubectl exec $POD -- nslookup workshop-app-service

# Testar conectividade HTTP de dentro do Pod
kubectl exec $POD -- wget -qO- http://workshop-app-service

# Dica: use -c <nome> para especificar o container em Pods com múltiplos containers
# kubectl exec -it $POD -c sidecar -- sh


# ==============================================================================
# 11. PORT-FORWARD
# ==============================================================================

# Abrir túnel para um Service (acesse http://localhost:8080 no browser)
kubectl port-forward service/workshop-app-service 8080:80

# Abrir túnel em background (PowerShell Job)
Start-Job { kubectl port-forward service/workshop-app-service 8080:80 }

# Ver jobs em background
Get-Job

# Encerrar todos os jobs de port-forward
Get-Job | Stop-Job; Get-Job | Remove-Job


# ==============================================================================
# 12. EDITAR E MODIFICAR RECURSOS
# ==============================================================================

# Editar um recurso diretamente no editor padrão
kubectl edit deployment workshop-deployment-completo

# Aplicar um patch de réplicas via JSON
kubectl patch deployment workshop-deployment-completo --type=merge -p '{"spec":{"replicas":3}}'

# Adicionar um label a todos os Pods com o selector
kubectl label pod -l app=nuxt-workshop ambiente=workshop

# Remover um label de todos os Pods (sufixo - remove o label)
kubectl label pod -l app=nuxt-workshop ambiente-

# Adicionar uma anotação a um Deployment
kubectl annotate deployment workshop-deployment-completo descricao="app principal do workshop" --overwrite

# Ver os labels atuais de todos os Pods
kubectl get pods --show-labels

# Forçar um novo rollout sem mudar imagem (útil para recarregar ConfigMap/Secret)
kubectl rollout restart deployment/workshop-deployment-completo


# ==============================================================================
# 13. ROLLOUT E ROLLBACK
# ==============================================================================

# Ver o status do rollout em andamento
kubectl rollout status deployment/workshop-deployment-completo

# Ver histórico de revisões do Deployment
kubectl rollout history deployment/workshop-deployment-completo

# Ver detalhes de uma revisão específica
kubectl rollout history deployment/workshop-deployment-completo --revision=2

# Fazer rollback para a revisão anterior
kubectl rollout undo deployment/workshop-deployment-completo

# Fazer rollback para uma revisão específica
kubectl rollout undo deployment/workshop-deployment-completo --to-revision=1

# Pausar um rollout em andamento
kubectl rollout pause deployment/workshop-deployment-completo

# Retomar um rollout pausado
kubectl rollout resume deployment/workshop-deployment-completo


# ==============================================================================
# 14. LIMPEZA
# ==============================================================================

# Deletar todos os Pods com o label (o Deployment recria automaticamente)
kubectl delete pod -l app=nuxt-workshop

# Deletar todos os recursos declarados em um arquivo YAML
kubectl delete -f 04.fundamentos-kubernetes/05-deployment-completo.yaml

# Deletar todos os recursos com um label específico
kubectl delete all -l app=nuxt-workshop

# Deletar um namespace inteiro (remove tudo dentro dele)
kubectl delete namespace workshop-teste

# Deletar o release Helm (remove todos os recursos gerenciados pelo chart)
helm uninstall nuxt-workshop

# Deletar o cluster k3d inteiro (ambiente zerado)
k3d cluster delete workshop
