// ============================================================
// PANIC INC. v3 - obj_panic - CREATE
// ============================================================
game_set_speed(60, gamespeed_fps);
randomize();

// ---------- RECORDE SALVO ----------
ini_open("panic_save.ini");
best_pontos = ini_read_real("save", "best", 0);
best_level  = ini_read_real("save", "level", 1);
ini_close();

// ---------- TELA E CAMERAS ----------
gw = 1280; gh = 720;
vw = 800;  vh = 450;
surface_resize(application_surface, gw, gh);
display_set_gui_size(gw, gh);
window_set_size(gw, gh);
window_center();

view_enabled = true;
view_visible[0] = true;
view_wport[0] = gw;
view_hport[0] = gh;
cam2d = camera_create_view(0, 0, vw, vh);
view_camera[0] = cam2d;
cam3d = camera_create();

// ---------- ESTADOS ----------
STATE_TITLE = 0; STATE_PLAYING = 1; STATE_PAUSED = 2; STATE_GAMEOVER = 3; STATE_LEVELDONE = 4;
state = STATE_TITLE;
mode  = 0;               // 0 = 2D, 1 = 3D (TAB)

// ---------- CONFIGURACOES ----------
tile = 32; cols = 52; rows = 36;
wall_h = 64; eye_h = 36; fov = 72;
mouse_sens = 0.15; mouse_sens_y = 0.12; turn_speed = 2.8;
camera_pitch = 0;
flash_len = 200; flash_angle = 28; ambient_r = 70; ambient_cur = 70;
ndx  = [1, -1, 0, 0];
ndy  = [0, 0, 1, -1];
ndx8 = [1, -1, 0, 0, 1, 1, -1, -1];
ndy8 = [0, 0, 1, -1, 1, -1, 1, -1];
item_names = ["DOCUMENTO CONFIDENCIAL", "KIT MEDICO", "BATERIA"];
structure_names = ["ARQUIVO", "ENFERMARIA", "SUBESTACAO", "ABRIGO" ];

// ---------- MELHORIAS (upgrades entre fases) ----------
speed_mult = 1; stam_mult = 1; batt_mult = 1; hear_mult = 1; extra_pickups = 0;
upg_defs = [
    { name : "PERNAS LEVES",       desc : "+12% de velocidade" },
    { name : "PULMOES DE ACO",     desc : "A stamina dura 40% mais" },
    { name : "LANTERNA POTENTE",   desc : "Mais alcance e cone de luz maior" },
    { name : "BATERIA ECONOMICA",  desc : "A bateria dura 40% mais" },
    { name : "CORACAO DE FERRO",   desc : "+25 de vida maxima e cura total" },
    { name : "PASSOS FELINOS",     desc : "Monstros te ouvem de menos longe" },
    { name : "SORTE DE LADRAO",    desc : "+1 kit medico e +1 bateria por fase" }
];
upg_choice = [0, 1, 2];

// ---------- VARIAVEIS DE JOGO ----------
pontos = 0; level = 1;
battery = 100; flash_on = true; flash_power = 1;
panic = 0; shake = 0; hurt_flash = 0; heart_pulse = 0;
msg = ""; msg_timer = 0;
level_time = 0; last_bonus = 0;
nearby_item = -1;
cam_x = 0; cam_y = 0;
fade = 1;
combo = 0; combo_timer = 0;
blackout = 0; blackout_cd = 2400;
flare_charges = 2; flare_pulse = 0; flare_x = 0; flare_y = 0;
alert_cd = 0; heart_cd = 0; step_sign = false; drip_cd = 300; creak_cd = 900;
particles = []; enemies = []; items = []; rooms = [];
lamps = []; decals = []; floaters = []; dust = [];
vb_world = -1;
docs_total = 1; docs_got = 0;
exit_c = 0; exit_r = 0; exit_open = false; alarm_on = false;
spawn_timer = 0; spawn_interval = 1000; max_enemies = 6;
sfx_on = true;

// olhos decorativos da tela de titulo
title_eyes = [];
repeat (14) array_push(title_eyes, { x : random(gw), y : random(gh), ph : random(360), s : random_range(0.6, 1.6) });

// ---------- PLAYER ----------
player = {
    // [MULTIPLAYER FUTURO]
    player_id : 0, is_local : true, sync_x : 0, sync_y : 0, sync_dir : 0,

    x : 100, y : 100,
    hitbox : 9, radius : 10,
    walk_speed : 1.5, run_speed : 2.7,
    is_running : false, is_moving : false,
    facing_dir : 0,
    hp : 100, hp_max : 100,
    stamina : 100, stamina_max : 100, exhausted : false,
    rank : 1, xp : 0, xp_next : 5,
    hurt_cd : 0,
    bob : 0
};

