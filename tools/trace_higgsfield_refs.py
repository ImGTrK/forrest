"""Convert Higgsfield design references into small, inspectable pixel-art studies.

The generated contact sheets are visual references, not atlas-ready assets. This
script extracts selected shapes to native game sizes so they can be evaluated and
hand-polished before replacing any integrated PNG. It never writes into assets/.
"""

from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np

from draw_base_art import P


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "higgsfield"
OUT = SOURCE / "native_preview"

# Source sheet, snug source rectangle, native target, background, outline,
# optional rotation and whether a narrow inventory slot should fill its height.
STUDIES = {
    "hero_front": ("characters_reference.png", (85, 145, 335, 520), (16, 16), None, "ink", 0, True),
    "hero_side": ("characters_reference.png", (420, 145, 670, 520), (16, 16), None, "ink", 0, True),
    "hero_back": ("characters_reference.png", (745, 145, 970, 515), (16, 16), None, "ink", 0, True),
    "enemy_open": ("characters_reference.png", (165, 625, 460, 905), (16, 16), None, "ink", 0, False),
    "enemy_blink": ("characters_reference.png", (565, 625, 865, 905), (16, 16), None, "ink", 0, False),
    "tree": ("environment_reference.png", (15, 75, 415, 495), (32, 32), (254, 243, 226), "brown_dark", 0, False),
    "bush": ("environment_reference.png", (425, 355, 610, 505), (16, 16), (254, 243, 226), "brown_dark", 0, False),
    "rock": ("environment_reference.png", (665, 365, 790, 500), (16, 16), (254, 243, 226), "ink", 0, False),
    "iron_vein": ("environment_reference.png", (840, 365, 990, 500), (16, 16), (254, 243, 226), "ink", 0, False),
    "chest": ("items_reference.png", (45, 230, 205, 375), (16, 16), (253, 234, 198), "ink", 0, False),
    "bed": ("items_reference.png", (240, 100, 405, 385), (16, 32), (253, 234, 198), "ink", 0, True),
    "bench": ("items_reference.png", (420, 215, 700, 390), (32, 16), (253, 234, 198), "ink", 0, True),
    "board": ("items_reference.png", (710, 105, 995, 390), (32, 32), (253, 234, 198), "ink", 0, False),
    "wood": ("items_reference.png", (35, 495, 190, 630), (16, 32), (253, 234, 198), "ink", 90, True),
    "stone": ("items_reference.png", (210, 520, 350, 640), (16, 16), (253, 234, 198), "ink", 0, False),
    "iron": ("items_reference.png", (375, 510, 520, 645), (16, 16), (253, 234, 198), "ink", 0, False),
    "stone_axe": ("items_reference.png", (535, 485, 665, 655), (16, 32), (253, 234, 198), "ink", 0, True),
    "stone_pickaxe": ("items_reference.png", (685, 485, 870, 655), (16, 32), (253, 234, 198), "ink", 0, True),
    "wood_sword": ("items_reference.png", (865, 470, 990, 660), (16, 32), (253, 234, 198), "ink", 0, True),
    "iron_axe": ("items_reference.png", (25, 725, 175, 950), (16, 32), (253, 234, 198), "ink", 0, True),
    "iron_pickaxe": ("items_reference.png", (165, 725, 335, 950), (16, 32), (253, 234, 198), "ink", 0, True),
    "iron_sword": ("items_reference.png", (335, 700, 430, 950), (16, 32), (253, 234, 198), "ink", 0, True),
    "lantern": ("items_reference.png", (460, 760, 590, 950), (16, 16), (253, 234, 198), "ink", 0, True),
    "oil": ("items_reference.png", (600, 760, 720, 950), (16, 16), (253, 234, 198), "ink", 0, True),
    "heart_full": ("items_reference.png", (725, 815, 825, 920), (16, 16), (253, 234, 198), "ink", 0, False),
    "heart_half": ("items_reference.png", (820, 815, 925, 920), (16, 16), (253, 234, 198), "ink", 0, False),
    "heart_empty": ("items_reference.png", (915, 815, 1010, 920), (16, 16), (253, 234, 198), "ink", 0, False),
    # Second, smaller-sheet pass requested at the actual game cell sizes.
    "focus_stone": ("items_sheet_attempt_16px.png", (45, 140, 270, 350), (16, 16), None, "ink", 0, False),
    "focus_stone_axe": ("items_sheet_attempt_16px.png", (285, 125, 510, 485), (16, 32), None, "ink", 0, True),
    "focus_iron_sword": ("items_sheet_attempt_16px.png", (525, 125, 705, 485), (16, 32), None, "ink", 0, True),
    "focus_heart_full": ("items_sheet_attempt_16px.png", (745, 135, 960, 355), (16, 16), None, "ink", 0, False),
    "focus_chest": ("items_sheet_attempt_16px.png", (35, 530, 275, 810), (16, 16), None, "ink", 0, False),
    "focus_bed": ("items_sheet_attempt_16px.png", (280, 510, 510, 910), (16, 32), None, "ink", 0, True),
    "focus_bench": ("items_sheet_attempt_16px.png", (510, 550, 930, 855), (32, 16), None, "ink", 0, True),
    "focus_hero_front": ("player_three_views_16px.png", (55, 325, 350, 730), (16, 16), None, "ink", 0, True),
    "focus_hero_side": ("player_three_views_16px.png", (365, 325, 655, 730), (16, 16), None, "ink", 0, True),
    "focus_hero_back": ("player_three_views_16px.png", (690, 325, 965, 730), (16, 16), None, "ink", 0, True),
    "focus_enemy_blink": ("enemy_sheet_attempt_16px.png", (75, 300, 485, 715), (16, 16), None, "ink", 0, True),
    "focus_enemy_open": ("enemy_sheet_attempt_16px.png", (550, 300, 965, 715), (16, 16), None, "ink", 0, True),
}


