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
| `systems/` | Lógica não-visual: `spawner/` (ondas), `pooling/` (reuso de objetos), `upgrades/` |
| `components/` | Nós reutilizáveis por composição: `health_component/`, `hurtbox_component/` (recebe dano), `hitbox_component/` (causa dano) |
| `data/` | Resources `.tres` com números do jogo (vida, dano, velocidade); sem código |
| `effects/` | Efeitos visuais (partículas), ex.: `death_puff/` |
| `levels/` | Mapas/arenas (`test_arena/` para protótipo) |
| `ui/` | `hud/` e `menus/` |
| `autoload/` | Singletons globais — manter o mínimo: `EventBus` (sinais) e `GameManager` (estado entre cenas) |

## Convenções

- Pastas e arquivos em `snake_case`; classes em `PascalCase` (`class_name BaseEnemy`).
- Código (variáveis, funções, classes) em inglês.
- Cena e script com o mesmo nome, na mesma pasta (`player.tscn` + `player.gd`).
- Sempre caminhos `res://`, nunca absolutos.
- Preferir composição (componentes) a hierarquias de herança profundas.
- Status/balanceamento ficam em `data/` (Resources `.tres`), não hardcoded em scripts. O script que define o Resource fica junto da entidade (ex.: `base_enemy/enemy_stats.gd` → `data/enemies/pig.tres`).
- Cada inimigo é uma **cena herdada** de `base_enemy.tscn` (base + modelo em `Model` + seu `.tres`), ex.: `enemies/pig/pig.tscn`. Não pendurar nós dentro de cenas instanciadas direto no level: o Godot descarta ao salvar.
- Modelos `.glb`: uma malha só, transforms aplicados, origem embaixo no centro (onde "pisa").
- Comunicação entre sistemas desacoplados via sinais do `event_bus`.
- `.gitkeep` mantém pastas vazias no Git; pode remover quando a pasta tiver arquivos.
- `.godot/` é cache local e fica fora do Git.

## Padrões do código

- **Grupos:** `"player"` (o player) e `"enemies"` (só inimigos *ativos*). Sistemas se acham por grupo, sem ligação manual na cena.
- **Pooling (`ObjectPool`):** `acquire()` / `release()`; o objeto pode ter `on_pool_acquire()` (resetar estado) e `on_pool_release()`. Para "morrer", usar `ObjectPool.release_or_free(self)` (funciona com ou sem pool). Cada sistema cria seu pool por código (`EnemyPool` no spawner, `ProjectilePool` na arma).
- O pool é `Node` (não `Node3D`) de propósito: os filhos não herdam a posição de quem está acima (balas não andam junto com o player).
- **Morte/sumir durante colisão → `call_deferred`:** desligar áreas no meio da checagem de colisão dá erro no Godot.
- **`HitboxComponent.hit_once`:** ligado = um acerto e para (bala, `reset()` ao reutilizar); desligado = dano contínuo (contato do inimigo, limitado pela invulnerabilidade do alvo).
- **Debug** (só no editor, em `test_arena.gd`): tecla **K** mata todos os inimigos; overlay com FPS e nº de inimigos. Para estresse, trocar o Config do spawner por `data/spawner/stress_spawn.tres`.

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
- Meta de protótipo: 300–500 inimigos na tela com FPS estável. **Medido:** 500 porcos a ~81 FPS (debug, Mac M2), ainda sem MultiMesh. Repetir o teste quando os inimigos pararem de se sobrepor.

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
  - [x] 7.5 `game_manager`: **não precisou** — o estado da partida vive nos sistemas e conversa pelo `EventBus`; recarregar a cena zera tudo

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

**Depois:** escolher itens do [BACKLOG.md](BACKLOG.md) (ex.: separação entre inimigos, mais inimigos, mais armas, menu principal).

### Lembretes para continuar
- Mudou `project.godot` (autoload, layers)? **Projeto → Recarregar Projeto Atual** no Godot.
- Se o Godot perguntar para recarregar uma cena alterada fora dele, escolha **recarregar** (não salvar por cima).
- ▶️ abre o menu principal; para testar direto a arena, abra `test_arena.tscn` e use **Rodar cena atual** (Cmd+R / F6).
- Testes rápidos: **K** mata todos; overlay mostra FPS/inimigos; para estresse, Config do spawner → `stress_spawn.tres`.

## Ideias futuras

Ficam no [BACKLOG.md](BACKLOG.md), organizadas por tema. Ao terminar uma, apagar de lá (o progresso fica no Roadmap acima).

## Fluxo de trabalho

- Planos são revisados pelo dono do projeto antes de codar.
- Explicar o "porquê" das decisões ao implementar.