// ============================================================
// FUNCOES UTEIS
// ============================================================
shade = function(_c, _k) {
    return make_color_rgb(
        clamp(round(color_get_red(_c)   * _k), 0, 255),
        clamp(round(color_get_green(_c) * _k), 0, 255),
        clamp(round(color_get_blue(_c)  * _k), 0, 255));
};

fillrect = function(_x1, _y1, _x2, _y2) {
    draw_primitive_begin(pr_trianglestrip);
    draw_vertex(_x1, _y1); draw_vertex(_x2, _y1);
    draw_vertex(_x1, _y2); draw_vertex(_x2, _y2);
    draw_primitive_end();
};

gtext = function(_x, _y, _str, _sc, _col) {
    draw_set_alpha(1);
    draw_set_color(c_black);
    draw_text_transformed(_x + 2, _y + 2, _str, _sc, _sc, 0);
    draw_set_color(_col);
    draw_text_transformed(_x, _y, _str, _sc, _sc, 0);
};

solid_at = function(_x, _y) {
    var _c = floor(_x / tile);
    var _r = floor(_y / tile);
    if (_c < 0 || _r < 0 || _c >= cols || _r >= rows) return true;
    return grid[_c][_r] == 1;
};

box_hits = function(_x, _y, _h) {
    return solid_at(_x - _h, _y - _h) || solid_at(_x + _h - 0.01, _y - _h)
        || solid_at(_x - _h, _y + _h - 0.01) || solid_at(_x + _h - 0.01, _y + _h - 0.01);
};

move_body = function(_o, _dx, _dy, _h) {
    var _sx = sign(_dx);
    var _left = abs(_dx);
    while (_left > 0) {
        var _st = min(1, _left);
        if (!box_hits(_o.x + _sx * _st, _o.y, _h)) _o.x += _sx * _st; else break;
        _left -= _st;
    }
    var _sy = sign(_dy);
    _left = abs(_dy);
    while (_left > 0) {
        var _st2 = min(1, _left);
        if (!box_hits(_o.x, _o.y + _sy * _st2, _h)) _o.y += _sy * _st2; else break;
        _left -= _st2;
    }
};

los = function(_x1, _y1, _x2, _y2) {
    var _d = point_distance(_x1, _y1, _x2, _y2);
    var _n = ceil(_d / 10);
    for (var i = 1; i < _n; i++) {
        var _t = i / _n;
        if (solid_at(lerp(_x1, _x2, _t), lerp(_y1, _y2, _t))) return false;
    }
    return true;
};

// Comprimento de um raio ate bater na parede (usado no feixe da lanterna)
ray_len = function(_x, _y, _dir, _max) {
    var _l = 0;
    while (_l < _max) {
        if (solid_at(_x + lengthdir_x(_l, _dir), _y + lengthdir_y(_l, _dir))) break;
        _l += 6;
    }
    return _l;
};

// Brilho (0..1) de um ponto: ambiente + lanterna + lampadas
light_at = function(_x, _y) {
    var _d = point_distance(_x, _y, player.x, player.y);
    var _b = clamp(1 - _d / ambient_cur, 0, 1);
    _b = _b * _b * 0.9;
    if (flash_on && _d < flash_len) {
        var _ad = abs(angle_difference(player.facing_dir, point_direction(player.x, player.y, _x, _y)));
        if (_ad < flash_angle) {
            var _f = 1 - _d / flash_len;
            var _edge = min(1, (1 - _ad / flash_angle) * 2.2);
            _b = max(_b, _f * _edge * flash_power);
        }
    }
    for (var k = 0; k < array_length(lamps); k++) {
        var _l = lamps[k];
        if (abs(_x - _l.x) < 120 && abs(_y - _l.y) < 120) {
            var _ld = point_distance(_x, _y, _l.x, _l.y);
            if (_ld < 120) {
                var _q = 1 - _ld / 120;
                _b = max(_b, _q * _q * 0.8 * _l.on);
            }
        }
    }
    return clamp(_b, 0, 1);
};

show_msg = function(_t, _frames) {
    msg = _t;
    msg_timer = _frames;
};

add_floater = function(_x, _y, _txt, _col) {
    array_push(floaters, { x : _x, y : _y, txt : _txt, col : _col, life : 70 });
};

add_particles = function(_x, _y, _n, _col, _sp) {
    repeat (_n) {
        var _d = random(360);
        var _s = random_range(0.3, 1) * _sp;
        var _l = irandom_range(20, 45);
        array_push(particles, {
            x : _x, y : _y,
            vx : lengthdir_x(_s, _d), vy : lengthdir_y(_s, _d),
            life : _l, maxlife : _l,
            col : _col, size : random_range(1.5, 3.5)
        });
    }
};

