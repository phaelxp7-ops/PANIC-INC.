"""Embed the CC0 material atlases in Create_0.gml for sprite_add()."""
from pathlib import Path
import base64

ROOT = Path(__file__).resolve().parent
CREATE = ROOT.parents[1] / "obj_panic" / "Create_0.gml"
MATERIALS = ROOT.parent / "materials"
BEGIN = "// <PANIC_TEXTURES_BEGIN>"
END = "// <PANIC_TEXTURES_END>"

def gml_data_url(variable: str, image: Path) -> str:
    encoded = base64.b64encode(image.read_bytes()).decode("ascii")
    chunks = [encoded[i:i + 96] for i in range(0, len(encoded), 96)]
    lines = [f'var _{variable}_data = "data:image/jpeg;base64," +']
    lines.extend(f'    "{chunk}"' + (" +" if i < len(chunks) - 1 else ";")
                 for i, chunk in enumerate(chunks))
    lines.append(f'{variable} = sprite_add(_{variable}_data, 1, false, true, 0, 0);')
    return "\n".join(lines)

block = "\n".join([
    BEGIN,
    "// Texturas CC0 embutidas: sem caminhos externos nem importação manual no IDE.",
    gml_data_url("marta_tex_shirt", ROOT / "marta_shirt.jpg"),
    gml_data_url("marta_tex_denim", ROOT / "marta_denim.jpg"),
    gml_data_url("marta_tex_skin", ROOT / "marta_skin.jpg"),
    gml_data_url("world_surface_tex", MATERIALS / "world_surface_atlas.jpg"),
    gml_data_url("cabin_floor_tex", MATERIALS / "cabin_floor_atlas.jpg"),
    gml_data_url("monster_skin_tex", MATERIALS / "monster_skin_atlas.jpg"),
    gml_data_url("pine_bark_tex", MATERIALS / "pine_bark_atlas.jpg"),
    END,
])

source = CREATE.read_text(encoding="utf-8")
if "// <MARTA_TEXTURES_BEGIN>" in source and "// <MARTA_TEXTURES_END>" in source:
    old_start = source.index("// <MARTA_TEXTURES_BEGIN>")
    old_finish = source.index("// <MARTA_TEXTURES_END>", old_start) + len("// <MARTA_TEXTURES_END>")
    source = source[:old_start] + block + source[old_finish:]
elif BEGIN in source and END in source:
    start = source.index(BEGIN)
    finish = source.index(END, start) + len(END)
    source = source[:start] + block + source[finish:]
else:
    marker = "vertex_format_begin();\nvertex_format_add_position_3d();"
    if marker not in source:
        raise SystemExit("Could not locate vertex format marker in Create_0.gml")
    source = source.replace(marker, block + "\n\n" + marker, 1)
CREATE.write_text(source, encoding="utf-8", newline="\n")
print(f"Embedded texture maps into {CREATE}")
