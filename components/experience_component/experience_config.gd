class_name ExperienceConfig
extends Resource
## Quanto XP cada nível pede: base_xp + xp_growth * (nível - 1).
## Ex.: 5, 8, 11, 14... com os valores padrão.

## XP para ir do nível 1 ao 2.
@export var base_xp: float = 5.0
## Quanto a mais cada nível seguinte pede.
@export var xp_growth: float = 3.0
