"""Meta semanal — regra pura do default por faixa etária (§3.5).

B2C (docs/plano_b2c.md Fase 2): sem professor, a meta vem da faixa etária da
criança (`progressao/faixa.py`), não mais de `turma_config` nem de
`ano_escolar`. Valores PROVISÓRIOS — calibração pedagógica pendente.

`meta_config` permanece como parâmetro para o domínio `professor` (fatia B2B
congelada, docs/plano_b2c.md Fase 6) continuar funcionando sem mudança.
"""
from app.progressao.faixa import meta_semanal_default

META_DEFAULT_POR_ANO = {6: 4, 7: 5, 8: 6, 9: 7}  # só o professor (B2B) usa
META_DEFAULT = 5  # fallback para ano fora do Fundamental II


def meta_efetiva(meta_config: int | None, ano_escolar: int | None) -> int:
    """Usada pelo domínio `professor` (B2B congelado) — mantida como estava."""
    if meta_config is not None:
        return meta_config
    return META_DEFAULT_POR_ANO.get(ano_escolar, META_DEFAULT)


def meta_efetiva_b2c(faixa_etaria: str) -> int:
    """Meta semanal do perfil de criança B2C — sempre o default da faixa
    (não há professor configurando; ver `perfil_crianca.faixa_etaria`)."""
    return meta_semanal_default(faixa_etaria)
