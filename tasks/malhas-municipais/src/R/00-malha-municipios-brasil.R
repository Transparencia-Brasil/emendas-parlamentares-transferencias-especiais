#' :: DESCRIÇÃO ================================================================
#' Coletando shapefiles dos municípios do Brasil no IBGE.

# :: LIBS ======================================================================
library(tidyverse)
library(here)
library(sf)

# :: FILEPATHS =================================================================

TASK <- "tasks/malhas-municipais"

# DIRETÓRIOS -------------------------------------------------------------------

# diretório para receber os dados brutos desta task:
OUTPUT_DIR <- here(TASK, "outputs")

# diretório temporário para receber o conjunto de arquivos zipado
TMP_DIR <- here(TASK, "tmp")

# Criando diretórios
dir.create(TMP_DIR)
dir.create(OUTPUT_DIR)

# inclui arquivos brutos em .gitignore
usethis::use_git_ignore(OUTPUT_DIR) # muito grande!
usethis::use_git_ignore(TMP_DIR) # muito grande!


# FTP --------------------------------------------------------------------------
URL_BASE <- "https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2022/Brasil/BR"

MUNICS_ZIPFILE_FTP <- str_glue("{URL_BASE}/BR_Municipios_2022.zip")
UFS_ZIPFILE_FTP <- str_glue("{URL_BASE}/BR_UF_2022.zip")


# ZIPFILES ---------------------------------------------------------------------
MUNICS_ZIPFILE_LOCAL <- str_glue("{TMP_DIR}/BR_Municipios_2022.zip")
UFS_ZIPFILE_LOCAL <- str_glue("{TMP_DIR}/BR_UF_2022.zip")


# SHP --------------------------------------------------------------------------
# shapefiles originais
MUNICS_SHP <- str_glue("{TMP_DIR}/BR_Municipios_2022.shp")
UFS_SHP <- str_glue("{TMP_DIR}/BR_UF_2022.shp")


# RDS --------------------------------------------------------------------------
# malha de municípíos e ufs em rds - resultado
MUNICS_RDS <- str_glue("{OUTPUT_DIR}/municipios-sf.rds")
UFS_RDS <- str_glue("{OUTPUT_DIR}/ufs-sf.rds")

# mantém somente ids de municípios
MUNICS_IDS_RDS <- str_glue("{OUTPUT_DIR}/municipios.rds")

# :: DOWNLOAD ==================================================================

download.file(
  url = MUNICS_ZIPFILE_FTP,
  destfile = MUNICS_ZIPFILE_LOCAL,
  mode = "wb"
)


download.file(
  url = UFS_ZIPFILE_FTP,
  destfile = UFS_ZIPFILE_LOCAL,
  mode = "wb"
)


# UNZIP ========================================================================

unzip(
  zipfile = MUNICS_ZIPFILE_LOCAL,
  exdir = TMP_DIR
)

unzip(
  zipfile = UFS_ZIPFILE_LOCAL,
  exdir = TMP_DIR
)


# :: LEITURA ===================================================================

# shp2rds

munics <- read_sf(MUNICS_SHP)
ufs <- read_sf(UFS_SHP)

# :: TRANSFORMA ================================================================

# essa versão mantém atributos espaciais (para fazer mapas)
munics <- munics %>%
  as_tibble() %>%
  transmute(
    codigo_ibge = CD_MUN,
    nome_municipio = NM_MUN,
    uf = SIGLA_UF,
    geometry = geometry
  )

# essa versão mantém somente ids
munics_ids <- munics %>%
  select(-geometry)


# somente atributos espaciais das ufs, pois a única finalidade é fazer mapas
ufs <- ufs %>%
  as_tibble() %>%
  transmute(
    codigo_uf = CD_UF,
    nome_uf = NM_UF,
    uf = SIGLA_UF,
    nome_regiao = NM_REGIAO,
    geometry = geometry
  )

# :: SAVE ======================================================================

saveRDS(ufs, UFS_RDS)
saveRDS(munics, MUNICS_RDS)
saveRDS(munics_ids, MUNICS_IDS_RDS)
