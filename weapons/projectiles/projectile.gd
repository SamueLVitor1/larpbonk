class_name Projectile
extends Node3D
## Bala que voa reto e some sozinha depois de um tempo.
## Feita para vir de um ObjectPool: launch() prepara tudo de novo a cada tiro.

@export var speed: float = 20.0
## Segundos até sumir se não acertar nada.
@export var lifetime: float = 2.0

var direction := Vector3.FORWARD
var _time_left: float = 0.0


## Posiciona e dispara. Chamado por quem atira, logo depois de pegar do pool.
func launch(from: Vector3, toward: Vector3) -> void:
	global_position = from
	direction = toward.normalized()
	_time_left = lifetime


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_time_left -= delta
	if _time_left <= 0.0:
		ObjectPool.release_or_free(self)
