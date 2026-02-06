# Contributor Guidelines

## Stack

- R, tidyverse, ggplot2, broom, tidymodels.

## Observações importantes

- Explicar conceitos de forma simples e em português
- Escreve em PT-BR
- Padrão para nomear arquivos: `01-neste-estilo.qmd`

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
