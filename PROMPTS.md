# Prompts de desenvolvimento

## 18 de novembro de 2026 — Início oficial do projeto

> Antes de começares a programar o jogo, analisa o sistema operativo e as ferramentas de desenvolvimento instaladas. […] Por enquanto, vamos desenvolver apenas a Sala 1.

Excerto do pedido inicial. Definiu Godot 4 e GDScript, o âmbito da primeira versão, a preservação dos recursos gráficos existentes e a ordem de trabalho. Também estabeleceu Supabase, publicação Web, testes e aprovação prévia de commits e publicação.

## 18 de novembro de 2026 — Montagem manual da Sala 1

> No Godot pode deixar tudo organizado para eu só montar o local do jogo.

Paráfrase do pedido que definiu a edição manual da sala pelo responsável. A preparação concentra-se nas camadas editáveis e nos elementos que pode posicionar no editor.

## 18 de novembro de 2026 — Câmara, personagens e área caminhável

> Quero que prepares o cenário, o enquadramento e a estrutura para que eu possa montar o mapa manualmente, arrastando e posicionando objetos no editor.

O pedido definiu a vista lateral 16:9, a câmara que acompanha o jogador na horizontal, o movimento em quatro direções e a montagem inicial com os recursos originais. Cada elemento ficou numa instância editável e as posições são guardadas no editor.

## 18 de novembro de 2026 — Filtro de filme antigo e varredor

> Quero o filtro e as animações nos personagens. O NPC com a vassoura vai andar pela sala toda e varrê-la. Como o jogo vai ficar mais escuro, quero um realce subtil nos personagens.

Paráfrase do pedido que definiu o tratamento visual da Sala 1 e distinguiu a rotina do varredor das animações em repouso dos outros prisioneiros.

## 19 de novembro de 2026 — Montar a parte de fora antes da transição

> Antes de fazer isso eu quero que você monte o mapa e depois me deixe editar.

O pedido definiu a ordem de trabalho. Primeiro, montar o cenário exterior com os assets fornecidos para edição manual. Depois da aprovação, ligar o extremo direito da Sala 1 ao exterior com uma transição lateral desfocada.

> Ele tem ir pra fora a partir da porta que esta fechada, e depois ele entra na porta que esta aberta.

A correção definiu a direção do percurso pelo pátio ampliado. A porta fechada à esquerda é o ponto de chegada e a porta aberta à direita é o destino.

> A transição da sala 1 pra parte de fora esta muito seca e sem blur […] adicione o filtro de desenho antigo nessa parte, e coloque neve caindo do lado de fora, não muita neve […] pro jogador não poder pisar em cima [das poças].

O pedido acrescentou um desfoque mais visível na transição, a película da Sala 1 no exterior, neve leve e colisões nos contornos das poças.

## 20 de novembro de 2026 — Primeiro desafio de furtividade

> O jogador pode sair do esconderijo inicial, agachar-se atrás do carrinho e acompanhar o movimento para a direita.

O pedido e a imagem marcada definiram a colocação da pilha, do trabalhador, do guarda e do carrinho, bem como o percurso. O carrinho enche ao longo de seis segundos e regressa vazio após três segundos atrás do Barracão 2. A pilha e a carga cheia bloqueiam a linha de visão quando o jogador está agachado. O pedido também especificou a inversão temporal dos fotogramas da animação de puxar e a reutilização da entrada existente.

> O pegador do carrinho tem que estar virado para direita […] eu quero que ele vá andando até lá e depois toca a animação dele arrastando o carrinho.

A revisão pede que o trabalhador saia da posição de carregamento e encaixe nas pegas antes de recuar. Também pede um guarda mais afastado e um ritmo mais lento.

> O guarda só consegue ver da linha azul pra frente […] só vai poder seguir o carrinho quando passar da linha branca.

A imagem da revisão também identifica a curva a corrigir atrás do Barracão 2. O ritmo reduzido aplica-se à fase de puxar o carrinho cheio.

> A seta verde vai ser o percurso do prisioneiro com o carrinho […] a seta vermelha é o percurso do guarda […] eu quero acompanhar o carrinho igual o quadrado roxo.

A revisão acrescenta pausas antes de carregar e puxar, uma paragem conjunta de três segundos junto ao Barracão 2 e uma zona móvel de cobertura do lado da câmara.

> Do limite vermelho pra baixo do carrinho o guarda não pode ver o player e do azul pra cima o guarda consegue ver.

