"""Build compact, runtime-friendly diffuse maps from the project's CC0 sources."""
from pathlib import Path
import random

from PIL import Image, ImageDraw, ImageEnhance, ImageOps

ROOT = Path(__file__).resolve().parent
ASSETS = ROOT.parent
POLY = ASSETS / "third_party" / "polyhaven"
OGA = ASSETS / "third_party" / "opengameart"
MARTA = ASSETS / "marta_materials"
ROOT.mkdir(parents=True, exist_ok=True)
MARTA.mkdir(parents=True, exist_ok=True)

CELL = 128
PAD = 2


def color_tint(image: Image.Image, color: tuple[int, int, int], strength: float) -> Image.Image:
    """Blend a CC0 diffuse patch with a restrained biome tint."""
    gray = ImageOps.grayscale(image).convert("RGB")
    tint = Image.new("RGB", image.size, color)
    colored = Image.blend(gray, tint, strength)
    return Image.blend(image, colored, strength * 0.58)


def atlas_group(atlas: Image.Image, source: Image.Image, group_x: int, group_y: int,
                seed: int, brightness: float, contrast: float,
                tint: tuple[int, int, int] | None = None) -> None:
    rng = random.Random(seed)
    source = source.convert("RGB")
    sw, sh = source.size
    crop = min(sw, sh, 300)
    for variant in range(16):
        x = rng.randrange(0, max(1, sw - crop + 1))
        y = rng.randrange(0, max(1, sh - crop + 1))
        patch = source.crop((x, y, x + crop, y + crop))
        if rng.random() < 0.5:
            patch = ImageOps.mirror(patch)
        if rng.random() < 0.5:
            patch = ImageOps.flip(patch)
        patch = patch.rotate(rng.choice((0, 90, 180, 270)))
        patch = patch.resize((CELL - PAD * 2, CELL - PAD * 2), Image.Resampling.LANCZOS)
        patch = ImageEnhance.Contrast(patch).enhance(contrast * rng.uniform(0.96, 1.04))
        patch = ImageEnhance.Brightness(patch).enhance(brightness * rng.uniform(0.96, 1.04))
        if tint:
            patch = color_tint(patch, tint, 0.30)
        col = group_x + variant % 4
        row = group_y + variant // 4
        left = col * CELL + PAD
        top = row * CELL + PAD
        atlas.paste(patch, (left, top))
        # Two-pixel duplicated gutters prevent sampling neighboring atlas cells.
        atlas.paste(patch.crop((0, 0, patch.width, 1)).resize((patch.width, PAD)), (left, top - PAD))
        atlas.paste(patch.crop((0, patch.height - 1, patch.width, patch.height)).resize((patch.width, PAD)), (left, top + patch.height))
        atlas.paste(patch.crop((0, 0, 1, patch.height)).resize((PAD, patch.height)), (left - PAD, top))
        atlas.paste(patch.crop((patch.width - 1, 0, patch.width, patch.height)).resize((PAD, patch.height)), (left + patch.width, top))
        for dx, dy, px, py in ((-PAD, -PAD, 0, 0), (patch.width, -PAD, patch.width - 1, 0),
                               (-PAD, patch.height, 0, patch.height - 1),
                               (patch.width, patch.height, patch.width - 1, patch.height - 1)):
            corner = patch.crop((px, py, px + 1, py + 1)).resize((PAD, PAD))
            atlas.paste(corner, (left + dx, top + dy))


def build_world_atlas() -> None:
    atlas = Image.new("RGB", (CELL * 8, CELL * 8), (24, 28, 27))
    atlas_group(atlas, Image.open(POLY / "forrest_ground_03_diff_1k.jpg"), 0, 0, 431, 0.96, 1.18, (77, 93, 68))
    atlas_group(atlas, Image.open(POLY / "asphalt_01_diff_1k.jpg"), 4, 0, 932, 1.18, 1.14)
    atlas_group(atlas, Image.open(POLY / "concrete_floor_diff_1k.jpg"), 0, 4, 177, 1.08, 1.13, (112, 145, 157))
    atlas_group(atlas, Image.open(POLY / "concrete_floor_diff_1k.jpg"), 4, 4, 610, 0.91, 1.18, (140, 78, 75))
    atlas.save(ROOT / "world_surface_atlas.jpg", quality=88, optimize=True, progressive=False)


def build_bark_atlas() -> None:
    atlas = Image.new("RGB", (CELL * 4, CELL * 4), (32, 22, 18))
    atlas_group(atlas, Image.open(POLY / "pine_bark_diff_1k.jpg"), 0, 0, 193, 1.05, 1.18)
    atlas.save(ROOT / "pine_bark_atlas.jpg", quality=86, optimize=True, progressive=False)


