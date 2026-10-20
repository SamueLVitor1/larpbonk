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
