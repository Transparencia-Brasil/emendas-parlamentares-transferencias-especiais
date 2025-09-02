library(here)
library(tidyverse)
options(width = 150)

# :: PATHS ---------------------------------------------------------------------

INPUT_DIR <- "tasks/classificacao-natureza-despesa/inputs"
OUTPUT_DIR <- "tasks/classificacao-natureza-despesa/inputs"
TRANSFEREGOV_DIR <- here("tasks/transferegov/outputs")

PATH_TRANSFEREGOV_TABLES <- list.files(TRANSFEREGOV_DIR, pattern = "csv$", full.names = TRUE)

PATH_PORTARIA_103_2021 <- here(INPUT_DIR, "texto-completo-portaria-103-2021.rds")
PATH_PORTARIA_103_2021_TXT <- here(INPUT_DIR, "texto-completo-portaria-103-2021.txt")

PATH_NATUREZA_DESPESA <- here(INPUT_DIR, "natureza-de-despesas.rds")
PATH_NATUREZA_DESPESA_CSV <- here(INPUT_DIR, "natureza-de-despesas.csv")

PATH_DISCRIMINACAO_NATUREZA_DESPESA <- here(INPUT_DIR, "discriminacao-natureza-de-despesas.rds")
PATH_DISCRIMINACAO_NATUREZA_DESPESA_CSV <- here(INPUT_DIR, "discriminacao-natureza-de-despesas.csv")

PATH_METAS_CSV <- here(OUTPUT_DIR, "metas.csv")
PATH_EXECUTORES_CSV <- here(OUTPUT_DIR, "executores.csv")

PATH_EMENDAS_DETALHADAS <- here(OUTPUT_DIR, "emendas-detalhadas.csv")


# :: FUNÇÕES AUXILIARES --------------------------------------------------------

#' Carregar CSVs da transferegov
#' Lê múltiplos arquivos CSV e atribui nomes padronizados à lista retornada.
#' @param x Vetor ou lista com os caminhos dos arquivos CSV.
#' @return Uma lista com os dados lidos, nomeada de acordo com o padrão definido.
read_transferegov_csvs <- \(x) {
  ids <- basename(x) |>
    snakecase::to_snake_case() |>
    str_remove("^\\d+_") |>
    str_remove("_csv$") |>
    str_remove("_especial$")
  x |>
    map(read_csv, col_types = cols(.default = col_character())) |>
    set_names(ids)
}

#' Ler CSV do agent
#' Lê um arquivo CSV convertendo todas as colunas para texto.
#' @param path Caminho do arquivo CSV.
#' @return Um tibble com os dados do CSV.
read_csv_agent <- function(path) {
  readr::read_csv(
    file = path,
    col_types = readr::cols(.default = readr::col_character()), # lê tudo como texto p/ não perder info
    locale = readr::locale(encoding = "UTF-8"),
    na = c("", "NA"),
    quote = "\"",
    progress = FALSE
  )
}


# :: LOAD TRANSFEREGOV ---------------------------------------------------------

# carrega todos os dados
transferegov <- read_transferegov_csvs(PATH_TRANSFEREGOV_TABLES)


# :: SELECIONA TABELAS E CAMPOS ------------------------------------------------

# Plano de ação
# -------------
plano_acao <- transferegov$plano_acao |>
  filter(id_programa == "23") |>
  select(
    id_plano_acao,
    cnpj_beneficiario_plano_acao,
    nome_beneficiario_plano_acao,
    uf_beneficiario_plano_acao,
    codigo_emenda_parlamentar_formatado_plano_acao
  )

# Executores
# ----------
executores <- plano_acao |>
  distinct(id_plano_acao) |>
  inner_join(transferegov$executor) |>
  mutate(across(starts_with("vl_"), as.numeric)) |>
  distinct(
    id_plano_acao,	id_executor,	cnpj_executor, nome_executor,	objeto_executor
  )

# Metas
# -----
metas <- plano_acao |>
  distinct(id_plano_acao) |>
  inner_join(executores) |>
  distinct(id_executor) |>
  inner_join(transferegov$meta) |>
  mutate(across(starts_with("vl_"), as.numeric)) |>
  mutate(across(starts_with("qt_"), as.numeric)) |>
  select(-nome_meta)

# Plano de trabalho
# -----------------
plano_trabalho <- plano_acao |>
  distinct(id_plano_acao) |>
  inner_join(transferegov$plano_trabalho) |>
  glimpse()
  select(
    id_plano_acao, id_plano_trabalho, situacao_plano_trabalho,
    prazo_execucao_meses_plano_trabalho, classificacao_orcamentaria_pt
  )

# Finalidades
# -----------
finalidades <- executores |>
  distinct(id_executor) |>
  inner_join(transferegov$finalidade)
  # não tá fazendo muito sentido: ver id_executor == "47042"


# :: CRIAR TABELA ÚNICA --------------------------------------------------------

