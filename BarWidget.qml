import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "renefoster.athena-kanban"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property string dataFile: Quickshell.env("HOME") + "/.config/omarchy/kanban_data.json"
  property var rawData: ({ tasks: [] })
  property int doingCount: 0
  property int totalCount: 0

  function refreshData() {
    if (!readProc.running) readProc.running = true
  }

  function handleReadResult(text) {
    rawData = Model.parseData(text)
    var tasks = rawData.tasks || []
    doingCount = Model.getWipCount(tasks)
    totalCount = tasks.length
  }

  Component.onCompleted: refreshData()

  Process {
    id: readProc
    command: ["cat", root.dataFile]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.handleReadResult(text)
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) root.handleReadResult("")
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: root.refreshData()
  }

  readonly property string barText: root.doingCount > 0 ? " " + root.doingCount : ""

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.barText
    active: root.doingCount > 0
    horizontalMargin: 8
    tooltipText: "Athena Kanban (" + root.doingCount + " doing, " + root.totalCount + " total)"

    onPressed: function(b) {
      if (b === Qt.MiddleButton) {
        root.refreshData()
      } else if (root.bar) {
        root.bar.run("omarchy-shell shell toggle renefoster.athena-kanban '{}'")
      }
    }
  }
}
