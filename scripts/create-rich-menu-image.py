#!/usr/bin/env python3
"""リッチメニュー用の画像を生成する (2500x843, 2ボタン横並び)"""

from PIL import Image, ImageDraw, ImageFont
import os

WIDTH = 2500
HEIGHT = 843
BG_COLOR = "#06C755"
DIVIDER_COLOR = "#FFFFFF"
TEXT_COLOR = "#FFFFFF"

img = Image.new("RGB", (WIDTH, HEIGHT), BG_COLOR)
draw = ImageDraw.Draw(img)

# 中央の区切り線
draw.line([(WIDTH // 2, 0), (WIDTH // 2, HEIGHT)], fill=DIVIDER_COLOR, width=4)

# フォント（macOS 標準の日本語フォント）
font_paths = [
    "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc",
    "/System/Library/Fonts/Hiragino Sans GB.ttc",
    "/System/Library/Fonts/Helvetica.ttc",
]
font = None
for fp in font_paths:
    if os.path.exists(fp):
        try:
            font = ImageFont.truetype(fp, 80)
            break
        except Exception:
            continue
if font is None:
    font = ImageFont.load_default()

labels = ["あいさつ", "ヘルプ"]
for i, label in enumerate(labels):
    cx = WIDTH // 4 + (WIDTH // 2) * i
    cy = HEIGHT // 2
    bbox = draw.textbbox((0, 0), label, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text((cx - tw // 2, cy - th // 2), label, fill=TEXT_COLOR, font=font)

output_path = os.path.join(os.path.dirname(__file__), "rich-menu.png")
img.save(output_path)
print(f"Created: {output_path}")
