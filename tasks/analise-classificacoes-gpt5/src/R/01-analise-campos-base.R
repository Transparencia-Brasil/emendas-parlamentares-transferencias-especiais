# Análise Detalhada dos Campos do Dataset de Emendas GPT (Versão Base R)
# ========================================================================
# Script para análise exploratória dos campos:
# - classificacao_detalhamento_objeto
# - classificacao_justificativa  
# - elemento_despesa_estimado
# - categoria_macro
#
# Este script funciona com R base, mas utilizará pacotes avançados se disponíveis

options(width = 150)

# :: FUNÇÃO AUXILIAR PARA CONVERTER EXCEL PARA CSV ---------------------------

convert_excel_to_csv <- function() {
  cat("Tentando converter Excel para CSV usando python...\n")
  
  # Script Python para converter Excel para CSV
  python_script <- '
import pandas as pd
import sys

try:
    df = pd.read_excel("tasks/analise-classificacoes-gpt5/inputs/emendas-gpt.xlsx")
    df.to_csv("tasks/analise-classificacoes-gpt5/inputs/emendas-gpt.csv", index=False)
    print("Conversão realizada com sucesso!")
except Exception as e:
    print(f"Erro na conversão: {e}")
    sys.exit(1)
'
  
  # Escrever script temporário
  writeLines(python_script, "/tmp/convert_excel.py")
  
  # Executar conversão
  result <- system("cd /home/runner/work/emendas-parlamentares-transferencias-especiais/emendas-parlamentares-transferencias-especiais && python3 /tmp/convert_excel.py", intern = TRUE)
  
  if (file.exists("tasks/analise-classificacoes-gpt5/inputs/emendas-gpt.csv")) {
    cat("Arquivo CSV criado com sucesso!\n")
    return(TRUE)
  } else {
    cat("Falha na conversão.\n")
    return(FALSE)
  }
}

# :: LOAD DATA -----------------------------------------------------------------

# Definir caminho do arquivo
PATH_EMENDAS_XLSX <- "tasks/analise-classificacoes-gpt5/inputs/emendas-gpt.xlsx"
PATH_EMENDAS_CSV <- "tasks/analise-classificacoes-gpt5/inputs/emendas-gpt.csv"

# Verificar se arquivo existe
if (!file.exists(PATH_EMENDAS_XLSX)) {
  stop("Arquivo não encontrado: ", PATH_EMENDAS_XLSX)
}

# Tentar carregar dados
emendas_gpt <- NULL

# Método 1: Tentar com readxl
if (require(readxl, quietly = TRUE)) {
  cat("Carregando dados com readxl...\n")
  emendas_gpt <- readxl::read_excel(PATH_EMENDAS_XLSX)
  
  # Limpar nomes das colunas
  if (require(janitor, quietly = TRUE)) {
    emendas_gpt <- janitor::clean_names(emendas_gpt)
  } else {
    # Limpar nomes manualmente
    names(emendas_gpt) <- gsub("[^a-zA-Z0-9_]", "_", tolower(names(emendas_gpt)))
    names(emendas_gpt) <- gsub("_{2,}", "_", names(emendas_gpt))
    names(emendas_gpt) <- gsub("^_|_$", "", names(emendas_gpt))
  }
}

# Método 2: Tentar CSV se já existe
if (is.null(emendas_gpt) && file.exists(PATH_EMENDAS_CSV)) {
  cat("Carregando dados do arquivo CSV existente...\n")
  emendas_gpt <- read.csv(PATH_EMENDAS_CSV, stringsAsFactors = FALSE)
}

# Método 3: Converter Excel para CSV e tentar novamente
if (is.null(emendas_gpt)) {
  cat("Tentando converter Excel para CSV...\n")
  if (convert_excel_to_csv()) {
    emendas_gpt <- read.csv(PATH_EMENDAS_CSV, stringsAsFactors = FALSE)
  }
}

