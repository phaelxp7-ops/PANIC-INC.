Warning: truncated output (original token count: 18607)
Total output lines: 1779

// ============================================================
// PANIC INC. v4 - "O CORACAO DO MEDO"
// obj_panic - CREATE
// Mundo aberto, historia, NPCs, monstros, sanidade e chefe final.
// ============================================================
game_set_speed(60, gamespeed_fps);
randomize();

// ---------- SAVE (finais vistos e melhor tempo) ----------
ini_open("panic_save.ini");
endings_seen = ini_read_real("save", "endings", 0);
best_time    = ini_read_real("save", "besttime", 0);
ini_close();

// ---------- FONTE COM ACENTOS ----------
fnt_main = font_add("Arial", 13, false, false, 32, 383);

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
STATE_TITLE = 0; STATE_PLAYING = 1; STATE_PAUSED = 2; STATE_GAMEOVER = 3; STATE_DIALOG = 4;
STATE_READ = 5; STATE_JOURNAL = 6; STATE_MAP = 7; STATE_INTRO = 8; STATE_ENDCHOICE = 9;
STATE_ENDING = 10; STATE_UPGRADE = 11;
state = STATE_TITLE;
mode  = 0;               // 0 = 2D, 1 = 3D (TAB)
camera_pitch = 0;        // inclinacao vertical da camera em primeira pessoa

// tipos de item
IT_NOTE = 0; IT_MED = 1; IT_BAT = 2; IT_AMMO = 3; IT_KEY = 4; IT_PILL = 5;

// ---------- CONFIGURACOES ----------
tile = 32; cols = 128; rows = 84;
wall_h = 64; eye_h = 36; fov = 72;
mouse_sens = 0.15; turn_speed = 2.8;
flash_len = 200; flash_angle = 28; ambient_r = 70; ambient_cur = 70;
ndx  = [1, -1, 0, 0];
ndy  = [0, 0, 1, -1];
ndx8 = [1, -1, 0, 0, 1, 1, -1, -1];
ndy8 = [0, 0, 1, -1, 1, -1, 1, -1];

// paletas: 0 floresta, 1 cidade, 2 complexo, 3 subsolo, 4 madeira, 5 pedra
pal_floor = [make_color_rgb(34, 46, 34), make_color_rgb(54, 56, 62), make_color_rgb(46, 58, 74), make_color_rgb(62, 36, 46), make_color_rgb(78, 56, 38), make_color_rgb(40, 48, 38)];
pal_wall  = [make_color_rgb(22, 62, 30), make_color_rgb(88, 80, 96), make_color_rgb(74, 90, 116), make_color_rgb(98, 52, 64), make_color_rgb(112, 76, 46), make_color_rgb(104, 108, 116)];
biome_names = ["FLORESTA DE PINHEIROS", "CIDADE DE VALE SOMBRIO", "COMPLEXO PANIC INC.", "SUBSOLO - NÍVEL -3"];

// ---------- MELHORIAS ----------
speed_mult = 1; stam_mult = 1; batt_mult = 1; hear_mult = 1; dmg_mult = 1; sanity_mult = 1;
upg_defs = [
    { name : "PERNAS LEVES",       desc : "+12% de velocidade" },
    { name : "PULMÕES DE AÇO",     desc : "A stamina dura 40% mais" },
    { name : "LANTERNA POTENTE",   desc : "Mais alcance e cone de luz maior" },
    { name : "BATERIA ECONÔMICA",  desc : "A bateria dura 40% mais" },
    { name : "CORAÇÃO DE FERRO",   desc : "+25 de vida máxima e cura total" },
    { name : "PASSOS FELINOS",     desc : "Monstros te ouvem de menos longe" },
    { name : "BALAS PERFURANTES",  desc : "+40% de dano do revólver" },
    { name : "MENTE FORTE",        desc : "A sanidade cai 35% mais devagar" }
];
upg_choice = [0, 1, 2];

