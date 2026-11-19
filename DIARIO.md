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

### Sombra de avião na Sala 1

- Aplicámos um shader ao chão que usa os vãos das janelas do PNG original para projetar faixas de luz. Uma silhueta de avião a hélice atravessa essas faixas da esquerda para a direita. A primeira passagem começa após três segundos e repete-se a cada 29 segundos.
- **Testes aprovados.** Verificámos no Godot que a sombra entra, atravessa, sai da sala e repete o percurso. Inspecionámos fotogramas da exportação Web no Chrome com a sombra em posições diferentes, sem erros de consola.
- Refinámos a silhueta com base na referência do responsável. A nova forma tem um só motor, uma hélice frontal e asas afuniladas. Acrescentámos um borrão escuro limitado aos vidros e sincronizado com a posição da sombra no chão. Confirmámos a sincronização por teste no Godot e nos fotogramas do Chrome.

### Restantes prisioneiros da Sala 1

- Importámos as sete folhas de sprites originais dos prisioneiros 03 a 09 e conferimos os SHA-256. Selecionámos 11 fotogramas em repouso por personagem, verificámos visualmente os recortes e mantivemos o alinhamento pelos pés.
- Distribuímos os novos personagens perto da parede. Cada um está numa cena reutilizável e pode ser movido no editor. O varredor continua a ser o único NPC que muda de posição durante o jogo.
- **Testes aprovados.** No Godot, confirmámos que os nove prisioneiros animam sem sair do lugar, que as regiões dos fotogramas ficam dentro das texturas e que o varredor se desloca. Inspecionámos as extremidades da sala no build Web, que correu no Chrome sem erros de consola.

### Muro e lareira na Sala 1

- Copiámos os dois PNGs fornecidos e conferimos os SHA-256. Instalámos a lareira num vão entre beliches e o muro de tijolo mais à direita, ambos como cenas reutilizáveis em `Environment/Props`. Mantivemos os ajustes já guardados no cenário e nos NPCs.
- **Testes aprovados.** Verificámos no Godot que os dois objetos carregam, que o protagonista colide com as bases e que pode passar à frente. Confirmámos o enquadramento dos dois objetos no build Web sem erros de consola.

### Sombras dos personagens

- Criámos uma sombra de contacto reutilizável, com centro mais escuro e bordas suaves. Adicionámo-la ao protagonista, ao varredor e aos nove modelos de prisioneiros. As sombras dos personagens sentados são mais largas. A origem fica junto aos pés e a camada é desenhada acima do chão e abaixo dos objetos.
- **Testes aprovados.** Confirmámos no Godot o alinhamento nos onze modelos e o seguimento do protagonista e do varredor em movimento. Verificámos a aparência no Chrome com o filtro de filme antigo, sem erros de consola.

### Novas animações do varredor

- Ligámos as três novas folhas fornecidas pelo responsável às animações de repouso, caminhada e varredura. Verificámos os SHA-256 e os recortes dos 49 fotogramas escolhidos. Mantivemos a origem junto aos pés e usámos texturas de importação de 1920 × 1920 a partir dos PNGs de 3840 × 3840.
- **Testes aprovados.** Confirmámos a origem e reprodução dos fotogramas, as dez paragens do percurso e a sombra de contacto. A primeira exportação avisou sobre o identificador da animação após a troca do recurso. Restaurámos o identificador original e o novo build correu no Chrome sem erros de consola.

### Câmara mais próxima

- Aumentámos o zoom da câmara de 1,0× para 1,18×. Baixámos o centro do enquadramento para privilegiar o protagonista e o chão, mantendo a janela de jogo em 16:9.
- **Testes aprovados.** Confirmámos no Godot que o protagonista fica dentro do enquadramento inicial e que a vista respeita os limites da sala à esquerda, ao centro e à direita. Verificámos o novo plano e o acompanhamento no build Web no Chrome.

### Revisão da caminhada do varredor

- Encontrámos uma nova versão da caminhada. Copiámos o PNG sem alterações e conferimos o SHA-256. As folhas de repouso e de varredura tinham os mesmos hashes das versões já usadas. Selecionámos 16 fotogramas da nova folha e alinhámos a base dos pés com a sombra.
- **Testes aprovados.** Confirmámos no Godot as três animações, a origem dos fotogramas e as dez paragens do percurso. Verificámos a nova caminhada no Chrome, sem erros de consola.

