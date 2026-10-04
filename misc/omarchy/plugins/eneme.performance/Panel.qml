import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "eneme.performance"
  ipcTarget: "eneme.performance"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  property int cpuUsage: 0
  property int memoryUsage: 0
  property string loadAverage: "0.00"
  property int diskUsage: 0
  property string refreshRate: "N/A"
  property string gpuUsage: "N/A"
  property string gpuTemperature: "N/A"
  property string vramUsage: "N/A"

  function open() {
    root.controller.show()
    root.refresh()
  }

  function close() { root.controller.hide() }
  function toggle() { root.opened ? root.close() : root.open() }

  function refresh() {
    if (!statsProcess.running) statsProcess.running = true
  }

  function applyStats(raw) {
    var values = String(raw || "0,0,0.00,0").trim().split(",")
    root.cpuUsage = Math.max(0, Math.min(100, Number(values[0]) || 0))
    root.memoryUsage = Math.max(0, Math.min(100, Number(values[1]) || 0))
    root.loadAverage = values[2] || "0.00"
    root.diskUsage = Math.max(0, Math.min(100, Number(values[3]) || 0))
    root.refreshRate = values[4] || "N/A"
    root.gpuUsage = values[5] || "N/A"
    root.gpuTemperature = values[6] || "N/A"
    root.vramUsage = values[7] || "N/A"
  }

  function launch(command) {
    if (root.bar) root.bar.run(command)
    root.close()
  }

  Timer {
    interval: 2000
    running: root.opened
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: statsProcess
    command: ["bash", Quickshell.env("HOME") + "/.config/omarchy/plugins/eneme.performance/stats.sh"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyStats(text)
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: false
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(details.implicitHeight)
    focusTarget: keyCatcher

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()

      Column {
        id: details
        width: parent.width
        spacing: Style.space(12)

        Text {
          text: "System performance"
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
        }

        GridLayout {
          width: parent.width
          columns: 2
          columnSpacing: Style.space(18)
          rowSpacing: Style.space(8)

          Text { text: "CPU"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body }
          Text { text: root.cpuUsage + "%"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
          Text { text: "Memory"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body }
          Text { text: root.memoryUsage + "%"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
          Text { text: "Load average"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body }
          Text { text: root.loadAverage; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
          Text { text: "Root disk"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body }
          Text { text: root.diskUsage + "%"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
          Text { text: "Refresh rate"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body }
          Text { text: root.refreshRate + (root.refreshRate === "N/A" ? "" : " Hz"); color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
          Text { text: "GPU"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body }
          Text { text: root.gpuUsage + (root.gpuUsage === "N/A" ? "" : "%"); color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
          Text { text: "GPU temperature"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body }
          Text { text: root.gpuTemperature + (root.gpuTemperature === "N/A" ? "" : " C"); color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
          Text { text: "VRAM"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body }
          Text { text: root.vramUsage + (root.vramUsage === "N/A" ? "" : "%"); color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true }
        }

        Rectangle { width: parent.width; height: 1; color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.2) }

        GridLayout {
          width: parent.width
          columns: 2
          columnSpacing: Style.space(8)
          rowSpacing: Style.space(8)

          Repeater {
            model: [
              { label: "btop", command: "uwsm-app -- ghostty --class=org.omarchy.btop --window-width=170 --window-height=100 -e btop" },
              { label: "Disk usage", command: "xdg-terminal-exec --app-id=TUI.float -e bash -c 'dua i /'" },
              { label: "Disks", command: "uwsm-app -- gnome-disks" },
              { label: "System manager", command: "omarchy-menu system" }
            ]
            delegate: Rectangle {
              required property var modelData
              Layout.fillWidth: true
              implicitHeight: Style.space(38)
              color: buttonMouse.containsMouse ? Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.12) : "transparent"
              border.color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.35)
              border.width: 1
              radius: Style.cornerRadius

              Text {
                anchors.centerIn: parent
                text: modelData.label
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.body
              }

              MouseArea {
                id: buttonMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.launch(modelData.command)
              }
            }
          }
        }
      }
    }
  }
}
