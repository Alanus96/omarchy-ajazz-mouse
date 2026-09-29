import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Battery / charging / connection-mode widget for an Ajazz AJ139 Pro (COMPX)
// mouse. The value is read straight from `ajazz-battery --status`, so the
// widget never depends on a cached file and reacts to USB plug/unplug on the
// next poll. Left click opens the control panel.
BarWidget {
  id: root
  moduleName: "io.github.alanus96.ajazz-mouse"

  property var status: ({})
  property bool haveStatus: false

  readonly property bool showPercent: setting("showPercent", true) === true
  readonly property int pollSeconds: Math.max(1, Number(setting("pollInterval", 2)))
  readonly property int warningThreshold: Number(setting("warningThreshold", 30))
  readonly property int criticalThreshold: Number(setting("criticalThreshold", 15))
  readonly property bool hideWhenOffline: setting("hideWhenOffline", false) === true
  readonly property string scriptPath: localPath(Qt.resolvedUrl("scripts/ajazz-battery"))

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) value = value.substring(7)
    try { return decodeURIComponent(value) } catch (error) { return value }
  }

  readonly property bool present: haveStatus ? status.present === true : false
  readonly property bool online: haveStatus ? status.online === true : false
  readonly property int percent: (haveStatus && status.pct !== undefined && status.pct !== null)
    ? Math.round(Number(status.pct)) : -1
  readonly property bool charging: haveStatus ? status.charging === true : false
  readonly property string transport: (haveStatus && status.transport) ? String(status.transport) : ""

  readonly property bool low: online && percent >= 0 && percent <= warningThreshold
  readonly property bool critical: online && percent >= 0 && percent <= criticalThreshold
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function refresh() {
    if (!statusProcess.running) statusProcess.running = true
  }

  function applyStatus(raw) {
    var parsed = null
    try { parsed = JSON.parse(String(raw || "").trim()) } catch (e) { parsed = null }
    if (parsed && typeof parsed === "object") {
      root.status = parsed
      root.haveStatus = true
    }
  }

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    target.bar = root.bar
    target.settings = root.settings
    target.anchorItem = button
    target.hostWidget = root
  }

  function barText() {
    if (!root.present) return "󰍽"
    if (!root.online) return "󰍽 –"
    var label = root.percent >= 0 ? String(root.percent) + "%" : "–"
    if (!root.showPercent) label = ""
    if (root.charging) label += (label.length ? " " : "") + "⚡"
    return ("󰍽" + (label.length ? " " + label : ""))
  }

  function tooltip() {
    var name = "Ajazz AJ139 Pro"
    if (!root.haveStatus) return name + " · reading…"
    if (!root.present) return name + " · not connected"
    if (!root.online) return name + " · no reply (asleep?)"
    var parts = [name, root.percent + "%"]
    parts.push(root.charging ? "charging" : "discharging")
    if (root.transport.length) parts.push(root.transport)
    return parts.join(" · ")
  }

  visible: root.present || !root.hideWhenOffline
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()
  Component.onCompleted: refresh()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: true
    text: root.barText()
    active: root.low
    useActiveColor: true
    tooltipText: root.tooltip()
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton) root.toggle()
      else root.refresh()
    }
  }

  Process {
    id: statusProcess
    command: [root.scriptPath, "--status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyStatus(text)
    }
  }

  Timer {
    interval: root.pollSeconds * 1000
    running: !root.opened
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
