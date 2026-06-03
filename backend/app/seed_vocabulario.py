"""Seed do banco base de vocabulário (fatia A).

Conteúdo curado à mão para a demo — palavras "ricas" que são alternativas a
termos comuns/superutilizados (eixo de dificuldade da seção 3.5: distância do
sinônimo comum). Cada palavra traz definição conversacional + exemplo + 2–3
sinônimos + as 8 questões (4 níveis × 2 variações), no formato da seção 3.1/3.4:

  Nível 1 — reconhecimento (significado)
  Nível 2 — sinônimo (associação em contexto)
  Nível 3 — aplicação (completar a frase)
  Nível 4 — avaliação (julgar o uso correto)

`opcoes` guarda as alternativas (JSONB); `resposta_correta` é o texto certo (e
sempre uma das alternativas — checado no carregamento). Idempotente por `lema`.

Em produção o banco base tem 500–800 palavras geradas+revisadas offline
(arquitetura, Bloco 3). Aqui é uma amostra representativa para exercitar sessão
e diagnóstico de ponta a ponta. Uso:

    python -m app.seed_vocabulario
"""
import asyncio

from sqlalchemy import insert, select

from app import schema
from app.db import engine

# Cada questão: (enunciado, [opcoes], resposta_correta). A 1ª opção é a correta
# por convenção de autoria; a ordem é embaralhada na entrega ao app (server-side).
PALAVRAS = [
    {
        "lema": "enorme",
        "definicao": "de tamanho muito grande",
        "exemplo_uso": "Vimos um navio enorme chegar ao porto.",
        "nivel_dificuldade": 2,
        "sinonimos": ["imenso", "gigantesco"],
        "questoes": {
            1: [
                ("O que a palavra «enorme» quer dizer?",
                 ["Muito grande", "Muito rápido", "Muito antigo", "Muito barato"]),
                ("«Enorme» é o mesmo que...",
                 ["de tamanho muito grande", "de cor escura", "de som alto", "de gosto doce"]),
            ],
            2: [
                ("Na frase «Vimos um prédio enorme», qual palavra pode substituir «enorme»?",
                 ["imenso", "rápido", "frio", "barato"]),
                ("Qual é um sinônimo de «enorme»?",
                 ["gigantesco", "pequeno", "leve", "calmo"]),
            ],
            3: [
                ("Complete: «O elefante é um animal ___, bem maior que o cavalo.»",
                 ["enorme", "rápido", "antigo", "barato"]),
                ("Complete: «A festa foi num salão ___, com espaço para mil pessoas.»",
                 ["enorme", "estreito", "silencioso", "barato"]),
            ],
            4: [
                ("Em qual frase «enorme» foi usada corretamente?",
                 ["O estádio era enorme e cabia muita gente.",
                  "O café estava enorme de tão quente.",
                  "Ela falou de modo enorme e gentil.",
                  "O carro andava enorme pela estrada."]),
                ("Em qual frase «enorme» faz sentido?",
                 ["A montanha enorme dominava a paisagem.",
                  "O suco estava enorme de gelado.",
                  "Ele sorriu de forma enorme e rápida.",
                  "O teste foi enorme de fácil."]),
            ],
        },
    },
    {
        "lema": "veloz",
        "definicao": "que se move com muita velocidade, muito rápido",
        "exemplo_uso": "O guepardo é o animal mais veloz da savana.",
        "nivel_dificuldade": 2,
        "sinonimos": ["rápido", "ligeiro"],
        "questoes": {
            1: [
                ("O que significa «veloz»?",
                 ["Que se move muito rápido", "Que é muito grande", "Que é muito caro", "Que é muito velho"]),
                ("«Veloz» quer dizer...",
                 ["que tem muita velocidade", "que tem muita cor", "que tem muito peso", "que tem muito som"]),
            ],
            2: [
                ("Na frase «O guepardo é veloz», qual palavra pode substituir «veloz»?",
                 ["rápido", "enorme", "caro", "escuro"]),
                ("Qual é um sinônimo de «veloz»?",
                 ["ligeiro", "lento", "pesado", "quieto"]),
            ],
            3: [
                ("Complete: «O trem-bala é muito ___ e cruza o país em poucas horas.»",
                 ["veloz", "antigo", "barato", "estreito"]),
                ("Complete: «Com passos ___, ela chegou antes de todos.»",
                 ["velozes", "lentos", "pesados", "quietos"]),
            ],
            4: [
                ("Em qual frase «veloz» foi usada corretamente?",
                 ["O corredor veloz venceu a prova.",
                  "O bolo estava veloz e gostoso.",
                  "A casa era veloz e grande.",
                  "O livro ficou veloz de longo."]),
                ("Em qual frase «veloz» faz sentido?",
                 ["A moto veloz passou pela avenida.",
                  "O dia estava veloz de ensolarado.",
                  "O suco era veloz de doce.",
                  "A parede ficou veloz de branca."]),
            ],
        },
    },
    {
        "lema": "belo",
        "definicao": "que agrada aos olhos, bonito",
        "exemplo_uso": "O pôr do sol estava belo, cheio de cores.",
        "nivel_dificuldade": 3,
        "sinonimos": ["bonito", "formoso"],
        "questoes": {
            1: [
                ("O que significa «belo»?",
                 ["Que é muito bonito", "Que é muito rápido", "Que é muito caro", "Que é muito alto"]),
                ("«Belo» é o mesmo que...",
                 ["que agrada aos olhos, bonito", "que faz muito barulho", "que custa muito dinheiro", "que pesa bastante"]),
            ],
            2: [
                ("Na frase «Que belo jardim!», qual palavra pode substituir «belo»?",
                 ["bonito", "rápido", "caro", "frio"]),
                ("Qual é um sinônimo de «belo»?",
                 ["formoso", "feio", "lento", "pesado"]),
            ],
            3: [
                ("Complete: «O pôr do sol estava ___, com várias cores no céu.»",
                 ["belo", "rápido", "barato", "estreito"]),
                ("Complete: «Ela pintou um quadro tão ___ que todos elogiaram.»",
                 ["belo", "veloz", "antigo", "barato"]),
            ],
            4: [
                ("Em qual frase «belo» foi usada corretamente?",
                 ["Fizemos um belo passeio pela praia.",
                  "O suco estava belo de gelado.",
                  "O carro corria belo na pista.",
                  "A prova foi bela de difícil."]),
                ("Em qual frase «belo» faz sentido?",
                 ["A cidade tinha um belo centro histórico.",
                  "O café estava belo de quente.",
                  "Ele correu belo até em casa.",
                  "O teste ficou belo de longo."]),
            ],
        },
    },
    {
        "lema": "relevante",
        "definicao": "que tem importância, que faz diferença numa situação",
        "exemplo_uso": "A professora destacou o ponto mais relevante da aula.",
        "nivel_dificuldade": 4,
        "sinonimos": ["importante", "significativo", "essencial"],
        "questoes": {
            1: [
                ("O que significa «relevante»?",
                 ["Que tem importância, que faz diferença", "Que tem muita cor", "Que tem muito peso", "Que tem muita pressa"]),
                ("«Relevante» quer dizer...",
                 ["que importa numa situação", "que está em silêncio", "que é muito antigo", "que se move devagar"]),
            ],
            2: [
                ("Na frase «Foi uma descoberta relevante», qual palavra pode substituir «relevante»?",
                 ["importante", "colorida", "barulhenta", "distante"]),
                ("Qual é um sinônimo de «relevante»?",
                 ["significativo", "insignificante", "silencioso", "veloz"]),
            ],
            3: [
                ("Complete: «O professor explicou um ponto muito ___ para a prova.»",
                 ["relevante", "molhado", "redondo", "barato"]),
                ("Complete: «A reunião tratou de assuntos ___ para a escola toda.»",
                 ["relevantes", "coloridos", "silenciosos", "velozes"]),
            ],
            4: [
                ("Em qual frase «relevante» foi usada corretamente?",
                 ["A informação era relevante para entender a história.",
                  "O bolo estava relevante de doce.",
                  "Ele correu de modo relevante até a escola.",
                  "A camiseta era relevante de azul."]),
                ("Em qual frase «relevante» faz sentido?",
                 ["O exame trouxe um dado relevante sobre o clima.",
                  "O suco estava relevante de gelado.",
                  "A casa era relevante de grande.",
                  "O dia ficou relevante de ensolarado."]),
            ],
        },
    },
    {
        "lema": "árduo",
        "definicao": "que exige muito esforço, difícil e trabalhoso",
        "exemplo_uso": "O treino foi árduo, mas todos aguentaram até o fim.",
        "nivel_dificuldade": 5,
        "sinonimos": ["difícil", "trabalhoso", "cansativo"],
        "questoes": {
            1: [
                ("O que significa «árduo»?",
                 ["Que exige muito esforço, difícil", "Que é muito bonito", "Que é muito rápido", "Que é muito barato"]),
                ("«Árduo» é o mesmo que...",
                 ["trabalhoso e cansativo", "colorido e alegre", "leve e simples", "doce e gostoso"]),
            ],
            2: [
                ("Na frase «Foi um trabalho árduo», qual palavra pode substituir «árduo»?",
                 ["difícil", "fácil", "colorido", "rápido"]),
                ("Qual é um sinônimo de «árduo»?",
                 ["trabalhoso", "simples", "leve", "veloz"]),
            ],
            3: [
                ("Complete: «Subir a montanha foi um desafio ___, que exigiu muito esforço.»",
                 ["árduo", "fácil", "colorido", "barato"]),
                ("Complete: «Depois de um treino ___, os atletas descansaram bastante.»",
                 ["árduo", "simples", "barato", "colorido"]),
            ],
            4: [
                ("Em qual frase «árduo» foi usada corretamente?",
                 ["O estudo para o concurso foi árduo, mas valeu a pena.",
                  "O sorvete estava árduo de gelado.",
                  "O quarto ficou árduo de arrumado.",
                  "A música era árdua de animada."]),
                ("Em qual frase «árduo» faz sentido?",
                 ["Foi um caminho árduo até conseguir o emprego.",
                  "O café estava árduo de quente.",
                  "O carro era árduo de veloz.",
                  "O dia ficou árduo de bonito."]),
            ],
        },
    },
    {
        "lema": "íntegro",
        "definicao": "que é honesto e age com caráter, sempre correto",
        "exemplo_uso": "Um cidadão íntegro devolveu a carteira que achou na rua.",
        "nivel_dificuldade": 5,
        "sinonimos": ["honesto", "correto", "justo"],
        "questoes": {
            1: [
                ("O que significa «íntegro»?",
                 ["Que é honesto e tem caráter", "Que é muito grande", "Que é muito rápido", "Que é muito antigo"]),
                ("«Íntegro» quer dizer...",
                 ["pessoa correta e honesta", "pessoa muito veloz", "pessoa muito alta", "pessoa muito rica"]),
            ],
            2: [
                ("Na frase «Ele é um juiz íntegro», qual palavra pode substituir «íntegro»?",
                 ["honesto", "veloz", "alto", "rico"]),
                ("Qual é um sinônimo de «íntegro»?",
                 ["correto", "desonesto", "lento", "pesado"]),
            ],
            3: [
                ("Complete: «Um funcionário ___ recusou o dinheiro oferecido por fora.»",
                 ["íntegro", "veloz", "enorme", "barato"]),
                ("Complete: «A empresa procura um gerente ___, que nunca minta aos clientes.»",
                 ["íntegro", "veloz", "colorido", "antigo"]),
            ],
            4: [
                ("Em qual frase «íntegro» foi usada corretamente?",
                 ["O funcionário íntegro recusou a propina.",
                  "O suco estava íntegro de doce.",
                  "O carro era íntegro de rápido.",
                  "A casa ficou íntegra de grande."]),
                ("Em qual frase «íntegro» faz sentido?",
                 ["Por ser íntegro, ele contou toda a verdade.",
                  "O bolo estava íntegro de gostoso.",
                  "O atleta era íntegro de veloz.",
                  "O dia ficou íntegro de ensolarado."]),
            ],
        },
    },
    {
        "lema": "meticuloso",
        "definicao": "que cuida de cada detalhe com muita atenção",
        "exemplo_uso": "O relojoeiro meticuloso montou cada peça com calma.",
        "nivel_dificuldade": 6,
        "sinonimos": ["cuidadoso", "detalhista", "caprichoso"],
        "questoes": {
            1: [
                ("O que significa «meticuloso»?",
                 ["Que cuida de cada detalhe com atenção", "Que é muito rápido", "Que é muito grande", "Que é muito barato"]),
                ("«Meticuloso» é o mesmo que...",
                 ["caprichoso e detalhista", "apressado e distraído", "leve e simples", "doce e colorido"]),
            ],
            2: [
                ("Na frase «É um pintor meticuloso», qual palavra pode substituir «meticuloso»?",
                 ["cuidadoso", "apressado", "veloz", "barato"]),
                ("Qual é um sinônimo de «meticuloso»?",
                 ["detalhista", "descuidado", "veloz", "enorme"]),
            ],
            3: [
                ("Complete: «O cientista é ___ e anota cada resultado com cuidado.»",
                 ["meticuloso", "apressado", "barato", "colorido"]),
                ("Complete: «Com um trabalho ___, ela revisou cada página do relatório.»",
                 ["meticuloso", "apressado", "veloz", "barato"]),
            ],
            4: [
                ("Em qual frase «meticuloso» foi usada corretamente?",
                 ["O relojoeiro meticuloso montou cada peça com calma.",
                  "O suco estava meticuloso de gelado.",
                  "O carro era meticuloso de veloz.",
                  "A casa ficou meticulosa de grande."]),
                ("Em qual frase «meticuloso» faz sentido?",
                 ["Por ser meticuloso, conferiu todas as contas duas vezes.",
                  "O café estava meticuloso de quente.",
                  "O dia ficou meticuloso de bonito.",
                  "O atleta era meticuloso de rápido."]),
            ],
        },
    },
    {
        "lema": "perspicaz",
        "definicao": "que percebe as coisas com rapidez e esperteza",
        "exemplo_uso": "A detetive perspicaz notou a pista que ninguém viu.",
        "nivel_dificuldade": 7,
        "sinonimos": ["astuto", "sagaz", "observador"],
        "questoes": {
            1: [
                ("O que significa «perspicaz»?",
                 ["Que percebe as coisas com rapidez e esperteza", "Que é muito grande", "Que é muito antigo", "Que é muito barato"]),
                ("«Perspicaz» quer dizer...",
                 ["esperto e observador", "lento e distraído", "leve e simples", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Uma detetive perspicaz», qual palavra pode substituir «perspicaz»?",
                 ["esperta", "distraída", "lenta", "pesada"]),
                ("Qual é um sinônimo de «perspicaz»?",
                 ["astuto", "distraído", "lento", "enorme"]),
            ],
            3: [
                ("Complete: «O aluno ___ percebeu o erro antes de todos.»",
                 ["perspicaz", "distraído", "barato", "colorido"]),
                ("Complete: «Com um olhar ___, ela notou o detalhe que faltava.»",
                 ["perspicaz", "distraído", "lento", "barato"]),
            ],
            4: [
                ("Em qual frase «perspicaz» foi usada corretamente?",
                 ["O investigador perspicaz descobriu a pista escondida.",
                  "O suco estava perspicaz de doce.",
                  "O carro era perspicaz de veloz.",
                  "A casa ficou perspicaz de grande."]),
                ("Em qual frase «perspicaz» faz sentido?",
                 ["Por ser perspicaz, resolveu o enigma rapidamente.",
                  "O bolo estava perspicaz de gostoso.",
                  "O dia ficou perspicaz de ensolarado.",
                  "O atleta era perspicaz de rápido."]),
            ],
        },
    },
]


def _validar(palavra: dict) -> None:
    """Falha cedo se a autoria estiver inconsistente (resposta fora das opções etc.)."""
    for nivel, variacoes in palavra["questoes"].items():
        assert 1 <= nivel <= 4, f"{palavra['lema']}: nível inválido {nivel}"
        assert len(variacoes) >= 2, f"{palavra['lema']} N{nivel}: precisa de ≥2 variações"
        for enunciado, opcoes in variacoes:
            assert len(opcoes) == len(set(opcoes)), f"{palavra['lema']}: opções repetidas em «{enunciado}»"
            # convenção: 1ª opção é a correta — precisa estar na lista (trivialmente) e ser única.
            assert opcoes[0] in opcoes


async def seed_vocabulario() -> dict:
    for p in PALAVRAS:
        _validar(p)

    inseridas = 0
    total_questoes = 0
    async with engine.begin() as conn:
        for p in PALAVRAS:
            existe = (
                await conn.execute(
                    select(schema.palavra.c.id).where(schema.palavra.c.lema == p["lema"])
                )
            ).scalar_one_or_none()
            if existe is not None:
                continue

            palavra_id = (
                await conn.execute(
                    insert(schema.palavra)
                    .values(
                        lema=p["lema"],
                        definicao=p["definicao"],
                        exemplo_uso=p["exemplo_uso"],
                        nivel_dificuldade=p["nivel_dificuldade"],
                        origem="banco_base",
                    )
                    .returning(schema.palavra.c.id)
                )
            ).scalar_one()

            for texto in p["sinonimos"]:
                await conn.execute(
                    insert(schema.palavra_sinonimo).values(palavra_id=palavra_id, texto=texto)
                )

            for nivel, variacoes in p["questoes"].items():
                for indice, (enunciado, opcoes) in enumerate(variacoes):
                    await conn.execute(
                        insert(schema.questao).values(
                            palavra_id=palavra_id,
                            nivel=nivel,
                            variacao=chr(ord("a") + indice),  # a, b, …
                            enunciado=enunciado,
                            opcoes=opcoes,
                            resposta_correta=opcoes[0],  # 1ª opção é a correta (autoria)
                        )
                    )
                    total_questoes += 1
            inseridas += 1

    return {"palavras_inseridas": inseridas, "questoes_inseridas": total_questoes}


if __name__ == "__main__":
    print("seed vocabulário:", asyncio.run(seed_vocabulario()))
