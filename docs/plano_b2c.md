# Plano de migração B2C — VocabBR Kids

> **Status:** em execução — Fases 1–3 (identidade familiar, recalibração por
> faixa etária, assinatura Apple IAP) feitas e verificadas (147 testes de
> backend, 42 do app, fluxo completo testado ao vivo no simulador iOS).
> Detalhe em `design/notas-implementacao.md` § "Pivô B2C" (24/08/2026).
> Fases 4–6 (redação real, Área do Responsável, congelamento formal do
> professor) não começaram.
> **Criado em:** 24 de agosto de 2026.
> **Escopo:** transformar o produto de "software de vocabulário para escolas"
> (B2B, venda por escola, professor no centro) em "assinatura familiar mobile"
> (B2C, R$ 30/mês, pai compra, criança de 7–12 usa, IA no lugar do professor).
>
> Este documento é o **passo a passo**: o que muda no código (arquivo a
> arquivo), quais regras de negócio nascem, quais ferramentas entram, qual
> conteúdo falta criar e qual documentação (inclusive legal) precisa ser
> escrita ou adaptada.
>
> ⚠️ Pela **regra das decisões revisadas** (`CLAUDE.md`), nada aqui vale até os
> documentos contratuais serem editados junto. A lista de edições obrigatórias
> está na seção 12.

## Escopo do MVP (decidido 24/08, dono)

O MVP **não** mira a trilha completa (3 países / 20 destinos / 80 nós). Dois
cortes deliberados para lançar mais rápido:

1. **Trilha: só os 4 destinos com arte já pronta.** Verificado em
   `docs/referencia_arte.md`: de 20 cartões-postais planejados, **4 estão
   gerados** — Rio de Janeiro, Foz do Iguaçu e Amazônia (Brasil) + Paris
   (França). Fernando de Noronha, Lençóis Maranhenses e os outros 6 destinos
   franceses **não** têm arte e ficam fora do MVP. Japão inteiro fica fora.
   **Trilha do MVP: 2 países (Brasil parcial + França parcial), 4 destinos,
   16 nós** (4 nós/destino, como já é o padrão). Nenhuma peça de arte nova
   precisa ser gerada para lançar.
2. **Vocabulário: 100 palavras**, não as 600–900 da seção 10 original. Runway
   suficiente para validar o produto sem o esforço de curadoria de médio prazo.

Isso substitui os números de "Conteúdo a criar" (seção 10) e o risco R1
(seção 14) da versão anterior deste documento. Ampliar para os 3 países e o
banco de 600+ palavras é trabalho de **pós-MVP**, não bloqueia o lançamento.

---

## 00 - Sumário executivo

### O que sobrevive intacto (≈70% do backend)

O núcleo single-player já é B2C por natureza e **não muda**:

| Domínio | Situação |
|---|---|
| `vocabulario` | Intacto. Banco de palavras é global, não tem escola. |
| `sessao` | Intacto. Fila, intercalação de erro, guardas de integridade. |
| `progressao/xp.py` | Intacto. XP e combo são por aluno. |
| `adaptacao` | Intacto. Regra pura de nível. |
| `trilha` | Código intacto. **Seed do MVP muda**: 2 países / 4 destinos / 16 nós (ver "Escopo do MVP"), não os 3 países / 20 destinos / 80 nós do catálogo original. |
| `diagnostico` | **Quase** — só a semente de nível inicial depende de `ano_escolar`. |
| App Flutter: Sessão, Resumo, Trilha, Passaporte, Home | Intacto. |

### O que morre

- `backend/app/professor/` (778 linhas) e `app/lib/features/professor/` (136 KB).
- Entrada por `codigo_turma` — o conceito de turma some do caminho crítico.
- Meta semanal definida por professor.
- Redação atribuída por professor.

### O que nasce

1. **Identidade familiar** — conta do responsável → perfis de criança.
2. **Faixa etária** como eixo de calibração (substitui `ano_escolar`).
3. **Assinatura via Apple IAP** + gate de entitlement no backend.
4. **Programa de afiliados** (influenciador, % sobre venda, sem taxa base).
5. **Pipeline de redação real** — tema atribuído pela plataforma, correção por
   LLM, rubrica por faixa etária. Hoje é 100% mock.
6. **Área do Responsável** dentro do mesmo app, atrás de portão parental.
7. **Camada legal** — LGPD art. 14 (consentimento parental), termos, política
   de privacidade, exclusão de conta.

### O gargalo real não é código, é conteúdo

Cálculo direto a partir do repo:

- Trilha completa = 80 nós × 4.500 XP = **360.000 XP** ([seed_trilha.py](backend/app/seed_trilha.py)).
- XP médio por questão ≈ 120 ([progressao/xp.py](backend/app/progressao/xp.py)).
- Logo, a trilha inteira exige ≈ **3.000 questões respondidas**.
- Banco atual: **37 palavras × 8 questões = 296 questões** → cobre ~8 dos 80 nós.

**Uma criança pagante esgota o conteúdo em ~3 semanas e cancela.** Este é o
risco nº 1 do pivô, maior que qualquer item técnico. Ver seção 10.

---

## 01 - Decisões de produto que precisam ser travadas ANTES do código

Não comece a Fase 1 sem estas respostas. Cada uma muda schema ou fluxo.

| # | Decisão | Opções | Recomendação |
|---|---|---|---|
| D1 | Faixas etárias | 2 faixas (7–9 / 10–12) ou 3 (7–8 / 9–10 / 11–12) | **3 faixas.** 7 e 12 é abismo; 2 faixas deixa o meio mal servido. |
| D2 | Login do responsável | E-mail+senha / Sign in with Apple / ambos | **Ambos.** Apple exige Sign in with Apple se houver outro login social; e-mail+senha é o fallback. |
| D3 | Criança faz login? | Sim / não (troca de perfil dentro da conta) | **Não.** Perfil selecionado na abertura, sem senha. Menos atrito, menos dado de menor coletado. |
| D4 | Múltiplas crianças | 1 / até 3 / ilimitado | **Até 3 no mesmo preço.** Aumenta LTV percebido e é diferencial contra concorrente. |
| D5 | Free tier | Nada / diagnóstico / 1º destino completo | **Onboarding + diagnóstico + 1º destino (4 nós) grátis.** Mostra valor antes do paywall. |
| D6 | Trial | Sem / 7 dias / 14 dias | **7 dias** (introductory offer da Apple). |
| D7 | Preço | R$ 30/mês avulso ou +anual | **R$ 29,90/mês + R$ 249/ano.** O anual é o que salva o LTV frente ao churn. |
| D8 | Frequência de redação | Semanal / quinzenal / sob demanda | **Quinzenal automática + "pedir tema agora"** (limitado, para não estourar custo de LLM). |
| D9 | Categoria na App Store | Kids Category / Educação 4+ | **Educação, 4+**, com portão parental. Ver seção 8 — Kids Category proíbe SDK de terceiros e complica afiliados. Precisa de validação jurídica. |
| D10 | Escrita manuscrita | Só digitada / foto+OCR / ambas | **Ambas.** Criança de 7–8 não digita redação. OCR **no dispositivo** (seção 9). |
| D11 | Manter B2B vivo? | Deletar / congelar | **Congelar.** Ver Fase 6. |

