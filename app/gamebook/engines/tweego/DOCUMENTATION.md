# Tweego

## Guide ufficiali

- [Documentazione di Tweego](https://www.motoslave.net/tweego/docs/): installazione, opzioni CLI, formati supportati e compilazione/decompilazione.
- [Riferimento alla notazione Twee](https://www.motoslave.net/tweego/docs/#twee-notation): sintassi dei passaggi, metadati e collegamenti.
- [Repository di Tweego](https://github.com/tmedwards/tweego): sorgenti, release e istruzioni per compilare il tool.
- [Specifiche Twee 3](https://github.com/iftechfoundation/twine-specs/blob/master/twee-3-specification.md): specifica del formato testuale usato per le storie Twine.

## Formati e progetti di esempio

- [Twine Story Formats](https://twinery.org/reference/en/story-formats/): panoramica dei formati narrativi; il formato scelto determina macro e funzionalità disponibili nella storia compilata.
- [Twine Cookbook](https://twinery.org/cookbook/): ricette ed esempi per formati come Harlowe e SugarCube.
- [Tweego setup](https://github.com/ChapelR/tweego-setup): progetto boilerplate con struttura e configurazione iniziale per compilare con Tweego.

## Prima stanza

La bozza in [story.twee](story.twee) usa SugarCube 2 e mette in scena il risveglio nella sala criogenica. I nomi degli oggetti cliccabili sono verdi; l'ispezione corrisponde a `look <soggetto>` e le interazioni operative sono indicate come `use <soggetto>`. La scena si ferma quando la porta si sblocca, prima dell'incontro con il Medico.

Per compilare l'HTML:

```sh
MISE_GLOBAL_CONFIG_FILE="$PWD/mise.toml" MISE_CACHE_DIR="$PWD/.local/mise/cache" MISE_STATE_DIR="$PWD/.local/mise/state" MISE_DATA_DIR="$PWD/.local/mise/data" mise -C app/gamebook/engines/tweego run --raw --skip-tools build
```

Il file generato è `.local/gamebook/tweego/story.html`.
