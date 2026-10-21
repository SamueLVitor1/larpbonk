extends Node
## Troca de cena com tela de carregamento (registrado como autoload "SceneLoader").
##
## Por quê: o mapa trava alguns frames ao entrar (leitura do arquivo, relevo,
## TerrainScatter, pools, aquecimento de shaders). Aqui a leitura vai para outra
## thread (a animação não congela) e o resto acontece escondido atrás da tela,
## que só some depois que o mapa terminou de montar.
##
## Uso: `SceneLoader.change_scene(path)` ou `SceneLoader.reload()`.

const LOADING_SCREEN := preload("res://ui/loading_screen/loading_screen.tscn")

## Frames que a tela segura depois que o mapa entra: cobre o terreno/scatter
## (call_deferred) e o aquecimento de shaders dos pools (~3 frames).
@export var settle_frames: int = 8
## Tempo mínimo na tela, para não virar só um "pisco" preto.
@export var min_duration: float = 0.4

var _screen: LoadingScreen
var _busy := false


func _ready() -> void:
	# Precisa rodar com o jogo pausado (a cena antiga fica congelada durante a troca).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_screen = LOADING_SCREEN.instantiate()
	add_child(_screen)


func reload() -> void:
	change_scene(get_tree().current_scene.scene_file_path)


func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	var started := Time.get_ticks_msec()
	await _screen.cover()
	# Congela a cena antiga: nada de porco batendo no player atrás da tela.
	get_tree().paused = true

	ResourceLoader.load_threaded_request(path)
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	var scene := ResourceLoader.load_threaded_get(path) as PackedScene
	if scene == null:
		push_error("SceneLoader: não deu para carregar %s" % path)
		get_tree().paused = false
		_screen.uncover()
		_busy = false
		return

	# A troca só acontece no fim do frame: despausar antes deixaria a cena antiga
	# rodar 1 frame (o player podia morrer e o game over pausaria a cena nova).
	get_tree().change_scene_to_packed(scene)
	await get_tree().process_frame
	get_tree().paused = false
	for i in settle_frames:
		await get_tree().process_frame
	var remaining := min_duration - (Time.get_ticks_msec() - started) / 1000.0
	if remaining > 0.0:
		await get_tree().create_timer(remaining, true, false, true).timeout
	await _screen.uncover()
	_busy = false
