@tool
class_name TerrainArea
extends Resource
## Um retângulo do HeightTerrain com altura definida à mão: chão plano, platô,
## fundo de lago ou rampa. Por cima do ruído dos morros; áreas posteriores na
## lista do terreno vencem as anteriores.

## Retângulo no plano X/Z, relativo ao centro do terreno (metros).
@export var rect := Rect2(-5, -5, 10, 10)
## Altura dentro do retângulo. Numa rampa, é a altura na borda de menor Z.
@export var height: float = 0.0
## Rampa: a altura vai de `height` (menor Z) até `height_end` (maior Z).
@export var ramp: bool = false
@export var height_end: float = 0.0
## Distância (fora do retângulo) em que a área se mistura com o relevo em volta.
## Pequena = parede íngreme (penhasco); grande = encosta suave.
@export var falloff: float = 4.0


## Quanto esta área manda no ponto: 1 dentro, caindo suave até 0 no falloff.
func weight_at(point: Vector2) -> float:
	var dx := maxf(maxf(rect.position.x - point.x, point.x - rect.end.x), 0.0)
	var dz := maxf(maxf(rect.position.y - point.y, point.y - rect.end.y), 0.0)
	var distance := sqrt(dx * dx + dz * dz)
	if falloff <= 0.0:
		return 1.0 if distance <= 0.0 else 0.0
	return 1.0 - smoothstep(0.0, falloff, distance)


func height_at(point: Vector2) -> float:
	if not ramp or rect.size.y <= 0.0:
		return height
	var t := clampf((point.y - rect.position.y) / rect.size.y, 0.0, 1.0)
	return lerpf(height, height_end, t)
