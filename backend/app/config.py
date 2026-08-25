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
    # TTL da sessão. Longo de propósito: a criança não tem senha própria
    # (entra por seleção de perfil) e o token vive em secure storage no
    # dispositivo.
    jwt_ttl_horas: int = 720  # 30 dias

    # CORS: origens explícitas separadas por vírgula (nunca "*"). Vazio =
    # CORS desligado — hoje só o app mobile consome a API.
    cors_origins: str = ""

    # Rate limiting (janela fixa de 60s, em memória — vale por processo; se a
    # API escalar horizontalmente, mover o estado para Redis).
    rate_limit_habilitado: bool = True
    # B2C (docs/plano_b2c.md Fase 1): /sessao é login com senha, não mais
    # /acesso/turma (turma inteira atrás de um NAT). Cai para um teto que
    # freia brute-force sem incomodar erro de digitação legítimo.
    rl_login_por_minuto: int = 5
    rl_anonimo_por_minuto: int = 60  # demais rotas sem token, por IP
    rl_autenticado_por_minuto: int = 240  # por token

    # Assinatura (B2C, docs/plano_b2c.md Fase 3). O backend não fala StoreKit
    # nem valida recibo da Apple diretamente — o RevenueCat faz isso e manda um
    # webhook normalizado; autenticamos o webhook por um segredo compartilhado
    # (header Authorization, configurado também no painel do RevenueCat).
    # Sem default de propósito: webhook sem segredo configurado é rejeitado,
    # nunca aceito "por engano".
    revenuecat_webhook_secret: str = ""

    # Redação real (B2C, docs/plano_b2c.md Fase 4). Sem default de propósito:
    # sem a chave, a análise falha com um erro claro ("configuração pendente"),
    # não com um 500 opaco — mesma convenção do RevenueCat acima.
    anthropic_api_key: str = ""
    anthropic_modelo_redacao: str = "claude-sonnet-5"

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def sync_database_url(self) -> str:
        """URL síncrona (psycopg) para o Alembic — migrations não usam async."""
        return self.database_url.replace("+asyncpg", "+psycopg")


settings = Settings()
