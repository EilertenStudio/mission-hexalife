# Arcade

`arcade:play` avvia la scena canonica
[`test-gameplay-action-adventure`](../../assets/scenes/test-gameplay-action-adventure/).
La scena mostra una mappa top-down fissa da 320×288 pixel, divisa in 10×9
metatile da 32×32 pixel. Il disegno della mappa usa una griglia base da 16×16.

I tasti `K`, `J`, `I` e `L` muovono Jerv rispettivamente in basso, a sinistra,
in alto e a destra. Ogni pressione avvia un movimento di un metatile e il
ciclo WALK dura 0,33 secondi. I confini e gli ostacoli della mappa bloccano il
movimento. Raggiunta la soglia della porta, `I` porta Jerv nella stanza
interna vuota; `K` nel varco in fondo alla stanza lo riporta all'esterno.

La mappa esterna e la stanza sono disegnate negli SVG in
[`assets/rooms/action-adventure-field/exports/`](../../assets/rooms/action-adventure-field/exports/).
Arcade non legge SVG direttamente: `map.json` e `interior.json` indicano le
esportazioni PNG 320×288 derivate dai vettori. Jerv è uno sprite separato,
definito in [`character.json`](../../assets/scenes/test-gameplay-action-adventure/character.json).
L'implementazione ritaglia dal PNG un frame RGBA da 32×32 e lo compone sul
framebuffer con campionamento nearest.

## Overlay di sistema

La configurazione dell'overlay è in
[`menus.json`](../../assets/scenes/test-gameplay-action-adventure/menus.json);
il controller comune è in [`system-overlay.mjs`](system-overlay.mjs).

- `Ctrl+P`, poi `D`: apre Debug.
- `Ctrl+P`, poi `M`: apre il selettore scena. È mantenuta solo la scena attuale.
- `Ctrl+P`, poi `R`: ricarica la scena e rilegge gli asset dal disco.
- `Ctrl+P`, poi `C`: copia il framebuffer corrente come PNG negli appunti.
- In Debug, `P` mette in pausa o riprende i frame; `-`/`[` e `+`/`=`/`]`
  cambiano il limite FPS; `V` alterna i mezzi blocchi e i glifi ASCII.
- `Esc` chiude il menu aperto; `Q` esce quando i menu sono chiusi.

La pausa ferma il timer di resa e conserva il frame, mentre l'overlay resta
utilizzabile. La copia acquisisce il framebuffer prima della conversione nel
terminale e quindi non include i pannelli testuali. Su Wayland usa `wl-copy`;
su X11 prova `xclip`.

## Capacità e limiti

Arcade fornisce un framebuffer RGB, compositing RGBA, conversione a mezzi
blocchi e input mouse SGR. La scena usa rendering software e non una camera 3D.
La mappa è un fondale raster: Arcade non legge o rasterizza l'SVG durante
l'esecuzione. Il clipboard richiede `wl-copy` o `xclip` e contiene il solo
framebuffer, non l'interfaccia testuale del terminale.

## Riferimenti upstream

- [README ufficiale: rendering engine e package API](https://github.com/vercel-labs/arcade#build-with-arcade)
- [Guida upstream: verifica e visualizzazione dell'output](https://github.com/vercel-labs/arcade/blob/main/docs/verifying-output.md)
- [Pacchetto `ascii-arcade` su npm](https://www.npmjs.com/package/ascii-arcade)
