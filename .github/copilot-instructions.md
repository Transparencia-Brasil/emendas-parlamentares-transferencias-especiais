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

## Instruções para Commits

- Mensagens de commit devem ser escritas em português (pt-br).
- Seja objetivo e claro, descrevendo a alteração realizada.
- Mensagens de commit devem começar sempre com uma palavra-chave seguida de explicação curta, por exemplo:
  - feat (ou “feature”): introduz funcionalidade nova para o usuário.
  - fix: corrige bug (comportamento incorreto).
  - chore: manutenção que não muda comportamento do produto (ex.: atualizar dependência, ajustes de CI, limpeza).
  - refactor: mudança interna de código sem mudar comportamento (nem corrigir bug, nem adicionar feature).
  - docs: documentação (README, comentários de docs, wiki).
  - test: adicionar/ajustar testes.
  - perf: melhoria de performance.
  - build: mudanças no sistema de build/deps (ex.: webpack, poetry, npm lock).
  - ci: pipeline (GitHub Actions, etc.).
  - style: formatação (lint, whitespace) sem alterar lógica.
- Evite mensagens genéricas sem explicação, como apenas "update" ou "fix".
- Commits que envolvem dados sensíveis ou mudanças estruturais devem conter explicação sucinta do impacto.
- Use o tempo presente para descrever a mudança, por exemplo: "Adiciona função de limpeza de dados" em vez de "Adicionou função de limpeza de dados".

---

Consulte `AGENTS.md` e os READMEs das pastas para detalhes específicos de cada fluxo ou agente.