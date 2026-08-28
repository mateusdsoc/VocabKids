# ECA Digital (Lei nº 15.211/2025) — análise de conformidade

> Lei nova, **em vigor desde 17/03/2026** (6 meses após a sanção em
> setembro/2025) — não estava em nenhuma versão anterior deste plano porque
> não existia quando o checklist original (`docs/produto/plano_b2c.md` §11)
> foi escrito. Também chamada de "Lei Felca". Regulamentação complementar
> (decreto do MJSP/ANPD/Casa Civil) ainda está sendo detalhada — este
> documento reflete o texto da lei e o que já foi divulgado oficialmente até
> 26/08/2026; **revisitar quando o decreto sair**.

## O que a lei exige, e como o VocabKids se posiciona

| Exigência da lei | O que significa na prática | Situação do VocabKids |
|---|---|---|
| **Aferição de idade real**, não autodeclaração simples (pra produtos etariamente restritos — álcool, jogos de azar, conteúdo adulto) | Não basta perguntar "você tem 18 anos?" pra liberar produto restrito | Não se aplica diretamente — o VocabKids não vende produto etariamente restrito. A idade da *criança* (não do responsável) é informada pelo *responsável*, o que é estrutura diferente: quem se autodeclara adulto é quem cria a conta, coberto pela Seção 5.1 da Política de Privacidade (esforços razoáveis do art. 14 §5 da LGPD), não pela regra de aferição de idade da ECA Digital |
| **Segurança e privacidade desde o design** ("segurança por padrão") | Arquitetura já nasce pensando em segurança da criança, não como retrofit | **Já atendido pelo desenho original do produto**: minimização de dado (apelido + ano, não nome completo), sem SDK de rastreamento de terceiros, pseudonimização do texto enviado à IA, triagem de risco antes de qualquer outra coisa na redação |
| **Supervisão parental acessível, clara e sem custo** | Ferramenta de controle parental não pode ser paga à parte | **Já atendido**: a Área do Responsável (resumo semanal, exclusão de conta, portão PIN) é parte do produto, não um add-on pago |
| **Mecanismo eficaz de reporte imediato às autoridades** para exploração, abuso ou aliciamento | A plataforma precisa ter um caminho real pra acionar autoridades quando identificar risco, não só "lidar internamente" | **Gap conhecido, aceito por decisão do dono (27/08) — não vai ser construído.** A triagem de risco (R-RD-7) leva a "revisão humana" interna (estado `revisao_humana` no banco), sem nenhum canal formal de acionamento de Conselho Tutelar/Disque 100/SaferNet. A operação (uma pessoa) não tem capacidade de manter esse processo. Isto é uma decisão de risco assumida conscientemente, não um item "em progresso" — ver `docs/legal/plano_resposta_incidente.md` §8. |
| **Restrição de publicidade e coleta excessiva pra perfilamento comportamental** | Proibido usar dado de criança pra montar perfil publicitário | **Já atendido**: zero SDK de anúncio, zero rastreamento comportamental, telemetria é só operacional (Política de Privacidade, Seção 10) |
| **Proibição de monetizar conteúdo que sexualize menor** | — | Não aplicável à natureza do produto (educação de vocabulário/redação) |
| Contas de crianças até 16 anos vinculadas a um responsável legal | — | **Já é a arquitetura central do produto** desde a Fase 1 (perfil de criança só existe dentro da conta do responsável) |

## Onde isto ainda é incerto (regulamentação pendente)

A lei em si define princípios; os **padrões técnicos específicos** (ex.:
formato exato do canal de denúncia, prazos de resposta, eventual
obrigatoriedade de relatório de transparência) ficam pra um decreto do
Executivo, ainda em elaboração com participação da ANPD. Recomendação:
tratar o que está nesta tabela como o piso de conformidade razoável hoje, e
revisitar quando o decreto for publicado — sem esperar o decreto pra agir,
porque os princípios gerais da lei já valem desde 17/03/2026.

## Não há exigência de registro/cadastro do app junto ao governo

Pelas fontes públicas consultadas, não foi identificada obrigação de
registro prévio de plataformas junto a um órgão federal como pré-requisito
pra operar — diferente de, por exemplo, provedores de rede social de grande
porte, que podem ter obrigações adicionais de transparência não aplicáveis
a um app do porte do VocabKids. **Se isso mudar com a regulamentação,
atualizar aqui.**

---

*Última atualização: 26/08/2026, com base em pesquisa pública — ver
`docs/legal/fontes_pesquisa.md`.*
