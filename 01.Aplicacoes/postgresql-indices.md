# Índices no PostgreSQL — Guia Prático

---

## 1. Ambiente de Testes

Antes de qualquer coisa, vamos criar uma base de dados realista para explorar todos os tipos de índice. O objetivo é ter volume suficiente para que as diferenças de performance sejam visíveis e mensuráveis.

### 1.1 Extensões necessárias

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;    -- busca por similaridade
CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid()
```

### 1.2 Criação da tabela

```sql
CREATE TABLE pedidos (
    id          SERIAL PRIMARY KEY,
    uuid        UUID DEFAULT gen_random_uuid(),
    cliente     VARCHAR(100),
    email       VARCHAR(150),
    status      VARCHAR(20),
    valor       NUMERIC(10,2),
    criado_em   TIMESTAMP,
    descricao   TEXT,
    tags        TEXT[],
    metadata    JSONB
);
```

### 1.3 Geração de 5 milhões de registros

O `generate_series()` é a ferramenta nativa do PostgreSQL para isso. O script abaixo leva entre 1 e 3 minutos dependendo do hardware:

```sql
INSERT INTO pedidos (cliente, email, status, valor, criado_em, descricao, tags, metadata)
SELECT
    'Cliente ' || (random() * 100000)::int,

    'user' || (random() * 100000)::int || '@exemplo.com',

    (ARRAY['pendente','aprovado','cancelado','enviado','processando'])
        [ceil(random() * 5)::int],

    round((random() * 9900 + 100)::numeric, 2),

    NOW() - (random() * INTERVAL '3 years'),

    'Pedido referente ao produto '
        || (ARRAY['Notebook','Teclado','Mouse','Monitor','Headset','Webcam','SSD','Memória'])
               [ceil(random() * 8)::int]
        || ' com entrega para a região '
        || (ARRAY['Sul','Norte','Leste','Oeste','Centro'])
               [ceil(random() * 5)::int],

    ARRAY[
        'tag-' || (random() * 100)::int,
        'cat-' || (random() * 50)::int,
        (ARRAY['promocao','estoque','importado','nacional','fragil'])
            [ceil(random() * 5)::int]
    ],

    jsonb_build_object(
        'canal',     (ARRAY['web','app','telefone','loja'])
                         [ceil(random() * 4)::int],
        'parcelas',  ceil(random() * 12)::int,
        'desconto',  round((random() * 30)::numeric, 2),
        'frete',     jsonb_build_object(
                         'tipo',  (ARRAY['PAC','SEDEX','Retirada'])
                                      [ceil(random() * 3)::int],
                         'valor', round((random() * 50)::numeric, 2)
                     )
    )

FROM generate_series(1, 5000000);
```

### 1.4 Verificando o volume gerado

```sql
-- Contagem e tamanho da tabela
SELECT
    COUNT(*)                                          AS total_linhas,
    pg_size_pretty(pg_total_relation_size('pedidos')) AS tamanho_total;

-- Distribuição por status
SELECT status, COUNT(*), round(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM pedidos
GROUP BY status
ORDER BY 2 DESC;
```

### 1.5 Forçar estatísticas atualizadas

Antes de testar, garanta que o planner tem informações precisas sobre a tabela:

```sql
ANALYZE pedidos;
```

---

## 2. Como ler o EXPLAIN ANALYZE

Todas as análises a seguir usam `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)`. Entender a saída é essencial:

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM pedidos WHERE valor = 1500;
```

Os campos mais importantes na saída:

| Campo | O que significa |
|---|---|
| `Seq Scan` | Varredura completa — leu todas as linhas |
| `Index Scan` | Usou o índice para localizar e buscou a linha na tabela |
| `Index Only Scan` | Usou o índice e nem precisou ir à tabela |
| `Bitmap Index Scan` | Usou o índice para montar um mapa de blocos, depois leu os blocos |
| `cost=X..Y` | Estimativa do planner (X = custo para a 1ª linha, Y = custo total) |
| `actual time=X..Y` | Tempo real medido em ms |
| `rows=N` | Linhas retornadas |
| `Buffers: hit=N` | Blocos lidos do cache (RAM) |
| `Buffers: read=N` | Blocos lidos do disco |

