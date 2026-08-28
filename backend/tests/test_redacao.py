"""Redação B2C real — atribuição, envio, triagem de risco (Fase 4, docs/plano_b2c.md).

Usa um `Analisador` fake via `app.dependency_overrides` — nenhum teste aqui faz
chamada de rede nem depende de `OPENAI_API_KEY` (ver pendência registrada em
`app/redacao/analisador.py` sobre o `AnalisadorOpenAI` real nunca ter sido
exercitado contra a API de verdade).
"""
import pytest

from app.main import app
from app.redacao.analisador import (
    Ancora,
    AnotacaoAnalise,
    PalavraExtraida,
    ResultadoAnalise,
    get_analisador,
)
from app.seed_temas import seed_temas


class _AnalisadorFake:
    def __init__(self, resultado: ResultadoAnalise):
        self._resultado = resultado
        self.chamadas = []

    async def analisar(self, *, texto, faixa_etaria, tema):
        self.chamadas.append({"texto": texto, "faixa_etaria": faixa_etaria, "tema": tema})
        return self._resultado


def _usar_analisador(resultado: ResultadoAnalise) -> _AnalisadorFake:
    fake = _AnalisadorFake(resultado)
    app.dependency_overrides[get_analisador] = lambda: fake
    return fake


@pytest.fixture(autouse=True)
def _limpar_override():
    yield
    app.dependency_overrides.pop(get_analisador, None)


async def _criar_familia(client, *, ano_nascimento=2015, email="mae@teste.com"):
    """Responsável + 1 perfil de criança (faixa 11-12 p/ ano_nascimento=2015,
    dado o `currentDate` do ambiente de teste); devolve os headers de cada um."""
    cadastro = (
        await client.post(
            "/v1/conta",
            json={
                "nome": "Responsável",
                "email": email,
                "senha": "senha-forte-123",
                "aceite_termos": True,
                "consentimento_lgpd": True,
            },
        )
    ).json()
    h_responsavel = {"Authorization": f"Bearer {cadastro['token']}"}
    perfil = (
        await client.post(
            "/v1/conta/perfis",
            json={"apelido": "Criança", "ano_nascimento": ano_nascimento},
            headers=h_responsavel,
        )
    ).json()
    acesso = (
        await client.post(f"/v1/perfis/{perfil['usuario_id']}/entrar", headers=h_responsavel)
    ).json()
    h_aluno = {"Authorization": f"Bearer {acesso['token']}"}
    return h_responsavel, h_aluno, perfil["usuario_id"]


@pytest.mark.asyncio
async def test_atribuicao_automatica_nasce_na_primeira_consulta(client):
    await seed_temas()
    _, h_aluno, _ = await _criar_familia(client)

    r1 = (await client.get("/v1/redacoes", headers=h_aluno)).json()
    assert len(r1["itens"]) == 1
    assert r1["itens"][0]["origem"] == "automatica"
    assert r1["itens"][0]["redacao_id"] is None

    # Chamar de novo não duplica (última atribuição é recente).
    r2 = (await client.get("/v1/redacoes", headers=h_aluno)).json()
    assert len(r2["itens"]) == 1
    assert r2["itens"][0]["id"] == r1["itens"][0]["id"]


@pytest.mark.asyncio
async def test_sem_catalogo_para_a_faixa_nao_atribui_nada(client):
    # Sem seed_temas() — catálogo vazio.
    _, h_aluno, _ = await _criar_familia(client)
    r = (await client.get("/v1/redacoes", headers=h_aluno)).json()
    assert r["itens"] == []


@pytest.mark.asyncio
async def test_envio_curto_demais_e_rejeitado_sem_chamar_analisador(client):
    await seed_temas()
    _, h_aluno, _ = await _criar_familia(client)
    fake = _usar_analisador(ResultadoAnalise(risco_sinalizado=False, risco_motivo=None))

    atribuicoes = (await client.get("/v1/redacoes", headers=h_aluno)).json()["itens"]
    atribuicao_id = atribuicoes[0]["id"]

    resp = await client.post(
        f"/v1/redacoes/{atribuicao_id}/enviar",
        headers=h_aluno,
        json={"formato": "digital", "texto_extraido": "um texto bem curto"},
    )
    assert resp.status_code == 200
    assert resp.json()["status"] == "erro_ingestao"
    assert fake.chamadas == []  # nunca chegou a chamar a IA


