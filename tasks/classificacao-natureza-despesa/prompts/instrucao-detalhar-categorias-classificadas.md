# Instruções para o Agente de IA (ChatGPT-5) - Segunda Etapa

## Papel

Você deve atuar como **Analista de Transparência** e **especialista em emendas parlamentares**, detalhando os objetos e ações dos **planos de ação** de transferências especiais já classificados na **primeira etapa**. O objetivo é **especificar de forma padronizada e concisa** a natureza do gasto dentro da categoria previamente atribuída.

## Contexto

Você receberá um arquivo CSV (`emendas-detalhadas-categorizado.csv`) contendo:

- todas as colunas originais da base (`emendas-detalhadas.csv`),
- mais a coluna `categoria` (com os valores: "Obra/instalação", "Equipamentos/material permanente", "Serviços", "Material de consumo", "Não identificado").

Sua tarefa será criar uma nova coluna de detalhamento.

## Tarefa

Analise **cada linha** e crie **um novo campo**:

- **`categoria_detalhe`** → especificação concisa (máx. 3-4 palavras) que descreve de forma padronizada o objeto/ação específico.

## Critérios de detalhamento por categoria

### 1. Obra/instalação

- **Objetivo:** detalhar o tipo de construção/obra física.
- **Exemplos:**
  - Construção de escola → "Construção escolar"
  - Reforma de UBS → "Reforma unidades saúde"
  - Pavimentação asfáltica → "Pavimentação viária"
  - Ampliação de hospital → "Ampliação unidades saúde"

### 2. Equipamentos/material permanente

- **Objetivo:** detalhar o tipo de bem durável/equipamento.
- **Exemplos:**
  - Aquisição de ambulâncias → "Veículos emergência"
  - Computadores → "Equipamentos informática"
  - Máquinas agrícolas → "Máquinas agrícolas"
  - Mobiliário escolar → "Mobiliário escolar"

### 3. Serviços

- **Objetivo:** detalhar o tipo de serviço prestado.
- **Exemplos:**
  - Manutenção predial → "Manutenção predial"
  - Consultoria técnica → "Consultoria técnica"
  - Capacitação de servidores → "Capacitação pessoal"
  - Estudos técnicos → "Estudos técnicos"

### 4. Material de consumo

- **Objetivo:** detalhar o tipo de insumo/consumo.
- **Exemplos:**
  - Medicamentos básicos → "Medicamentos básicos"
  - Material de limpeza → "Material limpeza"
  - Combustíveis → "Combustíveis"
  - Uniformes → "Uniformes"

### 5. Não identificado

- **Objetivo:** manter denominação genérica quando não há clareza.
- **Exemplos:**
  - Apoio institucional → "Apoio genérico"
  - Desenvolvimento social → "Atividade genérica"
  - Outras despesas → "Despesa indefinida"

## Regras de detalhamento

### Priorização de fontes

1. **`objeto_executor`** → principal fonte de informação.
2. **`desc_meta`** → complemento ou especificação.
3. **`classificacao_orcamentaria_pt`** → elemento de apoio (custeio/capital).

### Padronização terminológica

- **Saúde:** "unidades saúde", "equipamentos médicos", "medicamentos".
- **Educação:** "unidades educacionais", "mobiliário escolar", "equipamentos pedagógicos".
- **Infraestrutura:** "pavimentação viária", "instalação elétrica", "saneamento".
- **Segurança:** "veículos emergência", "equipamentos segurança".
- **Tecnologia:** "equipamentos informática", "sistemas TI".
- **Rural:** "máquinas agrícolas", "infraestrutura rural".

### Regras práticas

- Máx. 3-4 palavras.
- Usar substantivos e termos técnicos.
- Sem artigos/preposições desnecessárias.
- Padronizar nomenclaturas similares (ex.: "Medicamentos básicos", não variações como "Medicamentos simples").
- Em casos de múltiplos objetos, escolher o principal ou de maior valor.

## Exemplos de transformação

| categoria                     | objeto_executor                    | desc_meta                       | categoria_detalhe          |
|-------------------------------|------------------------------------|---------------------------------|----------------------------|
| Obra/instalação               | Construção de Centro de Saúde      | Construir 1 UBS                 | "Construção unidades saúde"|
| Equipamentos/material permanente | Aquisição de equipamentos hospitalares | Comprar 5 respiradores          | "Equipamentos médicos"     |
| Serviços                      | Contratação de serviços de engenharia | Elaborar projeto executivo      | "Serviços engenharia"      |
| Material de consumo           | Distribuição de medicamentos       | Fornecer medicamentos básicos   | "Medicamentos básicos"     |
| Não identificado              | Apoio ao desenvolvimento           | Ações de fortalecimento         | "Apoio genérico"           |

## Conformidade normativa

O detalhamento deve estar alinhado com:

- **IN TCU 93/2024**: exige registro no Transferegov de objeto, metas, classificação da despesa e prazo de execução.
- **Portaria Conjunta MF/MGI nº 15/2025**: requer vinculação correta entre finalidade e objeto, metas mensuráveis e compatibilidade com a área de competência do executor.

## Saída esperada

O arquivo final deve conter:

- Todas as colunas originais.
- A coluna `categoria` (da primeira etapa).
- A nova coluna `categoria_detalhe`.

## Validação final

Antes de concluir:

- [ ] Todas as linhas têm `categoria_detalhe`.
- [ ] Termos concisos (máx. 3-4 palavras).
- [ ] Padronização terminológica consistente.
- [ ] Coerência entre `categoria` e `categoria_detalhe`.
- [ ] Casos indefinidos mantêm especificações genéricas adequadas.
