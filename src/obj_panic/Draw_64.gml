// ============================================================
// PANIC INC. v3 - obj_panic - DRAW GUI (HUD, menus, efeitos)
// ============================================================
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);

// ---------- TITULO ----------
if (state == STATE_TITLE) {
    draw_set_color(make_color_rgb(8, 8, 14));
    fillrect(0, 0, gw, gh);

    // olhos piscando no escuro
    for (var i = 0; i < array_length(title_eyes); i++) {
        var _te = title_eyes[i];
        var _ba = max(0, sin((current_time / 600 + _te.ph) * _te.s));
        if (_ba > 0.2) {
            gpu_set_blendmode(bm_add);
            draw_set_color(c_red);
            draw_set_alpha(0.35 * _ba);
            draw_circle(_te.x - 12, _te.y, 9, false);
            draw_circle(_te.x + 12, _te.y, 9, false);
            gpu_set_blendmode(bm_normal);
            draw_set_alpha(_ba);
            draw_set_color(c_yellow);
            draw_circle(_te.x - 12, _te.y, 3, false);
            draw_circle(_te.x + 12, _te.y, 3, false);
        }
    }
    draw_set_alpha(1);

    // Cartao central usa escalas conservadoras para nao cortar texto em janelas menores.
    draw_set_halign(fa_center);
    var _gl = ((current_time mod 1800) < 70) ? irandom_range(-3, 3) : 0;
    var _title_scale = min(5.0, gw / 250);
    gtext(gw / 2 + _gl + 2, 92, "PANIC INC.", _title_scale, make_color_rgb(90, 0, 0));
    gtext(gw / 2 + _gl, 92, "PANIC INC.", _title_scale, c_red);
    draw_set_color(make_color_rgb(24, 27, 40));
    draw_roundrect(gw * 0.12, 205, gw * 0.88, 520, false);
    draw_set_color(make_color_rgb(65, 76, 96));
    draw_roundrect(gw * 0.12, 205, gw * 0.88, 520, true);
    gtext(gw / 2, 226, "CADA CONTRATO MUDA: ARQUIVOS, GERADORES OU ANOMALIAS.", 1.35, c_white);
    gtext(gw / 2, 286, "WASD: explorar     SHIFT: correr     MOUSE: olhar para os lados e para cima/baixo", 1.1, c_ltgray);
    gtext(gw / 2, 322, "E: coletar     F: lanterna     Q: sinalizador (atordoa monstros)", 1.1, c_aqua);
    gtext(gw / 2, 358, "TAB: alternar 2D/3D     M: som     ESC: pausar", 1.1, c_ltgray);
    gtext(gw / 2, 398, "Salas podem ter emboscadas, apagao, caches ou apenas silencio.", 1.05, c_orange);
    gtext(gw / 2, 426, "O VIGIA aprende sua rota. A lanterna nao o detem.", 1.05, c_red);
    gtext(gw / 2, 570, "[ ENTER ]  INICIAR TURNO", 2.0 + sin(current_time / 200) * 0.12, c_yellow);
    if (best_pontos > 0) gtext(gw / 2, 630, "RECORDE: " + string(best_pontos) + "   |   MELHOR FASE: " + string(best_level), 1.2, c_aqua);
    draw_set_halign(fa_left);
    exit;
}

// ---------- VINHETA ESCURA + PANICO ----------
var _vin = 0.45 + (blackout > 0 ? 0.25 : 0);
draw_set_color(c_black);
for (var i = 0; i < 14; i++) {
    draw_set_alpha(_vin * (1 - i / 14) * 0.7);
    fillrect(0, i * 12, gw, i * 12 + 12);
    fillrect(0, gh - i * 12 - 12, gw, gh - i * 12);
    fillrect(i * 12, 0, i * 12 + 12, gh);
    fillrect(gw - i * 12 - 12, 0, gw - i * 12, gh);
}
var _pv = max(panic / 100 * 0.55, hurt_flash * 0.6, heart_pulse * panic / 100 * 0.45);
if (_pv > 0.02) {
    draw_set_color(c_red);
    for (var i = 0; i < 12; i++) {
        draw_set_alpha(_pv * (1 - i / 12) * 0.5);
        fillrect(0, i * 12, gw, i * 12 + 12);
        fillrect(0, gh - i * 12 - 12, gw, gh - i * 12);
        fillrect(i * 12, 0, i * 12 + 12, gh);
        fillrect(gw - i * 12 - 12, 0, gw - i * 12, gh);
    }
}
// alarme pulsando em vermelho
if (alarm_on) {
    draw_set_color(c_red);
    draw_set_alpha(0.07 + 0.07 * sin(current_time / 140));
    fillrect(0, 0, gw, gh);
}
draw_set_alpha(1);

