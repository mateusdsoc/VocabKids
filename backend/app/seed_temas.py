"""Seed do catálogo de temas de redação (Fase 4, `docs/plano_b2c.md` §10.4).

⚠️ **Catálogo PARCIAL, não o final.** O plano pede 120 temas (40 por faixa,
curados como o vocabulário — §10.1 passo 5: revisão humana obrigatória,
inclusive gerado por IA). Este arquivo tem só **6 temas por faixa** (18 no
total), o suficiente para a rotação quinzenal não repetir nos primeiros ~3
meses e para o pipeline de `app/redacao/` ter o que atribuir em dev/teste.
Os 102 temas restantes são trabalho de conteúdo pendente — ver
`design/notas-implementacao.md` (Fase 4, 25/08).

Idempotente por `titulo` — mesmo padrão de `seed_vocabulario.py`. Uso:

    python -m app.seed_temas
"""
import asyncio

from sqlalchemy import insert, select

from app import schema
from app.db import engine

TEMAS = [
    # ─────────────────────────────── 7-8 ───────────────────────────────
    {
        "faixa_etaria": "7-8",
        "titulo": "Meu animal favorito",
        "enunciado": "Conte para a gente qual é o seu animal favorito e por quê.",
        "genero": "descritiva",
        "apoio": ["Como ele é?", "Onde ele vive?", "O que você mais gosta nele?"],
    },
    {
        "faixa_etaria": "7-8",
        "titulo": "Um dia diferente",
        "enunciado": "Imagine que você acordou e podia voar por um dia. O que você faria?",
        "genero": "narrativa",
        "apoio": ["Pra onde você voaria primeiro?", "Quem você mostraria isso?"],
    },
    {
        "faixa_etaria": "7-8",
        "titulo": "Minha comida preferida",
        "enunciado": "Qual é a sua comida preferida? Descreva o gosto, o cheiro e quando você come ela.",
        "genero": "descritiva",
        "apoio": ["Quem faz essa comida pra você?", "Em que ocasião você come ela?"],
    },
    {
        "faixa_etaria": "7-8",
        "titulo": "Carta para um amigo",
        "enunciado": "Escreva uma carta contando uma novidade para um amigo ou amiga.",
        "genero": "carta",
        "apoio": ["O que aconteceu?", "Por que essa novidade é importante pra você?"],
    },
    {
        "faixa_etaria": "7-8",
        "titulo": "Se eu tivesse um superpoder",
        "enunciado": "Se você pudesse ter um superpoder, qual seria? O que você faria com ele?",
        "genero": "opinativa",
        "apoio": ["Por que esse poder e não outro?", "Você usaria pra ajudar alguém?"],
    },
    {
        "faixa_etaria": "7-8",
        "titulo": "Minhas férias dos sonhos",
        "enunciado": "Se você pudesse viajar pra qualquer lugar, pra onde iria? Conte como seria essa viagem.",
        "genero": "narrativa",
        "apoio": ["Com quem você iria?", "O que você faria lá?"],
    },
    # ─────────────────────────────── 9-10 ───────────────────────────────
    {
        "faixa_etaria": "9-10",
        "titulo": "Um herói brasileiro",
        "enunciado": "Escolha uma pessoa que você considera um herói brasileiro (real ou de história) e explique por quê.",
        "genero": "opinativa",
        "apoio": ["O que essa pessoa fez de importante?", "O que você aprende com ela?"],
    },
    {
        "faixa_etaria": "9-10",
        "titulo": "Se eu pudesse mudar o mundo",
        "enunciado": "Se você pudesse mudar uma coisa no mundo, o que seria e como você faria isso?",
        "genero": "opinativa",
        "apoio": ["Por que isso é importante?", "Quem mais seria ajudado com essa mudança?"],
    },
    {
        "faixa_etaria": "9-10",
        "titulo": "Um dia na vida de...",
        "enunciado": "Escolha um animal, objeto ou personagem e conte como seria um dia inteiro na vida dele.",
        "genero": "narrativa",
        "apoio": ["O que ele faz de manhã, tarde e noite?", "O que é mais difícil no dia dele?"],
    },
    {
        "faixa_etaria": "9-10",
        "titulo": "Uma invenção incrível",
        "enunciado": "Invente um objeto que ainda não existe e explique para que ele serve e como funciona.",
        "genero": "descritiva",
        "apoio": ["Que problema ele resolve?", "Quem usaria essa invenção?"],
    },
    {
        "faixa_etaria": "9-10",
        "titulo": "Carta para o meu eu do futuro",
        "enunciado": "Escreva uma carta para você mesmo, para ler daqui a 5 anos.",
        "genero": "carta",
        "apoio": ["O que você quer lembrar de hoje?", "O que você espera ter conquistado?"],
    },
    {
        "faixa_etaria": "9-10",
        "titulo": "A cidade que eu queria visitar",
        "enunciado": "Escolha uma cidade do mundo que você tem curiosidade de conhecer e explique por quê.",
        "genero": "descritiva",
        "apoio": ["O que você já ouviu falar dela?", "O que você faria no primeiro dia lá?"],
    },
    # ─────────────────────────────── 11-12 ───────────────────────────────
    {
        "faixa_etaria": "11-12",
        "titulo": "Tecnologia: amiga ou vilã?",
        "enunciado": "Na sua opinião, a tecnologia ajuda ou atrapalha mais a vida das crianças hoje? Justifique.",
        "genero": "opinativa",
        "apoio": ["Dê um exemplo real.", "Existe um jeito de equilibrar isso?"],
    },
    {
        "faixa_etaria": "11-12",
        "titulo": "Uma decisão difícil",
        "enunciado": "Conte sobre uma vez em que você (ou um personagem inventado) teve que tomar uma decisão difícil.",
        "genero": "narrativa",
        "apoio": ["O que estava em jogo?", "O que você aprendeu com essa decisão?"],
    },
    {
        "faixa_etaria": "11-12",
        "titulo": "O planeta daqui a 50 anos",
        "enunciado": "Como você imagina que o planeta vai estar daqui a 50 anos? O que precisa mudar desde já?",
        "genero": "opinativa",
        "apoio": ["Cite um problema ambiental específico.", "O que cada pessoa pode fazer?"],
    },
    {
        "faixa_etaria": "11-12",
        "titulo": "Carta para quem vai liderar o país",
        "enunciado": "Escreva uma carta para um futuro presidente com 3 pedidos que você considera importantes.",
        "genero": "carta",
        "apoio": ["Por que esses pedidos e não outros?", "Quem seria beneficiado?"],
    },
    {
        "faixa_etaria": "11-12",
        "titulo": "Um livro (ou filme) que mudou como eu penso",
        "enunciado": "Fale sobre um livro, filme ou série que te fez pensar diferente sobre algo.",
        "genero": "opinativa",
        "apoio": ["O que exatamente mudou na sua forma de pensar?", "Você recomendaria pra alguém?"],
    },
    {
        "faixa_etaria": "11-12",
        "titulo": "Se eu governasse minha escola por um dia",
        "enunciado": "Se você fosse diretor(a) da sua escola por um dia, o que você mudaria e por quê?",
        "genero": "opinativa",
        "apoio": ["Que problema você resolveria primeiro?", "Como os outros alunos reagiriam?"],
    },
]


async def seed_temas() -> dict:
    inseridos = 0
    async with engine.begin() as conn:
        for t in TEMAS:
            existe = (
                await conn.execute(
                    select(schema.tema_catalogo.c.id).where(schema.tema_catalogo.c.titulo == t["titulo"])
                )
            ).scalar_one_or_none()
            if existe is not None:
                continue
            await conn.execute(
                insert(schema.tema_catalogo).values(
                    faixa_etaria=t["faixa_etaria"],
                    titulo=t["titulo"],
                    enunciado=t["enunciado"],
                    genero=t["genero"],
                    apoio=t["apoio"],
                )
            )
            inseridos += 1
    return {"temas_inseridos": inseridos}


if __name__ == "__main__":
    print("seed temas de redação:", asyncio.run(seed_temas()))
