# The Last Winter

Jogo narrativo 2D de exploração e furtividade. Durante a Segunda Guerra Mundial, uma criança presa num campo de concentração procura o pai. A Sala 1 do barracão permite testar o movimento, montar o cenário à mão e observar o varredor a trabalhar.

## Executar localmente

1. Abre `project.godot` no [Godot 4.7.2 standard](https://godotengine.org/download/windows/). O renderer Compatibility está configurado.
2. Carrega em **F5** para ver a base visual da Sala 1. Usa **F6** com a cena da sala aberta para a ver isoladamente.
3. Para confirmar o arranque sem interface gráfica, corre os comandos abaixo na raiz do projeto. Em Windows, `godot` pode ser substituído pelo caminho do executável com sufixo `_console.exe`.

```powershell
godot --headless --path . --editor --import
godot --headless --path . --quit-after 2
```

Na máquina de desenvolvimento, o editor portátil está em `../../work/godot-4.7.2/` a partir da raiz do projeto. Essa cópia já tem os modelos Web e pode ser executada sem instalar o editor no sistema.

## Estrutura

- `scenes/` contém as cenas Godot. `main.tscn` é o ponto de entrada e abre a Sala 1.
- `assets/modelos/` reúne os PNGs utilizados e as cenas reutilizáveis. `room_01/` contém o cenário e o beliche. `characters/` contém as cenas, os spritesheets e os fotogramas de animação do protagonista, dos prisioneiros e do varredor.
- `export_presets.cfg` configura a exportação Web.
- `AGENTS.md`, `DIARIO.md` e `PROMPTS.md` registam as regras de trabalho, o percurso real e os pedidos que definiram o projeto.
- À medida que forem usados, `web/` receberá o código do browser, `supabase/migrations/` o esquema versionado e `tests/` os testes.

## Montar a Sala 1 no editor

1. No painel **Sistema de Ficheiros**, abre `scenes/rooms/room_01.tscn` e escolhe **2D**. Seleciona `Background/Floor` e carrega em **F** para centrar. Usa a roda do rato para ajustar o zoom e arrasta com o botão do meio para navegar. A vista 2D permite ver os 2170 × 725 do cenário. No jogo, a câmara mostra uma janela 16:9 de 1280 × 720.
2. Para mover um beliche, seleciona-o em `Environment/BunkBeds`. Clica na ferramenta **Mover** na barra da vista 2D e arrasta o beliche pelo ponto junto aos pés. Podes também escrever as coordenadas no **Inspetor → Transform → Position**. Para redimensionar, edita **Scale** e mantém X e Y iguais para preservar a proporção.
3. Para acrescentar um beliche, seleciona um existente e usa **Ctrl+D**. Também podes arrastar `assets/modelos/room_01/bunk_bed.tscn` para `BunkBeds` na árvore da cena. Para acrescentar outro NPC, arrasta uma das nove cenas `prisoner_*.tscn`, em `assets/modelos/characters/prisoners/`, para **Characters → Prisoners**.
4. Seleciona **Camera2D** para ver o retângulo inicial e os limites na vista 2D. `WalkableArea` desenha a guia verde. As formas em `CollisionBoundaries` determinam os limites físicos. `Background` contém a parede e o chão separados. Para ajustar os beliches mais próximos da câmara, move os nós em **Foreground → ForegroundBunks**. Cada nó usa uma região do mesmo PNG, tem posição independente e serve de sobreposição visual. Usa o ícone do olho de `Reference` para ver a imagem de fundo completa.
5. Usa **Ctrl+S** para guardar, **F5** para iniciar o projeto ou **F6** para testar a cena aberta. Move o protagonista com **WASD** ou **setas**. Usa **F8** para voltar ao editor. O protagonista alterna entre repouso e movimento, e os prisioneiros têm animações em repouso.
6. Em **Characters → Sweeper**, o Inspetor permite editar os pontos da rota, a velocidade e a duração de cada paragem para varrer. Em **FilmEffect → Filter → Material**, podes ajustar a exposição, o grão e a vinheta. O material `effects/character_light.tres` controla o realce partilhado pelos personagens.
7. Em **Environment → Props**, podes mover o muro (`BrickWall`) e a lareira (`Fireplace`) separadamente. Cada modelo tem colisão na base.

## Primeira publicação

1. Instala os modelos de exportação da mesma versão do Godot. Em **Projeto → Exportar**, escolhe **Web** e usa `dist/index.html`. Com os modelos instalados, podes exportar pela linha de comandos.

   ```powershell
   New-Item -ItemType Directory -Path dist -Force | Out-Null
   godot --headless --path . --export-release Web dist/index.html
   ```

2. Abre a exportação via HTTP local ou usa **Executar no browser** no Godot. Verifica a inicialização WebGL, o carregamento de `.wasm` e `.pck` e a consola do browser. O preset usa uma única thread para servir o build sem configurar cabeçalhos de isolamento. [Exportação Web do Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
3. Com autorização, publica apenas o conteúdo de `dist/` no Netlify e confirma a abertura por HTTPS numa janela privada. Faz a primeira publicação técnica cedo e substitui-a pela versão jogável quando estiver pronta. O Netlify serve os ficheiros exportados e o GitHub guarda as fontes. [Deploy manual do Netlify](https://docs.netlify.com/deploy/create-deploys/)
4. Integra o Supabase no plano gratuito. A página Web trata do registo, login e logout com `supabase-js`. A página mantém a sessão, e o Godot comunica com ela via `JavaScriptBridge` para carregar e guardar o progresso. Testa a receção de emails num endereço externo se usarmos confirmação de conta, porque o SMTP incluído só entrega a membros da equipa do projeto. [Autenticação por palavra-passe](https://supabase.com/docs/guides/auth/passwords) · [SMTP do Supabase](https://supabase.com/docs/guides/auth/auth-smtp)
5. Guarda um registo por jogador em `player_progress`, com `user_id` e o último ponto de controlo. Usa Row Level Security para limitar a leitura e a escrita ao utilizador autenticado dono do registo. Usa a chave publicável no browser e mantém chaves privilegiadas fora do build. [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security) · [Chaves Supabase](https://supabase.com/docs/guides/getting-started/api-keys)
6. Automatiza os testes de registo e login, gravação e recuperação após reabrir o browser e isolamento entre duas contas. Acrescenta testes Godot sem interface para os controlos e as colisões da Sala 1 quando forem implementados. Documenta os comandos e regista os resultados de cada execução.

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

Os sete PNGs de cenário da Sala 1 e os catorze spritesheets importados foram fornecidos pelo responsável do projeto no pacote Last Winter. O ficheiro `Três beliches em madeira e tecido.png` foi importado como `room1_foreground_bunks.png`. Os PNGs copiados são idênticos aos originais. O Godot prepara texturas de trabalho e seleciona os fotogramas das animações por região. Os restantes spritesheets estão no pacote original. Registar aqui a autoria, as licenças e as fontes históricas conforme forem confirmadas.
