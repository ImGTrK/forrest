"""Original, editable pixel-art bases for the 32 currently integrated PNGs.

Run with ``python tools/draw_base_art.py``. This intentionally overwrites the
listed PNGs; keep edited versions in version control before regenerating.
Every shape is drawn at native resolution, with no resampling or antialiasing.
"""

from pathlib import Path
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
P = {
    "ink": "#211C2B",       # near-black for actors and usable objects
    "plum": "#3B2D45",      # UI and depth shadow
    "brown_dark": "#4B373B",  # 1 px environment outlines
    "brown": "#744B46",
    "bark": "#9A6550",
    "wood_light": "#D1996D",
    "grass_dark": "#5E8869",
    "grass": "#84AB78",
    "grass_light": "#B8D18E",
    "leaf_dark": "#2B6653",
    "leaf": "#4C9465",
    "leaf_light": "#90C57B",
    "pale_leaf": "#D4E2A1",
    "cream": "#F6E3BE",
    "ivory": "#FFF1D6",
    "sand": "#E8C69C",
    "path": "#D8AD82",
    "path_shadow": "#B88064",
    "blush": "#F2BAC5",
    "rose": "#E390A8",
    "red": "#D34B55",
    "red_dark": "#963D4D",
    "stone_dark": "#596574",
    "stone": "#939DA6",
    "stone_light": "#D0D2D1",
    "iron": "#47738A",
    "iron_light": "#93BDCE",
    "gold": "#E5BA6B",
    "gold_light": "#FFE1A0",
    "white": "#F4F0E8",  # untinted bars and tiny glints
    # Brighter clustered accents derived from the approved Higgsfield studies.
    "jade_deep": "#245848",
    "jade_bright": "#72B36C",
    "leaf_sun": "#B9D88B",
    "flower_light": "#FFE0DE",
    "flower_pink": "#F8A9BC",
    "ore_blue": "#376E96",
    "ore_glint": "#80C9E8",
    "honey": "#D4A258",
    "hair_dark": "#2E253A",
    "hair": "#52364F",
    "hair_light": "#80566E",
    "skin": "#F5CBA3",
}

SIZES = {
    "assets/tilesets/terrain.png": (64, 16),
    "assets/sprites/player/player.png": (256, 256),
    "assets/sprites/player/sword.png": (16, 16),
    "assets/sprites/enemies/enemy_basic.png": (32, 16),
    "assets/sprites/world/tree.png": (32, 32),
    "assets/sprites/world/rock.png": (16, 16),
    "assets/sprites/world/iron_vein.png": (16, 16),
    "assets/sprites/world/bush.png": (16, 16),
    "assets/sprites/world/chest.png": (16, 16),
    "assets/sprites/world/bed.png": (16, 32),
    "assets/sprites/world/bench.png": (32, 16),
    "assets/sprites/world/board.png": (32, 32),
    "assets/sprites/items/wood.png": (16, 32),
    "assets/sprites/items/stone.png": (16, 16),
    "assets/sprites/items/iron.png": (16, 16),
    "assets/sprites/items/stone_axe.png": (16, 32),
    "assets/sprites/items/stone_pickaxe.png": (16, 32),
    "assets/sprites/items/wood_sword.png": (16, 32),
    "assets/sprites/items/iron_axe.png": (16, 32),
    "assets/sprites/items/iron_pickaxe.png": (16, 32),
    "assets/sprites/items/iron_sword.png": (16, 32),
    "assets/sprites/items/lantern.png": (16, 16),
    "assets/sprites/items/oil.png": (16, 16),
    "assets/sprites/ui/hearts/heart_full.png": (16, 16),
    "assets/sprites/ui/hearts/heart_half.png": (16, 16),
    "assets/sprites/ui/hearts/heart_empty.png": (16, 16),
    "assets/sprites/ui/slot.png": (18, 18),
    "assets/sprites/ui/icon_clock.png": (8, 8),
    "assets/sprites/ui/icon_energy.png": (8, 8),
    "assets/sprites/ui/icon_weight.png": (8, 8),
    "assets/sprites/ui/energy_bar_under.png": (64, 8),
    "assets/sprites/ui/energy_bar_fill.png": (64, 8),
}


