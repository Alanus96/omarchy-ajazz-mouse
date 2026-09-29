import QtQuick
import qs.Commons

// Small clickable pill used for the mouse panel controls.
Rectangle {
  id: chip

  property string label: ""
  property bool selected: false
  property bool enabled: true
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  signal clicked()

  implicitWidth: labelItem.implicitWidth + Style.space(16)
  implicitHeight: Style.space(26)
  radius: Style.space(6)
  opacity: enabled ? 1.0 : 0.5
  color: selected
    ? accent
    : Qt.rgba(foreground.r, foreground.g, foreground.b, 0.10)
  border.width: Math.max(1, Style.space(1))
  border.color: selected
    ? accent
    : Qt.rgba(foreground.r, foreground.g, foreground.b, 0.28)

  Text {
    id: labelItem
    anchors.centerIn: parent
    text: chip.label
    color: chip.selected ? Color.background : chip.foreground
    font.family: chip.fontFamily
    font.pixelSize: Style.font.body
    renderType: Text.NativeRendering
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: chip.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    enabled: chip.enabled
    onClicked: chip.clicked()
  }
}
