# Ink Scene Director

Addon Godot 4 che legge il JSON prodotto da `inklecate` e lascia a Godot la
regia della presentazione. Il runtime è scritto in GDScript e non include un
parser o un compilatore Ink.

## Uso

1. Compilare il sorgente `.ink` con `inklecate`.
2. Aggiungere un nodo `InkSceneDirector` alla scena.
3. Registrare i cue Godot che la storia può richiedere.
4. Collegare `line_emitted`, `choices_available`, `variables_changed` e
   `story_ended`, poi chiamare `load_story()` e `start_story()`.

`line_emitted(text, tags, knot_name)` include il knot Ink sorgente di ogni
paragrafo. `knot_name` permette alla scena di mantenere insieme i paragrafi
dello stesso knot e riconoscere quando la storia è passata a un altro.

Le scene che offrono azioni tramite oggetti possono collegare un input Godot a
`choose_target(knot_name)`: il metodo seleziona la scelta attualmente disponibile
che porta a quel knot e restituisce `false` se Ink non la offre in quel momento.
La scena decide quali input e hotspot corrispondono ai knot; condizioni e
conseguenze restano nello story Ink.

```gdscript
func _show_line(text: String, tags: PackedStringArray, knot_name: String) -> void:
	# Presenta il paragrafo e usa knot_name per rilevare i cambi di nodo.
	pass

func _ready() -> void:
	$InkSceneDirector.register_scene_cue("cryogenic_room", _show_cryogenic_room)
	$InkSceneDirector.register_actor_cue("medico", _show_doctor)
	$InkSceneDirector.line_emitted.connect(_show_line)
	$InkSceneDirector.choices_available.connect(_show_choices)
	if $InkSceneDirector.load_story():
		$InkSceneDirector.start_story()
```

I tag `scene:id`, `actor:id` (anche `char:id`), `camera:id` e `audio:id`
richiedono un handler registrato con l'API corrispondente. I tag non invocano
metodi, percorsi o risorse scelti dal file Ink: l'Ink sceglie solo un ID
presente nella registry Godot. I tag `ui:id` sono inoltrati come metadati della
riga e non eseguono cue.

## Compatibilità attuale

Il runtime supporta il sottoinsieme usato da `app/gamebook/story.ink` e il
formato compilato Ink 21: knot e divert, variabili globali int/bool,
assegnazioni ed espressioni aritmetiche/logiche, condizioni, interpolazione,
scelte normali e sticky, tag. Il compilatore rifiuta in modo esplicito opcode,
versioni o Ink list non supportati. Funzioni Ink, thread, `EXTERNAL`, list e
altre estensioni non sono incluse in questa PoC.

La scena dimostrativa e il verificatore della storia sono in
`app/game/tests/test-gameplay-ink/`. Il JSON compilato è un artefatto ignorato
da Git. Nella sala criogenica la PoC include hotspot sulla capsula in primo
piano, sul terminale e sulla porta; gli hotspot seguono le scelte disponibili
e le opzioni interne al terminale restano scelte testuali.