**Dica:** execute a mesma query duas vezes. Na primeira, blocos vão do disco para o cache. Na segunda, `hit` domina e o tempo é menor. Para simular cold cache:

```sql
-- No PostgreSQL, para pré-aquecer o cache:
SELECT pg_prewarm('pedidos');

-- Para desabilitar temporariamente o cache de resultados (só análise):
SET enable_material = OFF;
```

---

## 3. Como o PostgreSQL usa índices internamente

### Na leitura (SELECT)

Quando você executa uma query, o **Query Planner** avalia os caminhos disponíveis e escolhe o de menor custo estimado. Os principais fatores são:

- **Seletividade:** quantas linhas a condição retorna? Se for menos de ~5–10% da tabela, um índice tende a ser mais rápido que Seq Scan.
- **Estatísticas:** o planner usa `pg_statistic` (alimentado pelo `ANALYZE`) para estimar cardinalidade. Estatísticas desatualizadas levam a planos ruins.
- **Custo de I/O vs. CPU:** acessar linhas espalhadas em disco via índice tem custo de I/O alto (random reads). Para grandes volumes, às vezes o Seq Scan (leitura sequencial) é mais eficiente.
- **`random_page_cost` e `seq_page_cost`:** parâmetros de configuração que o planner usa para estimar custos. Em SSDs NVMe, vale ajustar para favorecer mais índices.

```sql
-- Ver os custos configurados
SHOW seq_page_cost;
SHOW random_page_cost;

-- Ajuste recomendado para SSD/NVMe (padrão é 4.0)
SET random_page_cost = 1.1;
```

### Na escrita (INSERT / UPDATE / DELETE)

Cada índice na tabela tem um custo nas operações de escrita:

- **INSERT:** para cada linha inserida, todos os índices da tabela precisam ser atualizados. 10 índices = 10 estruturas para manter.
- **UPDATE:** se a coluna indexada muda, o índice antigo precisa ser marcado como inválido (dead tuple) e uma nova entrada inserida.
- **DELETE:** a entrada do índice é marcada como morta. O espaço só é recuperado pelo `VACUUM`.

Por isso, o número de índices é sempre um balanço: mais índices = leituras mais rápidas + escritas mais lentas + mais espaço em disco.

```sql
-- Ver tamanho de cada índice individualmente
SELECT
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS tamanho
FROM pg_indexes
WHERE tablename = 'pedidos'
ORDER BY pg_relation_size(indexname::regclass) DESC;
```

---

## 4. B-Tree

### O que é

É o índice padrão do PostgreSQL. Internamente, organiza os valores em uma árvore balanceada onde cada nó interno divide o espaço de busca ao meio. Para uma tabela de 5 milhões de linhas, encontrar um valor exige atravessar apenas ~23 níveis de árvore (log₂ de 5M ≈ 23), ao invés de ler 5M linhas.

**Quando usar:** igualdade (`=`), ranges (`<`, `>`, `BETWEEN`), ordenação (`ORDER BY`), `LIKE 'prefixo%'` com prefixo fixo.

**Não serve para:** `LIKE '%meio%'`, `ILIKE`, arrays, JSONB, dados geoespaciais.

### Criando o índice

```sql
-- Índice simples em coluna numérica
CREATE INDEX idx_pedidos_valor ON pedidos(valor);

-- Índice em coluna de data
CREATE INDEX idx_pedidos_criado_em ON pedidos(criado_em);

-- Índice em coluna de texto de baixa cardinalidade
CREATE INDEX idx_pedidos_status ON pedidos(status);
```

### Testando — antes e depois

