// Checkpoint di sviluppo: ogni salto crea una nuova partita con lo stato indicato.
const checkpoints = [
  { id: "inizio", label: "Introduzione", path: null, setup: {} },
  { id: "risveglio", label: "Risveglio nella sala criogenica", path: "risveglio", setup: {} },
  { id: "medico", label: "Incontro con il Medico", path: "corridoio_medico", setup: {} },
  { id: "motori", label: "Intervento nella sala motori", path: "sala_motori", setup: {} },
  {
    id: "silenzio", label: "Il Capitano non risponde", path: "silenzio",
    setup: { turno: 1, fascia: 2, energia: 3 },
  },
  {
    id: "ponte", label: "Indagine e preparazione", path: "ponte",
    setup: { turno: 1, fascia: 2, energia: 3 },
  },
  {
    id: "corpo", label: "Ingresso nel centro di comando", path: "corpo",
    setup: {
      turno: 4, giorno: 2, fascia: 1, energia: 2, fungo: 2, porta: 2,
      cockpit_aperto: true, turno_apertura: 4, kit_recuperato: true,
      turno_kit: 2, analisi_fungo: true, visto_qc_crio: true,
    },
  },
  {
    id: "asteroidi", label: "Manovra sugli asteroidi", path: "asteroidi",
    setup: {
      turno: 12, giorno: 4, fascia: 1, energia: 4, fungo: 2,
      cockpit_aperto: true, qc_pronto: true, visto_qc_crio: true,
    },
  },
];

if (typeof module !== "undefined" && module.exports) module.exports = checkpoints;
if (typeof window !== "undefined") window.hexalifeCheckpoints = checkpoints;
