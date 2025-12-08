Mission HeXalife - Game Story
-----------------------------

Version: 0.0.4
Authors:

- JervNorsk
- Feona
- Raino98

## 📝 Storyboard Riassunto e Tracciamento (Aggiornato)


| Sezione |               Titolo Scena               |               Location Principale               |                                          Evento/Stato                                          |                                                                     Narrazione Chiave                                                                     |                                                    Azioni/Interazioni del Player                                                    |            Personaggi Coinvolti            |
| :-----: | :---------------------------------------: | :---------------------------------------------: | :---------------------------------------------------------------------------------------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------------------------------------------------: | :----------------------------------------: |
|   1-3   |              *(Precedenti)*              |            Stanza Criogenica, Ponte            |                               Risveglio e Dialogo con il Medico.                               |                                             Malfunzionamento Motori, Status Ingegnere, 2 mesi di criogenesi.                                             |                                               Varie interazioni e 3 dialoghi forzati.                                               |               Player, Doctor               |
|   ---   |                    ---                    |                       ---                       |                                               ---                                               |                                                                            ---                                                                            |                                                                 ---                                                                 |                    ---                    |
|  **4**  |     **Chiamata Urgente del Capitano**     |                Ponte della Nave                |                            L'OloNav del Medico squilla urgentemente.                            |      Il**Capitano** rivela la presenza di un **Fungo** che sta invadendo la nave. Le spore si moltiplicano in Sala Macchine grazie all'elettricità.      |                                           *Nessuna azione specificata in questa sezione*                                           |    Player, Doctor, Captain (via OloNav)    |
|   ---   |                    ---                    |                       ---                       |                                               ---                                               |                                                                            ---                                                                            |                                                                 ---                                                                 |                    ---                    |
|  **5**  |         **L'Incarico Ufficiale**         |                Ponte della Nave                |                       Il Medico si allontana per seguire i suoi compiti.                       |                            Il**Capitano** incarica il Player (Ingegnere) di trovare e portare il **Biologo** in Sala Macchine.                            |                                       **Obiettivo:** Raggiungere il Biologo (nuova Location).                                       |       Player, Doctor (si allontana)       |
|   ---   |                    ---                    |                       ---                       |                                               ---                                               |                                                                            ---                                                                            |                                                                 ---                                                                 |                    ---                    |
|  **6**  | **Gestione Energetica in Sala Macchine** |                  Sala Macchine                  |                                   Player e Biologo arrivano.                                   |            Il**Biologo** inizia lo studio del fungo. Il **Player** capisce che la bassa energia richiede la **gestione manuale delle porte**.            | **Azioni:** Player dà energia al **Secondo Reattore**. **Dialogo:** Prima analisi, si chiama il Capitano con l'OloNav del Biologo. |   Player, Biologo, Captain (via OloNav)   |
|   ---   |                    ---                    |                       ---                       |                                               ---                                               |                                                                            ---                                                                            |                                                                 ---                                                                 |                    ---                    |
|  **7**  | **Il Blocco e la Trasmissione Difettosa** |              Ponte / Stanza Player              |                           Tentativo di recuperare l'OloNav personale.                           | Il Player rimane**bloccato** nella sua stanza. Tentativi di comunicazione falliscono (**trasmissione malfunzionante**). La porta si sblocca dopo X tempo. |         **Azioni:** Player si reca nella sua stanza per prendere il suo **OloNav** personale. Tenta di chiamare il Biologo.         |                   Player                   |
|   ---   |                    ---                    |                       ---                       |                                               ---                                               |                                                                            ---                                                                            |                                                                 ---                                                                 |                    ---                    |
|  **8**  |       **La Corsa Contro il Tempo**       |             Sala Macchine / Cockpit             | Il Fungo ha interferito col sistema elettrico (OloNav intermittente). Il Capitano non risponde. |                                          Trovano la porta del**Cockpit** **bloccata** dalla crescita del fungo.                                          |  **Azioni:** Il Player torna in Sala Macchine. Tentativo fallito di avvisare il resto dell'equipaggio/Capitano. Vanno al Cockpit.  |              Player, Biologo              |
|   ---   |                    ---                    |                       ---                       |                                               ---                                               |                                                                            ---                                                                            |                                                                 ---                                                                 |                    ---                    |
|  **9**  |          **Il Drone e L'Orrore**          | Sala Macchine / Condotti di Aerazione / Cockpit |                                Riunione per sbloccare la porta.                                |                            **Droni di Pulizia** usati nei **Condotti di Aerazione** come soluzione per raggiungere la stanza.                            |   **Azioni:** Riunione (implicita, con Biologo/Doctor?), si decide per il drone. **Evento:** Raggiungono la stanza del Capitano.   | Player, Biologo (e forse altri equipaggio) |
| **10** |       **La Scomparsa del Capitano**       |                     Cockpit                     |                                      Il Capitano è morto.                                      |                                                 Il corpo del Capitano sta venendo**inglobato dal fungo**.                                                 |                                                 **Scoperta:** Il Capitano è morto.                                                 |              Player, Biologo              |

---

## Storyboard

1. [Scena] Risveglio

   - [Location] Stanza Criogenica

     - Al centro della stanza ci sono disposte 4 capsule criogeniche
     - Sulla parete centrale sono disposti una serie di schermi e un terminale
     - Sulla parete sinistra e presente una porta che si collega al ponte
   - [Evento] Stato di emergenza della nave

     - Luci rosse di emergenza ad intermittenza, animazione lenta
     - Sirena di emergenza
   - [Narrazione] Ti svegli nella Stanza Criogenica.

     - Vedi altre 3 capsule criogeniche aperte e vuote
     - Sei da solo nella stanza
     - Il personaggio giocante è in uno stato di confusione iniziale
   - [Azioni] Puoi interagire con la stanza

     - [Prop] Ispezioni il terminale della stanza

       - A schermo e' presente lo stato della nave e dove il personale e' richiesto
       - A schermo e' presente il tempo di scongelamento delle capsule
       - A schermo e' presente il tempo di criogenesi del presonale
     - [Prop] Ispezioni le capsule criogeniche aperte

       - [Dialogo] Sembra siano state aprte da un po'
     - [Prop] Attraversi la porta a sinistra
2. [Scena] Incontro con il MEDICO

   - [Location] Ponte della nave

     - Collega le stanze della nave
   - [Evento] Stato di emergenza della nave
   - [Narrazione] Uscendo dalla stanza ti ritrovi sul ponte della nave, dopo qualche passo incontri una figura che si avvicina velocemente: e' il MEDICO di bordo

     - Vedi altre 3 capsule criogeniche aperte e vuote
     - Sei da solo nella stanza
     - Il personaggio giocante è in uno stato di confusione iniziale

- [Azioni] Puoi interagire con la stanza

  - [Prop] Ispezioni il terminale della stanza

    - A schermo e' presente lo stato della nave e dove il personale e' richiesto
    - A schermo e' presente il tempo di scongelamento delle capsule
    - A schermo e' presente il tempo di criogenesi del presonale
  - [Prop] Ispezioni le capsule criogeniche aperte

    - [Dialogo] Sembra siano state aprte da un po'
  - [Prop] Attraversi la porta a sinistra