// Aparicao curta do Vigia: rosto no centro, som e camera shake fazem o susto ter leitura clara.
if (jumpscare > 0) {
    var _ja = clamp(jumpscare / 18, 0, 1);
    draw_set_color(c_maroon);
    draw_set_alpha(_ja * 0.28);
    fillrect(0, 0, gw, gh);
    draw_set_color(c_black);
    draw_set_alpha(_ja);
    draw_ellipse(gw * 0.5 - 175, gh * 0.5 - 205, gw * 0.5 + 175, gh * 0.5 + 210, false);
    draw_set_color(c_red);
    draw_ellipse(gw * 0.5 - 105, gh * 0.5 - 65, gw * 0.5 - 28, gh * 0.5 - 25, false);
    draw_ellipse(gw * 0.5 + 28, gh * 0.5 - 65, gw * 0.5 + 105, gh * 0.5 - 25, false);
    draw_set_color(c_white);
    draw_ellipse(gw * 0.5 - 78, gh * 0.5 - 58, gw * 0.5 - 48, gh * 0.5 - 32, false);
    draw_ellipse(gw * 0.5 + 48, gh * 0.5 - 58, gw * 0.5 + 78, gh * 0.5 - 32, false);
    draw_set_color(c_black);
    draw_triangle(gw * 0.5 - 72, gh * 0.5 + 45, gw * 0.5 + 72, gh * 0.5 + 45, gw * 0.5, gh * 0.5 + 150, false);
    draw_set_alpha(1);
}

// ---------- BARRAS ----------
var _bw = 260;
draw_set_color(c_black);
fillrect(22, 22, 26 + _bw, 44);
fillrect(22, 48, 26 + _bw, 64);
fillrect(22, 68, 26 + _bw, 84);
draw_set_color(c_dkgray);
fillrect(24, 24, 24 + _bw, 42);
fillrect(24, 50, 24 + _bw, 62);
fillrect(24, 70, 24 + _bw, 82);
draw_set_color(player.hp < 30 && (current_time div 200) mod 2 == 0 ? c_white : c_red);
fillrect(24, 24, 24 + _bw * clamp(player.hp / player.hp_max, 0, 1), 42);
draw_set_color(player.exhausted ? c_gray : c_lime);
fillrect(24, 50, 24 + _bw * clamp(player.stamina / player.stamina_max, 0, 1), 62);
draw_set_color(battery < 20 ? c_orange : c_yellow);
fillrect(24, 70, 24 + _bw * clamp(battery / 100, 0, 1), 82);
draw_set_color(c_white);
draw_text(24 + _bw + 10, 24, "VIDA " + string(ceil(player.hp)));
draw_text(24 + _bw + 10, 48, "STAMINA");
draw_text(24 + _bw + 10, 68, "BATERIA " + (flash_on ? "(ON)" : "(OFF)"));

gtext(24, 96, objective_names[mission_type] + ": " + string(docs_got) + " / " + string(docs_total), 1.25, c_yellow);
gtext(24, 124, "PONTOS: " + string(pontos), 1.2, c_white);
gtext(24, 198, "SINALIZADORES [Q]: " + string(flare_charges), 1.05, c_aqua);
gtext(24, 222, "NIVEL DE CAMPO " + string(player.rank) + "  XP " + string(player.xp) + "/" + string(player.xp_next), 1.0, c_aqua);
gtext(24, 246, structure_names[current_zone.kind] + "  |  RISCO " + string(ceil(current_zone.danger * 100)) + "%", 1.0,
      current_zone.danger > 0.7 ? c_red : c_ltgray);
if (combo > 1) {
    gtext(24, 148, "COMBO x" + string(combo), 1.4, c_orange);
    draw_set_color(c_dkgray);
    fillrect(24, 174, 164, 180);
    draw_set_color(c_orange);
    fillrect(24, 174, 24 + 140 * (combo_timer / (60 * 18)), 180);
}

