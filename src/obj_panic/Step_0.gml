// ============================================================
// PANIC INC. v4 - obj_panic - STEP
// ============================================================

// ---------- SOM ON/OFF ----------
if (keyboard_check_pressed(ord("N"))) {
    sfx_on = !sfx_on;
    audio_master_gain(sfx_on ? 0.9 : 0);
}

// ---------- TITULO ----------
if (state == STATE_TITLE) {
    window_set_cursor(cr_default);
    if (keyboard_check_pressed(vk_enter)) { state = STATE_INTRO; intro_i = 0; intro_t = 0; }
    exit;
}

// ---------- INTRODUCAO DA HISTORIA ----------
if (state == STATE_INTRO) {
    window_set_cursor(cr_default);
    intro_t += 1.2;
    var _txt = intro_pages[intro_i];
    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(ord("E")) || mouse_check_button_pressed(mb_left)) {
        if (intro_t < string_length(_txt)) {
            intro_t = string_length(_txt);
        } else {
            intro_i++;
            intro_t = 0;
            if (intro_i >= array_length(intro_pages)) {
                state = STATE_PLAYING;
                fade = 1;
                show_msg("Fale com a mulher na cabana.", 220);
            }
        }
    }
    exit;
}

// ---------- DIALOGO ----------
if (state == STATE_DIALOG) {
    window_set_cursor(cr_default);
    dlg_t += 1.5;
    var _ln = dlg_lines[dlg_i];
    if (keyboard_check_pressed(ord("E")) || keyboard_check_pressed(vk_enter) || mouse_check_button_pressed(mb_left)) {
        if (dlg_t < string_length(_ln[1])) {
            dlg_t = string_length(_ln[1]);
        } else {
            dlg_i++;
            dlg_t = 0;
            if (dlg_i >= array_length(dlg_lines)) finish_dialog();
        }
    }
    exit;
}

// ---------- LENDO UMA NOTA ----------
if (state == STATE_READ) {
    window_set_cursor(cr_default);
    if (keyboard_check_pressed(ord("E")) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_escape)) {
        state = STATE_PLAYING;
    }
    exit;
}

// ---------- ESCOLHA DE MELHORIA ----------
if (state == STATE_UPGRADE) {
    window_set_cursor(cr_default);
    var _pk = -1;
    if (keyboard_check_pressed(ord("1"))) _pk = 0;
    if (keyboard_check_pressed(ord("2"))) _pk = 1;
    if (keyboard_check_pressed(ord("3"))) _pk = 2;
    if (_pk != -1) {
        apply_upgrade(upg_choice[_pk]);
        play_snd(snd_win, 0.6, 1);
        state = STATE_PLAYING;
    }
    exit;
}

// ---------- ESCOLHA DO FINAL ----------
if (state == STATE_ENDCHOICE) {
    window_set_cursor(cr_default);
    if (keyboard_check_pressed(ord("1")) || keyboard_check_pressed(ord("2"))) {
        ending = keyboard_check_pressed(ord("1")) ? 1 : 2;
        endings_seen = endings_seen | ending;
        var _secs = floor(play_time / 60);
        if (best_time == 0 || _secs < best_time) best_time = _secs;
        save_game();
        if (ending == 1) {
            end_text = "Você aperta o botão. O Coração pulsa uma última vez e se apaga.\n\nLucas sorri: 'Você não tem mais medo, Ana.'\n\nQuando a luz do amanhecer chega a Vale Sombrio, os Esvaziados se desfazem como cinza. Quem eles foram, finalmente descansa.\n\nLucas já não está ali. Mas, pela primeira vez em muito tempo, a cidade dorme em paz.\n\nFINAL: O DESCANSO";
        } else {
            end_text = "Você arranca Lucas do casulo. O Coração grita.\n\nVocês correm enquanto o complexo desaba atrás de vocês. O sol nasce sobre as cinzas. Lucas respira, vivo.\n\nMas, ao longe, na mata... algo ainda observa.\n\nO Coração não morreu. Ele só aprendeu o seu nome.\n\nFINAL: O ECO DO MEDO";
        }
        end_t = 0;
        play_snd(snd_win, 0.8, 0.8);
        state = STATE_ENDING;
    }
    exit;
}
if (state == STATE_ENDING) {
    window_set_cursor(cr_default);
    end_t += 0.9;
    if (keyboard_check_pressed(vk_enter)) {
        if (end_t < string_length(end_text)) {
            end_t = string_length(end_text);
        } else {
            audio_stop_all();
            drone_inst = audio_play_sound(snd_drone, 1, true);
            audio_sound_gain(drone_inst, 0.3, 0);
            new_game();
            state = STATE_TITLE;
        }
    }
    exit;
}

