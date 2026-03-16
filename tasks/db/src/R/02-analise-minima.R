library(here)
library(tidyverse)
source(here("tasks/db/src/R/utils.R"))

con <- conectar_transferegov()

# Ver todas as tabelas do banco de dados
tabelas <- DBI::dbListTables(con)
cli::cat_line(cli::col_green("Tabelas no banco: ", paste(tabelas, collapse = ", ")))

# Contagem de linhas por tabela
cli::cat_rule("Contagem de linhas por tabela")
purrr::walk(tabelas, \(tbl) {
  n <- DBI::dbGetQuery(con, paste0("SELECT COUNT(*) AS n FROM ", tbl))$n
  cli::cat_line(paste0("  ", tbl, ": ", format(n, big.mark = ".", decimal.mark = ","), " linhas"))
})

# Amostra de plano_acao (com colunas IBGE)
cli::cat_rule("Amostra: plano_acao (colunas IBGE)")
df_plano <- get_query(
  "SELECT id_plano_acao, nome_beneficiario_plano_acao, codigo_ibge_municipio, codigo_ibge_uf
   FROM plano_acao LIMIT 5", con = con, quiet = TRUE)
print(df_plano)

# Amostra de empenho (com colunas IBGE)
cli::cat_rule("Amostra: empenho (colunas IBGE)")
df_empenho <- get_query(
  "SELECT id_empenho, nome_beneficiario_empenho, codigo_ibge_municipio, codigo_ibge_uf
   FROM empenho LIMIT 5", con = con, quiet = TRUE)
print(df_empenho)

# Amostra de tabelas IBGE
cli::cat_rule("Amostra: municipio")
df_mun <- get_query("SELECT * FROM municipio LIMIT 5", con = con, quiet = TRUE)
print(df_mun)

cli::cat_rule("Amostra: uf")
df_uf <- get_query("SELECT * FROM uf LIMIT 5", con = con, quiet = TRUE)
print(df_uf)

# Join: plano_acao + municipio + uf
cli::cat_rule("Join: plano_acao + municipio + uf")
df_join <- get_query("
  SELECT pa.id_plano_acao, pa.nome_beneficiario_plano_acao,
         m.nome_municipio, m.populacao_2022, u.sigla_uf, u.nome_regiao
  FROM plano_acao pa
  LEFT JOIN municipio m ON pa.codigo_ibge_municipio = m.codigo_ibge
  LEFT JOIN uf u ON pa.codigo_ibge_uf = u.codigo_ibge_uf
  WHERE pa.codigo_ibge_municipio IS NOT NULL
  LIMIT 10
", con = con, quiet = TRUE)
print(df_join)

# Join: empenho + municipio
cli::cat_rule("Join: empenho + municipio")
df_join_emp <- get_query("
  SELECT e.id_empenho, e.nome_beneficiario_empenho,
         m.nome_municipio, u.sigla_uf
  FROM empenho e
  LEFT JOIN municipio m ON e.codigo_ibge_municipio = m.codigo_ibge
  LEFT JOIN uf u ON e.codigo_ibge_uf = u.codigo_ibge_uf
  WHERE e.codigo_ibge_municipio IS NOT NULL
  LIMIT 10
", con = con, quiet = TRUE)
print(df_join_emp)

DBI::dbDisconnect(con, shutdown = TRUE)
cli::cat_line(cli::col_green("\u2714 Análise mínima concluída com sucesso."))

DBI::dbDisconnect(con, shutdown = TRUE)