A nova referência define uma linha móvel na caixa. A proteção acompanha toda a faixa de baixo dentro da largura assinalada, mesmo com o carrinho vazio.

## 23 de novembro de 2026 — Cozinha e serviço de comida

> Quero conseguir reorganizar a cozinha inteira à mão, sem precisar de modificar código.

O pedido definiu a cozinha editável, o circuito do mexedor pelos três caldeirões, comensais animados e uma interação de escolha de comida com os três clipes fornecidos.

### Revisão da montagem e das animações

> Melhorei o spritesheet de idle do balcão e editei a cozinha […] as animações das pessoas da cozinha estão meio travadas.

O pedido definiu a montagem guardada no editor como ponto de partida para realinhar colisões e interações, incorporar o novo idle e suavizar as animações dos NPCs.

> Volta ao spritesheet do mexedor e da mesa que só tem uma pessoa.

O Michel preferiu o movimento original nestes dois casos e pediu para repor as respetivas animações.

> O spritesheet do balcão está difícil de editar no editor do Godot pois o frame que aparece lá não tem no jogo.

Comparei a vista da cozinha com a execução e corrigi o corte do balcão no limite da câmara.

> Quero que no editor eu consiga mudar o tamanho do balcão sem ter que adivinhar.

O pedido definiu a necessidade de ver os ajustes de escala no enquadramento do jogo enquanto se edita a cena.

Uma captura enviada pelo Michel mostrou o protagonista inclinado junto à pilha de pijamas. Corrigi a rotação na cena exterior.

## 24 de novembro de 2026 — Desempenho e segundo exterior

> Investiga a causa real deste problema antes de continuar o desenvolvimento […] Eu próprio vou montar e organizar o cenário manualmente.

A ordem do pedido foi abrir a cozinha, medir e corrigir os travamentos e só depois preparar o segundo exterior com os assets separados e editáveis.

> Troque o chão pelo mesmo chão que tem no lado de fora 1 […] quero que o céu e a cerca fiquem por cima do chão nas camadas.

O pedido definiu a textura a reutilizar e a ordem de desenho do terreno.

> A torre de vigia vai emitir uma luz […] o padrão da luz é começar da caixa 4 e ir até à caixa 1 e depois repetir.

O pedido também definiu a linha branca como limite da zona segura e as caixas como cobertura com sombra visível.

> Ao seguir em frente na cozinha dava acesso ao lado de fora 2 […] e coloque o filtro que usamos e também a neve.

O pedido completou o percurso da cozinha ao segundo pátio e especificou o filtro e a neve a cair.

> A luz tem que vir da marcação branca […] quando chegar no 1 vai do 1 pro 4, assim indo e voltando sem desaparecer.

O pedido ajustou a origem do feixe e o ritmo da varredura.

> A luz pode ser rápida na transição de uma caixa para outra mas em cada caixa fica parada por um segundo […] faz uma luz forte.

O pedido especificou o contraste entre a deslocação rápida e as pausas e um holofote mais forte na cabine.

> Agora vamos fazer o que falta, deve ser o login e a database, pode começar a fazer isso.

O pedido fechou a fase de alterações ao conteúdo do jogo e iniciou a implementação de contas e progresso persistente no Supabase. O enunciado da Mindera foi consultado para confirmar os requisitos de autenticação, persistência entre sessões e testes automáticos.

> Esse vai ser o menu do jogo […] New Game, Credits, Quit […] quando a pessoa já tem um progresso, aparece mais uma opção Continue.

O pedido forneceu a arte do menu, a referência tipográfica e a dos cartões, o texto integral do aviso e a assinatura dos créditos. Também pediu cinco relatos reais em páginas separadas e o filtro de película no menu e na cutscene da sopa.

> Nessa parte, deixe a movimentação da luz mais aleatória, acho que está muito fácil, e deixe o player em uma velocidade normal.

O pedido ajustou a dificuldade do segundo pátio, com uma sequência menos previsível do holofote e a velocidade base do jogador.

> Adicionar o dog na parte de fora 1 […] o cachorro não vê se o player estiver passando atrás do carrinho […] quero tudo do jogo em inglês.

O pedido introduziu a vigilância do cão durante a ronda e animações de susto, raiva e corrida para ambos os perseguidores. A captura passou a reiniciar o pátio e os textos do jogo e do portal foram uniformizados em inglês.