// ============================================================
// SONS SINTETIZADOS (sem arquivos!)
// ============================================================
make_snd = function(_dur, _fn) {
    var _rate = 22050;
    var _n = floor(_dur * _rate);
    var _b = buffer_create(_n * 2, buffer_fixed, 2);
    for (var i = 0; i < _n; i++) {
        var _s = _fn(i / _rate, _dur);
        buffer_write(_b, buffer_s16, round(clamp(_s, -1, 1) * 30000));
    }
    return audio_create_buffer_sound(_b, buffer_s16, _rate, 0, _n * 2, audio_mono);
};

play_snd = function(_s, _gain, _pitch) {
    var _i = audio_play_sound(_s, 5, false);
    audio_sound_gain(_i, _gain, 0);
    audio_sound_pitch(_i, _pitch);
    return _i;
};

snd_step = make_snd(0.12, function(_t, _d) {
    return ((random(2) - 1) * 0.35 + sin(2 * pi * 70 * _t) * 0.6) * exp(-_t * 45);
});
snd_pick = make_snd(0.35, function(_t, _d) {
    var _f = (_t < 0.1) ? 660 : ((_t < 0.2) ? 880 : 1320);
    return sin(2 * pi * _f * _t) * 0.5 * exp(-(_t mod 0.1) * 14);
});
snd_hurt = make_snd(0.4, function(_t, _d) {
    var _f = 140 - _t * 180;
    var _saw = ((_t * _f) mod 1) * 2 - 1;
    return (_saw * 0.5 + (random(2) - 1) * 0.4) * exp(-_t * 7);
});
snd_click = make_snd(0.05, function(_t, _d) {
    return (random(2) - 1) * exp(-_t * 120) * 0.7;
});
snd_heart = make_snd(0.45, function(_t, _d) {
    var _a = sin(2 * pi * 52 * _t) * exp(-_t * 16);
    var _t2 = _t - 0.17;
    var _b = (_t2 > 0) ? sin(2 * pi * 46 * _t2) * exp(-_t2 * 18) * 0.7 : 0;
    return (_a + _b) * 0.9;
});
snd_alarm = make_snd(1.0, function(_t, _d) {
    var _f = ((floor(_t * 4) mod 2) == 0) ? 620 : 840;
    return ((sin(2 * pi * _f * _t) > 0) ? 1 : -1) * 0.22;
});
snd_drone = make_snd(4, function(_t, _d) {
    var _w = 2 * pi;
    var _l = 0.6 + 0.4 * sin(_w * 0.25 * _t);
    return sin(_w * 55 * _t) * 0.35 + sin(_w * 55.5 * _t) * 0.35
         + sin(_w * 82.25 * _t) * 0.15 * _l + sin(_w * 110.5 * _t) * 0.06 * _l;
});
snd_growl = make_snd(0.9, function(_t, _d) {
    var _env = sin(pi * _t / _d);
    var _f = 60 + 20 * sin(2 * pi * 7 * _t);
    var _saw = ((_t * _f) mod 1) * 2 - 1;
    return (_saw * 0.5 + (random(2) - 1) * 0.3 * (0.5 + 0.5 * sin(2 * pi * 30 * _t))) * _env * 0.9;
});
snd_scare = make_snd(0.8, function(_t, _d) {
    var _f = 900 + 700 * _t / _d;
    var _s = sin(2 * pi * _f * _t) * 0.3 + sin(2 * pi * _f * 1.41 * _t) * 0.25 + (random(2) - 1) * 0.35;
    return _s * exp(-_t * 3.5);
});
snd_win = make_snd(1.0, function(_t, _d) {
    var _n = min(floor(_t / 0.15), 5);
    var _f = 523;
    if (_n == 1) _f = 659; else if (_n == 2) _f = 784; else if (_n == 3) _f = 1047;
    else if (_n == 4) _f = 1319; else if (_n == 5) _f = 1568;
    return sin(2 * pi * _f * _t) * 0.4 * exp(-(_t mod 0.15) * 6);
});
snd_beep = make_snd(0.18, function(_t, _d) {
    return sin(2 * pi * 900 * _t) * 0.4 * exp(-_t * 10);
});
snd_drip = make_snd(0.35, function(_t, _d) {
    var _f = 1800 - 2200 * _t;
    return sin(2 * pi * _f * _t) * 0.35 * exp(-_t * 14);
});
snd_creak = make_snd(1.0, function(_t, _d) {
    var _f = 180 + 120 * sin(2 * pi * 3 * _t) + 60 * _t;
    return (sin(2 * pi * _f * _t) * 0.25 + (random(2) - 1) * 0.12) * sin(pi * _t / _d);
});
snd_blackout = make_snd(0.6, function(_t, _d) {
    return (sin(2 * pi * (200 - 300 * _t) * _t) * 0.5 + (random(2) - 1) * 0.3) * exp(-_t * 5);
});

