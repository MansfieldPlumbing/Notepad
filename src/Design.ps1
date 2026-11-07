# Extracted design contract; no native renderer or application engine is implemented here.
# PSD1-compatible literal data inline in PS1. Invoke with &, never dot-source.
[CmdletBinding()]
param()
if ($MyInvocation.InvocationName -eq '.') { throw 'Invoke Notepad.Design.ps1 with &.' }
$Design = data {
@{
    'Provenance' = @{
        'Repository' = 'MansfieldPlumbing/JS2PS'
        'Path' = 'experiments/notepad.html'
        'GitBlobSha' = '9786ee25a52ba6ee9dc984e6dbe4809b63bc216e'
        'Sha256' = '3f0981401c086bc4eb9d1bb0c8716ac57797c59b1b30e3078c07f820044236e7'
        'StudyDate' = '2026-10-16'
        'QuickPSLocalCommit' = '62747ebf088d79fd45e704a09bfcdc5e998f6dfc'
    }
    'DefaultSettings' = @{
        'theme' = 'dark'
        'fontFamily' = 'Consolas'
        'fontStyle' = 'Regular'
        'fontSize' = '11'
        'wordWrap' = $true
        'formatting' = $true
        'openingFiles' = 'newTab'
        'startupOption' = 'continueSession'
        'recentFilesEnabled' = $false
        'spellCheck' = $true
        'showStatusBar' = $true
        'zoom' = 100
    }
    'Styles' = @{
        'RawCss' = '/* Windows 11 Modern Notepad - WinUI 3 Fluent Integrated Stylesheet */

:root {
  /* WinUI 3 Fluent Dark Palette */
  --bg-window: #1f1f1f;
  --bg-titlebar: #1f1f1f;
  --bg-menubar: #1f1f1f;
  --bg-editor: #282828;
  --bg-tab-active: #2c2c2c;
  --bg-tab-hover: #262626;
  --bg-card: #2d2d2d;
  --bg-card-hover: #323232;
  --bg-flyout: #2c2c2c;
  --bg-flyout-item-hover: #383838;
  --bg-control: #323232;
  --bg-control-hover: #3c3c3c;
  --bg-control-active: #2a2a2a;
  --bg-statusbar: #1f1f1f;
  --bg-dialog: #2c2c2c;

  --text-primary: #ffffff;
  --text-secondary: #9d9d9d;
  --text-disabled: #606060;
  --text-link: #60cdff;

  --border-subtle: rgba(255, 255, 255, 0.06);
  --border-control: rgba(255, 255, 255, 0.09);
  --border-active: #60cdff;

  --accent-color: #0090f1;
  --accent-hover: #1aa0ff;
  --accent-active: #0078d4;

  --selection-bg: #005fb8;
  --selection-text: #ffffff;

  --font-ui: ''Segoe UI Variable Text'', ''Segoe UI'', -apple-system, BlinkMacSystemFont, Roboto, sans-serif;
  --font-editor: ''Consolas'', ''Cascadia Code'', ''Courier New'', monospace;
  --font-size-editor: 11pt;
  --font-weight-editor: 400;
  --font-style-editor: normal;

  --shadow-flyout: 0 8px 24px rgba(0, 0, 0, 0.55);
  --shadow-modal: 0 16px 36px rgba(0, 0, 0, 0.65);
}

[data-theme="light"] {
  --bg-window: #f3f3f3;
  --bg-titlebar: #f3f3f3;
  --bg-menubar: #f3f3f3;
  --bg-editor: #ffffff;
  --bg-tab-active: #ffffff;
  --bg-tab-hover: #eaeaea;
  --bg-card: #ffffff;
  --bg-card-hover: #f9f9f9;
  --bg-flyout: #ffffff;
  --bg-flyout-item-hover: #f0f0f0;
  --bg-control: #fbfbfb;
  --bg-control-hover: #f5f5f5;
  --bg-control-active: #ebebeb;
  --bg-statusbar: #f3f3f3;
  --bg-dialog: #ffffff;

  --text-primary: #1b1b1b;
  --text-secondary: #616161;
  --text-disabled: #a0a0a0;
  --text-link: #005fb8;

  --border-subtle: rgba(0, 0, 0, 0.06);
  --border-control: rgba(0, 0, 0, 0.12);
  --border-active: #005fb8;

  --accent-color: #005fb8;
  --accent-hover: #106ebe;
  --accent-active: #004578;

  --selection-bg: #99c9ff;
  --selection-text: #000000;

  --shadow-flyout: 0 8px 24px rgba(0, 0, 0, 0.15);
  --shadow-modal: 0 16px 36px rgba(0, 0, 0, 0.25);
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  user-select: none;
  -webkit-user-select: none;
}

html, body {
  width: 100%;
  height: 100%;
  overflow: hidden;
  background-color: var(--bg-window);
  color: var(--text-primary);
  font-family: var(--font-ui);
  font-size: 14px;
  line-height: 1.4;
  -webkit-font-smoothing: antialiased;
}

/* Base Window Frame */
.notepad-window {
  display: flex;
  flex-direction: column;
  width: 100vw;
  height: 100vh;
  background-color: var(--bg-window);
  position: relative;
}

/* 1. Title Bar & Tabs Strip */
.notepad-titlebar {
  display: flex;
  align-items: center;
  height: 40px;
  background-color: var(--bg-titlebar);
  padding: 0 0 0 10px;
  position: relative;
  border-bottom: 1px solid var(--border-subtle);
  flex-shrink: 0;
}

.titlebar-left {
  display: flex;
  align-items: center;
  flex: 1;
  height: 100%;
  overflow: hidden;
}

.notepad-app-icon {
  width: 18px;
  height: 18px;
  margin-right: 12px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}

.notepad-app-icon svg {
  width: 100%;
  height: 100%;
}

.notepad-tabs-container {
  display: flex;
  align-items: flex-end;
  height: 100%;
  overflow-x: auto;
  overflow-y: hidden;
  scrollbar-width: none;
}
.notepad-tabs-container::-webkit-scrollbar {
  display: none;
}

.notepad-tab {
  display: flex;
  align-items: center;
  height: 34px;
  min-width: 130px;
  max-width: 220px;
  padding: 0 8px 0 12px;
  background-color: transparent;
  color: var(--text-secondary);
  border-radius: 7px 7px 0 0;
  cursor: pointer;
  position: relative;
  transition: background-color 0.1s ease, color 0.1s ease;
  font-size: 12px;
  margin-right: 2px;
}

.notepad-tab:hover {
  background-color: var(--bg-tab-hover);
  color: var(--text-primary);
}

.notepad-tab.active {
  background-color: var(--bg-tab-active);
  color: var(--text-primary);
  border-top: 1px solid var(--border-subtle);
  border-left: 1px solid var(--border-subtle);
  border-right: 1px solid var(--border-subtle);
  border-bottom: 1px solid var(--bg-tab-active);
  z-index: 2;
}

.tab-title {
  flex: 1;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  margin-right: 6px;
}

.tab-indicator-container {
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}

.tab-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background-color: var(--text-secondary);
  display: none;
}

.tab-close-btn {
  width: 20px;
  height: 20px;
  border-radius: 4px;
  display: none;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  color: var(--text-secondary);
  cursor: pointer;
}

.tab-close-btn:hover {
  background-color: var(--bg-control-hover);
  color: var(--text-primary);
}

.notepad-tab:hover .tab-close-btn,
.notepad-tab.active .tab-close-btn {
  display: flex;
}
.notepad-tab:hover .tab-dot,
.notepad-tab.active .tab-dot {
  display: none;
}
.notepad-tab.unsaved .tab-dot {
  display: block;
}
.notepad-tab.unsaved:hover .tab-dot {
  display: none;
}
.notepad-tab.unsaved:hover .tab-close-btn {
  display: flex;
}

.add-tab-btn {
  width: 32px;
  height: 32px;
  border-radius: 4px;
  background: transparent;
  border: none;
  color: var(--text-primary);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  margin-left: 4px;
  margin-bottom: 2px;
}

.add-tab-btn:hover {
  background-color: var(--bg-control-hover);
}

.add-tab-btn svg {
  width: 14px;
  height: 14px;
  fill: currentColor;
}

/* Window Controls */
.window-controls {
  display: flex;
  height: 100%;
}

.win-btn {
  width: 46px;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  color: var(--text-primary);
  cursor: pointer;
  transition: background-color 0.1s ease;
}

.win-btn svg {
  width: 10px;
  height: 10px;
  fill: currentColor;
}

.win-btn:hover {
  background-color: var(--bg-control-hover);
}

.win-btn.win-close:hover {
  background-color: #c42b1c;
  color: #ffffff;
}

.win-btn:active {
  background-color: var(--bg-control-active);
}

/* 2. Menu Bar */
.notepad-menubar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 38px;
  background-color: var(--bg-menubar);
  padding: 0 8px;
  border-bottom: 1px solid var(--border-subtle);
  position: relative;
  z-index: 100;
  flex-shrink: 0;
}

.menubar-left {
  display: flex;
  align-items: center;
}

.menu-item-btn {
  padding: 5px 10px;
  border-radius: 4px;
  background: transparent;
  border: none;
  color: var(--text-primary);
  font-family: var(--font-ui);
  font-size: 13px;
  cursor: pointer;
  margin-right: 2px;
  transition: background-color 0.1s ease;
}

.menu-item-btn:hover,
.menu-item-btn.open {
  background-color: var(--bg-control-hover);
}

.menubar-right {
  display: flex;
  align-items: center;
  gap: 4px;
}

.menu-action-btn {
  width: 32px;
  height: 32px;
  border-radius: 4px;
  background: transparent;
  border: none;
  color: var(--text-primary);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  position: relative;
  transition: background-color 0.1s ease;
}

.menu-action-btn:hover {
  background-color: var(--bg-control-hover);
}

.menu-action-btn svg {
  width: 16px;
  height: 16px;
  fill: currentColor;
}

.notification-badge-dot {
  position: absolute;
  top: 6px;
  right: 6px;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background-color: #0090f1;
}

/* 3. Flyout Menus - Exact WinUI 3 MenuFlyout Metrics */
.flyout-menu {
  position: absolute;
  top: 36px;
  background-color: var(--bg-flyout);
  border: 1px solid var(--border-control);
  border-radius: 8px;
  box-shadow: var(--shadow-flyout);
  padding: 4px;
  min-width: 240px;
  display: none;
  flex-direction: column;
  z-index: 1000;
  backdrop-filter: blur(20px);
}

.flyout-menu.open {
  display: flex;
  animation: flyoutFadeIn 0.1s ease-out;
}

@keyframes flyoutFadeIn {
  from {
    opacity: 0;
    transform: translateY(-2px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.menu-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 28px;
  padding: 0 10px;
  border-radius: 4px;
  color: var(--text-primary);
  font-size: 13px;
  line-height: 28px;
  cursor: pointer;
  position: relative;
  transition: background-color 0.08s ease;
  white-space: nowrap;
  flex-shrink: 0;
}

.menu-row:hover {
  background-color: var(--bg-flyout-item-hover);
}

.menu-row.disabled {
  color: var(--text-disabled);
  cursor: default;
  pointer-events: none;
}

.menu-row-left {
  display: flex;
  align-items: center;
  gap: 8px;
}

.menu-check-icon {
  width: 14px;
  height: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-primary);
}

.menu-check-icon svg {
  width: 12px;
  height: 12px;
  fill: currentColor;
}

.menu-row-label {
  white-space: nowrap;
}

.menu-row-shortcut {
  color: var(--text-secondary);
  font-size: 12px;
  margin-left: 28px;
  white-space: nowrap;
}

.menu-separator {
  height: 1px;
  background-color: var(--border-subtle);
  margin: 3px 6px;
  flex-shrink: 0;
}

.menu-submenu-arrow {
  color: var(--text-secondary);
  display: flex;
  align-items: center;
}
.menu-submenu-arrow svg {
  width: 10px;
  height: 10px;
  fill: currentColor;
}

.submenu-container {
  position: relative;
}

.submenu-flyout {
  position: absolute;
  left: 100%;
  top: -4px;
  background-color: var(--bg-flyout);
  border: 1px solid var(--border-control);
  border-radius: 8px;
  box-shadow: var(--shadow-flyout);
  padding: 4px;
  min-width: 200px;
  display: none;
  flex-direction: column;
}

.submenu-container:hover .submenu-flyout {
  display: flex;
}

/* 4. Main Body: Editor & Find/Replace */
.notepad-main-content {
  flex: 1;
  position: relative;
  display: flex;
  background-color: var(--bg-editor);
  overflow: hidden;
}

.editor-view-container {
  width: 100%;
  height: 100%;
  position: relative;
  display: flex;
}

.editor-textarea {
  width: 100%;
  height: 100%;
  background: transparent;
  border: none;
  outline: none;
  resize: none;
  color: var(--text-primary);
  font-family: var(--font-editor);
  font-size: var(--font-size-editor);
  font-weight: var(--font-weight-editor);
  font-style: var(--font-style-editor);
  line-height: 1.45;
  padding: 14px 16px;
  tab-size: 4;
  caret-color: var(--accent-color);
  user-select: text;
  -webkit-user-select: text;
}

.editor-textarea::selection {
  background-color: var(--selection-bg);
  color: var(--selection-text);
}

.editor-textarea.wrap {
  white-space: pre-wrap;
  word-break: break-word;
  overflow-x: hidden;
  overflow-y: auto;
}

.editor-textarea.nowrap {
  white-space: pre;
  overflow-x: auto;
  overflow-y: auto;
}

/* WinUI Custom Scrollbars */
.editor-textarea::-webkit-scrollbar,
.settings-scroll-area::-webkit-scrollbar {
  width: 12px;
  height: 12px;
}
.editor-textarea::-webkit-scrollbar-thumb,
.settings-scroll-area::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.2);
  border: 3px solid transparent;
  background-clip: padding-box;
  border-radius: 6px;
}
.editor-textarea::-webkit-scrollbar-thumb:hover,
.settings-scroll-area::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.35);
  border: 3px solid transparent;
  background-clip: padding-box;
}
.editor-textarea::-webkit-scrollbar-track,
.settings-scroll-area::-webkit-scrollbar-track {
  background: transparent;
}

/* Find & Replace Floating Widget */
.find-replace-flyout {
  position: absolute;
  top: 10px;
  right: 24px;
  background-color: var(--bg-flyout);
  border: 1px solid var(--border-control);
  border-radius: 8px;
  box-shadow: var(--shadow-flyout);
  padding: 8px 10px;
  z-index: 200;
  display: none;
  flex-direction: column;
  gap: 6px;
  min-width: 320px;
  max-width: 460px;
}

.find-replace-flyout.open {
  display: flex;
  animation: flyoutFadeIn 0.12s ease-out;
}

.find-row, .replace-row {
  display: flex;
  align-items: center;
  gap: 6px;
}

.find-input-wrap {
  display: flex;
  align-items: center;
  background-color: var(--bg-window);
  border: 1px solid var(--border-control);
  border-radius: 4px;
  flex: 1;
  padding: 0 8px;
  position: relative;
}

.find-input-wrap:focus-within {
  border-bottom: 2px solid var(--accent-color);
}

.find-input {
  background: transparent;
  border: none;
  outline: none;
  color: var(--text-primary);
  font-family: var(--font-ui);
  font-size: 13px;
  height: 28px;
  width: 100%;
  user-select: text;
  -webkit-user-select: text;
}

.match-count-badge {
  font-size: 12px;
  color: var(--text-secondary);
  white-space: nowrap;
  padding-left: 6px;
}

.find-btn {
  width: 28px;
  height: 28px;
  border-radius: 4px;
  background: transparent;
  border: none;
  color: var(--text-primary);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.find-btn:hover {
  background-color: var(--bg-control-hover);
}

.find-btn.active {
  background-color: var(--bg-control-active);
  color: var(--accent-color);
}

.find-btn svg {
  width: 14px;
  height: 14px;
  fill: currentColor;
}

.text-action-btn {
  padding: 4px 10px;
  border-radius: 4px;
  background-color: var(--bg-control);
  border: 1px solid var(--border-control);
  color: var(--text-primary);
  font-family: var(--font-ui);
  font-size: 12px;
  cursor: pointer;
  white-space: nowrap;
}

.text-action-btn:hover {
  background-color: var(--bg-control-hover);
}

/* 5. Status Bar */
.notepad-statusbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 28px;
  background-color: var(--bg-statusbar);
  border-top: 1px solid var(--border-subtle);
  padding: 0 16px;
  font-size: 12px;
  color: var(--text-secondary);
  z-index: 5;
  flex-shrink: 0;
}

.statusbar-left,
.statusbar-right {
  display: flex;
  align-items: center;
  height: 100%;
}

.statusbar-item {
  display: flex;
  align-items: center;
  height: 100%;
  padding: 0 10px;
  cursor: default;
  transition: background-color 0.1s ease;
}

.statusbar-item.interactive {
  cursor: pointer;
}

.statusbar-item.interactive:hover {
  background-color: var(--bg-control-hover);
  color: var(--text-primary);
}

.statusbar-divider {
  width: 1px;
  height: 14px;
  background-color: var(--border-subtle);
}

/* 6. Settings View */
.notepad-settings-view {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: var(--bg-window);
  z-index: 500;
  display: none;
  flex-direction: column;
}

.notepad-settings-view.open {
  display: flex;
}

.settings-titlebar {
  display: flex;
  align-items: center;
  height: 40px;
  padding: 0 0 0 8px;
  border-bottom: 1px solid var(--border-subtle);
  flex-shrink: 0;
}

.settings-back-btn {
  width: 32px;
  height: 32px;
  border-radius: 4px;
  background: transparent;
  border: none;
  color: var(--text-primary);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  margin-right: 8px;
}

.settings-back-btn:hover {
  background-color: var(--bg-control-hover);
}

.settings-back-btn svg {
  width: 16px;
  height: 16px;
  fill: currentColor;
}

.settings-titlebar-name {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 12px;
  color: var(--text-primary);
  flex: 1;
}

.settings-scroll-area {
  flex: 1;
  overflow-y: auto;
  padding: 24px 40px 60px 40px;
  display: flex;
  justify-content: center;
}

.settings-layout-grid {
  display: grid;
  grid-template-columns: 1fr 280px;
  gap: 40px;
  width: 100%;
  max-width: 1080px;
}

.settings-main-col {
  display: flex;
  flex-direction: column;
}

.settings-page-title {
  font-size: 28px;
  font-weight: 600;
  margin-bottom: 24px;
  color: var(--text-primary);
}

.settings-section-header {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
  margin-top: 24px;
  margin-bottom: 8px;
}

.settings-card {
  background-color: var(--bg-card);
  border: 1px solid var(--border-subtle);
  border-radius: 8px;
  padding: 14px 16px;
  margin-bottom: 4px;
  display: flex;
  flex-direction: column;
  transition: background-color 0.1s ease;
}

.settings-card.expandable .settings-card-header {
  cursor: pointer;
}

.settings-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
}

.card-info-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.card-icon {
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-primary);
}

.card-icon svg {
  width: 18px;
  height: 18px;
  fill: currentColor;
}

.card-text-titles {
  display: flex;
  flex-direction: column;
}

.card-primary-title {
  font-size: 14px;
  font-weight: 400;
  color: var(--text-primary);
}

.card-subtitle {
  font-size: 12px;
  color: var(--text-secondary);
  margin-top: 2px;
}

/* Fluent Dropdown Select */
.fluent-select {
  background-color: var(--bg-control);
  border: 1px solid var(--border-control);
  border-radius: 4px;
  color: var(--text-primary);
  padding: 6px 32px 6px 12px;
  font-family: var(--font-ui);
  font-size: 13px;
  cursor: pointer;
  appearance: none;
  -webkit-appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16'' fill=''%239d9d9d''%3E%3Cpath d=''M3.2 5.2a.75.75 0 0 1 1.06 0L8 8.94l3.74-3.74a.75.75 0 1 1 1.06 1.06l-4.27 4.27a.75.75 0 0 1-1.06 0L3.2 6.26a.75.75 0 0 1 0-1.06z''/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 10px center;
  background-size: 12px;
}

.fluent-select:hover {
  background-color: var(--bg-control-hover);
}

.fluent-select:focus {
  outline: none;
  border-bottom: 2px solid var(--accent-color);
}

