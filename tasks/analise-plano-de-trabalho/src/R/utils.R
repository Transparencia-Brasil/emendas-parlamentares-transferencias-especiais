#' Limpeza mínima e normalização de texto para buscas por dicionário
#'
#' @description
#' `tidy_text()` aplica uma sequência de transformações pensadas para
#' pré-processar texto em pt-BR visando *matching* posterior por dicionário:
#' - minúsculas;
#' - substituição de URLs, e-mails, menções, hashtags e emojis por marcadores;
#' - separação de hífens;
#' - remoção de pontuação (exceto os sinais dos marcadores < >);
#' - preservação de números;
#' - normalização de espaços.
#'
#' @param x Vetor de `string`.
#' @return Vetor de `string` com o texto limpo.
#' @details
#' Marcadores usados: `<url>`, `<email>`, `<mention>`, `<hashtag>`, `<emoji>`.
#' A função é totalmente vetorizada e preserva `NA_character_`.
#'
#' @examples
#' txt <- c(
#'   "Relatório – disponível em https://exemplo.org/Relatorio.pdf (versão 2).",
#'   "Contato: oi+dados@transparencia.org.br; veja @TransparenciaBR #LAI",
#'   "Custo-benefício: R$ 1.200,00 — entrega em 10-12 dias 😊"
#' )
#' tidy_text(txt)
#' #> "relatório  disponível em <url> versão 2"
#' #> "contato  <email>  veja <mention> <hashtag>"
#' #> "custo benefício  r 1.200,00  entrega em 10 12 dias <emoji>"
#'
#' @importFrom stringi stri_trans_tolower stri_replace_all_regex
#' @importFrom stringr str_replace_all str_trim
#' @export
tidy_text <- function(x) {
  # Validação leve
  if (!is.atomic(x)) {
    stop("`x` deve ser um vetor atômico (idealmente character).", call. = FALSE)
  }
  # Coerção segura para character; preserva NAs
  x <- as.character(x)

  # Função auxiliar que processa um elemento (usaremos vetorização do stringi)
  # Observação: usamos ICU regex (stringi) para lidar com classes Unicode.
  # Passos:
  # 1) normalização básica (quebras de linha/tabs -> espaço)
  x <- stringr::str_replace_all(x, "[\\r\\n\\t]+", " ")

  # 1b) Remove acentos
  x <- stringi::stri_trans_general(x, "Latin-ASCII")

  # 2) substituição de URLs (antes de e-mails/menções)
  #    cobre http(s)://... e www....
  x <- stringr::str_replace_all(x, "(?i)\\b(?:https?://|www\\.)\\S+", "<url>")

  # 3) substituição de e-mails
  x <- stringr::str_replace_all(
    x,
    "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b",
    "<email>"
  )

  # 4) menções (@usuario) – evitar capturar parte de e-mails (já substituídos)
  #    usamos limite de palavra/espaço no início
  x <- stringr::str_replace_all(x, "(^|\\s)@(\\p{L}|\\p{N}|_)+", "\\1<mention>")

  # 5) hashtags (#tema)
  x <- stringr::str_replace_all(x, "(^|\\s)#(\\p{L}|\\p{N}|_)+", "\\1<hashtag>")

  # 6) emojis → marcador (classe Unicode Extended_Pictographic)
  x <- stringi::stri_replace_all_regex(x, "\\p{Extended_Pictographic}+", "<emoji>")

  # 7) separar hífens (substituir hífens e similares por espaço)
  #    inclui várias variantes tipográficas
  x <- stringr::str_replace_all(x, "[-‐‑‒–—―]+", " ")

  # 8) minúsculas em pt (mantém acentuação)
  x <- stringi::stri_trans_tolower(x, locale = "pt")

  # 9) remover pontuação, preservando marcadores e separadores numéricos

  # 9a) remover toda pontuação EXCETO os sinais dos marcadores (<, >) e
  #     os separadores numéricos (ponto e vírgula)
  x <- stringi::stri_replace_all_regex(x, "[\\p{P}&&[^<>.,]]+", " ")

  # 9b) remover pontos e vírgulas que NÃO estejam entre dígitos
  #     (ou seja, manter apenas 1.234,56; apagar o resto)
  x <- stringi::stri_replace_all_regex(x, "(?<!\\d)[.,]|[.,](?!\\d)", " ")

  # 10) normalizar espaços (colapsar múltiplos e aparar)
  x <- stringr::str_replace_all(x, "\\s+", " ")
  x <- stringr::str_trim(x)

  # 11) strings vazias viram "" (mantemos assim) e NAs permanecem NAs
  x
}
