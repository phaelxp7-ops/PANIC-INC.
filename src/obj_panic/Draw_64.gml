// PANIC INC. v4 - interface, narrativa e menus
draw_set_font(fnt_main);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);

// Tela inicial cinematografica.
if (state == STATE_TITLE) {
    draw_set_color(make_color_rgb(4, 5, 10)); fillrect(0, 0, gw, gh);
    for (var i = 0; i < array_length(title_eyes); i++) {
        var _eye = title_eyes[i];
        var _blink = max(0, sin((current_time / 600 + _eye.ph) * _eye.s));
        if (_blink > 0.18) {
            gpu_set_blendmode(bm_add); draw_set_alpha(0.28 * _blink); draw_set_color(c_red);
            draw_circle(_eye.x - 10, _eye.y, 7, false); draw_circle(_eye.x + 10, _eye.y, 7, false);
            draw_set_alpha(_blink); draw_set_color(make_color_rgb(255, 225, 150));
            draw_circle(_eye.x - 10, _eye.y, 2, false); draw_circle(_eye.x + 10, _eye.y, 2, false);
            gpu_set_blendmode(bm_normal); draw_set_alpha(1);
        }
    }
    draw_set_halign(fa_center);
    var _glitch = ((current_time mod 2400) < 45) ? irandom_range(-5, 5) : 0;
    gtext(gw / 2 + _glitch, 105, "PANIC INC.", 5.2, make_color_rgb(175, 18, 28));
    gtext(gw / 2, 208, "O CORAÇÃO DO MEDO", 1.8, c_ltgray);
    draw_set_color(make_color_rgb(14, 18, 26)); draw_roundrect(gw * 0.2, 270, gw * 0.8, 490, false);
    draw_set_color(make_color_rgb(63, 68, 81)); draw_roundrect(gw * 0.2, 270, gw * 0.8, 490, true);
    gtext(gw / 2, 298, "UM RPG DE SOBREVIVÊNCIA E TERROR", 1.25, c_aqua);
    gtext(gw / 2, 346, "Explore Vale Sombrio. Encontre seu irmão.", 1.15, c_white);
    gtext(gw / 2, 375, "Não confie no que você vê quando a sanidade cai.", 1.05, c_ltgray);
    gtext(gw / 2, 550, "[ ENTER ]  COMEÇAR HISTÓRIA", 1.7 + 0.08 * sin(current_time / 180), c_yellow);
    gtext(gw / 2, 604, "WASD mover | SHIFT correr | F lanterna | E interagir | TAB 2D/3D", 0.95, c_ltgray);
    gtext(gw / 2, 632, "H cura | Q calmante | R bateria | J diário | M mapa | N som", 0.95, c_ltgray);
    if (endings_seen > 0) gtext(gw / 2, 670, "Finais descobertos: " + string(endings_seen) + "  |  Melhor tempo: " + string(best_time) + "s", 0.9, c_aqua);
    draw_set_halign(fa_left);
    exit;
}

// Historia de abertura e dialogos com texto gradualmente revelado.
if (state == STATE_INTRO) {
    draw_set_color(c_black); draw_set_alpha(1); fillrect(0, 0, gw, gh); draw_set_alpha(1);
    draw_set_halign(fa_center);
    gtext(gw / 2, 120, "VALE SOMBRIO", 2.0, c_red);
    draw_set_halign(fa_left);
    var _intro = intro_pages[intro_i];
    var _intro_len = clamp(floor(intro_t), 0, string_length(_intro));
    draw_set_color(c_white); draw_text_ext(170, 270, string_copy(_intro, 1, _intro_len), -1, gw - 340);
    draw_set_halign(fa_center);
    gtext(gw / 2, gh - 100, "[ E / ENTER ] continuar", 1.2, c_yellow);
    draw_set_halign(fa_left);
    exit;
}