def build_cabin_floor_atlas() -> None:
    """Build a 4x4 set of worn wood-plank tiles for cabin floors."""
    source = Image.open(POLY / "pine_bark_diff_1k.jpg").convert("RGB")
    atlas = Image.new("RGB", (512, 512), (37, 25, 17))
    rng = random.Random(712)
    for variant in range(16):
        tile = Image.new("RGB", (128, 128), (52, 35, 23))
        draw = ImageDraw.Draw(tile)
        for row in range(4):
            y = row * 32
            cx = rng.uniform(0.2, 0.8)
            cy = rng.uniform(0.15, 0.85)
            patch = ImageOps.fit(source, (128, 32), centering=(cx, cy), method=Image.Resampling.LANCZOS)
            patch = ImageEnhance.Color(patch).enhance(0.68)
            patch = ImageEnhance.Brightness(patch).enhance(rng.uniform(0.52, 0.72))
            tile.paste(patch, (0, y))
            # Board seams, end joints and subtle scratches make the cabin read as timber.
            draw.line((0, y, 127, y), fill=(23, 16, 12), width=2)
            seam = rng.randrange(32, 97)
            draw.line((seam, y + 3, seam, y + 30), fill=(30, 20, 14), width=2)
            for _ in range(7):
                gx = rng.randrange(128)
                gy = y + rng.randrange(4, 29)
                draw.line((gx, gy, min(127, gx + rng.randrange(7, 30)), gy),
                          fill=(rng.randrange(38, 60), rng.randrange(25, 40), rng.randrange(16, 27)), width=1)
        draw.line((0, 127, 127, 127), fill=(23, 16, 12), width=2)
        atlas.paste(tile, ((variant % 4) * 128, (variant // 4) * 128))
    atlas.save(ROOT / "cabin_floor_atlas.jpg", quality=90, optimize=True, progressive=False)


def build_monster_atlas() -> None:
    source = Image.open(OGA / "Organic_Matter_002_COLOR.jpg").convert("RGB")
    # One dark, irregular organic surface; each creature gets its own restrained horror palette.
    palettes = [
        ((17, 21, 25), (113, 128, 119)),  # Esvaziado: cold, drained flesh
        ((19, 7, 9), (145, 44, 32)),      # Rastejante: bruised red tissue
        ((29, 31, 35), (184, 187, 175)),  # Estátua: cracked pale shell
        ((8, 5, 14), (83, 33, 107)),      # Sombra: violet-black membrane
    ]
    atlas = Image.new("RGB", (512, 512), (14, 12, 16))
    for idx, (shadow, light) in enumerate(palettes):
        crop = source.crop((0, 0, source.width, source.height)).resize((252, 252), Image.Resampling.LANCZOS)
        gray = ImageOps.grayscale(crop)
        material = ImageOps.colorize(gray, black=shadow, white=light).convert("RGB")
        material = ImageEnhance.Contrast(material).enhance(1.28 if idx != 2 else 1.36)
        material = ImageEnhance.Color(material).enhance(1.12)
        x = (idx % 2) * 256 + 2
        y = (idx // 2) * 256 + 2
        atlas.paste(material, (x, y))
        atlas.paste(material.crop((0, 0, material.width, 1)).resize((material.width, 2)), (x, y - 2))
        atlas.paste(material.crop((0, material.height - 1, material.width, material.height)).resize((material.width, 2)), (x, y + material.height))
        atlas.paste(material.crop((0, 0, 1, material.height)).resize((2, material.height)), (x - 2, y))
        atlas.paste(material.crop((material.width - 1, 0, material.width, material.height)).resize((2, material.height)), (x + material.width, y))
        for dx, dy, px, py in ((-2, -2, 0, 0), (material.width, -2, material.width - 1, 0),
                               (-2, material.height, 0, material.height - 1),
                               (material.width, material.height, material.width - 1, material.height - 1)):
            corner = material.crop((px, py, px + 1, py + 1)).resize((2, 2))
            atlas.paste(corner, (x + dx, y + dy))
    atlas.save(ROOT / "monster_skin_atlas.jpg", quality=90, optimize=True, progressive=False)


def build_marta_maps() -> None:
    shirt = Image.open(POLY / "fabric_pattern_05_col_01_1k.jpg").convert("RGB")
    shirt = ImageOps.fit(shirt, (256, 256), centering=(0.5, 0.5), method=Image.Resampling.LANCZOS)
    shirt = ImageEnhance.Brightness(shirt).enhance(0.58)
    shirt = ImageEnhance.Contrast(shirt).enhance(1.15)
    shirt.save(MARTA / "marta_shirt.jpg", quality=88, optimize=True)

    denim = Image.open(POLY / "denim_fabric_diff_1k.jpg").convert("RGB")
    denim = ImageOps.fit(denim, (256, 256), method=Image.Resampling.LANCZOS)
    denim = ImageEnhance.Brightness(denim).enhance(0.78)
    denim.save(MARTA / "marta_denim.jpg", quality=88, optimize=True)

    # Reuse a clean, enlarged skin patch from the CC0 NPC atlas. Texture remains matte
    # and neutral so the separate eyes, mouth and nose geometry stay readable.
    skin_source = Image.open(ASSETS / "third_party" / "stef_npc" / "ladyarms.jpg").convert("RGB")
    skin = skin_source.crop((259, 272, 293, 318)).resize((128, 128), Image.Resampling.LANCZOS)
    skin = ImageEnhance.Contrast(skin).enhance(1.12)
    skin.save(MARTA / "marta_skin.jpg", quality=88, optimize=True)


build_world_atlas()
build_bark_atlas()
build_cabin_floor_atlas()
build_monster_atlas()
build_marta_maps()
print(f"Generated compact GameMaker materials in {ROOT}")
