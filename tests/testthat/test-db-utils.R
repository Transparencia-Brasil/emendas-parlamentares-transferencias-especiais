library(testthat)
library(here)
source(here("tasks/db/src/R/utils.R"))

test_that("converter_tipos converte colunas numéricas com prefixos valor_, vl_, qt_", {
  df <- data.frame(
    valor_total = c("100.50", "200.75", "300"),
    vl_custeio = c("50.25", "75.50", "100"),
    qt_unidades = c("10", "20", "30"),
    nome = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )

  resultado <- converter_tipos(df)

  expect_type(resultado$valor_total, "double")
  expect_type(resultado$vl_custeio, "double")
  expect_type(resultado$qt_unidades, "double")
  expect_equal(resultado$valor_total, c(100.50, 200.75, 300))
  expect_equal(resultado$vl_custeio, c(50.25, 75.50, 100))
  expect_equal(resultado$qt_unidades, c(10, 20, 30))
  expect_type(resultado$nome, "character")
})

test_that("converter_tipos converte colunas DATE com prefixo data_ (sem hora)", {
  df <- data.frame(
    data_inicio = c("2024-01-15", "2024-02-20", "2024-03-25"),
    data_fim = c("2024-06-30", "2024-07-31", "2024-08-31"),
    nome = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )

  resultado <- converter_tipos(df)

  expect_s3_class(resultado$data_inicio, "Date")
  expect_s3_class(resultado$data_fim, "Date")
  expect_equal(resultado$data_inicio, as.Date(c("2024-01-15", "2024-02-20", "2024-03-25")))
  expect_equal(resultado$data_fim, as.Date(c("2024-06-30", "2024-07-31", "2024-08-31")))
  expect_type(resultado$nome, "character")
})

