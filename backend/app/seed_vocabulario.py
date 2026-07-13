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
(arquitetura, Bloco 3). Aqui são 37 palavras curadas cobrindo os níveis 1–10
(3–4 por nível) — runway suficiente para várias sessões e um diagnóstico que
exercita a escada inteira, sem esgotar o vocabulário novo na 2ª sessão.

Reprodutível entre máquinas: o banco base vive **neste arquivo versionado** e o
seed é **idempotente por `lema`** — um `git pull` + `python -m
app.seed_vocabulario` gera o mesmo vocabulário no notebook e no desktop, e
rodar de novo não duplica nada (o progresso do aluno é por banco, não sincroniza
entre máquinas — isso é esperado). Uso:

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
    # ─────────────────────────── Nível 1 (piso) ───────────────────────────
    {
        "lema": "gentil",
        "definicao": "que trata os outros com educação e carinho",
        "exemplo_uso": "A vizinha gentil sempre ajuda quem precisa.",
        "nivel_dificuldade": 1,
        "sinonimos": ["educado", "cortês", "amável"],
        "questoes": {
            1: [
                ("O que significa «gentil»?",
                 ["Que trata os outros com educação e carinho", "Que corre muito rápido", "Que é muito grande", "Que custa muito caro"]),
                ("«Gentil» é o mesmo que...",
                 ["educado e amável", "veloz e apressado", "enorme e pesado", "escuro e frio"]),
            ],
            2: [
                ("Na frase «Que menino gentil!», qual palavra pode substituir «gentil»?",
                 ["educado", "apressado", "enorme", "veloz"]),
                ("Qual é um sinônimo de «gentil»?",
                 ["cortês", "grosseiro", "veloz", "pesado"]),
            ],
            3: [
                ("Complete: «Ela foi muito ___ e ajudou a senhora a atravessar a rua.»",
                 ["gentil", "veloz", "enorme", "barata"]),
                ("Complete: «Com um gesto ___, ele ofereceu o lugar para o idoso.»",
                 ["gentil", "apressado", "pesado", "escuro"]),
            ],
            4: [
                ("Em qual frase «gentil» foi usada corretamente?",
                 ["O garçom gentil nos atendeu com um sorriso.",
                  "O suco estava gentil de gelado.",
                  "O carro era gentil de rápido.",
                  "A casa ficou gentil de grande."]),
                ("Em qual frase «gentil» faz sentido?",
                 ["Ela deu uma resposta gentil e educada.",
                  "O café estava gentil de quente.",
                  "O dia ficou gentil de ensolarado.",
                  "O atleta era gentil de veloz."]),
            ],
        },
    },
    {
        "lema": "esperto",
        "definicao": "que aprende e entende as coisas com facilidade",
        "exemplo_uso": "O cachorro esperto aprendeu o truque em poucos minutos.",
        "nivel_dificuldade": 1,
        "sinonimos": ["inteligente", "atento", "vivo"],
        "questoes": {
            1: [
                ("O que significa «esperto»?",
                 ["Que aprende e entende com facilidade", "Que é muito grande", "Que é muito caro", "Que é muito antigo"]),
                ("«Esperto» quer dizer...",
                 ["inteligente e atento", "lento e distraído", "enorme e pesado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Um aluno esperto», qual palavra pode substituir «esperto»?",
                 ["inteligente", "distraído", "lento", "pesado"]),
                ("Qual é um sinônimo de «esperto»?",
                 ["atento", "distraído", "lento", "enorme"]),
            ],
            3: [
                ("Complete: «O menino ___ resolveu a charada antes de todos.»",
                 ["esperto", "lento", "enorme", "barato"]),
                ("Complete: «Com uma ideia ___, ela achou um jeito mais fácil de fazer.»",
                 ["esperta", "distraída", "pesada", "barata"]),
            ],
            4: [
                ("Em qual frase «esperto» foi usada corretamente?",
                 ["O aluno esperto entendeu a matéria rapidinho.",
                  "O suco estava esperto de doce.",
                  "O carro era esperto de veloz.",
                  "A casa ficou esperta de grande."]),
                ("Em qual frase «esperto» faz sentido?",
                 ["Por ser esperto, ele achou a solução na hora.",
                  "O café estava esperto de quente.",
                  "O dia ficou esperto de bonito.",
                  "A parede era esperta de branca."]),
            ],
        },
    },
    {
        "lema": "calmo",
        "definicao": "que fica tranquilo, sem pressa nem agitação",
        "exemplo_uso": "O mar estava calmo, sem nenhuma onda forte.",
        "nivel_dificuldade": 1,
        "sinonimos": ["tranquilo", "sereno", "sossegado"],
        "questoes": {
            1: [
                ("O que significa «calmo»?",
                 ["Que fica tranquilo, sem agitação", "Que é muito rápido", "Que é muito grande", "Que é muito caro"]),
                ("«Calmo» é o mesmo que...",
                 ["tranquilo e sossegado", "veloz e apressado", "enorme e pesado", "escuro e frio"]),
            ],
            2: [
                ("Na frase «O lago estava calmo», qual palavra pode substituir «calmo»?",
                 ["tranquilo", "agitado", "veloz", "enorme"]),
                ("Qual é um sinônimo de «calmo»?",
                 ["sereno", "agitado", "veloz", "pesado"]),
            ],
            3: [
                ("Complete: «Depois da tempestade, o tempo ficou ___ e silencioso.»",
                 ["calmo", "veloz", "enorme", "barato"]),
                ("Complete: «Ela falou de forma ___, sem se apressar nem gritar.»",
                 ["calma", "apressada", "pesada", "barata"]),
            ],
            4: [
                ("Em qual frase «calmo» foi usada corretamente?",
                 ["O paciente ficou calmo depois de respirar fundo.",
                  "O suco estava calmo de gelado.",
                  "O carro era calmo de veloz.",
                  "A casa ficou calma de grande."]),
                ("Em qual frase «calmo» faz sentido?",
                 ["O rio seguia calmo entre as pedras.",
                  "O café estava calmo de quente.",
                  "O dia ficou calmo de ensolarado.",
                  "O atleta era calmo de rápido."]),
            ],
        },
    },
    # ─────────────────────────────── Nível 2 ───────────────────────────────
    {
        "lema": "corajoso",
        "definicao": "que enfrenta o medo e o perigo sem fugir",
        "exemplo_uso": "O bombeiro corajoso entrou nas chamas para salvar o gato.",
        "nivel_dificuldade": 2,
        "sinonimos": ["valente", "destemido", "bravo"],
        "questoes": {
            1: [
                ("O que significa «corajoso»?",
                 ["Que enfrenta o medo e o perigo", "Que é muito grande", "Que é muito rápido", "Que é muito caro"]),
                ("«Corajoso» quer dizer...",
                 ["valente e destemido", "lento e medroso", "enorme e pesado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Um herói corajoso», qual palavra pode substituir «corajoso»?",
                 ["valente", "medroso", "lento", "pesado"]),
                ("Qual é um sinônimo de «corajoso»?",
                 ["destemido", "medroso", "lento", "enorme"]),
            ],
            3: [
                ("Complete: «O menino ___ enfrentou o cachorro bravo para proteger a irmã.»",
                 ["corajoso", "medroso", "enorme", "barato"]),
                ("Complete: «Foi preciso um ato ___ para saltar daquela altura.»",
                 ["corajoso", "medroso", "pesado", "barato"]),
            ],
            4: [
                ("Em qual frase «corajoso» foi usada corretamente?",
                 ["O soldado corajoso defendeu a ponte sozinho.",
                  "O suco estava corajoso de gelado.",
                  "O carro era corajoso de veloz.",
                  "A casa ficou corajosa de grande."]),
                ("Em qual frase «corajoso» faz sentido?",
                 ["Por ser corajosa, ela subiu no palco sem medo.",
                  "O café estava corajoso de quente.",
                  "O dia ficou corajoso de bonito.",
                  "A parede era corajosa de branca."]),
            ],
        },
    },
    {
        "lema": "curioso",
        "definicao": "que quer saber e descobrir como as coisas funcionam",
        "exemplo_uso": "A criança curiosa perguntava o nome de cada planta.",
        "nivel_dificuldade": 2,
        "sinonimos": ["interessado", "atento", "indagador"],
        "questoes": {
            1: [
                ("O que significa «curioso»?",
                 ["Que quer saber e descobrir as coisas", "Que é muito grande", "Que é muito rápido", "Que é muito caro"]),
                ("«Curioso» é o mesmo que...",
                 ["interessado em descobrir", "distraído e sem interesse", "enorme e pesado", "escuro e frio"]),
            ],
            2: [
                ("Na frase «Um aluno curioso», qual palavra pode substituir «curioso»?",
                 ["interessado", "distraído", "lento", "pesado"]),
                ("Qual é um sinônimo de «curioso»?",
                 ["indagador", "distraído", "lento", "enorme"]),
            ],
            3: [
                ("Complete: «O menino ___ abriu o rádio só para ver como funcionava.»",
                 ["curioso", "distraído", "enorme", "barato"]),
                ("Complete: «Com um olhar ___, ela examinou cada detalhe do inseto.»",
                 ["curioso", "distraído", "pesado", "barato"]),
            ],
            4: [
                ("Em qual frase «curioso» foi usada corretamente?",
                 ["O cientista curioso investigou o fenômeno estranho.",
                  "O suco estava curioso de gelado.",
                  "O carro era curioso de veloz.",
                  "A casa ficou curiosa de grande."]),
                ("Em qual frase «curioso» faz sentido?",
                 ["Por ser curiosa, ela leu tudo sobre o assunto.",
                  "O café estava curioso de quente.",
                  "O dia ficou curioso de ensolarado.",
                  "O atleta era curioso de rápido."]),
            ],
        },
    },
    # ─────────────────────────────── Nível 3 ───────────────────────────────
    {
        "lema": "frágil",
        "definicao": "que se quebra ou se machuca com facilidade",
        "exemplo_uso": "A taça de vidro é frágil e pode trincar num toque.",
        "nivel_dificuldade": 3,
        "sinonimos": ["delicado", "quebradiço", "sensível"],
        "questoes": {
            1: [
                ("O que significa «frágil»?",
                 ["Que se quebra com facilidade", "Que é muito rápido", "Que é muito caro", "Que é muito antigo"]),
                ("«Frágil» quer dizer...",
                 ["delicado e quebradiço", "forte e resistente", "veloz e apressado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Um vaso frágil», qual palavra pode substituir «frágil»?",
                 ["delicado", "resistente", "veloz", "enorme"]),
                ("Qual é um sinônimo de «frágil»?",
                 ["quebradiço", "resistente", "veloz", "pesado"]),
            ],
            3: [
                ("Complete: «Cuidado com a caixa: o conteúdo é ___ e quebra fácil.»",
                 ["frágil", "resistente", "enorme", "barato"]),
                ("Complete: «A ponte estava tão ___ que balançava com o vento.»",
                 ["frágil", "resistente", "pesada", "barata"]),
            ],
            4: [
                ("Em qual frase «frágil» foi usada corretamente?",
                 ["O enfeite frágil se partiu ao cair no chão.",
                  "O suco estava frágil de gelado.",
                  "O carro era frágil de veloz.",
                  "A casa ficou frágil de grande."]),
                ("Em qual frase «frágil» faz sentido?",
                 ["A asa da borboleta é frágil e fina.",
                  "O café estava frágil de quente.",
                  "O dia ficou frágil de ensolarado.",
                  "O atleta era frágil de rápido."]),
            ],
        },
    },
    {
        "lema": "generoso",
        "definicao": "que gosta de dar e ajudar sem esperar nada em troca",
        "exemplo_uso": "O padeiro generoso doava o pão que sobrava aos vizinhos.",
        "nivel_dificuldade": 3,
        "sinonimos": ["bondoso", "caridoso", "altruísta"],
        "questoes": {
            1: [
                ("O que significa «generoso»?",
                 ["Que gosta de dar e ajudar os outros", "Que é muito rápido", "Que é muito grande", "Que é muito antigo"]),
                ("«Generoso» é o mesmo que...",
                 ["bondoso e caridoso", "egoísta e mesquinho", "veloz e apressado", "escuro e frio"]),
            ],
            2: [
                ("Na frase «Um homem generoso», qual palavra pode substituir «generoso»?",
                 ["bondoso", "egoísta", "veloz", "enorme"]),
                ("Qual é um sinônimo de «generoso»?",
                 ["caridoso", "egoísta", "veloz", "pesado"]),
            ],
            3: [
                ("Complete: «O menino ___ dividiu o lanche com o colega que esqueceu o dele.»",
                 ["generoso", "egoísta", "enorme", "barato"]),
                ("Complete: «Com um gesto ___, ela doou os brinquedos para o abrigo.»",
                 ["generoso", "egoísta", "pesado", "barato"]),
            ],
            4: [
                ("Em qual frase «generoso» foi usada corretamente?",
                 ["O doador generoso ajudou várias famílias.",
                  "O suco estava generoso de gelado.",
                  "O carro era generoso de veloz.",
                  "A casa ficou generosa de grande."]),
                ("Em qual frase «generoso» faz sentido?",
                 ["Por ser generoso, ele repartiu tudo o que tinha.",
                  "O café estava generoso de quente.",
                  "O dia ficou generoso de ensolarado.",
                  "O atleta era generoso de rápido."]),
            ],
        },
    },
    {
        "lema": "sombrio",
        "definicao": "escuro e sem luz; que passa uma sensação triste",
        "exemplo_uso": "O corredor sombrio dava um pouco de medo à noite.",
        "nivel_dificuldade": 3,
        "sinonimos": ["escuro", "tenebroso", "obscuro"],
        "questoes": {
            1: [
                ("O que significa «sombrio»?",
                 ["Que é escuro e passa tristeza", "Que é muito rápido", "Que é muito grande", "Que é muito caro"]),
                ("«Sombrio» quer dizer...",
                 ["escuro e tenebroso", "claro e alegre", "veloz e apressado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Um beco sombrio», qual palavra pode substituir «sombrio»?",
                 ["escuro", "iluminado", "veloz", "enorme"]),
                ("Qual é um sinônimo de «sombrio»?",
                 ["tenebroso", "iluminado", "veloz", "pesado"]),
            ],
            3: [
                ("Complete: «O porão ___ não tinha nenhuma janela para entrar luz.»",
                 ["sombrio", "iluminado", "enorme", "barato"]),
                ("Complete: «O céu ficou ___ antes da tempestade começar.»",
                 ["sombrio", "ensolarado", "pesado", "barato"]),
            ],
            4: [
                ("Em qual frase «sombrio» foi usada corretamente?",
                 ["O castelo sombrio parecia abandonado na neblina.",
                  "O suco estava sombrio de gelado.",
                  "O carro era sombrio de veloz.",
                  "A casa ficou sombria de grande."]),
                ("Em qual frase «sombrio» faz sentido?",
                 ["A floresta sombria escondia o caminho.",
                  "O café estava sombrio de quente.",
                  "O dia ficou sombrio de bonito.",
                  "O atleta era sombrio de rápido."]),
            ],
        },
    },
    # ─────────────────────────────── Nível 4 ───────────────────────────────
    {
        "lema": "abundante",
        "definicao": "que existe em grande quantidade, de sobra",
        "exemplo_uso": "A colheita foi abundante e encheu todos os cestos.",
        "nivel_dificuldade": 4,
        "sinonimos": ["farto", "numeroso", "vasto"],
        "questoes": {
            1: [
                ("O que significa «abundante»?",
                 ["Que existe em grande quantidade", "Que é muito rápido", "Que é muito caro", "Que é muito antigo"]),
                ("«Abundante» quer dizer...",
                 ["farto e de sobra", "escasso e raro", "veloz e apressado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Uma comida abundante», qual palavra pode substituir «abundante»?",
                 ["farta", "escassa", "veloz", "enorme"]),
                ("Qual é um sinônimo de «abundante»?",
                 ["numeroso", "escasso", "veloz", "pesado"]),
            ],
            3: [
                ("Complete: «Depois da chuva, a água ficou ___ nos rios da região.»",
                 ["abundante", "escassa", "enorme", "barata"]),
                ("Complete: «A festa teve comida ___, com muito de sobra para todos.»",
                 ["abundante", "escassa", "pesada", "barata"]),
            ],
            4: [
                ("Em qual frase «abundante» foi usada corretamente?",
                 ["A safra abundante garantiu comida o ano inteiro.",
                  "O suco estava abundante de gelado.",
                  "O carro era abundante de veloz.",
                  "A casa ficou abundante de grande."]),
                ("Em qual frase «abundante» faz sentido?",
                 ["Havia água abundante para toda a plantação.",
                  "O café estava abundante de quente.",
                  "O dia ficou abundante de ensolarado.",
                  "O atleta era abundante de rápido."]),
            ],
        },
    },
    {
        "lema": "persistente",
        "definicao": "que não desiste e continua tentando até conseguir",
        "exemplo_uso": "A aluna persistente refez o exercício até acertar.",
        "nivel_dificuldade": 4,
        "sinonimos": ["insistente", "perseverante", "tenaz"],
        "questoes": {
            1: [
                ("O que significa «persistente»?",
                 ["Que não desiste e continua tentando", "Que é muito rápido", "Que é muito grande", "Que é muito caro"]),
                ("«Persistente» é o mesmo que...",
                 ["insistente e perseverante", "desistente e preguiçoso", "veloz e apressado", "escuro e frio"]),
            ],
            2: [
                ("Na frase «Um esforço persistente», qual palavra pode substituir «persistente»?",
                 ["insistente", "desistente", "veloz", "enorme"]),
                ("Qual é um sinônimo de «persistente»?",
                 ["perseverante", "desistente", "veloz", "pesado"]),
            ],
            3: [
                ("Complete: «Mesmo caindo várias vezes, a criança ___ aprendeu a andar de bicicleta.»",
                 ["persistente", "desistente", "enorme", "barata"]),
                ("Complete: «Com um trabalho ___, ele treinou todo dia até vencer.»",
                 ["persistente", "desistente", "pesado", "barato"]),
            ],
            4: [
                ("Em qual frase «persistente» foi usada corretamente?",
                 ["O corredor persistente terminou a prova apesar do cansaço.",
                  "O suco estava persistente de gelado.",
                  "O carro era persistente de veloz.",
                  "A casa ficou persistente de grande."]),
                ("Em qual frase «persistente» faz sentido?",
                 ["Por ser persistente, ela estudou até passar na prova.",
                  "O café estava persistente de quente.",
                  "O dia ficou persistente de ensolarado.",
                  "A parede era persistente de branca."]),
            ],
        },
    },
    {
        "lema": "genuíno",
        "definicao": "que é verdadeiro, sem imitação nem fingimento",
        "exemplo_uso": "Ela demonstrou um interesse genuíno pela história do país.",
        "nivel_dificuldade": 4,
        "sinonimos": ["autêntico", "verdadeiro", "legítimo"],
        "questoes": {
            1: [
                ("O que significa «genuíno»?",
                 ["Que é verdadeiro, sem imitação", "Que é muito rápido", "Que é muito grande", "Que é muito caro"]),
                ("«Genuíno» quer dizer...",
                 ["autêntico e verdadeiro", "falso e imitado", "veloz e apressado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Um sorriso genuíno», qual palavra pode substituir «genuíno»?",
                 ["verdadeiro", "falso", "veloz", "enorme"]),
                ("Qual é um sinônimo de «genuíno»?",
                 ["autêntico", "falso", "veloz", "pesado"]),
            ],
            3: [
                ("Complete: «Aquele era um couro ___, e não uma imitação barata.»",
                 ["genuíno", "falso", "enorme", "veloz"]),
                ("Complete: «Ela sentiu uma alegria ___ ao rever a amiga.»",
                 ["genuína", "falsa", "pesada", "barata"]),
            ],
            4: [
                ("Em qual frase «genuíno» foi usada corretamente?",
                 ["O quadro genuíno foi pintado pelo próprio artista.",
                  "O suco estava genuíno de gelado.",
                  "O carro era genuíno de veloz.",
                  "A casa ficou genuína de grande."]),
                ("Em qual frase «genuíno» faz sentido?",
                 ["Seu carinho pelos animais era genuíno.",
                  "O café estava genuíno de quente.",
                  "O dia ficou genuíno de ensolarado.",
                  "O atleta era genuíno de rápido."]),
            ],
        },
    },
    # ─────────────────────────────── Nível 5 ───────────────────────────────
    {
        "lema": "audacioso",
        "definicao": "que age com ousadia e coragem, sem medo do risco",
        "exemplo_uso": "O plano audacioso surpreendeu todos os adversários.",
        "nivel_dificuldade": 5,
        "sinonimos": ["ousado", "atrevido", "arrojado"],
        "questoes": {
            1: [
                ("O que significa «audacioso»?",
                 ["Que age com ousadia, sem medo do risco", "Que é muito grande", "Que é muito rápido", "Que é muito caro"]),
                ("«Audacioso» é o mesmo que...",
                 ["ousado e arrojado", "tímido e medroso", "enorme e pesado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Um plano audacioso», qual palavra pode substituir «audacioso»?",
                 ["ousado", "tímido", "veloz", "enorme"]),
                ("Qual é um sinônimo de «audacioso»?",
                 ["arrojado", "tímido", "lento", "pesado"]),
            ],
            3: [
                ("Complete: «Com uma jogada ___, o time arriscou tudo nos minutos finais.»",
                 ["audaciosa", "tímida", "enorme", "barata"]),
                ("Complete: «O explorador ___ decidiu cruzar o deserto sozinho.»",
                 ["audacioso", "tímido", "pesado", "barato"]),
            ],
            4: [
                ("Em qual frase «audacioso» foi usada corretamente?",
                 ["O empresário audacioso investiu numa ideia arriscada.",
                  "O suco estava audacioso de gelado.",
                  "O carro era audacioso de veloz.",
                  "A casa ficou audaciosa de grande."]),
                ("Em qual frase «audacioso» faz sentido?",
                 ["Foi uma decisão audaciosa mudar de país sozinha.",
                  "O café estava audacioso de quente.",
                  "O dia ficou audacioso de bonito.",
                  "O atleta era audacioso de rápido."]),
            ],
        },
    },
    {
        "lema": "próspero",
        "definicao": "que vai bem, cresce e tem sucesso",
        "exemplo_uso": "A cidade próspera atraía gente em busca de trabalho.",
        "nivel_dificuldade": 5,
        "sinonimos": ["bem-sucedido", "florescente", "abastado"],
        "questoes": {
            1: [
                ("O que significa «próspero»?",
                 ["Que vai bem, cresce e tem sucesso", "Que é muito rápido", "Que é muito antigo", "Que é muito escuro"]),
                ("«Próspero» quer dizer...",
                 ["bem-sucedido e florescente", "pobre e fracassado", "veloz e apressado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Um negócio próspero», qual palavra pode substituir «próspero»?",
                 ["bem-sucedido", "fracassado", "veloz", "enorme"]),
                ("Qual é um sinônimo de «próspero»?",
                 ["florescente", "fracassado", "veloz", "pesado"]),
            ],
            3: [
                ("Complete: «A fazenda ___ produzia mais a cada ano.»",
                 ["próspera", "falida", "enorme", "barata"]),
                ("Complete: «Depois de anos de esforço, ele montou um comércio ___.»",
                 ["próspero", "falido", "pesado", "barato"]),
            ],
            4: [
                ("Em qual frase «próspero» foi usada corretamente?",
                 ["O comerciante próspero abriu novas lojas na região.",
                  "O suco estava próspero de gelado.",
                  "O carro era próspero de veloz.",
                  "A casa ficou próspera de grande."]),
                ("Em qual frase «próspero» faz sentido?",
                 ["A região próspera gerava muitos empregos.",
                  "O café estava próspero de quente.",
                  "O dia ficou próspero de ensolarado.",
                  "O atleta era próspero de rápido."]),
            ],
        },
    },
    # ─────────────────────────────── Nível 6 ───────────────────────────────
    {
        "lema": "cauteloso",
        "definicao": "que age com cuidado para evitar riscos",
        "exemplo_uso": "O motorista cauteloso reduziu a velocidade na curva molhada.",
        "nivel_dificuldade": 6,
        "sinonimos": ["cuidadoso", "prudente", "precavido"],
        "questoes": {
            1: [
                ("O que significa «cauteloso»?",
                 ["Que age com cuidado para evitar riscos", "Que é muito rápido", "Que é muito grande", "Que é muito caro"]),
                ("«Cauteloso» é o mesmo que...",
                 ["prudente e precavido", "descuidado e apressado", "enorme e pesado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Um passo cauteloso», qual palavra pode substituir «cauteloso»?",
                 ["cuidadoso", "descuidado", "veloz", "enorme"]),
                ("Qual é um sinônimo de «cauteloso»?",
                 ["prudente", "descuidado", "veloz", "pesado"]),
            ],
            3: [
                ("Complete: «Foi ___ e conferiu os freios antes da viagem.»",
                 ["cauteloso", "descuidado", "enorme", "barato"]),
                ("Complete: «Com um jeito ___, ela guardou o dinheiro em lugar seguro.»",
                 ["cauteloso", "descuidado", "pesado", "barato"]),
            ],
            4: [
                ("Em qual frase «cauteloso» foi usada corretamente?",
                 ["O médico cauteloso pediu mais exames antes de decidir.",
                  "O suco estava cauteloso de gelado.",
                  "O carro era cauteloso de veloz.",
                  "A casa ficou cautelosa de grande."]),
                ("Em qual frase «cauteloso» faz sentido?",
                 ["Por ser cauteloso, ele leu o contrato inteiro antes de assinar.",
                  "O café estava cauteloso de quente.",
                  "O dia ficou cauteloso de ensolarado.",
                  "O atleta era cauteloso de rápido."]),
            ],
        },
    },
    {
        "lema": "eloquente",
        "definicao": "que fala muito bem e convence quem escuta",
        "exemplo_uso": "O discurso eloquente do estudante emocionou a plateia.",
        "nivel_dificuldade": 6,
        "sinonimos": ["expressivo", "persuasivo", "articulado"],
        "questoes": {
            1: [
                ("O que significa «eloquente»?",
                 ["Que fala muito bem e convence", "Que é muito grande", "Que é muito rápido", "Que é muito caro"]),
                ("«Eloquente» quer dizer...",
                 ["expressivo e persuasivo", "calado e confuso", "enorme e pesado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Um orador eloquente», qual palavra pode substituir «eloquente»?",
                 ["persuasivo", "confuso", "veloz", "enorme"]),
                ("Qual é um sinônimo de «eloquente»?",
                 ["articulado", "confuso", "lento", "pesado"]),
            ],
            3: [
                ("Complete: «Com um discurso ___, ela convenceu a turma toda a votar na ideia.»",
                 ["eloquente", "confuso", "enorme", "barato"]),
                ("Complete: «O advogado ___ explicou o caso de forma clara e convincente.»",
                 ["eloquente", "confuso", "pesado", "barato"]),
            ],
            4: [
                ("Em qual frase «eloquente» foi usada corretamente?",
                 ["O palestrante eloquente prendeu a atenção de todos.",
                  "O suco estava eloquente de gelado.",
                  "O carro era eloquente de veloz.",
                  "A casa ficou eloquente de grande."]),
                ("Em qual frase «eloquente» faz sentido?",
                 ["Sua fala eloquente convenceu o júri.",
                  "O café estava eloquente de quente.",
                  "O dia ficou eloquente de bonito.",
                  "O atleta era eloquente de rápido."]),
            ],
        },
    },
    {
        "lema": "tenaz",
        "definicao": "que segura firme e não larga, insistente",
        "exemplo_uso": "Com esforço tenaz, a formiga carregou a folha até o fim.",
        "nivel_dificuldade": 6,
        "sinonimos": ["persistente", "firme", "obstinado"],
        "questoes": {
            1: [
                ("O que significa «tenaz»?",
                 ["Que insiste com firmeza e não larga", "Que é muito grande", "Que é muito rápido", "Que é muito caro"]),
                ("«Tenaz» é o mesmo que...",
                 ["firme e obstinado", "frouxo e desistente", "enorme e pesado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Uma vontade tenaz», qual palavra pode substituir «tenaz»?",
                 ["firme", "fraca", "veloz", "enorme"]),
                ("Qual é um sinônimo de «tenaz»?",
                 ["obstinado", "desistente", "veloz", "pesado"]),
            ],
            3: [
                ("Complete: «Com uma garra ___, o time lutou até o último segundo.»",
                 ["tenaz", "fraca", "enorme", "barata"]),
                ("Complete: «O pesquisador ___ não parou até encontrar a resposta.»",
                 ["tenaz", "desistente", "pesado", "barato"]),
            ],
            4: [
                ("Em qual frase «tenaz» foi usada corretamente?",
                 ["O alpinista tenaz insistiu até chegar ao topo.",
                  "O suco estava tenaz de gelado.",
                  "O carro era tenaz de veloz.",
                  "A casa ficou tenaz de grande."]),
                ("Em qual frase «tenaz» faz sentido?",
                 ["Sua determinação tenaz superou todos os obstáculos.",
                  "O café estava tenaz de quente.",
                  "O dia ficou tenaz de ensolarado.",
                  "O atleta era tenaz de rápido."]),
            ],
        },
    },
    # ─────────────────────────────── Nível 7 ───────────────────────────────
    {
        "lema": "resiliente",
        "definicao": "que se recupera e resiste às dificuldades",
        "exemplo_uso": "Mesmo após a perda, a família resiliente seguiu em frente.",
        "nivel_dificuldade": 7,
        "sinonimos": ["resistente", "forte", "flexível"],
        "questoes": {
            1: [
                ("O que significa «resiliente»?",
                 ["Que se recupera e resiste às dificuldades", "Que é muito grande", "Que é muito rápido", "Que é muito caro"]),
                ("«Resiliente» quer dizer...",
                 ["resistente e capaz de se recuperar", "frágil e desanimado", "enorme e pesado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Uma pessoa resiliente», qual palavra pode substituir «resiliente»?",
                 ["resistente", "frágil", "veloz", "enorme"]),
                ("Qual é um sinônimo de «resiliente»?",
                 ["forte", "frágil", "veloz", "pesado"]),
            ],
            3: [
                ("Complete: «Mesmo depois de muitos tropeços, ela se mostrou ___ e recomeçou.»",
                 ["resiliente", "frágil", "enorme", "barata"]),
                ("Complete: «O material ___ voltava ao formato original depois de dobrado.»",
                 ["resiliente", "frágil", "pesado", "barato"]),
            ],
            4: [
                ("Em qual frase «resiliente» foi usada corretamente?",
                 ["O povo resiliente reconstruiu a cidade após a enchente.",
                  "O suco estava resiliente de gelado.",
                  "O carro era resiliente de veloz.",
                  "A casa ficou resiliente de grande."]),
                ("Em qual frase «resiliente» faz sentido?",
                 ["Por ser resiliente, ela superou a doença e voltou a treinar.",
                  "O café estava resiliente de quente.",
                  "O dia ficou resiliente de ensolarado.",
                  "A parede era resiliente de branca."]),
            ],
        },
    },
    {
        "lema": "astuto",
        "definicao": "esperto em conseguir o que quer, às vezes com manha",
        "exemplo_uso": "A raposa astuta enganou o caçador e fugiu.",
        "nivel_dificuldade": 7,
        "sinonimos": ["sagaz", "matreiro", "esperto"],
        "questoes": {
            1: [
                ("O que significa «astuto»?",
                 ["Esperto em conseguir o que quer, com manha", "Que é muito grande", "Que é muito rápido", "Que é muito caro"]),
                ("«Astuto» é o mesmo que...",
                 ["sagaz e matreiro", "tolo e ingênuo", "enorme e pesado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Um comerciante astuto», qual palavra pode substituir «astuto»?",
                 ["sagaz", "ingênuo", "veloz", "enorme"]),
                ("Qual é um sinônimo de «astuto»?",
                 ["matreiro", "ingênuo", "lento", "pesado"]),
            ],
            3: [
                ("Complete: «Com um plano ___, ele conseguiu o melhor lugar sem brigar.»",
                 ["astuto", "ingênuo", "enorme", "barato"]),
                ("Complete: «A menina ___ percebeu o truque e não caiu na pegadinha.»",
                 ["astuta", "ingênua", "pesada", "barata"]),
            ],
            4: [
                ("Em qual frase «astuto» foi usada corretamente?",
                 ["O ladrão astuto driblou o alarme sem ser notado.",
                  "O suco estava astuto de gelado.",
                  "O carro era astuto de veloz.",
                  "A casa ficou astuta de grande."]),
                ("Em qual frase «astuto» faz sentido?",
                 ["Com um golpe astuto, o jogador venceu a partida de xadrez.",
                  "O café estava astuto de quente.",
                  "O dia ficou astuto de ensolarado.",
                  "O atleta era astuto de rápido."]),
            ],
        },
    },
    {
        "lema": "iminente",
        "definicao": "que está prestes a acontecer, muito perto",
        "exemplo_uso": "As nuvens escuras anunciavam uma tempestade iminente.",
        "nivel_dificuldade": 7,
        "sinonimos": ["próximo", "prestes", "vindouro"],
        "questoes": {
            1: [
                ("O que significa «iminente»?",
                 ["Que está prestes a acontecer", "Que já passou faz tempo", "Que é muito grande", "Que é muito caro"]),
                ("«Iminente» quer dizer...",
                 ["muito próximo de acontecer", "distante e improvável", "enorme e pesado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Um perigo iminente», qual palavra pode substituir «iminente»?",
                 ["próximo", "distante", "veloz", "enorme"]),
                ("Qual é um sinônimo de «iminente»?",
                 ["prestes a ocorrer", "distante", "lento", "pesado"]),
            ],
            3: [
                ("Complete: «A chegada ___ do trem fez todos se levantarem.»",
                 ["iminente", "distante", "enorme", "barata"]),
                ("Complete: «Sentindo o desabamento ___, os operários saíram correndo.»",
                 ["iminente", "distante", "pesado", "barato"]),
            ],
            4: [
                ("Em qual frase «iminente» foi usada corretamente?",
                 ["A estreia iminente do filme já lotava as bilheterias.",
                  "O suco estava iminente de gelado.",
                  "O carro era iminente de veloz.",
                  "A casa ficou iminente de grande."]),
                ("Em qual frase «iminente» faz sentido?",
                 ["Diante do risco iminente, todos deixaram o prédio.",
                  "O café estava iminente de quente.",
                  "O dia ficou iminente de ensolarado.",
                  "O atleta era iminente de rápido."]),
            ],
        },
    },
    # ─────────────────────────────── Nível 8 ───────────────────────────────
    {
        "lema": "impecável",
        "definicao": "sem nenhum defeito ou erro",
        "exemplo_uso": "O garçom serviu a mesa de forma impecável, sem um deslize.",
        "nivel_dificuldade": 8,
        "sinonimos": ["perfeito", "irrepreensível", "imaculado"],
        "questoes": {
            1: [
                ("O que significa «impecável»?",
                 ["Que não tem nenhum defeito ou erro", "Que é muito grande", "Que é muito rápido", "Que é muito caro"]),
                ("«Impecável» é o mesmo que...",
                 ["perfeito e sem defeitos", "cheio de erros", "enorme e pesado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Um trabalho impecável», qual palavra pode substituir «impecável»?",
                 ["perfeito", "defeituoso", "veloz", "enorme"]),
                ("Qual é um sinônimo de «impecável»?",
                 ["irrepreensível", "defeituoso", "lento", "pesado"]),
            ],
            3: [
                ("Complete: «A apresentação foi ___, sem nenhum erro do começo ao fim.»",
                 ["impecável", "falha", "enorme", "barata"]),
                ("Complete: «Ele entregou um relatório ___, sem uma vírgula fora do lugar.»",
                 ["impecável", "falho", "pesado", "barato"]),
            ],
            4: [
                ("Em qual frase «impecável» foi usada corretamente?",
                 ["A costureira fez um acabamento impecável no vestido.",
                  "O suco estava impecável de gelado.",
                  "O carro era impecável de veloz.",
                  "A casa ficou impecável de grande."]),
                ("Em qual frase «impecável» faz sentido?",
                 ["Sua caligrafia impecável parecia impressa.",
                  "O café estava impecável de quente.",
                  "O dia ficou impecável de ensolarado.",
                  "O atleta era impecável de rápido."]),
            ],
        },
    },
    {
        "lema": "sublime",
        "definicao": "de uma beleza ou qualidade tão grande que emociona",
        "exemplo_uso": "A vista do alto da montanha era sublime.",
        "nivel_dificuldade": 8,
        "sinonimos": ["grandioso", "magnífico", "elevado"],
        "questoes": {
            1: [
                ("O que significa «sublime»?",
                 ["De uma beleza ou qualidade que emociona", "Que é muito rápido", "Que é muito comum", "Que é muito barato"]),
                ("«Sublime» quer dizer...",
                 ["grandioso e magnífico", "comum e sem graça", "veloz e apressado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Uma música sublime», qual palavra pode substituir «sublime»?",
                 ["magnífica", "comum", "veloz", "enorme"]),
                ("Qual é um sinônimo de «sublime»?",
                 ["grandioso", "comum", "lento", "pesado"]),
            ],
            3: [
                ("Complete: «O bailarino fez um movimento ___, que arrancou aplausos.»",
                 ["sublime", "comum", "enorme", "barato"]),
                ("Complete: «Do mirante, o pôr do sol tinha uma beleza ___.»",
                 ["sublime", "comum", "pesada", "barata"]),
            ],
            4: [
                ("Em qual frase «sublime» foi usada corretamente?",
                 ["A ópera ofereceu um espetáculo sublime.",
                  "O suco estava sublime de gelado.",
                  "O carro era sublime de veloz.",
                  "A casa ficou sublime de grande."]),
                ("Em qual frase «sublime» faz sentido?",
                 ["A pintura sublime deixou os visitantes sem palavras.",
                  "O café estava sublime de quente.",
                  "O dia ficou sublime de rápido.",
                  "O atleta era sublime de veloz."]),
            ],
        },
    },
    {
        "lema": "inóspito",
        "definicao": "que não oferece conforto, difícil de habitar",
        "exemplo_uso": "O deserto inóspito não tinha água nem sombra.",
        "nivel_dificuldade": 8,
        "sinonimos": ["hostil", "árido", "desabitado"],
        "questoes": {
            1: [
                ("O que significa «inóspito»?",
                 ["Que não oferece conforto, difícil de habitar", "Que é muito rápido", "Que é muito caro", "Que é muito antigo"]),
                ("«Inóspito» é o mesmo que...",
                 ["hostil e difícil de morar", "acolhedor e confortável", "veloz e apressado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Uma região inóspita», qual palavra pode substituir «inóspito»?",
                 ["hostil", "acolhedora", "veloz", "enorme"]),
                ("Qual é um sinônimo de «inóspito»?",
                 ["árido", "acolhedor", "lento", "pesado"]),
            ],
            3: [
                ("Complete: «O topo da montanha era ___, gelado e sem abrigo.»",
                 ["inóspito", "acolhedor", "enorme", "barato"]),
                ("Complete: «Eles cruzaram uma terra ___, onde quase nada crescia.»",
                 ["inóspita", "acolhedora", "pesada", "barata"]),
            ],
            4: [
                ("Em qual frase «inóspito» foi usada corretamente?",
                 ["O planalto inóspito afastava qualquer morador.",
                  "O suco estava inóspito de gelado.",
                  "O carro era inóspito de veloz.",
                  "A casa ficou inóspita de grande."]),
                ("Em qual frase «inóspito» faz sentido?",
                 ["A ilha inóspita não tinha comida nem água doce.",
                  "O café estava inóspito de quente.",
                  "O dia ficou inóspito de ensolarado.",
                  "O atleta era inóspito de rápido."]),
            ],
        },
    },
    {
        "lema": "perene",
        "definicao": "que dura para sempre, que não acaba",
        "exemplo_uso": "A amizade perene deles resistiu a toda distância.",
        "nivel_dificuldade": 8,
        "sinonimos": ["permanente", "duradouro", "contínuo"],
        "questoes": {
            1: [
                ("O que significa «perene»?",
                 ["Que dura para sempre, que não acaba", "Que é muito rápido", "Que é muito grande", "Que é muito caro"]),
                ("«Perene» quer dizer...",
                 ["permanente e duradouro", "passageiro e breve", "veloz e apressado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Uma fonte perene», qual palavra pode substituir «perene»?",
                 ["permanente", "passageira", "veloz", "enorme"]),
                ("Qual é um sinônimo de «perene»?",
                 ["duradouro", "passageiro", "lento", "pesado"]),
            ],
            3: [
                ("Complete: «O rio ___ nunca secava, nem na estiagem mais forte.»",
                 ["perene", "passageiro", "enorme", "barato"]),
                ("Complete: «Eles cultivavam uma esperança ___, que não morria nunca.»",
                 ["perene", "passageira", "pesada", "barata"]),
            ],
            4: [
                ("Em qual frase «perene» foi usada corretamente?",
                 ["A neve perene cobre o topo daquela montanha o ano todo.",
                  "O suco estava perene de gelado.",
                  "O carro era perene de veloz.",
                  "A casa ficou perene de grande."]),
                ("Em qual frase «perene» faz sentido?",
                 ["O amor perene dos avós durou a vida inteira.",
                  "O café estava perene de quente.",
                  "O dia ficou perene de ensolarado.",
                  "O atleta era perene de rápido."]),
            ],
        },
    },
    # ─────────────────────────────── Nível 9 ───────────────────────────────
    {
        "lema": "efêmero",
        "definicao": "que dura muito pouco tempo",
        "exemplo_uso": "A beleza da flor era efêmera: durou só um dia.",
        "nivel_dificuldade": 9,
        "sinonimos": ["passageiro", "breve", "fugaz"],
        "questoes": {
            1: [
                ("O que significa «efêmero»?",
                 ["Que dura muito pouco tempo", "Que dura para sempre", "Que é muito grande", "Que é muito caro"]),
                ("«Efêmero» é o mesmo que...",
                 ["passageiro e breve", "eterno e duradouro", "enorme e pesado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Um prazer efêmero», qual palavra pode substituir «efêmero»?",
                 ["passageiro", "eterno", "veloz", "enorme"]),
                ("Qual é um sinônimo de «efêmero»?",
                 ["fugaz", "eterno", "lento", "pesado"]),
            ],
            3: [
                ("Complete: «A fama ___ do artista sumiu em poucos meses.»",
                 ["efêmera", "eterna", "enorme", "barata"]),
                ("Complete: «O arco-íris é um espetáculo ___, que logo desaparece.»",
                 ["efêmero", "eterno", "pesado", "barato"]),
            ],
            4: [
                ("Em qual frase «efêmero» foi usada corretamente?",
                 ["O brilho efêmero da estrela cadente durou um instante.",
                  "O suco estava efêmero de gelado.",
                  "O carro era efêmero de veloz.",
                  "A casa ficou efêmera de grande."]),
                ("Em qual frase «efêmero» faz sentido?",
                 ["A moda efêmera daquele verão logo foi esquecida.",
                  "O café estava efêmero de quente.",
                  "O dia ficou efêmero de ensolarado.",
                  "O atleta era efêmero de rápido."]),
            ],
        },
    },
    {
        "lema": "austero",
        "definicao": "sério e rígido, sem luxo nem exageros",
        "exemplo_uso": "O diretor austero não abria exceção para ninguém.",
        "nivel_dificuldade": 9,
        "sinonimos": ["severo", "rígido", "sóbrio"],
        "questoes": {
            1: [
                ("O que significa «austero»?",
                 ["Sério e rígido, sem luxo nem exageros", "Que é muito rápido", "Que é muito grande", "Que é muito colorido"]),
                ("«Austero» quer dizer...",
                 ["severo e sóbrio", "festivo e exagerado", "veloz e apressado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Um juiz austero», qual palavra pode substituir «austero»?",
                 ["severo", "festivo", "veloz", "enorme"]),
                ("Qual é um sinônimo de «austero»?",
                 ["rígido", "festivo", "lento", "pesado"]),
            ],
            3: [
                ("Complete: «O quarto ___ tinha só uma cama e uma mesa, sem enfeites.»",
                 ["austero", "luxuoso", "enorme", "barato"]),
                ("Complete: «Com um tom ___, o comandante exigiu disciplina total.»",
                 ["austero", "brincalhão", "pesado", "barato"]),
            ],
            4: [
                ("Em qual frase «austero» foi usada corretamente?",
                 ["O professor austero mantinha regras muito rígidas.",
                  "O suco estava austero de gelado.",
                  "O carro era austero de veloz.",
                  "A casa ficou austera de grande."]),
                ("Em qual frase «austero» faz sentido?",
                 ["Levava uma vida austera, sem gastos supérfluos.",
                  "O café estava austero de quente.",
                  "O dia ficou austero de ensolarado.",
                  "O atleta era austero de rápido."]),
            ],
        },
    },
    {
        "lema": "magnânimo",
        "definicao": "que age com grandeza de espírito e perdoa com facilidade",
        "exemplo_uso": "O rei magnânimo perdoou os que o traíram.",
        "nivel_dificuldade": 9,
        "sinonimos": ["generoso", "nobre", "grandioso"],
        "questoes": {
            1: [
                ("O que significa «magnânimo»?",
                 ["Que age com grandeza de espírito e perdoa", "Que é muito rápido", "Que é muito grande", "Que é muito caro"]),
                ("«Magnânimo» é o mesmo que...",
                 ["generoso e nobre de espírito", "mesquinho e rancoroso", "veloz e apressado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Um gesto magnânimo», qual palavra pode substituir «magnânimo»?",
                 ["nobre", "mesquinho", "veloz", "enorme"]),
                ("Qual é um sinônimo de «magnânimo»?",
                 ["generoso", "mesquinho", "lento", "pesado"]),
            ],
            3: [
                ("Complete: «Num ato ___, ela perdoou a dívida do amigo.»",
                 ["magnânimo", "mesquinho", "enorme", "barato"]),
                ("Complete: «O vencedor ___ elogiou o adversário derrotado.»",
                 ["magnânimo", "rancoroso", "pesado", "barato"]),
            ],
            4: [
                ("Em qual frase «magnânimo» foi usada corretamente?",
                 ["O líder magnânimo estendeu a mão aos rivais.",
                  "O suco estava magnânimo de gelado.",
                  "O carro era magnânimo de veloz.",
                  "A casa ficou magnânima de grande."]),
                ("Em qual frase «magnânimo» faz sentido?",
                 ["Foi magnânimo ao dividir o prêmio com toda a equipe.",
                  "O café estava magnânimo de quente.",
                  "O dia ficou magnânimo de ensolarado.",
                  "O atleta era magnânimo de rápido."]),
            ],
        },
    },
    # ─────────────────────────────── Nível 10 ──────────────────────────────
    {
        "lema": "incólume",
        "definicao": "que saiu sem nenhum dano ou ferimento",
        "exemplo_uso": "Apesar do acidente, o motorista saiu incólume.",
        "nivel_dificuldade": 10,
        "sinonimos": ["ileso", "intacto", "são"],
        "questoes": {
            1: [
                ("O que significa «incólume»?",
                 ["Que saiu sem nenhum dano ou ferimento", "Que é muito rápido", "Que é muito grande", "Que é muito caro"]),
                ("«Incólume» quer dizer...",
                 ["ileso e intacto", "ferido e danificado", "veloz e apressado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Saiu incólume do desastre», qual palavra pode substituir «incólume»?",
                 ["ileso", "ferido", "veloz", "enorme"]),
                ("Qual é um sinônimo de «incólume»?",
                 ["intacto", "ferido", "lento", "pesado"]),
            ],
            3: [
                ("Complete: «O prédio resistiu ao terremoto e ficou ___.»",
                 ["incólume", "destruído", "enorme", "barato"]),
                ("Complete: «Depois da queda, por sorte ela permaneceu ___.»",
                 ["incólume", "ferida", "pesada", "barata"]),
            ],
            4: [
                ("Em qual frase «incólume» foi usada corretamente?",
                 ["O piloto escapou incólume das ferragens.",
                  "O suco estava incólume de gelado.",
                  "O carro era incólume de veloz.",
                  "A casa ficou incólume de grande."]),
                ("Em qual frase «incólume» faz sentido?",
                 ["Os documentos sobreviveram incólumes ao incêndio.",
                  "O café estava incólume de quente.",
                  "O dia ficou incólume de ensolarado.",
                  "O atleta era incólume de rápido."]),
            ],
        },
    },
    {
        "lema": "loquaz",
        "definicao": "que fala muito, muito conversador",
        "exemplo_uso": "O guia loquaz não parava de contar histórias.",
        "nivel_dificuldade": 10,
        "sinonimos": ["falante", "tagarela", "comunicativo"],
        "questoes": {
            1: [
                ("O que significa «loquaz»?",
                 ["Que fala muito, muito conversador", "Que é muito rápido", "Que é muito grande", "Que é muito caro"]),
                ("«Loquaz» é o mesmo que...",
                 ["falante e tagarela", "calado e quieto", "veloz e apressado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Um vizinho loquaz», qual palavra pode substituir «loquaz»?",
                 ["falante", "calado", "veloz", "enorme"]),
                ("Qual é um sinônimo de «loquaz»?",
                 ["tagarela", "calado", "lento", "pesado"]),
            ],
            3: [
                ("Complete: «O apresentador ___ falava sem parar durante todo o programa.»",
                 ["loquaz", "calado", "enorme", "barato"]),
                ("Complete: «Numa roda ___, ninguém conseguia terminar a própria frase.»",
                 ["loquaz", "silenciosa", "pesada", "barata"]),
            ],
            4: [
                ("Em qual frase «loquaz» foi usada corretamente?",
                 ["O tio loquaz animou o jantar com muitas histórias.",
                  "O suco estava loquaz de gelado.",
                  "O carro era loquaz de veloz.",
                  "A casa ficou loquaz de grande."]),
                ("Em qual frase «loquaz» faz sentido?",
                 ["Sempre loquaz, ela puxava conversa com todos.",
                  "O café estava loquaz de quente.",
                  "O dia ficou loquaz de ensolarado.",
                  "O atleta era loquaz de rápido."]),
            ],
        },
    },
    {
        "lema": "ínfimo",
        "definicao": "o menor possível, pequeníssimo",
        "exemplo_uso": "A diferença de tempo entre os dois foi ínfima.",
        "nivel_dificuldade": 10,
        "sinonimos": ["mínimo", "diminuto", "irrisório"],
        "questoes": {
            1: [
                ("O que significa «ínfimo»?",
                 ["O menor possível, pequeníssimo", "Que é muito grande", "Que é muito rápido", "Que é muito caro"]),
                ("«Ínfimo» quer dizer...",
                 ["mínimo e diminuto", "enorme e vasto", "veloz e apressado", "doce e colorido"]),
            ],
            2: [
                ("Na frase «Um valor ínfimo», qual palavra pode substituir «ínfimo»?",
                 ["mínimo", "enorme", "veloz", "pesado"]),
                ("Qual é um sinônimo de «ínfimo»?",
                 ["diminuto", "enorme", "lento", "caro"]),
            ],
            3: [
                ("Complete: «Restava uma quantidade ___ de água no fundo do copo.»",
                 ["ínfima", "enorme", "pesada", "barata"]),
                ("Complete: «O erro foi ___, quase impossível de notar.»",
                 ["ínfimo", "enorme", "pesado", "barato"]),
            ],
            4: [
                ("Em qual frase «ínfimo» foi usada corretamente?",
                 ["Pagou um preço ínfimo por aquele livro usado.",
                  "O suco estava ínfimo de gelado.",
                  "O carro era ínfimo de veloz.",
                  "A casa ficou ínfima de grande."]),
                ("Em qual frase «ínfimo» faz sentido?",
                 ["A chance de erro era ínfima depois de tantos testes.",
                  "O café estava ínfimo de quente.",
                  "O dia ficou ínfimo de ensolarado.",
                  "O atleta era ínfimo de rápido."]),
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
