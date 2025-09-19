# Análise Detalhada dos Campos do Dataset de Emendas GPT
# ========================================================
# Script para análise exploratória dos campos:
# - classificacao_detalhamento_objeto
# - classificacao_justificativa  
# - elemento_despesa_estimado
# - categoria_macro

options(width = 150)

# Carregar pacotes com tratamento de erro
required_packages <- c("here", "tidyverse", "readxl", "ggplot2", "scales", "janitor")
missing_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]

if (length(missing_packages) > 0) {
  message("AVISO: Os seguintes pacotes não estão instalados: ", paste(missing_packages, collapse = ", "))
  message("Execute primeiro: install.packages(c('", paste(missing_packages, collapse = "', '"), "'))")
  message("Tentando continuar com pacotes base do R...")
}

# Carregar pacotes disponíveis
for (pkg in required_packages) {
  if (pkg %in% installed.packages()[,"Package"]) {
    suppressPackageStartupMessages(library(pkg, character.only = TRUE))
  }
}

# :: PATHS ---------------------------------------------------------------------

PATH_EMENDAS_GPT <- here("tasks/analise-classificacoes-gpt5/inputs/emendas-gpt.xlsx")

# :: LOAD DATA -----------------------------------------------------------------

# Verificar se here está disponível
if ("here" %in% (.packages()) || require(here, quietly = TRUE)) {
  PATH_EMENDAS_GPT <- here("tasks/analise-classificacoes-gpt5/inputs/emendas-gpt.xlsx")
} else {
  PATH_EMENDAS_GPT <- "tasks/analise-classificacoes-gpt5/inputs/emendas-gpt.xlsx"
}

# Verificar se arquivo existe
if (!file.exists(PATH_EMENDAS_GPT)) {
  stop("Arquivo não encontrado: ", PATH_EMENDAS_GPT)
}

# Carregar dados
can_load_excel <- FALSE
if (require(readxl, quietly = TRUE)) {
  can_load_excel <- TRUE
  if (require(janitor, quietly = TRUE)) {
    emendas_gpt <- readxl::read_excel(PATH_EMENDAS_GPT) |>
      janitor::clean_names()
  } else {
    emendas_gpt <- readxl::read_excel(PATH_EMENDAS_GPT)
    # Limpar nomes manualmente se janitor não estiver disponível
    names(emendas_gpt) <- gsub("[^a-zA-Z0-9_]", "_", tolower(names(emendas_gpt)))
    names(emendas_gpt) <- gsub("_{2,}", "_", names(emendas_gpt))
    names(emendas_gpt) <- gsub("^_|_$", "", names(emendas_gpt))
  }
} else {
  # Fallback para CSV se readxl não estiver disponível
  message("AVISO: readxl não disponível. Tentando ler como CSV...")
  csv_path <- gsub("\\.xlsx$", ".csv", PATH_EMENDAS_GPT)
  if (file.exists(csv_path)) {
    emendas_gpt <- read.csv(csv_path, stringsAsFactors = FALSE)
  } else {
    stop("Não foi possível carregar os dados. Instale o pacote 'readxl' ou converta o arquivo para CSV.")
  }
}

# Verificar estrutura dos dados
message("Estrutura dos dados:")
str(emendas_gpt)

message("\nPrimeiras linhas:")
print(head(emendas_gpt))

message("\nColunas disponíveis:")
print(names(emendas_gpt))

# :: ANÁLISES ESPECÍFICAS -----------------------------------------------------

cat("\n=== INICIANDO ANÁLISES ===\n")

# 1. CLASSIFICAÇÃO DETALHAMENTO OBJETO
cat("\n--- Análise: Classificação Detalhamento Objeto ---\n")

# Verificar se a coluna existe (considerando variações no nome)
col_detalhamento <- NULL
if ("CLASSIFICACAO.DETALHAMENTO.OBJETO" %in% names(emendas_gpt)) {
  col_detalhamento <- "CLASSIFICACAO.DETALHAMENTO.OBJETO"
} else if ("classificacao_detalhamento_objeto" %in% names(emendas_gpt)) {
  col_detalhamento <- "classificacao_detalhamento_objeto"
}

# Distribuição das categorias
if (!is.null(col_detalhamento) && require(dplyr, quietly = TRUE)) {
  # Versão com dplyr
  dist_detalhamento <- emendas_gpt |>
    count(!!sym(col_detalhamento), sort = TRUE) |>
    mutate(
      prop = n / sum(n),
      prop_pct = if (require(scales, quietly = TRUE)) scales::percent(prop, accuracy = 0.1) else paste0(round(prop * 100, 1), "%")
    )
} else if (!is.null(col_detalhamento)) {
  # Versão base R
  tbl <- table(emendas_gpt[[col_detalhamento]])
  tbl_sorted <- sort(tbl, decreasing = TRUE)
  dist_detalhamento <- data.frame(
    categoria = names(tbl_sorted),
    n = as.numeric(tbl_sorted),
    prop = as.numeric(tbl_sorted) / sum(tbl_sorted),
    stringsAsFactors = FALSE
  )
  names(dist_detalhamento)[1] <- col_detalhamento
  dist_detalhamento$prop_pct <- paste0(round(dist_detalhamento$prop * 100, 1), "%")
} else {
  dist_detalhamento <- NULL
  cat("Coluna de detalhamento do objeto não encontrada.\n")
}

