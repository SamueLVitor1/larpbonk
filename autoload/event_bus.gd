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

## Hora de escolher: `choices` são as cartas (UpgradeData) sorteadas.
@warning_ignore("unused_signal")
signal upgrade_choices_offered(choices: Array)

## O jogador escolheu esta carta.
@warning_ignore("unused_signal")
signal upgrade_chosen(upgrade: UpgradeData)

## Vida do player mudou (dano, cura ou aumento da vida máxima).
@warning_ignore("unused_signal")
signal player_health_changed(current: float, max_value: float)

## Tempo da partida, avisado uma vez por segundo (pausa não conta).
@warning_ignore("unused_signal")
signal run_time_changed(seconds: int)
