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

recursos_especiais <- tribble(
  ~start_msg,                                         ~end_msg,                                             ~path_input,          ~path_output,               ~resource,                                      ~key_column,
  "Coletando planos de ação...",                     "Fim da coleta de planos de ação.",                  PATH_PROGRAMA,       PATH_PLANO_ACAO,           "plano_acao_especial",                         "id_programa",
  "Coletando empenhos...",                           "Fim da coleta de empenhos...",                     PATH_PLANO_ACAO,     PATH_EMPENHO,              "empenho_especial",                             "id_plano_acao",
  "Coletando documento hábil...",                    "Fom da coleta de documento hábil.",               PATH_EMPENHO,        PATH_DOCUMENTO_HABIL,      "documento_habil_especial",                    "id_empenho",
  "Coletando ordem de pagamento - órdem bancária...", "Fim da coleta de ordem de pagamento - órdem bancária.", PATH_DOCUMENTO_HABIL, PATH_ORDEM_PAGAMENTO, "ordem_pagamento_ordem_bancaria_especial",     "id_dh",
  "Coletando de histórico de pagamento...",          "Fim de coleta de histórico de pagamento.",        PATH_ORDEM_PAGAMENTO,PATH_HISTORICO_PAGAMENTO,  "historico_pagamento_especial",                "id_op_ob",
  "Coletando de relatório de gestão...",             "Fim de coleta de relatório de gestão.",           PATH_PLANO_ACAO,     PATH_RELATORIO_GESTAO,     "relatorio_gestao_especial",                   "id_plano_acao",
  "Coletando relatório de gestão (novo)...",        "Fim da coleta de relatório de gestão (novo).",    PATH_PLANO_ACAO,     PATH_RELATORIO_GESTAO_NOVO,"relatorio_gestao_novo_especial",              "id_plano_acao",
  "Coletando lista de executores...",               "Fim da coleta de lista de executores.",           PATH_PLANO_ACAO,     PATH_EXECUTOR,             "executor_especial",                            "id_plano_acao",
  "Coletando metas...",                              "Fim da coleta de metas.",                         PATH_EXECUTOR,       PATH_META,                 "meta_especial",                               "id_executor",
  "Coletando planos de trabalho...",                 "Fim da coleta de planos de trabalho.",            PATH_PLANO_ACAO,     PATH_PLANO_TRABALHO,       "plano_trabalho_especial",                     "id_plano_acao",
  "Colentando lista de finalidades...",              "Fim da coleta de lista de finalidades.",         PATH_EXECUTOR,       PATH_FINALIDADE,           "finalidade_especial",                         "id_executor"
)

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
