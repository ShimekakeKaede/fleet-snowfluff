/**
 * Fleet Snowfluff — Activity bar Account / Settings menu-open tracker.
 * Loaded via vscode_vibrancy.imports; requires Fleet Vibrancy runtime patch (setup-vibrancy.ps1).
 */
(function () {
  'use strict';

  var GLOBAL_ROOT =
    '.monaco-workbench .activitybar > .content > :not(.composite-bar)';
  var GLOBAL_ITEM =
    GLOBAL_ROOT + ' .monaco-action-bar .action-item, ' +
    GLOBAL_ROOT + ' .monaco-action-bar .composite-bar-action-tab';
  var GLOBAL_ICON =
    '.activitybar .codicon-settings-view-bar-icon, .activitybar .codicon-accounts-view-bar-icon';
  var MENU =
    '.context-view .monaco-menu-container, .context-view .monaco-menu';
  var OPEN_CLASS = 'fleet-act-menu-open';

  var openTargets = null;
  var menuWasVisible = false;

  function queryItem(target) {
    if (!target || !target.closest) return null;
    var viaBar = target.closest(GLOBAL_ITEM);
    if (viaBar) return viaBar;
    var icon = target.closest(GLOBAL_ICON);
    if (!icon) return null;
    return icon.closest('.action-item') ||
      icon.closest('.composite-bar-action-tab') ||
      icon.closest('.composite-bar-action-tab-label');
  }

  function menuVisible() {
    return !!document.querySelector(MENU);
  }

  function clearOpen() {
    if (!openTargets) return;
    openTargets.forEach(function (el) {
      el.classList.remove(OPEN_CLASS);
    });
    openTargets = null;
  }

  function applyOpen(item) {
    if (!item) return;
    clearOpen();
    var targets = [item];
    var actionItem = item.classList.contains('action-item')
      ? item
      : item.closest('.action-item');
    var tab = item.classList.contains('composite-bar-action-tab')
      ? item
      : item.closest('.composite-bar-action-tab');
    if (actionItem && targets.indexOf(actionItem) === -1) targets.push(actionItem);
    if (tab && targets.indexOf(tab) === -1) targets.push(tab);
    openTargets = targets;
    targets.forEach(function (el) {
      el.classList.add(OPEN_CLASS);
    });
  }

  function sync() {
    var visible = menuVisible();
    if (visible) {
      menuWasVisible = true;
      return;
    }
    if (menuWasVisible) {
      menuWasVisible = false;
      clearOpen();
    }
  }

  var observerRaf = 0;

  function scheduleSync() {
    sync();
    requestAnimationFrame(sync);
    setTimeout(sync, 0);
    setTimeout(sync, 50);
    setTimeout(sync, 200);
  }

  function scheduleObserverSync() {
    if (observerRaf) return;
    observerRaf = requestAnimationFrame(function () {
      observerRaf = 0;
      sync();
    });
  }

  function onPointerDown(event) {
    if (event.button !== 0) return;
    var item = queryItem(event.target);
    if (!item) return;
    applyOpen(item);
    scheduleSync();
  }

  function onKeyDown(event) {
    if (event.key !== 'Enter' && event.key !== ' ') return;
    var item = queryItem(event.target);
    if (!item) return;
    applyOpen(item);
    scheduleSync();
  }

  var observer = new MutationObserver(scheduleObserverSync);

  function start() {
    if (!document.querySelector('.monaco-workbench')) {
      requestAnimationFrame(start);
      return;
    }
    document.documentElement.dataset.fleetActMenu = 'ready';
    document.addEventListener('mousedown', onPointerDown, true);
    document.addEventListener('keydown', onKeyDown, true);
    observer.observe(document.body, {
      childList: true,
      subtree: true,
    });
    scheduleSync();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
