#!/usr/bin/env python3
"""macro-hy.sh'in arka plan süreci: sanal klavye + fare oluşturur.
  SIGUSR1 (ALT + orta tık):  W + D + sol tık basılı tut / bırak
  SIGUSR2 (SHIFT + orta tık): sadece sol tık basılı tut / bırak
SIGTERM'de basılı ne varsa bırakıp çıkar (takılı tuş kalmasın).

Klavye ve fare ayrı aygıt: libinput, tuş + fare tuşunu tek aygıtta
görünce fareyi tanımayabiliyor.
"""
import signal

from evdev import UInput, ecodes as e

KEYS = [e.KEY_W, e.KEY_D]

kb = UInput({e.EV_KEY: KEYS}, name="macro-hy keyboard")
mouse = UInput(
    {e.EV_KEY: [e.BTN_LEFT, e.BTN_RIGHT, e.BTN_MIDDLE], e.EV_REL: [e.REL_X, e.REL_Y]},
    name="macro-hy mouse",
)
held_wd = False     # ALT + orta tık makrosu
held_click = False  # SHIFT + orta tık makrosu


def apply():
    # İki makro da sol tıkı kullanıyor: biri açıkken öteki kapanınca bırakılmasın
    for code in KEYS:
        kb.write(e.EV_KEY, code, int(held_wd))
    kb.syn()
    mouse.write(e.EV_KEY, e.BTN_LEFT, int(held_wd or held_click))
    mouse.syn()


def toggle_wd(*_):
    global held_wd
    held_wd = not held_wd
    apply()


def toggle_click(*_):
    global held_click
    held_click = not held_click
    apply()


def stop(*_):
    global held_wd, held_click
    held_wd = held_click = False
    apply()
    kb.close()
    mouse.close()
    raise SystemExit


signal.signal(signal.SIGUSR1, toggle_wd)
signal.signal(signal.SIGUSR2, toggle_click)
signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)
while True:
    signal.pause()
