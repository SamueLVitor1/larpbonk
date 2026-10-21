class_name BaseLevel
extends Node3D
## Base de todo mapa: player, spawners, HUD e menus. Cada mapa é uma cena
## herdada desta e só acrescenta o cenário (luz, céu, chão, obstáculos).
## Também guarda atalhos de debug, que só funcionam rodando pelo editor
## (somem num jogo exportado).

var _debug_label: Label


func _ready() -> void:
	if OS.is_debug_build():
		_create_debug_overlay()


## Texto no canto da tela com FPS e inimigos ativos, para os testes de estresse.
func _create_debug_overlay() -> void:
	var layer := CanvasLayer.new()
	_debug_label = Label.new()
	_debug_label.position = Vector2(12, 22)
	_debug_label.add_theme_font_size_override("font_size", 20)
	_debug_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_debug_label.add_theme_constant_override("outline_size", 6)
	layer.add_child(_debug_label)
	add_child(layer)


func _process(_delta: float) -> void:
	if _debug_label:
		_debug_label.text = "FPS: %d\nInimigos: %d" % [
			Engine.get_frames_per_second(),
			get_tree().get_nodes_in_group("enemies").size(),
		] + ("\nIMORTAL" if _player_invincible() else "")


func _player_invincible() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Player
	return player != null and player.health.invincible


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_K:
		_kill_all_enemies()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I:
		_toggle_invincible()


func _toggle_invincible() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	player.health.invincible = not player.health.invincible
	print("[debug] imortal: %s" % ("LIGADO" if player.health.invincible else "desligado"))


## Mata pelo HealthComponent (em vez de apagar direto), para testar o mesmo
## caminho de morte que as armas vão usar.
func _kill_all_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy is BaseEnemy:
			enemy.health.take_damage(enemy.health.current_health)
	print("[debug] %d inimigo(s) morto(s)" % enemies.size())
