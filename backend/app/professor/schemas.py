"""Contratos Pydantic do domínio professor.

Mesmos shapes desde a fatia A (o app não muda): os modelos espelham
`associacao_turma`, `turma_config` e `redacao_atribuicao`. O campo `mock`
permanece no contrato — agora sempre `False` (fatia C, dados reais).
"""
from datetime import date

from pydantic import BaseModel, Field, field_validator


class TurmaResumo(BaseModel):
    id: int
    nome: str
    ano_escolar: int
    alunos_ativos: int
    meta_semanal: int


class TurmasOut(BaseModel):
    mock: bool
    turmas: list[TurmaResumo]


class AlunoPainel(BaseModel):
    id: int
    nome: str
    palavras_semana: int  # palavras dominadas nesta semana (unidade da meta, §3.5)
    meta_semana: int
    palavras_dominadas: int  # acumulado histórico


class PainelOut(BaseModel):
    mock: bool
    turma_id: int
    turma_nome: str
    ano_escolar: int
    alunos_ativos: int
    alunos_total: int
    palavras_dominadas_semana: int
    meta_semanal: int
    sinal_turma: list[str]  # palavras fracas recorrentes na turma (§3.5)
    alunos: list[AlunoPainel]


class TurmaLinha(BaseModel):
    id: int
    nome: str
    ano_escolar: int
    alunos_ativos: int
    alunos_total: int
    palavras_dominadas_semana: int
    meta_semanal: int


class EscolaPainelOut(BaseModel):
    """Escopo escola (§3.11): agregado só-leitura — o coordenador vive aqui; o
    professor enxerga pelo toggle turma↔escola."""

    mock: bool
    escola_nome: str
    turmas_total: int
    alunos_ativos: int
    alunos_total: int
    palavras_dominadas_semana: int
    sinal_escola: list[str]
    turmas: list[TurmaLinha]


class AlunoPalavra(BaseModel):
    """Uma palavra no vocabulário do aluno (espelha `aluno_palavra`)."""

    texto: str
    estado: str  # descoberta | nivel_1..4 | dominada (máquina de estados, §3.4)
    origem: str  # pessoal_redacao | sinal_turma | banco_base (§3.2/§3.5)


class AlunoRedacao(BaseModel):
    """Atribuição da turma sob a ótica deste aluno (`redacao_atribuicao` +
    `redacao`). `status` traduzido para a linguagem do professor — ver
    `service._status_para_professor`."""

    id: int
    tema: str
    status: str  # pendente | em_analise | analisada
    enviada_em: str | None


class AlunoDetalheOut(BaseModel):
    """Detalhe do aluno — drill-down do painel (telas §8.2). Só leitura.

    Counters + uma lista **limitada** de palavras notáveis (não o histórico
    inteiro — produto §3.5: "o contador, não a lista, que ficaria longa demais")
    e as redações do aluno. Sem % de acerto / tempo (decisões de produto).
    """

    mock: bool
    id: int
    nome: str
    turma_id: int
    turma_nome: str
    ano_escolar: int
    palavras_semana: int  # dominadas nesta semana (unidade da meta, §3.5)
    meta_semana: int
    palavras_dominadas: int  # acumulado histórico (counter)
    palavras_em_progresso: int  # em nivel_1..4, ainda não dominadas (counter)
    palavras: list[AlunoPalavra]  # subconjunto notável (recentes/ativas)
    redacoes: list[AlunoRedacao]


class AtribuirRedacaoIn(BaseModel):
    """Corpo de POST /professor/turmas/{id}/redacoes (espelha `redacao_atribuicao`,
    §4.6): o professor atribui **tema + prazo**; o aluno é quem envia depois."""

    tema: str
    prazo: str | None = None  # data ISO (yyyy-mm-dd) ou null (sem prazo)

    @field_validator("tema")
    @classmethod
    def _tema_nao_vazio(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("tema obrigatório")
        return v

    @field_validator("prazo")
    @classmethod
    def _prazo_iso(cls, v: str | None) -> str | None:
        if v is None:
            return v
        try:
            date.fromisoformat(v)
        except ValueError as e:
            raise ValueError("prazo deve ser uma data ISO (yyyy-mm-dd)") from e
        return v


class RedacaoAtribuicaoOut(BaseModel):
    mock: bool
    id: int
    turma_id: int
    tema: str
    prazo: str | None


class AtualizarMetaIn(BaseModel):
    """Corpo de PUT /professor/turmas/{id}/meta (espelha `turma_config.meta_semanal`,
    §3.5): meta em **palavras dominadas por semana, por aluno**. Só professor."""

    meta_semanal: int = Field(ge=1, le=50)


class MetaTurmaOut(BaseModel):
    mock: bool
    turma_id: int
    meta_semanal: int
