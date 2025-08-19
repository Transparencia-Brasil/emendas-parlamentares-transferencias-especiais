library(httr2)
library(here)
library(tidyverse)

URL_PORTARIA_103_2021 <- "https://www.in.gov.br/en/web/dou/-/portaria-conunta-stn/sof/me-n-103-de-5-de-outubro-de-2021-351613861"

# Anexo III
PATH_NATUREZA_DESPESA <- here("tasks/transferegov/outputs/portaria-103-2021/natureza-de-despesas.rds")


# ANEXO II ---------------------------------------------------------------------

natureza_despesa <- URL_PORTARIA_103_2021 |>
  request() |>
  req_perform() |>
  resp_body_html(encoding = "utf-8") |>
  xml2::xml_find_all('//*[@id="materia"]/div/div[3]') |>
  xml2::xml_text() |>
  str_split("\n") |>
  as_tibble_col(column_name = "texto") |>
  unnest(texto) |>
  mutate(texto = str_squish(texto)) |>
  filter(texto != "") |>
  mutate(secao = if_else(str_starts(texto, "ANEXO"), texto, NA_character_), .before = texto) |>
  fill(secao, .direction = "down") |>
  filter(secao == "ANEXO II") |>
  mutate(titulo = "NATUREZA DE DESPESA", .before = everything()) |>
  mutate(subsecao_i = if_else(str_starts(texto, "(I|II) - "), texto, NA_character_), .before = texto) |>
  mutate(subsecao_ii = if_else(str_starts(texto, "[A-D] - "), texto, NA_character_), .before = texto) |>
  mutate(subsecao_iii = if_else(str_starts(texto, "[0-9]+\\s?-\\s?"), texto, NA_character_), .before = texto) |>
  fill(subsecao_i,subsecao_ii, .direction = "down") |>
  filter(titulo != texto) |>
  filter(secao != texto) |>
  filter(subsecao_i != texto) |>
  filter(subsecao_ii != texto) |>
  fill(subsecao_iii, .direction = "down") |>
  mutate(texto = if_else(texto == subsecao_iii, NA_character_, texto)) |>
  filter(!(subsecao_i == "II - DOS CONCEITOS E ESPECIFICAÇÕES" & is.na(texto))) |>
  group_by(across(titulo:subsecao_iii)) |>
  mutate(idx = paste0("linha_", row_number())) |>
  pivot_wider(names_from = idx, values_from = texto) |>
  ungroup() |>
  unite(linha_1:linha_6,col = "paragrafo", sep = "\n", na.rm = TRUE)

natureza_despesa |>
  filter(subsecao_i == "I - DA ESTRUTURA") |>
  select(subsecao_ii, subsecao_iii) |>
  nest_by(subsecao_ii) |>
  deframe()

# ANEXO III --------------------------------------------------------------------

# Anexo III da Portaria Conjunta STN/SOF nº 163, de 2001, consolidada pela Portaria Conjunta STN/SOF/ME nº 103, de 5 de outubro de 2021.
# Onde vou salvar as classificações com natureza e elemento de despesa

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

# salva
saveRDS(anexo_iii, PATH_NATUREZA_DESPESA)
