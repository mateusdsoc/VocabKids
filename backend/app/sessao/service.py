"""Composição da sessão (`montar_sessao`) — lógica do Bloco 2a.

Monta uma fila de slots na hora (não há "sessão de questões fixa", arquitetura):

    [card p1, p1·N1, p1·N2,  card p2, p2·N1, p2·N2,  p1·N3, p2·N3,  + ~4 revisão]

Cards das palavras novas ficam agrupados no início (nenhum card no meio, 3.2).
A revisão prioriza palavras com N4 vencido e escolhe a questão por prioridade
(N2 não-usada → N3 não-usada → repete a errada), nunca reperguntando uma
variação já acertada e nunca usando o N1 como revisão (3.4).
"""
import math
import random
from collections import defaultdict

from sqlalchemy.ext.asyncio import AsyncConnection

from app.adaptacao import regras as adaptacao
from app.errors import ApiError
from app.progressao import xp as xp_regras
from app.sessao import repository as repo
from app.trilha import service as trilha

# Nível em que o aluno está "trabalhando" por estado (descoberta colapsa no N1:
# acertar o N1 já leva a nivel_2, sem evento separado de "card visto").
_NIVEL_DE_TRABALHO = {
    "descoberta": 1,
    "nivel_1": 1,
    "nivel_2": 2,
    "nivel_3": 3,
    "nivel_4": 4,
}
_PROXIMO_ESTADO = {1: "nivel_2", 2: "nivel_3", 3: "nivel_4", 4: "dominada"}

NOVAS_BASE = 2          # palavras novas no caminho feliz
REVISAO_ALVO = 4        # slots de revisão almejados
TARGET_QUESTOES = 10    # alvo de questões por sessão (cards não contam)
QUESTOES_POR_NOVA = 3   # N1 + N2 + N3


def _embaralhar(opcoes: list[str]) -> list[str]:
    copia = list(opcoes)
    random.shuffle(copia)
    return copia


async def montar_sessao(conn: AsyncConnection, usuario_id: int) -> dict:
    progresso = await repo.ler_progresso(conn, usuario_id)
    if progresso is None:
        raise ApiError(409, "perfil_incompleto", "Aluno sem registro de progresso.")
    nivel = progresso.nivel_dificuldade_atual
    sessoes_total = progresso.sessoes_total

    # 1. Revisão: quanto dá para preencher define quantas palavras novas extras
    #    entram (aluno recém-diagnosticado tem pouca revisão → sessão "mais nova").
    candidatas = await repo.selecionar_revisao_candidatas(
        conn, usuario_id, sessoes_total, REVISAO_ALVO
    )
    slots_revisao_estimados = sum(2 if c.n4_vencido else 1 for c in candidatas)

    # 2. Palavras novas: 2 base + o suficiente para cobrir a lacuna até o alvo.
    faltam = max(0, TARGET_QUESTOES - slots_revisao_estimados)
    qtd_novas = max(NOVAS_BASE, math.ceil(faltam / QUESTOES_POR_NOVA))
    novas = await repo.selecionar_palavras_novas(conn, usuario_id, nivel, qtd_novas)

    # 3. Uma query para as questões de todas as palavras envolvidas.
    novas_ids = [p.id for p in novas]
    palavra_ids = novas_ids + [c.palavra_id for c in candidatas]
    questoes = await repo.ler_questoes_do_aluno(conn, usuario_id, palavra_ids)
    sinonimos = await repo.ler_sinonimos(conn, novas_ids)

    por_palavra_nivel: dict[tuple[int, int], list] = defaultdict(list)
    for q in questoes:
        por_palavra_nivel[(q.palavra_id, q.nivel)].append(q)

    def escolher(palavra_id: int, nivel_q: int):
        """Primeira variação ainda não acertada (não-usada antes de usada-errada)."""
        cands = [
            q
            for q in por_palavra_nivel.get((palavra_id, nivel_q), [])
            if q.acertou is not True
        ]
        if not cands:
            return None
        cands.sort(key=lambda q: (q.acertou is not None, q.variacao))
        return cands[0]

    def escolher_revisao(palavra_id: int):
        """Questão de revisão por prioridade: N2 antes de N3; não-usada antes de errada."""
        cands = [
            (nv, q)
            for nv in (2, 3)
            for q in por_palavra_nivel.get((palavra_id, nv), [])
            if q.acertou is not True
        ]
        if not cands:
            return None
        cands.sort(key=lambda t: (t[1].acertou is not None, t[0], t[1].variacao))
        return cands[0]

    def slot_questao(q, palavra_id, nivel_q, is_revisao):
        return {
            "tipo": "questao",
            "questao_id": q.id,
            "palavra_id": palavra_id,
            "nivel": nivel_q,
            "is_revisao": is_revisao,
            "enunciado": q.enunciado,
            "opcoes": _embaralhar(q.opcoes),
        }

    slots: list[dict] = []
    n_questoes = 0

    # Bloco das novas: card + N1 + N2 agrupados; depois os N3.
    for p in novas:
        slots.append(
            {
                "tipo": "card",
                "palavra": {
                    "id": p.id,
                    "lema": p.lema,
                    "definicao": p.definicao,
                    "exemplo_uso": p.exemplo_uso,
                    "audio_url": p.audio_url,
                    "sinonimos": sinonimos.get(p.id, []),
                    "palavra_gatilho": None,
                },
            }
        )
        for nivel_q in (1, 2):
            q = escolher(p.id, nivel_q)
            if q:
                slots.append(slot_questao(q, p.id, nivel_q, is_revisao=False))
                n_questoes += 1
    for p in novas:
        q = escolher(p.id, 3)
        if q:
            slots.append(slot_questao(q, p.id, 3, is_revisao=False))
            n_questoes += 1

    # Bloco de revisão (até o alvo de questões): Q de revisão + N4 se vencido.
    for c in candidatas:
        if n_questoes >= TARGET_QUESTOES:
            break
        escolha = escolher_revisao(c.palavra_id)
        if escolha:
            nivel_q, q = escolha
            slots.append(slot_questao(q, c.palavra_id, nivel_q, is_revisao=True))
            n_questoes += 1
        # N4 vencido é atômico com a revisão da palavra (avaliação final espaçada,
        # prioridade máxima): se a palavra entrou, o N4 entra junto, sem o teto cortar.
        if c.n4_vencido:
            q4 = escolher(c.palavra_id, 4)
            if q4:
                slots.append(slot_questao(q4, c.palavra_id, 4, is_revisao=True))
                n_questoes += 1

    # Persistência: abre a sessão e introduz as novas (card a ser visto = descoberta).
    sessao_id = await repo.abrir_sessao(conn, usuario_id)
    await repo.zerar_combo(conn, usuario_id)  # combo é por sessão (3.7)
    await repo.introduzir_palavras(conn, usuario_id, novas_ids)

    return {"sessao_id": sessao_id, "slots": slots}


