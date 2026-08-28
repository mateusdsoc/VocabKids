/// Textos legais exibidos dentro do app no cadastro (docs/legal/, versão
/// condensada pra leitura em tela pequena — o conteúdo completo, com todas
/// as seções e a base jurídica citada, vive em `docs/legal/*.md`).
///
/// Versão do consentimento: mantida em sincronia manual com
/// `CONSENTIMENTO_VERSAO_ATUAL` em `backend/app/identidade/schemas.py`. Se
/// o texto abaixo mudar de forma relevante, a constante do backend precisa
/// subir junto — é isso que força um novo aceite de quem já tinha consentido
/// com a versão antiga.
const String kVersaoConsentimentoLgpd = '1.0';

const String termosDeUsoResumo = '''
Estes Termos de Uso são um contrato entre o VocabKids e você, responsável legal — nunca a criança. A criança usa o app por um perfil dentro da sua conta, mas quem aceita estes termos e responde por eles é sempre o adulto.

O QUE É O VOCABKIDS
Um app de vocabulário e redação em português para crianças de 7 a 12 anos. O primeiro destino da trilha é gratuito; o restante exige assinatura.

SUA CONTA
Você fornece e-mail e senha para criar a conta e é responsável por mantê-la em sigilo. Você pode cadastrar até 3 perfis de criança, cada um com apenas um apelido e o ano de nascimento — nunca o nome completo.

ASSINATURA
Processada pela App Store da Apple — não vemos nem guardamos seu cartão. Renova automaticamente até você cancelar direto nas configurações da sua conta Apple. A compra só pode ser feita por você, nunca durante o jogo da criança.

REDAÇÃO E TRIAGEM DE SEGURANÇA
O texto de redação enviado pela criança passa por uma triagem automática de segurança antes de qualquer análise. Você concorda com esse processamento, que existe para proteção da criança.

ISENÇÕES
O VocabKids é uma ferramenta de apoio educacional, não substitui acompanhamento pedagógico profissional. A análise por inteligência artificial pode conter imprecisões e não é avaliação escolar oficial. Somos regidos pela legislação brasileira, incluindo o Código de Defesa do Consumidor.

CANCELAMENTO
Você pode excluir sua conta a qualquer momento, direto no app — isso remove a conta e os perfis das crianças vinculados a ela.

O texto completo está em nosso site (docs/legal/termos_de_uso.md no repositório do projeto).
''';

const String consentimentoLgpdTexto = '''
Para cadastrar um perfil de criança, precisamos do seu consentimento específico — diferente de aceitar os Termos de Uso gerais. A Lei Geral de Proteção de Dados (LGPD, art. 14) trata dado de criança como categoria especialmente protegida.

O QUE VAMOS COLETAR SOBRE A CRIANÇA
• Um apelido — nunca o nome completo.
• O ano de nascimento (não a data completa) — só para calibrar a dificuldade certa.
• O progresso no jogo: pontos, nível, palavras aprendidas.
• Os textos de redação, se você ativar essa função — analisados por uma inteligência artificial externa (OpenAI) de forma anônima: só o texto e a faixa etária, nunca nome ou qualquer identificação.

O QUE NÃO FAZEMOS
• Não vendemos nem compartilhamos dado da criança com publicidade.
• Não usamos rastreamento de terceiros dentro do app.
• A criança nunca vê anúncio nem consegue comprar nada sozinha.

SEUS DIREITOS
A qualquer momento você pode ver, corrigir ou excluir os dados da criança — inclusive excluindo a conta inteira direto pelo app, o que apaga tudo em até 30 dias. Você também pode retirar este consentimento, o que na prática significa excluir a conta.

Ao marcar a caixa de consentimento, você declara que é maior de idade e responsável legal pela(s) criança(s) que vai cadastrar nesta conta, que leu e entendeu o que será coletado, e que consente especificamente com esse tratamento nos termos do art. 14 da LGPD (Lei nº 13.709/2018).

Detalhe completo: docs/legal/politica_privacidade.md e docs/legal/termo_consentimento_parental.md no repositório do projeto.
''';
