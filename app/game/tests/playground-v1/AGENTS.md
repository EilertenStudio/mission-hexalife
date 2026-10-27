# Playground V1

- Questa scena è la base per provare meccaniche reali in una stanza indipendente
  dalla storia. Non trasferire qui le interazioni del Playground Concept senza
  una scelta esplicita.
- Tenere assets e features specifiche di V1 nelle rispettive cartelle locali.
  Non promuoverle nelle cartelle globali del gioco senza approvazione.
- L'utente cura la direzione visuale. Non inventare o sostituire composizione,
  stile, palette o asset visivi; mantenere lo scaffold neutro finché non vengono
  forniti indicazioni e materiali.
- Direzione visiva corrente: pixel art monocromatica con cinque tonalità
  consentite, `#000000`, `#202020`, `#404040`, `#606060` e `#808080`. Niente
  texture o dithering. Gli asset non devono contenere illuminazione baked:
  rappresentare gli oggetti attraverso le loro silhouette usando le tonalità
  della palette. Le luci, se introdotte, vanno gestite nella scena Godot.
- Per `garage_room`, gli asset `V006` modificati dall'utente sono il riferimento
  visivo definitivo. Mantieni invariati i relativi sorgenti Pixelorama e gli
  export; implementa l'illuminazione e gli effetti nella scena Godot.
- La scena resta una PoC sotto tests/ e non sostituisce la scena principale.
