#!/usr/bin/env python3
"""Control Panel'in soluna, panelin arkasından kayarak açılan mini paneller.

    minipanel.py daemon [power|notif]   arka planda bekle (oturum açılınca başlar)
    SIGUSR1 → güç menüsü (güneş butonu), SIGUSR2 → bildirim filtresi (çark);
    menü açıkken herhangi biri menüyü kapatır. Sinyalleri mini-panel.sh gönderir.

Her tıklamada Python + GTK'yı baştan açmak ~300 ms sürüyordu; süreç sürekli
çalıştığı için menü artık hemen açılıyor (pencere her seferinde yeniden kurulur,
o kısmı birkaç ms).

Ekranı kaplayan şeffaf bir katman (layer-shell, overlay) açar:
  - menü panelin sol kenarından sola doğru kayar (Gtk.Revealer, SLIDE_LEFT);
    kesilme kenarı panelin kenarı olduğu için arkasından çıkıyormuş gibi görünür
  - menünün dışına tıklamak ya da Esc menüyü kapatır
  - Control Panel kapanınca (swaync-client -s → visible: false) menü de kapanır
  - menü açıkken güneş / çark simgesi, tam üstüne hover renginde çizilir

Koordinatlar mantıksal piksel (ölçek 1.25), monitörün sol üst köşesinden;
SwayNC paneliyle (config.json: sağ boşluk 14, genişlik 458) ölçülerek bulundu.
mini-panel.sh üzerinden başlatılır (LD_PRELOAD gerekiyor).
"""

import json
import os
import signal
import re
import subprocess
import sys

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gdk, GLib, Gtk  # noqa: E402
from gi.repository import Gtk4LayerShell as LayerShell  # noqa: E402

try:
    from gi.repository import GLibUnix  # noqa: E402

    signal_add, fd_add = GLibUnix.signal_add, GLibUnix.fd_add_full
except ImportError:
    signal_add, fd_add = GLib.unix_signal_add, GLib.unix_fd_add_full

HOME = os.path.expanduser("~")
SCRIPTS = f"{HOME}/.config/swaync/scripts"
CONFIG = f"{HOME}/.config/swaync/config.json"
KNOWN = os.path.join(
    os.environ.get("XDG_STATE_HOME", f"{HOME}/.local/state"), "swaync/known-apps"
)
PIDFILE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "kvara-minipanel.pid")
BLOCK_PREFIX = "block: "
KINDS = {"power": signal.SIGUSR1, "notif": signal.SIGUSR2}

PANEL_RIGHT = 14 + 473  # panelin sol kenarı: ekranın sağından uzaklık (kenarlık dahil)
GAP = 10  # menü ile panel arası
ANIM_MS = 220

HOST_Y = 106  # bilgisayar adının dikey ortası → güç menüsünün üst kenarı
GEAR_Y = (503, 372)  # çarkın tahmini dikey ortası (ekrandan okunamazsa): medya kartı var / yok
GEAR_SCAN_X = (1080, 1100)  # çarkın arandığı sütun (NOTIFICATIONS yazısından önce biter)
GEAR_COLORS = ((149, 127, 184), (229, 194, 131))  # normal / hover

# Menü açıkken "aktif" simge: SwayNC'deki simgenin tam üstüne (sol üst köşe)
SUN = {"text": "󰖙", "x": 1074, "y": 83, "css": "sun"}
GEAR = {"text": "󰒓", "x": 1084, "y_from_center": -7, "css": "gear"}

CSS = """
window, window.background { background: none; box-shadow: none; }
* { font-family: "CommitMono Nerd Font"; }

.frame {
  background: rgba(17, 17, 27, 0.55);
  border: 2px solid #63537a;
  border-radius: 18px;
  padding: 8px;
  backdrop-filter: blur(24px);
}
.title {
  color: #e5c283;
  font-weight: bold;
  font-size: 0.85rem;
  letter-spacing: 2px;
  margin: 4px 8px 8px 8px;
}
.hint {
  color: #957fb8;
  font-size: 0.8rem;
  margin: 4px 8px;
}
.item {
  background: none;
  color: #FFF8E7;
  border: none;
  border-radius: 10px;
  box-shadow: none;
  padding: 8px 12px;
  font-size: 0.95rem;
}
.item:hover { background: #313244; color: #e5c283; }
.item.danger:hover { background: #f38ba8; color: #11111b; }
.item.blocked { color: rgba(166, 173, 200, 0.55); }
.item.blocked:hover { color: #f38ba8; }
.item label { margin: 0; }

entry {
  background: rgba(30, 30, 46, 0.5);
  color: #e5c283;
  border: 1px solid rgba(149, 127, 184, 0.25);
  border-radius: 10px;
  box-shadow: none;
  margin: 0 0 6px 0;
  min-height: 32px;
}
entry:focus-within { border-color: #957fb8; outline: none; }

/* Alttaki simgenin kenar yumuşatmasından kalan ince hareyi panel rengiyle ört */
.glyph { text-shadow: 0 0 1px #16161f, 0 0 2px #16161f; }
.glyph.sun  { color: #957fb8; font-size: 2rem; transform: translate(-0.3px, 0.6px); }
.glyph.gear { color: #e5c283; font-size: 1.05rem; }
"""


