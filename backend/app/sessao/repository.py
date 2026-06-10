"""Repositório do domínio sessão — leitura/escrita do estado operacional (Core).

Desempenho: `montar_sessao` faz um número **fixo** de queries (não cresce com o
nº de palavras). As questões de todas as palavras envolvidas vêm numa só query,
com left join em `aluno_questao` para saber o que já foi usado/acertado.
"""
from collections import defaultdict

from sqlalchemy import and_, func, insert, select, update
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.engine import Row
from sqlalchemy.ext.asyncio import AsyncConnection

from app import schema

# Estados que tornam a palavra candidata a revisão (já passou ao menos o N1;
# 'descoberta'/'nivel_1' ainda não têm N2 para revisar; 'dominada' saiu do loop).
ESTADOS_EM_PROGRESSO = ("nivel_2", "nivel_3", "nivel_4")


async def ler_progresso(conn: AsyncConnection, usuario_id: int) -> Row | None:
    p = schema.aluno_progresso
    stmt = select(p.c.nivel_dificuldade_atual, p.c.sessoes_total).where(
        p.c.usuario_id == usuario_id
    )
    return (await conn.execute(stmt)).first()


async def selecionar_palavras_novas(
    conn: AsyncConnection, usuario_id: int, nivel_alvo: int, limite: int
) -> list[Row]:
    """Palavras do banco base ainda não atribuídas ao aluno, mais próximas do nível.

    Primário é o `nivel_dificuldade_atual` (ordem dentro do nível tem pouco impacto,
    seção 3.5); se faltam palavras no nível exato, alarga para os vizinhos por
    distância — robusto a lacunas de conteúdo.
    """
    p, ap = schema.palavra, schema.aluno_palavra
    ja_atribuida = (
        select(ap.c.id)
        .where(ap.c.usuario_id == usuario_id, ap.c.palavra_id == p.c.id)
        .exists()
    )
    distancia = func.abs(p.c.nivel_dificuldade - nivel_alvo)
    stmt = (
        select(
            p.c.id,
            p.c.lema,
            p.c.definicao,
            p.c.exemplo_uso,
            p.c.audio_url,
            p.c.nivel_dificuldade,
        )
        .where(p.c.origem == "banco_base", ~ja_atribuida)
        .order_by(distancia, p.c.id)
        .limit(limite)
    )
    return list((await conn.execute(stmt)).all())


async def selecionar_revisao_candidatas(
    conn: AsyncConnection, usuario_id: int, sessoes_total: int, limite: int
) -> list[Row]:
    """Palavras em progresso, N4-vencido primeiro, depois mais antigas."""
    ap = schema.aluno_palavra
    n4_vencido = and_(
        ap.c.estado == "nivel_4",
        ap.c.nivel4_agendado_para.isnot(None),
        ap.c.nivel4_agendado_para <= sessoes_total,
    )
    stmt = (
        select(ap.c.palavra_id, n4_vencido.label("n4_vencido"))
        .where(
            ap.c.usuario_id == usuario_id,
            ap.c.estado.in_(ESTADOS_EM_PROGRESSO),
        )
        .order_by(n4_vencido.desc(), ap.c.atribuida_em)
        .limit(limite)
    )
    return list((await conn.execute(stmt)).all())


async def ler_questoes_do_aluno(
    conn: AsyncConnection, usuario_id: int, palavra_ids: list[int]
) -> list[Row]:
    """Questões ativas das palavras + se o aluno já usou/acertou cada uma.

    `acertou is None` → variação ainda não usada (sem linha em `aluno_questao`).
    """
    if not palavra_ids:
        return []
    q, aq = schema.questao, schema.aluno_questao
    juncao = q.outerjoin(
        aq, and_(aq.c.questao_id == q.c.id, aq.c.usuario_id == usuario_id)
    )
    stmt = (
        select(
            q.c.id,
            q.c.palavra_id,
            q.c.nivel,
            q.c.variacao,
            q.c.enunciado,
            q.c.opcoes,
            aq.c.acertou,
        )
        .select_from(juncao)
        .where(q.c.palavra_id.in_(palavra_ids), q.c.status == "ativa")
        .order_by(q.c.palavra_id, q.c.nivel, q.c.variacao)
    )
    return list((await conn.execute(stmt)).all())


