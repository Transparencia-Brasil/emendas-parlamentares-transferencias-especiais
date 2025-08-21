library(here)
library(tidyverse)


# :: PATHS ---------------------------------------------------------------------

INPUT_DIR <- "tasks/classificacao-natureza-despesa/inputs"
OUTPUT_DIR <- "tasks/classificacao-natureza-despesa/inputs"
TRANSFEREGOV_DIR <- here("tasks/transferegov/outputs")

PATH_TRANSFEREGOV_TABLES <- list.files(
  TRANSFEREGOV_DIR,
  pattern = "csv$",
  full.names = TRUE
)

PATH_PORTARIA_103_2021 <- here(
  INPUT_DIR,
  "texto-completo-portaria-103-2021.rds"
)
PATH_PORTARIA_103_2021_TXT <- here(
  INPUT_DIR,
  "texto-completo-portaria-103-2021.txt"
)
PATH_NATUREZA_DESPESA <- here(INPUT_DIR, "natureza-de-despesas.rds")
PATH_DISCRIMINACAO_NATUREZA_DESPESA <- here(
  INPUT_DIR,
  "discriminacao-natureza-de-despesas.rds"
)


# :: LOAD TRANSFEREGOV ---------------------------------------------------------

# helper para carregar os dados
read_transferegov_csvs <- \(x) {
  ids <- basename(x) |>
    snakecase::to_snake_case() |>
    str_remove("^\\d+_") |>
    str_remove("_csv$") |>
    str_remove("_especial$")
  x |>
    map(read_csv, col_types = cols(.default = col_character())) |>
    set_names(ids)
}

# carrega todos os dados
transferegov <- read_transferegov_csvs(PATH_TRANSFEREGOV_TABLES)

# isolando o campo objeto_executor
executores <- transferegov$plano_acao |>
  filter(id_programa == "23") |>
  distinct(id_plano_acao) |>
  inner_join(transferegov$executor) |>
  mutate(across(starts_with("vl_"), as.numeric)) |>
  select(id_plano_acao, id_executor, objeto_executor)

# > executores
# # A tibble: 9,755 × 3
#    id_plano_acao id_executor objeto_executor
#    <chr>         <chr>       <chr>
#  1 83398         38161       "PAVIMENTAÇÃO EM TRECHOS DE ESTRADAS VICINAIS DE QUILOMBO/SC"
#  2 78012         39470       "Pavimentação em Paralelepípedo das Ruas Juvenal Ferreira Dantas, Maria da Guia Vasconcelos e Sabino Ferreira de Vasconc…
#  3 75539         38219       "Construção de Centro Comunitário Esportivo na Sede do Município de Arataca/BA"
#  4 84071         42980       "Pavimentação tipo TSD na rua Edmundo Vieira de Freitas Sobrinho, bairro Aeroporto com travessia para o bairro professor…
#  5 79653         40080       "O objeto da presente emenda parlamentar é a revitalização e reforma do camelódromo de Uberlândia/MG, visando melhorar a…
#  6 83591         37588       "Implantação de passagens molhadas em estradas vicinais no município de Olho D'Água Grande – AL"
#  7 76173         43087       "Custeio de ações e serviços de Atenção Primária à Saúde, com foco no fortalecimento da Estratégia Saúde da Família, amp…
#  8 84471         38230       "Pavimentação/Asfalto sobre pavimento existente e Paralelepípedos e Calçadas nas ruas: Rua Arthur Marinho de Menezes e T…
#  9 83885         38782       "Aquisição de uma retroescavadeira para a secretaria municipal de obras, destinada melhoria dos serviços urbanos no muni…
# 10 76896         39518       "REFORMA DA ESCOLA MUNICIPAL DE ENSINO FUNDAMENTAL VEREADOR CANDIDO LOPES DE OLIVEIRA EM SÃO DOMINGOS DO CAPIM/PA"
# # ℹ 9,745 more rows
# # ℹ Use `print(n = ...)` to see more rows

# isolando o campo desc_meta
metas <- transferegov$plano_acao |>
  filter(id_programa == "23") |>
  distinct(id_plano_acao) |>
  inner_join(transferegov$executor) |>
  distinct(id_executor) |>
  inner_join(transferegov$meta) |>
  mutate(across(starts_with("vl_"), as.numeric)) |>
  mutate(across(starts_with("qt_"), as.numeric)) |>
  select(id_executor, id_meta, desc_meta)