Execute os blocos abaixo **antes** de criar os índices e **depois**. Compare o `actual time` e o tipo de scan:

```sql
-- Teste 1: busca por range de valor
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, cliente, valor
FROM pedidos
WHERE valor BETWEEN 4500 AND 5000;

-- Teste 2: busca por data recente
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, cliente, criado_em
FROM pedidos
WHERE criado_em > NOW() - INTERVAL '30 days';

-- Teste 3: ordenação com LIMIT (Index Scan ou Index Only Scan esperado)
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, valor
FROM pedidos
ORDER BY valor DESC
LIMIT 50;

-- Teste 4: status com baixa cardinalidade (planner pode preferir Seq Scan!)
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) FROM pedidos WHERE status = 'cancelado';
```

### Analisando os resultados

No teste 4 é comum ver o planner **ignorar** o índice em `status`, porque "cancelado" representa ~20% das linhas. Ler 1M de linhas espalhadas pelo disco via índice pode ser mais lento do que uma varredura sequencial contínua. Isso é comportamento correto — não é bug.

Para forçar o teste e confirmar:

```sql
-- Desabilita Seq Scan temporariamente (só para análise!)
SET enable_seqscan = OFF;
EXPLAIN (ANALYZE, BUFFERS) SELECT COUNT(*) FROM pedidos WHERE status = 'cancelado';
SET enable_seqscan = ON;
```

---

## 5. Hash

### O que é

Armazena um hash de 32 bits do valor indexado. A busca é O(1) — vai direto ao balde sem comparações. Não mantém ordem, portanto não serve para ranges ou `ORDER BY`. Está sólido e com suporte a WAL desde o PostgreSQL 10.

**Quando usar:** colunas onde a única operação é `=` e a cardinalidade é alta (UUIDs, hashes, emails, tokens).

**Não serve para:** `<`, `>`, `BETWEEN`, `ORDER BY`, `LIKE`.

### Criando o índice

```sql
CREATE INDEX idx_pedidos_uuid_hash  ON pedidos USING HASH (uuid);
CREATE INDEX idx_pedidos_email_hash ON pedidos USING HASH (email);
```

### Testando

```sql
-- Teste 1: busca por UUID exato
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM pedidos
WHERE uuid = (SELECT uuid FROM pedidos LIMIT 1);

-- Teste 2: comparar com B-Tree na mesma coluna
CREATE INDEX idx_email_btree ON pedidos(email);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM pedidos WHERE email = 'user42000@exemplo.com';

DROP INDEX idx_email_btree;

-- Teste 3: confirmar que Hash NÃO funciona para range
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM pedidos WHERE email > 'user5@exemplo.com'; -- vai usar Seq Scan
```

### Analisando os resultados

No teste 1, o Hash geralmente entrega tempo sub-milissegundo porque vai direto ao bloco. No teste 3, o planner ignora o Hash e faz Seq Scan — comportamento esperado e correto.

---

## 6. GIN (Generalized Inverted Index)

### O que é

O GIN cria uma entrada no índice para **cada elemento** dentro de um campo composto. Imagine uma coluna de tags `['kubernetes', 'devops', 'cloud']` — o GIN indexa `kubernetes`, `devops` e `cloud` separadamente, apontando cada um para as linhas que os contêm. É como o índice remissivo de um livro.

**Quando usar:** `TEXT[]` (arrays), `JSONB`, full-text search (`TSVECTOR`), e `pg_trgm` para buscas por `LIKE '%texto%'` e `ILIKE`.

**Cuidado:** GIN tem custo de inserção mais alto que B-Tree porque pode gerar muitas entradas por linha.

### Criando os índices

