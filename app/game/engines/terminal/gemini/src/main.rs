use std::f64::consts::TAU;
use std::io::{self, IsTerminal, Write};
use std::time::{Duration, Instant};

use crossterm::event::{
    self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEventKind, KeyModifiers,
    MouseButton, MouseEventKind,
};
use crossterm::execute;
use crossterm::terminal::{
    EnterAlternateScreen, LeaveAlternateScreen, disable_raw_mode, enable_raw_mode,
};
use gemini_engine::ascii::Text;
use gemini_engine::core::{ColChar, Modifier, Vec2D};
use gemini_engine::mesh3d::{Face, Mesh3D, Transform3D, Vec3D};
use gemini_engine::view::ScaleFitView;
use gemini_engine::view3d::{DisplayMode, Light, Viewport};

const FPS: f64 = 6.0;
const FOV_DEGREES: f64 = 48.0;
const ORBIT_MIN_DISTANCE: f64 = 2.5;
const ORBIT_MAX_DISTANCE: f64 = 20.0;

#[derive(Clone, Copy)]
enum CameraDrag {
    Orbit,
    Zoom,
    Pan,
}

struct OrbitCamera {
    target: Vec3D,
    yaw: f64,
    pitch: f64,
    distance: f64,
}

impl OrbitCamera {
    fn initial() -> Self {
        let eye = Vec3D::new(4.5, 2.85, 6.5);
        let target = Vec3D::new(0.0, -0.35, 0.0);
        let offset = eye - target;
        let distance = offset.length();
        Self {
            target,
            yaw: offset.x.atan2(offset.z),
            pitch: (offset.y / distance).asin(),
            distance,
        }
    }

    fn eye(&self) -> Vec3D {
        let horizontal = self.pitch.cos();
        self.target
            + Vec3D::new(
                self.yaw.sin() * horizontal,
                self.pitch.sin(),
                self.yaw.cos() * horizontal,
            ) * self.distance
    }

    fn transform(&self) -> Transform3D {
        Transform3D::look_at_lh(self.eye(), self.target, Vec3D::Y)
    }

    fn drag(&mut self, mode: CameraDrag, dx: f64, dy: f64, width: usize, height: usize) {
        match mode {
            CameraDrag::Orbit => {
                self.yaw += dx * 0.025;
                self.pitch = (self.pitch - dy * 0.025).clamp(-1.52, 1.52);
            }
            CameraDrag::Zoom => {
                self.distance = (self.distance * (dy * 0.018).exp())
                    .clamp(ORBIT_MIN_DISTANCE, ORBIT_MAX_DISTANCE);
            }
            CameraDrag::Pan => {
                let forward = (self.target - self.eye()).normalize();
                let right = forward.cross(Vec3D::Y).normalize();
                let camera_up = right.cross(forward).normalize();
                let width = width.max(1) as f64;
                let height = height.max(1) as f64;
                let scale = self.distance * 1.4;
                self.target += right * (-dx * scale / width) + camera_up * (dy * scale / height);
            }
        }
    }
}

struct TerminalGuard;

impl TerminalGuard {
    fn enter() -> io::Result<Self> {
        enable_raw_mode()?;
        if let Err(error) = execute!(
            io::stdout(),
            EnterAlternateScreen,
            EnableMouseCapture,
            crossterm::cursor::Hide
        ) {
            let _ = disable_raw_mode();
            return Err(error);
        }
        Ok(Self)
    }
}

impl Drop for TerminalGuard {
    fn drop(&mut self) {
        let mut stdout = io::stdout();
        let _ = execute!(
            stdout,
            crossterm::cursor::Show,
            DisableMouseCapture,
            LeaveAlternateScreen
        );
        let _ = disable_raw_mode();
        let _ = stdout.flush();
    }
}

fn main() -> io::Result<()> {
    if !io::stdin().is_terminal() || !io::stdout().is_terminal() {
        eprintln!("L'esempio Gemini Engine richiede un terminale interattivo.");
        std::process::exit(1);
    }

    let _terminal = TerminalGuard::enter()?;
    run()
}