plano_acao # 10.145 linhas
plano_trabalho # 9.747 linhas
executores # 9.753 linhas
metas # 17.236 linhas
# finalidades # 10.349 linhas

# RELAÇÕES:
# Um plano de ação contém um ou nenhum planos de trabalho
# Um plano de ação contém um ou mais executores
# Um executor contém uma ou mais metas

emendas <- plano_acao |>
  left_join(plano_trabalho) |>
  left_join(executores)

emendas <- left_join(emendas, metas)

write_csv(emendas, PATH_EMENDAS_DETALHADAS)


# :: LOAD CATEGORIAS DE DESPESA ------------------------------------------------

metas |> write_csv(PATH_METAS_CSV)
executores |> write_csv(PATH_EXECUTORES_CSV)

natureza_despesa <- readRDS(PATH_NATUREZA_DESPESA)

natureza_despesa |>
  enframe() |>
  unnest(value) |>
  write_csv(PATH_NATUREZA_DESPESA_CSV)

discriminacao_natureza_despesa <- readRDS(PATH_DISCRIMINACAO_NATUREZA_DESPESA)
write_csv(discriminacao_natureza_despesa, PATH_DISCRIMINACAO_NATUREZA_DESPESA_CSV)

# Dicionário de Dados - Dataset Emendas TransfereGov
# Baseado na API de Transferências Especiais

library(tibble)

dicionario_emendas <- tribble(
  ~nome_coluna, ~descricao, ~endpoint,

  # Campos de Plano de Ação
  "id_plano_acao", "Identificador único do plano de ação da transferência especial", "plano_acao",
  "cnpj_beneficiario_plano_acao", "CNPJ da entidade beneficiária cadastrada no plano de ação", "plano_acao",
  "nome_beneficiario_plano_acao", "Nome/razão social da entidade beneficiária do plano de ação", "plano_acao",
  "uf_beneficiario_plano_acao", "Unidade Federativa (Estado) do beneficiário do plano de ação", "plano_acao",
  "codigo_emenda_parlamentar_formatado_plano_acao", "Código Formatado da Emenda Parlamentar", "plano_acao",

  # Campos de Plano de Trabalho
  "id_plano_trabalho", "Identificador único do plano de trabalho", "plano_trabalho",
  "situacao_plano_trabalho", "Status atual do plano de trabalho (ex: APROVADO, Em Análise, etc.)", "plano_trabalho",
  "prazo_execucao_meses_plano_trabalho", "Prazo em meses definido para execução completa do plano de trabalho", "plano_trabalho",
  "classificacao_orcamentaria_pt", "Texto com classificação orçamentária da despesa informado quando indicado no orcamento proprio", "plano_trabalho",

  # Campos de Executor
  "id_executor", "Identificador Unico do Executor do Planejamento", "executor_especial",
  "cnpj_executor", "CNPJ da entidade executora", "executor_especial",
  "nome_executor", "Nome/razão social da entidade responsável pela execução físico-financeira", "executor_especial",
  "objeto_executor", "Descrição detalhada do objeto/finalidade da execução dos recursos", "executor_especial",

  # Campos de Meta
  "id_meta", "Identificador único da meta específica do executor", "meta_especial",
  "sequencial_meta", "Sequencial usado para ordenação", "meta_especial",
  "desc_meta", "Descrição detalhada e específica da meta do executor", "meta_especial",
  "un_medida_meta", "Unidade de medida da meta do executor (ex: M2, UN, M, KM, etc.)", "meta_especial",
  "qt_uniade_meta", "Quantidade numérica de unidades previstas para a meta", "meta_especial",
  "qt_meses_meta", "Quantidade de meses prevista para execução da meta específica", "meta_especial",

  # Campos de Valores - Emenda Especial
  "vl_custeio_emenda_especial_meta", "Valor em reais destinado a custeio proveniente da emenda especial para a meta", "meta_especial",
  "vl_investimento_emenda_especial_meta", "Valor em reais destinado a investimento proveniente da emenda especial para a meta", "meta_especial",

  # Campos de Valores - Recursos Próprios
  "vl_custeio_recursos_proprios_meta", "Valor em reais de Custeio de Recursos Proprios", "meta_especial",
  "vl_investimento_recursos_proprios_meta", "Valor em reais de Investimento de Recursos Proprios", "meta_especial",

  # Campos de Valores - Rendimentos
  "vl_custeio_rendimento_meta", "Valor em reais de Custeio de Rendimentos", "meta_especial",
  "vl_investimento_rendimento_meta", "Valor em reais de Investimento de Rendimentos", "meta_especial",

  # Campos de Valores - Doações
  "vl_custeio_doacao_meta", "Valor em reais de Custeio de Doações", "meta_especial",
  "vl_investimento_doacao_meta", "Valor em reais de Investimento de Doações", "meta_especial"
)

# Visualizar o dicionário
View(dicionario_emendas)