def canvas(size):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    return image, ImageDraw.Draw(image)


def rect(d, box, color):
    d.rectangle(box, fill=P.get(color, color))


def poly(d, points, color):
    d.polygon(points, fill=P.get(color, color))


def ell(d, box, color):
    d.ellipse(box, fill=P.get(color, color))


def blossom(d, x, y, center="gold"):
    # Five pixels, legible at native size; no blurry particle effects.
    for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
        rect(d, (x + dx, y + dy, x + dx, y + dy), "blush")
    rect(d, (x, y, x, y), center)


def terrain():
    im, d = canvas((64, 16))
    # Grass: repeatable base, few flecks to keep the 16 px pattern calm.
    rect(d, (0, 0, 15, 15), "grass")
    rect(d, (3, 4, 4, 4), "grass_light")
    rect(d, (11, 12, 11, 13), "grass_dark")
    # Dense foliage in broad interlocking bands; no circular tile-grid motif.
    rect(d, (16, 0, 31, 15), "leaf_dark")
    poly(d, [(16, 3), (19, 3), (20, 1), (24, 2), (27, 0), (31, 2),
             (31, 7), (28, 6), (26, 8), (21, 6), (18, 8), (16, 7)], "leaf")
    poly(d, [(16, 10), (19, 9), (22, 11), (26, 8), (29, 10), (31, 9),
             (31, 14), (28, 13), (24, 15), (20, 13), (16, 15)], "leaf")
    rect(d, (18, 3, 20, 3), "leaf_light")
    rect(d, (26, 4, 29, 4), "leaf_light")
    rect(d, (21, 11, 23, 11), "leaf_light")
    rect(d, (17, 15, 30, 15), "brown_dark")
    # Village floor: warm cream blocks, not a second grass tile.
    rect(d, (32, 0, 47, 15), "sand")
    rect(d, (32, 0, 47, 0), "cream")
    rect(d, (32, 8, 47, 8), "path")
    rect(d, (39, 0, 39, 7), "path")
    rect(d, (35, 9, 35, 15), "path")
    rect(d, (43, 9, 43, 15), "path")
    # Path: full-bleed so corridors join in all four directions.
    rect(d, (48, 0, 63, 15), "cream")
    for x, y in ((50, 3), (59, 5), (54, 11), (62, 13)):
        rect(d, (x, y, x + 1, y), "sand")
    rect(d, (57, 10, 57, 10), "path")
    return im


def tree():
    im, d = canvas((32, 32))
    # Transparent shadow stays inside the 2x2 footprint.
    ell(d, (6, 27, 29, 31), (60, 52, 72, 90))
    poly(d, [(12, 18), (21, 18), (22, 29), (20, 31), (12, 31), (11, 28)], "brown_dark")
    rect(d, (14, 19, 20, 29), "bark")
    rect(d, (15, 21, 16, 28), "wood_light")
    rect(d, (19, 23, 20, 30), "brown")
    for box in ((2, 13, 17, 24), (10, 7, 27, 23), (4, 3, 23, 20)):
        ell(d, box, "brown_dark")
    for box in ((3, 12, 16, 22), (11, 7, 26, 21), (5, 3, 22, 18)):
        ell(d, box, "leaf_dark")
    for box in ((4, 9, 17, 17), (8, 4, 20, 13), (14, 10, 25, 17)):
        ell(d, box, "leaf")
    for box in ((6, 5, 14, 9), (14, 6, 20, 9), (6, 12, 11, 14), (17, 12, 23, 14)):
        ell(d, box, "leaf_light")
    for x, y in ((8, 7), (19, 8), (13, 14), (23, 14), (5, 17)):
        blossom(d, x, y)
    rect(d, (6, 4, 11, 4), "pale_leaf")
    return im


