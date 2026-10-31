// ============================================================
// PANIC INC. v3 - obj_panic - STEP
// ============================================================

// ---------- SOM ON/OFF ----------
if (keyboard_check_pressed(ord("M"))) {
    sfx_on = !sfx_on;
    audio_master_gain(sfx_on ? 0.9 : 0);
}

// ---------- TITULO ----------
if (state == STATE_TITLE) {
    window_set_cursor(cr_default);
    if (keyboard_check_pressed(vk_enter)) { state = STATE_PLAYING; fade = 1; }
    exit;
}

// ---------- ESTADOS ----------
if (keyboard_check_pressed(vk_escape)) {
    if (state == STATE_PLAYING)     { state = STATE_PAUSED; audio_pause_all(); }
    else if (state == STATE_PAUSED) { state = STATE_PLAYING; audio_resume_all(); }
}
if (keyboard_check_pressed(vk_tab)) mode = 1 - mode;

if (state == STATE_GAMEOVER && keyboard_check_pressed(ord("R"))) {
    new_game();
    state = STATE_PLAYING;
}
if (state == STATE_LEVELDONE) {
    var _pk = -1;
    if (keyboard_check_pressed(ord("1"))) _pk = 0;
    if (keyboard_check_pressed(ord("2"))) _pk = 1;
    if (keyboard_check_pressed(ord("3"))) _pk = 2;
    if (_pk != -1) {
        apply_upgrade(upg_choice[_pk]);
        level++;
        generate_level();
        state = STATE_PLAYING;
    }
}

window_set_cursor((mode == 1 && state == STATE_PLAYING) ? cr_none : cr_default);

if (state != STATE_PLAYING) exit;

flare_pulse = max(0, flare_pulse - 1);

// [MULTIPLAYER FUTURO]: jogadores remotos nao leem teclado,
// apenas interpolam para (sync_x, sync_y) recebidos pela rede.

level_time++;
fade = max(0, fade - 0.02);
if (player.hurt_cd > 0) player.hurt_cd--;
shake = max(0, shake - 0.6);
hurt_flash = max(0, hurt_flash - 0.04);
heart_pulse = max(0, heart_pulse - 0.07);
if (msg_timer > 0) msg_timer--;
if (combo_timer > 0) { combo_timer--; if (combo_timer <= 0) combo = 0; }

// ============================================================
// QUEDA DE ENERGIA (evento aleatorio de suspense)
// ============================================================
blackout_cd--;
if (blackout_cd <= 0 && blackout <= 0) {
    blackout = irandom_range(150, 270);
    blackout_cd = irandom_range(2400, 4200);
    play_snd(snd_blackout, 0.8, 1);
    show_msg("QUEDA DE ENERGIA...", 150);
    shake = max(shake, 6);
}
if (blackout > 0) {
    blackout--;
    if (blackout == 0) play_snd(snd_click, 0.7, 0.7);
}
ambient_cur = (blackout > 0) ? 28 : ambient_r;

for (var k = 0; k < array_length(lamps); k++) {
    var _lm = lamps[k];
    var _tg = 1;
    if (blackout > 0) _tg = 0;
    else if (_lm.broken && irandom(99) < 14) _tg = 0.15;
    _lm.on = lerp(_lm.on, _tg, 0.4);
}

// ============================================================
// INPUT
// ============================================================
var _kl = keyboard_check(ord("A"));
var _kr = keyboard_check(ord("D"));
var _ku = keyboard_check(ord("W")) || keyboard_check(vk_up);
var _kd = keyboard_check(ord("S")) || keyboard_check(vk_down);
if (mode == 0) {
    _kl = _kl || keyboard_check(vk_left);
    _kr = _kr || keyboard_check(vk_right);
}
var _has_input = (_kl || _kr || _ku || _kd);

