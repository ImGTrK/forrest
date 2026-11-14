"""Rebuild Forrest's integrated native PNGs from the Higgsfield art studies.

The generated images in docs/higgsfield are design references. This script
traces their strongest shapes to exact Godot dimensions, then makes explicit
one-pixel corrections for readability. It intentionally overwrites 32 assets.
Run `python -B tools/trace_higgsfield_refs.py` first when source art changes.
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageOps
import numpy as np

import draw_base_art as base


ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / "docs" / "higgsfield" / "native_preview"
P = base.P


def study(name):
    return Image.open(NATIVE / f"{name}.png").convert("RGBA")


def rectangle(draw, xy, name):
    draw.rectangle(xy, fill=P.get(name, name))


def polygon(draw, xy, name):
    draw.polygon(xy, fill=P.get(name, name))


def flower(draw, x, y, large=False):
    if large:
        for px, py in ((x - 2, y), (x + 2, y), (x, y - 2), (x, y + 2)):
            rectangle(draw, (px, py, px + 1, py + 1), "flower_pink")
        rectangle(draw, (x - 1, y - 1, x + 1, y + 1), "flower_light")
    else:
        for px, py in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            rectangle(draw, (px, py, px, py), "flower_pink")
        rectangle(draw, (x, y, x, y), "gold_light")
    rectangle(draw, (x, y, x, y), "gold")


def flowering_tree():
    im = study("tree")
    d = ImageDraw.Draw(im)
    # The generated tree lost its pink spots at 32 px. Restore five readable
    # clusters and widen the trunk just enough to survive the 2x2 tile cell.
    polygon(d, [(13, 24), (18, 24), (19, 29), (17, 31), (13, 31), (12, 29)], "brown_dark")
    rectangle(d, (14, 25, 17, 29), "bark")
    rectangle(d, (14, 25, 14, 29), "wood_light")
    rectangle(d, (17, 27, 17, 30), "brown")
    for x, y, big in ((8, 10, True), (21, 8, False), (15, 16, True),
                      (25, 18, False), (6, 20, False)):
        flower(d, x, y, big)
    return im


def flowering_bush():
    im = study("bush")
    d = ImageDraw.Draw(im)
    rectangle(d, (4, 12, 12, 13), "leaf_dark")
    flower(d, 5, 6)
    flower(d, 10, 9)
    return im


def vein():
    im = study("iron_vein")
    d = ImageDraw.Draw(im)
    rectangle(d, (6, 4, 7, 5), "ore_glint")
    rectangle(d, (10, 7, 11, 8), "ore_blue")
    rectangle(d, (11, 6, 11, 6), "white")
    return im


def player_frame(direction, frame, moving):
    """Eight readable directions, four idle and four walk frames per row."""
    mirrored = direction in (1, 2, 3)
    view = {0: "front", 1: "front_angle", 2: "side", 3: "back_angle",
            4: "back", 5: "back_angle", 6: "side", 7: "front_angle"}[direction]
    im = Image.new("RGBA", (16, 16))
    d = ImageDraw.Draw(im)
    stride = (-1, 0, 1, 0)[frame] if moving else 0
    arm = (1, -1, -1, 1)[frame] if moving else 0
    scarf_sway = 1 if frame == 1 else -1 if frame == 3 else 0

    # Feet are anchored at y=15 so collision alignment stays stable.
    if view in ("front", "back"):
        rectangle(d, (4 + stride, 12, 7 + stride, 15), "ink")
        rectangle(d, (9 - stride, 12, 12 - stride, 15), "ink")
        rectangle(d, (5 + stride, 13, 6 + stride, 14), "brown")
        rectangle(d, (10 - stride, 13, 11 - stride, 14), "brown")
    else:
        rectangle(d, (5 + stride, 12, 8 + stride, 15), "ink")
        rectangle(d, (9 - stride, 12, 12 - stride, 15), "ink")
        rectangle(d, (6 + stride, 13, 7 + stride, 14), "brown")
        rectangle(d, (10 - stride, 13, 11 - stride, 14), "brown")

    # Body, backpack and leafy sprout from the generated concept.
    rectangle(d, (4, 8, 11, 13), "ink")
    rectangle(d, (5, 9, 10, 12), "cream")
    rectangle(d, (5, 9, 6, 10), "ivory")
    if view == "front":
        rectangle(d, (3, 9, 4, 12), "ink")
        rectangle(d, (3, 10, 3, 11), "bark")
        rectangle(d, (2, 7, 3, 8), "ink")
        rectangle(d, (2, 7, 3, 7), "leaf_light")
        for x, y in ((5, 10), (6, 11), (7, 11), (8, 12)):
            rectangle(d, (x, y, x, y), "brown")
    elif view == "back":
        rectangle(d, (5, 9, 10, 13), "ink")
        rectangle(d, (6, 10, 9, 12), "bark")
        rectangle(d, (7, 11, 8, 11), "honey")
        rectangle(d, (11, 8, 12, 9), "ink")
        rectangle(d, (12, 8, 13, 8), "leaf_light")
    else:
        rectangle(d, (2, 8, 6, 13), "ink")
        rectangle(d, (3, 9, 5, 12), "bark")
        rectangle(d, (4, 10, 4, 10), "gold")
        rectangle(d, (2, 7, 3, 8), "ink")
        rectangle(d, (2, 7, 3, 7), "leaf_light")
        rectangle(d, (3, 8, 4, 8), "jade_deep")

    # Hands and arms swing visibly while walking.
    if view in ("front", "back"):
        rectangle(d, (2, 9 + arm, 4, 12 + arm), "ink")
        rectangle(d, (11, 9 - arm, 13, 12 - arm), "ink")
        rectangle(d, (3, 10 + arm, 3, 11 + arm), "skin")
        rectangle(d, (12, 10 - arm, 12, 11 - arm), "skin")
    else:
        rectangle(d, (10, 9 - arm, 13, 12 - arm), "ink")
        rectangle(d, (11, 10 - arm, 12, 11 - arm), "skin")

    # Fluffy plum hair: one-pixel near-black silhouette and upper-left shine.
    polygon(d, [(6, 0), (8, 0), (9, 1), (11, 1), (11, 2),
                (13, 3), (13, 5), (12, 6), (11, 7), (4, 7),
                (2, 6), (2, 4), (3, 3), (3, 2), (5, 2), (5, 1)], "ink")
    polygon(d, [(6, 1), (8, 1), (9, 2), (10, 2), (12, 4),
                (11, 6), (4, 6), (3, 5), (4, 3), (5, 3)], "hair")
    rectangle(d, (6, 1, 8, 1), "hair_light")
    rectangle(d, (4, 3, 6, 3), "hair_light")
    rectangle(d, (5, 4, 5, 4), "hair_light")
    rectangle(d, (9, 5, 11, 5), "hair_dark")
    if view == "back":
        rectangle(d, (5, 6, 10, 7), "hair")
        rectangle(d, (9, 7, 10, 7), "hair_dark")
    elif view == "back_angle":
        rectangle(d, (5, 6, 10, 7), "hair")
        rectangle(d, (11, 6, 12, 8), "ink")
        rectangle(d, (11, 7, 11, 7), "skin")
    elif view == "side":
        rectangle(d, (9, 6, 12, 8), "ink")
        rectangle(d, (9, 6, 11, 8), "skin")
        rectangle(d, (11, 7, 11, 7), "ink" if not (not moving and frame == 2) else "brown")
    elif view == "front_angle":
        rectangle(d, (6, 6, 11, 8), "ink")
        rectangle(d, (7, 6, 10, 8), "skin")
        rectangle(d, (10, 7, 10, 7), "ink" if not (not moving and frame == 2) else "brown")
    else:
        rectangle(d, (5, 6, 10, 8), "ink")
        rectangle(d, (5, 6, 10, 8), "skin")
        rectangle(d, (6, 7, 6, 7), "ink" if not (not moving and frame == 2) else "brown")
        rectangle(d, (9, 7, 9, 7), "ink" if not (not moving and frame == 2) else "brown")
    # Bangs keep the head's original asymmetry without covering the eye.
    rectangle(d, (4, 5, 5, 5), "hair_dark")
    rectangle(d, (8, 5, 9, 5), "hair_dark")

    # Red is reserved for this scarf and danger. Its tail flutters per frame.
    rectangle(d, (4, 9, 11, 9), "ink")
    rectangle(d, (5, 9, 10, 9), "red")
    if view in ("front", "front_angle"):
        rectangle(d, (12, 9 + scarf_sway, 14, 11 + scarf_sway), "ink")
        rectangle(d, (12, 9 + scarf_sway, 13, 10 + scarf_sway), "red")
    elif view == "back":
        rectangle(d, (2, 9 + scarf_sway, 4, 10 + scarf_sway), "ink")
        rectangle(d, (3, 9 + scarf_sway, 4, 9 + scarf_sway), "red")
    else:
        rectangle(d, (3, 9 + scarf_sway, 5, 10 + scarf_sway), "red_dark")
    hair_study = study({"front": "focus_hero_front", "front_angle": "focus_hero_front",
                        "side": "focus_hero_side", "back_angle": "focus_hero_back",
                        "back": "focus_hero_back"}[view])
    for y in range(7):
        for x in range(16):
            px = hair_study.getpixel((x, y))
            if px[3]:
                im.putpixel((x, y), px)
    if not moving and frame == 2 and view in ("back", "back_angle"):
        # A tiny hair glint replaces the invisible blink in rear-facing poses.
        rectangle(d, (7, 2, 8, 2), "hair_light")
    if mirrored:
        im = ImageOps.mirror(im)
    return im


def player_sheet():
    source = Image.open(ROOT / "docs" / "higgsfield" / "player_sheet_attempt_16px.png").convert("RGBA")
    if source.size != (1024, 1024):
        raise ValueError("Higgsfield player sheet must have eight 128 px cells per side")
    palette = np.array([tuple(bytes.fromhex(color[1:])) for color in P.values()], dtype=np.int32)
    im = Image.new("RGBA", (256, 256))
    for row in range(8):
        for col in range(8):
            # The left-facing rows in the generated sheet drifted toward front
            # views. Mirror the coherent right-facing counterparts instead.
            source_row = {1: 7, 2: 6, 3: 5}.get(row, row)
            cell = source.crop((col * 128, source_row * 128,
                                (col + 1) * 128, (source_row + 1) * 128))
            cell = cell.resize((32, 32), Image.Resampling.BOX)
            if row in (1, 2, 3):
                cell = ImageOps.mirror(cell)
            rgba = np.array(cell, dtype=np.uint8)
            rgb = rgba[:, :, :3].astype(np.int32)
            nearest = ((rgb[:, :, None, :] - palette[None, None, :, :]) ** 2).sum(axis=3).argmin(axis=2)
            rgba[:, :, :3] = palette[nearest].astype(np.uint8)
            rgba[:, :, 3] = (rgba[:, :, 3] >= 128).astype(np.uint8) * 255
            im.alpha_composite(Image.fromarray(rgba, "RGBA"), (col * 32, row * 32))
    return im


def enemy_sheet():
    out = Image.new("RGBA", (32, 16))
    for frame, name in enumerate(("focus_enemy_blink", "focus_enemy_open")):
        im = study(name)
        d = ImageDraw.Draw(im)
        # Restore the strong eye/blink and pink snout lost to reduction.
        rectangle(d, (10, 8, 13, 10), "skin")
        if frame:
            rectangle(d, (11, 8, 11, 9), "ink")
            rectangle(d, (11, 8, 11, 8), "white")
        else:
            rectangle(d, (10, 9, 12, 9), "ink")
        rectangle(d, (5, 4, 6, 5), "jade_bright")
        out.alpha_composite(im, (frame * 16, 0))
    return out


def iron_tool_from(name):
    im = study(name)
    px = im.load()
    stone_to_iron = {
        P["stone_light"].upper(): P["ore_glint"],
        P["stone"].upper(): P["iron_light"],
        P["stone_dark"].upper(): P["ore_blue"],
    }
    for y in range(min(15, im.height)):
        for x in range(im.width):
            rgb = "#%02X%02X%02X" % px[x, y][:3]
            if rgb in stone_to_iron and px[x, y][3]:
                replacement = stone_to_iron[rgb]
                px[x, y] = tuple(bytes.fromhex(replacement[1:])) + (255,)
    return im


def heart_set():
    full = study("focus_heart_full")
    states = {"heart_full": full}
    for name in ("heart_half", "heart_empty"):
        im = full.copy()
        pix = im.load()
        for y in range(im.height):
            for x in range(im.width):
                if not pix[x, y][3]:
                    continue
                if pix[x, y][:3] == tuple(bytes.fromhex(P["ink"][1:])):
                    continue
                if name == "heart_empty" or x >= 8:
                    pix[x, y] = tuple(bytes.fromhex(P["cream"][1:])) + (255,)
        states[name] = im
    return states


def build():
    # Rebuild the quiet HUD, four terrain tiles and sword from the same native
    # shapes. Every integrated PNG is then replaced below where the references
    # yielded a stronger design at the contracted size.
    base.build()
    assets = {
        "assets/sprites/player/player.png": player_sheet(),
        "assets/sprites/enemies/enemy_basic.png": enemy_sheet(),
        "assets/sprites/world/tree.png": flowering_tree(),
        "assets/sprites/world/bush.png": flowering_bush(),
        "assets/sprites/world/rock.png": study("rock"),
        "assets/sprites/world/iron_vein.png": vein(),
        "assets/sprites/world/chest.png": study("focus_chest"),
        "assets/sprites/world/bed.png": study("focus_bed"),
        "assets/sprites/world/bench.png": study("focus_bench"),
        "assets/sprites/world/board.png": study("board"),
        "assets/sprites/items/wood.png": study("wood"),
        "assets/sprites/items/stone.png": study("focus_stone"),
        "assets/sprites/items/iron.png": study("iron"),
        "assets/sprites/items/stone_axe.png": study("focus_stone_axe"),
        "assets/sprites/items/stone_pickaxe.png": study("stone_pickaxe"),
        "assets/sprites/items/wood_sword.png": study("wood_sword"),
        "assets/sprites/items/iron_axe.png": iron_tool_from("focus_stone_axe"),
        "assets/sprites/items/iron_pickaxe.png": iron_tool_from("stone_pickaxe"),
        "assets/sprites/items/iron_sword.png": study("focus_iron_sword"),
        "assets/sprites/items/lantern.png": study("lantern"),
        "assets/sprites/items/oil.png": study("oil"),
    }
    for name, im in heart_set().items():
        assets[f"assets/sprites/ui/hearts/{name}.png"] = im
    for path, im in assets.items():
        if im.size != base.SIZES[path]:
            raise ValueError(f"{path}: {im.size} != {base.SIZES[path]}")
        if im.getchannel("A").getextrema()[1] != 255:
            raise ValueError(f"{path}: no opaque pixels")
        im.save(ROOT / path)
    print(f"Wrote {len(base.SIZES)} integrated sprites; {len(assets)} refined from Higgsfield references")


if __name__ == "__main__":
    build()
