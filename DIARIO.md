# Diário de desenvolvimento

## 18 de novembro de 2026 — Preparação do projeto

- Inspecionámos a pasta aberta e as ferramentas. A pasta não tinha um projeto Godot nem um repositório Git. O Git 2.54.0, GitHub CLI 2.96.0, Node.js 24.16.0, npm 11.13.0 e VS Code 1.136.1 já estavam disponíveis no Windows 11 25H2 x64.
- Preparámos o Godot 4.7.2 standard portátil e os modelos oficiais de exportação Web. A primeira tentativa de acesso à rede falhou na resolução do endereço. Com a permissão de rede, o download funcionou. Comparámos os dois ficheiros descarregados com os SHA-256 publicados.
- Criámos a estrutura inicial com uma cena Godot vazia, o preset Web e a documentação de trabalho. Inicializámos o Git em `main` e confirmámos a identidade local aprovada pelo responsável. O GitHub devolveu HTTP 401 para a sessão guardada. A renovação da sessão depende da confirmação da conta no browser.
- Na primeira importação, o Godot sinalizou dois campos em falta no preset e não conseguiu criar a pasta de dados no ambiente isolado. Corrigimos o preset e apontámos temporariamente os dados do processo para a pasta de trabalho.
- **Testes aprovados.** Importação via `--headless --editor --import`, arranque da cena via `--headless --quit-after 2` e exportação via `--headless --export-release Web dist/index.html`. Um teste automatizado com Playwright abriu o build servido por HTTP local no Chrome, confirmou que o WebGL 2 iniciou e que o browser carregou os ficheiros WASM e PCK sem erros de consola. O `git check-ignore` confirmou as exclusões de cache, configuração local, dependências e build.
- **Próxima etapa.** Rever a base, renovar a autenticação do GitHub, preparar a publicação técnica quando autorizada e importar os recursos originais da Sala 1 quando forem fornecidos. A publicação e os testes de autenticação e persistência ficam para quando os serviços estiverem ligados.

### Segunda sessão — GitHub e base editável da Sala 1

- Confirmámos que a sessão do GitHub já funcionava. Com autorização do responsável, criámos o repositório público vazio `andrattek-rgb/the-last-winter`, ligámos o remoto `origin` e verificámos o acesso com `git ls-remote origin`. A sessão terminou sem commits nem envio de ficheiros.
- Encontrámos cinco PNGs de cenário na pasta indicada. Copiámo-los para o projeto e conferimos o SHA-256 de cada cópia. A camada de primeiro plano recebeu um nome de ficheiro novo. Os originais ficaram no Ambiente de Trabalho.
- Alinhámos a parede e o chão na cena editável. Preparámos um beliche reutilizável, uma camada de primeiro plano e a imagem de referência. A disposição dos beliches fica a cargo do responsável no editor. Os spritesheets dos personagens ficaram no pacote original para uma etapa posterior.
- **Testes aprovados.** O Godot importou os cinco PNGs e abriu a cena principal em modo headless. O teste estrutural confirmou o alinhamento da parede e do chão, a ordenação por profundidade no grupo do mobiliário e que o beliche pode ser instanciado na sala. Exportámos de novo para Web e verificámos a imagem renderizada no Chrome sem erros de consola.

### Montagem jogável da Sala 1

