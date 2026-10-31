// ============================================================
// PANIC INC. v3 - obj_panic - DRAW (mundo 2D ou 3D)
// ============================================================
if (state == STATE_TITLE) {
    draw_clear(make_color_rgb(8, 8, 14));
    exit;
}

// ************************************************************
// MODO 3D (primeira pessoa)
// ************************************************************
if (mode == 1) {
    draw_clear_alpha(c_black, 1);
    gpu_set_ztestenable(true);
    gpu_set_zwriteenable(true);
    gpu_set_cullmode(cull_noculling);

    var _fd = player.facing_dir;
    var _ex = player.x + random_range(-shake, shake) * 0.2;
    var _ey = player.y + random_range(-shake, shake) * 0.2;
    var _motion = player.is_moving ? 1 : 0.18;
    var _sway = sin(current_time / 115) * (player.is_running ? 1.25 : 0.65) * _motion;
    var _ez = eye_h + sin(player.bob) * (player.is_running ? 2.8 : 1.5) + sin(current_time / 430) * 0.7;
    var _look_dir = _fd + _sway;
    var _pitch_target = dsin(camera_pitch) / max(0.84, dcos(camera_pitch));
    var _view = matrix_build_lookat(_ex, _ey, _ez,
                                    _ex + lengthdir_x(1, _look_dir), _ey + lengthdir_y(1, _look_dir), _ez + _pitch_target,
                                    0, 0, 1);
    var _proj = matrix_build_projection_perspective_fov(-fov, -gw / gh, 1, 2000);
    camera_set_view_mat(cam3d, _view);
    camera_set_proj_mat(cam3d, _proj);
    camera_apply(cam3d);

    // Nevoa = alcance da lanterna
    var _fog_end = flash_on ? (150 + 300 * flash_power) : 105;
    if (blackout > 0) _fog_end *= 0.7;
    _fog_end *= max(0.72, 1 - max(0, level - 3) * 0.025);
    gpu_set_fog(true, c_black, 20, _fog_end);

    vertex_submit(vb_world, pr_trianglelist, -1);

    // Itens
    for (var i = 0; i < array_length(items); i++) {
        var _it = items[i];
        if (point_distance(_it.x, _it.y, player.x, player.y) > 420) continue;
        var _vbi = (_it.type == 0) ? vb_doc : ((_it.type == 1) ? vb_med : ((_it.type == 2) ? vb_bat : ((_it.type == 3) ? vb_fuse : vb_relic)));
        var _zz = 14 + sin(_it.timer * 0.05) * 3;
        draw_box3d(_vbi, _it.x, _it.y, _zz, 10, 10, 10, _it.timer * 2);
    }

    // Corpos dos inimigos
    for (var i = 0; i < array_length(enemies); i++) {
        var _en = enemies[i];
        if (point_distance(_en.x, _en.y, player.x, player.y) > 420) continue;
        var _stride = sin(_en.anim * 0.18) * (_en.mode == 1 ? 5 : 2);
        var _bz = abs(sin(_en.anim * 0.18)) * (_en.mode == 1 ? 3.5 : 1.2);
        var _hgt = (_en.type == 3) ? 58 : ((_en.type == 1) ? 29 : ((_en.type == 2) ? 44 : 36));
        var _wid = (_en.type == 3) ? 8 : ((_en.type == 1) ? 9 : 12);
        var _turn = _en.face + sin(_en.anim * 0.07) * 3;
        draw_box3d(vb_body[_en.type], _en.x, _en.y, _hgt / 2 + _bz, _wid, _wid * 0.78, _hgt, _turn);
        draw_box3d(vb_hd[_en.type], _en.x + lengthdir_x(2, _turn), _en.y + lengthdir_y(2, _turn), _hgt + 6 + _bz, 12, 12, 12, _turn + sin(_en.anim * 0.12) * 8);
        // Bracos e pernas articulados: movimento alternado deixa a perseguicao visivel em primeira pessoa.
        draw_box3d(vb_body[_en.type], _en.x + lengthdir_x(_stride, _turn + 90), _en.y + lengthdir_y(_stride, _turn + 90), _hgt * 0.52 + _bz, 4.5, 5, _hgt * 0.48, _turn + 12);
        draw_box3d(vb_body[_en.type], _en.x - lengthdir_x(_stride, _turn + 90), _en.y - lengthdir_y(_stride, _turn + 90), _hgt * 0.52 + _bz, 4.5, 5, _hgt * 0.48, _turn - 12);
        if (_en.type == 3) {
            // O Vigia e alto, estreito, com bracos pendentes e caixa toracica marcada.
            draw_box3d(vb_hd[3], _en.x, _en.y, _hgt * 0.67 + _bz, 9, 3, 4, _turn);
            draw_box3d(vb_body[3], _en.x + lengthdir_x(9, _turn + 90), _en.y + lengthdir_y(9, _turn + 90), _hgt * 0.56 + _bz, 3, 4, _hgt * 0.78, _turn + 8);
            draw_box3d(vb_body[3], _en.x - lengthdir_x(9, _turn + 90), _en.y - lengthdir_y(9, _turn + 90), _hgt * 0.56 + _bz, 3, 4, _hgt * 0.78, _turn - 8);
        }
    }

    // ---- SEM NEVOA: olhos, lampadas e farol da saida (brilham no escuro) ----
    gpu_set_fog(false, c_black, 0, 1);

    for (var i = 0; i < array_length(enemies); i++) {
        var _en2 = enemies[i];
        if (point_distance(_en2.x, _en2.y, player.x, player.y) > 380) continue;
        var _bz2 = sin(_en2.anim * 0.1) * 1.5;
        var _eh = ((_en2.type == 3) ? 58 : ((_en2.type == 1) ? 29 : ((_en2.type == 2) ? 44 : 36))) + 7 + _bz2;
        var _eye_step = (_en2.type == 3) ? 1 : 2;
        for (var s = -1; s <= 1; s += _eye_step) {
            var _ox = _en2.x + lengthdir_x(7, _en2.face) + lengthdir_x(3.5 * s, _en2.face + 90);
            var _oy = _en2.y + lengthdir_y(7, _en2.face) + lengthdir_y(3.5 * s, _en2.face + 90);
            draw_box3d(_en2.type == 3 ? vb_eye_watcher : vb_eye, _ox, _oy, _eh, _en2.type == 3 ? 3.2 : 2.5, 2.5, 2.5, 0);
        }
    }
    for (var k = 0; k < array_length(lamps); k++) {
        var _la = lamps[k];
        if (_la.on > 0.5 && point_distance(_la.x, _la.y, player.x, player.y) < 500) {
            draw_box3d(vb_lamp, _la.x, _la.y, wall_h - 4, 8, 8, 3, 0);
        }
    }
    var _exx = exit_c * tile + tile / 2;
    var _exy = exit_r * tile + tile / 2;
    var _vbx = exit_open ? vb_exit_open : vb_exit_lock;
    draw_box3d(_vbx, _exx, _exy, 2, 24, 24, 3, 0);
    draw_box3d(_vbx, _exx, _exy, 28, 8, 8, 52, current_time * 0.1);

    gpu_set_ztestenable(false);
    camera_apply(cam2d);
    exit;
}