async def ler_sinonimos(
    conn: AsyncConnection, palavra_ids: list[int]
) -> dict[int, list[str]]:
    if not palavra_ids:
        return {}
    ps = schema.palavra_sinonimo
    stmt = (
        select(ps.c.palavra_id, ps.c.texto)
        .where(ps.c.palavra_id.in_(palavra_ids))
        .order_by(ps.c.id)
    )
    por_palavra: dict[int, list[str]] = defaultdict(list)
    for row in (await conn.execute(stmt)).all():
        por_palavra[row.palavra_id].append(row.texto)
    return dict(por_palavra)


async def abrir_sessao(conn: AsyncConnection, usuario_id: int) -> int:
    return (
        await conn.execute(
            insert(schema.sessao)
            .values(usuario_id=usuario_id)
            .returning(schema.sessao.c.id)
        )
    ).scalar_one()


async def introduzir_palavras(
    conn: AsyncConnection, usuario_id: int, palavra_ids: list[int]
) -> None:
    """Cria as linhas de `aluno_palavra` no estado 'descoberta' (card a ser visto)."""
    if not palavra_ids:
        return
    await conn.execute(
        insert(schema.aluno_palavra),
        [
            {
                "usuario_id": usuario_id,
                "palavra_id": pid,
                "estado": "descoberta",
                "origem": "banco_base",
            }
            for pid in palavra_ids
        ],
    )


# ─────────────────────────────── responder ───────────────────────────────


async def buscar_sessao(conn: AsyncConnection, sessao_id: int) -> Row | None:
    s = schema.sessao
    return (
        await conn.execute(
            select(s.c.usuario_id, s.c.finalizada_em, s.c.xp_ganho).where(
                s.c.id == sessao_id
            )
        )
    ).first()


async def somar_xp_sessao(conn: AsyncConnection, sessao_id: int, xp: int) -> None:
    """Atribui XP à sessão aberta (fonte do `xp_ganho` no resumo do fim)."""
    s = schema.sessao
    await conn.execute(
        update(s).where(s.c.id == sessao_id).values(xp_ganho=s.c.xp_ganho + xp)
    )


async def buscar_questao(conn: AsyncConnection, questao_id: int) -> Row | None:
    q = schema.questao
    return (
        await conn.execute(
            select(
                q.c.id,
                q.c.palavra_id,
                q.c.nivel,
                q.c.opcoes,
                q.c.resposta_correta,
                q.c.status,
            ).where(q.c.id == questao_id)
        )
    ).first()


async def ler_aluno_questao(
    conn: AsyncConnection, usuario_id: int, questao_id: int
) -> Row | None:
    aq = schema.aluno_questao
    return (
        await conn.execute(
            select(aq.c.tentativas, aq.c.acertou).where(
                aq.c.usuario_id == usuario_id, aq.c.questao_id == questao_id
            )
        )
    ).first()


async def ler_aluno_palavra(
    conn: AsyncConnection, usuario_id: int, palavra_id: int
) -> Row | None:
    ap = schema.aluno_palavra
    return (
        await conn.execute(
            select(ap.c.estado, ap.c.nivel4_agendado_para).where(
                ap.c.usuario_id == usuario_id, ap.c.palavra_id == palavra_id
            )
        )
    ).first()


async def ler_pontuacao(conn: AsyncConnection, usuario_id: int) -> Row | None:
    p = schema.aluno_progresso
    return (
        await conn.execute(
            select(
                p.c.xp_total,
                p.c.combo_atual,
                p.c.sessoes_total,
                p.c.palavras_dominadas,
            ).where(p.c.usuario_id == usuario_id)
        )
    ).first()


async def registrar_aluno_questao(
    conn: AsyncConnection,
    usuario_id: int,
    questao_id: int,
    tentativas: int,
    acertou: bool,
    acertou_primeira: bool,
    conta_sinal: bool,
) -> None:
    aq = schema.aluno_questao
    stmt = pg_insert(aq).values(
        usuario_id=usuario_id,
        questao_id=questao_id,
        tentativas=tentativas,
        acertou=acertou,
        acertou_primeira=acertou_primeira,
        conta_sinal=conta_sinal,
        respondida_em=func.now(),
    )
    stmt = stmt.on_conflict_do_update(
        index_elements=[aq.c.usuario_id, aq.c.questao_id],
        set_={
            "tentativas": tentativas,
            "acertou": acertou,
            "acertou_primeira": acertou_primeira,
            "conta_sinal": conta_sinal,
            "respondida_em": func.now(),
        },
    )
    await conn.execute(stmt)


