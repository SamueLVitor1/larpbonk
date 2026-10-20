class_name CharacterSelect
extends Control
## Seleção de personagem: quadradinhos à esquerda, vitrine 3D + nome +
## descrição à direita. A escolha vai para o GameManager antes da partida.

@export var characters: Array[CharacterData] = []
## Quadradinhos com cadeado depois dos personagens ("tem mais por vir").
@export var locked_slots: int = 2
@export var slot_size := Vector2(140, 170)
## Graus por segundo da vitrine girando.
@export var spin_speed: float = 30.0
@export_file("*.tscn") var game_scene: String = "res://levels/temple/temple.tscn"
@export_file("*.tscn") var main_menu_scene: String = "res://ui/menus/main_menu/main_menu.tscn"

var _selected: CharacterData

@onready var slots: GridContainer = %Slots
@onready var model_pivot: Node3D = %ModelPivot
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var start_button: Button = %StartButton
@onready var back_button: Button = %BackButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_build_slots()
	if not characters.is_empty():
		_select(characters[0])
	start_button.grab_focus.call_deferred()


func _process(delta: float) -> void:
	model_pivot.rotate_y(deg_to_rad(spin_speed) * delta)


func _build_slots() -> void:
	# ButtonGroup: só um quadradinho fica "apertado" por vez.
	var group := ButtonGroup.new()
	for character in characters:
		var slot := _make_slot(character.display_name, _make_portrait(character))
		slot.button_group = group
		slot.toggle_mode = true
		slot.pressed.connect(_select.bind(character))
		slots.add_child(slot)
	if slots.get_child_count() > 0:
		(slots.get_child(0) as Button).button_pressed = true
	for i in locked_slots:
		var locked := _make_slot("???", null)
		locked.disabled = true
		locked.tooltip_text = "Em breve"
		slots.add_child(locked)


## Quadradinho estilo Megabonk: retrato em cima, nome embaixo.
func _make_slot(label: String, portrait: Control) -> Button:
	var slot := Button.new()
	slot.custom_minimum_size = slot_size
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE  # o clique vai para o botão
	slot.add_child(box)
	if portrait == null:
		var placeholder := Label.new()
		placeholder.text = "?"
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.add_theme_font_size_override("font_size", 48)
		placeholder.modulate = Color(1, 1, 1, 0.35)
		portrait = placeholder
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(portrait)
	var name_label := Label.new()
	name_label.text = label
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)
	return slot


## Imagem do .tres se houver; senão, uma mini câmera 3D apontada para o rosto.
func _make_portrait(character: CharacterData) -> Control:
	if character.portrait:
		var image := TextureRect.new()
		image.texture = character.portrait
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return image
	if character.model_scene == null:
		return null

	var container := SubViewportContainer.new()
	container.stretch = true
	var viewport := SubViewport.new()
	# Mundo próprio: o retrato não enxerga a vitrine grande (nem ela a ele).
	viewport.own_world_3d = true
	viewport.world_3d = World3D.new()
	viewport.world_3d.environment = _portrait_environment()
	viewport.transparent_bg = true
	container.add_child(viewport)

	var model := _instantiate_model(character)
	viewport.add_child(model)
	var camera := Camera3D.new()
	camera.fov = 30.0
	camera.position = Vector3(0.0, character.portrait_height, character.portrait_distance)
	viewport.add_child(camera)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30.0, 25.0, 0.0)
	viewport.add_child(light)
	return container


func _portrait_environment() -> Environment:
	var environment := Environment.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.8, 0.85)
	environment.ambient_light_energy = 0.6
	return environment


## Modelo na escala certa e fazendo a animação parada (sem isso fica em pose de T).
func _instantiate_model(character: CharacterData) -> Node3D:
	var model := character.model_scene.instantiate() as Node3D
	model.scale = Vector3.ONE * character.model_scale
	var anim := model.find_child("AnimationPlayer") as AnimationPlayer
	if anim:
		var idle := character.idle_animation
		if not anim.has_animation(idle):
			idle = idle.trim_suffix("-loop")
		if anim.has_animation(idle):
			anim.play.call_deferred(idle)
	return model


func _select(character: CharacterData) -> void:
	_selected = character
	name_label.text = character.display_name
	description_label.text = character.description
	_show_model(character)


func _show_model(character: CharacterData) -> void:
	for child in model_pivot.get_children():
		child.queue_free()
	model_pivot.rotation = Vector3.ZERO
	if character.model_scene == null:
		return
	model_pivot.add_child(_instantiate_model(character))


func _on_start_pressed() -> void:
	GameManager.selected_character = _selected
	get_tree().change_scene_to_file(game_scene)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(main_menu_scene)
