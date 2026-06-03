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

    @property
    def sync_database_url(self) -> str:
        """URL síncrona (psycopg) para o Alembic — migrations não usam async."""
        return self.database_url.replace("+asyncpg", "+psycopg")


settings = Settings()
