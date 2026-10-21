# Larpbonk

Survivors-like 3D (inspirado no Megabonk), visual pixelado/low-poly simples.
Engine: **Godot 4.7.2** (GDScript), renderizador Forward+. Desenvolvido em Windows e macOS, sincronizado via Git.

## Estrutura (organização por funcionalidade)

Cada funcionalidade guarda cena, script e recursos próprios juntos.

| Pasta | Conteúdo |
|---|---|
| `assets/` | Arquivos brutos importados, sem lógica: `models/` (.glb do Blender), `textures/`, `audio/music`, `audio/sfx`, `fonts/`, `shaders/` |
| `entities/` | Coisas que vivem no mundo: `player/`, `enemies/` (`base_enemy/` + um subdiretório por inimigo), `pickups/` (XP, baús, cura) |
| `weapons/` | Armas automáticas (`base_weapon/`) e `projectiles/` |
| `systems/` | Lógica não-visual: `spawner/` (ondas), `pooling/` (reuso de objetos), `upgrades/`, `terrain/` (relevo + espalhar vegetação) |
| `components/` | Nós reutilizáveis por composição: `health_component/`, `hurtbox_component/` (recebe dano), `hitbox_component/` (causa dano) |
| `data/` | Resources `.tres` com números do jogo (vida, dano, velocidade); sem código |
| `effects/` | Efeitos visuais (partículas), ex.: `death_puff/` |
| `levels/` | Mapas: `base_level/` (sistemas comuns) + um subdiretório por mapa com `props/` e `materials/` próprios (`temple/`; `test_arena/` para protótipo/estresse) |
| `ui/` | `hud/`, `menus/` e `theme/` (`larpbonk_theme.tres` + `palette.gd` com as cores) |
| `autoload/` | Singletons globais — manter o mínimo: `EventBus` (sinais), `GameManager` (estado entre cenas) e `SceneLoader` (troca de cena com tela de carregamento) |

## Convenções

- Pastas e arquivos em `snake_case`; classes em `PascalCase` (`class_name BaseEnemy`).
- Código (variáveis, funções, classes) em inglês.
- Cena e script com o mesmo nome, na mesma pasta (`player.tscn` + `player.gd`).
- Sempre caminhos `res://`, nunca absolutos.
- Preferir composição (componentes) a hierarquias de herança profundas.
- Status/balanceamento ficam em `data/` (Resources `.tres`), não hardcoded em scripts. O script que define o Resource fica junto da entidade (ex.: `base_enemy/enemy_stats.gd` → `data/enemies/pig.tres`).
- Cada inimigo é uma **cena herdada** de `base_enemy.tscn` (base + modelo em `Model` + seu `.tres`), ex.: `enemies/pig/pig.tscn`. Não pendurar nós dentro de cenas instanciadas direto no level: o Godot descarta ao salvar.
- Cada mapa é uma **cena herdada** de `levels/base_level/base_level.tscn` (player, spawners, HUD, menus, debug) e só acrescenta o cenário (`WorldEnvironment`, luz, chão, obstáculos). Sistema novo comum a todos os mapas entra na base. Mapa fechado define `spawn_areas` (lista de `Rect2` X/Z; vale estar em qualquer uma) no `EnemySpawner` herdado; lista vazia = sem limite.
- Modelos `.glb`: uma malha só, transforms aplicados, origem embaixo no centro (onde "pisa").
- Comunicação entre sistemas desacoplados via sinais do `event_bus`.
- **Entrar num mapa → `SceneLoader.change_scene(path)` / `SceneLoader.reload()`**, nunca `change_scene_to_file` direto: carrega em outra thread e esconde a montagem do mapa (relevo, scatter, pools, shaders) atrás do "CARREGANDO...". Menus leves podem trocar direto.
- `.gitkeep` mantém pastas vazias no Git; pode remover quando a pasta tiver arquivos.
- `.godot/` é cache local e fica fora do Git.
- **UI:** resolução base 1920×1080 (stretch `canvas_items`, janela abre em 1280×720); tamanhos de UI pensados nessa escala. Estilo NES: fonte Press Start 2P (`assets/fonts/`, importada sem antialiasing, tamanhos múltiplos de 8), cores em `Palette`, item de menu sem caixa (destaque = amarelo + cursor ►, via componente `MenuCursor` em `ui/theme/`: aponte `menu` para o nó dos botões). Variações do Theme: `MenuTitle`, `MenuText`, `CharacterSlot`, `VersionLabel`. Texturas pixel art com filtro Nearest (padrão do projeto).