/* Fluent Toggle Switch */
.fluent-toggle-wrapper {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
}

.toggle-switch {
  width: 40px;
  height: 20px;
  border-radius: 10px;
  background-color: #333333;
  border: 1px solid #777777;
  position: relative;
  transition: all 0.15s ease;
  display: flex;
  align-items: center;
}

[data-theme="light"] .toggle-switch {
  background-color: #e0e0e0;
  border: 1px solid #999999;
}

.toggle-switch .toggle-knob {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background-color: #cecece;
  margin-left: 3px;
  transition: transform 0.15s ease, background-color 0.15s ease;
}

[data-theme="light"] .toggle-switch .toggle-knob {
  background-color: #555555;
}

.fluent-toggle-wrapper.on .toggle-switch {
  background-color: var(--accent-color);
  border-color: var(--accent-color);
}

.fluent-toggle-wrapper.on .toggle-switch .toggle-knob {
  transform: translateX(18px);
  background-color: #ffffff;
  width: 14px;
  height: 14px;
}

.toggle-label {
  font-size: 13px;
  color: var(--text-primary);
  min-width: 24px;
}

/* Accordion Expandables - Default Closed */
.accordion-toggle-btn {
  background: transparent;
  border: none;
  color: var(--text-secondary);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 4px;
}

.accordion-toggle-btn svg {
  width: 14px;
  height: 14px;
  fill: currentColor;
  transition: transform 0.2s ease;
}

.settings-card.expanded .accordion-toggle-btn svg {
  transform: rotate(180deg);
}

.card-expand-content {
  display: none;
  flex-direction: column;
  padding-top: 16px;
  border-top: 1px solid var(--border-subtle);
  margin-top: 14px;
  gap: 14px;
}

.settings-card.expanded .card-expand-content {
  display: flex;
}

/* Font Setting Rows */
.font-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 8px;
}

.font-row-label {
  font-size: 13px;
  color: var(--text-primary);
}

.font-preview-box {
  background-color: #202020;
  border: 1px solid var(--border-subtle);
  border-radius: 6px;
  padding: 24px 16px;
  text-align: center;
  color: var(--text-primary);
  margin-top: 8px;
  user-select: none;
}

[data-theme="light"] .font-preview-box {
  background-color: #f7f7f7;
}

/* Radio Group */
.fluent-radio-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 4px 8px;
}

.fluent-radio-option {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
  font-size: 13px;
  color: var(--text-primary);
}

.radio-circle {
  width: 18px;
  height: 18px;
  border-radius: 50%;
  border: 1px solid #888888;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: border-color 0.15s ease;
}

.fluent-radio-option.selected .radio-circle {
  border: 2px solid var(--accent-color);
}

.radio-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background-color: var(--accent-color);
  display: none;
}

.fluent-radio-option.selected .radio-dot {
  display: block;
}

/* Settings Right Column: About this App */
.settings-side-col {
  display: flex;
  flex-direction: column;
}

.about-header {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 12px;
}

.about-app-name {
  font-size: 13px;
  color: var(--text-primary);
  margin-bottom: 4px;
}

.about-copyright {
  font-size: 12px;
  color: var(--text-secondary);
  margin-bottom: 16px;
}

.about-links {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 24px;
}

.about-link {
  font-size: 13px;
  color: var(--text-link);
  text-decoration: none;
  cursor: pointer;
}

.about-link:hover {
  text-decoration: underline;
}

.about-buttons {
  display: flex;
  flex-direction: column;
  gap: 10px;
  max-width: 180px;
}

.fluent-btn {
  padding: 7px 16px;
  border-radius: 4px;
  background-color: var(--bg-control);
  border: 1px solid var(--border-control);
  color: var(--text-primary);
  font-family: var(--font-ui);
  font-size: 13px;
  cursor: pointer;
  text-align: center;
  transition: background-color 0.1s ease;
}

.fluent-btn:hover {
  background-color: var(--bg-control-hover);
}

.fluent-btn:active {
  background-color: var(--bg-control-active);
}

.fluent-btn.primary {
  background-color: var(--accent-color);
  border-color: var(--accent-color);
  color: #ffffff;
}

.fluent-btn.primary:hover {
  background-color: var(--accent-hover);
}

/* Modals & Dialogs */
.modal-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(8px);
  z-index: 2000;
  display: none;
  align-items: center;
  justify-content: center;
}

.modal-overlay.open {
  display: flex;
}

.fluent-dialog {
  background-color: var(--bg-dialog);
  border: 1px solid var(--border-control);
  border-radius: 8px;
  box-shadow: var(--shadow-modal);
  width: 90%;
  max-width: 440px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  animation: flyoutFadeIn 0.15s ease-out;
}

.dialog-title {
  font-size: 18px;
  font-weight: 600;
  color: var(--text-primary);
}

.dialog-message {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.5;
}

.dialog-input {
  background-color: var(--bg-window);
  border: 1px solid var(--border-control);
  border-radius: 4px;
  color: var(--text-primary);
  font-family: var(--font-ui);
  font-size: 13px;
  padding: 8px 12px;
  outline: none;
}

.dialog-input:focus {
  border-bottom: 2px solid var(--accent-color);
}

