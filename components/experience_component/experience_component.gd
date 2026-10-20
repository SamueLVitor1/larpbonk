class_name ExperienceComponent
extends Node
## Soma o XP coletado e sobe de nível. Escuta e avisa pelo EventBus,
## assim HUD e tela de upgrade não precisam conhecer o player.

signal leveled_up(new_level: int)

@export var config: ExperienceConfig

var level: int = 1
var xp: float = 0.0


func _ready() -> void:
	EventBus.xp_collected.connect(add_xp)
	# Deferred: a HUD pode entrar na cena depois do player e perderia o primeiro aviso.
	_announce.call_deferred()


func xp_to_next_level() -> float:
	if config == null:
		return 5.0
	return config.base_xp + config.xp_growth * (level - 1)


## O while cobre o caso de uma gema grande valer mais de um nível;
## o XP que sobra passa para o próximo.
func add_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		leveled_up.emit(level)
		EventBus.player_leveled_up.emit(level)
	_announce()


func _announce() -> void:
	EventBus.player_xp_changed.emit(xp, xp_to_next_level(), level)
