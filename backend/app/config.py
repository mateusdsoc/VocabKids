"""Configuração via variáveis de ambiente (pydantic-settings).

Princípio interface-estável/provider-variável (seção 12 do produto): demo→produção
é troca de connection string, não reescrita.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # URL async (asyncpg) usada pelo app em runtime.
    database_url: str = "postgresql+asyncpg://postgres@localhost:5432/vocabkids"
    app_env: str = "dev"

    # Auth JWT (HS256). Sem default de propósito: um segredo vazio derruba a
    # emissão/validação de token com erro claro (gere com `openssl rand -hex 32`).
    jwt_secret: str = ""
    # TTL da sessão. Longo de propósito: aluno não tem senha (reentra pelo
    # código de turma) e o token vive em secure storage no dispositivo.
    jwt_ttl_horas: int = 720  # 30 dias

    # CORS: origens explícitas separadas por vírgula (nunca "*" — o site do
    # professor entra aqui quando for publicado). Vazio = CORS desligado.
    cors_origins: str = ""

    # Rate limiting (janela fixa de 60s, em memória — vale por processo; se a
    # API escalar horizontalmente, mover o estado para Redis).
    rate_limit_habilitado: bool = True
    rl_login_por_minuto: int = 20  # /acesso/turma por IP (turma inteira atrás de um NAT)
    rl_anonimo_por_minuto: int = 60  # demais rotas sem token, por IP
    rl_autenticado_por_minuto: int = 240  # por token — não pune a turma pelo IP compartilhado

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def sync_database_url(self) -> str:
        """URL síncrona (psycopg) para o Alembic — migrations não usam async."""
        return self.database_url.replace("+asyncpg", "+psycopg")


settings = Settings()