// ============================================================
// HISTORIA: NOTAS (ids 0 a 14)
// ============================================================
notes_data = [];
add_note = function(_t, _x) { array_push(notes_data, { title : _t, text : _x }); };
add_note("Bilhete de Lucas", "Ana, se você está lendo isto, NÃO venha atrás de mim.\n\nA PANIC INC. não fabrica segurança. Fabrica MEDO.\n\nVou desligar o sistema esta noite. Se eu não voltar... não deixe a luz apagar.\n\n- Lucas");
add_note("Aviso da Guarda Florestal", "Dia 3 do apagão. O povo da cidade veio para a mata. Estavam... vazios. Não falavam, só andavam em direção à luz.\n\nTranquei o portão da cidade e escondi a chave aqui.\n\nSe você está lendo isto: mantenha a lanterna acesa. A luz os segura.");
add_note("Diário do Acampamento", "Meu filho jurava ver alguém parado entre as árvores. Quando acendi a lanterna, a coisa congelou. Quando desviei o olhar, estava mais perto.\n\nNUNCA desvie o olhar das estátuas pálidas. Elas só se movem quando ninguém está olhando.");
add_note("Lápide sem nome", "AQUI JAZEM OS QUE NÃO PUDERAM GRITAR.\n\nA PANIC INC. pagava a cada família para participar do 'estudo noturno'. Ninguém perguntou o que o estudo era.");
add_note("Boletim da Rádio Vale", "...cidade em quarentena. Não é doença. O que saiu do complexo se alimenta do que você sente. Quanto mais medo, mais fortes eles ficam.\n\nRespire. Fique na luz. Na escuridão total, a sua própria mente começa a mentir para você.");
add_note("Relatório da Delegacia", "O Diretor Voss exigiu o cartão-mestre do complexo. Guardei na sala de evidências.\n\nAs Sombras que andam à noite são o medo que sobrou das vítimas. A luz da lanterna as queima. Mantenha o feixe nelas.");
add_note("Receita da Farmácia", "Os calmantes acabaram. Sobraram algumas pílulas na gaveta.\n\nQuando a sanidade cai, a mente cria monstros que não existem. Se você ver algo que desaparece quando chega perto... não era real.");
add_note("Carta na Igreja", "Rezo por eles toda noite. Alguns vêm até a porta e ficam chorando sem som.\n\nChoram porque ainda lembram quem eram.\n\n- Padre Antônio");
add_note("Memorando PANIC INC. #1", "PROJETO CORAÇÃO: reator que converte medo humano em energia. Produção 400% acima da meta.\n\nEfeito colateral: sujeitos 'esvaziam' após exposição prolongada.\n\nAprovado pelo Diretor Voss.");
add_note("Memorando PANIC INC. #2", "O sistema precisa de uma ÂNCORA: alguém cujo medo seja forte e constante o bastante para estabilizar o reator.\n\nO técnico Lucas Almeida mostrou-se... compatível.\n\nTransferir para o Nível -3.");
add_note("Diário de Lucas", "Descobri o que fizeram comigo. Eu sou a âncora. Enquanto eu sentir medo, o Coração vive. Se um dia eu parar de ter medo... ele morre.\n\nAna, eu precisava que você viesse. Preciso que você me ajude a não ter medo.");
add_note("Gravação do Diretor", "Eu não sou o monstro, Ana. Sou o futuro.\n\nO medo é a única energia infinita. Você vai me ajudar... ou vai alimentar o Coração como todos os outros.");
add_note("Laudo de Autópsia", "Os esvaziados não têm sangue. Têm vácuo. Reagem à luz como plantas ao sol.\n\nOs rastejantes são os primeiros a esvaziar: rápidos, agitados, frágeis. As Sombras morrem se forem iluminadas por tempo suficiente.");
add_note("Terminal do Elevador", "Elevador para o Nível -3. Requer 3 fusíveis de energia.\n\nOrdem do Diretor: ninguém desce.\n\nEle está lá embaixo. Ele sempre esteve lá embaixo.");
add_note("Câmera de Segurança 12", "Registro: o Diretor aparece e some entre os monitores. Quando ele desaparece, as luzes morrem.\n\nPara vê-lo, só com a lanterna. Para feri-lo... também.");

intro_pages = [
    "Vale Sombrio, 3h12 da madrugada.\n\nHá três noites a cidade inteira está sem energia. Ninguém atende o telefone. Ninguém sai de casa.",
    "Seu irmão, Lucas, era técnico noturno na PANIC INC., a empresa que sustentava a cidade.\n\nHoje, um bilhete apareceu embaixo da sua porta...",
    "'Ana, se você está lendo isto, NÃO venha atrás de mim.\n\nA PANIC INC. não fabrica segurança. Fabrica MEDO.\n\nVou desligar o sistema esta noite. Se eu não voltar... não deixe a luz apagar.'\n\n- Lucas",
    "Você dirigiu a noite toda. O carro morreu no fim da estrada, no meio da mata.\n\nAo longe, uma única luz de cabana ainda está acesa.\n\nVocê não vai voltar sem o seu irmão."
];
intro_i = 0; intro_t = 0;

// ---------- VARIAVEIS DE ESTADO ----------
dlg_lines = []; dlg_i = 0; dlg_t = 0; dlg_after = 0;
read_note = 0; jr_sel = 0; ending = 0; end_t = 0; end_text = "";
msg = ""; msg_timer = 0; zone_name = ""; zone_timer = 0;
sfx_on = true;
near_lamps = []; vis_prev = [];
nearby_kind = -1; nearby_idx = -1; prompt = "";
active_npc = -1;
cam_x = 0; cam_y = 0;
title_eyes = [];
repeat (16) array_push(title_eyes, { x : random(gw), y : random(gh), ph : random(360), s : random_range(0.6, 1.6) });

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
    hurt_cd : 0, shoot_cd : 0,
    bob : 0
};

// ============================================================
// FUNCOES UTEIS
// ============================================================
tc = function(_c) { return _c * tile + tile / 2; };

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
    return grid[_c][_r] >= 1;
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

ray_len = function(_x, _y, _dir, _max) {
    var _l = 0;
    while (_l < _max) {
        if (solid_at(_x + lengthdir_x(_l, _dir), _y + lengthdir_y(_l, _dir))) break;
        _l += 6;
    }
    return _l;
};

