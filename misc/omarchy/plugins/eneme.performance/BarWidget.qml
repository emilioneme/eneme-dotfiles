import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "eneme.performance"

  property int cpuUsage: 0
  property int memoryUsage: 0
  property string gpuUsage: "N/A"
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function refresh() {
    if (!statsProcess.running) statsProcess.running = true
  }

  function togglePanel() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
  }

  function applyStats(raw) {
    try {
      var values = String(raw || "0,0").trim().split(",")
      root.cpuUsage = Math.max(0, Math.min(100, Number(values[0]) || 0))
      root.memoryUsage = Math.max(0, Math.min(100, Number(values[1]) || 0))
      root.gpuUsage = values[5] || "N/A"
    } catch (error) {
      root.cpuUsage = 0
      root.memoryUsage = 0
      root.gpuUsage = "N/A"
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Timer {
    interval: 2000
    running: true
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

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: " " + root.cpuUsage + "%   " + root.memoryUsage + "%  GPU " + (root.gpuUsage === "N/A" ? "N/A" : root.gpuUsage + "%")
    horizontalMargin: 8
    verticalPadding: 6
    tooltipText: "CPU and memory usage"

    onPressed: function(mouseButton) { if (mouseButton === Qt.LeftButton) root.togglePanel() }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: { root.injectPanel(); Qt.callLater(root.injectPanel) }
  }

  onBarChanged: injectPanel()
}