# > metas
# # A tibble: 17,236 × 3
#    id_executor id_meta desc_meta
#    <chr>       <chr>   <chr>
#  1 38161       83871   Execução de pavimentação com pedras irregulares em parte de estrada vicinal localizada na Linha Janeiro, situada na zona rural.
#  2 38161       84281   Execução de pavimentação com pedras irregulares em parte de estrada vicinal localizada na Linha Consoladora, situada na zona r…
#  3 38161       84282   Execução de pavimentação com pedras irregulares em parte de estrada vicinal localizada na Linha Venturin, situada na zona rura…
#  4 38161       84283   Execução de pavimentação com pedras irregulares em parte de estrada vicinal localizada na Linha Santa Lúcia, situada na zona r…
#  5 39470       85614   Pavimentação em Paralelepípedo das Ruas Juvenal Ferreira Dantas, Maria da Guia Vasconcelos e Sabino Ferreira de Vasconcelos, L…
#  6 38219       83945   Construção de Centro Comunitário Esportivo na Sede do Município de Arataca/BA
#  7 42980       91420   Implantação de pavimentação urbana em travessia, com extensão de cerca de 415m, contemplando terraplanagem, drenagem, paviment…
#  8 40080       86456   REFORMA DO CAMELODROMO MUNICIPAL DA AVENIDA AFONSO PENA
#  9 37588       83118   Implantação De Passagem Molhada Em Estradas Vicinais no Municipio ee Olho Dagua Grande - AL
# 10 43087       91569   Execução dos serviços de Atenção Primária à Saúde nas Unidades Básicas de Saúde, mediante contrato de gestão firmado com a Org…
# # ℹ 17,226 more rows
# # ℹ Use `print(n = ...)` to see more rows

# :: LOAD CATEGORIAS DE DESPESA ------------------------------------------------

natureza_despesa <- readRDS(PATH_NATUREZA_DESPESA)
# > natureza_despesa
# $`A - CATEGORIAS ECONÔMICAS`
# # A tibble: 2 × 3
#   codigo_descricao descricao           conceito

#   <chr>            <chr>               <chr>

# 1 3                Despesas Correntes  Classificam-se nessa categoria todas as despesas que não contribuem, diretamente, para a formação ou aquisição…
# 2 4                Despesas de Capital Classificam-se nessa categoria aquelas despesas que contribuem, diretamente, para a formação ou aquisição de u…

# $`B - GRUPOS DE NATUREZA DE DESPESA`
# # A tibble: 6 × 3
#   codigo_descricao descricao                  conceito

#   <chr>            <chr>                      <chr>

# 1 1                Pessoal e Encargos Sociais "Despesas orçamentárias com pessoal ativo, inativo e pensionistas, relativas a mandatos eletivos, cargo…
# 2 2                Juros e Encargos da Dívida "Despesas orçamentárias com o pagamento de juros, comissões e outros encargos de operações de crédito i…
# 3 3                Outras Despesas Correntes  "Despesas orçamentárias com aquisição de material de consumo, pagamento de diárias, contribuições, subv…
# 4 4                Investimentos              "Despesas orçamentárias com softwares e com o planejamento e a execução de obras, inclusive com a aquis…
# 5 5                Inversões Financeiras      "Despesas orçamentárias com a aquisição de imóveis ou bens de capital já em utilização; aquisição de tí…
# 6 6                Amortização da Dívida      "Despesas orçamentárias com o pagamento e/ou refinanciamento do principal e da atualização monetária ou…

# $`C - MODALIDADES DE APLICAÇÃO`
#                      Despesa…
#  5 32               Execução Orçamentária Delegada a Estados e ao Distrito Federal                                                            Despesa…
#  6 35               Transferências Fundo a Fundo aos Estados e ao Distrito Federal à conta de recursos de que tratam os §§ 1oe 2odo art. 24 … Despesa…
#  7 36               Transferências Fundo a Fundo aos Estados e ao Distrito Federal à conta de recursos de que trata o art. 25 da Lei Complem… Despesa…
#  8 40               Transferências a Municípios                                                                                               Despesa…
#  9 41               Transferências a Municípios - Fundo a Fundo                                                                               Despesa…
# 10 42               Execução Orçamentária Delegada a Municípios                                                                               Despesa…
# # ℹ 21 more rows
# # ℹ Use `print(n = ...)` to see more rows

