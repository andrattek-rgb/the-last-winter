# The Last Winter

Jogo narrativo 2D de exploração e furtividade. Durante a Segunda Guerra Mundial, uma criança presa num campo de concentração procura o pai. A Sala 1 do barracão permite testar o movimento, montar o cenário à mão e observar o varredor a trabalhar.

## Executar localmente

1. Abre `project.godot` no [Godot 4.7.2 standard](https://godotengine.org/download/windows/). O renderer Compatibility está configurado.
2. Carrega em **F5** para abrir o menu. Escolhe **New Game** e confirma o aviso para começar na Sala 1. Segue para a direita até ao fim das beliches para sair junto à porta fechada do pátio. Atravessa o pátio e carrega em **W** ou **↑** em frente à porta aberta para entrar. Usa **F6** com `scenes/rooms/parte_de_fora.tscn` aberta para testar diretamente o exterior.
3. Para confirmar o arranque sem interface gráfica, corre os comandos abaixo na raiz do projeto. Em Windows, `godot` pode ser substituído pelo caminho do executável com sufixo `_console.exe`.

```powershell
godot --headless --path . --editor --import
godot --headless --path . --quit-after 2
godot --headless --path . --fixed-fps 60 --script res://tests/exterior_route.gd
godot --headless --path . --fixed-fps 60 --script res://tests/laundry_stealth.gd
godot --headless --path . --fixed-fps 60 --script res://tests/kitchen.gd
godot --headless --path . --fixed-fps 60 --script res://tests/title_menu.gd
```

Na máquina de desenvolvimento, o editor portátil está em `../../work/godot-4.7.2/` a partir da raiz do projeto. Essa cópia já tem os modelos Web e pode ser executada sem instalar o editor no sistema.

## Estrutura

- `scenes/` contém as cenas Godot. `main.tscn` abre a Sala 1 e liga-a ao pátio em `scenes/rooms/parte_de_fora.tscn`.
- `assets/modelos/` reúne os PNGs utilizados e as cenas reutilizáveis. `room_01/` contém o cenário e o beliche. `characters/` contém as cenas, os spritesheets e os fotogramas de animação do protagonista, dos prisioneiros e do varredor.
- `export_presets.cfg` configura a exportação Web.
- `AGENTS.md`, `DIARIO.md` e `PROMPTS.md` registam as regras de trabalho, o percurso real e os pedidos que definiram o projeto.
- `tests/` contém as verificações do jogo, da autenticação Web e da persistência. `web/` contém o portal de contas e `supabase/migrations/` o esquema versionado.

## Editar o exterior

Em `parte_de_fora.tscn`, ajusta `ChegadaDoBarracao` junto à porta fechada e `EntradaPortaAberta` junto aos degraus da porta da direita. O filho `Limiar` marca o ponto a que o protagonista caminha ao entrar. Se moveres um barracão, ajusta também o polígono correspondente em `LimitesDoPatio` e testa com **F6**.

Em `Neve`, a propriedade **Amount** controla a quantidade de flocos. O filtro de película está em `FilmeAntigo` e a textura nevada está em `Paisagem/Chao`. Para veres os limites do pátio durante um teste, ativa **Debug → Visible Collision Shapes** antes de carregar em **F6**.

### Testar a furtividade

- Abre `parte_de_fora.tscn` e usa **F6**. Mantém **C** premido para te agachares atrás da pilha. Usa **WASD** ou as setas para acompanhar o carrinho pelo lado de baixo do ecrã, dentro da largura da caixa. Se o guarda ou o cão te virem, vão reagir e correr atrás de ti. Se te alcançarem, recomeças junto ao primeiro barracão. Usa **W** ou **↑** junto à porta aberta para terminar o desafio.
- O cão fica em **Personagens → Cao**. No Inspetor da cena principal do pátio, **Dog Sight Range** e **Dog Detection Seconds** definem o alcance e o tempo de deteção enquanto o guarda está afastado do posto. **Run Speed** é editável em cada perseguidor.
- Quando o carrinho chega à caixa junto à cozinha, podes passar para trás dela e esperar que o guarda siga. No editor, **Personagens → Caixa01 → Cobertura** define a área protegida e **BaseDaCaixa** define a colisão.
- Para ajustar o guarda, ativa o olho de **Personagens → GuardaEmPerseguicao** na árvore e seleciona **Art**. Escolhe **Animation** (`startled`, `angry` ou `run`) e ajusta o campo correspondente em **Pursuit Scale**. O guarda de perseguição fica oculto no jogo até à deteção.
- Em **Personagens**, ajusta as posições da pilha, do trabalhador, do carrinho e do guarda. A propriedade **Size** da pilha e de **Carrinho → Cobertura** controla a área que interceta a visão do guarda.
- Em **Desafio → Percurso**, edita a curva do trajeto. O primeiro ponto ancora a curva à posição inicial do carrinho. Em **Desafio**, ajusta **Pull Speed** quando o trabalhador puxa o carrinho cheio, **Travel Speed** para o regresso e **Guard Follow From X** para a linha branca. O marcador **Carrinho → Arte → Pegas** define onde as mãos encaixam.
- Em **VisaoDoGuarda**, **Sight Start X** define o início da vigilância no pátio. Também podes ajustar o alcance, o ângulo e o tempo de deteção. Em **Carrinho → Cobertura**, **Position** define a linha que acompanha o carrinho e **Size X** define a largura protegida abaixo dela, com o carrinho vazio ou cheio.
- Em **Desafio**, **Idle Seconds** controla as pausas antes de carregar e de puxar. **Stop At X** e **Stop Seconds** controlam a paragem do carrinho. O marcador **ParagemGuarda** define onde o guarda espera.
- Em **Desafio → Worker Load Scale**, ajusta apenas o tamanho do trabalhador durante `load_clothes`. Usa `1.0` para ver a animação à escala base ou `1.20` para a ampliar 20%.

## Montar a Sala 1 no editor

1. No painel **Sistema de Ficheiros**, abre `scenes/rooms/room_01.tscn` e escolhe **2D**. Seleciona `Background/Floor` e carrega em **F** para centrar. Usa a roda do rato para ajustar o zoom e arrasta com o botão do meio para navegar. A vista 2D permite ver os 2170 × 725 do cenário. No jogo, a câmara mostra uma janela 16:9 de 1280 × 720.
2. Para mover um beliche, seleciona-o em `Environment/BunkBeds`. Clica na ferramenta **Mover** na barra da vista 2D e arrasta o beliche pelo ponto junto aos pés. Podes também escrever as coordenadas no **Inspetor → Transform → Position**. Para redimensionar, edita **Scale** e mantém X e Y iguais para preservar a proporção.
3. Para acrescentar um beliche, seleciona um existente e usa **Ctrl+D**. Também podes arrastar `assets/modelos/room_01/bunk_bed.tscn` para `BunkBeds` na árvore da cena. Para acrescentar outro NPC, arrasta uma das nove cenas `prisoner_*.tscn`, em `assets/modelos/characters/prisoners/`, para **Characters → Prisoners**.
4. Seleciona **Camera2D** para ver o retângulo inicial e os limites na vista 2D. `WalkableArea` desenha a guia verde. As formas em `CollisionBoundaries` determinam os limites físicos. `Background` contém a parede e o chão separados. Para ajustar os beliches mais próximos da câmara, move os nós em **Foreground → ForegroundBunks**. Cada nó usa uma região do mesmo PNG, tem posição independente e serve de sobreposição visual. Usa o ícone do olho de `Reference` para ver a imagem de fundo completa.
5. Usa **Ctrl+S** para guardar, **F5** para iniciar o projeto ou **F6** para testar a cena aberta. Move o protagonista com **WASD** ou **setas**. Usa **F8** para voltar ao editor. O protagonista alterna entre repouso e movimento, e os prisioneiros têm animações em repouso.
6. Em **Characters → Sweeper**, o Inspetor permite editar os pontos da rota, a velocidade e a duração de cada paragem para varrer. Em **FilmEffect → Filter → Material**, podes ajustar a exposição, o grão e a vinheta. O material `effects/character_light.tres` controla o realce partilhado pelos personagens.
7. Em **Environment → Props**, podes mover o muro (`BrickWall`) e a lareira (`Fireplace`) separadamente. Cada modelo tem colisão na base.

## Contas e progresso

Na versão Web, cria uma conta com email e palavra-passe ou carrega em **Entrar**. Ao entrar numa zona na partida principal, o jogo guarda automaticamente o ponto de controlo no Supabase. No menu, **Continue → Original save** abre a entrada da última zona alcançada. Os pontos disponíveis são Sala 1, primeiro pátio, cozinha e segundo pátio. Os três cartões adicionais começam vazios e guardam partidas separadas no armazenamento local do browser, por conta. No Godot, todos os cartões usam o armazenamento local.

1. No projeto Supabase, aplica `supabase/migrations/202611240001_player_progress.sql` no **SQL Editor** e ativa o provider **Email** em **Authentication**. A migração limita a leitura ao dono do registo. A função de gravação valida a conta e só avança o ponto de controlo.
2. Em **Authentication → URL Configuration**, configura o **Site URL** e os URLs de redirecionamento para os endereços que vão servir o jogo. Para disponibilizar confirmação de conta a jogadores externos, configura SMTP próprio. [Autenticação por palavra-passe](https://supabase.com/docs/guides/auth/passwords) · [SMTP do Supabase](https://supabase.com/docs/guides/auth/auth-smtp)
3. Copia `.env.example` para `.env` e preenche o URL do projeto e a chave **Publishable**. Define `GODOT_BIN` caso o executável Godot não esteja no PATH. [Chaves do Supabase](https://supabase.com/docs/guides/getting-started/api-keys)

## Exportar e testar no browser

Com Node.js 24 e os modelos de exportação da mesma versão do Godot instalados, corre na raiz do projeto:

```powershell
npm ci
npm test
node --env-file=.env web/build.mjs
python -m http.server 8000 --directory dist
```

Abre `http://localhost:8000` no browser. A exportação usa o renderer Compatibility e uma única thread. Com autorização, publica o conteúdo de `dist/` no Netlify e verifica o registo, login e progresso com duas contas. [Exportação Web do Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html) · [Deploy manual do Netlify](https://docs.netlify.com/deploy/create-deploys/)

O teste de browser usa a exportação real e uma API Supabase simulada. Para o executar, usa estas variáveis apenas no terminal de teste e volta a exportar com a configuração real antes de publicar:

```powershell
$env:SUPABASE_URL = "https://test-winter.supabase.co"
$env:SUPABASE_PUBLISHABLE_KEY = "sb_publishable_test_fixture"
npm run build:web
npx playwright install chromium
npm run test:browser
```

Podes definir `TEST_CHROMIUM_BIN` para reutilizar um Chrome instalado. O `npm test` valida a migração com PostgreSQL local via PGlite e a recuperação de erros de gravação.

## GitHub

O repositório local foi inicializado em `main` e o remoto `origin` aponta para `andrattek-rgb/the-last-winter`. Se for preciso renovar a sessão, usa `gh auth login --hostname github.com --git-protocol https --web` no terminal. `gh api user --jq .login` confirma a conta ativa. [Repositório](https://github.com/andrattek-rgb/the-last-winter) · [Autenticação do GitHub CLI](https://docs.github.com/en/github-cli/github-cli/authenticating-with-github-cli)

## Ordem de trabalho até à entrega

- **18–19 de novembro.** Fechar o ambiente, validar o build Web local e preparar a publicação técnica.
- **20–22 de novembro.** Importar os recursos da Sala 1, testar controlos e colisões e ligar o registo, o login e um ponto de controlo ao Supabase.
- **23–24 de novembro.** Testar a versão jogável publicada, incluindo a recuperação do progresso e o isolamento entre contas.
- **25–26 de novembro.** Corrigir falhas de entrega, gravar o vídeo e verificar os links numa janela privada.

## Entrega Mindera School

Prazo em Portugal continental: **26 de novembro de 2026, às 23h59**. Preparar o link do jogo, o link do repositório público, o diário e os prompts no GitHub, e o link de um vídeo de até dois minutos. O enunciado também pede um PowerPoint para o painel, com 20 minutos de apresentação e 10 minutos de perguntas. A data da apresentação e o destinatário da entrega devem ser confirmados na comunicação da Mindera.

## Créditos e referências

Os PNGs de cenário e os spritesheets de personagens foram fornecidos pelo responsável do projeto no pacote Last Winter. O ficheiro `Três beliches em madeira e tecido.png` foi importado como `room1_foreground_bunks.png`. Os spritesheets ativos do varredor estão em `assets/modelos/characters/sweeper/`, com a caminhada ligada a `npc_velho_walk_spritesheet_v2.png`. Os PNGs copiados são idênticos aos originais. O Godot prepara texturas de trabalho e seleciona os fotogramas das animações por região. Registar aqui a autoria, as licenças e as fontes históricas conforme forem confirmadas.

O menu usa a imagem **Boné às Riscas sob o Holofote**, fornecida pelo autor, e a fonte **Archivo Black** sob a licença OFL incluída em `assets/menu/`. Os créditos apontam para as fontes de cada relato. [Anne Frank House](https://www.annefrank.org/en/anne-frank/who-was-anne-frank/) · [Elie Wiesel](https://encyclopedia.ushmm.org/content/en/article/elie-wiesel) · [Gerda Weissmann Klein](https://encyclopedia.ushmm.org/content/en/id-card/gerda-weissmann) · [Janusz Korczak](https://encyclopedia.ushmm.org/content/en/article/janusz-korczak-1) · [Irena Sendler](https://encyclopedia.ushmm.org/content/en/oral-history/irena-sendler-describes-how-she-was-arrested-and-tortured-by-the-gestapo)

## Cozinha e refeitório

A porta aberta do Barracão 2 leva à cozinha. Para testar diretamente no editor, abre `scenes/rooms/kitchen.tscn` e usa **F6**. Aproxima-te da frente do balcão até aparecer **[E] Interact** e carrega em **E**. Escolhe **BREAD** ou **SOUP** com o rato ou com **←/→** e **Enter**. O controlo volta quando a entrega termina. As escolhas concluídas ficam na lista `received_food` da sessão da cozinha.

- Em **EmCena**, podes mover as mesas, os três caldeirões, o mexedor e o balcão. Usa a propriedade **Z Index** para um ajuste manual de profundidade. A ordenação por Y está ativa.
- Abre os filhos de cada caldeirão para mover **PontoDoCorredor** e **PontoDeParagem**. Mudar a posição do caldeirão move os dois pontos com ele. Em **Mexedor**, edita a lista de estações, **Walking Speed** e **Stir Seconds**.
- Ajusta **Balcao → Interacao → Alcance**, as formas junto aos objetos e **Limites → Perimetro**. As cenas instanciadas já têm os filhos editáveis.
- Em **KitchenInteraction**, podes trocar as três referências de vídeo e as respetivas pistas de som. A arte original de cada mesa já inclui os comensais e a do balcão já inclui o servidor. Cada composição move-se como uma peça. Os PNGs foram copiados intactos.