test_that("converter_tipos converte colunas TIMESTAMP com data_hora_ (ISO 8601 sem frações)", {
  df <- data.frame(
    data_hora_criacao = c("2024-01-15T10:30:00", "2024-02-20T14:45:30", "2024-03-25T08:15:45"),
    nome = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )

  resultado <- converter_tipos(df)

  expect_s3_class(resultado$data_hora_criacao, "POSIXct")
  expect_equal(
    resultado$data_hora_criacao,
    as.POSIXct(c("2024-01-15T10:30:00", "2024-02-20T14:45:30", "2024-03-25T08:15:45"),
               format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC")
  )
  expect_type(resultado$nome, "character")
})

test_that("converter_tipos converte colunas TIMESTAMP com data_hora_ (ISO 8601 com frações)", {
  df <- data.frame(
    data_hora_atualizacao = c("2024-01-15T10:30:00.123", "2024-02-20T14:45:30.456", "2024-03-25T08:15:45.789"),
    nome = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )

  resultado <- converter_tipos(df)

  expect_s3_class(resultado$data_hora_atualizacao, "POSIXct")
  expect_equal(
    resultado$data_hora_atualizacao,
    as.POSIXct(c("2024-01-15T10:30:00.123", "2024-02-20T14:45:30.456", "2024-03-25T08:15:45.789"),
               format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC")
  )
  expect_type(resultado$nome, "character")
})

test_that("converter_tipos converte colunas TIMESTAMP com data_e_hora_ (ISO 8601)", {
  df <- data.frame(
    data_e_hora_relatorio = c("2024-01-15T10:30:00", "2024-02-20T14:45:30.123"),
    nome = c("A", "B"),
    stringsAsFactors = FALSE
  )

  resultado <- converter_tipos(df)

  expect_s3_class(resultado$data_e_hora_relatorio, "POSIXct")
  expect_equal(
    resultado$data_e_hora_relatorio,
    as.POSIXct(c("2024-01-15T10:30:00", "2024-02-20T14:45:30.123"),
               format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC")
  )
  expect_type(resultado$nome, "character")
})

test_that("converter_tipos não converte data_hora_ para DATE (deve ser TIMESTAMP)", {
  df <- data.frame(
    data_hora_teste = c("2024-01-15T10:30:00"),
    data_teste = c("2024-01-15"),
    stringsAsFactors = FALSE
  )

  resultado <- converter_tipos(df)

  # data_hora_ deve ser POSIXct, não Date
  expect_s3_class(resultado$data_hora_teste, "POSIXct")
  expect_false(inherits(resultado$data_hora_teste, "Date"))

  # data_ (sem hora) deve ser Date
  expect_s3_class(resultado$data_teste, "Date")
})

test_that("converter_tipos mantém colunas character quando não há padrão", {
  df <- data.frame(
    nome = c("João", "Maria", "José"),
    codigo = c("ABC123", "DEF456", "GHI789"),
    descricao = c("Texto 1", "Texto 2", "Texto 3"),
    stringsAsFactors = FALSE
  )

  resultado <- converter_tipos(df)

  expect_type(resultado$nome, "character")
  expect_type(resultado$codigo, "character")
  expect_type(resultado$descricao, "character")
})

test_that("converter_tipos lida com múltiplos tipos de colunas simultaneamente", {
  df <- data.frame(
    id = c("1", "2", "3"),
    valor_total = c("100.50", "200.75", "300"),
    data_inicio = c("2024-01-15", "2024-02-20", "2024-03-25"),
    data_hora_criacao = c("2024-01-15T10:30:00", "2024-02-20T14:45:30", "2024-03-25T08:15:45"),
    nome = c("A", "B", "C"),
    qt_items = c("5", "10", "15"),
    stringsAsFactors = FALSE
  )

  resultado <- converter_tipos(df)

  expect_type(resultado$id, "character")
  expect_type(resultado$valor_total, "double")
  expect_s3_class(resultado$data_inicio, "Date")
  expect_s3_class(resultado$data_hora_criacao, "POSIXct")
  expect_type(resultado$nome, "character")
  expect_type(resultado$qt_items, "double")
})

test_that("converter_tipos lida com valores NA corretamente", {
  df <- data.frame(
    valor_total = c("100.50", NA, "300"),
    data_inicio = c("2024-01-15", NA, "2024-03-25"),
    data_hora_criacao = c("2024-01-15T10:30:00", NA, "2024-03-25T08:15:45"),
    stringsAsFactors = FALSE
  )

  resultado <- converter_tipos(df)

  expect_type(resultado$valor_total, "double")
  expect_true(is.na(resultado$valor_total[2]))
  expect_s3_class(resultado$data_inicio, "Date")
  expect_true(is.na(resultado$data_inicio[2]))
  expect_s3_class(resultado$data_hora_criacao, "POSIXct")
  expect_true(is.na(resultado$data_hora_criacao[2]))
})

test_that("converter_tipos preserva estrutura do dataframe", {
  df <- data.frame(
    valor_a = c("10", "20"),
    nome = c("X", "Y"),
    data_teste = c("2024-01-01", "2024-02-01"),
    stringsAsFactors = FALSE
  )

  resultado <- converter_tipos(df)

  expect_equal(nrow(resultado), 2)
  expect_equal(ncol(resultado), 3)
  expect_equal(names(resultado), c("valor_a", "nome", "data_teste"))
})

test_that("converter_tipos converte colunas numéricas com prefixos populacao_ e pib_", {
  df <- data.frame(
    populacao_2022 = c("51990", "2312", "16976"),
    pib_2021 = c("1234567890", "39801594", "127927329"),
    nome = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )

  resultado <- converter_tipos(df)

  expect_type(resultado$populacao_2022, "double")
  expect_type(resultado$pib_2021, "double")
  expect_equal(resultado$populacao_2022, c(51990, 2312, 16976))
  expect_equal(resultado$pib_2021, c(1234567890, 39801594, 127927329))
  expect_type(resultado$nome, "character")
})