## Padrões do código

- **Grupos:** `"player"` (o player), `"enemies"` (só inimigos *ativos*) e `"bosses"` (chefes; podem ser travados com **R**). Sistemas se acham por grupo, sem ligação manual na cena.
- **Mira travada (R):** `LockOn` (nó do player) escolhe o chefe mais perto e emite `EventBus.lock_on_changed(target)`; a arma prioriza o alvo (se no alcance) com balas que atravessam o resto (`HitboxComponent.only_target`) e a HUD desenha a mira (`LockOnReticle`). A câmera **não** é travada (fica livre com o mouse). `BaseEnemy.aim_height` diz para onde mirar em cada inimigo.
- **Pooling (`ObjectPool`):** `acquire()` / `release()`; o objeto pode ter `on_pool_acquire()` (resetar estado) e `on_pool_release()`. Para "morrer", usar `ObjectPool.release_or_free(self)` (funciona com ou sem pool). Cada sistema cria seu pool por código (`EnemyPool` no spawner, `ProjectilePool` na arma).
- O pool é `Node` (não `Node3D`) de propósito: os filhos não herdam a posição de quem está acima (balas não andam junto com o player).
- **Morte/sumir durante colisão → `call_deferred`:** desligar áreas no meio da checagem de colisão dá erro no Godot.
- **`HitboxComponent.hit_once`:** ligado = um acerto e para (bala, `reset()` ao reutilizar); desligado = dano contínuo (contato do inimigo, limitado pela invulnerabilidade do alvo).
- **Relevo (`HeightTerrain`, `@tool`):** ruído + `TerrainArea` (plano/platô/rampa/lago) → malha low-poly, colisão do player e grade de alturas. Quem não usa física (inimigos, spawner, gemas) pergunta `HeightTerrain.ground_height(x, z)`; sem terreno = 0. Mudou algo e não atualizou no editor → botão **Regerar terreno** no Inspetor.
- **`TerrainScatter`** (filho do terreno): espalha uma cena (com colisão) ou uma malha (`MultiMesh`, ex.: grama) com semente fixa; as cópias não ficam salvas no `.tscn`.
- **Debug** (só no editor, em `base_level.gd`, vale para todo mapa): tecla **K** mata todos os inimigos; **G** mostra a grade de obstáculos; **F** mostra as setinhas do campo de fluxo; **I** liga/desliga o player imortal; overlay com FPS, nº de inimigos e objetos em uso por pool (`ObjectPool.all`, ex.: `Gem: 2400`). Para estresse, trocar o Config do spawner por `data/spawner/stress_spawn.tres`.

## Camadas de colisão (3D)

| Layer | Nome | Uso |
|---|---|---|
| 1 | `world` | Chão, paredes |
| 2 | `player` | Corpo do player |
| 3 | `enemies` | Corpo dos inimigos |
| 4 | `player_hurtbox` | Hurtbox do player (mask das hitboxes de inimigos) |
| 5 | `enemy_hurtbox` | Hurtbox dos inimigos (mask das hitboxes de projéteis) |

## Performance (crítico para survivors-like)

