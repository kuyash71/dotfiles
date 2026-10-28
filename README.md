# kvara dotfiles

CachyOS (Arch) + Hyprland 0.56 masaüstü ayarları. Lavanta & altın tema
(Catppuccin Mocha tabanlı), iki monitör (eDP-1 + DP-1).

## İçerik

| Klasör | Ne |
|---|---|
| `config/hypr` | Hyprland, hyprlock, yardımcı betikler (`scripts/`), duvar kağıtları |
| `config/waybar` | Üst bar — [mechabar](https://github.com/sejjy/mechabar) temeli üzerine özelleştirilmiş |
| `config/swaync` | Bildirim servisi + sağdan açılan **Control Panel** |
| `config/swayosd` | Ses / parlaklık / Caps Lock ekran göstergesi |
| `config/rofi` | Uygulama başlatıcı |
| `config/kitty` | Terminal |
| `config/fish` | Kabuk (`fish_variables` bilerek dahil değil) |
| `config/qt6ct` | Qt uygulamalarının teması |
| `config/autostart` | Blueman otomatik başlatmasını kapatır (Bluetooth'u KDE bluedevil yönetiyor) |
| `system/` | Sistem dosyaları (`/etc` altına gider, `sudo` gerekir) |

## Control Panel (swaync)

Waybar'ın en sağındaki butonla açılır (SUPER+N de olur), tıklanan monitörde
sağdan kayarak gelir. Bildirim varsa Waybar butonu altın renge döner.

- Güç satırı: kilit, uyku, çıkış, yeniden başlat, kapat (son üçü onay ister)
- Wi-Fi, Bluetooth, Rahatsız Etme, ekran görüntüsü, parlaklık
- **Mullvad** butonu: yeşil = bağlı, kırmızı = daemon açık / VPN kapalı,
  gri = daemon kapalı, altın = bağlanıyor. Yanındaki mini buton daemon'u açar/kapatır.
- MSI Center (MControlCenter), Razer (Polychromatic)
- Medya, ses (+ çark: pavucontrol), bildirimler

Betikler: `config/swaync/scripts/` (`mullvad.sh`, `power.sh`, `toggle.sh`,
`mcontrolcenter.sh`). `config/swaync/mullvad-state.css` `mullvad.sh`
tarafından otomatik yazılır.

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

- **Blur (GTK 4.24 + Hyprland 0.56):** GTK4 uygulamalarında layerrule'daki
  `blur = on` tek başına yetmez; GTK blur alanını kendisi bildirir. CSS'te
  `backdrop-filter` olmayan yüzey için alan boş kalır ve blur olmaz
  (bkz. `swaync/style.css` sonu).
- **Mini Mullvad butonu ve kullanıcı adı** CSS `transform` ile
  yerleştirildi (SwayNC ızgara butonlarına sabit minimum genişlik veriyor).
  Panel genişliği (572px) değişirse bu değerlerin yeniden ayarlanması gerekir.
- Waybar teması [sejjy/mechabar](https://github.com/sejjy/mechabar) (MIT)
  üzerine kuruludur; lisansı `config/waybar/LICENSE`.
