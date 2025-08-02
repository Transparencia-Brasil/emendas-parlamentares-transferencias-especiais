#' Faz uma requisição a um endpoint e retorna os dados em formato de dataframe
#'
#' @description
#' Esta função realiza uma requisição HTTP GET para o endpoint fornecido, captura possíveis erros
#' e retorna os dados da resposta em um dataframe.
#'
#' @param endpoint Uma string contendo a URL do endpoint a ser consultado.
#'
#' @return Um dataframe contendo os dados retornados pelo endpoint, acrescido de uma coluna:
#'   - `endpoint`: a URL do endpoint consultado.
#'
coleta_endpoint <- function(endpoint) {
  # Faz a requisição ao endpoint
  resposta <- request(endpoint) %>%
    req_method("GET") %>%
    req_headers(accept = "*/*") %>%
    req_error() %>% # Captura erros se houver
    req_perform()

  # Converte a resposta da requisicao em um dataframe
  df_itens <- resp_body_string(resposta) %>%
    fromJSON(flatten = TRUE) %>%
    as.data.frame() %>%
    as_tibble()

  df_itens$endpoint <- endpoint

  # # Informa o progresso da coleta
  # cat(endpoint, "\r")
  # flush.console()

  # Pausar brevemente entre as requisições para evitar sobrecarregar o servidor
  Sys.sleep(0.2)

  return(df_itens)
}