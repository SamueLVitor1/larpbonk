class_name Palette
extends RefCounted
## Paleta oficial do Larpbonk (UI estilo tela de título NES).
##
## Use de qualquer script, sem instanciar: `$Background.color = Palette.BACKGROUND`.
## O Theme (larpbonk_theme.tres) repete algumas dessas cores, porque um .tres
## não lê constantes de script. Mudou uma cor aqui? Mude também no Theme.

# --- Base ---
const BACKGROUND := Color("#000000")   ## céu preto da tela de título
const TEXT := Color("#ffffff")         ## item de menu normal
const SELECTED := Color("#ffd23f")     ## item com foco/hover + cursor ►
const DISABLED := Color("#5e5470")     ## indisponível, versão, dicas

# --- Logo (faixas cromadas, de cima para baixo) ---
const LOGO_WHITE := Color("#ffffff")
const LOGO_LIGHT_PINK := Color("#ffd1e6")
const LOGO_PINK := Color("#ff8cc0")
const LOGO_MAGENTA := Color("#e0408a")
const LOGO_PINK_SHINE := Color("#ffb3d4")
const LOGO_WINE := Color("#a8186a")
const LOGO_SHADOW := Color("#3a0d5c")
const LOGO_DEEP_SHADOW := Color("#1a0630")

# --- Paisagem ---
const HORIZON_BLUE := Color("#1e5cff")
const HORIZON_CYAN := Color("#3c9cff")
const FAR_MOUNTAIN := Color("#2b5a80")
const NEAR_MOUNTAIN := Color("#15304a")
const FIELD := Color("#170a2a")
const FIELD_DOT_PURPLE := Color("#7a4dff")
const FIELD_DOT_PINK := Color("#d0409a")

# --- Tipografia (Press Start 2P: sempre múltiplos de 8) ---
const FONT_SMALL := 16   ## versão, dicas de controle
const FONT_MEDIUM := 24  ## subtítulos, HUD
const FONT_MENU := 40    ## itens do menu principal