---

## 02 - Modelo de negócio: Apple IAP + afiliados sem taxa base

### 2.1 Por que não tem Stripe

Regra 3.1.1 da App Store: conteúdo digital consumido no app **tem de** passar
por In-App Purchase. Assinatura vendida por fora e destravada no app é rejeição
certa. Então: IAP é o único caminho, e isso tem consequências que precisam
entrar no plano desde já.

- **Comissão Apple:** 30%, ou **15%** no *Small Business Program* (receita
  < US$ 1 M/ano — vocês se qualificam). Líquido em R$ 29,90 ≈ **R$ 25,4**.
  ⚠️ Confirmar tratamento tributário BR — a Apple é *merchant of record*.
- **Você não controla o checkout.** Sem cupom próprio, sem link de pagamento,
  sem trial customizado fora do que a Apple oferece.
- **Reembolso é decisão da Apple**, e chega por webhook (`REFUND`).
- **Renovação/cancelamento** só se sabe por *App Store Server Notifications V2*.

### 2.2 Programa de afiliados (o ponto delicado)

Você quer influenciador remunerado só por % de venda. Com IAP, a Apple **não
oferece rastreamento de afiliado**. As opções reais:

| Mecanismo | Como funciona | Veredito |
|---|---|---|
| **Offer Code da Apple** | Código único por influenciador que dá desconto | Rastreia resgate, mas **desconta do seu preço** e é limitado |
| **App Analytics campaign link** | Link de campanha por influenciador | Só agregado, não liga à assinatura individual |
| **Código digitado no app** | Campo "tem um código?" no onboarding → gravado na conta → comissão quando a assinatura confirma | ✅ **Recomendado** |

**Regra de negócio do afiliado (a implementar):**

```
1. Influenciador recebe um código legível (ex.: MARIA10).
2. Campo opcional "código de indicação" no cadastro do responsável.
   → grava atribuicao_afiliado(conta_id, afiliado_id) — imutável, 1x por conta.
3. Janela de atribuição: 30 dias entre cadastro e 1ª compra. Fora disso, não conta.
4. Comissão = pct_comissao × valor LÍQUIDO recebido da Apple (nunca sobre o bruto).
5. Recorrência: pagar sobre os primeiros 12 meses da assinatura (padrão de mercado);
   depois zera. Trava o custo de aquisição.
6. Estorno: reembolso pela Apple → comissão da competência é revertida.
7. Fechamento mensal → relatório → pagamento manual por PIX.
```

Para o influenciador ter incentivo real sem taxa base, a comissão precisa ser
alta: **30–40% dos 12 primeiros meses**. Em R$ 25,4 líquidos, 35% = R$ 8,9/mês
× 12 = **R$ 107 por assinante convertido**. É competitivo com CAC pago e você
só paga sobre resultado — mas note que sobra **R$ 16,5/mês** no primeiro ano
para cobrir infra, LLM e conteúdo. Faça a conta antes de fechar o percentual.

---

## 03 - Arquitetura alvo

```
                     ┌───────────────────────────────────────┐
   App Flutter       │  1 app, 2 modos:                      │
   (iOS primeiro)    │  • Modo Criança (perfil, sem senha)   │
                     │  • Área do Responsável (portão PIN)   │
                     └──────────────┬────────────────────────┘
                                    │ HTTPS /v1
                     ┌──────────────▼────────────────────────┐
                     │  FastAPI                              │
                     │  identidade · vocabulario · sessao    │
                     │  diagnostico · trilha · redacao(REAL) │
                     │  assinatura(NOVO) · responsavel(NOVO) │
                     │  afiliado(NOVO)                       │
                     └───┬───────────────┬─────────────┬─────┘
                         │               │             │
              ┌──────────▼──┐   ┌────────▼──────┐  ┌───▼────────┐
              │ PostgreSQL  │   │ procrastinate │  │ App Store  │
              │   (Neon)    │   │   (worker)    │  │ Server API │
              └─────────────┘   └───────┬───────┘  │ + Notif V2 │
                                        │          └────────────┘
                                   Claude API
                              (análise + geração)

   OCR: NO DISPOSITIVO (ML Kit) — a foto nunca sai do aparelho.
```

**Mudança arquitetural relevante frente a `docs/arquitetura.md`:** o Bloco 2b
previa OCR no Google Cloud Vision com a foto no R2. Para B2C isso é ruim em
dois eixos — custo e LGPD (imagem de caderno de criança em bucket). Proposta:
OCR **on-device**, sobe só o `texto_extraido`, e a foto é descartada.
**Isso elimina o R2 do caminho crítico.** Ver seção 9.

---

## 04 - FASE 1 — Identidade familiar (o desbloqueio de tudo)

**Duração estimada:** 5–8 dias. **Sem isso, nada mais anda.**

### 4.1 Modelo de dados — migration `b2c_01_identidade`

Tabelas **novas**:

```python
# app/schema.py

conta = Table(  # a família — unidade de cobrança
    "conta", metadata, _id(),
    Column("responsavel_usuario_id", BigInteger,
           ForeignKey("usuario.id", ondelete="CASCADE"), nullable=False, unique=True),
    Column("consentimento_lgpd_em", DateTime(timezone=True), nullable=True),
    Column("consentimento_versao", Text, nullable=True),   # versão do termo aceito
    Column("pin_hash", Text, nullable=True),               # portão parental
    _created_at(),
)

perfil_crianca = Table(  # dados da criança — mínimo necessário (LGPD)
    "perfil_crianca", metadata,
    Column("usuario_id", BigInteger, ForeignKey("usuario.id", ondelete="CASCADE"),
           primary_key=True),
    Column("conta_id", BigInteger, ForeignKey("conta.id", ondelete="CASCADE"),
           nullable=False),
    Column("apelido", Text, nullable=False),        # NÃO nome completo
    Column("ano_nascimento", Integer, nullable=False),  # ano, não data — menos dado
    Column("faixa_etaria", Text, nullable=False),
    Column("ano_escolar", Integer, nullable=True),  # opcional, informado pelo pai
    Column("avatar_ref", Text, nullable=True),
    _created_at(),
    CheckConstraint("faixa_etaria IN ('7-8','9-10','11-12')", name="faixa_valida"),
    CheckConstraint("ano_escolar IS NULL OR ano_escolar BETWEEN 1 AND 9",
                    name="ano_escolar_range_b2c"),
)
```

Tabelas **alteradas**:

```python
# associacao: 'responsavel' entra como papel; escola_id continua nullable
CheckConstraint("papel IN ('aluno','responsavel','professor','coordenador','admin')")

# usuario: credenciais do responsável (aluno continua sem)
Column("senha_hash", Text, nullable=True)   # argon2, só responsável
# auth_provider/auth_subject já existem → servem para Sign in with Apple

# turma: ⚠️ NÃO alterar o CHECK 6..9. A turma sai do caminho B2C inteira;
#        mexer nela só cria migration inútil. Ver Fase 6.
```

### 4.2 Backend — arquivo a arquivo

| Arquivo | Ação |
|---|---|
| [identidade/schemas.py](backend/app/identidade/schemas.py) | ➖ `AcessoTurmaIn/Out`, `TurmaOut`, `EscolaOut`. ➕ `CadastroIn`, `LoginIn`, `AppleLoginIn`, `PerfilCriancaIn/Out`, `ContaOut`, `SelecionarPerfilIn`. `MeOut`: trocar `escola`/`turma` por `perfil` + `assinatura`. |
| [identidade/repository.py](backend/app/identidade/repository.py) | ➖ `buscar_turma_por_codigo`, `buscar_aluno_na_turma`, `meta_config_da_turma`. ➖ `criar_aluno(escola_id, turma_id, …)`. ➕ `criar_conta`, `buscar_conta_por_email`, `criar_perfil_crianca`, `listar_perfis_da_conta`, `buscar_perfil_crianca`. ✏️ `buscar_perfil` — joins de escola/turma saem, entra `perfil_crianca`. |
| [identidade/service.py](backend/app/identidade/service.py) | ➖ `acessar_por_codigo_turma`. ➕ `cadastrar_responsavel`, `login`, `login_apple`, `criar_crianca`, `entrar_como_crianca`. ✏️ `perfil` — `meta_semanal` passa a vir da faixa. |
| [identidade/auth.py](backend/app/identidade/auth.py) | ✏️ `criar_token` ganha `conta_id` e `perfil_id`. ➕ `TokenCrianca` × `TokenResponsavel` (dois escopos). ➕ `require_responsavel`. ➖ `require_papel('professor',…)` fica órfã → some com a Fase 6. |
| [identidade/routes.py](backend/app/identidade/routes.py) | ➖ `POST /acesso/turma`. ➕ `POST /conta`, `POST /sessao` (login), `POST /sessao/apple`, `GET /conta/perfis`, `POST /conta/perfis`, `POST /perfis/{id}/entrar`, `DELETE /conta` (exigido pela Apple). |
| [progressao/meta.py](backend/app/progressao/meta.py) | ✏️ `META_DEFAULT_POR_ANO` → `META_DEFAULT_POR_FAIXA = {'7-8': 3, '9-10': 4, '11-12': 5}`. Assinatura vira `meta_efetiva(faixa)`. |
| [diagnostico/escada.py](backend/app/diagnostico/escada.py) | ✏️ `nivel_inicial(ano_escolar)` (hoje `ano - 4`, que dá **≤ 0** para 2º–4º ano) → `nivel_inicial(faixa)` com `{'7-8': 1, '9-10': 2, '11-12': 4}`. Reduzir `MAX_PERGUNTAS` de 15 → **10** para 7–8 anos (aguentam menos). |
| [diagnostico/service.py](backend/app/diagnostico/service.py), [repository.py](backend/app/diagnostico/repository.py) | ✏️ Trocar leitura de `turma.ano_escolar` por `perfil_crianca.faixa_etaria`. |
| [seed.py](backend/app/seed.py), [seed_demo.py](backend/app/seed_demo.py) | 🔁 Reescrever: família demo (1 responsável + 2 crianças em faixas diferentes) no lugar de turma/professora. |
| [config.py](backend/app/config.py) | ✏️ `rl_login_por_minuto` cai de 20 → 5 (não há mais turma inteira atrás de um NAT; agora é login com senha e precisa de freio anti-brute-force). |

### 4.3 App Flutter — arquivo a arquivo

