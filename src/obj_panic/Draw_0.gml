// PANIC INC. v4 - mundo 2D/3D
draw_clear(make_color_rgb(5, 6, 10));

// A camera de primeira pessoa usa o mesmo mundo gerado pelo jogo 2D.
if (mode == 1 && state != STATE_TITLE && state != STATE_INTRO) {
    gpu_set_ztestenable(true);
    gpu_set_zwriteenable(true);
    gpu_set_cullmode(cull_noculling);

    var _eye_x = player.x + random_range(-shake, shake) * 0.15;
    var _eye_y = player.y + random_range(-shake, shake) * 0.15;
    var _eye_z = eye_h + sin(player.bob) * (player.is_running ? 2.5 : 1.2);
    var _yaw = player.facing_dir;
    var _reach = 300;
    var _pitch = camera_pitch;
    var _look_x = _eye_x + lengthdir_x(_reach * dcos(_pitch), _yaw);
    var _look_y = _eye_y + lengthdir_y(_reach * dcos(_pitch), _yaw);
    var _look_z = _eye_z + _reach * dsin(_pitch);
    camera_set_view_mat(cam3d, matrix_build_lookat(_eye_x, _eye_y, _eye_z, _look_x, _look_y, _look_z, 0, 0, 1));
    camera_set_proj_mat(cam3d, matrix_build_projection_perspective_fov(-fov, gw / gh, 1, 1800));
    camera_apply(cam3d);

    var _fog_end = flash_on ? 620 * flash_power : 240;
    if (blackout > 0) _fog_end *= 0.55;
    if (sanity < 30) _fog_end *= 0.8;
    var _fog_col = (cur_biome == 0) ? make_color_rgb(10, 19, 15) : make_color_rgb(13, 16, 23);
    gpu_set_fog(true, _fog_col, 45, max(120, _fog_end));
    vertex_submit(vb_world, pr_trianglelist, -1);

    // Objetos do cenario sempre flutuam um pouco para continuarem legiveis.
    for (var i = 0; i < array_length(items); i++) {
        var _it = items[i];
        if (point_distance(_it.x, _it.y, player.x, player.y) > 430) continue;
        var _item_index = clamp(_it.type, 0, array_length(vb_it) - 1);
        draw_box3d(vb_it[_item_index], _it.x, _it.y, 12 + sin(_it.timer * 0.05) * 3, 9, 9, 9, _it.timer);
    }
    for (var i = 0; i < array_length(lamps); i++) {
        var _lamp = lamps[i];
        if (_lamp.on > 0.05 && point_distance(_lamp.x, _lamp.y, player.x, player.y) < 500) {
            draw_box3d(vb_lamp, _lamp.x, _lamp.y, wall_h - 5, 10, 10, 4, 0);
        }
    }

    // Silhuetas articuladas: tronco e cabeca organicos, membros separados e movimento.
    for (var i = 0; i < array_length(enemies); i++) {
        var _en = enemies[i];
        if (point_distance(_en.x, _en.y, player.x, player.y) > 500) continue;
        var _type = clamp(_en.type, 0, 3);
        var _turn = _en.face + sin(_en.anim * 0.05) * 3;
        var _stride = sin(_en.anim * 0.18) * (_en.mode == 1 ? 6 : 2);
        var _bob = abs(sin(_en.anim * 0.18)) * (_en.mode == 1 ? 3 : 1);
        var _height = en_h[_type];
        var _width = en_w[_type];
        if (_type == 1) {
            // O Rastejante se arrasta baixo, com coluna arqueada e bracos longos.
            draw_box3d(vb_body[_type], _en.x, _en.y, 10 + _bob, 25, 15, 11, _turn);
            draw_box3d(vb_hd[_type], _en.x + lengthdir_x(16, _turn), _en.y + lengthdir_y(16, _turn), 13 + _bob, 13, 12, 9, _turn);
            for (var s = -1; s <= 1; s += 2) {
                draw_box3d(vb_body[_type], _en.x + lengthdir_x(9 * s, _turn + 90), _en.y + lengthdir_y(9 * s, _turn + 90), 6 + _bob, 21, 4, 5, _turn + 18 * s);
                draw_box3d(vb_spike, _en.x + lengthdir_x(22, _turn) + lengthdir_x(9 * s, _turn + 90), _en.y + lengthdir_y(22, _turn) + lengthdir_y(9 * s, _turn + 90), 4 + _bob, 5, 5, 10, _turn + 90 * s);
            }
        } else {
            draw_box3d(vb_body[_type], _en.x, _en.y, _height * 0.43 + _bob, _width * 1.65, _width * 1.25, _height * 0.82, _turn);
            // Cabeca afundada nos ombros e nucleo vermelho visivel na penumbra.
            draw_box3d(vb_hd[_type], _en.x + lengthdir_x(5, _turn), _en.y + lengthdir_y(5, _turn), _height * 0.84 + _bob, _type == 3 ? 13 : 11, 10, _type == 3 ? 17 : 12, _turn);
            var _face_x = _en.x + lengthdir_x(11, _turn);
            var _face_y = _en.y + lengthdir_y(11, _turn);
            var _eye_glow = 1 + 0.3 * sin(_en.anim * 0.32);
            for (var _eye_side = -1; _eye_side <= 1; _eye_side += 2) {
                draw_box3d(vb_core, _face_x + lengthdir_x(3.5 * _eye_side, _turn + 90), _face_y + lengthdir_y(3.5 * _eye_side, _turn + 90), _height * 0.9 + _bob, 3.4 * _eye_glow, 3.4 * _eye_glow, 3.4 * _eye_glow, 0);
            }
            for (var s = -1; s <= 1; s += 2) {
                var _sx = _en.x + lengthdir_x(7 * s, _turn + 90);
                var _sy = _en.y + lengthdir_y(7 * s, _turn + 90);
                draw_box3d(vb_body[_type], _sx + lengthdir_x(_stride, _turn), _sy + lengthdir_y(_stride, _turn), _height * 0.48 + _bob, 6, 7, _height * 0.55, _turn + 12 * s);
                draw_box3d(vb_body[_type], _en.x + lengthdir_x(5 * s, _turn + 90), _en.y + lengthdir_y(5 * s, _turn + 90), _height * 0.16 + _bob, 7, 8, _height * 0.35, _turn - _stride * s);
            }
            if (_type == 3) {
                draw_box3d(vb_spike, _en.x - lengthdir_x(5, _turn + 90), _en.y - lengthdir_y(5, _turn + 90), _height + 12 + _bob, 8, 8, 22, _turn - 18);
                draw_box3d(vb_spike, _en.x + lengthdir_x(5, _turn + 90), _en.y + lengthdir_y(5, _turn + 90), _height + 12 + _bob, 8, 8, 22, _turn + 18);
                draw_box3d(vb_spike, _en.x, _en.y, _height + 16 + _bob, 5, 5, 18, _turn);
                // Espinhos quebrados ao longo das costas tornam a silhueta legivel de longe.
                for (var _sp = 0; _sp < 4; _sp++) {
                    draw_box3d(vb_spike, _en.x - lengthdir_x(8 + _sp * 5, _turn), _en.y - lengthdir_y(8 + _sp * 5, _turn), _height * 0.72 + _bob, 6, 7, 18 - _sp * 2, _turn + 90);
                }
            }
        }
    }
    for (var i = 0; i < array_length(npcs); i++) {
        var _npc = npcs[i];
        if (point_distance(_npc.x, _npc.y, player.x, player.y) > 420) continue;
        var _nb = 0.8 * sin(current_time / 200 + i);
        var _npc_body = (_npc.kind == 3 && _npc.revealed) ? vb_npc_alert : vb_npc;
        var _nf = _npc.face;
        var _walk = sin(current_time / 95 + i * 2) * 3;
        // Silhueta humana em camadas: casaco, ombros, cabeça, braços e pernas.
        draw_box3d(_npc_body, _npc.x, _npc.y, 17 + _nb, 9, 7, 16, _nf);
        draw_box3d(_npc_body, _npc.x + lengthdir_x(1, _nf), _npc.y + lengthdir_y(1, _nf), 26 + _nb, 13, 8, 9, _nf);
        draw_box3d(vb_hd[2], _npc.x + lengthdir_x(2, _nf), _npc.y + lengthdir_y(2, _nf), 34 + _nb, 6, 6, 8, _nf);
        for (var _side = -1; _side <= 1; _side += 2) {
            draw_box3d(_npc_body, _npc.x + lengthdir_x(6 * _side, _nf + 90), _npc.y + lengthdir_y(6 * _side, _nf + 90), 20 + _nb + _walk * _side, 3.5, 4, 13, _nf + 8 * _side);
            draw_box3d(vb_body[0], _npc.x + lengthdir_x(3 * _side, _nf + 90), _npc.y + lengthdir_y(3 * _side, _nf + 90), 5 + _nb - _walk * _side, 3.5, 4, 10, _nf - 8 * _side);
        }
        // Um pequeno reflexo ocular identifica a face quando a lanterna a alcança.
        if (flash_on && point_distance(_npc.x, _npc.y, player.x, player.y) < flash_len) {
            draw_box3d(vb_eye, _npc.x + lengthdir_x(6, _nf), _npc.y + lengthdir_y(6, _nf), 40 + _nb, 1.5, 1.5, 1.5, 0);
        }
    }

    // O Diretor tem uma massa grande, coroa de espinhos e um nucleo pulsante.
    if (boss != -1) {
        var _pulse = 1 + 0.06 * sin(boss.anim * 0.12);
        draw_box3d(vb_boss, boss.x, boss.y, 36, 58 * _pulse, 52 * _pulse, 70 * _pulse, boss.face);
        draw_box3d(vb_core, boss.x + lengthdir_x(25, boss.face), boss.y + lengthdir_y(25, boss.face), 40, 15, 10, 20, current_time * 0.08);
        for (var s = -1; s <= 1; s++) {
            draw_box3d(vb_spike, boss.x + lengthdir_x(12 * s, boss.face + 90), boss.y + lengthdir_y(12 * s, boss.face + 90), 78, 13, 13, 36, boss.face + 15 * s);
        }
    }

    // Tiros do chefe e brilho visivel mesmo atraves da nevoa.
    gpu_set_fog(false, c_black, 0, 1);
    for (var i = 0; i < array_length(shots); i++) {
        var _sh = shots[i];
        draw_box3d(vb_core, _sh.x, _sh.y, 20, 6, 6, 6, current_time * 0.2);
    }
    for (var i = 0; i < array_length(hallu); i++) {
        var _ha = hallu[i];
        var _a = clamp(_ha.life / 55, 0, 0.75);
        draw_set_alpha(_a);
        draw_box3d(vb_hd[3], _ha.x, _ha.y, 24 + sin(_ha.anim * 0.1) * 4, 15, 12, 36, _ha.face);
        draw_box3d(vb_eye, _ha.x, _ha.y, 38, 5, 4, 4, 0);
        draw_set_alpha(1);
    }
    for (var i = 0; i < array_length(lamps); i++) {
        var _lamp = lamps[i];
        if (_lamp.on > 0.4 && point_distance(_lamp.x, _lamp.y, player.x, player.y) < 500) {
            draw_set_color(_lamp.col);
            draw_set_alpha(_lamp.on * 0.7);
            draw_circle(_lamp.x, _lamp.y, 12 + sin(current_time / 100) * 2, true);
        }
    }
    draw_set_alpha(1);
    gpu_set_fog(false, c_black, 0, 1);
    gpu_set_ztestenable(false);
    gpu_set_zwriteenable(false);
    matrix_set(matrix_world, matrix_build_identity());
    camera_apply(cam2d);
    exit;
}