// ---------- GAME OVER ----------
if (state == STATE_GAMEOVER) {
    window_set_cursor(cr_default);
    if (keyboard_check_pressed(ord("R"))) respawn();
    exit;
}

// ---------- PAUSA / DIARIO / MAPA / MODO 2D-3D ----------
if (keyboard_check_pressed(vk_escape)) {
    if (state == STATE_PLAYING)      { state = STATE_PAUSED; audio_pause_all(); }
    else if (state == STATE_PAUSED)  { state = STATE_PLAYING; audio_resume_all(); }
    else if (state == STATE_JOURNAL || state == STATE_MAP) state = STATE_PLAYING;
}
if (keyboard_check_pressed(vk_tab) && (state == STATE_PLAYING || state == STATE_PAUSED)) mode = 1 - mode;

if (state == STATE_PLAYING) {
    if (keyboard_check_pressed(ord("J"))) { state = STATE_JOURNAL; jr_sel = array_length(notes_found) - 1; }
    else if (keyboard_check_pressed(ord("M"))) state = STATE_MAP;
} else if (state == STATE_JOURNAL) {
    var _nn = array_length(notes_found);
    if (keyboard_check_pressed(ord("S")) || keyboard_check_pressed(vk_down)) jr_sel = min(_nn - 1, jr_sel + 1);
    if (keyboard_check_pressed(ord("W")) || keyboard_check_pressed(vk_up))   jr_sel = max(0, jr_sel - 1);
    if (keyboard_check_pressed(ord("J"))) state = STATE_PLAYING;
} else if (state == STATE_MAP) {
    if (keyboard_check_pressed(ord("M"))) state = STATE_PLAYING;
}

window_set_cursor((mode == 1 && state == STATE_PLAYING) ? cr_none : cr_default);

if (state != STATE_PLAYING) exit;

// [MULTIPLAYER FUTURO]: jogadores remotos nao leem teclado,
// apenas interpolam para (sync_x, sync_y) recebidos pela rede.

// ============================================================
// TEMPORIZADORES
// ============================================================
play_time++;
fade = max(0, fade - 0.02);
white_flash = max(0, white_flash - 0.015);
if (player.hurt_cd > 0) player.hurt_cd--;
if (player.shoot_cd > 0) player.shoot_cd--;
muzzle = max(0, muzzle - 1);
shake = max(0, shake - 0.6);
hurt_flash = max(0, hurt_flash - 0.04);
heart_pulse = max(0, heart_pulse - 0.07);
if (msg_timer > 0) msg_timer--;
// Interferencias raras: uma linha curta, sem cobrir os avisos de jogo.
if (radio_cd > 0) radio_cd--;
if (sanity < 38 && radio_cd <= 0 && msg_timer <= 0 && state == STATE_PLAYING) {
    var _static_lines = [
        "RADIO: Ana... não tem ninguém na cabana.",
        "LUCAS? [chiado] Você demorou. Ele já sabe que chegou.",
        "VOZ DESCONHECIDA: Apague a lanterna. Quero ver seu rosto.",
        "RÁDIO: ...a gravação foi feita amanhã. Repito: amanhã."
    ];
    show_msg(_static_lines[irandom(array_length(_static_lines) - 1)], 150);
    play_snd(snd_whisper, 0.32, random_range(0.75, 1.15));
    radio_cd = irandom_range(900, 1500);
}
if (zone_timer > 0) zone_timer--;
if (alarm_timer > 0) alarm_timer--;
if (flicker_t > 0) flicker_t--;