if (state == STATE_DIALOG) {
    draw_set_color(c_black); draw_set_alpha(1); fillrect(0, 0, gw, gh); draw_set_alpha(1);
    var _line = dlg_lines[dlg_i];
    draw_set_color(make_color_rgb(13, 17, 25)); draw_roundrect(90, gh - 235, gw - 90, gh - 48, false);
    draw_set_color(make_color_rgb(100, 112, 130)); draw_roundrect(90, gh - 235, gw - 90, gh - 48, true);
    draw_set_halign(fa_left);
    gtext(125, gh - 210, _line[0], 1.5, c_aqua);
    var _dialog_len = clamp(floor(dlg_t), 0, string_length(_line[1]));
    draw_set_color(c_white); draw_text_ext(125, gh - 165, string_copy(_line[1], 1, _dialog_len), -1, gw - 250);
    draw_set_halign(fa_right);
    gtext(gw - 125, gh - 82, "[ E / ENTER ]", 1, c_yellow);
    draw_set_halign(fa_left);
    exit;
}

if (state == STATE_READ) {
    draw_set_color(c_black); draw_set_alpha(1); fillrect(0, 0, gw, gh); draw_set_alpha(1);
    var _note = notes_data[read_note];
    draw_set_color(make_color_rgb(28, 27, 24)); draw_roundrect(150, 80, gw - 150, gh - 80, false);
    draw_set_color(make_color_rgb(155, 132, 92)); draw_roundrect(150, 80, gw - 150, gh - 80, true);
    draw_set_halign(fa_center); gtext(gw / 2, 112, _note.title, 1.8, c_yellow); draw_set_halign(fa_left);
    draw_set_halign(fa_left);
    draw_set_color(make_color_rgb(224, 218, 196)); draw_text_ext(205, 180, _note.text, -1, gw - 410);
    draw_set_halign(fa_center); gtext(gw / 2, gh - 120, "[ E ] guardar no diário e continuar", 1.1, c_ltgray);
    draw_set_halign(fa_left);
    exit;
}

// Selecao de melhoria entre capitulos.
if (state == STATE_UPGRADE) {
    draw_set_color(c_black); draw_set_alpha(1); fillrect(0, 0, gw, gh); draw_set_alpha(1);
    draw_set_halign(fa_center); gtext(gw / 2, 70, "VOCÊ SOBREVIVEU À NOITE", 2.3, c_aqua);
    gtext(gw / 2, 125, "Escolha uma habilidade permanente", 1.2, c_white);
    for (var i = 0; i < 3; i++) {
        var _ux = 115 + i * 355;
        draw_set_color(make_color_rgb(20, 26, 37)); draw_roundrect(_ux, 220, _ux + 300, 485, false);
        draw_set_color(make_color_rgb(75, 103, 125)); draw_roundrect(_ux, 220, _ux + 300, 485, true);
        gtext(_ux + 150, 255, "[ " + string(i + 1) + " ]", 1.4, c_yellow);
        gtext(_ux + 150, 315, upg_defs[upg_choice[i]].name, 1.25, c_aqua);
        draw_set_halign(fa_center);
        draw_set_color(c_ltgray); draw_text_ext(_ux + 150, 370, upg_defs[upg_choice[i]].desc, -1, 256);
    }
    draw_set_halign(fa_left);
    exit;
}

if (state == STATE_ENDCHOICE) {
    draw_set_color(c_black); draw_set_alpha(1); fillrect(0, 0, gw, gh); draw_set_alpha(1);
    draw_set_halign(fa_center); gtext(gw / 2, 105, "O CORAÇÃO AINDA PULSA", 2.2, c_red);
    gtext(gw / 2, 185, "Lucas espera sua decisão. O que você faz?", 1.25, c_white);
    draw_set_color(make_color_rgb(20, 22, 30)); draw_roundrect(130, 275, 610, 475, false); draw_roundrect(130, 275, 610, 475, true);
    draw_set_color(make_color_rgb(20, 22, 30)); draw_roundrect(670, 275, 1150, 475, false); draw_roundrect(670, 275, 1150, 475, true);
    gtext(370, 315, "[ 1 ] DESLIGAR", 1.45, c_aqua);
    gtext(370, 370, "Acabar com o Coração e libertar", 0.95, c_ltgray); gtext(370, 394, "as pessoas presas nele.", 0.95, c_ltgray);
    gtext(910, 315, "[ 2 ] SALVAR LUCAS", 1.45, c_yellow);
    gtext(910, 370, "Fugir com seu irmão, mas deixar", 0.95, c_ltgray); gtext(910, 394, "o mal vivo sob a cidade.", 0.95, c_ltgray);
    draw_set_halign(fa_left);
    exit;
}