audio_master_gain(0.9);
drone_inst = audio_play_sound(snd_drone, 1, true);
audio_sound_gain(drone_inst, 0.3, 0);

hurt_player = function(_dmg) {
    if (player.hurt_cd > 0) return;
    player.hp = max(0, player.hp - _dmg);
    player.hurt_cd = 68;
    shake = 10;
    hurt_flash = 1;
    combo = 0;
    combo_timer = 0;
    add_particles(player.x, player.y, 14, c_red, 2.5);
    play_snd(snd_hurt, 0.8, random_range(0.9, 1.1));
    array_push(decals, { x : player.x + random_range(-10, 10), y : player.y + random_range(-10, 10), r : random_range(3, 8) });
    if (array_length(decals) > 40) array_delete(decals, 0, 1);
};

// ============================================================
// GERACAO DO MAPA
// ============================================================
carve_rect = function(_c1, _r1, _c2, _r2) {
    for (var i = max(1, _c1); i <= min(cols - 2, _c2); i++) {
        for (var j = max(1, _r1); j <= min(rows - 2, _r2); j++) {
            grid[i][j] = 0;
        }
    }
};

connect_rooms = function(_a, _b) {
    var _ax = _a.x + _a.w div 2;
    var _ay = _a.y + _a.h div 2;
    var _bx = _b.x + _b.w div 2;
    var _by = _b.y + _b.h div 2;
    carve_rect(min(_ax, _bx), _ay, max(_ax, _bx), _ay + 1);
    carve_rect(_bx, min(_ay, _by), _bx + 1, max(_ay, _by));
};

random_floor = function(_fx, _fy, _mind) {
    for (var t = 0; t < 400; t++) {
        var _c = irandom_range(1, cols - 2);
        var _r = irandom_range(1, rows - 2);
        if (grid[_c][_r] == 0) {
            var _px = _c * tile + tile / 2;
            var _py = _r * tile + tile / 2;
            if (point_distance(_px, _py, _fx, _fy) >= _mind * (1 - t / 400)) {
                return { x : _px, y : _py };
            }
        }
    }
    return { x : _fx, y : _fy };
};

// Tipos: 0 = normal, 1 = corredor (rapido), 2 = perseguidor (congela na luz)
spawn_enemy = function(_mind) {
    var _p = random_floor(player.x, player.y, _mind);
    var _zone_danger = 0.15;
    var _zone_dist = 1000000;
    for (var k = 0; k < array_length(rooms); k++) {
        var _room = rooms[k];
        var _rd = point_distance(_p.x, _p.y, (_room.x + _room.w * 0.5) * tile, (_room.y + _room.h * 0.5) * tile);
        if (_rd < _zone_dist) { _zone_dist = _rd; _zone_danger = _room.danger; }
    }
    var _threat = clamp(level + floor(_zone_danger * 3), 1, 24);
    var _r = random(1);
    var _type = 0;
    if (_threat >= 2 && _r < min(0.48, 0.16 + _zone_danger * 0.30 + max(0, level - 3) * 0.018)) _type = 1;
    else if (_threat >= 3 && _r > max(0.52, 0.84 - _zone_danger * 0.24 - max(0, level - 4) * 0.015)) _type = 2;
    var _spd = min(2.2, 0.72 + _threat * 0.065 + _zone_danger * 0.15) + random_range(-0.06, 0.06);
    if (_type == 1) _spd *= 1.32;
    if (_type == 2) _spd *= 1.14;
    array_push(enemies, {
        x : _p.x, y : _p.y, spd : _spd, type : _type, danger : _zone_danger,
        face : random(360), anim : random(360), lit : false,
        mode : 0, wdir : random(360), wt : irandom_range(30, 90), lost : 0, stun : 0
    });
};

