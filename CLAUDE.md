# Tung Tung Sahur Adventures

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
| `levels/` | Mapas/arenas (`test_arena/` para protótipo) |
| `ui/` | `hud/` e `menus/` |
| `autoload/` | Singletons globais — manter o mínimo (`game_manager`, `event_bus`) |

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
- Meta de protótipo: 300–500 inimigos na tela com FPS estável.

## Ideias futuras (backlog)

- **Ondas em grupos:** spawner às vezes solta vários inimigos juntos (grupinho/círculo fechando), em vez de só um por vez.
- **Inimigos se afastando uns dos outros:** hoje eles se sobrepõem num "bolo"; dá para adicionar uma separação simples por código (sem física).
- **Mais tipos de inimigo:** novas cenas herdadas de `base_enemy` + `.tres` (ex.: porco grande lento com muita vida).
- **Visual temático da bala:** trocar a esfera azul por algo do Gojo (Azul/Vermelho), com efeito de brilho. Se vier do Sketchfab: licença CC0/CC-BY (dar crédito) e low poly.
- **Exportar** para macOS (app não assinado → clique direito → Abrir) e Windows.

## Fluxo de trabalho

- Planos são revisados pelo dono do projeto antes de codar.
- Explicar o "porquê" das decisões ao implementar.
