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

from app.errors import ApiError
from app.sessao import repository as repo

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
    await repo.introduzir_palavras(conn, usuario_id, novas_ids)

    return {"sessao_id": sessao_id, "slots": slots}
