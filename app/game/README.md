# Avvio Web sulla rete locale

Per compilare `story.ink`, esportare la scena principale di Godot per Web e
servirla sulla rete locale:

```sh
./app/game/scripts/web.sh
```

Lo script usa Godot 4.7.2 e Ink dalla toolchain mise del repository. Il server
Python ascolta su tutte le interfacce (`0.0.0.0`) alla porta `8060`; l'URL LAN
viene stampato al termine dell'export. Aprilo da un browser su un altro
computer collegato alla stessa rete. `Ctrl+C` ferma il server.

Per cambiare porta o indirizzo di bind:

```sh
WEB_PORT=8080 ./app/game/scripts/web.sh
WEB_BIND=127.0.0.1 ./app/game/scripts/web.sh
```

L'export viene scritto in `app/game/dist/web/`, esclusa dal versionamento. Se
Godot segnala template mancanti, installare i template Web della stessa
versione (`4.7.2.stable`) da **Editor > Manage Export Templates** e rilanciare
il comando. La build Web usa il renderer Compatibility e il template senza
thread; il progetto desktop continua a usare il renderer configurato per il
desktop.