var _secs = floor(level_time / 60);
var _tm = string(_secs div 60) + ":" + string_replace_all(string_format(_secs mod 60, 2, 0), " ", "0");
draw_set_halign(fa_center);
gtext(gw / 2, 16, "FASE " + string(level) + "   |   TEMPO " + _tm, 1.3, c_white);
if (alarm_on && (current_time div 300) mod 2 == 0) gtext(gw / 2, 44, "!!! ALARME !!!", 1.6, c_red);

// ---------- MINIMAPA ----------
// Mantem o minimapa inteiro dentro do HUD mesmo quando os complexos crescem.
var _ms = max(1, min(3, floor((gh - 40) / rows), floor((gw * 0.22) / cols)));
var _mmx = gw - cols * _ms - 16;
var _mmy = 16;
draw_set_color(c_black);
draw_set_alpha(0.65);
fillrect(_mmx - 4, _mmy - 4, _mmx + cols * _ms + 4, _mmy + rows * _ms + 4);
draw_set_alpha(1);
for (var c = 0; c < cols; c++) {
    for (var r = 0; r < rows; r++) {
        if (explored[c][r]) {
            draw_set_color(grid[c][r] == 1 ? make_color_rgb(90, 95, 125) : make_color_rgb(40, 42, 55));
            fillrect(_mmx + c * _ms, _mmy + r * _ms, _mmx + c * _ms + _ms, _mmy + r * _ms + _ms);
        }
    }
}
if (explored[exit_c][exit_r]) {
    draw_set_color(exit_open ? c_lime : c_maroon);
    fillrect(_mmx + exit_c * _ms - 1, _mmy + exit_r * _ms - 1, _mmx + exit_c * _ms + _ms + 1, _mmy + exit_r * _ms + _ms + 1);
}
draw_set_color(c_yellow);
for (var i = 0; i < array_length(items); i++) {
    var _mi = items[i];
    if (_mi.type == ((mission_type == 0) ? 0 : ((mission_type == 1) ? 3 : 4))
        && explored[floor(_mi.x / tile)][floor(_mi.y / tile)]) {
        fillrect(_mmx + _mi.x / tile * _ms - 1, _mmy + _mi.y / tile * _ms - 1,
                 _mmx + _mi.x / tile * _ms + 2, _mmy + _mi.y / tile * _ms + 2);
    }
}
draw_set_color(c_red);
for (var i = 0; i < array_length(enemies); i++) {
    var _me = enemies[i];
    if (point_distance(_me.x, _me.y, player.x, player.y) < 170) {
        fillrect(_mmx + _me.x / tile * _ms - 1, _mmy + _me.y / tile * _ms - 1,
                 _mmx + _me.x / tile * _ms + 2, _mmy + _me.y / tile * _ms + 2);
    }
}
draw_set_color(c_aqua);
fillrect(_mmx + player.x / tile * _ms - 1.5, _mmy + player.y / tile * _ms - 1.5,
         _mmx + player.x / tile * _ms + 2, _mmy + player.y / tile * _ms + 2);

// ---------- MIRA E INDICADORES DE PERIGO (3D) ----------
if (mode == 1) {
    draw_set_color(c_white);
    draw_set_alpha(0.7);
    fillrect(gw / 2 - 2, gh / 2 - 2, gw / 2 + 2, gh / 2 + 2);
    draw_set_alpha(1);

    var _rvx = lengthdir_x(1, player.facing_dir - 90);
    var _rvy = lengthdir_y(1, player.facing_dir - 90);
    for (var i = 0; i < array_length(enemies); i++) {
        var _en = enemies[i];
        if (_en.mode != 1) continue;
        var _ed = point_distance(_en.x, _en.y, player.x, player.y);
        if (_ed > 280) continue;
        var _ang = abs(angle_difference(player.facing_dir, point_direction(player.x, player.y, _en.x, _en.y)));
        if (_ang < 50) continue;
        var _dot = (_en.x - player.x) * _rvx + (_en.y - player.y) * _rvy;
        var _sx = (_dot > 0) ? gw - 50 : 50;
        var _dir = (_dot > 0) ? -1 : 1;
        var _al = clamp(1 - _ed / 280, 0.25, 1) * (0.6 + 0.4 * sin(current_time / 100));
        draw_set_alpha(_al);
        draw_set_color(c_red);
        draw_triangle(_sx, gh / 2 - 30, _sx, gh / 2 + 30, _sx + _dir * 36, gh / 2, false);
    }
    draw_set_alpha(1);
}

