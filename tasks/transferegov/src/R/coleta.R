# LIBS -------------------------------------------------------------------------

library(tidyverse)
library(here)
library(httr2)
library(jsonlite)
library(data.table)


# FILES ------------------------------------------------------------------------

# Chamando as funções
PATH_UTILS <- here("tasks/transferegov/src/R/utils.R")
source(PATH_UTILS)

# Diretório onde os dados são guardados
PATH_OUTPUT_DIR <- here("tasks/transferegov/tmp")

# helper
get_file <- \(dir = PATH_OUTPUT_DIR, file) here(dir, file)

# filepaths
PATH_PROGRAMA <- get_file(file = "01-programa.csv")
PATH_PLANO_ACAO <- get_file(file = "02-plano-acao.csv")
PATH_EMPENHO <- get_file(file = "03-empenho.csv")
PATH_DOCUMENTO_HABIL <- get_file(file = "04-documento-habil.csv")
PATH_ORDEM_PAGAMENTO <- get_file(file = "05-ordem-pagamento.csv")
PATH_HISTORICO_PAGAMENTO <- get_file(file = "06-historico-pagamento.csv")
PATH_RELATORIO_GESTAO <- get_file(file = "07-relatorio-gestao.csv")
PATH_RELATORIO_GESTAO_NOVO <- get_file(file = "08-relatorio-gestao-novo.csv")
PATH_EXECUTOR <- get_file(file = "09-executor.csv")
PATH_META <- get_file(file = "10-meta.csv")
PATH_PLANO_TRABALHO <- get_file(file = "11-plano-trabalho.csv")
PATH_FINALIDADE <- get_file(file = "12-finalidade.csv")

lubridate::now()


# :: 01.PROGRAMA ESPECIAL ------------------------------------------------------
message("Coletando programa...")

programa_especial <- fetch_transferegov_resource(
  resource = "programa_especial",
  key = NULL,
  perc = NULL,
  PATH_PROGRAMA
)

message("Fim da coleta de programa.")


# :: 02-12.RECURSOS ESPECIAIS --------------------------------------------------

# Vetores individuais
start_msg <- c(
  "Coletando planos de ação...",
  "Coletando empenhos...",
  "Coletando documento hábil...",
  "Coletando ordem de pagamento...",
  "Coletando de histórico de pagamento...",
  "Coletando de relatório de gestão...",
  "Coletando relatório de gestão (novo)...",
  "Coletando lista de executores...",
  "Coletando metas...",
  "Coletando planos de trabalho...",
  "Colentando lista de finalidades..."
)

end_msg <- c(
  "Fim da coleta de planos de ação.",
  "Fim da coleta de empenhos...",
  "Fom da coleta de documento hábil.",
  "Fim da coleta de ordem de pagamento.",
  "Fim de coleta de histórico de pagamento.",
  "Fim de coleta de relatório de gestão.",
  "Fim da coleta de relatório de gestão (novo).",
  "Fim da coleta de lista de executores.",
  "Fim da coleta de metas.",
  "Fim da coleta de planos de trabalho.",
  "Fim da coleta de lista de finalidades."
)

path_input <- c(
  PATH_PROGRAMA,
  PATH_PLANO_ACAO,
  PATH_EMPENHO,
  PATH_DOCUMENTO_HABIL,
  PATH_ORDEM_PAGAMENTO,
  PATH_PLANO_ACAO,
  PATH_PLANO_ACAO,
  PATH_PLANO_ACAO,
  PATH_EXECUTOR,
  PATH_PLANO_ACAO,
  PATH_EXECUTOR
)

path_output <- c(
  PATH_PLANO_ACAO,
  PATH_EMPENHO,
  PATH_DOCUMENTO_HABIL,
  PATH_ORDEM_PAGAMENTO,
  PATH_HISTORICO_PAGAMENTO,
  PATH_RELATORIO_GESTAO,
  PATH_RELATORIO_GESTAO_NOVO,
  PATH_EXECUTOR,
  PATH_META,
  PATH_PLANO_TRABALHO,
  PATH_FINALIDADE
)

resource <- c(
  "plano_acao_especial",
  "empenho_especial",
  "documento_habil_especial",
  "ordem_pagamento_ordem_bancaria_especial",
  "historico_pagamento_especial",
  "relatorio_gestao_especial",
  "relatorio_gestao_novo_especial",
  "executor_especial",
  "meta_especial",
  "plano_trabalho_especial",
  "finalidade_especial"
)

key_column <- c(
  "id_programa",
  "id_plano_acao",
  "id_empenho",
  "id_dh",
  "id_op_ob",
  "id_plano_acao",
  "id_plano_acao",
  "id_plano_acao",
  "id_executor",
  "id_plano_acao",
  "id_executor"
)

# Montando a tibble final
recursos_especiais <- tibble::tibble(
  start_msg,
  end_msg,
  path_input,
  path_output,
  resource,
  key_column
)

recursos_especiais


recursos_especiais |> pwalk(
  function(start_msg, end_msg, path_input, path_output, resource, key_column) {
    message(start_msg)
    build_transferegov_params(
      path_input = path_input,
      path_output = path_output,
      resource = resource,
      key_column = key_column
    ) |> pwalk(fetch_transferegov_resource)
    message(end_msg)
  }
)


# :: FIM -----------------------------------------------------------------------
lubridate::now()