// Exploracao em 2D: tiles texturizados proceduralmente e iluminacao local.
var _view_x = camera_get_view_x(cam2d);
var _view_y = camera_get_view_y(cam2d);
var _c0 = max(0, floor(_view_x / tile));
var _c1 = min(cols - 1, floor((_view_x + vw) / tile));
var _r0 = max(0, floor(_view_y / tile));
var _r1 = min(rows - 1, floor((_view_y + vh) / tile));

for (var c = _c0; c <= _c1; c++) {
    for (var r = _r0; r <= _r1; r++) {
        var _x = c * tile; var _y = r * tile;
        if (!explored[c][r]) {
            draw_set_color(make_color_rgb(3, 4, 7));
            fillrect(_x, _y, _x + tile, _y + tile);
            continue;
        }
        var _bio = clamp(biome[c][r], 0, array_length(pal_floor) - 1);
        if (grid[c][r] >= 1) {
            var _wall = pal_wall[_bio];
            draw_set_color(shade(_wall, 0.8)); fillrect(_x, _y, _x + tile, _y + tile);
            draw_set_color(shade(_wall, 1.15)); fillrect(_x, _y, _x + tile, _y + 5);
            draw_set_color(shade(_wall, 0.55)); fillrect(_x, _y + tile - 5, _x + tile, _y + tile);
            if (_bio == 4) {
                draw_set_color(make_color_rgb(68, 43, 28));
                fillrect(_x + 7, _y + 2, _x + 9, _y + tile - 2);
                fillrect(_x + 23, _y + 2, _x + 25, _y + tile - 2);
            } else {
                draw_set_color(shade(_wall, 0.62));
                fillrect(_x, _y + 15, _x + tile, _y + 17);
                var _offset = ((r mod 2) * 16) + 7;
                fillrect(_x + _offset, _y + 5, _x + _offset + 2, _y + 15);
                fillrect(_x + 16 - (_offset mod 16), _y + 17, _x + 18 - (_offset mod 16), _y + 27);
            }
            if (grid[c][r] == 2) {
                draw_set_color(make_color_rgb(210, 115, 35));
                draw_rectangle(_x + 4, _y + 4, _x + tile - 4, _y + tile - 4, true);
                draw_set_color(make_color_rgb(30, 22, 18));
                fillrect(_x + 13, _y + 6, _x + 19, _y + tile - 6);
            }
        } else {
            var _noise = abs((c * 37 + r * 71 + c * r * 13) mod 23);
            draw_set_color(shade(pal_floor[_bio], 0.82 + _noise / 100));
            fillrect(_x, _y, _x + tile, _y + tile);
            draw_set_color(shade(pal_floor[_bio], 0.66));
            if (_bio == 0) {
                // Folhas e terra: repetiveis por posicao, sem custo de sprites externas.
                if (_noise mod 3 == 0) draw_circle(_x + 6 + (_noise mod 17), _y + 8 + (_noise mod 15), 2, false);
                if (_noise mod 5 == 0) draw_line(_x + 5, _y + 25, _x + 15, _y + 21);
            } else if (_bio == 1) {
                if (_noise mod 4 == 0) draw_line(_x + 3, _y + 9, _x + 28, _y + 9);
                if (_noise mod 6 == 0) draw_circle(_x + 21, _y + 23, 2, false);
            } else {
                if (_noise mod 4 == 0) draw_line(_x + 4, _y + 25, _x + 24, _y + 8);
                if (_noise mod 5 == 0) fillrect(_x + 4, _y + 6, _x + 27, _y + 8);
            }
        }
        // Sombra gradual para tiles ja vistos, mas fora da visao atual.
        if (!vis[c][r]) {
            draw_set_color(c_black);
            draw_set_alpha(explored[c][r] ? 0.55 : 0.95);
            fillrect(_x, _y, _x + tile, _y + tile);
            draw_set_alpha(1);
        } else {
            var _light = light_at(_x + tile / 2, _y + tile / 2);
            if (_light < 0.86) {
                draw_set_color(c_black);
                draw_set_alpha(1 - _light);
                fillrect(_x, _y, _x + tile, _y + tile);
                draw_set_alpha(1);
            }
        }
    }
}

