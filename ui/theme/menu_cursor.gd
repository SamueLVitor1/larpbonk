class_name MenuCursor
extends TextureRect
## Cursor ► estilo NES que acompanha o botão com foco (teclado ou mouse).
## Basta pôr na cena e apontar `menu` para o nó que contém os botões: ele pega
## todos os Button lá dentro que aceitam foco. Fora deles (ex.: quadradinhos da
## seleção), o cursor some. Passar o mouse num botão dá foco nele, então
## teclado e mouse mostram sempre o mesmo item.

## Nó acima dos botões que o cursor acompanha (procura em todos os níveis).
@export var menu: Node
## Duração de cada fase do pisca-pisca.
@export var blink_interval: float = 0.4
## Espaço, em pixels, entre o cursor e o texto.
@export var gap: float = 24.0

var _buttons: Array[Button] = []
var _blink_timer: Timer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true  # posição livre, sem depender de container
	hide()
	for node in menu.find_children("*", "Button", true, false):
		var button := node as Button
		if button.focus_mode == Control.FOCUS_NONE:
			continue
		_buttons.append(button)
		button.mouse_entered.connect(func() -> void:
			if not button.disabled:
				button.grab_focus())
	get_viewport().gui_focus_changed.connect(_on_focus_changed)

	_blink_timer = Timer.new()
	_blink_timer.wait_time = blink_interval
	_blink_timer.timeout.connect(func() -> void: self_modulate.a = 1.0 - self_modulate.a)
	add_child(_blink_timer)


func _on_focus_changed(control: Control) -> void:
	if control not in _buttons:
		hide()
		_blink_timer.stop()
		return
	# Containers só posicionam os filhos no fim do frame (ex.: menu que acabou
	# de abrir); antes disso a posição do botão ainda está errada.
	await get_tree().process_frame
	if control.get_viewport().gui_get_focus_owner() != control:
		return
	global_position = Vector2(
		control.global_position.x - size.x - gap,
		control.global_position.y + (control.size.y - size.y) / 2.0
	)
	# Reinicia o pisca para aparecer na hora em que troca de item.
	self_modulate.a = 1.0
	show()
	_blink_timer.start()