def rock(iron=False):
    im, d = canvas((16, 16))
    ell(d, (2, 12, 14, 15), (60, 52, 72, 75))
    poly(d, [(1, 11), (3, 6), (7, 3), (12, 4), (15, 9), (13, 13), (4, 14)], "ink")
    poly(d, [(2, 10), (4, 6), (7, 4), (11, 5), (13, 9), (12, 12), (4, 13)], "stone_dark")
    poly(d, [(4, 6), (7, 4), (10, 5), (7, 9), (3, 10)], "stone_light")
    poly(d, [(8, 9), (12, 6), (13, 10), (11, 12), (6, 12)], "stone")
    if iron:
        for points in ([(5, 7), (7, 6), (8, 8), (7, 11), (6, 10)], [(10, 5), (12, 6), (11, 8), (9, 10), (8, 9)]):
            poly(d, points, "iron")
        rect(d, (6, 7, 6, 8), "iron_light")
        rect(d, (10, 6, 10, 7), "iron_light")
        rect(d, (12, 9, 12, 9), "white")
    return im


def bush():
    im, d = canvas((16, 16))
    ell(d, (1, 12, 14, 15), (60, 52, 72, 70))
    for box in ((1, 6, 10, 14), (5, 3, 14, 13), (3, 1, 11, 10)):
        ell(d, box, "brown_dark")
    for box in ((2, 6, 9, 13), (6, 4, 13, 12), (4, 2, 10, 9)):
        ell(d, box, "leaf_dark")
    ell(d, (4, 3, 8, 6), "leaf_light")
    rect(d, (9, 5, 11, 5), "leaf")
    blossom(d, 4, 9)
    blossom(d, 10, 8)
    return im


def chest():
    im, d = canvas((16, 16))
    ell(d, (1, 13, 15, 15), (60, 52, 72, 70))
    rect(d, (1, 5, 14, 13), "ink")
    rect(d, (2, 6, 13, 12), "brown")
    rect(d, (2, 7, 13, 8), "bark")
    rect(d, (3, 10, 12, 12), "brown_dark")
    rect(d, (2, 4, 13, 5), "ink")
    rect(d, (3, 3, 12, 4), "wood_light")
    rect(d, (3, 5, 4, 12), "gold")
    rect(d, (11, 5, 12, 12), "gold")
    rect(d, (7, 6, 9, 10), "ink")
    rect(d, (7, 7, 8, 9), "gold_light")
    return im


def bed():
    im, d = canvas((16, 32))
    rect(d, (2, 1, 13, 30), "ink")
    rect(d, (3, 2, 12, 29), "brown")
    rect(d, (4, 4, 11, 26), "cream")
    rect(d, (4, 5, 11, 10), "ivory")
    rect(d, (4, 11, 11, 25), "rose")
    rect(d, (4, 13, 11, 20), "red")
    rect(d, (5, 13, 6, 23), "blush")
    rect(d, (4, 24, 11, 26), "red_dark")
    rect(d, (2, 2, 3, 30), "wood_light")
    rect(d, (12, 2, 13, 30), "wood_light")
    rect(d, (4, 2, 11, 3), "wood_light")
    return im


def bench():
    im, d = canvas((32, 16))
    ell(d, (2, 12, 30, 15), (60, 52, 72, 70))
    rect(d, (2, 5, 29, 11), "ink")
    rect(d, (3, 5, 28, 9), "bark")
    rect(d, (4, 6, 27, 7), "wood_light")
    rect(d, (4, 10, 7, 14), "ink")
    rect(d, (24, 10, 27, 14), "ink")
    rect(d, (5, 10, 6, 13), "brown")
    rect(d, (25, 10, 26, 13), "brown")
    rect(d, (12, 3, 15, 5), "stone_dark")
    rect(d, (13, 2, 14, 3), "stone_light")
    rect(d, (18, 4, 25, 5), "iron")
    rect(d, (21, 2, 22, 5), "wood_light")
    return im


def board():
    im, d = canvas((32, 32))
    ell(d, (3, 28, 29, 31), (60, 52, 72, 65))
    rect(d, (5, 5, 8, 30), "ink")
    rect(d, (23, 5, 26, 30), "ink")
    rect(d, (6, 6, 7, 29), "bark")
    rect(d, (24, 6, 25, 29), "bark")
    rect(d, (3, 5, 28, 23), "ink")
    rect(d, (4, 6, 27, 22), "brown")
    rect(d, (5, 7, 26, 8), "wood_light")
    rect(d, (5, 20, 26, 21), "brown_dark")
    for x, y, w, h in ((7, 10, 7, 7), (17, 9, 8, 9), (12, 15, 8, 5)):
        rect(d, (x, y, x + w, y + h), "ink")
        rect(d, (x + 1, y + 1, x + w - 1, y + h - 1), "cream")
        rect(d, (x + 2, y + 3, x + w - 2, y + 3), "path_shadow")
        rect(d, (x + 1, y + 1, x + 1, y + 1), "red")
    return im


