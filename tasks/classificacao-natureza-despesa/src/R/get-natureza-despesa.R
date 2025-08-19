library(httr2)
library(here)
library(tidyverse)


# :: FILEPATHS -----------------------------------------------------------------

TASK_DIR <- "tasks/classificacao-natureza-despesa/outputs"

# Anexo III
PATH_DISCRIMINACAO_NATUREZA_DESPESA <- here(TASK_DIR, "discriminacao-natureza-de-despesas.rds")
PATH_NATUREZA_DESPESA <- here(TASK_DIR, "natureza-de-despesas.rds")

# Dicionario:
# "https://docs.google.com/spreadsheets/d/1IRAMky8cgDtGMHrpLZyPBD1FFdG5SmclnjoTzxYiABI"
URL_DICIONARIO <- "1IRAMky8cgDtGMHrpLZyPBD1FFdG5SmclnjoTzxYiABI"


# :: URL BASE DA PORTARIA 103-2021 ---------------------------------------------

# Anexo III da Portaria Conjunta STN/SOF nº 163, de 2001, consolidada pela Portaria Conjunta STN/SOF/ME nº 103, de 5 de outubro de 2021.

URL_PORTARIA_103_2021 <- "https://www.in.gov.br/en/web/dou/-/portaria-conunta-stn/sof/me-n-103-de-5-de-outubro-de-2021-351613861"


# ANEXO II ---------------------------------------------------------------------

# Scrap portaria - retorna um texto
natureza_despesa <- URL_PORTARIA_103_2021 |>
  request() |>
  req_perform() |>
  resp_body_html(encoding = "utf-8") |>
  xml2::xml_find_all('//*[@id="materia"]/div/div[3]') |>
  xml2::xml_text()

# Atribui tabularidade ao texto
natureza_despesa <- natureza_despesa |>
  str_split("\n") |>
  as_tibble_col(column_name = "texto") |>
  unnest(texto) |>
  mutate(texto = str_squish(texto))

# Filtra o anexo II do texto
natureza_despesa <- natureza_despesa |>
  filter(texto != "") |>
  mutate(secao = if_else(str_starts(texto, "ANEXO"), texto, NA_character_), .before = texto) |>
  fill(secao, .direction = "down") |>
  filter(secao == "ANEXO II")

# Extrai estrutura de tópicos
natureza_despesa <- natureza_despesa |>
  mutate(
    titulo = "NATUREZA DE DESPESA",
    subsecao_i = if_else(str_starts(texto, "(I|II) - "), texto, NA_character_),
    subsecao_ii = if_else(str_starts(texto, "[A-D] - "), texto, NA_character_),
    subsecao_iii = if_else(str_starts(texto, "[0-9]+\\s?-\\s?"), texto, NA_character_)
  ) |>
  fill(subsecao_i,subsecao_ii, .direction = "down")

# remove linhas repetitivas
natureza_despesa <- natureza_despesa |>
  filter(titulo != texto) |>
  filter(secao != texto) |>
  filter(subsecao_i != texto) |>
  filter(subsecao_ii != texto)

# inclui estrutura de tópicos de nível iii e remove mais linhas repetitivas
natureza_despesa <- natureza_despesa |>
  fill(subsecao_iii, .direction = "down") |>
  mutate(texto = if_else(texto == subsecao_iii, NA_character_, texto)) |>
  filter(!(subsecao_i == "II - DOS CONCEITOS E ESPECIFICAÇÕES" & is.na(texto)))

# pivot para consolidar parágrafo em uma única
natureza_despesa <- natureza_despesa |>
  group_by(across(titulo:subsecao_iii)) |>
  mutate(idx = paste0("linha_", row_number())) |>
  pivot_wider(names_from = idx, values_from = texto) |>
  ungroup() |>
  unite(linha_1:linha_6, col = "paragrafo", sep = "\n", na.rm = TRUE)

# Finaliza a estruturação de conceitos
conceitos <- natureza_despesa |>
  filter(subsecao_i == "II - DOS CONCEITOS E ESPECIFICAÇÕES") |>
  select(subsecao_ii, subsecao_iii, conceito = paragrafo) |>
  nest_by(subsecao_ii) |>
  deframe() |>
  map(~ separate(.x, subsecao_iii, c("codigo", "descricao"), "\\s?- ", extra = "merge"))

# exporta pra Gsheets
enframe(conceitos) |>
  mutate(salva = map2(value, name, googlesheets4::write_sheet, ss = URL_DICIONARIO))

# exporta para RDS
natureza_despesa |>
  filter(subsecao_i == "II - DOS CONCEITOS E ESPECIFICAÇÕES") |>
  select(subsecao_ii, subsecao_iii, conceito = paragrafo) |>
  nest_by(subsecao_ii) |>
  saveRDS(PATH_NATUREZA_DESPESA)


# ANEXO III --------------------------------------------------------------------

# faz o parse do texto da portaria
portaria <- URL_PORTARIA_103_2021 |>
  request() |>
  req_perform() |>
  resp_body_html(encoding = "utf-8") |>
  xml2::xml_find_all('//*[@id="materia"]/div/div[3]/table[2]/tbody[1]') |>
  xml2::xml_text()

# raspa a tabela do anexo III com classificações de despesa
anexo_iii <- portaria |>
  str_split("\n") |>
  as_tibble_col(column_name = "texto") |>
  unnest(texto) |>
  mutate(texto = str_squish(texto)) |>
  filter(!texto  %in% c("", "CODIGO", "DESCRIÇÃO")) |>
  mutate(codigo = if_else(str_starts(texto, "\\d"), texto, NA_character_), .before = texto) |>
  fill(codigo, .direction = "down") |>
  filter(texto != codigo)

# exporta para RDS
saveRDS(anexo_iii, PATH_DISCRIMINACAO_NATUREZA_DESPESA)

# exporta pra Gsheets
anexo_iii |>
  googlesheets4::write_sheet(
    ss = URL_DICIONARIO,
    sheet = "III - DISCRIMINAÇÃO DAS NATUREZAS DE DESPESA"
  )