// ---------- Correr / stamina ----------
if (player.exhausted && player.stamina > 30) player.exhausted = false;
player.is_running = keyboard_check(vk_shift) && _has_input && !player.exhausted && player.stamina > 0;
if (player.is_running) {
    player.stamina -= 0.55 * stam_mult;
    if (player.stamina <= 0) {
        player.stamina = 0;
        player.exhausted = true;
        player.is_running = false;
    }
} else {
    player.stamina = min(player.stamina_max, player.stamina + 0.3);
}

// ---------- Direcao do movimento ----------
var _mx = 0;
var _my = 0;
if (mode == 0) {
    var _ix = _kr - _kl;
    var _iy = _kd - _ku;
    if (_ix != 0 || _iy != 0) {
        var _d = point_direction(0, 0, _ix, _iy);
        _mx = lengthdir_x(1, _d);
        _my = lengthdir_y(1, _d);
    }
    player.facing_dir = point_direction(player.x, player.y, mouse_x, mouse_y);
} else {
    var _fw = _ku - _kd;
    var _st = _kr - _kl;
    var _fx = lengthdir_x(1, player.facing_dir);
    var _fy = lengthdir_y(1, player.facing_dir);
    var _rx = lengthdir_x(1, player.facing_dir - 90);
    var _ry = lengthdir_y(1, player.facing_dir - 90);
    _mx = _fx * _fw + _rx * _st;
    _my = _fy * _fw + _ry * _st;
    var _len = point_distance(0, 0, _mx, _my);
    if (_len > 1) { _mx /= _len; _my /= _len; }

    if (keyboard_check(vk_left))  player.facing_dir += turn_speed;
    if (keyboard_check(vk_right)) player.facing_dir -= turn_speed;
    if (window_has_focus()) {
        var _wcx = window_get_width() / 2;
        var _wcy = window_get_height() / 2;
        player.facing_dir -= (window_mouse_get_x() - _wcx) * mouse_sens;
        window_mouse_set(_wcx, _wcy);
    }
}

var _spd = (player.is_running ? player.run_speed : player.walk_speed) * speed_mult;
player.is_moving = (_mx != 0 || _my != 0);
move_body(player, _mx * _spd, _my * _spd, player.hitbox);
if (player.is_moving) player.bob += player.is_running ? 0.24 : 0.15;

// Sinalizador: recurso limitado que abre espaco quando o jogador fica cercado.
if (keyboard_check_pressed(ord("Q")) && flare_charges > 0) {
    flare_charges--;
    flare_pulse = 34;
    flare_x = player.x;
    flare_y = player.y;
    var _stunned = 0;
    for (var i = 0; i < array_length(enemies); i++) {
        var _flare_enemy = enemies[i];
        if (point_distance(flare_x, flare_y, _flare_enemy.x, _flare_enemy.y) <= 220
            && los(flare_x, flare_y, _flare_enemy.x, _flare_enemy.y)) {
            _flare_enemy.stun = 150;
            _flare_enemy.mode = 0;
            _stunned++;
        }
    }
    add_particles(flare_x, flare_y, 32, c_aqua, 4);
    play_snd(snd_scare, 0.8, 1.35);
    show_msg(_stunned > 0 ? "SINALIZADOR! AMEACAS ATORDOADAS" : "SINALIZADOR! AREA ILUMINADA", 120);
}

// ---------- Passos ----------
var _sg = (sin(player.bob) > 0);
if (player.is_moving && _sg != step_sign) {
    step_sign = _sg;
    play_snd(snd_step, player.is_running ? 0.45 : 0.22, random_range(0.8, 1.2));
}

// ---------- Lanterna ----------
if (keyboard_check_pressed(ord("F"))) {
    flash_on = !flash_on;
    if (battery <= 0) flash_on = false;
    play_snd(snd_click, 0.6, flash_on ? 1.2 : 0.8);
}
flash_power = 1;
if (flash_on) {
    battery -= 0.02 * batt_mult;
    if (battery < 20 && irandom(99) < 10) flash_power = 0.3;
    if (battery <= 0) {
        battery = 0;
        flash_on = false;
        show_msg("A BATERIA ACABOU!", 150);
    }
}
if (battery < 15 && flash_on && (level_time mod 180) == 0) play_snd(snd_beep, 0.4, 1);