- Mantivemos as camadas de parede e chão no mesmo espaço de 2170 × 725. Colocámos dois beliches independentes, o protagonista à esquerda e dois prisioneiros sentados junto à zona do fundo. O grupo de primeiro plano e a referência completa ficaram disponíveis no editor.
- As folhas de sprites usadas chegam aos 6144 × 7680. Copiámos os PNGs usados sem alteração e comparámos os SHA-256. O Godot gera texturas de importação menores e cada cena de personagem seleciona um fotograma com `AtlasTexture` e posiciona a origem junto aos pés. Os restantes spritesheets estão no pacote original.
- Mudámos a resolução base para 1280 × 720 e colocámos uma câmara horizontal suavizada com limites de cenário. O protagonista move-se com WASD ou com as setas. As colisões dos pés respeitam os quatro limites do chão e os beliches. A ordenação pelo eixo Y permite sobreposições conforme a profundidade.
- **Testes aprovados.** Importação e arranque sem interface gráfica, teste automatizado com ações nas quatro direções, colisões da sala e do mobiliário, limites da câmara e independência das duas instâncias do beliche. O build Web arrancou no Chrome sem erros e a tecla D deslocou o protagonista e a câmara. No editor, abrimos o jogo com F5, arrastámos o primeiro beliche separadamente, repusemos a posição com Ctrl+Z e deixámos a vista 2D enquadrada na sala inteira.

### Beliches em primeiro plano

- Usámos o PNG de primeiro plano já importado para criar três sprites independentes em `Foreground/ForegroundBunks`. Cada sprite mostra apenas a região de um beliche. Colocámos os três junto à borda inferior como elementos visuais, acima dos personagens na ordem de desenho. Preservámos a disposição dos beliches que o responsável já tinha montado ao fundo.
- **Testes aprovados.** A sala arrancou no Godot e a exportação Web correu no Chrome sem erros de consola. Confirmámos nas imagens de início e de deslocação que os beliches aparecem junto à borda inferior e acompanham o cenário enquanto a câmara avança.

### Organização dos modelos e preparação do primeiro commit

- Reunimos os oito PNGs e as quatro cenas reutilizáveis em `assets/modelos/`, com subpastas para o cenário, o protagonista e os prisioneiros. O SHA-256 dos oito PNGs coincide com o dos originais. A cena da sala manteve os ajustes guardados pelo responsável, com catorze instâncias de beliches ao fundo e seis sprites de beliches em primeiro plano.
- **Testes aprovados.** Revimos os ficheiros selecionados para o commit e verificámos o diff com `git diff --cached --check`. Numa cópia criada a partir desses ficheiros, sem cache do projeto, o Godot importou os recursos, abriu a cena e exportou para Web. No Chrome, a tecla D moveu o jogador e a câmara sem erros na consola.

### Filtro de filme antigo, animações e varredor

- Aplicámos um filtro a preto e branco com redução de exposição, grão, vinheta e oscilação ligeira. Um material partilhado clareia suavemente os personagens. Preservámos a montagem que o responsável guardou no editor.
- Importámos quatro folhas adicionais dos recursos originais e verificámos os SHA-256. O protagonista usa animações de repouso e movimento, e os prisioneiros sentados animam-se sem mudar de posição. O varredor usa as folhas de caminhar e varrer, com dez pontos editáveis e pausas de 2,5 segundos.
- O primeiro teste de percurso encontrou um ponto para lá da colisão dianteira já guardada pelo responsável. Recuámos os pontos dianteiros para dentro da área caminhável.
- **Testes aprovados.** Um teste automatizado no Godot confirmou a transição das animações do protagonista, o avanço dos fotogramas dos prisioneiros, as dez paragens do varredor e a sua imobilidade durante a varredura. Exportámos para Web e verificámos no Chrome a composição do filtro, o varredor a trabalhar e a deslocação do protagonista e da câmara, sem erros de consola.

### Correção dos recortes das animações

- Inspecionámos os fotogramas nas texturas importadas pelo Godot. Ajustámos as regiões dos quatro recursos de animação e compensámos as margens para preservar o alinhamento dos pés. Selecionámos poses sem blocos de fundo na corrida e com o contorno da vassoura visível na caminhada. Os sete PNGs de animação coincidem com os originais.
- **Testes aprovados.** Revimos os 84 fotogramas usados, repetimos o teste de animações e das dez paragens do varredor com a velocidade ajustada pelo responsável e validámos o build Web no Chrome sem erros de consola.
