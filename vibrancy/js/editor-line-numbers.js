/**
 * Fleet Snowfluff — editor line-number highlights (selection + multi-cursor).
 * DOM-only: cursor screen Y + selection overlay rects. Loaded via vscode_vibrancy.imports.
 */
(function () {
  'use strict';

  var HIGHLIGHT = 'fleet-line-number-highlight';
  var raf = 0;
  var dragging = false;
  var dragLineKeys = null;
  var highlightState = typeof WeakMap !== 'undefined' ? new WeakMap() : null;
  var editorObservers = typeof WeakMap !== 'undefined' ? new WeakMap() : null;
  var debugEl = null;

  function lineKeyFromRect(rect) {
    return Math.round((rect.top + rect.bottom) / 2);
  }

  function cursorScreenCenters(editorRoot) {
    var layer = editorRoot.querySelector('.cursors-layer');
    if (!layer) return [];
    var nodes = layer.querySelectorAll('.cursor');
    if (!nodes.length) nodes = layer.querySelectorAll(':scope > div');
    var centers = [];
    Array.prototype.forEach.call(nodes, function (node) {
      var rect = node.getBoundingClientRect();
      if (rect.height > 0) centers.push((rect.top + rect.bottom) / 2);
    });
    return centers;
  }

  function selectionRects(editorRoot) {
    var rects = [];
    editorRoot.querySelectorAll('.view-overlays .selected-text').forEach(function (node) {
      if (node.closest('.view-lines')) return;
      var rect = node.getBoundingClientRect();
      if (rect.height > 0.5 && rect.width > 0) rects.push(rect);
    });
    editorRoot.querySelectorAll('.view-lines .view-line').forEach(function (line) {
      if (!line.querySelector('.selected-text')) return;
      var rect = line.getBoundingClientRect();
      if (rect.height > 0) rects.push(rect);
    });
    return rects;
  }

  function lineMatchesCursorY(lineRect, cursorCenters) {
    var lineCy = (lineRect.top + lineRect.bottom) / 2;
    for (var i = 0; i < cursorCenters.length; i++) {
      if (Math.abs(lineCy - cursorCenters[i]) <= 4) return true;
    }
    return false;
  }

  function lineOverlapsRect(lineRect, selRect) {
    return lineRect.height > 0 &&
      lineRect.top < selRect.bottom - 1 &&
      lineRect.bottom > selRect.top + 1;
  }

  function shouldHighlight(ln, cursorCenters, selRects, dragKeys) {
    var lineRect = ln.getBoundingClientRect();
    var key = lineKeyFromRect(lineRect);

    if (dragKeys && dragKeys.has(key)) return true;
    if (ln.classList.contains('active-line-number')) return true;
    if (lineMatchesCursorY(lineRect, cursorCenters)) return true;

    for (var i = 0; i < selRects.length; i++) {
      if (lineOverlapsRect(lineRect, selRects[i])) return true;
    }
    return false;
  }

  function isEditorVisible(editorRoot) {
    var rect = editorRoot.getBoundingClientRect();
    return rect.width > 2 && rect.height > 2;
  }

  function applyHighlights(editorRoot) {
    if (!isEditorVisible(editorRoot)) return;
    var cursorCenters = cursorScreenCenters(editorRoot);
    var selRects = selectionRects(editorRoot);

    editorRoot.querySelectorAll('.margin-view-overlays .line-numbers').forEach(function (ln) {
      var lineRect = ln.getBoundingClientRect();
      var key = lineKeyFromRect(lineRect);
      var next = shouldHighlight(ln, cursorCenters, selRects, dragLineKeys);

      if (dragging && next && dragLineKeys) dragLineKeys.add(key);

      var prev = highlightState ? highlightState.get(ln) : undefined;
      if (prev === next) return;

      if (highlightState) highlightState.set(ln, next);
      if (next) ln.classList.add(HIGHLIGHT);
      else ln.classList.remove(HIGHLIGHT);
    });
  }

  function isDebugOn() {
    return document.documentElement.dataset.fleetLnDebug === '1';
  }

  function collectDebugInfo(editorRoot) {
    var layer = editorRoot.querySelector('.cursors-layer');
    var cursors = layer ? layer.querySelectorAll('.cursor, :scope > div') : [];
    return {
      cursorsDom: cursors.length,
      cursorCenters: cursorScreenCenters(editorRoot).length,
      selRects: selectionRects(editorRoot).length,
      highlighted: editorRoot.querySelectorAll('.' + HIGHLIGHT).length,
      activeLine: editorRoot.querySelectorAll('.active-line-number').length,
      dragging: dragging,
      dragSticky: dragLineKeys ? dragLineKeys.size : 0
    };
  }

  function ensureDebugHud() {
    if (!isDebugOn()) {
      if (debugEl) {
        debugEl.remove();
        debugEl = null;
      }
      return;
    }
    if (!debugEl) {
      debugEl = document.createElement('div');
      debugEl.id = 'fleet-ln-debug';
      debugEl.style.cssText =
        'position:fixed;bottom:8px;left:8px;z-index:999999;' +
        'font:12px/1.4 ui-monospace,monospace;' +
        'background:rgba(0,0,0,.88);color:#ffb7c5;padding:8px 10px;' +
        'border-radius:6px;pointer-events:none;max-width:420px;white-space:pre-wrap;';
      document.body.appendChild(debugEl);
    }
  }

  function updateDebugHud(info) {
    ensureDebugHud();
    if (!debugEl) return;
    debugEl.textContent = [
      'Fleet line-numbers debug',
      '关闭: document.documentElement.dataset.fleetLnDebug=""',
      '',
      'cursors DOM: ' + info.cursorsDom,
      'cursor Y: ' + info.cursorCenters,
      'selection rects: ' + info.selRects,
      '高亮行号: ' + info.highlighted,
      'active-line: ' + info.activeLine,
      'dragging: ' + info.dragging,
      'drag sticky: ' + info.dragSticky
    ].join('\n');
  }

  function syncAll() {
    raf = 0;
    var editors = document.querySelectorAll('.monaco-editor');
    editors.forEach(applyHighlights);
    if (isDebugOn() && editors.length) {
      var info = collectDebugInfo(editors[0]);
      info.editors = editors.length;
      updateDebugHud(info);
    }
  }

  function schedule() {
    if (raf) return;
    raf = requestAnimationFrame(syncAll);
  }

  function bindEditor(editorRoot) {
    if (editorObservers && editorObservers.has(editorRoot)) return;
    var mo = new MutationObserver(schedule);
    mo.observe(editorRoot, {
      subtree: true,
      childList: true,
      attributes: true,
      attributeFilter: ['class']
    });
    if (editorObservers) editorObservers.set(editorRoot, mo);
  }

  function scanEditors() {
    document.querySelectorAll('.monaco-editor').forEach(bindEditor);
    schedule();
  }

  new MutationObserver(function (mutations) {
    for (var i = 0; i < mutations.length; i++) {
      if (mutations[i].addedNodes.length) {
        scanEditors();
        return;
      }
    }
  }).observe(document.body, { childList: true, subtree: true });

  document.addEventListener('mousedown', function (e) {
    if (e.button !== 0 || !e.target.closest('.monaco-editor')) return;
    dragging = true;
    dragLineKeys = new Set();
    schedule();
  }, true);

  document.addEventListener('mouseup', function () {
    if (!dragging) return;
    dragging = false;
    dragLineKeys = null;
    schedule();
  }, true);

  document.addEventListener('mousemove', function (e) {
    if (!dragging || e.buttons !== 1) return;
    schedule();
  }, true);

  document.addEventListener('keyup', schedule, true);

  window.fleetLnDiag = function () {
    var editors = document.querySelectorAll('.monaco-editor');
    if (!editors.length) {
      var empty = { error: '页面上没有 .monaco-editor，请先打开一个代码文件' };
      console.log('[fleetLnDiag]', empty);
      return empty;
    }
    var ed = editors[0];
    var info = collectDebugInfo(ed);
    info.editors = editors.length;
    var layer = ed.querySelector('.cursors-layer');
    var cursors = layer ? layer.querySelectorAll('.cursor, :scope > div') : [];
    info.cursorNodes = Array.prototype.map.call(cursors, function (c, i) {
      var r = c.getBoundingClientRect();
      return {
        i: i,
        class: c.className,
        rectTop: Math.round(r.top),
        rectH: Math.round(r.height)
      };
    });
    console.log('[fleetLnDiag]', info);
    if (isDebugOn()) updateDebugHud(info);
    return info;
  };

  scanEditors();
})();