def player_frame(direction, frame, moving):
    im, d = canvas((16, 16))
    back = direction in (3, 4, 5)
    left = direction in (1, 2, 3)
    right = direction in (5, 6, 7)
    bob = 1 if (moving and frame in (1, 3)) or (not moving and frame == 2) else 0
    stride = (-1, 0, 1, 0)[frame] if moving else 0
    # Backpack silhouette first, so actor retains a distinct outline at 1x.
    rect(d, (3 if not left else 9, 7 + bob, 5 if not left else 12, 11 + bob), "ink")
    rect(d, (4 if not left else 10, 7 + bob, 5 if not left else 11, 10 + bob), "bark")
    # Boots and trousers.
    rect(d, (4 + stride, 11 + bob, 6 + stride, 14), "ink")
    rect(d, (9 - stride, 11 + bob, 11 - stride, 14), "ink")
    rect(d, (5 + stride, 12 + bob, 6 + stride, 13), "brown")
    rect(d, (9 - stride, 12 + bob, 10 - stride, 13), "brown")
    rect(d, (4, 7 + bob, 11, 12 + bob), "ink")
    rect(d, (5, 8 + bob, 10, 11 + bob), "cream")
    rect(d, (6, 10 + bob, 10, 11 + bob), "brown")
    # Arms shift opposite to the legs while walking.
    arm = (1, -1, -1, 1)[frame] if moving else 0
    rect(d, (3, 8 + bob + arm, 4, 10 + bob + arm), "ink")
    rect(d, (11, 8 + bob - arm, 12, 10 + bob - arm), "ink")
    rect(d, (4, 9 + bob + arm, 4, 9 + bob + arm), "sand")
    rect(d, (11, 9 + bob - arm, 11, 9 + bob - arm), "sand")
    # Head and hair. Rear view has no face; sides have one eye.
    rect(d, (4, 2 + bob, 11, 8 + bob), "ink")
    rect(d, (5, 3 + bob, 10, 7 + bob), "sand" if not back else "brown")
    rect(d, (4, 2 + bob, 11, 4 + bob), "brown_dark")
    rect(d, (5, 2 + bob, 9, 2 + bob), "bark")
    rect(d, (4, 5 + bob, 4, 6 + bob), "brown_dark")
    if not back and not (not moving and frame == 2):
        if direction == 0:
            rect(d, (6, 6 + bob, 6, 6 + bob), "ink")
            rect(d, (9, 6 + bob, 9, 6 + bob), "ink")
        elif left:
            rect(d, (5, 6 + bob, 5, 6 + bob), "ink")
        elif right:
            rect(d, (10, 6 + bob, 10, 6 + bob), "ink")
    # Vermilion scarf is the hero's constant visual anchor.
    rect(d, (5, 8 + bob, 10, 8 + bob), "red")
    tail_x = 3 if right else 11
    tail_y = 8 + bob + (1 if not moving and frame == 1 else 0)
    rect(d, (tail_x, tail_y, tail_x + 1, tail_y + 2), "red_dark")
    rect(d, (tail_x, tail_y, tail_x, tail_y), "red")
    if not moving and frame == 3:
        rect(d, (6, 9 + bob, 9, 9 + bob), "blush")
    return im


def player_sheet():
    im, _ = canvas((256, 256))
    for row in range(8):
        for col in range(8):
            frame = player_frame(row, col % 4, col >= 4)
            frame = frame.resize((32, 32), Image.Resampling.NEAREST)
            im.alpha_composite(frame, (col * 32, row * 32))
    return im