update_visibility = function() {
    for (var i = 0; i < cols; i++) {
        for (var j = 0; j < rows; j++) vis[i][j] = 0;
    }
    var _pc = floor(player.x / tile);
    var _pr = floor(player.y / tile);
    var _R = 9;
    var _c0 = max(0, _pc - _R); var _c1 = min(cols - 1, _pc + _R);
    var _r0 = max(0, _pr - _R); var _r1 = min(rows - 1, _pr + _R);
    for (var c = _c0; c <= _c1; c++) {
        for (var r = _r0; r <= _r1; r++) {
            if (grid[c][r] == 0 && los(player.x, player.y, c * tile + tile / 2, r * tile + tile / 2)) vis[c][r] = 1;
        }
    }
    for (var c = _c0; c <= _c1; c++) {
        for (var r = _r0; r <= _r1; r++) {
            if (grid[c][r] == 1) {
                for (var k = 0; k < 8; k++) {
                    var _nc = c + ndx8[k];
                    var _nr = r + ndy8[k];
                    if (_nc >= 0 && _nr >= 0 && _nc < cols && _nr < rows) {
                        if (grid[_nc][_nr] == 0 && vis[_nc][_nr] == 1) { vis[c][r] = 1; break; }
                    }
                }
            }
        }
    }
    for (var c = _c0; c <= _c1; c++) {
        for (var r = _r0; r <= _r1; r++) {
            if (vis[c][r] == 1) explored[c][r] = 1;
        }
    }
};

update_flow = function() {
    for (var i = 0; i < cols; i++) {
        for (var j = 0; j < rows; j++) flow[i][j] = -1;
    }
    var _pc = floor(player.x / tile);
    var _pr = floor(player.y / tile);
    if (_pc < 0 || _pr < 0 || _pc >= cols || _pr >= rows) return;
    if (grid[_pc][_pr] == 1) return;
    var _head = 0;
    var _tail = 0;
    flow[_pc][_pr] = 0;
    flow_q[_tail] = _pc + _pr * cols;
    _tail++;
    while (_head < _tail) {
        var _cur = flow_q[_head];
        _head++;
        var _cc = _cur mod cols;
        var _cr = _cur div cols;
        var _d = flow[_cc][_cr];
        for (var k = 0; k < 4; k++) {
            var _nc = _cc + ndx[k];
            var _nr = _cr + ndy[k];
            if (_nc < 0 || _nr < 0 || _nc >= cols || _nr >= rows) continue;
            if (grid[_nc][_nr] == 1 || flow[_nc][_nr] != -1) continue;
            flow[_nc][_nr] = _d + 1;
            flow_q[_tail] = _nc + _nr * cols;
            _tail++;
        }
    }
};

// ============================================================
// GEOMETRIA 3D
// ============================================================
vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_color();
vf = vertex_format_end();

vv = function(_vb, _x, _y, _z, _c) {
    vertex_position_3d(_vb, _x, _y, _z);
    vertex_color(_vb, _c, 1);
};

vquad = function(_vb, _x1, _y1, _z1, _x2, _y2, _z2, _x3, _y3, _z3, _x4, _y4, _z4, _c) {
    vv(_vb, _x1, _y1, _z1, _c); vv(_vb, _x2, _y2, _z2, _c); vv(_vb, _x3, _y3, _z3, _c);
    vv(_vb, _x1, _y1, _z1, _c); vv(_vb, _x3, _y3, _z3, _c); vv(_vb, _x4, _y4, _z4, _c);
};

make_box = function(_c) {
    var _vb = vertex_create_buffer();
    vertex_begin(_vb, vf);
    var _h = 0.5;
    vquad(_vb, -_h,-_h, _h,  _h,-_h, _h,  _h, _h, _h, -_h, _h, _h, shade(_c, 1.0));
    vquad(_vb, -_h,-_h,-_h, -_h, _h,-_h,  _h, _h,-_h,  _h,-_h,-_h, shade(_c, 0.4));
    vquad(_vb,  _h,-_h,-_h,  _h, _h,-_h,  _h, _h, _h,  _h,-_h, _h, shade(_c, 0.8));
    vquad(_vb, -_h,-_h,-_h, -_h,-_h, _h, -_h, _h, _h, -_h, _h,-_h, shade(_c, 0.6));
    vquad(_vb, -_h, _h,-_h, -_h, _h, _h,  _h, _h, _h,  _h, _h,-_h, shade(_c, 0.7));
    vquad(_vb, -_h,-_h,-_h,  _h,-_h,-_h,  _h,-_h, _h, -_h,-_h, _h, shade(_c, 0.9));
    vertex_end(_vb);
    vertex_freeze(_vb);
    return _vb;
};

draw_box3d = function(_vb, _x, _y, _z, _sx, _sy, _sz, _rz) {
    matrix_set(matrix_world, matrix_build(_x, _y, _z, 0, 0, _rz, _sx, _sy, _sz));
    vertex_submit(_vb, pr_trianglelist, -1);
    matrix_set(matrix_world, matrix_build_identity());
};

