options(width = 150)
library(here)
library(tidyverse)
library(readxl)
library(gt)


# :: PATHS ---------------------------------------------------------------------

PATH_EMENDAS_GPT <- here("tasks/analise-classificacoes-gpt5/inputs/emendas-gpt.xlsx")

PATH_META <- here("tasks/transferegov/outputs/10-meta.csv")


# :: METAS ---------------------------------------------------------------------

metas <- transferegov$plano_acao |>
  filter(id_programa == "23") |>
  distinct(id_plano_acao) |>
  inner_join(transferegov$executor) |>
  distinct(id_executor) |>
  inner_join(transferegov$meta) |>
  mutate(across(starts_with("vl_"), as.numeric)) |>
  mutate(across(starts_with("qt_"), as.numeric))

# :: LOAD DATA -----------------------------------------------------------------

emendas_gpt <- readxl::read_excel(PATH_EMENDAS_GPT, col_types = "text") |>
  janitor::clean_names() |>
  mutate(
    id_meta = str_remove(id_meta, "0$"),
    sequencial_meta = str_remove(sequencial_meta, "0$")
  )


meta <- metas |>
  rowwise() |>
  transmute(
    id_executor,
    id_meta,
    sequencial_meta,
    vl_custeio = vl_custeio_emenda_especial_meta,
    vl_investimento = vl_investimento_emenda_especial_meta,
    vl_total = vl_custeio + vl_investimento
  )


# :: CONTAGEM GERAL DAS CLASSIFICAÇÕES -----------------------------------------

emendas_gpt |>
  count(classificacao_detalhamento_objeto, classificacao_justificativa, sort = TRUE) |>
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
    classificacao_justificativa = "Justificativa",
    n = "Quantidade"
  ) |>
  opt_row_striping()


# :: VALOR TOTAL DAS EMENDAS POR CLASSIFICAÇÃO ---------------------------------


emendas_gpt |>
  left_join(meta) |>
  summarise(
    vl_custeio = sum(vl_custeio, na.rm = TRUE),
    vl_investimento = sum(vl_investimento, na.rm = TRUE),
    vl_total = sum(vl_total, na.rm = TRUE),
    .by = c(classificacao_detalhamento_objeto, classificacao_justificativa)
  ) |>
  gt() |>
  tab_header(
    title = "Valor Total das Emendas por Classificação",
    subtitle = "Soma dos valores por detalhamento e justificativa"
  ) |>
  fmt_number(
    columns = c(vl_custeio, vl_investimento, vl_total),
    sep_mark = ".",
    dec_mark = ",",
    decimals = 0
  ) |>
  cols_label(
    classificacao_detalhamento_objeto = "Detalhamento do Objeto",
    classificacao_justificativa = "Justificativa",
    vl_custeio = "Valor Custeio",
    vl_investimento = "Valor Investimento",
    vl_total = "Valor Total"
  ) |>
  opt_row_striping()


# :: SUMMARY BY PLAN -----------------------------------------------------------

resumo_por_plano <- emendas_gpt |>
  filter(id_plano_acao %in% c("76888", "79197", "76436", "80284")) |>
  summarise(
    .by = c(
      chave,
      classificacao_detalhamento_objeto, classificacao_justificativa
    ),
    qtd_metas = n()
  ) |>
  group_by(chave) |>
  mutate(
    total_metas = sum(qtd_metas),
    perc_metas = qtd_metas / total_metas
  ) |>
  ungroup()


resumo_por_plano |>
  select(chave, classificacao_detalhamento_objeto, classificacao_justificativa, qtd_metas, total_metas, perc_metas) |>
  gt(groupname_col = "chave") |>
  tab_header(
    title = "Resumo por Plano de Ação",
    subtitle = "Distribuição das metas por detalhamento e justificativa"
  ) |>
  fmt_number(
    columns = c(qtd_metas, total_metas, perc_metas),
    decimals = 0,
    sep_mark = ".",
    dec_mark = ","
  ) |>
  fmt_percent(
    columns = perc_metas,
    decimals = 1
  ) |>
  cols_label(
    chave = "Chave",
    classificacao_detalhamento_objeto = "Detalhamento do Objeto",
    classificacao_justificativa = "Justificativa",
    qtd_metas = "Qtd. Metas",
    total_metas = "Total Metas",
    perc_metas = "% Metas"
  ) |>
  opt_row_striping() |>
  opt_table_outline() |>
  tab_options(
    table.font.size = "14px",
    heading.background.color = "#F5F5F5"
  ) |>
  tab_style(
    style = cell_text(indent = px(48)),
    locations = cells_body(columns = "classificacao_detalhamento_objeto")
  )

emendas_gpt |>
  filter(chave == "76436-35942-38823") |>
  # summarise(
  #   .by = c(classificacao_justificativa, objeto_executor, desc_meta)
  # ) |>
  View()