// ============================================================
// QUEDA DE ENERGIA E LAMPADAS
// ============================================================
blackout_cd--;
if (blackout_cd <= 0 && blackout <= 0 && !boss_started) {
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
    if (blackout > 0 || (flicker_t > 0 && irandom(3) == 0)) _tg = 0;
    else if (_lm.broken && irandom(99) < 14) _tg = 0.15;
    _lm.on = lerp(_lm.on, _tg, 0.4);
}

// ============================================================
// INPUT E MOVIMENTO
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
    // +90 e o lado direito da camera para a convencao de angulos do GameMaker.
    var _rx = lengthdir_x(1, player.facing_dir + 90);
    var _ry = lengthdir_y(1, player.facing_dir + 90);
    _mx = _fx * _fw + _rx * _st;
    _my = _fy * _fw + _ry * _st;
    var _len = point_distance(0, 0, _mx, _my);
    if (_len > 1) { _mx /= _len; _my /= _len; }
    if (keyboard_check(vk_left))  player.facing_dir += turn_speed;
    if (keyboard_check(vk_right)) player.facing_dir -= turn_speed;
    if (window_has_focus()) {
        var _wcx = window_get_width() / 2;
        var _wcy = window_get_height() / 2;
        // Mouse para a direita deve girar a camera para a direita.
        player.facing_dir += (window_mouse_get_x() - _wcx) * mouse_sens;
        camera_pitch = clamp(camera_pitch - (window_mouse_get_y() - _wcy) * mouse_sens, -30, 30);
        window_mouse_set(_wcx, _wcy);
    }
}

var _spd = (player.is_running ? player.run_speed : player.walk_speed) * speed_mult;
player.is_moving = (_mx != 0 || _my != 0);
move_body(player, _mx * _spd, _my * _spd, player.hitbox);
if (player.is_moving) player.bob += player.is_running ? 0.24 : 0.15;

// passos
var _sg = (sin(player.bob) > 0);
if (player.is_moving && _sg != step_sign) {
    step_sign = _sg;
    play_snd(snd_step, player.is_running ? 0.45 : 0.22, random_range(0.8, 1.2));
}

// lanterna
if (keyboard_check_pressed(ord("F"))) {
    flash_on = !flash_on;
    if (battery <= 0) flash_on = false;
    play_snd(snd_click, 0.6, flash_on ? 1.2 : 0.8);
}
flash_power = 1;
if (flash_on) {
    battery -= 0.02 * batt_mult;
    if (battery < 20 && irandom(99) < 10) flash_power = 0.3;
    if (flicker_t > 0 && irandom(2) == 0) flash_power = 0.1;
    if (battery <= 0) {
        battery = 0;
        flash_on = false;
        show_msg("A BATERIA ACABOU! Use [R] se tiver uma reserva.", 180);
    }
}
if (battery < 15 && flash_on && (play_time mod 180) == 0) play_snd(snd_beep, 0.4, 1);

// arma e itens
if (mouse_check_button_pressed(mb_left) || keyboard_check_pressed(vk_space)) fire_gun();
if (keyboard_check_pressed(ord("H"))) use_med();
if (keyboard_check_pressed(ord("Q"))) use_pill();
if (keyboard_check_pressed(ord("R"))) use_bat();