# $`D - ELEMENTOS DE DESPESA`
# # A tibble: 84 × 3
#    codigo_descricao descricao                                                conceito
#    <chr>            <chr>                                                    <chr>
#  1 01               Aposentadorias, Reserva Remunerada e Reformas            "Despesas orçamentárias com pagamento de aposentadorias de servidores in…
#  2 03               Pensões                                                  "Despesas orçamentárias com pagamento de pensões civis, pelo Regime Próp…
#  3 04               Contratação por Tempo Determinado                        "Despesas orçamentárias com a contratação de pessoal por tempo determina…
#  4 06               Benefício Mensal ao Deficiente e ao Idoso                "Despesas orçamentárias decorrentes do cumprimento do art. 203, inciso V…
#  5 07               Contribuição a Entidades Fechadas de Previdência         "Despesas orçamentárias com os encargos da entidade patrocinadora no reg…
#  6 08               Outros Benefícios Assistenciais do servidor e do militar "Despesas orçamentárias com benefícios assistenciais, inclusive auxílio-…
#  7 10               Seguro Desemprego e Abono Salarial                       "Despesas orçamentárias com pagamento do seguro-desemprego e do abono de…
#  8 11               Vencimentos e Vantagens Fixas - Pessoal Civil            "Despesas orçamentárias com: Vencimento; Salário Pessoal Permanente; Ven…
#  9 12               Vencimentos e Vantagens Fixas - Pessoal Militar          "Despesas orçamentárias com: Soldo; Gratificação de Localidade Especial;…
# 10 13               Obrigações Patronais                                     "Despesas orçamentárias com encargos que a administração tem pela sua co…
# # ℹ 74 more rows
# # ℹ Use `print(n = ...)` to see more rows

discriminacao_natureza_despesa <- readRDS(PATH_DISCRIMINACAO_NATUREZA_DESPESA)
# > discriminacao_natureza_despesa
# # A tibble: 678 × 2
#    codigo       texto
#    <chr>        <chr>
#  1 3.0.00.00.00 DESPESAS CORRENTES
#  2 3.1.00.00.00 PESSOAL E ENCARGOS SOCIAIS
#  3 3.1.30.00.00 Transferências a Estados e ao Distrito Federal
#  4 3.1.30.41.00 Contribuições
#  5 3.1.30.99.00 A Classificar
#  6 3.1.71.00.00 Transferências a Consórcios Públicos mediante contrato de rateio
#  7 3.1.71.70.00 Rateio pela Participação em Consórcio Público
#  8 3.1.71.99.00 A Classificar
#  9 3.1.73.00.00 Transferências a Consórcios Públicos mediante contrato de rateio à conta de recursos de que tratam os §§ 1 o e 2 o do art. 24 da Lei …
# 10 3.1.73.70.00 Rateio pela Participação em Consórcio Público
# # ℹ 668 more rows
# # ℹ Use `print(n = ...)` to see more rows

#' Precisamos perguntar aos dados:

# EXEMPLO:

# Exemplo de dicionário
# dicionário de códigos BR
# codbr_env <- catmat %>%
#   select(codigo_br, desc_item) %>%
#   deframe() %>%
#   as.list() %>%
#   list2env(new.env(hash = TRUE))
#

# Busca códigoBR na descrição usando hash table
#descr <- descr %>%
#  mutate(
#    descricao_catmat = map_chr(
#      clean_descricao,
#      retorna_termo_dicionario,
#      envir = codbr_env
#    )
#  )
#
#

#' Detecta e retorna um termo de um texto com base em um dicionário hash table.
#'
#' @param texto A string na qual será procurada texto definido em dicionário
#'  definido com hash table, new.env(hash=TRUE).
#' @param envir variável hash-table (new.env(hash=TRUE))
#'
#' @return Uma string contendo a descrição associada ao texto.
#'
#' @examples
#' extrai_dicionario("Frasco 1000 ML", unid_medida_env)
#' Retorna: [1] "frasco"
# retorna_termo_dicionario <- function(texto, envir) {
#   # Lookup hashtable (cópia no escopo local)
#   lookup_map <- envir

#   # Separa o texto em tokens
#   tokens <- unlist(strsplit(texto, " "))

#   # Se o token estiver no mapa de pesquisa retorna a unidade de medida
#   # itera sobre a lista de tokens
#   term <- NA
#   for (token in tokens) {
#     if (!is.null(lookup_map[[token]])) term <- lookup_map[[token]]
#   }

#   return(term)
# }

#' Implementação abaixo: normalização de texto, criação de dicionário/hash-table
#' e enriquecimento das tabelas com o elemento de despesa (código e descrição).
