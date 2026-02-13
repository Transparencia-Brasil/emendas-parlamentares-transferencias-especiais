library(here)
library(tidyverse)
source(here("tasks/db/src/R/utils.R"))

# Opção 1: Uso rápido (abre e fecha conexão automaticamente)
df_plano <- get_query("SELECT * FROM plano_acao LIMIT 5")

print(df_plano)

# Opção 2: Reutilizando conexão (para muitas queries seguidas, é mais performático)
con <- conectar_transferegov()

df_empenhos <- get_query("SELECT * FROM empenho LIMIT 5", con = con)
df_pagamentos <- get_query("SELECT * FROM documento_habil LIMIT 5", con = con)

DBI::dbDisconnect(con, shutdown = TRUE)