// ============================================================
// ZONAS, PONTOS SEGUROS E SANIDADE
// ============================================================
var _pcc = clamp(floor(player.x / tile), 0, cols - 1);
var _prr = clamp(floor(player.y / tile), 0, rows - 1);
var _bio = biome[_pcc][_prr];
if (_bio >= 4) _bio = 0;
if (_bio != cur_biome) {
    cur_biome = _bio;
    zone_name = biome_names[_bio];
    zone_timer = 220;
    if (!visited_biome[_bio]) {
        visited_biome[_bio] = true;
        pick_upgrades();
        state = STATE_UPGRADE;
        play_snd(snd_whisper, 0.5, 0.8);
    }
}

var _safe_idx = in_safe(player.x, player.y);
if (_safe_idx != check_idx) {
    check_idx = _safe_idx;
    if (_safe_idx != -1) {
        var _sf = safes[_safe_idx];
        check_x = _sf.rx;
        check_y = _sf.ry;
        if (!_sf.visited) {
            _sf.visited = true;
            show_msg("Ponto seguro: " + _sf.name + " (checkpoint salvo)", 220);
            play_snd(snd_heal, 0.5, 1);
        }
    }
}

var _dsan = 0;
if (_safe_idx != -1) {
    _dsan = 0.12;
    player.hp = min(player.hp_max, player.hp + 0.04);
} else {
    if (!flash_on && !lamp_near(player.x, player.y, 110)) _dsan -= 0.035;
    if (blackout > 0) _dsan -= 0.015;
    _dsan -= (panic / 100) * 0.03;
    if (cur_biome == 2) _dsan -= 0.004;
    if (cur_biome == 3) _dsan -= 0.01;
    if (_dsan < 0) _dsan *= sanity_mult;
}
sanity = clamp(sanity + _dsan, 0, 100);
if (sanity <= 0) player.hp = max(0, player.hp - 0.02);

// ---------- chefe: gatilho da arena ----------
if (!boss_started && !boss_dead && player.y > 60 * tile && player.x > 94 * tile && player.x < 121 * tile) {
    boss_started = true;
    start_dialog([
        ["Diretor Voss", "Ana Almeida... você chegou mais longe do que todos os outros."],
        ["Ana", "Onde está o meu irmão?!"],
        ["Diretor Voss", "Aqui. Vivo. Alimentando o Coração com o medo dele... e agora com o seu."],
        ["Diretor Voss", "Eu sou o futuro desta cidade. Venha. Mostre-me o quanto você consegue temer."]
    ], 3);
    exit;
}

// ============================================================
// VISAO E PATHFINDING
// ============================================================
update_visibility();
if ((play_time mod 8) == 0) update_flow();