async def avancar_aluno_palavra(
    conn: AsyncConnection,
    usuario_id: int,
    palavra_id: int,
    estado: str,
    nivel4_agendado_para: int | None,
    dominou: bool,
) -> None:
    ap = schema.aluno_palavra
    valores: dict = {"estado": estado, "nivel4_agendado_para": nivel4_agendado_para}
    if dominou:
        valores["dominada_em"] = func.now()
    await conn.execute(
        update(ap)
        .where(ap.c.usuario_id == usuario_id, ap.c.palavra_id == palavra_id)
        .values(**valores)
    )


async def aplicar_pontuacao(
    conn: AsyncConnection,
    usuario_id: int,
    xp_total: int,
    combo_atual: int,
    palavras_dominadas: int,
) -> None:
    p = schema.aluno_progresso
    await conn.execute(
        update(p)
        .where(p.c.usuario_id == usuario_id)
        .values(
            xp_total=xp_total,
            combo_atual=combo_atual,
            palavras_dominadas=palavras_dominadas,
        )
    )


async def zerar_combo(conn: AsyncConnection, usuario_id: int) -> None:
    """Combo é por sessão (3.7): zera ao abrir cada sessão."""
    p = schema.aluno_progresso
    await conn.execute(
        update(p).where(p.c.usuario_id == usuario_id).values(combo_atual=0)
    )


# ───────────────────────────────── fim ─────────────────────────────────


async def ler_progresso_fim(conn: AsyncConnection, usuario_id: int) -> Row | None:
    p = schema.aluno_progresso
    return (
        await conn.execute(
            select(
                p.c.nivel_dificuldade_atual,
                p.c.nivel_mudou_em_sessao,
                p.c.xp_total,
                p.c.palavras_dominadas,
            ).where(p.c.usuario_id == usuario_id)
        )
    ).first()


async def incrementar_sessoes_total(conn: AsyncConnection, usuario_id: int) -> int:
    p = schema.aluno_progresso
    return (
        await conn.execute(
            update(p)
            .where(p.c.usuario_id == usuario_id)
            .values(sessoes_total=p.c.sessoes_total + 1)
            .returning(p.c.sessoes_total)
        )
    ).scalar_one()


async def finalizar_sessao(conn: AsyncConnection, sessao_id: int) -> None:
    s = schema.sessao
    await conn.execute(
        update(s).where(s.c.id == sessao_id).values(finalizada_em=func.now())
    )


async def ler_acertos_primeira_no_nivel(
    conn: AsyncConnection, usuario_id: int, nivel: int, janela: int
) -> list[bool]:
    """Janela móvel do sinal limpo: `acertou_primeira` das últimas respostas de
    INTRODUÇÃO (`conta_sinal`) de palavras no nível dado — revisão fica de fora
    para não inflar a acurácia (Bloco 2a)."""
    aq, q, p = schema.aluno_questao, schema.questao, schema.palavra
    juncao = aq.join(q, q.c.id == aq.c.questao_id).join(
        p, p.c.id == q.c.palavra_id
    )
    stmt = (
        select(aq.c.acertou_primeira)
        .select_from(juncao)
        .where(
            aq.c.usuario_id == usuario_id,
            aq.c.conta_sinal.is_(True),
            p.c.nivel_dificuldade == nivel,
            aq.c.respondida_em.isnot(None),
        )
        .order_by(aq.c.respondida_em.desc())
        .limit(janela)
    )
    return list((await conn.execute(stmt)).scalars().all())


async def atualizar_nivel(
    conn: AsyncConnection, usuario_id: int, novo_nivel: int, sessao: int
) -> None:
    p = schema.aluno_progresso
    await conn.execute(
        update(p)
        .where(p.c.usuario_id == usuario_id)
        .values(nivel_dificuldade_atual=novo_nivel, nivel_mudou_em_sessao=sessao)
    )
