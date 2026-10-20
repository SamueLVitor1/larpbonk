extends Node
## Estado que precisa sobreviver à troca de cenas (menu → seleção → partida).
## Mantido no mínimo: o resto do estado da partida vive nos próprios sistemas.
## Registrado como autoload "GameManager" no project.godot.

## Personagem escolhido na tela de seleção (null = padrão do player).
var selected_character: CharacterData