// ============================================================
// INIMIGOS
// ============================================================
alert_cd = max(0, alert_cd - 1);
var _nearest = 99999;
var _act = 0;
for (var i = array_length(enemies) - 1; i >= 0; i--) {
    var _e = enemies[i];
    var _dist = point_distance(_e.x, _e.y, player.x, player.y);
    if (_dist > 900) continue;
    _act++;
    _nearest = min(_nearest, _dist);
    if (_e.flash > 0) _e.flash--;

    // esta sob a luz da lanterna?
    var _lit = false;
    if (flash_on && _dist < flash_len) {
        var _ad = abs(angle_difference(player.facing_dir, point_direction(player.x, player.y, _e.x, _e.y)));
        if (_ad < flash_angle + 6 && los(player.x, player.y, _e.x, _e.y)) _lit = true;
    }
    var _seen = _lit;
    if (!_seen && mode == 1 && _dist < 320) {
        var _ad2 = abs(angle_difference(player.facing_dir, point_direction(player.x, player.y, _e.x, _e.y)));
        if (_ad2 < fov * 0.55 && los(player.x, player.y, _e.x, _e.y)) _seen = true;
    }
    _e.lit = _lit;

    // ouvir / ver o player
    var _hear = (player.is_running ? 400 : 230) * hear_mult;
    if (alarm_timer > 0) _hear = 99999;
    if (_e.type == 3) _hear = max(_hear, 420);
    var _sees = (_dist < 300 && los(_e.x, _e.y, player.x, player.y));
    if (_safe_idx == -1 && (_sees || _dist < _hear)) {
        _e.lost = 0;
        if (_e.mode == 0) {
            _e.mode = 1;
            if (alert_cd <= 0) {
                alert_cd = 90;
                var _vol = clamp(1.1 - _dist / 600, 0.25, 0.9);
                if (_e.type == 0) play_snd(snd_scare, _vol, random_range(0.8, 1));
                if (_e.type == 1) play_snd(snd_growl, _vol, random_range(1.3, 1.6));
                if (_e.type == 2) play_snd(snd_stone, _vol, 0.8);
                if (_e.type == 3) play_snd(snd_whisper, _vol, random_range(0.8, 1.1));
                add_floater(_e.x, _e.y - 16, "!", c_red);
                if (_dist < 260) shake = max(shake, 5);
            }
        }
    } else if (_e.mode == 1) {
        _e.lost++;
        if (_e.lost > 240 || (_safe_idx != -1 && _e.lost > 60)) _e.mode = 0;
    }

    // velocidade por tipo
    var _sp = _e.spd;
    if (alarm_timer > 0) _sp *= 1.2;
    if (_e.mode == 0) _sp *= 0.5;
    switch (_e.type) {
        case 0:
            _e.lurch--;
            if (_e.lurch <= 0) { _e.lurch = irandom_range(100, 200); _e.lunge = 14; }
            if (_e.lunge > 0) {
                _e.lunge--;
                if (_e.mode == 1) _sp *= 2.4;
            }
            if (_lit) _sp *= 0.55;
            break;
        case 1:
            if (_lit) _sp *= 0.7;
            break;
        case 2:
            if (_seen || _e.mode == 0) _sp = 0;
            break;
        case 3:
            if (_e.mode == 0) _sp *= 1.2;
            break;
    }

    // Sombras morrem na luz e roubam bateria
    if (_e.type == 3) {
        if (_lit) {
            _e.hp -= 0.55;
            _e.flash = 2;
            if (_e.hp <= 0) { kill_enemy(i); continue; }
        }
        if (_dist < 130 && flash_on) battery = max(0, battery - 0.05);
    }

    // movimento
    if (_sp > 0) {
        if (_e.mode == 1) {
            var _tx = player.x;
            var _ty = player.y;
            if (_e.type != 3) {
                if (_sees) {
                    _sp *= 1.1;
                } else {
                    var _ec = clamp(floor(_e.x / tile), 0, cols - 1);
                    var _er = clamp(floor(_e.y / tile), 0, rows - 1);
                    var _bv = flow_val(_ec, _er);
                    if (_bv < 0) _bv = 99999;
                    for (var k = 0; k < 4; k++) {
                        var _nc = _ec + ndx[k];
                        var _nr = _er + ndy[k];
                        if (_nc < 0 || _nr < 0 || _nc >= cols || _nr >= rows) continue;
                        var _fv = flow_val(_nc, _nr);
                        if (_fv >= 0 && _fv < _bv) {
                            _bv = _fv;
                            _tx = _nc * tile + tile / 2;
                            _ty = _nr * tile + tile / 2;
                        }
                    }
                }
            }
            var _dir = point_direction(_e.x, _e.y, _tx, _ty);
            if (_e.type == 1) _dir += sin(_e.anim * 0.35) * 38;
            if (_dist > 6) {
                if (_e.type == 3) {
                    _e.x += lengthdir_x(_sp, _dir);
                    _e.y += lengthdir_y(_sp, _dir);
                } else {
                    move_body(_e, lengthdir_x(_sp, _dir), lengthdir_y(_sp, _dir), _e.rad - 2);
                }
            }
            _e.face = _dir;
        } else {
            var _ox = _e.x;
            var _oy = _e.y;
            _e.wt--;
            if (_e.wt <= 0) {
                _e.wdir += random_range(-70, 70);
                _e.wt = irandom_range(40, 120);
            }
            if (_e.type == 3) {
                _e.x += lengthdir_x(_sp, _e.wdir);
                _e.y += lengthdir_y(_sp, _e.wdir);
            } else {
                move_body(_e, lengthdir_x(_sp, _e.wdir), lengthdir_y(_sp, _e.wdir), _e.rad - 2);
                if (point_distance(_ox, _oy, _e.x, _e.y) < _sp * 0.3) {
                    _e.wdir = random(360);
                    _e.wt = 30;
                }
            }
            _e.face = _e.wdir;
        }
        _e.anim += (_e.type == 1) ? 14 : 8;
    }

    // monstros nao entram nos pontos seguros
    var _si = in_safe(_e.x, _e.y);
    if (_si != -1) {
        var _s2 = safes[_si];
        var _pd = point_direction(_s2.x, _s2.y, _e.x, _e.y);
        move_body(_e, lengthdir_x(2, _pd), lengthdir_y(2, _pd), 8);
    }

    // sons ocasionais
    if (_e.mode == 1 && _dist < 320 && irandom(420) == 0) {
        if (_e.type == 2) play_snd(snd_stone, clamp(1 - _dist / 350, 0.15, 0.7), random_range(0.7, 1));
        else play_snd(snd_growl, clamp(1 - _dist / 350, 0.15, 0.7), random_range(0.8, 1.3));
    }

    // dano por contato
    if (_safe_idx == -1 && _dist < _e.rad + 9) {
        if (_e.type == 0) hurt_player(18, 6);
        if (_e.type == 1) hurt_player(9, 3);
        if (_e.type == 2) hurt_player(32, 10);
        if (_e.type == 3) hurt_player(7, 12);
    }
}
panic = lerp(panic, clamp(100 - _nearest / 3.2, 0, 100), 0.05);