if (!is.null(dist_detalhamento)) {
  print("Distribuição do Detalhamento do Objeto:")
  print(dist_detalhamento)
  
  # Gráfico de barras (se ggplot2 estiver disponível)
  if (require(ggplot2, quietly = TRUE)) {
    grafico_detalhamento <- dist_detalhamento |>
      ggplot(aes(x = reorder(!!sym(col_detalhamento), n), y = n)) +
      geom_bar(stat = "identity", fill = "steelblue", alpha = 0.8) +
      coord_flip() +
      labs(
        title = "Distribuição do Detalhamento do Objeto",
        subtitle = paste("Total de registros:", sum(dist_detalhamento$n)),
        x = "Detalhamento do Objeto",
        y = "Frequência"
      ) +
      geom_text(aes(label = n), hjust = -0.1, size = 3) +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 12)
      )
    
    print(grafico_detalhamento)
  } else {
    message("ggplot2 não disponível. Usando gráfico base R...")
    # Gráfico base R
    par(mar = c(5, 15, 4, 2))
    barplot(
      dist_detalhamento$n,
      names.arg = dist_detalhamento[[col_detalhamento]],
      horiz = TRUE,
      las = 1,
      main = "Distribuição do Detalhamento do Objeto",
      xlab = "Frequência",
      col = "steelblue"
    )
  }
}

# :: 2. ANÁLISE DE CLASSIFICACAO_JUSTIFICATIVA --------------------------------

message("\n=== ANÁLISE: CLASSIFICAÇÃO JUSTIFICATIVA ===")

# Frequência das justificativas
dist_justificativa <- emendas_gpt |>
  count(classificacao_justifificativa, sort = TRUE) |>
  mutate(
    prop = n / sum(n),
    prop_pct = scales::percent(prop, accuracy = 0.1)
  )

print("Distribuição das Justificativas:")
print(dist_justificativa)

# Top 10 justificativas
top10_justificativas <- dist_justificativa |>
  head(10)

grafico_justificativas <- top10_justificativas |>
  ggplot(aes(x = reorder(classificacao_justifificativa, n), y = n)) +
  geom_bar(stat = "identity", fill = "coral", alpha = 0.8) +
  coord_flip() +
  labs(
    title = "Top 10 Justificativas",
    subtitle = paste("Representa", scales::percent(sum(top10_justificativas$prop), accuracy = 0.1), "do total"),
    x = "Justificativa",
    y = "Frequência"
  ) +
  geom_text(aes(label = n), hjust = -0.1, size = 3) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12)
  )

print(grafico_justificativas)

# :: 3. ANÁLISE DE ELEMENTO_DESPESA_ESTIMADO ----------------------------------

message("\n=== ANÁLISE: ELEMENTO DESPESA ESTIMADO ===")

# Verificar se a coluna existe e convertê-la para numérico
if ("elemento_despesa_estimado" %in% names(emendas_gpt)) {
  emendas_gpt <- emendas_gpt |>
    mutate(elemento_despesa_estimado = as.numeric(elemento_despesa_estimado))
  
  # Estatísticas descritivas
  estatisticas_despesa <- emendas_gpt |>
    summarise(
      n_total = n(),
      n_validos = sum(!is.na(elemento_despesa_estimado)),
      n_missing = sum(is.na(elemento_despesa_estimado)),
      media = mean(elemento_despesa_estimado, na.rm = TRUE),
      mediana = median(elemento_despesa_estimado, na.rm = TRUE),
      desvio_padrao = sd(elemento_despesa_estimado, na.rm = TRUE),
      minimo = min(elemento_despesa_estimado, na.rm = TRUE),
      maximo = max(elemento_despesa_estimado, na.rm = TRUE),
      q25 = quantile(elemento_despesa_estimado, 0.25, na.rm = TRUE),
      q75 = quantile(elemento_despesa_estimado, 0.75, na.rm = TRUE)
    )
  
  print("Estatísticas do Elemento de Despesa Estimado:")
  print(estatisticas_despesa)
  
  # Histograma
  grafico_despesa <- emendas_gpt |>
    filter(!is.na(elemento_despesa_estimado)) |>
    ggplot(aes(x = elemento_despesa_estimado)) +
    geom_histogram(bins = 30, fill = "navy", color = "white", alpha = 0.7) +
    labs(
      title = "Distribuição do Elemento de Despesa Estimado",
      subtitle = paste("N =", estatisticas_despesa$n_validos, "registros válidos"),
      x = "Valor Estimado (R$)",
      y = "Frequência"
    ) +
    scale_x_continuous(labels = scales::dollar_format(prefix = "R$ ", big.mark = ".")) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 12)
    )
  
  print(grafico_despesa)
  
} else {
  message("Coluna 'elemento_despesa_estimado' não encontrada no dataset.")
}

