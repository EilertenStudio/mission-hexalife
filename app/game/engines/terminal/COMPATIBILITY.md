# Compatibilità degli engine terminali

Confronto tra le versioni usate dagli esempi nel repository: Arcade
(`ascii-arcade` 0.1.7), xRenderEngine (`xre-rs` 0.2.0) e Gemini Engine
(`gemini-engine` 1.2.1). Le capacità indicate sono quelle rilevanti per la
scena 3D `room`; controlli e menu specifici dell'applicazione sono distinti
dalle funzioni offerte dall'engine. La configurazione desiderata dei menu di
debug e camera è in [`menus.json`](../../src/scenes/room/menus.json).

## Confronto

| Area | Arcade | xRenderEngine (XRE) | Gemini Engine |
| --- | --- | --- | --- |
| Rendering | Renderer software con buffer RGBA, buffer di profondità e supersampling prima della conversione in glifi. | Renderer software con buffer di campioni per sotto-cella e test di profondità per campione; supporta shading e interpolazione sulle superfici. | Renderer software che proietta mesh e riempie poligoni nella griglia del terminale; l'illuminazione seleziona caratteri per faccia. |
| Materiali e luci | API per materiali e shader personalizzati. L'implementazione della stanza calcola luci RGB, attenuazione e spotlight nel materiale. | Materiali RGB con texture, emissione e quantizzazione cel; luci ambientali, direzionali e puntiformi con attenuazione. Non offre spotlight o blending alpha dei materiali. | Mesh e colori per faccia, con illuminazione ambientale, direzionale e puntiforme. La luce produce principalmente un'intensità usata per scegliere il glifo; non offre spotlight, attenuazione per distanza o blending alpha dei materiali. |
| Scene e applicazione | Fornisce renderer, geometrie e API della piattaforma. Ciclo di gioco, animazioni e controlli sono responsabilità dell'app. | È il framework più ampio dei tre: include scene, camera/controller, input, strumenti TUI e componenti per il ciclo di gioco. | Fornisce soprattutto mesh 3D e viewport; l'app gestisce il ciclo, gli input e i controlli della camera. |
| Menu nell'esempio | Menu camera con orbita, pan, zoom e volo; menu sistema con FPS misurati e limite regolabile. | Menu camera e sistema con volo; non implementa l'accelerazione Shift, il pan col tasto centrale né lo zoom con rotella. | Menu camera con orbita, pan e zoom; volo, menu debug sistema e gesti alternativi centrale/rotella non sono implementati. |
| Resa della stanza attuale | Mantiene il fascio spotlight traslucido e le luci colorate tramite il materiale personalizzato dell'app. | Approssima lo spotlight con una luce puntiforme calda in movimento; non mostra il fascio trasparente. | Approssima il fascio con un cono opaco e una luce puntiforme in movimento; l'illuminazione non conserva il contributo RGB delle luci. |

Tutti e tre renderizzano via CPU e presentano il risultato nel terminale: la
differenza visiva dipende dal buffer e dai materiali disponibili, non dall'uso
di una GPU. La trasparenza di celle o widget dell'interfaccia TUI, quando
disponibile, non equivale al blending alpha di un materiale 3D.

## Scelta attuale

La preferenza attuale è **Arcade**. Per la stanza è quello che consente di
ottenere la resa più vicina allo stato desiderato, in particolare per il fascio
traslucido, lo spotlight e l'illuminazione colorata. XRE resta un'alternativa
più strutturata per scene e interfacce terminali, ma per raggiungere quella
resa richiederebbe estensioni o approssimazioni al renderer. Gemini è adatto a
provare mesh 3D ASCII essenziali, ma ha meno strumenti per riprodurre questi
effetti.

La preferenza non cambia la fonte canonica della scena: geometria, luci,
materiali e vista iniziale restano descritti in
[`app/game/src/scenes/room/`](../../src/scenes/room/). Le implementazioni degli
engine devono seguire quello stato e documentare le differenze tecniche.

## Riferimenti

- [Arcade: API per costruire con il rendering engine](https://github.com/vercel-labs/arcade#build-with-arcade)
- [Arcade: verifica dell'output e pipeline di rendering](https://github.com/vercel-labs/arcade/blob/main/docs/verifying-output.md)
- [XRE 0.2.0: documentazione del renderer](https://docs.rs/xre-render/0.2.0/xre_render/)
- [XRE: guida al rendering](https://github.com/ulpian/xRenderEngine/blob/main/docs/book/src/rendering.md)
- [Gemini Engine 1.2.1: API 3D](https://docs.rs/gemini-engine/1.2.1/gemini_engine/view3d/)
- [Gemini Engine 1.2.1: esempi](https://docs.rs/crate/gemini-engine/1.2.1/source/examples/)