// ************************************************************
// MODO 2D (visao de cima com escuridao)
// ************************************************************
var _cx = camera_get_view_x(cam2d);
var _cy = camera_get_view_y(cam2d);
draw_clear(make_color_rgb(4, 4, 8));

var _c0 = max(0, floor(_cx / tile));
var _c1 = min(cols - 1, floor((_cx + vw) / tile));
var _r0 = max(0, floor(_cy / tile));
var _r1 = min(rows - 1, floor((_cy + vh) / tile));

draw_set_alpha(1);
for (var c = _c0; c <= _c1; c++) {
    for (var r = _r0; r <= _r1; r++) {
        if (!explored[c][r]) continue;
        var _x1 = c * tile;
        var _y1 = r * tile;

        // ---- tile ----
        draw_set_alpha(1);
        if (grid[c][r] == 1) {
            draw_set_color(make_color_rgb(78, 82, 108));
            fillrect(_x1, _y1, _x1 + tile, _y1 + tile);
            // tijolos
            draw_set_color(make_color_rgb(58, 60, 82));
            fillrect(_x1, _y1 + 14, _x1 + tile, _y1 + 15);
            fillrect(_x1 + ((r mod 2) * 16) + 8, _y1 + 7, _x1 + ((r mod 2) * 16) + 9, _y1 + 14);
            fillrect(_x1 + (((r + 1) mod 2) * 16) + 8, _y1 + 15, _x1 + (((r + 1) mod 2) * 16) + 9, _y1 + 27);
            draw_set_color(make_color_rgb(112, 118, 150));
            fillrect(_x1, _y1, _x1 + tile, _y1 + 5);
            draw_set_color(make_color_rgb(200, 60, 50));
            fillrect(_x1, _y1 + 5, _x1 + tile, _y1 + 7);
            draw_set_color(make_color_rgb(48, 50, 70));
            fillrect(_x1, _y1 + tile - 4, _x1 + tile, _y1 + tile);
        } else {
            var _hh = ((c * 73856093) ^ (r * 19349663)) & 15;
            var _g = 50 + _hh + ((c + r) mod 2) * 6;
            draw_set_color(make_color_rgb(_g, _g, _g + 14));
            fillrect(_x1, _y1, _x1 + tile, _y1 + tile);
            // rachaduras / grades de ventilacao
            if (_hh == 3) {
                draw_set_color(make_color_rgb(30, 30, 40));
                draw_line(_x1 + 6, _y1 + 4, _x1 + 14, _y1 + 16);
                draw_line(_x1 + 14, _y1 + 16, _x1 + 12, _y1 + 27);
            } else if (_hh == 9) {
                draw_set_color(make_color_rgb(28, 28, 36));
                for (var gx = 0; gx < 5; gx++) fillrect(_x1 + 6 + gx * 4, _y1 + 8, _x1 + 8 + gx * 4, _y1 + 24);
            }
            if (c == exit_c && r == exit_r) {
                var _pulse = 0.55 + 0.25 * sin(current_time / 180);
                draw_set_alpha(_pulse);
                draw_set_color(exit_open ? c_lime : make_color_rgb(150, 30, 30));
                fillrect(_x1 + 2, _y1 + 2, _x1 + tile - 2, _y1 + tile - 2);
                draw_set_alpha(1);
            }
        }

        // ---- escuridao por cima ----
        draw_set_color(c_black);
        if (vis[c][r]) {
            var _tdist = point_distance(_x1 + 16, _y1 + 16, player.x, player.y);
            var _near_lamp = false;
            for (var k = 0; k < array_length(lamps); k++) {
                if (abs(_x1 - lamps[k].x) < 150 && abs(_y1 - lamps[k].y) < 150) { _near_lamp = true; break; }
            }
            if (_tdist > flash_len + 30 && !_near_lamp) {
                draw_set_alpha(0.8);
                fillrect(_x1, _y1, _x1 + tile, _y1 + tile);
            } else {
                for (var sx = 0; sx < 4; sx++) {
                    for (var sy = 0; sy < 4; sy++) {
                        var _px = _x1 + sx * 8;
                        var _py = _y1 + sy * 8;
                        var _b = max(0.2, light_at(_px + 4, _py + 4));
                        draw_set_alpha(1 - _b);
                        fillrect(_px, _py, _px + 8, _py + 8);
                    }
                }
            }
        } else {
            draw_set_alpha(0.8);
            fillrect(_x1, _y1, _x1 + tile, _y1 + tile);
        }
        draw_set_alpha(1);
    }
}