# :: 4. ANÁLISE DE CATEGORIA_MACRO --------------------------------------------

message("\n=== ANÁLISE: CATEGORIA MACRO ===")

# Verificar se a coluna existe
if ("categoria_macro" %in% names(emendas_gpt)) {
  # Proporção de categorias macro
  dist_categoria_macro <- emendas_gpt |>
    count(categoria_macro, sort = TRUE) |>
    mutate(
      prop = n / sum(n),
      prop_pct = scales::percent(prop, accuracy = 0.1)
    )
  
  print("Distribuição das Categorias Macro:")
  print(dist_categoria_macro)
  
  # Gráfico de barras
  grafico_categoria_macro <- dist_categoria_macro |>
    ggplot(aes(x = reorder(categoria_macro, prop), y = prop)) +
    geom_bar(stat = "identity", fill = "orange", alpha = 0.8) +
    coord_flip() +
    labs(
      title = "Proporção das Categorias Macro",
      subtitle = paste("Total de registros:", sum(dist_categoria_macro$n)),
      x = "Categoria Macro",
      y = "Proporção"
    ) +
    geom_text(aes(label = prop_pct), hjust = -0.1, size = 3) +
    scale_y_continuous(labels = scales::percent_format()) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 12)
    )
  
  print(grafico_categoria_macro)
  
} else {
  message("Coluna 'categoria_macro' não encontrada no dataset.")
}

# :: 5. ANÁLISES CRUZADAS -----------------------------------------------------

message("\n=== ANÁLISES CRUZADAS ===")

# 5.1 Despesa estimada por categoria macro (se ambas existirem)
if ("elemento_despesa_estimado" %in% names(emendas_gpt) && "categoria_macro" %in% names(emendas_gpt)) {
  
  despesa_por_categoria <- emendas_gpt |>
    filter(!is.na(elemento_despesa_estimado), !is.na(categoria_macro)) |>
    group_by(categoria_macro) |>
    summarise(
      n_registros = n(),
      media_despesa = mean(elemento_despesa_estimado, na.rm = TRUE),
      mediana_despesa = median(elemento_despesa_estimado, na.rm = TRUE),
      total_despesa = sum(elemento_despesa_estimado, na.rm = TRUE),
      .groups = "drop"
    ) |>
    arrange(desc(media_despesa))
  
  print("Despesa Estimada por Categoria Macro:")
  print(despesa_por_categoria)
  
  # Gráfico
  grafico_despesa_categoria <- despesa_por_categoria |>
    ggplot(aes(x = reorder(categoria_macro, media_despesa), y = media_despesa)) +
    geom_bar(stat = "identity", fill = "darkgreen", alpha = 0.8) +
    coord_flip() +
    labs(
      title = "Despesa Estimada Média por Categoria Macro",
      subtitle = "Valores em Reais (R$)",
      x = "Categoria Macro",
      y = "Despesa Média (R$)"
    ) +
    geom_text(
      aes(label = scales::dollar(media_despesa, prefix = "R$ ", big.mark = ".")), 
      hjust = -0.1, size = 3
    ) +
    scale_y_continuous(labels = scales::dollar_format(prefix = "R$ ", big.mark = ".")) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 12)
    )
  
  print(grafico_despesa_categoria)
}

# 5.2 Cruzamento entre detalhamento e justificativa
cruzamento_det_just <- emendas_gpt |>
  count(classificacao_detalhamento_objeto, classificacao_justifificativa, sort = TRUE) |>
  head(15)

print("Top 15 Combinações Detalhamento x Justificativa:")
print(cruzamento_det_just)

# 5.3 Resumo geral
resumo_geral <- emendas_gpt |>
  summarise(
    total_registros = n(),
    detalhamentos_unicos = n_distinct(classificacao_detalhamento_objeto, na.rm = TRUE),
    justificativas_unicas = n_distinct(classificacao_justifificativa, na.rm = TRUE),
    categorias_macro_unicas = if ("categoria_macro" %in% names(emendas_gpt)) n_distinct(categoria_macro, na.rm = TRUE) else NA,
    registros_com_despesa = if ("elemento_despesa_estimado" %in% names(emendas_gpt)) sum(!is.na(elemento_despesa_estimado)) else NA
  )

message("\n=== RESUMO GERAL ===")
print(resumo_geral)

message("\n=== ANÁLISE CONCLUÍDA ===")
message("Gráficos e tabelas foram gerados para todos os campos disponíveis.")
message("Verifique os resultados acima para insights sobre o dataset.")