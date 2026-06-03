"""Dependências compartilhadas da camada de API.

Acesso a dados com SQLAlchemy Core (decisão #2 do Bloco 3): queries explícitas,
sem ORM pesado. A conexão/transação é por request e é **gerida pelo middleware**
(`db_transacao` em `app.main`), que faz o commit ANTES de a resposta ser enviada.

Por que não um yield-dependency com `engine.begin()`: o teardown de dependências
`yield` do FastAPI roda DEPOIS da resposta, então o commit corria com o próximo
request (leitura-após-escrita via — ex.: criar aluno e usar o token em seguida).
"""
from sqlalchemy.ext.asyncio import AsyncConnection
from starlette.requests import Request


def get_conn(request: Request) -> AsyncConnection:
    return request.state.conn