async def responder(
    conn: AsyncConnection,
    usuario_id: int,
    sessao_id: int,
    questao_id: int,
    opcao: str,
) -> dict:
    """Corrige uma resposta no servidor: XP/combo, avanço de estado, domínio.

    A correção é server-side (integridade do XP, cliente fino). A intercalação de
    erro é reordenada no cliente (decisão #3) — aqui só registramos e devolvemos o
    feedback, incluindo a resposta correta (revelada só APÓS responder).
    """
    sessao = await repo.buscar_sessao(conn, sessao_id)
    if sessao is None:
        raise ApiError(404, "sessao_nao_encontrada", "Sessão não encontrada.")
    if sessao.usuario_id != usuario_id:
        raise ApiError(403, "sem_permissao", "Sessão de outro usuário.")
    if sessao.finalizada_em is not None:
        raise ApiError(409, "sessao_encerrada", "Sessão já encerrada.")

    questao = await repo.buscar_questao(conn, questao_id)
    if questao is None:
        raise ApiError(404, "questao_nao_encontrada", "Questão não encontrada.")
    if questao.status != "ativa":
        raise ApiError(409, "questao_indisponivel", "Questão indisponível.")
    if opcao not in questao.opcoes:
        raise ApiError(400, "opcao_invalida", "Opção não pertence à questão.")

    aluno_palavra = await repo.ler_aluno_palavra(conn, usuario_id, questao.palavra_id)
    if aluno_palavra is None:
        raise ApiError(409, "palavra_nao_atribuida", "Palavra não atribuída ao aluno.")

    anterior = await repo.ler_aluno_questao(conn, usuario_id, questao_id)
    if anterior is not None and anterior.acertou:
        # Nunca se repergunta uma variação já acertada (3.4).
        raise ApiError(409, "questao_ja_respondida", "Questão já acertada.")

    tentativa = (anterior.tentativas if anterior else 0) + 1
    correto = opcao == questao.resposta_correta
    primeira = correto and tentativa == 1

    progresso = await repo.ler_pontuacao(conn, usuario_id)
    pontos = xp_regras.pontuar(
        correto=correto,
        tentativa=tentativa,
        combo_atual=progresso.combo_atual,
    )

    # Avanço de estado: só no acerto e só quando a questão é do nível em trabalho.
    estado = aluno_palavra.estado
    novo_estado = estado
    nivel4_agendado = aluno_palavra.nivel4_agendado_para
    dominou = False
    xp_dominio = 0
    nivel_trabalho = _NIVEL_DE_TRABALHO.get(estado)
    # Resposta de introdução (questão no nível em trabalho) = sinal limpo da
    # adaptação; revisão (nível já passado) não conta (Bloco 2a).
    conta_sinal = nivel_trabalho is not None and questao.nivel == nivel_trabalho
    if correto and nivel_trabalho is not None and questao.nivel == nivel_trabalho:
        novo_estado = _PROXIMO_ESTADO[nivel_trabalho]
        if nivel_trabalho == 3:
            # N4 adiado ~2 sessões (vence numa sessão futura).
            nivel4_agendado = progresso.sessoes_total + 2
        elif nivel_trabalho == 4:
            dominou = True
            xp_dominio = xp_regras.BONUS_DOMINIO

    xp_ganho = pontos.xp + xp_dominio
    xp_total = progresso.xp_total + xp_ganho
    palavras_dominadas = progresso.palavras_dominadas + (1 if dominou else 0)

    # Persistência.
    await repo.registrar_aluno_questao(
        conn, usuario_id, questao_id, tentativa, correto, primeira, conta_sinal
    )
    if xp_ganho:
        await repo.somar_xp_sessao(conn, sessao_id, xp_ganho)
    if novo_estado != estado:
        await repo.avancar_aluno_palavra(
            conn, usuario_id, questao.palavra_id, novo_estado, nivel4_agendado, dominou
        )
    await repo.aplicar_pontuacao(
        conn, usuario_id, xp_total, pontos.combo, palavras_dominadas
    )

    # Trilha: avança o nó e concede recompensas (cartão/carimbo/selo) — o pedaço
    # que ficou adiado quando a trilha ainda não existia.
    recompensas = await trilha.processar_recompensas(
        conn, usuario_id, progresso.xp_total, xp_total, pontos.combo, palavras_dominadas
    )

    return {
        "correto": correto,
        "resposta_correta": questao.resposta_correta,
        "tentativas": tentativa,
        "xp_ganho": xp_ganho,
        "combo_atual": pontos.combo,
        "xp_total": xp_total,
        "estado_palavra": novo_estado,
        "dominou": dominou,
        "recompensas": recompensas,
    }


