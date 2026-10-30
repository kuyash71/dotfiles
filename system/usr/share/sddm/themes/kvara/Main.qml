// kvara — SDDM giriş ekranı (Lavanta & Altın)
// ~/.config/hypr/hyprlock.conf'un birebir karşılığı: aynı arka plan, aynı
// sol sütun (saat, tarih, cam kart). Sayılar hyprlock'taki gibi 1920x1080
// fiziksel piksel; başka çözünürlükte `s` ile ölçeklenir. Yazı boyutları
// hyprlock'taki punto değerleri × 4/3 (piksel).

import QtQuick
import QtQuick.Controls.Basic
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#11111b"

    readonly property real s: height / 1080
    readonly property real colX: width / 2 - 470 * s   // sütunun merkezi
    readonly property real midY: height / 2

    readonly property string font: "CommitMono Nerd Font"
    readonly property color cream: "#fff8e7"
    readonly property color gold: "#e5c283"
    readonly property color lav: "#957fb8"
    readonly property color red: "#f38ba8"

    function pt(p) { return Math.round(p * 4 / 3 * s) }

    // --- Kullanıcı / oturum -------------------------------------------------
    property string userName: userModel.lastUser
    property string avatarSrc: Qt.resolvedUrl("assets/avatar.png")
    property int sessionIndex: sessionModel.lastIndex
    property int attempts: 0
    property bool failed: false

    Repeater {
        model: userModel
        delegate: Item {
            Component.onCompleted: {
                if (root.userName === "" && index === 0)
                    root.userName = model.name
                if (model.name === root.userName && model.icon)
                    root.avatarSrc = model.icon.toString().startsWith("/")
                        ? "file://" + model.icon : model.icon
            }
        }
    }

    // Oturum adlarını sırayla topla (alttaki oturum seçici için)
    property var sessions: []
    Repeater {
        model: sessionModel
        delegate: Item {
            Component.onCompleted: {
                var l = root.sessions.slice()
                l[index] = model.name.replace(" (uwsm-managed)", " · uwsm")
                root.sessions = l
            }
        }
    }

    function login() {
        if (password.text.length === 0)
            return
        sddm.login(root.userName, password.text, root.sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.attempts += 1
            root.failed = true
            password.text = ""
            failTimer.restart()
        }
    }
    Timer { id: failTimer; interval: 2000; onTriggered: root.failed = false }

    // --- Arka plan: blur yok, solu hafif karartılmış (hypr/scripts/lock-bg.py)
    Image {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        smooth: false   // piksel sanat keskin kalsın
    }

    // --- Saat / tarih -------------------------------------------------------
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    Text {
        id: clock
        text: Qt.formatTime(root.now, "HH:mm")
        color: root.cream
        font { family: root.font; pixelSize: pt(92); bold: true }
        x: root.colX - width / 2
        y: root.midY - 285 * s - height / 2
        style: Text.Raised
        styleColor: "#4d11111b"
    }

    Text {
        text: Qt.locale("tr_TR").toString(root.now, "dddd · d MMMM")
        color: root.gold
        font { family: root.font; pixelSize: pt(14); letterSpacing: pt(4) }
        x: root.colX - width / 2
        y: root.midY - 208 * s - height / 2
        style: Text.Raised
        styleColor: "#4d11111b"
    }

    // --- Cam kart -----------------------------------------------------------
    Canvas {
        id: card
        width: 380 * s
        height: 342 * s
        x: root.colX - width / 2
        y: root.midY + 36 * s - height / 2
        onPaint: {
            var ctx = getContext("2d"), b = 2 * s, r = 28 * s
            ctx.reset()
            ctx.beginPath()
            ctx.roundedRect(b / 2, b / 2, width - b, height - b, r, r)
            ctx.fillStyle = Qt.rgba(17 / 255, 17 / 255, 27 / 255, 0.55)
            ctx.fill()
            // Köşeden köşeye lavanta → altın
            var g = ctx.createLinearGradient(0, 0, width * 0.35, height)
            g.addColorStop(0, root.lav)
            g.addColorStop(1, root.gold)
            ctx.strokeStyle = g
            ctx.lineWidth = b
            ctx.stroke()
        }
    }

    // --- Avatar: yuvarlak, altın → lavanta halka ------------------------------
    Canvas {
        id: avatar
        width: 136 * s
        height: 136 * s
        x: root.colX - width / 2
        y: root.midY - 36 * s - height / 2
        Component.onCompleted: loadImage(root.avatarSrc)
        onImageLoaded: requestPaint()
        Connections {
            target: root
            function onAvatarSrcChanged() { avatar.loadImage(root.avatarSrc) }
        }
        onPaint: {
            var ctx = getContext("2d"), b = 3 * s, c = width / 2
            ctx.reset()
            if (isImageLoaded(root.avatarSrc)) {
                ctx.save()
                ctx.beginPath()
                ctx.arc(c, c, c - b, 0, 2 * Math.PI)
                ctx.clip()
                ctx.drawImage(root.avatarSrc, b, b, width - 2 * b, height - 2 * b)
                ctx.restore()
            }
            var g = ctx.createLinearGradient(0, 0, width, height)
            g.addColorStop(0, root.gold)
            g.addColorStop(1, root.lav)
            ctx.beginPath()
            ctx.arc(c, c, c - b / 2, 0, 2 * Math.PI)
            ctx.strokeStyle = g
            ctx.lineWidth = b
            ctx.stroke()
        }
    }

    Text {
        text: root.userName
        color: root.gold
        font { family: root.font; pixelSize: pt(18); bold: true }
        x: root.colX - width / 2
        y: root.midY + 62 * s - height / 2
    }

    Text {
        text: "󰖙 " + (sddm.hostName || "kvara")
        color: root.lav
        font { family: root.font; pixelSize: pt(11); letterSpacing: pt(2) }
        x: root.colX - width / 2
        y: root.midY + 89 * s - height / 2
    }

    // --- Şifre ----------------------------------------------------------------
    TextField {
        id: password
        width: 300 * s
        height: 50 * s
        x: root.colX - width / 2
        y: root.midY + 148 * s - height / 2
        focus: true
        echoMode: TextInput.Password
        passwordCharacter: "●"
        horizontalAlignment: TextInput.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter
        color: root.cream
        selectionColor: root.lav
        font { family: root.font; pixelSize: pt(12); letterSpacing: pt(3) }
        // Qt odaktaki ortalanmış alanda placeholderText'i gizliyor; kendimiz çiziyoruz
        Text {
            anchors.centerIn: parent
            visible: password.text.length === 0
            text: root.failed ? "Yanlış şifre · " + root.attempts : "󰌾   Şifre"
            color: root.failed ? root.red : root.lav
            font { family: root.font; pixelSize: pt(12) }
        }
        onAccepted: root.login()
        onTextChanged: if (text.length) root.failed = false
        background: Rectangle {
            radius: height / 2
            color: Qt.rgba(30 / 255, 30 / 255, 46 / 255, 0.6)
            border.width: 2 * s
            border.color: root.failed ? root.red
                        : keyboard.capsLock ? root.gold
                        : Qt.rgba(149 / 255, 127 / 255, 184 / 255, 0.45)
        }
        Component.onCompleted: forceActiveFocus()
    }

    // --- Alt satır: klavye · oturum · yeniden başlat · kapat --------------------
    Row {
        id: bottom
        spacing: 26 * s
        x: root.colX - width / 2
        y: root.height - 36 * s - height

        component Info: Text {
            property bool clickable: false
            color: clickable && area.containsMouse ? root.gold : root.lav
            font { family: root.font; pixelSize: pt(11) }
            style: Text.Raised
            styleColor: "#b311111b"
            signal clicked
            MouseArea {
                id: area
                anchors.fill: parent
                enabled: parent.clickable
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: parent.clicked()
            }
        }

        Info {
            visible: keyboard.layouts.length > 0
            text: "󰌌  " + (visible ? keyboard.layouts[keyboard.currentLayout].longName : "")
        }
        Info {
            // Tıklayınca sıradaki oturuma geç (Hyprland / uwsm / Plasma)
            text: "󰕮  " + (root.sessions[root.sessionIndex] || "")
            clickable: root.sessions.length > 1
            onClicked: root.sessionIndex = (root.sessionIndex + 1) % root.sessions.length
        }
        Info {
            text: "󰜉"
            clickable: sddm.canReboot
            visible: sddm.canReboot
            onClicked: sddm.reboot()
        }
        Info {
            text: "󰐥"
            clickable: sddm.canPowerOff
            visible: sddm.canPowerOff
            onClicked: sddm.powerOff()
        }
    }
}
