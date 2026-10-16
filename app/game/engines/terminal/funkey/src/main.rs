use funkey::{run, Config, Flow, Frame, Game, Input, Key, Sprite};

const WIDTH: i32 = 160;
const HEIGHT: i32 = 100;
const BACKGROUND: u32 = 0x090e18;
const CRYOGENIC_ROOM_PNG: &[u8] = include_bytes!(env!("FUNKEY_CRYOGENIC_ROOM_IMAGE"));

#[derive(Clone, Copy, PartialEq, Eq)]
enum View {
    Wakeup,
    Room,
    Capsule,
    Terminal,
    Map,
    QcAlert,
    Blackout,
    SceneEnd,
}

struct CryogenicAwakening {
    background: Sprite,
    view: View,
    selected: usize,
    capsule_examined: bool,
    terminal_seen: bool,
    rebooted: bool,
    room_message: [&'static str; 4],
}

impl CryogenicAwakening {
    fn new() -> Self {
        let background = Sprite::from_png(CRYOGENIC_ROOM_PNG)
            .expect("Impossibile decodificare il fondale pixel art della sala criogenica");
        Self {
            background,
            view: View::Wakeup,
            selected: 0,
            capsule_examined: false,
            terminal_seen: false,
            rebooted: false,
            room_message: [
                "RESTI SEDUTO FINCHE LA STANZA RALLENTA.",
                "LA GUARNIZIONE DELLA CAPSULA E NERA.",
                "LE ALTRE CAPSULE SONO VUOTE. SEI SOLO.",
                "IL TERMINALE LAMPEGGIA. PORTA BLOCCATA.",
            ],
        }
    }

    fn open_target(&mut self, target: usize) {
        self.selected = target;
        match target {
            0 => {
                self.capsule_examined = true;
                self.view = View::Capsule;
            }
            1 => {
                self.terminal_seen = true;
                self.view = View::Terminal;
            }
            2 if self.rebooted => self.view = View::SceneEnd,
            2 => {
                self.room_message = [
                    "TIRI LA MANIGLIA. LA PORTA NON CEDE.",
                    "SETTORE CRIOGENICO ISOLATO.",
                    "SUL PANNELLO LA LUCE RESTA ROSSA.",
                    "IL TERMINALE E ANCORA ACCESO.",
                ];
            }
            _ => {}
        }
    }

    fn close_terminal(&mut self) {
        if self.capsule_examined && !self.rebooted {
            self.view = View::Blackout;
        } else {
            self.view = View::Room;
            self.room_message = [
                "IL MESSAGGIO DEL CAPITANO RESTA ATTIVO.",
                "PUOI RILEGGERE MAPPA E ALLARME QC.",
                "NESSUNO E VISIBILE NELLA SALA.",
                "SCEGLI UN OGGETTO DA ESAMINARE.",
            ];
        }
    }

    fn return_from_capsule(&mut self) {
        if self.terminal_seen && !self.rebooted {
            self.view = View::Blackout;
        } else {
            self.view = View::Room;
        }
    }

    fn reboot_room(&mut self) {
        self.rebooted = true;
        self.view = View::Room;
        self.room_message = [
            "LA RISERVA LOCALE SI RIAVVIA.",
            "SIRENA SPENTA. LUCI NORMALI DI NUOVO.",
            "LA SPIA DELLA PORTA PASSA AL VERDE.",
            "I REATTORI RESTANO IN AVARIA.",
        ];
    }

    fn change_selection(&mut self, amount: isize) {
        self.selected = (self.selected as isize + amount).rem_euclid(3) as usize;
    }

    fn draw_background(&self, frame: &mut Frame) {
        frame.clear(BACKGROUND);
        let fits_width = frame.w * self.background.h <= frame.h * self.background.w;
        let (draw_w, draw_h) = if fits_width {
            (frame.w, frame.w * self.background.h / self.background.w)
        } else {
            (frame.h * self.background.w / self.background.h, frame.h)
        };
        let offset_x = (frame.w - draw_w) / 2;
        let offset_y = (frame.h - draw_h) / 2;

        for y in 0..draw_h {
            let source_y = y * self.background.h / draw_h;
            for x in 0..draw_w {
                let source_x = x * self.background.w / draw_w;
                let pixel = self.background.px[(source_y * self.background.w + source_x) as usize];
                if pixel >> 24 != 0 {
                    frame.put(offset_x + x, offset_y + y, pixel & 0x00ff_ffff);
                }
            }
        }

        if !self.rebooted {
            frame.dim(0.68);
            let width = frame.w;
            frame.rect(0, 0, width, 12, 0x26090d);
            frame.rect(5, 3, 6, 6, 0xff3544);
            text(frame, 15, 4, "SIRENA // SETTORE ISOLATO", 0xff8b91);
        } else {
            let width = frame.w;
            frame.rect(0, 0, width, 12, 0x091719);
            frame.rect(5, 3, 6, 6, 0x58d7ae);
            text(frame, 15, 4, "RISERVA LOCALE ATTIVA", 0x8de6c2);
        }
    }

