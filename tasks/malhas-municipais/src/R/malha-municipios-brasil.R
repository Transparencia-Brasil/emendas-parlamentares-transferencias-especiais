#' :: DESCRIÇÃO ================================================================
#' Coletando shapefiles dos municípios do Brasil no IBGE.

# :: LIBS ======================================================================
library(tidyverse)
library(here)
library(sf)

# :: FILEPATHS =================================================================

# DIRETÓRIOS -------------------------------------------------------------------
# diretório para receber os dados brutos desta task:
malha_munics <- here("data/ibge/malha-municipios-brasil")

# diretório temporário para receber o conjunto de arquivos zipado
tmp <- here("tasks/ibge-malha-de-municipios/tmp")
# Criando diretórios
dir.create(tmp)
dir.create(malha_munics, recursive = TRUE)

# inclui arquivos brutos em .gitignore
usethis::use_git_ignore("malha-municipios-brasil") # muito grande!

# FTP --------------------------------------------------------------------------
munics_zipfile_ftp <- "https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2022/Brasil/BR/BR_Municipios_2022.zip"
ufs_zipfile_ftp <- "https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2022/Brasil/BR/BR_UF_2022.zip"

# ZIPFILES ---------------------------------------------------------------------
munics_zipfile_local <- str_glue("{tmp}/BR_Municipios_2022.zip")
ufs_zipfile_local <- str_glue("{tmp}/BR_UF_2022.zip")

# SHP --------------------------------------------------------------------------
# shapefiles originais
path_to_munics_shp <- here(str_glue("{malha_munics}/BR_Municipios_2022.shp"))
path_to_ufs_shp <- here(str_glue("{malha_munics}/BR_UF_2022.shp"))

# RDS --------------------------------------------------------------------------
# malha de municípíos e ufs em rds - resultado
path_to_munics <- here("data/ibge/malha-municipios-brasil/municipios-sf.rds")
path_to_ufs <- here("data/ibge/malha-municipios-brasil/ufs-sf.rds")

# mantém somente ids de municípios
path_to_munics_ids <- here("data/ibge/municipios.rds")

# :: DOWNLOAD ==================================================================

download.file(url = munics_zipfile_ftp, destfile = munics_zipfile_local, mode = "wb")
unzip(zipfile = munics_zipfile_local, exdir = malha_munics)

download.file(url = ufs_zipfile_ftp, destfile = ufs_zipfile_local, mode = "wb")
unzip(zipfile = ufs_zipfile_local, exdir = malha_munics)

# :: SALVA =====================================================================

# shp2rds

munics <- read_sf(path_to_munics_shp)
ufs <- read_sf(path_to_ufs_shp)

# essa versão mantém atributos espaciais (para fazer mapas)
munics %>%
  transmute(
    codigo_ibge = CD_MUN,
    nome_municipio = NM_MUN,
    uf = SIGLA_UF
  ) %>%
  saveRDS(path_to_munics)

# essa versão mantém somente ids
munics %>%
  st_set_geometry(NULL) %>%
  transmute(
    codigo_ibge = CD_MUN,
    nome_municipio = NM_MUN,
    uf = SIGLA_UF
  ) %>%
  saveRDS(path_to_munics_ids)

# somente atributos espaciais das ufs, pois a única finalidade é fazer mapas
ufs %>%
  transmute(
    codigo_uf = CD_UF,
    nome_uf = NM_UF,
    uf = SIGLA_UF,
    nome_regiao <- NM_REGIAO
  ) %>%
  saveRDS(path_to_ufs)
