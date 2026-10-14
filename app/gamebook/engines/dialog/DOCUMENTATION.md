# Dialog

## Guide ufficiali

- [Repository ufficiale Dialog-IF](https://github.com/Dialog-IF/dialog): compilatore `dialogc`, debugger `dgdebug`, libreria standard, documentazione inclusa e istruzioni di build.
- [Manuale di Dialog](https://dialog-if.github.io/manual/): guida alla lingua e alla libreria standard.
- [Dialog IDE](https://github.com/Dialog-IF/dialog-ide): estensione VS Code facoltativa con Skein per eseguire e verificare percorsi di gioco.

## Esempi e risorse

- La cartella [`docs`](https://github.com/Dialog-IF/dialog/tree/main/docs) del repository contiene il manuale e il materiale di riferimento distribuito con Dialog.
- [Aamachine](https://github.com/Dialog-IF/aamachine): interprete per progetti Dialog, utile per provare e distribuire storie compatibili sul web.

## Prototipo Missione Hexalife

La prima stanza è in [`story.dg`](story.dg). È una prova esplorabile da parser: il giocatore digita comandi invece di scegliere da un menu. Per giocarla con il debugger:

```sh
MISE_GLOBAL_CONFIG_FILE="$PWD/mise.toml" \
MISE_CACHE_DIR="$PWD/.local/mise/cache" \
MISE_STATE_DIR="$PWD/.local/mise/state" \
MISE_DATA_DIR="$PWD/.local/mise/data" \
mise -C app/gamebook/engines/dialog run --raw play
```

Digita `aiuto` o `help` per vedere la sintassi. Le sole azioni di gioco sono `look <soggetto>` e `use <soggetto>`; `look` senza soggetto descrive la stanza. I soggetti accettati sono capsula, terminale, mappa, QC e porta (sono riconosciuti anche i corrispondenti nomi inglesi). La corrente di backup scatta dopo `look capsule`, `use map` e `use QC`. Il prototipo si ferma quando si apre la porta; il corridoio e l'incontro con il Medico non sono inclusi.

I nomi degli oggetti interattivi sono verdi e cliccabili nell'interprete Å-machine: attivano `look <soggetto>`. Nel debugger CLI i link appaiono con il comando tra parentesi angolari; digita il comando al prompt. Il task `play` forza ANSI in `dgdebug` e rimappa i colori alla palette 256-color di Ink tramite [`play-ansi.py`](scripts/play-ansi.py): narrazione azzurro grigio, oggetti e comandi verdi, input ambra, QC ciano, allarmi rossi e stato grigio attenuato. I nomi dei ruoli sono colorati soltanto quando vengono citati: Capitano arancione, Primo Ufficiale rosa, Medico verde acqua, Scienziato viola e Ingegnere avorio. Il dialogo resta nel colore narrativo.

Per compilare la storia in formato Å-machine, usa `mise -C app/gamebook/engines/dialog run --raw build`. Il file risultante viene scritto sotto `.local/gamebook/dialog/`.
