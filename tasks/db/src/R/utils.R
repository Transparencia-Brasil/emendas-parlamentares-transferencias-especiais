# tasks/db/src/R/utils.R
# Funções auxiliares para criação e manutenção do banco DuckDB local
# -------------------------------------------------------------------

library(here)
library(tidyverse)
library(DBI)
library(duckdb)
library(snakecase)

# :: CAMINHOS ------------------------------------------------------------------

DB_PATH <- here("tasks/db/outputs/transferegov.duckdb")
CSV_DIR <- here("tasks/transferegov/outputs")


# :: FUNÇÕES -------------------------------------------------------------------

#' Conectar ao banco DuckDB local
#' Cria ou abre uma conexão DBI com o banco DuckDB.
#' Se o arquivo não existir, ele será criado automaticamente.
#' @return Objeto de conexão DBI.
conectar_transferegov <- function(path = DB_PATH) {
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path)
  cli::cat_line(cli::col_green("\u2714 Conectado ao banco: ", path))
  con
}


#' Ler CSVs da pasta de outputs do Transferegov
#' Lista, lê e nomeia todos os CSVs como character.
#' Reutiliza a lógica de `read_transferegov_csvs()` de 00-load-transferegov.R.
#' @param dir Diretório contendo os CSVs (default: tasks/transferegov/outputs).
#' @return Lista nomeada de data.frames (um por tabela).
ler_csvs_transferegov <- function(dir = CSV_DIR) {
  arquivos <- list.files(dir, pattern = "\\.csv$", full.names = TRUE)
  stopifnot("Nenhum CSV encontrado" = length(arquivos) > 0)

  ids <- basename(arquivos) |>
    snakecase::to_snake_case() |>
    str_remove("^\\d+_") |>
    str_remove("_csv$") |>
    str_remove("_especial$")

  tabelas <- arquivos |>
    purrr::map(readr::read_csv,
      col_types = readr::cols(.default = readr::col_character()),
      locale = readr::locale(encoding = "UTF-8"),
      na = c("", "NA"),
      progress = FALSE
    ) |>
    purrr::set_names(ids)

  cli::cat_line(cli::col_green(
    "\u2714 ", length(tabelas), " tabelas lidas: ",
    paste(names(tabelas), collapse = ", ")
  ))

  tabelas
}