- Inimigos, projéteis e gemas de XP passam por pooling; evitar `instantiate()`/`queue_free()` em massa.
- Inimigos não usam física completa por unidade; preferir movimento simples no código.
- Considerar `MultiMeshInstance3D` para muitos inimigos iguais.
- Meta de protótipo: 300–500 inimigos na tela com FPS estável. **Medido:** 500 porcos a ~81 FPS (debug, Mac M2), ainda sem MultiMesh. No Windows (Intel Iris Xe, debug, sem vsync): 500 porcos a ~86 FPS na `test_arena` e no pátio do templo, ~67 FPS no meio do jardim (vegetação + sombras).
- **Depois do passo 14** (porcos espalhados, Mac M2, debug): o gargalo é **desenho**, não código (com o jogo pausado o frame continuava em 65 ms). Causas: o porco tem **8 partes/materiais** (500 × 8 = ~4.000 desenhos) e cada sombra redesenha tudo nas cascatas do sol. Tirar a sombra da horda: 65 → ~22 ms. Próximo grande ganho: **MultiMesh da horda** (ver Roadmap 15).
- **Modelos de horda/props repetidos:** custo = nº de materiais × nº de cópias na tela. Para eles: **1 malha e 1 material** (textura de paleta pequena, UVs nos quadradinhos de cor, filtro Nearest), ~1.000 triângulos no máximo (props 300–800). Player e chefes podem ter mais (são um só).
- **Teto de vizinhos** no `HordeSeparation` (`max_neighbor_checks`): sem ele, horda espremida num canto vira centenas × centenas de comparações (caiu para 4 FPS).

## Roadmap (progresso)

Feito em passos pequenos, cada um testado no jogo antes do próximo (e um commit por passo).

- [x] **1. Vida e dano** — `HealthComponent` (vida, invulnerabilidade, `reset()`), `HurtboxComponent` (recebe), `HitboxComponent` (causa, `hit_once`).
- [x] **2. Primeiro inimigo**
  - [x] 2.1 `EnemyStats` + `data/enemies/pig.tres`
  - [x] 2.2 Cena base `base_enemy.tscn` (componentes + lê o `.tres`)
  - [x] 2.3 Persegue o player (sem física, vira para ele)
  - [x] 2.4 `pig.tscn` = cena herdada da base + modelo do porco
  - [x] 2.5 Tecla **K** (debug) mata todos
- [x] **3. Spawner**
  - [x] 3.1 Spawna num círculo em volta do player
  - [x] 3.2 Só fora da câmera
  - [x] 3.3 Ritmo acelera com o tempo (rampa)
  - [x] 3.4 `SpawnerConfig` + `data/spawner/default_spawn.tres`
- [x] **4. Pooling**
  - [x] 4.1 `ObjectPool` genérico
  - [x] 4.2 Inimigo com `on_pool_acquire/release`
  - [x] 4.3 Spawner usa o pool
  - [x] 4.4 Estresse: 500 porcos a ~81 FPS (overlay de FPS no debug)
- [x] **5. Arma automática**
  - [x] 5.1 Projétil (esfera azul) voando reto
  - [x] 5.2 `BaseWeapon` mira no inimigo mais perto
  - [x] 5.3 Acerto: dano, inimigo morre e volta pro pool
  - [x] 5.4 `WeaponStats` + `data/weapons/blue_orb.tres`, pool de balas, aquecimento de shader
- [x] **6. XP e level up**
  - [x] 6.1 `EventBus` (autoload) + gema de XP ao morrer (`DropSpawner`)
  - [x] 6.2 Ímã e coleta (`pickup_radius` no player)
  - [x] 6.3 `ExperienceComponent` + `data/player/experience.tres` + HUD com barra de XP e nível
  - [x] 6.4 Tela de level up: 3 cartas (`UpgradeData` em `data/upgrades/`, `UpgradeManager`, `LevelUpMenu`)
- [x] **7. HUD e game over**
  - [x] 7.1 Barra de vida do player na HUD (via `EventBus`)
  - [x] 7.2 Cronômetro da partida na HUD
  - [x] 7.3 Game over: ao morrer, pausa e mostra tela com tempo sobrevivido e nível (`GameOverMenu`)
  - [x] 7.4 Botão "Jogar de novo" (recarrega a cena)
  - [x] 7.5 `game_manager`: não precisou aqui (o estado da partida vive nos sistemas e conversa pelo `EventBus`; recarregar a cena zera tudo). Criado depois, no passo 10, só para o estado entre cenas

