# ==============================================================================
# Imagem: workshop-envs
# Servidor HTTP Node.js que lê variáveis de ambiente e as exibe em uma página
# HTML — ideal para demonstrar ENV, -e, ConfigMap e Secret no Kubernetes.
# Porta padrão: 3000 (controlada pela variável PORT).
# ==============================================================================

# ------------------------------------------------------------------------------
# Base image
# node:22-alpine é pequena (~60 MB), usa Node LTS e já inclui o usuário "node"
# (UID 1000) sem permissões root, dispensando um RUN useradd dedicado.
# ------------------------------------------------------------------------------
FROM node:22-alpine

# ------------------------------------------------------------------------------
# Variáveis de ambiente padrão
# Definir defaults aqui documenta todas as variáveis suportadas pela aplicação
# e garante que o container funcione sem nenhum -e passado explicitamente.
# Qualquer valor pode ser sobrescrito em runtime sem recriar a imagem.
# ------------------------------------------------------------------------------
ENV PORT=3000 \
    APP_NAME="workshop-app" \
    APP_ENV="development" \
    APP_MESSAGE="Olá do container!" \
    DB_HOST="" \
    DB_USER="" \
    DB_PASS=""

# ------------------------------------------------------------------------------
# Diretório de trabalho
# Centraliza todos os arquivos da aplicação em /app, evitando que acabem na
# raiz do filesystem do container.
# ------------------------------------------------------------------------------
WORKDIR /app

# ------------------------------------------------------------------------------
# Código-fonte
# Copiamos os quatro arquivos da aplicação de forma explícita:
#   server.js  — lógica do servidor e endpoint /api/env
#   index.html — estrutura da página
#   style.css  — estilos separados do HTML
#   client.js  — script do browser que faz fetch em /api/env
# Não há package.json porque a aplicação usa apenas módulos nativos do Node.
# ------------------------------------------------------------------------------
COPY server.js index.html style.css client.js .

# ------------------------------------------------------------------------------
# Privilégios
# Troca para o usuário "node" (UID 1000) antes de iniciar o processo.
# Rodar como não-root minimiza o impacto de uma eventual vulnerabilidade
# na aplicação ou no runtime.
# ------------------------------------------------------------------------------
USER node

# Documenta a porta; não publica automaticamente — use -p no docker run.
EXPOSE 3000

# ------------------------------------------------------------------------------
# Entrypoint
# Forma exec (array JSON) garante que o processo Node receba sinais do kernel
# diretamente (SIGTERM durante graceful shutdown), sem intermediário shell.
# ------------------------------------------------------------------------------
CMD ["node", "server.js"]
