library(tidyverse)
library(here)
library(sf)
options(width = 150)

# :: FILEPATHS -----------------------------------------------------------------

UTILS <- here("tasks/db/src/R/utils.R")
source(UTILS)

TASK <- "tasks/malhas-municipais"

OUTPUT_DIR <- here(TASK, "outputs")

# malha de municípíos e ufs em rds - resultado
MUNICS_RDS <- str_glue("{OUTPUT_DIR}/municipios-sf.rds")
UFS_RDS <- str_glue("{OUTPUT_DIR}/ufs-sf.rds")

# mantém somente ids de municípios
MUNICS_IDS_RDS <- str_glue("{OUTPUT_DIR}/municipios.rds")


# :: LEITURA -------------------------------------------------------------------

# shp2rds
munics <- readRDS(MUNICS_RDS)
ufs <- readRDS(UFS_RDS)


# :: BENEFICIÁRIOS -------------------------------------------------------------

cli::cat_rule("Lendo CSVs de tasks/transferegov/outputs/")
tabelas <- ler_csvs_transferegov()

beneficiarios <- tabelas$plano_acao |>
  select(contains("beneficiario")) |>
  distinct()


# :: ETL -----------------------------------------------------------------------

#' Gera chave normalizada para município ou UF
#'
#' @param nome Nome do município ou estado
#' @param uf Sigla da UF
#'
#' @return Chave normalizada em minúsculas com caracteres especiais removidos
#'
#' @examples
#' make_key("São Paulo", "SP")
#'
make_key <- function(nome, uf) {
  key <- nome |>
    str_to_lower() |>
    str_to_lower() |>
    stringi::stri_trans_general("Latin-ASCII") |>
    str_remove("prefeitura municipal") |>
    str_remove("^municipio d[aeiou] ") |>
    str_replace_all("'|\\:", "") |>
    str_squish() |>
    str_replace("sao thome das letras", "sao tome das letras") |>
    str_replace("santa isabel do para", "santa izabel do para") |>
    str_replace("sao valerio da natividade", "sao valerio") |>
    str_replace("sao miguel doeste", "sao miguel do oeste") |>
    str_replace("sao lourenco doeste", "sao lourenco do oeste") |>
    str_replace("santo antonio d[oe] leverger", "santo antonio de leverger") |>
    str_replace("pingo dagua", "pingo-dagua") |>
    str_replace("pindare mirim", "pindare-mirim") |>
    str_replace("munhoz de mello", "munhoz de melo") |>
    str_replace("mogi guacu", "mogi-guacu") |>
    str_replace("jahu", "jau") |>
    str_replace("lagedo do tabocal", "lajedo do tabocal") |>
    str_replace("iguaraci", "iguaracy") |>
    str_replace("grao para", "grao-para") |>
    str_replace("graccho", "gracho") |>
    str_replace("gouvea", "gouveia") |>
    str_replace("fortaleza do tabocao", "tabocao") |>
    str_replace("entre ijuis", "entre-ijuis") |>
    str_replace("couto de magalhaes", "couto magalhaes") |>
    str_replace("cerro-cora", "cerro cora") |>
    str_replace("brasopolis", "brazopolis")

    key <- if_else(
      str_detect(key, "estado d[eoa]"),
      str_glue("{uf}"),
      str_glue("{key}-{uf}")
    )

    key <- key |>
      str_replace("presidente juscelino-RN", "serra caiada-RN") |>
      str_replace("santa teresinha-BA", "santa terezinha-BA") |>
      str_replace("bom jesus-GO", "bom jesus de goias-GO") |>
      str_replace("boa saude-RN", "januario cicco-RN") |>
      str_replace("bela vista do caroba-PR", "bela vista da caroba-PR") |>
      str_replace("balneario de picarras-SC", "balneario picarras-SC") |>
      str_replace("armacao de buzios-RJ", "armacao dos buzios-RJ") |>
      str_replace("amparo de sao francisco-SE", "amparo do sao francisco-SE") |>
      str_replace("estancia turistica de olimpia-SP", "olimpia-SP") |>
      str_replace("distrito federal-DF", "brasilia-DF")

    key
}

# gera chave normalizada para município ou UF
benef <- beneficiarios |>
  mutate(
    .before = everything(),
    key = make_key(nome_beneficiario_plano_acao, uf_beneficiario_plano_acao)
  ) |>
  select(
    key,
    cnpj_beneficiario = cnpj_beneficiario_plano_acao
  )

# gera chave normalizada para município
mun <- munics |>
  mutate(
    .before = everything(),
    key = make_key(nome_municipio, sigla_uf)
  ) |>
  select(
    key,
    codigo_ibge_municipio = codigo_ibge,
    codigo_ibge_uf
  )

# gera chave normalizada para uf
uf <- ufs |>
  select(
    key = sigla_uf,
    codigo_ibge_uf
  )

# associa beneficiários a municípios ou ufs, conforme chave normalizada
benef <- benef |>
  mutate(
    territorialidade = case_when(
      key %in% mun$key ~ "municipio",
      key %in% uf$key ~ "uf",
      TRUE ~ "desconecido"
    )
  ) |>
  nest(.by = territorialidade) |>
  mutate(
    data = if_else(
      territorialidade == "municipio",
      map(data, ~ left_join(.x, mun)),
      map(data, ~ left_join(.x, uf))
    )
  ) |>
  unnest(data) |>
  select(-territorialidade, -key)

# associa beneficiários a municípios ou ufs nas tabelas de plano de ação e empenho
tabelas$plano_acao <- tabelas$plano_acao |>
  left_join(benef, by = c("cnpj_beneficiario_plano_acao" = "cnpj_beneficiario"))

tabelas$empenho <- tabelas$empenho |>
  left_join(benef, by = c("cnpj_beneficiario_empenho" = "cnpj_beneficiario"))


# :: SALVA ---------------------------------------------------------------------

# salva tabelas atualizadas
CSV_PLANO_ACAO <- str_glue("{CSV_DIR}/02-plano-acao.csv")
CSV_EMPENHO <- str_glue("{CSV_DIR}/03-empenho.csv")

tabelas$plano_acao |> glimpse()
tabelas$empenho |> glimpse()

data.table::fwrite(
  tabelas$plano_acao,
  CSV_PLANO_ACAO,
  sep = ",",
  row.names = FALSE,
  quote = TRUE
)

data.table::fwrite(
  tabelas$empenho,
  CSV_EMPENHO,
  sep = ",",
  row.names = FALSE,
  quote = TRUE
)

munics |>
  select(-geometry) |>
  write_csv(str_glue("{OUTPUT_DIR}/municipios.csv"))

ufs |>
  select(-geometry) |>
  write_csv(str_glue("{OUTPUT_DIR}/uf.csv"))
