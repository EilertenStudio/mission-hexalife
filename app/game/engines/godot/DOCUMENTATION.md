# Godot

Il menu di sistema è registrato come autoload in `project.godot`, così i tasti
canonici `Ctrl+P` restano disponibili mentre cambiano le scene. `Ctrl+P` apre
il menu rapido; `D` apre il debug, `J` il controllo di BPM e judgment, `M` il
selettore scena, `R` ricarica e `C` copia il frame. Nel menu Debug, `P` mette
in pausa o riprende la scena, `-` e `+`/`=` regolano il limite FPS e `V`
alterna i filtri nearest e linear.

La copia del frame usa gli strumenti di clipboard di Linux: serve `wl-copy` in
sessione Wayland oppure `xclip` in sessione X11. Se nessuno dei due è
disponibile, il menu mostra un avviso e non copia l'immagine. La cattura viene
presa dal viewport di gioco senza l'overlay del menu.

Il selettore scena mostra le scene Godot registrate nel menu canonico della
scena. Al momento il progetto contiene solo `test-gameplay-rhythm-crypto`.

## Ritmo, movimento e musica

La scena riproduce in loop `assets/audio/hard-dungeon-bpm140.ogg`, il brano
`Hard Dungeon` di MintoDog, pubblicato su OpenGameArt con licenza CC0. La
descrizione canonica della traccia, del BPM e della licenza è
`app/game/assets/scenes/test-gameplay-rhythm-crypto/sources/music.json`.
La traccia ha tempo nativo di 140 BPM e viene adattata al BPM selezionato
tramite `AudioStreamPlayer.pitch_scale`; questo modifica anche l'intonazione.
Il precedente loop originale generato per il prototipo è conservato come
alternativa in `assets/audio/dungeon-pulse-original.wav`; la fonte è
`sources/music-original.json` e si rigenera con
`scripts/audio/generate_music.py`. `PagSu` e
`PagGiù` regolano il volume a passi del 10%, con volume iniziale al 40%.

Il clock legge la posizione del player audio in loop e la usa come riferimento
per beat, turni e barra di timing. L'input viene giudicato rispetto al beat
intero o al mezzo beat più vicino. Le finestre iniziali sono `PERFECT` ±50 ms e
`GOOD` ±120 ms; `MISS` oltre GOOD non esegue l'azione. `Ctrl+P` → `J` apre il
menu per regolare BPM e le due finestre a passi di 5 ms e per attivare o
disattivare il vincolo BPM con `0`. GOOD resta strettamente sotto il punto medio
tra slot consecutivi: il limite è il precedente multiplo di 5 ms sotto
`15000 / BPM`, fino a un massimo di 120 ms. Aumentare il BPM quindi non rende
più permissivo il timing e le zone GOOD non si sovrappongono. Jerv si muove
subito quando l'input è accettato; non attende il beat successivo. Movimento e
abilità condividono due slot per beat: uno sul beat intero e uno sul mezzo
beat, con una sola azione per slot. Una direzione tenuta ripete un passo solo
sui beat interi; l'azione extra sul mezzo beat richiede una nuova pressione.
Gli input che portano fuori dalla griglia mostrano `BLOCKED` e non consumano lo
slot; un'altra azione nello stesso slot mostra `LOCKED`.

Ogni input direzionale ritmico e ogni passo effettivo scrivono una riga nel log
di Godot con turno, slot, fase audio, giudizio, direzione e celle di partenza e
arrivo. `[MOVE INPUT]` registra anche input `MISS`, `LOCKED` e `BLOCKED`;
`[MOVE #...]` identifica i passi eseguiti e distingue input manuali,
ripetizione sul beat e ripetizione libera.

La barra mostra le finestre GOOD e PERFECT al centro per il beat intero e ai due
bordi per il mezzo beat; la larghezza segue i valori configurati nel menu e le
stesse finestre usate per valutare gli input. Il marker arriva al centro sul
beat intero, attraversa il lato destro e riappare a sinistra a metà beat, quindi
torna al centro. Tacche rosse fisse segnano i punti obiettivo: centro per il beat
intero e bordi per l'half-beat. La scala delle zone viene ricalcolata rispetto
alla durata del beat al BPM selezionato. Il clock audio usa `AudioStreamPlayer` e una compensazione
basata sulla posizione di mix e sulla latenza d'uscita; latenza del dispositivo,
frame rate e tempi d'input possono comunque introdurre scarti percepibili.
Se un frame salta più beat, il clock si riallinea al beat audio corrente e non
riesegue i turni mancanti in un'unica raffica di passi; `[CLOCK RESYNC]` registra
quanti beat sono stati saltati.

La scena mostra anche `AUTO`, un rilevatore diagnostico di attacchi ricavato
direttamente dallo spettro della traccia. Godot instrada il player attraverso un
bus runtime a guadagno unitario con `AudioEffectSpectrumAnalyzer`; il detector
misura il flusso spettrale adattivo soprattutto nelle basse frequenze e impone
un intervallo minimo di 300 ms tra candidati. Il caret ciano resta sulla fase
dell'ultimo rilevamento sopra la barra e si illumina più intensamente quando
trova un nuovo candidato. Questo percorso non invoca il judgment, non muove
Jerv e non cambia il clock dei turni. Rileva transienti salienti, non ricostruisce
una beatmap né stima con certezza BPM o downbeat; la finestra FFT introduce un
breve ritardo e alcuni accenti possono essere ignorati o segnalati come candidati.

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

Anche le animazioni seguono il beat: ogni frame IDLE di Jerv dura due beat; gli
attacchi e gli effetti sul tile durano un beat, distribuito sui quattro frame.
La sprite sheet di Jerv e quella del pipistrello sono progetti Pixelorama
editabili nella cartella `exports` della scena; il task `export-bat` esporta i
due frame del pipistrello e aggiorna la copia usata da Godot.

Il pipistrello rosso parte dalla cella `[8, 5]` e, a ogni beat intero, sceglie
casualmente una cella cardinale adiacente interna alla griglia che non sia
occupata da Jerv. Questo riprende il movimento casuale cardinale del pipistrello
rosso di Crypt of the NecroDancer; non si muove sul mezzo beat. Le caselle
esterne non sono destinazioni e non c'è avvolgimento dei bordi. Se non ha una
destinazione valida resta fermo. Gli oggetti dimostrativi non lo bloccano.
Jerv non può entrare nella cella occupata dal pipistrello; non sono implementati
attacchi, collisioni con danni o salute. Quando il vincolo BPM è disattivato, il
clock si ferma e il pipistrello non si sposta; il battito delle ali continua
alla velocità di riferimento di 120 BPM. A tempo attivo i due frame delle ali
si alternano a metà beat.

Le animazioni non bloccano l'avanzamento dei turni. Se un beat scade senza
azioni del giocatore, l'animazione in corso continua; quando una nuova azione
ritmica viene accettata, l'animazione e il VFX precedenti vengono interrotti e
la nuova azione parte subito.