    fn draw_room(&self, frame: &mut Frame) {
        panel(frame, 58, if self.rebooted { 0x397d6c } else { 0x78353e });
        text(frame, 4, 61, "SALA CRIOGENICA  //  1-3 O FRECCE", 0xd5e1ed);
        for (i, line) in self.room_message.iter().enumerate() {
            text(frame, 4, 68 + i as i32 * 6, line, 0xb9c8d5);
        }
        let labels = ["1 CAPSULA", "2 TERMINALE", "3 PORTA"];
        for (index, label) in labels.iter().enumerate() {
            draw_button(frame, 2 + index as i32 * 53, 93, label, self.selected == index, self.rebooted);
        }
    }

    fn draw_wakeup(&self, frame: &mut Frame) {
        panel(frame, 58, 0x78353e);
        text(frame, 4, 61, "RISVEGLIO  //  POV INGEGNERE", 0xff9a9a);
        text(frame, 4, 69, "IL SUONO ARRIVA PRIMA DEI PENSIERI.", 0xe4dce0);
        text(frame, 4, 75, "LA LUCE ROSSA PULSA OLTRE IL VETRO.", 0xe4dce0);
        text(frame, 4, 81, "IL COPERCHIO NON CEDE. TIRI LA LEVA.", 0xe4dce0);
        text(frame, 4, 87, "L'ARIA SIBILA. LE GAMBE CEDONO.", 0xe4dce0);
        text(frame, 4, 94, "INVIO // GUARDA LA STANZA", 0xffb8b8);
    }

    fn draw_capsule(&self, frame: &mut Frame) {
        panel(frame, 58, 0x78353e);
        text(frame, 4, 61, "LA TUA CAPSULA", 0xff9a9a);
        text(frame, 4, 68, "UN FERMO DEL COPERCHIO E DEFORMATO.", 0xd5e1ed);
        text(frame, 4, 74, "SPIA DI MANUTENZIONE ACCESA.", 0xd5e1ed);
        text(frame, 4, 80, "IL DISPLAY NON MOSTRA LA CRONOLOGIA.", 0xd5e1ed);
        text(frame, 4, 86, "TI APPOGGI. LE DITA SI CALMANO.", 0xd5e1ed);
        text(frame, 4, 94, "INVIO // TORNA ALLA SALA", 0xffb8b8);
    }

    fn draw_terminal(&self, frame: &mut Frame) {
        panel(frame, 52, 0x2d8290);
        text(frame, 4, 55, "TERMINALE // MESSAGGIO IN ATTESA", 0x8ce7f1);
        text(frame, 4, 63, "REGISTRAZIONE AUDIO DEL CAPITANO.", 0xd5e1ed);
        text(frame, 4, 70, "SALA MOTORI. QC A POTENZA STABILE.", 0xd5e1ed);
        text(frame, 4, 77, "IMPIANTI VITALI ATTIVI.", 0xd5e1ed);
        text(frame, 4, 85, "M MAPPA    A ALLARME QC", 0x8ce7f1);
        text(frame, 4, 93, "ESC // CHIUDI TERMINALE", 0x8ce7f1);
    }

    fn draw_map(&self, frame: &mut Frame) {
        panel(frame, 48, 0x2d8290);
        text(frame, 4, 51, "MAPPA // SEGNALI DEI TERMINALI", 0x8ce7f1);
        text(frame, 4, 59, "CAPITANO: CENTRO DI COMANDO", 0xd5e1ed);
        text(frame, 4, 65, "PRIMO UFFICIALE: CORRIDOIO", 0xd5e1ed);
        text(frame, 4, 71, "MEDICO: VERSO SALA CRIOGENICA", 0xd5e1ed);
        text(frame, 4, 77, "SCIENZIATO: VICINO AL LABORATORIO", 0xd5e1ed);
        text(frame, 4, 84, "POSIZIONI RILEVATE. NON VEDI NESSUNO.", 0xb9c8d5);
        text(frame, 4, 93, "ESC / INVIO // TORNA AL TERMINALE", 0x8ce7f1);
    }

    fn draw_qc_alert(&self, frame: &mut Frame) {
        panel(frame, 52, 0x2d8290);
        text(frame, 4, 55, "QC // ALLARME ATTIVO", 0x8ce7f1);
        text(frame, 4, 63, "ENERGIA DEI REATTORI IN CALO.", 0xd5e1ed);
        text(frame, 4, 70, "RITORNO INTERROTTO.", 0xd5e1ed);
        text(frame, 4, 77, "ASTEROIDI PREVISTI: CIRCA TRE GIORNI.", 0xff9a9a);
        text(frame, 4, 84, "LA COLLISIONE NON E CERTA.", 0xb9c8d5);
        text(frame, 4, 89, "STIMA LEGATA ALL'ENERGIA DISPONIBILE.", 0xb9c8d5);
        text(frame, 4, 95, "ESC / INVIO // TORNA", 0x8ce7f1);
    }

