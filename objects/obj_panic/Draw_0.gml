// PANIC INC. v4 - mundo 2D/3D
draw_clear(make_color_rgb(10, 15, 25));

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
    _fog_end *= (graphics_quality == 0) ? 0.82 : ((graphics_quality == 2) ? 1.12 : 1.0);
    var _fog_col = (cur_biome == 0) ? make_color_rgb(10, 19, 15) : make_color_rgb(13, 16, 23);
    gpu_set_fog(true, _fog_col, 45, max(120, _fog_end));
    for (var _gb = 0; _gb < array_length(vb_floor); _gb++) {
        if (array_length(vb_floor) > _gb && vb_floor[_gb] != -1) {
            var _floor_tex = (_gb == 4) ? cabin_floor_tex : world_surface_tex;
            vertex_submit(vb_floor[_gb], pr_trianglelist, sprite_get_texture(_floor_tex, 0));
        }
    }
    vertex_submit(vb_world, pr_trianglelist, -1);
    vertex_submit(vb_tree_bark, pr_trianglelist, sprite_get_texture(pine_bark_tex, 0));

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

    // Criaturas com mapas de pele distintos, focinho, cavidade oral, garras e silhuetas prÃ³prias.
    for (var i = 0; i < array_length(enemies); i++) {
        var _en = enemies[i];
        if (point_distance(_en.x, _en.y, player.x, player.y) > 500) continue;
        var _type = clamp(_en.type, 0, 3);
        var _turn = _en.face + sin(_en.anim * 0.05) * 3;
        var _stride = sin(_en.anim * 0.18) * (_en.mode == 1 ? 6 : 2);
        var _bob = abs(sin(_en.anim * 0.18)) * (_en.mode == 1 ? 3 : 1);
        var _breath = 1 + sin(_en.anim * 0.075 + _type) * (_en.mode == 1 ? 0.055 : 0.025);
        var _height = en_h[_type];
        var _width = en_w[_type];
        var _skin_vb = vb_enemy_skin[_type];
        if (_type == 1) {
            // O Rastejante arrasta o tÃ³rax e abre uma mandÃ­bula larga antes do bote.
            var _lunge = _en.mode == 1 ? 5 + abs(sin(_en.anim * 0.28)) * 7 : 0;
            draw_textured_box3d(_skin_vb, monster_skin_tex, _en.x, _en.y, 10 + _bob, (29 + _lunge) * _breath, 16, 10, _turn);
            draw_textured_box3d(_skin_vb, monster_skin_tex, _en.x + lengthdir_x(17 + _lunge, _turn), _en.y + lengthdir_y(17 + _lunge, _turn), 13 + _bob, 12, 9, 8, _turn);
            var _jaw_x = _en.x + lengthdir_x(23 + _lunge, _turn);
            var _jaw_y = _en.y + lengthdir_y(23 + _lunge, _turn);
            draw_box3d(vb_mouth_dark, _jaw_x, _jaw_y, 10 + _bob, 8, 3, 5 + abs(sin(_en.anim * 0.2)) * 5, _turn);
            draw_box3d(vb_mouth_wet, _jaw_x + lengthdir_x(1, _turn), _jaw_y + lengthdir_y(1, _turn), 8 + _bob, 4.5, 1.5, 2.2, _turn);
            for (var _tooth = -1; _tooth <= 1; _tooth++) {
                draw_box3d(vb_claw, _jaw_x + lengthdir_x(2.5, _turn) + lengthdir_x(_tooth * 2.5, _turn + 90), _jaw_y + lengthdir_y(2.5, _turn) + lengthdir_y(_tooth * 2.5, _turn + 90), 12 + _bob, 1.0, 1.0, 3.5, _turn);
            }
            for (var s = -1; s <= 1; s += 2) {
                var _shoulder_x = _en.x + lengthdir_x(4, _turn) + lengthdir_x(8 * s, _turn + 90);
                var _shoulder_y = _en.y + lengthdir_y(4, _turn) + lengthdir_y(8 * s, _turn + 90);
                var _hand_x = _en.x + lengthdir_x(18 + _lunge + _stride * 0.4, _turn) + lengthdir_x(13 * s, _turn + 90);
                var _hand_y = _en.y + lengthdir_y(18 + _lunge + _stride * 0.4, _turn) + lengthdir_y(13 * s, _turn + 90);
                draw_textured_box3d(_skin_vb, monster_skin_tex, _shoulder_x, _shoulder_y, 7 + _bob, 18, 5, 5, _turn + 18 * s);
                draw_textured_box3d(_skin_vb, monster_skin_tex, _hand_x, _hand_y, 4 + _bob, 15, 3.5, 3.5, _turn + 35 * s);
                draw_box3d(vb_claw, _hand_x + lengthdir_x(7, _turn), _hand_y + lengthdir_y(7, _turn), 3 + _bob, 2.3, 2.3, 7, _turn + 90);
                draw_box3d(vb_claw, _hand_x + lengthdir_x(8, _turn + 90 * s), _hand_y + lengthdir_y(8, _turn + 90 * s), 3 + _bob, 1.8, 1.8, 5, _turn + 90 * s);
                draw_box3d(vb_spike, _hand_x + lengthdir_x(11, _turn + 90 * s), _hand_y + lengthdir_y(11, _turn + 90 * s), 3 + _bob, 1.1, 1.1, 5, _turn + 90 * s);
                // A perna traseira fica dobrada e vibra antes de cada arrancada.
                draw_textured_box3d(_skin_vb, monster_skin_tex, _en.x - lengthdir_x(7, _turn) + lengthdir_x(7 * s, _turn + 90), _en.y - lengthdir_y(7, _turn) + lengthdir_y(7 * s, _turn + 90), 4 + _bob, 11, 5, 4.5, _turn - 28 * s);
            }
        } else {
            var _torso_w = (_type == 2) ? _width * 1.12 : _width * 1.55;
            // TÃ³rax, abdÃ´men e ombros separados formam uma silhueta orgÃ¢nica, nÃ£o um bloco Ãºnico.
            draw_textured_box3d(_skin_vb, monster_skin_tex, _en.x, _en.y, _height * 0.43 + _bob, _torso_w * _breath, _width * 0.9, _height * 0.82, _turn);
            draw_textured_box3d(_skin_vb, monster_skin_tex, _en.x - lengthdir_x(2, _turn), _en.y - lengthdir_y(2, _turn), _height * 0.25 + _bob, _torso_w * 0.72, _width * 0.82, _height * 0.40, _turn);
            for (var _shoulder = -1; _shoulder <= 1; _shoulder += 2) {
                var _shoulder_x = _en.x + lengthdir_x(8 * _shoulder, _turn + 90);
                var _shoulder_y = _en.y + lengthdir_y(8 * _shoulder, _turn + 90);
                draw_textured_box3d(_skin_vb, monster_skin_tex, _shoulder_x, _shoulder_y, _height * 0.68 + _bob, _type == 2 ? 7 : 9, 7, 8, _turn + 10 * _shoulder);
            }
            // CabeÃ§a alongada, boca funda e olhos recuados mudam a leitura da silhueta.
            var _head_x = _en.x + lengthdir_x(_type == 2 ? 7 : 5, _turn);
            var _head_y = _en.y + lengthdir_y(_type == 2 ? 7 : 5, _turn);
            draw_textured_box3d(_skin_vb, monster_skin_tex, _head_x, _head_y, _height * 0.84 + _bob, _type == 3 ? 9 : 10, 8, _type == 3 ? 19 : 13, _turn);
            var _face_x = _en.x + lengthdir_x(_type == 2 ? 12 : 11, _turn);
            var _face_y = _en.y + lengthdir_y(_type == 2 ? 12 : 11, _turn);
            var _eye_glow = 0.42 + 0.16 * sin(_en.anim * 0.32);
            draw_box3d(vb_mouth_dark, _face_x + lengthdir_x(1.8, _turn), _face_y + lengthdir_y(1.8, _turn), _height * 0.76 + _bob, _type == 2 ? 3 : 4, 2.3, _type == 2 ? 7 : 8, _turn);
            draw_box3d(vb_mouth_wet, _face_x + lengthdir_x(2.6, _turn), _face_y + lengthdir_y(2.6, _turn), _height * 0.73 + _bob, 1.2, 1.1, 3.2, _turn);
            for (var _eye_side = -1; _eye_side <= 1; _eye_side += 2) {
                var _socket_x = _face_x + lengthdir_x(3.1 * _eye_side, _turn + 90);
                var _socket_y = _face_y + lengthdir_y(3.1 * _eye_side, _turn + 90);
                draw_box3d(vb_eyedark, _socket_x, _socket_y, _height * 0.88 + _bob, 3.4, 2.2, 2.6, _turn);
                if (_type != 2 || flash_on) {
                    var _eye_reveal = (flash_on || _en.mode == 1) ? 1.0 : 0.34;
                    draw_box3d(vb_core, _socket_x + lengthdir_x(1.0, _turn), _socket_y + lengthdir_y(1.0, _turn), _height * 0.88 + _bob, 1.0 * _eye_glow * _eye_reveal, 0.8, 1.1 * _eye_glow * _eye_reveal, _turn);
                }
            }
            for (var s = -1; s <= 1; s += 2) {
                var _sx = _en.x + lengthdir_x(7 * s, _turn + 90);
                var _sy = _en.y + lengthdir_y(7 * s, _turn + 90);
                var _arm_x = _sx + lengthdir_x(_stride, _turn);
                var _arm_y = _sy + lengthdir_y(_stride, _turn);
                draw_textured_box3d(_skin_vb, monster_skin_tex, _arm_x, _arm_y, _height * 0.48 + _bob, _type == 2 ? 5 : 6, 5, _height * 0.58, _turn + 12 * s);
                draw_textured_box3d(_skin_vb, monster_skin_tex, _arm_x + lengthdir_x(4 * s, _turn + 90), _arm_y + lengthdir_y(4 * s, _turn + 90), _height * 0.29 + _bob + _stride * 0.2, 3.8, 3.9, _height * 0.30, _turn + 18 * s);
                draw_textured_box3d(_skin_vb, monster_skin_tex, _en.x + lengthdir_x(5 * s, _turn + 90), _en.y + lengthdir_y(5 * s, _turn + 90), _height * 0.16 + _bob, 6.5, 6.5, _height * 0.35, _turn - _stride * s);
                draw_box3d(vb_claw, _arm_x + lengthdir_x(8, _turn), _arm_y + lengthdir_y(8, _turn), _height * 0.21 + _bob + _stride * 0.2, 2.2, 2.2, 8, _turn + 90 * s);
                for (var _finger = -1; _finger <= 1; _finger++) {
                    var _fx = _arm_x + lengthdir_x(10, _turn) + lengthdir_x(_finger * 2.1, _turn + 90);
                    var _fy = _arm_y + lengthdir_y(10, _turn) + lengthdir_y(_finger * 2.1, _turn + 90);
                    draw_box3d(vb_spike, _fx, _fy, _height * 0.16 + _bob, 0.9, 0.9, 5.5, _turn + 90 * s + _finger * 8);
                }
            }
            if (_type == 0) {
                // Costelas escuras atravessam a pele ressecada do Esvaziado.
                for (var _rib = 0; _rib < 4; _rib++) {
                    draw_box3d(vb_eyedark, _en.x + lengthdir_x(7.8, _turn), _en.y + lengthdir_y(7.8, _turn), _height * 0.35 + _rib * 3.4 + _bob, 8, 2.0, 1.3, _turn);
                }
                draw_box3d(vb_mouth_dark, _face_x + lengthdir_x(3.0, _turn), _face_y + lengthdir_y(3.0, _turn), _height * 0.70 + _bob, 4.0, 1.7, 5.8, _turn);
                for (var _fang = -1; _fang <= 1; _fang += 2) draw_box3d(vb_claw, _face_x + lengthdir_x(5, _turn) + lengthdir_x(2.0 * _fang, _turn + 90), _face_y + lengthdir_y(5, _turn) + lengthdir_y(2.0 * _fang, _turn + 90), _height * 0.69 + _bob, 1.0, 1.0, 3.6, _turn);
            }
            if (_type == 2) {
                // A EstÃ¡tua Ã© alta, sem expressÃ£o, e dobra os braÃ§os como galhos quebrados.
                for (var _horn = -1; _horn <= 1; _horn += 2) {
                    draw_box3d(vb_spike, _head_x + lengthdir_x(3.8 * _horn, _turn + 90), _head_y + lengthdir_y(3.8 * _horn, _turn + 90), _height + 8 + _bob, 3.6, 3.6, 16, _turn + 20 * _horn);
                }
                draw_box3d(vb_eyedark, _face_x + lengthdir_x(1, _turn), _face_y + lengthdir_y(1, _turn), _height * 0.88 + _bob, 5.5, 2.5, 2.0, _turn);
                draw_box3d(vb_spike, _head_x + lengthdir_x(3, _turn + 90), _head_y + lengthdir_y(3, _turn + 90), _height + 2 + _bob, 1.0, 1.0, 12, _turn + 8);
            }
            if (_type == 3) {
                draw_box3d(vb_spike, _en.x - lengthdir_x(5, _turn + 90), _en.y - lengthdir_y(5, _turn + 90), _height + 12 + _bob, 6, 6, 22, _turn - 18);
                draw_box3d(vb_spike, _en.x + lengthdir_x(5, _turn + 90), _en.y + lengthdir_y(5, _turn + 90), _height + 12 + _bob, 6, 6, 22, _turn + 18);
                draw_box3d(vb_spike, _en.x, _en.y, _height + 16 + _bob, 4, 4, 19, _turn);
                // Espinhos quebrados e filamentos laterais se mexem quando a Sombra persegue.
                for (var _sp = 0; _sp < 4; _sp++) {
                    var _tail_z = _height * 0.73 + _bob + sin(_en.anim * 0.21 + _sp) * 2;
                    draw_box3d(vb_spike, _en.x - lengthdir_x(8 + _sp * 5, _turn), _en.y - lengthdir_y(8 + _sp * 5, _turn), _tail_z, 5, 6, 18 - _sp * 2, _turn + 90);
                }
            }
        }
    }
    for (var i = 0; i < array_length(npcs); i++) {
        var _npc = npcs[i];
        if (point_distance(_npc.x, _npc.y, player.x, player.y) > 420) continue;
        var _nb = 0.8 * sin(current_time / 200 + i);
        var _dist_player = point_distance(_npc.x, _npc.y, player.x, player.y);
        var _nf = (_npc.name == "Marta" && _dist_player < 150)
            ? point_direction(_npc.x, _npc.y, player.x, player.y) : _npc.face;
        var _walk = sin(current_time / 115 + i * 2) * 1.3;
        var _stride = abs(sin(current_time / 115 + i * 2)) * 1.6;
        var _forward_x = lengthdir_x(1, _nf); var _forward_y = lengthdir_y(1, _nf);
        var _right_x = lengthdir_x(1, _nf + 90); var _right_y = lengthdir_y(1, _nf + 90);

        // Marta: silhueta humana mais estreita, com pernas, roupa, mangas e rosto separados.
        // As texturas de camiseta, jeans e pele vÃªm dos materiais CC0 empacotados no Create.
        draw_textured_box3d(vb_npc_denim, marta_tex_denim, _npc.x, _npc.y, 20 + _nb, 7.2, 4.2, 6.5, _nf);
        draw_textured_box3d(vb_npc_shirt, marta_tex_shirt, _npc.x, _npc.y, 27 + _nb, 8.2, 4.6, 10.5, _nf);
        draw_textured_box3d(vb_npc_shirt, marta_tex_shirt, _npc.x, _npc.y, 33 + _nb, 9.3, 4.8, 5.3, _nf);

        // Mochila curta e alÃ§as distinguem a sobrevivente sem alargar o torso.
        draw_box3d(vb_npc_pack, _npc.x - _forward_x * 3.2, _npc.y - _forward_y * 3.2, 28 + _nb, 4.5, 2.2, 8.5, _nf);
        draw_box3d(vb_npc_scarf, _npc.x, _npc.y, 36 + _nb, 3.6, 3.7, 2.0, _nf);

        for (var _side = -1; _side <= 1; _side += 2) {
            var _lx = _npc.x + _right_x * 2.2 * _side;
            var _ly = _npc.y + _right_y * 2.2 * _side;
            var _leg_swing = _walk * _side;
            draw_textured_box3d(vb_npc_denim, marta_tex_denim, _lx + _forward_x * _leg_swing, _ly + _forward_y * _leg_swing, 13 + _nb, 3.0, 3.2, 9.5, _nf + _leg_swing * 1.3);
            draw_textured_box3d(vb_npc_denim, marta_tex_denim, _lx + _forward_x * _leg_swing * 1.35, _ly + _forward_y * _leg_swing * 1.35, 6 + _nb, 2.55, 2.9, 7.5, _nf + _leg_swing * 1.8);
            draw_box3d(vb_npc_boot, _lx + _forward_x * 1.1, _ly + _forward_y * 1.1, 2.5 + _nb, 3.1, 4.0, 3.0, _nf);

            var _sx = _npc.x + _right_x * 5.0 * _side;
            var _sy = _npc.y + _right_y * 5.0 * _side;
            draw_textured_box3d(vb_npc_shirt, marta_tex_shirt, _sx, _sy, 29 + _nb, 2.8, 3.0, 8.0, _nf + _side * 5);
            draw_textured_box3d(vb_npc_skin, marta_tex_skin, _sx + _right_x * 0.25 * _side, _sy + _right_y * 0.25 * _side, 22 + _nb + _walk * _side, 2.15, 2.35, 7.2, _nf + _side * 3);
            draw_textured_box3d(vb_npc_skin, marta_tex_skin, _sx + _right_x * 0.3 * _side, _sy + _right_y * 0.3 * _side, 15.5 + _nb + _walk * _side, 1.9, 2.15, 4.0, _nf);
        }

        // PescoÃ§o, cabeÃ§a oval, cabelo preso e traÃ§os faciais visÃ­veis de frente.
        draw_textured_box3d(vb_npc_skin, marta_tex_skin, _npc.x, _npc.y, 37.8 + _nb, 2.6, 2.7, 3.3, _nf);
        draw_textured_box3d(vb_npc_skin, marta_tex_skin, _npc.x + _forward_x * 0.2, _npc.y + _forward_y * 0.2, 43 + _nb, 5.0, 4.5, 6.6, _nf);
        draw_box3d(vb_npc_hair, _npc.x - _forward_x * 0.4, _npc.y - _forward_y * 0.4, 46 + _nb, 5.5, 5.0, 3.3, _nf);
        draw_box3d(vb_npc_hair, _npc.x - _forward_x * 2.4, _npc.y - _forward_y * 2.4, 40 + _nb, 3.0, 3.2, 9.0, _nf);
        for (var _face_eye = -1; _face_eye <= 1; _face_eye += 2) {
            // Os olhos ficam um pouco a frente da superfÃ­cie da cabeÃ§a para nÃ£o sumirem na malha.
            var _ex = _npc.x + _forward_x * 2.85 + _right_x * 1.05 * _face_eye;
            var _ey = _npc.y + _forward_y * 2.85 + _right_y * 1.05 * _face_eye;
            draw_box3d(vb_npc_eye, _ex, _ey, 43.5 + _nb, 0.92, 0.62, 0.78, _nf);
            draw_box3d(vb_npc_brow, _ex + _forward_x * 0.34, _ey + _forward_y * 0.34, 44.6 + _nb, 1.18, 0.48, 0.38, _nf);
        }
        draw_textured_box3d(vb_npc_skin, marta_tex_skin, _npc.x + _forward_x * 3.05, _npc.y + _forward_y * 3.05, 42.2 + _nb, 0.9, 0.8, 1.2, _nf);
        draw_box3d(vb_npc_mouth, _npc.x + _forward_x * 2.95, _npc.y + _forward_y * 2.95, 40.7 + _nb, 1.15, 0.45, 0.55, _nf);

        // Reflexo ocular sutil sob a lanterna, sem os olhos amarelos artificiais antigos.
        var _to_player = point_direction(_npc.x, _npc.y, player.x, player.y);
        if (flash_on && _dist_player < flash_len && abs(angle_difference(_nf, _to_player)) < 65) {
            for (var _flash_eye = -1; _flash_eye <= 1; _flash_eye += 2) {
                draw_box3d(vb_eye, _npc.x + _forward_x * 3.2 + _right_x * 1.05 * _flash_eye, _npc.y + _forward_y * 3.2 + _right_y * 1.05 * _flash_eye, 43.5 + _nb, 0.3, 0.3, 0.3, 0);
            }
        }
    }

    // O Diretor usa a pele mais escura do atlas, com veios e nÃºcleo pulsante.
    if (boss != -1) {
        var _pulse = 1 + 0.06 * sin(boss.anim * 0.12);
        var _boss_sway = sin(boss.anim * 0.08) * 3;
        var _boss_fx = lengthdir_x(1, boss.face); var _boss_fy = lengthdir_y(1, boss.face);
        var _boss_rx = lengthdir_x(1, boss.face + 90); var _boss_ry = lengthdir_y(1, boss.face + 90);
        // Silhueta assimÃ©trica: caixa torÃ¡cica, cabeÃ§a afundada e braÃ§os quase no chÃ£o.
        draw_textured_box3d(vb_enemy_skin[3], monster_skin_tex, boss.x, boss.y, 37, 52 * _pulse, 42, 68 * _pulse, boss.face);
        draw_textured_box3d(vb_enemy_skin[3], monster_skin_tex, boss.x + _boss_fx * 3, boss.y + _boss_fy * 3, 83 + _boss_sway, 28, 27, 31, boss.face);
        for (var s = -1; s <= 1; s += 2) {
            var _bsx = boss.x + _boss_rx * 24 * s;
            var _bsy = boss.y + _boss_ry * 24 * s;
            var _arm_sway = sin(boss.anim * 0.11 + s) * 7;
            draw_textured_box3d(vb_enemy_skin[3], monster_skin_tex, _bsx, _bsy, 63 + _boss_sway, 21, 20, 32, boss.face + s * 10);
            draw_textured_box3d(vb_enemy_skin[3], monster_skin_tex, _bsx + _boss_fx * (13 + _arm_sway), _bsy + _boss_fy * (13 + _arm_sway), 37, 15, 15, 37, boss.face + s * 18);
            draw_box3d(vb_claw, _bsx + _boss_fx * 27 + _boss_rx * s * 2, _bsy + _boss_fy * 27 + _boss_ry * s * 2, 17, 5, 5, 15, boss.face + 90 * s);
            draw_box3d(vb_spike, _bsx - _boss_fx * 5 + _boss_rx * s * 7, _bsy - _boss_fy * 5 + _boss_ry * s * 7, 94 + _boss_sway, 8, 8, 28 + 3 * sin(boss.anim * 0.1 + s), boss.face + s * 12);
        }
        draw_box3d(vb_core, boss.x + _boss_fx * 30, boss.y + _boss_fy * 30, 49 + _boss_sway, 14 * _pulse, 10, 18 * _pulse, current_time * 0.08);
        for (var _rib = -2; _rib <= 2; _rib++) draw_box3d(vb_eyedark, boss.x + _boss_fx * 19 + _boss_rx * _rib * 6, boss.y + _boss_fy * 19 + _boss_ry * _rib * 6, 40 + abs(_rib) * 4, 3, 2, 18, boss.face);
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
            var _variant_2d = abs((c * 37 + r * 71 + c * r * 13 + (c div 3) * 7 + (r div 2) * 11) mod 16);
            var _mat_col = (_bio mod 2) * 4 + (_variant_2d mod 4);
            var _mat_row = floor(_bio / 2) * 4 + floor(_variant_2d / 4);
            var _src_x = _mat_col * 128 + 2; var _src_y = _mat_row * 128 + 2;
            if (world_surface_tex != -1) {
                draw_sprite_part_ext(world_surface_tex, 0, _src_x, _src_y, 124, 124, _x, _y, tile / 124, tile / 124, c_white, 1);
            } else {
                draw_set_color(pal_floor[_bio]);
                fillrect(_x, _y, _x + tile, _y + tile);
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
    draw_husk(_en.x, _en.y, _en.face, _ec, _en.mode == 1, _en.anim, 1, _en.type);
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
    draw_husk(_ha.x, _ha.y, _ha.face, make_color_rgb(202, 202, 220), false, _ha.anim, 0.7, 3);
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