#' Converter tipos de colunas de um data.frame
#' Aplica conversões automáticas baseadas no nome da coluna e conteúdo:
#'   - Colunas com prefixo valor_, vl_, qt_ → as.numeric()
#'   - Colunas timestamp (nome com data_hora_/data_e_hora_ ou conteúdo ISO 8601 com "T") → as.POSIXct()
#'   - Colunas com data_ (sem hora) → as.Date()
#'   - Demais colunas permanecem character
#' @param df Um data.frame com colunas character.
#' @return O data.frame com tipos convertidos.
converter_tipos <- function(df) {
  nomes <- names(df)

  # Colunas numéricas: valor_, vl_, qt_
  cols_num <- nomes[str_detect(nomes, "^(valor_|vl_|qt_)")]
  
  # Colunas timestamp: inicia por padrão de nome (data_hora_, data_e_hora_)
  cols_ts <- nomes[str_detect(nomes, "(data_hora_|data_e_hora_)")]
  
  # Detecta colunas adicionais com timestamp por conteúdo (presença de "T" no formato ISO 8601)
  # Candidatas: colunas data_ que não têm hora_ ou e_hora_ no nome
  cols_data_candidatas <- nomes[str_detect(nomes, "^data_") & !str_detect(nomes, "(hora_|e_hora_)")]
  
  # Número de valores a amostrar para detectar timestamps por conteúdo
  TIMESTAMP_SAMPLE_SIZE <- 5
  
  # Verifica conteúdo de cada coluna candidata
  cols_ts_conteudo <- purrr::keep(cols_data_candidatas, \(col) {
    amostra <- df[[col]][!is.na(df[[col]])]
    length(amostra) > 0 && any(str_detect(amostra[seq_len(min(TIMESTAMP_SAMPLE_SIZE, length(amostra)))], "T"))
  })
  
  cols_ts <- c(cols_ts, cols_ts_conteudo)
  
  # Colunas date: data_ (sem hora) — exclui as que foram identificadas como timestamp
  cols_date <- setdiff(
    nomes[str_detect(nomes, "^data_")],
    cols_ts
  )

  df <- df |>
    mutate(across(all_of(cols_num), as.numeric)) |>
    mutate(across(all_of(cols_ts), ~ as.POSIXct(.x, format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC"))) |>
    mutate(across(all_of(cols_date), ~ as.Date(.x)))

  df
}


#' Criar tabelas no banco DuckDB com schema tipado e constraints
#' Executa DDL SQL para cada uma das 13 tabelas, com PRIMARY KEY e FOREIGN KEY.
#' As tabelas são criadas na ordem correta para respeitar as referências FK.
#' @param con Conexão DBI ao banco DuckDB.
criar_tabelas <- function(con) {

  ddl <- list(

    # 1. programa (raiz)
    programa = "
      CREATE TABLE IF NOT EXISTS programa (
        id_programa                                  VARCHAR PRIMARY KEY,
        ano_programa                                 VARCHAR,
        modalidade_programa                          VARCHAR,
        codigo_programa                              VARCHAR,
        id_orgao_superior_programa                   VARCHAR,
        sigla_orgao_superior_programa                VARCHAR,
        nome_orgao_superior_programa                 VARCHAR,
        id_orgao_programa                            VARCHAR,
        sigla_orgao_programa                         VARCHAR,
        nome_orgao_programa                          VARCHAR,
        id_unidade_gestora_programa                  VARCHAR,
        documentos_origem_programa                   VARCHAR,
        id_unidade_orcamentaria_responsavel_programa VARCHAR,
        data_inicio_ciencia_programa                 DATE,
        data_fim_ciencia_programa                    DATE,
        valor_necessidade_financeira_programa        DOUBLE,
        valor_total_disponibilizado_programa         DOUBLE,
        valor_impedido_programa                      DOUBLE,
        valor_a_disponibilizar_programa              DOUBLE,
        valor_documentos_habeis_gerados_programa     DOUBLE,
        valor_obs_geradas_programa                   DOUBLE,
        valor_disponibilidade_atual_programa         DOUBLE
      );
    ",

    # 2. plano_acao (FK → programa)
    plano_acao = "
      CREATE TABLE IF NOT EXISTS plano_acao (
        id_plano_acao                                         VARCHAR PRIMARY KEY,
        codigo_plano_acao                                     VARCHAR,
        ano_plano_acao                                        VARCHAR,
        modalidade_plano_acao                                 VARCHAR,
        situacao_plano_acao                                   VARCHAR,
        cnpj_beneficiario_plano_acao                          VARCHAR,
        nome_beneficiario_plano_acao                          VARCHAR,
        uf_beneficiario_plano_acao                            VARCHAR,
        codigo_banco_plano_acao                               VARCHAR,
        codigo_situacao_dado_bancario_plano_acao              VARCHAR,
        nome_banco_plano_acao                                 VARCHAR,
        numero_agencia_plano_acao                             VARCHAR,
        dv_agencia_plano_acao                                 VARCHAR,
        numero_conta_plano_acao                               VARCHAR,
        dv_conta_plano_acao                                   VARCHAR,
        nome_parlamentar_emenda_plano_acao                    VARCHAR,
        ano_emenda_parlamentar_plano_acao                     VARCHAR,
        codigo_parlamentar_emenda_plano_acao                  VARCHAR,
        sequencial_emenda_parlamentar_plano_acao              VARCHAR,
        numero_emenda_parlamentar_plano_acao                  VARCHAR,
        codigo_emenda_parlamentar_formatado_plano_acao        VARCHAR,
        codigo_descricao_areas_politicas_publicas_plano_acao  VARCHAR,
        descricao_programacao_orcamentaria_plano_acao         VARCHAR,
        motivo_impedimento_plano_acao                         VARCHAR,
        valor_custeio_plano_acao                              DOUBLE,
        valor_investimento_plano_acao                         DOUBLE,
        id_programa                                           VARCHAR,
        FOREIGN KEY (id_programa) REFERENCES programa(id_programa)
      );
    ",

    # 3. empenho (FK → plano_acao)
    empenho = "
      CREATE TABLE IF NOT EXISTS empenho (
        id_empenho                         VARCHAR PRIMARY KEY,
        id_minuta_empenho                  VARCHAR,
        numero_empenho                     VARCHAR,
        situacao_empenho                   VARCHAR,
        descricao_situacao_empenho         VARCHAR,
        tipo_documento_empenho             VARCHAR,
        descricao_tipo_documento_empenho   VARCHAR,
        status_processamento_empenho       VARCHAR,
        ug_responsavel_empenho             VARCHAR,
        ug_emitente_empenho                VARCHAR,
        descricao_ug_emitente_empenho      VARCHAR,
        fonte_recurso_empenho              VARCHAR,
        plano_interno_empenho              VARCHAR,
        ptres_empenho                      VARCHAR,
        grupo_natureza_despesa_empenho     VARCHAR,
        natureza_despesa_empenho           VARCHAR,
        subitem_empenho                    VARCHAR,
        categoria_despesa_empenho          VARCHAR,
        modalidade_despesa_empenho         VARCHAR,
        cnpj_beneficiario_empenho          VARCHAR,
        nome_beneficiario_empenho          VARCHAR,
        uf_beneficiario_empenho            VARCHAR,
        numero_ro_empenho                  VARCHAR,
        data_emissao_empenho               DATE,
        prioridade_desbloqueio_empenho     VARCHAR,
        valor_empenho                      DOUBLE,
        id_plano_acao                      VARCHAR,
        FOREIGN KEY (id_plano_acao) REFERENCES plano_acao(id_plano_acao)
      );
    ",

    # 4. relatorio_gestao_novo (FK → plano_acao)
    relatorio_gestao_novo = "
      CREATE TABLE IF NOT EXISTS relatorio_gestao_novo (
        id_relatorio_gestao_novo              VARCHAR PRIMARY KEY,
        data_e_hora_relatorio_gestao_novo     TIMESTAMP,
        tipo_relatorio_gestao_novo            VARCHAR,
        valor_executado_relatorio_gestao_novo DOUBLE,
        valor_pendente_relatorio_gestao_novo  DOUBLE,
        situacao_relatorio_gestao_novo        VARCHAR,
        id_plano_acao                         VARCHAR,
        FOREIGN KEY (id_plano_acao) REFERENCES plano_acao(id_plano_acao)
      );
    ",

    # 5. executor (FK → plano_acao)
    executor = "
      CREATE TABLE IF NOT EXISTS executor (
        id_plano_acao                                       VARCHAR,
        id_executor                                         VARCHAR PRIMARY KEY,
        cnpj_executor                                       VARCHAR,
        nome_executor                                       VARCHAR,
        objeto_executor                                     VARCHAR,
        vl_custeio_executor                                 DOUBLE,
        vl_investimento_executor                            DOUBLE,
        ind_recursos_gerenciados_conta_especifica_executor  VARCHAR,
        codigo_banco_executor                               VARCHAR,
        nome_banco_executor                                 VARCHAR,
        numero_agencia_executor                             VARCHAR,
        dv_agencia_executor                                 VARCHAR,
        nome_agencia_executor                               VARCHAR,
        numero_conta_executor                               VARCHAR,
        dv_conta_executor                                   VARCHAR,
        codigo_situacao_dado_bancario_executor              VARCHAR,
        descricao_situacao_dado_bancario_executor           VARCHAR,
        FOREIGN KEY (id_plano_acao) REFERENCES plano_acao(id_plano_acao)
      );
    ",

    # 6. plano_trabalho (FK → plano_acao)
    plano_trabalho = "
      CREATE TABLE IF NOT EXISTS plano_trabalho (
        id_plano_trabalho                              VARCHAR PRIMARY KEY,
        situacao_plano_trabalho                         VARCHAR,
        ind_orcamento_proprio_plano_trabalho            VARCHAR,
        data_inicio_execucao_plano_trabalho             TIMESTAMP,
        data_fim_execucao_plano_trabalho                TIMESTAMP,
        prazo_execucao_meses_plano_trabalho             VARCHAR,
        id_plano_acao                                   VARCHAR,
        classificacao_orcamentaria_pt                   VARCHAR,
        ind_justificativa_prorrogacao_atraso_pt         VARCHAR,
        ind_justificativa_prorrogacao_paralizacao_pt    VARCHAR,
        justificativa_prorrogacao_pt                    VARCHAR,
        FOREIGN KEY (id_plano_acao) REFERENCES plano_acao(id_plano_acao)
      );
    ",

    # 7. documento_habil (FK → empenho)
    documento_habil = "
      CREATE TABLE IF NOT EXISTS documento_habil (
        id_dh                                           VARCHAR PRIMARY KEY,
        id_minuta_documento_habil                       VARCHAR,
        numero_documento_habil                          VARCHAR,
        situacao_dh                                     VARCHAR,
        descricao_situacao_dh                            VARCHAR,
        tipo_documento_dh                               VARCHAR,
        ug_emitente_dh                                  VARCHAR,
        descricao_ug_emitente_dh                        VARCHAR,
        data_vencimento_dh                              DATE,
        data_emissao_dh                                 DATE,
        ug_pagadora_dh                                  VARCHAR,
        descricao_ug_pagadora_dh                        VARCHAR,
        variacao_patrimonial_diminuta_dh                VARCHAR,
        passivo_transferencia_constitucional_legal_dh   VARCHAR,
        centro_custo_empenho                            VARCHAR,
        codigo_siorg_empenho                            VARCHAR,
        mes_referencia_empenho                          VARCHAR,
        ano_referencia_empenho                          VARCHAR,
        ug_beneficiada_dh                               VARCHAR,
        descricao_ug_beneficiada_dh                     VARCHAR,
        valor_dh                                        DOUBLE,
        valor_rateio_dh                                 DOUBLE,
        id_empenho                                      VARCHAR,
        FOREIGN KEY (id_empenho) REFERENCES empenho(id_empenho)
      );
    ",

    # 8. meta (FK → executor)
    meta = "
      CREATE TABLE IF NOT EXISTS meta (
        id_executor                            VARCHAR,
        id_meta                                VARCHAR PRIMARY KEY,
        sequencial_meta                        VARCHAR,
        nome_meta                              VARCHAR,
        desc_meta                              VARCHAR,
        un_medida_meta                         VARCHAR,
        qt_uniade_meta                         DOUBLE,
        vl_custeio_emenda_especial_meta        DOUBLE,
        vl_investimento_emenda_especial_meta   DOUBLE,
        vl_custeio_recursos_proprios_meta      DOUBLE,
        vl_investimento_recursos_proprios_meta DOUBLE,
        vl_custeio_rendimento_meta             DOUBLE,
        vl_investimento_rendimento_meta        DOUBLE,
        vl_custeio_doacao_meta                 DOUBLE,
        vl_investimento_doacao_meta            DOUBLE,
        qt_meses_meta                          DOUBLE,
        FOREIGN KEY (id_executor) REFERENCES executor(id_executor)
      );
    ",

    # 9. finalidade (tabela associativa, sem PK; FK → executor)
    finalidade = "
      CREATE TABLE IF NOT EXISTS finalidade (
        id_executor                      VARCHAR,
        cd_area_politica_publica_tipo_pt VARCHAR,
        area_politica_publica_tipo_pt    VARCHAR,
        cd_area_politica_publica_pt      VARCHAR,
        area_politica_publica_pt         VARCHAR,
        FOREIGN KEY (id_executor) REFERENCES executor(id_executor)
      );
    ",

    # 10. plano_trabalho_analise (FK → plano_trabalho)
    plano_trabalho_analise = "
      CREATE TABLE IF NOT EXISTS plano_trabalho_analise (
        id_plano_trabalho_analise        VARCHAR PRIMARY KEY,
        codigo_siorg_orgao_analise_pt    VARCHAR,
        nome_orgao_analise_pt            VARCHAR,
        situacao_planejamento_pt         VARCHAR,
        situacao_parecer_analise_pt      VARCHAR,
        texto_parecer_analise_pt         VARCHAR,
        situacao_analise_pt              VARCHAR,
        data_analise_pt                  TIMESTAMP,
        valor_reprovado_analise_pt       DOUBLE,
        id_plano_trabalho                VARCHAR,
        FOREIGN KEY (id_plano_trabalho) REFERENCES plano_trabalho(id_plano_trabalho)
      );
    ",

    # 11. orgao_analise_pendente (FK → plano_trabalho)
    orgao_analise_pendente = "
      CREATE TABLE IF NOT EXISTS orgao_analise_pendente (
        id_analise_pendente             VARCHAR PRIMARY KEY,
        id_orgao_analise_pendente_pt    VARCHAR,
        nome_orgao_analise_pendente_pt  VARCHAR,
        id_plano_trabalho               VARCHAR,
        FOREIGN KEY (id_plano_trabalho) REFERENCES plano_trabalho(id_plano_trabalho)
      );
    ",

    # 12. ordem_pagamento (FK → documento_habil)
    ordem_pagamento = "
      CREATE TABLE IF NOT EXISTS ordem_pagamento (
        id_op_ob                                    VARCHAR PRIMARY KEY,
        data_emissao_op                             DATE,
        numero_ordem_pagamento                      VARCHAR,
        vinculacao_op                               VARCHAR,
        situacao_op                                 VARCHAR,
        descricao_situacao_op                       VARCHAR,
        data_situacao_op                            DATE,
        data_emissao_ob                             DATE,
        numero_ordem_bancaria                       VARCHAR,
        numero_ordem_lancamento                     VARCHAR,
        data_assinatura_ordenador_despesa_ob        DATE,
        data_assinatura_gestor_financeiro_ob        DATE,
        id_dh                                       VARCHAR,
        FOREIGN KEY (id_dh) REFERENCES documento_habil(id_dh)
      );
    ",

    # 13. historico_pagamento (FK → ordem_pagamento)
    historico_pagamento = "
      CREATE TABLE IF NOT EXISTS historico_pagamento (
        id_historico_op_ob               VARCHAR PRIMARY KEY,
        data_hora_historico_op           TIMESTAMP,
        historico_situacao_op            VARCHAR,
        descricao_historico_situacao_op  VARCHAR,
        id_op_ob                         VARCHAR,
        FOREIGN KEY (id_op_ob) REFERENCES ordem_pagamento(id_op_ob)
      );
    "
  )

  # Executa cada DDL na ordem
  purrr::iwalk(ddl, \(sql, nome) {
    DBI::dbExecute(con, sql)
    cli::cat_line(cli::col_cyan("  \u2714 Tabela criada: ", nome))
  })

  cli::cat_line(cli::col_green("\u2714 ", length(ddl), " tabelas criadas com sucesso."))
  invisible(names(ddl))
}


#' Popular tabelas do banco DuckDB a partir de data.frames
#' Insere os dados na ordem correta para respeitar as constraints de FK.
#' 
#' Esta função valida a presença de tabelas obrigatórias e remove automaticamente
#' tabelas dependentes quando suas tabelas pai estão ausentes, evitando falhas de FK.
#' 
#' Comportamento:
#' - Falha imediatamente se tabelas obrigatórias (ex: "programa") estiverem ausentes
#' - Remove automaticamente tabelas dependentes quando tabelas pai estão faltando
#' - Exemplo: se "empenho" faltar, "documento_habil", "ordem_pagamento" e 
#'   "historico_pagamento" são automaticamente removidas para evitar FK órfãs
#' 
#' @param con Conexão DBI ao banco DuckDB.
#' @param tabelas Lista nomeada de data.frames (saída de ler_csvs_transferegov).
popular_tabelas <- function(con, tabelas) {

  # Ordem de inserção que respeita dependências FK
  ordem_insercao <- c(
    "programa",
    "plano_acao",
    "empenho",
    "relatorio_gestao_novo",
    "executor",
    "plano_trabalho",
    "documento_habil",
    "meta",
    "finalidade",
    "plano_trabalho_analise",
    "orgao_analise_pendente",
    "ordem_pagamento",
    "historico_pagamento"
  )

  # Mapeamento de dependências: tabela → tabela pai (se houver FK)
  dependencias <- list(
    programa                = NULL,
    plano_acao              = "programa",
    empenho                 = "plano_acao",
    relatorio_gestao_novo   = "plano_acao",
    executor                = "plano_acao",
    plano_trabalho          = "plano_acao",
    documento_habil         = "empenho",
    meta                    = "executor",
    finalidade              = "executor",
    plano_trabalho_analise  = "plano_trabalho",
    orgao_analise_pendente  = "plano_trabalho",
    ordem_pagamento         = "documento_habil",
    historico_pagamento     = "ordem_pagamento"
  )

  # Tabelas obrigatórias (raiz da hierarquia)
  obrigatorias <- c("programa")

  # Mapeamento de chave primária por tabela (para deduplicar)
  pk_map <- c(
    programa                = "id_programa",
    plano_acao              = "id_plano_acao",
    empenho                 = "id_empenho",
    relatorio_gestao_novo   = "id_relatorio_gestao_novo",
    executor                = "id_executor",
    plano_trabalho          = "id_plano_trabalho",
    documento_habil         = "id_dh",
    meta                    = "id_meta",
    plano_trabalho_analise  = "id_plano_trabalho_analise",
    orgao_analise_pendente  = "id_analise_pendente",
    ordem_pagamento         = "id_op_ob",
    historico_pagamento     = "id_historico_op_ob"
    # finalidade não tem PK — será deduplicada por todas as colunas
  )

  # Valida que todas as tabelas esperadas existem nos dados lidos
  faltantes <- setdiff(ordem_insercao, names(tabelas))
  
  # Falha cedo se tabelas obrigatórias estiverem ausentes
  faltantes_obrigatorias <- intersect(faltantes, obrigatorias)
  if (length(faltantes_obrigatorias) > 0) {
    cli::cli_abort(c(
      "x" = paste("Tabelas obrigatórias ausentes nos CSVs:", 
                  paste(faltantes_obrigatorias, collapse = ", ")),
      "i" = "A carga não pode prosseguir sem as tabelas raiz da hierarquia."
    ))
  }
  
  # Remove tabelas faltantes e suas dependentes
  if (length(faltantes) > 0) {
    # Calcula todas as tabelas que devem ser removidas (faltantes + dependentes)
    # Pré-computa índice reverso (pai → filhos) para eficiência O(n)
    # Nota: usa c() para simplicidade; com 13 tabelas, overhead é negligível
    filhos_por_pai <- list()
    for (filho in names(dependencias)) {
      pai <- dependencias[[filho]]
      if (!is.null(pai)) {
        filhos_por_pai[[pai]] <- c(filhos_por_pai[[pai]], filho)
      }
    }
    
    tabelas_removidas <- faltantes
    fila_idx <- 1
    fila <- faltantes
    
    # BFS usando índice em vez de remover elementos (evita O(n) por remoção)
    while (fila_idx <= length(fila)) {
      pai_removido <- fila[fila_idx]
      fila_idx <- fila_idx + 1
      
      # Consulta O(1) no índice reverso
      filhos <- filhos_por_pai[[pai_removido]]
      if (!is.null(filhos)) {
        novos_filhos <- setdiff(filhos, tabelas_removidas)
        if (length(novos_filhos) > 0) {
          tabelas_removidas <- c(tabelas_removidas, novos_filhos)
          fila <- c(fila, novos_filhos)
        }
      }
    }
    
    cli::cat_line(cli::col_yellow(
      "\u26A0 Tabelas ausentes nos CSVs: ",
      paste(faltantes, collapse = ", ")
    ))
    
    # Se há tabelas dependentes que serão removidas além das faltantes
    dependentes_removidas <- setdiff(tabelas_removidas, faltantes)
    if (length(dependentes_removidas) > 0) {
      cli::cat_line(cli::col_yellow(
        "\u26A0 Tabelas dependentes também serão ignoradas (para evitar violações de FK): ",
        paste(dependentes_removidas, collapse = ", ")
      ))
    }
    
    ordem_insercao <- setdiff(ordem_insercao, tabelas_removidas)
  }

  # Insere cada tabela (com deduplicação prévia)
  purrr::walk(ordem_insercao, \(nome) {
    df <- tabelas[[nome]]
    n_orig <- nrow(df)

    # Deduplica pela PK (ou por todas as colunas se não houver PK)
    pk <- pk_map[nome]
    if (!is.na(pk) && pk %in% names(df)) {
      df <- dplyr::distinct(df, .data[[pk]], .keep_all = TRUE)
    } else {
      df <- dplyr::distinct(df)
    }

    n_dedup <- nrow(df)
    n_removidas <- n_orig - n_dedup

    DBI::dbAppendTable(con, nome, df)

    msg <- paste0("  \u2714 ", nome, ": ", format(n_dedup, big.mark = "."), " linhas inseridas")
    if (n_removidas > 0) {
      msg <- paste0(msg, " (", n_removidas, " duplicatas removidas)")
    }
    cli::cat_line(cli::col_cyan(msg))
  })

  cli::cat_line(cli::col_green("\u2714 Todas as tabelas populadas com sucesso."))
  invisible(ordem_insercao)
}


#' @title Executa uma consulta SQL no banco Transferegov
#' @description Envia uma query para o banco DuckDB e retorna uma tibble.
#' @param qry String com o comando SQL. Ex: "SELECT * FROM plano_acao LIMIT 5".
#' @param con Objeto de conexão DBI. Se NULL, abre uma conexão temporária e fecha ao final.
#' @param quiet Se TRUE, não imprime a mensagem da query no console.
#' @return Uma tibble com o resultado da consulta.
get_query <- function(qry, con = NULL, quiet = FALSE) {

  # Controle de conexão: se não fornecida, cria uma temporária
  usando_con_temp <- FALSE
  if (is.null(con)) {
    con <- conectar_transferegov()
    usando_con_temp <- TRUE
  }

  # Mensagem de log
  if (!quiet) {
    db_path <- tryCatch(DBI::dbGetInfo(con)$dbname, error = function(e) "DuckDB")
    message(sprintf("Executando em [%s]:\n%s", basename(db_path), qry))
  }

  # Execução segura
  resultado <- tryCatch({
    DBI::dbGetQuery(con, qry) |>
      tibble::as_tibble()
  }, finally = {
    # Garante fechamento se a conexão for temporária
    if (usando_con_temp) {
      DBI::dbDisconnect(con, shutdown = TRUE)
    }
  })

  return(resultado)
}