// ---------- SANGUE NO CHAO ----------
for (var i = 0; i < array_length(decals); i++) {
    var _dc = decals[i];
    var _dcc = floor(_dc.x / tile);
    var _dcr = floor(_dc.y / tile);
    if (_dcc < 0 || _dcr < 0 || _dcc >= cols || _dcr >= rows) continue;
    if (!vis[_dcc][_dcr]) continue;
    var _dl = light_at(_dc.x, _dc.y);
    if (_dl < 0.05) continue;
    draw_set_alpha(clamp(_dl * 0.9, 0, 0.8));
    draw_set_color(make_color_rgb(110, 10, 10));
    draw_circle(_dc.x, _dc.y, _dc.r, false);
    draw_circle(_dc.x + _dc.r * 0.8, _dc.y - _dc.r * 0.4, _dc.r * 0.5, false);
}
draw_set_alpha(1);

// ---------- FEIXE DA LANTERNA (para nas paredes) ----------
if (flash_on) {
    var _fdb = player.facing_dir;
    var _stp = flash_angle / 4;
    var _bcol = make_color_rgb(255, 235, 170);
    gpu_set_blendmode(bm_add);
    draw_primitive_begin(pr_trianglefan);
    draw_vertex_color(player.x, player.y, _bcol, 0.30 * flash_power);
    for (var a = -flash_angle; a <= flash_angle + 0.1; a += _stp) {
        var _rl = ray_len(player.x, player.y, _fdb + a, flash_len);
        draw_vertex_color(player.x + lengthdir_x(_rl, _fdb + a), player.y + lengthdir_y(_rl, _fdb + a), _bcol, 0);
    }
    draw_primitive_end();
    gpu_set_blendmode(bm_normal);
}

