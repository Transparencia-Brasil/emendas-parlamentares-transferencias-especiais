# POPULACAO RESIDENTE 2022 ======================================================

populacao_ibge_sidra <- "https://apisidra.ibge.gov.br/values/t/9514/n6/all/v/allxp/p/all/c2/6794/c287/100362/c286/113635"

tidy_populacao_ibge <- \(populacao_ibge) {
  col_names <- flatten_chr(populacao_ibge[1, ])
  populacao_ibge <- populacao_ibge %>%
    set_names(col_names) %>%
    slice(-1)
  return(populacao_ibge)
}

populacao_ibge <- populacao_ibge_sidra %>%
  request() %>%
  req_method("GET") %>%
  req_headers(accept = "*/*") %>%
  req_perform() %>%
  resp_body_json(simplifyVector = TRUE) %>%
  as_tibble() %>%
  tidy_populacao_ibge() %>%
  transmute(
    codigo_ibge = `Município (Código)`,
    populacao_2022 = as.integer(Valor)
  )

# PIB MUNICIPIOS 2021 ==========================================================

pib_ibge_sidra <- "https://apisidra.ibge.gov.br/values/t/5938/n6/all/v/37/p/last%201/d/v37%203"

tidy_pib_ibge <- \(pib_ibge) {
  col_names <- flatten_chr(pib_ibge[1, ])
  pib_ibge <- pib_ibge %>%
    set_names(col_names) %>%
    slice(-1)
  return(pib_ibge)
}

pib_ibge <- pib_ibge_sidra %>%
  request() %>%
  req_method("GET") %>%
  req_headers(accept = "*/*") %>%
  req_perform() %>%
  resp_body_json(simplifyVector = TRUE) %>%
  as_tibble() %>%
  tidy_pib_ibge() %>%
  transmute(
    codigo_ibge = `Município (Código)`,
    pib_2021 = as.numeric(Valor) * 1000
  )