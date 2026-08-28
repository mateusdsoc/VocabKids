# Privacy Nutrition Labels — mapeamento para o App Store Connect

> ⚠️ **Isto não é o formulário em si** — é o mapeamento de "o que o app
> realmente coleta" pras categorias que a Apple usa no formulário de
> App Privacy do App Store Connect. Você preenche o formulário de verdade lá
> dentro na hora de submeter; use esta tabela como guia pra não esquecer
> nada e não superdeclarar (declarar coleta que não existe também é
> problema, não só o contrário). Confirmar contra a versão atual do
> formulário da Apple antes de submeter — categorias da Apple mudam de vez
> em quando.

## Como preencher, categoria por categoria

| Categoria da Apple | O VocabKids coleta? | Detalhe | Vinculado à identidade do usuário? | Usado para rastreamento (tracking)? |
|---|---|---|---|---|
| **Contact Info → Name** | Sim (parcial) | Nome do **responsável** (não da criança — a criança só tem apelido, que a Apple trata como "User Content", ver abaixo) | Sim | Não |
| **Contact Info → Email Address** | Sim | E-mail do responsável, pra login | Sim | Não |
| **Identifiers → User ID** | Sim | ID interno de conta/usuário | Sim | Não |
| **Financial Info → Payment Info** | Não, diretamente | Pagamento processado pela Apple via IAP — não vemos nem armazenamos dado de cartão | — | Não |
| **User Content → Other User Content** | Sim | Apelido da criança, texto das redações, progresso de jogo | Sim (vinculado à conta) | Não |
| **Usage Data → Product Interaction** | Sim | Eventos de uso (sessão iniciada, resposta dada) — telemetria própria, sem SDK de terceiros | Sim (vinculado à conta) | Não |
| **Diagnostics** | [Confirmar — depende se algum crash reporting for adicionado; hoje não há SDK de crash reporting de terceiros no projeto] | — | — | Não |
| **Location** | Não | — | — | — |
| **Health & Fitness** | Não | — | — | — |
| **Contacts** | Não | — | — | — |
| **Browsing History** | Não | — | — | — |
| **Search History** | Não | — | — | — |
| **Identifiers → Device ID** | [Confirmar — depende de como o RevenueCat/Apple IAP identifica o dispositivo internamente; geralmente não precisa ser declarado por nós separadamente, mas checar a documentação do RevenueCat sobre isso] | — | — | Não |

## Pontos de atenção específicos pra app infantil

- **"Usado para rastreamento" deve ser NÃO em toda linha** — é isso que a
  ausência de SDK de terceiros/publicidade garante (Política de Privacidade,
  Seção 10). Isso é uma vantagem real na review de app infantil: simplifica
  bastante o formulário e evita as perguntas mais duras da Guideline 5.1.4.
- Apps na categoria Kids (se a Decisão D9 do plano optar por isso) têm um
  crivo adicional sobre publicidade comportamental e coleta de dado de
  terceiro — como não usamos nenhum SDK de anúncio/analytics de terceiros,
  isso já está coberto, mas **confirme isso é reafirmado no formulário**, não
  suposto.
- **Apelido da criança**: a Apple pode pedir uma resposta específica sobre
  se o app coleta dado de criança apartado do responsável. A resposta
  honesta é: o **apelido** é dado da criança, mas nunca coletamos nome
  completo/e-mail/foto/localização dela — vale deixar essa distinção clara
  se o formulário permitir texto livre em algum campo.

## Pendências

- Confirmar se algum crash reporting será adicionado (linha "Diagnostics"
  acima) antes de submeter — hoje não há.
- Confirmar com a documentação do RevenueCat qual identificador de
  dispositivo (se algum) precisa constar como coletado por eles em nosso
  nome.
- Preencher o formulário real no App Store Connect usando esta tabela como
  checklist, não como substituto — a Apple pode ter subcategorias mais finas
  do que as listadas aqui.

---

*Última atualização: 26/08/2026.*