// ---------- DICAS ----------
if (nearby_item != -1) {
    gtext(gw / 2, gh - 130, "[E] Pegar " + item_names[items[nearby_item].type], 1.6, c_yellow);
}
if (!exit_open && point_distance(player.x, player.y, exit_c * tile + 16, exit_r * tile + 16) < 60) {
    gtext(gw / 2, gh - 100, "SAIDA TRANCADA - conclua: " + objective_names[mission_type], 1.3, c_orange);
}
else if (exit_open && point_distance(player.x, player.y, exit_c * tile + 16, exit_r * tile + 16) < 60) {
    gtext(gw / 2, gh - 100, "[E] EXTRAIR   |   voce pode explorar antes de sair", 1.3, c_lime);
}
if (msg_timer > 0) gtext(gw / 2, 110, msg, 1.5, c_white);

draw_set_halign(fa_left);
gtext(24, gh - 30, "TAB: modo " + (mode == 0 ? "2D" : "3D") + "   |   F: lanterna   |   MOUSE: camera 3D   |   M: som " + (sfx_on ? "ON" : "OFF") + "   |   ESC: pausa", 1, c_ltgray);

// ---------- FADE ----------
if (fade > 0) {
    draw_set_color(c_black);
    draw_set_alpha(fade);
    fillrect(0, 0, gw, gh);
    draw_set_alpha(1);
}

// ---------- TELAS DE ESTADO ----------
draw_set_halign(fa_center);
if (state == STATE_PAUSED) {
    draw_set_color(c_black); draw_set_alpha(0.6);
    fillrect(0, 0, gw, gh);
    draw_set_alpha(1);
    gtext(gw / 2, gh / 2 - 40, "PAUSADO", 4, c_white);
    gtext(gw / 2, gh / 2 + 30, "ESC para continuar", 1.5, c_ltgray);
}
else if (state == STATE_GAMEOVER) {
    draw_set_color(c_black); draw_set_alpha(0.78);
    fillrect(0, 0, gw, gh);
    draw_set_alpha(1);
    var _gj = ((current_time mod 1800) < 80) ? irandom_range(-5, 5) : 0;
    gtext(gw / 2 + _gj, gh / 2 - 100, "VOCE FOI PEGO", 5, c_red);
    gtext(gw / 2, gh / 2 - 10, "Fase " + string(level) + "   |   Pontos: " + string(pontos) + "   |   Recorde: " + string(best_pontos), 1.6, c_white);
    gtext(gw / 2, gh / 2 + 60, "[ R ] Tentar de novo", 2, c_yellow);
}
else if (state == STATE_LEVELDONE) {
    draw_set_color(c_black); draw_set_alpha(0.8);
    fillrect(0, 0, gw, gh);
    draw_set_alpha(1);
    gtext(gw / 2, gh / 2 - 250, "VOCE ESCAPOU!", 4.5, c_lime);
    gtext(gw / 2, gh / 2 - 160, "Bonus de tempo: +" + string(last_bonus) + "   |   Pontos: " + string(pontos), 1.6, c_white);
    gtext(gw / 2, gh / 2 - 100, "ESCOLHA UMA MELHORIA (1, 2 ou 3):", 1.6, c_yellow);
    for (var i = 0; i < 3; i++) {
        var _cxm = gw / 2 + (i - 1) * 340;
        var _top = gh / 2 - 50;
        draw_set_color(make_color_rgb(20, 22, 34));
        fillrect(_cxm - 150, _top, _cxm + 150, _top + 210);
        draw_set_color(c_yellow);
        draw_rectangle(_cxm - 150, _top, _cxm + 150, _top + 210, true);
        var _u = upg_defs[upg_choice[i]];
        gtext(_cxm, _top + 14, "[" + string(i + 1) + "]", 2.2, c_yellow);
        gtext(_cxm, _top + 80, _u.name, 1.3, c_white);
        draw_set_color(c_ltgray);
        draw_text_ext(_cxm, _top + 125, _u.desc, 22, 260);
    }
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);

