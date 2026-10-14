use std::collections::HashSet;
use std::io::IsTerminal;
use std::time::{Duration, Instant};

use xre::core::math::{Quat, UVec2, Vec3};
use xre::core::{CellBuffer, Color, Style, Transform};
use xre::render::{
    builtin_cell_shaders, draw_mesh, Camera, Cull, Light, LightRig, Material, Mesh, Projection,
    SampleBuffer, ShadeMode,
};
use xre::scene::{FpsController, OrbitController};
use xre::term::{
    Capabilities, Event, EventQueue, KeyCode, KeyState, Modifiers, MouseButton, MouseEvent,
    MouseKind, Presenter, TerminalGuard,
};
use xre::tui::{BorderSet, Constraint, Frame, Layout, Panel, Text, Viewport3D, Widget};

struct RoomSurface {
    mesh: Mesh,
    transform: Transform,
    material: Material,
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum Menu {
    Scene,
    Camera,
    System,
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum CameraView {
    Orbit,
    Flight,
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum CameraDrag {
    Orbit,
    Zoom,
    Pan,
    Fly,
}

fn main() -> std::io::Result<()> {
    if !std::io::stdin().is_terminal() || !std::io::stdout().is_terminal() {
        eprintln!("L'esempio xRenderEngine richiede un terminale interattivo.");
        std::process::exit(1);
    }

    let _guard = TerminalGuard::enter().map_err(std::io::Error::other)?;
    let keyboard_enhanced = _guard.keyboard_enhanced();
    let caps = Capabilities::probe();
    let mut presenter = Presenter::stdout(&caps);
    let mut cells = CellBuffer::new(caps.size);
    let mut events = EventQueue::new();
    let shaders = builtin_cell_shaders();
    let mut samples = SampleBuffer::new(UVec2::new(1, 1), 2, 4);

    let room = room_surfaces();
    let bulb = Mesh::uv_sphere(0.115, 8, 12);
    let colored_bulbs = [
        (
            Vec3::new(-2.2, 1.67, -2.45),
            Vec3::new(115.0 / 255.0, 181.0 / 255.0, 1.0),
        ),
        (
            Vec3::new(2.2, 1.67, -2.45),
            Vec3::new(1.0, 122.0 / 255.0, 194.0 / 255.0),
        ),
        (
            Vec3::new(-2.2, 1.67, 2.45),
            Vec3::new(122.0 / 255.0, 1.0, 199.0 / 255.0),
        ),
    ];

    // The engine exposes point and directional lights. The warm source stays
    // below the fixed lamp and sweeps along X to suggest Arcade's moving beam.
    let mut rig = LightRig::ambient_only(Vec3::splat(0.18));
    rig.lights.push(point_light(
        Vec3::new(0.0, 1.5, 0.0),
        Vec3::new(1.0, 177.0 / 255.0, 91.0 / 255.0),
        4.0,
    ));
    for (position, color) in [
        (
            Vec3::new(-2.2, 1.5, -2.45),
            Vec3::new(115.0 / 255.0, 181.0 / 255.0, 1.0),
        ),
        (
            Vec3::new(2.2, 1.5, -2.45),
            Vec3::new(1.0, 122.0 / 255.0, 194.0 / 255.0),
        ),
        (
            Vec3::new(-2.2, 1.5, 2.45),
            Vec3::new(122.0 / 255.0, 1.0, 199.0 / 255.0),
        ),
    ] {
        rig.lights.push(point_light(position, color, 2.8));
    }

    let camera_target = Vec3::new(0.0, -0.35, 0.0);
    let initial_eye = Vec3::new(4.5, 2.85, 6.5);
    let initial_offset = initial_eye - camera_target;
    let mut orbit = OrbitController::new(camera_target, initial_offset.length());
    orbit.yaw = initial_offset.x.atan2(initial_offset.z);
    orbit.pitch = (initial_offset.y / initial_offset.length()).asin();
    settle_orbit(&mut orbit);

    let initial_forward = (camera_target - initial_eye).normalize();
    let mut flight = FpsController::new(initial_eye);
    flight.yaw = initial_forward.x.atan2(initial_forward.z);
    flight.pitch = initial_forward.y.asin();
    let mut camera =
        Camera::look_at(initial_eye, camera_target).with_projection(Projection::Perspective {
            fov_y: 48.0_f32.to_radians(),
            near: 0.1,
            far: 40.0,
        });

    let start = Instant::now();
    let mut last_frame = Instant::now();
    let mut target_fps = 6_u32;
    let mut menu = Menu::Scene;
    let mut camera_view = CameraView::Orbit;
    let mut camera_drag = None;
    let mut last_mouse_position = None;
    let mut fly_button_down = false;
    let mut held_fly_keys = HashSet::new();
    let mut last_fallback_movement = Instant::now();
    let mut running = true;

    while running {
        let frame_period = Duration::from_secs_f32(1.0 / target_fps as f32);
        let until_frame = frame_period.saturating_sub(last_frame.elapsed());
        events
            .pump(until_frame.min(Duration::from_millis(16)))
            .map_err(std::io::Error::other)?;

        for event in events.drain() {
            match event {
                Event::Resize(size) => {
                    cells.resize(size);
                    presenter.resize(size);
                }
                Event::Key(key) => {
                    if key.state == KeyState::Release {
                        held_fly_keys.remove(&key.code);
                        continue;
                    }

                    match menu {
                        Menu::Scene => match key.code {
                            KeyCode::Char('c') => menu = Menu::Camera,
                            KeyCode::Char('d') => menu = Menu::System,
                            KeyCode::Char('q') | KeyCode::Esc => running = false,
                            _ => {}
                        },
                        Menu::Camera => match key.code {
                            KeyCode::Char('c') | KeyCode::Esc => {
                                menu = Menu::Scene;
                                camera_drag = None;
                                last_mouse_position = None;
                                fly_button_down = false;
                                held_fly_keys.clear();
                            }
                            code if fly_button_down && is_fly_key(code) => {
                                if keyboard_enhanced {
                                    held_fly_keys.insert(code);
                                } else {
                                    let movement_at = Instant::now();
                                    let step_dt = movement_at
                                        .duration_since(last_fallback_movement)
                                        .as_secs_f32()
                                        .clamp(1.0 / 60.0, 0.1);
                                    last_fallback_movement = movement_at;
                                    let (right, up, forward) = fly_direction(code);
                                    flight.move_local(right, up, forward, step_dt);
                                }
                            }
                            _ => {}
                        },
                        Menu::System => match key.code {
                            KeyCode::Char('c') => menu = Menu::Camera,
                            KeyCode::Char('d') | KeyCode::Esc => menu = Menu::Scene,
                            KeyCode::Char('[') | KeyCode::Char('-') => {
                                target_fps = target_fps.saturating_sub(1).max(1);
                            }
                            KeyCode::Char(']') | KeyCode::Char('=') | KeyCode::Char('+') => {
                                target_fps = (target_fps + 1).min(30);
                            }
                            _ => {}
                        },
                    }
                }
                Event::Mouse(mouse) if menu == Menu::Camera => {
                    handle_camera_mouse(
                        &mouse,
                        &mut orbit,
                        &mut flight,
                        &mut camera_view,
                        &mut camera_drag,
                        &mut last_mouse_position,
                        &mut fly_button_down,
                        &mut held_fly_keys,
                    );
                }
                _ => {}
            }
        }
        if !running {
            break;
        }

        let now = Instant::now();
        if now.duration_since(last_frame) < Duration::from_secs_f32(1.0 / target_fps as f32) {
            continue;
        }
        let dt = now.duration_since(last_frame).as_secs_f32().max(0.001);
        last_frame = now;
        let elapsed = start.elapsed().as_secs_f32();

        // Enhanced terminals report releases for smooth per-frame movement.
        // Other terminals use their repeat events as small movement steps.
        if keyboard_enhanced
            && menu == Menu::Camera
            && fly_button_down
            && camera_view == CameraView::Flight
        {
            let held = |code: KeyCode| -> f32 {
                if held_fly_keys.contains(&code) {
                    1.0
                } else {
                    0.0
                }
            };
            let axis = |positive, negative| held(positive) - held(negative);
            let mut right = axis(KeyCode::Char('d'), KeyCode::Char('a'));
            let mut up = axis(KeyCode::Char(' '), KeyCode::Char('x'));
            let mut forward = axis(KeyCode::Char('w'), KeyCode::Char('s'));
            let magnitude = (right * right + up * up + forward * forward).sqrt();
            if magnitude > 1.0 {
                right /= magnitude;
                up /= magnitude;
                forward /= magnitude;
            }
            flight.move_local(right, up, forward, dt);
        }
        match camera_view {
            CameraView::Orbit => {
                orbit.update(dt);
                orbit.apply(&mut camera);
            }
            CameraView::Flight => flight.apply(&mut camera),
        }

        let beam_sweep_x = (elapsed * 1.15).sin() * 1.5;
        rig.lights[0] = point_light(
            Vec3::new(beam_sweep_x, 1.5, 0.0),
            Vec3::new(1.0, 177.0 / 255.0, 91.0 / 255.0),
            4.0,
        );

        if cells.size() != presenter.size() {
            cells.resize(presenter.size());
        }
        cells.fill(Style::DEFAULT.with_bg(Color::Rgb(8, 10, 16)).cell(' '));

        let columns =
            Layout::horizontal([Constraint::Fill(1), Constraint::Len(28)]).split(cells.area());
        let viewport_panel = Panel::new()
            .border(Some(BorderSet::ROUNDED))
            .border_style(Style::fg(Color::Rgb(90, 110, 140)))
            .title("Stanza xRenderEngine")
            .title_style(Style::fg(Color::Rgb(120, 200, 255)));
        let viewport = viewport_panel.inner(columns[0]);

        samples.resize(
            UVec2::new(viewport.width().max(1), viewport.height().max(1)),
            2,
            4,
        );
        samples.clear([8, 10, 16]);
        let view_projection = camera.view_projection(
            viewport.width().max(1),
            viewport.height().max(1),
            Projection::DEFAULT_CELL_ASPECT,
        );

        for surface in &room {
            draw_mesh(
                &mut samples,
                &surface.mesh,
                surface.transform.to_mat4(),
                view_projection,
                &rig,
                &surface.material,
                ShadeMode::PerSample,
                Cull::None,
            );
        }

        // The amber lamp is fixed at the room center; the moving point light
        // beneath it creates the closest lighting effect supported by XRE.
        draw_bulb(
            &mut samples,
            &bulb,
            Vec3::new(0.0, 1.67, 0.0),
            Vec3::new(1.0, 208.0 / 255.0, 124.0 / 255.0),
            view_projection,
            &rig,
        );
        for (position, color) in colored_bulbs {
            draw_bulb(&mut samples, &bulb, position, color, view_projection, &rig);
        }

        {
            let mut frame = Frame::root(&mut cells);
            viewport_panel.render(columns[0], &mut frame);
            Viewport3D::new(&samples, shaders[0].1.as_ref()).render(viewport, &mut frame);

            let (panel_title, lines) = match menu {
                Menu::Scene => (
                    "Scena",
                    vec![
                        "Ambiente aperto".to_owned(),
                        "3 luci RGB fisse".to_owned(),
                        "Luce calda in moto".to_owned(),
                        String::new(),
                        "c: controlli camera".to_owned(),
                        "d: impostazioni FPS".to_owned(),
                        "q: esci".to_owned(),
                    ],
                ),
                Menu::Camera => (
                    "Camera",
                    vec![
                        format!(
                            "Vista: {}",
                            if camera_view == CameraView::Orbit {
                                "orbita"
                            } else {
                                "volo"
                            }
                        ),
                        String::new(),
                        "Alt+sinistro: orbita".to_owned(),
                        "Alt+destro: zoom".to_owned(),
                        "Ctrl+Alt+sinistro: pan".to_owned(),
                        "Tieni destro: volo".to_owned(),
                        "Volo: WASD, Space/X".to_owned(),
                        String::new(),
                        "Esc/c: chiudi menu".to_owned(),
                    ],
                ),
                Menu::System => (
                    "Sistema",
                    vec![
                        format!("fps reale  {:>3.0}", 1.0 / dt),
                        format!("fps limite {:>3}", target_fps),
                        String::new(),
                        "[-] / [+]: regola FPS".to_owned(),
                        String::new(),
                        "d / Esc: chiudi menu".to_owned(),
                    ],
                ),
            };
            let info_panel = Panel::new()
                .border(Some(BorderSet::ROUNDED))
                .border_style(Style::fg(Color::Rgb(90, 110, 140)))
                .title(panel_title);
            let info = info_panel.render(columns[1], &mut frame);
            for (row, line) in lines.iter().enumerate() {
                Text::styled(line.clone(), Style::fg(Color::Rgb(180, 190, 200))).render_into(
                    xre::core::Rect::new(info.left(), info.top() + row as u32, info.width(), 1),
                    &mut frame,
                );
            }
        }

        presenter.present(&cells).map_err(std::io::Error::other)?;
    }
    Ok(())
}

fn room_surfaces() -> Vec<RoomSurface> {
    let plane = Mesh::plane(6.8);
    let mut floor_transform = Transform::from_translation(Vec3::new(0.0, -2.0, 0.0));
    floor_transform.scale = Vec3::new(6.0 / 6.8, 1.0, 1.0);

    let mut back_transform = Transform::from_translation(Vec3::new(0.0, 0.0, -3.4));
    back_transform.rotation = Quat::from_rotation_x(std::f32::consts::FRAC_PI_2);
    back_transform.scale = Vec3::new(6.0 / 6.8, 1.0, 4.0 / 6.8);

    let mut left_transform = Transform::from_translation(Vec3::new(-3.0, 0.0, 0.0));
    left_transform.rotation = Quat::from_rotation_z(-std::f32::consts::FRAC_PI_2);
    left_transform.scale = Vec3::new(4.0 / 6.8, 1.0, 6.8 / 6.8);

    let mut right_transform = Transform::from_translation(Vec3::new(3.0, 0.0, 0.0));
    right_transform.rotation = Quat::from_rotation_z(std::f32::consts::FRAC_PI_2);
    right_transform.scale = Vec3::new(4.0 / 6.8, 1.0, 6.8 / 6.8);

    [
        (floor_transform, Vec3::new(0.36, 0.41, 0.53)),
        (back_transform, Vec3::new(0.31, 0.37, 0.49)),
        (left_transform, Vec3::new(0.39, 0.43, 0.54)),
        (right_transform, Vec3::new(0.29, 0.34, 0.45)),
    ]
    .into_iter()
    .map(|(transform, color)| RoomSurface {
        mesh: plane.clone(),
        transform,
        material: Material::colored(color),
    })
    .collect()
}

fn point_light(position: Vec3, color: Vec3, intensity: f32) -> Light {
    Light::Point {
        position,
        color,
        intensity,
        attenuation: (1.0, 0.12, 0.035),
    }
}

fn settle_orbit(orbit: &mut OrbitController) {
    let damping = orbit.damping;
    orbit.damping = 0.0;
    orbit.update(1.0 / 60.0);
    orbit.damping = damping;
}

fn sync_flight_from_orbit(flight: &mut FpsController, orbit: &OrbitController) {
    let eye = orbit.eye();
    let forward = (orbit.target - eye).normalize();
    flight.position = eye;
    flight.yaw = forward.x.atan2(forward.z);
    flight.pitch = forward.y.asin();
}

fn sync_orbit_from_flight(orbit: &mut OrbitController, flight: &FpsController) {
    let offset = flight.position - orbit.target;
    let distance = offset.length().max(0.2);
    let mut next = OrbitController::new(orbit.target, distance);
    next.yaw = offset.x.atan2(offset.z);
    next.pitch = (offset.y / distance).clamp(-1.0, 1.0).asin();
    settle_orbit(&mut next);
    *orbit = next;
}

fn handle_camera_mouse(
    mouse: &MouseEvent,
    orbit: &mut OrbitController,
    flight: &mut FpsController,
    camera_view: &mut CameraView,
    camera_drag: &mut Option<CameraDrag>,
    last_mouse_position: &mut Option<(u32, u32)>,
    fly_button_down: &mut bool,
    held_fly_keys: &mut HashSet<KeyCode>,
) {
    match mouse.kind {
        MouseKind::Down(button) => {
            let ctrl_alt =
                mouse.mods.contains(Modifiers::CTRL) && mouse.mods.contains(Modifiers::ALT);
            let alt = mouse.mods.contains(Modifiers::ALT);
            let drag = match button {
                MouseButton::Left if ctrl_alt => Some(CameraDrag::Pan),
                MouseButton::Left if alt => Some(CameraDrag::Orbit),
                MouseButton::Right if alt => Some(CameraDrag::Zoom),
                MouseButton::Right => Some(CameraDrag::Fly),
                _ => None,
            };
            if let Some(drag) = drag {
                if drag == CameraDrag::Fly {
                    if *camera_view == CameraView::Orbit {
                        sync_flight_from_orbit(flight, orbit);
                    }
                    *camera_view = CameraView::Flight;
                    *fly_button_down = true;
                    held_fly_keys.clear();
                } else if *camera_view == CameraView::Flight {
                    sync_orbit_from_flight(orbit, flight);
                    *camera_view = CameraView::Orbit;
                }
                *camera_drag = Some(drag);
                *last_mouse_position = Some((mouse.col, mouse.row));
            }
        }
        MouseKind::Drag(button) => {
            if let (Some(drag), Some((previous_col, previous_row))) =
                (*camera_drag, *last_mouse_position)
            {
                let dx = mouse.col as f32 - previous_col as f32;
                let dy = mouse.row as f32 - previous_row as f32;
                match (drag, button) {
                    (CameraDrag::Orbit, MouseButton::Left) => {
                        orbit.rotate(dx * 0.025, -dy * 0.025);
                    }
                    (CameraDrag::Zoom, MouseButton::Right) => {
                        orbit.zoom((dy * 0.04).exp());
                    }
                    (CameraDrag::Pan, MouseButton::Left) => {
                        let scale = orbit.distance * 0.025;
                        orbit.pan(-dx * scale, dy * scale);
                    }
                    (CameraDrag::Fly, MouseButton::Right) if *fly_button_down => {
                        flight.look(dx * 0.012, -dy * 0.012);
                    }
                    _ => {}
                }
                *last_mouse_position = Some((mouse.col, mouse.row));
            }
        }
        MouseKind::Up(button) => {
            if button == MouseButton::Right && *camera_drag == Some(CameraDrag::Fly) {
                *fly_button_down = false;
                held_fly_keys.clear();
            }
            *camera_drag = None;
            *last_mouse_position = None;
        }
        _ => {}
    }
}

fn is_fly_key(code: KeyCode) -> bool {
    matches!(code, KeyCode::Char('w' | 'a' | 's' | 'd' | ' ' | 'x'))
}

fn fly_direction(code: KeyCode) -> (f32, f32, f32) {
    match code {
        KeyCode::Char('a') => (-1.0, 0.0, 0.0),
        KeyCode::Char('d') => (1.0, 0.0, 0.0),
        KeyCode::Char(' ') => (0.0, 1.0, 0.0),
        KeyCode::Char('x') => (0.0, -1.0, 0.0),
        KeyCode::Char('w') => (0.0, 0.0, 1.0),
        KeyCode::Char('s') => (0.0, 0.0, -1.0),
        _ => (0.0, 0.0, 0.0),
    }
}

fn draw_bulb(
    samples: &mut SampleBuffer,
    mesh: &Mesh,
    position: Vec3,
    color: Vec3,
    view_projection: xre::core::math::Mat4,
    rig: &LightRig,
) {
    let transform = Transform::from_translation(position);
    draw_mesh(
        samples,
        mesh,
        transform.to_mat4(),
        view_projection,
        rig,
        &Material::colored(color).unlit(),
        ShadeMode::PerSample,
        Cull::Back,
    );
}
