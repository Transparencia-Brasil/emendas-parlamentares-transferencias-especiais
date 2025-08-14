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


# :: 01.PROGRAMA ESPECIAL ------------------------------------------------------

programa_especial <- fetch_transferegov_resource(
  resource = "programa_especial",
  key = NULL,
  perc = NULL,
  PATH_PROGRAMA
)


# :: 02.PLANO DE AÇÂO ESPECIAL -------------------------------------------------

build_transferegov_params(
  path_input = PATH_PROGRAMA,
  path_output = PATH_PLANO_ACAO,
  resource = "plano_acao_especial",
  key_column = "id_programa"
) |> pwalk(fetch_transferegov_resource)


# :: 03.EMPENHO ESPECIAL -------------------------------------------------------

build_transferegov_params(
  path_input = PATH_PLANO_ACAO,
  path_output = PATH_EMPENHO,
  resource = "empenho_especial",
  key_column = "id_plano_acao"
) |> pwalk(fetch_transferegov_resource)


# :: 04.DOCUMENTO HÁBIL ESPECIAL -----------------------------------------------

build_transferegov_params(
  path_input = PATH_EMPENHO,
  path_output = PATH_DOCUMENTO_HABIL,
  resource = "documento_habil_especial",
  key_column = "id_empenho"
) |> pwalk(fetch_transferegov_resource)


# :: 05.ORDEM PAGAMENTO - ORDEM BANCÁRIA ESPECIAL ------------------------------

build_transferegov_params(
  path_input = PATH_DOCUMENTO_HABIL,
  path_output = PATH_ORDEM_PAGAMENTO,
  # resource = "historico_pagamento_especial",
  resource = "ordem_pagamento_ordem_bancaria_especial",
  key_column = "id_dh"
) |> pwalk(fetch_transferegov_resource)


# :: 06.HISTÓRICO PAGAMENTO ESPECIAL -------------------------------------------

build_transferegov_params(
  path_input = PATH_ORDEM_PAGAMENTO,
  path_output = PATH_HISTORICO_PAGAMENTO,
  resource = "historico_pagamento_especial",
  key_column = "id_op_ob"
) |> pwalk(fetch_transferegov_resource)


# :: 07.RELATÓRIO GESTÃO ESPECIAL ----------------------------------------------

build_transferegov_params(
  path_input = PATH_PLANO_ACAO,
  path_output = PATH_RELATORIO_GESTAO,
  resource = "relatorio_gestao_especial",
  key_column = "id_plano_acao"
) |> pwalk(fetch_transferegov_resource)


# :: 08.RELATÓRIO GESTÃO NOVO ESPECIAL -----------------------------------------

build_transferegov_params(
  path_input = PATH_PLANO_ACAO,
  path_output = PATH_RELATORIO_GESTAO_NOVO,
  resource = "relatorio_gestao_novo_especial",
  key_column = "id_plano_acao"
) |> pwalk(fetch_transferegov_resource)


# :: 09.EXECUTOR ESPECIAL ------------------------------------------------------

build_transferegov_params(
  path_input = PATH_PLANO_ACAO,
  path_output = PATH_EXECUTOR,
  resource = "executor_especial",
  key_column = "id_plano_acao"
) |> pwalk(fetch_transferegov_resource)


# :: 10.META ESPECIAL ----------------------------------------------------------

build_transferegov_params(
  path_input = PATH_EXECUTOR,
  path_output = PATH_META,
  resource = "meta_especial",
  key_column = "id_executor"
) |> pwalk(fetch_transferegov_resource)


# :: 11.PLANO TRABALHO ESPECIAL ------------------------------------------------

build_transferegov_params(
  path_input = PATH_PLANO_ACAO,
  path_output = PATH_PLANO_TRABALHO,
  resource = "plano_trabalho_especial",
  key_column = "id_plano_acao"
) |> pwalk(fetch_transferegov_resource)


# :: 12.FINALIDADE ESPECIAL ----------------------------------------------------

build_transferegov_params(
  path_input = PATH_EXECUTOR,
  path_output = PATH_FINALIDADE,
  resource = "finalidade_especial",
  key_column = "id_executor"
) |> pwalk(fetch_transferegov_resource)