# Se ainda não conseguiu carregar, parar execução
if (is.null(emendas_gpt)) {
  stop("Não foi possível carregar os dados. Instale o pacote 'readxl' ou converta o arquivo para CSV manualmente.")
}

# :: VERIFICAR ESTRUTURA DOS DADOS --------------------------------------------

cat("\n=== INFORMAÇÕES DO DATASET ===\n")
cat("Dimensões:", nrow(emendas_gpt), "linhas x", ncol(emendas_gpt), "colunas\n")
cat("\nPrimeiras colunas:\n")
print(head(names(emendas_gpt), 10))

cat("\nPrimeiras linhas (primeiras 5 colunas):\n")
print(head(emendas_gpt[, 1:min(5, ncol(emendas_gpt))]))

# :: IDENTIFICAR COLUNAS DE INTERESSE -----------------------------------------

# Procurar colunas que podem conter os campos de interesse
campos_interesse <- c(
  "classificacao_detalhamento_objeto",
  "CLASSIFICACAO.DETALHAMENTO.OBJETO",
  "classificacao_justifificativa", 
  "CLASSIFICACAO.JUSTIFIFICATIVA",
  "classificacao_justificativa",
  "elemento_despesa_estimado",
  "categoria_macro"
)

colunas_encontradas <- names(emendas_gpt)[names(emendas_gpt) %in% campos_interesse]
colunas_similares <- names(emendas_gpt)[grepl("classif|justif|despesa|categoria|macro", names(emendas_gpt), ignore.case = TRUE)]

cat("\n=== COLUNAS DE INTERESSE ===\n")
cat("Colunas exatas encontradas:", paste(colunas_encontradas, collapse = ", "), "\n")
cat("Colunas similares encontradas:", paste(colunas_similares, collapse = ", "), "\n")

# Mapear colunas encontradas para nomes padronizados
col_detalhamento <- NULL
col_justificativa <- NULL
col_despesa <- "elemento_despesa_estimado"
col_categoria <- "categoria_macro"

# Verificar detalhamento
if ("CLASSIFICACAO.DETALHAMENTO.OBJETO" %in% names(emendas_gpt)) {
  col_detalhamento <- "CLASSIFICACAO.DETALHAMENTO.OBJETO"
} else if ("classificacao_detalhamento_objeto" %in% names(emendas_gpt)) {
  col_detalhamento <- "classificacao_detalhamento_objeto"
}

# Verificar justificativa  
if ("CLASSIFICACAO.JUSTIFIFICATIVA" %in% names(emendas_gpt)) {
  col_justificativa <- "CLASSIFICACAO.JUSTIFIFICATIVA"
} else if ("classificacao_justifificativa" %in% names(emendas_gpt)) {
  col_justificativa <- "classificacao_justifificativa"
} else if ("classificacao_justificativa" %in% names(emendas_gpt)) {
  col_justificativa <- "classificacao_justificativa"
}

# :: FUNÇÃO AUXILIAR PARA ANÁLISE DESCRITIVA ----------------------------------

criar_tabela_frequencia <- function(dados, coluna) {
  if (!(coluna %in% names(dados))) {
    cat("Coluna", coluna, "não encontrada.\n")
    return(NULL)
  }
  
  # Remover valores NA
  valores <- dados[[coluna]][!is.na(dados[[coluna]])]
  
  if (length(valores) == 0) {
    cat("Coluna", coluna, "não possui valores válidos.\n")
    return(NULL)
  }
  
  # Criar tabela de frequência
  freq_table <- table(valores)
  freq_sorted <- sort(freq_table, decreasing = TRUE)
  
  # Criar data frame
  resultado <- data.frame(
    categoria = names(freq_sorted),
    frequencia = as.numeric(freq_sorted),
    proporcao = as.numeric(freq_sorted) / sum(freq_sorted),
    stringsAsFactors = FALSE
  )
  
  resultado$percentual <- paste0(round(resultado$proporcao * 100, 1), "%")
  
  return(resultado)
}