```sql
-- Para arrays
CREATE INDEX idx_pedidos_tags_gin ON pedidos USING GIN (tags);

-- Para JSONB (indexa todo o documento)
CREATE INDEX idx_pedidos_metadata_gin ON pedidos USING GIN (metadata);

-- Para pg_trgm (busca por similaridade em texto)
CREATE INDEX idx_pedidos_cliente_trgm ON pedidos USING GIN (cliente gin_trgm_ops);
CREATE INDEX idx_pedidos_descricao_trgm ON pedidos USING GIN (descricao gin_trgm_ops);

-- Para full-text search
ALTER TABLE pedidos ADD COLUMN IF NOT EXISTS search_vector TSVECTOR;
UPDATE pedidos SET search_vector = to_tsvector('portuguese', descricao);
CREATE INDEX idx_pedidos_fts ON pedidos USING GIN (search_vector);
```

### Testando

```sql
-- Teste 1: busca em array — pedidos com tag específica
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, cliente, tags
FROM pedidos
WHERE tags @> ARRAY['promocao'];

-- Teste 2: busca em array — pelo menos uma das tags
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, cliente, tags
FROM pedidos
WHERE tags && ARRAY['promocao', 'fragil'];

-- Teste 3: busca em JSONB por canal de venda
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, cliente, metadata
FROM pedidos
WHERE metadata @> '{"canal": "app"}';

-- Teste 4: busca por campo aninhado no JSONB
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, metadata
FROM pedidos
WHERE metadata -> 'frete' @> '{"tipo": "SEDEX"}';

-- Teste 5: pg_trgm — LIKE com wildcard nos dois lados (impossível sem pg_trgm)
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, cliente
FROM pedidos
WHERE cliente ILIKE '%liente 423%';

-- Teste 6: similaridade de texto
SELECT id, cliente, similarity(cliente, 'Cliente 4230') AS score
FROM pedidos
WHERE cliente % 'Cliente 4230'
ORDER BY score DESC
LIMIT 10;

-- Teste 7: full-text search com ranking
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, descricao, ts_rank(search_vector, query) AS rank
FROM pedidos, to_tsquery('portuguese', 'Notebook & Sul') query
WHERE search_vector @@ query
ORDER BY rank DESC
LIMIT 20;
```

### Analisando os resultados

No teste 5, sem o índice `pg_trgm` o PostgreSQL faz `Seq Scan` com `Filter` em todas as 5M linhas. Com o índice GIN, ele usa `Bitmap Index Scan`, que monta um mapa dos blocos relevantes antes de acessar a tabela — geralmente 10x a 100x mais rápido.

```sql
-- Ver o threshold de similaridade do pg_trgm
SHOW pg_trgm.similarity_threshold; -- padrão: 0.3

-- Ajustar para buscas mais restritivas
SET pg_trgm.similarity_threshold = 0.5;
```

---

## 7. GiST (Generalized Search Tree)

### O que é

Uma estrutura de árvore extensível que suporta tipos de dados complexos. Ao contrário do GIN, o GiST é **lossy** — pode retornar falsos positivos, e o PostgreSQL refaz a verificação automaticamente (recheck). Em compensação, ocupa menos espaço em disco e tem inserção mais rápida que o GIN.

**Quando usar:** ranges de valores (`tsrange`, `numrange`, `daterange`), dados geoespaciais com PostGIS, e como alternativa ao GIN para `pg_trgm` quando o espaço é crítico.

**Quando preferir GIN:** quando a velocidade de leitura é mais importante que espaço em disco e velocidade de inserção.

### Criando os índices

```sql
-- Adicionar coluna de range de datas (simula períodos de vigência)
ALTER TABLE pedidos ADD COLUMN IF NOT EXISTS periodo tsrange;

UPDATE pedidos
SET periodo = tsrange(criado_em, criado_em + (random() * INTERVAL '90 days'));

-- Índice GiST para range
CREATE INDEX idx_pedidos_periodo_gist ON pedidos USING GiST (periodo);

-- Índice GiST para pg_trgm (alternativa ao GIN)
CREATE INDEX idx_pedidos_cliente_gist ON pedidos USING GiST (cliente gist_trgm_ops);
```

### Testando

