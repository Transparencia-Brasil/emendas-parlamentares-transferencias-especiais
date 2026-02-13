library(here)
library(tidyverse)
options(width = 180)

# :: PATHS ---------------------------------------------------------------------

INPUT_DIR <- "tasks/analise-exploratoria/inputs"
OUTPUT_DIR <- "tasks/analise-exploratoria/outputs"
TRANSFEREGOV_DIR <- here("tasks/transferegov/outputs")


PATH_MINI_TRANSFEREGOV <- here(INPUT_DIR, "mini-transferegov.rds")

PATH_TRANSFEREGOV_TABLES <- list.files(here("tasks/transferegov/outputs"), pattern = "csv$", full.names = TRUE)


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

consolida_emendas_por_programas <- function(id_prog) {

  # Plano de ação
  # -------------
  plano_acao <- transferegov$plano_acao |>
    filter(id_programa == id_prog) |>
    mutate(across(starts_with("valor_"), as.numeric)) |>
    left_join(select(transferegov$programa, id_programa, codigo_programa)) |>
    select(
      codigo_programa, id_plano_acao,
      cnpj_beneficiario_plano_acao,
      nome_beneficiario_plano_acao,
      uf_beneficiario_plano_acao,
      codigo_emenda_parlamentar_formatado_plano_acao,
      valor_custeio_plano_acao,
      valor_investimento_plano_acao
    )

  # Executores
  # ----------
  executores <- plano_acao |>
    distinct(id_plano_acao) |>
    inner_join(transferegov$executor) |>
    mutate(across(starts_with("vl_"), as.numeric)) |>
    distinct(
      id_plano_acao, id_executor,
      cnpj_executor, nome_executor,	objeto_executor,
      vl_custeio_executor, vl_investimento_executor
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
  metas # 23.701 linhas (out.2025) | 25.240 (fev.2025)
  # finalidades # 10.349 linhas

  # RELAÇÕES:
  # Um plano de ação contém um ou nenhum planos de trabalho
  # Um plano de ação contém um ou mais executores
  # Um executor contém uma ou mais metas

  emendas <- plano_acao |>
    left_join(plano_trabalho) |>
    left_join(executores)

  emendas <- left_join(emendas, metas)

  emendas |>
    select(
      codigo_programa,
      id_plano_acao,
      id_executor,
      id_plano_trabalho,
      id_meta,
      sequencial_meta,
      codigo_emenda_parlamentar_formatado_plano_acao,
      cnpj_beneficiario_plano_acao,
      nome_beneficiario_plano_acao,
      uf_beneficiario_plano_acao,
      cnpj_executor,
      nome_executor,
      objeto_executor,
      situacao_plano_trabalho,
      prazo_execucao_meses_plano_trabalho,
      classificacao_orcamentaria_pt,
      desc_meta,
      qt_meses_meta,
      un_medida_meta,
      qt_unidade_meta = qt_uniade_meta,
      #
      valor_custeio_plano_acao,
      valor_investimento_plano_acao,
      #
      vl_custeio_executor,
      vl_investimento_executor,
      #
      vl_custeio_emenda_especial_meta,
      vl_investimento_emenda_especial_meta,
      #
      vl_custeio_recursos_proprios_meta,
      vl_investimento_recursos_proprios_meta,
      #
      vl_custeio_doacao_meta,
      vl_investimento_doacao_meta,
      #
      vl_custeio_rendimento_meta,
      vl_investimento_rendimento_meta

    )

}

emendas_programa_23 <- consolida_emendas_por_programas("23")
emendas_programa_24 <- consolida_emendas_por_programas("24")

emendas <- bind_rows(emendas_programa_23, emendas_programa_24)

saveRDS(emendas, PATH_MINI_TRANSFEREGOV)
write_excel_csv2(emendas, "tasks\\analise-exploratoria\\inputs\\emendas-detalhadas-fevereiro-2026.csv")
