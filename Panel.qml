import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Popup panel for the Ajazz AJ139 Pro mouse: shows live status and lets the
// user change polling rate, active DPI profile, the 8 DPI stages and their
// LED colours. Every control shells out to `ajazz-ctl`, which performs a
// backup before writing.
Panel {
  id: root
  moduleName: "io.github.alanus96.ajazz-mouse"
  ipcTarget: "io.github.alanus96.ajazz-mouse"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var info: ({})
  property bool loading: false
  property bool busy: false
  property string error: ""

  readonly property var barIdentity: hostWidget || root
  readonly property string ctlPath: localPath(Qt.resolvedUrl("scripts/ajazz-ctl"))

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) value = value.substring(7)
    try { return decodeURIComponent(value) } catch (error) { return value }
  }
  readonly property var palette: ["#ff0000", "#00ff00", "#0000ff", "#ffff00",
                                  "#00ffff", "#ff00ff", "#ffffff", "#ff8000",
                                  "#8000ff", "#000000"]

  readonly property var dpiValues: (info && info.dpi) ? info.dpi : []
  readonly property var colors: (info && info.colors) ? info.colors : []
  readonly property int rateHz: (info && info.polling_hz) ? info.polling_hz : 0
  readonly property int activeProfile: (info && info.active_profile) ? info.active_profile : 0

  function open() {
    error = ""
    loading = true
    root.controller.show()
    Qt.callLater(root.refresh)
  }
  function close() { root.controller.hide() }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function refresh() {
    if (!infoProcess.running) infoProcess.running = true
  }

  function applyInfo(raw) {
    try {
      var parsed = JSON.parse(String(raw || "{}"))
      info = (parsed && typeof parsed === "object") ? parsed : ({})
      error = ""
    } catch (e) {
      error = "Konnte Daten nicht lesen"
    }
    loading = false
  }

  function run(args) {
    if (actionProcess.running) return
    busy = true
    error = ""
    actionProcess.actionArgs = args
    actionProcess.running = true
  }

  function clampDpi(value) {
    var v = Math.max(100, Math.min(30000, Number(value) || 0))
    return Math.round(v / 50) * 50
  }

  function stepDpi(slot, delta) {
    var current = Number(root.dpiValues[slot - 1] || 0)
    root.run(["dpi", String(slot), String(root.clampDpi(current + delta))])
  }

  function nextColor(slot) {
    var current = String(root.colors[slot - 1] || "").toLowerCase()
    var idx = root.palette.indexOf(current)
    return root.palette[(idx + 1) % root.palette.length]
  }

  function cycleColor(slot) {
    root.run(["color", String(slot), root.nextColor(slot)])
  }

  function statusText() {
    if (root.error !== "") return root.error
    if (!root.info || root.info.battery === undefined) return root.loading ? "Lese Daten…" : ""
    var b = root.info.battery
    var parts = [b.pct + "%"]
    parts.push(b.charging ? "lädt" : "entlädt")
    parts.push(root.rateHz + " Hz")
    parts.push("Profil " + root.activeProfile)
    return parts.join("  ·  ")
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(text) { if (text === "r" || text === "R") root.refresh() }

      Column {
        id: contentColumn
        width: parent.width
        spacing: Style.space(8)

        // ── header ──
        Text {
          width: parent.width
          text: "Ajazz AJ139 Pro"
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
        }

        Text {
          width: parent.width
          text: root.statusText()
          color: root.error !== "" ? Color.urgent : Qt.darker(root.barForeground, 1.35)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Rectangle { width: parent.width; height: Math.max(1, Style.space(1)); color: root.barForeground; opacity: 0.14 }

        // ── polling rate ──
        Text {
          text: "POLLING-RATE"
          color: Qt.darker(root.barForeground, 1.5)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        Row {
          spacing: Style.space(6)
          Repeater {
            model: [125, 250, 500, 1000]
            delegate: Chip {
              required property int modelData
              label: String(modelData)
              selected: root.rateHz === modelData
              foreground: root.barForeground
              enabled: !root.busy
              onClicked: root.run(["rate", String(modelData)])
            }
          }
        }

        // ── active profile ──
        Text {
          text: "AKTIVES PROFIL"
          color: Qt.darker(root.barForeground, 1.5)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        Row {
          spacing: Style.space(6)
          Repeater {
            model: 8
            delegate: Chip {
              required property int index
              label: String(index + 1)
              selected: root.activeProfile === index + 1
              foreground: root.barForeground
              enabled: !root.busy
              onClicked: root.run(["profile", String(index + 1)])
            }
          }
        }

        // ── DPI stages + colours ──
        Text {
          text: "DPI-STUFEN UND FARBEN"
          color: Qt.darker(root.barForeground, 1.5)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        Repeater {
          model: 8
          delegate: Item {
            required property int index
            width: contentColumn.width
            height: Style.space(28)

            Text {
              id: stageLabel
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(46)
              text: "DPI" + (index + 1)
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.body
            }

            Rectangle {
              id: swatch
              anchors.left: stageLabel.right
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(18)
              height: width
              radius: Style.space(4)
              color: root.colors[index] || "transparent"
              border.width: 1
              border.color: Qt.rgba(root.barForeground.r, root.barForeground.g, root.barForeground.b, 0.4)
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: !root.busy
                onClicked: root.cycleColor(index + 1)
              }
            }

            Text {
              anchors.left: swatch.right
              anchors.leftMargin: Style.space(10)
              anchors.right: minusChip.left
              anchors.rightMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              text: (root.dpiValues[index] !== undefined ? root.dpiValues[index] : "–") + " dpi"
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignRight
            }

            Chip {
              id: minusChip
              anchors.right: plusChip.left
              anchors.rightMargin: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter
              label: "−"
              foreground: root.barForeground
              enabled: !root.busy
              onClicked: root.stepDpi(index + 1, -100)
            }

            Chip {
              id: plusChip
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              label: "+"
              foreground: root.barForeground
              enabled: !root.busy
              onClicked: root.stepDpi(index + 1, 100)
            }
          }
        }

        Rectangle { width: parent.width; height: Math.max(1, Style.space(1)); color: root.barForeground; opacity: 0.14 }

        // ── footer ──
        Row {
          spacing: Style.space(6)
          Chip {
            label: "Backup"
            foreground: root.barForeground
            enabled: !root.busy
            onClicked: root.run(["backup"])
          }
          Chip {
            label: "Wiederherstellen"
            foreground: root.barForeground
            enabled: !root.busy
            onClicked: root.run(["restore"])
          }
          Chip {
            label: "Neu laden"
            foreground: root.barForeground
            enabled: !root.busy
            onClicked: root.refresh()
          }
        }

        Text {
          width: parent.width
          text: "Klick auf die Farbe wechselt sie · R lädt neu · Schreiben ändert die Maus sofort"
          color: Qt.darker(root.barForeground, 1.7)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
      }
    }
  }

  Process {
    id: infoProcess
    command: [root.ctlPath, "info", "--json"]
    onRunningChanged: if (running) root.loading = true
    onExited: root.loading = false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyInfo(text)
    }
  }

  Process {
    id: actionProcess
    property var actionArgs: []
    command: [root.ctlPath].concat(actionArgs)
    onExited: function(code) {
      root.busy = false
      if (code !== 0) root.error = "Aktion fehlgeschlagen (darf keinen Admin brauchen?)"
      root.refresh()
    }
    stderr: StdioCollector { waitForEnd: true }
  }
}
