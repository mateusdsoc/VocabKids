"""Meta semanal — regra pura do default por ano (§3.5).

O professor configura `turma_config.meta_semanal`; se nula, vale o default do
ano escolar ("se o professor não mexer, o padrão funciona sozinho"). Valores
PROVISÓRIOS: espelham a demo (7º=5, 8º=6) numa rampa linear — a calibração
pedagógica (simular contra o ritmo real de domínio) está pendente e registrada
nas notas de implementação.
"""

META_DEFAULT_POR_ANO = {6: 4, 7: 5, 8: 6, 9: 7}
META_DEFAULT = 5  # fallback para ano fora do Fundamental II


def meta_efetiva(meta_config: int | None, ano_escolar: int | None) -> int:
    if meta_config is not None:
        return meta_config
    return META_DEFAULT_POR_ANO.get(ano_escolar, META_DEFAULT)