fn run() -> io::Result<()> {
    let mut view = ScaleFitView::new(ColChar::EMPTY).with_empty_row_count(1);
    let mut camera = OrbitCamera::initial();
    let mut viewport = Viewport::new(camera.transform(), FOV_DEGREES, view.view.center());
    viewport.clipping_distace = 0.1;
    viewport.character_width_multiplier = 2.0;

    viewport.objects.extend(room_surfaces());
    viewport.objects.push(cube_mesh(
        Vec3D::new(0.0, 1.67, 0.0),
        0.115,
        [255, 208, 124],
    ));
    for (position, color) in [
        (Vec3D::new(-2.2, 1.67, -2.45), [115, 181, 255]),
        (Vec3D::new(2.2, 1.67, -2.45), [255, 122, 194]),
        (Vec3D::new(-2.2, 1.67, 2.45), [122, 255, 199]),
    ] {
        viewport.objects.push(cube_mesh(position, 0.09, color));
    }
    let beam_index = viewport.objects.len();
    viewport.objects.push(cone_mesh());

    let mut camera_menu_open = false;
    let mut camera_drag = None;
    let mut last_mouse_position = None;
    let mut running = true;
    let frame_period = Duration::from_secs_f64(1.0 / FPS);
    let mut last_frame = Instant::now();
    let start = Instant::now();

    while running {
        let wait = frame_period
            .saturating_sub(last_frame.elapsed())
            .min(Duration::from_millis(20));

        if event::poll(wait)? {
            match event::read()? {
                Event::Key(key) if key.kind != KeyEventKind::Release => {
                    if key.code == KeyCode::Char('c')
                        && key.modifiers.contains(KeyModifiers::CONTROL)
                    {
                        running = false;
                    } else {
                        match key.code {
                            KeyCode::Char('c' | 'C') => {
                                camera_menu_open = !camera_menu_open;
                                camera_drag = None;
                                last_mouse_position = None;
                            }
                            KeyCode::Esc if camera_menu_open => {
                                camera_menu_open = false;
                                camera_drag = None;
                                last_mouse_position = None;
                            }
                            KeyCode::Esc | KeyCode::Char('q' | 'Q') if !camera_menu_open => {
                                running = false;
                            }
                            _ => {}
                        }
                    }
                }
                Event::Mouse(mouse) if camera_menu_open => match mouse.kind {
                    MouseEventKind::Down(button) => {
                        let alt = mouse.modifiers.contains(KeyModifiers::ALT);
                        let ctrl_alt = alt && mouse.modifiers.contains(KeyModifiers::CONTROL);
                        camera_drag = match button {
                            MouseButton::Left if ctrl_alt => Some(CameraDrag::Pan),
                            MouseButton::Left if alt => Some(CameraDrag::Orbit),
                            MouseButton::Right if alt => Some(CameraDrag::Zoom),
                            _ => None,
                        };
                        last_mouse_position = Some((mouse.column, mouse.row));
                    }
                    MouseEventKind::Drag(_) => {
                        if let (Some(mode), Some((last_x, last_y))) =
                            (camera_drag, last_mouse_position)
                        {
                            let dx = f64::from(mouse.column) - f64::from(last_x);
                            let dy = f64::from(mouse.row) - f64::from(last_y);
                            camera.drag(mode, dx, dy, view.view.width, view.view.height);
                            last_mouse_position = Some((mouse.column, mouse.row));
                        }
                    }
                    MouseEventKind::Up(_) => {
                        camera_drag = None;
                        last_mouse_position = None;
                    }
                    _ => {}
                },
                Event::Resize(_, _) => view.update(),
                _ => {}
            }
        }

        if !running || last_frame.elapsed() < frame_period {
            continue;
        }

        let elapsed = start.elapsed().as_secs_f64();
        let angle = 0.43 * (elapsed * 1.15).sin();
        let beam_transform = Transform3D::from_translation(Vec3D::new(0.0, 1.42, 0.0))
            .mul_mat4(&Transform3D::from_rotation_z(angle));
        viewport.objects[beam_index].transform = beam_transform;

        // Gemini has point and directional lights, but no spot light, cone falloff,
        // distance attenuation, or colored light contribution.
        let moving_light = Vec3D::new(1.45 * angle.sin(), 1.5, 0.0);
        viewport.display_mode = DisplayMode::Illuminated {
            lights: vec![
                Light::new_ambient(0.18),
                Light::new_point(0.22, Vec3D::new(-2.2, 1.5, -2.45)),
                Light::new_point(0.22, Vec3D::new(2.2, 1.5, -2.45)),
                Light::new_point(0.22, Vec3D::new(-2.2, 1.5, 2.45)),
                Light::new_point(0.38, moving_light),
            ],
        };
        viewport.camera_transform = camera.transform();
        view.update();
        viewport.canvas_centre = view.view.center();
        view.view.clear();
        view.view.draw(&viewport);

        let help = if camera_menu_open {
            "Camera | Alt+Left orbit | Ctrl+Alt+Left pan | Alt+Right zoom | Esc close"
        } else {
            "Gemini Engine | C camera | q quit"
        };
        view.view.draw(&Text::new(
            Vec2D::new(1, 0),
            help,
            Modifier::from_rgb(230, 230, 230),
        ));
        view.view.display_render()?;
        last_frame = Instant::now();
    }

    Ok(())
}

