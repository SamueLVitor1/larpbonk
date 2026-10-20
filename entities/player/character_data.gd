class_name CharacterData
extends Resource
## Um personagem jogável. Cada um é um .tres em data/characters/.
## Por enquanto usado na tela de seleção; quando houver mais de um, o player
## passa a ler daqui o modelo (e, no futuro, arma inicial e status).

@export var display_name: String = ""
@export_multiline var description: String = ""
@export var model_scene: PackedScene
## Escala do modelo (o .glb do Gojo é grande e usa 0.268 no player).
@export var model_scale: float = 1.0
## Animação parada para a vitrine da seleção.
@export var idle_animation: String = "idle-loop"

@export_group("Retrato")
## Imagem do retrato. Vazio = o jogo "fotografa" o rosto do modelo 3D.
@export var portrait: Texture2D
## Altura da câmera do retrato automático (metros, já com a escala aplicada).
@export var portrait_height: float = 1.6
## Distância da câmera até o rosto.
@export var portrait_distance: float = 0.9
