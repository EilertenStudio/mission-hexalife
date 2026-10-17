# Arcade

`arcade:play` avvia la scena canonica `test-visual-grooms`, definita in
[`src/scenes/test-visual-grooms/`](../../../src/scenes/test-visual-grooms/).
La scena usa un framebuffer ortografico fisso da 160×90 pixel, una stanza,
tre oggetti, una torcia stilizzata fissa sul lato destro e una luce locale che
segue il puntatore. La sfera conserva un'emissione pulsante tenue.

Geometria, posizioni, dimensioni, illuminazione, camera, hotspot e menu
provengono dai documenti della scena. I tre sprite RGBA da 32×32 sono collegati
in `src/` e si trovano in
[`assets/test-visual-grooms/exports/`](../../../assets/test-visual-grooms/exports/).
Le pareti sono poligoni canonici shadati a runtime: la luce puntiforme segue il
mouse con falloff radiale e un overlay tenue forma un alone attorno al puntatore.
Le linee della stanza e i bordi esposti degli sprite ricevono highlight nella
zona illuminata. I pixel degli sprite vengono convertiti in luminanza per
mantenere la palette quasi monocromatica. La torcia laterale è disegnata con
forme pixel geometriche; non genera un cono. Arcade usa
`RenderTarget`, la resa a mezzi blocchi e gli eventi mouse SGR. Il movimento
evidenzia la sagoma dello sprite; il click sinistro mostra per un istante un
contorno e un anello luminosi.

## Overlay di sistema condiviso

Le scene Arcade fanno riferimento alla stessa configurazione canonica in
[`src/scenes/_shared/arcade-system-menus.json`](../../../src/scenes/_shared/arcade-system-menus.json)
e usano il controller e il renderer comuni in
[`system-overlay.mjs`](system-overlay.mjs). Ogni scena istanzia lo stesso tool:
sequenze, comandi e overlay funzionano allo stesso modo in tutte le scene
selezionabili. Le scene forniscono le operazioni specifiche di ricarica, pausa
e copia del proprio framebuffer.

- `Ctrl+P`, poi `D`: apre Debug.
- `Ctrl+P`, poi `M`: apre il selettore scene; `1` sceglie Test visual grooms e
  `2` la Sala criogenica.
- `Ctrl+P`, poi `R`: ricarica la scena attiva e rilegge gli asset dal disco.
- `Ctrl+P`, poi `C`: copia il framebuffer corrente come PNG negli appunti.
- In Debug, `P` mette in pausa o riprende il frame; `-`/`[` e `+`/`=`/`]`
  cambiano il limite FPS; `V` alterna pixel a mezzo blocco e glifi ASCII.
- `Esc` chiude il menu aperto; `Q` esce quando i menu sono chiusi.

La pausa ferma il timer di resa e conserva il frame della scena; l’overlay di
sistema resta utilizzabile. La copia acquisisce il framebuffer RGB prima della
conversione nel terminale, quindi non include i pannelli testuali TUI. L’immagine
viene ridimensionata alla risoluzione canonica della scena (160×90 per Test
visual grooms, 160×100 per la Sala criogenica). Su Wayland usa `wl-copy`; su
X11 prova `xclip`. Se entrambi mancano o il clipboard non è raggiungibile,
Arcade mostra un messaggio di errore.

## Dettagli della scena

La Sala criogenica resta selezionabile ed è implementata in
[`cryogenic-story.mjs`](cryogenic-story.mjs). La sua stanza usa un'immagine
pixel art statica descritta in [`src/scenes/cryogenic-room/`](../../../src/scenes/cryogenic-room/).
Da lì si possono ispezionare capsula, terminale e porta; il terminale mostra
mappa e allarme QC. Pannelli e pulsanti usano il layer TUI di Arcade, mentre il
fondale pixel art resta statico. Il limite iniziale è 6 FPS per entrambe le scene.

## Capacità e limiti

Arcade fornisce un framebuffer RGB, compositing RGBA, conversione a mezzi
blocchi e input mouse SGR. La luce del puntatore usa una maschera radiale 2D
smussata; l'alone è un'aggiunta visiva, non un raggio volumetrico. Non calcola
occlusione o ombre proiettate. Gli sprite mantengono una diffusione minima di
0.08 per conservarne le sagome anche lontano dal puntatore. Edge highlights e
sprite rim light seguono la maschera ma non sono riflessioni fisiche. Non c'è
camera 3D. Gli hotspot sono
rettangoli in coordinate della scena; il contorno hover segue invece la sagoma
opaca dello sprite. La copia PNG richiede `wl-copy` o `xclip`; l'immagine
contiene il framebuffer e non la UI testuale del terminale. L'hover richiede un
terminale che supporti il reporting SGR del movimento mouse.

## Riferimenti upstream

- [README ufficiale: rendering engine e package API](https://github.com/vercel-labs/arcade#build-with-arcade)
- [Guida upstream: verifica e visualizzazione dell'output](https://github.com/vercel-labs/arcade/blob/main/docs/verifying-output.md)
- [Pacchetto `ascii-arcade` su npm](https://www.npmjs.com/package/ascii-arcade)
