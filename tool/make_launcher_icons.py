"""Builds Android launcher icons from assets/icons/adaptive_master.png.

The master is a 108dp adaptive-icon canvas with red guide lines (visible area
square, safe-zone circle). Guide pixels are painted navy; the result is the
foreground layer, the background layer is the plain navy colour.
"""
import os
from PIL import Image

NAVY = (31, 42, 92)
RED = (210, 55, 56)
RES = 'android/app/src/main/res'
src = 'assets/icons/adaptive_master.png'

im = Image.open(src).convert('RGBA')
px = im.load()
w, h = im.size


def on_guide(p):
    """Pixel is red, or a red/navy blend (the anti-aliased guide lines)."""
    r, g, b, a = p
    if a == 0:
        return True  # rounded-corner transparency outside the tile
    d = [RED[i] - NAVY[i] for i in range(3)]
    t = sum((p[i] - NAVY[i]) * d[i] for i in range(3)) / sum(x * x for x in d)
    if t <= 0.03:
        return False
    err = max(abs(p[i] - (NAVY[i] + t * d[i])) for i in range(3))
    return err < 14


removed = 0
for y in range(h):
    for x in range(w):
        if on_guide(px[x, y]):
            if px[x, y][:3] != NAVY:
                removed += 1
            px[x, y] = NAVY + (255,)
print('guide pixels removed:', removed)
im.save('assets/icons/adaptive_foreground_clean.png')

# 108dp foreground per density.
for dpi, scale in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]:
    s = round(108 * scale)
    im.resize((s, s), Image.LANCZOS).save(f'{RES}/mipmap-{dpi}/ic_launcher_foreground.png')
    # Legacy icon (Android < 8): the 72dp visible square, rounded preview.
    legacy = Image.open('assets/icons/preview_rounded_square_128.png').convert('RGBA')
    legacy.resize((round(48 * scale),) * 2, Image.LANCZOS).save(f'{RES}/mipmap-{dpi}/ic_launcher.png')
    print(dpi, s)