// Decoracao de floresta, usada como moldura e obstaculo visual.
for (var c = _c0; c <= _c1; c++) {
    for (var r = _r0; r <= _r1; r++) {
        if (!vis[c][r] || grid[c][r] != 1 || biome[c][r] != 0) continue;
        if ((c * 19 + r * 31) mod 7 != 0) continue;
        var _tx = c * tile + 16; var _ty = r * tile + 18;
        draw_set_color(make_color_rgb(10, 19, 13)); draw_ellipse(_tx - 12, _ty + 4, _tx + 12, _ty + 11, false);
        draw_set_color(make_color_rgb(39, 58, 40)); draw_triangle(_tx - 14, _ty + 4, _tx + 14, _ty + 4, _tx, _ty - 28, false);
        draw_set_color(make_color_rgb(25, 39, 29)); draw_triangle(_tx - 11, _ty - 3, _tx + 11, _ty - 3, _tx, _ty - 36, false);
    }
}

// Pontos seguros e luzes quentes ajudam a criar contraste com o mundo escuro.
for (var i = 0; i < array_length(lamps); i++) {
    var _lamp = lamps[i];
    var _lc = floor(_lamp.x / tile); var _lr = floor(_lamp.y / tile);
    if (_lc < _c0 || _lc > _c1 || _lr < _r0 || _lr > _r1 || !vis[_lc][_lr]) continue;
    if (_lamp.on > 0.1) {
        gpu_set_blendmode(bm_add);
        draw_set_color(_lamp.col); draw_set_alpha(_lamp.on * 0.24);
        draw_circle(_lamp.x, _lamp.y, 35 + 4 * sin(current_time / 100), false);
        gpu_set_blendmode(bm_normal); draw_set_alpha(1);
        draw_set_color(make_color_rgb(255, 220, 145)); draw_circle(_lamp.x, _lamp.y, 5, false);
    }
}

