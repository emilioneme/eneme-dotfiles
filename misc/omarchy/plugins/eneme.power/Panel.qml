import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "eneme.power"
  ipcTarget: "eneme.power"
  manageIpc: true

  property int selectedIndex: 0
  property bool cursorActive: false
  property string uptimeText: ""
  property bool hibernateAvailable: true
  property bool suspendAvailable: true

  readonly property var powerItems: Model.getItems(hibernateAvailable, suspendAvailable)

  function moveCursor(dy) {
    var len = powerItems.length
    if (len <= 0) return
    if (!cursorActive) {
      cursorActive = true
      if (dy < 0) {
        selectedIndex = len - 1
      } else {
        selectedIndex = 0
      }
      return
    }
    selectedIndex = (selectedIndex + dy + len) % len
  }

  function activateCursor() {
    if (selectedIndex >= 0 && selectedIndex < powerItems.length) {
      triggerItem(powerItems[selectedIndex])
    }
  }

  function triggerItem(item) {
    if (!item) return
    root.close()
    if (item.action) {
      Util.execDetached(item.action)
    }
  }

  function triggerKey(keyChar) {
    var k = String(keyChar || "").toLowerCase()
    for (var i = 0; i < powerItems.length; i++) {
      if (powerItems[i].key === k || String(i + 1) === k) {
        selectedIndex = i
        triggerItem(powerItems[i])
        return true
      }
    }
    return false
  }

  Process {
    id: hibernateCheck
    command: ["omarchy-hibernation-available"]
    onExited: function(code) {
      root.hibernateAvailable = (code === 0)
    }
  }

  Process {
    id: suspendCheck
    command: ["bash", "-c", "! omarchy-toggle-enabled suspend-off"]
    onExited: function(code) {
      root.suspendAvailable = (code === 0)
    }
  }

  Process {
    id: uptimeProc
    command: ["uptime", "-p"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "").trim()
        if (raw) root.uptimeText = raw
      }
    }
  }

  function checkAvailability() {
    hibernateCheck.running = true
    suspendCheck.running = true
    uptimeProc.running = true
  }

  Component.onCompleted: checkAvailability()

  onOpenedChanged: {
    if (opened) {
      cursorActive = false
      selectedIndex = 0
      checkAvailability()
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    tooltipText: "Power Menu"
    active: root.opened
    onPressed: function(b) {
      root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(270))
    contentHeight: panel.fittedContentHeight(panelColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (dy !== 0) root.moveCursor(dy)
      }
      onActivateRequested: root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) { root.triggerKey(t) }

      Column {
        id: panelColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(10)

        // Header / Hero
        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

          Text {
            id: heroIcon
            text: ""
            color: Color.accent
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(12)
            anchors.right: closeBtn.left
            anchors.rightMargin: Style.space(6)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "Power Menu"
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              text: root.uptimeText ? root.uptimeText.toUpperCase() : "SYSTEM CONTROLS"
              color: Qt.darker(root.barForeground, 1.4)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.1
              elide: Text.ElideRight
              width: parent.width
            }
          }

          PanelActionButton {
            id: closeBtn
            iconText: "✕"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            tooltipText: "Close"
            onClicked: root.close()
          }
        }

        // Separator
        PanelSeparator {
          foreground: root.barForeground
        }

        // Action Rows
        Column {
          width: parent.width
          spacing: Style.space(4)

          Repeater {
            model: root.powerItems

            CursorSurface {
              id: itemRow
              required property var modelData
              required property int index

              readonly property bool isSelected: root.cursorActive && root.selectedIndex === index
              readonly property bool isUrgent: modelData.urgent === true
              readonly property bool isAccent: modelData.accent === true

              width: parent.width
              implicitHeight: Style.space(38)
              hasCursor: isSelected
              foreground: root.barForeground

              Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(8)
                anchors.rightMargin: Style.space(8)
                spacing: Style.space(10)

                Text {
                  text: itemRow.modelData.icon
                  color: itemRow.isUrgent
                    ? (itemRow.isSelected ? Color.urgent : Qt.darker(Color.urgent, 1.2))
                    : (itemRow.isAccent
                      ? (itemRow.isSelected ? Color.accent : Qt.darker(Color.accent, 1.2))
                      : root.barForeground)
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.title
                  width: Style.space(22)
                  horizontalAlignment: Text.AlignHCenter
                  anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                  width: parent.width - Style.space(22) - Style.space(10) - (hotkeyBadge.visible ? hotkeyBadge.width + Style.space(10) : 0)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(1)

                  Text {
                    text: itemRow.modelData.label
                    color: itemRow.isUrgent && itemRow.isSelected ? Color.urgent : root.barForeground
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.body
                    font.bold: itemRow.isSelected
                    elide: Text.ElideRight
                    width: parent.width
                  }

                  Text {
                    text: itemRow.modelData.detail
                    color: Qt.darker(root.barForeground, 1.4)
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideRight
                    width: parent.width
                  }
                }

                BorderSurface {
                  id: hotkeyBadge
                  visible: itemRow.modelData.hotkey !== ""
                  implicitWidth: Style.space(22)
                  implicitHeight: Style.space(20)
                  anchors.verticalCenter: parent.verticalCenter
                  radius: Style.cornerRadius
                  color: itemRow.isSelected ? Style.hoverFillFor(root.barForeground, Color.accent) : Util.alpha(root.barForeground, 0.06)
                  borderSpec: Border.flat(Util.alpha(root.barForeground, itemRow.isSelected ? 0.4 : 0.15), 1)

                  Text {
                    anchors.centerIn: parent
                    text: itemRow.modelData.hotkey
                    color: itemRow.isSelected ? root.barForeground : Qt.darker(root.barForeground, 1.4)
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                  root.cursorActive = true
                  root.selectedIndex = itemRow.index
                }
                onClicked: {
                  root.triggerItem(itemRow.modelData)
                }
              }
            }
          }
        }

        // Footer hint
        PanelSeparator {
          foreground: root.barForeground
          opacity: 0.4
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Style.space(6)
          opacity: 0.45

          Text {
            text: "↑↓ move"
            color: root.barForeground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
          Text {
            text: "•"
            color: root.barForeground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
          Text {
            text: "↵ run"
            color: root.barForeground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
          Text {
            text: "•"
            color: root.barForeground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
          Text {
            text: "esc close"
            color: root.barForeground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }
}