// brilho (0..1) de um ponto: ambiente + lanterna + lampadas proximas + tiro
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
    if (muzzle > 0) _b = max(_b, clamp(1 - _d / 170, 0, 1) * 0.9);
    for (var k = 0; k < array_length(near_lamps); k++) {
        var _l = near_lamps[k];
        var _ld = point_distance(_x, _y, _l.x, _l.y);
        if (_ld < 120) {
            var _q = 1 - _ld / 120;
            _b = max(_b, _q * _q * 0.8 * _l.on);
        }
    }
    return clamp(_b, 0, 1);
};

in_safe = function(_x, _y) {
    for (var i = 0; i < array_length(safes); i++) {
        if (point_distance(_x, _y, safes[i].x, safes[i].y) < safes[i].r) return i;
    }
    return -1;
};

lamp_near = function(_x, _y, _r) {
    for (var i = 0; i < array_length(lamps); i++) {
        if (lamps[i].on > 0.5 && point_distance(_x, _y, lamps[i].x, lamps[i].y) < _r) return true;
    }
    return false;
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
snd_shot = make_snd(0.4, function(_t, _d) {
    return (random(2) - 1) * 0.8 * exp(-_t * 22) + sin(2 * pi * 85 * _t) * 0.9 * exp(-_t * 14);
});
snd_whisper = make_snd(1.4, function(_t, _d) {
    var _env = sin(pi * _t / _d);
    var _syl = 0.5 + 0.5 * sin(2 * pi * 4.5 * _t);
    return (random(2) - 1) * 0.28 * _env * _syl + sin(2 * pi * (260 + 90 * sin(2 * pi * 1.7 * _t)) * _t) * 0.05 * _env;
});
snd_door = make_snd(0.7, function(_t, _d) {
    return (sin(2 * pi * (110 - 70 * _t) * _t) * 0.7 + (random(2) - 1) * 0.25 * exp(-_t * 30)) * exp(-_t * 5);
});
snd_roar = make_snd(1.8, function(_t, _d) {
    var _env = sin(pi * _t / _d);
    var _f = 42 + 22 * sin(2 * pi * 3.2 * _t);
    var _saw = ((_t * _f) mod 1) * 2 - 1;
    return (_saw * 0.55 + (random(2) - 1) * 0.35) * _env;
});
snd_stone = make_snd(0.6, function(_t, _d) {
    return (random(2) - 1) * 0.35 * sin(pi * _t / _d) * (0.5 + 0.5 * sin(2 * pi * 38 * _t));
});
snd_heal = make_snd(0.5, function(_t, _d) {
    var _f = 440 + 500 * _t / _d;
    return sin(2 * pi * _f * _t) * 0.4 * sin(pi * _t / _d);
});
snd_boss_mus = make_snd(6, function(_t, _d) {
    var _w = 2 * pi;
    var _b = (_t * 2.4) mod 1;
    var _s = sin(_w * 49 * _t) * 0.5 * exp(-_b * 4) + sin(_w * 98 * _t) * 0.2 * exp(-_b * 6);
    var _st = ((floor(_t * 0.8) mod 2) == 0) ? 1 : 1.0595;
    var _m = 0.5 + 0.5 * sin(_w * 0.4 * _t);
    _s += sin(_w * 220 * _st * _t) * 0.06 * _m + sin(_w * 233 * _st * _t) * 0.06 * _m;
    return _s;
});

audio_master_gain(0.9);
drone_inst = audio_play_sound(snd_drone, 1, true);
audio_sound_gain(drone_inst, 0.3, 0);
boss_mus_inst = -1;

// ============================================================
// GERACAO DO MUNDO
// ============================================================
carve_rect = function(_c1, _r1, _c2, _r2, _bio) {
    for (var i = max(1, _c1); i <= min(cols - 2, _c2); i++) {
        for (var j = max(1, _r1); j <= min(rows - 2, _r2); j++) {
            grid[i][j] = 0;
            if (_bio >= 0) biome[i][j] = _bio;
        }
    }
};

carve_disc = function(_cx, _cy, _rad, _bio) {
    for (var i = _cx - _rad; i <= _cx + _rad; i++) {
        for (var j = _cy - _rad; j <= _cy + _rad; j++) {
            if (i < 1 || j < 1 || i > cols - 2 || j > rows - 2) continue;
            if (point_distance(i, j, _cx, _cy) <= _rad) {
                grid[i][j] = 0;
                if (_bio >= 0) biome[i][j] = _bio;
            }
        }
    }
};

carve_path = function(_x1, _y1, _x2, _y2, _w, _bio) {
    var _x = _x1;
    var _y = _y1;
    var _guard = 0;
    while ((abs(_x - _x2) > 1 || abs(_y - _y2) > 1) && _guard < 900) {
        _guard++;
        carve_disc(round(_x), round(_y), _w, _bio);
        var _d = point_direction(_x, _y, _x2, _y2) + random_range(-40, 40);
        _x += lengthdir_x(1, _d);
        _y += lengthdir_y(1, _d);
    }
    carve_disc(_x2, _y2, _w, _bio);
};

connect_rooms = function(_a, _b, _bio) {
    var _ax = _a.x + _a.w div 2;
    var _ay = _a.y + _a.h div 2;
    var _bx = _b.x + _b.w div 2;
    var _by = _b.y + _b.h div 2;
    carve_rect(min(_ax, _bx), _ay, max(_ax, _bx), _ay + 1, _bio);
    carve_rect(_bx, min(_ay, _by), _bx + 1, max(_ay, _by), _bio);
};

gen_forest = function() {
    for (var c = 1; c <= 46; c++) {
        for (var r = 1; r <= 82; r++) {
            grid[c][r] = (random(1) < 0.42) ? 1 : 0;
            biome[c][r] = 0;
        }
    }
    repeat (4) {
        var _tmp = array_create(cols);
        for (var i = 0; i < cols; i++) _tmp[i] = array_create(rows, 1);
        for (var c = 1; c <= 46; c++) {
            for (var r = 1; r <= 82; r++) {
                var _n = 0;
                for (var k = 0; k < 8; k++) _n += grid[c + ndx8[k]][r + ndy8[k]];
                _tmp[c][r] = (_n >= 5) ? 1 : 0;
            }
        }
        for (var c = 1; c <= 46; c++) {
            for (var r = 1; r <= 82; r++) grid[c][r] = _tmp[c][r];
        }
    }
    // clareiras e trilhas
    carve_disc(9, 42, 9, 0);
    carve_disc(30, 12, 7, 0);
    carve_disc(36, 62, 6, 0);
   …8607 tokens truncated…Ana. O Coração vive do meu medo. Se eu parar de temer, ele morre... e eu junto."],
            ["Lucas", "Você pode me levar embora e deixar o Coração vivo. Ou pode desligá-lo e acabar com tudo isso."],
            ["Lucas", "A escolha é sua. Eu confio em você."]
        ], 4);
    }
};

