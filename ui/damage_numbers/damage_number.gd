class_name DamageNumber
extends Label3D
## Número que salta de um inimigo atingido, sobe e some. Vem de um ObjectPool.

## Segundos até sumir.
@export var duration: float = 0.6
## Quanto sobe durante a animação (metros).
@export var rise_height: float = 0.8

var _time_left: float = 0.0
var _start: Vector3


func show_damage(at: Vector3, amount: float) -> void:
	# Pequeno desvio aleatório para números seguidos não ficarem um em cima do outro.
	_start = at + Vector3(randf_range(-0.3, 0.3), 0.0, randf_range(-0.3, 0.3))
	global_position = _start
	text = str(roundi(amount))
	modulate.a = 1.0
	_time_left = duration


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		ObjectPool.release_or_free(self)
		return
	var progress := 1.0 - _time_left / duration
	# ease out: sobe rápido e desacelera, com cara de "salto".
	global_position = _start + Vector3.UP * rise_height * ease(progress, 0.4)
	# Some só na segunda metade, para dar tempo de ler.
	modulate.a = clampf(2.0 - progress * 2.0, 0.0, 1.0)
