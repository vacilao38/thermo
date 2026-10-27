"""Render the code-native thermometer mark as a multi-size Windows icon (Pillow)."""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parent.parent
im = Image.new('RGBA', (256, 256), (0, 0, 0, 0))
d = ImageDraw.Draw(im)
d.rounded_rectangle((8, 8, 248, 248), radius=58, fill='#e9eff2')
d.rounded_rectangle((90, 31, 146, 183), radius=28, fill='#ffffff')
d.ellipse((69, 151, 167, 237), fill='#ffffff')
d.rounded_rectangle((103, 43, 133, 190), radius=15, fill='#d2dee2')
d.rounded_rectangle((109, 73, 127, 194), radius=9, fill='#378e7b')
d.ellipse((82, 165, 154, 224), fill='#247d70')
d.ellipse((95, 174, 114, 192), fill='#64b4a1')
for y in range(51, 151, 20):
    d.rounded_rectangle((158, y, 180, y + 4), radius=2, fill='#9b8bc2')
im.save(root / 'windows/runner/resources/app_icon.ico', sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])