# :: FUNÇÃO PARA CRIAR GRÁFICO BASE R -----------------------------------------

criar_grafico_barras <- function(dados, titulo, max_categorias = 10, arquivo = NULL) {
  if (is.null(dados) || nrow(dados) == 0) {
    return(NULL)
  }
  
  # Limitar número de categorias para visualização
  dados_plot <- head(dados, max_categorias)
  
  # Abrir arquivo se especificado
  if (!is.null(arquivo)) {
    png(arquivo, width = 800, height = 600)
  }
  
  # Configurar margens
  par(mar = c(5, 12, 4, 2))
  
  # Criar gráfico de barras horizontal
  barplot(
    dados_plot$frequencia,
    names.arg = dados_plot$categoria,
    horiz = TRUE,
    las = 1,
    main = titulo,
    xlab = "Frequência",
    col = "steelblue",
    cex.names = 0.8
  )
  
  # Adicionar valores nas barras
  text(
    x = dados_plot$frequencia + max(dados_plot$frequencia) * 0.02,
    y = seq_along(dados_plot$frequencia),
    labels = dados_plot$frequencia,
    pos = 4,
    cex = 0.8
  )
  
  # Fechar arquivo se especificado
  if (!is.null(arquivo)) {
    dev.off()
    cat("Gráfico salvo em:", arquivo, "\n")
  }
}

# :: ANÁLISES ESPECÍFICAS -----------------------------------------------------

cat("\n=== INICIANDO ANÁLISES ===\n")

# Criar diretório para outputs se não existir
if (!dir.exists("tasks/analise-classificacoes-gpt5/outputs")) {
  dir.create("tasks/analise-classificacoes-gpt5/outputs", recursive = TRUE)
}

# 1. CLASSIFICAÇÃO DETALHAMENTO OBJETO
cat("\n--- Análise: Classificação Detalhamento Objeto ---\n")
if (!is.null(col_detalhamento)) {
  freq_detalhamento <- criar_tabela_frequencia(emendas_gpt, col_detalhamento)
  if (!is.null(freq_detalhamento)) {
    print(freq_detalhamento)
    
    # Salvar tabela
    write.csv(freq_detalhamento, "tasks/analise-classificacoes-gpt5/outputs/freq_detalhamento_objeto.csv", row.names = FALSE)
    
    # Criar gráfico
    criar_grafico_barras(freq_detalhamento, "Distribuição do Detalhamento do Objeto", 
                        arquivo = "tasks/analise-classificacoes-gpt5/outputs/grafico_detalhamento_objeto.png")
  }
} else {
  cat("Coluna de detalhamento do objeto não encontrada.\n")
}

# 2. CLASSIFICAÇÃO JUSTIFICATIVA
cat("\n--- Análise: Classificação Justificativa ---\n")
if (!is.null(col_justificativa)) {
  freq_justificativa <- criar_tabela_frequencia(emendas_gpt, col_justificativa)
  if (!is.null(freq_justificativa)) {
    cat("Top 15 Justificativas:\n")
    print(head(freq_justificativa, 15))
    
    # Salvar tabela
    write.csv(freq_justificativa, "tasks/analise-classificacoes-gpt5/outputs/freq_justificativas.csv", row.names = FALSE)
    
    # Criar gráfico
    criar_grafico_barras(head(freq_justificativa, 10), "Top 10 Justificativas",
                        arquivo = "tasks/analise-classificacoes-gpt5/outputs/grafico_justificativas.png")
  }
} else {
  cat("Coluna de justificativa não encontrada.\n")
}