finish_dialog = function() {
    var _code = dlg_after;
    state = STATE_PLAYING;
    if (_code == 1) {
        talked_marta = true;
        has_gun = true;
        ammo += 6;
        play_snd(snd_pick, 0.7, 0.8);
        show_msg("Você recebeu o REVÓLVER (6 balas). Atire com o botão esquerdo ou ESPAÇO.", 300);
    }
    if (_code == 2) {
        talked_tomas = true;
        pills += 2;
        play_snd(snd_pick, 0.7, 1.1);
        show_msg("Você recebeu 2 pílulas calmantes [Q].", 200);
    }
    if (_code == 3) start_boss_fight();
    if (_code == 4) {
        lucas_met = true;
        state = STATE_ENDCHOICE;
    }
    if (_code == 5) {
        meds++;
        ammo += has_gun ? 2 : 0;
        if (active_npc != -1) active_npc.used = true;
        show_msg("A pessoa deixou um kit médico e munição. Encontro concluído.", 220);
        play_snd(snd_pick, 0.7, 1.15);
        active_npc = -1;
    }
    if (_code == 6) {
        if (active_npc != -1) active_npc.revealed = true;
        blackout = max(blackout, 150);
        flicker_t = 75;
        alarm_timer = max(alarm_timer, 420);
        var _ambush = pick_spot(cur_biome, player.x, player.y, 170);
        var _attacker = spawn_enemy_at(choose(0, 1, 2), _ambush.x, _ambush.y);
        _attacker.mode = 1;
        _attacker.summoned = true;
        show_msg("TRAÍRA! A luz apagou e algo veio pelo caminho que você mostrou.", 260);
        play_snd(snd_scare, 0.9, 0.8);
        shake = max(shake, 12);
        active_npc = -1;
    }
};

try_open_gate = function(_g) {
    var _ok = false;
    if (_g.need == 0 && has_gatekey) _ok = true;
    if (_g.need == 1 && has_keycard) _ok = true;
    if (_g.need == 2 && fuses >= 3) _ok = true;
    if (_ok) {
        for (var c = _g.c1; c <= _g.c2; c++) {
            for (var r = _g.r1; r <= _g.r2; r++) grid[c][r] = 0;
        }
        _g.open = true;
        play_snd(snd_door, 0.9, 1);
        shake = 5;
        show_msg(_g.name + " aberto!", 160);
        build_3d();
    } else {
        play_snd(snd_click, 0.7, 0.5);
        if (_g.need == 0) show_msg("Trancado. Precisa da chave do portão.", 160);
        if (_g.need == 1) show_msg("Trancado. Precisa do cartão de acesso.", 160);
        if (_g.need == 2) show_msg("Sem energia. Precisa de 3 fusíveis (" + string(fuses) + "/3).", 160);
    }
};

// ============================================================
// COMBATE
// ============================================================
add_tracer = function(_x1, _y1, _x2, _y2) {
    array_push(tracers, { x1 : _x1, y1 : _y1, x2 : _x2, y2 : _y2, life : 6 });
};