```sql
-- Teste 1: pedidos cujo período contém uma data específica
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, cliente, periodo
FROM pedidos
WHERE periodo @> '2024-06-15 00:00:00'::timestamp;

-- Teste 2: períodos que se sobrepõem a um intervalo
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, cliente, periodo
FROM pedidos
WHERE periodo && tsrange('2024-01-01', '2024-03-31');

-- Teste 3: comparar GiST vs GIN para pg_trgm no mesmo campo
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, cliente FROM pedidos WHERE cliente ILIKE '%liente 5%';
```

### Comparando GiST vs GIN para pg_trgm

```sql
SELECT
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS tamanho
FROM pg_indexes
WHERE tablename = 'pedidos'
  AND indexname IN ('idx_pedidos_cliente_trgm', 'idx_pedidos_cliente_gist');
```

Regra geral: GiST ocupa ~30–50% menos espaço que GIN para `pg_trgm`, mas pode ser mais lento em leituras intensas. Para tabelas com muitas escritas e leituras ocasionais, prefira GiST. Para tabelas predominantemente de leitura, prefira GIN.

---

## 8. BRIN (Block Range INdex)

### O que é

O menor índice possível. Em vez de indexar cada linha, o BRIN armazena apenas o **valor mínimo e máximo** de cada intervalo de blocos físicos (por padrão, 128 blocos = ~1MB de dados). A busca descarta os blocos cujo range não intersecta com o filtro, sem precisar inspecionar cada linha.

**Funciona bem quando:** os dados têm correlação natural com a ordem física — ou seja, foram inseridos em ordem crescente (timestamps de logs, IDs sequenciais, particionamentos por data).

**Não funciona bem quando:** os dados são inseridos de forma aleatória, porque os valores mínimo e máximo de cada bloco vão se sobrepor e o índice perde utilidade.

**Vantagem:** ocupa apenas alguns KB mesmo em tabelas de bilhões de linhas.

### Verificando a correlação antes de criar

```sql
-- Correlação entre a ordem física e o valor da coluna.
-- Valores próximos de 1.0 ou -1.0: boa correlação (BRIN eficiente).
-- Valores próximos de 0.0: correlação ruim (BRIN ineficiente).
SELECT attname, correlation
FROM pg_stats
WHERE tablename = 'pedidos'
  AND attname IN ('id', 'criado_em', 'valor', 'status');
```

### Criando o índice

```sql
-- BRIN em timestamp (inserido aproximadamente em ordem — boa correlação)
CREATE INDEX idx_pedidos_brin_data ON pedidos USING BRIN (criado_em)
    WITH (pages_per_range = 64);  -- quanto menor, mais preciso e maior o índice

-- BRIN em ID serial (correlação perfeita = 1.0)
CREATE INDEX idx_pedidos_brin_id ON pedidos USING BRIN (id);
```

### Testando

```sql
-- Teste 1: range de datas
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) FROM pedidos
WHERE criado_em BETWEEN '2024-01-01' AND '2024-03-31';

-- Teste 2: comparar tamanho BRIN vs B-Tree
SELECT
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS tamanho
FROM pg_indexes
WHERE tablename = 'pedidos'
  AND indexname IN ('idx_pedidos_brin_data', 'idx_pedidos_criado_em');

-- Teste 3: BRIN com pages_per_range menor (mais preciso, maior)
CREATE INDEX idx_pedidos_brin_fino ON pedidos USING BRIN (criado_em)
    WITH (pages_per_range = 16);

EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) FROM pedidos
WHERE criado_em BETWEEN '2024-06-01' AND '2024-06-30';
```

### Analisando os resultados

O BRIN costuma ser 100x a 1000x menor que um B-Tree equivalente. A velocidade de leitura fica entre o Seq Scan e o B-Tree — mas para tabelas de dezenas de GB onde um B-Tree seria impraticável de manter, o BRIN é muitas vezes a única opção viável.

---