// Rastro, poeira e sangue contam o que aconteceu no caminho.
for (var i = 0; i < array_length(decals); i++) {
    var _dc = decals[i]; var _dcx = floor(_dc.x / tile); var _dcy = floor(_dc.y / tile);
    if (_dcx < 0 || _dcy < 0 || _dcx >= cols || _dcy >= rows || !vis[_dcx][_dcy]) continue;
    draw_set_alpha(0.55); draw_set_color(make_color_rgb(100, 8, 14)); draw_ellipse(_dc.x - _dc.r, _dc.y - _dc.r * 0.5, _dc.x + _dc.r, _dc.y + _dc.r * 0.5, false); draw_set_alpha(1);
}
for (var i = 0; i < array_length(dust); i++) {
    var _du = dust[i];
    if (point_distance(_du.x, _du.y, player.x, player.y) > 180 || light_at(_du.x, _du.y) < 0.3) continue;
    draw_set_alpha(0.55); draw_set_color(c_white); draw_circle(_du.x, _du.y, 1, false); draw_set_alpha(1);
}

for (var i = 0; i < array_length(items); i++) {
    var _it = items[i]; var _ic = floor(_it.x / tile); var _ir = floor(_it.y / tile);
    if (_ic < 0 || _ir < 0 || _ic >= cols || _ir >= rows || !vis[_ic][_ir]) continue;
    var _col = (_it.type == IT_NOTE) ? c_yellow : ((_it.type == IT_MED) ? c_lime : ((_it.type == IT_BAT) ? c_aqua : ((_it.type == IT_AMMO) ? c_orange : make_color_rgb(210, 80, 255))));
    var _bob = sin(_it.timer * 0.07) * 2;
    gpu_set_blendmode(bm_add); draw_set_color(_col); draw_set_alpha(0.32); draw_circle(_it.x, _it.y + _bob, 12, false); gpu_set_blendmode(bm_normal); draw_set_alpha(1);
    draw_set_color(_col);
    if (_it.type == IT_NOTE) { draw_rectangle(_it.x - 5, _it.y - 7 + _bob, _it.x + 5, _it.y + 7 + _bob, false); draw_line(_it.x - 3, _it.y - 2 + _bob, _it.x + 3, _it.y - 2 + _bob); draw_line(_it.x - 3, _it.y + 2 + _bob, _it.x + 3, _it.y + 2 + _bob); }
    else if (_it.type == IT_KEY) { draw_circle(_it.x, _it.y + _bob, 5, true); draw_line_width(_it.x + 4, _it.y + _bob, _it.x + 11, _it.y + _bob, 2); }
    else { draw_circle(_it.x, _it.y + _bob, 6, false); draw_set_color(c_white); draw_circle(_it.x - 2, _it.y - 2 + _bob, 2, false); }
}

