extends Node
## Sinais globais para sistemas que não se conhecem conversarem.
## Ex.: o inimigo avisa que morreu; quem solta gemas escuta, sem um saber do outro.
## Registrado como autoload "EventBus" no project.godot.

## Um inimigo morreu em `position` e vale `xp_value` de experiência.
@warning_ignore("unused_signal")
signal enemy_died(position: Vector3, xp_value: float)

## O player coletou uma gema que valia `amount` de experiência.
@warning_ignore("unused_signal")
signal xp_collected(amount: float)

## XP do player mudou: `current` de `needed` para o próximo nível, no nível `level`.
@warning_ignore("unused_signal")
signal player_xp_changed(current: float, needed: float, level: int)

## O player subiu para o nível `level`.
@warning_ignore("unused_signal")
signal player_leveled_up(level: int)