## 9. Índice Parcial

### O que é

Um modificador que restringe quais linhas são incluídas no índice através de uma cláusula `WHERE`. O resultado é um índice menor, mais rápido de construir, manter e usar — mas que só funciona para queries que satisfaçam a condição do índice.

**Quando usar:** quando uma consulta frequente filtra sempre pelo mesmo subconjunto (status fixo, registros não processados, últimos N dias, valor alto, etc.).

### Criando os índices

```sql
-- Só pedidos pendentes (subconjunto ativo e consultado com frequência)
CREATE INDEX idx_pedidos_pendentes ON pedidos(criado_em)
    WHERE status = 'pendente';

-- Pedidos de alto valor aprovados
CREATE INDEX idx_pedidos_alto_valor ON pedidos(valor DESC)
    WHERE status = 'aprovado' AND valor > 5000;

-- Pedidos recentes (simula uma "janela quente")
CREATE INDEX idx_pedidos_recentes ON pedidos(criado_em DESC, valor)
    WHERE criado_em > '2024-06-01';
```

### Testando

```sql
-- Teste 1: usa o índice parcial (condição idêntica ao WHERE do índice)
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, cliente, criado_em
FROM pedidos
WHERE status = 'pendente'
  AND criado_em > NOW() - INTERVAL '60 days';

-- Teste 2: NÃO usa o índice parcial (condição diferente)
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, cliente, criado_em
FROM pedidos
WHERE status = 'aprovado'       -- diferente do índice de pendentes
  AND criado_em > NOW() - INTERVAL '60 days';

-- Teste 3: pedidos de alto valor aprovados
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, cliente, valor
FROM pedidos
WHERE status = 'aprovado' AND valor > 7000;

-- Comparar tamanho: parcial vs. índice completo
SELECT
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS tamanho
FROM pg_indexes
WHERE tablename = 'pedidos'
  AND indexname IN ('idx_pedidos_status', 'idx_pedidos_pendentes');
```

### Analisando os resultados

O índice parcial costuma ser 3x a 10x menor que o índice completo equivalente (proporcional ao percentual de linhas que satisfazem a condição). Para o planner, um índice menor significa menos I/O e estimativas mais precisas — ele tende a preferir índices parciais quando aplicáveis.

---

## 10. Índice Composto

### O que é

Um índice que cobre múltiplas colunas em uma única estrutura B-Tree. O planner pode usar o índice para o prefixo das colunas (da esquerda para a direita), mas não para colunas do meio ou do final sem as anteriores.

**Regra de ouro:** coloque primeiro a coluna com maior seletividade (mais valores distintos), e pense na ordem de acesso das suas queries.

**Quando usar:** queries que filtram por múltiplas colunas juntas com frequência; queries que filtram por um campo e ordenam por outro.

### Criando os índices

```sql
-- Composto: status + valor (filtro por status, range por valor)
CREATE INDEX idx_pedidos_status_valor ON pedidos(status, valor DESC);

-- Composto: status + data (filtro por status, range por data)
CREATE INDEX idx_pedidos_status_data  ON pedidos(status, criado_em DESC);

-- Covering index: inclui colunas extras que a query precisa mas não filtra,
-- permitindo Index Only Scan (sem acessar a tabela)
CREATE INDEX idx_pedidos_cover ON pedidos(status, criado_em DESC)
    INCLUDE (cliente, valor);
```

### Testando

```sql
-- Teste 1: usa o índice composto (ambas as colunas)
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, cliente, valor
FROM pedidos
WHERE status = 'aprovado' AND valor BETWEEN 3000 AND 6000;

-- Teste 2: usa só o prefixo do índice (primeira coluna)
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, cliente
FROM pedidos
WHERE status = 'enviado'
ORDER BY valor DESC
LIMIT 100;

-- Teste 3: NÃO usa o índice composto (segunda coluna sem a primeira)
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, cliente
FROM pedidos
WHERE valor > 8000;  -- sem filtro por status

-- Teste 4: covering index — Index Only Scan (não acessa a tabela)
EXPLAIN (ANALYZE, BUFFERS)
SELECT cliente, valor
FROM pedidos
WHERE status = 'aprovado'
  AND criado_em > '2024-01-01'
ORDER BY criado_em DESC
LIMIT 50;
```

