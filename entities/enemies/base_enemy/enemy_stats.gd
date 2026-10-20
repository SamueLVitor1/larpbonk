class_name EnemyStats
extends Resource
## Números de um tipo de inimigo. Cada inimigo ganha um .tres em data/enemies/,
## assim dá para balancear pelo Inspector sem mexer em código.

@export var max_health: float = 30.0
## Dano por contato no player.
@export var contact_damage: float = 10.0
## Metros por segundo. Referência: o player anda a 6.
@export var move_speed: float = 3.0
## Quanto de XP vale a gema que ele solta ao morrer.
@export var xp_value: float = 1.0