wall_face = function(_ax, _ay, _bx, _by, _k, _theme) {
    var _base = make_color_rgb(120, 125, 150);
    if (_theme == 1) _base = make_color_rgb(105, 145, 125);
    else if (_theme == 2) _base = make_color_rgb(155, 112, 78);
    else if (_theme == 3) _base = make_color_rgb(135, 125, 105);
    var _hh = wall_h;
    vquad(vb_world, _ax,_ay,0,   _bx,_by,0,   _bx,_by,14,      _ax,_ay,14,      shade(_base, _k * 0.55));
    vquad(vb_world, _ax,_ay,14,  _bx,_by,14,  _bx,_by,_hh-6,   _ax,_ay,_hh-6,   shade(_base, _k));
    vquad(vb_world, _ax,_ay,_hh-6, _bx,_by,_hh-6, _bx,_by,_hh, _ax,_ay,_hh,     shade(make_color_rgb(200, 60, 50), _k * 0.8));
    // Painel metalico fino: quebra a repeticao das paredes sem exigir sprites externos.
    var _len = point_distance(_ax, _ay, _bx, _by);
    if (_len > 30) {
        var _mx = (_ax + _bx) * 0.5;
        var _my = (_ay + _by) * 0.5;
        var _dx = (_bx - _ax) / _len;
        var _dy = (_by - _ay) / _len;
        var _px = -_dy * 1.2;
        var _py = _dx * 1.2;
        vquad(vb_world, _mx-_dx*7-_px,_my-_dy*7-_py,20, _mx+_dx*7-_px,_my+_dy*7-_py,20,
              _mx+_dx*7-_px,_my+_dy*7-_py,wall_h-12, _mx-_dx*7-_px,_my-_dy*7-_py,wall_h-12,
              shade(make_color_rgb(125, 135, 150), _k * 0.72));
    }
};

build_3d = function() {
    if (vb_world != -1) vertex_delete_buffer(vb_world);
    vb_world = vertex_create_buffer();
    vertex_begin(vb_world, vf);
    for (var c = 0; c < cols; c++) {
        for (var r = 0; r < rows; r++) {
            var _x1 = c * tile; var _y1 = r * tile;
            var _x2 = _x1 + tile; var _y2 = _y1 + tile;
            var _theme = 0;
            var _room_dist = 1000000;
            for (var q = 0; q < array_length(rooms); q++) {
                var _candidate = rooms[q];
                var _qd = point_distance(c + 0.5, r + 0.5, _candidate.x + _candidate.w * 0.5, _candidate.y + _candidate.h * 0.5);
                if (_qd < _room_dist) { _room_dist = _qd; _theme = _candidate.theme; }
            }
            if (grid[c][r] == 0) {
                var _k = 0.82 + 0.18 * (((c * 7 + r * 13) mod 5) / 4);
                var _chk = (((c + r) mod 2) == 0) ? 1.0 : 0.88;
                var _floor_base = make_color_rgb(95, 100, 112);
                if (_theme == 1) _floor_base = make_color_rgb(82, 112, 96);
                else if (_theme == 2) _floor_base = make_color_rgb(120, 83, 58);
                else if (_theme == 3) _floor_base = make_color_rgb(112, 105, 83);
                var _fc = shade(_floor_base, _k * _chk);
                vquad(vb_world, _x1,_y1,0, _x2,_y1,0, _x2,_y2,0, _x1,_y2,0, _fc);
                // Faixas de piso e grelhas de drenagem para dar escala e leitura ao corredor.
                if (((c * 13 + r * 7) mod 9) == 0) {
                    var _gc = shade(make_color_rgb(55, 62, 72), _k);
                    vquad(vb_world, _x1+5,_y1+7,0.35, _x1+tile-5,_y1+7,0.35, _x1+tile-5,_y1+9,0.35, _x1+5,_y1+9,0.35, _gc);
                    vquad(vb_world, _x1+5,_y1+23,0.35, _x1+tile-5,_y1+23,0.35, _x1+tile-5,_y1+25,0.35, _x1+5,_y1+25,0.35, _gc);
                } else if (((c * 5 + r * 11) mod 17) == 0) {
                    var _stain = shade(make_color_rgb(72, 27, 31), _k * 0.72);
                    vquad(vb_world, _x1+8,_y1+15,0.25, _x1+18,_y1+13,0.25, _x1+22,_y1+18,0.25, _x1+10,_y1+20,0.25, _stain);
                }
                vquad(vb_world, _x1,_y1,wall_h, _x2,_y1,wall_h, _x2,_y2,wall_h, _x1,_y2,wall_h, make_color_rgb(40, 40, 52));
            } else {
                if (r > 0 && grid[c][r - 1] == 0)           wall_face(_x1, _y1, _x2, _y1, 0.95, _theme);
                if (r < rows - 1 && grid[c][r + 1] == 0)    wall_face(_x1, _y2, _x2, _y2, 0.70, _theme);
                if (c > 0 && grid[c - 1][r] == 0)           wall_face(_x1, _y1, _x1, _y2, 0.80, _theme);
                if (c < cols - 1 && grid[c + 1][r] == 0)    wall_face(_x2, _y1, _x2, _y2, 0.60, _theme);
            }
        }
    }
    vertex_end(vb_world);
    vertex_freeze(vb_world);
};

