"use strict";
/**
 * Windows 11 Notepad - High-Performance Semantic Web Implementation
 * Version: 11.2606.15.0
 * Self-Contained JavaScript Architecture with Integrated Fluent Stylesheet
 * Pure Vanilla JavaScript | Zero Third-Party Dependencies | Zero Bing/AI Integrations
 */
(function () {
    'use strict';
    const window = globalThis.window;
    const document = globalThis.document;
    // --- Dynamic Fluent Stylesheet Injection ---
    const DESIGN_TOKENS = {
        spacing: {
            titlebarHeight: '40px', menubarHeight: '38px', statusbarHeight: '28px',
            editorPadding: '14px 16px', titlebarInset: '10px',
            menubarPadding: '0 8px', statusbarPadding: '0 16px'
        },
        typeScale: {
            ui: '14px', menu: '13px', status: '12px', editor: '11pt',
            dialogTitle: '18px'
        },
        colors: {
            dark: {
                window: '#1f1f1f', titlebar: '#1f1f1f', menubar: '#1f1f1f',
                editor: '#282828', tabActive: '#2c2c2c', tabHover: '#262626',
                card: '#2d2d2d', flyout: '#2c2c2c', control: '#323232',
                statusbar: '#1f1f1f', dialog: '#2c2c2c', textPrimary: '#ffffff',
                textSecondary: '#9d9d9d', accent: '#0090f1', selection: '#005fb8'
            },
            light: {
                window: '#f3f3f3', titlebar: '#f3f3f3', menubar: '#f3f3f3',
                editor: '#ffffff', tabActive: '#ffffff', tabHover: '#eaeaea',
                card: '#ffffff', flyout: '#ffffff', control: '#fbfbfb',
                statusbar: '#f3f3f3', dialog: '#ffffff', textPrimary: '#1b1b1b',
                textSecondary: '#616161', accent: '#005fb8', selection: '#005fb8'
            }
        },
        radii: { tab: '7px 7px 0 0', control: '4px', flyout: '8px', dialog: '8px' },
        elevation: {
            dark: { flyout: '0 8px 24px rgba(0, 0, 0, 0.55)', modal: '0 16px 36px rgba(0, 0, 0, 0.65)' },
            light: { flyout: '0 8px 24px rgba(0, 0, 0, 0.15)', modal: '0 16px 36px rgba(0, 0, 0, 0.25)' }
        },
        motion: {
            tabHover: '0.1s ease', menuHover: '0.1s ease',
            flyout: '0.1s ease-out', find: '0.12s ease-out', dialog: '0.15s ease-out'
        },
        stylesheet: `/* Windows 11 Modern Notepad - WinUI 3 Fluent Integrated Stylesheet */

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

  --font-ui: 'Segoe UI Variable Text', 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, sans-serif;
  --font-editor: 'Consolas', 'Cascadia Code', 'Courier New', monospace;
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
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16' fill='%239d9d9d'%3E%3Cpath d='M3.2 5.2a.75.75 0 0 1 1.06 0L8 8.94l3.74-3.74a.75.75 0 1 1 1.06 1.06l-4.27 4.27a.75.75 0 0 1-1.06 0L3.2 6.26a.75.75 0 0 1 0-1.06z'/%3E%3C/svg%3E");
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
`
    };
    function ensureStylesInjected() {
        if (!document.getElementById('notepad-fluent-styles')) {
            const styleTag = document.createElement('style');
            styleTag.id = 'notepad-fluent-styles';
            styleTag.textContent = DESIGN_TOKENS.stylesheet;
            document.head.appendChild(styleTag);
        }
    }
    // --- SVG Icons Library (WinUI 3 / Segoe Fluent Icons) ---
    const ICONS = {
        app: `<svg viewBox="0 0 24 24"><path fill="#0078d4" d="M4 2.5C4 1.67 4.67 1 5.5 1h13c.83 0 1.5.67 1.5 1.5v19c0 .83-.67 1.5-1.5 1.5h-13c-.83 0-1.5-.67-1.5-1.5v-19z"/><path fill="#60cdff" d="M7 6h10v2H7zm0 4h10v2H7zm0 4h6v2H7z"/><path fill="#ffffff" opacity="0.8" d="M7 18h10v1.5H7z"/></svg>`,
        minimize: `<svg viewBox="0 0 10 10"><path d="M0 5h10v1H0z"/></svg>`,
        maximize: `<svg viewBox="0 0 10 10"><path d="M1 1h8v8H1V1zm1 1v6h6V2H2z"/></svg>`,
        restore: `<svg viewBox="0 0 10 10"><path d="M3 1h6v6H8V2H3V1zm-2 2h6v6H1V3zm1 1v4h4V4H2z"/></svg>`,
        close: `<svg viewBox="0 0 10 10"><path d="M1.4 0.7L5 4.3 8.6 0.7 9.3 1.4 5.7 5 9.3 8.6 8.6 9.3 5 5.7 1.4 9.3 0.7 8.6 4.3 5 0.7 1.4z"/></svg>`,
        plus: `<svg viewBox="0 0 16 16"><path d="M8 2a.75.75 0 0 1 .75.75v4.5h4.5a.75.75 0 0 1 0 1.5h-4.5v4.5a.75.75 0 0 1-1.5 0v-4.5h-4.5a.75.75 0 0 1 0-1.5h4.5v-4.5A.75.75 0 0 1 8 2z"/></svg>`,
        back: `<svg viewBox="0 0 16 16"><path d="M13.5 7.25H4.86l3.97-3.97a.75.75 0 0 0-1.06-1.06l-5.25 5.25a.75.75 0 0 0 0 1.06l5.25 5.25a.75.75 0 1 0 1.06-1.06L4.86 8.75H13.5a.75.75 0 0 0 0-1.5z"/></svg>`,
        gear: `<svg viewBox="0 0 16 16"><path d="M7.07 1a1 1 0 0 0-.98.8l-.27 1.34a5.03 5.03 0 0 0-1.28.53l-1.23-.62a1 1 0 0 0-1.24.31L1.13 5.01a1 1 0 0 0 .15 1.27l1.04.88c-.04.28-.07.56-.07.84s.03.56.07.84l-1.04.88a1 1 0 0 0-.15 1.27l1.24 1.65a1 1 0 0 0 1.24.31l1.23-.62c.4.23.83.41 1.28.53l.27 1.34a1 1 0 0 0 .98.8h2.06a1 1 0 0 0 .98-.8l.27-1.34c.45-.12.88-.3 1.28-.53l1.23.62a1 1 0 0 0 1.24-.31l1.24-1.65a1 1 0 0 0-.15-1.27l-1.04-.88c.04-.28.07-.56.07-.84s-.03-.56-.07-.84l1.04-.88a1 1 0 0 0 .15-1.27L13.87 3.36a1 1 0 0 0-1.24-.31l-1.23.62a5.03 5.03 0 0 0-1.28-.53l-.27-1.34a1 1 0 0 0-.98-.8H7.07zM8 5.5a2.5 2.5 0 1 1 0 5 2.5 2.5 0 0 1 0-5z"/></svg>`,
        megaphone: `<svg viewBox="0 0 16 16"><path d="M13 2.5a.75.75 0 0 0-1.06-.68L4.62 5.08A2.75 2.75 0 0 0 2 7.75v.5c0 1.2.78 2.22 1.88 2.58l-.63 2.2a.75.75 0 0 0 .95.93l2.87-.96.48-.16a.75.75 0 0 0 .47-.45l.63-1.89h3.29l.06.01a.75.75 0 0 0 .8-.66l.2-1.39A2.99 2.99 0 0 0 15 5.5v-.5a2.5 2.5 0 0 0-2-2.5zm1 3c0 .83-.67 1.5-1.5 1.5h-.5V4h.5c.83 0 1.5.67 1.5 1.5z"/></svg>`,
        check: `<svg viewBox="0 0 16 16"><path d="M13.78 4.22a.75.75 0 0 1 0 1.06l-7.25 7.25a.75.75 0 0 1-1.06 0L2.22 9.28a.75.75 0 0 1 1.06-1.06L6 10.94l6.72-6.72a.75.75 0 0 1 1.06 0z"/></svg>`,
        chevronDown: `<svg viewBox="0 0 16 16"><path d="M3.2 5.2a.75.75 0 0 1 1.06 0L8 8.94l3.74-3.74a.75.75 0 1 1 1.06 1.06l-4.27 4.27a.75.75 0 0 1-1.06 0L3.2 6.26a.75.75 0 0 1 0-1.06z"/></svg>`,
        chevronRight: `<svg viewBox="0 0 16 16"><path d="M5.2 3.2a.75.75 0 0 1 1.06 0l4.27 4.27a.75.75 0 0 1 0 1.06l-4.27 4.27a.75.75 0 0 1-1.06-1.06L8.94 8 5.2 4.26a.75.75 0 0 1 0-1.06z"/></svg>`,
        theme: `<svg viewBox="0 0 16 16"><path d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zm0 1.5a5.5 5.5 0 1 1 0 11 5.5 5.5 0 0 1 0-11zm-.75 2v4c0 .2.08.39.22.53l2.5 2.5 1.06-1.06-2.28-2.28V4.5H7.25z"/></svg>`,
        font: `<svg viewBox="0 0 16 16"><path d="M3.5 13h1.8l1.1-3h3.2l1.1 3h1.8L8.8 2.5H7.2L3.5 13zm3.4-4.5l1.1-3.2 1.1 3.2H6.9z"/></svg>`,
        wordWrap: `<svg viewBox="0 0 16 16"><path d="M2 3.5h12v1.5H2V3.5zm0 4h9a2.5 2.5 0 1 1 0 5H8.5v-1.5H11a1 1 0 1 0 0-2H2V7.5zm0 4h4.5V13H2v-1.5z"/><path d="M8 10.5l-2.5 2L8 14.5v-4z"/></svg>`,
        formatting: `<svg viewBox="0 0 16 16"><path d="M12.8 1.2a1 1 0 0 0-1.4 0L7.5 5.1 10.9 8.5l3.9-3.9a1 1 0 0 0 0-1.4l-2-2zM6.8 5.8L2.2 10.4c-.2.2-.3.5-.3.8v2.3c0 .3.2.5.5.5h2.3c.3 0 .6-.1.8-.3l4.6-4.6-3.2-3.3z"/></svg>`,
        openFiles: `<svg viewBox="0 0 16 16"><path d="M3 2a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V9.5h-1.5V12a.5.5 0 0 1-.5.5H3a.5.5 0 0 1-.5-.5V4a.5.5 0 0 1 .5-.5h2.5V2H3zm7 0v1.5h2.44L6.72 9.22l1.06 1.06L13.5 4.56V7H15V2h-5z"/></svg>`,
        tabsApp: `<svg viewBox="0 0 16 16"><path d="M2 3a1 1 0 0 0-1 1v8a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1H2zm0 1.5h12v1H2v-1zm0 2.5h12v6H2V7z"/></svg>`,
        recentFiles: `<svg viewBox="0 0 16 16"><path d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zm0 1.5a5.5 5.5 0 1 1 0 11 5.5 5.5 0 0 1 0-11zm-.75 2v4c0 .2.08.39.22.53l2.5 2.5 1.06-1.06-2.28-2.28V4.5H7.25z"/></svg>`,
        spellCheck: `<svg viewBox="0 0 16 16"><path d="M2.5 9h1.1l.6-1.8h2l.6 1.8h1.1L5.6 2.5H4.3L2.5 9zm2-2.7l.7-2.1.7 2.1h-1.4zm6.2 2.7h1.6c1.1 0 1.8-.7 1.8-1.7 0-.6-.3-1.1-.9-1.3.4-.2.7-.6.7-1.2 0-.9-.7-1.6-1.7-1.6h-1.5V9zm1-5.6h.6c.4 0 .7.3.7.7s-.3.7-.7.7h-.6V3.4zm0 2.3h.7c.5 0 .8.3.8.8s-.3.8-.8.8h-.7V5.7zM10.8 11.2l-2.6 2.6-1.1-1.1-.7.7 1.8 1.8 3.3-3.3-.7-.7z"/></svg>`,
        search: `<svg viewBox="0 0 16 16"><path d="M11.74 10.68a6 6 0 1 0-1.06 1.06l3.47 3.47a.75.75 0 0 0 1.06-1.06l-3.47-3.47zM11 6.5a4.5 4.5 0 1 1-9 0 4.5 4.5 0 0 1 9 0z"/></svg>`,
        arrowUp: `<svg viewBox="0 0 16 16"><path d="M8 3.2l4.27 4.27a.75.75 0 0 1-1.06 1.06L8 5.31 4.79 8.53a.75.75 0 1 1-1.06-1.06L8 3.2z"/></svg>`,
        arrowDown: `<svg viewBox="0 0 16 16"><path d="M8 12.8L3.73 8.53a.75.75 0 0 1 1.06-1.06L8 10.69l3.21-3.22a.75.75 0 1 1 1.06 1.06L8 12.8z"/></svg>`,
        caseSensitive: `<svg viewBox="0 0 16 16"><path d="M3.2 11.5h1.3l.8-2.2h2.4l.8 2.2h1.3L6.8 3.5H5.2L3.2 11.5zm2.5-3.3l.8-2.3.8 2.3H5.7zm6.8 3.3h1.2v-4.5c0-.9-.6-1.5-1.5-1.5s-1.5.6-1.5 1.5v4.5h1.2v-1.1c.2.4.6.6 1 .6.7 0 1.1-.4 1.1-1.1v-2.4h-1.5v2.4c0 .3.2.5.5.5s.5-.2.5-.5V8.5h-1.2V7c0-.3.2-.5.5-.5s.5.2.5.5v4.5z"/></svg>`,
        wrapAround: `<svg viewBox="0 0 16 16"><path d="M2.5 8.5a5.5 5.5 0 1 0 1.6-3.9H2V3h4v4H4.5V5.5a4 4 0 1 1-1.2 2.8H2v.2z"/></svg>`
    };
    // --- Default State Definition ---
    const DEFAULT_SETTINGS = {
        theme: 'dark',
        fontFamily: 'Consolas',
        fontStyle: 'Regular',
        fontSize: '11',
        wordWrap: true,
        formatting: true,
        openingFiles: 'newTab',
        startupOption: 'continueSession',
        recentFilesEnabled: false,
        spellCheck: true,
        showStatusBar: true,
        zoom: 100
    };
    class NotepadApp {
        container;
        settings;
        tabs;
        activeTabId;
        nextTabId;
        activeMenu;
        findReplaceState;
        dialogResolve;
        dom;
        constructor(container) {
            ensureStylesInjected();
            this.container = container || document.getElementById('notepad-root') || document.body;
            this.settings = this.loadSettings();
            this.tabs = [];
            this.activeTabId = null;
            this.nextTabId = 1;
            this.activeMenu = null;
            this.findReplaceState = {
                isOpen: false,
                isReplaceOpen: false,
                query: '',
                replaceQuery: '',
                matchCase: false,
                wrapAround: true,
                matches: [],
                currentIndex: -1
            };
            this.dialogResolve = null;
            this.init();
        }
        // --- Settings & Persistence ---
        loadSettings() {
            try {
                const saved = localStorage.getItem('win11_notepad_settings');
                return saved ? Object.assign({}, DEFAULT_SETTINGS, JSON.parse(saved)) : Object.assign({}, DEFAULT_SETTINGS);
            }
            catch (e) {
                return Object.assign({}, DEFAULT_SETTINGS);
            }
        }
        saveSettings() {
            try {
                localStorage.setItem('win11_notepad_settings', JSON.stringify(this.settings));
            }
            catch (e) { }
        }
        loadSavedSession() {
            if (this.settings.startupOption === 'continueSession') {
                try {
                    const saved = localStorage.getItem('win11_notepad_session');
                    if (saved) {
                        const data = JSON.parse(saved);
                        if (Array.isArray(data.tabs) && data.tabs.length > 0) {
                            this.tabs = data.tabs;
                            this.nextTabId = data.nextTabId || (this.tabs.length + 1);
                            this.activeTabId = data.activeTabId || this.tabs[0].id;
                            return;
                        }
                    }
                }
                catch (e) { }
            }
            // Default: Clean initial tab named 'Untitled' with empty content
            this.tabs = [{
                    id: this.nextTabId++,
                    title: 'Untitled',
                    content: '',
                    isModified: false,
                    filePath: null,
                    encoding: 'UTF-8',
                    lineEnding: 'Unix (LF)',
                    cursorLine: 1,
                    cursorCol: 1,
                    isMarkdown: false
                }];
            this.activeTabId = this.tabs[0].id;
        }
        saveSession() {
            if (this.settings.startupOption === 'continueSession') {
                try {
                    const data = {
                        tabs: this.tabs,
                        nextTabId: this.nextTabId,
                        activeTabId: this.activeTabId
                    };
                    localStorage.setItem('win11_notepad_session', JSON.stringify(data));
                }
                catch (e) { }
            }
        }
        // --- DOM Construction ---
        init() {
            this.loadSavedSession();
            this.applyTheme();
            this.renderAppSkeleton();
            this.attachGlobalEvents();
            this.renderTabs();
            this.updateActiveTabContent();
            this.updateStatusBar();
            this.applyEditorStyles();
        }
        applyTheme() {
            let theme = this.settings.theme;
            if (theme === 'system') {
                theme = window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark';
            }
            document.documentElement.setAttribute('data-theme', theme);
        }
        renderAppSkeleton() {
            this.container.innerHTML = `
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
            <button class="menu-action-btn" id="btn-whats-new" title="What's new">
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
              class="editor-textarea ${this.settings.wordWrap ? 'wrap' : 'nowrap'}"
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
                    <div class="fluent-toggle-wrapper ${this.settings.wordWrap ? 'on' : ''}" id="toggle-setting-wordwrap">
                      <div class="toggle-switch"><div class="toggle-knob"></div></div>
                      <span class="toggle-label">${this.settings.wordWrap ? 'On' : 'Off'}</span>
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
                    <div class="fluent-toggle-wrapper ${this.settings.formatting ? 'on' : ''}" id="toggle-setting-formatting">
                      <div class="toggle-switch"><div class="toggle-knob"></div></div>
                      <span class="toggle-label">${this.settings.formatting ? 'On' : 'Off'}</span>
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
                      <div class="fluent-radio-option ${this.settings.startupOption === 'continueSession' ? 'selected' : ''}" data-value="continueSession" id="radio-startup-continue">
                        <div class="radio-circle"><div class="radio-dot"></div></div>
                        <span>Continue previous session</span>
                      </div>
                      <div class="fluent-radio-option ${this.settings.startupOption === 'newSession' ? 'selected' : ''}" data-value="newSession" id="radio-startup-new">
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
                    <div class="fluent-toggle-wrapper ${this.settings.recentFilesEnabled ? 'on' : ''}" id="toggle-setting-recent-files">
                      <div class="toggle-switch"><div class="toggle-knob"></div></div>
                      <span class="toggle-label">${this.settings.recentFilesEnabled ? 'On' : 'Off'}</span>
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
                    <div class="fluent-toggle-wrapper ${this.settings.spellCheck ? 'on' : ''}" id="toggle-setting-spellcheck">
                      <div class="toggle-switch"><div class="toggle-knob"></div></div>
                      <span class="toggle-label">${this.settings.spellCheck ? 'On' : 'Off'}</span>
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
      `;
            // Cache elements
            this.dom = {
                editor: document.getElementById('editor-area'),
                tabsContainer: document.getElementById('tabs-container'),
                btnAddTab: document.getElementById('btn-add-tab'),
                flyoutFile: document.getElementById('flyout-file'),
                flyoutEdit: document.getElementById('flyout-edit'),
                flyoutView: document.getElementById('flyout-view'),
                menuBtnFile: document.getElementById('menu-btn-file'),
                menuBtnEdit: document.getElementById('menu-btn-edit'),
                menuBtnView: document.getElementById('menu-btn-view'),
                btnSettingsToggle: document.getElementById('btn-settings-toggle'),
                settingsView: document.getElementById('settings-view'),
                settingsBtnBack: document.getElementById('settings-btn-back'),
                statusBar: document.getElementById('notepad-statusbar'),
                sbCursorPos: document.getElementById('sb-cursor-pos'),
                sbCharCount: document.getElementById('sb-char-count'),
                sbDocType: document.getElementById('sb-doc-type'),
                sbZoomLevel: document.getElementById('sb-zoom-level'),
                sbLineEnding: document.getElementById('sb-line-ending'),
                sbEncoding: document.getElementById('sb-encoding'),
                checkStatusBar: document.getElementById('check-status-bar'),
                checkWordWrap: document.getElementById('check-word-wrap'),
                findReplacePanel: document.getElementById('find-replace-panel'),
                findQueryInput: document.getElementById('find-query-input'),
                replaceQueryInput: document.getElementById('replace-query-input'),
                replaceRow: document.getElementById('replace-row-container'),
                findMatchCounter: document.getElementById('find-match-counter'),
                findBtnPrev: document.getElementById('find-btn-prev'),
                findBtnNext: document.getElementById('find-btn-next'),
                findBtnCase: document.getElementById('find-btn-case'),
                findBtnWrap: document.getElementById('find-btn-wrap'),
                findBtnToggleReplace: document.getElementById('find-btn-toggle-replace'),
                findBtnClose: document.getElementById('find-btn-close'),
                btnDoReplace: document.getElementById('btn-do-replace'),
                btnDoReplaceAll: document.getElementById('btn-do-replace-all'),
                modalOverlay: document.getElementById('notepad-modal'),
                dialogTitle: document.getElementById('dialog-title-text'),
                dialogMessage: document.getElementById('dialog-message-text'),
                dialogCustomBody: document.getElementById('dialog-custom-body'),
                dialogButtons: document.getElementById('dialog-btn-container'),
                hiddenFileInput: document.getElementById('hidden-file-input')
            };
            this.syncSettingsUI();
        }
        // --- Tab Management ---
        getActiveTab() {
            return this.tabs.find(t => t.id === this.activeTabId) || null;
        }
        renderTabs() {
            this.dom.tabsContainer.innerHTML = '';
            this.tabs.forEach(tab => {
                const tabEl = document.createElement('div');
                tabEl.className = `notepad-tab ${tab.id === this.activeTabId ? 'active' : ''} ${tab.isModified ? 'unsaved' : ''}`;
                tabEl.dataset.tabId = String(tab.id);
                tabEl.title = tab.filePath || tab.title;
                tabEl.innerHTML = `
          <span class="tab-title">${this.escapeHTML(tab.title)}</span>
          <div class="tab-indicator-container">
            <span class="tab-dot" title="Unsaved changes"></span>
            <button class="tab-close-btn" title="Close tab (Ctrl+W)">${ICONS.close}</button>
          </div>
        `;
                tabEl.addEventListener('click', (e) => {
                    if (e.target.closest('.tab-close-btn')) {
                        e.stopPropagation();
                        this.promptCloseTab(tab.id);
                    }
                    else {
                        this.switchTab(tab.id);
                    }
                });
                this.dom.tabsContainer.appendChild(tabEl);
            });
        }
        createNewTab(title = 'Untitled', content = '', filePath = null, isMarkdown = false) {
            const newTab = {
                id: this.nextTabId++,
                title: title,
                content: content,
                isModified: false,
                filePath: filePath,
                encoding: 'UTF-8',
                lineEnding: content.includes('\r\n') ? 'Windows (CRLF)' : 'Unix (LF)',
                cursorLine: 1,
                cursorCol: 1,
                isMarkdown: isMarkdown
            };
            this.tabs.push(newTab);
            this.switchTab(newTab.id);
            this.saveSession();
        }
        switchTab(tabId) {
            if (this.activeTabId) {
                const prevTab = this.getActiveTab();
                if (prevTab) {
                    prevTab.content = this.dom.editor.value;
                    prevTab.cursorLine = this.calculateCursorLineCol().line;
                    prevTab.cursorCol = this.calculateCursorLineCol().col;
                }
            }
            this.activeTabId = tabId;
            const curTab = this.getActiveTab();
            if (curTab) {
                this.dom.editor.value = curTab.content;
            }
            this.renderTabs();
            this.updateStatusBar();
            this.dom.editor.focus();
            this.saveSession();
        }
        promptCloseTab(tabId) {
            const tab = this.tabs.find(t => t.id === tabId);
            if (!tab)
                return;
            if (tab.isModified) {
                this.showModal({
                    title: 'Notepad',
                    message: `Do you want to save changes to ${tab.title}?`,
                    buttons: [
                        { text: 'Save', primary: true, action: async () => {
                                await this.saveTab(tab);
                                this.closeTab(tabId);
                            }
                        },
                        { text: "Don't Save", action: () => this.closeTab(tabId) },
                        { text: 'Cancel', action: () => { } }
                    ]
                });
            }
            else {
                this.closeTab(tabId);
            }
        }
        closeTab(tabId) {
            const idx = this.tabs.findIndex(t => t.id === tabId);
            if (idx === -1)
                return;
            this.tabs.splice(idx, 1);
            if (this.tabs.length === 0) {
                this.createNewTab('Untitled', '');
            }
            else if (this.activeTabId === tabId) {
                const newIdx = Math.max(0, idx - 1);
                this.switchTab(this.tabs[newIdx].id);
            }
            else {
                this.renderTabs();
            }
            this.saveSession();
        }
        // --- File Operations ---
        async openFileDialog() {
            if (window.showOpenFilePicker) {
                try {
                    const [fileHandle] = await window.showOpenFilePicker({
                        types: [
                            {
                                description: 'Text Files',
                                accept: {
                                    'text/*': ['.txt', '.md', '.json', '.js', '.html', '.css', '.xml', '.py', '.gitignore', '.c', '.cpp', '.h']
                                }
                            }
                        ],
                        multiple: false
                    });
                    const file = await fileHandle.getFile();
                    const content = await file.text();
                    this.createNewTab(file.name, content, file.name);
                    return;
                }
                catch (err) {
                    if (err.name === 'AbortError')
                        return;
                }
            }
            // Fallback: standard input[type=file]
            this.dom.hiddenFileInput.onchange = (e) => {
                const file = e.target.files?.[0];
                if (!file)
                    return;
                const reader = new FileReader();
                reader.onload = (event) => {
                    this.createNewTab(file.name, String(event.target?.result ?? ''), file.name);
                    this.dom.hiddenFileInput.value = '';
                };
                reader.readAsText(file);
            };
            this.dom.hiddenFileInput.click();
        }
        async saveTab(tab, forceSaveAs = false) {
            if (!tab)
                return;
            tab.content = this.dom.editor.value;
            if (!forceSaveAs && tab.fileHandle && tab.fileHandle.createWritable) {
                try {
                    const writable = await tab.fileHandle.createWritable();
                    await writable.write(tab.content);
                    await writable.close();
                    tab.isModified = false;
                    this.renderTabs();
                    this.saveSession();
                    return;
                }
                catch (e) { }
            }
            if (window.showSaveFilePicker) {
                try {
                    const handle = await window.showSaveFilePicker({
                        suggestedName: tab.title.endsWith('.txt') || tab.title.includes('.') ? tab.title : `${tab.title}.txt`,
                        types: [
                            {
                                description: 'Text Documents (*.txt)',
                                accept: { 'text/plain': ['.txt'] }
                            },
                            {
                                description: 'All Files (*.*)',
                                accept: { '*/*': ['.*'] }
                            }
                        ]
                    });
                    const writable = await handle.createWritable();
                    await writable.write(tab.content);
                    await writable.close();
                    tab.title = handle.name;
                    tab.fileHandle = handle;
                    tab.isModified = false;
                    this.renderTabs();
                    this.saveSession();
                    return;
                }
                catch (err) {
                    if (err.name === 'AbortError')
                        return;
                }
            }
            // Fallback: browser blob download
            const blob = new Blob([tab.content], { type: 'text/plain;charset=utf-8' });
            const a = document.createElement('a');
            a.href = URL.createObjectURL(blob);
            a.download = tab.title.includes('.') ? tab.title : `${tab.title}.txt`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(a.href);
            tab.isModified = false;
            this.renderTabs();
            this.saveSession();
        }
        saveAllTabs() {
            this.tabs.forEach(tab => {
                if (tab.isModified)
                    this.saveTab(tab);
            });
        }
        // --- Status Bar & Editor Metrics ---
        calculateCursorLineCol() {
            const textarea = this.dom.editor;
            const pos = textarea.selectionStart || 0;
            const text = textarea.value.substring(0, pos);
            const lines = text.split('\n');
            const line = lines.length;
            const col = lines[lines.length - 1].length + 1;
            return { line, col };
        }
        updateStatusBar() {
            const activeTab = this.getActiveTab();
            if (!activeTab)
                return;
            const { line, col } = this.calculateCursorLineCol();
            const textarea = this.dom.editor;
            const selStart = textarea.selectionStart;
            const selEnd = textarea.selectionEnd;
            const selLength = Math.abs(selEnd - selStart);
            this.dom.sbCursorPos.textContent = `Ln ${line}, Col ${col}`;
            if (selLength > 0) {
                this.dom.sbCharCount.textContent = `${selLength} selected`;
            }
            else {
                this.dom.sbCharCount.textContent = `${textarea.value.length} characters`;
            }
            this.dom.sbDocType.textContent = activeTab.isMarkdown ? 'Markdown' : 'Plain text';
            this.dom.sbZoomLevel.textContent = `${this.settings.zoom}%`;
            this.dom.sbLineEnding.textContent = activeTab.lineEnding;
            this.dom.sbEncoding.textContent = activeTab.encoding;
            // Status bar visibility
            this.dom.statusBar.style.display = this.settings.showStatusBar ? 'flex' : 'none';
            this.dom.checkStatusBar.style.visibility = this.settings.showStatusBar ? 'visible' : 'hidden';
            this.dom.checkWordWrap.style.visibility = this.settings.wordWrap ? 'visible' : 'hidden';
        }
        applyEditorStyles() {
            const editor = this.dom.editor;
            editor.style.fontFamily = `"${this.settings.fontFamily}", monospace`;
            editor.style.fontSize = `${parseInt(this.settings.fontSize) * (this.settings.zoom / 100)}pt`;
            if (this.settings.fontStyle.includes('Bold')) {
                editor.style.fontWeight = '700';
            }
            else {
                editor.style.fontWeight = '400';
            }
            if (this.settings.fontStyle.includes('Italic')) {
                editor.style.fontStyle = 'italic';
            }
            else {
                editor.style.fontStyle = 'normal';
            }
            if (this.settings.wordWrap) {
                editor.className = 'editor-textarea wrap';
            }
            else {
                editor.className = 'editor-textarea nowrap';
            }
            // Update sample preview in Settings
            const preview = document.getElementById('font-sample-preview');
            if (preview) {
                preview.style.fontFamily = `"${this.settings.fontFamily}", monospace`;
                preview.style.fontSize = `${this.settings.fontSize}pt`;
                preview.style.fontWeight = this.settings.fontStyle.includes('Bold') ? '700' : '400';
                preview.style.fontStyle = this.settings.fontStyle.includes('Italic') ? 'italic' : 'normal';
            }
        }
        updateActiveTabContent() {
            const activeTab = this.getActiveTab();
            if (activeTab) {
                this.dom.editor.value = activeTab.content;
            }
        }
        // --- Find and Replace System ---
        openFind(showReplace = false) {
            this.closeMenus();
            this.findReplaceState.isOpen = true;
            this.findReplaceState.isReplaceOpen = showReplace;
            this.dom.findReplacePanel.classList.add('open');
            this.dom.replaceRow.style.display = showReplace ? 'flex' : 'none';
            // Prepopulate with selected text if available
            const selText = this.dom.editor.value.substring(this.dom.editor.selectionStart, this.dom.editor.selectionEnd);
            if (selText && !selText.includes('\n')) {
                this.dom.findQueryInput.value = selText;
                this.findReplaceState.query = selText;
            }
            this.executeFind();
            this.dom.findQueryInput.focus();
            this.dom.findQueryInput.select();
        }
        closeFind() {
            this.findReplaceState.isOpen = false;
            this.dom.findReplacePanel.classList.remove('open');
            this.dom.editor.focus();
        }
        executeFind() {
            const query = this.dom.findQueryInput.value;
            this.findReplaceState.query = query;
            const text = this.dom.editor.value;
            if (!query) {
                this.findReplaceState.matches = [];
                this.findReplaceState.currentIndex = -1;
                this.dom.findMatchCounter.textContent = '0 of 0';
                return;
            }
            const flags = this.findReplaceState.matchCase ? 'g' : 'gi';
            const escaped = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            const regex = new RegExp(escaped, flags);
            const matches = [];
            let match;
            while ((match = regex.exec(text)) !== null) {
                matches.push({ start: match.index, end: match.index + query.length });
                if (regex.lastIndex === match.index)
                    regex.lastIndex++;
            }
            this.findReplaceState.matches = matches;
            if (matches.length > 0) {
                const curPos = this.dom.editor.selectionStart;
                let bestIdx = matches.findIndex(m => m.start >= curPos);
                if (bestIdx === -1)
                    bestIdx = 0;
                this.findReplaceState.currentIndex = bestIdx;
                this.selectMatch(bestIdx);
            }
            else {
                this.findReplaceState.currentIndex = -1;
                this.dom.findMatchCounter.textContent = 'No results';
            }
        }
        selectMatch(index) {
            const matches = this.findReplaceState.matches;
            if (!matches || matches.length === 0 || index < 0 || index >= matches.length) {
                this.dom.findMatchCounter.textContent = '0 of 0';
                return;
            }
            this.findReplaceState.currentIndex = index;
            const match = matches[index];
            this.dom.editor.setSelectionRange(match.start, match.end);
            this.dom.findMatchCounter.textContent = `${index + 1} of ${matches.length}`;
            this.updateStatusBar();
        }
        findNext() {
            if (this.findReplaceState.matches.length === 0) {
                this.executeFind();
                return;
            }
            let next = this.findReplaceState.currentIndex + 1;
            if (next >= this.findReplaceState.matches.length) {
                if (this.findReplaceState.wrapAround)
                    next = 0;
                else
                    return;
            }
            this.selectMatch(next);
        }
        findPrev() {
            if (this.findReplaceState.matches.length === 0) {
                this.executeFind();
                return;
            }
            let prev = this.findReplaceState.currentIndex - 1;
            if (prev < 0) {
                if (this.findReplaceState.wrapAround)
                    prev = this.findReplaceState.matches.length - 1;
                else
                    return;
            }
            this.selectMatch(prev);
        }
        replaceCurrent() {
            if (this.findReplaceState.matches.length === 0 || this.findReplaceState.currentIndex === -1)
                return;
            const replaceWith = this.dom.replaceQueryInput.value;
            const match = this.findReplaceState.matches[this.findReplaceState.currentIndex];
            const textarea = this.dom.editor;
            const val = textarea.value;
            textarea.value = val.substring(0, match.start) + replaceWith + val.substring(match.end);
            const activeTab = this.getActiveTab();
            if (activeTab) {
                activeTab.content = textarea.value;
                activeTab.isModified = true;
            }
            this.renderTabs();
            this.executeFind();
        }
        replaceAll() {
            const query = this.dom.findQueryInput.value;
            if (!query)
                return;
            const replaceWith = this.dom.replaceQueryInput.value;
            const flags = this.findReplaceState.matchCase ? 'g' : 'gi';
            const escaped = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            const regex = new RegExp(escaped, flags);
            const textarea = this.dom.editor;
            textarea.value = textarea.value.replace(regex, replaceWith);
            const activeTab = this.getActiveTab();
            if (activeTab) {
                activeTab.content = textarea.value;
                activeTab.isModified = true;
            }
            this.renderTabs();
            this.executeFind();
        }
        // --- Go To Line Dialog ---
        showGoToDialog() {
            this.closeMenus();
            const current = this.calculateCursorLineCol().line;
            this.showModal({
                title: 'Go to line',
                message: 'Line number:',
                hasInput: true,
                inputValue: current.toString(),
                buttons: [
                    {
                        text: 'Go to',
                        primary: true,
                        action: (lineVal) => {
                            const lineNum = parseInt(lineVal ?? '', 10);
                            if (!isNaN(lineNum) && lineNum > 0) {
                                const lines = this.dom.editor.value.split('\n');
                                let targetPos = 0;
                                for (let i = 0; i < Math.min(lineNum - 1, lines.length); i++) {
                                    targetPos += lines[i].length + 1;
                                }
                                this.dom.editor.setSelectionRange(targetPos, targetPos);
                                this.dom.editor.focus();
                                this.updateStatusBar();
                            }
                        }
                    },
                    { text: 'Cancel', action: () => { } }
                ]
            });
        }
        // --- Modal Dialog System ---
        showModal({ title, message, hasInput = false, inputValue = '', buttons = [] }) {
            this.dom.dialogTitle.textContent = title;
            this.dom.dialogMessage.textContent = message;
            this.dom.dialogCustomBody.innerHTML = '';
            let inputEl = null;
            if (hasInput) {
                inputEl = document.createElement('input');
                inputEl.className = 'dialog-input';
                inputEl.type = 'text';
                inputEl.value = inputValue;
                this.dom.dialogCustomBody.appendChild(inputEl);
            }
            this.dom.dialogButtons.innerHTML = '';
            buttons.forEach(btnConfig => {
                const btn = document.createElement('button');
                btn.className = `fluent-btn ${btnConfig.primary ? 'primary' : ''}`;
                btn.textContent = btnConfig.text;
                btn.addEventListener('click', () => {
                    this.dom.modalOverlay.classList.remove('open');
                    if (btnConfig.action) {
                        btnConfig.action(inputEl ? inputEl.value : null);
                    }
                });
                this.dom.dialogButtons.appendChild(btn);
            });
            this.dom.modalOverlay.classList.add('open');
            if (inputEl) {
                inputEl.focus();
                inputEl.select();
                inputEl.addEventListener('keydown', (e) => {
                    if (e.key === 'Enter') {
                        const primaryBtn = this.dom.dialogButtons.querySelector('.fluent-btn.primary') || this.dom.dialogButtons.children[0];
                        if (primaryBtn)
                            primaryBtn.click();
                    }
                    else if (e.key === 'Escape') {
                        this.dom.modalOverlay.classList.remove('open');
                    }
                });
            }
        }
        // --- Settings Synchronization & View ---
        openSettings(scrollToSection = null) {
            this.closeMenus();
            this.dom.settingsView.classList.add('open');
            if (scrollToSection) {
                const target = document.getElementById(scrollToSection);
                if (target) {
                    target.classList.add('expanded');
                    target.scrollIntoView({ behavior: 'smooth' });
                }
            }
        }
        closeSettings() {
            this.dom.settingsView.classList.remove('open');
            this.dom.editor.focus();
        }
        syncSettingsUI() {
            // Theme
            const themeSelect = document.getElementById('setting-theme-select');
            if (themeSelect)
                themeSelect.value = this.settings.theme;
            // Font
            const fontFam = document.getElementById('setting-font-family');
            if (fontFam)
                fontFam.value = this.settings.fontFamily;
            const fontStyle = document.getElementById('setting-font-style');
            if (fontStyle)
                fontStyle.value = this.settings.fontStyle;
            const fontSize = document.getElementById('setting-font-size');
            if (fontSize)
                fontSize.value = this.settings.fontSize;
            // Opening files
            const openFiles = document.getElementById('setting-opening-files');
            if (openFiles)
                openFiles.value = this.settings.openingFiles;
            // Toggles
            this.updateToggleState('toggle-setting-wordwrap', this.settings.wordWrap);
            this.updateToggleState('toggle-setting-formatting', this.settings.formatting);
            this.updateToggleState('toggle-setting-recent-files', this.settings.recentFilesEnabled);
            this.updateToggleState('toggle-setting-spellcheck', this.settings.spellCheck);
        }
        updateToggleState(elementId, isChecked) {
            const el = document.getElementById(elementId);
            if (!el)
                return;
            if (isChecked) {
                el.classList.add('on');
                el.querySelector('.toggle-label').textContent = 'On';
            }
            else {
                el.classList.remove('on');
                el.querySelector('.toggle-label').textContent = 'Off';
            }
        }
        // --- Menus Management - Seamless Zero-Gap Positioning ---
        toggleMenu(menuName) {
            if (this.activeMenu === menuName) {
                this.closeMenus();
                return;
            }
            this.closeMenus();
            this.activeMenu = menuName;
            let flyout = null;
            let btn = null;
            if (menuName === 'file') {
                flyout = this.dom.flyoutFile;
                btn = this.dom.menuBtnFile;
            }
            else if (menuName === 'edit') {
                flyout = this.dom.flyoutEdit;
                btn = this.dom.menuBtnEdit;
            }
            else if (menuName === 'view') {
                flyout = this.dom.flyoutView;
                btn = this.dom.menuBtnView;
            }
            if (flyout && btn) {
                btn.classList.add('open');
                flyout.classList.add('open');
                // Align horizontally with menu button and vertically flush with menubar bottom (36px)
                flyout.style.left = `${btn.offsetLeft}px`;
                flyout.style.top = '36px';
            }
        }
        closeMenus() {
            this.activeMenu = null;
            document.querySelectorAll('.menu-item-btn').forEach(b => b.classList.remove('open'));
            document.querySelectorAll('.flyout-menu').forEach(f => f.classList.remove('open'));
        }
        // --- Event Listeners & Dispatchers ---
        attachGlobalEvents() {
            const editor = this.dom.editor;
            // Text input & modification
            editor.addEventListener('input', () => {
                const activeTab = this.getActiveTab();
                if (activeTab) {
                    activeTab.content = editor.value;
                    if (!activeTab.isModified) {
                        activeTab.isModified = true;
                        this.renderTabs();
                    }
                }
                this.updateStatusBar();
                if (this.findReplaceState.isOpen) {
                    this.executeFind();
                }
            });
            // Cursor movement
            ['keyup', 'click', 'select'].forEach(ev => {
                editor.addEventListener(ev, () => this.updateStatusBar());
            });
            // Tab key indent
            editor.addEventListener('keydown', (e) => {
                if (e.key === 'Tab') {
                    e.preventDefault();
                    const start = editor.selectionStart;
                    const end = editor.selectionEnd;
                    editor.value = editor.value.substring(0, start) + '\t' + editor.value.substring(end);
                    editor.selectionStart = editor.selectionEnd = start + 1;
                    const activeTab = this.getActiveTab();
                    if (activeTab) {
                        activeTab.content = editor.value;
                        activeTab.isModified = true;
                        this.renderTabs();
                    }
                    this.updateStatusBar();
                }
            });
            // Window controls
            document.getElementById('btn-win-close').addEventListener('click', () => {
                const hasUnsaved = this.tabs.some(t => t.isModified);
                if (hasUnsaved) {
                    this.showModal({
                        title: 'Notepad',
                        message: 'You have unsaved changes. Do you want to save before closing?',
                        buttons: [
                            { text: 'Save All', primary: true, action: () => { this.saveAllTabs(); window.close(); } },
                            { text: "Don't Save", action: () => window.close() },
                            { text: 'Cancel', action: () => { } }
                        ]
                    });
                }
                else {
                    window.close();
                }
            });
            document.getElementById('btn-win-max').addEventListener('click', () => {
                if (!document.fullscreenElement) {
                    document.documentElement.requestFullscreen().catch(() => { });
                }
                else {
                    document.exitFullscreen().catch(() => { });
                }
            });
            // Tabs Header button
            this.dom.btnAddTab.addEventListener('click', () => this.createNewTab('Untitled', ''));
            // Menu button click & hover navigation
            const menuPairs = [
                { name: 'file', btn: this.dom.menuBtnFile },
                { name: 'edit', btn: this.dom.menuBtnEdit },
                { name: 'view', btn: this.dom.menuBtnView }
            ];
            menuPairs.forEach(({ name, btn }) => {
                btn.addEventListener('click', (e) => {
                    e.stopPropagation();
                    this.toggleMenu(name);
                });
                btn.addEventListener('mouseenter', () => {
                    if (this.activeMenu && this.activeMenu !== name) {
                        this.toggleMenu(name);
                    }
                });
            });
            // Settings toggle
            this.dom.btnSettingsToggle.addEventListener('click', () => this.openSettings());
            this.dom.settingsBtnBack.addEventListener('click', () => this.closeSettings());
            const settingsWinClose = document.getElementById('settings-win-close');
            if (settingsWinClose)
                settingsWinClose.addEventListener('click', () => this.closeSettings());
            // Outside click closes menus
            window.addEventListener('click', (e) => {
                if (!e.target.closest('.notepad-menubar') && !e.target.closest('.flyout-menu')) {
                    this.closeMenus();
                }
            });
            // Menu Actions Dispatcher
            document.querySelectorAll('.menu-row[data-action]').forEach(item => {
                item.addEventListener('click', (e) => {
                    e.stopPropagation();
                    const action = item.dataset.action;
                    this.closeMenus();
                    this.handleAction(action);
                });
            });
            // Status Bar interactive clicks
            this.dom.sbLineEnding.addEventListener('click', () => {
                const tab = this.getActiveTab();
                if (!tab)
                    return;
                if (tab.lineEnding === 'Unix (LF)') {
                    tab.lineEnding = 'Windows (CRLF)';
                    this.dom.editor.value = this.dom.editor.value.replace(/(?<!\r)\n/g, '\r\n');
                }
                else {
                    tab.lineEnding = 'Unix (LF)';
                    this.dom.editor.value = this.dom.editor.value.replace(/\r\n/g, '\n');
                }
                tab.content = this.dom.editor.value;
                tab.isModified = true;
                this.renderTabs();
                this.updateStatusBar();
            });
            this.dom.sbZoomLevel.addEventListener('click', () => {
                this.settings.zoom = 100;
                this.applyEditorStyles();
                this.updateStatusBar();
            });
            // Find & Replace Buttons
            this.dom.findQueryInput.addEventListener('input', () => this.executeFind());
            this.dom.findQueryInput.addEventListener('keydown', (e) => {
                if (e.key === 'Enter') {
                    if (e.shiftKey)
                        this.findPrev();
                    else
                        this.findNext();
                }
                else if (e.key === 'Escape') {
                    this.closeFind();
                }
            });
            this.dom.findBtnNext.addEventListener('click', () => this.findNext());
            this.dom.findBtnPrev.addEventListener('click', () => this.findPrev());
            this.dom.findBtnClose.addEventListener('click', () => this.closeFind());
            this.dom.findBtnToggleReplace.addEventListener('click', () => {
                const willShow = this.dom.replaceRow.style.display === 'none';
                this.dom.replaceRow.style.display = willShow ? 'flex' : 'none';
                if (willShow)
                    this.dom.replaceQueryInput.focus();
            });
            this.dom.findBtnCase.addEventListener('click', () => {
                this.findReplaceState.matchCase = !this.findReplaceState.matchCase;
                this.dom.findBtnCase.classList.toggle('active', this.findReplaceState.matchCase);
                this.executeFind();
            });
            this.dom.findBtnWrap.addEventListener('click', () => {
                this.findReplaceState.wrapAround = !this.findReplaceState.wrapAround;
                this.dom.findBtnWrap.classList.toggle('active', this.findReplaceState.wrapAround);
            });
            this.dom.btnDoReplace.addEventListener('click', () => this.replaceCurrent());
            this.dom.btnDoReplaceAll.addEventListener('click', () => this.replaceAll());
            // Settings Listeners
            document.getElementById('setting-theme-select').addEventListener('change', (e) => {
                this.settings.theme = e.target.value;
                this.applyTheme();
                this.saveSettings();
            });
            const updateFontSettings = () => {
                this.settings.fontFamily = document.getElementById('setting-font-family').value;
                this.settings.fontStyle = document.getElementById('setting-font-style').value;
                this.settings.fontSize = document.getElementById('setting-font-size').value;
                this.applyEditorStyles();
                this.saveSettings();
            };
            document.getElementById('setting-font-family').addEventListener('change', updateFontSettings);
            document.getElementById('setting-font-style').addEventListener('change', updateFontSettings);
            document.getElementById('setting-font-size').addEventListener('change', updateFontSettings);
            document.getElementById('toggle-setting-wordwrap').addEventListener('click', () => {
                this.settings.wordWrap = !this.settings.wordWrap;
                this.updateToggleState('toggle-setting-wordwrap', this.settings.wordWrap);
                this.applyEditorStyles();
                this.updateStatusBar();
                this.saveSettings();
            });
            document.getElementById('toggle-setting-formatting').addEventListener('click', () => {
                this.settings.formatting = !this.settings.formatting;
                this.updateToggleState('toggle-setting-formatting', this.settings.formatting);
                this.saveSettings();
            });
            document.getElementById('setting-opening-files').addEventListener('change', (e) => {
                this.settings.openingFiles = e.target.value;
                this.saveSettings();
            });
            // Accordion card toggles (Default closed, click header or button to toggle)
            const toggleCardAccordion = (cardId) => {
                const card = document.getElementById(cardId);
                if (card)
                    card.classList.toggle('expanded');
            };
            document.getElementById('header-font-setting').addEventListener('click', () => toggleCardAccordion('card-font-setting'));
            document.getElementById('header-startup-setting').addEventListener('click', () => toggleCardAccordion('card-startup-setting'));
            // Startup session radios
            const radioContinue = document.getElementById('radio-startup-continue');
            const radioNew = document.getElementById('radio-startup-new');
            radioContinue.addEventListener('click', (e) => {
                e.stopPropagation();
                this.settings.startupOption = 'continueSession';
                radioContinue.classList.add('selected');
                radioNew.classList.remove('selected');
                this.saveSettings();
            });
            radioNew.addEventListener('click', (e) => {
                e.stopPropagation();
                this.settings.startupOption = 'newSession';
                radioNew.classList.add('selected');
                radioContinue.classList.remove('selected');
                this.saveSettings();
            });
            document.getElementById('toggle-setting-recent-files').addEventListener('click', () => {
                this.settings.recentFilesEnabled = !this.settings.recentFilesEnabled;
                this.updateToggleState('toggle-setting-recent-files', this.settings.recentFilesEnabled);
                this.saveSettings();
            });
            document.getElementById('toggle-setting-spellcheck').addEventListener('click', () => {
                this.settings.spellCheck = !this.settings.spellCheck;
                this.updateToggleState('toggle-setting-spellcheck', this.settings.spellCheck);
                this.dom.editor.spellcheck = this.settings.spellCheck;
                this.saveSettings();
            });
            // Keyboard Shortcuts Router
            window.addEventListener('keydown', (e) => {
                if (e.ctrlKey && !e.altKey) {
                    const key = e.key.toLowerCase();
                    if (key === 'n') {
                        e.preventDefault();
                        if (e.shiftKey)
                            this.handleAction('newWindow');
                        else
                            this.handleAction('newTab');
                    }
                    else if (key === 'o') {
                        e.preventDefault();
                        this.handleAction('openFile');
                    }
                    else if (key === 's') {
                        e.preventDefault();
                        if (e.shiftKey)
                            this.handleAction('saveAs');
                        else
                            this.handleAction('save');
                    }
                    else if (key === 'w') {
                        e.preventDefault();
                        if (e.shiftKey)
                            this.handleAction('closeWindow');
                        else
                            this.handleAction('closeTab');
                    }
                    else if (key === 'f') {
                        e.preventDefault();
                        this.openFind(false);
                    }
                    else if (key === 'h') {
                        e.preventDefault();
                        this.openFind(true);
                    }
                    else if (key === 'g') {
                        e.preventDefault();
                        this.showGoToDialog();
                    }
                    else if (key === 'p') {
                        e.preventDefault();
                        this.handleAction('print');
                    }
                    else if (key === '=' || key === '+') {
                        e.preventDefault();
                        this.handleAction('zoomIn');
                    }
                    else if (key === '-') {
                        e.preventDefault();
                        this.handleAction('zoomOut');
                    }
                    else if (key === '0') {
                        e.preventDefault();
                        this.handleAction('zoomReset');
                    }
                }
                else if (e.ctrlKey && e.altKey && e.key.toLowerCase() === 's') {
                    e.preventDefault();
                    this.handleAction('saveAll');
                }
                else if (e.key === 'F3') {
                    e.preventDefault();
                    if (e.shiftKey)
                        this.findPrev();
                    else
                        this.findNext();
                }
                else if (e.key === 'F5') {
                    e.preventDefault();
                    this.handleAction('timeDate');
                }
                else if (e.key === 'Escape') {
                    if (this.findReplaceState.isOpen)
                        this.closeFind();
                    if (this.dom.modalOverlay.classList.contains('open'))
                        this.dom.modalOverlay.classList.remove('open');
                    this.closeMenus();
                }
            });
        }
        // --- Central Action Handler ---
        handleAction(action) {
            const activeTab = this.getActiveTab();
            const editor = this.dom.editor;
            switch (action) {
                case 'newTab':
                    this.createNewTab('Untitled', '');
                    break;
                case 'newWindow':
                    window.open(window.location.href, '_blank');
                    break;
                case 'newMarkdownTab':
                    this.createNewTab('Untitled.md', '# Markdown Document\n\nWrite here...', null, true);
                    break;
                case 'openFile':
                    this.openFileDialog();
                    break;
                case 'save':
                    this.saveTab(activeTab, false);
                    break;
                case 'saveAs':
                    this.saveTab(activeTab, true);
                    break;
                case 'saveAll':
                    this.saveAllTabs();
                    break;
                case 'pageSetup':
                case 'print':
                    window.print();
                    break;
                case 'closeTab':
                    if (activeTab)
                        this.promptCloseTab(activeTab.id);
                    break;
                case 'closeWindow':
                case 'exit':
                    window.close();
                    break;
                case 'undo':
                    document.execCommand('undo');
                    break;
                case 'cut':
                    document.execCommand('cut');
                    break;
                case 'copy':
                    document.execCommand('copy');
                    break;
                case 'paste':
                    navigator.clipboard.readText().then(clip => {
                        const start = editor.selectionStart;
                        const end = editor.selectionEnd;
                        editor.value = editor.value.substring(0, start) + clip + editor.value.substring(end);
                        editor.selectionStart = editor.selectionEnd = start + clip.length;
                        if (activeTab) {
                            activeTab.content = editor.value;
                            activeTab.isModified = true;
                        }
                        this.renderTabs();
                        this.updateStatusBar();
                    }).catch(() => {
                        document.execCommand('paste');
                    });
                    break;
                case 'delete':
                    const start = editor.selectionStart;
                    const end = editor.selectionEnd;
                    if (start === end) {
                        editor.value = editor.value.substring(0, start) + editor.value.substring(start + 1);
                    }
                    else {
                        editor.value = editor.value.substring(0, start) + editor.value.substring(end);
                    }
                    editor.selectionStart = editor.selectionEnd = start;
                    if (activeTab) {
                        activeTab.content = editor.value;
                        activeTab.isModified = true;
                    }
                    this.renderTabs();
                    this.updateStatusBar();
                    break;
                case 'clearFormatting':
                    break;
                case 'find':
                    this.openFind(false);
                    break;
                case 'findNext':
                    this.findNext();
                    break;
                case 'findPrevious':
                    this.findPrev();
                    break;
                case 'replace':
                    this.openFind(true);
                    break;
                case 'goTo':
                    this.showGoToDialog();
                    break;
                case 'selectAll':
                    editor.select();
                    break;
                case 'timeDate':
                    const now = new Date();
                    const timeStr = now.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
                    const dateStr = `${now.getMonth() + 1}/${now.getDate()}/${now.getFullYear()}`;
                    const stamp = `${timeStr} ${dateStr}`;
                    const cPos = editor.selectionStart;
                    editor.value = editor.value.substring(0, cPos) + stamp + editor.value.substring(editor.selectionEnd);
                    editor.selectionStart = editor.selectionEnd = cPos + stamp.length;
                    if (activeTab) {
                        activeTab.content = editor.value;
                        activeTab.isModified = true;
                    }
                    this.renderTabs();
                    this.updateStatusBar();
                    break;
                case 'openFontSettings':
                    this.openSettings('card-font-setting');
                    break;
                case 'zoomIn':
                    if (this.settings.zoom < 500) {
                        this.settings.zoom += 10;
                        this.applyEditorStyles();
                        this.updateStatusBar();
                    }
                    break;
                case 'zoomOut':
                    if (this.settings.zoom > 20) {
                        this.settings.zoom -= 10;
                        this.applyEditorStyles();
                        this.updateStatusBar();
                    }
                    break;
                case 'zoomReset':
                    this.settings.zoom = 100;
                    this.applyEditorStyles();
                    this.updateStatusBar();
                    break;
                case 'toggleStatusBar':
                    this.settings.showStatusBar = !this.settings.showStatusBar;
                    this.saveSettings();
                    this.updateStatusBar();
                    break;
                case 'toggleWordWrap':
                    this.settings.wordWrap = !this.settings.wordWrap;
                    this.saveSettings();
                    this.applyEditorStyles();
                    this.updateStatusBar();
                    this.updateToggleState('toggle-setting-wordwrap', this.settings.wordWrap);
                    break;
                case 'toggleMarkdownPreview':
                    this.showMarkdownPreview();
                    break;
            }
        }
        showMarkdownPreview() {
            const activeTab = this.getActiveTab();
            if (!activeTab)
                return;
            const html = this.simpleMarkdownToHtml(activeTab.content);
            this.showModal({
                title: `Markdown Preview: ${activeTab.title}`,
                message: '',
                buttons: [{ text: 'Close', primary: true, action: () => { } }]
            });
            const body = document.getElementById('dialog-custom-body');
            body.innerHTML = `<div style="max-height: 380px; overflow-y: auto; padding: 12px; background: rgba(0,0,0,0.2); border-radius: 6px; user-select: text;">${html}</div>`;
        }
        simpleMarkdownToHtml(md) {
            return md
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/^# (.*$)/gim, '<h1>$1</h1>')
                .replace(/^## (.*$)/gim, '<h2>$1</h2>')
                .replace(/^### (.*$)/gim, '<h3>$1</h3>')
                .replace(/\*\*(.*?)\*\*/gim, '<strong>$1</strong>')
                .replace(/\*(.*?)\*/gim, '<em>$1</em>')
                .replace(/`([^`]+)`/gim, '<code style="background: rgba(255,255,255,0.1); padding: 2px 4px; border-radius: 3px;">$1</code>')
                .replace(/\n/gim, '<br>');
        }
        escapeHTML(str) {
            return str.replace(/[&<>'"]/g, tag => ({
                '&': '&amp;',
                '<': '&lt;',
                '>': '&gt;',
                "'": '&#39;',
                '"': '&quot;'
            }[tag] || tag));
        }
    }
    // Auto-initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => new NotepadApp());
    }
    else {
        new NotepadApp();
    }
    // Export for modular usage
    window.NotepadApp = NotepadApp;
})();
//# sourceMappingURL=notepad.compiled.js.map