# 3. ELEMENTO DESPESA ESTIMADO
cat("\n--- Análise: Elemento Despesa Estimado ---\n")
if (col_despesa %in% names(emendas_gpt)) {
  # Converter para numérico
  despesa_values <- emendas_gpt[[col_despesa]]
  
  # Tentar diferentes conversões
  if (is.character(despesa_values)) {
    # Remover caracteres não numéricos e converter
    despesa_values <- gsub("[^0-9.,\\-]", "", despesa_values)
    despesa_values <- gsub(",", ".", despesa_values)
    despesa_values <- as.numeric(despesa_values)
  } else {
    despesa_values <- as.numeric(despesa_values)
  }
  
  despesa_valid <- despesa_values[!is.na(despesa_values) & despesa_values > 0]
  
  if (length(despesa_valid) > 0) {
    # Estatísticas
    stats_despesa <- data.frame(
      estatistica = c("N total", "N válidos", "N missing/zeros", "Mínimo", "Máximo", "Média", "Mediana", "Desvio Padrão"),
      valor = c(
        length(despesa_values),
        length(despesa_valid),
        sum(is.na(despesa_values) | despesa_values == 0),
        min(despesa_valid),
        max(despesa_valid),
        mean(despesa_valid),
        median(despesa_valid),
        sd(despesa_valid)
      )
    )
    
    cat("Estatísticas do Elemento de Despesa Estimado:\n")
    print(stats_despesa)
    
    # Salvar estatísticas
    write.csv(stats_despesa, "tasks/analise-classificacoes-gpt5/outputs/estatisticas_despesa_estimada.csv", row.names = FALSE)
    
    # Histograma
    png("tasks/analise-classificacoes-gpt5/outputs/histograma_despesa_estimada.png", width = 800, height = 600)
    par(mar = c(5, 4, 4, 2))
    hist(
      despesa_valid,
      breaks = 30,
      main = "Distribuição do Elemento de Despesa Estimado",
      xlab = "Valor (R$)",
      ylab = "Frequência",
      col = "navy",
      border = "white"
    )
    dev.off()
    cat("Histograma salvo em: tasks/analise-classificacoes-gpt5/outputs/histograma_despesa_estimada.png\n")
  } else {
    cat("Não há valores válidos para elemento_despesa_estimado.\n")
  }
} else {
  cat("Coluna 'elemento_despesa_estimado' não encontrada.\n")
}

# 4. CATEGORIA MACRO
cat("\n--- Análise: Categoria Macro ---\n")
if (col_categoria %in% names(emendas_gpt)) {
  freq_categoria <- criar_tabela_frequencia(emendas_gpt, col_categoria)
  if (!is.null(freq_categoria)) {
    print(freq_categoria)
    
    # Salvar tabela
    write.csv(freq_categoria, "tasks/analise-classificacoes-gpt5/outputs/freq_categoria_macro.csv", row.names = FALSE)
    
    # Criar gráfico
    criar_grafico_barras(freq_categoria, "Distribuição das Categorias Macro",
                        arquivo = "tasks/analise-classificacoes-gpt5/outputs/grafico_categoria_macro.png")
  }
} else {
  cat("Coluna 'categoria_macro' não encontrada.\n")
}

# :: ANÁLISES CRUZADAS ---------------------------------------------------------

cat("\n=== ANÁLISES CRUZADAS ===\n")

# Cruzamento Detalhamento x Justificativa
if (!is.null(col_detalhamento) && !is.null(col_justificativa)) {
  cat("\n--- Cruzamento: Detalhamento x Justificativa ---\n")
  
  # Criar tabela cruzada
  dados_limpos <- emendas_gpt[
    !is.na(emendas_gpt[[col_detalhamento]]) & 
    !is.na(emendas_gpt[[col_justificativa]]),
  ]
  
  if (nrow(dados_limpos) > 0) {
    cruzamento <- table(
      dados_limpos[[col_detalhamento]],
      dados_limpos[[col_justificativa]]
    )
    
    # Converter para data frame e ordenar
    cruzamento_df <- as.data.frame(cruzamento)
    names(cruzamento_df) <- c("Detalhamento", "Justificativa", "Frequencia")
    cruzamento_df <- cruzamento_df[cruzamento_df$Frequencia > 0, ]
    cruzamento_df <- cruzamento_df[order(cruzamento_df$Frequencia, decreasing = TRUE), ]
    
    cat("Top 15 combinações Detalhamento x Justificativa:\n")
    print(head(cruzamento_df, 15))
    
    # Salvar resultado
    write.csv(cruzamento_df, "tasks/analise-classificacoes-gpt5/outputs/cruzamento_detalhamento_justificativa.csv", row.names = FALSE)
  }
}