if (state == STATE_ENDING) {
    draw_set_color(c_black); draw_set_alpha(1); fillrect(0, 0, gw, gh); draw_set_alpha(1);
    draw_set_halign(fa_center); gtext(gw / 2, 82, "PANIC INC.", 2.2, c_red); draw_set_halign(fa_left);
    var _end_len = clamp(floor(end_t), 0, string_length(end_text));
    draw_set_halign(fa_left);
    draw_set_color(c_white); draw_text_ext(180, 190, string_copy(end_text, 1, _end_len), -1, gw - 360);
    if (_end_len >= string_length(end_text)) { draw_set_halign(fa_center); gtext(gw / 2, gh - 85, "[ ENTER ] voltar ao inicio", 1.1, c_yellow); draw_set_halign(fa_left); }
    exit;
}

if (state == STATE_GAMEOVER) {
    draw_set_color(c_black); draw_set_alpha(1); fillrect(0, 0, gw, gh); draw_set_alpha(1);
    draw_set_halign(fa_center); gtext(gw / 2, 170, "A ESCURIDÃO TE ENCONTROU", 2.5, c_red);
    gtext(gw / 2, 255, "Pontos: " + string(kills) + " inimigos derrotados", 1.2, c_white);
    gtext(gw / 2, 300, "[ R ] tentar novamente no ultimo ponto seguro", 1.1, c_yellow);
    draw_set_halign(fa_left);
    exit;
}

// HUD persistente da campanha.
var _pad = 22;
var _barw = 230;
draw_set_alpha(0.72); draw_set_color(c_black); fillrect(_pad - 8, _pad - 8, _pad + 325, 142); draw_set_alpha(1);
gtext(_pad, _pad, "VIDA", 0.9, c_white);
draw_set_color(make_color_rgb(48, 19, 24)); fillrect(_pad, _pad + 22, _pad + _barw, _pad + 34);
draw_set_color(player.hp < 30 ? c_red : make_color_rgb(180, 42, 48)); fillrect(_pad, _pad + 22, _pad + _barw * clamp(player.hp / player.hp_max, 0, 1), _pad + 34);
gtext(_pad + _barw + 10, _pad + 17, string(ceil(player.hp)) + "/" + string(player.hp_max), 0.8, c_white);
gtext(_pad, _pad + 43, "FOLEGO", 0.8, c_white);
draw_set_color(make_color_rgb(18, 43, 29)); fillrect(_pad, _pad + 64, _pad + _barw, _pad + 76);
draw_set_color(player.exhausted ? c_gray : c_lime); fillrect(_pad, _pad + 64, _pad + _barw * clamp(player.stamina / player.stamina_max, 0, 1), _pad + 76);
gtext(_pad, _pad + 85, "LANTERNA", 0.8, c_white);
draw_set_color(make_color_rgb(48, 42, 16)); fillrect(_pad, _pad + 106, _pad + _barw, _pad + 118);
draw_set_color(battery < 20 ? c_orange : c_yellow); fillrect(_pad, _pad + 106, _pad + _barw * clamp(battery / 100, 0, 1), _pad + 118);
gtext(_pad + _barw + 10, _pad + 101, flash_on ? "ON" : "OFF", 0.8, flash_on ? c_yellow : c_gray);