### Analisando os resultados

No teste 4, procure por `Index Only Scan` na saída. Isso significa que todos os dados necessários estavam no próprio índice — o PostgreSQL não precisou acessar a tabela. É o cenário de melhor performance possível para leitura.

```sql
-- Se heap_fetches for alto no Index Only Scan, rode VACUUM para atualizar o Visibility Map
VACUUM ANALYZE pedidos;
```

---

## 11. PostgreSQL como banco NoSQL

O PostgreSQL suporta workloads NoSQL nativamente, sem precisar de um banco separado. Isso elimina a complexidade de manter dois sistemas, duas sincronizações e duas operações.

### 11.1 JSONB

O tipo `JSONB` armazena JSON em formato binário, indexável e consultável com operadores nativos.

```sql
-- Busca por canal de venda
SELECT id, cliente, metadata->>'canal' AS canal
FROM pedidos
WHERE metadata @> '{"canal": "app"}';

-- Busca por campo aninhado
SELECT id, metadata->'frete'->>'tipo' AS tipo_frete
FROM pedidos
WHERE metadata->'frete' @> '{"tipo": "SEDEX"}';

-- Filtro numérico dentro do JSON
SELECT id, cliente, (metadata->>'parcelas')::int AS parcelas
FROM pedidos
WHERE (metadata->>'parcelas')::int >= 10;

-- Indexar campo específico dentro do JSON para buscas numéricas
CREATE INDEX idx_parcelas ON pedidos ((metadata->>'parcelas')::int);

EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM pedidos WHERE (metadata->>'parcelas')::int = 12;
```

### 11.2 Arrays nativos

```sql
-- Pedidos com a tag 'promocao'
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, cliente, tags
FROM pedidos
WHERE tags @> ARRAY['promocao'];

-- Pedidos com pelo menos uma das tags
SELECT id, cliente, tags
FROM pedidos
WHERE tags && ARRAY['promocao', 'fragil']
LIMIT 20;

-- Pedidos sem nenhuma dessas tags
SELECT id, cliente
FROM pedidos
WHERE NOT (tags && ARRAY['fragil', 'importado'])
LIMIT 20;
```

### 11.3 Full-Text Search

```sql
-- Busca simples
SELECT id, descricao, ts_rank(search_vector, query) AS relevancia
FROM pedidos, to_tsquery('portuguese', 'Notebook') query
WHERE search_vector @@ query
ORDER BY relevancia DESC
LIMIT 10;

-- Busca com múltiplos termos (AND)
SELECT id, descricao
FROM pedidos
WHERE search_vector @@ to_tsquery('portuguese', 'Monitor & Sul')
LIMIT 10;

-- Busca com alternativas (OR)
SELECT id, descricao
FROM pedidos
WHERE search_vector @@ to_tsquery('portuguese', 'Teclado | Mouse')
LIMIT 10;

-- Busca com destaque dos termos encontrados
SELECT
    id,
    ts_headline('portuguese', descricao,
        to_tsquery('portuguese', 'Notebook'),
        'MaxWords=15, MinWords=5'
    ) AS trecho
FROM pedidos
WHERE search_vector @@ to_tsquery('portuguese', 'Notebook')
LIMIT 5;
```

### 11.4 Quando usar cada abordagem NoSQL

| Cenário | Recomendação |
|---|---|
| Schema fixo e bem definido | Colunas relacionais normais |
| Schema variável por registro | JSONB |
| Múltiplos valores por campo | Arrays |
| Busca por substring ou similaridade | `pg_trgm` + GIN |
| Busca textual avançada com relevância | Full-Text Search |
| Substituir MongoDB | JSONB + GIN |
| Substituir Elasticsearch (casos simples) | FTS + `pg_trgm` |

