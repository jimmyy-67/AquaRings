"""Arbol estilo TOY con fondo celeste.

Uso:
    py tools/generate_tree_toy.py

Genera (solo ASSETS, no toca scenes/ ni scripts/):
    assets/sprites/tree_toy.png  (640x480, fondo celeste opaco)

Estilo toy / suave, coherente con jam_toy y vase_pink:
  - Todo redondeado, sin picos.
  - Supersampling x4 + downscale LANCZOS para bordes suaves.
  - Outline grueso redondeado marron oscuro.
  - Copa en blobs verdes superpuestos + brillos + 3 manzanas toy.
  - Nubes toy, sol sonriente simple, colina verde.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SPR = ROOT / "assets" / "sprites"
OUT_NAME = "tree_toy.png"

SS = 4
W, H = 640, 480

SKY = (174, 216, 245)       # celeste
SKY_LIGHT = (205, 235, 252)
SUN = (255, 220, 95)
SUN_DARK = (240, 185, 60)
CLOUD = (255, 255, 255)
OUTLINE = (58, 38, 28)
TRUNK = (172, 118, 74)
TRUNK_DARK = (132, 86, 50)
TRUNK_LIGHT = (205, 150, 100)
LEAF = (112, 178, 92)
LEAF_DARK = (86, 146, 70)
LEAF_LIGHT = (150, 210, 125)
LEAF_LINE = (62, 100, 56)
GROUND = (126, 192, 102)
GROUND_DARK = (98, 162, 80)
APPLE = (235, 85, 80)
APPLE_DARK = (185, 50, 50)


def _rr(d, box, radius, fill=None, outline=None, width=1):
    s = SS
    d.rounded_rectangle([c * s for c in box], radius=radius * s,
                        fill=fill, outline=outline, width=max(1, int(width * s)))


def _ell(d, box, fill=None, outline=None, width=1):
    s = SS
    d.ellipse([c * s for c in box], fill=fill, outline=outline,
              width=max(1, int(width * s)))


def _soft(layer, box, color, blur):
    s = SS
    tmp = Image.new("RGBA", (W * s, H * s), (0, 0, 0, 0))
    ImageDraw.Draw(tmp, "RGBA").ellipse([c * s for c in box], fill=color)
    tmp = tmp.filter(ImageFilter.GaussianBlur(radius=blur * s))
    layer.alpha_composite(tmp)


def main() -> None:
    SPR.mkdir(parents=True, exist_ok=True)
    S = (W * SS, H * SS)
    img = Image.new("RGBA", S, SKY + (255,))
    d = ImageDraw.Draw(img, "RGBA")

    # Halo luminoso central sin blur con alpha (evita franja oscura del blur RGBA)
    for r, a in ((320, 28), (260, 30), (200, 32)):
        d.ellipse([(320 - r) * SS, (230 - r) * SS,
                   (320 + r) * SS, (230 + r) * SS],
                  fill=SKY_LIGHT + (a,))

    # --- sol toy arriba-izq ---
    sx, sy, sr = 105, 95, 44
    _ell(d, (sx - sr, sy - sr, sx + sr, sy + sr),
         fill=SUN + (255,), outline=OUTLINE + (255,), width=5)
    _ell(d, (sx - sr + 12, sy - sr + 10, sx - sr + 32, sy - sr + 28),
         fill=(255, 240, 180, 255))
    # rayos cortos redondeados (8)
    from math import cos, sin, pi
    for k in range(8):
        a = k * pi / 4 + 0.26
        x0 = sx + cos(a) * (sr + 3)
        y0 = sy + sin(a) * (sr + 3)
        x1 = sx + cos(a) * (sr + 18)
        y1 = sy + sin(a) * (sr + 18)
        d.line([(x0 * SS, y0 * SS), (x1 * SS, y1 * SS)],
               fill=OUTLINE + (255,), width=int(7 * SS), joint="curve")
        d.line([(x0 * SS, y0 * SS), (x1 * SS, y1 * SS)],
               fill=SUN + (255,), width=int(4 * SS), joint="curve")

    # --- nubes toy ---
    for cx, cy, sc in ((470, 105, 1.0), (200, 150, 0.7), (520, 200, 0.6)):
        for ox, oy, r in ((-38 * sc, 6 * sc, 22 * sc), (-10 * sc, -6 * sc, 28 * sc),
                          (22 * sc, 6 * sc, 20 * sc), (0 * sc, 12 * sc, 30 * sc)):
            _ell(d, (cx + ox - r, cy + oy - r, cx + ox + r, cy + oy + r),
                 fill=CLOUD + (255,), outline=OUTLINE + (255,), width=3.5)

    # --- colina verde ---
    _ell(d, (-120, 360, 760, 560), fill=GROUND + (255,),
         outline=OUTLINE + (255,), width=5)
    _ell(d, (60, 390, 580, 470), fill=GROUND_DARK + (90,))

    # sombra bajo el arbol
    sh = Image.new("RGBA", S, (0, 0, 0, 0))
    ImageDraw.Draw(sh, "RGBA").ellipse(
        [(250) * SS, (418) * SS, (390) * SS, (448) * SS], fill=(50, 70, 50, 80))
    sh = sh.filter(ImageFilter.GaussianBlur(radius=4 * SS))
    img.alpha_composite(sh)
    d = ImageDraw.Draw(img, "RGBA")

    # --- tronco toy: corto, gordito, redondeado ---
    tx0, tx1, ty0, ty1 = 292, 348, 290, 428
    _rr(d, (tx0, ty0, tx1, ty1), 22, fill=TRUNK + (255,),
        outline=OUTLINE + (255,), width=6)
    # veta / luz lateral
    _rr(d, (tx0 + 9, ty0 + 14, tx0 + 22, ty1 - 12), 8, fill=TRUNK_LIGHT + (200,))
    _rr(d, (tx1 - 22, ty0 + 14, tx1 - 9, ty1 - 12), 8, fill=TRUNK_DARK + (160,))
    # raices redondeadas
    _ell(d, (tx0 - 18, ty1 - 26, tx0 + 22, ty1 + 6), fill=TRUNK + (255,),
         outline=OUTLINE + (255,), width=5)
    _ell(d, (tx1 - 22, ty1 - 26, tx1 + 18, ty1 + 6), fill=TRUNK + (255,),
         outline=OUTLINE + (255,), width=5)
    # ramas cortas toy
    d.line([((320) * SS, (300) * SS), ((270) * SS, (260) * SS)],
           fill=OUTLINE + (255,), width=int(20 * SS), joint="curve")
    d.line([((320) * SS, (300) * SS), ((270) * SS, (260) * SS)],
           fill=TRUNK + (255,), width=int(13 * SS), joint="curve")
    d.line([((320) * SS, (295) * SS), ((372) * SS, (252) * SS)],
           fill=OUTLINE + (255,), width=int(20 * SS), joint="curve")
    d.line([((320) * SS, (295) * SS), ((372) * SS, (252) * SS)],
           fill=TRUNK + (255,), width=int(13 * SS), joint="curve")

    # --- copa toy: 5 blobs superpuestos ---
    blobs = (
        (225, 175, 78),   # izq
        (320, 140, 88),   # centro-arriba
        (415, 175, 78),   # der
        (270, 235, 72),   # izq-bajo
        (370, 235, 72),   # der-bajo
    )
    for bx, by, r in blobs:
        _ell(d, (bx - r, by - r, bx + r, by + r),
             fill=LEAF + (255,), outline=OUTLINE + (255,), width=6)
    # sombreado inferior dentro de la copa
    _soft(img, (240, 200, 400, 300), LEAF_DARK + (130,), 8)
    # luz superior
    _soft(img, (250, 90, 390, 170), LEAF_LIGHT + (140,), 7)
    d = ImageDraw.Draw(img, "RGBA")
    # brillos blancos toy (hojitas luz)
    for hx, hy, hr in ((285, 120, 14), (350, 115, 11), (240, 170, 9)):
        _ell(d, (hx - hr, hy - hr, hx + hr, hy + hr),
             fill=(235, 250, 230, 210))
    # textura: puntitos verde oscuro (profundidad toy)
    for px_, py_, pr in ((250, 210, 6), (300, 190, 7), (350, 205, 6),
                         (390, 180, 5), (320, 230, 6), (275, 155, 5)):
        _ell(d, (px_ - pr, py_ - pr, px_ + pr, py_ + pr),
             fill=LEAF_DARK + (160,))

    # --- manzanas toy (3) ---
    for ax, ay, ar in ((265, 200, 16), (375, 195, 16), (320, 245, 17)):
        _ell(d, (ax - ar, ay - ar, ax + ar, ay + ar),
             fill=APPLE + (255,), outline=OUTLINE + (255,), width=4)
        _ell(d, (ax - ar + 5, ay - ar + 4, ax - ar + 12, ay - ar + 11),
             fill=(255, 200, 195, 255))
        # hojita
        _ell(d, (ax + 2, ay - ar - 10, ax + 14, ay - ar + 1),
             fill=LEAF + (255,), outline=LEAF_LINE + (255,), width=2.5)

    # pasto toy: matitas redondeadas sobre la colina
    for gx in (150, 190, 460, 500, 540):
        _ell(d, (gx - 10, 378 - 10, gx + 10, 378 + 10),
             fill=LEAF_DARK + (255,), outline=OUTLINE + (255,), width=3)
        _ell(d, (gx - 10, 372 - 10, gx + 10, 372 + 10),
             fill=LEAF + (255,), outline=OUTLINE + (255,), width=3)
    # flores toy
    for fx, fy, col in ((120, 425, (255, 150, 180)), (520, 430, (255, 210, 120)),
                        (220, 435, (255, 255, 255))):
        for ox, oy in ((-7, 0), (7, 0), (0, -7), (0, 7)):
            _ell(d, (fx + ox - 6, fy + oy - 6, fx + ox + 6, fy + oy + 6),
                 fill=col + (255,), outline=OUTLINE + (255,), width=2.5)
        _ell(d, (fx - 5, fy - 5, fx + 5, fy + 5),
             fill=SUN + (255,), outline=OUTLINE + (255,), width=2.5)

    small = img.resize((W, H), Image.LANCZOS)
    small = small.convert("RGB")  # fondo celeste opaco, sin alfa
    target = SPR / OUT_NAME
    if target.exists():
        target.unlink()
    small.save(target)
    print(f"OK {OUT_NAME} {small.size} (arbol toy, fondo celeste)")


if __name__ == "__main__":
    main()
