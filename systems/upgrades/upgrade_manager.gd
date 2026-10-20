class_name UpgradeManager
extends Node
## Escuta o level up, sorteia cartas e aplica a escolhida.
## Conversa com a tela de cartas só pelo EventBus (um não conhece o outro).

@export var upgrades: Array[UpgradeData] = []
@export var choices_per_level: int = 3

## Level ups ainda sem carta escolhida (vários de uma vez = várias telas seguidas).
var _pending_level_ups: int = 0
var _menu_open := false


func _ready() -> void:
	EventBus.player_leveled_up.connect(_on_player_leveled_up)
	EventBus.upgrade_chosen.connect(_on_upgrade_chosen)


func _on_player_leveled_up(_level: int) -> void:
	_pending_level_ups += 1
	if not _menu_open:
		_offer_choices()


func _offer_choices() -> void:
	if upgrades.is_empty():
		_pending_level_ups = 0
		return
	var pool := upgrades.duplicate()
	pool.shuffle()
	_menu_open = true
	EventBus.upgrade_choices_offered.emit(pool.slice(0, choices_per_level))


func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	_menu_open = false
	_pending_level_ups = maxi(_pending_level_ups - 1, 0)
	_apply(upgrade)
	if _pending_level_ups > 0:
		_offer_choices()


func _apply(upgrade: UpgradeData) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	var weapon := _find_weapon(player)
	match upgrade.stat:
		UpgradeData.Stat.WEAPON_DAMAGE:
			if weapon:
				weapon.stats.damage *= 1.0 + upgrade.amount
		UpgradeData.Stat.FIRE_RATE:
			if weapon:
				# Mais rápido = intervalo menor: dividir mantém o "+15%" honesto.
				weapon.stats.fire_interval /= 1.0 + upgrade.amount
		UpgradeData.Stat.MOVE_SPEED:
			player.move_speed *= 1.0 + upgrade.amount
		UpgradeData.Stat.PICKUP_RADIUS:
			player.pickup_radius *= 1.0 + upgrade.amount
		UpgradeData.Stat.MAX_HEALTH:
			player.health.max_health += upgrade.amount
			player.health.heal(upgrade.amount)
	print("Upgrade: %s" % upgrade.title)


## Por enquanto o player tem uma arma só; com várias, o upgrade vai precisar dizer qual.
func _find_weapon(player: Node) -> BaseWeapon:
	for child in player.get_children():
		if child is BaseWeapon:
			return child
	return null
