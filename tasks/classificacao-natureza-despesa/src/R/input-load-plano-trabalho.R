library(here)
library(tidyverse)


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


# :: LOAD TRANSFEREGOV ---------------------------------------------------------

# helper para carregar os dados
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

# carrega todos os dados
transferegov <- read_transferegov_csvs(PATH_TRANSFEREGOV_TABLES)

# isolando o campo objeto_executor
executores <- transferegov$plano_acao |>
  filter(id_programa == "23") |>
  distinct(id_plano_acao) |>
  inner_join(transferegov$executor) |>
  mutate(across(starts_with("vl_"), as.numeric)) |>
  select(id_plano_acao, id_executor, objeto_executor)

# isolando o campo desc_meta
metas <- transferegov$plano_acao |>
  filter(id_programa == "23") |>
  distinct(id_plano_acao) |>
  inner_join(transferegov$executor) |>
  distinct(id_executor) |>
  inner_join(transferegov$meta) |>
  mutate(across(starts_with("vl_"), as.numeric)) |>
  mutate(across(starts_with("qt_"), as.numeric)) |>
  select(id_executor, id_meta, desc_meta)

metas |> write_csv(PATH_METAS_CSV)
executores |> write_csv(PATH_EXECUTORES_CSV)


# :: LOAD CATEGORIAS DE DESPESA ------------------------------------------------

natureza_despesa <- readRDS(PATH_NATUREZA_DESPESA)

natureza_despesa |>
  enframe() |>
  unnest(value) |>
  write_csv(PATH_NATUREZA_DESPESA_CSV)

discriminacao_natureza_despesa <- readRDS(PATH_DISCRIMINACAO_NATUREZA_DESPESA)
write_csv(discriminacao_natureza_despesa, PATH_DISCRIMINACAO_NATUREZA_DESPESA_CSV)
