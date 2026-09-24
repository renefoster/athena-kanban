// Pure JS business logic for Athena Kanban
.pragma library

function parseData(jsonStr) {
  var fallback = { version: 1, wipLimit: 3, columns: ["todo", "doing", "done"], tasks: [] };
  if (!jsonStr || typeof jsonStr !== "string" || !jsonStr.trim()) return fallback;
  try {
    var parsed = JSON.parse(jsonStr);
    if (!parsed || !Array.isArray(parsed.tasks)) parsed.tasks = [];
    if (!parsed.wipLimit) parsed.wipLimit = 3;
    return parsed;
  } catch (e) {
    return fallback;
  }
}

function serializeData(dataObj) {
  return JSON.stringify(dataObj, null, 2);
}

function getTasksByColumn(tasks, col) {
  if (!Array.isArray(tasks)) return [];
  return tasks.filter(function(t) { return t && t.column === col; });
}

function getWipCount(tasks) {
  return getTasksByColumn(tasks, "doing").length;
}

function addTask(dataObj, column, title) {
  var cleanTitle = String(title || "").trim();
  if (!cleanTitle) return dataObj;
  var now = new Date();
  var newTask = {
    id: String(now.getTime()),
    title: cleanTitle,
    column: column || "todo",
    createdAt: now.toISOString()
  };
  var newTasks = (dataObj.tasks || []).slice();
  newTasks.push(newTask);
  return {
    version: dataObj.version || 1,
    wipLimit: dataObj.wipLimit || 3,
    columns: dataObj.columns || ["todo", "doing", "done"],
    tasks: newTasks
  };
}

function moveTask(dataObj, taskId, targetColumn) {
  var now = new Date();
  var nowIso = now.toISOString();
  var newTasks = (dataObj.tasks || []).map(function(t) {
    if (t.id === String(taskId)) {
      var updatedTask = {
        id: t.id,
        title: t.title,
        column: targetColumn,
        createdAt: t.createdAt,
        progressAt: t.progressAt,
        doneAt: t.doneAt
      };
      if (targetColumn === "doing") updatedTask.progressAt = nowIso;
      if (targetColumn === "done") updatedTask.doneAt = nowIso;
      return updatedTask;
    }
    return t;
  });
  return {
    version: dataObj.version || 1,
    wipLimit: dataObj.wipLimit || 3,
    columns: dataObj.columns || ["todo", "doing", "done"],
    tasks: newTasks
  };
}

function formatDuration(ms) {
  if (!ms || ms < 0) return "0m";
  var totalSeconds = Math.floor(ms / 1000);
  var hours = Math.floor(totalSeconds / 3600);
  var minutes = Math.floor((totalSeconds % 3600) / 60);
  var seconds = totalSeconds % 60;

  var res = [];
  if (hours > 0) res.push(hours + "h");
  if (minutes > 0) res.push(minutes + "m");
  if (seconds > 0 || res.length === 0) res.push(seconds + "s");
  return res.join(" ");
}

function calculateTimeDiff(start, end) {
  if (!start || !end) return 0;
  return new Date(end).getTime() - new Date(start).getTime();
}

function deleteTask(dataObj, taskId) {
  var newTasks = (dataObj.tasks || []).filter(function(t) {
    return t.id !== String(taskId);
  });
  return {
    version: dataObj.version || 1,
    wipLimit: dataObj.wipLimit || 3,
    columns: dataObj.columns || ["todo", "doing", "done"],
    tasks: newTasks
  };
}

function clearDone(dataObj) {
  var newTasks = (dataObj.tasks || []).filter(function(t) {
    return t.column !== "done";
  });
  return {
    version: dataObj.version || 1,
    wipLimit: dataObj.wipLimit || 3,
    columns: dataObj.columns || ["todo", "doing", "done"],
    tasks: newTasks
  };
}
