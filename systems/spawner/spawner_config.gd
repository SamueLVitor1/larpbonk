class_name SpawnerConfig
extends Resource
## Balanceamento do spawner. Cada configuração (dificuldade, fase) é um .tres
## em data/spawner/; o spawner só lê daqui.

## Intervalo entre inimigos no começo da partida (segundos).
@export var start_interval: float = 1.5
## Intervalo mínimo, alcançado ao fim da rampa.
@export var end_interval: float = 0.3
## Quanto tempo (segundos) leva para ir do start ao end.
@export var ramp_duration: float = 180.0
## Distância do player em que os inimigos nascem (metros).
@export var spawn_radius: float = 15.0
## Teto de inimigos vivos, para não travar enquanto não há pooling.
@export var max_enemies: int = 100