// ---------- Visao e pathfinding ----------
update_visibility();
if ((level_time mod 6) == 0) update_flow();

// ============================================================
// INIMIGOS
// ============================================================
alert_cd = max(0, alert_cd - 1);
var _nearest = 99999;
for (var i = 0; i < array_length(enemies); i++) {
    var _e = enemies[i];
    if (_e.stun > 0) {
        _e.stun--;
        _e.anim += 2;
        continue;
    }
    var _dist = point_distance(_e.x, _e.y, player.x, player.y);
    _nearest = min(_nearest, _dist);

    // Esta na luz da lanterna?
    var _lit = false;
    if (flash_on && _dist < flash_len) {
        var _ad = abs(angle_difference(player.facing_dir, point_direction(player.x, player.y, _e.x, _e.y)));
        if (_ad < flash_angle + 6 && los(player.x, player.y, _e.x, _e.y)) _lit = true;
    }
    _e.lit = _lit;

    // Ouvir / ver o player
    var _hear = (player.is_running ? 400 : 230) * hear_mult;
    if (alarm_on) _hear = 99999;
    var _sees = (_dist < 280 && los(_e.x, _e.y, player.x, player.y));
    if (_sees || _dist < _hear) {
        _e.lost = 0;
        if (_e.mode == 0) {
            _e.mode = 1;
            if (alert_cd <= 0) {
                alert_cd = 90;
                play_snd(snd_scare, clamp(1.1 - _dist / 600, 0.25, 0.9), random_range(0.9, 1.1));
                add_floater(_e.x, _e.y - 16, "!", c_red);
                if (_dist < 260) shake = max(shake, 5);
            }
        }
    } else if (_e.mode == 1) {
        _e.lost++;
        if (_e.lost > 240) _e.mode = 0;
    }

    // Velocidade
    var _sp = _e.spd * (alarm_on ? 1.25 : 1);
    if (_e.mode == 0) _sp *= 0.5;
    if (_e.type == 2) {
        if (_lit) _sp = 0;           // perseguidor congela na luz
    } else if (_lit) {
        _sp *= 0.35;
    }

    if (_sp > 0) {
        if (_e.mode == 1) {
            var _tx = player.x;
            var _ty = player.y;
            if (_sees) {
                _sp *= 1.15;
            } else {
                var _ec = floor(_e.x / tile);
                var _er = floor(_e.y / tile);
                if (_ec >= 0 && _er >= 0 && _ec < cols && _er < rows) {
                    var _bv = flow[_ec][_er];
                    if (_bv < 0) _bv = 99999;
                    for (var k = 0; k < 4; k++) {
                        var _nc = _ec + ndx[k];
                        var _nr = _er + ndy[k];
                        if (_nc < 0 || _nr < 0 || _nc >= cols || _nr >= rows) continue;
                        var _fv = flow[_nc][_nr];
                        if (_fv >= 0 && _fv < _bv) {
                            _bv = _fv;
                            _tx = _nc * tile + tile / 2;
                            _ty = _nr * tile + tile / 2;
                        }
                    }
                }
            }
            var _dir = point_direction(_e.x, _e.y, _tx, _ty);
            if (_dist > 6) move_body(_e, lengthdir_x(_sp, _dir), lengthdir_y(_sp, _dir), 8);
            _e.face = _dir;
        } else {
            // Vagando sem rumo
            var _ox = _e.x;
            var _oy = _e.y;
            _e.wt--;
            if (_e.wt <= 0) {
                _e.wdir += random_range(-70, 70);
                _e.wt = irandom_range(40, 120);
            }
            move_body(_e, lengthdir_x(_sp, _e.wdir), lengthdir_y(_sp, _e.wdir), 8);
            if (point_distance(_ox, _oy, _e.x, _e.y) < _sp * 0.3) {
                _e.wdir = random(360);
                _e.wt = 30;
            }
            _e.face = _e.wdir;
        }
        _e.anim += 8;
    }

    // Rosnado ocasional
    if (_e.mode == 1 && _dist < 320 && irandom(420) == 0) {
        play_snd(snd_growl, clamp(1 - _dist / 350, 0.15, 0.7), random_range(0.8, 1.2));
    }

    // Dano
    var _hr = (_e.type == 1) ? 17 : 19;
    if (_dist < _hr) hurt_player((_e.type == 1) ? 8 : 14);
}
panic = lerp(panic, clamp(100 - _nearest / 3.2, 0, 100), 0.05);

