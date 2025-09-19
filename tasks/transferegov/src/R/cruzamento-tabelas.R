library(tidyverse)
library(here)

PATH_TABLES <- list.files(here("tasks/transferegov/outputs"), pattern = "csv$", full.names = TRUE)
GSHEET <- "https://docs.google.com/spreadsheets/d/1luTg73bwDcl18YZSBx14zeU1i0E-qWPdP4OcZU0Py68"

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

transferegov <- read_transferegov_csvs(PATH_TABLES)


# :: PROGRAMA ------------------------------------------------------------------

# . id_programa                                  <chr> "23"
# $ ano_programa                                 <chr> "2025"
# $ modalidade_programa                          <chr> "ESPECIAL"
# . codigo_programa                              <chr> "09032025"
# $ id_orgao_superior_programa                   <chr> "308800"
# $ sigla_orgao_superior_programa                <chr> "MF"
# $ nome_orgao_superior_programa                 <chr> "Ministério da Fazenda"
# $ id_orgao_programa                            <chr> "308800"
# $ sigla_orgao_programa                         <chr> "MF"
# . nome_orgao_programa                          <chr> "Ministério da Fazenda"
# . id_unidade_gestora_programa                  <chr> "1"
# . documentos_origem_programa                   <chr> NA
# $ id_unidade_orcamentaria_responsavel_programa <chr> "308800"
# . data_inicio_ciencia_programa                 <chr> "2025-07-29"
# . data_fim_ciencia_programa                    <chr> "2025-08-05"
# . valor_necessidade_financeira_programa        <chr> "6994172321.73"
# . valor_total_disponibilizado_programa         <chr> "0"
# . valor_impedido_programa                      <chr> "90489700.62"
# . valor_a_disponibilizar_programa              <chr> "6903682621.11"
# . valor_documentos_habeis_gerados_programa     <chr> "0"
# . valor_obs_geradas_programa                   <chr> "0"
# . valor_disponibilidade_atual_programa         <chr> "0"

programa <- transferegov$programa |>
  filter(id_programa == "23")

programa |>
  as.list() |>
  enframe(name = "campo", value = "valor") |>
  unnest(valor) |>
  googlesheets4::write_sheet(GSHEET, sheet = "Programa")


# :: PLANO DE AÇÃO -------------------------------------------------------------

transferegov$plano_acao |>
  filter(id_programa == "23") |>
  mutate(across(starts_with("valor"), as.numeric)) |>
  googlesheets4::write_sheet(GSHEET, sheet = "Plano de ação - emendas")


# :: EXECUTORES ----------------------------------------------------------------

transferegov$plano_acao |>
  filter(id_programa == "23") |>
  distinct(id_plano_acao) |>
  inner_join(transferegov$executor) |>
  mutate(across(starts_with("vl_"), as.numeric)) |>
  googlesheets4::write_sheet(GSHEET, sheet = "Lista de executores")


# :: FINALIDADES ---------------------------------------------------------------

transferegov$plano_acao |>
  filter(id_programa == "23") |>
  distinct(id_plano_acao) |>
  inner_join(transferegov$executor) |>
  distinct(id_executor) |>
  inner_join(transferegov$finalidade) |>
  googlesheets4::write_sheet(GSHEET, sheet = "Finalidades")


# :: METAS ---------------------------------------------------------------------

transferegov$plano_acao |>
  filter(id_programa == "23") |>
  distinct(id_plano_acao) |>
  inner_join(transferegov$executor) |>
  distinct(id_executor) |>
  inner_join(transferegov$meta) |>
  mutate(across(starts_with("vl_"), as.numeric)) |>
  mutate(across(starts_with("qt_"), as.numeric)) |>
  googlesheets4::write_sheet(GSHEET, sheet = "Metas")


# :: PLANO DE TRABALHO ---------------------------------------------------------

transferegov$plano_acao |>
  filter(id_programa == "23") |>
  distinct(id_plano_acao) |>
  inner_join(transferegov$plano_trabalho) |>
  mutate(across(starts_with("data_"), as_date)) |>
  googlesheets4::write_sheet(GSHEET, sheet = "Plano de Trabalho")