kill_enemy = function(_i) {
    var _e = enemies[_i];
    var _col = (_e.type == 3) ? make_color_rgb(140, 120, 200) : make_color_rgb(120, 10, 10);
    add_particles(_e.x, _e.y, 24, _col, 2.8);
    play_snd(snd_hurt, 0.5, 0.6);
    kills++;
    if (_e.type != 3 && !_e.summoned) {
        var _r = random(1);
        if (_r < 0.20) place_item(_e.x, _e.y, IT_AMMO, 0, -1);
        else if (_r < 0.30) place_item(_e.x, _e.y, IT_MED, 0, -1);
        else if (_r < 0.38) place_item(_e.x, _e.y, IT_PILL, 0, -1);
    }
    array_delete(enemies, _i, 1);
};

damage_enemy = function(_i, _d) {
    var _e = enemies[_i];
    _e.hp -= _d;
    _e.flash = 6;
    _e.lost = 0;
    if (_e.mode == 0) _e.mode = 1;
    add_particles(_e.x, _e.y, 6, make_color_rgb(150, 20, 20), 2);
    if (_e.hp <= 0) kill_enemy(_i);
};

hurt_player = function(_dmg, _san) {
    if (player.hurt_cd > 0) return;
    player.hp = max(0, player.hp - _dmg);
    sanity = max(0, sanity - _san * sanity_mult);
    player.hurt_cd = 50;
    shake = 10;
    hurt_flash = 1;
    add_particles(player.x, player.y, 14, c_red, 2.5);
    play_snd(snd_hurt, 0.8, random_range(0.9, 1.1));
    array_push(decals, { x : player.x + random_range(-10, 10), y : player.y + random_range(-10, 10), r : random_range(3, 8) });
    if (array_length(decals) > 60) array_delete(decals, 0, 1);
};

fire_gun = function() {
    if (!has_gun || player.shoot_cd > 0) return;
    if (ammo <= 0) {
        play_snd(snd_click, 0.6, 0.6);
        show_msg("Sem munição!", 60);
        player.shoot_cd = 20;
        return;
    }
    ammo--;
    player.shoot_cd = 28;
    muzzle = 5;
    shake = max(shake, 3);
    play_snd(snd_shot, 0.9, random_range(0.95, 1.05));
    var _dir = player.facing_dir + random_range(-1.5, 1.5);
    var _len = 0;
    var _hx = player.x;
    var _hy = player.y;
    var _hit = -1;
    var _hitboss = false;
    var _dmg = 40 * dmg_mult;
    while (_len < 420) {
        _len += 5;
        _hx = player.x + lengthdir_x(_len, _dir);
        _hy = player.y + lengthdir_y(_len, _dir);
        if (solid_at(_hx, _hy)) break;
        for (var i = 0; i < array_length(enemies); i++) {
            if (point_distance(_hx, _hy, enemies[i].x, enemies[i].y) < enemies[i].rad + 3) { _hit = i; break; }
        }
        if (_hit != -1) break;
        if (boss != -1 && point_distance(_hx, _hy, boss.x, boss.y) < boss.rad + 3) { _hitboss = true; break; }
    }
    add_tracer(player.x + lengthdir_x(12, _dir), player.y + lengthdir_y(12, _dir), _hx, _hy);
    // o tiro faz barulho: atrai monstros
    for (var i = 0; i < array_length(enemies); i++) {
        if (enemies[i].mode == 0 && point_distance(enemies[i].x, enemies[i].y, player.x, player.y) < 600) {
            enemies[i].mode = 1;
            enemies[i].lost = 0;
        }
    }
    if (_hit != -1) damage_enemy(_hit, _dmg);
    if (_hitboss) {
        var _m = 1;
        if (boss.phase == 2 && !boss.lit) _m = 0.15;
        boss.hp -= _dmg * _m;
        boss.flash = 6;
        add_particles(boss.x, boss.y, 8, make_color_rgb(255, 60, 60), 2.5);
    }
};

// ---------- sustos ----------
spawn_hallu = function() {
    var _d = player.facing_dir + random_range(-35, 35);
    var _l = ray_len(player.x, player.y, _d, 190);
    if (_l < 110) return false;
    array_push(hallu, { x : player.x + lengthdir_x(_l - 12, _d), y : player.y + lengthdir_y(_l - 12, _d), face : _d + 180, life : 200, watch : 0, anim : random(360) });
    sanity = max(0, sanity - 2);
    play_snd(snd_whisper, 0.35, random_range(0.8, 1.2));
    return true;
};

trigger_scare = function() {
    var _k = irandom(3);
    switch (_k) {
        case 0: spawn_hallu(); break;
        case 1: flicker_t = 100; play_snd(snd_whisper, 0.5, 0.7); break;
        case 2: foot_scare = 8; break;
        case 3: play_snd(snd_door, 0.7, random_range(0.7, 1)); shake = max(shake, 5); break;
    }
};

// ============================================================
// CHEFE: O DIRETOR
// ============================================================
boss_shot = function(_x, _y, _dir, _spd, _dmg) {
    array_push(shots, { x : _x, y : _y, vx : lengthdir_x(_spd, _dir), vy : lengthdir_y(_spd, _dir), life : 260, dmg : _dmg });
};

boss_ring = function(_n, _spd, _off, _dmg) {
    for (var i = 0; i < _n; i++) boss_shot(boss.x, boss.y, _off + i * 360 / _n, _spd, _dmg);
};

seal_arena = function() {
    for (var c = 106; c <= 108; c++) grid[c][59] = 2;
    seal_on = true;
    build_3d();
};

