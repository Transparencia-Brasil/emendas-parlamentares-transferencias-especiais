# Copilot Instructions — emendas-parlamentares-transferencias-especiais

## Visão geral do projeto

Este repositório é mantido pela **Transparência Brasil** e concentra a coleta, análise e classificação de dados de **transferências especiais** (emendas parlamentares) obtidos pela API pública do Transferegov. A linguagem principal é **R** (tidyverse). Há também automações que utilizam prompts para modelos de linguagem (LLMs) voltadas à classificação de natureza de despesa e análise de planos de trabalho.

**Links de referência:**

- [Documentação da API — Transferências Especiais](https://docs.api.transferegov.gestao.gov.br/transferenciasespeciais/#/)
- [Site do Transferegov](https://especiais.transferegov.sistema.gov.br/transferencia-especial/programa/detalhe/23/dados-basicos)

---

## Estrutura de diretórios

```
.
├── .github/                         # Instruções para Copilot e configurações GitHub
│   └── copilot-instructions.md
├── AGENTS.md                        # Diretrizes para agentes de IA
├── setup/
│   └── rsetup.R                     # Configuração do ambiente R (paletas, fontes, tema ggplot2)
├── data/
│   ├── source1/                     # Fontes de dados brutos (estrutura reservada)
│   └── source2/
├── docs/                            # Saída Quarto: HTML estático, estilos CSS
│   └── tasks/                       # Relatórios renderizados por task
├── tests/
│   ├── testthat.R                   # Ponto de entrada dos testes
│   └── testthat/
│       └── test-utils.R             # Testes das funções utilitárias de coleta
├── tasks/                           # ★ Núcleo do projeto — cada subpasta é um fluxo de trabalho
│   ├── transferegov/                # Coleta de dados da API (ver seção dedicada)
│   │   ├── src/R/
│   │   │   ├── coleta.R             # Orquestra a coleta sequencial de todos os endpoints
│   │   │   ├── utils.R              # Funções: request, collect, fetch, build_params
│   │   │   └── cruzamento-tabelas.R # Cruza tabelas e exporta para Google Sheets
│   │   ├── outputs/                 # CSVs resultantes da coleta (ver seção "Tabelas")
│   │   ├── tmp/                     # Arquivos temporários da coleta (ignorados pelo git)
│   │   └── log/                     # Logs de execução
│   ├── analise-exploratoria/        # Análise exploratória dos dados coletados
│   │   ├── src/R/
│   │   │   └── 00-load-transferegov.R
│   │   ├── inputs/                  # CSVs e RDS de entrada
│   │   └── docs/
│   │       └── 00-totalizacoes.qmd  # Relatório Quarto
│   ├── analise-plano-de-trabalho/   # Análise detalhada de planos de trabalho
│   │   └── src/R/                   # Scripts 01- a 06- + utils.R
│   ├── classificacao-natureza-despesa/  # Classificação com LLMs
│   │   ├── src/R/                   # Scripts de preparação de inputs
│   │   ├── inputs/                  # CSVs de emendas, naturezas, portarias
│   │   └── prompts/                 # Prompts para agentes (agente.md, instruções)
│   ├── analise-classificacoes-gpt5/ # Análise dos resultados de classificação por LLM
│   │   ├── src/R/
│   │   ├── inputs/
│   │   └── outputs/
│   ├── malhas-municipais/           # Dados geográficos de municípios (IBGE)
│   ├── sidra-ibge/                  # Dados socioeconômicos do SIDRA/IBGE
│   └── langgraph-learning/          # Experimentos com LangGraph (Python)
├── _quarto.yml                      # Configuração do projeto Quarto
├── _post-copy.R                     # Script pós-render do Quarto
└── project.Rproj                    # Projeto RStudio
```

### Convenções de organização

- Cada **task** segue a estrutura `tasks/<nome>/src/R/`, `tasks/<nome>/inputs/`, `tasks/<nome>/outputs/` e opcionalmente `tasks/<nome>/docs/`.
- Scripts R são nomeados com **prefixo numérico sequencial** e **nome descritivo em kebab-case**: `01-nome-do-script.R`.
- Documentos Quarto seguem o mesmo padrão: `00-totalizacoes.qmd`.
- Prompts para LLMs ficam em `tasks/<nome>/prompts/` como arquivos `.md`.

---

## Coleta de dados — API Transferegov

### Fonte de dados

A API REST do módulo de **Transferências Especiais** do Transferegov (versão 11.2.0, especificação OAS 2.0) está disponível em:

```
Base URL: https://api.transferegov.gestao.gov.br/transferenciasespeciais/
```

A API utiliza a sintaxe de operadores do [PostgREST](https://postgrest.org/en/v11.2/api.html) para filtros. Exemplo: `id_programa=eq.23`.

### Como funciona a coleta (`tasks/transferegov/src/R/coleta.R`)

O script `coleta.R` orquestra a coleta de **14 recursos** da API de forma sequencial e encadeada:

1. **Coleta o programa** (`programa_especial`) — ponto de partida, filtrado por `ano_programa == "2025"`.
2. **Coleta em cascata** — cada recurso seguinte usa os IDs coletados do recurso anterior como parâmetro. Por exemplo, os `id_plano_acao` obtidos em `02-plano-acao.csv` são usados para consultar empenhos, executores, planos de trabalho, etc.

A lógica central está em `utils.R`, com quatro funções principais:

| Função                            | Descrição                                                                                                                   |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `request_transferegov_resource()` | Monta a URL da requisição HTTP com parâmetros PostgREST. Inclui `Sys.sleep(0.15)` entre chamadas.                           |
| `collect_transferegov_resource()` | Executa a requisição com **paginação automática** (`offset` de 1000 em 1000), retry (3 tentativas) e throttle (30 req/60s). |
| `fetch_transferegov_resource()`   | Wrapper que coleta e salva o resultado em CSV com `data.table::fwrite()` (modo append).                                     |
| `build_transferegov_params()`     | Lê um CSV, extrai IDs únicos de uma coluna-chave e gera uma tibble com os parâmetros para chamadas em lote.                 |

**Fluxo de dependência da coleta:**

```
programa_especial (sem chave)
  └─► plano_acao_especial        (id_programa)
        ├─► empenho_especial     (id_plano_acao)
        ├─► historico_pagamento  (id_op_ob, via cadeia empenho → DH → OP)
        ├─► relatorio_gestao     (id_plano_acao)
        ├─► relatorio_gestao_novo(id_plano_acao)
        ├─► executor_especial    (id_plano_acao)
        │     ├─► meta_especial      (id_executor)
        │     └─► finalidade_especial(id_executor)
        └─► plano_trabalho       (id_plano_acao)
              ├─► plano_trabalho_analise  (id_plano_trabalho)
              └─► orgao_analise_pendente  (id_plano_trabalho)
```

Os CSVs são salvos primeiro em `tasks/transferegov/tmp/` (ignorado pelo Git) e depois copiados para `tasks/transferegov/outputs/` (versionados).

---

## Tabelas coletadas (`tasks/transferegov/outputs/`)

### 01-programa.csv (22 colunas)

Cadastro dos **programas de transferências especiais**. Contém o órgão responsável, modalidade, período de ciência e valores financeiros agregados (disponibilizado, impedido, a disponibilizar). Chave primária: `id_programa`.

### 02-plano-acao.csv (27 colunas)

**Planos de ação** vinculados a emendas parlamentares. Cada linha é uma emenda endereçada a um beneficiário (município/estado). Contém dados do parlamentar autor, área de política pública, dados bancários, valores de custeio e investimento, e situação (CIENTE/IMPEDIDO). FK: `id_programa`.

### 03-empenho.csv (27 colunas)

**Notas de empenho orçamentário**. Classificação orçamentária completa (natureza de despesa, fonte, PTRES, grupo, subitem), UG emitente, beneficiário, situação e valor empenhado. FK: `id_plano_acao`.

### 04-documento-habil.csv (23 colunas)

**Documentos hábeis** (tipo TF — Transferência Financeira) que liquidam os empenhos. Contém datas de emissão/vencimento, UG pagadora e valor. FK: `id_empenho`.

### 05-ordem-pagamento.csv (13 colunas)

**Ordens de pagamento (OP) e ordens bancárias (OB)**. Registra datas de emissão, assinaturas do ordenador de despesa e gestor financeiro, e situação do envio bancário. FK: `id_dh`.

### 06-historico-pagamento.csv (5 colunas)

**Histórico de transições** de situação das ordens de pagamento (ex.: "Aguardando Envio" → "OB Enviada"), com timestamp. FK: `id_op_ob`.

### 08-relatorio-gestao-novo.csv (7 colunas)

**Relatórios de gestão** (parciais ou finais) apresentados pelos beneficiários para prestação de contas. Valores executados/pendentes e situação. FK: `id_plano_acao`.

### 09-executor.csv (17 colunas)

**Executores** (municípios/entidades) vinculados ao plano de ação. Inclui objeto da obra/serviço, dados bancários e valores de custeio/investimento. FK: `id_plano_acao`.

### 10-meta.csv (16 colunas)

**Metas físicas e financeiras** de cada executor. Descrição, unidade de medida, quantidade, valores por fonte (emenda, recursos próprios, rendimento, doação) e prazo. FK: `id_executor`.

### 11-plano-trabalho.csv (11 colunas)

**Planos de trabalho** detalhando a execução. Situação (APROVADO etc.), período de execução, classificação orçamentária detalhada e justificativas de prorrogação. FK: `id_plano_acao`.

### 12-finalidade.csv (5 colunas)

**Áreas de política pública** associadas a cada executor (ex.: Urbanismo/Infraestrutura). Tabela de classificação funcional. FK: `id_executor`.

### 13-plano-trabalho-analise.csv (10 colunas)

**Análises dos órgãos setoriais** sobre os planos de trabalho. Parecer (aprovar/complementar), texto do parecer, situação e valor reprovado. FK: `id_plano_trabalho`.

### 14-orgao-analise-pendente.csv (4 colunas)

**Órgãos com análise pendente** para determinado plano de trabalho. Indica quais ministérios ainda não concluíram a avaliação. FK: `id_plano_trabalho`.

---

## Modelo relacional das tabelas

```
01-programa
  └── 02-plano-acao ............... [id_programa]
        ├── 03-empenho ............ [id_plano_acao]
        │     └── 04-documento-habil [id_empenho]
        │           └── 05-ordem-pagamento [id_dh]
        │                 └── 06-historico-pagamento [id_op_ob]
        ├── 08-relatorio-gestao-novo [id_plano_acao]
        ├── 09-executor ........... [id_plano_acao]
        │     ├── 10-meta ......... [id_executor]
        │     └── 12-finalidade ... [id_executor]
        └── 11-plano-trabalho ..... [id_plano_acao]
              ├── 13-plano-trabalho-analise [id_plano_trabalho]
              └── 14-orgao-analise-pendente [id_plano_trabalho]
```

- A **cadeia financeira** segue: programa → plano de ação → empenho → documento hábil → ordem de pagamento → histórico.
- A **cadeia de execução** segue: plano de ação → executor → metas + finalidades; plano de ação → plano de trabalho → análises.
- Todas as colunas são lidas como `character` por padrão. Conversões numéricas e de data devem ser feitas explicitamente no momento da análise.

---

## Configuração do ambiente

1. Abra o projeto com `project.Rproj` no RStudio, ou use o terminal R.
2. Execute `setup/rsetup.R` para configurar paletas de cores (Transparência Brasil, DadosJusBR, Achados e Pedidos), fontes (Open Sans) e o tema padrão do ggplot2.
3. **Pacotes principais**: tidyverse, httr2, jsonlite, data.table, here, ggplot2, ggtext, hrbrthemes, broom, tidymodels, testthat, scales, snakecase, googlesheets4, showtext.
4. Rode os testes com: `testthat::test_dir("tests/testthat")`.

---

## Convenções e padrões de código

- **Idioma**: todo código, comentários, mensagens e documentação em **português (PT-BR)**.
- **Nomeação de arquivos**: prefixo numérico + kebab-case → `01-nome-descritivo.R`, `02-outro-script.qmd`.
- **Funções R**: documentadas com roxygen2 (`#' @param`, `#' @return`).
- **Caminhos**: use sempre `here::here()` para caminhos relativos ao projeto. Nunca use caminhos absolutos hardcoded.
- **Leitura de CSVs**: use `col_types = cols(.default = col_character())` ou `"c"` para ler tudo como texto e converter explicitamente depois.
- **Escrita de CSVs**: use `data.table::fwrite()` com `quote = TRUE`.
- **Explicações**: claras, simples e em português. Consulte `AGENTS.md` para diretrizes de agentes.

---

## Fluxos de trabalho (tasks)

| Task                              | Descrição                                                                                         |
| --------------------------------- | ------------------------------------------------------------------------------------------------- |
| `transferegov/`                   | Coleta dados da API e salva CSVs. Ponto de partida para todas as análises.                        |
| `analise-exploratoria/`           | Exploração e totalização dos dados coletados. Gera relatórios Quarto.                             |
| `analise-plano-de-trabalho/`      | Análise detalhada dos planos de trabalho (elemento de despesa, localização, público, prazo etc.). |
| `classificacao-natureza-despesa/` | Classificação de natureza de despesa com apoio de LLMs. Contém prompts em `prompts/`.             |
| `analise-classificacoes-gpt5/`    | Avaliação dos resultados das classificações feitas por LLMs.                                      |
| `malhas-municipais/`              | Dados geográficos de municípios (malhas IBGE).                                                    |
| `sidra-ibge/`                     | Dados socioeconômicos do SIDRA/IBGE.                                                              |

### Criando uma nova task

```
tasks/
  nova-task/
    src/R/
      01-primeiro-script.R
    inputs/
    outputs/
    docs/
      00-relatorio.qmd     # (opcional)
```

---

## Boas práticas de versionamento (Git)

- **Mensagens e idioma**: sempre em português (PT-BR).
- **Branches**:
  - Use prefixos para organizar: `feat/` (funcionalidade), `fix/` (correção), `docs/` (documentação), `chore/` (tarefas gerais), `data/` (atualização de dados coletados).
  - Exemplos: `feat/novo-coletor-empenhos`, `fix/encoding-csv`, `data/coleta-fevereiro-2026`.
- **Commits**:
  - Mensagens no imperativo ("Adiciona...", "Corrige...", "Remove...").
  - Estrutura: `tipo: descrição breve`.
  - Tipos comuns:
    - `feat`: funcionalidade nova (ex.: novo endpoint, novo script de análise).
    - `fix`: correção de bug (ex.: encoding, caminhos Windows).
    - `docs`: documentação (README, prompts, relatórios Quarto).
    - `refactor`: mudança interna sem alterar comportamento.
    - `chore`: manutenção (dependências, CI, limpeza de arquivos).
    - `test`: adicionar ou ajustar testes.
    - `data`: atualização de CSVs coletados ou inputs.
    - `perf`: melhoria de performance.
    - `style`: formatação/lint sem alterar lógica.
  - Exemplos:
    - `feat: adiciona coleta de órgão com análise pendente`
    - `fix: corrige erro de encoding na leitura de empenhos`
    - `data: atualiza coleta de fevereiro de 2026`
    - `docs: atualiza prompt de classificação de despesas`
  - Mantenha commits **pequenos e com contexto único** — evite misturar coleta, análise e documentação no mesmo commit.
  - Commits que envolvem dados sensíveis ou mudanças estruturais devem conter explicação sucinta do impacto.
- **Arquivos ignorados**: CSVs temporários (`tmp/`), logs de coleta, arquivos de configuração local (`.Renviron`, `.vscode/`) e outputs antigos (`old/`) já estão no `.gitignore`.

---

## Recomendações para agentes de IA

- Sempre consulte `AGENTS.md` e os prompts em `tasks/classificacao-natureza-despesa/prompts/` antes de automatizar fluxos.
- Priorize clareza e rastreabilidade nas respostas.
- Siga as convenções de nomeação e idioma do projeto.
- Ao criar novos scripts, siga a estrutura de tasks existente.
- Ao manipular dados, leia CSVs como texto e converta tipos explicitamente.