for (var i = 0; i < array_length(npcs); i++) {
    var _npc = npcs[i]; var _nx = floor(_npc.x / tile); var _ny = floor(_npc.y / tile);
    if (_nx < 0 || _ny < 0 || _nx >= cols || _ny >= rows || !vis[_nx][_ny]) continue;
    var _npc_color = (_npc.kind == 2) ? make_color_rgb(85, 145, 195) : ((_npc.kind == 3 && _npc.revealed) ? make_color_rgb(155, 28, 38) : make_color_rgb(150, 91, 72));
    draw_person(_npc.x, _npc.y + sin(current_time / 180 + i) * 1.5, _npc.face, _npc_color);
    if (point_distance(player.x, player.y, _npc.x, _npc.y) < 90) { draw_set_color(c_aqua); draw_circle(_npc.x, _npc.y - 18, 2 + sin(current_time / 100), false); }
}

for (var i = 0; i < array_length(enemies); i++) {
    var _en = enemies[i]; var _ex = floor(_en.x / tile); var _ey = floor(_en.y / tile);
    if (_ex < 0 || _ey < 0 || _ex >= cols || _ey >= rows || !vis[_ex][_ey]) continue;
    var _ec = (_en.type == 0) ? make_color_rgb(100, 110, 128) : ((_en.type == 1) ? make_color_rgb(130, 45, 34) : ((_en.type == 2) ? make_color_rgb(205, 211, 225) : make_color_rgb(68, 26, 77)));
    var _pulse = _en.mode == 1 ? 1 : 0.74;
    draw_set_alpha(_pulse);
    draw_husk(_en.x, _en.y, _en.face, _ec, _en.mode == 1, _en.anim, 1);
    draw_set_alpha(1);
    if (_en.mode == 1) {
        draw_set_color(make_color_rgb(255, 30, 22));
        for (var s = -1; s <= 1; s += 2) draw_circle(_en.x + lengthdir_x(3 * s, _en.face + 90), _en.y + lengthdir_y(3 * s, _en.face + 90), 1.5, false);
    }
}

