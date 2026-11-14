// userChrome.css'in yüklenmesi için
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Flatpak'te Zen ekran kartını tanıyamıyor (FEATURE_FAILURE_DL_BLOCKLIST_NO_ID)
// ve yazılımsal WebRender'a düşüyor; çizimi ekran kartına zorla
user_pref("gfx.webrender.all", true);
