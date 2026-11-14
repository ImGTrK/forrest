"""Render the current native PNGs as a 640x360 contact sheet and 2x preview."""

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"


def asset(path):
    return Image.open(ASSETS / path).convert("RGBA")


def paste(im, path, xy):
    im.alpha_composite(asset(path), xy)


def main():
    scene = Image.new("RGBA", (640, 360), "#779A7E")
    ground = asset("tilesets/terrain.png")
    tiles = [ground.crop((i * 16, 0, i * 16 + 16, 16)) for i in range(4)]
    for y in range(22):
        for x in range(40):
            wall = x in (0, 39) or y in (0, 21)
            path = (abs(y - 11) <= 1 and 2 <= x <= 34) or (abs(x - 31) <= 1 and 5 <= y <= 11)
            scene.alpha_composite(tiles[1 if wall else 3 if path else 0], (x * 16, y * 16))
    placements = [
        ("tree", (64, 48)), ("tree", (192, 64)), ("tree", (464, 80)),
        ("tree", (448, 224)), ("bush", (128, 80)), ("bush", (384, 64)),
        ("rock", (144, 208)), ("iron_vein", (352, 208)),
        ("chest", (512, 208)), ("board", (544, 64)),
        ("bench", (96, 256)), ("bed", (48, 240)),
    ]
    for name, xy in placements:
        paste(scene, f"sprites/world/{name}.png", xy)
    player = asset("sprites/player/player.png").crop((0, 0, 32, 32))
    enemy = asset("sprites/enemies/enemy_basic.png").crop((16, 0, 32, 16))
    scene.alpha_composite(player, (224, 146))
    scene.alpha_composite(enemy, (360, 160))
    # Compact HUD sample, pixel-perfect at base resolution.
    for i in range(3):
        paste(scene, "sprites/ui/hearts/heart_full.png", (12 + i * 17, 12))
    for i, name in enumerate(("wood", "stone", "iron", "stone_axe", "iron_sword")):
        x = 262 + i * 19
        paste(scene, "sprites/ui/slot.png", (x, 329))
        icon = asset(f"sprites/items/{name}.png")
        if icon.height == 32:
            icon = icon.resize((8, 16), Image.Resampling.NEAREST)
            scene.alpha_composite(icon, (x + 5, 330))
        else:
            scene.alpha_composite(icon, (x + 1, 330))
    out = ROOT / "docs" / "PREVIEW_ARTE_BASE.png"
    scene.convert("RGB").save(out)
    scene.resize((1280, 720), Image.Resampling.NEAREST).convert("RGB").save(out.with_name("PREVIEW_ARTE_BASE_2X.png"))
    render_contact_sheet()
    render_animation_checks()
    print(out)


def render_contact_sheet():
    paths = [
        "tilesets/terrain.png", "sprites/player/player.png", "sprites/player/sword.png",
        "sprites/enemies/enemy_basic.png",
        *[f"sprites/world/{name}.png" for name in
          ("tree", "rock", "iron_vein", "bush", "chest", "bed", "bench", "board")],
        *[f"sprites/items/{name}.png" for name in
          ("wood", "stone", "iron", "stone_axe", "stone_pickaxe", "wood_sword",
           "iron_axe", "iron_pickaxe", "iron_sword", "lantern", "oil")],
        *[f"sprites/ui/{name}.png" for name in
          ("hearts/heart_full", "hearts/heart_half", "hearts/heart_empty",
           "slot", "icon_clock", "icon_energy", "icon_weight",
           "energy_bar_under", "energy_bar_fill")],
    ]
    assert len(paths) == 32
    sheet = Image.new("RGB", (8 * 128, 4 * 136), "#F3DEC1")
    d = ImageDraw.Draw(sheet)
    for i, path in enumerate(paths):
        x, y = i % 8 * 128, i // 8 * 136
        d.rectangle((x + 4, y + 4, x + 123, y + 131), fill="#3C3448", outline="#80545A", width=1)
        im = asset(path)
        if path.endswith("player.png"):
            im = im.crop((0, 0, 32, 32))
        if path.endswith("enemy_basic.png"):
            im = im.crop((16, 0, 32, 16))
        scale = min(5, 112 // im.width, 100 // im.height)
        enlarged = im.resize((im.width * scale, im.height * scale), Image.Resampling.NEAREST)
        sheet.paste(enlarged, (x + 64 - enlarged.width // 2, y + 55 - enlarged.height // 2), enlarged)
        name = Path(path).stem
        d.text((x + 7, y + 113), name, fill="#F3DEC1")
    sheet.save(ROOT / "docs" / "CONTACTO_SPRITES_BASE.png")


def render_animation_checks():
    out = ROOT / "docs" / "higgsfield"
    player = asset("sprites/player/player.png")
    full = Image.new("RGBA", player.size, "#3B2D45")
    full.alpha_composite(player)
    full.resize((1024, 1024), Image.Resampling.NEAREST).convert("RGB").save(
        out / "preview_player_sheet_8x.png")
    strip = Image.new("RGBA", (256, 32), "#84AB78")
    for row in range(8):
        strip.alpha_composite(player.crop((0, row * 32, 32, row * 32 + 32)), (row * 32, 0))
    strip.resize((1024, 128), Image.Resampling.NEAREST).convert("RGB").save(
        out / "preview_player_directions.png")
    enemy = Image.new("RGBA", (32, 16), "#84AB78")
    enemy.alpha_composite(asset("sprites/enemies/enemy_basic.png"))
    enemy.resize((512, 256), Image.Resampling.NEAREST).convert("RGB").save(
        out / "preview_enemy_frames.png")


if __name__ == "__main__":
    main()