draw_set_alpha(0.68); draw_set_color(c_black); fillrect(gw - 340, 16, gw - 16, 122); draw_set_alpha(1);
draw_set_halign(fa_right);
gtext(gw - 28, 24, zone_name, 0.9, c_aqua);
gtext(gw - 28, 50, get_objective(), 0.82, c_white);
gtext(gw - 28, 77, "Sanidade " + string(floor(sanity)) + "%  |  " + (cur_biome == 0 ? "MATA" : (cur_biome == 1 ? "CIDADE" : (cur_biome == 2 ? "COMPLEXO" : "SUBSOLO"))), 0.8, sanity < 30 ? c_red : c_ltgray);
gtext(gw - 28, 101, "H " + string(meds) + " kits   Q " + string(pills) + " calmantes   R " + string(bats) + " baterias   Balas " + string(ammo), 0.72, c_ltgray);
draw_set_halign(fa_left);

// Minimapa apenas revela areas exploradas, sem denunciar inimigos distantes.
var _ms = 2;
var _mapw = cols * _ms; var _maph = rows * _ms;
var _mapx = gw - _mapw - 22; var _mapy = gh - _maph - 70;
draw_set_color(c_black); draw_set_alpha(0.72); fillrect(_mapx - 5, _mapy - 5, _mapx + _mapw + 5, _mapy + _maph + 5); draw_set_alpha(1);
for (var c = 0; c < cols; c++) {
    for (var r = 0; r < rows; r++) {
        if (!explored[c][r]) continue;
        draw_set_color(grid[c][r] >= 1 ? make_color_rgb(96, 103, 122) : make_color_rgb(47, 54, 65));
        fillrect(_mapx + c * _ms, _mapy + r * _ms, _mapx + (c + 1) * _ms, _mapy + (r + 1) * _ms);
    }
}
draw_set_color(c_aqua); draw_circle(_mapx + player.x / tile * _ms, _mapy + player.y / tile * _ms, 3, false);
if (boss_dead) { draw_set_color(c_lime); draw_circle(_mapx + 107 * _ms, _mapy + 75 * _ms, 2, false); }

// Relogio, chefe e sinais de perigo.
var _seconds = floor(play_time / 60);
var _clock = string(_seconds div 60) + ":" + string_format(_seconds mod 60, 2, 0);
draw_set_halign(fa_center); gtext(gw / 2, 20, "VALE SOMBRIO  |  " + _clock, 1.0, c_white);
if (alarm_timer > 0) gtext(gw / 2, 48, "ALARME - OS ESVAZIADOS OUVIRAM VOCÊ", 1.1, c_red);
if (boss != -1) {
    var _bossw = 440;
    draw_set_color(make_color_rgb(40, 10, 17)); fillrect(gw / 2 - _bossw / 2, 76, gw / 2 + _bossw / 2, 91);
    draw_set_color(c_red); fillrect(gw / 2 - _bossw / 2, 76, gw / 2 - _bossw / 2 + _bossw * clamp(boss.hp / boss.hpmax, 0, 1), 91);
    gtext(gw / 2, 99, "O DIRETOR  |  FASE " + string(boss.phase), 0.95, c_white);
}
if (mode == 1 && state == STATE_PLAYING) {
    draw_set_color(c_white); draw_set_alpha(0.8);
    fillrect(gw / 2 - 1, gh / 2 - 8, gw / 2 + 1, gh / 2 + 8);
    fillrect(gw / 2 - 8, gh / 2 - 1, gw / 2 + 8, gh / 2 + 1);
    draw_set_alpha(1);
}