| Arquivo | Ação |
|---|---|
| [features/identidade/models.dart](app/lib/features/identidade/models.dart) | ➖ `Turma`, `Escola`, `AcessoTurma`. ➕ `Conta`, `PerfilCrianca`, `Assinatura`. ✏️ `Me`. |
| [features/identidade/repository.dart](app/lib/features/identidade/repository.dart) | ➖ `acessarPorTurma`. ➕ `cadastrar`, `login`, `loginApple`, `criarCrianca`, `entrarComoCrianca`, `excluirConta`. |
| [features/identidade/auth_controller.dart](app/lib/features/identidade/auth_controller.dart) | ✏️ `entrar({codigoTurma, nome})` → `entrar({email, senha})`. ➕ estado de perfil ativo. ✏️ `OnboardingPendente` passa a ser **por perfil de criança**, não por sessão de app. |
| [features/identidade/entrada_screen.dart](app/lib/features/identidade/entrada_screen.dart) | 🔁 Reescrever. A metáfora do passe de embarque **se mantém**, mas o formulário vira e-mail/senha + Sign in with Apple. Os widgets (`passport_field`, `perforation`, `brand_mark`) são reaproveitados. |
| **NOVO** `features/identidade/cadastro_screen.dart` | Cadastro do responsável + aceite de termos + campo de código de indicação. |
| **NOVO** `features/identidade/perfis_screen.dart` | Seletor "quem vai estudar hoje?" — cartões de perfil. |
| **NOVO** `features/identidade/criar_crianca_screen.dart` | Apelido + ano de nascimento → faixa calculada. |
| [main.dart](app/lib/main.dart) | ✏️ `_Gate`: `deslogado → Entrada`, `logado sem perfil → CriarCrianca`, `logado com perfis → Seletor`, `perfil ativo + onboarding → Onboarding`, `perfil ativo → Home`. |
| [features/home/home_mapper.dart](app/lib/features/home/home_mapper.dart) | ✏️ Fallback de meta some (meta agora sempre existe, vem da faixa). |
| [features/home/widgets/quick_actions.dart](app/lib/features/home/widgets/quick_actions.dart) | ✏️ "ranking da turma" → remover ou virar "sua evolução". |
| [features/identidade/perfil_screen.dart](app/lib/features/identidade/perfil_screen.dart), [widgets/identity_card.dart](app/lib/features/identidade/widgets/identity_card.dart) | ✏️ Campos de turma/escola no cartão-passaporte → faixa/apelido. |
| [features/configuracoes/configuracoes_screen.dart](app/lib/features/configuracoes/configuracoes_screen.dart) | ✏️ Remove referências a turma. ➕ "Área do Responsável", "Gerenciar assinatura", "Excluir conta". |
| [core/config.dart](app/lib/core/config.dart) | ➕ `AppConfig.revenueCatKey`. |

### 4.4 Regras de negócio novas

```
R-ID-1  Um responsável = uma conta = até 3 perfis de criança (D4).
R-ID-2  Criança nunca tem credencial. Token de criança é derivado do token do
        responsável e só dá acesso às rotas de gameplay.
R-ID-3  Token de responsável NÃO acessa rota de gameplay, e vice-versa.
R-ID-4  faixa_etaria é DERIVADA de ano_nascimento na criação e RECALCULADA no
        aniversário (job diário). A criança "sobe de faixa" sem perder progresso.
R-ID-5  Subir de faixa NÃO reseta nível nem XP — só muda meta semanal e rubrica
        de redação. (Coerente com "sem regressão de nível", produto §3.4.)
R-ID-6  Exclusão de conta: hard delete em ≤ 30 dias, com confirmação por e-mail.
        Exigido pela Apple (5.1.1(v)) e pela LGPD.
R-ID-7  Coletar o MÍNIMO da criança: apelido + ano de nascimento. Nunca nome
        completo, foto, escola, localização.
```

---

## 05 - FASE 2 — Recalibração para 7–12 anos

**Duração:** 2–3 dias de código. O conteúdo é a seção 10 e leva muito mais.

O produto inteiro foi calibrado para Fundamental II (11–14 anos). A escada do
diagnóstico literalmente quebra: `nivel_inicial = ano_escolar - 4` dá 1 para o
5º ano e **negativo** para o 2º.

### 5.1 Mapa de faixa → parâmetros

| Faixa | Ano escolar típico | Nível inicial | Meta semanal | Nível máx. de palavra | Questões no diagnóstico |
|---|---|---|---|---|---|
| 7–8 | 2º–3º | 1 | 3 palavras | 4 | 10 |
| 9–10 | 4º–5º | 2 | 4 palavras | 7 | 12 |
| 11–12 | 6º–7º | 4 | 5 palavras | 10 | 15 |

➕ Criar `backend/app/progressao/faixa.py` — **módulo puro**, seguindo o padrão
de `xp.py` e `regras.py`: `faixa_de(ano_nascimento)`, `parametros(faixa)`.
Testável sem banco.

### 5.2 Filtro de conteúdo por faixa

Regra nova em `sessao/service.py` e `diagnostico/service.py`:

```
R-FX-1  A seleção de palavras nunca oferece palavra com
        nivel_dificuldade > nivel_maximo(faixa), mesmo que a adaptação
        tenha subido o aluno. A adaptação sobe DENTRO da faixa.
R-FX-2  Se o aluno de uma faixa esgotar as palavras disponíveis, ele passa a
        revisar em vez de travar. (Já existe `selecionar_revisao`, mas o gatilho
        de "acabou o conteúdo" precisa ser explícito.)
```

⚠️ R-FX-1 é o que impede uma criança de 7 anos receber "efêmero". Sem isso, o
produto fica pedagogicamente errado no dia 1.

---

## 06 - FASE 3 — Assinatura (Apple IAP)

**Duração:** 5–7 dias. **Comece o cadastro na Apple na semana 1** — D-U-N-S,
contrato de Paid Apps e dados bancários levam mais tempo que a review em si.

### 6.1 Schema — migration `b2c_02_assinatura`

```python
assinatura = Table(
    "assinatura", metadata, _id(),
    Column("conta_id", BigInteger, ForeignKey("conta.id", ondelete="CASCADE"),
           nullable=False),
    Column("loja", Text, nullable=False),                 # 'apple' | 'google'
    Column("produto_id", Text, nullable=False),
    Column("transacao_original_id", Text, nullable=False, unique=True),
    Column("status", Text, nullable=False),
    Column("expira_em", DateTime(timezone=True), nullable=True),
    Column("em_trial", Boolean, nullable=False, server_default="false"),
    Column("ambiente", Text, nullable=False),             # 'sandbox' | 'production'
    Column("atualizada_em", DateTime(timezone=True), nullable=False,
           server_default=func.now()),
    _created_at(),
    CheckConstraint(
        "status IN ('ativa','em_periodo_de_graca','expirada','cancelada','reembolsada')",
        name="status_assinatura_valido"),
)

evento_loja = Table(  # log cru do webhook — idempotência e auditoria
    "evento_loja", metadata, _id(),
    Column("loja", Text, nullable=False),
    Column("tipo", Text, nullable=False),
    Column("payload", JSONB, nullable=False),
    Column("assinatura_dedup", Text, nullable=False, unique=True),
    Column("processado_em", DateTime(timezone=True), nullable=True),
    _created_at(),
)
```

### 6.2 Backend novo: `backend/app/assinatura/`

Seguindo o padrão rotas → serviço → repositório:

```
routes.py       POST /v1/assinatura/webhook   (sem auth, valida assinatura JWS)
                GET  /v1/assinatura           (status da conta)
                POST /v1/assinatura/restaurar
service.py      aplicar_evento(), status_da_conta(), esta_ativa()
repository.py   upsert por transacao_original_id
entitlement.py  ⭐ dependency require_assinatura — regra PURA de acesso
```

### 6.3 Regras de negócio

```
R-AS-1  Fonte da verdade do entitlement é o BACKEND, nunca o app.
        Coerente com "cliente fino, servidor autoritativo" (CLAUDE.md).
R-AS-2  Free tier: onboarding + diagnóstico + 4 primeiros nós (destino 1).
        Passou disso sem assinatura → 402 `assinatura_necessaria`.
R-AS-3  Assinatura é da CONTA, não do perfil. Vale para as 3 crianças.
R-AS-4  Período de graça: falha de cobrança mantém acesso por 16 dias
        (billing retry da Apple) com aviso na Área do Responsável.
R-AS-5  Expirou → NÃO apaga progresso. Vira read-only: vê passaporte e
        histórico, não abre sessão nova. Reativar restaura tudo.
R-AS-6  Webhook é idempotente por `assinatura_dedup`. Evento repetido é no-op.
R-AS-7  Reembolso → status 'reembolsada' + reversão da comissão do afiliado.
```

⚠️ **R-AS-5 é decisão de produto, não técnica.** Apagar progresso ao cancelar
mata a chance de reativação — e reativação é a métrica que sustenta B2C.

### 6.4 Rotas que ganham o gate

`POST /v1/sessao`, `POST /v1/redacoes/*`, `GET /v1/trilha` (além do nó 4).
**Não** gatear: `/me`, `/conta/*`, `/assinatura/*`, passaporte (read-only).

### 6.5 App Flutter

- ➕ `features/assinatura/` — `paywall_screen.dart`, `assinatura_controller.dart`,
  `assinatura_repository.dart`.
- ✏️ [pubspec.yaml](app/pubspec.yaml) — ➕ `purchases_flutter` em **versão exata**
  (o arquivo proíbe `^`, e o comentário registra que `pub get` solto já quebrou
  o build). Commit deliberado, com `pubspec.lock`.
- ✏️ [core/api_client.dart](app/lib/core/api_client.dart) — tratar `402` →
  abre paywall em vez de erro genérico.

---

## 07 - FASE 4 — Redação real (o coração do B2C)

**Duração:** 12–18 dias. **É o que justifica R$ 30 contra um app grátis.**

Hoje [redacao/routes.py](backend/app/redacao/routes.py) devolve 3 registros
fixos. Não existe nenhuma dependência de IA no `pyproject.toml`.

### 7.1 Quem atribui o tema (a sua pergunta central)

**Não construa um painel de "configurar métricas".** O pai não sabe calibrar
redação, não quer o trabalho, e um painel de rigor mal usado gera avaliação
injusta da criança. A calibração é do produto:

```
R-RD-1  A plataforma atribui tema automaticamente a cada 15 dias, por perfil,
        de um catálogo curado por faixa etária.
R-RD-2  O tema sai do catálogo da FAIXA, sem repetir nos últimos 6 meses.
R-RD-3  A RUBRICA é fixa por faixa — definida por você, no código, versionada.
        Nem pai nem criança editam.
R-RD-4  O responsável pode "pedir um tema agora" (máx. 2 extras/mês/perfil —
        trava de custo de LLM).
R-RD-5  Nunca mostrar nota numérica de 0 a 10 para a criança. Devolver
        conquistas + 1 ponto de melhoria. Punição é decisão travada do produto.
R-RD-6  Para o RESPONSÁVEL, aí sim, métricas por dimensão em escala visual
        (ex.: 4 níveis nomeados), com evolução ao longo do tempo.
```

### 7.2 Rubrica por faixa (a criar — `backend/app/redacao/rubrica.py`)

Módulo **puro**, no padrão de `xp.py`. Esqueleto:

```python
DIMENSOES = ["vocabulario", "coesao", "ortografia", "estrutura", "adequacao_ao_tema"]

RUBRICA = {
  "7-8":   {"min_palavras": 40,  "max_palavras": 120,
            "peso": {"vocabulario": .3, "ortografia": .3, "adequacao_ao_tema": .3,
                     "estrutura": .1, "coesao": .0},
            "tolerancia_ortografica": "alta",
            "tom": "celebra o esforço; 1 melhoria por vez"},
  "9-10":  {"min_palavras": 80,  "max_palavras": 200, ...},
  "11-12": {"min_palavras": 120, "max_palavras": 300, ...},
}
```

⚠️ Coesão pesa **zero** aos 7–8 anos de propósito: cobrar conectivo de quem
está aprendendo a formar frase é errado pedagogicamente e desmotiva.

### 7.3 Pipeline

```
envio (app)
  └─ OCR NO DISPOSITIVO (manuscrita) ou texto digitado
      └─ POST /v1/redacoes/{id}/enviar  { texto_extraido, formato }
          └─ enfileira job (procrastinate)
              1. VALIDAR      tamanho vs rubrica; muito curto → devolve gentilmente
              2. ANALISAR     1 chamada Claude, rubrica da faixa no prompt
                              → redacao_analise.anotacoes (JSONB)
              3. EXTRAIR      palavras fracas/superutilizadas → redacao_palavra
              4. ATRIBUIR     buscar_ou_gerar_e_atribuir → entra na trilha
                              com palavra_gatilho (gancho do card, produto §3.2)
              5. NOTIFICAR    push "sua redação voltou!"
```

Os passos 3 e 4 **já estão especificados** em `docs/arquitetura.md` Bloco 2b —
reaproveite o desenho, ele não depende de professor.

### 7.4 Schema — migration `b2c_03_redacao`

```python
# redacao_atribuicao: ➖ turma_id, ➖ professor_associacao_id
#                     ➕ usuario_id (a criança), ➕ origem ('automatica'|'sob_demanda')
#                     ➕ tema_catalogo_id

tema_catalogo = Table(   # NOVO — o catálogo curado
    "tema_catalogo", metadata, _id(),
    Column("faixa_etaria", Text, nullable=False),
    Column("titulo", Text, nullable=False),
    Column("enunciado", Text, nullable=False),
    Column("apoio", JSONB, nullable=True),   # perguntas-guia para destravar
    Column("genero", Text, nullable=False),  # narrativa|descritiva|opinativa|carta
    _created_at(),
)

# ➖ sinal_turma, ➖ turma_config  → sem professor, não existem
```