// monstros novos aparecem com o tempo (nao na arena do chefe)
spawn_timer++;
if (spawn_timer >= spawn_interval && !boss_started) {
    spawn_timer = 0;
    spawn_interval = irandom_range(1200, 2000);
    if (_act < 10) {
        var _tt = 0;
        if (cur_biome == 0) _tt = choose(0, 0, 1, 3);
        if (cur_biome == 1) _tt = choose(0, 1, 2, 3);
        if (cur_biome >= 2) _tt = choose(1, 3, 2, 0);
        var _p = pick_spot(cur_biome, player.x, player.y, 420);
        spawn_enemy_at(_tt, _p.x, _p.y);
        play_snd(snd_whisper, 0.3, 0.7);
        show_msg("Algo novo apareceu na escuridão...", 140);
    }
}

// ============================================================
// CHEFE E PROJETEIS
// ============================================================
if (boss != -1) update_boss();

for (var i = array_length(shots) - 1; i >= 0; i--) {
    var _sh = shots[i];
    _sh.x += _sh.vx;
    _sh.y += _sh.vy;
    _sh.life--;
    if (_sh.life <= 0 || solid_at(_sh.x, _sh.y)) {
        array_delete(shots, i, 1);
        continue;
    }
    if (point_distance(_sh.x, _sh.y, player.x, player.y) < 11) {
        hurt_player(_sh.dmg, 4);
        array_delete(shots, i, 1);
    }
}