unseal_arena = function() {
    for (var c = 106; c <= 108; c++) grid[c][59] = 0;
    seal_on = false;
    build_3d();
};

start_boss_fight = function() {
    boss = { x : tc(107), y : tc(70), hp : 700, hpmax : 700, phase : 1, anim : 0, face : 90, cd : 120, pat : 0,
             dash : 0, dt : 0, dang : 0, tp : 200, flash : 0, lit : false, rad : 22 };
    seal_arena();
    var _ax = [97, 117, 97, 117, 97, 117];
    var _ay = [62, 62, 78, 78, 70, 70];
    for (var k = 0; k < 6; k++) place_item(tc(_ax[k]), tc(_ay[k]), IT_AMMO, 0, -1);
    place_item(tc(101), tc(70), IT_MED, 0, -1);
    place_item(tc(113), tc(70), IT_MED, 0, -1);
    if (boss_mus_inst != -1) audio_stop_sound(boss_mus_inst);
    boss_mus_inst = audio_play_sound(snd_boss_mus, 8, true);
    audio_sound_gain(boss_mus_inst, 0.55, 0);
    play_snd(snd_roar, 1, 0.9);
    shake = 16;
    show_msg("O DIRETOR: 'Mostre-me o seu medo!'", 240);
};

boss_defeated = function() {
    boss_dead = true;
    boss = -1;
    shots = [];
    shake = 30;
    white_flash = 1;
    play_snd(snd_roar, 1, 0.5);
    add_particles(tc(107), tc(70), 60, make_color_rgb(255, 60, 60), 4);
    if (boss_mus_inst != -1) { audio_stop_sound(boss_mus_inst); boss_mus_inst = -1; }
    for (var i = array_length(enemies) - 1; i >= 0; i--) {
        if (enemies[i].summoned) array_delete(enemies, i, 1);
    }
    unseal_arena();
    array_push(npcs, { x : tc(107), y : tc(75), kind : 2, name : "Lucas", face : 270 });
    sanity = min(100, sanity + 30);
    show_msg("O Diretor caiu! Fale com Lucas, perto do Coração.", 260);
};

update_boss = function() {
    var _b = boss;
    var _dist = point_distance(_b.x, _b.y, player.x, player.y);
    _b.anim++;
    if (_b.flash > 0) _b.flash--;

    // luz da lanterna revela e fere o chefe
    _b.lit = false;
    if (flash_on && _dist < flash_len + 40) {
        var _ad = abs(angle_difference(player.facing_dir, point_direction(player.x, player.y, _b.x, _b.y)));
        if (_ad < flash_angle + 12 && los(player.x, player.y, _b.x, _b.y)) _b.lit = true;
    }
    if (_b.lit) {
        _b.hp -= 0.30 * dmg_mult;
        battery = max(0, battery - 0.02);
        _b.flash = 2;
    }

    var _ph = 1;
    if (_b.hp <= 470) _ph = 2;
    if (_b.hp <= 220) _ph = 3;
    if (_ph != _b.phase) {
        _b.phase = _ph;
        shake = 18;
        play_snd(snd_roar, 1, 0.8 + 0.1 * _ph);
        _b.cd = 80;
        _b.dash = 0;
        var _ax2 = [97, 117, 97, 117];
        var _ay2 = [62, 62, 78, 78];
        for (var k = 0; k < 4; k++) place_item(tc(_ax2[k]), tc(_ay2[k]), IT_AMMO, 0, -1);
        if (_ph == 2) {
            show_msg("O DIRETOR: 'Você não me vê... mas eu vejo o seu medo.'", 280);
            blackout = 360;
            repeat (2) { var _s = spawn_enemy_at(3, boss.x + random_range(-60, 60), boss.y + random_range(-60, 60)); _s.summoned = true; _s.mode = 1; }
        }
        if (_ph == 3) {
            show_msg("O DIRETOR: 'ENTÃO VAMOS ACABAR COM ISSO!'", 280);
            repeat (2) { var _s2 = spawn_enemy_at(0, boss.x + random_range(-60, 60), boss.y + random_range(-60, 60)); _s2.summoned = true; _s2.mode = 1; }
        }
    }

    _b.cd--;
    var _dirp = point_direction(_b.x, _b.y, player.x, player.y);
    if (_b.dash == 0) _b.face = _dirp;

    switch (_ph) {
        case 1:
            if (_dist > 150) move_body(_b, lengthdir_x(0.85, _dirp), lengthdir_y(0.85, _dirp), 14);
            if (_b.cd <= 0) {
                if (_b.pat == 0) boss_ring(14, 2.2, random(360), 12);
                else { for (var a = -14; a <= 14; a += 14) boss_shot(_b.x, _b.y, _dirp + a, 3.2, 12); }
                _b.pat = 1 - _b.pat;
                _b.cd = 150;
                play_snd(snd_growl, 0.6, 0.6);
            }
            break;
        case 2:
            if (_dist > 100) move_body(_b, lengthdir_x(0.7, _dirp), lengthdir_y(0.7, _dirp), 14);
            _b.tp--;
            if (_b.tp <= 0) {
                _b.tp = 220;
                for (var t = 0; t < 30; t++) {
                    var _a = random(360);
                    var _px = player.x + lengthdir_x(170, _a);
                    var _py = player.y + lengthdir_y(170, _a);
                    if (!box_hits(_px, _py, 16) && _px > 94 * tile && _px < 120 * tile && _py > 60 * tile && _py < 80 * tile) {
                        add_particles(_b.x, _b.y, 14, make_color_rgb(150, 20, 200), 2.5);
                        _b.x = _px;
                        _b.y = _py;
                        add_particles(_b.x, _b.y, 14, make_color_rgb(150, 20, 200), 2.5);
                        play_snd(snd_whisper, 0.8, 0.6);
                        break;
                    }
                }
            }
            if (_b.cd <= 0) {
                for (var a2 = -24; a2 <= 24; a2 += 12) boss_shot(_b.x, _b.y, _dirp + a2, 3.4, 12);
                if (_b.pat == 1) boss_ring(8, 2.4, random(360), 10);
                _b.pat = 1 - _b.pat;
                _b.cd = 110;
                play_snd(snd_growl, 0.6, 0.5);
            }
            break;
        case 3:
            if (_b.dash == 0) {
                if (_dist > 90) move_body(_b, lengthdir_x(1.5, _dirp), lengthdir_y(1.5, _dirp), 14);
                if (_b.cd <= 0) {
                    if (irandom(1) == 0) {
                        _b.dash = 1;
                        _b.dt = 45;
                        _b.dang = _dirp;
                        play_snd(snd_roar, 0.7, 1.2);
                    } else {
                        boss_ring(16, 2.6, random(360), 12);
                        for (var a3 = -10; a3 <= 10; a3 += 10) boss_shot(_b.x, _b.y, _dirp + a3, 3.8, 12);
                        _b.cd = 95;
                        play_snd(snd_growl, 0.6, 0.5);
                    }
                }
            } else if (_b.dash == 1) {
                _b.dt--;
                _b.dang = _dirp;
                if (_b.dt <= 0) { _b.dash = 2; _b.dt = 22; }
                _b.face = _b.dang;
            } else {
                _b.dt--;
                move_body(_b, lengthdir_x(7.5, _b.dang), lengthdir_y(7.5, _b.dang), 14);
                _b.face = _b.dang;
                if (_b.dt <= 0) { _b.dash = 0; _b.cd = 90; }
            }
            if (_dist < 420) sanity = max(0, sanity - 0.02 * sanity_mult);
            break;
    }

    var _dd = (_b.dash == 2) ? 32 : 26;
    if (point_distance(_b.x, _b.y, player.x, player.y) < _b.rad + _dd - 8) hurt_player((_b.dash == 2) ? 30 : 22, 8);

    if (_b.hp <= 0) boss_defeated();
};