def sword():
    im, d = canvas((16, 16))
    poly(d, [(7, 1), (9, 1), (10, 3), (9, 9), (7, 9), (6, 3)], "ink")
    rect(d, (7, 2, 8, 8), "stone_light")
    rect(d, (7, 2, 7, 7), "white")
    rect(d, (4, 9, 11, 10), "ink")
    rect(d, (5, 9, 10, 9), "gold")
    rect(d, (7, 10, 8, 14), "brown")
    rect(d, (6, 14, 9, 14), "ink")
    return im


def enemy():
    im, _ = canvas((32, 16))
    for frame in range(2):
        cell, d = canvas((16, 16))
        ell(d, (2, 12, 14, 15), (60, 52, 72, 70))
        poly(d, [(2, 9), (3, 6), (7, 5), (10, 6), (12, 8), (14, 8), (15, 11), (12, 13), (4, 13), (1, 11)], "ink")
        poly(d, [(3, 9), (4, 7), (7, 6), (10, 7), (12, 9), (14, 10), (12, 12), (4, 12)], "red_dark")
        rect(d, (3, 8, 7, 9), "brown")
        poly(d, [(8, 7), (12, 6), (14, 8), (14, 11), (11, 12), (8, 10)], "rose")
        poly(d, [(9, 7), (10, 3), (12, 6)], "ink")
        rect(d, (10, 4, 10, 6), "red")
        rect(d, (3, 12, 5, 14), "ink")
        rect(d, (10, 12, 12, 14), "ink")
        rect(d, (13, 10, 15, 11), "ink")
        rect(d, (13, 10, 14, 10), "blush")
        if frame == 1:
            rect(d, (11, 8, 12, 9), "ivory")
            rect(d, (12, 8, 12, 9), "ink")
        else:
            rect(d, (11, 9, 12, 9), "ink")
        im.alpha_composite(cell, (frame * 16, 0))
    return im


def wood_item():
    im, d = canvas((16, 32))
    rect(d, (4, 2, 12, 29), "ink")
    rect(d, (5, 3, 11, 28), "bark")
    rect(d, (6, 4, 7, 27), "wood_light")
    rect(d, (9, 6, 10, 26), "brown")
    rect(d, (4, 3, 12, 6), "brown_dark")
    rect(d, (5, 3, 11, 5), "sand")
    rect(d, (7, 4, 9, 4), "brown")
    rect(d, (4, 26, 12, 29), "brown_dark")
    rect(d, (5, 27, 11, 28), "sand")
    return im


def stone_item(iron=False):
    im, d = canvas((16, 16))
    poly(d, [(2, 6), (6, 3), (11, 4), (14, 8), (12, 13), (4, 13), (1, 10)], "ink")
    poly(d, [(3, 6), (6, 4), (10, 5), (12, 8), (11, 12), (4, 12), (2, 9)], "iron" if iron else "stone")
    poly(d, [(4, 6), (6, 4), (9, 5), (7, 8), (3, 8)], "iron_light" if iron else "stone_light")
    rect(d, (10, 9, 11, 11), "stone_dark")
    if iron:
        rect(d, (5, 6, 5, 6), "white")
        rect(d, (8, 7, 9, 8), "iron_light")
    return im


def tool_item(kind, material):
    im, d = canvas((16, 32))
    head = {"stone": "stone", "iron": "iron_light", "wood": "wood_light"}[material]
    head_shadow = {"stone": "stone_dark", "iron": "iron", "wood": "brown"}[material]
    # Diagonal warm wooden shaft runs through the whole 1x2 item silhouette.
    for y in range(7, 27):
        x = 10 - (y - 7) // 5
        rect(d, (x - 1, y, x + 1, y), "ink")
        rect(d, (x, y, x, y), "bark")
    rect(d, (5, 27, 8, 29), "ink")
    rect(d, (6, 27, 7, 28), "wood_light")
    if kind == "axe":
        poly(d, [(5, 4), (11, 3), (13, 7), (11, 12), (7, 11), (4, 9)], "ink")
        poly(d, [(5, 5), (10, 4), (12, 7), (10, 10), (7, 10), (5, 8)], head_shadow)
        rect(d, (5, 5, 7, 6), head)
        rect(d, (4, 7, 4, 9), head)
    elif kind == "pickaxe":
        poly(d, [(1, 7), (4, 4), (11, 3), (15, 6), (12, 9), (10, 7), (5, 8)], "ink")
        poly(d, [(2, 7), (5, 5), (11, 4), (14, 6), (11, 7), (5, 7)], head_shadow)
        rect(d, (4, 5, 10, 5), head)
        rect(d, (2, 6, 3, 6), head)
    else:  # sword
        poly(d, [(8, 2), (10, 2), (12, 5), (10, 19), (7, 19), (6, 6)], "ink")
        poly(d, [(8, 3), (10, 4), (10, 17), (8, 17), (7, 6)], head_shadow)
        rect(d, (8, 4, 8, 15), head)
        rect(d, (3, 18, 13, 20), "ink")
        rect(d, (4, 18, 12, 18), "gold" if material != "wood" else "wood_light")
        rect(d, (7, 19, 9, 27), "brown")
        rect(d, (6, 27, 10, 29), "ink")
    return im