fn room_surfaces() -> Vec<Mesh3D> {
    vec![
        quad_mesh(
            [
                Vec3D::new(-3.0, -2.0, -3.4),
                Vec3D::new(3.0, -2.0, -3.4),
                Vec3D::new(3.0, -2.0, 3.4),
                Vec3D::new(-3.0, -2.0, 3.4),
            ],
            [91, 103, 126],
        ),
        quad_mesh(
            [
                Vec3D::new(-3.0, -2.0, -3.4),
                Vec3D::new(3.0, -2.0, -3.4),
                Vec3D::new(3.0, 2.0, -3.4),
                Vec3D::new(-3.0, 2.0, -3.4),
            ],
            [80, 95, 124],
        ),
        quad_mesh(
            [
                Vec3D::new(-3.0, -2.0, 3.4),
                Vec3D::new(-3.0, -2.0, -3.4),
                Vec3D::new(-3.0, 2.0, -3.4),
                Vec3D::new(-3.0, 2.0, 3.4),
            ],
            [101, 112, 139],
        ),
        quad_mesh(
            [
                Vec3D::new(3.0, -2.0, -3.4),
                Vec3D::new(3.0, -2.0, 3.4),
                Vec3D::new(3.0, 2.0, 3.4),
                Vec3D::new(3.0, 2.0, -3.4),
            ],
            [75, 87, 112],
        ),
    ]
}

fn quad_mesh(vertices: [Vec3D; 4], color: [u8; 3]) -> Mesh3D {
    let fill = ColChar::SOLID.with_rgb(color[0], color[1], color[2]);
    let mut faces = vec![Face::new(vec![0, 1, 2, 3], fill)];
    faces.push(Face::new(vec![3, 2, 1, 0], fill));
    Mesh3D::new(vertices.to_vec(), faces)
}

fn cube_mesh(position: Vec3D, half_size: f64, color: [u8; 3]) -> Mesh3D {
    let points = [
        Vec3D::new(1.0, 1.0, -1.0),
        Vec3D::new(1.0, 1.0, 1.0),
        Vec3D::new(1.0, -1.0, -1.0),
        Vec3D::new(1.0, -1.0, 1.0),
        Vec3D::new(-1.0, 1.0, -1.0),
        Vec3D::new(-1.0, 1.0, 1.0),
        Vec3D::new(-1.0, -1.0, -1.0),
        Vec3D::new(-1.0, -1.0, 1.0),
    ];
    let vertices = points.into_iter().map(|point| point * half_size).collect();
    let fill = ColChar::SOLID.with_rgb(color[0], color[1], color[2]);
    let faces = double_sided_faces(
        &[
            vec![2, 3, 1, 0],
            vec![4, 5, 7, 6],
            vec![1, 3, 7, 5],
            vec![4, 6, 2, 0],
            vec![6, 7, 3, 2],
            vec![0, 1, 5, 4],
        ],
        fill,
    );
    Mesh3D::new(vertices, faces).with_transform(Transform3D::from_translation(position))
}

fn cone_mesh() -> Mesh3D {
    let segments = 16;
    let length = 3.4;
    let radius = (28.0_f64.to_radians()).tan() * length;
    let mut vertices = vec![Vec3D::ZERO];
    for segment in 0..segments {
        let angle = TAU * segment as f64 / segments as f64;
        vertices.push(Vec3D::new(
            radius * angle.cos(),
            -length,
            radius * angle.sin(),
        ));
    }

    let fill = ColChar::SOLID.with_rgb(255, 177, 91);
    let mut faces = Vec::with_capacity(segments * 2);
    for segment in 0..segments {
        let next = (segment + 1) % segments;
        faces.push(Face::new(vec![0, segment + 1, next + 1], fill));
        faces.push(Face::new(vec![next + 1, segment + 1, 0], fill));
    }
    Mesh3D::new(vertices, faces)
}

fn double_sided_faces(windings: &[Vec<usize>], fill: ColChar) -> Vec<Face> {
    let mut faces = Vec::with_capacity(windings.len() * 2);
    for winding in windings {
        faces.push(Face::new(winding.clone(), fill));
        faces.push(Face::new(winding.iter().rev().copied().collect(), fill));
    }
    faces
}
