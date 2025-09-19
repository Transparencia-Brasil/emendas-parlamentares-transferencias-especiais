options(width = 150)
library(here)
library(tidyverse)
library(readxl)
library(gt)


# :: PATHS ---------------------------------------------------------------------

PATH_EMENDAS_GPT <- here("tasks/analise-classificacoes-gpt5/inputs/emendas-gpt.xlsx")


# :: LOAD DATA -----------------------------------------------------------------

emendas_gpt <- readxl::read_excel(PATH_EMENDAS_GPT) |>
  janitor::clean_names() |>
  rename(classificacao_justificativa = classificacao_justifificativa)

emendas_gpt |>
    count(classificacao_detalhamento_objeto, classificacao_justificativa, sort = TRUE) |>
    gt() |>
    tab_header(
      title = "Contagem das Classificações das Emendas",
      subtitle = "Detalhamento do objeto e justificativa"
    ) |>
    fmt_number(
      columns = n,
      sep_mark = ".",
      dec_mark = ",",
      decimals = 0
    ) |>
    cols_label(
      classificacao_detalhamento_objeto = "Detalhamento do Objeto",
      classificacao_justificativa = "Justificativa",
      n = "Quantidade"
    ) |>
    opt_row_striping()


emendas_gpt |>
  summarise(
    .by = c(
      id_plano_acao, id_plano_trabalho, id_executor,
      classificacao_detalhamento_objeto, classificacao_justificativa
    ),
    qtd_metas = n()
  ) |>
  mutate(
    total_metas = sum(qtd_metas),
    perc_metas = qtd_metas / total_metas
  )


# 1. Distribuição de classificacao_detalhamento_objeto
emendas_gpt %>%
  count(classificacao_detalhamento_objeto, sort = TRUE) %>%
  ggplot(aes(x = reorder(classificacao_detalhamento_objeto, n), y = n)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(title = "Distribuição do Detalhamento do Objeto", x = "Detalhamento", y = "Frequência")

# 2. Frequência das justificativas
emendas_gpt %>%
  count(classificacao_justificativa, sort = TRUE) %>%
  ggplot(aes(x = reorder(classificacao_justificativa, n), y = n)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(title = "Top 10 Justificativas", x = "Justificativa", y = "Frequência")

# 3. Estatísticas do elemento_despesa_estimado
summary(emendas_gpt$elemento_despesa_estimado)

ggplot(emendas_gpt, aes(x = elemento_despesa_estimado)) +
  geom_histogram(bins = 30, fill = "blue", color = "white", stat="count") +
  labs(title = "Distribuição do Elemento de Despesa Estimado", x = "Valor Estimado", y = "Frequência")

# 4. Proporção de categoria_macro
emendas_gpt %>%
  count(categoria_macro) %>%
  mutate(prop = n / sum(n)) %>%
  ggplot(aes(x = reorder(categoria_macro, prop), y = prop)) +
  geom_bar(stat = "identity", fill = "orange") +
  coord_flip() +
  labs(title = "Proporção das Categorias Macro", x = "Categoria Macro", y = "Proporção")

# 5. Despesa estimada por categoria_macro
emendas_gpt %>%
  group_by(categoria_macro) %>%
  summarise(media_despesa = mean(elemento_despesa_estimado, na.rm = TRUE)) %>%
  ggplot(aes(x = reorder(categoria_macro, media_despesa), y = media_despesa)) +
  geom_bar(stat = "identity", fill = "green") +
  coord_flip() +
  labs(title = "Despesa Estimada Média por Categoria Macro", x = "Categoria Macro", y = "Despesa Média")