// Novos inimigos com o tempo
spawn_timer++;
if (spawn_timer >= spawn_interval && array_length(enemies) < max_enemies) {
    spawn_timer = 0;
    spawn_enemy(380);
    play_snd(snd_growl, 0.25, 0.7);
    show_msg("Algo novo apareceu na escuridao...", 140);
}

// ============================================================
// SONS AMBIENTE E CORACAO
// ============================================================
if (panic > 25) {
    heart_cd--;
    if (heart_cd <= 0) {
        play_snd(snd_heart, 0.35 + panic / 150, 1);
        heart_pulse = 1;
        if (panic > 70) shake = max(shake, 1.5);
        heart_cd = lerp(70, 22, clamp(panic / 100, 0, 1));
    }
}
if ((level_time mod 10) == 0) {
    // A trilha fica mais opressiva com a proximidade e a profundidade do complexo.
    var _phase_drone = min(0.22, max(0, level - 1) * 0.018);
    audio_sound_gain(drone_inst, clamp(0.18 + panic / 100 * 0.42 + _phase_drone, 0.18, 0.82), 250);
}
drip_cd--;
if (drip_cd <= 0) {
    play_snd(snd_drip, 0.25, random_range(0.7, 1.3));
    drip_cd = irandom_range(300, 900);
}
creak_cd--;
if (creak_cd <= 0) {
    play_snd(snd_creak, 0.2, random_range(0.6, 1.2));
    creak_cd = irandom_range(900, 2400);
}

// ============================================================
// ITENS E INTERACAO (tecla E)
// ============================================================
nearby_item = -1;
var _bd = 44;
for (var i = 0; i < array_length(items); i++) {
    items[i].timer += 3;
    var _dd = point_distance(player.x, player.y, items[i].x, items[i].y);
    if (_dd <= _bd) {
        _bd = _dd;
        nearby_item = i;
    }
}

if (nearby_item != -1 && keyboard_check_pressed(ord("E"))) {
    var _it = items[nearby_item];
    var _pcol = c_yellow;
    switch (_it.type) {
        case 0:
            docs_got++;
            combo = (combo_timer > 0) ? combo + 1 : 1;
            combo_timer = 60 * 18;
            var _gain = 100 * combo;
            pontos += _gain;
            add_floater(_it.x, _it.y - 12, "+" + string(_gain) + (combo > 1 ? " x" + string(combo) : ""), c_yellow);
            play_snd(snd_pick, 0.7, 1 + combo * 0.06);
            // Marcos de coleta dao uma pequena recompensa de recuperacao.
            if ((docs_got mod 3) == 0 && docs_got < docs_total) {
                player.hp = min(player.hp_max, player.hp + 12);
                battery = min(100, battery + 15);
                pontos += 150;
                add_floater(_it.x, _it.y - 28, "MARCO! +VIDA +BATERIA +150", c_aqua);
                play_snd(snd_win, 0.3, 1.25);
            }
            show_msg("DOCUMENTO " + string(docs_got) + "/" + string(docs_total), 120);
            if (docs_got >= docs_total) {
                exit_open = true;
                alarm_on = true;
                var _ai = audio_play_sound(snd_alarm, 10, true);
                audio_sound_gain(_ai, 0.35, 0);
                show_msg("ALARME ATIVADO! FUJA PELA SAIDA VERDE!", 260);
                shake = 12;
                if (level == 1) spawn_enemy(420);
            }
            break;
        case 1:
            player.hp = min(player.hp_max, player.hp + 35);
            _pcol = c_lime;
            play_snd(snd_pick, 0.6, 0.7);
            add_floater(_it.x, _it.y - 12, "+35 VIDA", c_lime);
            show_msg("+35 de vida", 90);
            break;
        case 2:
            battery = min(100, battery + 45);
            _pcol = c_aqua;
            play_snd(snd_pick, 0.6, 1.4);
            add_floater(_it.x, _it.y - 12, "+BATERIA", c_aqua);
            show_msg("Bateria recarregada", 90);
            break;
    }
    add_particles(_it.x, _it.y, 18, _pcol, 2);
    array_delete(items, nearby_item, 1);
    nearby_item = -1;
}