// ============================================================
// DESENHO REUTILIZAVEL
// ============================================================
draw_husk = function(_x, _y, _face, _col, _chase, _anim, _a) {
    draw_set_alpha(_a);
    var _tw = sin(_anim * 0.2) * (_chase ? 2.2 : 1);
    var _reach = _chase ? 21 : 11;
    for (var s = -1; s <= 1; s += 2) {
        var _sx = _x + lengthdir_x(8 * s, _face + 90);
        var _sy = _y + lengthdir_y(8 * s, _face + 90);
        var _ang = _face + _tw * 3 * s;
        var _ex = _sx + lengthdir_x(_reach, _ang);
        var _ey = _sy + lengthdir_y(_reach, _ang);
        draw_set_color(shade(_col, 0.55));
        draw_line_width(_sx, _sy, _ex, _ey, 3);
        for (var cl = -1; cl <= 1; cl++) {
            draw_line_width(_ex, _ey, _ex + lengthdir_x(6, _ang + cl * 28), _ey + lengthdir_y(6, _ang + cl * 28), 1);
        }
        draw_set_color(_col);
        draw_circle(_sx, _sy, 4, false);
    }
    draw_set_color(_col);
    draw_circle(_x, _y, 9, false);
    var _hx = _x + lengthdir_x(5, _face);
    var _hy = _y + lengthdir_y(5, _face);
    draw_set_color(shade(_col, 1.2));
    draw_circle(_hx, _hy, 6, false);
    draw_set_color(c_black);
    for (var s = -1; s <= 1; s += 2) {
        draw_circle(_hx + lengthdir_x(2, _face) + lengthdir_x(2.6 * s, _face + 90), _hy + lengthdir_y(2, _face) + lengthdir_y(2.6 * s, _face + 90), 1.8, false);
    }
    if (_chase) draw_circle(_hx + lengthdir_x(4, _face), _hy + lengthdir_y(4, _face), 2.2, false);
    draw_set_alpha(1);
};

