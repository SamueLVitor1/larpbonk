extends Node3D
## Arena de protótipo. Também guarda atalhos de debug, que só funcionam
## rodando pelo editor (somem num jogo exportado).


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_K:
		_kill_all_enemies()


## Mata pelo HealthComponent (em vez de apagar direto), para testar o mesmo
## caminho de morte que as armas vão usar.
func _kill_all_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy is BaseEnemy:
			enemy.health.take_damage(enemy.health.current_health)
	print("[debug] %d inimigo(s) morto(s)" % enemies.size())
