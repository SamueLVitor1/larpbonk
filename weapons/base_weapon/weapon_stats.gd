class_name WeaponStats
extends Resource
## Números de uma arma. Cada arma ganha um .tres em data/weapons/;
## upgrades vão mexer nestes valores.

@export var damage: float = 10.0
## Segundos entre tiros.
@export var fire_interval: float = 0.8
## Só atira em inimigos até essa distância (metros).
@export var fire_range: float = 15.0
## Metros por segundo.
@export var projectile_speed: float = 20.0
## Segundos até a bala sumir se não acertar nada.
@export var projectile_lifetime: float = 2.0
## Bala some ao bater em muro/pilar/árvore (ObstacleGrid). Desligado = atravessa:
## com mira automática, perder tiro na parede frustra (a orb azul atravessa).
@export var stopped_by_obstacles: bool = false