vb_doc   = make_box(make_color_rgb(255, 220, 60));
vb_med   = make_box(make_color_rgb(80, 255, 120));
vb_bat   = make_box(make_color_rgb(80, 220, 255));
vb_lamp  = make_box(make_color_rgb(255, 230, 150));
vb_body  = [make_box(make_color_rgb(120, 20, 25)), make_box(make_color_rgb(100, 40, 140)), make_box(make_color_rgb(200, 200, 215))];
vb_hd    = [make_box(make_color_rgb(190, 50, 50)), make_box(make_color_rgb(160, 80, 210)), make_box(make_color_rgb(240, 240, 250))];
vb_eye   = make_box(make_color_rgb(255, 255, 80));
vb_exit_open = make_box(make_color_rgb(60, 255, 90));
vb_exit_lock = make_box(make_color_rgb(200, 40, 40));

// ============================================================
// FASES
// ============================================================
generate_level = function() {
    audio_stop_sound(snd_alarm);

    // Cada contrato abre um complexo maior, com mais salas e mais rotas.
    cols = min(128, 96 + max(0, level - 1) * 5);
    rows = min(90, 68 + max(0, level - 1) * 4);

    grid = array_create(cols);
    explored = array_create(cols);
    vis = array_create(cols);
    flow = array_create(cols);
    for (var i = 0; i < cols; i++) {
        grid[i] = array_create(rows, 1);
        explored[i] = array_create(rows, 0);
        vis[i] = array_create(rows, 0);
        flow[i] = array_create(rows, -1);
    }
    flow_q = array_create(cols * rows, 0);

    // --- salas ---
    rooms = [];
    var _tries = 0;
    var _room_target = min(24, 12 + floor(max(0, level - 1) * 0.8));
    while (array_length(rooms) < _room_target && _tries < 1800) {
        _tries++;
        var _w = irandom_range(8, 15);
        var _h = irandom_range(6, 11);
        var _cx = irandom_range(2, cols - _w - 3);
        var _cy = irandom_range(2, rows - _h - 3);
        var _ok = true;
        for (var k = 0; k < array_length(rooms); k++) {
            var _o = rooms[k];
            if (_cx < _o.x + _o.w + 2 && _cx + _w + 2 > _o.x && _cy < _o.y + _o.h + 2 && _cy + _h + 2 > _o.y) {
                _ok = false;
                break;
            }
        }
        if (_ok) array_push(rooms, { x : _cx, y : _cy, w : _w, h : _h, theme : irandom(3), danger : 0.2, kind : 0 });
    }
    for (var k = 0; k < array_length(rooms); k++) {
        var _rm = rooms[k];
        carve_rect(_rm.x, _rm.y, _rm.x + _rm.w - 1, _rm.y + _rm.h - 1);
    }
    for (var k = 1; k < array_length(rooms); k++) connect_rooms(rooms[k - 1], rooms[k]);
    repeat (3) connect_rooms(rooms[irandom(array_length(rooms) - 1)], rooms[irandom(array_length(rooms) - 1)]);

    // Cada estrutura recebe identidade e risco proprios; alas distantes tendem a ser mais perigosas.
    var _origin = rooms[0];
    var _world_diag = max(1, point_distance(0, 0, cols, rows));
    for (var k = 0; k < array_length(rooms); k++) {
        var _z = rooms[k];
        var _dist = point_distance(_origin.x + _origin.w * 0.5, _origin.y + _origin.h * 0.5, _z.x + _z.w * 0.5, _z.y + _z.h * 0.5);
        _z.kind = irandom(3);
        _z.theme = _z.kind;
        _z.danger = clamp(0.12 + (_dist / _world_diag) * 1.05 + random_range(-0.12, 0.2) + max(0, level - 1) * 0.012, 0.08, 1);
        rooms[k] = _z;
    }

    // --- pilares nas salas (cobertura e variedade) ---
    for (var k = 1; k < array_length(rooms); k++) {
        var _rp = rooms[k];
        if (random(1) < 0.7) grid[_rp.x + 1][_rp.y + _rp.h - 2] = 1;
        if (random(1) < 0.7) grid[_rp.x + _rp.w - 2][_rp.y + 1] = 1;
    }

    // --- lampadas nos cantos das salas ---
    lamps = [];
    for (var k = 0; k < array_length(rooms); k++) {
        var _rl = rooms[k];
        array_push(lamps, {
            x : _rl.x * tile + tile / 2, y : _rl.y * tile + tile / 2,
            on : 1, broken : (random(1) < 0.35)
        });
    }

    // --- spawn do player na sala 0 ---
    var _s = rooms[0];
    player.x = (_s.x + _s.w div 2) * tile + tile / 2;
    player.y = (_s.y + _s.h div 2) * tile + tile / 2;
    player.facing_dir = 0;
    camera_pitch = 0;
    player.hurt_cd = 0;
    player.bob = 0;

    // --- saida na sala mais distante ---
    var _best = -1;
    exit_c = _s.x + _s.w div 2;
    exit_r = _s.y + _s.h div 2;
    for (var k = 1; k < array_length(rooms); k++) {
        var _rk = rooms[k];
        var _dd = point_distance(_s.x, _s.y, _rk.x, _rk.y);
        if (_dd > _best) {
            _best = _dd;
            exit_c = _rk.x + _rk.w div 2;
            exit_r = _rk.y + _rk.h div 2;
        }
    }
    exit_open = false;
    alarm_on = false;

    // --- itens ---
    items = [];
    docs_total = min(4 + floor((level - 1) * 0.75), 12);
    docs_got = 0;
    for (var i = 0; i < docs_total; i++) {
        var _p = random_floor(player.x, player.y, 260);
        array_push(items, { x : _p.x, y : _p.y, type : 0, timer : random(360) });
    }
    repeat (2 + extra_pickups) {
        var _p1 = random_floor(player.x, player.y, 120);
        array_push(items, { x : _p1.x, y : _p1.y, type : 1, timer : random(360) });
    }
    repeat (3 + extra_pickups) {
        var _p2 = random_floor(player.x, player.y, 120);
        array_push(items, { x : _p2.x, y : _p2.y, type : 2, timer : random(360) });
    }

    // --- inimigos ---
    enemies = [];
    repeat (min(2 + ceil(level * 0.7), 8)) spawn_enemy(460);
    spawn_timer = 0;
    // A fase 1 permanece intensa; as seguintes escalam mais devagar.
    spawn_interval = max(560, 1650 - max(0, level - 1) * 105);
    max_enemies = min(12, 3 + ceil(level * 0.8));

    // --- poeira ambiente, sangue, textos ---
    dust = [];
    repeat (80) array_push(dust, { x : random(cols * tile), y : random(rows * tile), vx : random_range(-0.15, 0.15), vy : random_range(-0.1, 0.1) });
    decals = [];
    floaters = [];
    particles = [];

    level_time = 0;
    shake = 0; hurt_flash = 0; panic = 0; heart_pulse = 0;
    blackout = 0; blackout_cd = irandom_range(1800, 3000);
    combo = 0; combo_timer = 0;
    flare_charges = 2; flare_pulse = 0;
    fade = 1;
    cam_x = clamp(player.x - vw / 2, 0, cols * tile - vw);
    cam_y = clamp(player.y - vh / 2, 0, rows * tile - vh);

    update_visibility();
    update_flow();
    build_3d();
    current_zone = rooms[0];
    show_msg("COMPLEXO " + string(level) + ": explore, colete dados e encontre a saida", 240);
};