// ---------- POEIRA NO AR (so aparece na luz) ----------
for (var i = 0; i < array_length(dust); i++) {
    var _du = dust[i];
    if (_du.x < _cx || _du.x > _cx + vw || _du.y < _cy || _du.y > _cy + vh) continue;
    var _dlb = light_at(_du.x, _du.y);
    if (_dlb < 0.15) continue;
    draw_set_alpha(_dlb * 0.5);
    draw_set_color(c_white);
    draw_circle(_du.x, _du.y, 1, false);
}
draw_set_alpha(1);

// ---------- ITENS ----------
for (var i = 0; i < array_length(items); i++) {
    var _it = items[i];
    var _ic = floor(_it.x / tile);
    var _ir = floor(_it.y / tile);
    if (!vis[_ic][_ir]) continue;
    var _lb = light_at(_it.x, _it.y);
    if (_lb < 0.08) continue;
    var _oy = dsin(_it.timer) * 2;
    // brilho
    gpu_set_blendmode(bm_add);
    draw_set_alpha(_lb * 0.25);
    draw_set_color(_it.type == 0 ? c_yellow : (_it.type == 1 ? c_lime : (_it.type == 2 ? c_aqua : (_it.type == 3 ? c_orange : make_color_rgb(210, 80, 255)))));
    draw_circle(_it.x, _it.y + _oy, 14 + sin(_it.timer * 0.1) * 2, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(clamp(_lb * 1.4, 0, 1));
    if (_it.type == 0) {
        draw_set_color(c_white);
        draw_rectangle(_it.x - 6, _it.y - 8 + _oy, _it.x + 6, _it.y + 8 + _oy, false);
        draw_set_color(c_orange);
        draw_rectangle(_it.x - 6, _it.y - 8 + _oy, _it.x + 6, _it.y + 8 + _oy, true);
        draw_line(_it.x - 3, _it.y - 3 + _oy, _it.x + 3, _it.y - 3 + _oy);
        draw_line(_it.x - 3, _it.y + 1 + _oy, _it.x + 3, _it.y + 1 + _oy);
    } else if (_it.type == 1) {
        draw_set_color(c_white);
        draw_circle(_it.x, _it.y + _oy, 8, false);
        draw_set_color(c_red);
        draw_rectangle(_it.x - 5, _it.y - 1.5 + _oy, _it.x + 5, _it.y + 1.5 + _oy, false);
        draw_rectangle(_it.x - 1.5, _it.y - 5 + _oy, _it.x + 1.5, _it.y + 5 + _oy, false);
    } else if (_it.type == 2) {
        draw_set_color(c_aqua);
        draw_rectangle(_it.x - 4, _it.y - 7 + _oy, _it.x + 4, _it.y + 7 + _oy, false);
        draw_set_color(c_white);
        draw_rectangle(_it.x - 2, _it.y - 9 + _oy, _it.x + 2, _it.y - 7 + _oy, false);
    } else if (_it.type == 3) {
        draw_set_color(c_dkgray);
        draw_rectangle(_it.x - 8, _it.y - 5 + _oy, _it.x + 8, _it.y + 5 + _oy, false);
        draw_set_color(c_orange);
        draw_rectangle(_it.x - 5, _it.y - 3 + _oy, _it.x + 5, _it.y + 3 + _oy, false);
        draw_line_width(_it.x - 7, _it.y - 7 + _oy, _it.x + 7, _it.y + 7 + _oy, 2);
    } else {
        draw_set_color(make_color_rgb(210, 80, 255));
        draw_triangle(_it.x, _it.y - 9 + _oy, _it.x + 8, _it.y + _oy, _it.x, _it.y + 9 + _oy, false);
        draw_triangle(_it.x, _it.y - 9 + _oy, _it.x - 8, _it.y + _oy, _it.x, _it.y + 9 + _oy, false);
    }
    draw_set_alpha(1);
}

// ---------- INIMIGOS ----------
for (var i = 0; i < array_length(enemies); i++) {
    var _en = enemies[i];
    var _nc2 = floor(_en.x / tile);
    var _nr2 = floor(_en.y / tile);
    if (!vis[_nc2][_nr2]) continue;
    var _edist = point_distance(_en.x, _en.y, player.x, player.y);
    var _eb = light_at(_en.x, _en.y);
    if (_edist < 40) _eb = max(_eb, 0.5);

    var _ecol = make_color_rgb(150, 25, 30);
    var _eeye = c_yellow;
    if (_en.type == 1) { _ecol = make_color_rgb(140, 60, 190); _eeye = make_color_rgb(255, 90, 255); }
    if (_en.type == 2) { _ecol = make_color_rgb(215, 215, 225); _eeye = c_white; }
    if (_en.type == 3) { _ecol = make_color_rgb(35, 12, 27); _eeye = make_color_rgb(255, 35, 48); }
    if (_en.lit) _ecol = merge_color(_ecol, c_white, 0.45);
    var _pul = sin(_en.anim * 0.1);
    var _rad = (_en.type == 3) ? 14 + _pul * 2 : (((_en.type == 1) ? 8 : 11) + _pul);

    if (_eb >= 0.1) {
        draw_set_alpha(clamp(_eb * 1.5, 0, 1));
        draw_set_color(c_black);
        draw_ellipse(_en.x - 9, _en.y + 5, _en.x + 9, _en.y + 12, false);
        // tentaculos
        draw_set_color(shade(_ecol, 0.7));
        for (var t = 0; t < 6; t++) {
            var _ta = t * 60 + _en.anim * 0.8;
            var _tl = 14 + 3 * sin(_en.anim * 0.15 + t * 2);
            draw_line_width(_en.x + lengthdir_x(6, _ta), _en.y + lengthdir_y(6, _ta),
                            _en.x + lengthdir_x(_tl, _ta), _en.y + lengthdir_y(_tl, _ta), 2);
        }
        draw_set_color(_ecol);
        draw_circle(_en.x, _en.y, _rad, false);
        // Cicatrizes e placas no corpo ajudam a distinguir a criatura mesmo no escuro.
        draw_set_color(shade(_ecol, 0.55));
        draw_line_width(_en.x - 4, _en.y - 2, _en.x + 3, _en.y + 3, 2);
        draw_circle(_en.x - 4, _en.y - 4, 1.5, false);
        draw_circle(_en.x + 4, _en.y + 4, 1.5, false);
        if (_en.type == 1) {
            var _horn = 4 + sin(_en.anim * 0.18) * 2;
            draw_set_color(shade(_ecol, 1.3));
            draw_line_width(_en.x - 4, _en.y - 5, _en.x - 7, _en.y - 5 - _horn, 2);
            draw_line_width(_en.x + 4, _en.y - 5, _en.x + 7, _en.y - 5 - _horn, 2);
        } else if (_en.type == 2) {
            draw_set_color(c_white);
            draw_line_width(_en.x - 7, _en.y - 8, _en.x - 10, _en.y - 13, 2);
            draw_line_width(_en.x + 7, _en.y - 8, _en.x + 10, _en.y - 13, 2);
        }
        draw_set_color(c_black);
        draw_circle(_en.x, _en.y, _rad, true);
    }

    // olhos brilhantes (visiveis ate no escuro)
    var _ea = (_en.mode == 1) ? 1 : 0.6;
    for (var s = -1; s <= 1; s += 2) {
        var _ex2 = _en.x + lengthdir_x(5, _en.face) + lengthdir_x(3.5 * s, _en.face + 90);
        var _ey2 = _en.y + lengthdir_y(5, _en.face) + lengthdir_y(3.5 * s, _en.face + 90);
        gpu_set_blendmode(bm_add);
        draw_set_alpha(0.45 * _ea);
        draw_set_color(_eeye);
        draw_circle(_ex2, _ey2, 7, false);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
        draw_set_color(_eeye);
        draw_circle(_ex2, _ey2, 2, false);
    }
    if (_en.type == 3) {
        var _third_eye_x = _en.x + lengthdir_x(5, _en.face);
        var _third_eye_y = _en.y + lengthdir_y(5, _en.face);
        draw_set_color(_eeye);
        draw_circle(_third_eye_x, _third_eye_y, 3, false);
    }
    draw_set_alpha(1);
}

// ---------- LAMPADAS (brilho aditivo) ----------
for (var k = 0; k < array_length(lamps); k++) {
    var _la = lamps[k];
    var _lc = floor(_la.x / tile);
    var _lr = floor(_la.y / tile);
    if (!explored[_lc][_lr]) continue;
    var _lcol = alarm_on ? make_color_rgb(255, 40, 40) : make_color_rgb(255, 200, 120);
    var _lal = _la.on * (alarm_on ? (0.5 + 0.5 * sin(current_time / 120)) : 1);
    draw_set_color(shade(_lcol, 0.4 + _lal * 0.6));
    draw_set_alpha(1);
    draw_circle(_la.x, _la.y, 4, false);
    gpu_set_blendmode(bm_add);
    draw_set_color(_lcol);
    draw_set_alpha(0.16 * _lal);
    draw_circle(_la.x, _la.y, 46, false);
    draw_set_alpha(0.22 * _lal);
    draw_circle(_la.x, _la.y, 22, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// ---------- PLAYER (personagem animado) ----------
var _px0 = player.x;
var _py0 = player.y;
var _fd2 = player.facing_dir;
var _sw = sin(player.bob) * (player.is_moving ? 1 : 0);
var _stride = cos(player.bob) * (player.is_moving ? (player.is_running ? 1 : 0.65) : 0.12);
var _breath = sin(current_time / 210) * 0.7;
var _blink = (player.hurt_cd > 0 && (player.hurt_cd mod 6) < 3);
var _jacket = _blink ? c_white : (player.is_running ? make_color_rgb(60, 160, 230) : make_color_rgb(40, 90, 200));

draw_set_alpha(0.35);
draw_set_color(c_black);
draw_ellipse(_px0 - 10, _py0 + 5, _px0 + 10, _py0 + 13, false);
draw_set_alpha(1);

// pes (andando)
draw_set_color(make_color_rgb(30, 30, 40));
for (var s = -1; s <= 1; s += 2) {
    var _fo = _stride * 4 * s;
    draw_circle(_px0 + lengthdir_x(_fo, _fd2) + lengthdir_x(5 * s, _fd2 + 90),
                _py0 + lengthdir_y(_fo, _fd2) + lengthdir_y(5 * s, _fd2 + 90), 3.5, false);
}
// Mochila de equipamento com faixa refletiva
draw_set_color(make_color_rgb(28, 42, 62));
draw_circle(_px0 - lengthdir_x(5, _fd2), _py0 - lengthdir_y(5, _fd2), 5.2, false);
draw_set_color(make_color_rgb(255, 190, 55));
draw_line_width(_px0 - lengthdir_x(5, _fd2) + lengthdir_x(3, _fd2 + 90), _py0 - lengthdir_y(5, _fd2) + lengthdir_y(3, _fd2 + 90),
                _px0 - lengthdir_x(5, _fd2) - lengthdir_x(3, _fd2 + 90), _py0 - lengthdir_y(5, _fd2) - lengthdir_y(3, _fd2 + 90), 2);
// bracos articulados: o braco livre balanca com o passo e o outro aponta a lanterna
draw_set_color(shade(_jacket, 0.75));
for (var s = -1; s <= 1; s += 2) {
    var _arm_swing = (s < 0) ? -_stride * 4 : 0;
    var _ax = _px0 + lengthdir_x(7 * s, _fd2 + 90);
    var _ay = _py0 + lengthdir_y(7 * s, _fd2 + 90) + _breath;
    var _hx = _px0 + lengthdir_x((s < 0) ? 11 : 13, _fd2) + lengthdir_x(2 * s, _fd2 + 90);
    var _hy = _py0 + lengthdir_y((s < 0) ? 11 : 13, _fd2) + lengthdir_y(2 * s, _fd2 + 90) + _arm_swing;
    draw_line_width(_ax, _ay, _hx, _hy, 4);
    draw_set_color(make_color_rgb(225, 180, 145));
    draw_circle(_hx, _hy, 2.2, false);
    draw_set_color(shade(_jacket, 0.75));
}
// corpo
draw_set_color(_jacket);
draw_ellipse(_px0 - 8, _py0 - 8 + _breath, _px0 + 8, _py0 + 9 + _breath, false);
draw_set_color(shade(_jacket, 1.35));
draw_line_width(_px0 - 4, _py0 - 3 + _breath, _px0 + 4, _py0 - 3 + _breath, 2);
draw_set_color(make_color_rgb(255, 190, 55));
draw_line_width(_px0, _py0 - 1 + _breath, _px0, _py0 + 5 + _breath, 2);
draw_set_color(shade(_jacket, 0.8));
for (var s = -1; s <= 1; s += 2) {
    draw_circle(_px0 + lengthdir_x(7 * s, _fd2 + 90), _py0 + lengthdir_y(7 * s, _fd2 + 90), 4, false);
}
draw_set_color(c_black);
draw_circle(_px0, _py0, 9, true);
// cabeca e cabelo
draw_set_color(make_color_rgb(40, 28, 22));
draw_circle(_px0 - lengthdir_x(1.5, _fd2), _py0 - lengthdir_y(1.5, _fd2), 6.5, false);
draw_set_color(make_color_rgb(235, 195, 160));
draw_circle(_px0 + lengthdir_x(1.5, _fd2), _py0 + lengthdir_y(1.5, _fd2), 5, false);
// oculos de protecao e respirador dao uma silhueta propria ao funcionario
var _face_x = _px0 + lengthdir_x(5.2, _fd2);
var _face_y = _py0 + lengthdir_y(5.2, _fd2);
draw_set_color(make_color_rgb(18, 28, 38));
draw_circle(_face_x, _face_y, 3.3, false);
draw_set_color(make_color_rgb(70, 225, 220));
draw_circle(_face_x + lengthdir_x(1.3, _fd2 + 90), _face_y + lengthdir_y(1.3, _fd2 + 90), 0.9, false);
draw_circle(_face_x - lengthdir_x(1.3, _fd2 + 90), _face_y - lengthdir_y(1.3, _fd2 + 90), 0.9, false);
draw_set_color(make_color_rgb(205, 210, 190));
draw_line_width(_px0 + lengthdir_x(2, _fd2 + 90), _py0 + lengthdir_y(2, _fd2 + 90),
                _px0 + lengthdir_x(5, _fd2), _py0 + lengthdir_y(5, _fd2), 2);
// lanterna
draw_set_color(flash_on ? c_yellow : c_gray);
draw_circle(_px0 + lengthdir_x(14, _fd2), _py0 + lengthdir_y(14, _fd2), 3.5, false);
if (flash_on) {
    gpu_set_blendmode(bm_add);
    draw_set_alpha(0.35 * flash_power);
    draw_circle(_px0 + lengthdir_x(14, _fd2), _py0 + lengthdir_y(14, _fd2), 9, false);
    gpu_set_blendmode(bm_normal);
}

// ---------- PULSO VISUAL DO SINALIZADOR ----------
if (flare_pulse > 0) {
    var _flare_progress = 1 - flare_pulse / 34;
    var _flare_radius = 24 + _flare_progress * 220;
    gpu_set_blendmode(bm_add);
    draw_set_color(c_aqua);
    draw_set_alpha((flare_pulse / 34) * 0.9);
    draw_circle(flare_x, flare_y, _flare_radius, true);
    draw_circle(flare_x, flare_y, max(2, _flare_radius - 5), true);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// ---------- PARTICULAS ----------
for (var i = 0; i < array_length(particles); i++) {
    var _pa = particles[i];
    draw_set_alpha(_pa.life / _pa.maxlife);
    draw_set_color(_pa.col);
    draw_circle(_pa.x, _pa.y, _pa.size, false);
}

// ---------- TEXTOS FLUTUANTES ----------
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
for (var i = 0; i < array_length(floaters); i++) {
    var _fl = floaters[i];
    draw_set_alpha(clamp(_fl.life / 30, 0, 1));
    draw_set_color(c_black);
    draw_text(_fl.x + 1, _fl.y + 1, _fl.txt);
    draw_set_color(_fl.col);
    draw_text(_fl.x, _fl.y, _fl.txt);
}
draw_set_halign(fa_left);
draw_set_valign(fa_top);

draw_set_alpha(1);
draw_set_color(c_white);
gpu_set_blendmode(bm_normal);

