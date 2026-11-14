"""Build pixel-perfect layout examples for reference-based Higgsfield iterations.

These are visual contracts, not target artwork. Each source pixel is enlarged
with nearest-neighbor scaling so the 16 px frame boundaries are unambiguous.
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "higgsfield"
CREAM = "#F8E7C4"
PLUM = "#3C3448"
RED = "#C84E59"


def base(title, subtitle):
    im = Image.new("RGB", (1024, 1024), CREAM)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 1023, 82), fill=PLUM)
    d.text((28, 20), title, fill=CREAM, font=ImageFont.load_default(size=32))
    d.text((28, 58), subtitle, fill="#EAB8BF", font=ImageFont.load_default(size=17))
    return im, d


def place(im, path, xy, scale):
    sprite = Image.open(ROOT / path).convert("RGBA")
    sprite = sprite.resize((sprite.width * scale, sprite.height * scale), Image.Resampling.NEAREST)
    im.paste(sprite, xy, sprite)


def cell_grid(d, xy, columns, rows, scale, color=RED, cell_size=16):
    x, y = xy
    for col in range(columns + 1):
        px = x + col * cell_size * scale
        d.line((px, y, px, y + rows * cell_size * scale), fill=color, width=2)
    for row in range(rows + 1):
        py = y + row * cell_size * scale
        d.line((x, py, x + columns * cell_size * scale, py), fill=color, width=2)


def player_contract():
    im, d = base("PLAYER 32x32 SPRITESHEET", "256x256 SHEET / 8 DIRECTIONS / FOUR IDLE + FOUR WALK")
    d.rectangle((68, 134, 956, 927), fill=PLUM)
    xy = (96, 160)
    place(im, "assets/sprites/player/player.png", xy, 3)
    cell_grid(d, xy, 8, 8, 3, cell_size=32)
    for row, label in enumerate(("S", "SW", "W", "NW", "N", "NE", "E", "SE")):
        d.text((70, 206 + row * 96), label, fill=CREAM, font=ImageFont.load_default(size=17))
    for col in range(8):
        d.text((120 + col * 96, 932), str(col), fill=PLUM, font=ImageFont.load_default(size=20))
    d.text((97, 965), "COL 0-3 IDLE  /  COL 4-7 WALK  /  ONE FRAME = 32x32 px", fill=PLUM,
           font=ImageFont.load_default(size=18))
    im.save(OUT / "contract_player_32px.png", optimize=True)


def world_contract():
    im, d = base("WORLD SPRITE SIZE CONTRACT", "LAYOUT ONLY / ONE VISIBLE SQUARE = 16x16 SOURCE PIXELS")
    d.rectangle((40, 120, 982, 980), fill=PLUM)
    place(im, "assets/tilesets/terrain.png", (78, 165), 12)
    cell_grid(d, (78, 165), 4, 1, 12)
    d.text((80, 363), "TERRAIN 64x16: GRASS / WALL / VILLAGE / CREAM PATH", fill=CREAM,
           font=ImageFont.load_default(size=21))
    place(im, "assets/sprites/world/tree.png", (95, 465), 12)
    cell_grid(d, (95, 465), 2, 2, 12)
    d.text((95, 862), "TREE 32x32", fill=CREAM, font=ImageFont.load_default(size=22))
    place(im, "assets/sprites/world/bush.png", (540, 490), 12)
    cell_grid(d, (540, 490), 1, 1, 12)
    d.text((540, 698), "BUSH 16x16", fill=CREAM, font=ImageFont.load_default(size=21))
    place(im, "assets/sprites/world/rock.png", (750, 490), 12)
    cell_grid(d, (750, 490), 1, 1, 12)
    d.text((750, 698), "ROCK 16x16", fill=CREAM, font=ImageFont.load_default(size=21))
    d.text((535, 790), "DARK BROWN 1px OUTLINE ON PLANTS", fill="#EAB8BF",
           font=ImageFont.load_default(size=20))
    im.save(OUT / "contract_world_16px.png", optimize=True)


def items_contract():
    im, d = base("ITEM & UI SPRITE SIZE CONTRACT", "LAYOUT ONLY / TRANSPARENT OBJECTS / NO SHADOW OUTSIDE CELL")
    d.rectangle((40, 115, 982, 982), fill=PLUM)
    samples = [
        ("stone", "assets/sprites/items/stone.png", (85, 170), (1, 1)),
        ("axe", "assets/sprites/items/stone_axe.png", (305, 170), (1, 2)),
        ("sword", "assets/sprites/items/iron_sword.png", (520, 170), (1, 2)),
        ("heart", "assets/sprites/ui/hearts/heart_full.png", (755, 170), (1, 1)),
        ("chest", "assets/sprites/world/chest.png", (85, 590), (1, 1)),
        ("bed", "assets/sprites/world/bed.png", (305, 590), (1, 2)),
        ("bench", "assets/sprites/world/bench.png", (525, 590), (2, 1)),
    ]
    for label, path, xy, cells in samples:
        place(im, path, xy, 10)
        cell_grid(d, xy, *cells, 10)
        d.text((xy[0], xy[1] + cells[1] * 160 + 10), f"{label.upper()} {cells[0]*16}x{cells[1]*16}",
               fill=CREAM, font=ImageFont.load_default(size=19))
    im.save(OUT / "contract_items_16px.png", optimize=True)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    player_contract()
    world_contract()
    items_contract()
    print("Created 32 px player and 16 px world/item layout references for Higgsfield")
