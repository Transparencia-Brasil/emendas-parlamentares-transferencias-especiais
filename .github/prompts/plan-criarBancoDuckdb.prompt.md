## Plano: Criar banco DuckDB local `transferegov`

**TL;DR** — Criar a task `tasks/db/` com um script R que lê os 13 CSVs de [tasks/transferegov/outputs/](tasks/transferegov/outputs/) **e 2 CSVs de [tasks/malhas-municipais/outputs/](tasks/malhas-municipais/outputs/)** (municipios e UFs do IBGE), converte tipos (valores → `DOUBLE`, datas → `DATE`/`TIMESTAMP`), e grava num banco DuckDB único em `tasks/db/outputs/transferegov.duckdb` com chaves primárias e estrangeiras. O script expõe funções reutilizáveis para criar, popular e conectar ao banco.

**Steps**

1. **Criar a estrutura da task**
   - `tasks/db/src/R/01-criar-banco.R` — script principal que orquestra criação e carga
   - `tasks/db/src/R/utils.R` — funções auxiliares (conexão, criação de tabelas, conversão de tipos, carga)
   - `tasks/db/outputs/` — diretório onde ficará o arquivo `transferegov.duckdb`

2. **Implementar `utils.R` com 5 funções**:

   | Função                    | Responsabilidade                                                                                                                                                                                                                     |
   | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
   | `conectar_transferegov()` | Cria/abre conexão DBI com `duckdb::duckdb()` apontando para `tasks/db/outputs/transferegov.duckdb` via `here::here()`                                                                                                                |
   | `ler_csvs_transferegov()` | Reutiliza a lógica de `read_transferegov_csvs()` já existente em [00-load-transferegov.R](tasks/analise-exploratoria/src/R/00-load-transferegov.R#L25-L35): lista CSVs, lê como character, nomeia em snake_case sem prefixo numérico. **Também lê** `tasks/malhas-municipais/outputs/municipios.csv` (como `municipio`) e `tasks/malhas-municipais/outputs/uf.csv` (como `uf`), adicionando-os à lista de tabelas |
   | `converter_tipos()`       | Recebe um data.frame e aplica conversões: colunas com prefixo `valor_`, `vl_`, `qt_` → `as.numeric()`; colunas com `data_` → `as.Date()` ou `as.POSIXct()` (para campos `data_hora_`); demais permanecem `character`                 |
   | `criar_tabelas()`         | Recebe a conexão e executa DDL SQL com `CREATE TABLE` para cada tabela, definindo `PRIMARY KEY` e `FOREIGN KEY` referências conforme o modelo relacional documentado (ver abaixo)                                                    |
   | `popular_tabelas()`       | Recebe a conexão e a lista de data.frames, faz `DBI::dbWriteTable()` (append) para cada tabela na ordem correta (respeitando FK)                                                                                                     |

3. **Definir o schema SQL com constraints** — A função `criar_tabelas()` emitirá DDL para as **15 tabelas** (13 do Transferegov + 2 do IBGE). Mapeamento de PK/FK baseado no fluxo de [coleta.R](tasks/transferegov/src/R/coleta.R) e na documentação do `copilot-instructions.md`:

   ```
   # Tabelas de referência IBGE (sem FK — inseridas primeiro)
   uf ........................ PK(codigo_ibge_uf)
   municipio ................. PK(codigo_ibge)          FK(codigo_ibge_uf → uf)

   # Tabelas do Transferegov
   programa .................. PK(id_programa)
   plano_acao ................ PK(id_plano_acao)        FK(id_programa → programa)
                                                        FK(codigo_ibge_municipio → municipio)
                                                        FK(codigo_ibge_uf → uf)
   empenho ................... PK(id_empenho)           FK(id_plano_acao → plano_acao)
                                                        FK(codigo_ibge_municipio → municipio)
                                                        FK(codigo_ibge_uf → uf)
   documento_habil ........... PK(id_dh)                FK(id_empenho → empenho)
   ordem_pagamento ........... PK(id_op_ob)             FK(id_dh → documento_habil)
   historico_pagamento ....... PK(id_historico_op_ob)    FK(id_op_ob → ordem_pagamento)
   relatorio_gestao_novo ..... PK(id_relatorio_gestao_novo) FK(id_plano_acao → plano_acao)
   executor .................. PK(id_executor)           FK(id_plano_acao → plano_acao)
   meta ...................... PK(id_meta)               FK(id_executor → executor)
   plano_trabalho ............ PK(id_plano_trabalho)     FK(id_plano_acao → plano_acao)
   finalidade ................ Sem PK (tabela associativa) FK(id_executor → executor)
   plano_trabalho_analise .... PK(id_plano_trabalho_analise) FK(id_plano_trabalho → plano_trabalho)
   orgao_analise_pendente .... PK(id_analise_pendente)   FK(id_plano_trabalho → plano_trabalho)
   ```

   **Novas colunas adicionadas a tabelas existentes:**
   - `plano_acao`: `codigo_ibge_municipio VARCHAR`, `codigo_ibge_uf VARCHAR` (com FK para `municipio` e `uf`)
   - `empenho`: `codigo_ibge_municipio VARCHAR`, `codigo_ibge_uf VARCHAR` (com FK para `municipio` e `uf`)

   **Novas tabelas IBGE (fonte: `tasks/malhas-municipais/outputs/`):**
   - `uf`: `codigo_ibge_uf VARCHAR PK`, `nome_uf VARCHAR`, `sigla_uf VARCHAR`, `nome_regiao VARCHAR`
   - `municipio`: `codigo_ibge VARCHAR PK`, `nome_municipio VARCHAR`, `nome_uf VARCHAR`, `sigla_uf VARCHAR`, `codigo_ibge_uf VARCHAR FK(→uf)`, `populacao_2022 DOUBLE`, `pib_2021 DOUBLE`

   Os tipos SQL serão: `VARCHAR` (padrão), `DOUBLE` (colunas de valor/quantidade/população/PIB), `DATE` (colunas de data), `TIMESTAMP` (colunas data_hora).

4. **Implementar `01-criar-banco.R`** — Script orquestrador:
   - Carrega `here`, `tidyverse`, `DBI`, `duckdb`
   - Source `tasks/db/src/R/utils.R`
   - Exibe as 5 primeiras linhas de cada tabela (via `head()`) para log/inspeção dos campos comuns (IDs compartilhados)
   - Remove o banco existente se houver (para recriar do zero)
   - Chama `conectar_transferegov()` → `criar_tabelas()` → pipeline: `ler_csvs_transferegov()` → `converter_tipos()` por tabela → `popular_tabelas()`
   - Desconecta com `DBI::dbDisconnect()`
   - Imprime resumo final: quantidade de linhas por tabela via `DBI::dbGetQuery(con, "SELECT COUNT(*) FROM ...")`

5. **Ordem de inserção** (para respeitar FK):
   1. `uf`
   2. `municipio`
   3. `programa`
   4. `plano_acao`
   5. `empenho`, `relatorio_gestao_novo`, `executor`, `plano_trabalho`
   6. `documento_habil`, `meta`, `finalidade`, `plano_trabalho_analise`, `orgao_analise_pendente`
   7. `ordem_pagamento`
   8. `historico_pagamento`

6. **Adicionar `transferegov.duckdb` ao `.gitignore`** — O banco gerado é derivado dos CSVs já versionados, então não precisa ser versionado. Adicionar `tasks/db/outputs/*.duckdb` ao `.gitignore`.

**Verificação**

- Executar `source(here("tasks/db/src/R/01-criar-banco.R"))` no R — deve criar o banco sem erros
- Validar contagem de linhas: `DBI::dbGetQuery(con, "SELECT COUNT(*) FROM plano_acao")` deve retornar ~13.746
- Validar tabelas IBGE: `DBI::dbGetQuery(con, "SELECT COUNT(*) FROM municipio")` deve retornar 5.570; `... FROM uf` deve retornar 27
- Testar um join SQL para verificar integridade: `SELECT pa.id_plano_acao, e.id_empenho FROM plano_acao pa JOIN empenho e ON pa.id_plano_acao = e.id_plano_acao LIMIT 5`
- Testar join com IBGE: `SELECT pa.id_plano_acao, m.nome_municipio, u.sigla_uf FROM plano_acao pa JOIN municipio m ON pa.codigo_ibge_municipio = m.codigo_ibge JOIN uf u ON pa.codigo_ibge_uf = u.codigo_ibge_uf LIMIT 5`
- Testar FK: tentar inserir um registro com `id_programa` inexistente deve falhar
- Opcional: adicionar teste em `tests/testthat/test-db.R` que cria o banco em diretório temporário e verifica a contagem de linhas

**Decisões**

- **DuckDB** escolhido sobre SQLite por preferência do usuário — mais performático para queries analíticas, igualmente simples (arquivo único, sem servidor)
- **Com constraints** (PK/FK) — garante integridade referencial no banco; a tabela `finalidade` não terá PK pois é associativa (composta por `id_executor` + códigos de área)
- **Conversão de tipos** — colunas `valor_*`, `vl_*`, `qt_*` viram `DOUBLE`; `data_*` viram `DATE`; `data_hora_*` ou `data_e_hora_*` viram `TIMESTAMP`; demais ficam `VARCHAR`
