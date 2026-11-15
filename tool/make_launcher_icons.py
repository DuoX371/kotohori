"""Builds the Android launcher icons and the in-app icon from assets/icons/.

Sources (1024 px, 108dp adaptive-icon canvas for the layers):
  foreground.png  adaptive foreground layer (transparent around the logo)
  monochrome.png  Android 13+ themed-icon layer (black on transparent)
  icon.png        full square icon (background colour + logo)
The background layer is the plain colour in values/ic_launcher_background.xml.
"""
from PIL import Image, ImageDraw

RES = 'android/app/src/main/res'
ICONS = 'assets/icons'


def rounded(im, size):
    """[im] scaled to [size] with rounded corners, like a launcher tile."""
    im = im.convert('RGBA').resize((size, size), Image.LANCZOS)
    mask = Image.new('L', (size * 4, size * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size * 4 - 1, size * 4 - 1), radius=size * 4 * 0.22, fill=255)
    im.putalpha(mask.resize((size, size), Image.LANCZOS))
    return im


fg = Image.open(f'{ICONS}/foreground.png').convert('RGBA')
mono = Image.open(f'{ICONS}/monochrome.png').convert('RGBA')
full = Image.open(f'{ICONS}/icon.png').convert('RGBA')

for dpi, scale in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]:
    s = round(108 * scale)  # adaptive layers are 108dp
    fg.resize((s, s), Image.LANCZOS).save(f'{RES}/mipmap-{dpi}/ic_launcher_foreground.png')
    mono.resize((s, s), Image.LANCZOS).save(f'{RES}/mipmap-{dpi}/ic_launcher_monochrome.png')
    # Legacy icon (Android < 8): 48dp rounded tile.
    rounded(full, round(48 * scale)).save(f'{RES}/mipmap-{dpi}/ic_launcher.png')
    print(dpi, s)

# Shown inside the app (About, licences) and in the README.
rounded(full, 128).save(f'{ICONS}/app_icon_128.png')
print('app_icon_128.png')