### Película e destaque dos personagens

- Reforçámos o aspeto de película a preto e branco com uma curva de contraste, grão fino combinado com grão mais largo, vinheta suave e riscos e poeira ocasionais. Clareámos os meios-tons dos personagens e preservámos os contornos escuros. O protagonista tem um material ajustável à parte com um realce um pouco maior.
- **Testes aprovados.** Confirmámos no Godot as sombras dos personagens e a sincronização da passagem do avião. Inspecionámos o novo contraste nas capturas do Chrome, com o build Web a correr sem erros de consola.

### Regresso ao visual anterior

- A pedido do responsável, repusemos o grão, a exposição e a vinheta anteriores, bem como o realce partilhado pelos personagens. Confirmámos o arranque no Godot e a exportação Web no Chrome sem erros.

## 19 de novembro de 2026 — Montagem inicial da parte de fora

- Copiámos os quatro PNGs da pasta do responsável e confirmámos que os ficheiros copiados têm os mesmos SHA-256 dos originais. Montámos céu e cercas, terreno e dois barracões como elementos independentes na cena `scenes/rooms/parte_de_fora.tscn`.
- A cena tem uma câmara para pré-visualizar todo o exterior e um marcador de chegada perto da porta aberta. A colisão no fim da Sala 1, a mudança de cena e o deslize com desfoque aguardam a edição e aprovação do responsável.
- O Godot importou a arte sem avisos. Inspecionámos uma captura renderizada do exterior e verificámos que a cena principal continuava a arrancar.

### Percurso do barracão ao pátio

- Aproveitámos a montagem ampliada pelo responsável. O extremo direito da Sala 1 ativa um deslize lateral de 0,65 segundos com desfoque. O protagonista aparece junto à porta fechada à esquerda do pátio.
- A câmara acompanha a travessia do pátio. Em frente à porta aberta, avançar em profundidade leva o protagonista pelos degraus até ao limiar. A imagem escurece no fim do percurso.
- O teste automático percorreu a Sala 1, verificou o ponto de chegada, os limites do pátio e a entrada pela direita. Inspecionámos o deslize e a entrada em capturas do Godot. No Chrome, o build Web abriu sem erros na consola e confirmou a saída para o pátio e os controlos no exterior.

### Película, neve e poças no exterior

- Aumentámos a transição para 1,10 segundos e reforçámos o desfoque horizontal. A transição lê a imagem do exterior depois do filtro para evitar um salto visual no fim.
- Aplicámos a mesma película da Sala 1 ao pátio e acrescentámos flocos leves. Delineámos cinco poças com colisões editáveis e ajustámos o enquadramento, o perímetro e o limiar da porta à montagem mais estreita.
- O teste automático confirmou as cinco colisões, o bloqueio do movimento na poça central e um caminho que contorna a água até à porta aberta. Inspecionámos o deslize, a neve e a entrada em capturas do Godot. O Chrome apresentou a saída para o pátio com o filtro e a neve e sem erros na consola.

### Câmara mais próxima no exterior

- Aplicámos o zoom de 1,18× da Sala 1 também ao pátio e baixámos o centro da câmara para manter o protagonista e o chão no enquadramento. Confirmámos a vista junto às duas portas em capturas do Godot e ajustámos o teste à versão guardada do perímetro do pátio. O percurso automático passou.

### Novo chão do pátio

- Importámos o PNG «Paisagem Nevada Vintage Monocromática» e verificámos que a cópia é idêntica ao original. O chão novo ocupa o mesmo espaço e deixou o percurso livre das colisões das antigas poças.
- Ajustámos a zona de entrada aos degraus para que o protagonista a alcance antes de colidir com o barracão. O teste automático passou desde a Sala 1 até à porta aberta. Conferimos o aspeto do chão nos dois extremos do pátio no Godot.

### Cordas em primeiro plano na Sala 1

- Importámos o PNG original das cordas e pendurámo-lo num sprite independente na camada das beliches da frente. Confirmámos a sobreposição numa captura do Godot.
- Durante o teste do percurso, repusemos a referência direta ao PNG do chão nevado, que o editor tinha guardado como referência à cache local. O percurso completo voltou a passar.