def lantern():
    im, d = canvas((16, 16))
    rect(d, (5, 1, 10, 3), "ink")
    rect(d, (6, 1, 9, 2), "gold")
    rect(d, (3, 4, 12, 13), "ink")
    rect(d, (4, 5, 11, 12), "brown")
    rect(d, (5, 5, 10, 11), "gold")
    rect(d, (6, 6, 9, 10), "cream")
    rect(d, (7, 7, 8, 9), "gold_light")
    rect(d, (3, 12, 12, 14), "ink")
    rect(d, (5, 13, 10, 13), "gold")
    return im


def oil():
    im, d = canvas((16, 16))
    rect(d, (6, 1, 9, 2), "ink")
    rect(d, (6, 2, 9, 3), "brown")
    poly(d, [(5, 4), (10, 4), (12, 7), (12, 12), (10, 14), (5, 14), (3, 12), (3, 7)], "ink")
    poly(d, [(5, 5), (10, 5), (11, 8), (11, 12), (10, 13), (5, 13), (4, 12), (4, 8)], "cream")
    rect(d, (5, 8, 10, 12), "gold")
    rect(d, (6, 9, 7, 11), "gold_light")
    rect(d, (10, 9, 10, 12), "brown")
    return im


def heart(kind):
    im, d = canvas((16, 16))
    points = [(2, 3), (5, 2), (8, 4), (11, 2), (14, 3), (15, 6), (14, 9), (8, 15), (2, 9), (1, 6)]
    poly(d, points, "ink")
    poly(d, [(3, 4), (5, 3), (8, 5), (11, 3), (13, 4), (14, 6), (13, 9), (8, 13), (3, 9), (2, 6)], "plum")
    if kind == "full":
        poly(d, [(3, 4), (5, 3), (8, 5), (11, 3), (13, 4), (14, 6), (13, 9), (8, 13), (3, 9), (2, 6)], "red")
        rect(d, (3, 5, 5, 6), "blush")
        rect(d, (4, 4, 5, 4), "cream")
    elif kind == "half":
        poly(d, [(3, 4), (5, 3), (8, 5), (8, 13), (3, 9), (2, 6)], "red")
        rect(d, (3, 5, 5, 6), "blush")
        rect(d, (4, 4, 5, 4), "cream")
    else:
        rect(d, (3, 5, 5, 5), "brown")
        rect(d, (10, 5, 12, 5), "brown")
    return im


def slot():
    im, d = canvas((18, 18))
    rect(d, (0, 0, 17, 17), "ink")
    rect(d, (1, 1, 16, 16), "cream")
    rect(d, (2, 2, 15, 15), "plum")
    rect(d, (3, 3, 14, 14), "brown_dark")
    rect(d, (1, 1, 13, 1), "ivory")
    rect(d, (1, 1, 1, 13), "ivory")
    rect(d, (3, 3, 13, 3), "brown")
    return im