// ============================================================
// SAIDA
// ============================================================
if (exit_open) {
    var _exx = exit_c * tile + tile / 2;
    var _exy = exit_r * tile + tile / 2;
    if (point_distance(player.x, player.y, _exx, _exy) < 26) {
        last_bonus = max(0, 500 - floor(level_time / 60) * 4);
        pontos += 250 + last_bonus;
        best_pontos = max(best_pontos, pontos);
        best_level = max(best_level, level);
        save_best();
        player.hp = min(player.hp_max, player.hp + 25);
        audio_stop_sound(snd_alarm);
        play_snd(snd_win, 0.7, 1);
        pick_upgrades();
        state = STATE_LEVELDONE;
    }
}

// ============================================================
// PARTICULAS, TEXTOS, POEIRA
// ============================================================
for (var i = array_length(particles) - 1; i >= 0; i--) {
    var _p = particles[i];
    _p.x += _p.vx;
    _p.y += _p.vy;
    _p.vx *= 0.94;
    _p.vy *= 0.94;
    _p.life--;
    if (_p.life <= 0) array_delete(particles, i, 1);
}
for (var i = array_length(floaters) - 1; i >= 0; i--) {
    var _fl = floaters[i];
    _fl.y -= 0.5;
    _fl.life--;
    if (_fl.life <= 0) array_delete(floaters, i, 1);
}
for (var i = 0; i < array_length(dust); i++) {
    var _du = dust[i];
    _du.x += _du.vx;
    _du.y += _du.vy;
    if (_du.x < 0) _du.x = cols * tile;
    if (_du.x > cols * tile) _du.x = 0;
    if (_du.y < 0) _du.y = rows * tile;
    if (_du.y > rows * tile) _du.y = 0;
}

// ============================================================
// CAMERA 2D
// ============================================================
var _look = (mode == 0) ? 30 : 0;
var _tcx = clamp(player.x - vw / 2 + lengthdir_x(_look, player.facing_dir), 0, cols * tile - vw);
var _tcy = clamp(player.y - vh / 2 + lengthdir_y(_look, player.facing_dir), 0, rows * tile - vh);
cam_x = lerp(cam_x, _tcx, 0.15);
cam_y = lerp(cam_y, _tcy, 0.15);
camera_set_view_pos(cam2d, cam_x + random_range(-shake, shake), cam_y + random_range(-shake, shake));

// ---------- DEBUG ----------
if (keyboard_check_pressed(ord("K"))) hurt_player(10);

// ---------- GAME OVER ----------
if (player.hp <= 0) {
    best_pontos = max(best_pontos, pontos);
    best_level = max(best_level, level);
    save_best();
    audio_stop_sound(snd_alarm);
    play_snd(snd_growl, 1, 0.6);
    state = STATE_GAMEOVER;
}

