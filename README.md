# kvara dotfiles

CachyOS (Arch) + Hyprland 0.56 masaüstü ayarları. Lavanta & altın tema
(Catppuccin Mocha tabanlı), iki monitör (eDP-1 + DP-1).

## İçerik

| Klasör | Ne |
|---|---|
| `config/hypr` | Hyprland (`hyprland.lua`), hyprlock, yardımcı betikler (`scripts/`), duvar kağıtları |
| `config/waybar` | Üst bar — [mechabar](https://github.com/sejjy/mechabar) temeli üzerine özelleştirilmiş |
| `config/swaync` | Bildirim servisi + sağdan açılan **Control Panel** |
| `config/swayosd` | Ses / parlaklık / Caps Lock ekran göstergesi |
| `config/rofi` | Uygulama başlatıcı |
| `config/kitty` | Terminal |
| `config/fish` | Kabuk (`fish_variables` bilerek dahil değil) |
| `config/qt6ct` | Qt uygulamalarının teması |
| `config/autostart` | Blueman otomatik başlatmasını kapatır (Bluetooth'u KDE bluedevil yönetiyor) |
| `zen/` | Zen Browser: pencere sürüklemeyi ve kapat/küçült/büyüt butonlarını kapatır. Profil klasörüne kopyalanır: `userChrome.css` → `chrome/`, `user.js` → profil köküne (Flatpak'te `~/.var/app/app.zen_browser.zen/.zen/<profil>/`) |
| `system/` | Sistem dosyaları (`/etc` altına gider, `sudo` gerekir) |

## Control Panel (swaync)

Waybar'ın en sağındaki butonla açılır (SUPER+N de olur), tıklanan monitörde
sağdan kayarak gelir. Bildirim varsa Waybar butonu altın renge döner.

- Bilgisayar adının solundaki güneş (󰖙) güç butonu: panelin soluna mini bir
  güç menüsü açar (kilit, uyku, çıkış, yeniden başlat, kapat; son üçü onay ister)
- Wi-Fi, Bluetooth, Rahatsız Etme, ekran görüntüsü, parlaklık
- **Mullvad** butonu: yeşil = bağlı, kırmızı = daemon açık / VPN kapalı,
  gri = daemon kapalı, altın = bağlanıyor. Yanındaki mini buton daemon'u açar/kapatır.
- MSI Center (MControlCenter), Razer (Polychromatic)
- Medya, bildirimler. NOTIFICATIONS solundaki çark, panelin soluna açılan mini
  panelde hangi uygulamaların bildirim
  gönderebileceğini seçtirir. Bildirim gönderen
  uygulamalar `~/.local/state/swaync/known-apps`'e kaydedilir; kapatılanlar
  `config.json` → `notification-visibility` altına `block: <ad>` olarak yazılır.
  `config.json`'daki `scripts` girdisi tam yol kullanır (`/home/kuyash/...`):
  SwayNC script komutlarında `sh -c` ve `$HOME` çalışmıyor.
- Mini paneller `scripts/minipanel.py` (GTK4 + gtk4-layer-shell, Python).
  Oturum açılınca arka planda başlar (`mini-panel.sh daemon`, cairo ile çizim,
  ~75 MB); butonlar `mini-panel.sh power|notif` ile sinyal gönderir, böylece
  menü ~50 ms'de açılır. Ekranı kaplayan şeffaf bir katmanda menü
  panelin kenarından sola kayar; dışarı tıklama / Esc / panelin kapanması
  menüyü kapatır. Konumlar ölçülmüş sabitler (ölçek 1.25, panel 458px);
  panel boyutu değişirse `minipanel.py`'nin başındaki değerler güncellenmeli
  (çarkın yüksekliği medya kartına göre değiştiği için ekrandan okunuyor).
  Gereken paketler: `python-gobject`, `gtk4-layer-shell`.

Betikler: `config/swaync/scripts/` (`mullvad.sh`, `power.sh`, `toggle.sh`,
`mcontrolcenter.sh`). `config/swaync/mullvad-state.css` `mullvad.sh`
tarafından otomatik yazılır.

## Kilit ve giriş ekranı

hyprlock (`config/hypr/hyprlock.conf`) ve SDDM (`system/usr/share/sddm/themes/kvara`)
aynı tasarımı kullanır: blur'suz `tower.png`, sol sütunda saat + cam kart.
Arka plan, solu hafif karartılmış bir kopya (`lock-bg.png`); duvar kağıdı
değişirse `config/hypr/scripts/lock-bg.py` ile yeniden üretilip SDDM temasının
`assets/background.png`'sine de kopyalanmalı. Boyutlar 1920x1080 fiziksel
piksel (hyprlock ölçek uygulamıyor). SDDM teması pixie'nin yerine geçti:
pixie avatarı gösteremiyordu (uzantısız yolu reddediyordu) ve paket
güncellemesinde elle yapılan değişiklikler silinirdi.

```fish
sudo cp -r system/usr/share/sddm/themes/kvara /usr/share/sddm/themes/
sudo sed -i 's/^Current=.*/Current=kvara/' /etc/sddm.conf /etc/sddm.conf.d/theme.conf
```

Test (kurmadan): `sddm-greeter-qt6 --test-mode --theme system/usr/share/sddm/themes/kvara`

## Gerekli paketler

Depodan:

```fish
sudo pacman -S hyprland hyprlock hyprpolkitagent hyprshot uwsm \
    waybar swaync swayosd rofi kitty fish qt6ct \
    awww waypaper cliphist wl-clipboard grim fzf jq \
    brightnessctl playerctl pavucontrol otf-commit-mono-nerd
```

AUR'dan: `mullvad-vpn-bin`, `mcontrolcenter-git`, `polychromatic`,
`bibata-cursor-theme-bin`.

## Kurulum

Var olan ayarların üzerine yazar — önce yedek al.

```fish
cp -r config/* ~/.config/
sudo install -m 644 system/etc/polkit-1/rules.d/50-mullvad-daemon.rules /etc/polkit-1/rules.d/
```

`50-mullvad-daemon.rules` kullanıcı adına (`kuyash`) bağlıdır; başka bir
kullanıcıda dosyadaki adı değiştir.

## Notlar

- **Hyprland 0.57+ sadece Lua config okur.** `hyprland.lua` asıl config;
  `hyprland.conf` 0.56 ve öncesi için arşiv olarak duruyor. `hyprland.lua`
  yoksa Hyprland varsayılan bir config üretip onunla açılır (Waybar, Türkçe
  klavye vb. olmadan). `hyprctl dispatch` de artık Lua bekler:
  `hyprctl dispatch 'hl.dsp.exit()'`. Doğrulamak için:
  `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua`
- **Blur (GTK 4.24 + Hyprland 0.56):** GTK4 uygulamalarında layerrule'daki
  `blur = on` tek başına yetmez; GTK blur alanını kendisi bildirir. CSS'te
  `backdrop-filter` olmayan yüzey için alan boş kalır ve blur olmaz
  (bkz. `swaync/style.css` sonu).
- **Mini Mullvad butonu ve kullanıcı adı** CSS `transform` ile
  yerleştirildi (SwayNC ızgara butonlarına sabit minimum genişlik veriyor).
  Panel genişliği (572px) değişirse bu değerlerin yeniden ayarlanması gerekir.
- Waybar teması [sejjy/mechabar](https://github.com/sejjy/mechabar) (MIT)
  üzerine kuruludur; lisansı `config/waybar/LICENSE`.
