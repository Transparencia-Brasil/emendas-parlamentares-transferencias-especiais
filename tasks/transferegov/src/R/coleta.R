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
PATH_OUTPUT_DIR <- here("tasks/transferegov/outputs")

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


# :: 02.PLANO DE AÇÂO ESPECIAL -------------------------------------------------

message("Coletando planos de ação...")

build_transferegov_params(
  path_input = PATH_PROGRAMA,
  path_output = PATH_PLANO_ACAO,
  resource = "plano_acao_especial",
  key_column = "id_programa"
) |> pwalk(fetch_transferegov_resource)

message("Fim da coleta de planos de ação.")


# :: 03.EMPENHO ESPECIAL -------------------------------------------------------

message("Coletando empenhos...")

build_transferegov_params(
  path_input = PATH_PLANO_ACAO,
  path_output = PATH_EMPENHO,
  resource = "empenho_especial",
  key_column = "id_plano_acao"
) |> pwalk(fetch_transferegov_resource)

message("Fim da coleta de empenhos...")


# :: 04.DOCUMENTO HÁBIL ESPECIAL -----------------------------------------------

message("Coletando documento hábil...")

build_transferegov_params(
  path_input = PATH_EMPENHO,
  path_output = PATH_DOCUMENTO_HABIL,
  resource = "documento_habil_especial",
  key_column = "id_empenho"
) |> pwalk(fetch_transferegov_resource)

message("Fom da coleta de documento hábil.")


# :: 05.ORDEM PAGAMENTO - ORDEM BANCÁRIA ESPECIAL ------------------------------

message("Coletando ordem de pagamento - órdem bancária...")

build_transferegov_params(
  path_input = PATH_DOCUMENTO_HABIL,
  path_output = PATH_ORDEM_PAGAMENTO,
  # resource = "historico_pagamento_especial",
  resource = "ordem_pagamento_ordem_bancaria_especial",
  key_column = "id_dh"
) |> pwalk(fetch_transferegov_resource)

message("Fim da coleta de ordem de pagamento - órdem bancária.")


# :: 06.HISTÓRICO PAGAMENTO ESPECIAL -------------------------------------------

message("Coletando de histórico de pagamento...")

build_transferegov_params(
  path_input = PATH_ORDEM_PAGAMENTO,
  path_output = PATH_HISTORICO_PAGAMENTO,
  resource = "historico_pagamento_especial",
  key_column = "id_op_ob"
) |> pwalk(fetch_transferegov_resource)

message("Fim de coleta de histórico de pagamento.")


# :: 07.RELATÓRIO GESTÃO ESPECIAL ----------------------------------------------

message("Coletando de relatório de gestão...")

build_transferegov_params(
  path_input = PATH_PLANO_ACAO,
  path_output = PATH_RELATORIO_GESTAO,
  resource = "relatorio_gestao_especial",
  key_column = "id_plano_acao"
) |> pwalk(fetch_transferegov_resource)

message("Fim de coleta de relatório de gestão.")


# :: 08.RELATÓRIO GESTÃO NOVO ESPECIAL -----------------------------------------

message("Coletando relatório de gestão (novo)...")

build_transferegov_params(
  path_input = PATH_PLANO_ACAO,
  path_output = PATH_RELATORIO_GESTAO_NOVO,
  resource = "relatorio_gestao_novo_especial",
  key_column = "id_plano_acao"
) |> pwalk(fetch_transferegov_resource)

message("Fim da coleta de relatório de gestão (novo).")


# :: 09.EXECUTOR ESPECIAL ------------------------------------------------------

message("Coletando lista de executores...")

build_transferegov_params(
  path_input = PATH_PLANO_ACAO,
  path_output = PATH_EXECUTOR,
  resource = "executor_especial",
  key_column = "id_plano_acao"
) |> pwalk(fetch_transferegov_resource)

message("Fim da coleta de lista de executores.")


# :: 10.META ESPECIAL ----------------------------------------------------------

message("Coletando metas...")

build_transferegov_params(
  path_input = PATH_EXECUTOR,
  path_output = PATH_META,
  resource = "meta_especial",
  key_column = "id_executor"
) |> pwalk(fetch_transferegov_resource)

message("Fim da coleta de metas.")


# :: 11.PLANO TRABALHO ESPECIAL ------------------------------------------------

message("Coletando planos de trabalho...")

build_transferegov_params(
  path_input = PATH_PLANO_ACAO,
  path_output = PATH_PLANO_TRABALHO,
  resource = "plano_trabalho_especial",
  key_column = "id_plano_acao"
) |> pwalk(fetch_transferegov_resource)

message("Fim da coleta de planos de trabalho.")


# :: 12.FINALIDADE ESPECIAL ----------------------------------------------------

message("Colentando lista de finalidades...")

build_transferegov_params(
  path_input = PATH_EXECUTOR,
  path_output = PATH_FINALIDADE,
  resource = "finalidade_especial",
  key_column = "id_executor"
) |> pwalk(fetch_transferegov_resource)

message("Fim da coleta de lista de finalidades.")


# :: FIM -----------------------------------------------------------------------
lubridate::now()