---

## 12. Planejamento de Índices — Como Pensar

### Índices simples

Crie um índice simples quando:

- A coluna aparece frequentemente no `WHERE` sozinha
- A seletividade é alta (poucos resultados por busca) — regra prática: menos de 5–10% das linhas
- A coluna é usada em `ORDER BY` + `LIMIT` (evita sort em memória)
- A coluna tem alta cardinalidade (muitos valores distintos)

```sql
-- Verificar cardinalidade e seletividade antes de criar
SELECT
    attname,
    n_distinct,
    correlation,
    most_common_vals,
    most_common_freqs
FROM pg_stats
WHERE tablename = 'pedidos'
ORDER BY attname;
```

Evite índice simples quando a coluna tem poucos valores distintos (`status`, booleanos) e a query retorna muitas linhas — o planner vai preferir Seq Scan mesmo com índice.

### Índices compostos

Use um índice composto quando:

- Duas ou mais colunas aparecem juntas no `WHERE` com frequência
- Uma coluna filtra por igualdade e outra ordena — coloque a de igualdade primeiro
- Quer evitar acessar a tabela incluindo colunas extras com `INCLUDE`

```sql
-- Padrão mais comum: igualdade + range + ordenação
-- Query: WHERE status = 'X' AND criado_em > Y ORDER BY criado_em DESC
CREATE INDEX idx_exemplo ON pedidos(status, criado_em DESC);

-- Covering index: tudo que a query precisa está no índice
-- Query: SELECT cliente, valor FROM pedidos WHERE status = 'X' AND criado_em > Y
CREATE INDEX idx_cover ON pedidos(status, criado_em DESC) INCLUDE (cliente, valor);
```

### Detectando índices não utilizados

Após rodar a aplicação em produção por algum tempo, verifique índices que nunca foram usados:

```sql
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan          AS vezes_usado,
    idx_tup_read      AS linhas_lidas_via_indice,
    pg_size_pretty(pg_relation_size(indexrelid)) AS tamanho
FROM pg_stat_user_indexes
WHERE tablename = 'pedidos'
ORDER BY idx_scan ASC;
```

Índices com `idx_scan = 0` após semanas de uso são candidatos a remoção — estão consumindo espaço e atrasando escritas sem nenhum benefício.

### Detectando queries sem índice (queries lentas)

```sql
-- Requer: shared_preload_libraries = 'pg_stat_statements' no postgresql.conf
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

SELECT
    query,
    calls,
    round(total_exec_time::numeric / calls, 2) AS avg_ms,
    round(total_exec_time::numeric, 2)         AS total_ms,
    rows / calls                               AS avg_rows
FROM pg_stat_statements
WHERE query ILIKE '%pedidos%'
ORDER BY avg_ms DESC
LIMIT 10;
```

### Resumo — matriz de decisão

| Situação | Índice recomendado |
|---|---|
| `WHERE col = valor` (alta cardinalidade) | B-Tree simples |
| `WHERE col = valor` (UUID, hash, token) | Hash |
| `WHERE col BETWEEN x AND y` | B-Tree simples |
| `WHERE col LIKE '%texto%'` | GIN + pg_trgm |
| `WHERE array_col @> ARRAY[...]` | GIN |
| `WHERE jsonb_col @> '{...}'` | GIN |
| `WHERE tsrange_col @> timestamp` | GiST |
| `WHERE fts_col @@ to_tsquery(...)` | GIN (tsvector) |
| Tabela enorme, timestamp sequencial | BRIN |
| Subconjunto fixo consultado com frequência | Parcial |
| `WHERE col1 = x AND col2 > y` | Composto (col1, col2) |
| `SELECT a, b WHERE col1 = x` sem heap fetch | Composto com INCLUDE |
