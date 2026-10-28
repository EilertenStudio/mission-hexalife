# Credits and licenses

This registry records third-party software and assets used by the Godot game.
Keep it current when bundled dependencies or shipped assets change. The license
for each item applies to that item; the repository's root license does not
replace third-party licenses.

## Playground V1 prototypes

### Rain on Window Loop

- **Use:** Ambient rain sample for the Playground V1 garage audio comparison.
- **Creator:** alxl.
- **License:** CC0 1.0 Universal. The source page says attribution is appreciated
  but not required; this project records it for provenance.
- **Bundled file:**
  `tests/playground-v1/features/audio/exterior_rain/samples/rain_on_window_loop.wav`.
- **Source:** [OpenGameArt: Rain on Window Loop](https://opengameart.org/content/rain-on-window-loop).

### Thunder and Wind Gusts

- **Use:** Randomized thunder and wind SFX layered over the continuous rain in
  the Playground V1 garage.
- **License:** CC0 1.0 Universal for all listed Freesound recordings.
- **Bundled files:**
  `tests/playground-v1/features/audio/storm_sfx/samples/thunder_clap_roboroo.mp3`,
  `thunder_clap_fission9.mp3`, `thunder_roll_emulius.mp3`,
  `wind_gust_wintuh.mp3`, `wind_gust_zip_creates.mp3`, and
  `wind_gust_hyperbloodhell.mp3`.
- **Creators and sources:** roboroo ([Freesound #436790](https://freesound.org/people/roboroo/sounds/436790/));
  Fission9 ([Freesound #534023](https://freesound.org/people/Fission9/sounds/534023/));
  Emulius ([Freesound #744723](https://freesound.org/people/Emulius/sounds/744723/));
  wintuh ([Freesound #471854](https://freesound.org/people/wintuh/sounds/471854/));
  ZIP.Creates ([Freesound #726316](https://freesound.org/people/ZIP.Creates/sounds/726316/));
  HYPERBLOODHELL ([Freesound #693460](https://freesound.org/people/HYPERBLOODHELL/sounds/693460/)).

### Flashlight Toggle

- **Use:** Click sound when the Playground V1 flashlight is toggled on or off.
- **Creator:** Rudmer Rotteveel.
- **License:** CC0 1.0 Universal.
- **Bundled file:**
  `tests/playground-v1/assets/rooms/garage_room/audio/flashlight_toggle.mp3`.
- **Source:** [Freesound: Small Flashlight Click on 01](https://freesound.org/people/Rudmer_Rotteveel/sounds/457458/).

### Wooden Door Open and Close

- **Use:** Open and close sounds for the Playground V1 garage room door.
- **Creator:** Iwan Gabovitch; submitted to OpenGameArt by qubodup.
- **License:** CC0 1.0 Universal. Attribution is not required; this entry records
  the source and provenance.
- **Bundled files:**
  `tests/playground-v1/assets/rooms/garage_room/audio/door_open.wav` and
  `tests/playground-v1/assets/rooms/garage_room/audio/door_close.wav`.
- **Source:** [OpenGameArt: Door open, door close](https://opengameart.org/content/door-open-door-close).

### Mechanical Sounds

- **Use:** Alternative mechanical squeak samples for the Playground V1
  Bulblight swing event and sound mapping preview. `squeakyclick2.wav` is the
  current Bulblight sound; `squeakyclick1.wav` remains available as an
  alternative.
- **Creator:** Brian MacIntosh (BMacZero on OpenGameArt).
- **License:** CC0. Attribution is optional; this entry records the source.
- **Bundled files:**
  `tests/playground-v1/assets/rooms/garage_room/audio/bulb_squeak.wav` and
  `tests/playground-v1/assets/rooms/garage_room/audio/bulb_squeak_02.wav`.
- **Source:** [OpenGameArt: Mechanical Sounds](https://opengameart.org/content/mechanical-sounds),
  `squeakyclick1.wav` and `squeakyclick2.wav`.

### Light Switch Turn On And Off SFX

- **Use:** Separate switch activation and deactivation sounds for the
  Playground V1 garage room.
- **Creator:** FunnyDude.
- **License:** CC0. Attribution is not required; this entry records the source
  and provenance.
- **Bundled files:**
  `tests/playground-v1/assets/rooms/garage_room/audio/light_switch_turn_on.mp3`
  and
  `tests/playground-v1/assets/rooms/garage_room/audio/light_switch_turn_off.mp3`.
- **Source:** [OpenGameArt: Light Switch Turn On And Off SFX](https://opengameart.org/content/light-switch-turn-on-and-off-sfx-0).

### Concrete Floor And Ceiling Taps

- **Use:** Contact sounds for the concrete floor and ceiling in the Playground
  V1 garage. The floor clip is reduced to a short, dry 25 ms attack with its
  low rumble cut; the ceiling clip retains the longer resonant decay.
- **Creator:** vestibule-door.
- **License:** CC0 1.0 Universal.
- **Bundled files:**
  `tests/playground-v1/assets/rooms/garage_room/audio/material_taps/concrete_tap.wav`
  and `tests/playground-v1/assets/rooms/garage_room/audio/material_taps/ceiling_tap.mp3`.
- **Source:** [Freesound: patting stone wall.wav](https://freesound.org/people/vestibule-door/sounds/669723/).

### Plaster Wall Tap

- **Use:** Material contact sound for the plaster walls in the Playground V1
  garage room. The bundled clip is a short edit of one wall knock from the
  source recording.
- **Creator:** p379.
- **License:** CC0 1.0 Universal.
- **Bundled file:**
  `tests/playground-v1/assets/rooms/garage_room/audio/material_taps/plaster_tap.wav`.
- **Source:** [Freesound: knocking on wall.wav](https://freesound.org/people/p379/sounds/642765/).

## Included in the game

### Pixelify Sans

- **Use:** Title Screen menu typography. Selected as a pixel-style substitute
  while the license for Pannetje 10 is unknown.
- **Designer:** Stefie Justprince; Pixelify Sans Project Authors.
- **Copyright:** Copyright 2021 The Pixelify Sans Project Authors
  (https://github.com/eifetx/Pixelify-Sans).
- **License:** SIL Open Font License 1.1 (OFL).
- **Bundled file:** `assets/ui/fonts/pixelify_sans/pixelify_sans.ttf`.
- **License text:** [`licenses/pixelify_sans_OFL.txt`](licenses/pixelify_sans_OFL.txt).
- **Source:** [Google Fonts: Pixelify Sans](https://github.com/google/fonts/tree/main/ofl/pixelifysans),
  originally published at [eifetx/Pixelify-Sans](https://github.com/eifetx/Pixelify-Sans).

The OFL permits bundling the font with software. Keep the font's copyright and
license notice when redistributing the font file.

## Engine and development tools

### Godot Engine 4.7.2

- **Use:** Game engine and runtime.
- **Copyright:** Copyright (c) 2014-present Godot Engine contributors.
- **License:** MIT.
- **License and attribution:** [godotengine.org/license](https://godotengine.org/license).

Preserve the `COPYRIGHT.txt` attribution file produced with Godot exports when
redistributing a build.

### Godot AI Addon 4.3.0

- **Use:** Development tool enabled in the editor; not a game asset.
- **Copyright:** Copyright (c) 2025 Godot AI contributors.
- **License:** MIT, included at `addons/godot_ai/LICENSE`.
- **Source:** [Godot AI](https://github.com/hi-godot/godot-ai).

## Evaluated, not included

### Pannetje 10

Considered for the Title Screen typography. It is not bundled or used because
its author, source and distribution license have not been confirmed. Revisit
this entry if those details become available.
