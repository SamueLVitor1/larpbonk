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
- Status/balanceamento ficam em `data/` (Resources), não hardcoded em scripts.
- Comunicação entre sistemas desacoplados via sinais do `event_bus`.
- `.gitkeep` mantém pastas vazias no Git; pode remover quando a pasta tiver arquivos.
- `.godot/` é cache local e fica fora do Git.

## Performance (crítico para survivors-like)

- Inimigos, projéteis e gemas de XP passam por pooling; evitar `instantiate()`/`queue_free()` em massa.
- Inimigos não usam física completa por unidade; preferir movimento simples no código.
- Considerar `MultiMeshInstance3D` para muitos inimigos iguais.
- Meta de protótipo: 300–500 inimigos na tela com FPS estável.

## Fluxo de trabalho

- Planos são revisados pelo dono do projeto antes de codar.
- Explicar o "porquê" das decisões ao implementar.
