# ==============================================================================
# Build da imagem
# ==============================================================================
docker build -t workshop-envs:0.1.0 .

# ==============================================================================
# Exemplo 1 — valores padrão (definidos no Dockerfile via ENV)
# Acesse: http://localhost:3001
# Demonstra: o container funciona sem nenhum -e; os defaults do ENV aparecem.
# ==============================================================================
docker run --rm -p 3001:3000 `
    --name envs-default `
    workshop-envs:0.1.0

# ==============================================================================
# Exemplo 2 — ambiente de desenvolvimento com banco configurado
# Acesse: http://localhost:3002
# Demonstra: -e individual para cada variável; DB_PASS mascarado na UI.
# ==============================================================================
docker run --rm -p 3002:3000 `
    --name envs-dev `
    -e APP_NAME="minha-api" `
    -e APP_ENV="development" `
    -e APP_MESSAGE="Rodando em DEV — não usar em produção!" `
    -e DB_HOST="postgres-dev:5432" `
    -e DB_USER="dev_user" `
    -e DB_PASS="dev_secret" `
    workshop-envs:0.1.0

# ==============================================================================
# Exemplo 3 — ambiente de produção na porta 8080
# Acesse: http://localhost:8080
# Demonstra: APP_ENV=production e porta interna alterada via PORT.
# ==============================================================================
docker run --rm -p 8080:8080 `
    --name envs-prod `
    -e PORT=8080 `
    -e APP_NAME="minha-api" `
    -e APP_ENV="production" `
    -e APP_MESSAGE="Bem-vindo à produção!" `
    -e DB_HOST="postgres-prod:5432" `
    -e DB_USER="prod_user" `
    -e DB_PASS="prod_s3cr3t_muito_seguro" `
    workshop-envs:0.1.0

# ==============================================================================
# Exemplo 4 — usando arquivo .env (simula ConfigMap + Secret do Kubernetes)
# Acesse: http://localhost:3004
# Demonstra: --env-file agrupa todas as variáveis em um único arquivo externo,
#            o equivalente mais próximo de um ConfigMap/Secret no docker run.
# ==============================================================================
docker run --rm -p 3004:3000 `
    --name envs-envfile `
    --env-file .env.example `
    workshop-envs:0.1.0

# ==============================================================================
# Exemplo 5 — duas instâncias simultâneas em portas diferentes
# Acesse instância A: http://localhost:3010
# Acesse instância B: http://localhost:3011
# Demonstra: mesma imagem, configurações distintas, isolamento por container.
# ==============================================================================
docker run --rm -d -p 3010:3000 `
    --name envs-instancia-a `
    -e APP_NAME="instancia-A" `
    -e APP_ENV="staging" `
    -e APP_MESSAGE="Você acessou a instância A" `
    workshop-envs:0.1.0

docker run --rm -d -p 3011:3000 `
    --name envs-instancia-b `
    -e APP_NAME="instancia-B" `
    -e APP_ENV="staging" `
    -e APP_MESSAGE="Você acessou a instância B" `
    workshop-envs:0.1.0