if (nearby_kind != -1 && state == STATE_PLAYING) {
    draw_set_color(c_black); draw_set_alpha(0.76); draw_roundrect(gw / 2 - 260, gh - 112, gw / 2 + 260, gh - 60, false); draw_set_alpha(1);
    draw_set_halign(fa_center); gtext(gw / 2, gh - 99, "[ E ]  " + prompt, 1.15, c_yellow);
}
if (msg_timer > 0 && state == STATE_PLAYING) {
    draw_set_color(c_black); draw_set_alpha(0.72); draw_roundrect(gw * 0.2, gh * 0.21, gw * 0.8, gh * 0.21 + 42, false); draw_set_alpha(1);
    draw_set_halign(fa_center); gtext(gw / 2, gh * 0.21 + 10, msg, 0.95, c_white);
}
if (zone_timer > 0 && state == STATE_PLAYING) { draw_set_halign(fa_center); gtext(gw / 2, gh * 0.15, zone_name, 1.25, c_aqua); }

draw_set_halign(fa_left);
gtext(20, gh - 28, "TAB modo " + (mode == 0 ? "2D" : "3D") + "  |  F lanterna  |  H cura  |  Q sanidade  |  R bateria  |  J diário  |  M mapa  |  N som  |  ESC pausa", 0.78, c_ltgray);

// Efeitos de terror em primeira pessoa: vignette, desfoque simulado e interferencia.
var _vignette = clamp((100 - sanity) / 150 + panic / 240 + hurt_flash * 0.35, 0, 0.72);
if (_vignette > 0.02) {
    draw_set_color(make_color_rgb(22, 0, 8));
    for (var i = 0; i < 12; i++) {
        draw_set_alpha(_vignette * (1 - i / 12) * 0.42);
        fillrect(0, i * 12, gw, i * 12 + 12); fillrect(0, gh - i * 12 - 12, gw, gh - i * 12);
        fillrect(i * 12, 0, i * 12 + 12, gh); fillrect(gw - i * 12 - 12, 0, gw - i * 12, gh);
    }
    draw_set_alpha(1);
}
if (blackout > 0) { draw_set_color(c_black); draw_set_alpha(0.24); fillrect(0, 0, gw, gh); draw_set_alpha(1); }
if (panic > 78 && (current_time mod 400) < 45) { draw_set_color(c_red); draw_set_alpha(0.08); fillrect(0, 0, gw, gh); draw_set_alpha(1); }

