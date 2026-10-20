class_name LevelUpMenu
extends CanvasLayer
## Tela de cartas do level up. Pausa o jogo, mostra as opções que chegam pelo
## EventBus e devolve a escolhida. process_mode = Always para funcionar pausada.

@export var card_size := Vector2(240, 150)

@onready var cards: HBoxContainer = %Cards


func _ready() -> void:
	hide()
	EventBus.upgrade_choices_offered.connect(_on_choices_offered)


func _on_choices_offered(choices: Array) -> void:
	for child in cards.get_children():
		child.queue_free()
	for upgrade: UpgradeData in choices:
		cards.add_child(_make_card(upgrade))
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Foco na 1ª carta: dá para escolher pelo teclado (setas + Enter) também.
	if cards.get_child_count() > 0:
		(cards.get_child(0) as Button).grab_focus.call_deferred()


func _make_card(upgrade: UpgradeData) -> Button:
	var card := Button.new()
	card.custom_minimum_size = card_size
	card.text = "%s\n\n%s" % [upgrade.title, upgrade.description]
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_theme_font_size_override("font_size", 20)
	card.pressed.connect(_on_card_pressed.bind(upgrade))
	return card


func _on_card_pressed(upgrade: UpgradeData) -> void:
	hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Avisa por último: se houver outro level up na fila, a tela reabre
	# (e pausa de novo) dentro deste mesmo emit.
	EventBus.upgrade_chosen.emit(upgrade)