// ============================================================
// SUSTOS E ALUCINACOES
// ============================================================
scare_cd--;
if (scare_cd <= 0 && !boss_started) {
    trigger_scare();
    scare_cd = irandom_range(1500, 3000);
}
if (sanity < 45 && array_length(hallu) < 3 && irandom(round(200 + sanity * 8)) == 0) spawn_hallu();
for (var i = array_length(hallu) - 1; i >= 0; i--) {
    var _h = hallu[i];
    _h.life--;
    _h.anim += 6;
    var _hd = point_distance(_h.x, _h.y, player.x, player.y);
    if (flash_on && _hd < flash_len) {
        var _had = abs(angle_difference(player.facing_dir, point_direction(player.x, player.y, _h.x, _h.y)));
        if (_had < flash_angle + 6) _h.watch++;
    }
    if (_hd < 70 || _h.watch > 22 || _h.life <= 0) {
        if (_hd < 70 || _h.watch > 22) {
            play_snd(snd_whisper, 0.5, 1.3);
            shake = max(shake, 4);
            flicker_t = 25;
        }
        array_delete(hallu, i, 1);
    }
}
if (foot_scare > 0 && (play_time mod 22) == 0) {
    foot_scare--;
    play_snd(snd_step, 0.5, 0.6);
}
whisper_cd--;
if (whisper_cd <= 0) {
    if (sanity < 40) play_snd(snd_whisper, 0.25 + (40 - sanity) / 120, random_range(0.7, 1.3));
    whisper_cd = irandom_range(300, 700);
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
if ((play_time mod 10) == 0) audio_sound_gain(drone_inst, 0.25 + panic / 100 * 0.5 + ((cur_biome == 3) ? 0.15 : 0), 200);
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
// INTERACAO (tecla E): itens, NPCs, portoes
// ============================================================
nearby_kind = -1;
nearby_idx = -1;
prompt = "";
var _bd = 9999;
for (var i = 0; i < array_length(items); i++) {
    items[i].timer += 3;
    var _dd = point_distance(player.x, player.y, items[i].x, items[i].y);
    if (_dd <= 44 && _dd < _bd) {
        _bd = _dd;
        nearby_kind = 0;
        nearby_idx = i;
    }
}
for (var i = 0; i < array_length(npcs); i++) {
    var _dn = point_distance(player.x, player.y, npcs[i].x, npcs[i].y);
    if (_dn <= 58 && _dn < _bd) {
        _bd = _dn;
        nearby_kind = 1;
        nearby_idx = i;
    }
}
for (var i = 0; i < array_length(gates); i++) {
    var _gg = gates[i];
    if (_gg.open) continue;
    var _dg = point_distance(player.x, player.y, _gg.x, _gg.y);
    if (_dg <= 70 && _dg < _bd) {
        _bd = _dg;
        nearby_kind = 2;
        nearby_idx = i;
    }
}
if (nearby_kind == 0) prompt = item_label(items[nearby_idx]);
if (nearby_kind == 1) prompt = "Falar com " + npcs[nearby_idx].name;
if (nearby_kind == 2) prompt = "Abrir: " + gates[nearby_idx].name;

if (nearby_kind != -1 && keyboard_check_pressed(ord("E"))) {
    if (nearby_kind == 0) pickup_item(nearby_idx);
    else if (nearby_kind == 1) npc_talk(npcs[nearby_idx]);
    else if (nearby_kind == 2) try_open_gate(gates[nearby_idx]);
    nearby_kind = -1;
}

// ============================================================
// PARTICULAS, TEXTOS, POEIRA, TRACOS DE TIRO
// ============================================================
for (var i = array_length(particles) - 1; i >= 0; i--) {
    var _p2 = particles[i];
    _p2.x += _p2.vx;
    _p2.y += _p2.vy;
    _p2.vx *= 0.94;
    _p2.vy *= 0.94;
    _p2.life--;
    if (_p2.life <= 0) array_delete(particles, i, 1);
}
for (var i = array_length(floaters) - 1; i >= 0; i--) {
    var _fl = floaters[i];
    _fl.y -= 0.5;
    _fl.life--;
    if (_fl.life <= 0) array_delete(floaters, i, 1);
}
for (var i = array_length(tracers) - 1; i >= 0; i--) {
    tracers[i].life--;
    if (tracers[i].life <= 0) array_delete(tracers, i, 1);
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

// ---------- MORTE ----------
if (player.hp <= 0) {
    deaths++;
    if (boss_mus_inst != -1) {
        audio_stop_sound(boss_mus_inst);
        boss_mus_inst = -1;
    }
    play_snd(snd_growl, 1, 0.6);
    state = STATE_GAMEOVER;
}


