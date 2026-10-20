# Backlog — Larpbonk

Ideias para depois do roadmap principal (ver `CLAUDE.md`). Não é ordem de prioridade.
Ao implementar uma, marcar no Roadmap do `CLAUDE.md` e apagar daqui.

## ✨ Game feel (pouco trabalho, muito impacto) — sugestão para começar
- Sons: tiro, acerto, gema coletada, level up. Música de fundo.

## 🎭 Tema e personagens
- **Tung Tung Sahur de verdade:** chefão aos ~5 min, ou 2º personagem jogável com taco (dano em área).
- **Infinito (Gojo):** escudo que deixa inimigos lentos perto do player.
- **Vazio Imenso (Domain Expansion):** especial com recarga longa que congela a tela por alguns segundos.

- **Silhueta preta** nos personagens bloqueados da seleção (modelo 3D pintado de preto, como no Megabonk).
- **2º personagem jogável:** o player passa a ler `GameManager.selected_character` (modelo, arma inicial, status).

## 🔫 Armas
- 🔴 **Vermelho:** rajada que empurra inimigos (knockback).
- 🟣 **Roxo:** raio lento e enorme que atravessa tudo; possível "evolução" de Azul + Vermelho.
- 🌀 **Orbes orbitando** o player, batendo em quem encosta.
- 💥 **Aura:** dano contínuo em área em volta do player.
- **Bala que atravessa (pierce):** upgrade; `HitboxComponent` com contador de acertos em vez de `hit_once`.
- **Visual temático da bala:** trocar a esfera azul por algo do Gojo, com brilho. Se vier do Sketchfab: licença CC0/CC-BY (dar crédito) e low poly.

## 🐷 Inimigos
- 🐗 **Porcão:** grande, lento, muita vida.
- 👑 **Porco Rei (continuação):** já existe e aparece aos 30 s (teste; subir para ~5 min). Falta: barra de vida de chefe na HUD + aviso "chefe chegou", baú ao morrer, ataques (investida, pisão), animações (o modelo não tem).
- **Mira travada:** trocar de alvo com R segurado / travar inimigos comuns? Indicador na borda da tela quando o alvo travado está fora da vista.
- 🪖 **Porco de capacete:** toma menos dano.
- 💨 **Porquinho rápido:** pequeno, frágil e veloz.
- 💣 **Porco-bomba:** explode perto do player.
- Cada um = cena herdada de `base_enemy` + `.tres` em `data/enemies/`.

## 🌊 Spawner e horda
- **Ondas em grupos:** às vezes solta vários juntos (grupinho / círculo fechando em volta).
- **Inimigos no relevo:** hoje sobem qualquer inclinação (até o penhasco do platô), porque só seguem a altura. Limitar a subida se ficar estranho.
- **Inimigos desviando de obstáculos:** hoje atravessam pilares/lanternas do templo (andam sem física). Opções baratas: empurrar para fora de círculos conhecidos dos obstáculos, ou flow field no mapa.
- **Inimigos se afastando uns dos outros:** hoje viram um "bolo"; separação simples por código (sem física). Repetir o teste de estresse depois.

## 🎁 Coletáveis
- 📦 **Baú:** de chefes, dá upgrade grátis.
- 🍗 **Comida:** cura um pouco; drop raro.
- 🧲 **Ímã gigante:** puxa todas as gemas da tela.
- 💎 **Gemas de valores/cores:** verde 1, azul 5, vermelha 20 XP.
- **Cor da gema** diferente do verde dos porcos (ciano/roxo/amarelo) para destacar na horda.

## 🖥️ UI
- **Levar o estilo NES ao resto** (cartas de level up e HUD); depois ligar `larpbonk_theme.tres` como Theme global.
- **Opções** no menu principal (volume, tela cheia); o botão já existe desabilitado.
- **Parallax** nas 4 camadas da paisagem do menu.

## 🃏 Upgrades
- **Cartas bonitas:** ícone, cor por raridade, animação.
- **Nível máximo por upgrade** (ex.: "Força 3/5") e upgrades que exigem outro antes.

## 🗺️ Estrutura e meta
- **Performance do jardim:** ~20% menos FPS que no templo com 500 porcos. Testar: sombras só nas árvores perto, menos lanternas com luz, `visibility_range` na vegetação.
- **Seleção de mapa** (hoje a seleção de personagem abre sempre o templo).
- **Mais mapas:** floresta, deserto… (cena herdada de `base_level` + `props/` próprios).
- 🏆 **Recorde salvo** ("Seu melhor: 07:32").
- 💰 **Moedas entre partidas** para melhorias permanentes (estilo Megabonk).
- 🎯 **Partida com objetivo:** sobreviver 10 min e enfrentar o chefão final.
- **Exportar** para macOS (app não assinado → clique direito → Abrir) e Windows.