def run(*cmd):
    subprocess.Popen(cmd, start_new_session=True,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def hypr_json(what):
    out = subprocess.run(["hyprctl", what, "-j"], capture_output=True, text=True).stdout
    return json.loads(out)


def focused_monitor():
    return next(m for m in hypr_json("monitors") if m["focused"])


def gear_center_y(mon):
    """Çarkın dikey ortası. Medya kartının yüksekliği çalan içeriğe göre
    değiştiği için sabit değil: tıklanan yerin çevresinde ekrandan okunur."""
    cy = int(hypr_json("cursorpos")["y"]) - mon["y"]
    found = scan_gear(mon, cy)
    if found is not None:
        return found
    best = min(GEAR_Y, key=lambda y: abs(y - cy))
    return best if abs(best - cy) <= 20 else cy


def scan_gear(mon, cy):
    """Monitörün görüntüsünde, tıklanan y'nin ±30 px çevresinde çarkın
    renklerindeki piksellerin dikey ortası (mantıksal px). Bulamazsa None."""
    try:
        ppm = subprocess.run(["grim", "-t", "ppm", "-o", mon["name"], "-"],
                             capture_output=True, timeout=1).stdout
        # P6\n<w> <h>\n255\n<RGB...>. split() kullanma: koyu pikseller boşluk
        # baytı (0x09, 0x20…) olabiliyor ve başlıkla birlikte yutuluyor
        m = re.match(rb"P6\s+(\d+)\s+(\d+)\s+\d+\s", ppm)
        w, h = int(m[1]), int(m[2])
        data = ppm[m.end():]
    except (subprocess.SubprocessError, TypeError, OSError):
        return None
    sc = mon["scale"]
    x0, x1 = (int(x * sc) for x in GEAR_SCAN_X)
    y0, y1 = max(0, int((cy - 30) * sc)), min(h, int((cy + 30) * sc))
    rows = []
    for y in range(y0, y1):
        line = data[(y * w + x0) * 3:(y * w + x1) * 3]
        for i in range(0, len(line), 3):
            px = line[i:i + 3]
            if any(all(abs(a - b) <= 24 for a, b in zip(px, c)) for c in GEAR_COLORS):
                rows.append(y)
                break
    # Bitişik satır grupları: medya kartının kenarı da aynı mor, onu ayıkla.
    # Simge boyunda (8-28 px) olup tıklanan yere en yakın grup çarktır.
    runs, start = [], None
    for i, y in enumerate(rows):
        if start is None:
            start = y
        if i + 1 == len(rows) or rows[i + 1] - y > 2:
            runs.append((start, y))
            start = None
    runs = [r for r in runs if 8 * sc <= r[1] - r[0] + 1 <= 28 * sc]
    if not runs:
        return None
    a, b = min(runs, key=lambda r: abs((r[0] + r[1]) / 2 - cy * sc))
    return round((a + b) / 2 / sc)


def read_apps():
    try:
        with open(CONFIG) as f:
            vis = json.load(f).get("notification-visibility", {})
    except (OSError, ValueError):
        vis = {}
    blocked = {k[len(BLOCK_PREFIX):] for k in vis if k.startswith(BLOCK_PREFIX)}
    try:
        with open(KNOWN) as f:
            known = {line.strip() for line in f if line.strip()}
    except OSError:
        known = set()
    return sorted(known | blocked, key=str.casefold), blocked


class MiniPanel(Gtk.Application):
    def __init__(self, first=None):
        super().__init__(application_id=None)
        self.first = first  # başlarken hemen açılacak menü (varsa)
        self.win = None
        self.closing = False
        self.sub = None

    def do_startup(self):
        Gtk.Application.do_startup(self)
        self.hold()  # pencere yokken de çalışmaya devam et
        provider = Gtk.CssProvider()
        provider.load_from_string(CSS)
        # ~/.config/gtk-4.0/gtk.css (Catppuccin) USER önceliğiyle yükleniyor;
        # pencere zeminini opak yapmasın diye onun da üstüne çık
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_USER + 1)

    def do_activate(self):
        if self.first:
            self.show(self.first)

    def request(self, kind):
        """Sinyal geldi: menü açıksa kapat, değilse aç."""
        if self.win is not None:
            self.close()
        else:
            self.show(kind)

    # --- Pencere -----------------------------------------------------------
    def show(self, kind):
        mon = focused_monitor()
        self.kind = kind
        self.closing = False

        win = Gtk.Window(application=self)
        self.win = win
        LayerShell.init_for_window(win)
        LayerShell.set_namespace(win, "kvara-minipanel")
        LayerShell.set_layer(win, LayerShell.Layer.OVERLAY)
        LayerShell.set_exclusive_zone(win, -1)
        LayerShell.set_keyboard_mode(win, LayerShell.KeyboardMode.EXCLUSIVE)
        for edge in (LayerShell.Edge.TOP, LayerShell.Edge.BOTTOM,
                     LayerShell.Edge.LEFT, LayerShell.Edge.RIGHT):
            LayerShell.set_anchor(win, edge, True)
        for gm in Gdk.Display.get_default().get_monitors():
            if gm.get_connector() == mon["name"]:
                LayerShell.set_monitor(win, gm)

        root = Gtk.Overlay()
        root.set_child(Gtk.Box(hexpand=True, vexpand=True))

        if self.kind == "power":
            top, glyph = HOST_Y, dict(SUN)
            frame = self.build_power()
        else:
            top = gear_center_y(mon)
            glyph = dict(GEAR, y=top + GEAR["y_from_center"])
            frame = self.build_notif()

        # Menü: sağ kenarı panelin sol kenarına sabit, içerik oradan sola kayar
        self.revealer = Gtk.Revealer(
            transition_type=Gtk.RevealerTransitionType.SLIDE_LEFT,
            transition_duration=ANIM_MS)
        frame.set_margin_end(GAP)
        self.revealer.set_child(frame)
        holder = Gtk.Box(halign=Gtk.Align.END, valign=Gtk.Align.START)
        holder.set_margin_end(PANEL_RIGHT)
        holder.set_margin_top(top)
        holder.append(self.revealer)
        root.add_overlay(holder)
        self.frame = frame

        # "Aktif" simge
        g = Gtk.Label(label=glyph["text"], halign=Gtk.Align.START,
                      valign=Gtk.Align.START, can_target=False)
        g.add_css_class("glyph")
        g.add_css_class(glyph["css"])
        g.set_margin_start(int(glyph["x"]))
        g.set_margin_top(int(glyph["y"]))
        root.add_overlay(g)

        win.set_child(root)

        click = Gtk.GestureClick()
        click.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
        click.connect("pressed", self.on_press)
        win.add_controller(click)

        keys = Gtk.EventControllerKey()
        keys.connect("key-pressed", self.on_key)
        win.add_controller(keys)

        win.present()
        GLib.timeout_add(30, lambda: self.revealer.set_reveal_child(True) and False)
        self.watch_panel()

    def item(self, text, on_click, *classes):
        b = Gtk.Button(label=text)
        b.add_css_class("item")
        for c in classes:
            b.add_css_class(c)
        b.get_child().set_xalign(0)
        b.connect("clicked", on_click)
        return b

    # --- Güç menüsü --------------------------------------------------------
    def build_power(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        box.add_css_class("frame")
        box.set_size_request(220, -1)
        for text, action in (("󰌾   Kilitle", "lock"), ("󰤄   Uyku", "suspend"),
                             ("󰍃   Oturumu kapat", "logout"),
                             ("󰜉   Yeniden başlat", "reboot"), ("󰐥   Kapat", "poweroff")):
            extra = ("danger",) if action == "poweroff" else ()
            box.append(self.item(text, lambda _b, a=action: self.power(a), *extra))
        return box

    def power(self, action):
        self.close_then(f"{SCRIPTS}/power.sh", action)

    # --- Bildirim filtresi -------------------------------------------------
    def build_notif(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        box.add_css_class("frame")
        box.set_size_request(280, -1)

        title = Gtk.Label(label="BİLDİRİMLER", xalign=0)
        title.add_css_class("title")
        box.append(title)

        entry = Gtk.Entry(placeholder_text="Uygulama adı yaz · Enter")
        entry.connect("activate", self.on_entry)
        box.append(entry)

        self.list = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        scroll = Gtk.ScrolledWindow(hscrollbar_policy=Gtk.PolicyType.NEVER,
                                    propagate_natural_height=True,
                                    max_content_height=380)
        scroll.set_child(self.list)
        box.append(scroll)

        hint = Gtk.Label(label="󰂚 açık · 󰂛 kapalı", xalign=0)
        hint.add_css_class("hint")
        box.append(hint)
        self.fill_list()
        return box

    def fill_list(self):
        while (child := self.list.get_first_child()) is not None:
            self.list.remove(child)
        apps, blocked = read_apps()
        if not apps:
            empty = Gtk.Label(label="Henüz bildirim gönderen\nuygulama yok", xalign=0)
            empty.add_css_class("hint")
            self.list.append(empty)
        for app in apps:
            off = app in blocked
            self.list.append(self.item(f"{'󰂛' if off else '󰂚'}   {app}",
                                       lambda _b, a=app: self.toggle(a),
                                       *(("blocked",) if off else ())))

    def toggle(self, app):
        # notif-filter.sh SwayNC'yi yeniden yüklüyor, bu da Control Panel'i
        # kapatıyor; menü panelden önce kapansın
        self.close_then(f"{SCRIPTS}/notif-filter.sh", "toggle", app)

    def on_entry(self, entry):
        name = entry.get_text().strip()
        if name:
            entry.set_text("")
            self.toggle(name)

    # --- Kapanma -----------------------------------------------------------
    def on_press(self, gesture, _n, x, y):
        target = self.win.pick(x, y, Gtk.PickFlags.DEFAULT)
        if target is None or not (target == self.frame or target.is_ancestor(self.frame)):
            gesture.set_state(Gtk.EventSequenceState.CLAIMED)
            self.close()

    def on_key(self, _ctl, keyval, _code, _state):
        if keyval == Gdk.KEY_Escape:
            self.close()
            return True
        return False

    def watch_panel(self):
        """Control Panel kapanınca menüyü de kapat."""
        self.sub = subprocess.Popen(["swaync-client", "-s"], stdout=subprocess.PIPE,
                                    stderr=subprocess.DEVNULL)
        self.sub_buf = b""
        self.sub_src = fd_add(GLib.PRIORITY_DEFAULT, self.sub.stdout.fileno(),
                              GLib.IOCondition.IN | GLib.IOCondition.HUP, self.on_panel)

    def on_panel(self, fd, cond):
        # Ham okuma: tamponlu readline() aynı anda gelen satırları yutup
        # "visible: false" mesajını kaçırabiliyor
        data = os.read(fd, 4096) if cond & GLib.IOCondition.IN else b""
        if not data:
            self.close()
            return True  # kaynağı stop_watch kaldırır
        self.sub_buf += data
        *lines, self.sub_buf = self.sub_buf.split(b"\n")
        for line in lines:
            try:
                if not json.loads(line).get("visible", True):
                    self.close()
                    return True  # kaynağı stop_watch kaldırır
            except ValueError:
                pass
        return True

    def close(self):
        if self.win is None or self.closing:
            return
        self.closing = True
        self.stop_watch()
        self.revealer.set_reveal_child(False)
        GLib.timeout_add(ANIM_MS + 20, self.destroy_window)

    def close_then(self, *cmd):
        """Menüyü animasyonsuz hemen kapat, komutu ondan sonra çalıştır."""
        if self.win is None or self.closing:
            return
        self.closing = True
        self.stop_watch()
        self.destroy_window()
        # Pencerenin ekrandan kalkmasına bir kare süre tanı
        GLib.timeout_add(40, lambda: run(*cmd) and False)

    def destroy_window(self):
        if self.win is not None:
            self.win.destroy()
            self.win = None
        return False

    def stop_watch(self):
        if self.sub:
            GLib.source_remove(self.sub_src)
            self.sub.terminate()
            self.sub.wait()
            self.sub = None


def main():
    args = sys.argv[1:]
    if not args or args[0] != "daemon" or (len(args) > 1 and args[1] not in KINDS):
        print("kullanım: minipanel.py daemon [power|notif]", file=sys.stderr)
        return 1

    with open(PIDFILE, "w") as f:
        f.write(str(os.getpid()))

    app = MiniPanel(args[1] if len(args) > 1 else None)
    for kind, sig in KINDS.items():
        signal_add(GLib.PRIORITY_DEFAULT, sig, lambda k=kind: app.request(k) or True)
    for sig in (signal.SIGTERM, signal.SIGINT):
        signal_add(GLib.PRIORITY_DEFAULT, sig, lambda: app.quit() or True)
    code = app.run([])
    app.stop_watch()
    try:
        os.unlink(PIDFILE)
    except OSError:
        pass
    # GTK + layer-shell nesnelerinin Python kapanışında sonlandırılması
    # süreci asılı bırakıyor; iş bittiği için doğrudan çık
    os._exit(code)


if __name__ == "__main__":
    sys.exit(main())
