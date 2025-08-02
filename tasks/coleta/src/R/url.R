library(tidyverse)
library(here)
library(httr2)
library(jsonlite)

PATH_UTILS <- here("tasks/coleta/src/R/utils.R")
source(PATH_UTILS)


URL_PROGRAMA_ESPECIAL <- "https://api.transferegov.gestao.gov.br/transferenciasespeciais/programa_especial"

programa_especial <- coleta_endpoint(URL_PROGRAMA_ESPECIAL) |>
    glimpse()

URL_PLANO_ACAO_ESPECIAL <- "https://api.transferegov.gestao.gov.br/transferenciasespeciais/plano_acao_especial?id_programa=eq.%2023&offset=11000&limit=1000"

plano_acao_especial <- coleta_endpoint(URL_PLANO_ACAO_ESPECIAL)

coleta_plano_acao <- function(id_programa, offset = 0, limit = 1000) {

    URL_BASE <- "https://api.transferegov.gestao.gov.br/transferenciasespeciais/plano_acao_especial"
    URL_BASE_PARAMETRIZADA <- "{URL_BASE}?id_programa={id_programa}&offset={offset}&limit={limit}"

    URL_PARAMETRIZADA <- str_glue(URL_BASE_PARAMETRIZADA)

    flush.console()
    cat(offset, "resultados coletados\r")

    result <- coleta_endpoint(URL_PARAMETRIZADA)

    repeat {
        offset <- offset + limit
        URL_PARAMETRIZADA <- str_glue(URL_BASE_PARAMETRIZADA)
        flush.console()
        cat(offset, "resultados coletados\r")

        result_next_page <- coleta_endpoint(URL_PARAMETRIZADA)

        # Se não houver mais dados, encerra o loop
        if (nrow(result_next_page) == 0) break

        # Junta os resultados
        result <- bind_rows(result, result_next_page)
    }

    return(result)

}

plano_acao <- coleta_plano_acao(id_programa = "eq.23")
plano_acao |>
    glimpse()
