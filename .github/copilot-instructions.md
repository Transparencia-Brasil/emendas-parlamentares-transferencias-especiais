# Copilot Instructions para api-transferegov

## Visão geral do projeto

Este repositório realiza coleta, análise e classificação de dados relacionados ao Transferegov, utilizando principalmente R e automações baseadas em prompts para modelos de linguagem. O foco está em conformidade normativa e padronização dos processos de análise de despesas públicas.

## Arquitetura e componentes principais

- **tasks/**: Fluxos de análise organizados por tema. Cada subpasta contém scripts R, entradas e prompts específicos.
- **data/**: Fontes de dados brutos, organizadas por origem.
- **docs/**: Documentação estática e estilos para relatórios.
- **setup/**: Scripts de configuração do ambiente R.
- **transferegov/**: Scripts para coleta e cruzamento de dados da API, outputs tabulares e logs.
- **tasks/classificacao-natureza-despesa/prompts/**: Prompts e instruções para agentes de classificação e detalhamento.

## Convenções e padrões

- **Scripts R**: Nomeação sequencial e descritiva (`01-nome-do-script.R`).
- **Quarto/Markdown**: Use o padrão `01-neste-estilo.qmd` para arquivos de documentação ou análise.
- **Explicações**: Sempre em português simples e claro.
- **Prompts**: Atualize conforme mudanças normativas; consulte `AGENTS.md` para diretrizes de agentes.

## Fluxos de trabalho

- **Execução**: Scripts R são executados individualmente conforme o fluxo de análise. Use o RStudio ou terminal R.
- **Testes**: Testes unitários em `tests/` usando testthat.
- **Configuração**: Execute `setup/rsetup.R` para preparar o ambiente.
- **Dados**: Inputs e outputs organizados por tema em subpastas de `tasks/` e `transferegov/outputs/`.

## Integrações e dependências

- **API Transferegov**: Consulte a [documentação oficial](https://docs.api.transferegov.gestao.gov.br/transferenciasespeciais/#/).
- **Pacotes R**: tidyverse, ggplot2, broom, tidymodels.

## Exemplos de padrões

- Para criar um novo script de análise: `tasks/analise-plano-de-trabalho/src/R/07-nova-analise.R`
- Para adicionar um novo prompt: `tasks/classificacao-natureza-despesa/prompts/instrucao-nova.md`

## Recomendações para agentes

- Priorize clareza e rastreabilidade.
- Siga os padrões de nomeação e explicação.
- Consulte sempre os arquivos de instrução e prompts antes de automatizar fluxos.

---

Consulte `AGENTS.md` e os READMEs das pastas para detalhes específicos de cada fluxo ou agente.