if (state == STATE_PAUSED || state == STATE_JOURNAL || state == STATE_MAP) {
    // Menus sem transparência de HUD por baixo: impede textos e barras duplicadas.
    draw_set_color(make_color_rgb(5, 7, 11)); draw_set_alpha(0.98); fillrect(0, 0, gw, gh); draw_set_alpha(1);
    draw_set_halign(fa_center);
    if (state == STATE_PAUSED) {
        gtext(gw / 2, 190, "PAUSADO", 2.8, c_white);
        gtext(gw / 2, 265, "ESC continuar  |  TAB trocar câmera  |  J diário  |  M mapa", 1.05, c_ltgray);
        gtext(gw / 2, 315, "Contrato atual: " + get_objective(), 0.9, c_aqua);
    } else if (state == STATE_JOURNAL) {
        gtext(gw / 2, 42, "DIÁRIO DE ANA", 2, c_yellow);
        var _found = array_length(notes_found);
        var _panel_x = 48;
        var _panel_y = 104;
        var _panel_w = gw - 96;
        var _panel_h = gh - 188;
        var _list_w = clamp(_panel_w * 0.33, 300, 360);
        var _detail_x = _panel_x + _list_w + 18;
        var _detail_w = _panel_w - _list_w - 18;

        draw_set_color(make_color_rgb(18, 23, 31));
        fillrect(_panel_x, _panel_y, _panel_x + _panel_w, _panel_y + _panel_h);
        draw_set_color(make_color_rgb(65, 83, 98));
        draw_rectangle(_panel_x, _panel_y, _panel_x + _panel_w, _panel_y + _panel_h, true);
        draw_set_color(make_color_rgb(27, 35, 45));
        fillrect(_panel_x + 12, _panel_y + 12, _panel_x + _list_w, _panel_y + _panel_h - 12);
        fillrect(_detail_x, _panel_y + 12, _panel_x + _panel_w - 12, _panel_y + _panel_h - 12);

        draw_set_halign(fa_left);
        draw_set_color(c_aqua); draw_text(_panel_x + 24, _panel_y + 22, "REGISTROS ENCONTRADOS");
        draw_set_color(make_color_rgb(60, 72, 83));
        fillrect(_panel_x + 24, _panel_y + 49, _panel_x + _list_w - 12, _panel_y + 51);
        var _journal_y = _panel_y + 62;
        for (var i = 0; i < _found; i++) {
            var _nid = notes_found[i];
            if (_nid < 0 || _nid >= array_length(notes_data)) continue;
            var _row_y = _journal_y + i * 27;
            if (_row_y > _panel_y + _panel_h - 46) break;
            if (i == jr_sel) {
                draw_set_color(make_color_rgb(26, 62, 74));
                fillrect(_panel_x + 18, _row_y - 3, _panel_x + _list_w - 18, _row_y + 22);
            }
            draw_set_halign(fa_left);
            draw_set_color(i == jr_sel ? c_aqua : c_ltgray);
            draw_text(_panel_x + 25, _row_y, (i == jr_sel ? "> " : "  ") + notes_data[_nid].title);
        }
        if (_found > 0 && jr_sel >= 0 && jr_sel < _found && notes_found[jr_sel] >= 0 && notes_found[jr_sel] < array_length(notes_data)) {
            var _selected = notes_found[jr_sel];
            draw_set_halign(fa_left);
            gtext(_detail_x + 24, _panel_y + 24, notes_data[_selected].title, 1.35, c_yellow);
            draw_set_color(make_color_rgb(74, 92, 104));
            fillrect(_detail_x + 24, _panel_y + 58, _panel_x + _panel_w - 36, _panel_y + 60);
            draw_set_color(make_color_rgb(229, 229, 219));
            draw_text_ext(_detail_x + 24, _panel_y + 80, notes_data[_selected].text, -1, _detail_w - 48);
        } else {
            draw_set_halign(fa_center);
            gtext(_detail_x + _detail_w / 2, _panel_y + 90, "Nenhum registro encontrado ainda.", 1.05, c_ltgray);
        }
        draw_set_halign(fa_center);
        gtext(gw / 2, gh - 70, "W/S selecionar  |  J ou ESC voltar", 1, c_ltgray);
    } else {
        gtext(gw / 2, 28, "MAPA DE VALE SOMBRIO", 1.8, c_aqua);
        var _scale = min(5, floor(min((gw - 120) / cols, (gh - 150) / rows)));
        var _mx = (gw - cols * _scale) / 2; var _my = (gh - rows * _scale) / 2;
        draw_set_color(make_color_rgb(20, 23, 30)); fillrect(_mx - 5, _my - 5, _mx + cols * _scale + 5, _my + rows * _scale + 5);
        for (var c = 0; c < cols; c++) for (var r = 0; r < rows; r++) {
            if (!explored[c][r]) continue;
            draw_set_color(grid[c][r] >= 1 ? make_color_rgb(116, 124, 145) : pal_floor[clamp(biome[c][r], 0, array_length(pal_floor) - 1)]);
            fillrect(_mx + c * _scale, _my + r * _scale, _mx + (c + 1) * _scale, _my + (r + 1) * _scale);
        }
        draw_set_color(c_aqua); draw_circle(_mx + player.x / tile * _scale, _my + player.y / tile * _scale, max(3, _scale), false);
        gtext(gw / 2, gh - 42, "M ou ESC voltar", 0.95, c_ltgray);
    }
    draw_set_halign(fa_left);
}

// Fade de entrada/retorno.
if (fade > 0 && state == STATE_PLAYING) { draw_set_color(c_black); draw_set_alpha(fade); fillrect(0, 0, gw, gh); draw_set_alpha(1); }
draw_set_alpha(1);
draw_set_halign(fa_left);