- [x] **8. Game feel**
  - [x] 8.1 Inimigo pisca branco ao tomar dano (`material_overlay`)
  - [x] 8.2 Números de dano subindo (`Label3D` com pool, `EventBus.enemy_damaged`)
  - [x] 8.3 "Puf" de partículas ao morrer (`effects/death_puff/`, `GPUParticles3D` one-shot com pool)
  - [x] 8.4 Câmera treme quando o player toma dano (`h_offset`/`v_offset` no `CameraRig`)

- [x] **9. Menus**
  - [x] 9.1 Menu principal (`ui/menus/main_menu/`): Jogar / Sair; é a cena principal do projeto
  - [x] 9.2 Pausa no Esc: Continuar / Recomeçar / Menu principal (`ui/menus/pause_menu/`; só abre se nada mais pausou o jogo)
  - [x] 9.3 Game over com botão "Menu principal"
- [x] **10. Seleção de personagem**
  - [x] 10.1 `CharacterData` (`entities/player/character_data.gd`) + `data/characters/gojo.tres`
  - [x] 10.2 Tela `ui/menus/character_select/`: quadradinhos (+2 com cadeado) e vitrine 3D girando com nome/descrição
  - [x] 10.3 `GameManager` (autoload) guarda `selected_character`. **O player ainda não lê** (só existe o Gojo); ao criar o 2º personagem, o player deve trocar modelo/arma a partir dele

- [x] **11. Mapas**
  - [x] 11.1 `BaseLevel` (`levels/base_level/`) com os sistemas comuns; `test_arena` vira cena herdada só com o cenário
  - [x] 11.2 Templo (`levels/temple/`): pátio 80×80 fechado por muro, peças reutilizáveis em `props/` (muro, pilar, lanterna, torii) com colisão para o player; `EnemySpawner.spawn_areas` impede porcos fora do mapa. A seleção de personagem abre o templo. **Inimigos e balas ainda atravessam obstáculos** (sem física)
  - [x] 11.3 Relevo: `HeightTerrain` + `TerrainArea` (`systems/terrain/`); inimigos, spawner e gemas seguem a altura do chão
  - [x] 11.4 Jardim ao norte do templo (160×120): morros, platô de 10 m com rampa, cachoeira (`props/waterfall.tscn` + `assets/shaders/water.gdshader`), lago raso, vegetação via `TerrainScatter`, sebe + paredes invisíveis na borda. `spawn_areas` com 2 retângulos (templo + jardim)

- [x] **12. Primeiro chefe**
  - [x] 12.1 Porco Rei (`entities/enemies/king_pig/`, `data/enemies/king_pig.tres`): cena herdada, ~3,5 m, 300 de vida
  - [x] 12.2 `BossSpawner` na `base_level`: solta o chefe uma vez em `spawn_time` (**30 s, só para teste**)
  - [x] 12.3 Travar mira no chefe com **R** (mira na HUD, tiros focados que atravessam a horda; câmera livre)

- [x] **13. UI estilo NES (começo)**
  - [x] 13.1 Menu principal novo (logo LARPBONK, cursor ► piscando, paisagem pixel art), feito no Claude Design
  - [x] 13.2 `ui/theme/larpbonk_theme.tres` + `Palette`; aplicado **só** no menu principal por enquanto
  - [x] 13.3 Resolução base 1920×1080; HUD e menus antigos reescalados (×1,667)
  - [x] 13.4 Tela de carregamento (`SceneLoader` + `ui/loading_screen/`): tira a travadinha ao entrar no mapa, recomeçar e jogar de novo
  - [x] 13.5 Pausa, game over e seleção de personagem no estilo NES (`MenuCursor` reutilizável)