def remove_background(crop, base):
    if base is None:
        return crop.convert("RGBA")
    rgb = np.array(crop.convert("RGB"), dtype=np.int16)
    base_rgb = np.array(base, dtype=np.int16)
    candidate = (np.max(np.abs(rgb - base_rgb), axis=2) <= 30).astype("uint8") * 255
    # Padding joins every exterior patch of paper; enclosed cream details remain.
    background = Image.new("L", (crop.width + 2, crop.height + 2), 255)
    background.paste(Image.fromarray(candidate, "L"), (1, 1))
    ImageDraw.floodfill(background, (0, 0), 128, thresh=0)
    flooded = np.array(background.crop((1, 1, crop.width + 1, crop.height + 1)))
    keep = (flooded != 128).astype("uint8") * 255
    result = crop.convert("RGBA")
    result.putalpha(Image.fromarray(keep, "L"))
    return result


def quantize_native(image, size, outline, rotation, stretch):
    if rotation:
        image = image.rotate(rotation, expand=True)
    alpha = image.getchannel("A")
    box = alpha.point(lambda a: 255 if a >= 128 else 0).getbbox()
    if not box:
        raise ValueError("Empty extracted shape")
    image = image.crop(box)
    w, h = size
    max_w, max_h = w - 2, h - 2
    # Keep the outer silhouette and use the available cell, without smoothing.
    if stretch:
        small_size = (max_w, max_h)
    else:
        ratio = min(max_w / image.width, max_h / image.height)
        small_size = (max(1, round(image.width * ratio)), max(1, round(image.height * ratio)))
    small = image.resize(small_size, Image.Resampling.BOX)
    rgba = np.array(small, dtype=np.uint8)
    rgb = rgba[:, :, :3].astype(np.int32)
    palette = np.array([tuple(bytes.fromhex(c[1:])) for c in P.values()], dtype=np.int32)
    nearest = ((rgb[:, :, None, :] - palette[None, None, :, :]) ** 2).sum(axis=3).argmin(axis=2)
    mapped = palette[nearest].astype(np.uint8)
    opaque = rgba[:, :, 3] >= 128
    edge = opaque.copy()
    edge[1:, :] &= opaque[:-1, :]
    edge[:-1, :] &= opaque[1:, :]
    edge[:, 1:] &= opaque[:, :-1]
    edge[:, :-1] &= opaque[:, 1:]
    mapped[opaque & ~edge] = tuple(bytes.fromhex(P[outline][1:]))
    out = np.zeros((h, w, 4), dtype=np.uint8)
    x = (w - small_size[0]) // 2
    y = h - 1 - small_size[1] if h >= 30 else (h - small_size[1]) // 2
    out[y:y + small_size[1], x:x + small_size[0], :3] = mapped
    out[y:y + small_size[1], x:x + small_size[0], 3] = opaque.astype(np.uint8) * 255
    return Image.fromarray(out, "RGBA")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    generated = {}
    for name, (file, box, size, bg, outline, rotation, stretch) in STUDIES.items():
        image = Image.open(SOURCE / file).convert("RGBA").crop(box)
        image = remove_background(image, bg)
        native = quantize_native(image, size, outline, rotation, stretch)
        native.save(OUT / f"{name}.png")
        generated[name] = native
    sheet = Image.new("RGB", (7 * 144, ((len(generated) + 6) // 7) * 144), P["cream"])
    d = ImageDraw.Draw(sheet)
    for i, (name, native) in enumerate(generated.items()):
        x, y = i % 7 * 144, i // 7 * 144
        d.rectangle((x + 4, y + 4, x + 139, y + 139), fill=P["plum"])
        scale = min(5, 126 // native.width, 115 // native.height)
        large = native.resize((native.width * scale, native.height * scale), Image.Resampling.NEAREST)
        sheet.paste(large, (x + 72 - large.width // 2, y + 64 - large.height // 2), large)
        d.text((x + 8, y + 121), name, fill=P["cream"])
    sheet.save(SOURCE / "native_studies.png")
    print(f"Wrote {len(generated)} native-size studies and contact sheet")


if __name__ == "__main__":
    main()