apply_upgrade = function(_id) {
    switch (_id) {
        case 0: speed_mult += 0.12; break;
        case 1: stam_mult *= 0.6; break;
        case 2: flash_len += 30; flash_angle += 4; break;
        case 3: batt_mult *= 0.6; break;
        case 4: player.hp_max += 25; player.hp = player.hp_max; break;
        case 5: hear_mult *= 0.7; break;
        case 6: extra_pickups += 1; break;
    }
};

pick_upgrades = function() {
    var _pool = [0, 1, 2, 3, 4, 5, 6];
    upg_choice = [];
    repeat (3) {
        var _i = irandom(array_length(_pool) - 1);
        array_push(upg_choice, _pool[_i]);
        array_delete(_pool, _i, 1);
    }
};

save_best = function() {
    ini_open("panic_save.ini");
    ini_write_real("save", "best", best_pontos);
    ini_write_real("save", "level", best_level);
    ini_close();
};

new_game = function() {
    pontos = 0;
    level = 1;
    player.rank = 1; player.xp = 0; player.xp_next = 5;
    speed_mult = 1; stam_mult = 1; batt_mult = 1; hear_mult = 1; extra_pickups = 0;
    flash_len = 200; flash_angle = 28;
    camera_pitch = 0;
    player.hp_max = 100;
    player.hp = player.hp_max;
    player.stamina_max = 100;
    player.stamina = player.stamina_max;
    player.exhausted = false;
    battery = 100;
    flash_on = true;
    generate_level();
};

new_game();

