#!/usr/bin/env bash
#
# MControlCenter'ı tray yöneticisi (StatusNotifierWatcher) hazır olunca başlat.
#
# Sorun: Tray yöneticisi oturum ortasında değişirse (ör. KDE'nin kded6'sı geç
# başlayıp görevi Waybar'dan devralırsa) MControlCenter yeniden kaydolmuyor ve
# simgesi kayboluyordu. Bu yüzden kded6'yı en başta başlatıp tray yöneticisinin
# baştan sabit kalmasını sağlıyoruz, MControlCenter'ı da ondan sonra açıyoruz.

# kded6'yı D-Bus üzerinden başlat (zaten çalışıyorsa bir şey yapmaz)
busctl --user call org.kde.kded6 /kded org.kde.kded6 loadedModules > /dev/null 2>&1

# Tray yöneticisini en fazla 20 sn bekle
for _ in {1..40}; do
	busctl --user status org.kde.StatusNotifierWatcher > /dev/null 2>&1 && break
	sleep 0.5
done

exec mcontrolcenter
