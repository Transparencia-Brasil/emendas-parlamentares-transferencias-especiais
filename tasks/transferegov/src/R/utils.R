#' Monta uma requisição para a API do Transferegov
#'
#' @param host URL base da API.
#' @param basepath Caminho base do módulo da API.
#' @param resource Recurso específico a ser acessado.
#' @param params Lista de parâmetros de consulta.
#'
#' @return Um objeto de requisição (`httr2_request`).
#'
request_transferegov_resource <- function(host = "https://api.transferegov.gestao.gov.br",
                                          basepath = "transferenciasespeciais",
                                          resource,
                                          params = list()) {
  req <- request(host) |>
    req_url_path_append(basepath) |>
    req_url_path_append(resource)

  if (length(params) > 0) req <- req_url_query(req, !!!params)

  Sys.sleep(.15)

  return(req)
}

#' Coleta dados paginados da API do Transferegov
#'
#' @param ... Argumentos passados para `request_transferegov_resource()`.
#'
#' @return Um `tibble` com os dados coletados.
#'
collect_transferegov_resource <- function(...) {
  # callback para monitorar o fim da paginação
  is_complete <- function(resp) {
    resp <- resp_body_json(resp, simplifyVector = TRUE)
    resp <- as_tibble(resp)
    nrow(resp) == 0
  }

  # append de todas as páginas
  resps_data_as_tibble <- function(resp) {
    data <- resp_body_json(resp, simplifyVector = TRUE)
    data <- as_tibble(data)
  }

  # requisição e coleta dinâmica dos dados da API
  request_transferegov_resource(...) |>
    req_throttle(capacity = 30, fill_time_s = 60) |> # 30 requisições em 60 segundos
    req_perform_iterative(
      max_reqs = Inf,
      next_req = iterate_with_offset(
        param_name = "offset",
        start = 0,
        offset = 1000,
        resp_complete = is_complete
      )
    ) |>
    resps_data(resps_data_as_tibble)
}

#' Coleta dados da API Transferegov e salva em CSV
#'
#' @param resource Recurso da API a ser acessado.
#' @param key Parâmetros de consulta (lista nomeada).
#' @param perc Indicador de progresso.
#' @param path_output Caminho do arquivo CSV de saída.
#'
#' @return Sem retorno. Salva os dados em arquivo.
#'
fetch_transferegov_resource <- function(resource, key = list(), perc, path_output) {
  msg <- sprintf("Key: %s; %s complete", key[[1]], perc)
  flush.console()
  cat(msg, "\r")

  result <- collect_transferegov_resource(resource = resource, param = key)

  if (nrow(result) > 0) {
    fwrite(
      result,
      path_output,
      sep = ",",
      row.names = FALSE,
      col.names = !file.exists(path_output),
      append = TRUE,
      quote = TRUE
    )
  }
}

#' Gera parâmetros para consulta à API Transferegov
#'
#' Lê um arquivo CSV, extrai valores únicos de uma coluna-chave e monta uma tibble
#' com os parâmetros necessários para chamadas à API.
#'
#' @param path_input Caminho para o arquivo CSV de entrada.
#' @param path_output Caminho onde os resultados serão salvos.
#' @param resource Nome do recurso da API.
#' @param key_column Nome da coluna que contém os identificadores.
#'
#' @return Uma tibble com colunas: `resource`, `key`, `perc`, `path_output`.
#'
build_transferegov_params <- function(path_input, path_output, resource, key_column) {
  # Lê o arquivo e extrai os valores únicos da coluna-chave
  df <- read_csv(path_input, col_types = "c") |>
    distinct(.data[[key_column]])

  # Nome da coluna-chave
  key_values <- df[[key_column]]

  # Monta tibble com parâmetros
  tibble(
    resource = resource,
    key = map(key_values, ~ list(sprintf("eq.%s", .x)) |> set_names(key_column)),
    perc = scales::percent(seq_along(key_values) / length(key_values), accuracy = 0.02),
    path_output = path_output
  )
}
