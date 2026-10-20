class_name HealthComponent
extends Node
## Guarda a vida de quem o possui. Só emite sinais: quem decide o que fazer
## na morte é o dono (player → game over, inimigo → volta pro pool).

signal health_changed(current: float, max_value: float)
signal damaged(amount: float)
signal died

@export var max_health: float = 100.0
## Tempo sem tomar dano após um acerto. Player ~0.5s; inimigos normalmente 0.
@export var invulnerability_time: float = 0.0

var current_health: float
var is_dead := false

var _invulnerable_until: float = 0.0


func _ready() -> void:
	reset()


func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0 or is_invulnerable():
		return
	current_health = maxf(current_health - amount, 0.0)
	_invulnerable_until = _now() + invulnerability_time
	damaged.emit(amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		is_dead = true
		died.emit()


func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current_health = minf(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


## Volta à vida cheia. Essencial para objetos reaproveitados pelo pooling.
func reset() -> void:
	current_health = max_health
	is_dead = false
	_invulnerable_until = 0.0
	health_changed.emit(current_health, max_health)


func is_invulnerable() -> bool:
	return _now() < _invulnerable_until


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
