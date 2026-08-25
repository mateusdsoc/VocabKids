"""Orquestração do diagnóstico: pega a próxima questão, verifica a resposta,
avança a escada e, ao terminar, grava o `nivel_dificuldade_atual`."""
import random

from sqlalchemy.ext.asyncio import AsyncConnection

from app.diagnostico import escada
from app.diagnostico import repository as repo
from app.diagnostico.schemas import DiagnosticoIn, EstadoDiagnostico
from app.errors import ApiError


def _embaralhar(opcoes: list[str]) -> list[str]:
    copia = list(opcoes)
    random.shuffle(copia)
    return copia


def _resposta_final(perguntas: int, max_perguntas: int, nivel: int) -> dict:
    return {
        "concluido": True,
        "perguntas": perguntas,
        "max_perguntas": max_perguntas,
        "questao": None,
        "estado": None,
        "nivel_dificuldade_atual": nivel,
    }


async def _proxima(conn: AsyncConnection, usuario_id: int, estado: EstadoDiagnostico) -> dict:
    """Apresenta a próxima questão; sem conteúdo disponível, finaliza com o
    melhor nível conhecido (robusto a lacunas do banco)."""
    questao = await repo.buscar_questao_n1(conn, estado.nivel, estado.usadas)
    if questao is None:
        ceiling = estado.ultimo_passou if estado.ultimo_passou is not None else escada.NIVEL_MIN
        nivel = max(escada.NIVEL_MIN, ceiling - 1)
        await repo.definir_nivel(conn, usuario_id, nivel)
        return _resposta_final(estado.perguntas, estado.max_perguntas, nivel)

    estado = estado.model_copy(
        update={"questao_atual": questao.id, "usadas": estado.usadas + [questao.id]}
    )
    return {
        "concluido": False,
        "perguntas": estado.perguntas,
        "max_perguntas": estado.max_perguntas,
        "questao": {
            "questao_id": questao.id,
            "enunciado": questao.enunciado,
            "opcoes": _embaralhar(questao.opcoes),
        },
        "estado": estado,
        "nivel_dificuldade_atual": None,
    }


async def passo(conn: AsyncConnection, usuario_id: int, entrada: DiagnosticoIn) -> dict:
    # Início: sem estado → monta a escada a partir da faixa etária da criança.
    if entrada.estado is None:
        faixa_etaria = await repo.ler_faixa_etaria(conn, usuario_id)
        return await _proxima(conn, usuario_id, escada.iniciar(faixa_etaria))

    # Avanço: precisa da resposta à questão apresentada.
    estado = entrada.estado
    if entrada.questao_id is None or entrada.opcao is None:
        raise ApiError(400, "resposta_ausente", "Informe questao_id e opcao.")
    if entrada.questao_id != estado.questao_atual:
        raise ApiError(400, "questao_inesperada", "Questão não corresponde ao estado.")

    correta = await repo.ler_resposta(conn, entrada.questao_id)
    if correta is None:
        raise ApiError(404, "questao_nao_encontrada", "Questão não encontrada.")

    acertou = entrada.opcao == correta
    novo_estado, nivel_final = escada.avancar(estado, acertou)
    if nivel_final is not None:
        await repo.definir_nivel(conn, usuario_id, nivel_final)
        return _resposta_final(estado.perguntas + 1, estado.max_perguntas, nivel_final)
    return await _proxima(conn, usuario_id, novo_estado)