draw_person = function(_x, _y, _face, _jacket) {
    draw_set_alpha(0.35);
    draw_set_color(c_black);
    draw_ellipse(_x - 10, _y + 5, _x + 10, _y + 13, false);
    draw_set_alpha(1);
    draw_set_color(_jacket);
    draw_circle(_x, _y, 9, false);
    for (var s = -1; s <= 1; s += 2) {
        draw_circle(_x + lengthdir_x(7 * s, _face + 90), _y + lengthdir_y(7 * s, _face + 90), 4, false);
    }
    draw_set_color(c_black);
    draw_circle(_x, _y, 9, true);
    draw_set_color(make_color_rgb(40, 28, 22));
    draw_circle(_x - lengthdir_x(1.5, _face), _y - lengthdir_y(1.5, _face), 6.5, false);
    draw_set_color(make_color_rgb(235, 195, 160));
    draw_circle(_x + lengthdir_x(1.5, _face), _y + lengthdir_y(1.5, _face), 5, false);
};

// ============================================================
// MELHORIAS, RESPAWN, NOVO JOGO
// ============================================================
apply_upgrade = function(_id) {
    switch (_id) {
        case 0: speed_mult += 0.12; break;
        case 1: stam_mult *= 0.6; break;
        case 2: flash_len += 30; flash_angle += 4; break;
        case 3: batt_mult *= 0.6; break;
        case 4: player.hp_max += 25; player.hp = player.hp_max; break;
        case 5: hear_mult *= 0.7; break;
        case 6: dmg_mult += 0.4; break;
        case 7: sanity_mult *= 0.65; break;
    }
};

pick_upgrades = function() {
    var _pool = [0, 1, 2, 3, 4, 5, 6, 7];
    upg_choice = [];
    repeat (3) {
        var _i = irandom(array_length(_pool) - 1);
        array_push(upg_choice, _pool[_i]);
        array_delete(_pool, _i, 1);
    }
};

save_game = function() {
    ini_open("panic_save.ini");
    ini_write_real("save", "endings", endings_seen);
    ini_write_real("save", "besttime", best_time);
    ini_close();
};

respawn = function() {
    player.x = check_x;
    player.y = check_y;
    player.hp = player.hp_max * 0.6;
    player.hurt_cd = 90;
    sanity = max(sanity, 55);
    battery = max(battery, 35);
    for (var i = array_length(enemies) - 1; i >= 0; i--) {
        var _e = enemies[i];
        _e.mode = 0;
        if (point_distance(_e.x, _e.y, check_x, check_y) < 380) array_delete(enemies, i, 1);
    }
    shots = [];
    if (boss_started && !boss_dead) {
        boss_started = false;
        boss = -1;
        if (seal_on) unseal_arena();
        if (boss_mus_inst != -1) { audio_stop_sound(boss_mus_inst); boss_mus_inst = -1; }
        for (var i = array_length(enemies) - 1; i >= 0; i--) {
            if (enemies[i].summoned) array_delete(enemies, i, 1);
        }
    }
    alarm_timer = 0;
    blackout = 0;
    fade = 1;
    state = STATE_PLAYING;
    show_msg("Você acorda num ponto seguro...", 180);
    update_visibility();
    update_flow();
};

new_game = function() {
    has_gun = false; ammo = 0; meds = 0; pills = 0; bats = 0;
    has_gatekey = false; has_keycard = false; fuses = 0;
    talked_marta = false; talked_tomas = false; lucas_met = false;
    boss_started = false; boss_dead = false; boss = -1; boss_mus_inst = -1;
    notes_found = [0];
    active_npc = -1;
    kills = 0; deaths = 0; play_time = 0;
    speed_mult = 1; stam_mult = 1; batt_mult = 1; hear_mult = 1; dmg_mult = 1; sanity_mult = 1;
    flash_len = 200; flash_angle = 28;
    player.hp_max = 100; player.hp = 100;
    player.stamina = 100; player.exhausted = false;
    player.hurt_cd = 0; player.shoot_cd = 0; player.bob = 0;
    battery = 100; flash_on = true; flash_power = 1; sanity = 100;
    panic = 0; shake = 0; hurt_flash = 0; heart_pulse = 0; white_flash = 0; muzzle = 0;
    fade = 1; blackout = 0; blackout_cd = irandom_range(2400, 4200);
    scare_cd = irandom_range(1200, 2400); alert_cd = 0; heart_cd = 0; step_sign = false;
    drip_cd = 300; creak_cd = 900; whisper_cd = 600; flicker_t = 0; foot_scare = 0; alarm_timer = 0;
    spawn_timer = 0; spawn_interval = irandom_range(1200, 2000);
    particles = []; floaters = []; decals = []; shots = []; tracers = []; hallu = []; dust = [];
    repeat (120) array_push(dust, { x : random(cols * tile), y : random(rows * tile), vx : random_range(-0.15, 0.15), vy : random_range(-0.1, 0.1) });
    visited_biome = [true, false, false, false];
    cur_biome = 0; zone_name = biome_names[0]; zone_timer = 220;
    check_idx = -1;
    generate_world();
    player.x = tc(10);
    player.y = tc(42);
    player.facing_dir = 0;
    check_x = player.x; check_y = player.y;
    cam_x = clamp(player.x - vw / 2, 0, cols * tile - vw);
    cam_y = clamp(player.y - vh / 2, 0, rows * tile - vh);
    update_visibility();
    update_flow();
    build_3d();
    msg = ""; msg_timer = 0;
};

new_game();



