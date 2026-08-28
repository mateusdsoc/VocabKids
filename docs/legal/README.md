# Documentação legal — VocabKids

Documentos que atendem `docs/produto/plano_b2c.md` §11.1 (tabela exigida
pela LGPD antes do lançamento). Escritos em 26/08/2026 com pesquisa de fonte
primária (texto da LGPD, Enunciado ANPD 1/2023, ECA Digital, guidelines da
Apple, política da OpenAI — proveniência completa em
[fontes_pesquisa.md](fontes_pesquisa.md)), a partir do schema real do
backend — não de template genérico. **Decisão do dono: sem advogado.**
Nenhum destes é aconselhamento jurídico individualizado, mas todos refletem
o melhor esforço a partir de fonte pública disponível nesta data.

| Documento | Público ou interno? | O que ainda falta (dado seu, não conteúdo jurídico) |
|---|---|---|
| [politica_privacidade.md](politica_privacidade.md) | Público | Preencher CPF/e-mail definitivo |
| [termos_de_uso.md](termos_de_uso.md) | Público | Preencher foro/CNPJ quando existir |
| [termo_consentimento_parental.md](termo_consentimento_parental.md) | Público (tela no app) | ✅ Implementado (27/08) — nada pendente aqui |
| [suboperadores.md](suboperadores.md) | Público | Confirmar provedor de push quando escolhido |
| [eca_digital.md](eca_digital.md) | Interno | Revisitar quando sair o decreto de regulamentação |
| [ropa.md](ropa.md) | Interno | Preencher pendências pontuais (§3) — TTL de telemetria, prazo fiscal de transação |
| [politica_retencao_exclusao.md](politica_retencao_exclusao.md) | Interno | Implementar job de expurgo automático de redação aos 24 meses |
| [plano_resposta_incidente.md](plano_resposta_incidente.md) | Interno | Nada pendente — canal de reporte às autoridades foi descartado por decisão do dono (§8), risco aceito conscientemente |
| [opt_out_llm.md](opt_out_llm.md) | Interno (referenciado na Política de Privacidade) | Nada a fazer ainda — a checagem no painel só faz sentido quando existir conta/chave OpenAI de verdade |
| [privacy_nutrition_labels.md](privacy_nutrition_labels.md) | Interno (guia de preenchimento) | Preencher o formulário real no App Store Connect na hora de submeter |
| [fontes_pesquisa.md](fontes_pesquisa.md) | Interno | Registro de proveniência — revisitar se alguma fonte for atualizada |

## O que foi resolvido nesta rodada (26/08) que antes estava em aberto

- **DPO nomeado com contato público**: o fundador, provisoriamente — Política
  de Privacidade §11.
- **Decisão D9** (categoria Kids vs. Educação/4+): **Educação/4+ com portão
  parental**, decidido com pesquisa concreta (Kids Category não cobre a
  faixa 7–12 inteira e proíbe até dado pseudonimizado a terceiro) — ver
  Política de Privacidade §9 e `docs/produto/plano_b2c.md` §11.2.
- **ECA Digital**: lei nova (vigente desde 17/03/2026) que não existia
  quando o plano original foi escrito — endereçada em `eca_digital.md`. Um
  gap real dela (canal de reporte às autoridades) foi identificado em 26/08
  e depois **descartado por decisão do dono em 27/08** — ver abaixo.

## O que foi implementado em código nesta rodada (27/08)

- **Tela de consentimento parental**: `app/lib/features/identidade/cadastro_screen.dart`
  ganhou duas caixas de marcação separadas (Termos de Uso + consentimento
  LGPD, este último visualmente destacado), cada uma abrindo o texto
  completo (`legal_texts.dart` + `widgets/legal_text_screen.dart`). O valor
  real de cada caixa agora vai pro backend (antes o app mandava `true` fixo
  pros dois campos, mesmo sem UI que os representasse de verdade).
  Verificado ao vivo no navegador contra o backend real: gate bloqueia sem
  as duas caixas marcadas, cria a conta com as duas marcadas, e
  `conta.consentimento_lgpd_em`/`consentimento_versao` gravam certinho no
  Postgres. `flutter analyze` limpo, `flutter test` 26/26.
- O gate no **backend** já existia desde a Fase 1 (não era pendência de
  código, só de UI) — `_exigir_consentimento` em
  `backend/app/identidade/routes.py`.

## Escopo descartado por decisão do dono (27/08)

- **Canal de reporte às autoridades** (Conselho Tutelar/Disque 100/SaferNet)
  pra sinal de risco grave na redação, que o ECA Digital pede — a operação
  não tem capacidade de manter isso. Risco aceito conscientemente, não
  resolvido: ver `plano_resposta_incidente.md` §8 e `eca_digital.md`.

## O que continua exigindo ação humana (quando fizer sentido, não agora)

- Verificar a conta OpenAI de verdade (`opt_out_llm.md`) — só quando a
  conta/chave existir.
- Job de expurgo automático de redação (24 meses) — só quando alguém tiver
  esse tempo de uso.

## Regra de manutenção

Mesma regra do `CLAUDE.md` "decisões revisadas": se o schema mudar de um
jeito que afete o que é coletado (nova tabela/coluna com dado pessoal), o
`ropa.md` e, se for o caso, a `politica_privacidade.md` são atualizados no
mesmo PR — não depois. Revisitar `fontes_pesquisa.md` a cada ~6 meses ou
quando uma lei/política de provedor citada nela mudar.
