"""Armazenamento dos arquivos de redação — interface estável, provider variável.

Princípio da seção 12 do produto: o chamador (serviço) fala com a interface
[Armazenamento]; dev/testes usam disco local, produção usará R2 (S3-compatível)
trocando só o provider em [armazenamento]. Chaves são caminhos relativos
(ex.: `atribuicao_3/usuario_9/ab12_p1.jpg`) — válidas igual em disco e em bucket.

O I/O local roda em thread (`asyncio.to_thread`) para não segurar o event loop
do FastAPI durante a gravação de fotos de alguns MB.
"""
import asyncio
from pathlib import Path
from typing import Protocol

from app.config import settings


class Armazenamento(Protocol):
    async def salvar(self, chave: str, conteudo: bytes) -> None: ...

    async def ler(self, chave: str) -> bytes: ...

    async def remover(self, chave: str) -> None: ...


class ArmazenamentoLocal:
    """Arquivos em disco sob uma raiz fixa (`REDACOES_DIR`)."""

    def __init__(self, raiz: str) -> None:
        self._raiz = Path(raiz)

    def _caminho(self, chave: str) -> Path:
        caminho = (self._raiz / chave).resolve()
        if not caminho.is_relative_to(self._raiz.resolve()):
            # Chave é sempre gerada pelo serviço; sair da raiz é bug, não input.
            raise ValueError(f"chave fora da raiz de redações: {chave!r}")
        return caminho

    async def salvar(self, chave: str, conteudo: bytes) -> None:
        def _gravar() -> None:
            caminho = self._caminho(chave)
            caminho.parent.mkdir(parents=True, exist_ok=True)
            caminho.write_bytes(conteudo)

        await asyncio.to_thread(_gravar)

    async def ler(self, chave: str) -> bytes:
        return await asyncio.to_thread(self._caminho(chave).read_bytes)

    async def remover(self, chave: str) -> None:
        await asyncio.to_thread(self._caminho(chave).unlink, missing_ok=True)


def armazenamento() -> Armazenamento:
    # Lê a config a cada chamada (e não na importação) para o diretório poder
    # ser trocado por teste/ambiente sem reimportar o módulo.
    return ArmazenamentoLocal(settings.redacoes_dir)
