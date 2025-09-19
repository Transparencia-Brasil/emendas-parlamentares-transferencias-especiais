options(width = 150)
library(here)
library(tidyverse)
library(readxl)
library(gt)


# :: PATHS ---------------------------------------------------------------------

PATH_EMENDAS_GPT <- here("tasks/analise-classificacoes-gpt5/inputs/emendas-gpt.xlsx")


# :: LOAD DATA -----------------------------------------------------------------

# :: LOAD DATA -----------------------------------------------------------------

emendas_gpt <- readxl::read_excel(PATH_EMENDAS_GPT) |>
  janitor::clean_names()

# :: QUICK ANALYSIS TABLE ------------------------------------------------------

tabela_classificacoes <- emendas_gpt |>
  count(classificacao_detalhamento_objeto, classificacao_justifificativa, sort = TRUE) |>
  gt() |>
  tab_header(
    title = "Contagem das Classificações das Emendas",
    subtitle = "Detalhamento do objeto e justificativa"
  ) |>
  fmt_number(
    columns = n,
    sep_mark = ".",
    dec_mark = ",",
    decimals = 0
  ) |>
  cols_label(
    classificacao_detalhamento_objeto = "Detalhamento do Objeto",
    classificacao_justifificativa = "Justificativa",
    n = "Quantidade"
  ) |>
  opt_row_striping()

print(tabela_classificacoes)

# :: SUMMARY BY PLAN -----------------------------------------------------------

resumo_por_plano <- emendas_gpt |>
  summarise(
    .by = c(
      id_plano_acao, id_plano_trabalho, id_executor,
      classificacao_detalhamento_objeto, classificacao_justifificativa
    ),
    qtd_metas = n()
  ) |>
  mutate(
    total_metas = sum(qtd_metas),
    perc_metas = qtd_metas / total_metas
  )

print(resumo_por_plano)