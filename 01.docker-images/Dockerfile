# ==============================================================================
# Imagem: workshop-nginx
# Serve um site estatico (index.html + index.css + index.js) via nginx na
# porta 8080, rodando como usuario nao-root.
# ==============================================================================

# ------------------------------------------------------------------------------
# Layer 1 - Base image
# nginxinc/nginx-unprivileged e a variante oficial com seguranca por padrao:
#   - Processo ja roda como UID 101 (nginx), sem root
#   - Escuta na porta 8080 (nao-privilegiada) por padrao
#   - /var/cache/nginx, /var/log/nginx e /tmp ja tem permissoes corretas
# Isso elimina a necessidade de RUN chown e USER no Dockerfile.
# ------------------------------------------------------------------------------
FROM nginxinc/nginx-unprivileged:1.29-alpine3.23-perl

# ------------------------------------------------------------------------------
# Layer 2 - Configuracao do nginx
# Substitui o nginx.conf padrao pelo nosso, que aponta a root para
# /usr/share/nginx/html e redireciona arquivos temporarios para /tmp.
# Compativel com a execucao como usuario nao-root sem alteracoes adicionais.
# ------------------------------------------------------------------------------
COPY nginx.conf /etc/nginx/nginx.conf

# ------------------------------------------------------------------------------
# Layer 3 - Arquivos do site
# Copia os tres arquivos estaticos diretamente para o diretorio servido pelo
# nginx. Um unico COPY e mais eficiente pois gera apenas uma layer de diff.
# ------------------------------------------------------------------------------
COPY index.html index.css index.js /usr/share/nginx/html/

# ------------------------------------------------------------------------------
# Metadados
# EXPOSE documenta a porta utilizada; nao publica a porta automaticamente.
# ------------------------------------------------------------------------------
EXPOSE 8080

# ------------------------------------------------------------------------------
# Layer 4 - Comando de inicializacao
# Forma exec (array) garante que o nginx receba os sinais do sistema (SIGTERM)
# corretamente durante graceful shutdown do container.
# ------------------------------------------------------------------------------
CMD ["nginx", "-g", "daemon off;"]
