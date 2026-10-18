# Godot

Il menu di sistema è registrato come autoload in `project.godot`, così i tasti
canonici `Ctrl+P` restano disponibili mentre cambiano le scene. `Ctrl+P` apre
il menu rapido; `D` apre il debug, `M` il selettore scena, `R` ricarica e `C`
copia il frame. Nel menu Debug, `P` mette in pausa o riprende la scena, `-` e
`+`/`=` regolano il limite FPS e `V` alterna i filtri nearest e linear.

La copia del frame usa gli strumenti di clipboard di Linux: serve `wl-copy` in
sessione Wayland oppure `xclip` in sessione X11. Se nessuno dei due è
disponibile, il menu mostra un avviso e non copia l'immagine. La cattura viene
presa dal viewport di gioco senza l'overlay del menu.

Il selettore scena mostra le scene Godot registrate nel menu canonico della
scena. Al momento il progetto contiene solo `test-gameplay-rhythm-crypto`.

## Ritmo, movimento e musica

La scena riproduce in loop `assets/audio/dungeon-pulse-original.wav`, una
traccia originale chiptune/elettronica generata dalla fonte musicale
`app/game/assets/scenes/test-gameplay-rhythm-crypto/sources/music.json`.
Lead pulse, basso, pad e batteria sono sintetizzati dallo script
`scripts/audio/generate_music.py`; il brano usa un arrangiamento e una melodia
originali, senza trascrivere la musica di una zona esistente. `PagSu` e
`PagGiù` regolano il volume a passi del 10%, con volume iniziale al 40%.

Il clock legge la posizione del player audio in loop e la usa come riferimento
per beat, turni e barra di timing. L'input viene giudicato rispetto al beat
intero o al mezzo beat più vicino: `PERFECT` entro 50 ms, `GOOD` entro 120 ms e
`MISS` oltre la finestra, senza azione. Jerv si muove subito quando l'input è
accettato; non attende il beat successivo. Movimento e abilità condividono due
slot per beat: uno sul beat intero e uno sul mezzo beat, con una sola azione per
slot. Una direzione tenuta ripete un passo solo sui beat interi; l'azione extra
sul mezzo beat richiede una nuova pressione. Gli input che portano fuori dalla
griglia mostrano `BLOCKED` e non consumano lo slot; un'altra azione nello stesso
slot mostra `LOCKED`.

Ogni input direzionale ritmico e ogni passo effettivo scrivono una riga nel log
di Godot con turno, slot, fase audio, giudizio, direzione e celle di partenza e
arrivo. `[MOVE INPUT]` registra anche input `MISS`, `LOCKED` e `BLOCKED`;
`[MOVE #...]` identifica i passi eseguiti e distingue input manuali,
ripetizione sul beat e ripetizione libera.

La barra mostra le finestre GOOD e PERFECT al centro per il beat intero e ai due
bordi per il mezzo beat. Il marker arriva al centro sul beat intero, attraversa
il lato destro e riappare a sinistra a metà beat, quindi torna al centro. Le
larghezze delle zone seguono le finestre in millisecondi al BPM selezionato. Il
clock audio usa `AudioStreamPlayer` e una compensazione
basata sulla posizione di mix e sulla latenza d'uscita; latenza del dispositivo,
frame rate e tempi d'input possono comunque introdurre scarti percepibili.

I tasti `1`–`6` selezionano i profili da 60, 80, 100, 120, 140 e 160 BPM.
`[` aumenta il tempo e `]` lo diminuisce a passi di 5 BPM, tra 40 e 240 BPM.
Il cambio aggiorna la velocità della traccia, gli intervalli delle animazioni e
la barra di timing. Il prototipo cambia il BPM modificando `pitch_scale`:
insieme al tempo cambia anche l'intonazione della musica.

`0` attiva o disattiva il vincolo BPM. Quando è disattivato, la musica continua,
il clock dei turni e la barra di timing si fermano, mentre IJKL e A/S eseguono
le azioni subito alla pressione. Tenere premuto un movimento lo ripete dopo
0,22 secondi e poi ogni 0,12 secondi. Le animazioni continuano alla velocità
corrispondente a 120 BPM; riattivando il vincolo, il clock si riallinea al beat
della musica.

Anche le animazioni seguono il beat: ogni frame IDLE dura due beat; gli attacchi
di Jerv e i relativi effetti sul tile durano un beat, distribuito sui quattro
frame. L'impulso visivo del beat occupa il 36% della durata corrente. La scena
non contiene nemici né comportamenti avversari: il combattimento è limitato
all'uso ritmico di Black Hole e White Hole sugli oggetti dimostrativi.

Le animazioni non bloccano l'avanzamento dei turni. Se un beat scade senza
azioni del giocatore, l'animazione in corso continua; quando una nuova azione
ritmica viene accettata, l'animazione e il VFX precedenti vengono interrotti e
la nuova azione parte subito.
