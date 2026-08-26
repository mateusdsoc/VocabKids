# Pesquisa de Ferramentas e Custos

> Documento de referência técnica com a pesquisa de modelos de IA, serviços de OCR e ferramentas NLP avaliados para o VocabBR Kids.
>
> Data da pesquisa: 19 de maio de 2026.
>
> Este documento não contém decisões de produto. As decisões estão em `rascunho_product.md`.

---

## 01 - Modelos de IA para análise de redação

### Preços por modelo

| Modelo | Input (por 1M tokens) | Output (por 1M tokens) | Observação |
|---|---|---|---|
| Gemini 2.5 Flash-Lite | $0.10 | $0.40 | Mais barato do mercado |
| GPT-4o mini | $0.15 | $0.60 | Segundo mais barato, amplamente testado |
| Gemini 2.5 Flash | $0.30 | $2.50 | Melhor qualidade que o Lite, mais caro |
| Claude Haiku 4.5 | $1.00 | $5.00 | Qualidade alta, ~10x mais caro que GPT-4o mini |

Todos os modelos oferecem batch processing com 50% de desconto para cargas não urgentes.

### Simulação de custo

Premissas: redação de ~300 palavras, ~500 tokens de input (redação + prompt), ~1.000 tokens de output (análise completa).

#### Cenário: 200 redações por dia (escola média)

| Modelo | Custo/dia | Custo/mês (22 dias) |
|---|---|---|
| Gemini 2.5 Flash-Lite | ~$0.09 | ~$2.00 |
| GPT-4o mini | ~$0.14 | ~$3.00 |
| Gemini 2.5 Flash | ~$0.53 | ~$11.70 |
| Claude Haiku 4.5 | ~$1.10 | ~$24.20 |

#### Cenário: 2.000 redações por dia (10 escolas)

| Modelo | Custo/mês |
|---|---|
| Gemini 2.5 Flash-Lite | ~$20 |
| GPT-4o mini | ~$30 |
| Gemini 2.5 Flash | ~$117 |
| Claude Haiku 4.5 | ~$242 |

### Conclusão

Os custos de IA para análise de redação são muito baixos em todos os cenários. A diferença de preço entre os modelos baratos é irrelevante na prática. A decisão deve ser orientada pela qualidade da análise em português, não pelo preço.

Recomendação: testar os 3 modelos mais baratos com redações reais de alunos e avaliar qual:
- acerta melhor erros de acentuação e vírgula;
- dá sugestões de sinônimos mais adequadas para a faixa etária;
- analisa coesão/estrutura de forma útil;
- lida melhor com texto informal e cheio de erros.

---

## 02 - Serviços de OCR para redações manuscritas

### Preços por serviço

| Serviço | Custo | Observação |
|---|---|---|
| Google Cloud Vision | $1.50 por 1.000 páginas | Primeiras 1.000/mês grátis. Suporte a PT-BR. |
| Azure AI Vision | ~$1–2 por 1.000 páginas | Boa acurácia para manuscrito em português. |
| Google Document AI | $30 por 1.000 páginas | Para parsing de formulários (provavelmente desnecessário). |

### Simulação de custo

Cenário: 100 redações manuscritas por dia (nem todas as redações serão manuscritas).

- 100 × 22 dias = 2.200 páginas/mês
- Google Cloud Vision: primeiras 1.000 grátis, 1.200 × $0.0015 = **$1.80/mês**

Custo extremamente baixo.

### Riscos do OCR

- Acurácia com caligrafia infantil: pode ter taxa de erro maior que com adultos.
- Palavras mal lidas: devem ser validadas contra dicionário (Hunspell) antes de ações.
- Qualidade da foto: iluminação ruim, ângulo torto ou papel amassado afetam resultado.

---

## 03 - Ferramentas NLP (pré-processamento)

### Ferramentas avaliadas

| Ferramenta | Custo | O que faz | PT-BR |
|---|---|---|---|
| Hunspell | Grátis (open source, LGPL) | Verificação ortográfica, validação de palavras | Sim |
| LanguageTool | Grátis self-hosted / $4–20/mês API | Gramática, pontuação, acentuação, concordância | Sim |
| spaCy (pt_core_news) | Grátis (open source) | Tokenização, classificação gramatical, análise sintática | Sim |
| Nuspell | Grátis (open source) | Alternativa moderna ao Hunspell, mesma funcionalidade | Sim |

### Hunspell (recomendado para MVP)

- Usado pelo Chrome, Firefox, macOS e LibreOffice.
- Dicionário PT-BR completo disponível.
- Bindings para Python, Java, .NET, Ruby e outras linguagens.
- Funcionalidade principal para o VocabBR Kids: validar se uma palavra existe antes de gerar questões de vocabulário.
- Custo: zero.

### LanguageTool (opcional, para escala)

- Ferramenta open source de correção gramatical.
- Tem regras específicas para português brasileiro, incluindo pontuação e concordância.
- Pode ser self-hosted (servidor Java) com custo zero além da infraestrutura.
- API cloud: 20 requisições/min no free, 80 req/min no premium.
- Uso potencial: camada de pré-processamento antes da IA para reduzir custo em volume alto.
- Recomendação: não é necessário no MVP. Avaliar se o volume justificar.

### spaCy

- Modelo de NLP para português com tokenização, POS tagging e análise de dependência.
- Útil para análises mais estruturadas no futuro.
- Não é necessário no MVP.

---

## 04 - Estimativa de custo total por escola (MVP)

| Componente | Custo mensal estimado |
|---|---|
| IA para análise de redação (modelo barato) | ~$2–3 |
| OCR para manuscritas (Google Vision) | ~$2–5 |
| Hunspell (validação ortográfica) | Grátis |
| **Total por escola** | **~$4–8/mês** |

Esses números escalam linearmente com volume. Mesmo com 50 escolas, o custo total de IA e OCR ficaria abaixo de $400/mês.

---

## 05 - Próximos passos de investigação

- [ ] Testar GPT-4o mini, Gemini 2.5 Flash-Lite e Gemini 2.5 Flash com redações reais de alunos do Fundamental II.
- [ ] Avaliar qualidade do OCR do Google Cloud Vision com caligrafia de crianças/adolescentes.
- [ ] Testar integração do Hunspell com a linguagem escolhida para o backend.
- [ ] Definir o prompt de análise de redação (quais dimensões, formato de saída, nível de detalhe).