def icon(kind):
    im, d = canvas((8, 8))
    if kind == "clock":
        ell(d, (0, 0, 7, 7), "ink")
        ell(d, (1, 1, 6, 6), "cream")
        rect(d, (3, 2, 3, 4), "brown_dark")
        rect(d, (3, 4, 5, 4), "brown_dark")
    elif kind == "energy":
        poly(d, [(4, 0), (6, 0), (4, 3), (7, 3), (2, 8), (3, 5), (1, 5)], "ink")
        poly(d, [(4, 1), (5, 1), (3, 4), (5, 4), (3, 6), (4, 4), (2, 4)], "gold_light")
    else:
        rect(d, (2, 0, 5, 1), "ink")
        rect(d, (3, 1, 4, 2), "cream")
        poly(d, [(2, 3), (5, 3), (7, 6), (6, 7), (1, 7), (0, 6)], "ink")
        poly(d, [(2, 4), (5, 4), (6, 6), (1, 6)], "stone_light")
    return im


def bar(fill):
    im, d = canvas((64, 8))
    if fill:
        # Monochrome: HUD and weight bar tint this texture in code.
        rect(d, (1, 1, 62, 6), "#F8F8F8")
        rect(d, (1, 6, 62, 6), "#CFCFCF")
    else:
        rect(d, (0, 0, 63, 7), "ink")
        rect(d, (1, 1, 62, 6), "cream")
        rect(d, (2, 2, 61, 5), "plum")
        rect(d, (3, 3, 60, 4), "brown_dark")
        rect(d, (1, 1, 57, 1), "ivory")
    return im


def build():
    sprites = {
        "assets/tilesets/terrain.png": terrain(),
        "assets/sprites/player/player.png": player_sheet(),
        "assets/sprites/player/sword.png": sword(),
        "assets/sprites/enemies/enemy_basic.png": enemy(),
        "assets/sprites/world/tree.png": tree(),
        "assets/sprites/world/rock.png": rock(),
        "assets/sprites/world/iron_vein.png": rock(True),
        "assets/sprites/world/bush.png": bush(),
        "assets/sprites/world/chest.png": chest(),
        "assets/sprites/world/bed.png": bed(),
        "assets/sprites/world/bench.png": bench(),
        "assets/sprites/world/board.png": board(),
        "assets/sprites/items/wood.png": wood_item(),
        "assets/sprites/items/stone.png": stone_item(),
        "assets/sprites/items/iron.png": stone_item(True),
        "assets/sprites/items/lantern.png": lantern(),
        "assets/sprites/items/oil.png": oil(),
        "assets/sprites/ui/hearts/heart_full.png": heart("full"),
        "assets/sprites/ui/hearts/heart_half.png": heart("half"),
        "assets/sprites/ui/hearts/heart_empty.png": heart("empty"),
        "assets/sprites/ui/slot.png": slot(),
        "assets/sprites/ui/icon_clock.png": icon("clock"),
        "assets/sprites/ui/icon_energy.png": icon("energy"),
        "assets/sprites/ui/icon_weight.png": icon("weight"),
        "assets/sprites/ui/energy_bar_under.png": bar(False),
        "assets/sprites/ui/energy_bar_fill.png": bar(True),
    }
    for material in ("stone", "iron"):
        for kind in ("axe", "pickaxe"):
            sprites[f"assets/sprites/items/{material}_{kind}.png"] = tool_item(kind, material)
    sprites["assets/sprites/items/wood_sword.png"] = tool_item("sword", "wood")
    sprites["assets/sprites/items/iron_sword.png"] = tool_item("sword", "iron")
    assert set(sprites) == set(SIZES), (set(SIZES) - set(sprites), set(sprites) - set(SIZES))
    for path, image in sprites.items():
        assert image.size == SIZES[path], (path, image.size)
        dest = ROOT / path
        dest.parent.mkdir(parents=True, exist_ok=True)
        image.save(dest)
    palette_lines = ["GIMP Palette", "Name: Forrest Primavera", "Columns: 6", f"# {len(P)} native pixel-art colors"]
    for name, color in P.items():
        rgb = tuple(int(color[i:i + 2], 16) for i in (1, 3, 5))
        palette_lines.append(f"{rgb[0]:3d} {rgb[1]:3d} {rgb[2]:3d}  {name}")
    (ROOT / "assets" / "PALETA_FORREST.gpl").write_text("\n".join(palette_lines) + "\n", encoding="utf-8")
    print(f"Wrote {len(sprites)} original PNGs at native resolution.")


if __name__ == "__main__":
    build()