### 7.5 Segurança de conteúdo (obrigatório, não opcional)

```
R-RD-7  Toda redação passa por triagem ANTES da análise. Sinal de risco
        (violência doméstica, autolesão, abuso) → NÃO devolve correção
        automática; marca para revisão humana e notifica o responsável com
        texto acolhedor pré-aprovado.
R-RD-8  Nenhum dado de criança vai para treinamento de modelo. Exigir e
        documentar o opt-out contratual do provedor de LLM.
R-RD-9  Texto de redação é retido por 24 meses e apagado junto com a conta.
```

R-RD-7 não é exagero: você vai receber texto de criança de 7 anos sobre a vida
dela. Um produto que responde a "meu pai me bate" com "sua ortografia melhorou"
é um incidente sério, e previsível.

---

## 08 - FASE 5 — Área do Responsável

**Duração:** 5–7 dias. Substitui o painel do professor — **mesma pergunta,
outra pessoa**, então boa parte das queries de `professor/repository.py` serve
de referência (escopo por conta em vez de por turma).

- ➕ `backend/app/responsavel/` (rotas/serviço/repositório).
- ➕ `app/lib/features/responsavel/` — dentro do app da criança, atrás de
  **portão parental** (PIN de 4 dígitos, `conta.pin_hash`).

**Conteúdo da tela** (é o que renova a assinatura, então trate como produto,
não como relatório):

1. Resumo da semana por criança: palavras dominadas / meta, minutos, sessões.
2. Evolução da redação por dimensão, ao longo do tempo.
3. "O que ele aprendeu esta semana" — 5 palavras com definição, para o pai
   conversar com o filho. **Este é o item de maior valor percebido.**
4. Gerenciar assinatura, perfis, exclusão de conta.

```
R-RS-1  Portão parental antes de QUALQUER dado ou link externo (Apple 5.1.4).
R-RS-2  Não mostrar taxa de acerto nem tempo/velocidade — decisão travada do
        produto vale também para o pai.
R-RS-3  Nada de comparação com outras crianças. Sem ranking, sem percentil.
```

---

## 09 - FASE 6 — Congelar o professor (por último, não por primeiro)

Graças a R1/R2 (`test/arquitetura_professor_test.dart`), o professor já é
removível com uma tesoura. Mas **não delete agora**:

- Ele já não entra no APK/IPA do aluno (tree-shaking garantido pelo guard).
- Custa zero se você parar de mexer.
- Preserva a opção B2B se uma escola aparecer.

**Passo real:**

1. Remover `professor_router` de [api/v1.py](backend/app/api/v1.py) — a
   superfície some da API pública sem apagar código.
2. Marcar `backend/app/professor/` e `app/lib/features/professor/` como
   congelados num cabeçalho de arquivo.
3. Manter `tests/` do professor rodando (guarda contra regressão do schema).
4. Deletar de verdade **só depois** de 3 meses de B2C validado — commit único,
   reversível por git.

⚠️ O que **precisa** sair agora: `sinal_turma`, `turma_config` e as rotas de
professor no pipeline de redação (Fase 4), porque bloqueiam o novo modelo.

---

## 10 - Conteúdo a criar

> Números revisados para o **MVP** (decisão 24/08 — ver "Escopo do MVP" no
> topo do documento). Os números originais (900 palavras, 3 países) viram
> meta de **pós-MVP**, mantidos aqui como referência de para onde crescer.

### 10.1 Vocabulário — de 37 para 100 palavras (MVP)

Estado: [seed_vocabulario.py](backend/app/seed_vocabulario.py) tem **37
palavras** distribuídas nos níveis 1–10 (3–4 por nível).

**Meta do MVP: 100 palavras**, distribuídas pelos níveis que a trilha de 16 nós
efetivamente usa. Verificação de runway: XP_POR_NO = 4.500 × 16 nós =
72.000 XP para atravessar a trilha inteira; 100 palavras × 8 questões = 800
questões, que a XP média por questão (~100–150 com combo) já cobre com folga
— e a fila de revisão (`selecionar_revisao`) continua dando XP depois que o
banco novo se esgota, então não há trava dura de progresso, só menos palavra
nova por sessão com o tempo. Suficiente para validar o produto.

**Meta pós-MVP** (quando ampliar para 3 países / trilha completa):

| Faixa | Níveis | Palavras mínimo | Palavras ideal |
|---|---|---|---|
| 7–8 | 1–4 | 200 | 300 |
| 9–10 | 2–7 | 250 | 350 |
| 11–12 | 4–10 | 250 | 350 |

Cada palavra = definição conversacional + exemplo + 2–3 sinônimos + **8
questões** (4 níveis × 2 variações). 100 palavras ≈ **800 questões** (MVP);
900 palavras ≈ 7.200 questões (pós-MVP).

**Como produzir** (não dá para escrever à mão, nem as 100 do MVP):

```
➕ backend/app/conteudo/gerador.py   (script offline, roda 1x, não em runtime)
   1. Lista de lemas por faixa (curada por humano — a partir de listas de
      frequência do português e de material didático por ano)
   2. Claude gera definição + exemplo + sinônimos + 8 questões por palavra
   3. QA automático (a "camada preventiva" de arquitetura.md §552):
      2ª chamada barata — "algum distrator também está correto nesta frase?"
   4. Export para o formato de seed_vocabulario.py
   5. ⭐ REVISÃO HUMANA por amostragem — mínimo 20%, 100% na faixa 7–8
```

⚠️ **Não pule o passo 5**, nem para as 100 do MVP. Questão de vocabulário com
distrator ambíguo ensina errado, e criança de 7 anos não sabe reclamar — o pai
cancela e não diz por quê.

**Esforço:** ~1 semana para as 100 do MVP com o pipeline (vs. ~3 semanas para
as 900 do pós-MVP), maior parte em curadoria humana.

### 10.2 Arte / recompensas — MVP não precisa gerar nada

