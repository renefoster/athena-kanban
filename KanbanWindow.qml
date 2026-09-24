import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Item {
  id: root
  property var hostWidget: null
  readonly property bool isOpen: window.visible

  property string dataFile: Quickshell.env("HOME") + "/.config/omarchy/kanban_data.json"
  property var rawData: ({ version: 1, wipLimit: 3, columns: ["todo", "doing", "done"], tasks: [] })

  readonly property var todoTasks: Model.getTasksByColumn(rawData.tasks, "todo")
  readonly property var doingTasks: Model.getTasksByColumn(rawData.tasks, "doing")
  readonly property var doneTasks: Model.getTasksByColumn(rawData.tasks, "done")
  readonly property int wipCount: doingTasks.length
  readonly property int wipLimit: rawData.wipLimit || 3

  readonly property int cornerRadius: Style.cornerRadius > 0 ? Style.cornerRadius : 8
  readonly property int smallCornerRadius: Math.max(4, cornerRadius - 4)

  function open() {
    refreshData()
    window.visible = true
  }

  function close() {
    window.visible = false
  }

  function toggle() {
    if (window.visible) close()
    else open()
  }

  function refreshData() {
    if (!readProc.running) readProc.running = true
  }

  function handleReadResult(text) {
    rawData = Model.parseData(text)
  }

  function saveData(newObj) {
    rawData = newObj
    var jsonStr = Model.serializeData(newObj)
    writeProc.command = ["bash", "-c", "cat << 'EOF' > " + dataFile + "\n" + jsonStr + "\nEOF"]
    writeProc.running = true
    if (hostWidget && typeof hostWidget.refreshData === "function") {
      hostWidget.refreshData()
    }
  }

  function addTask(col, title) {
    var updated = Model.addTask(rawData, col, title)
    saveData(updated)
  }

  function moveTask(id, targetCol) {
    var updated = Model.moveTask(rawData, id, targetCol)
    saveData(updated)
  }

  function deleteTask(id) {
    var updated = Model.deleteTask(rawData, id)
    saveData(updated)
  }

  function clearDone() {
    var updated = Model.clearDone(rawData)
    saveData(updated)
  }

  Component.onCompleted: refreshData()

  Process {
    id: readProc
    command: ["cat", root.dataFile]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.handleReadResult(text)
    }
  }

  Process {
    id: writeProc
    onExited: function(exitCode) {
      root.refreshData()
    }
  }

  FloatingWindow {
    id: window
    title: "Athena Kanban"
    implicitWidth: 920
    implicitHeight: 600
    minimumSize: Qt.size(680, 440)
    visible: false
    color: Color.background

    Item {
      anchors.fill: parent
      anchors.margins: 16
      focus: true

      Keys.onEscapePressed: root.close()

      // Header
      RowLayout {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36
        spacing: 12

        Text {
          text: " Athena Kanban"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: 18
          font.bold: true
        }

        Rectangle {
          color: root.wipCount > root.wipLimit ? Color.urgent : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.08)
          radius: root.smallCornerRadius
          implicitWidth: wipBadgeText.implicitWidth + 16
          implicitHeight: 24

          Text {
            id: wipBadgeText
            anchors.centerIn: parent
            text: root.wipCount + " / " + root.wipLimit + " WIP"
            color: root.wipCount > root.wipLimit ? "white" : Color.muted
            font.family: Style.font.family
            font.pixelSize: 11
            font.bold: true
          }
        }

        Item { Layout.fillWidth: true }

        Rectangle {
          implicitWidth: 28
          implicitHeight: 28
          radius: root.smallCornerRadius
          color: closeBtnArea.containsMouse ? Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.12) : "transparent"

          Text {
            anchors.centerIn: parent
            text: "✕"
            color: Color.foreground
            font.pixelSize: 13
          }

          MouseArea {
            id: closeBtnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.close()
          }
        }
      }

      // 3 Kanban Columns
      RowLayout {
        anchors.top: header.bottom
        anchors.topMargin: 16
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 14

        // 1. TO DO
        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.04)
          radius: root.cornerRadius
          border.color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.12)
          border.width: 1

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Text {
              text: "To Do (" + root.todoTasks.length + ")"
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: 14
              font.bold: true
            }

            Rectangle {
              Layout.fillWidth: true
              height: 34
              color: Qt.rgba(Color.background.r, Color.background.g, Color.background.b, 0.7)
              radius: root.smallCornerRadius
              border.color: addInput.activeFocus ? Color.accent : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.15)
              border.width: 1

              TextInput {
                id: addInput
                anchors.fill: parent
                anchors.margins: 8
                color: Color.foreground
                selectionColor: Color.accent
                font.family: Style.font.family
                font.pixelSize: 12
                clip: true
                selectByMouse: true

                Text {
                  anchors.fill: parent
                  text: "+ Add new task..."
                  color: Color.muted
                  font.family: Style.font.family
                  font.pixelSize: 12
                  visible: !addInput.text && !addInput.activeFocus
                }

                onAccepted: {
                  if (text.trim().length > 0) {
                    root.addTask("todo", text.trim())
                    text = ""
                  }
                }
              }
            }

            ListView {
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true
              spacing: 8
              model: root.todoTasks

              delegate: Rectangle {
                width: ListView.view.width
                height: cardCol.implicitHeight + 16
                radius: root.smallCornerRadius
                color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.08)
                border.color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.14)
                border.width: 1

                ColumnLayout {
                  id: cardCol
                  anchors.fill: parent
                  anchors.margins: 8
                  spacing: 6

                  Text {
                    Layout.fillWidth: true
                    text: modelData.title
                    color: Color.foreground
                    font.family: Style.font.family
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                  }

                  RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }

                    Text {
                      text: "→"
                      color: Color.accent
                      font.bold: true
                      font.pixelSize: 14

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.moveTask(modelData.id, "doing")
                      }
                    }

                    Text {
                      text: " ✕"
                      color: Color.muted
                      font.pixelSize: 12

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.deleteTask(modelData.id)
                      }
                    }
                  }

                        Text {
                          Layout.fillWidth: true
                          text: {
                            if (!modelData.createdAt) return "Created: N/A";
                            var date = new Date(modelData.createdAt);
                            if (isNaN(date.getTime())) return "Created: N/A";

                            var localDate = new Date(date.getTime() + (8 * 60 * 60 * 1000));
                            var y = localDate.getUTCFullYear();
                            var m = ("0" + (localDate.getUTCMonth() + 1)).slice(-2);
                            var d = ("0" + localDate.getUTCDate()).slice(-2);
                            var hh = ("0" + localDate.getUTCHours()).slice(-2);
                            var mm = ("0" + localDate.getUTCMinutes()).slice(-2);

                            return "Created: " + y + "-" + m + "-" + d + " " + hh + ":" + mm;
                          }
                          color: Color.muted
                          font.family: Style.font.family
                          font.pixelSize: 10
                          horizontalAlignment: Text.AlignLeft
                        }
                }
              }
            }
          }
        }

        // 2. IN PROGRESS
        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.04)
          radius: root.cornerRadius
          border.color: root.wipCount > root.wipLimit ? Color.urgent : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.12)
          border.width: 1

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
              Layout.fillWidth: true
              Text {
                text: "In Progress (" + root.doingTasks.length + ")"
                color: Color.foreground
                font.family: Style.font.family
                font.pixelSize: 14
                font.bold: true
              }
              Item { Layout.fillWidth: true }
              Text {
                text: "Max " + root.wipLimit
                color: Color.muted
                font.family: Style.font.family
                font.pixelSize: 11
              }
            }

            ListView {
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true
              spacing: 8
              model: root.doingTasks

              delegate: Rectangle {
                width: ListView.view.width
                height: doingCardCol.implicitHeight + 16
                radius: root.smallCornerRadius
                color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.10)
                border.color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.4)
                border.width: 1

                ColumnLayout {
                  id: doingCardCol
                  anchors.fill: parent
                  anchors.margins: 8
                  spacing: 6

                  Text {
                    Layout.fillWidth: true
                    text: modelData.title
                    color: Color.foreground
                    font.family: Style.font.family
                    font.pixelSize: 12
                    font.bold: true
                    wrapMode: Text.Wrap
                  }

                  RowLayout {
                    Layout.fillWidth: true

                    Text {
                      text: "←"
                      color: Color.muted
                      font.bold: true
                      font.pixelSize: 14

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.moveTask(modelData.id, "todo")
                      }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                      text: "→"
                      color: Color.accent
                      font.bold: true
                      font.pixelSize: 14

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.moveTask(modelData.id, "done")
                      }
                    }

                    Text {
                      text: " ✕"
                      color: Color.muted
                      font.pixelSize: 12

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.deleteTask(modelData.id)
                      }
                    }
                  }

                        Text {
                          Layout.fillWidth: true
                          text: {
                            if (!modelData.createdAt) return "Created: N/A";
                            var date = new Date(modelData.createdAt);
                            if (isNaN(date.getTime())) return "Created: N/A";

                            var localDate = new Date(date.getTime() + (8 * 60 * 60 * 1000));
                            var y = localDate.getUTCFullYear();
                            var m = ("0" + (localDate.getUTCMonth() + 1)).slice(-2);
                            var d = ("0" + localDate.getUTCDate()).slice(-2);
                            var hh = ("0" + localDate.getUTCHours()).slice(-2);
                            var mm = ("0" + localDate.getUTCMinutes()).slice(-2);

                            return "Created: " + y + "-" + m + "-" + d + " " + hh + ":" + mm;
                          }
                          color: Color.muted
                          font.family: Style.font.family
                          font.pixelSize: 10
                          horizontalAlignment: Text.AlignLeft
                        }

                  RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Text {
                      id: stopwatchText
                      color: Color.accent
                      font.family: Style.font.family
                      font.pixelSize: 11
                      font.bold: true
                      text: "00:00:00"
                    }
                  }

                  Timer {
                    interval: 1000
                    running: modelData.column === "doing" && modelData.progressAt
                    repeat: true
                    onTriggered: {
                      var start = new Date(modelData.progressAt).getTime();
                      var now = new Date().getTime();
                      var diff = now - start;
                      var h = Math.floor(diff / 3600000);
                      var m = Math.floor((diff % 3600000) / 60000);
                      var s = Math.floor((diff % 60000) / 1000);
                      stopwatchText.text = (h < 10 ? "0" + h : h) + ":" +
                                           (m < 10 ? "0" + m : m) + ":" +
                                           (s < 10 ? "0" + s : s);
                    }
                  }
                }
              }
            }
          }
        }

        // 3. DONE
        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.04)
          radius: root.cornerRadius
          border.color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.12)
          border.width: 1

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
              Layout.fillWidth: true
              Text {
                text: "Done (" + root.doneTasks.length + ")"
                color: Color.foreground
                font.family: Style.font.family
                font.pixelSize: 14
                font.bold: true
              }
              Item { Layout.fillWidth: true }
              Text {
                text: "Clear"
                color: Color.muted
                font.family: Style.font.family
                font.pixelSize: 11
                visible: root.doneTasks.length > 0

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.clearDone()
                }
              }
            }

            ListView {
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true
              spacing: 8
              model: root.doneTasks

              delegate: Rectangle {
                width: ListView.view.width
                height: doneCardCol.implicitHeight + 16
                radius: root.smallCornerRadius
                color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.06)
                border.color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.10)
                border.width: 1
                opacity: 0.75

                ColumnLayout {
                  id: doneCardCol
                  anchors.fill: parent
                  anchors.margins: 8
                  spacing: 6

                  Text {
                    Layout.fillWidth: true
                    text: modelData.title
                    color: Color.muted
                    font.family: Style.font.family
                    font.pixelSize: 12
                    font.strikeout: true
                    wrapMode: Text.Wrap
                  }

                  RowLayout {
                    Layout.fillWidth: true

                    Text {
                      text: "←"
                      color: Color.muted
                      font.bold: true
                      font.pixelSize: 14

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.moveTask(modelData.id, "doing")
                      }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                      text: " ✕"
                      color: Color.muted
                      font.pixelSize: 12

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.deleteTask(modelData.id)
                      }
                    }
                  }

                        Text {
                          Layout.fillWidth: true
                          text: {
                            if (!modelData.createdAt) return "Created: N/A";
                            var date = new Date(modelData.createdAt);
                            if (isNaN(date.getTime())) return "Created: N/A";

                            var localDate = new Date(date.getTime() + (8 * 60 * 60 * 1000));
                            var y = localDate.getUTCFullYear();
                            var m = ("0" + (localDate.getUTCMonth() + 1)).slice(-2);
                            var d = ("0" + localDate.getUTCDate()).slice(-2);
                            var hh = ("0" + localDate.getUTCHours()).slice(-2);
                            var mm = ("0" + localDate.getUTCMinutes()).slice(-2);

                            return "Created: " + y + "-" + m + "-" + d + " " + hh + ":" + mm;
                          }
                          color: Color.muted
                          font.family: Style.font.family
                          font.pixelSize: 10
                          horizontalAlignment: Text.AlignLeft
                        }

                  Text {
                    Layout.fillWidth: true
                    color: Color.muted
                    font.family: Style.font.family
                    font.pixelSize: 10
                    font.bold: true
                    text: {
                      var c = modelData.createdAt;
                      var p = modelData.progressAt;
                      var d = modelData.doneAt;

                      var diffL = p ? Model.formatDuration(Model.calculateTimeDiff(c, p)) : "N/A";
                      var diffD = (p && d) ? Model.formatDuration(Model.calculateTimeDiff(p, d)) : "N/A";
                      var diffT = d ? Model.formatDuration(Model.calculateTimeDiff(c, d)) : "N/A";

                      return "[l] " + diffL + " [d] " + diffD + " [t] " + diffT;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