async def finalizar(conn: AsyncConnection, usuario_id: int, sessao_id: int) -> dict:
    """Fecha a sessão: resumo + incrementa sessoes_total + roda a adaptação.

    A adaptação lê o sinal limpo (acurácia de 1ª tentativa no nível atual, janela
    móvel) e move o nível em ±1 com histerese e cooldown (Bloco 2a).
    """
    sessao = await repo.buscar_sessao(conn, sessao_id)
    if sessao is None:
        raise ApiError(404, "sessao_nao_encontrada", "Sessão não encontrada.")
    if sessao.usuario_id != usuario_id:
        raise ApiError(403, "sem_permissao", "Sessão de outro usuário.")
    if sessao.finalizada_em is not None:
        raise ApiError(409, "sessao_encerrada", "Sessão já encerrada.")

    progresso = await repo.ler_progresso_fim(conn, usuario_id)
    nivel_anterior = progresso.nivel_dificuldade_atual

    sessoes_total = await repo.incrementar_sessoes_total(conn, usuario_id)
    await repo.finalizar_sessao(conn, sessao_id)

    # Adaptação contínua.
    janela = await repo.ler_acertos_primeira_no_nivel(
        conn, usuario_id, nivel_anterior, adaptacao.JANELA
    )
    amostra = len(janela)
    acuracia = (sum(1 for ok in janela if ok) / amostra) if amostra else None
    pode_mover = (
        progresso.nivel_mudou_em_sessao is None
        or (sessoes_total - progresso.nivel_mudou_em_sessao) > adaptacao.COOLDOWN_SESSOES
    )
    novo_nivel, mudou = adaptacao.decidir(
        acuracia=acuracia,
        amostra=amostra,
        nivel_atual=nivel_anterior,
        pode_mover=pode_mover,
    )
    if mudou:
        await repo.atualizar_nivel(conn, usuario_id, novo_nivel, sessoes_total)

    return {
        "xp_ganho": sessao.xp_ganho,
        "xp_total": progresso.xp_total,
        "palavras_dominadas": progresso.palavras_dominadas,
        "nivel_anterior": nivel_anterior,
        "nivel_atual": novo_nivel,
        "nivel_mudou": mudou,
        "sessoes_total": sessoes_total,
    }
