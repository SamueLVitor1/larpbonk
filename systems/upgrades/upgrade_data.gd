class_name UpgradeData
extends Resource
## Uma carta de upgrade. Cada uma é um .tres em data/upgrades/:
## para criar um upgrade novo de um stat que já existe, basta um arquivo novo.

enum Stat {
	WEAPON_DAMAGE,  ## amount = fração (0.2 = +20%)
	FIRE_RATE,      ## amount = fração (0.15 = atira 15% mais rápido)
	MOVE_SPEED,     ## amount = fração
	PICKUP_RADIUS,  ## amount = fração
	MAX_HEALTH,     ## amount = pontos de vida (também cura esse tanto)
}

@export var title: String = ""
@export_multiline var description: String = ""
@export var stat: Stat = Stat.WEAPON_DAMAGE
@export var amount: float = 0.2
