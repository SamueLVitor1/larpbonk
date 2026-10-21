class_name Projectile
extends Node3D
## Bala que voa reto e some sozinha depois de um tempo.
## Feita para vir de um ObjectPool: launch() prepara tudo de novo a cada tiro.

@export var speed: float = 20.0
## Segundos até sumir se não acertar nada.
@export var lifetime: float = 2.0
## Some ao bater em obstáculos (vem do WeaponStats a cada tiro).
@export var stopped_by_obstacles: bool = false

var direction := Vector3.FORWARD
var _time_left: float = 0.0
## Só "arma" a checagem de muro depois de passar por uma célula livre: o player
## colado num pilar está numa célula bloqueada, e a bala sumiria ao nascer.
var _armed := false

@onready var hitbox: HitboxComponent = $HitboxComponent


func _ready() -> void:
	hitbox.hit.connect(_on_hit)


## Posiciona e dispara. Chamado por quem atira, logo depois de pegar do pool.
## Com stats, usa os números da arma; sem, usa os padrões do Inspector.
## Com only_target, a bala atravessa todos os outros inimigos (mira travada).
func launch(from: Vector3, toward: Vector3, stats: WeaponStats = null, only_target: Node = null) -> void:
	if stats:
		speed = stats.projectile_speed
		lifetime = stats.projectile_lifetime
		hitbox.damage = stats.damage
		stopped_by_obstacles = stats.stopped_by_obstacles
	global_position = from
	direction = toward.normalized()
	_time_left = lifetime
	_armed = false
	hitbox.only_target = only_target
	hitbox.reset()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_time_left -= delta
	if _time_left <= 0.0 or _hit_obstacle():
		_despawn()


## Bateu em muro/pilar/árvore? Usa a grade do ObstacleGrid (sem física) e só
## conta na faixa de altura que bloqueia (passa por cima de obstáculos baixos
## e por baixo da viga do torii, igual aos inimigos).
func _hit_obstacle() -> bool:
	if not stopped_by_obstacles:
		return false
	var blocked := ObstacleGrid.is_blocked(global_position.x, global_position.z)
	if not _armed:
		_armed = not blocked
		return false
	if not blocked:
		return false
	var height := global_position.y - HeightTerrain.ground_height(global_position.x, global_position.z)
	return height <= ObstacleGrid.active.probe_top


## Acertou: some. Deferred porque o acerto acontece no meio da checagem de
## colisão, e desligar a área nesse momento dá erro no Godot.
func _on_hit(_hurtbox: HurtboxComponent) -> void:
	_despawn.call_deferred()


func _despawn() -> void:
	ObjectPool.release_or_free(self)