.dialog-buttons {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: 8px;
}
'
        'Rules' = @(
            @{
                'Header' = ':root'
                'SourceOffset' = 0
                'Selectors' = @(
                    ':root'
                )
                'Declarations' = @(
                    @{
                        'Property' = '--bg-window'
                        'Value' = '#1f1f1f'
                    }
                    @{
                        'Property' = '--bg-titlebar'
                        'Value' = '#1f1f1f'
                    }
                    @{
                        'Property' = '--bg-menubar'
                        'Value' = '#1f1f1f'
                    }
                    @{
                        'Property' = '--bg-editor'
                        'Value' = '#282828'
                    }
                    @{
                        'Property' = '--bg-tab-active'
                        'Value' = '#2c2c2c'
                    }
                    @{
                        'Property' = '--bg-tab-hover'
                        'Value' = '#262626'
                    }
                    @{
                        'Property' = '--bg-card'
                        'Value' = '#2d2d2d'
                    }
                    @{
                        'Property' = '--bg-card-hover'
                        'Value' = '#323232'
                    }
                    @{
                        'Property' = '--bg-flyout'
                        'Value' = '#2c2c2c'
                    }
                    @{
                        'Property' = '--bg-flyout-item-hover'
                        'Value' = '#383838'
                    }
                    @{
                        'Property' = '--bg-control'
                        'Value' = '#323232'
                    }
                    @{
                        'Property' = '--bg-control-hover'
                        'Value' = '#3c3c3c'
                    }
                    @{
                        'Property' = '--bg-control-active'
                        'Value' = '#2a2a2a'
                    }
                    @{
                        'Property' = '--bg-statusbar'
                        'Value' = '#1f1f1f'
                    }
                    @{
                        'Property' = '--bg-dialog'
                        'Value' = '#2c2c2c'
                    }
                    @{
                        'Property' = '--text-primary'
                        'Value' = '#ffffff'
                    }
                    @{
                        'Property' = '--text-secondary'
                        'Value' = '#9d9d9d'
                    }
                    @{
                        'Property' = '--text-disabled'
                        'Value' = '#606060'
                    }
                    @{
                        'Property' = '--text-link'
                        'Value' = '#60cdff'
                    }
                    @{
                        'Property' = '--border-subtle'
                        'Value' = 'rgba(255, 255, 255, 0.06)'
                    }
                    @{
                        'Property' = '--border-control'
                        'Value' = 'rgba(255, 255, 255, 0.09)'
                    }
                    @{
                        'Property' = '--border-active'
                        'Value' = '#60cdff'
                    }
                    @{
                        'Property' = '--accent-color'
                        'Value' = '#0090f1'
                    }
                    @{
                        'Property' = '--accent-hover'
                        'Value' = '#1aa0ff'
                    }
                    @{
                        'Property' = '--accent-active'
                        'Value' = '#0078d4'
                    }
                    @{
                        'Property' = '--selection-bg'
                        'Value' = '#005fb8'
                    }
                    @{
                        'Property' = '--selection-text'
                        'Value' = '#ffffff'
                    }
                    @{
                        'Property' = '--font-ui'
                        'Value' = '''Segoe UI Variable Text'', ''Segoe UI'', -apple-system, BlinkMacSystemFont, Roboto, sans-serif'
                    }
                    @{
                        'Property' = '--font-editor'
                        'Value' = '''Consolas'', ''Cascadia Code'', ''Courier New'', monospace'
                    }
                    @{
                        'Property' = '--font-size-editor'
                        'Value' = '11pt'
                    }
                    @{
                        'Property' = '--font-weight-editor'
                        'Value' = '400'
                    }
                    @{
                        'Property' = '--font-style-editor'
                        'Value' = 'normal'
                    }
                    @{
                        'Property' = '--shadow-flyout'
                        'Value' = '0 8px 24px rgba(0, 0, 0, 0.55)'
                    }
                    @{
                        'Property' = '--shadow-modal'
                        'Value' = '0 16px 36px rgba(0, 0, 0, 0.65)'
                    }
                )
            }
            @{
                'Header' = '[data-theme="light"]'
                'SourceOffset' = 1260
                'Selectors' = @(
                    '[data-theme="light"]'
                )
                'Declarations' = @(
                    @{
                        'Property' = '--bg-window'
                        'Value' = '#f3f3f3'
                    }
                    @{
                        'Property' = '--bg-titlebar'
                        'Value' = '#f3f3f3'
                    }
                    @{
                        'Property' = '--bg-menubar'
                        'Value' = '#f3f3f3'
                    }
                    @{
                        'Property' = '--bg-editor'
                        'Value' = '#ffffff'
                    }
                    @{
                        'Property' = '--bg-tab-active'
                        'Value' = '#ffffff'
                    }
                    @{
                        'Property' = '--bg-tab-hover'
                        'Value' = '#eaeaea'
                    }
                    @{
                        'Property' = '--bg-card'
                        'Value' = '#ffffff'
                    }
                    @{
                        'Property' = '--bg-card-hover'
                        'Value' = '#f9f9f9'
                    }
                    @{
                        'Property' = '--bg-flyout'
                        'Value' = '#ffffff'
                    }
                    @{
                        'Property' = '--bg-flyout-item-hover'
                        'Value' = '#f0f0f0'
                    }
                    @{
                        'Property' = '--bg-control'
                        'Value' = '#fbfbfb'
                    }
                    @{
                        'Property' = '--bg-control-hover'
                        'Value' = '#f5f5f5'
                    }
                    @{
                        'Property' = '--bg-control-active'
                        'Value' = '#ebebeb'
                    }
                    @{
                        'Property' = '--bg-statusbar'
                        'Value' = '#f3f3f3'
                    }
                    @{
                        'Property' = '--bg-dialog'
                        'Value' = '#ffffff'
                    }
                    @{
                        'Property' = '--text-primary'
                        'Value' = '#1b1b1b'
                    }
                    @{
                        'Property' = '--text-secondary'
                        'Value' = '#616161'
                    }
                    @{
                        'Property' = '--text-disabled'
                        'Value' = '#a0a0a0'
                    }
                    @{
                        'Property' = '--text-link'
                        'Value' = '#005fb8'
                    }
                    @{
                        'Property' = '--border-subtle'
                        'Value' = 'rgba(0, 0, 0, 0.06)'
                    }
                    @{
                        'Property' = '--border-control'
                        'Value' = 'rgba(0, 0, 0, 0.12)'
                    }
                    @{
                        'Property' = '--border-active'
                        'Value' = '#005fb8'
                    }
                    @{
                        'Property' = '--accent-color'
                        'Value' = '#005fb8'
                    }
                    @{
                        'Property' = '--accent-hover'
                        'Value' = '#106ebe'
                    }
                    @{
                        'Property' = '--accent-active'
                        'Value' = '#004578'
                    }
                    @{
                        'Property' = '--selection-bg'
                        'Value' = '#99c9ff'
                    }
                    @{
                        'Property' = '--selection-text'
                        'Value' = '#000000'
                    }
                    @{
                        'Property' = '--shadow-flyout'
                        'Value' = '0 8px 24px rgba(0, 0, 0, 0.15)'
                    }
                    @{
                        'Property' = '--shadow-modal'
                        'Value' = '0 16px 36px rgba(0, 0, 0, 0.25)'
                    }
                )
            }
            @{
                'Header' = '*'
                'SourceOffset' = 2150
                'Selectors' = @(
                    '*'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'box-sizing'
                        'Value' = 'border-box'
                    }
                    @{
                        'Property' = 'margin'
                        'Value' = '0'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '0'
                    }
                    @{
                        'Property' = 'user-select'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = '-webkit-user-select'
                        'Value' = 'none'
                    }
                )
            }
            @{
                'Header' = 'html, body'
                'SourceOffset' = 2260
                'Selectors' = @(
                    'html'
                    'body'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'overflow'
                        'Value' = 'hidden'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-window)'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'font-family'
                        'Value' = 'var(--font-ui)'
                    }
                    @{
                        'Property' = 'font-size'
                        'Value' = '14px'
                    }
                    @{
                        'Property' = 'line-height'
                        'Value' = '1.4'
                    }
                    @{
                        'Property' = '-webkit-font-smoothing'
                        'Value' = 'antialiased'
                    }
                )
            }
            @{
                'Header' = '.notepad-window'
                'SourceOffset' = 2504
                'Selectors' = @(
                    '.notepad-window'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'flex-direction'
                        'Value' = 'column'
                    }
                    @{
                        'Property' = 'width'
                        'Value' = '100vw'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '100vh'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-window)'
                    }
                    @{
                        'Property' = 'position'
                        'Value' = 'relative'
                    }
                )
            }
            @{
                'Header' = '.notepad-titlebar'
                'SourceOffset' = 2685
                'Selectors' = @(
                    '.notepad-titlebar'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '40px'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-titlebar)'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '0 0 0 10px'
                    }
                    @{
                        'Property' = 'position'
                        'Value' = 'relative'
                    }
                    @{
                        'Property' = 'border-bottom'
                        'Value' = '1px solid var(--border-subtle)'
                    }
                    @{
                        'Property' = 'flex-shrink'
                        'Value' = '0'
                    }
                )
            }
            @{
                'Header' = '.titlebar-left'
                'SourceOffset' = 2948
                'Selectors' = @(
                    '.titlebar-left'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'flex'
                        'Value' = '1'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'overflow'
                        'Value' = 'hidden'
                    }
                )
            }
            @{
                'Header' = '.notepad-app-icon'
                'SourceOffset' = 3055
                'Selectors' = @(
                    '.notepad-app-icon'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '18px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '18px'
                    }
                    @{
                        'Property' = 'margin-right'
                        'Value' = '12px'
                    }
                    @{
                        'Property' = 'flex-shrink'
                        'Value' = '0'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'center'
                    }
                )
            }
            @{
                'Header' = '.notepad-app-icon svg'
                'SourceOffset' = 3216
                'Selectors' = @(
                    '.notepad-app-icon svg'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '100%'
                    }
                )
            }
            @{
                'Header' = '.notepad-tabs-container'
                'SourceOffset' = 3274
                'Selectors' = @(
                    '.notepad-tabs-container'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'flex-end'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'overflow-x'
                        'Value' = 'auto'
                    }
                    @{
                        'Property' = 'overflow-y'
                        'Value' = 'hidden'
                    }
                    @{
                        'Property' = 'scrollbar-width'
                        'Value' = 'none'
                    }
                )
            }
            @{
                'Header' = '.notepad-tabs-container::-webkit-scrollbar'
                'SourceOffset' = 3428
                'Selectors' = @(
                    '.notepad-tabs-container::-webkit-scrollbar'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'none'
                    }
                )
            }
            @{
                'Header' = '.notepad-tab'
                'SourceOffset' = 3492
                'Selectors' = @(
                    '.notepad-tab'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '34px'
                    }
                    @{
                        'Property' = 'min-width'
                        'Value' = '130px'
                    }
                    @{
                        'Property' = 'max-width'
                        'Value' = '220px'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '0 8px 0 12px'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'transparent'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-secondary)'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '7px 7px 0 0'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                    @{
                        'Property' = 'position'
                        'Value' = 'relative'
                    }
                    @{
                        'Property' = 'transition'
                        'Value' = 'background-color 0.1s ease, color 0.1s ease'
                    }
                    @{
                        'Property' = 'font-size'
                        'Value' = '12px'
                    }
                    @{
                        'Property' = 'margin-right'
                        'Value' = '2px'
                    }
                )
            }
            @{
                'Header' = '.notepad-tab:hover'
                'SourceOffset' = 3866
                'Selectors' = @(
                    '.notepad-tab:hover'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-tab-hover)'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                )
            }
            @{
                'Header' = '.notepad-tab.active'
                'SourceOffset' = 3961
                'Selectors' = @(
                    '.notepad-tab.active'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-tab-active)'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'border-top'
                        'Value' = '1px solid var(--border-subtle)'
                    }
                    @{
                        'Property' = 'border-left'
                        'Value' = '1px solid var(--border-subtle)'
                    }
                    @{
                        'Property' = 'border-right'
                        'Value' = '1px solid var(--border-subtle)'
                    }
                    @{
                        'Property' = 'border-bottom'
                        'Value' = '1px solid var(--bg-tab-active)'
                    }
                    @{
                        'Property' = 'z-index'
                        'Value' = '2'
                    }
                )
            }
            @{
                'Header' = '.tab-title'
                'SourceOffset' = 4262
                'Selectors' = @(
                    '.tab-title'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'flex'
                        'Value' = '1'
                    }
                    @{
                        'Property' = 'white-space'
                        'Value' = 'nowrap'
                    }
                    @{
                        'Property' = 'overflow'
                        'Value' = 'hidden'
                    }
                    @{
                        'Property' = 'text-overflow'
                        'Value' = 'ellipsis'
                    }
                    @{
                        'Property' = 'margin-right'
                        'Value' = '6px'
                    }
                )
            }
            @{
                'Header' = '.tab-indicator-container'
                'SourceOffset' = 4380
                'Selectors' = @(
                    '.tab-indicator-container'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '20px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '20px'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'position'
                        'Value' = 'relative'
                    }
                )
            }
            @{
                'Header' = '.tab-dot'
                'SourceOffset' = 4530
                'Selectors' = @(
                    '.tab-dot'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '6px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '6px'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '50%'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--text-secondary)'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'none'
                    }
                )
            }
            @{
                'Header' = '.tab-close-btn'
                'SourceOffset' = 4655
                'Selectors' = @(
                    '.tab-close-btn'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '20px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '20px'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '4px'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'background'
                        'Value' = 'transparent'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-secondary)'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                )
            }
            @{
                'Header' = '.tab-close-btn:hover'
                'SourceOffset' = 4889
                'Selectors' = @(
                    '.tab-close-btn:hover'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-control-hover)'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                )
            }
            @{
                'Header' = '.notepad-tab:hover .tab-close-btn,
.notepad-tab.active .tab-close-btn'
                'SourceOffset' = 4990
                'Selectors' = @(
                    '.notepad-tab:hover .tab-close-btn'
                    '.notepad-tab.active .tab-close-btn'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                )
            }
            @{
                'Header' = '.notepad-tab:hover .tab-dot,
.notepad-tab.active .tab-dot'
                'SourceOffset' = 5082
                'Selectors' = @(
                    '.notepad-tab:hover .tab-dot'
                    '.notepad-tab.active .tab-dot'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'none'
                    }
                )
            }
            @{
                'Header' = '.notepad-tab.unsaved .tab-dot'
                'SourceOffset' = 5161
                'Selectors' = @(
                    '.notepad-tab.unsaved .tab-dot'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'block'
                    }
                )
            }
            @{
                'Header' = '.notepad-tab.unsaved:hover .tab-dot'
                'SourceOffset' = 5213
                'Selectors' = @(
                    '.notepad-tab.unsaved:hover .tab-dot'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'none'
                    }
                )
            }
            @{
                'Header' = '.notepad-tab.unsaved:hover .tab-close-btn'
                'SourceOffset' = 5270
                'Selectors' = @(
                    '.notepad-tab.unsaved:hover .tab-close-btn'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                )
            }
            @{
                'Header' = '.add-tab-btn'
                'SourceOffset' = 5333
                'Selectors' = @(
                    '.add-tab-btn'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '32px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '32px'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '4px'
                    }
                    @{
                        'Property' = 'background'
                        'Value' = 'transparent'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                    @{
                        'Property' = 'margin-left'
                        'Value' = '4px'
                    }
                    @{
                        'Property' = 'margin-bottom'
                        'Value' = '2px'
                    }
                )
            }
            @{
                'Header' = '.add-tab-btn:hover'
                'SourceOffset' = 5605
                'Selectors' = @(
                    '.add-tab-btn:hover'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-control-hover)'
                    }
                )
            }
            @{
                'Header' = '.add-tab-btn svg'
                'SourceOffset' = 5674
                'Selectors' = @(
                    '.add-tab-btn svg'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '14px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '14px'
                    }
                    @{
                        'Property' = 'fill'
                        'Value' = 'currentColor'
                    }
                )
            }
            @{
                'Header' = '.window-controls'
                'SourceOffset' = 5749
                'Selectors' = @(
                    '.window-controls'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '100%'
                    }
                )
            }
            @{
                'Header' = '.win-btn'
                'SourceOffset' = 5826
                'Selectors' = @(
                    '.win-btn'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '46px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'background'
                        'Value' = 'transparent'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                    @{
                        'Property' = 'transition'
                        'Value' = 'background-color 0.1s ease'
                    }
                )
            }
            @{
                'Header' = '.win-btn svg'
                'SourceOffset' = 6072
                'Selectors' = @(
                    '.win-btn svg'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '10px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '10px'
                    }
                    @{
                        'Property' = 'fill'
                        'Value' = 'currentColor'
                    }
                )
            }
            @{
                'Header' = '.win-btn:hover'
                'SourceOffset' = 6143
                'Selectors' = @(
                    '.win-btn:hover'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-control-hover)'
                    }
                )
            }
            @{
                'Header' = '.win-btn.win-close:hover'
                'SourceOffset' = 6208
                'Selectors' = @(
                    '.win-btn.win-close:hover'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = '#c42b1c'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = '#ffffff'
                    }
                )
            }
            @{
                'Header' = '.win-btn:active'
                'SourceOffset' = 6285
                'Selectors' = @(
                    '.win-btn:active'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-control-active)'
                    }
                )
            }
            @{
                'Header' = '.notepad-menubar'
                'SourceOffset' = 6352
                'Selectors' = @(
                    '.notepad-menubar'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'space-between'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '38px'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-menubar)'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '0 8px'
                    }
                    @{
                        'Property' = 'border-bottom'
                        'Value' = '1px solid var(--border-subtle)'
                    }
                    @{
                        'Property' = 'position'
                        'Value' = 'relative'
                    }
                    @{
                        'Property' = 'z-index'
                        'Value' = '100'
                    }
                    @{
                        'Property' = 'flex-shrink'
                        'Value' = '0'
                    }
                )
            }
            @{
                'Header' = '.menubar-left'
                'SourceOffset' = 6644
                'Selectors' = @(
                    '.menubar-left'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                )
            }
            @{
                'Header' = '.menu-item-btn'
                'SourceOffset' = 6703
                'Selectors' = @(
                    '.menu-item-btn'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'padding'
                        'Value' = '5px 10px'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '4px'
                    }
                    @{
                        'Property' = 'background'
                        'Value' = 'transparent'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'font-family'
                        'Value' = 'var(--font-ui)'
                    }
                    @{
                        'Property' = 'font-size'
                        'Value' = '13px'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                    @{
                        'Property' = 'margin-right'
                        'Value' = '2px'
                    }
                    @{
                        'Property' = 'transition'
                        'Value' = 'background-color 0.1s ease'
                    }
                )
            }
            @{
                'Header' = '.menu-item-btn:hover,
.menu-item-btn.open'
                'SourceOffset' = 6971
                'Selectors' = @(
                    '.menu-item-btn:hover'
                    '.menu-item-btn.open'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-control-hover)'
                    }
                )
            }
            @{
                'Header' = '.menubar-right'
                'SourceOffset' = 7063
                'Selectors' = @(
                    '.menubar-right'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'gap'
                        'Value' = '4px'
                    }
                )
            }
            @{
                'Header' = '.menu-action-btn'
                'SourceOffset' = 7135
                'Selectors' = @(
                    '.menu-action-btn'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '32px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '32px'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '4px'
                    }
                    @{
                        'Property' = 'background'
                        'Value' = 'transparent'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                    @{
                        'Property' = 'position'
                        'Value' = 'relative'
                    }
                    @{
                        'Property' = 'transition'
                        'Value' = 'background-color 0.1s ease'
                    }
                )
            }
            @{
                'Header' = '.menu-action-btn:hover'
                'SourceOffset' = 7433
                'Selectors' = @(
                    '.menu-action-btn:hover'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-control-hover)'
                    }
                )
            }
            @{
                'Header' = '.menu-action-btn svg'
                'SourceOffset' = 7506
                'Selectors' = @(
                    '.menu-action-btn svg'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '16px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '16px'
                    }
                    @{
                        'Property' = 'fill'
                        'Value' = 'currentColor'
                    }
                )
            }
            @{
                'Header' = '.notification-badge-dot'
                'SourceOffset' = 7585
                'Selectors' = @(
                    '.notification-badge-dot'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'position'
                        'Value' = 'absolute'
                    }
                    @{
                        'Property' = 'top'
                        'Value' = '6px'
                    }
                    @{
                        'Property' = 'right'
                        'Value' = '6px'
                    }
                    @{
                        'Property' = 'width'
                        'Value' = '6px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '6px'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '50%'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = '#0090f1'
                    }
                )
            }
            @{
                'Header' = '.flyout-menu'
                'SourceOffset' = 7742
                'Selectors' = @(
                    '.flyout-menu'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'position'
                        'Value' = 'absolute'
                    }
                    @{
                        'Property' = 'top'
                        'Value' = '36px'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-flyout)'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = '1px solid var(--border-control)'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '8px'
                    }
                    @{
                        'Property' = 'box-shadow'
                        'Value' = 'var(--shadow-flyout)'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '4px'
                    }
                    @{
                        'Property' = 'min-width'
                        'Value' = '240px'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'flex-direction'
                        'Value' = 'column'
                    }
                    @{
                        'Property' = 'z-index'
                        'Value' = '1000'
                    }
                    @{
                        'Property' = 'backdrop-filter'
                        'Value' = 'blur(20px)'
                    }
                )
            }
            @{
                'Header' = '.flyout-menu.open'
                'SourceOffset' = 8118
                'Selectors' = @(
                    '.flyout-menu.open'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'animation'
                        'Value' = 'flyoutFadeIn 0.1s ease-out'
                    }
                )
            }
            @{
                'Header' = '@keyframes flyoutFadeIn'
                'SourceOffset' = 8199
                'Children' = @(
                    @{
                        'Header' = 'from'
                        'SourceOffset' = 8226
                        'Selectors' = @(
                            'from'
                        )
                        'Declarations' = @(
                            @{
                                'Property' = 'opacity'
                                'Value' = '0'
                            }
                            @{
                                'Property' = 'transform'
                                'Value' = 'translateY(-2px)'
                            }
                        )
                    }
                    @{
                        'Header' = 'to'
                        'SourceOffset' = 8288
                        'Selectors' = @(
                            'to'
                        )
                        'Declarations' = @(
                            @{
                                'Property' = 'opacity'
                                'Value' = '1'
                            }
                            @{
                                'Property' = 'transform'
                                'Value' = 'translateY(0)'
                            }
                        )
                    }
                )
            }
            @{
                'Header' = '.menu-row'
                'SourceOffset' = 8347
                'Selectors' = @(
                    '.menu-row'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'space-between'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '28px'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '0 10px'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '4px'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'font-size'
                        'Value' = '13px'
                    }
                    @{
                        'Property' = 'line-height'
                        'Value' = '28px'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                    @{
                        'Property' = 'position'
                        'Value' = 'relative'
                    }
                    @{
                        'Property' = 'transition'
                        'Value' = 'background-color 0.08s ease'
                    }
                    @{
                        'Property' = 'white-space'
                        'Value' = 'nowrap'
                    }
                    @{
                        'Property' = 'flex-shrink'
                        'Value' = '0'
                    }
                )
            }
            @{
                'Header' = '.menu-row:hover'
                'SourceOffset' = 8688
                'Selectors' = @(
                    '.menu-row:hover'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-flyout-item-hover)'
                    }
                )
            }
            @{
                'Header' = '.menu-row.disabled'
                'SourceOffset' = 8758
                'Selectors' = @(
                    '.menu-row.disabled'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-disabled)'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'default'
                    }
                    @{
                        'Property' = 'pointer-events'
                        'Value' = 'none'
                    }
                )
            }
            @{
                'Header' = '.menu-row-left'
                'SourceOffset' = 8856
                'Selectors' = @(
                    '.menu-row-left'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'gap'
                        'Value' = '8px'
                    }
                )
            }
            @{
                'Header' = '.menu-check-icon'
                'SourceOffset' = 8928
                'Selectors' = @(
                    '.menu-check-icon'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '14px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '14px'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                )
            }
            @{
                'Header' = '.menu-check-icon svg'
                'SourceOffset' = 9078
                'Selectors' = @(
                    '.menu-check-icon svg'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '12px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '12px'
                    }
                    @{
                        'Property' = 'fill'
                        'Value' = 'currentColor'
                    }
                )
            }
            @{
                'Header' = '.menu-row-label'
                'SourceOffset' = 9157
                'Selectors' = @(
                    '.menu-row-label'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'white-space'
                        'Value' = 'nowrap'
                    }
                )
            }
            @{
                'Header' = '.menu-row-shortcut'
                'SourceOffset' = 9201
                'Selectors' = @(
                    '.menu-row-shortcut'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-secondary)'
                    }
                    @{
                        'Property' = 'font-size'
                        'Value' = '12px'
                    }
                    @{
                        'Property' = 'margin-left'
                        'Value' = '28px'
                    }
                    @{
                        'Property' = 'white-space'
                        'Value' = 'nowrap'
                    }
                )
            }
            @{
                'Header' = '.menu-separator'
                'SourceOffset' = 9320
                'Selectors' = @(
                    '.menu-separator'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'height'
                        'Value' = '1px'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--border-subtle)'
                    }
                    @{
                        'Property' = 'margin'
                        'Value' = '3px 6px'
                    }
                    @{
                        'Property' = 'flex-shrink'
                        'Value' = '0'
                    }
                )
            }
            @{
                'Header' = '.menu-submenu-arrow'
                'SourceOffset' = 9435
                'Selectors' = @(
                    '.menu-submenu-arrow'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-secondary)'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                )
            }
            @{
                'Header' = '.menu-submenu-arrow svg'
                'SourceOffset' = 9532
                'Selectors' = @(
                    '.menu-submenu-arrow svg'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '10px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '10px'
                    }
                    @{
                        'Property' = 'fill'
                        'Value' = 'currentColor'
                    }
                )
            }
            @{
                'Header' = '.submenu-container'
                'SourceOffset' = 9613
                'Selectors' = @(
                    '.submenu-container'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'position'
                        'Value' = 'relative'
                    }
                )
            }
            @{
                'Header' = '.submenu-flyout'
                'SourceOffset' = 9659
                'Selectors' = @(
                    '.submenu-flyout'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'position'
                        'Value' = 'absolute'
                    }
                    @{
                        'Property' = 'left'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'top'
                        'Value' = '-4px'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-flyout)'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = '1px solid var(--border-control)'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '8px'
                    }
                    @{
                        'Property' = 'box-shadow'
                        'Value' = 'var(--shadow-flyout)'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '4px'
                    }
                    @{
                        'Property' = 'min-width'
                        'Value' = '200px'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'flex-direction'
                        'Value' = 'column'
                    }
                )
            }
            @{
                'Header' = '.submenu-container:hover .submenu-flyout'
                'SourceOffset' = 9947
                'Selectors' = @(
                    '.submenu-container:hover .submenu-flyout'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                )
            }
            @{
                'Header' = '.notepad-main-content'
                'SourceOffset' = 10010
                'Selectors' = @(
                    '.notepad-main-content'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'flex'
                        'Value' = '1'
                    }
                    @{
                        'Property' = 'position'
                        'Value' = 'relative'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-editor)'
                    }
                    @{
                        'Property' = 'overflow'
                        'Value' = 'hidden'
                    }
                )
            }
            @{
                'Header' = '.editor-view-container'
                'SourceOffset' = 10187
                'Selectors' = @(
                    '.editor-view-container'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'position'
                        'Value' = 'relative'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                )
            }
            @{
                'Header' = '.editor-textarea'
                'SourceOffset' = 10285
                'Selectors' = @(
                    '.editor-textarea'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'background'
                        'Value' = 'transparent'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'outline'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'resize'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'font-family'
                        'Value' = 'var(--font-editor)'
                    }
                    @{
                        'Property' = 'font-size'
                        'Value' = 'var(--font-size-editor)'
                    }
                    @{
                        'Property' = 'font-weight'
                        'Value' = 'var(--font-weight-editor)'
                    }
                    @{
                        'Property' = 'font-style'
                        'Value' = 'var(--font-style-editor)'
                    }
                    @{
                        'Property' = 'line-height'
                        'Value' = '1.45'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '14px 16px'
                    }
                    @{
                        'Property' = 'tab-size'
                        'Value' = '4'
                    }
                    @{
                        'Property' = 'caret-color'
                        'Value' = 'var(--accent-color)'
                    }
                    @{
                        'Property' = 'user-select'
                        'Value' = 'text'
                    }
                    @{
                        'Property' = '-webkit-user-select'
                        'Value' = 'text'
                    }
                )
            }
            @{
                'Header' = '.editor-textarea::selection'
                'SourceOffset' = 10743
                'Selectors' = @(
                    '.editor-textarea::selection'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--selection-bg)'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--selection-text)'
                    }
                )
            }
            @{
                'Header' = '.editor-textarea.wrap'
                'SourceOffset' = 10849
                'Selectors' = @(
                    '.editor-textarea.wrap'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'white-space'
                        'Value' = 'pre-wrap'
                    }
                    @{
                        'Property' = 'word-break'
                        'Value' = 'break-word'
                    }
                    @{
                        'Property' = 'overflow-x'
                        'Value' = 'hidden'
                    }
                    @{
                        'Property' = 'overflow-y'
                        'Value' = 'auto'
                    }
                )
            }
            @{
                'Header' = '.editor-textarea.nowrap'
                'SourceOffset' = 10969
                'Selectors' = @(
                    '.editor-textarea.nowrap'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'white-space'
                        'Value' = 'pre'
                    }
                    @{
                        'Property' = 'overflow-x'
                        'Value' = 'auto'
                    }
                    @{
                        'Property' = 'overflow-y'
                        'Value' = 'auto'
                    }
                )
            }
            @{
                'Header' = '.editor-textarea::-webkit-scrollbar,
.settings-scroll-area::-webkit-scrollbar'
                'SourceOffset' = 11058
                'Selectors' = @(
                    '.editor-textarea::-webkit-scrollbar'
                    '.settings-scroll-area::-webkit-scrollbar'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '12px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '12px'
                    }
                )
            }
            @{
                'Header' = '.editor-textarea::-webkit-scrollbar-thumb,
.settings-scroll-area::-webkit-scrollbar-thumb'
                'SourceOffset' = 11202
                'Selectors' = @(
                    '.editor-textarea::-webkit-scrollbar-thumb'
                    '.settings-scroll-area::-webkit-scrollbar-thumb'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background'
                        'Value' = 'rgba(255, 255, 255, 0.2)'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = '3px solid transparent'
                    }
                    @{
                        'Property' = 'background-clip'
                        'Value' = 'padding-box'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '6px'
                    }
                )
            }
            @{
                'Header' = '.editor-textarea::-webkit-scrollbar-thumb:hover,
.settings-scroll-area::-webkit-scrollbar-thumb:hover'
                'SourceOffset' = 11423
                'Selectors' = @(
                    '.editor-textarea::-webkit-scrollbar-thumb:hover'
                    '.settings-scroll-area::-webkit-scrollbar-thumb:hover'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background'
                        'Value' = 'rgba(255, 255, 255, 0.35)'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = '3px solid transparent'
                    }
                    @{
                        'Property' = 'background-clip'
                        'Value' = 'padding-box'
                    }
                )
            }
            @{
                'Header' = '.editor-textarea::-webkit-scrollbar-track,
.settings-scroll-area::-webkit-scrollbar-track'
                'SourceOffset' = 11635
                'Selectors' = @(
                    '.editor-textarea::-webkit-scrollbar-track'
                    '.settings-scroll-area::-webkit-scrollbar-track'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background'
                        'Value' = 'transparent'
                    }
                )
            }
            @{
                'Header' = '.find-replace-flyout'
                'SourceOffset' = 11756
                'Selectors' = @(
                    '.find-replace-flyout'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'position'
                        'Value' = 'absolute'
                    }
                    @{
                        'Property' = 'top'
                        'Value' = '10px'
                    }
                    @{
                        'Property' = 'right'
                        'Value' = '24px'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-flyout)'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = '1px solid var(--border-control)'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '8px'
                    }
                    @{
                        'Property' = 'box-shadow'
                        'Value' = 'var(--shadow-flyout)'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '8px 10px'
                    }
                    @{
                        'Property' = 'z-index'
                        'Value' = '200'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'flex-direction'
                        'Value' = 'column'
                    }
                    @{
                        'Property' = 'gap'
                        'Value' = '6px'
                    }
                    @{
                        'Property' = 'min-width'
                        'Value' = '320px'
                    }
                    @{
                        'Property' = 'max-width'
                        'Value' = '460px'
                    }
                )
            }
            @{
                'Header' = '.find-replace-flyout.open'
                'SourceOffset' = 12140
                'Selectors' = @(
                    '.find-replace-flyout.open'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'animation'
                        'Value' = 'flyoutFadeIn 0.12s ease-out'
                    }
                )
            }
            @{
                'Header' = '.find-row, .replace-row'
                'SourceOffset' = 12230
                'Selectors' = @(
                    '.find-row'
                    '.replace-row'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'gap'
                        'Value' = '6px'
                    }
                )
            }
            @{
                'Header' = '.find-input-wrap'
                'SourceOffset' = 12311
                'Selectors' = @(
                    '.find-input-wrap'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-window)'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = '1px solid var(--border-control)'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '4px'
                    }
                    @{
                        'Property' = 'flex'
                        'Value' = '1'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '0 8px'
                    }
                    @{
                        'Property' = 'position'
                        'Value' = 'relative'
                    }
                )
            }
            @{
                'Header' = '.find-input-wrap:focus-within'
                'SourceOffset' = 12527
                'Selectors' = @(
                    '.find-input-wrap:focus-within'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'border-bottom'
                        'Value' = '2px solid var(--accent-color)'
                    }
                )
            }
            @{
                'Header' = '.find-input'
                'SourceOffset' = 12610
                'Selectors' = @(
                    '.find-input'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background'
                        'Value' = 'transparent'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'outline'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'font-family'
                        'Value' = 'var(--font-ui)'
                    }
                    @{
                        'Property' = 'font-size'
                        'Value' = '13px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '28px'
                    }
                    @{
                        'Property' = 'width'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'user-select'
                        'Value' = 'text'
                    }
                    @{
                        'Property' = '-webkit-user-select'
                        'Value' = 'text'
                    }
                )
            }
            @{
                'Header' = '.match-count-badge'
                'SourceOffset' = 12848
                'Selectors' = @(
                    '.match-count-badge'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'font-size'
                        'Value' = '12px'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-secondary)'
                    }
                    @{
                        'Property' = 'white-space'
                        'Value' = 'nowrap'
                    }
                    @{
                        'Property' = 'padding-left'
                        'Value' = '6px'
                    }
                )
            }
            @{
                'Header' = '.find-btn'
                'SourceOffset' = 12967
                'Selectors' = @(
                    '.find-btn'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '28px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '28px'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '4px'
                    }
                    @{
                        'Property' = 'background'
                        'Value' = 'transparent'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                )
            }
            @{
                'Header' = '.find-btn:hover'
                'SourceOffset' = 13194
                'Selectors' = @(
                    '.find-btn:hover'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-control-hover)'
                    }
                )
            }
            @{
                'Header' = '.find-btn.active'
                'SourceOffset' = 13260
                'Selectors' = @(
                    '.find-btn.active'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-control-active)'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--accent-color)'
                    }
                )
            }
            @{
                'Header' = '.find-btn svg'
                'SourceOffset' = 13358
                'Selectors' = @(
                    '.find-btn svg'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '14px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '14px'
                    }
                    @{
                        'Property' = 'fill'
                        'Value' = 'currentColor'
                    }
                )
            }
            @{
                'Header' = '.text-action-btn'
                'SourceOffset' = 13430
                'Selectors' = @(
                    '.text-action-btn'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'padding'
                        'Value' = '4px 10px'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '4px'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-control)'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = '1px solid var(--border-control)'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'font-family'
                        'Value' = 'var(--font-ui)'
                    }
                    @{
                        'Property' = 'font-size'
                        'Value' = '12px'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                    @{
                        'Property' = 'white-space'
                        'Value' = 'nowrap'
                    }
                )
            }
            @{
                'Header' = '.text-action-btn:hover'
                'SourceOffset' = 13699
                'Selectors' = @(
                    '.text-action-btn:hover'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-control-hover)'
                    }
                )
            }
            @{
                'Header' = '.notepad-statusbar'
                'SourceOffset' = 13772
                'Selectors' = @(
                    '.notepad-statusbar'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'space-between'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '28px'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-statusbar)'
                    }
                    @{
                        'Property' = 'border-top'
                        'Value' = '1px solid var(--border-subtle)'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '0 16px'
                    }
                    @{
                        'Property' = 'font-size'
                        'Value' = '12px'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-secondary)'
                    }
                    @{
                        'Property' = 'z-index'
                        'Value' = '5'
                    }
                    @{
                        'Property' = 'flex-shrink'
                        'Value' = '0'
                    }
                )
            }
            @{
                'Header' = '.statusbar-left,
.statusbar-right'
                'SourceOffset' = 14095
                'Selectors' = @(
                    '.statusbar-left'
                    '.statusbar-right'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '100%'
                    }
                )
            }
            @{
                'Header' = '.statusbar-item'
                'SourceOffset' = 14190
                'Selectors' = @(
                    '.statusbar-item'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '0 10px'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'default'
                    }
                    @{
                        'Property' = 'transition'
                        'Value' = 'background-color 0.1s ease'
                    }
                )
            }
            @{
                'Header' = '.statusbar-item.interactive'
                'SourceOffset' = 14347
                'Selectors' = @(
                    '.statusbar-item.interactive'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                )
            }
            @{
                'Header' = '.statusbar-item.interactive:hover'
                'SourceOffset' = 14399
                'Selectors' = @(
                    '.statusbar-item.interactive:hover'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-control-hover)'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                )
            }
            @{
                'Header' = '.statusbar-divider'
                'SourceOffset' = 14513
                'Selectors' = @(
                    '.statusbar-divider'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '1px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '14px'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--border-subtle)'
                    }
                )
            }
            @{
                'Header' = '.notepad-settings-view'
                'SourceOffset' = 14609
                'Selectors' = @(
                    '.notepad-settings-view'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'position'
                        'Value' = 'absolute'
                    }
                    @{
                        'Property' = 'top'
                        'Value' = '0'
                    }
                    @{
                        'Property' = 'left'
                        'Value' = '0'
                    }
                    @{
                        'Property' = 'width'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-window)'
                    }
                    @{
                        'Property' = 'z-index'
                        'Value' = '500'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'flex-direction'
                        'Value' = 'column'
                    }
                )
            }
            @{
                'Header' = '.notepad-settings-view.open'
                'SourceOffset' = 14831
                'Selectors' = @(
                    '.notepad-settings-view.open'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                )
            }
            @{
                'Header' = '.settings-titlebar'
                'SourceOffset' = 14881
                'Selectors' = @(
                    '.settings-titlebar'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '40px'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '0 0 0 8px'
                    }
                    @{
                        'Property' = 'border-bottom'
                        'Value' = '1px solid var(--border-subtle)'
                    }
                    @{
                        'Property' = 'flex-shrink'
                        'Value' = '0'
                    }
                )
            }
            @{
                'Header' = '.settings-back-btn'
                'SourceOffset' = 15050
                'Selectors' = @(
                    '.settings-back-btn'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '32px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '32px'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '4px'
                    }
                    @{
                        'Property' = 'background'
                        'Value' = 'transparent'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                    @{
                        'Property' = 'margin-right'
                        'Value' = '8px'
                    }
                )
            }
            @{
                'Header' = '.settings-back-btn:hover'
                'SourceOffset' = 15307
                'Selectors' = @(
                    '.settings-back-btn:hover'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-control-hover)'
                    }
                )
            }
            @{
                'Header' = '.settings-back-btn svg'
                'SourceOffset' = 15382
                'Selectors' = @(
                    '.settings-back-btn svg'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '16px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '16px'
                    }
                    @{
                        'Property' = 'fill'
                        'Value' = 'currentColor'
                    }
                )
            }
            @{
                'Header' = '.settings-titlebar-name'
                'SourceOffset' = 15463
                'Selectors' = @(
                    '.settings-titlebar-name'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'gap'
                        'Value' = '10px'
                    }
                    @{
                        'Property' = 'font-size'
                        'Value' = '12px'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'flex'
                        'Value' = '1'
                    }
                )
            }
            @{
                'Header' = '.settings-scroll-area'
                'SourceOffset' = 15605
                'Selectors' = @(
                    '.settings-scroll-area'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'flex'
                        'Value' = '1'
                    }
                    @{
                        'Property' = 'overflow-y'
                        'Value' = 'auto'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '24px 40px 60px 40px'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'center'
                    }
                )
            }
            @{
                'Header' = '.settings-layout-grid'
                'SourceOffset' = 15739
                'Selectors' = @(
                    '.settings-layout-grid'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'grid'
                    }
                    @{
                        'Property' = 'grid-template-columns'
                        'Value' = '1fr 280px'
                    }
                    @{
                        'Property' = 'gap'
                        'Value' = '40px'
                    }
                    @{
                        'Property' = 'width'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'max-width'
                        'Value' = '1080px'
                    }
                )
            }
            @{
                'Header' = '.settings-main-col'
                'SourceOffset' = 15868
                'Selectors' = @(
                    '.settings-main-col'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'flex-direction'
                        'Value' = 'column'
                    }
                )
            }
            @{
                'Header' = '.settings-page-title'
                'SourceOffset' = 15935
                'Selectors' = @(
                    '.settings-page-title'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'font-size'
                        'Value' = '28px'
                    }
                    @{
                        'Property' = 'font-weight'
                        'Value' = '600'
                    }
                    @{
                        'Property' = 'margin-bottom'
                        'Value' = '24px'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                )
            }
            @{
                'Header' = '.settings-section-header'
                'SourceOffset' = 16053
                'Selectors' = @(
                    '.settings-section-header'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'font-size'
                        'Value' = '14px'
                    }
                    @{
                        'Property' = 'font-weight'
                        'Value' = '600'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'margin-top'
                        'Value' = '24px'
                    }
                    @{
                        'Property' = 'margin-bottom'
                        'Value' = '8px'
                    }
                )
            }
            @{
                'Header' = '.settings-card'
                'SourceOffset' = 16194
                'Selectors' = @(
                    '.settings-card'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-card)'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = '1px solid var(--border-subtle)'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '8px'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '14px 16px'
                    }
                    @{
                        'Property' = 'margin-bottom'
                        'Value' = '4px'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'flex-direction'
                        'Value' = 'column'
                    }
                    @{
                        'Property' = 'transition'
                        'Value' = 'background-color 0.1s ease'
                    }
                )
            }
            @{
                'Header' = '.settings-card.expandable .settings-card-header'
                'SourceOffset' = 16443
                'Selectors' = @(
                    '.settings-card.expandable .settings-card-header'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                )
            }
            @{
                'Header' = '.settings-card-header'
                'SourceOffset' = 16515
                'Selectors' = @(
                    '.settings-card-header'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'space-between'
                    }
                    @{
                        'Property' = 'width'
                        'Value' = '100%'
                    }
                )
            }
            @{
                'Header' = '.card-info-left'
                'SourceOffset' = 16631
                'Selectors' = @(
                    '.card-info-left'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'gap'
                        'Value' = '16px'
                    }
                )
            }
            @{
                'Header' = '.card-icon'
                'SourceOffset' = 16705
                'Selectors' = @(
                    '.card-icon'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '20px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '20px'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                )
            }
            @{
                'Header' = '.card-icon svg'
                'SourceOffset' = 16849
                'Selectors' = @(
                    '.card-icon svg'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '18px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '18px'
                    }
                    @{
                        'Property' = 'fill'
                        'Value' = 'currentColor'
                    }
                )
            }
            @{
                'Header' = '.card-text-titles'
                'SourceOffset' = 16922
                'Selectors' = @(
                    '.card-text-titles'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'flex-direction'
                        'Value' = 'column'
                    }
                )
            }
            @{
                'Header' = '.card-primary-title'
                'SourceOffset' = 16988
                'Selectors' = @(
                    '.card-primary-title'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'font-size'
                        'Value' = '14px'
                    }
                    @{
                        'Property' = 'font-weight'
                        'Value' = '400'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                )
            }
            @{
                'Header' = '.card-subtitle'
                'SourceOffset' = 17082
                'Selectors' = @(
                    '.card-subtitle'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'font-size'
                        'Value' = '12px'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-secondary)'
                    }
                    @{
                        'Property' = 'margin-top'
                        'Value' = '2px'
                    }
                )
            }
            @{
                'Header' = '.fluent-select'
                'SourceOffset' = 17172
                'Selectors' = @(
                    '.fluent-select'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-control)'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = '1px solid var(--border-control)'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '4px'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '6px 32px 6px 12px'
                    }
                    @{
                        'Property' = 'font-family'
                        'Value' = 'var(--font-ui)'
                    }
                    @{
                        'Property' = 'font-size'
                        'Value' = '13px'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                    @{
                        'Property' = 'appearance'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = '-webkit-appearance'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'background-image'
                        'Value' = 'url("data:image/svg+xml,%3Csvg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 16 16'' fill=''%239d9d9d''%3E%3Cpath d=''M3.2 5.2a.75.75 0 0 1 1.06 0L8 8.94l3.74-3.74a.75.75 0 1 1 1.06 1.06l-4.27 4.27a.75.75 0 0 1-1.06 0L3.2 6.26a.75.75 0 0 1 0-1.06z''/%3E%3C/svg%3E")'
                    }
                    @{
                        'Property' = 'background-repeat'
                        'Value' = 'no-repeat'
                    }
                    @{
                        'Property' = 'background-position'
                        'Value' = 'right 10px center'
                    }
                    @{
                        'Property' = 'background-size'
                        'Value' = '12px'
                    }
                )
            }
            @{
                'Header' = '.fluent-select:hover'
                'SourceOffset' = 17885
                'Selectors' = @(
                    '.fluent-select:hover'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-control-hover)'
                    }
                )
            }
            @{
                'Header' = '.fluent-select:focus'
                'SourceOffset' = 17956
                'Selectors' = @(
                    '.fluent-select:focus'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'outline'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'border-bottom'
                        'Value' = '2px solid var(--accent-color)'
                    }
                )
            }
            @{
                'Header' = '.fluent-toggle-wrapper'
                'SourceOffset' = 18047
                'Selectors' = @(
                    '.fluent-toggle-wrapper'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'gap'
                        'Value' = '10px'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                )
            }
            @{
                'Header' = '.toggle-switch'
                'SourceOffset' = 18174
                'Selectors' = @(
                    '.toggle-switch'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '40px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '20px'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '10px'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = '#333333'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = '1px solid #777777'
                    }
                    @{
                        'Property' = 'position'
                        'Value' = 'relative'
                    }
                    @{
                        'Property' = 'transition'
                        'Value' = 'all 0.15s ease'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                )
            }
            @{
                'Header' = '[data-theme="light"] .toggle-switch'
                'SourceOffset' = 18398
                'Selectors' = @(
                    '[data-theme="light"] .toggle-switch'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = '#e0e0e0'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = '1px solid #999999'
                    }
                )
            }
            @{
                'Header' = '.toggle-switch .toggle-knob'
                'SourceOffset' = 18497
                'Selectors' = @(
                    '.toggle-switch .toggle-knob'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '12px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '12px'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '50%'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = '#cecece'
                    }
                    @{
                        'Property' = 'margin-left'
                        'Value' = '3px'
                    }
                    @{
                        'Property' = 'transition'
                        'Value' = 'transform 0.15s ease, background-color 0.15s ease'
                    }
                )
            }
            @{
                'Header' = '[data-theme="light"] .toggle-switch .toggle-knob'
                'SourceOffset' = 18697
                'Selectors' = @(
                    '[data-theme="light"] .toggle-switch .toggle-knob'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = '#555555'
                    }
                )
            }
            @{
                'Header' = '.fluent-toggle-wrapper.on .toggle-switch'
                'SourceOffset' = 18780
                'Selectors' = @(
                    '.fluent-toggle-wrapper.on .toggle-switch'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--accent-color)'
                    }
                    @{
                        'Property' = 'border-color'
                        'Value' = 'var(--accent-color)'
                    }
                )
            }
            @{
                'Header' = '.fluent-toggle-wrapper.on .toggle-switch .toggle-knob'
                'SourceOffset' = 18904
                'Selectors' = @(
                    '.fluent-toggle-wrapper.on .toggle-switch .toggle-knob'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'transform'
                        'Value' = 'translateX(18px)'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = '#ffffff'
                    }
                    @{
                        'Property' = 'width'
                        'Value' = '14px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '14px'
                    }
                )
            }
            @{
                'Header' = '.toggle-label'
                'SourceOffset' = 19054
                'Selectors' = @(
                    '.toggle-label'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'font-size'
                        'Value' = '13px'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'min-width'
                        'Value' = '24px'
                    }
                )
            }
            @{
                'Header' = '.accordion-toggle-btn'
                'SourceOffset' = 19141
                'Selectors' = @(
                    '.accordion-toggle-btn'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background'
                        'Value' = 'transparent'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-secondary)'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '4px'
                    }
                )
            }
            @{
                'Header' = '.accordion-toggle-btn svg'
                'SourceOffset' = 19390
                'Selectors' = @(
                    '.accordion-toggle-btn svg'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '14px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '14px'
                    }
                    @{
                        'Property' = 'fill'
                        'Value' = 'currentColor'
                    }
                    @{
                        'Property' = 'transition'
                        'Value' = 'transform 0.2s ease'
                    }
                )
            }
            @{
                'Header' = '.settings-card.expanded .accordion-toggle-btn svg'
                'SourceOffset' = 19509
                'Selectors' = @(
                    '.settings-card.expanded .accordion-toggle-btn svg'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'transform'
                        'Value' = 'rotate(180deg)'
                    }
                )
            }
            @{
                'Header' = '.card-expand-content'
                'SourceOffset' = 19593
                'Selectors' = @(
                    '.card-expand-content'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'flex-direction'
                        'Value' = 'column'
                    }
                    @{
                        'Property' = 'padding-top'
                        'Value' = '16px'
                    }
                    @{
                        'Property' = 'border-top'
                        'Value' = '1px solid var(--border-subtle)'
                    }
                    @{
                        'Property' = 'margin-top'
                        'Value' = '14px'
                    }
                    @{
                        'Property' = 'gap'
                        'Value' = '14px'
                    }
                )
            }
            @{
                'Header' = '.settings-card.expanded .card-expand-content'
                'SourceOffset' = 19762
                'Selectors' = @(
                    '.settings-card.expanded .card-expand-content'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                )
            }
            @{
                'Header' = '.font-row'
                'SourceOffset' = 19829
                'Selectors' = @(
                    '.font-row'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'space-between'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '0 8px'
                    }
                )
            }
            @{
                'Header' = '.font-row-label'
                'SourceOffset' = 19960
                'Selectors' = @(
                    '.font-row-label'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'font-size'
                        'Value' = '13px'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                )
            }
            @{
                'Header' = '.font-preview-box'
                'SourceOffset' = 20030
                'Selectors' = @(
                    '.font-preview-box'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = '#202020'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = '1px solid var(--border-subtle)'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '6px'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '24px 16px'
                    }
                    @{
                        'Property' = 'text-align'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'margin-top'
                        'Value' = '8px'
                    }
                    @{
                        'Property' = 'user-select'
                        'Value' = 'none'
                    }
                )
            }
            @{
                'Header' = '[data-theme="light"] .font-preview-box'
                'SourceOffset' = 20260
                'Selectors' = @(
                    '[data-theme="light"] .font-preview-box'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = '#f7f7f7'
                    }
                )
            }
            @{
                'Header' = '.fluent-radio-group'
                'SourceOffset' = 20333
                'Selectors' = @(
                    '.fluent-radio-group'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'flex-direction'
                        'Value' = 'column'
                    }
                    @{
                        'Property' = 'gap'
                        'Value' = '12px'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '4px 8px'
                    }
                )
            }
            @{
                'Header' = '.fluent-radio-option'
                'SourceOffset' = 20452
                'Selectors' = @(
                    '.fluent-radio-option'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'gap'
                        'Value' = '12px'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                    @{
                        'Property' = 'font-size'
                        'Value' = '13px'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                )
            }
            @{
                'Header' = '.radio-circle'
                'SourceOffset' = 20599
                'Selectors' = @(
                    '.radio-circle'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '18px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '18px'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '50%'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = '1px solid #888888'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'transition'
                        'Value' = 'border-color 0.15s ease'
                    }
                )
            }
            @{
                'Header' = '.fluent-radio-option.selected .radio-circle'
                'SourceOffset' = 20806
                'Selectors' = @(
                    '.fluent-radio-option.selected .radio-circle'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'border'
                        'Value' = '2px solid var(--accent-color)'
                    }
                )
            }
            @{
                'Header' = '.radio-dot'
                'SourceOffset' = 20896
                'Selectors' = @(
                    '.radio-dot'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'width'
                        'Value' = '10px'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '10px'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '50%'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--accent-color)'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'none'
                    }
                )
            }
            @{
                'Header' = '.fluent-radio-option.selected .radio-dot'
                'SourceOffset' = 21023
                'Selectors' = @(
                    '.fluent-radio-option.selected .radio-dot'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'block'
                    }
                )
            }
            @{
                'Header' = '.settings-side-col'
                'SourceOffset' = 21087
                'Selectors' = @(
                    '.settings-side-col'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'flex-direction'
                        'Value' = 'column'
                    }
                )
            }
            @{
                'Header' = '.about-header'
                'SourceOffset' = 21198
                'Selectors' = @(
                    '.about-header'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'font-size'
                        'Value' = '14px'
                    }
                    @{
                        'Property' = 'font-weight'
                        'Value' = '600'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'margin-bottom'
                        'Value' = '12px'
                    }
                )
            }
            @{
                'Header' = '.about-app-name'
                'SourceOffset' = 21309
                'Selectors' = @(
                    '.about-app-name'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'font-size'
                        'Value' = '13px'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'margin-bottom'
                        'Value' = '4px'
                    }
                )
            }
            @{
                'Header' = '.about-copyright'
                'SourceOffset' = 21401
                'Selectors' = @(
                    '.about-copyright'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'font-size'
                        'Value' = '12px'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-secondary)'
                    }
                    @{
                        'Property' = 'margin-bottom'
                        'Value' = '16px'
                    }
                )
            }
            @{
                'Header' = '.about-links'
                'SourceOffset' = 21497
                'Selectors' = @(
                    '.about-links'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'flex-direction'
                        'Value' = 'column'
                    }
                    @{
                        'Property' = 'gap'
                        'Value' = '8px'
                    }
                    @{
                        'Property' = 'margin-bottom'
                        'Value' = '24px'
                    }
                )
            }
            @{
                'Header' = '.about-link'
                'SourceOffset' = 21593
                'Selectors' = @(
                    '.about-link'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'font-size'
                        'Value' = '13px'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-link)'
                    }
                    @{
                        'Property' = 'text-decoration'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                )
            }
            @{
                'Header' = '.about-link:hover'
                'SourceOffset' = 21700
                'Selectors' = @(
                    '.about-link:hover'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'text-decoration'
                        'Value' = 'underline'
                    }
                )
            }
            @{
                'Header' = '.about-buttons'
                'SourceOffset' = 21753
                'Selectors' = @(
                    '.about-buttons'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'flex-direction'
                        'Value' = 'column'
                    }
                    @{
                        'Property' = 'gap'
                        'Value' = '10px'
                    }
                    @{
                        'Property' = 'max-width'
                        'Value' = '180px'
                    }
                )
            }
            @{
                'Header' = '.fluent-btn'
                'SourceOffset' = 21849
                'Selectors' = @(
                    '.fluent-btn'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'padding'
                        'Value' = '7px 16px'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '4px'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-control)'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = '1px solid var(--border-control)'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'font-family'
                        'Value' = 'var(--font-ui)'
                    }
                    @{
                        'Property' = 'font-size'
                        'Value' = '13px'
                    }
                    @{
                        'Property' = 'cursor'
                        'Value' = 'pointer'
                    }
                    @{
                        'Property' = 'text-align'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'transition'
                        'Value' = 'background-color 0.1s ease'
                    }
                )
            }
            @{
                'Header' = '.fluent-btn:hover'
                'SourceOffset' = 22154
                'Selectors' = @(
                    '.fluent-btn:hover'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-control-hover)'
                    }
                )
            }
            @{
                'Header' = '.fluent-btn:active'
                'SourceOffset' = 22222
                'Selectors' = @(
                    '.fluent-btn:active'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-control-active)'
                    }
                )
            }
            @{
                'Header' = '.fluent-btn.primary'
                'SourceOffset' = 22292
                'Selectors' = @(
                    '.fluent-btn.primary'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--accent-color)'
                    }
                    @{
                        'Property' = 'border-color'
                        'Value' = 'var(--accent-color)'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = '#ffffff'
                    }
                )
            }
            @{
                'Header' = '.fluent-btn.primary:hover'
                'SourceOffset' = 22413
                'Selectors' = @(
                    '.fluent-btn.primary:hover'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--accent-hover)'
                    }
                )
            }
            @{
                'Header' = '.modal-overlay'
                'SourceOffset' = 22485
                'Selectors' = @(
                    '.modal-overlay'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'position'
                        'Value' = 'absolute'
                    }
                    @{
                        'Property' = 'top'
                        'Value' = '0'
                    }
                    @{
                        'Property' = 'left'
                        'Value' = '0'
                    }
                    @{
                        'Property' = 'width'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'height'
                        'Value' = '100%'
                    }
                    @{
                        'Property' = 'background-color'
                        'Value' = 'rgba(0, 0, 0, 0.5)'
                    }
                    @{
                        'Property' = 'backdrop-filter'
                        'Value' = 'blur(8px)'
                    }
                    @{
                        'Property' = 'z-index'
                        'Value' = '2000'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'none'
                    }
                    @{
                        'Property' = 'align-items'
                        'Value' = 'center'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'center'
                    }
                )
            }
            @{
                'Header' = '.modal-overlay.open'
                'SourceOffset' = 22756
                'Selectors' = @(
                    '.modal-overlay.open'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                )
            }
            @{
                'Header' = '.fluent-dialog'
                'SourceOffset' = 22798
                'Selectors' = @(
                    '.fluent-dialog'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-dialog)'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = '1px solid var(--border-control)'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '8px'
                    }
                    @{
                        'Property' = 'box-shadow'
                        'Value' = 'var(--shadow-modal)'
                    }
                    @{
                        'Property' = 'width'
                        'Value' = '90%'
                    }
                    @{
                        'Property' = 'max-width'
                        'Value' = '440px'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '24px'
                    }
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'flex-direction'
                        'Value' = 'column'
                    }
                    @{
                        'Property' = 'gap'
                        'Value' = '16px'
                    }
                    @{
                        'Property' = 'animation'
                        'Value' = 'flyoutFadeIn 0.15s ease-out'
                    }
                )
            }
            @{
                'Header' = '.dialog-title'
                'SourceOffset' = 23105
                'Selectors' = @(
                    '.dialog-title'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'font-size'
                        'Value' = '18px'
                    }
                    @{
                        'Property' = 'font-weight'
                        'Value' = '600'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                )
            }
            @{
                'Header' = '.dialog-message'
                'SourceOffset' = 23193
                'Selectors' = @(
                    '.dialog-message'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'font-size'
                        'Value' = '13px'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-secondary)'
                    }
                    @{
                        'Property' = 'line-height'
                        'Value' = '1.5'
                    }
                )
            }
            @{
                'Header' = '.dialog-input'
                'SourceOffset' = 23285
                'Selectors' = @(
                    '.dialog-input'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'background-color'
                        'Value' = 'var(--bg-window)'
                    }
                    @{
                        'Property' = 'border'
                        'Value' = '1px solid var(--border-control)'
                    }
                    @{
                        'Property' = 'border-radius'
                        'Value' = '4px'
                    }
                    @{
                        'Property' = 'color'
                        'Value' = 'var(--text-primary)'
                    }
                    @{
                        'Property' = 'font-family'
                        'Value' = 'var(--font-ui)'
                    }
                    @{
                        'Property' = 'font-size'
                        'Value' = '13px'
                    }
                    @{
                        'Property' = 'padding'
                        'Value' = '8px 12px'
                    }
                    @{
                        'Property' = 'outline'
                        'Value' = 'none'
                    }
                )
            }
            @{
                'Header' = '.dialog-input:focus'
                'SourceOffset' = 23525
                'Selectors' = @(
                    '.dialog-input:focus'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'border-bottom'
                        'Value' = '2px solid var(--accent-color)'
                    }
                )
            }
            @{
                'Header' = '.dialog-buttons'
                'SourceOffset' = 23598
                'Selectors' = @(
                    '.dialog-buttons'
                )
                'Declarations' = @(
                    @{
                        'Property' = 'display'
                        'Value' = 'flex'
                    }
                    @{
                        'Property' = 'justify-content'
                        'Value' = 'flex-end'
                    }
                    @{
                        'Property' = 'gap'
                        'Value' = '8px'
                    }
                    @{
                        'Property' = 'margin-top'
                        'Value' = '8px'
                    }
                )
            }
        )
    }
    'Icons' = @{
        'app' = '<svg viewBox="0 0 24 24"><path fill="#0078d4" d="M4 2.5C4 1.67 4.67 1 5.5 1h13c.83 0 1.5.67 1.5 1.5v19c0 .83-.67 1.5-1.5 1.5h-13c-.83 0-1.5-.67-1.5-1.5v-19z"/><path fill="#60cdff" d="M7 6h10v2H7zm0 4h10v2H7zm0 4h6v2H7z"/><path fill="#ffffff" opacity="0.8" d="M7 18h10v1.5H7z"/></svg>'
        'minimize' = '<svg viewBox="0 0 10 10"><path d="M0 5h10v1H0z"/></svg>'
        'maximize' = '<svg viewBox="0 0 10 10"><path d="M1 1h8v8H1V1zm1 1v6h6V2H2z"/></svg>'
        'restore' = '<svg viewBox="0 0 10 10"><path d="M3 1h6v6H8V2H3V1zm-2 2h6v6H1V3zm1 1v4h4V4H2z"/></svg>'
        'close' = '<svg viewBox="0 0 10 10"><path d="M1.4 0.7L5 4.3 8.6 0.7 9.3 1.4 5.7 5 9.3 8.6 8.6 9.3 5 5.7 1.4 9.3 0.7 8.6 4.3 5 0.7 1.4z"/></svg>'
        'plus' = '<svg viewBox="0 0 16 16"><path d="M8 2a.75.75 0 0 1 .75.75v4.5h4.5a.75.75 0 0 1 0 1.5h-4.5v4.5a.75.75 0 0 1-1.5 0v-4.5h-4.5a.75.75 0 0 1 0-1.5h4.5v-4.5A.75.75 0 0 1 8 2z"/></svg>'
        'back' = '<svg viewBox="0 0 16 16"><path d="M13.5 7.25H4.86l3.97-3.97a.75.75 0 0 0-1.06-1.06l-5.25 5.25a.75.75 0 0 0 0 1.06l5.25 5.25a.75.75 0 1 0 1.06-1.06L4.86 8.75H13.5a.75.75 0 0 0 0-1.5z"/></svg>'
        'gear' = '<svg viewBox="0 0 16 16"><path d="M7.07 1a1 1 0 0 0-.98.8l-.27 1.34a5.03 5.03 0 0 0-1.28.53l-1.23-.62a1 1 0 0 0-1.24.31L1.13 5.01a1 1 0 0 0 .15 1.27l1.04.88c-.04.28-.07.56-.07.84s.03.56.07.84l-1.04.88a1 1 0 0 0-.15 1.27l1.24 1.65a1 1 0 0 0 1.24.31l1.23-.62c.4.23.83.41 1.28.53l.27 1.34a1 1 0 0 0 .98.8h2.06a1 1 0 0 0 .98-.8l.27-1.34c.45-.12.88-.3 1.28-.53l1.23.62a1 1 0 0 0 1.24-.31l1.24-1.65a1 1 0 0 0-.15-1.27l-1.04-.88c.04-.28.07-.56.07-.84s-.03-.56-.07-.84l1.04-.88a1 1 0 0 0 .15-1.27L13.87 3.36a1 1 0 0 0-1.24-.31l-1.23.62a5.03 5.03 0 0 0-1.28-.53l-.27-1.34a1 1 0 0 0-.98-.8H7.07zM8 5.5a2.5 2.5 0 1 1 0 5 2.5 2.5 0 0 1 0-5z"/></svg>'
        'megaphone' = '<svg viewBox="0 0 16 16"><path d="M13 2.5a.75.75 0 0 0-1.06-.68L4.62 5.08A2.75 2.75 0 0 0 2 7.75v.5c0 1.2.78 2.22 1.88 2.58l-.63 2.2a.75.75 0 0 0 .95.93l2.87-.96.48-.16a.75.75 0 0 0 .47-.45l.63-1.89h3.29l.06.01a.75.75 0 0 0 .8-.66l.2-1.39A2.99 2.99 0 0 0 15 5.5v-.5a2.5 2.5 0 0 0-2-2.5zm1 3c0 .83-.67 1.5-1.5 1.5h-.5V4h.5c.83 0 1.5.67 1.5 1.5z"/></svg>'
        'check' = '<svg viewBox="0 0 16 16"><path d="M13.78 4.22a.75.75 0 0 1 0 1.06l-7.25 7.25a.75.75 0 0 1-1.06 0L2.22 9.28a.75.75 0 0 1 1.06-1.06L6 10.94l6.72-6.72a.75.75 0 0 1 1.06 0z"/></svg>'
        'chevronDown' = '<svg viewBox="0 0 16 16"><path d="M3.2 5.2a.75.75 0 0 1 1.06 0L8 8.94l3.74-3.74a.75.75 0 1 1 1.06 1.06l-4.27 4.27a.75.75 0 0 1-1.06 0L3.2 6.26a.75.75 0 0 1 0-1.06z"/></svg>'
        'chevronRight' = '<svg viewBox="0 0 16 16"><path d="M5.2 3.2a.75.75 0 0 1 1.06 0l4.27 4.27a.75.75 0 0 1 0 1.06l-4.27 4.27a.75.75 0 0 1-1.06-1.06L8.94 8 5.2 4.26a.75.75 0 0 1 0-1.06z"/></svg>'
        'theme' = '<svg viewBox="0 0 16 16"><path d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zm0 1.5a5.5 5.5 0 1 1 0 11 5.5 5.5 0 0 1 0-11zm-.75 2v4c0 .2.08.39.22.53l2.5 2.5 1.06-1.06-2.28-2.28V4.5H7.25z"/></svg>'
        'font' = '<svg viewBox="0 0 16 16"><path d="M3.5 13h1.8l1.1-3h3.2l1.1 3h1.8L8.8 2.5H7.2L3.5 13zm3.4-4.5l1.1-3.2 1.1 3.2H6.9z"/></svg>'
        'wordWrap' = '<svg viewBox="0 0 16 16"><path d="M2 3.5h12v1.5H2V3.5zm0 4h9a2.5 2.5 0 1 1 0 5H8.5v-1.5H11a1 1 0 1 0 0-2H2V7.5zm0 4h4.5V13H2v-1.5z"/><path d="M8 10.5l-2.5 2L8 14.5v-4z"/></svg>'
        'formatting' = '<svg viewBox="0 0 16 16"><path d="M12.8 1.2a1 1 0 0 0-1.4 0L7.5 5.1 10.9 8.5l3.9-3.9a1 1 0 0 0 0-1.4l-2-2zM6.8 5.8L2.2 10.4c-.2.2-.3.5-.3.8v2.3c0 .3.2.5.5.5h2.3c.3 0 .6-.1.8-.3l4.6-4.6-3.2-3.3z"/></svg>'
        'openFiles' = '<svg viewBox="0 0 16 16"><path d="M3 2a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V9.5h-1.5V12a.5.5 0 0 1-.5.5H3a.5.5 0 0 1-.5-.5V4a.5.5 0 0 1 .5-.5h2.5V2H3zm7 0v1.5h2.44L6.72 9.22l1.06 1.06L13.5 4.56V7H15V2h-5z"/></svg>'
        'tabsApp' = '<svg viewBox="0 0 16 16"><path d="M2 3a1 1 0 0 0-1 1v8a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1H2zm0 1.5h12v1H2v-1zm0 2.5h12v6H2V7z"/></svg>'
        'recentFiles' = '<svg viewBox="0 0 16 16"><path d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zm0 1.5a5.5 5.5 0 1 1 0 11 5.5 5.5 0 0 1 0-11zm-.75 2v4c0 .2.08.39.22.53l2.5 2.5 1.06-1.06-2.28-2.28V4.5H7.25z"/></svg>'
        'spellCheck' = '<svg viewBox="0 0 16 16"><path d="M2.5 9h1.1l.6-1.8h2l.6 1.8h1.1L5.6 2.5H4.3L2.5 9zm2-2.7l.7-2.1.7 2.1h-1.4zm6.2 2.7h1.6c1.1 0 1.8-.7 1.8-1.7 0-.6-.3-1.1-.9-1.3.4-.2.7-.6.7-1.2 0-.9-.7-1.6-1.7-1.6h-1.5V9zm1-5.6h.6c.4 0 .7.3.7.7s-.3.7-.7.7h-.6V3.4zm0 2.3h.7c.5 0 .8.3.8.8s-.3.8-.8.8h-.7V5.7zM10.8 11.2l-2.6 2.6-1.1-1.1-.7.7 1.8 1.8 3.3-3.3-.7-.7z"/></svg>'
        'search' = '<svg viewBox="0 0 16 16"><path d="M11.74 10.68a6 6 0 1 0-1.06 1.06l3.47 3.47a.75.75 0 0 0 1.06-1.06l-3.47-3.47zM11 6.5a4.5 4.5 0 1 1-9 0 4.5 4.5 0 0 1 9 0z"/></svg>'
        'arrowUp' = '<svg viewBox="0 0 16 16"><path d="M8 3.2l4.27 4.27a.75.75 0 0 1-1.06 1.06L8 5.31 4.79 8.53a.75.75 0 1 1-1.06-1.06L8 3.2z"/></svg>'
        'arrowDown' = '<svg viewBox="0 0 16 16"><path d="M8 12.8L3.73 8.53a.75.75 0 0 1 1.06-1.06L8 10.69l3.21-3.22a.75.75 0 1 1 1.06 1.06L8 12.8z"/></svg>'
        'caseSensitive' = '<svg viewBox="0 0 16 16"><path d="M3.2 11.5h1.3l.8-2.2h2.4l.8 2.2h1.3L6.8 3.5H5.2L3.2 11.5zm2.5-3.3l.8-2.3.8 2.3H5.7zm6.8 3.3h1.2v-4.5c0-.9-.6-1.5-1.5-1.5s-1.5.6-1.5 1.5v4.5h1.2v-1.1c.2.4.6.6 1 .6.7 0 1.1-.4 1.1-1.1v-2.4h-1.5v2.4c0 .3.2.5.5.5s.5-.2.5-.5V8.5h-1.2V7c0-.3.2-.5.5-.5s.5.2.5.5v4.5z"/></svg>'
        'wrapAround' = '<svg viewBox="0 0 16 16"><path d="M2.5 8.5a5.5 5.5 0 1 0 1.6-3.9H2V3h4v4H4.5V5.5a4 4 0 1 1-1.2 2.8H2v.2z"/></svg>'
    }
    'Document' = @{
        'Language' = 'en'
        'Title' = 'Notepad'
        'InitialTheme' = 'dark'
        'FaviconHref' = 'data:image/svg+xml,%3Csvg xmlns=''http://www.w3.org/2000/svg'' viewBox=''0 0 24 24''%3E%3Cpath fill=''%230078d4'' d=''M4 2.5C4 1.67 4.67 1 5.5 1h13c.83 0 1.5.67 1.5 1.5v19c0 .83-.67 1.5-1.5 1.5h-13c-.83 0-1.5-.67-1.5-1.5v-19z''/%3E%3Cpath fill=''%2360cdff'' d=''M7 6h10v2H7zm0 4h10v2H7zm0 4h6v2H7z''/%3E%3C/svg%3E'
    }
    'View' = @{
        'Root' = @{
            'Tag' = 'div'
            'Attributes' = @{
                'id' = 'notepad-root'
                'class' = 'notepad-window'
            }
            'Children' = @(
                @{
                    'Tag' = 'header'
                    'Attributes' = @{
                        'class' = 'notepad-titlebar'
                    }
                    'Children' = @(
                        @{
                            'Tag' = 'div'
                            'Attributes' = @{
                                'class' = 'titlebar-left'
                            }
                            'Children' = @(
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'notepad-app-icon'
                                        'title' = 'Notepad'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'svg-ref'
                                            'Attributes' = @{
                                                'name' = 'app'
                                            }
                                            'Children' = @()
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'notepad-tabs-container'
                                        'id' = 'tabs-container'
                                    }
                                    'Children' = @()
                                }
                                @{
                                    'Tag' = 'button'
                                    'Attributes' = @{
                                        'class' = 'add-tab-btn'
                                        'id' = 'btn-add-tab'
                                        'title' = 'New tab (Ctrl+N)'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'svg-ref'
                                            'Attributes' = @{
                                                'name' = 'plus'
                                            }
                                            'Children' = @()
                                        }
                                    )
                                }
                            )
                        }
                        @{
                            'Tag' = 'div'
                            'Attributes' = @{
                                'class' = 'window-controls'
                            }
                            'Children' = @(
                                @{
                                    'Tag' = 'button'
                                    'Attributes' = @{
                                        'class' = 'win-btn win-minimize'
                                        'id' = 'btn-win-min'
                                        'title' = 'Minimize'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'svg-ref'
                                            'Attributes' = @{
                                                'name' = 'minimize'
                                            }
                                            'Children' = @()
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'button'
                                    'Attributes' = @{
                                        'class' = 'win-btn win-maximize'
                                        'id' = 'btn-win-max'
                                        'title' = 'Maximize'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'svg-ref'
                                            'Attributes' = @{
                                                'name' = 'maximize'
                                            }
                                            'Children' = @()
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'button'
                                    'Attributes' = @{
                                        'class' = 'win-btn win-close'
                                        'id' = 'btn-win-close'
                                        'title' = 'Close'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'svg-ref'
                                            'Attributes' = @{
                                                'name' = 'close'
                                            }
                                            'Children' = @()
                                        }
                                    )
                                }
                            )
                        }
                    )
                }
                @{
                    'Tag' = 'nav'
                    'Attributes' = @{
                        'class' = 'notepad-menubar'
                    }
                    'Children' = @(
                        @{
                            'Tag' = 'div'
                            'Attributes' = @{
                                'class' = 'menubar-left'
                            }
                            'Children' = @(
                                @{
                                    'Tag' = 'button'
                                    'Attributes' = @{
                                        'class' = 'menu-item-btn'
                                        'id' = 'menu-btn-file'
                                    }
                                    'Children' = @(
                                        @{
                                            'Text' = 'File'
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'button'
                                    'Attributes' = @{
                                        'class' = 'menu-item-btn'
                                        'id' = 'menu-btn-edit'
                                    }
                                    'Children' = @(
                                        @{
                                            'Text' = 'Edit'
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'button'
                                    'Attributes' = @{
                                        'class' = 'menu-item-btn'
                                        'id' = 'menu-btn-view'
                                    }
                                    'Children' = @(
                                        @{
                                            'Text' = 'View'
                                        }
                                    )
                                }
                            )
                        }
                        @{
                            'Tag' = 'div'
                            'Attributes' = @{
                                'class' = 'menubar-right'
                            }
                            'Children' = @(
                                @{
                                    'Tag' = 'button'
                                    'Attributes' = @{
                                        'class' = 'menu-action-btn'
                                        'id' = 'btn-whats-new'
                                        'title' = 'What''s new'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'svg-ref'
                                            'Attributes' = @{
                                                'name' = 'megaphone'
                                            }
                                            'Children' = @()
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'notification-badge-dot'
                                            }
                                            'Children' = @()
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'button'
                                    'Attributes' = @{
                                        'class' = 'menu-action-btn'
                                        'id' = 'btn-settings-toggle'
                                        'title' = 'Settings'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'svg-ref'
                                            'Attributes' = @{
                                                'name' = 'gear'
                                            }
                                            'Children' = @()
                                        }
                                    )
                                }
                            )
                        }
                        @{
                            'Tag' = 'div'
                            'Attributes' = @{
                                'class' = 'flyout-menu'
                                'id' = 'flyout-file'
                            }
                            'Children' = @(
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'newTab'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'New tab'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Ctrl+N'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'newWindow'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'New window'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Ctrl+Shift+N'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'newMarkdownTab'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'New Markdown tab'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'openFile'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Open'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Ctrl+O'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row submenu-container'
                                        'id' = 'menu-recent-container'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Recent'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-submenu-arrow'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'svg-ref'
                                                    'Attributes' = @{
                                                        'name' = 'chevronRight'
                                                    }
                                                    'Children' = @()
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'div'
                                            'Attributes' = @{
                                                'class' = 'submenu-flyout'
                                                'id' = 'flyout-recent-items'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'menu-row disabled'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Tag' = 'span'
                                                            'Attributes' = @{
                                                                'class' = 'menu-row-label'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Text' = 'No recent files'
                                                                }
                                                            )
                                                        }
                                                    )
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'save'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Save'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Ctrl+S'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'saveAs'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Save as'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Ctrl+Shift+S'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'saveAll'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Save all'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Ctrl+Alt+S'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-separator'
                                    }
                                    'Children' = @()
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'pageSetup'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Page setup'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'print'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Print'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Ctrl+P'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-separator'
                                    }
                                    'Children' = @()
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'closeTab'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Close tab'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Ctrl+W'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'closeWindow'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Close window'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Ctrl+Shift+W'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'exit'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Exit'
                                                }
                                            )
                                        }
                                    )
                                }
                            )
                        }
                        @{
                            'Tag' = 'div'
                            'Attributes' = @{
                                'class' = 'flyout-menu'
                                'id' = 'flyout-edit'
                            }
                            'Children' = @(
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'undo'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Undo'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Ctrl+Z'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-separator'
                                    }
                                    'Children' = @()
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'cut'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Cut'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Ctrl+X'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'copy'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Copy'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Ctrl+C'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'paste'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Paste'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Ctrl+V'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'delete'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Delete'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Del'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-separator'
                                    }
                                    'Children' = @()
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'clearFormatting'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Clear formatting'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'find'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Find'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Ctrl+F'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'findNext'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Find next'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'F3'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'findPrevious'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Find previous'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Shift+F3'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'replace'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Replace'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Ctrl+H'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'goTo'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Go to'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Ctrl+G'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-separator'
                                    }
                                    'Children' = @()
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'selectAll'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Select all'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Ctrl+A'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'timeDate'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Time/Date'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-shortcut'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'F5'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-separator'
                                    }
                                    'Children' = @()
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'openFontSettings'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Font'
                                                }
                                            )
                                        }
                                    )
                                }
                            )
                        }
                        @{
                            'Tag' = 'div'
                            'Attributes' = @{
                                'class' = 'flyout-menu'
                                'id' = 'flyout-view'
                            }
                            'Children' = @(
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row submenu-container'
                                        'id' = 'menu-zoom-container'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Zoom'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-submenu-arrow'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'svg-ref'
                                                    'Attributes' = @{
                                                        'name' = 'chevronRight'
                                                    }
                                                    'Children' = @()
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'div'
                                            'Attributes' = @{
                                                'class' = 'submenu-flyout'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'menu-row'
                                                        'data-action' = 'zoomIn'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Tag' = 'span'
                                                            'Attributes' = @{
                                                                'class' = 'menu-row-label'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Text' = 'Zoom in'
                                                                }
                                                            )
                                                        }
                                                        @{
                                                            'Tag' = 'span'
                                                            'Attributes' = @{
                                                                'class' = 'menu-row-shortcut'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Text' = 'Ctrl+Plus'
                                                                }
                                                            )
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'menu-row'
                                                        'data-action' = 'zoomOut'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Tag' = 'span'
                                                            'Attributes' = @{
                                                                'class' = 'menu-row-label'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Text' = 'Zoom out'
                                                                }
                                                            )
                                                        }
                                                        @{
                                                            'Tag' = 'span'
                                                            'Attributes' = @{
                                                                'class' = 'menu-row-shortcut'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Text' = 'Ctrl+Minus'
                                                                }
                                                            )
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'menu-row'
                                                        'data-action' = 'zoomReset'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Tag' = 'span'
                                                            'Attributes' = @{
                                                                'class' = 'menu-row-label'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Text' = 'Restore default zoom'
                                                                }
                                                            )
                                                        }
                                                        @{
                                                            'Tag' = 'span'
                                                            'Attributes' = @{
                                                                'class' = 'menu-row-shortcut'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Text' = 'Ctrl+0'
                                                                }
                                                            )
                                                        }
                                                    )
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'toggleStatusBar'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'div'
                                            'Attributes' = @{
                                                'class' = 'menu-row-left'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'span'
                                                    'Attributes' = @{
                                                        'class' = 'menu-check-icon'
                                                        'id' = 'check-status-bar'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Tag' = 'svg-ref'
                                                            'Attributes' = @{
                                                                'name' = 'check'
                                                            }
                                                            'Children' = @()
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'span'
                                                    'Attributes' = @{
                                                        'class' = 'menu-row-label'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Text' = 'Status bar'
                                                        }
                                                    )
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row'
                                        'data-action' = 'toggleWordWrap'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'div'
                                            'Attributes' = @{
                                                'class' = 'menu-row-left'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'span'
                                                    'Attributes' = @{
                                                        'class' = 'menu-check-icon'
                                                        'id' = 'check-word-wrap'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Tag' = 'svg-ref'
                                                            'Attributes' = @{
                                                                'name' = 'check'
                                                            }
                                                            'Children' = @()
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'span'
                                                    'Attributes' = @{
                                                        'class' = 'menu-row-label'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Text' = 'Word wrap'
                                                        }
                                                    )
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'menu-row submenu-container'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-row-label'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Markdown'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{
                                                'class' = 'menu-submenu-arrow'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'svg-ref'
                                                    'Attributes' = @{
                                                        'name' = 'chevronRight'
                                                    }
                                                    'Children' = @()
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'div'
                                            'Attributes' = @{
                                                'class' = 'submenu-flyout'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'menu-row'
                                                        'data-action' = 'toggleMarkdownPreview'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Tag' = 'span'
                                                            'Attributes' = @{
                                                                'class' = 'menu-row-label'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Text' = 'Preview Markdown'
                                                                }
                                                            )
                                                        }
                                                    )
                                                }
                                            )
                                        }
                                    )
                                }
                            )
                        }
                    )
                }
                @{
                    'Tag' = 'main'
                    'Attributes' = @{
                        'class' = 'notepad-main-content'
                    }
                    'Children' = @(
                        @{
                            'Tag' = 'div'
                            'Attributes' = @{
                                'class' = 'editor-view-container'
                            }
                            'Children' = @(
                                @{
                                    'Tag' = 'textarea'
                                    'Attributes' = @{
                                        'class' = 'editor-textarea {{binding:0}}'
                                        'id' = 'editor-area'
                                        'spellcheck' = '{{binding:1}}'
                                        'autocapitalize' = 'off'
                                        'autocomplete' = 'off'
                                        'autocorrect' = 'off'
                                    }
                                    'Children' = @()
                                }
                            )
                        }
                        @{
                            'Tag' = 'div'
                            'Attributes' = @{
                                'class' = 'find-replace-flyout'
                                'id' = 'find-replace-panel'
                            }
                            'Children' = @(
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'find-row'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'div'
                                            'Attributes' = @{
                                                'class' = 'find-input-wrap'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'input'
                                                    'Attributes' = @{
                                                        'type' = 'text'
                                                        'class' = 'find-input'
                                                        'id' = 'find-query-input'
                                                        'placeholder' = 'Find'
                                                    }
                                                    'Children' = @()
                                                }
                                                @{
                                                    'Tag' = 'span'
                                                    'Attributes' = @{
                                                        'class' = 'match-count-badge'
                                                        'id' = 'find-match-counter'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Text' = '0 of 0'
                                                        }
                                                    )
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'button'
                                            'Attributes' = @{
                                                'class' = 'find-btn'
                                                'id' = 'find-btn-prev'
                                                'title' = 'Previous match (Shift+F3)'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'svg-ref'
                                                    'Attributes' = @{
                                                        'name' = 'arrowUp'
                                                    }
                                                    'Children' = @()
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'button'
                                            'Attributes' = @{
                                                'class' = 'find-btn'
                                                'id' = 'find-btn-next'
                                                'title' = 'Next match (F3)'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'svg-ref'
                                                    'Attributes' = @{
                                                        'name' = 'arrowDown'
                                                    }
                                                    'Children' = @()
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'button'
                                            'Attributes' = @{
                                                'class' = 'find-btn'
                                                'id' = 'find-btn-case'
                                                'title' = 'Match case'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'svg-ref'
                                                    'Attributes' = @{
                                                        'name' = 'caseSensitive'
                                                    }
                                                    'Children' = @()
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'button'
                                            'Attributes' = @{
                                                'class' = 'find-btn active'
                                                'id' = 'find-btn-wrap'
                                                'title' = 'Wrap around'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'svg-ref'
                                                    'Attributes' = @{
                                                        'name' = 'wrapAround'
                                                    }
                                                    'Children' = @()
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'button'
                                            'Attributes' = @{
                                                'class' = 'find-btn'
                                                'id' = 'find-btn-toggle-replace'
                                                'title' = 'Toggle replace'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'svg-ref'
                                                    'Attributes' = @{
                                                        'name' = 'chevronDown'
                                                    }
                                                    'Children' = @()
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'button'
                                            'Attributes' = @{
                                                'class' = 'find-btn'
                                                'id' = 'find-btn-close'
                                                'title' = 'Close'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'svg-ref'
                                                    'Attributes' = @{
                                                        'name' = 'close'
                                                    }
                                                    'Children' = @()
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'replace-row'
                                        'id' = 'replace-row-container'
                                        'style' = 'display: none;'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'div'
                                            'Attributes' = @{
                                                'class' = 'find-input-wrap'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'input'
                                                    'Attributes' = @{
                                                        'type' = 'text'
                                                        'class' = 'find-input'
                                                        'id' = 'replace-query-input'
                                                        'placeholder' = 'Replace with'
                                                    }
                                                    'Children' = @()
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'button'
                                            'Attributes' = @{
                                                'class' = 'text-action-btn'
                                                'id' = 'btn-do-replace'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Replace'
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'button'
                                            'Attributes' = @{
                                                'class' = 'text-action-btn'
                                                'id' = 'btn-do-replace-all'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Replace all'
                                                }
                                            )
                                        }
                                    )
                                }
                            )
                        }
                    )
                }
                @{
                    'Tag' = 'footer'
                    'Attributes' = @{
                        'class' = 'notepad-statusbar'
                        'id' = 'notepad-statusbar'
                    }
                    'Children' = @(
                        @{
                            'Tag' = 'div'
                            'Attributes' = @{
                                'class' = 'statusbar-left'
                            }
                            'Children' = @(
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'statusbar-item'
                                        'id' = 'sb-cursor-pos'
                                    }
                                    'Children' = @(
                                        @{
                                            'Text' = 'Ln 1, Col 1'
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'statusbar-divider'
                                    }
                                    'Children' = @()
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'statusbar-item'
                                        'id' = 'sb-char-count'
                                    }
                                    'Children' = @(
                                        @{
                                            'Text' = '0 characters'
                                        }
                                    )
                                }
                            )
                        }
                        @{
                            'Tag' = 'div'
                            'Attributes' = @{
                                'class' = 'statusbar-right'
                            }
                            'Children' = @(
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'statusbar-item interactive'
                                        'id' = 'sb-doc-type'
                                    }
                                    'Children' = @(
                                        @{
                                            'Text' = 'Plain text'
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'statusbar-divider'
                                    }
                                    'Children' = @()
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'statusbar-item interactive'
                                        'id' = 'sb-zoom-level'
                                    }
                                    'Children' = @(
                                        @{
                                            'Text' = '100%'
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'statusbar-divider'
                                    }
                                    'Children' = @()
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'statusbar-item interactive'
                                        'id' = 'sb-line-ending'
                                    }
                                    'Children' = @(
                                        @{
                                            'Text' = 'Unix (LF)'
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'statusbar-divider'
                                    }
                                    'Children' = @()
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'statusbar-item interactive'
                                        'id' = 'sb-encoding'
                                    }
                                    'Children' = @(
                                        @{
                                            'Text' = 'UTF-8'
                                        }
                                    )
                                }
                            )
                        }
                    )
                }
                @{
                    'Tag' = 'div'
                    'Attributes' = @{
                        'class' = 'notepad-settings-view'
                        'id' = 'settings-view'
                    }
                    'Children' = @(
                        @{
                            'Tag' = 'header'
                            'Attributes' = @{
                                'class' = 'settings-titlebar'
                            }
                            'Children' = @(
                                @{
                                    'Tag' = 'button'
                                    'Attributes' = @{
                                        'class' = 'settings-back-btn'
                                        'id' = 'settings-btn-back'
                                        'title' = 'Back'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'svg-ref'
                                            'Attributes' = @{
                                                'name' = 'back'
                                            }
                                            'Children' = @()
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'settings-titlebar-name'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'div'
                                            'Attributes' = @{
                                                'class' = 'notepad-app-icon'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'svg-ref'
                                                    'Attributes' = @{
                                                        'name' = 'app'
                                                    }
                                                    'Children' = @()
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'span'
                                            'Attributes' = @{

                                            }
                                            'Children' = @(
                                                @{
                                                    'Text' = 'Notepad'
                                                }
                                            )
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'window-controls'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'button'
                                            'Attributes' = @{
                                                'class' = 'win-btn win-minimize'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'svg-ref'
                                                    'Attributes' = @{
                                                        'name' = 'minimize'
                                                    }
                                                    'Children' = @()
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'button'
                                            'Attributes' = @{
                                                'class' = 'win-btn win-maximize'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'svg-ref'
                                                    'Attributes' = @{
                                                        'name' = 'maximize'
                                                    }
                                                    'Children' = @()
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'button'
                                            'Attributes' = @{
                                                'class' = 'win-btn win-close'
                                                'id' = 'settings-win-close'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'svg-ref'
                                                    'Attributes' = @{
                                                        'name' = 'close'
                                                    }
                                                    'Children' = @()
                                                }
                                            )
                                        }
                                    )
                                }
                            )
                        }
                        @{
                            'Tag' = 'div'
                            'Attributes' = @{
                                'class' = 'settings-scroll-area'
                            }
                            'Children' = @(
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'settings-layout-grid'
                                    }
                                    'Children' = @(
                                        @{
                                            'Tag' = 'div'
                                            'Attributes' = @{
                                                'class' = 'settings-main-col'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'h1'
                                                    'Attributes' = @{
                                                        'class' = 'settings-page-title'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Text' = 'Settings'
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'settings-section-header'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Text' = 'Appearance'
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'settings-card'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Tag' = 'div'
                                                            'Attributes' = @{
                                                                'class' = 'settings-card-header'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Tag' = 'div'
                                                                    'Attributes' = @{
                                                                        'class' = 'card-info-left'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'card-icon'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'svg-ref'
                                                                                    'Attributes' = @{
                                                                                        'name' = 'theme'
                                                                                    }
                                                                                    'Children' = @()
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'card-text-titles'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'div'
                                                                                    'Attributes' = @{
                                                                                        'class' = 'card-primary-title'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'App theme'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'div'
                                                                                    'Attributes' = @{
                                                                                        'class' = 'card-subtitle'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Select which app theme to display'
                                                                                        }
                                                                                    )
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                                @{
                                                                    'Tag' = 'select'
                                                                    'Attributes' = @{
                                                                        'class' = 'fluent-select'
                                                                        'id' = 'setting-theme-select'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'option'
                                                                            'Attributes' = @{
                                                                                'value' = 'dark'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Text' = 'Dark'
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'option'
                                                                            'Attributes' = @{
                                                                                'value' = 'light'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Text' = 'Light'
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'option'
                                                                            'Attributes' = @{
                                                                                'value' = 'system'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Text' = 'Use system setting'
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                            )
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'settings-section-header'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Text' = 'Text Formatting'
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'settings-card expandable'
                                                        'id' = 'card-font-setting'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Tag' = 'div'
                                                            'Attributes' = @{
                                                                'class' = 'settings-card-header'
                                                                'id' = 'header-font-setting'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Tag' = 'div'
                                                                    'Attributes' = @{
                                                                        'class' = 'card-info-left'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'card-icon'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'svg-ref'
                                                                                    'Attributes' = @{
                                                                                        'name' = 'font'
                                                                                    }
                                                                                    'Children' = @()
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'card-text-titles'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'div'
                                                                                    'Attributes' = @{
                                                                                        'class' = 'card-primary-title'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Font'
                                                                                        }
                                                                                    )
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                                @{
                                                                    'Tag' = 'button'
                                                                    'Attributes' = @{
                                                                        'class' = 'accordion-toggle-btn'
                                                                        'id' = 'btn-font-accordion'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'svg-ref'
                                                                            'Attributes' = @{
                                                                                'name' = 'chevronDown'
                                                                            }
                                                                            'Children' = @()
                                                                        }
                                                                    )
                                                                }
                                                            )
                                                        }
                                                        @{
                                                            'Tag' = 'div'
                                                            'Attributes' = @{
                                                                'class' = 'card-expand-content'
                                                                'id' = 'font-expand-content'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Tag' = 'div'
                                                                    'Attributes' = @{
                                                                        'class' = 'font-row'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'span'
                                                                            'Attributes' = @{
                                                                                'class' = 'font-row-label'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Text' = 'Family'
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'select'
                                                                            'Attributes' = @{
                                                                                'class' = 'fluent-select'
                                                                                'id' = 'setting-font-family'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = 'Consolas'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Consolas'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = 'Cascadia Code'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Cascadia Code'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = 'Segoe UI'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Segoe UI'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = 'Courier New'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Courier New'
                                                                                        }
                                                                                    )
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                                @{
                                                                    'Tag' = 'div'
                                                                    'Attributes' = @{
                                                                        'class' = 'font-row'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'span'
                                                                            'Attributes' = @{
                                                                                'class' = 'font-row-label'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Text' = 'Style'
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'select'
                                                                            'Attributes' = @{
                                                                                'class' = 'fluent-select'
                                                                                'id' = 'setting-font-style'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = 'Regular'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Regular'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = 'Bold'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Bold'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = 'Italic'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Italic'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = 'Bold Italic'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Bold Italic'
                                                                                        }
                                                                                    )
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                                @{
                                                                    'Tag' = 'div'
                                                                    'Attributes' = @{
                                                                        'class' = 'font-row'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'span'
                                                                            'Attributes' = @{
                                                                                'class' = 'font-row-label'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Text' = 'Size'
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'select'
                                                                            'Attributes' = @{
                                                                                'class' = 'fluent-select'
                                                                                'id' = 'setting-font-size'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = '8'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = '8'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = '9'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = '9'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = '10'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = '10'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = '11'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = '11'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = '12'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = '12'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = '14'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = '14'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = '16'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = '16'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = '18'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = '18'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = '20'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = '20'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = '24'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = '24'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = '28'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = '28'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'option'
                                                                                    'Attributes' = @{
                                                                                        'value' = '36'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = '36'
                                                                                        }
                                                                                    )
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                                @{
                                                                    'Tag' = 'div'
                                                                    'Attributes' = @{
                                                                        'class' = 'font-preview-box'
                                                                        'id' = 'font-sample-preview'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Text' = 'The sound of ocean waves calms my soul.'
                                                                        }
                                                                    )
                                                                }
                                                            )
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'settings-card'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Tag' = 'div'
                                                            'Attributes' = @{
                                                                'class' = 'settings-card-header'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Tag' = 'div'
                                                                    'Attributes' = @{
                                                                        'class' = 'card-info-left'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'card-icon'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'svg-ref'
                                                                                    'Attributes' = @{
                                                                                        'name' = 'wordWrap'
                                                                                    }
                                                                                    'Children' = @()
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'card-text-titles'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'div'
                                                                                    'Attributes' = @{
                                                                                        'class' = 'card-primary-title'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Word wrap'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'div'
                                                                                    'Attributes' = @{
                                                                                        'class' = 'card-subtitle'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Fit text within window by default'
                                                                                        }
                                                                                    )
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                                @{
                                                                    'Tag' = 'div'
                                                                    'Attributes' = @{
                                                                        'class' = 'fluent-toggle-wrapper {{binding:2}}'
                                                                        'id' = 'toggle-setting-wordwrap'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'toggle-switch'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'div'
                                                                                    'Attributes' = @{
                                                                                        'class' = 'toggle-knob'
                                                                                    }
                                                                                    'Children' = @()
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'span'
                                                                            'Attributes' = @{
                                                                                'class' = 'toggle-label'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Text' = '{{binding:3}}'
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                            )
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'settings-card'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Tag' = 'div'
                                                            'Attributes' = @{
                                                                'class' = 'settings-card-header'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Tag' = 'div'
                                                                    'Attributes' = @{
                                                                        'class' = 'card-info-left'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'card-icon'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'svg-ref'
                                                                                    'Attributes' = @{
                                                                                        'name' = 'formatting'
                                                                                    }
                                                                                    'Children' = @()
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'card-text-titles'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'div'
                                                                                    'Attributes' = @{
                                                                                        'class' = 'card-primary-title'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Formatting'
                                                                                        }
                                                                                    )
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                                @{
                                                                    'Tag' = 'div'
                                                                    'Attributes' = @{
                                                                        'class' = 'fluent-toggle-wrapper {{binding:4}}'
                                                                        'id' = 'toggle-setting-formatting'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'toggle-switch'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'div'
                                                                                    'Attributes' = @{
                                                                                        'class' = 'toggle-knob'
                                                                                    }
                                                                                    'Children' = @()
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'span'
                                                                            'Attributes' = @{
                                                                                'class' = 'toggle-label'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Text' = '{{binding:5}}'
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                            )
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'settings-section-header'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Text' = 'Opening Notepad'
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'settings-card'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Tag' = 'div'
                                                            'Attributes' = @{
                                                                'class' = 'settings-card-header'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Tag' = 'div'
                                                                    'Attributes' = @{
                                                                        'class' = 'card-info-left'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'card-icon'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'svg-ref'
                                                                                    'Attributes' = @{
                                                                                        'name' = 'openFiles'
                                                                                    }
                                                                                    'Children' = @()
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'card-text-titles'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'div'
                                                                                    'Attributes' = @{
                                                                                        'class' = 'card-primary-title'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Opening files'
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'div'
                                                                                    'Attributes' = @{
                                                                                        'class' = 'card-subtitle'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Choose where your files are opened'
                                                                                        }
                                                                                    )
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                                @{
                                                                    'Tag' = 'select'
                                                                    'Attributes' = @{
                                                                        'class' = 'fluent-select'
                                                                        'id' = 'setting-opening-files'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'option'
                                                                            'Attributes' = @{
                                                                                'value' = 'newTab'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Text' = 'Open in a new tab'
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'option'
                                                                            'Attributes' = @{
                                                                                'value' = 'newWindow'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Text' = 'Open in a new window'
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                            )
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'settings-card expandable'
                                                        'id' = 'card-startup-setting'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Tag' = 'div'
                                                            'Attributes' = @{
                                                                'class' = 'settings-card-header'
                                                                'id' = 'header-startup-setting'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Tag' = 'div'
                                                                    'Attributes' = @{
                                                                        'class' = 'card-info-left'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'card-icon'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'svg-ref'
                                                                                    'Attributes' = @{
                                                                                        'name' = 'tabsApp'
                                                                                    }
                                                                                    'Children' = @()
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'card-text-titles'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'div'
                                                                                    'Attributes' = @{
                                                                                        'class' = 'card-primary-title'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'When Notepad starts'
                                                                                        }
                                                                                    )
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                                @{
                                                                    'Tag' = 'button'
                                                                    'Attributes' = @{
                                                                        'class' = 'accordion-toggle-btn'
                                                                        'id' = 'btn-startup-accordion'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'svg-ref'
                                                                            'Attributes' = @{
                                                                                'name' = 'chevronDown'
                                                                            }
                                                                            'Children' = @()
                                                                        }
                                                                    )
                                                                }
                                                            )
                                                        }
                                                        @{
                                                            'Tag' = 'div'
                                                            'Attributes' = @{
                                                                'class' = 'card-expand-content'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Tag' = 'div'
                                                                    'Attributes' = @{
                                                                        'class' = 'fluent-radio-group'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'fluent-radio-option {{binding:6}}'
                                                                                'data-value' = 'continueSession'
                                                                                'id' = 'radio-startup-continue'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'div'
                                                                                    'Attributes' = @{
                                                                                        'class' = 'radio-circle'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Tag' = 'div'
                                                                                            'Attributes' = @{
                                                                                                'class' = 'radio-dot'
                                                                                            }
                                                                                            'Children' = @()
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'span'
                                                                                    'Attributes' = @{

                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Continue previous session'
                                                                                        }
                                                                                    )
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'fluent-radio-option {{binding:7}}'
                                                                                'data-value' = 'newSession'
                                                                                'id' = 'radio-startup-new'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'div'
                                                                                    'Attributes' = @{
                                                                                        'class' = 'radio-circle'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Tag' = 'div'
                                                                                            'Attributes' = @{
                                                                                                'class' = 'radio-dot'
                                                                                            }
                                                                                            'Children' = @()
                                                                                        }
                                                                                    )
                                                                                }
                                                                                @{
                                                                                    'Tag' = 'span'
                                                                                    'Attributes' = @{

                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Start new session and discard unsaved changes'
                                                                                        }
                                                                                    )
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                            )
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'settings-card'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Tag' = 'div'
                                                            'Attributes' = @{
                                                                'class' = 'settings-card-header'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Tag' = 'div'
                                                                    'Attributes' = @{
                                                                        'class' = 'card-info-left'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'card-icon'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'svg-ref'
                                                                                    'Attributes' = @{
                                                                                        'name' = 'recentFiles'
                                                                                    }
                                                                                    'Children' = @()
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'card-text-titles'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'div'
                                                                                    'Attributes' = @{
                                                                                        'class' = 'card-primary-title'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Recent Files'
                                                                                        }
                                                                                    )
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                                @{
                                                                    'Tag' = 'div'
                                                                    'Attributes' = @{
                                                                        'class' = 'fluent-toggle-wrapper {{binding:8}}'
                                                                        'id' = 'toggle-setting-recent-files'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'toggle-switch'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'div'
                                                                                    'Attributes' = @{
                                                                                        'class' = 'toggle-knob'
                                                                                    }
                                                                                    'Children' = @()
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'span'
                                                                            'Attributes' = @{
                                                                                'class' = 'toggle-label'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Text' = '{{binding:9}}'
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                            )
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'settings-section-header'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Text' = 'Spelling'
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'settings-card'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Tag' = 'div'
                                                            'Attributes' = @{
                                                                'class' = 'settings-card-header'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Tag' = 'div'
                                                                    'Attributes' = @{
                                                                        'class' = 'card-info-left'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'card-icon'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'svg-ref'
                                                                                    'Attributes' = @{
                                                                                        'name' = 'spellCheck'
                                                                                    }
                                                                                    'Children' = @()
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'card-text-titles'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'div'
                                                                                    'Attributes' = @{
                                                                                        'class' = 'card-primary-title'
                                                                                    }
                                                                                    'Children' = @(
                                                                                        @{
                                                                                            'Text' = 'Spell check'
                                                                                        }
                                                                                    )
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                                @{
                                                                    'Tag' = 'div'
                                                                    'Attributes' = @{
                                                                        'class' = 'fluent-toggle-wrapper {{binding:10}}'
                                                                        'id' = 'toggle-setting-spellcheck'
                                                                    }
                                                                    'Children' = @(
                                                                        @{
                                                                            'Tag' = 'div'
                                                                            'Attributes' = @{
                                                                                'class' = 'toggle-switch'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Tag' = 'div'
                                                                                    'Attributes' = @{
                                                                                        'class' = 'toggle-knob'
                                                                                    }
                                                                                    'Children' = @()
                                                                                }
                                                                            )
                                                                        }
                                                                        @{
                                                                            'Tag' = 'span'
                                                                            'Attributes' = @{
                                                                                'class' = 'toggle-label'
                                                                            }
                                                                            'Children' = @(
                                                                                @{
                                                                                    'Text' = '{{binding:11}}'
                                                                                }
                                                                            )
                                                                        }
                                                                    )
                                                                }
                                                            )
                                                        }
                                                    )
                                                }
                                            )
                                        }
                                        @{
                                            'Tag' = 'div'
                                            'Attributes' = @{
                                                'class' = 'settings-side-col'
                                            }
                                            'Children' = @(
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'about-header'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Text' = 'About this app'
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'about-app-name'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Text' = 'Windows Notepad 11.2606.15.0'
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'about-copyright'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Text' = '&copy; 2026 Microsoft. All rights reserved.'
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'about-links'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Tag' = 'a'
                                                            'Attributes' = @{
                                                                'class' = 'about-link'
                                                                'href' = 'https://www.microsoft.com/useterms'
                                                                'target' = '_blank'
                                                                'rel' = 'noopener'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Text' = 'Microsoft Software License Terms'
                                                                }
                                                            )
                                                        }
                                                        @{
                                                            'Tag' = 'a'
                                                            'Attributes' = @{
                                                                'class' = 'about-link'
                                                                'href' = 'https://www.microsoft.com/servicesagreement'
                                                                'target' = '_blank'
                                                                'rel' = 'noopener'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Text' = 'Microsoft Services Agreement'
                                                                }
                                                            )
                                                        }
                                                        @{
                                                            'Tag' = 'a'
                                                            'Attributes' = @{
                                                                'class' = 'about-link'
                                                                'href' = 'https://privacy.microsoft.com'
                                                                'target' = '_blank'
                                                                'rel' = 'noopener'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Text' = 'Microsoft Privacy Statement'
                                                                }
                                                            )
                                                        }
                                                        @{
                                                            'Tag' = 'a'
                                                            'Attributes' = @{
                                                                'class' = 'about-link'
                                                                'href' = '#acknowledgments'
                                                                'id' = 'link-third-party'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Text' = 'Third-Party Software Acknowledgments'
                                                                }
                                                            )
                                                        }
                                                    )
                                                }
                                                @{
                                                    'Tag' = 'div'
                                                    'Attributes' = @{
                                                        'class' = 'about-buttons'
                                                    }
                                                    'Children' = @(
                                                        @{
                                                            'Tag' = 'button'
                                                            'Attributes' = @{
                                                                'class' = 'fluent-btn'
                                                                'id' = 'btn-send-feedback'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Text' = 'Send feedback'
                                                                }
                                                            )
                                                        }
                                                        @{
                                                            'Tag' = 'button'
                                                            'Attributes' = @{
                                                                'class' = 'fluent-btn'
                                                                'id' = 'btn-help'
                                                            }
                                                            'Children' = @(
                                                                @{
                                                                    'Text' = 'Help'
                                                                }
                                                            )
                                                        }
                                                    )
                                                }
                                            )
                                        }
                                    )
                                }
                            )
                        }
                    )
                }
                @{
                    'Tag' = 'div'
                    'Attributes' = @{
                        'class' = 'modal-overlay'
                        'id' = 'notepad-modal'
                    }
                    'Children' = @(
                        @{
                            'Tag' = 'div'
                            'Attributes' = @{
                                'class' = 'fluent-dialog'
                                'id' = 'fluent-dialog-box'
                            }
                            'Children' = @(
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'dialog-title'
                                        'id' = 'dialog-title-text'
                                    }
                                    'Children' = @(
                                        @{
                                            'Text' = 'Notepad'
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'dialog-message'
                                        'id' = 'dialog-message-text'
                                    }
                                    'Children' = @(
                                        @{
                                            'Text' = 'Do you want to save changes?'
                                        }
                                    )
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'id' = 'dialog-custom-body'
                                    }
                                    'Children' = @()
                                }
                                @{
                                    'Tag' = 'div'
                                    'Attributes' = @{
                                        'class' = 'dialog-buttons'
                                        'id' = 'dialog-btn-container'
                                    }
                                    'Children' = @()
                                }
                            )
                        }
                    )
                }
                @{
                    'Tag' = 'input'
                    'Attributes' = @{
                        'type' = 'file'
                        'id' = 'hidden-file-input'
                        'style' = 'display: none;'
                    }
                    'Children' = @()
                }
            )
        }
        'Bindings' = @(
            @{
                'Id' = 0
                'Expression' = 'this.settings.wordWrap ? ''wrap'' : ''nowrap'''
            }
            @{
                'Id' = 1
                'Expression' = 'this.settings.spellCheck'
            }
            @{
                'Id' = 2
                'Expression' = 'this.settings.wordWrap ? ''on'' : '''''
            }
            @{
                'Id' = 3
                'Expression' = 'this.settings.wordWrap ? ''On'' : ''Off'''
            }
            @{
                'Id' = 4
                'Expression' = 'this.settings.formatting ? ''on'' : '''''
            }
            @{
                'Id' = 5
                'Expression' = 'this.settings.formatting ? ''On'' : ''Off'''
            }
            @{
                'Id' = 6
                'Expression' = 'this.settings.startupOption === ''continueSession'' ? ''selected'' : '''''
            }
            @{
                'Id' = 7
                'Expression' = 'this.settings.startupOption === ''newSession'' ? ''selected'' : '''''
            }
            @{
                'Id' = 8
                'Expression' = 'this.settings.recentFilesEnabled ? ''on'' : '''''
            }
            @{
                'Id' = 9
                'Expression' = 'this.settings.recentFilesEnabled ? ''On'' : ''Off'''
            }
            @{
                'Id' = 10
                'Expression' = 'this.settings.spellCheck ? ''on'' : '''''
            }
            @{
                'Id' = 11
                'Expression' = 'this.settings.spellCheck ? ''On'' : ''Off'''
            }
        )
        'SourceTemplate' = '
        <!-- Titlebar with Tabs & Window Controls -->
        <header class="notepad-titlebar">
          <div class="titlebar-left">
            <div class="notepad-app-icon" title="Notepad">${ICONS.app}</div>
            <div class="notepad-tabs-container" id="tabs-container"></div>
            <button class="add-tab-btn" id="btn-add-tab" title="New tab (Ctrl+N)">${ICONS.plus}</button>
          </div>
          <div class="window-controls">
            <button class="win-btn win-minimize" id="btn-win-min" title="Minimize">${ICONS.minimize}</button>
            <button class="win-btn win-maximize" id="btn-win-max" title="Maximize">${ICONS.maximize}</button>
            <button class="win-btn win-close" id="btn-win-close" title="Close">${ICONS.close}</button>
          </div>
        </header>

        <!-- Menu Bar -->
        <nav class="notepad-menubar">
          <div class="menubar-left">
            <button class="menu-item-btn" id="menu-btn-file">File</button>
            <button class="menu-item-btn" id="menu-btn-edit">Edit</button>
            <button class="menu-item-btn" id="menu-btn-view">View</button>
          </div>
          <div class="menubar-right">
            <button class="menu-action-btn" id="btn-whats-new" title="What''s new">
              ${ICONS.megaphone}
              <span class="notification-badge-dot"></span>
            </button>
            <button class="menu-action-btn" id="btn-settings-toggle" title="Settings">
              ${ICONS.gear}
            </button>
          </div>

          <!-- Dropdown Flyout Menus - Cleanly Positioned with Accurate WinUI Spacing -->
          <div class="flyout-menu" id="flyout-file">
            <div class="menu-row" data-action="newTab">
              <span class="menu-row-label">New tab</span>
              <span class="menu-row-shortcut">Ctrl+N</span>
            </div>
            <div class="menu-row" data-action="newWindow">
              <span class="menu-row-label">New window</span>
              <span class="menu-row-shortcut">Ctrl+Shift+N</span>
            </div>
            <div class="menu-row" data-action="newMarkdownTab">
              <span class="menu-row-label">New Markdown tab</span>
            </div>
            <div class="menu-row" data-action="openFile">
              <span class="menu-row-label">Open</span>
              <span class="menu-row-shortcut">Ctrl+O</span>
            </div>
            <div class="menu-row submenu-container" id="menu-recent-container">
              <span class="menu-row-label">Recent</span>
              <span class="menu-submenu-arrow">${ICONS.chevronRight}</span>
              <div class="submenu-flyout" id="flyout-recent-items">
                <div class="menu-row disabled"><span class="menu-row-label">No recent files</span></div>
              </div>
            </div>
            <div class="menu-row" data-action="save">
              <span class="menu-row-label">Save</span>
              <span class="menu-row-shortcut">Ctrl+S</span>
            </div>
            <div class="menu-row" data-action="saveAs">
              <span class="menu-row-label">Save as</span>
              <span class="menu-row-shortcut">Ctrl+Shift+S</span>
            </div>
            <div class="menu-row" data-action="saveAll">
              <span class="menu-row-label">Save all</span>
              <span class="menu-row-shortcut">Ctrl+Alt+S</span>
            </div>
            <div class="menu-separator"></div>
            <div class="menu-row" data-action="pageSetup">
              <span class="menu-row-label">Page setup</span>
            </div>
            <div class="menu-row" data-action="print">
              <span class="menu-row-label">Print</span>
              <span class="menu-row-shortcut">Ctrl+P</span>
            </div>
            <div class="menu-separator"></div>
            <div class="menu-row" data-action="closeTab">
              <span class="menu-row-label">Close tab</span>
              <span class="menu-row-shortcut">Ctrl+W</span>
            </div>
            <div class="menu-row" data-action="closeWindow">
              <span class="menu-row-label">Close window</span>
              <span class="menu-row-shortcut">Ctrl+Shift+W</span>
            </div>
            <div class="menu-row" data-action="exit">
              <span class="menu-row-label">Exit</span>
            </div>
          </div>

          <div class="flyout-menu" id="flyout-edit">
            <div class="menu-row" data-action="undo">
              <span class="menu-row-label">Undo</span>
              <span class="menu-row-shortcut">Ctrl+Z</span>
            </div>
            <div class="menu-separator"></div>
            <div class="menu-row" data-action="cut">
              <span class="menu-row-label">Cut</span>
              <span class="menu-row-shortcut">Ctrl+X</span>
            </div>
            <div class="menu-row" data-action="copy">
              <span class="menu-row-label">Copy</span>
              <span class="menu-row-shortcut">Ctrl+C</span>
            </div>
            <div class="menu-row" data-action="paste">
              <span class="menu-row-label">Paste</span>
              <span class="menu-row-shortcut">Ctrl+V</span>
            </div>
            <div class="menu-row" data-action="delete">
              <span class="menu-row-label">Delete</span>
              <span class="menu-row-shortcut">Del</span>
            </div>
            <div class="menu-separator"></div>
            <div class="menu-row" data-action="clearFormatting">
              <span class="menu-row-label">Clear formatting</span>
            </div>
            <!-- Excluded Bing/AI integrations per specification -->
            <div class="menu-row" data-action="find">
              <span class="menu-row-label">Find</span>
              <span class="menu-row-shortcut">Ctrl+F</span>
            </div>
            <div class="menu-row" data-action="findNext">
              <span class="menu-row-label">Find next</span>
              <span class="menu-row-shortcut">F3</span>
            </div>
            <div class="menu-row" data-action="findPrevious">
              <span class="menu-row-label">Find previous</span>
              <span class="menu-row-shortcut">Shift+F3</span>
            </div>
            <div class="menu-row" data-action="replace">
              <span class="menu-row-label">Replace</span>
              <span class="menu-row-shortcut">Ctrl+H</span>
            </div>
            <div class="menu-row" data-action="goTo">
              <span class="menu-row-label">Go to</span>
              <span class="menu-row-shortcut">Ctrl+G</span>
            </div>
            <div class="menu-separator"></div>
            <div class="menu-row" data-action="selectAll">
              <span class="menu-row-label">Select all</span>
              <span class="menu-row-shortcut">Ctrl+A</span>
            </div>
            <div class="menu-row" data-action="timeDate">
              <span class="menu-row-label">Time/Date</span>
              <span class="menu-row-shortcut">F5</span>
            </div>
            <div class="menu-separator"></div>
            <div class="menu-row" data-action="openFontSettings">
              <span class="menu-row-label">Font</span>
            </div>
          </div>

          <div class="flyout-menu" id="flyout-view">
            <div class="menu-row submenu-container" id="menu-zoom-container">
              <span class="menu-row-label">Zoom</span>
              <span class="menu-submenu-arrow">${ICONS.chevronRight}</span>
              <div class="submenu-flyout">
                <div class="menu-row" data-action="zoomIn">
                  <span class="menu-row-label">Zoom in</span>
                  <span class="menu-row-shortcut">Ctrl+Plus</span>
                </div>
                <div class="menu-row" data-action="zoomOut">
                  <span class="menu-row-label">Zoom out</span>
                  <span class="menu-row-shortcut">Ctrl+Minus</span>
                </div>
                <div class="menu-row" data-action="zoomReset">
                  <span class="menu-row-label">Restore default zoom</span>
                  <span class="menu-row-shortcut">Ctrl+0</span>
                </div>
              </div>
            </div>
            <div class="menu-row" data-action="toggleStatusBar">
              <div class="menu-row-left">
                <span class="menu-check-icon" id="check-status-bar">${ICONS.check}</span>
                <span class="menu-row-label">Status bar</span>
              </div>
            </div>
            <div class="menu-row" data-action="toggleWordWrap">
              <div class="menu-row-left">
                <span class="menu-check-icon" id="check-word-wrap">${ICONS.check}</span>
                <span class="menu-row-label">Word wrap</span>
              </div>
            </div>
            <div class="menu-row submenu-container">
              <span class="menu-row-label">Markdown</span>
              <span class="menu-submenu-arrow">${ICONS.chevronRight}</span>
              <div class="submenu-flyout">
                <div class="menu-row" data-action="toggleMarkdownPreview">
                  <span class="menu-row-label">Preview Markdown</span>
                </div>
              </div>
            </div>
          </div>
        </nav>

        <!-- Main Workspace Body -->
        <main class="notepad-main-content">
          <div class="editor-view-container">
            <textarea
              class="editor-textarea ${this.settings.wordWrap ? ''wrap'' : ''nowrap''}"
              id="editor-area"
              spellcheck="${this.settings.spellCheck}"
              autocapitalize="off"
              autocomplete="off"
              autocorrect="off"
            ></textarea>
          </div>

          <!-- Floating Find & Replace Widget -->
          <div class="find-replace-flyout" id="find-replace-panel">
            <div class="find-row">
              <div class="find-input-wrap">
                <input type="text" class="find-input" id="find-query-input" placeholder="Find">
                <span class="match-count-badge" id="find-match-counter">0 of 0</span>
              </div>
              <button class="find-btn" id="find-btn-prev" title="Previous match (Shift+F3)">${ICONS.arrowUp}</button>
              <button class="find-btn" id="find-btn-next" title="Next match (F3)">${ICONS.arrowDown}</button>
              <button class="find-btn" id="find-btn-case" title="Match case">${ICONS.caseSensitive}</button>
              <button class="find-btn active" id="find-btn-wrap" title="Wrap around">${ICONS.wrapAround}</button>
              <button class="find-btn" id="find-btn-toggle-replace" title="Toggle replace">${ICONS.chevronDown}</button>
              <button class="find-btn" id="find-btn-close" title="Close">${ICONS.close}</button>
            </div>
            <div class="replace-row" id="replace-row-container" style="display: none;">
              <div class="find-input-wrap">
                <input type="text" class="find-input" id="replace-query-input" placeholder="Replace with">
              </div>
              <button class="text-action-btn" id="btn-do-replace">Replace</button>
              <button class="text-action-btn" id="btn-do-replace-all">Replace all</button>
            </div>
          </div>
        </main>

        <!-- Status Bar -->
        <footer class="notepad-statusbar" id="notepad-statusbar">
          <div class="statusbar-left">
            <div class="statusbar-item" id="sb-cursor-pos">Ln 1, Col 1</div>
            <div class="statusbar-divider"></div>
            <div class="statusbar-item" id="sb-char-count">0 characters</div>
          </div>
          <div class="statusbar-right">
            <div class="statusbar-item interactive" id="sb-doc-type">Plain text</div>
            <div class="statusbar-divider"></div>
            <div class="statusbar-item interactive" id="sb-zoom-level">100%</div>
            <div class="statusbar-divider"></div>
            <div class="statusbar-item interactive" id="sb-line-ending">Unix (LF)</div>
            <div class="statusbar-divider"></div>
            <div class="statusbar-item interactive" id="sb-encoding">UTF-8</div>
          </div>
        </footer>

        <!-- Settings View (Default Closed Accordions) -->
        <div class="notepad-settings-view" id="settings-view">
          <header class="settings-titlebar">
            <button class="settings-back-btn" id="settings-btn-back" title="Back">${ICONS.back}</button>
            <div class="settings-titlebar-name">
              <div class="notepad-app-icon">${ICONS.app}</div>
              <span>Notepad</span>
            </div>
            <div class="window-controls">
              <button class="win-btn win-minimize">${ICONS.minimize}</button>
              <button class="win-btn win-maximize">${ICONS.maximize}</button>
              <button class="win-btn win-close" id="settings-win-close">${ICONS.close}</button>
            </div>
          </header>

          <div class="settings-scroll-area">
            <div class="settings-layout-grid">
              <div class="settings-main-col">
                <h1 class="settings-page-title">Settings</h1>

                <!-- Appearance -->
                <div class="settings-section-header">Appearance</div>
                <div class="settings-card">
                  <div class="settings-card-header">
                    <div class="card-info-left">
                      <div class="card-icon">${ICONS.theme}</div>
                      <div class="card-text-titles">
                        <div class="card-primary-title">App theme</div>
                        <div class="card-subtitle">Select which app theme to display</div>
                      </div>
                    </div>
                    <select class="fluent-select" id="setting-theme-select">
                      <option value="dark">Dark</option>
                      <option value="light">Light</option>
                      <option value="system">Use system setting</option>
                    </select>
                  </div>
                </div>

                <!-- Text Formatting -->
                <div class="settings-section-header">Text Formatting</div>

                <!-- Font Expandable Card (Default Closed) -->
                <div class="settings-card expandable" id="card-font-setting">
                  <div class="settings-card-header" id="header-font-setting">
                    <div class="card-info-left">
                      <div class="card-icon">${ICONS.font}</div>
                      <div class="card-text-titles">
                        <div class="card-primary-title">Font</div>
                      </div>
                    </div>
                    <button class="accordion-toggle-btn" id="btn-font-accordion">${ICONS.chevronDown}</button>
                  </div>
                  <div class="card-expand-content" id="font-expand-content">
                    <div class="font-row">
                      <span class="font-row-label">Family</span>
                      <select class="fluent-select" id="setting-font-family">
                        <option value="Consolas">Consolas</option>
                        <option value="Cascadia Code">Cascadia Code</option>
                        <option value="Segoe UI">Segoe UI</option>
                        <option value="Courier New">Courier New</option>
                      </select>
                    </div>
                    <div class="font-row">
                      <span class="font-row-label">Style</span>
                      <select class="fluent-select" id="setting-font-style">
                        <option value="Regular">Regular</option>
                        <option value="Bold">Bold</option>
                        <option value="Italic">Italic</option>
                        <option value="Bold Italic">Bold Italic</option>
                      </select>
                    </div>
                    <div class="font-row">
                      <span class="font-row-label">Size</span>
                      <select class="fluent-select" id="setting-font-size">
                        <option value="8">8</option>
                        <option value="9">9</option>
                        <option value="10">10</option>
                        <option value="11">11</option>
                        <option value="12">12</option>
                        <option value="14">14</option>
                        <option value="16">16</option>
                        <option value="18">18</option>
                        <option value="20">20</option>
                        <option value="24">24</option>
                        <option value="28">28</option>
                        <option value="36">36</option>
                      </select>
                    </div>
                    <div class="font-preview-box" id="font-sample-preview">
                      The sound of ocean waves calms my soul.
                    </div>
                  </div>
                </div>

                <!-- Word Wrap Toggle Card -->
                <div class="settings-card">
                  <div class="settings-card-header">
                    <div class="card-info-left">
                      <div class="card-icon">${ICONS.wordWrap}</div>
                      <div class="card-text-titles">
                        <div class="card-primary-title">Word wrap</div>
                        <div class="card-subtitle">Fit text within window by default</div>
                      </div>
                    </div>
                    <div class="fluent-toggle-wrapper ${this.settings.wordWrap ? ''on'' : ''''}" id="toggle-setting-wordwrap">
                      <div class="toggle-switch"><div class="toggle-knob"></div></div>
                      <span class="toggle-label">${this.settings.wordWrap ? ''On'' : ''Off''}</span>
                    </div>
                  </div>
                </div>

                <!-- Formatting Toggle Card -->
                <div class="settings-card">
                  <div class="settings-card-header">
                    <div class="card-info-left">
                      <div class="card-icon">${ICONS.formatting}</div>
                      <div class="card-text-titles">
                        <div class="card-primary-title">Formatting</div>
                      </div>
                    </div>
                    <div class="fluent-toggle-wrapper ${this.settings.formatting ? ''on'' : ''''}" id="toggle-setting-formatting">
                      <div class="toggle-switch"><div class="toggle-knob"></div></div>
                      <span class="toggle-label">${this.settings.formatting ? ''On'' : ''Off''}</span>
                    </div>
                  </div>
                </div>

                <!-- Opening Notepad -->
                <div class="settings-section-header">Opening Notepad</div>

                <!-- Opening Files Dropdown Card -->
                <div class="settings-card">
                  <div class="settings-card-header">
                    <div class="card-info-left">
                      <div class="card-icon">${ICONS.openFiles}</div>
                      <div class="card-text-titles">
                        <div class="card-primary-title">Opening files</div>
                        <div class="card-subtitle">Choose where your files are opened</div>
                      </div>
                    </div>
                    <select class="fluent-select" id="setting-opening-files">
                      <option value="newTab">Open in a new tab</option>
                      <option value="newWindow">Open in a new window</option>
                    </select>
                  </div>
                </div>

                <!-- When Notepad Starts Accordion Card (Default Closed) -->
                <div class="settings-card expandable" id="card-startup-setting">
                  <div class="settings-card-header" id="header-startup-setting">
                    <div class="card-info-left">
                      <div class="card-icon">${ICONS.tabsApp}</div>
                      <div class="card-text-titles">
                        <div class="card-primary-title">When Notepad starts</div>
                      </div>
                    </div>
                    <button class="accordion-toggle-btn" id="btn-startup-accordion">${ICONS.chevronDown}</button>
                  </div>
                  <div class="card-expand-content">
                    <div class="fluent-radio-group">
                      <div class="fluent-radio-option ${this.settings.startupOption === ''continueSession'' ? ''selected'' : ''''}" data-value="continueSession" id="radio-startup-continue">
                        <div class="radio-circle"><div class="radio-dot"></div></div>
                        <span>Continue previous session</span>
                      </div>
                      <div class="fluent-radio-option ${this.settings.startupOption === ''newSession'' ? ''selected'' : ''''}" data-value="newSession" id="radio-startup-new">
                        <div class="radio-circle"><div class="radio-dot"></div></div>
                        <span>Start new session and discard unsaved changes</span>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Recent Files Toggle Card -->
                <div class="settings-card">
                  <div class="settings-card-header">
                    <div class="card-info-left">
                      <div class="card-icon">${ICONS.recentFiles}</div>
                      <div class="card-text-titles">
                        <div class="card-primary-title">Recent Files</div>
                      </div>
                    </div>
                    <div class="fluent-toggle-wrapper ${this.settings.recentFilesEnabled ? ''on'' : ''''}" id="toggle-setting-recent-files">
                      <div class="toggle-switch"><div class="toggle-knob"></div></div>
                      <span class="toggle-label">${this.settings.recentFilesEnabled ? ''On'' : ''Off''}</span>
                    </div>
                  </div>
                </div>

                <!-- Spelling -->
                <div class="settings-section-header">Spelling</div>
                <div class="settings-card">
                  <div class="settings-card-header">
                    <div class="card-info-left">
                      <div class="card-icon">${ICONS.spellCheck}</div>
                      <div class="card-text-titles">
                        <div class="card-primary-title">Spell check</div>
                      </div>
                    </div>
                    <div class="fluent-toggle-wrapper ${this.settings.spellCheck ? ''on'' : ''''}" id="toggle-setting-spellcheck">
                      <div class="toggle-switch"><div class="toggle-knob"></div></div>
                      <span class="toggle-label">${this.settings.spellCheck ? ''On'' : ''Off''}</span>
                    </div>
                  </div>
                </div>
              </div>

              <!-- About Side Column -->
              <div class="settings-side-col">
                <div class="about-header">About this app</div>
                <div class="about-app-name">Windows Notepad 11.2606.15.0</div>
                <div class="about-copyright">&copy; 2026 Microsoft. All rights reserved.</div>

                <div class="about-links">
                  <a class="about-link" href="https://www.microsoft.com/useterms" target="_blank" rel="noopener">Microsoft Software License Terms</a>
                  <a class="about-link" href="https://www.microsoft.com/servicesagreement" target="_blank" rel="noopener">Microsoft Services Agreement</a>
                  <a class="about-link" href="https://privacy.microsoft.com" target="_blank" rel="noopener">Microsoft Privacy Statement</a>
                  <a class="about-link" href="#acknowledgments" id="link-third-party">Third-Party Software Acknowledgments</a>
                </div>

                <div class="about-buttons">
                  <button class="fluent-btn" id="btn-send-feedback">Send feedback</button>
                  <button class="fluent-btn" id="btn-help">Help</button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Semantic Fluent Modal Dialog Container -->
        <div class="modal-overlay" id="notepad-modal">
          <div class="fluent-dialog" id="fluent-dialog-box">
            <div class="dialog-title" id="dialog-title-text">Notepad</div>
            <div class="dialog-message" id="dialog-message-text">Do you want to save changes?</div>
            <div id="dialog-custom-body"></div>
            <div class="dialog-buttons" id="dialog-btn-container"></div>
          </div>
        </div>

        <!-- Hidden File Input for Native File System Compatibility -->
        <input type="file" id="hidden-file-input" style="display: none;" />
      '
        'TabTemplate' = '
          <span class="tab-title">${this.escapeHTML(tab.title)}</span>
          <div class="tab-indicator-container">
            <span class="tab-dot" title="Unsaved changes"></span>
            <button class="tab-close-btn" title="Close tab (Ctrl+W)">${ICONS.close}</button>
          </div>
        '
        'MarkdownPreviewTemplate' = '<div style="max-height: 380px; overflow-y: auto; padding: 12px; background: rgba(0,0,0,0.2); border-radius: 6px; user-select: text;">${html}</div>'
        'InlineCodeStyle' = 'background: rgba(255,255,255,0.1); padding: 2px 4px; border-radius: 3px;'
        'DynamicPrimitives' = @(
            'input.dialog-input'
            'button.fluent-btn'
            'button.fluent-btn.primary'
            'h1'
            'h2'
            'h3'
            'strong'
            'em'
            'code'
            'br'
        )
    }
    'MenuActions' = @(
        'newTab'
        'newWindow'
        'newMarkdownTab'
        'openFile'
        'save'
        'saveAs'
        'saveAll'
        'pageSetup'
        'print'
        'closeTab'
        'closeWindow'
        'exit'
        'undo'
        'cut'
        'copy'
        'paste'
        'delete'
        'clearFormatting'
        'find'
        'findNext'
        'findPrevious'
        'replace'
        'goTo'
        'selectAll'
        'timeDate'
        'openFontSettings'
        'zoomIn'
        'zoomOut'
        'zoomReset'
        'toggleStatusBar'
        'toggleWordWrap'
        'toggleMarkdownPreview'
    )
    'Methods' = @(
        @{
            'Name' = 'constructor'
            'Line' = 1333
        }
        @{
            'Name' = 'loadSettings'
            'Line' = 1357
        }
        @{
            'Name' = 'saveSettings'
            'Line' = 1366
        }
        @{
            'Name' = 'loadSavedSession'
            'Line' = 1372
        }
        @{
            'Name' = 'saveSession'
            'Line' = 1403
        }
        @{
            'Name' = 'init'
            'Line' = 1417
        }
        @{
            'Name' = 'applyTheme'
            'Line' = 1428
        }
        @{
            'Name' = 'renderAppSkeleton'
            'Line' = 1436
        }
        @{
            'Name' = 'getActiveTab'
            'Line' = 1978
        }
        @{
            'Name' = 'renderTabs'
            'Line' = 1982
        }
        @{
            'Name' = 'createNewTab'
            'Line' = 2011
        }
        @{
            'Name' = 'switchTab'
            'Line' = 2029
        }
        @{
            'Name' = 'promptCloseTab'
            'Line' = 2050
        }
        @{
            'Name' = 'closeTab'
            'Line' = 2073
        }
        @{
            'Name' = 'openFileDialog'
            'Line' = 2090
        }
        @{
            'Name' = 'saveTab'
            'Line' = 2127
        }
        @{
            'Name' = 'saveAllTabs'
            'Line' = 2186
        }
        @{
            'Name' = 'calculateCursorLineCol'
            'Line' = 2193
        }
        @{
            'Name' = 'updateStatusBar'
            'Line' = 2203
        }
        @{
            'Name' = 'applyEditorStyles'
            'Line' = 2231
        }
        @{
            'Name' = 'updateActiveTabContent'
            'Line' = 2264
        }
        @{
            'Name' = 'openFind'
            'Line' = 2272
        }
        @{
            'Name' = 'closeFind'
            'Line' = 2294
        }
        @{
            'Name' = 'executeFind'
            'Line' = 2300
        }
        @{
            'Name' = 'selectMatch'
            'Line' = 2336
        }
        @{
            'Name' = 'findNext'
            'Line' = 2349
        }
        @{
            'Name' = 'findPrev'
            'Line' = 2362
        }
        @{
            'Name' = 'replaceCurrent'
            'Line' = 2375
        }
        @{
            'Name' = 'replaceAll'
            'Line' = 2393
        }
        @{
            'Name' = 'showGoToDialog'
            'Line' = 2414
        }
        @{
            'Name' = 'showModal'
            'Line' = 2446
        }
        @{
            'Name' = 'openSettings'
            'Line' = 2490
        }
        @{
            'Name' = 'closeSettings'
            'Line' = 2502
        }
        @{
            'Name' = 'syncSettingsUI'
            'Line' = 2507
        }
        @{
            'Name' = 'updateToggleState'
            'Line' = 2531
        }
        @{
            'Name' = 'toggleMenu'
            'Line' = 2544
        }
        @{
            'Name' = 'closeMenus'
            'Line' = 2575
        }
        @{
            'Name' = 'attachGlobalEvents'
            'Line' = 2582
        }
        @{
            'Name' = 'handleAction'
            'Line' = 2890
        }
        @{
            'Name' = 'showMarkdownPreview'
            'Line' = 3043
        }
        @{
            'Name' = 'simpleMarkdownToHtml'
            'Line' = 3056
        }
        @{
            'Name' = 'escapeHTML'
            'Line' = 3070
        }
    )
}
}
$Design
