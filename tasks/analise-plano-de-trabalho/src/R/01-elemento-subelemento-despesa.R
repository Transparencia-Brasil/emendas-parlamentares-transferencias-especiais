library(here)
library(tidyverse)
source(here("tasks/analise-plano-de-trabalho/utils.R"))

# :: FILEPATHS -----------------------------------------------------------------

TASK_DESPESA <- "tasks/classificacao-natureza-despesa/outputs"
TASK_TRANSFEREGOV <- "tasks/transferegov/outputs"

PATH_TABLES <- list.files(TASK_TRANSFEREGOV, pattern = "csv$", full.names = TRUE)
PATH_DESPESAS <- list.files(TASK_DESPESA, pattern = "rds$", full.names = TRUE)


# :: READ DATA -----------------------------------------------------------------

read_files <- \(x) {
  ids <- basename(x) |>
    snakecase::to_snake_case() |>
    str_remove("^\\d+_") |>
    str_remove("_(csv|rds)$") |>
    str_remove("_especial$")

  if (unique(str_detect(x, "csv$"))) {
    df <- map(x, read_csv, col_types = cols(.default = col_character())) |>
      set_names(ids)
  }

  if (unique(str_detect(x, "rds$"))) {
    df <- map(x, readRDS) |>  set_names(ids)
  }

  return(df)
}

transferegov <- read_files(PATH_TABLES)
despesa <- read_files(PATH_DESPESAS)

# :: PERGUNTAS ::
# ---------------

# :: PERGUNTA 1.a --------------------------------------------------------------

#' Quantos e quais id_plano_acao contêm o elemento de despesa no campo
#'  `objeto_executor` da tabela Lista de executores?

executores <- transferegov$plano_acao |>
  filter(id_programa == "23") |>
  distinct(id_plano_acao) |>
  inner_join(transferegov$executor) |>
  mutate(across(starts_with("vl_"), as.numeric))

executores <- executores |>
  select(id_plano_acao, id_executor, objeto_executor) |>
  mutate(objeto_limpo = tidy_text(objeto_executor))

despesa$natureza_de_despesas |>
  filter(str_detect(subsecao_ii, "^D")) |>
  select(-subsecao_ii) |>
  unnest(data) |>
  select(subsecao_iii)