Trilha do MVP usa só os 4 destinos já desenhados (Rio, Foz do Iguaçu,
Amazônia, Paris) — ver "Escopo do MVP". **Nenhuma peça nova de cartão-postal
é necessária para lançar.** Os 3 carimbos de país (Brasil/França/Japão) e os
5 selos de feito seguem como estavam — carimbo do Japão pode ficar "a gerar"
sem bloquear, já que o país não entra no MVP.

Pós-MVP, ao expandir para os 3 países completos: faltam **16 dos 20**
cartões-postais (Noronha, Lençóis Maranhenses + os 6 restantes da França +
os 8 do Japão).

Ponto ainda em aberto, independente do MVP: o estilo visual foi travado para
11–14 anos. Para 7–8 anos provavelmente precisa de mais cor e personagem.
**Decisão pendente:** manter uma arte só (mais barato, e a metáfora de viagem
funciona bem em toda a faixa) ou variar por faixa (caro, fragmenta a marca).
**Recomendo arte única** — decidir antes de gerar as próximas peças, para não
retrabalhar as 4 que já existem.

### 10.3 Cards de descoberta

Já cobertos pelo schema (`palavra.definicao` + `exemplo_uso`). **Decisão:**
uma definição por palavra, não uma por faixa — a dificuldade já é controlada
pela seleção (R-FX-1). Duplicar conteúdo por faixa triplica o custo de curadoria
sem ganho pedagógico proporcional.

⚠️ Exceção: as ~40 palavras de nível 1–2 precisam de revisão de linguagem
específica para 7 anos. Foram escritas pensando em 11+.

### 10.4 Temas de redação

| Faixa | Temas p/ 1 ano (quinzenal + extras) |
|---|---|
| 7–8 | 40 |
| 9–10 | 40 |
| 11–12 | 40 |

**120 temas**, cada um com título, enunciado e 3 perguntas-guia. ➕ criar
`backend/app/seed_temas.py` (idempotente, no padrão dos outros seeds).

### 10.5 Onboarding e paywall (copy)

Conteúdo novo que não existe: tela de venda, comparativo grátis × assinante,
e-mails transacionais (boas-vindas, redação corrigida, falha de cobrança,
cancelamento), textos de push. ~15 peças de copy.

---

## 11 - Documentação legal e de conformidade (bloqueia o lançamento)

### 11.1 LGPD — criança é dado especialmente protegido

**Art. 14 §1 da LGPD:** tratamento de dados de crianças exige **consentimento
específico e em destaque** dado por ao menos um dos pais ou responsável legal.
Não é o aceite genérico dos termos.

| Documento | Status | Nota |
|---|---|---|
| Política de Privacidade | **criar** | Seção dedicada a dados de menores. Público. |
| Termos de Uso | **criar** | Contratante é o responsável, não a criança. |
| Termo de Consentimento Parental | **criar** | Tela própria, aceite explícito, versionado em `conta.consentimento_versao`. |
| Registro de Operações (ROPA) | **criar** | Art. 37. Interno. |
| Lista de suboperadores | **criar** | Apple, Anthropic, Neon, provedor de push. Público. |
| Política de Retenção e Exclusão | **criar** | Redação 24 meses; conta apagada em ≤ 30 dias. |
| Encarregado (DPO) | **nomear** | Art. 41. Pode ser você. E-mail de contato público. |
| Plano de resposta a incidente | **criar** | Art. 48. |

```
R-LG-1  Consentimento é registrado com data + versão do termo. Termo novo →
        pedir de novo.
R-LG-2  Minimização (art. 6º III): apelido + ano de nascimento. Nada além.
R-LG-3  Redação vai para o LLM sem identificador da criança — só o texto e a
        faixa. Pseudonimização real, não cosmética.
R-LG-4  Nenhum SDK de terceiros coleta dado da criança. Telemetria é
        server-side, na tabela `evento` que JÁ EXISTE no schema.
R-LG-5  Exportação de dados a pedido do responsável (art. 18) — JSON por e-mail.
```

⚠️ **R-LG-4 é uma vantagem sua:** a tabela `evento` já está no schema, então
você não precisa de Firebase Analytics/Mixpanel — que seriam justamente o que
complica na App Store para público infantil.

### 11.2 App Store — o que a review vai cobrar

| Guideline | Exigência |
|---|---|
| 3.1.1 | Assinatura obrigatoriamente por IAP |
| 5.1.1(v) | Exclusão de conta **dentro do app** |
| 5.1.4 | App infantil: portão parental antes de link externo/compra; sem publicidade comportamental |
| 1.3 | Classificação etária correta |
| 4.8 | Sign in with Apple se houver login social |
| 5.1.1(i) | Política de privacidade acessível na loja e no app |
| — | Privacy Nutrition Labels no App Store Connect |

**Decisão D9 em aberto:** entrar na *Kids Category* traz selo de confiança para
o pai, mas proíbe SDK de terceiros e endurece a review. Listar em **Educação /
4+** com portão parental é o caminho mais comum no Brasil e não te impede de
cumprir as mesmas regras. **Precisa de validação jurídica antes de submeter** —
errar isso custa ciclos de rejeição.

### 11.3 Documentação do projeto a adaptar (regra do CLAUDE.md)

| Documento | O que muda |
|---|---|
| `docs/rascunho_product.md` | Seções 01, 02 (público: pai/criança 7–12), 07 (professor sai), 08 (custo: LLM por assinante), nova seção de monetização |
| `docs/arquitetura.md` | Bloco 1 (identidade familiar), Bloco 2b (OCR on-device, sem R2), Bloco 3 (domínios `assinatura`/`responsavel`/`afiliado`) |
| `design/telas.md` | §1 Entrada reescrita; §8.2 Professor removida; ➕ Seletor de perfil, Paywall, Área do Responsável |
| `design/brief-mockup-*.md` | Revisar os 4 briefs para a faixa 7–12; ➕ briefs de paywall e área do responsável |
| `design/notas-implementacao.md` | **Registrar a decisão do pivô com data — obrigatório** |
| `CLAUDE.md` | Comandos (entrypoint do professor sai), arquitetura, decisões travadas |
| `HANDOFF.md` | Estado da migração |

---

## 12 - Ferramentas

