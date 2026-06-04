"""Convenção de erro da API — decisão #5 do Bloco 3 (arquitetura).

Todo erro sai no formato único:

    { "error": { "code": <snake_case>, "message": <legível>, "details": {} } }

O app ramifica pelo `code`; o status HTTP segue a semântica padrão. O `422` do
FastAPI (validação Pydantic) é capturado e reembrulhado no mesmo formato.
"""
import logging

from fastapi import FastAPI, Request
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

logger = logging.getLogger("app")

# status HTTP → code default (quando o erro não traz um code de domínio próprio).
_CODE_POR_STATUS = {
    400: "requisicao_invalida",
    401: "nao_autenticado",
    403: "sem_permissao",
    404: "nao_encontrado",
    409: "conflito",
    422: "validation_error",
    429: "limite_excedido",
    500: "erro_interno",
}


class ApiError(Exception):
    """Erro de domínio que vira o corpo de erro padronizado.

    Levante em serviços/rotas: `raise ApiError(404, "turma_nao_encontrada", "...")`.
    """

    def __init__(
        self, status_code: int, code: str, message: str, details: dict | None = None
    ):
        self.status_code = status_code
        self.code = code
        self.message = message
        self.details = details or {}
        super().__init__(message)


def _corpo(code: str, message: str, details: dict | None) -> dict:
    return {"error": {"code": code, "message": message, "details": details or {}}}


def register_error_handlers(app: FastAPI) -> None:
    """Pluga os handlers que garantem o formato único de erro."""

    @app.exception_handler(ApiError)
    async def _api_error(_: Request, exc: ApiError):
        return JSONResponse(
            status_code=exc.status_code,
            content=_corpo(exc.code, exc.message, exc.details),
        )

    @app.exception_handler(RequestValidationError)
    async def _validacao(_: Request, exc: RequestValidationError):
        return JSONResponse(
            status_code=422,  # default do FastAPI para validação
            content=_corpo(
                "validation_error",
                "Dados de entrada inválidos.",
                {"errors": jsonable_encoder(exc.errors())},
            ),
        )

    @app.exception_handler(StarletteHTTPException)
    async def _http(_: Request, exc: StarletteHTTPException):
        code = _CODE_POR_STATUS.get(exc.status_code, "erro")
        return JSONResponse(
            status_code=exc.status_code,
            content=_corpo(code, str(exc.detail), {}),
        )

    @app.exception_handler(Exception)
    async def _erro_interno(_: Request, exc: Exception):
        # Mantém o envelope da decisão #5 também no 500, sem vazar o traceback
        # ao cliente (fica no log). O middleware de transação já fez rollback.
        logger.exception("erro não tratado")
        return JSONResponse(
            status_code=500,
            content=_corpo("erro_interno", "Erro interno do servidor.", {}),
        )
