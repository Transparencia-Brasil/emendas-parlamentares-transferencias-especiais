# tasks/db/src/R/01-criar-banco.R
# Script orquestrador: cria e popula o banco DuckDB local `transferegov`
# -----------------------------------------------------------------------
#
# Uso:
#   source(here::here("tasks/db/src/R/01-criar-banco.R"))
#
# Pré-requisitos:
#   install.packages(c("DBI", "duckdb", "tidyverse", "here", "snakecase", "cli"))
#
# O banco é salvo em: tasks/db/outputs/transferegov.duckdb
# -----------------------------------------------------------------------

library(here)
library(tidyverse)
library(DBI)
library(duckdb)
library(cli)

source(here("tasks/db/src/R/utils.R"))


# :: 1. LER CSVs ---------------------------------------------------------------

cli::cat_rule("Lendo CSVs de tasks/transferegov/outputs/ e tasks/malhas-municipais/outputs/")
tabelas <- ler_csvs_transferegov()


# :: 2. INSPECIONAR CAMPOS COMUNS (5 primeiras linhas) -------------------------

cli::cat_rule("Inspeção: 5 primeiras linhas de cada tabela")

purrr::iwalk(tabelas, \(df, nome) {
  cli::cat_line(cli::col_blue("\n--- ", nome, " (", ncol(df), " colunas, ",
                              format(nrow(df), big.mark = "."), " linhas) ---"))
  print(head(df, 5))
})


# :: 3. CONVERTER TIPOS --------------------------------------------------------

cli::cat_rule("Convertendo tipos (numéricos, datas, timestamps)")
tabelas <- purrr::map(tabelas, converter_tipos)
cli::cat_line(cli::col_green("\u2714 Tipos convertidos para todas as tabelas."))


# :: 4. REMOVER BANCO EXISTENTE (recriação limpa) -----------------------------

if (file.exists(DB_PATH)) {
  file.remove(DB_PATH)
  cli::cat_line(cli::col_yellow("\u26A0 Banco anterior removido: ", DB_PATH))
}


# :: 5. CRIAR BANCO E TABELAS -------------------------------------------------

cli::cat_rule("Criando banco DuckDB e tabelas com constraints")
con <- conectar_transferegov()
criar_tabelas(con)


# :: 6. POPULAR TABELAS --------------------------------------------------------

cli::cat_rule("Populando tabelas")
popular_tabelas(con, tabelas)


# :: 7. RESUMO FINAL -----------------------------------------------------------

cli::cat_rule("Resumo: linhas por tabela no banco")

nomes_tabelas <- DBI::dbListTables(con)
resumo <- purrr::map_dfr(nomes_tabelas, \(tbl) {
  n <- DBI::dbGetQuery(con, paste0("SELECT COUNT(*) AS n FROM ", tbl))$n
  tibble(tabela = tbl, linhas = n)
}) |>
  arrange(tabela)

print(resumo, n = Inf)

total <- sum(resumo$linhas)
cli::cat_line(cli::col_green(
  "\n\u2714 Banco criado com sucesso! ",
  length(nomes_tabelas), " tabelas, ",
  format(total, big.mark = "."), " linhas no total."
))
cli::cat_line(cli::col_green("  Caminho: ", DB_PATH))


# :: 8. DESCONECTAR ------------------------------------------------------------

DBI::dbDisconnect(con, shutdown = TRUE)
cli::cat_line(cli::col_green("\u2714 Conexão encerrada."))
