class_name HordeSeparation
extends Node
## Empurra inimigos que estão se sobrepondo, para a horda se espalhar em vez de
## virar um "bolo" (500 porcos parecendo 10).
##
## Por quê centralizado: se cada inimigo procurasse os vizinhos sozinho, seriam
## 500 × 500 comparações. Aqui, uma vez por frame, os inimigos são separados
## numa grade de células (hash espacial); cada um só compara com quem está na
## própria célula e nas 8 vizinhas. Para aliviar mais, metade da horda é
## recalculada por frame (a outra metade usa o empurrão do frame anterior).
##
## O resultado vai para `BaseEnemy.separation` (direção × força, 0 a 1);
## o inimigo soma isso ao próprio passo antes de desviar dos obstáculos.

## Tamanho da célula do hash. Precisa ser ≥ maior soma de raios que importa
## (porco + Porco Rei ≈ 1,9 m), senão vizinhos sobrepostos escapam da busca.
@export var cell_size: float = 2.0

var _frame := 0


func _physics_process(_delta: float) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.size() < 2:
		return
	_frame += 1

	var cells := {}  # Vector2i -> Array[BaseEnemy]
	for node in enemies:
		var enemy := node as BaseEnemy
		if enemy == null:
			continue
		var key := _cell_of(enemy.global_position)
		if cells.has(key):
			cells[key].append(enemy)
		else:
			cells[key] = [enemy]

	for i in enemies.size():
		if (i + _frame) % 2 != 0:
			continue  # metade por frame
		var enemy := enemies[i] as BaseEnemy
		if enemy == null:
			continue
		enemy.separation = _push_for(enemy, cells)


## Soma dos empurrões de quem está perto demais: mais forte quanto mais sobreposto.
func _push_for(enemy: BaseEnemy, cells: Dictionary) -> Vector3:
	var push := Vector3.ZERO
	var position := enemy.global_position
	var key := _cell_of(position)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var neighbors: Array = cells.get(key + Vector2i(dx, dz), [])
			for other: BaseEnemy in neighbors:
				if other == enemy:
					continue
				var away := position - other.global_position
				away.y = 0.0
				var min_distance := enemy.body_radius + other.body_radius
				var distance_sq := away.length_squared()
				if distance_sq >= min_distance * min_distance:
					continue
				var distance := sqrt(distance_sq)
				if distance < 0.001:
					# Exatamente no mesmo ponto: escolhe um lado qualquer.
					away = Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1))
					distance = 0.001
				push += away / distance * (1.0 - distance / min_distance)
	return push.limit_length(1.0)


func _cell_of(position: Vector3) -> Vector2i:
	return Vector2i(floori(position.x / cell_size), floori(position.z / cell_size))