@pytest.mark.asyncio
async def test_envio_normal_grava_analise_e_resolve_ancoras(client):
    await seed_temas()
    _, h_aluno, _ = await _criar_familia(client)
    resultado = ResultadoAnalise(
        risco_sinalizado=False,
        risco_motivo=None,
        pontos_fortes=["Bom começo"],
        anotacoes=[
            AnotacaoAnalise(
                dimensao="vocabulario",
                titulo='"legal" é uma palavra coringa',
                comentario="Tente uma palavra mais precisa.",
                sugestoes=["incrível"],
                ancoras=[],
            )
        ],
        palavras=[PalavraExtraida(texto="legal", lema="legal", tipo="fraca")],
    )
    resultado.anotacoes[0].ancoras.append(Ancora(trecho="legal", ocorrencia=1))
    _usar_analisador(resultado)

    atribuicao_id = (await client.get("/v1/redacoes", headers=h_aluno)).json()["itens"][0]["id"]
    # faixa 11-12 exige >= 120 palavras (RUBRICA) — texto propositalmente longo.
    texto = "Meu passeio foi muito legal e eu gostei bastante de tudo que vi na viagem em família. " * 8
    envio = (
        await client.post(
            f"/v1/redacoes/{atribuicao_id}/enviar",
            headers=h_aluno,
            json={"formato": "digital", "texto_extraido": texto},
        )
    ).json()
    assert envio["status"] == "analisada"

    analise = (await client.get(f"/v1/redacoes/{envio['redacao_id']}/analise", headers=h_aluno)).json()
    assert analise["status"] == "analisada"
    assert analise["analise"]["pontos_fortes"] == ["Bom começo"]
    ancora = analise["analise"]["anotacoes"][0]["ancoras"][0]
    assert texto[ancora["inicio"] : ancora["fim"]] == "legal"


@pytest.mark.asyncio
async def test_risco_sinalizado_vai_para_revisao_humana_sem_expor_analise(client):
    await seed_temas()
    _, h_aluno, _ = await _criar_familia(client)
    _usar_analisador(
        ResultadoAnalise(
            risco_sinalizado=True,
            risco_motivo="menção a agressão em casa",
            pontos_fortes=["não deveria aparecer"],
        )
    )

    atribuicao_id = (await client.get("/v1/redacoes", headers=h_aluno)).json()["itens"][0]["id"]
    # faixa 11-12 exige >= 120 palavras (RUBRICA).
    texto = " ".join(["uma", "redação", "qualquer", "com", "palavras"] * 25)
    envio = (
        await client.post(
            f"/v1/redacoes/{atribuicao_id}/enviar",
            headers=h_aluno,
            json={"formato": "digital", "texto_extraido": texto},
        )
    ).json()
    assert envio["status"] == "revisao_humana"

    analise = (await client.get(f"/v1/redacoes/{envio['redacao_id']}/analise", headers=h_aluno)).json()
    assert analise["status"] == "revisao_humana"
    assert analise["analise"] is None
    assert analise["texto_extraido"] == ""  # nunca reexpõe o texto de risco pela mesma rota


@pytest.mark.asyncio
async def test_tema_extra_respeita_a_cota_mensal(client):
    await seed_temas()
    h_responsavel, h_aluno, usuario_id = await _criar_familia(client)

    for _ in range(2):
        resp = await client.post(
            "/v1/redacoes/tema-extra",
            headers=h_responsavel,
            json={"perfil_usuario_id": usuario_id},
        )
        assert resp.status_code == 200

    esgotado = await client.post(
        "/v1/redacoes/tema-extra",
        headers=h_responsavel,
        json={"perfil_usuario_id": usuario_id},
    )
    assert esgotado.status_code == 429
    assert esgotado.json()["error"]["code"] == "limite_de_temas_extras"

    redacoes = (await client.get("/v1/redacoes", headers=h_aluno)).json()
    assert redacoes["extras_restantes_no_mes"] == 0


@pytest.mark.asyncio
async def test_tema_extra_exige_papel_responsavel(client):
    await seed_temas()
    _, h_aluno, usuario_id = await _criar_familia(client)
    resp = await client.post(
        "/v1/redacoes/tema-extra", headers=h_aluno, json={"perfil_usuario_id": usuario_id}
    )
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_responsavel_nao_pede_tema_extra_para_perfil_de_outra_conta(client):
    await seed_temas()
    h_responsavel_1, _, _ = await _criar_familia(client, ano_nascimento=2015, email="familia1@teste.com")
    _, _, usuario_id_2 = await _criar_familia(client, ano_nascimento=2016, email="familia2@teste.com")

    resp = await client.post(
        "/v1/redacoes/tema-extra",
        headers=h_responsavel_1,
        json={"perfil_usuario_id": usuario_id_2},
    )
    assert resp.status_code == 404