for (var i = 0; i < array_length(hallu); i++) {
    var _ha = hallu[i]; var _hx = floor(_ha.x / tile); var _hy = floor(_ha.y / tile);
    if (_hx < 0 || _hy < 0 || _hx >= cols || _hy >= rows || !vis[_hx][_hy]) continue;
    draw_set_alpha(clamp(_ha.life / 55, 0, 0.72));
    draw_husk(_ha.x, _ha.y, _ha.face, make_color_rgb(202, 202, 220), false, _ha.anim, 0.7);
    draw_set_alpha(1);
}

if (boss != -1) {
    var _breath = 1 + 0.07 * sin(boss.anim * 0.12);
    draw_set_color(make_color_rgb(15, 4, 10)); draw_ellipse(boss.x - 34, boss.y + 15, boss.x + 34, boss.y + 31, false);
    draw_set_color(boss.flash > 0 ? c_white : make_color_rgb(80, 10, 23)); draw_ellipse(boss.x - 25 * _breath, boss.y - 32 * _breath, boss.x + 25 * _breath, boss.y + 28 * _breath, false);
    draw_set_color(make_color_rgb(45, 8, 20)); draw_triangle(boss.x - 25, boss.y - 14, boss.x - 17, boss.y - 55, boss.x - 6, boss.y - 25, false); draw_triangle(boss.x + 25, boss.y - 14, boss.x + 17, boss.y - 55, boss.x + 6, boss.y - 25, false);
    draw_set_color(c_red); draw_circle(boss.x - 8, boss.y - 8, 3, false); draw_circle(boss.x + 8, boss.y - 8, 3, false);
}

for (var i = 0; i < array_length(shots); i++) { draw_set_color(make_color_rgb(255, 60, 65)); draw_circle(shots[i].x, shots[i].y, 4, false); }
for (var i = 0; i < array_length(tracers); i++) { draw_set_color(c_yellow); draw_set_alpha(tracers[i].life / 6); draw_line_width(tracers[i].x1, tracers[i].y1, tracers[i].x2, tracers[i].y2, 2); draw_set_alpha(1); }
for (var i = 0; i < array_length(particles); i++) { var _p = particles[i]; draw_set_alpha(_p.life / _p.maxlife); draw_set_color(_p.col); draw_circle(_p.x, _p.y, _p.size, false); draw_set_alpha(1); }
for (var i = 0; i < array_length(floaters); i++) { var _f = floaters[i]; draw_set_alpha(_f.life / 70); draw_set_color(_f.col); draw_text(_f.x, _f.y - (70 - _f.life) * 0.3, _f.txt); draw_set_alpha(1); }

// Jogadora, lanterna e indicador de saida.
draw_set_color(make_color_rgb(5, 7, 12)); draw_ellipse(player.x - 10, player.y - 5, player.x + 10, player.y + 7, false);
draw_set_color(player.hurt_cd > 0 && (player.hurt_cd div 4) mod 2 == 0 ? c_white : make_color_rgb(60, 175, 205));
draw_circle(player.x, player.y, player.radius, false);
draw_set_color(c_white); draw_circle(player.x + lengthdir_x(4, player.facing_dir), player.y + lengthdir_y(4, player.facing_dir), 3, false);
if (flash_on) {
    var _end_x = player.x + lengthdir_x(flash_len * 0.42, player.facing_dir);
    var _end_y = player.y + lengthdir_y(flash_len * 0.42, player.facing_dir);
    draw_set_alpha(0.38); draw_set_color(make_color_rgb(255, 238, 180)); draw_line_width(player.x, player.y, _end_x, _end_y, 2); draw_set_alpha(1);
}

// Vinheta e lampejo dao resposta visual ao dano e a baixa sanidade.
if (hurt_flash > 0) { draw_set_color(c_red); draw_set_alpha(hurt_flash * 0.28); fillrect(_view_x, _view_y, _view_x + vw, _view_y + vh); draw_set_alpha(1); }
if (white_flash > 0) { draw_set_color(c_white); draw_set_alpha(white_flash * 0.45); fillrect(_view_x, _view_y, _view_x + vw, _view_y + vh); draw_set_alpha(1); }