# Despesa por Categoria Macro
if (col_despesa %in% names(emendas_gpt) && col_categoria %in% names(emendas_gpt)) {
  cat("\n--- Análise: Despesa por Categoria Macro ---\n")
  
  # Preparar dados
  dados_despesa <- emendas_gpt[
    !is.na(emendas_gpt[[col_despesa]]) & 
    !is.na(emendas_gpt[[col_categoria]]),
  ]
  
  if (nrow(dados_despesa) > 0) {
    # Converter despesa para numérico
    despesa_values <- dados_despesa[[col_despesa]]
    if (is.character(despesa_values)) {
      despesa_values <- gsub("[^0-9.,\\-]", "", despesa_values)
      despesa_values <- gsub(",", ".", despesa_values)
      despesa_values <- as.numeric(despesa_values)
    } else {
      despesa_values <- as.numeric(despesa_values)
    }
    
    # Filtrar valores válidos
    dados_validos <- !is.na(despesa_values) & despesa_values > 0
    dados_despesa <- dados_despesa[dados_validos, ]
    despesa_values <- despesa_values[dados_validos]
    
    if (length(despesa_values) > 0) {
      # Calcular estatísticas por categoria
      categorias <- unique(dados_despesa[[col_categoria]])
      resultado_despesa <- data.frame(
        categoria_macro = character(),
        n_registros = numeric(),
        total_despesa = numeric(),
        media_despesa = numeric(),
        mediana_despesa = numeric(),
        stringsAsFactors = FALSE
      )
      
      for (cat in categorias) {
        indices_cat <- dados_despesa[[col_categoria]] == cat
        despesas_cat <- despesa_values[indices_cat]
        
        resultado_despesa <- rbind(resultado_despesa, data.frame(
          categoria_macro = cat,
          n_registros = sum(indices_cat),
          total_despesa = sum(despesas_cat),
          media_despesa = mean(despesas_cat),
          mediana_despesa = median(despesas_cat),
          stringsAsFactors = FALSE
        ))
      }
      
      # Ordenar por média de despesa
      resultado_despesa <- resultado_despesa[order(resultado_despesa$media_despesa, decreasing = TRUE), ]
      
      print(resultado_despesa)
      
      # Gráfico de média por categoria (só se houver dados)
      if (nrow(resultado_despesa) > 0 && all(is.finite(resultado_despesa$media_despesa))) {
        par(mar = c(5, 8, 4, 2))
        barplot(
          resultado_despesa$media_despesa,
          names.arg = resultado_despesa$categoria_macro,
          horiz = TRUE,
          las = 1,
          main = "Despesa Média por Categoria Macro",
          xlab = "Despesa Média (R$)",
          col = "darkgreen",
          cex.names = 0.8
        )
      }
    } else {
      cat("Não há valores válidos de despesa para análise cruzada.\n")
    }
  }
}

# :: RESUMO FINAL --------------------------------------------------------------

cat("\n=== RESUMO FINAL ===\n")
cat("Total de registros no dataset:", nrow(emendas_gpt), "\n")
cat("Total de colunas:", ncol(emendas_gpt), "\n")

# Contagem de valores únicos por campo de interesse
for (campo in campos_interesse) {
  if (campo %in% names(emendas_gpt)) {
    n_unicos <- length(unique(emendas_gpt[[campo]][!is.na(emendas_gpt[[campo]])]))
    cat("Valores únicos em", campo, ":", n_unicos, "\n")
  }
}

cat("\n=== ANÁLISE CONCLUÍDA ===\n")
cat("Todas as análises disponíveis foram executadas com base nos dados e pacotes disponíveis.\n")