class_name DeathPuff
extends GPUParticles3D
## "Puf" de fumacinha quando um inimigo morre. Partículas de uma vez só
## (one_shot); volta para o pool quando termina. Vem de um ObjectPool.

var _time_left: float = 0.0


func play_at(at: Vector3) -> void:
	global_position = at
	restart()
	# Margem para as últimas partículas terminarem de sumir.
	_time_left = lifetime + 0.1


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		ObjectPool.release_or_free(self)
