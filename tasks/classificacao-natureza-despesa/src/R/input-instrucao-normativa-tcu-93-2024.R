library(httr2)
library(here)
library(tidyverse)


# :: FILEPATHS -----------------------------------------------------------------

INPUT_DIR <- "tasks/classificacao-natureza-despesa/inputs"

# Texto completo
PATH_TEXTO_COMPLETO_TXT <- here(
  INPUT_DIR,
  "texto-completo-portaria-15-2025.txt"
)


# :: URL BASE DA PORTARIA 15-2025 ----------------------------------------------

# APORTARIA CONJUNTA MF/MGI Nº 15, DE 28 DE JULHO DE 2025.

URL_PORTARIA_15_2025 <- "https://www.in.gov.br/en/web/dou/-/portaria-conjunta-mf/mgi-n-15-de-28-de-julho-de-2025-644990894"

# Scrap portaria - retorna um texto
texto_completo <- URL_PORTARIA_15_2025 |>
  request() |>
  req_perform() |>
  resp_body_html(encoding = "utf-8") |>
  xml2::xml_find_all('//*[@id="materia"]/div/div[3]') |>
  xml2::xml_text()

write_lines(texto_completo, PATH_TEXTO_COMPLETO_TXT)