| Necessidade | Escolha | Por quê |
|---|---|---|
| IAP + entitlement | **RevenueCat** (`purchases_flutter`) | Resolve StoreKit, recibo, webhook, período de graça e restauração. Grátis até US$ 2,5k/mês. Fazer na mão custa ~2 semanas. |
| Hash de senha | **argon2-cffi** | Padrão atual. |
| Sign in with Apple | `sign_in_with_apple` (Flutter) | Exigido pela 4.8. |
| **OCR** | **ML Kit on-device** (`google_mlkit_text_recognition`) | ⭐ Muda a arquitetura: grátis, offline, e **a foto nunca sai do aparelho**. Mata custo de Vision + bucket R2 + metade do risco LGPD. |
| LLM — análise de redação | **claude-sonnet-5** | Qualidade importa: é o produto. ~1 chamada/redação/15 dias. |
| LLM — geração de conteúdo | **claude-haiku-4-5** | Lote offline, 7.200 questões. Barato. |
| Fila | **procrastinate** | Já decidido em `arquitetura.md`; roda no Postgres, sem Redis. |
| Push | **APNs direto** (sem Firebase) | Evita SDK de terceiros no app infantil (R-LG-4). |
| Telemetria | **Tabela `evento`** (já existe) | Server-side, sem SDK. |
| Erros | **Sentry** com `send_default_pii=False` | Backend apenas; nunca no app da criança. |
| Banco | **Neon** | Já decidido. |
| Hospedagem | **Cloud Run**, São Paulo | Já decidido. |
| **Dispensados** | Stripe, Cloudflare R2, Google Cloud Vision, Firebase Analytics | Ver acima |

**Custo variável estimado por assinante/mês** (a validar):
LLM de redação ~R$ 0,15 · infra ~R$ 0,40 · Apple 15% ~R$ 4,50 ·
comissão de afiliado (ano 1, 35%) ~R$ 8,90 → **sobra ~R$ 16/mês no ano 1**.

---

## 13 - Ordem de execução

```
Semana 1     Travar D1–D11 · abrir conta Apple Developer (D-U-N-S, contrato
             Paid Apps — é o item de maior lead time) · iniciar redação dos
             documentos legais · começar a curadoria da lista de lemas
Semana 2–3   FASE 1 — Identidade familiar
Semana 3     FASE 2 — Recalibração de faixa (em paralelo)
Semana 4–5   FASE 3 — Assinatura + paywall
Semana 4–6   Conteúdo: pipeline de geração + curadoria (paralelo, contínuo)
Semana 6–8   FASE 4 — Redação real
Semana 8–9   FASE 5 — Área do Responsável
Semana 9     FASE 6 — Congelar professor · legal fechado · TestFlight
Semana 10    Submissão · recrutar 5–10 influenciadores para o piloto
```

**Caminho crítico real:** conta Apple e documentação legal, não o código. Ambos
podem rodar em paralelo desde o dia 1 e ambos travam o lançamento.

---

## 14 - Riscos

| # | Risco | Impacto | Mitigação |
|---|---|---|---|
| R1 | **Conteúdo insuficiente** — 37 palavras hoje; MVP precisa de 100 para a trilha de 16 nós | Alto se ficar abaixo de 100. Churn cedo | Não lançar MVP com menos de 100 palavras revisadas. Ao expandir para 3 países, subir para 600+ antes de reabrir a trilha completa |
| R2 | Influenciadores não vendem sem taxa base | Alto. Sem canal, sem produto | Testar com 3 antes de construir o painel de afiliados. Comissão 35% dos 12 primeiros meses |
| R3 | Rejeição na App Store por regra de app infantil | Médio. Semanas perdidas | Validar D9 com jurídico antes de submeter |
| R4 | Correção de redação por IA erra e o pai perde a confiança | Alto | Rubrica conservadora, tom sempre construtivo, nunca nota numérica para a criança |
| R5 | Redação revela situação grave em casa | Grave, e previsível | R-RD-7 desde o dia 1, não depois |
| R6 | Churn alto (5–10%/mês é o normal do setor) | Alto | Plano anual (D7), Área do Responsável forte, R-AS-5 (progresso preservado) |
| R7 | Criança de 7 anos não consegue usar sozinha | Médio | Testar com crianças reais no TestFlight antes de lançar. Não confie no design em abstrato |
| R8 | Perder a opção B2B ao deletar o professor | Baixo | Fase 6: congelar, não deletar |

---

## 15 - Checklist de fechamento

**Código**
- [x] Migrations de identidade (`3bf46f03ff00`) e assinatura (`86556a5e2ee2`) — cadeia linear. `b2c_03_redacao` (Fase 4) pendente.
- [x] `pytest` verde (147) — inclui faixa e entitlement. Afiliado (§2.2, negócio) ainda não tem domínio de código — pendente.
- [x] `flutter analyze` limpo e `flutter test` verde (42)
- [ ] Guard R1/R2 — sem mudança (professor segue congelado, não removido — nada a ajustar ainda)
- [x] `seed_demo.py` reescrito (conta B2C vitrine com assinatura ativa) e idempotente. `seed.py` preservado intocado (serve só o professor congelado). `seed_temas.py` é Fase 4, não existe ainda.

**Conteúdo**
- [ ] 100 palavras (MVP) com 8 questões, 20% revisadas por humano (100% na faixa 7–8)
- [ ] 120 temas de redação
- [ ] Arte do MVP: nenhuma peça nova (os 4 destinos já estão desenhados)
- [ ] Copy de paywall, onboarding, push e e-mails

**Legal**
- [ ] Política de Privacidade, Termos, Termo de Consentimento Parental publicados
- [ ] ROPA e plano de incidente escritos
- [ ] DPO nomeado com contato público
- [ ] Opt-out de treinamento documentado com o provedor de LLM
- [ ] Privacy Nutrition Labels preenchidos

**Docs do projeto** (regra das decisões revisadas)
- [x] `notas-implementacao.md` com a decisão do pivô datada (24/08)
- [x] `CLAUDE.md` reescrito pro estado B2C atual
- [~] `rascunho_product.md`, `arquitetura.md`, `telas.md`, briefs — ganharam
      nota de "pré-pivô B2B, ver plano B2C" no topo, **não foram reescritos
      por inteiro** (custo de reescrever ~2000 linhas de prosa B2B não se
      pagava frente a ter este plano como spec B2C paralela e completa).
      Reescrever de vez fica pra quando as Fases 4–5 (redação real, Área do
      Responsável) estabilizarem o que essas telas devem descrever.