    fn draw_blackout(&self, frame: &mut Frame) {
        frame.clear(0x020407);
        panel(frame, 58, 0x78353e);
        text(frame, 4, 61, "BLACKOUT", 0xff9a9a);
        text(frame, 4, 69, "IL TERMINALE SI SPEGNE.", 0xd5e1ed);
        text(frame, 4, 76, "UN CLIC NEL BUIO. LA SIRENA TACE.", 0xd5e1ed);
        text(frame, 4, 83, "LA RISERVA LOCALE SI RIAVVIA.", 0xd5e1ed);
        text(frame, 4, 94, "INVIO // CONTINUA", 0xffb8b8);
    }

    fn draw_scene_end(&self, frame: &mut Frame) {
        panel(frame, 58, 0x397d6c);
        text(frame, 4, 61, "PORTA SBLOCCATA", 0x8de6c2);
        text(frame, 4, 69, "LA PORTA SI APRE SUL CORRIDOIO.", 0xd5e1ed);
        text(frame, 4, 76, "LA SCENA DEL RISVEGLIO TERMINA QUI.", 0xd5e1ed);
        text(frame, 4, 94, "Q // ESCI", 0x8de6c2);
    }
}

impl Game for CryogenicAwakening {
    fn update(&mut self, input: &Input, _dt: f32) -> Flow {
        if input.pressed(Key::Char('q')) {
            return Flow::Quit;
        }

        let confirm = input.pressed(Key::Enter) || input.pressed(Key::Space);
        let back = input.pressed(Key::Escape) || input.pressed(Key::Backspace);

        match self.view {
            View::Wakeup => {
                if confirm {
                    self.view = View::Room;
                } else if back {
                    return Flow::Quit;
                }
            }
            View::Room => {
                if back {
                    return Flow::Quit;
                }
                if input.pressed(Key::Left) {
                    self.change_selection(-1);
                } else if input.pressed(Key::Right) {
                    self.change_selection(1);
                } else if input.pressed(Key::Char('1')) || input.pressed(Key::Char('c')) {
                    self.open_target(0);
                } else if input.pressed(Key::Char('2')) || input.pressed(Key::Char('t')) {
                    self.open_target(1);
                } else if input.pressed(Key::Char('3')) || input.pressed(Key::Char('p')) {
                    self.open_target(2);
                } else if confirm {
                    self.open_target(self.selected);
                }
            }
            View::Capsule => {
                if confirm || back {
                    self.return_from_capsule();
                }
            }
            View::Terminal => {
                if input.pressed(Key::Char('m')) || input.pressed(Key::Char('1')) {
                    self.view = View::Map;
                } else if input.pressed(Key::Char('a')) || input.pressed(Key::Char('2')) {
                    self.view = View::QcAlert;
                } else if back {
                    self.close_terminal();
                }
            }
            View::Map | View::QcAlert => {
                if confirm || back {
                    self.view = View::Terminal;
                }
            }
            View::Blackout => {
                if confirm {
                    self.reboot_room();
                }
            }
            View::SceneEnd => {
                if back {
                    return Flow::Quit;
                }
            }
        }

        Flow::Continue
    }

    fn draw(&mut self, frame: &mut Frame) {
        self.draw_background(frame);
        match self.view {
            View::Wakeup => self.draw_wakeup(frame),
            View::Room => self.draw_room(frame),
            View::Capsule => self.draw_capsule(frame),
            View::Terminal => self.draw_terminal(frame),
            View::Map => self.draw_map(frame),
            View::QcAlert => self.draw_qc_alert(frame),
            View::Blackout => self.draw_blackout(frame),
            View::SceneEnd => self.draw_scene_end(frame),
        }
    }
}

fn text(frame: &mut Frame, x: i32, y: i32, value: &str, color: u32) {
    frame.text(x, y, &value.to_ascii_uppercase(), color);
}

fn panel(frame: &mut Frame, y: i32, edge: u32) {
    let (width, height) = (frame.w, frame.h);
    frame.rect(0, y, width, height - y, 0x080d14);
    frame.hline(0, y, width, edge);
}

fn draw_button(frame: &mut Frame, x: i32, y: i32, label: &str, selected: bool, normal: bool) {
    let (fill, edge, ink) = if selected && normal {
        (0x14332f, 0x58d7ae, 0xb5f4dc)
    } else if selected {
        (0x3a1c22, 0xff5963, 0xffc3c6)
    } else if normal {
        (0x0e171a, 0x397d6c, 0xb9c8d5)
    } else {
        (0x120d11, 0x623039, 0xb9c8d5)
    };
    frame.rect(x, y, 50, 7, fill);
    frame.hline(x, y, 50, edge);
    frame.hline(x, y + 6, 50, edge);
    frame.vline(x, y, 7, edge);
    frame.vline(x + 49, y, 7, edge);
    text(frame, x + 3, y + 1, label, ink);
}

fn main() {
    let mut game = CryogenicAwakening::new();
    run(
        &mut game,
        Config {
            width: WIDTH,
            height: HEIGHT,
            fps: 6,
        },
    );
}
