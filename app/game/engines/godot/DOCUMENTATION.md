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

La scena ritmo genera un click sintetico breve a ogni beat, senza traccia
musicale o asset audio esterni. `PagSu` e `PagGiù` regolano il volume a passi
del 10%, con volume iniziale al 40%. Il click è attivato dal clock dei turni
nel ciclo di processo della scena, quindi la precisione del trigger segue il
frame rate e non un clock audio dedicato.

I tasti `1`–`6` selezionano i profili da 60, 80, 100, 120, 140 e 160 BPM.
`[` aumenta il tempo e `]` lo diminuisce a passi di 5 BPM, tra 40 e 240 BPM.
Il cambio conserva la fase corrente del beat e aggiorna insieme turni, barra di
timing e metronomo.

`0` attiva o disattiva il clock BPM. Quando è disattivato, il metronomo e la
barra di timing si fermano, mentre IJKL e A/S eseguono le azioni subito alla
pressione. Tenere premuto un movimento lo ripete dopo 0,22 secondi e poi ogni
0,12 secondi. Le animazioni continuano alla velocità corrispondente a 120 BPM;
riattivando il clock, turni e metronomo ripartono dal beat successivo.

Anche le animazioni seguono il beat: ogni frame IDLE dura due beat; gli attacchi
di Jerv e i relativi effetti sul tile durano un beat, distribuito sui quattro
frame. L'impulso visivo del beat occupa il 36% della durata corrente.

Le animazioni non bloccano l'avanzamento dei turni. Se un beat scade senza
azioni del giocatore, l'animazione in corso continua; se un'azione è pronta al
beat, l'animazione e il VFX precedenti vengono interrotti e l'azione parte
subito.
