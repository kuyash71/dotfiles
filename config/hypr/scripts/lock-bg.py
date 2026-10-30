#!/usr/bin/env python3
"""Kilit / giriş ekranı arka planını üretir: duvar kağıdının soluna, saat ve
kartın okunması için yumuşak bir karartma geçişi ekler (sağdaki kale net kalır).

    lock-bg.py [kaynak] [hedef]
    varsayılan: ~/Pictures/Backgrounds/tower.png → ~/.config/hypr/lock-bg.png

hyprlock'ta blur kapalıyken brightness/contrast çalışmadığı için karartma
resmin içine işleniyor. Duvar kağıdı değişirse yeniden çalıştır.
"""
import os
import sys

from PIL import Image

SRC = os.path.expanduser(sys.argv[1] if len(sys.argv) > 1 else "~/Pictures/Backgrounds/tower.png")
DST = os.path.expanduser(sys.argv[2] if len(sys.argv) > 2 else "~/.config/hypr/lock-bg.png")

SHADE = (17, 17, 27)  # panelin cam rengi
LEFT_ALPHA = 0.62     # en soldaki karartma
FADE_END = 0.58       # karartmanın bittiği yer (genişliğin oranı)
BASE_ALPHA = 0.08     # tüm resme hafif genel karartma

img = Image.open(SRC).convert("RGB")
w, h = img.size

# Yatay maske: solda LEFT_ALPHA, FADE_END'e kadar yumuşak (smoothstep) sönüyor
row = []
for x in range(w):
    t = min(x / (w * FADE_END), 1.0)
    fade = 1 - t * t * (3 - 2 * t)
    row.append(round(255 * (BASE_ALPHA + (LEFT_ALPHA - BASE_ALPHA) * fade)))
mask = Image.new("L", (w, 1))
mask.putdata(row)
mask = mask.resize((w, h), Image.NEAREST)

img.paste(Image.new("RGB", (w, h), SHADE), (0, 0), mask)
img.save(DST)
print(DST)