- [ ] **14. Movimento da horda** ← *em andamento*
  - [x] 14.1 `ObstacleGrid` (`systems/navigation/`, na `BaseLevel`): obstáculos (`StaticBody3D` menos o terreno) viram células bloqueadas ao montar o mapa; `ObstacleGrid.is_blocked(x, z)`; tecla **G** (debug) mostra as células
  - [x] 14.2 Inimigo desliza na parede (`BaseEnemy.body_radius`; tenta direto, só X, só Z)
  - [x] 14.3 Spawner (e `BossSpawner`, que usa a mesma função) não solta inimigo em célula bloqueada
  - [x] 14.4 Balas e obstáculos: **por arma** (`WeaponStats.stopped_by_obstacles`). A orb azul **atravessa** de propósito (mira automática + parar no muro = tiro perdido e frustração); armas futuras (flecha, pedra) podem parar. Checagem em `Projectile._hit_obstacle`, pela grade
  - [x] 14.5 `HordeSeparation` (`systems/navigation/`, na `BaseLevel`): hash espacial por frame (células de 2 m, metade da horda por frame) → `BaseEnemy.separation`, somado ao passo antes do `_slide`
  - [ ] 14.6 Teste de estresse de novo ← *parou aqui*
    - Feito: horda espalhada a ~22 ms/frame (sem sombra); correção do "bolo" em volta de lanterna/muro (4 → 47 FPS)
    - **Pendente:** depois de matar o Porco Rei e subir muitos níveis o frame foi a ~91 ms (13 FPS). Suspeita: **gemas acumulando** sem limite (no caos nascem 50 porcos/s). Rodar de novo e ler o overlay (Gem/Projectile/DamageNumber). Se forem as gemas: limite de gemas que, passado, soma o XP numa gema grande
    - **Pendente:** olhar a aba **Erros (5)** do Depurador
  - [x] 14.7 `FlowField` (`systems/navigation/`, na `BaseLevel`): BFS a partir do player a cada 0,25 s numa janela de 40 m; inimigo segue a setinha da célula (`FlowField.direction_at`) e o `_slide` continua como segurança; tecla **F** (debug) mostra as setinhas

- [ ] 14.8 **Escalada:** player pode subir em lanternas/muros (estruturas escaláveis); inimigos devem escalar também (guardar altura do topo por célula no `ObstacleGrid`, limite tipo 4 m; paredes invisíveis não). **Decidir:** todos escalam ou o Porco Rei fica embaixo?
- [ ] **15. MultiMesh da horda** (planejar): um `MultiMeshInstance3D` desenha todos os porcos (8 desenhos no total em vez de ~4.000); os nós continuam com a lógica, só o visual sai deles. O piscar branco vira cor por instância (shader). Confirmar antes em Depurador → Monitores → total de draw calls

**Depois:** escolher itens do [BACKLOG.md](BACKLOG.md) (ex.: separação entre inimigos, inimigos/balas colidindo com obstáculos, mais inimigos, mais armas, sons).

### Lembretes para continuar
- Mudou `project.godot` (autoload, layers)? **Projeto → Recarregar Projeto Atual** no Godot.
- Se o Godot perguntar para recarregar uma cena alterada fora dele, escolha **recarregar** (não salvar por cima).
- ▶️ abre o menu principal (→ templo); para testar direto um mapa, abra `temple.tscn` ou `test_arena.tscn` e use **Rodar cena atual** (Cmd+R / F6).
- Testes rápidos: **K** mata todos; overlay mostra FPS/inimigos; para estresse, Config do spawner → `stress_spawn.tres`.

## Ideias futuras

Ficam no [BACKLOG.md](BACKLOG.md), organizadas por tema. Ao terminar uma, apagar de lá (o progresso fica no Roadmap acima).

## Fluxo de trabalho

- Planos são revisados pelo dono do projeto antes de codar.
- Explicar o "porquê" das decisões ao implementar.
