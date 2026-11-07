"use strict";
/**
 * Windows 11 Notepad - High-Performance Semantic Web Implementation
 * Version: 11.2606.15.0
 * Self-Contained JavaScript Architecture with Integrated Fluent Stylesheet
 * Pure Vanilla JavaScript | Zero Third-Party Dependencies | Zero Bing/AI Integrations
 */
globalThis.__npTrace("267:105005:CallExpression", (function () {
    globalThis.__npTrace("284:296:StringLiteral", 'use strict');
    const window = globalThis.__npTrace("1927:1974:AsExpression", globalThis.__npTrace("1927:1944:PropertyAccessExpression", globalThis.__npTrace("1927:1937:Identifier", globalThis).window));
    const document = globalThis.__npTrace("1995:2064:AsExpression", globalThis.__npTrace("1995:2014:PropertyAccessExpression", globalThis.__npTrace("1995:2005:Identifier", globalThis).document));
    // --- Dynamic Fluent Stylesheet Injection ---
    const DESIGN_TOKENS = globalThis.__npTrace("2586:27858:ObjectLiteralExpression", {
        spacing: globalThis.__npTrace("2601:2801:ObjectLiteralExpression", {
            titlebarHeight: globalThis.__npTrace("2625:2631:StringLiteral", '40px'), menubarHeight: globalThis.__npTrace("2648:2654:StringLiteral", '38px'), statusbarHeight: globalThis.__npTrace("2673:2679:StringLiteral", '28px'),
            editorPadding: globalThis.__npTrace("2702:2713:StringLiteral", '14px 16px'), titlebarInset: globalThis.__npTrace("2730:2736:StringLiteral", '10px'),
            menubarPadding: globalThis.__npTrace("2760:2767:StringLiteral", '0 8px'), statusbarPadding: globalThis.__npTrace("2787:2795:StringLiteral", '0 16px')
        }),
        typeScale: globalThis.__npTrace("2818:2915:ObjectLiteralExpression", {
            ui: globalThis.__npTrace("2830:2836:StringLiteral", '14px'), menu: globalThis.__npTrace("2844:2850:StringLiteral", '13px'), status: globalThis.__npTrace("2860:2866:StringLiteral", '12px'), editor: globalThis.__npTrace("2876:2882:StringLiteral", '11pt'),
            dialogTitle: globalThis.__npTrace("2903:2909:StringLiteral", '18px')
        }),
        colors: globalThis.__npTrace("2929:3680:ObjectLiteralExpression", {
            dark: globalThis.__npTrace("2943:3301:ObjectLiteralExpression", {
                window: globalThis.__npTrace("2961:2970:StringLiteral", '#1f1f1f'), titlebar: globalThis.__npTrace("2982:2991:StringLiteral", '#1f1f1f'), menubar: globalThis.__npTrace("3002:3011:StringLiteral", '#1f1f1f'),
                editor: globalThis.__npTrace("3029:3038:StringLiteral", '#282828'), tabActive: globalThis.__npTrace("3051:3060:StringLiteral", '#2c2c2c'), tabHover: globalThis.__npTrace("3072:3081:StringLiteral", '#262626'),
                card: globalThis.__npTrace("3097:3106:StringLiteral", '#2d2d2d'), flyout: globalThis.__npTrace("3116:3125:StringLiteral", '#2c2c2c'), control: globalThis.__npTrace("3136:3145:StringLiteral", '#323232'),
                statusbar: globalThis.__npTrace("3166:3175:StringLiteral", '#1f1f1f'), dialog: globalThis.__npTrace("3185:3194:StringLiteral", '#2c2c2c'), textPrimary: globalThis.__npTrace("3209:3218:StringLiteral", '#ffffff'),
                textSecondary: globalThis.__npTrace("3243:3252:StringLiteral", '#9d9d9d'), accent: globalThis.__npTrace("3262:3271:StringLiteral", '#0090f1'), selection: globalThis.__npTrace("3284:3293:StringLiteral", '#005fb8')
            }),
            light: globalThis.__npTrace("3316:3674:ObjectLiteralExpression", {
                window: globalThis.__npTrace("3334:3343:StringLiteral", '#f3f3f3'), titlebar: globalThis.__npTrace("3355:3364:StringLiteral", '#f3f3f3'), menubar: globalThis.__npTrace("3375:3384:StringLiteral", '#f3f3f3'),
                editor: globalThis.__npTrace("3402:3411:StringLiteral", '#ffffff'), tabActive: globalThis.__npTrace("3424:3433:StringLiteral", '#ffffff'), tabHover: globalThis.__npTrace("3445:3454:StringLiteral", '#eaeaea'),
                card: globalThis.__npTrace("3470:3479:StringLiteral", '#ffffff'), flyout: globalThis.__npTrace("3489:3498:StringLiteral", '#ffffff'), control: globalThis.__npTrace("3509:3518:StringLiteral", '#fbfbfb'),
                statusbar: globalThis.__npTrace("3539:3548:StringLiteral", '#f3f3f3'), dialog: globalThis.__npTrace("3558:3567:StringLiteral", '#ffffff'), textPrimary: globalThis.__npTrace("3582:3591:StringLiteral", '#1b1b1b'),
                textSecondary: globalThis.__npTrace("3616:3625:StringLiteral", '#616161'), accent: globalThis.__npTrace("3635:3644:StringLiteral", '#005fb8'), selection: globalThis.__npTrace("3657:3666:StringLiteral", '#005fb8')
            })
        }),
        radii: globalThis.__npTrace("3693:3761:ObjectLiteralExpression", { tab: globalThis.__npTrace("3700:3713:StringLiteral", '7px 7px 0 0'), control: globalThis.__npTrace("3724:3729:StringLiteral", '4px'), flyout: globalThis.__npTrace("3739:3744:StringLiteral", '8px'), dialog: globalThis.__npTrace("3754:3759:StringLiteral", '8px') }),
        elevation: globalThis.__npTrace("3778:3985:ObjectLiteralExpression", {
            dark: globalThis.__npTrace("3792:3878:ObjectLiteralExpression", { flyout: globalThis.__npTrace("3802:3834:StringLiteral", '0 8px 24px rgba(0, 0, 0, 0.55)'), modal: globalThis.__npTrace("3843:3876:StringLiteral", '0 16px 36px rgba(0, 0, 0, 0.65)') }),
            light: globalThis.__npTrace("3893:3979:ObjectLiteralExpression", { flyout: globalThis.__npTrace("3903:3935:StringLiteral", '0 8px 24px rgba(0, 0, 0, 0.15)'), modal: globalThis.__npTrace("3944:3977:StringLiteral", '0 16px 36px rgba(0, 0, 0, 0.25)') })
        }),
        motion: globalThis.__npTrace("3999:4139:ObjectLiteralExpression", {
            tabHover: globalThis.__npTrace("4017:4028:StringLiteral", '0.1s ease'), menuHover: globalThis.__npTrace("4041:4052:StringLiteral", '0.1s ease'),
            flyout: globalThis.__npTrace("4068:4083:StringLiteral", '0.1s ease-out'), find: globalThis.__npTrace("4091:4107:StringLiteral", '0.12s ease-out'), dialog: globalThis.__npTrace("4117:4133:StringLiteral", '0.15s ease-out')
        }),
        stylesheet: globalThis.__npTrace("4157:27856:FirstTemplateToken", `/* Windows 11 Modern Notepad - WinUI 3 Fluent Integrated Stylesheet */

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
`)
    });
    function ensureStylesInjected() {
        if (globalThis.__npTrace("27905:27954:PrefixUnaryExpression", !globalThis.__npTrace("27906:27954:CallExpression", globalThis.__npTrace("27906:27914:Identifier", document).getElementById(globalThis.__npTrace("27930:27953:StringLiteral", 'notepad-fluent-styles'))))) {
            const styleTag = globalThis.__npTrace("27981:28012:CallExpression", globalThis.__npTrace("27981:27989:Identifier", document).createElement(globalThis.__npTrace("28004:28011:StringLiteral", 'style')));
            globalThis.__npTrace("28020:28057:BinaryExpression", globalThis.__npTrace("28020:28028:Identifier", styleTag).id = globalThis.__npTrace("28034:28057:StringLiteral", 'notepad-fluent-styles'));
            globalThis.__npTrace("28065:28112:BinaryExpression", globalThis.__npTrace("28065:28073:Identifier", styleTag).textContent = globalThis.__npTrace("28088:28112:PropertyAccessExpression", globalThis.__npTrace("28088:28101:Identifier", DESIGN_TOKENS).stylesheet));
            globalThis.__npTrace("28120:28155:CallExpression", globalThis.__npTrace("28120:28133:PropertyAccessExpression", globalThis.__npTrace("28120:28128:Identifier", document).head).appendChild(globalThis.__npTrace("28146:28154:Identifier", styleTag)));
        }
    }
    // --- SVG Icons Library (WinUI 3 / Segoe Fluent Icons) ---
    const ICONS = globalThis.__npTrace("28246:33628:ObjectLiteralExpression", {
        app: globalThis.__npTrace("28257:28542:FirstTemplateToken", `<svg viewBox="0 0 24 24"><path fill="#0078d4" d="M4 2.5C4 1.67 4.67 1 5.5 1h13c.83 0 1.5.67 1.5 1.5v19c0 .83-.67 1.5-1.5 1.5h-13c-.83 0-1.5-.67-1.5-1.5v-19z"/><path fill="#60cdff" d="M7 6h10v2H7zm0 4h10v2H7zm0 4h6v2H7z"/><path fill="#ffffff" opacity="0.8" d="M7 18h10v1.5H7z"/></svg>`),
        minimize: globalThis.__npTrace("28558:28615:FirstTemplateToken", `<svg viewBox="0 0 10 10"><path d="M0 5h10v1H0z"/></svg>`),
        maximize: globalThis.__npTrace("28631:28702:FirstTemplateToken", `<svg viewBox="0 0 10 10"><path d="M1 1h8v8H1V1zm1 1v6h6V2H2z"/></svg>`),
        restore: globalThis.__npTrace("28717:28806:FirstTemplateToken", `<svg viewBox="0 0 10 10"><path d="M3 1h6v6H8V2H3V1zm-2 2h6v6H1V3zm1 1v4h4V4H2z"/></svg>`),
        close: globalThis.__npTrace("28819:28953:FirstTemplateToken", `<svg viewBox="0 0 10 10"><path d="M1.4 0.7L5 4.3 8.6 0.7 9.3 1.4 5.7 5 9.3 8.6 8.6 9.3 5 5.7 1.4 9.3 0.7 8.6 4.3 5 0.7 1.4z"/></svg>`),
        plus: globalThis.__npTrace("28965:29145:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M8 2a.75.75 0 0 1 .75.75v4.5h4.5a.75.75 0 0 1 0 1.5h-4.5v4.5a.75.75 0 0 1-1.5 0v-4.5h-4.5a.75.75 0 0 1 0-1.5h4.5v-4.5A.75.75 0 0 1 8 2z"/></svg>`),
        back: globalThis.__npTrace("29157:29349:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M13.5 7.25H4.86l3.97-3.97a.75.75 0 0 0-1.06-1.06l-5.25 5.25a.75.75 0 0 0 0 1.06l5.25 5.25a.75.75 0 1 0 1.06-1.06L4.86 8.75H13.5a.75.75 0 0 0 0-1.5z"/></svg>`),
        gear: globalThis.__npTrace("29361:30000:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M7.07 1a1 1 0 0 0-.98.8l-.27 1.34a5.03 5.03 0 0 0-1.28.53l-1.23-.62a1 1 0 0 0-1.24.31L1.13 5.01a1 1 0 0 0 .15 1.27l1.04.88c-.04.28-.07.56-.07.84s.03.56.07.84l-1.04.88a1 1 0 0 0-.15 1.27l1.24 1.65a1 1 0 0 0 1.24.31l1.23-.62c.4.23.83.41 1.28.53l.27 1.34a1 1 0 0 0 .98.8h2.06a1 1 0 0 0 .98-.8l.27-1.34c.45-.12.88-.3 1.28-.53l1.23.62a1 1 0 0 0 1.24-.31l1.24-1.65a1 1 0 0 0-.15-1.27l-1.04-.88c.04-.28.07-.56.07-.84s-.03-.56-.07-.84l1.04-.88a1 1 0 0 0 .15-1.27L13.87 3.36a1 1 0 0 0-1.24-.31l-1.23.62a5.03 5.03 0 0 0-1.28-.53l-.27-1.34a1 1 0 0 0-.98-.8H7.07zM8 5.5a2.5 2.5 0 1 1 0 5 2.5 2.5 0 0 1 0-5z"/></svg>`),
        megaphone: globalThis.__npTrace("30017:30371:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M13 2.5a.75.75 0 0 0-1.06-.68L4.62 5.08A2.75 2.75 0 0 0 2 7.75v.5c0 1.2.78 2.22 1.88 2.58l-.63 2.2a.75.75 0 0 0 .95.93l2.87-.96.48-.16a.75.75 0 0 0 .47-.45l.63-1.89h3.29l.06.01a.75.75 0 0 0 .8-.66l.2-1.39A2.99 2.99 0 0 0 15 5.5v-.5a2.5 2.5 0 0 0-2-2.5zm1 3c0 .83-.67 1.5-1.5 1.5h-.5V4h.5c.83 0 1.5.67 1.5 1.5z"/></svg>`),
        check: globalThis.__npTrace("30384:30563:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M13.78 4.22a.75.75 0 0 1 0 1.06l-7.25 7.25a.75.75 0 0 1-1.06 0L2.22 9.28a.75.75 0 0 1 1.06-1.06L6 10.94l6.72-6.72a.75.75 0 0 1 1.06 0z"/></svg>`),
        chevronDown: globalThis.__npTrace("30582:30756:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M3.2 5.2a.75.75 0 0 1 1.06 0L8 8.94l3.74-3.74a.75.75 0 1 1 1.06 1.06l-4.27 4.27a.75.75 0 0 1-1.06 0L3.2 6.26a.75.75 0 0 1 0-1.06z"/></svg>`),
        chevronRight: globalThis.__npTrace("30776:30950:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M5.2 3.2a.75.75 0 0 1 1.06 0l4.27 4.27a.75.75 0 0 1 0 1.06l-4.27 4.27a.75.75 0 0 1-1.06-1.06L8.94 8 5.2 4.26a.75.75 0 0 1 0-1.06z"/></svg>`),
        theme: globalThis.__npTrace("30963:31151:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zm0 1.5a5.5 5.5 0 1 1 0 11 5.5 5.5 0 0 1 0-11zm-.75 2v4c0 .2.08.39.22.53l2.5 2.5 1.06-1.06-2.28-2.28V4.5H7.25z"/></svg>`),
        font: globalThis.__npTrace("31163:31288:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M3.5 13h1.8l1.1-3h3.2l1.1 3h1.8L8.8 2.5H7.2L3.5 13zm3.4-4.5l1.1-3.2 1.1 3.2H6.9z"/></svg>`),
        wordWrap: globalThis.__npTrace("31304:31482:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M2 3.5h12v1.5H2V3.5zm0 4h9a2.5 2.5 0 1 1 0 5H8.5v-1.5H11a1 1 0 1 0 0-2H2V7.5zm0 4h4.5V13H2v-1.5z"/><path d="M8 10.5l-2.5 2L8 14.5v-4z"/></svg>`),
        formatting: globalThis.__npTrace("31500:31704:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M12.8 1.2a1 1 0 0 0-1.4 0L7.5 5.1 10.9 8.5l3.9-3.9a1 1 0 0 0 0-1.4l-2-2zM6.8 5.8L2.2 10.4c-.2.2-.3.5-.3.8v2.3c0 .3.2.5.5.5h2.3c.3 0 .6-.1.8-.3l4.6-4.6-3.2-3.3z"/></svg>`),
        openFiles: globalThis.__npTrace("31721:31945:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M3 2a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V9.5h-1.5V12a.5.5 0 0 1-.5.5H3a.5.5 0 0 1-.5-.5V4a.5.5 0 0 1 .5-.5h2.5V2H3zm7 0v1.5h2.44L6.72 9.22l1.06 1.06L13.5 4.56V7H15V2h-5z"/></svg>`),
        tabsApp: globalThis.__npTrace("31960:32108:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M2 3a1 1 0 0 0-1 1v8a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1H2zm0 1.5h12v1H2v-1zm0 2.5h12v6H2V7z"/></svg>`),
        recentFiles: globalThis.__npTrace("32127:32315:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zm0 1.5a5.5 5.5 0 1 1 0 11 5.5 5.5 0 0 1 0-11zm-.75 2v4c0 .2.08.39.22.53l2.5 2.5 1.06-1.06-2.28-2.28V4.5H7.25z"/></svg>`),
        spellCheck: globalThis.__npTrace("32333:32689:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M2.5 9h1.1l.6-1.8h2l.6 1.8h1.1L5.6 2.5H4.3L2.5 9zm2-2.7l.7-2.1.7 2.1h-1.4zm6.2 2.7h1.6c1.1 0 1.8-.7 1.8-1.7 0-.6-.3-1.1-.9-1.3.4-.2.7-.6.7-1.2 0-.9-.7-1.6-1.7-1.6h-1.5V9zm1-5.6h.6c.4 0 .7.3.7.7s-.3.7-.7.7h-.6V3.4zm0 2.3h.7c.5 0 .8.3.8.8s-.3.8-.8.8h-.7V5.7zM10.8 11.2l-2.6 2.6-1.1-1.1-.7.7 1.8 1.8 3.3-3.3-.7-.7z"/></svg>`),
        search: globalThis.__npTrace("32703:32869:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M11.74 10.68a6 6 0 1 0-1.06 1.06l3.47 3.47a.75.75 0 0 0 1.06-1.06l-3.47-3.47zM11 6.5a4.5 4.5 0 1 1-9 0 4.5 4.5 0 0 1 9 0z"/></svg>`),
        arrowUp: globalThis.__npTrace("32884:33015:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M8 3.2l4.27 4.27a.75.75 0 0 1-1.06 1.06L8 5.31 4.79 8.53a.75.75 0 1 1-1.06-1.06L8 3.2z"/></svg>`),
        arrowDown: globalThis.__npTrace("33032:33166:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M8 12.8L3.73 8.53a.75.75 0 0 1 1.06-1.06L8 10.69l3.21-3.22a.75.75 0 1 1 1.06 1.06L8 12.8z"/></svg>`),
        caseSensitive: globalThis.__npTrace("33187:33491:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M3.2 11.5h1.3l.8-2.2h2.4l.8 2.2h1.3L6.8 3.5H5.2L3.2 11.5zm2.5-3.3l.8-2.3.8 2.3H5.7zm6.8 3.3h1.2v-4.5c0-.9-.6-1.5-1.5-1.5s-1.5.6-1.5 1.5v4.5h1.2v-1.1c.2.4.6.6 1 .6.7 0 1.1-.4 1.1-1.1v-2.4h-1.5v2.4c0 .3.2.5.5.5s.5-.2.5-.5V8.5h-1.2V7c0-.3.2-.5.5-.5s.5.2.5.5v4.5z"/></svg>`),
        wrapAround: globalThis.__npTrace("33509:33624:FirstTemplateToken", `<svg viewBox="0 0 16 16"><path d="M2.5 8.5a5.5 5.5 0 1 0 1.6-3.9H2V3h4v4H4.5V5.5a4 4 0 1 1-1.2 2.8H2v.2z"/></svg>`)
    });
    // --- Default State Definition ---
    const DEFAULT_SETTINGS = globalThis.__npTrace("33711:34009:ObjectLiteralExpression", {
        theme: globalThis.__npTrace("33724:33730:StringLiteral", 'dark'),
        fontFamily: globalThis.__npTrace("33748:33758:StringLiteral", 'Consolas'),
        fontStyle: globalThis.__npTrace("33775:33784:StringLiteral", 'Regular'),
        fontSize: globalThis.__npTrace("33800:33804:StringLiteral", '11'),
        wordWrap: globalThis.__npTrace("33820:33824:TrueKeyword", true),
        formatting: globalThis.__npTrace("33842:33846:TrueKeyword", true),
        openingFiles: globalThis.__npTrace("33866:33874:StringLiteral", 'newTab'),
        startupOption: globalThis.__npTrace("33895:33912:StringLiteral", 'continueSession'),
        recentFilesEnabled: globalThis.__npTrace("33938:33943:FalseKeyword", false),
        spellCheck: globalThis.__npTrace("33961:33965:TrueKeyword", true),
        showStatusBar: globalThis.__npTrace("33986:33990:TrueKeyword", true),
        zoom: globalThis.__npTrace("34002:34005:FirstLiteralToken", 100)
    });
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
            globalThis.__npTrace("34381:34403:CallExpression", ensureStylesInjected());
            globalThis.__npTrace("34411:34497:BinaryExpression", globalThis.__npTrace("34411:34415:ThisKeyword", this).container = globalThis.__npTrace("34428:34497:BinaryExpression", globalThis.__npTrace("34428:34480:BinaryExpression", globalThis.__npTrace("34428:34437:Identifier", container) || globalThis.__npTrace("34441:34480:CallExpression", globalThis.__npTrace("34441:34449:Identifier", document).getElementById(globalThis.__npTrace("34465:34479:StringLiteral", 'notepad-root')))) || globalThis.__npTrace("34484:34497:PropertyAccessExpression", globalThis.__npTrace("34484:34492:Identifier", document).body)));
            globalThis.__npTrace("34505:34540:BinaryExpression", globalThis.__npTrace("34505:34509:ThisKeyword", this).settings = globalThis.__npTrace("34521:34540:CallExpression", globalThis.__npTrace("34521:34525:ThisKeyword", this).loadSettings()));
            globalThis.__npTrace("34548:34562:BinaryExpression", globalThis.__npTrace("34548:34552:ThisKeyword", this).tabs = globalThis.__npTrace("34560:34562:ArrayLiteralExpression", []));
            globalThis.__npTrace("34570:34593:BinaryExpression", globalThis.__npTrace("34570:34574:ThisKeyword", this).activeTabId = globalThis.__npTrace("34589:34593:NullKeyword", null));
            globalThis.__npTrace("34601:34619:BinaryExpression", globalThis.__npTrace("34601:34605:ThisKeyword", this).nextTabId = globalThis.__npTrace("34618:34619:FirstLiteralToken", 1));
            globalThis.__npTrace("34627:34649:BinaryExpression", globalThis.__npTrace("34627:34631:ThisKeyword", this).activeMenu = globalThis.__npTrace("34645:34649:NullKeyword", null));
            globalThis.__npTrace("34657:34886:BinaryExpression", globalThis.__npTrace("34657:34661:ThisKeyword", this).findReplaceState = globalThis.__npTrace("34681:34886:ObjectLiteralExpression", {
                isOpen: globalThis.__npTrace("34699:34704:FalseKeyword", false),
                isReplaceOpen: globalThis.__npTrace("34729:34734:FalseKeyword", false),
                query: globalThis.__npTrace("34751:34753:StringLiteral", ''),
                replaceQuery: globalThis.__npTrace("34777:34779:StringLiteral", ''),
                matchCase: globalThis.__npTrace("34800:34805:FalseKeyword", false),
                wrapAround: globalThis.__npTrace("34827:34831:TrueKeyword", true),
                matches: globalThis.__npTrace("34850:34852:ArrayLiteralExpression", []),
                currentIndex: globalThis.__npTrace("34876:34878:PrefixUnaryExpression", -globalThis.__npTrace("34877:34878:FirstLiteralToken", 1))
            }));
            globalThis.__npTrace("34894:34919:BinaryExpression", globalThis.__npTrace("34894:34898:ThisKeyword", this).dialogResolve = globalThis.__npTrace("34915:34919:NullKeyword", null));
            globalThis.__npTrace("34928:34939:CallExpression", globalThis.__npTrace("34928:34932:ThisKeyword", this).init());
        }
        // --- Settings & Persistence ---
        loadSettings() {
            try {
                const saved = globalThis.__npTrace("35041:35087:CallExpression", globalThis.__npTrace("35041:35053:Identifier", localStorage).getItem(globalThis.__npTrace("35062:35086:StringLiteral", 'win11_notepad_settings')));
                return globalThis.__npTrace("35104:35204:ConditionalExpression", globalThis.__npTrace("35104:35109:Identifier", saved) ? globalThis.__npTrace("35112:35166:CallExpression", globalThis.__npTrace("35112:35118:Identifier", Object).assign(globalThis.__npTrace("35126:35128:ObjectLiteralExpression", {}), globalThis.__npTrace("35130:35146:Identifier", DEFAULT_SETTINGS), globalThis.__npTrace("35148:35165:CallExpression", globalThis.__npTrace("35148:35152:Identifier", JSON).parse(globalThis.__npTrace("35159:35164:Identifier", saved))))) : globalThis.__npTrace("35169:35204:CallExpression", globalThis.__npTrace("35169:35175:Identifier", Object).assign(globalThis.__npTrace("35183:35185:ObjectLiteralExpression", {}), globalThis.__npTrace("35187:35203:Identifier", DEFAULT_SETTINGS))));
            }
            catch (e) {
                return globalThis.__npTrace("35241:35276:CallExpression", globalThis.__npTrace("35241:35247:Identifier", Object).assign(globalThis.__npTrace("35255:35257:ObjectLiteralExpression", {}), globalThis.__npTrace("35259:35275:Identifier", DEFAULT_SETTINGS)));
            }
        }
        saveSettings() {
            try {
                globalThis.__npTrace("35334:35411:CallExpression", globalThis.__npTrace("35334:35346:Identifier", localStorage).setItem(globalThis.__npTrace("35355:35379:StringLiteral", 'win11_notepad_settings'), globalThis.__npTrace("35381:35410:CallExpression", globalThis.__npTrace("35381:35385:Identifier", JSON).stringify(globalThis.__npTrace("35396:35409:PropertyAccessExpression", globalThis.__npTrace("35396:35400:ThisKeyword", this).settings)))));
            }
            catch (e) { }
        }
        loadSavedSession() {
            if (globalThis.__npTrace("35476:35525:BinaryExpression", globalThis.__npTrace("35476:35503:PropertyAccessExpression", globalThis.__npTrace("35476:35489:PropertyAccessExpression", globalThis.__npTrace("35476:35480:ThisKeyword", this).settings).startupOption) === globalThis.__npTrace("35508:35525:StringLiteral", 'continueSession'))) {
                try {
                    const saved = globalThis.__npTrace("35567:35612:CallExpression", globalThis.__npTrace("35567:35579:Identifier", localStorage).getItem(globalThis.__npTrace("35588:35611:StringLiteral", 'win11_notepad_session')));
                    if (globalThis.__npTrace("35628:35633:Identifier", saved)) {
                        const data = globalThis.__npTrace("35662:35679:CallExpression", globalThis.__npTrace("35662:35666:Identifier", JSON).parse(globalThis.__npTrace("35673:35678:Identifier", saved)));
                        if (globalThis.__npTrace("35697:35745:BinaryExpression", globalThis.__npTrace("35697:35721:CallExpression", globalThis.__npTrace("35697:35702:Identifier", Array).isArray(globalThis.__npTrace("35711:35720:PropertyAccessExpression", globalThis.__npTrace("35711:35715:Identifier", data).tabs))) && globalThis.__npTrace("35725:35745:BinaryExpression", globalThis.__npTrace("35725:35741:PropertyAccessExpression", globalThis.__npTrace("35725:35734:PropertyAccessExpression", globalThis.__npTrace("35725:35729:Identifier", data).tabs).length) > globalThis.__npTrace("35744:35745:FirstLiteralToken", 0)))) {
                            globalThis.__npTrace("35763:35784:BinaryExpression", globalThis.__npTrace("35763:35767:ThisKeyword", this).tabs = globalThis.__npTrace("35775:35784:PropertyAccessExpression", globalThis.__npTrace("35775:35779:Identifier", data).tabs));
                            globalThis.__npTrace("35800:35857:BinaryExpression", globalThis.__npTrace("35800:35804:ThisKeyword", this).nextTabId = globalThis.__npTrace("35817:35857:BinaryExpression", globalThis.__npTrace("35817:35831:PropertyAccessExpression", globalThis.__npTrace("35817:35821:Identifier", data).nextTabId) || globalThis.__npTrace("35835:35857:ParenthesizedExpression", (globalThis.__npTrace("35836:35856:BinaryExpression", globalThis.__npTrace("35836:35852:PropertyAccessExpression", globalThis.__npTrace("35836:35845:PropertyAccessExpression", globalThis.__npTrace("35836:35840:ThisKeyword", this).tabs).length) + globalThis.__npTrace("35855:35856:FirstLiteralToken", 1))))));
                            globalThis.__npTrace("35873:35927:BinaryExpression", globalThis.__npTrace("35873:35877:ThisKeyword", this).activeTabId = globalThis.__npTrace("35892:35927:BinaryExpression", globalThis.__npTrace("35892:35908:PropertyAccessExpression", globalThis.__npTrace("35892:35896:Identifier", data).activeTabId) || globalThis.__npTrace("35912:35927:PropertyAccessExpression", globalThis.__npTrace("35912:35924:ElementAccessExpression", globalThis.__npTrace("35912:35921:PropertyAccessExpression", globalThis.__npTrace("35912:35916:ThisKeyword", this).tabs)[globalThis.__npTrace("35922:35923:FirstLiteralToken", 0)]).id)));
                            return;
                        }
                    }
                }
                catch (e) { }
            }
            // Default: Clean initial tab named 'Untitled' with empty content
            globalThis.__npTrace("36086:36369:BinaryExpression", globalThis.__npTrace("36086:36090:ThisKeyword", this).tabs = globalThis.__npTrace("36098:36369:ArrayLiteralExpression", [globalThis.__npTrace("36099:36368:ObjectLiteralExpression", {
                    id: globalThis.__npTrace("36113:36129:PostfixUnaryExpression", globalThis.__npTrace("36113:36117:ThisKeyword", this).nextTabId++),
                    title: globalThis.__npTrace("36146:36156:StringLiteral", 'Untitled'),
                    content: globalThis.__npTrace("36175:36177:StringLiteral", ''),
                    isModified: globalThis.__npTrace("36199:36204:FalseKeyword", false),
                    filePath: globalThis.__npTrace("36224:36228:NullKeyword", null),
                    encoding: globalThis.__npTrace("36248:36255:StringLiteral", 'UTF-8'),
                    lineEnding: globalThis.__npTrace("36277:36288:StringLiteral", 'Unix (LF)'),
                    cursorLine: globalThis.__npTrace("36310:36311:FirstLiteralToken", 1),
                    cursorCol: globalThis.__npTrace("36332:36333:FirstLiteralToken", 1),
                    isMarkdown: globalThis.__npTrace("36355:36360:FalseKeyword", false)
                })]));
            globalThis.__npTrace("36377:36411:BinaryExpression", globalThis.__npTrace("36377:36381:ThisKeyword", this).activeTabId = globalThis.__npTrace("36396:36411:PropertyAccessExpression", globalThis.__npTrace("36396:36408:ElementAccessExpression", globalThis.__npTrace("36396:36405:PropertyAccessExpression", globalThis.__npTrace("36396:36400:ThisKeyword", this).tabs)[globalThis.__npTrace("36406:36407:FirstLiteralToken", 0)]).id));
        }
        saveSession() {
            if (globalThis.__npTrace("36450:36499:BinaryExpression", globalThis.__npTrace("36450:36477:PropertyAccessExpression", globalThis.__npTrace("36450:36463:PropertyAccessExpression", globalThis.__npTrace("36450:36454:ThisKeyword", this).settings).startupOption) === globalThis.__npTrace("36482:36499:StringLiteral", 'continueSession'))) {
                try {
                    const data = globalThis.__npTrace("36540:36663:ObjectLiteralExpression", {
                        tabs: globalThis.__npTrace("36560:36569:PropertyAccessExpression", globalThis.__npTrace("36560:36564:ThisKeyword", this).tabs),
                        nextTabId: globalThis.__npTrace("36594:36608:PropertyAccessExpression", globalThis.__npTrace("36594:36598:ThisKeyword", this).nextTabId),
                        activeTabId: globalThis.__npTrace("36635:36651:PropertyAccessExpression", globalThis.__npTrace("36635:36639:ThisKeyword", this).activeTabId)
                    });
                    globalThis.__npTrace("36675:36742:CallExpression", globalThis.__npTrace("36675:36687:Identifier", localStorage).setItem(globalThis.__npTrace("36696:36719:StringLiteral", 'win11_notepad_session'), globalThis.__npTrace("36721:36741:CallExpression", globalThis.__npTrace("36721:36725:Identifier", JSON).stringify(globalThis.__npTrace("36736:36740:Identifier", data)))));
                }
                catch (e) { }
            }
        }
        // --- DOM Construction ---
        init() {
            globalThis.__npTrace("36833:36856:CallExpression", globalThis.__npTrace("36833:36837:ThisKeyword", this).loadSavedSession());
            globalThis.__npTrace("36864:36881:CallExpression", globalThis.__npTrace("36864:36868:ThisKeyword", this).applyTheme());
            globalThis.__npTrace("36889:36913:CallExpression", globalThis.__npTrace("36889:36893:ThisKeyword", this).renderAppSkeleton());
            globalThis.__npTrace("36921:36946:CallExpression", globalThis.__npTrace("36921:36925:ThisKeyword", this).attachGlobalEvents());
            globalThis.__npTrace("36954:36971:CallExpression", globalThis.__npTrace("36954:36958:ThisKeyword", this).renderTabs());
            globalThis.__npTrace("36979:37008:CallExpression", globalThis.__npTrace("36979:36983:ThisKeyword", this).updateActiveTabContent());
            globalThis.__npTrace("37016:37038:CallExpression", globalThis.__npTrace("37016:37020:ThisKeyword", this).updateStatusBar());
            globalThis.__npTrace("37046:37070:CallExpression", globalThis.__npTrace("37046:37050:ThisKeyword", this).applyEditorStyles());
        }
        applyTheme() {
            let theme = globalThis.__npTrace("37116:37135:PropertyAccessExpression", globalThis.__npTrace("37116:37129:PropertyAccessExpression", globalThis.__npTrace("37116:37120:ThisKeyword", this).settings).theme);
            if (globalThis.__npTrace("37147:37165:BinaryExpression", globalThis.__npTrace("37147:37152:Identifier", theme) === globalThis.__npTrace("37157:37165:StringLiteral", 'system'))) {
                globalThis.__npTrace("37177:37283:BinaryExpression", theme = globalThis.__npTrace("37185:37283:ConditionalExpression", globalThis.__npTrace("37185:37264:BinaryExpression", globalThis.__npTrace("37185:37202:PropertyAccessExpression", globalThis.__npTrace("37185:37191:Identifier", window).matchMedia) && globalThis.__npTrace("37206:37264:PropertyAccessExpression", globalThis.__npTrace("37206:37256:CallExpression", globalThis.__npTrace("37206:37212:Identifier", window).matchMedia(globalThis.__npTrace("37224:37255:StringLiteral", '(prefers-color-scheme: light)'))).matches)) ? globalThis.__npTrace("37267:37274:StringLiteral", 'light') : globalThis.__npTrace("37277:37283:StringLiteral", 'dark')));
            }
            globalThis.__npTrace("37299:37357:CallExpression", globalThis.__npTrace("37299:37323:PropertyAccessExpression", globalThis.__npTrace("37299:37307:Identifier", document).documentElement).setAttribute(globalThis.__npTrace("37337:37349:StringLiteral", 'data-theme'), globalThis.__npTrace("37351:37356:Identifier", theme)));
        }
        renderAppSkeleton() {
            globalThis.__npTrace("37398:62685:BinaryExpression", globalThis.__npTrace("37398:37412:PropertyAccessExpression", globalThis.__npTrace("37398:37402:ThisKeyword", this).container).innerHTML = globalThis.__npTrace("37425:62685:TemplateExpression", `
        <!-- Titlebar with Tabs & Window Controls -->
        <header class="notepad-titlebar">
          <div class="titlebar-left">
            <div class="notepad-app-icon" title="Notepad">${globalThis.__npTrace("37621:37630:PropertyAccessExpression", globalThis.__npTrace("37621:37626:Identifier", ICONS).app)}</div>
            <div class="notepad-tabs-container" id="tabs-container"></div>
            <button class="add-tab-btn" id="btn-add-tab" title="New tab (Ctrl+N)">${globalThis.__npTrace("37797:37807:PropertyAccessExpression", globalThis.__npTrace("37797:37802:Identifier", ICONS).plus)}</button>
          </div>
          <div class="window-controls">
            <button class="win-btn win-minimize" id="btn-win-min" title="Minimize">${globalThis.__npTrace("37960:37974:PropertyAccessExpression", globalThis.__npTrace("37960:37965:Identifier", ICONS).minimize)}</button>
            <button class="win-btn win-maximize" id="btn-win-max" title="Maximize">${globalThis.__npTrace("38070:38084:PropertyAccessExpression", globalThis.__npTrace("38070:38075:Identifier", ICONS).maximize)}</button>
            <button class="win-btn win-close" id="btn-win-close" title="Close">${globalThis.__npTrace("38176:38187:PropertyAccessExpression", globalThis.__npTrace("38176:38181:Identifier", ICONS).close)}</button>
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
              ${globalThis.__npTrace("38714:38729:PropertyAccessExpression", globalThis.__npTrace("38714:38719:Identifier", ICONS).megaphone)}
              <span class="notification-badge-dot"></span>
            </button>
            <button class="menu-action-btn" id="btn-settings-toggle" title="Settings">
              ${globalThis.__npTrace("38915:38925:PropertyAccessExpression", globalThis.__npTrace("38915:38920:Identifier", ICONS).gear)}
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
              <span class="menu-submenu-arrow">${globalThis.__npTrace("40036:40054:PropertyAccessExpression", globalThis.__npTrace("40036:40041:Identifier", ICONS).chevronRight)}</span>
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
              <span class="menu-submenu-arrow">${globalThis.__npTrace("44995:45013:PropertyAccessExpression", globalThis.__npTrace("44995:45000:Identifier", ICONS).chevronRight)}</span>
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
                <span class="menu-check-icon" id="check-status-bar">${globalThis.__npTrace("45934:45945:PropertyAccessExpression", globalThis.__npTrace("45934:45939:Identifier", ICONS).check)}</span>
                <span class="menu-row-label">Status bar</span>
              </div>
            </div>
            <div class="menu-row" data-action="toggleWordWrap">
              <div class="menu-row-left">
                <span class="menu-check-icon" id="check-word-wrap">${globalThis.__npTrace("46232:46243:PropertyAccessExpression", globalThis.__npTrace("46232:46237:Identifier", ICONS).check)}</span>
                <span class="menu-row-label">Word wrap</span>
              </div>
            </div>
            <div class="menu-row submenu-container">
              <span class="menu-row-label">Markdown</span>
              <span class="menu-submenu-arrow">${globalThis.__npTrace("46515:46533:PropertyAccessExpression", globalThis.__npTrace("46515:46520:Identifier", ICONS).chevronRight)}</span>
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
              class="editor-textarea ${globalThis.__npTrace("47015:47057:ConditionalExpression", globalThis.__npTrace("47015:47037:PropertyAccessExpression", globalThis.__npTrace("47015:47028:PropertyAccessExpression", globalThis.__npTrace("47015:47019:ThisKeyword", this).settings).wordWrap) ? globalThis.__npTrace("47040:47046:StringLiteral", 'wrap') : globalThis.__npTrace("47049:47057:StringLiteral", 'nowrap'))}"
              id="editor-area"
              spellcheck="${globalThis.__npTrace("47119:47143:PropertyAccessExpression", globalThis.__npTrace("47119:47132:PropertyAccessExpression", globalThis.__npTrace("47119:47123:ThisKeyword", this).settings).spellCheck)}"
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
              <button class="find-btn" id="find-btn-prev" title="Previous match (Shift+F3)">${globalThis.__npTrace("47783:47796:PropertyAccessExpression", globalThis.__npTrace("47783:47788:Identifier", ICONS).arrowUp)}</button>
              <button class="find-btn" id="find-btn-next" title="Next match (F3)">${globalThis.__npTrace("47891:47906:PropertyAccessExpression", globalThis.__npTrace("47891:47896:Identifier", ICONS).arrowDown)}</button>
              <button class="find-btn" id="find-btn-case" title="Match case">${globalThis.__npTrace("47996:48015:PropertyAccessExpression", globalThis.__npTrace("47996:48001:Identifier", ICONS).caseSensitive)}</button>
              <button class="find-btn active" id="find-btn-wrap" title="Wrap around">${globalThis.__npTrace("48113:48129:PropertyAccessExpression", globalThis.__npTrace("48113:48118:Identifier", ICONS).wrapAround)}</button>
              <button class="find-btn" id="find-btn-toggle-replace" title="Toggle replace">${globalThis.__npTrace("48233:48250:PropertyAccessExpression", globalThis.__npTrace("48233:48238:Identifier", ICONS).chevronDown)}</button>
              <button class="find-btn" id="find-btn-close" title="Close">${globalThis.__npTrace("48336:48347:PropertyAccessExpression", globalThis.__npTrace("48336:48341:Identifier", ICONS).close)}</button>
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
            <button class="settings-back-btn" id="settings-btn-back" title="Back">${globalThis.__npTrace("50033:50043:PropertyAccessExpression", globalThis.__npTrace("50033:50038:Identifier", ICONS).back)}</button>
            <div class="settings-titlebar-name">
              <div class="notepad-app-icon">${globalThis.__npTrace("50149:50158:PropertyAccessExpression", globalThis.__npTrace("50149:50154:Identifier", ICONS).app)}</div>
              <span>Notepad</span>
            </div>
            <div class="window-controls">
              <button class="win-btn win-minimize">${globalThis.__npTrace("50315:50329:PropertyAccessExpression", globalThis.__npTrace("50315:50320:Identifier", ICONS).minimize)}</button>
              <button class="win-btn win-maximize">${globalThis.__npTrace("50393:50407:PropertyAccessExpression", globalThis.__npTrace("50393:50398:Identifier", ICONS).maximize)}</button>
              <button class="win-btn win-close" id="settings-win-close">${globalThis.__npTrace("50492:50503:PropertyAccessExpression", globalThis.__npTrace("50492:50497:Identifier", ICONS).close)}</button>
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
                      <div class="card-icon">${globalThis.__npTrace("51054:51065:PropertyAccessExpression", globalThis.__npTrace("51054:51059:Identifier", ICONS).theme)}</div>
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
                      <div class="card-icon">${globalThis.__npTrace("52122:52132:PropertyAccessExpression", globalThis.__npTrace("52122:52127:Identifier", ICONS).font)}</div>
                      <div class="card-text-titles">
                        <div class="card-primary-title">Font</div>
                      </div>
                    </div>
                    <button class="accordion-toggle-btn" id="btn-font-accordion">${globalThis.__npTrace("52399:52416:PropertyAccessExpression", globalThis.__npTrace("52399:52404:Identifier", ICONS).chevronDown)}</button>
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
                      <div class="card-icon">${globalThis.__npTrace("54912:54926:PropertyAccessExpression", globalThis.__npTrace("54912:54917:Identifier", ICONS).wordWrap)}</div>
                      <div class="card-text-titles">
                        <div class="card-primary-title">Word wrap</div>
                        <div class="card-subtitle">Fit text within window by default</div>
                      </div>
                    </div>
                    <div class="fluent-toggle-wrapper ${globalThis.__npTrace("55262:55296:ConditionalExpression", globalThis.__npTrace("55262:55284:PropertyAccessExpression", globalThis.__npTrace("55262:55275:PropertyAccessExpression", globalThis.__npTrace("55262:55266:ThisKeyword", this).settings).wordWrap) ? globalThis.__npTrace("55287:55291:StringLiteral", 'on') : globalThis.__npTrace("55294:55296:StringLiteral", ''))}" id="toggle-setting-wordwrap">
                      <div class="toggle-switch"><div class="toggle-knob"></div></div>
                      <span class="toggle-label">${globalThis.__npTrace("55467:55504:ConditionalExpression", globalThis.__npTrace("55467:55489:PropertyAccessExpression", globalThis.__npTrace("55467:55480:PropertyAccessExpression", globalThis.__npTrace("55467:55471:ThisKeyword", this).settings).wordWrap) ? globalThis.__npTrace("55492:55496:StringLiteral", 'On') : globalThis.__npTrace("55499:55504:StringLiteral", 'Off'))}</span>
                    </div>
                  </div>
                </div>

                <!-- Formatting Toggle Card -->
                <div class="settings-card">
                  <div class="settings-card-header">
                    <div class="card-info-left">
                      <div class="card-icon">${globalThis.__npTrace("55830:55846:PropertyAccessExpression", globalThis.__npTrace("55830:55835:Identifier", ICONS).formatting)}</div>
                      <div class="card-text-titles">
                        <div class="card-primary-title">Formatting</div>
                      </div>
                    </div>
                    <div class="fluent-toggle-wrapper ${globalThis.__npTrace("56092:56128:ConditionalExpression", globalThis.__npTrace("56092:56116:PropertyAccessExpression", globalThis.__npTrace("56092:56105:PropertyAccessExpression", globalThis.__npTrace("56092:56096:ThisKeyword", this).settings).formatting) ? globalThis.__npTrace("56119:56123:StringLiteral", 'on') : globalThis.__npTrace("56126:56128:StringLiteral", ''))}" id="toggle-setting-formatting">
                      <div class="toggle-switch"><div class="toggle-knob"></div></div>
                      <span class="toggle-label">${globalThis.__npTrace("56301:56340:ConditionalExpression", globalThis.__npTrace("56301:56325:PropertyAccessExpression", globalThis.__npTrace("56301:56314:PropertyAccessExpression", globalThis.__npTrace("56301:56305:ThisKeyword", this).settings).formatting) ? globalThis.__npTrace("56328:56332:StringLiteral", 'On') : globalThis.__npTrace("56335:56340:StringLiteral", 'Off'))}</span>
                    </div>
                  </div>
                </div>

                <!-- Opening Notepad -->
                <div class="settings-section-header">Opening Notepad</div>

                <!-- Opening Files Dropdown Card -->
                <div class="settings-card">
                  <div class="settings-card-header">
                    <div class="card-info-left">
                      <div class="card-icon">${globalThis.__npTrace("56788:56803:PropertyAccessExpression", globalThis.__npTrace("56788:56793:Identifier", ICONS).openFiles)}</div>
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
                      <div class="card-icon">${globalThis.__npTrace("57730:57743:PropertyAccessExpression", globalThis.__npTrace("57730:57735:Identifier", ICONS).tabsApp)}</div>
                      <div class="card-text-titles">
                        <div class="card-primary-title">When Notepad starts</div>
                      </div>
                    </div>
                    <button class="accordion-toggle-btn" id="btn-startup-accordion">${globalThis.__npTrace("58028:58045:PropertyAccessExpression", globalThis.__npTrace("58028:58033:Identifier", ICONS).chevronDown)}</button>
                  </div>
                  <div class="card-expand-content">
                    <div class="fluent-radio-group">
                      <div class="fluent-radio-option ${globalThis.__npTrace("58242:58309:ConditionalExpression", globalThis.__npTrace("58242:58291:BinaryExpression", globalThis.__npTrace("58242:58269:PropertyAccessExpression", globalThis.__npTrace("58242:58255:PropertyAccessExpression", globalThis.__npTrace("58242:58246:ThisKeyword", this).settings).startupOption) === globalThis.__npTrace("58274:58291:StringLiteral", 'continueSession')) ? globalThis.__npTrace("58294:58304:StringLiteral", 'selected') : globalThis.__npTrace("58307:58309:StringLiteral", ''))}" data-value="continueSession" id="radio-startup-continue">
                        <div class="radio-circle"><div class="radio-dot"></div></div>
                        <span>Continue previous session</span>
                      </div>
                      <div class="fluent-radio-option ${globalThis.__npTrace("58604:58666:ConditionalExpression", globalThis.__npTrace("58604:58648:BinaryExpression", globalThis.__npTrace("58604:58631:PropertyAccessExpression", globalThis.__npTrace("58604:58617:PropertyAccessExpression", globalThis.__npTrace("58604:58608:ThisKeyword", this).settings).startupOption) === globalThis.__npTrace("58636:58648:StringLiteral", 'newSession')) ? globalThis.__npTrace("58651:58661:StringLiteral", 'selected') : globalThis.__npTrace("58664:58666:StringLiteral", ''))}" data-value="newSession" id="radio-startup-new">
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
                      <div class="card-icon">${globalThis.__npTrace("59234:59251:PropertyAccessExpression", globalThis.__npTrace("59234:59239:Identifier", ICONS).recentFiles)}</div>
                      <div class="card-text-titles">
                        <div class="card-primary-title">Recent Files</div>
                      </div>
                    </div>
                    <div class="fluent-toggle-wrapper ${globalThis.__npTrace("59499:59543:ConditionalExpression", globalThis.__npTrace("59499:59531:PropertyAccessExpression", globalThis.__npTrace("59499:59512:PropertyAccessExpression", globalThis.__npTrace("59499:59503:ThisKeyword", this).settings).recentFilesEnabled) ? globalThis.__npTrace("59534:59538:StringLiteral", 'on') : globalThis.__npTrace("59541:59543:StringLiteral", ''))}" id="toggle-setting-recent-files">
                      <div class="toggle-switch"><div class="toggle-knob"></div></div>
                      <span class="toggle-label">${globalThis.__npTrace("59718:59765:ConditionalExpression", globalThis.__npTrace("59718:59750:PropertyAccessExpression", globalThis.__npTrace("59718:59731:PropertyAccessExpression", globalThis.__npTrace("59718:59722:ThisKeyword", this).settings).recentFilesEnabled) ? globalThis.__npTrace("59753:59757:StringLiteral", 'On') : globalThis.__npTrace("59760:59765:StringLiteral", 'Off'))}</span>
                    </div>
                  </div>
                </div>

                <!-- Spelling -->
                <div class="settings-section-header">Spelling</div>
                <div class="settings-card">
                  <div class="settings-card-header">
                    <div class="card-info-left">
                      <div class="card-icon">${globalThis.__npTrace("60145:60161:PropertyAccessExpression", globalThis.__npTrace("60145:60150:Identifier", ICONS).spellCheck)}</div>
                      <div class="card-text-titles">
                        <div class="card-primary-title">Spell check</div>
                      </div>
                    </div>
                    <div class="fluent-toggle-wrapper ${globalThis.__npTrace("60408:60444:ConditionalExpression", globalThis.__npTrace("60408:60432:PropertyAccessExpression", globalThis.__npTrace("60408:60421:PropertyAccessExpression", globalThis.__npTrace("60408:60412:ThisKeyword", this).settings).spellCheck) ? globalThis.__npTrace("60435:60439:StringLiteral", 'on') : globalThis.__npTrace("60442:60444:StringLiteral", ''))}" id="toggle-setting-spellcheck">
                      <div class="toggle-switch"><div class="toggle-knob"></div></div>
                      <span class="toggle-label">${globalThis.__npTrace("60617:60656:ConditionalExpression", globalThis.__npTrace("60617:60641:PropertyAccessExpression", globalThis.__npTrace("60617:60630:PropertyAccessExpression", globalThis.__npTrace("60617:60621:ThisKeyword", this).settings).spellCheck) ? globalThis.__npTrace("60644:60648:StringLiteral", 'On') : globalThis.__npTrace("60651:60656:StringLiteral", 'Off'))}</span>
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
      `));
            // Cache elements
            globalThis.__npTrace("62718:65419:BinaryExpression", globalThis.__npTrace("62718:62722:ThisKeyword", this).dom = globalThis.__npTrace("62729:65419:AsExpression", globalThis.__npTrace("62729:65408:ObjectLiteralExpression", {
                editor: globalThis.__npTrace("62747:62808:AsExpression", globalThis.__npTrace("62747:62785:CallExpression", globalThis.__npTrace("62747:62755:Identifier", document).getElementById(globalThis.__npTrace("62771:62784:StringLiteral", 'editor-area')))),
                tabsContainer: globalThis.__npTrace("62833:62874:CallExpression", globalThis.__npTrace("62833:62841:Identifier", document).getElementById(globalThis.__npTrace("62857:62873:StringLiteral", 'tabs-container'))),
                btnAddTab: globalThis.__npTrace("62895:62933:CallExpression", globalThis.__npTrace("62895:62903:Identifier", document).getElementById(globalThis.__npTrace("62919:62932:StringLiteral", 'btn-add-tab'))),
                flyoutFile: globalThis.__npTrace("62955:62993:CallExpression", globalThis.__npTrace("62955:62963:Identifier", document).getElementById(globalThis.__npTrace("62979:62992:StringLiteral", 'flyout-file'))),
                flyoutEdit: globalThis.__npTrace("63015:63053:CallExpression", globalThis.__npTrace("63015:63023:Identifier", document).getElementById(globalThis.__npTrace("63039:63052:StringLiteral", 'flyout-edit'))),
                flyoutView: globalThis.__npTrace("63075:63113:CallExpression", globalThis.__npTrace("63075:63083:Identifier", document).getElementById(globalThis.__npTrace("63099:63112:StringLiteral", 'flyout-view'))),
                menuBtnFile: globalThis.__npTrace("63136:63176:CallExpression", globalThis.__npTrace("63136:63144:Identifier", document).getElementById(globalThis.__npTrace("63160:63175:StringLiteral", 'menu-btn-file'))),
                menuBtnEdit: globalThis.__npTrace("63199:63239:CallExpression", globalThis.__npTrace("63199:63207:Identifier", document).getElementById(globalThis.__npTrace("63223:63238:StringLiteral", 'menu-btn-edit'))),
                menuBtnView: globalThis.__npTrace("63262:63302:CallExpression", globalThis.__npTrace("63262:63270:Identifier", document).getElementById(globalThis.__npTrace("63286:63301:StringLiteral", 'menu-btn-view'))),
                btnSettingsToggle: globalThis.__npTrace("63331:63377:CallExpression", globalThis.__npTrace("63331:63339:Identifier", document).getElementById(globalThis.__npTrace("63355:63376:StringLiteral", 'btn-settings-toggle'))),
                settingsView: globalThis.__npTrace("63401:63441:CallExpression", globalThis.__npTrace("63401:63409:Identifier", document).getElementById(globalThis.__npTrace("63425:63440:StringLiteral", 'settings-view'))),
                settingsBtnBack: globalThis.__npTrace("63468:63512:CallExpression", globalThis.__npTrace("63468:63476:Identifier", document).getElementById(globalThis.__npTrace("63492:63511:StringLiteral", 'settings-btn-back'))),
                statusBar: globalThis.__npTrace("63533:63577:CallExpression", globalThis.__npTrace("63533:63541:Identifier", document).getElementById(globalThis.__npTrace("63557:63576:StringLiteral", 'notepad-statusbar'))),
                sbCursorPos: globalThis.__npTrace("63600:63640:CallExpression", globalThis.__npTrace("63600:63608:Identifier", document).getElementById(globalThis.__npTrace("63624:63639:StringLiteral", 'sb-cursor-pos'))),
                sbCharCount: globalThis.__npTrace("63663:63703:CallExpression", globalThis.__npTrace("63663:63671:Identifier", document).getElementById(globalThis.__npTrace("63687:63702:StringLiteral", 'sb-char-count'))),
                sbDocType: globalThis.__npTrace("63724:63762:CallExpression", globalThis.__npTrace("63724:63732:Identifier", document).getElementById(globalThis.__npTrace("63748:63761:StringLiteral", 'sb-doc-type'))),
                sbZoomLevel: globalThis.__npTrace("63785:63825:CallExpression", globalThis.__npTrace("63785:63793:Identifier", document).getElementById(globalThis.__npTrace("63809:63824:StringLiteral", 'sb-zoom-level'))),
                sbLineEnding: globalThis.__npTrace("63849:63890:CallExpression", globalThis.__npTrace("63849:63857:Identifier", document).getElementById(globalThis.__npTrace("63873:63889:StringLiteral", 'sb-line-ending'))),
                sbEncoding: globalThis.__npTrace("63912:63950:CallExpression", globalThis.__npTrace("63912:63920:Identifier", document).getElementById(globalThis.__npTrace("63936:63949:StringLiteral", 'sb-encoding'))),
                checkStatusBar: globalThis.__npTrace("63976:64019:CallExpression", globalThis.__npTrace("63976:63984:Identifier", document).getElementById(globalThis.__npTrace("64000:64018:StringLiteral", 'check-status-bar'))),
                checkWordWrap: globalThis.__npTrace("64044:64086:CallExpression", globalThis.__npTrace("64044:64052:Identifier", document).getElementById(globalThis.__npTrace("64068:64085:StringLiteral", 'check-word-wrap'))),
                findReplacePanel: globalThis.__npTrace("64114:64159:CallExpression", globalThis.__npTrace("64114:64122:Identifier", document).getElementById(globalThis.__npTrace("64138:64158:StringLiteral", 'find-replace-panel'))),
                findQueryInput: globalThis.__npTrace("64185:64228:CallExpression", globalThis.__npTrace("64185:64193:Identifier", document).getElementById(globalThis.__npTrace("64209:64227:StringLiteral", 'find-query-input'))),
                replaceQueryInput: globalThis.__npTrace("64257:64303:CallExpression", globalThis.__npTrace("64257:64265:Identifier", document).getElementById(globalThis.__npTrace("64281:64302:StringLiteral", 'replace-query-input'))),
                replaceRow: globalThis.__npTrace("64325:64373:CallExpression", globalThis.__npTrace("64325:64333:Identifier", document).getElementById(globalThis.__npTrace("64349:64372:StringLiteral", 'replace-row-container'))),
                findMatchCounter: globalThis.__npTrace("64401:64446:CallExpression", globalThis.__npTrace("64401:64409:Identifier", document).getElementById(globalThis.__npTrace("64425:64445:StringLiteral", 'find-match-counter'))),
                findBtnPrev: globalThis.__npTrace("64469:64509:CallExpression", globalThis.__npTrace("64469:64477:Identifier", document).getElementById(globalThis.__npTrace("64493:64508:StringLiteral", 'find-btn-prev'))),
                findBtnNext: globalThis.__npTrace("64532:64572:CallExpression", globalThis.__npTrace("64532:64540:Identifier", document).getElementById(globalThis.__npTrace("64556:64571:StringLiteral", 'find-btn-next'))),
                findBtnCase: globalThis.__npTrace("64595:64635:CallExpression", globalThis.__npTrace("64595:64603:Identifier", document).getElementById(globalThis.__npTrace("64619:64634:StringLiteral", 'find-btn-case'))),
                findBtnWrap: globalThis.__npTrace("64658:64698:CallExpression", globalThis.__npTrace("64658:64666:Identifier", document).getElementById(globalThis.__npTrace("64682:64697:StringLiteral", 'find-btn-wrap'))),
                findBtnToggleReplace: globalThis.__npTrace("64730:64780:CallExpression", globalThis.__npTrace("64730:64738:Identifier", document).getElementById(globalThis.__npTrace("64754:64779:StringLiteral", 'find-btn-toggle-replace'))),
                findBtnClose: globalThis.__npTrace("64804:64845:CallExpression", globalThis.__npTrace("64804:64812:Identifier", document).getElementById(globalThis.__npTrace("64828:64844:StringLiteral", 'find-btn-close'))),
                btnDoReplace: globalThis.__npTrace("64869:64910:CallExpression", globalThis.__npTrace("64869:64877:Identifier", document).getElementById(globalThis.__npTrace("64893:64909:StringLiteral", 'btn-do-replace'))),
                btnDoReplaceAll: globalThis.__npTrace("64937:64982:CallExpression", globalThis.__npTrace("64937:64945:Identifier", document).getElementById(globalThis.__npTrace("64961:64981:StringLiteral", 'btn-do-replace-all'))),
                modalOverlay: globalThis.__npTrace("65006:65046:CallExpression", globalThis.__npTrace("65006:65014:Identifier", document).getElementById(globalThis.__npTrace("65030:65045:StringLiteral", 'notepad-modal'))),
                dialogTitle: globalThis.__npTrace("65069:65113:CallExpression", globalThis.__npTrace("65069:65077:Identifier", document).getElementById(globalThis.__npTrace("65093:65112:StringLiteral", 'dialog-title-text'))),
                dialogMessage: globalThis.__npTrace("65138:65184:CallExpression", globalThis.__npTrace("65138:65146:Identifier", document).getElementById(globalThis.__npTrace("65162:65183:StringLiteral", 'dialog-message-text'))),
                dialogCustomBody: globalThis.__npTrace("65212:65257:CallExpression", globalThis.__npTrace("65212:65220:Identifier", document).getElementById(globalThis.__npTrace("65236:65256:StringLiteral", 'dialog-custom-body'))),
                dialogButtons: globalThis.__npTrace("65282:65329:CallExpression", globalThis.__npTrace("65282:65290:Identifier", document).getElementById(globalThis.__npTrace("65306:65328:StringLiteral", 'dialog-btn-container'))),
                hiddenFileInput: globalThis.__npTrace("65356:65400:CallExpression", globalThis.__npTrace("65356:65364:Identifier", document).getElementById(globalThis.__npTrace("65380:65399:StringLiteral", 'hidden-file-input')))
            })));
            globalThis.__npTrace("65428:65449:CallExpression", globalThis.__npTrace("65428:65432:ThisKeyword", this).syncSettingsUI());
        }
        // --- Tab Management ---
        getActiveTab() {
            return globalThis.__npTrace("65522:65576:BinaryExpression", globalThis.__npTrace("65522:65568:CallExpression", globalThis.__npTrace("65522:65531:PropertyAccessExpression", globalThis.__npTrace("65522:65526:ThisKeyword", this).tabs).find(t => globalThis.__npTrace("65542:65567:BinaryExpression", globalThis.__npTrace("65542:65546:PropertyAccessExpression", globalThis.__npTrace("65542:65543:Identifier", t).id) === globalThis.__npTrace("65551:65567:PropertyAccessExpression", globalThis.__npTrace("65551:65555:ThisKeyword", this).activeTabId)))) || globalThis.__npTrace("65572:65576:NullKeyword", null));
        }
        renderTabs() {
            globalThis.__npTrace("65610:65647:BinaryExpression", globalThis.__npTrace("65610:65632:PropertyAccessExpression", globalThis.__npTrace("65610:65618:PropertyAccessExpression", globalThis.__npTrace("65610:65614:ThisKeyword", this).dom).tabsContainer).innerHTML = globalThis.__npTrace("65645:65647:StringLiteral", ''));
            globalThis.__npTrace("65655:66616:CallExpression", globalThis.__npTrace("65655:65664:PropertyAccessExpression", globalThis.__npTrace("65655:65659:ThisKeyword", this).tabs).forEach(tab => {
                const tabEl = globalThis.__npTrace("65704:65733:CallExpression", globalThis.__npTrace("65704:65712:Identifier", document).createElement(globalThis.__npTrace("65727:65732:StringLiteral", 'div')));
                globalThis.__npTrace("65743:65856:BinaryExpression", globalThis.__npTrace("65743:65748:Identifier", tabEl).className = globalThis.__npTrace("65761:65856:TemplateExpression", `notepad-tab ${globalThis.__npTrace("65776:65819:ConditionalExpression", globalThis.__npTrace("65776:65803:BinaryExpression", globalThis.__npTrace("65776:65782:PropertyAccessExpression", globalThis.__npTrace("65776:65779:Identifier", tab).id) === globalThis.__npTrace("65787:65803:PropertyAccessExpression", globalThis.__npTrace("65787:65791:ThisKeyword", this).activeTabId)) ? globalThis.__npTrace("65806:65814:StringLiteral", 'active') : globalThis.__npTrace("65817:65819:StringLiteral", ''))} ${globalThis.__npTrace("65823:65854:ConditionalExpression", globalThis.__npTrace("65823:65837:PropertyAccessExpression", globalThis.__npTrace("65823:65826:Identifier", tab).isModified) ? globalThis.__npTrace("65840:65849:StringLiteral", 'unsaved') : globalThis.__npTrace("65852:65854:StringLiteral", ''))}`));
                globalThis.__npTrace("65866:65902:BinaryExpression", globalThis.__npTrace("65866:65879:PropertyAccessExpression", globalThis.__npTrace("65866:65871:Identifier", tabEl).dataset).tabId = globalThis.__npTrace("65888:65902:CallExpression", String(globalThis.__npTrace("65895:65901:PropertyAccessExpression", globalThis.__npTrace("65895:65898:Identifier", tab).id))));
                globalThis.__npTrace("65912:65951:BinaryExpression", globalThis.__npTrace("65912:65917:Identifier", tabEl).title = globalThis.__npTrace("65926:65951:BinaryExpression", globalThis.__npTrace("65926:65938:PropertyAccessExpression", globalThis.__npTrace("65926:65929:Identifier", tab).filePath) || globalThis.__npTrace("65942:65951:PropertyAccessExpression", globalThis.__npTrace("65942:65945:Identifier", tab).title)));
                globalThis.__npTrace("65962:66286:BinaryExpression", globalThis.__npTrace("65962:65967:Identifier", tabEl).innerHTML = globalThis.__npTrace("65980:66286:TemplateExpression", `
          <span class="tab-title">${globalThis.__npTrace("66018:66044:CallExpression", globalThis.__npTrace("66018:66022:ThisKeyword", this).escapeHTML(globalThis.__npTrace("66034:66043:PropertyAccessExpression", globalThis.__npTrace("66034:66037:Identifier", tab).title)))}</span>
          <div class="tab-indicator-container">
            <span class="tab-dot" title="Unsaved changes"></span>
            <button class="tab-close-btn" title="Close tab (Ctrl+W)">${globalThis.__npTrace("66238:66249:PropertyAccessExpression", globalThis.__npTrace("66238:66243:Identifier", ICONS).close)}</button>
          </div>
        `));
                globalThis.__npTrace("66297:66554:CallExpression", globalThis.__npTrace("66297:66302:Identifier", tabEl).addEventListener(globalThis.__npTrace("66320:66327:StringLiteral", 'click'), (e) => {
                    if (globalThis.__npTrace("66352:66399:CallExpression", globalThis.__npTrace("66352:66373:ParenthesizedExpression", (globalThis.__npTrace("66353:66372:AsExpression", globalThis.__npTrace("66353:66361:PropertyAccessExpression", globalThis.__npTrace("66353:66354:Identifier", e).target)))).closest(globalThis.__npTrace("66382:66398:StringLiteral", '.tab-close-btn')))) {
                        globalThis.__npTrace("66415:66434:CallExpression", globalThis.__npTrace("66415:66416:Identifier", e).stopPropagation());
                        globalThis.__npTrace("66448:66475:CallExpression", globalThis.__npTrace("66448:66452:ThisKeyword", this).promptCloseTab(globalThis.__npTrace("66468:66474:PropertyAccessExpression", globalThis.__npTrace("66468:66471:Identifier", tab).id)));
                    }
                    else {
                        globalThis.__npTrace("66508:66530:CallExpression", globalThis.__npTrace("66508:66512:ThisKeyword", this).switchTab(globalThis.__npTrace("66523:66529:PropertyAccessExpression", globalThis.__npTrace("66523:66526:Identifier", tab).id)));
                    }
                }));
                globalThis.__npTrace("66565:66606:CallExpression", globalThis.__npTrace("66565:66587:PropertyAccessExpression", globalThis.__npTrace("66565:66573:PropertyAccessExpression", globalThis.__npTrace("66565:66569:ThisKeyword", this).dom).tabsContainer).appendChild(globalThis.__npTrace("66600:66605:Identifier", tabEl)));
            }));
        }
        createNewTab(title = globalThis.__npTrace("66658:66668:StringLiteral", 'Untitled'), content = globalThis.__npTrace("66688:66690:StringLiteral", ''), filePath = globalThis.__npTrace("66718:66722:NullKeyword", null), isMarkdown = globalThis.__npTrace("66737:66742:FalseKeyword", false)) {
            const newTab = globalThis.__npTrace("66767:67091:ObjectLiteralExpression", {
                id: globalThis.__npTrace("66781:66797:PostfixUnaryExpression", globalThis.__npTrace("66781:66785:ThisKeyword", this).nextTabId++),
                title: globalThis.__npTrace("66814:66819:Identifier", title),
                content: globalThis.__npTrace("66838:66845:Identifier", content),
                isModified: globalThis.__npTrace("66867:66872:FalseKeyword", false),
                filePath: globalThis.__npTrace("66892:66900:Identifier", filePath),
                encoding: globalThis.__npTrace("66920:66927:StringLiteral", 'UTF-8'),
                lineEnding: globalThis.__npTrace("66949:67006:ConditionalExpression", globalThis.__npTrace("66949:66973:CallExpression", globalThis.__npTrace("66949:66956:Identifier", content).includes(globalThis.__npTrace("66966:66972:StringLiteral", '\r\n'))) ? globalThis.__npTrace("66976:66992:StringLiteral", 'Windows (CRLF)') : globalThis.__npTrace("66995:67006:StringLiteral", 'Unix (LF)')),
                cursorLine: globalThis.__npTrace("67028:67029:FirstLiteralToken", 1),
                cursorCol: globalThis.__npTrace("67050:67051:FirstLiteralToken", 1),
                isMarkdown: globalThis.__npTrace("67073:67083:Identifier", isMarkdown)
            });
            globalThis.__npTrace("67099:67121:CallExpression", globalThis.__npTrace("67099:67108:PropertyAccessExpression", globalThis.__npTrace("67099:67103:ThisKeyword", this).tabs).push(globalThis.__npTrace("67114:67120:Identifier", newTab)));
            globalThis.__npTrace("67129:67154:CallExpression", globalThis.__npTrace("67129:67133:ThisKeyword", this).switchTab(globalThis.__npTrace("67144:67153:PropertyAccessExpression", globalThis.__npTrace("67144:67150:Identifier", newTab).id)));
            globalThis.__npTrace("67162:67180:CallExpression", globalThis.__npTrace("67162:67166:ThisKeyword", this).saveSession());
        }
        switchTab(tabId) {
            if (globalThis.__npTrace("67230:67246:PropertyAccessExpression", globalThis.__npTrace("67230:67234:ThisKeyword", this).activeTabId)) {
                const prevTab = globalThis.__npTrace("67274:67293:CallExpression", globalThis.__npTrace("67274:67278:ThisKeyword", this).getActiveTab());
                if (globalThis.__npTrace("67307:67314:Identifier", prevTab)) {
                    globalThis.__npTrace("67328:67367:BinaryExpression", globalThis.__npTrace("67328:67335:Identifier", prevTab).content = globalThis.__npTrace("67346:67367:PropertyAccessExpression", globalThis.__npTrace("67346:67361:PropertyAccessExpression", globalThis.__npTrace("67346:67354:PropertyAccessExpression", globalThis.__npTrace("67346:67350:ThisKeyword", this).dom).editor).value));
                    globalThis.__npTrace("67379:67434:BinaryExpression", globalThis.__npTrace("67379:67386:Identifier", prevTab).cursorLine = globalThis.__npTrace("67400:67434:PropertyAccessExpression", globalThis.__npTrace("67400:67429:CallExpression", globalThis.__npTrace("67400:67404:ThisKeyword", this).calculateCursorLineCol()).line));
                    globalThis.__npTrace("67446:67499:BinaryExpression", globalThis.__npTrace("67446:67453:Identifier", prevTab).cursorCol = globalThis.__npTrace("67466:67499:PropertyAccessExpression", globalThis.__npTrace("67466:67495:CallExpression", globalThis.__npTrace("67466:67470:ThisKeyword", this).calculateCursorLineCol()).col));
                }
            }
            globalThis.__npTrace("67526:67550:BinaryExpression", globalThis.__npTrace("67526:67530:ThisKeyword", this).activeTabId = globalThis.__npTrace("67545:67550:Identifier", tabId));
            const curTab = globalThis.__npTrace("67573:67592:CallExpression", globalThis.__npTrace("67573:67577:ThisKeyword", this).getActiveTab());
            if (globalThis.__npTrace("67604:67610:Identifier", curTab)) {
                globalThis.__npTrace("67622:67660:BinaryExpression", globalThis.__npTrace("67622:67637:PropertyAccessExpression", globalThis.__npTrace("67622:67630:PropertyAccessExpression", globalThis.__npTrace("67622:67626:ThisKeyword", this).dom).editor).value = globalThis.__npTrace("67646:67660:PropertyAccessExpression", globalThis.__npTrace("67646:67652:Identifier", curTab).content));
            }
            globalThis.__npTrace("67676:67693:CallExpression", globalThis.__npTrace("67676:67680:ThisKeyword", this).renderTabs());
            globalThis.__npTrace("67701:67723:CallExpression", globalThis.__npTrace("67701:67705:ThisKeyword", this).updateStatusBar());
            globalThis.__npTrace("67731:67754:CallExpression", globalThis.__npTrace("67731:67746:PropertyAccessExpression", globalThis.__npTrace("67731:67739:PropertyAccessExpression", globalThis.__npTrace("67731:67735:ThisKeyword", this).dom).editor).focus());
            globalThis.__npTrace("67762:67780:CallExpression", globalThis.__npTrace("67762:67766:ThisKeyword", this).saveSession());
        }
        promptCloseTab(tabId) {
            const tab = globalThis.__npTrace("67843:67878:CallExpression", globalThis.__npTrace("67843:67852:PropertyAccessExpression", globalThis.__npTrace("67843:67847:ThisKeyword", this).tabs).find(t => globalThis.__npTrace("67863:67877:BinaryExpression", globalThis.__npTrace("67863:67867:PropertyAccessExpression", globalThis.__npTrace("67863:67864:Identifier", t).id) === globalThis.__npTrace("67872:67877:Identifier", tabId))));
            if (globalThis.__npTrace("67890:67894:PrefixUnaryExpression", !globalThis.__npTrace("67891:67894:Identifier", tab)))
                return;
            if (globalThis.__npTrace("67915:67929:PropertyAccessExpression", globalThis.__npTrace("67915:67918:Identifier", tab).isModified)) {
                globalThis.__npTrace("67941:68392:CallExpression", globalThis.__npTrace("67941:67945:ThisKeyword", this).showModal(globalThis.__npTrace("67956:68391:ObjectLiteralExpression", {
                    title: globalThis.__npTrace("67975:67984:StringLiteral", 'Notepad'),
                    message: globalThis.__npTrace("68005:68051:TemplateExpression", `Do you want to save changes to ${globalThis.__npTrace("68039:68048:PropertyAccessExpression", globalThis.__npTrace("68039:68042:Identifier", tab).title)}?`),
                    buttons: globalThis.__npTrace("68072:68381:ArrayLiteralExpression", [
                        globalThis.__npTrace("68086:68247:ObjectLiteralExpression", { text: globalThis.__npTrace("68094:68100:StringLiteral", 'Save'), primary: globalThis.__npTrace("68111:68115:TrueKeyword", true), action: async () => {
                                await globalThis.__npTrace("68161:68178:CallExpression", globalThis.__npTrace("68161:68165:ThisKeyword", this).saveTab(globalThis.__npTrace("68174:68177:Identifier", tab)));
                                globalThis.__npTrace("68196:68216:CallExpression", globalThis.__npTrace("68196:68200:ThisKeyword", this).closeTab(globalThis.__npTrace("68210:68215:Identifier", tabId)));
                            }
                        }),
                        globalThis.__npTrace("68261:68319:ObjectLiteralExpression", { text: globalThis.__npTrace("68269:68281:StringLiteral", "Don't Save"), action: () => globalThis.__npTrace("68297:68317:CallExpression", globalThis.__npTrace("68297:68301:ThisKeyword", this).closeTab(globalThis.__npTrace("68311:68316:Identifier", tabId))) }),
                        globalThis.__npTrace("68333:68369:ObjectLiteralExpression", { text: globalThis.__npTrace("68341:68349:StringLiteral", 'Cancel'), action: () => { } })
                    ])
                })));
            }
            else {
                globalThis.__npTrace("68417:68437:CallExpression", globalThis.__npTrace("68417:68421:ThisKeyword", this).closeTab(globalThis.__npTrace("68431:68436:Identifier", tabId)));
            }
        }
        closeTab(tabId) {
            const idx = globalThis.__npTrace("68502:68542:CallExpression", globalThis.__npTrace("68502:68511:PropertyAccessExpression", globalThis.__npTrace("68502:68506:ThisKeyword", this).tabs).findIndex(t => globalThis.__npTrace("68527:68541:BinaryExpression", globalThis.__npTrace("68527:68531:PropertyAccessExpression", globalThis.__npTrace("68527:68528:Identifier", t).id) === globalThis.__npTrace("68536:68541:Identifier", tabId))));
            if (globalThis.__npTrace("68554:68564:BinaryExpression", globalThis.__npTrace("68554:68557:Identifier", idx) === globalThis.__npTrace("68562:68564:PrefixUnaryExpression", -globalThis.__npTrace("68563:68564:FirstLiteralToken", 1))))
                return;
            globalThis.__npTrace("68581:68605:CallExpression", globalThis.__npTrace("68581:68590:PropertyAccessExpression", globalThis.__npTrace("68581:68585:ThisKeyword", this).tabs).splice(globalThis.__npTrace("68598:68601:Identifier", idx), globalThis.__npTrace("68603:68604:FirstLiteralToken", 1)));
            if (globalThis.__npTrace("68617:68639:BinaryExpression", globalThis.__npTrace("68617:68633:PropertyAccessExpression", globalThis.__npTrace("68617:68626:PropertyAccessExpression", globalThis.__npTrace("68617:68621:ThisKeyword", this).tabs).length) === globalThis.__npTrace("68638:68639:FirstLiteralToken", 0))) {
                globalThis.__npTrace("68651:68684:CallExpression", globalThis.__npTrace("68651:68655:ThisKeyword", this).createNewTab(globalThis.__npTrace("68669:68679:StringLiteral", 'Untitled'), globalThis.__npTrace("68681:68683:StringLiteral", '')));
            }
            else if (globalThis.__npTrace("68703:68729:BinaryExpression", globalThis.__npTrace("68703:68719:PropertyAccessExpression", globalThis.__npTrace("68703:68707:ThisKeyword", this).activeTabId) === globalThis.__npTrace("68724:68729:Identifier", tabId))) {
                const newIdx = globalThis.__npTrace("68756:68776:CallExpression", globalThis.__npTrace("68756:68760:Identifier", Math).max(globalThis.__npTrace("68765:68766:FirstLiteralToken", 0), globalThis.__npTrace("68768:68775:BinaryExpression", globalThis.__npTrace("68768:68771:Identifier", idx) - globalThis.__npTrace("68774:68775:FirstLiteralToken", 1))));
                globalThis.__npTrace("68786:68822:CallExpression", globalThis.__npTrace("68786:68790:ThisKeyword", this).switchTab(globalThis.__npTrace("68801:68821:PropertyAccessExpression", globalThis.__npTrace("68801:68818:ElementAccessExpression", globalThis.__npTrace("68801:68810:PropertyAccessExpression", globalThis.__npTrace("68801:68805:ThisKeyword", this).tabs)[globalThis.__npTrace("68811:68817:Identifier", newIdx)]).id)));
            }
            else {
                globalThis.__npTrace("68847:68864:CallExpression", globalThis.__npTrace("68847:68851:ThisKeyword", this).renderTabs());
            }
            globalThis.__npTrace("68880:68898:CallExpression", globalThis.__npTrace("68880:68884:ThisKeyword", this).saveSession());
        }
        // --- File Operations ---
        async openFileDialog() {
            if (globalThis.__npTrace("68977:69002:PropertyAccessExpression", globalThis.__npTrace("68977:68983:Identifier", window).showOpenFilePicker)) {
                try {
                    const [fileHandle] = await globalThis.__npTrace("69057:69406:CallExpression", globalThis.__npTrace("69057:69063:Identifier", window).showOpenFilePicker(globalThis.__npTrace("69083:69405:ObjectLiteralExpression", {
                        types: globalThis.__npTrace("69104:69364:ArrayLiteralExpression", [
                            globalThis.__npTrace("69120:69350:ObjectLiteralExpression", {
                                description: globalThis.__npTrace("69151:69163:StringLiteral", 'Text Files'),
                                accept: globalThis.__npTrace("69189:69334:ObjectLiteralExpression", {
                                    'text/*': globalThis.__npTrace("69219:69316:ArrayLiteralExpression", [globalThis.__npTrace("69220:69226:StringLiteral", '.txt'), globalThis.__npTrace("69228:69233:StringLiteral", '.md'), globalThis.__npTrace("69235:69242:StringLiteral", '.json'), globalThis.__npTrace("69244:69249:StringLiteral", '.js'), globalThis.__npTrace("69251:69258:StringLiteral", '.html'), globalThis.__npTrace("69260:69266:StringLiteral", '.css'), globalThis.__npTrace("69268:69274:StringLiteral", '.xml'), globalThis.__npTrace("69276:69281:StringLiteral", '.py'), globalThis.__npTrace("69283:69295:StringLiteral", '.gitignore'), globalThis.__npTrace("69297:69301:StringLiteral", '.c'), globalThis.__npTrace("69303:69309:StringLiteral", '.cpp'), globalThis.__npTrace("69311:69315:StringLiteral", '.h')])
                                })
                            })
                        ]),
                        multiple: globalThis.__npTrace("69388:69393:FalseKeyword", false)
                    })));
                    const file = await globalThis.__npTrace("69437:69457:CallExpression", globalThis.__npTrace("69437:69447:Identifier", fileHandle).getFile());
                    const content = await globalThis.__npTrace("69491:69502:CallExpression", globalThis.__npTrace("69491:69495:Identifier", file).text());
                    globalThis.__npTrace("69514:69562:CallExpression", globalThis.__npTrace("69514:69518:ThisKeyword", this).createNewTab(globalThis.__npTrace("69532:69541:PropertyAccessExpression", globalThis.__npTrace("69532:69536:Identifier", file).name), globalThis.__npTrace("69543:69550:Identifier", content), globalThis.__npTrace("69552:69561:PropertyAccessExpression", globalThis.__npTrace("69552:69556:Identifier", file).name)));
                    return;
                }
                catch (err) {
                    if (globalThis.__npTrace("69620:69663:BinaryExpression", globalThis.__npTrace("69620:69646:PropertyAccessExpression", globalThis.__npTrace("69620:69641:ParenthesizedExpression", (globalThis.__npTrace("69621:69640:AsExpression", globalThis.__npTrace("69621:69624:Identifier", err)))).name) === globalThis.__npTrace("69651:69663:StringLiteral", 'AbortError')))
                        return;
                }
            }
            // Fallback: standard input[type=file]
            globalThis.__npTrace("69743:70149:BinaryExpression", globalThis.__npTrace("69743:69767:PropertyAccessExpression", globalThis.__npTrace("69743:69751:PropertyAccessExpression", globalThis.__npTrace("69743:69747:ThisKeyword", this).dom).hiddenFileInput).onchange = (e) => {
                const file = globalThis.__npTrace("69816:69857:ElementAccessExpression", globalThis.__npTrace("69816:69852:PropertyAccessExpression", globalThis.__npTrace("69816:69846:ParenthesizedExpression", (globalThis.__npTrace("69817:69845:AsExpression", globalThis.__npTrace("69817:69825:PropertyAccessExpression", globalThis.__npTrace("69817:69818:Identifier", e).target)))).files)?.[globalThis.__npTrace("69855:69856:FirstLiteralToken", 0)]);
                if (globalThis.__npTrace("69871:69876:PrefixUnaryExpression", !globalThis.__npTrace("69872:69876:Identifier", file)))
                    return;
                const reader = globalThis.__npTrace("69909:69925:NewExpression", new FileReader());
                globalThis.__npTrace("69935:70107:BinaryExpression", globalThis.__npTrace("69935:69941:Identifier", reader).onload = (event) => {
                    globalThis.__npTrace("69974:70049:CallExpression", globalThis.__npTrace("69974:69978:ThisKeyword", this).createNewTab(globalThis.__npTrace("69992:70001:PropertyAccessExpression", globalThis.__npTrace("69992:69996:Identifier", file).name), globalThis.__npTrace("70003:70037:CallExpression", String(globalThis.__npTrace("70010:70036:BinaryExpression", globalThis.__npTrace("70010:70030:PropertyAccessExpression", globalThis.__npTrace("70010:70022:PropertyAccessExpression", globalThis.__npTrace("70010:70015:Identifier", event).target)?.result) ?? globalThis.__npTrace("70034:70036:StringLiteral", '')))), globalThis.__npTrace("70039:70048:PropertyAccessExpression", globalThis.__npTrace("70039:70043:Identifier", file).name)));
                    globalThis.__npTrace("70061:70096:BinaryExpression", globalThis.__npTrace("70061:70085:PropertyAccessExpression", globalThis.__npTrace("70061:70069:PropertyAccessExpression", globalThis.__npTrace("70061:70065:ThisKeyword", this).dom).hiddenFileInput).value = globalThis.__npTrace("70094:70096:StringLiteral", ''));
                });
                globalThis.__npTrace("70117:70140:CallExpression", globalThis.__npTrace("70117:70123:Identifier", reader).readAsText(globalThis.__npTrace("70135:70139:Identifier", file)));
            });
            globalThis.__npTrace("70157:70189:CallExpression", globalThis.__npTrace("70157:70181:PropertyAccessExpression", globalThis.__npTrace("70157:70165:PropertyAccessExpression", globalThis.__npTrace("70157:70161:ThisKeyword", this).dom).hiddenFileInput).click());
        }
        async saveTab(tab, forceSaveAs = globalThis.__npTrace("70257:70262:FalseKeyword", false)) {
            if (globalThis.__npTrace("70276:70280:PrefixUnaryExpression", !globalThis.__npTrace("70277:70280:Identifier", tab)))
                return;
            globalThis.__npTrace("70296:70331:BinaryExpression", globalThis.__npTrace("70296:70299:Identifier", tab).content = globalThis.__npTrace("70310:70331:PropertyAccessExpression", globalThis.__npTrace("70310:70325:PropertyAccessExpression", globalThis.__npTrace("70310:70318:PropertyAccessExpression", globalThis.__npTrace("70310:70314:ThisKeyword", this).dom).editor).value));
            if (globalThis.__npTrace("70344:70407:BinaryExpression", globalThis.__npTrace("70344:70374:BinaryExpression", globalThis.__npTrace("70344:70356:PrefixUnaryExpression", !globalThis.__npTrace("70345:70356:Identifier", forceSaveAs)) && globalThis.__npTrace("70360:70374:PropertyAccessExpression", globalThis.__npTrace("70360:70363:Identifier", tab).fileHandle)) && globalThis.__npTrace("70378:70407:PropertyAccessExpression", globalThis.__npTrace("70378:70392:PropertyAccessExpression", globalThis.__npTrace("70378:70381:Identifier", tab).fileHandle).createWritable))) {
                try {
                    const writable = await globalThis.__npTrace("70458:70489:CallExpression", globalThis.__npTrace("70458:70472:PropertyAccessExpression", globalThis.__npTrace("70458:70461:Identifier", tab).fileHandle).createWritable());
                    await globalThis.__npTrace("70507:70534:CallExpression", globalThis.__npTrace("70507:70515:Identifier", writable).write(globalThis.__npTrace("70522:70533:PropertyAccessExpression", globalThis.__npTrace("70522:70525:Identifier", tab).content)));
                    await globalThis.__npTrace("70552:70568:CallExpression", globalThis.__npTrace("70552:70560:Identifier", writable).close());
                    globalThis.__npTrace("70580:70602:BinaryExpression", globalThis.__npTrace("70580:70583:Identifier", tab).isModified = globalThis.__npTrace("70597:70602:FalseKeyword", false));
                    globalThis.__npTrace("70614:70631:CallExpression", globalThis.__npTrace("70614:70618:ThisKeyword", this).renderTabs());
                    globalThis.__npTrace("70643:70661:CallExpression", globalThis.__npTrace("70643:70647:ThisKeyword", this).saveSession());
                    return;
                }
                catch (e) { }
            }
            if (globalThis.__npTrace("70723:70748:PropertyAccessExpression", globalThis.__npTrace("70723:70729:Identifier", window).showSaveFilePicker)) {
                try {
                    const handle = await globalThis.__npTrace("70797:71248:CallExpression", globalThis.__npTrace("70797:70803:Identifier", window).showSaveFilePicker(globalThis.__npTrace("70823:71247:ObjectLiteralExpression", {
                        suggestedName: globalThis.__npTrace("70852:70938:ConditionalExpression", globalThis.__npTrace("70852:70905:BinaryExpression", globalThis.__npTrace("70852:70878:CallExpression", globalThis.__npTrace("70852:70861:PropertyAccessExpression", globalThis.__npTrace("70852:70855:Identifier", tab).title).endsWith(globalThis.__npTrace("70871:70877:StringLiteral", '.txt'))) || globalThis.__npTrace("70882:70905:CallExpression", globalThis.__npTrace("70882:70891:PropertyAccessExpression", globalThis.__npTrace("70882:70885:Identifier", tab).title).includes(globalThis.__npTrace("70901:70904:StringLiteral", '.')))) ? globalThis.__npTrace("70908:70917:PropertyAccessExpression", globalThis.__npTrace("70908:70911:Identifier", tab).title) : globalThis.__npTrace("70920:70938:TemplateExpression", `${globalThis.__npTrace("70923:70932:PropertyAccessExpression", globalThis.__npTrace("70923:70926:Identifier", tab).title)}.txt`)),
                        types: globalThis.__npTrace("70959:71235:ArrayLiteralExpression", [
                            globalThis.__npTrace("70975:71098:ObjectLiteralExpression", {
                                description: globalThis.__npTrace("71006:71030:StringLiteral", 'Text Documents (*.txt)'),
                                accept: globalThis.__npTrace("71056:71082:ObjectLiteralExpression", { 'text/plain': globalThis.__npTrace("71072:71080:ArrayLiteralExpression", [globalThis.__npTrace("71073:71079:StringLiteral", '.txt')]) })
                            }),
                            globalThis.__npTrace("71114:71221:ObjectLiteralExpression", {
                                description: globalThis.__npTrace("71145:71162:StringLiteral", 'All Files (*.*)'),
                                accept: globalThis.__npTrace("71188:71205:ObjectLiteralExpression", { '*/*': globalThis.__npTrace("71197:71203:ArrayLiteralExpression", [globalThis.__npTrace("71198:71202:StringLiteral", '.*')]) })
                            })
                        ])
                    })));
                    const writable = await globalThis.__npTrace("71283:71306:CallExpression", globalThis.__npTrace("71283:71289:Identifier", handle).createWritable());
                    await globalThis.__npTrace("71324:71351:CallExpression", globalThis.__npTrace("71324:71332:Identifier", writable).write(globalThis.__npTrace("71339:71350:PropertyAccessExpression", globalThis.__npTrace("71339:71342:Identifier", tab).content)));
                    await globalThis.__npTrace("71369:71385:CallExpression", globalThis.__npTrace("71369:71377:Identifier", writable).close());
                    globalThis.__npTrace("71397:71420:BinaryExpression", globalThis.__npTrace("71397:71400:Identifier", tab).title = globalThis.__npTrace("71409:71420:PropertyAccessExpression", globalThis.__npTrace("71409:71415:Identifier", handle).name));
                    globalThis.__npTrace("71432:71455:BinaryExpression", globalThis.__npTrace("71432:71435:Identifier", tab).fileHandle = globalThis.__npTrace("71449:71455:Identifier", handle));
                    globalThis.__npTrace("71467:71489:BinaryExpression", globalThis.__npTrace("71467:71470:Identifier", tab).isModified = globalThis.__npTrace("71484:71489:FalseKeyword", false));
                    globalThis.__npTrace("71501:71518:CallExpression", globalThis.__npTrace("71501:71505:ThisKeyword", this).renderTabs());
                    globalThis.__npTrace("71530:71548:CallExpression", globalThis.__npTrace("71530:71534:ThisKeyword", this).saveSession());
                    return;
                }
                catch (err) {
                    if (globalThis.__npTrace("71606:71649:BinaryExpression", globalThis.__npTrace("71606:71632:PropertyAccessExpression", globalThis.__npTrace("71606:71627:ParenthesizedExpression", (globalThis.__npTrace("71607:71626:AsExpression", globalThis.__npTrace("71607:71610:Identifier", err)))).name) === globalThis.__npTrace("71637:71649:StringLiteral", 'AbortError')))
                        return;
                }
            }
            // Fallback: browser blob download
            const blob = globalThis.__npTrace("71738:71799:NewExpression", new Blob(globalThis.__npTrace("71747:71760:ArrayLiteralExpression", [globalThis.__npTrace("71748:71759:PropertyAccessExpression", globalThis.__npTrace("71748:71751:Identifier", tab).content)]), globalThis.__npTrace("71762:71798:ObjectLiteralExpression", { type: globalThis.__npTrace("71770:71796:StringLiteral", 'text/plain;charset=utf-8') })));
            const a = globalThis.__npTrace("71817:71844:CallExpression", globalThis.__npTrace("71817:71825:Identifier", document).createElement(globalThis.__npTrace("71840:71843:StringLiteral", 'a')));
            globalThis.__npTrace("71852:71886:BinaryExpression", globalThis.__npTrace("71852:71853:Identifier", a).href = globalThis.__npTrace("71861:71886:CallExpression", globalThis.__npTrace("71861:71864:Identifier", URL).createObjectURL(globalThis.__npTrace("71881:71885:Identifier", blob))));
            globalThis.__npTrace("71894:71963:BinaryExpression", globalThis.__npTrace("71894:71895:Identifier", a).download = globalThis.__npTrace("71907:71963:ConditionalExpression", globalThis.__npTrace("71907:71930:CallExpression", globalThis.__npTrace("71907:71916:PropertyAccessExpression", globalThis.__npTrace("71907:71910:Identifier", tab).title).includes(globalThis.__npTrace("71926:71929:StringLiteral", '.'))) ? globalThis.__npTrace("71933:71942:PropertyAccessExpression", globalThis.__npTrace("71933:71936:Identifier", tab).title) : globalThis.__npTrace("71945:71963:TemplateExpression", `${globalThis.__npTrace("71948:71957:PropertyAccessExpression", globalThis.__npTrace("71948:71951:Identifier", tab).title)}.txt`)));
            globalThis.__npTrace("71971:71999:CallExpression", globalThis.__npTrace("71971:71984:PropertyAccessExpression", globalThis.__npTrace("71971:71979:Identifier", document).body).appendChild(globalThis.__npTrace("71997:71998:Identifier", a)));
            globalThis.__npTrace("72007:72016:CallExpression", globalThis.__npTrace("72007:72008:Identifier", a).click());
            globalThis.__npTrace("72024:72052:CallExpression", globalThis.__npTrace("72024:72037:PropertyAccessExpression", globalThis.__npTrace("72024:72032:Identifier", document).body).removeChild(globalThis.__npTrace("72050:72051:Identifier", a)));
            globalThis.__npTrace("72060:72087:CallExpression", globalThis.__npTrace("72060:72063:Identifier", URL).revokeObjectURL(globalThis.__npTrace("72080:72086:PropertyAccessExpression", globalThis.__npTrace("72080:72081:Identifier", a).href)));
            globalThis.__npTrace("72095:72117:BinaryExpression", globalThis.__npTrace("72095:72098:Identifier", tab).isModified = globalThis.__npTrace("72112:72117:FalseKeyword", false));
            globalThis.__npTrace("72125:72142:CallExpression", globalThis.__npTrace("72125:72129:ThisKeyword", this).renderTabs());
            globalThis.__npTrace("72150:72168:CallExpression", globalThis.__npTrace("72150:72154:ThisKeyword", this).saveSession());
        }
        saveAllTabs() {
            globalThis.__npTrace("72203:72285:CallExpression", globalThis.__npTrace("72203:72212:PropertyAccessExpression", globalThis.__npTrace("72203:72207:ThisKeyword", this).tabs).forEach(tab => {
                if (globalThis.__npTrace("72242:72256:PropertyAccessExpression", globalThis.__npTrace("72242:72245:Identifier", tab).isModified))
                    globalThis.__npTrace("72258:72275:CallExpression", globalThis.__npTrace("72258:72262:ThisKeyword", this).saveTab(globalThis.__npTrace("72271:72274:Identifier", tab)));
            }));
        }
        // --- Status Bar & Editor Metrics ---
        calculateCursorLineCol() {
            const textarea = globalThis.__npTrace("72391:72406:PropertyAccessExpression", globalThis.__npTrace("72391:72399:PropertyAccessExpression", globalThis.__npTrace("72391:72395:ThisKeyword", this).dom).editor);
            const pos = globalThis.__npTrace("72426:72454:BinaryExpression", globalThis.__npTrace("72426:72449:PropertyAccessExpression", globalThis.__npTrace("72426:72434:Identifier", textarea).selectionStart) || globalThis.__npTrace("72453:72454:FirstLiteralToken", 0));
            const text = globalThis.__npTrace("72475:72507:CallExpression", globalThis.__npTrace("72475:72489:PropertyAccessExpression", globalThis.__npTrace("72475:72483:Identifier", textarea).value).substring(globalThis.__npTrace("72500:72501:FirstLiteralToken", 0), globalThis.__npTrace("72503:72506:Identifier", pos)));
            const lines = globalThis.__npTrace("72529:72545:CallExpression", globalThis.__npTrace("72529:72533:Identifier", text).split(globalThis.__npTrace("72540:72544:StringLiteral", '\n')));
            const line = globalThis.__npTrace("72566:72578:PropertyAccessExpression", globalThis.__npTrace("72566:72571:Identifier", lines).length);
            const col = globalThis.__npTrace("72598:72632:BinaryExpression", globalThis.__npTrace("72598:72628:PropertyAccessExpression", globalThis.__npTrace("72598:72621:ElementAccessExpression", globalThis.__npTrace("72598:72603:Identifier", lines)[globalThis.__npTrace("72604:72620:BinaryExpression", globalThis.__npTrace("72604:72616:PropertyAccessExpression", globalThis.__npTrace("72604:72609:Identifier", lines).length) - globalThis.__npTrace("72619:72620:FirstLiteralToken", 1))]).length) + globalThis.__npTrace("72631:72632:FirstLiteralToken", 1));
            return globalThis.__npTrace("72647:72660:ObjectLiteralExpression", { line, col });
        }
        updateStatusBar() {
            const activeTab = globalThis.__npTrace("72717:72736:CallExpression", globalThis.__npTrace("72717:72721:ThisKeyword", this).getActiveTab());
            if (globalThis.__npTrace("72748:72758:PrefixUnaryExpression", !globalThis.__npTrace("72749:72758:Identifier", activeTab)))
                return;
            const { line, col } = globalThis.__npTrace("72797:72826:CallExpression", globalThis.__npTrace("72797:72801:ThisKeyword", this).calculateCursorLineCol());
            const textarea = globalThis.__npTrace("72851:72866:PropertyAccessExpression", globalThis.__npTrace("72851:72859:PropertyAccessExpression", globalThis.__npTrace("72851:72855:ThisKeyword", this).dom).editor);
            const selStart = globalThis.__npTrace("72891:72914:PropertyAccessExpression", globalThis.__npTrace("72891:72899:Identifier", textarea).selectionStart);
            const selEnd = globalThis.__npTrace("72937:72958:PropertyAccessExpression", globalThis.__npTrace("72937:72945:Identifier", textarea).selectionEnd);
            const selLength = globalThis.__npTrace("72984:73011:CallExpression", globalThis.__npTrace("72984:72988:Identifier", Math).abs(globalThis.__npTrace("72993:73010:BinaryExpression", globalThis.__npTrace("72993:72999:Identifier", selEnd) - globalThis.__npTrace("73002:73010:Identifier", selStart))));
            globalThis.__npTrace("73020:73079:BinaryExpression", globalThis.__npTrace("73020:73040:PropertyAccessExpression", globalThis.__npTrace("73020:73028:PropertyAccessExpression", globalThis.__npTrace("73020:73024:ThisKeyword", this).dom).sbCursorPos).textContent = globalThis.__npTrace("73055:73079:TemplateExpression", `Ln ${globalThis.__npTrace("73061:73065:Identifier", line)}, Col ${globalThis.__npTrace("73074:73077:Identifier", col)}`));
            if (globalThis.__npTrace("73091:73104:BinaryExpression", globalThis.__npTrace("73091:73100:Identifier", selLength) > globalThis.__npTrace("73103:73104:FirstLiteralToken", 0))) {
                globalThis.__npTrace("73116:73174:BinaryExpression", globalThis.__npTrace("73116:73136:PropertyAccessExpression", globalThis.__npTrace("73116:73124:PropertyAccessExpression", globalThis.__npTrace("73116:73120:ThisKeyword", this).dom).sbCharCount).textContent = globalThis.__npTrace("73151:73174:TemplateExpression", `${globalThis.__npTrace("73154:73163:Identifier", selLength)} selected`));
            }
            else {
                globalThis.__npTrace("73199:73271:BinaryExpression", globalThis.__npTrace("73199:73219:PropertyAccessExpression", globalThis.__npTrace("73199:73207:PropertyAccessExpression", globalThis.__npTrace("73199:73203:ThisKeyword", this).dom).sbCharCount).textContent = globalThis.__npTrace("73234:73271:TemplateExpression", `${globalThis.__npTrace("73237:73258:PropertyAccessExpression", globalThis.__npTrace("73237:73251:PropertyAccessExpression", globalThis.__npTrace("73237:73245:Identifier", textarea).value).length)} characters`));
            }
            globalThis.__npTrace("73288:73369:BinaryExpression", globalThis.__npTrace("73288:73306:PropertyAccessExpression", globalThis.__npTrace("73288:73296:PropertyAccessExpression", globalThis.__npTrace("73288:73292:ThisKeyword", this).dom).sbDocType).textContent = globalThis.__npTrace("73321:73369:ConditionalExpression", globalThis.__npTrace("73321:73341:PropertyAccessExpression", globalThis.__npTrace("73321:73330:Identifier", activeTab).isMarkdown) ? globalThis.__npTrace("73344:73354:StringLiteral", 'Markdown') : globalThis.__npTrace("73357:73369:StringLiteral", 'Plain text')));
            globalThis.__npTrace("73377:73436:BinaryExpression", globalThis.__npTrace("73377:73397:PropertyAccessExpression", globalThis.__npTrace("73377:73385:PropertyAccessExpression", globalThis.__npTrace("73377:73381:ThisKeyword", this).dom).sbZoomLevel).textContent = globalThis.__npTrace("73412:73436:TemplateExpression", `${globalThis.__npTrace("73415:73433:PropertyAccessExpression", globalThis.__npTrace("73415:73428:PropertyAccessExpression", globalThis.__npTrace("73415:73419:ThisKeyword", this).settings).zoom)}%`));
            globalThis.__npTrace("73444:73500:BinaryExpression", globalThis.__npTrace("73444:73465:PropertyAccessExpression", globalThis.__npTrace("73444:73452:PropertyAccessExpression", globalThis.__npTrace("73444:73448:ThisKeyword", this).dom).sbLineEnding).textContent = globalThis.__npTrace("73480:73500:PropertyAccessExpression", globalThis.__npTrace("73480:73489:Identifier", activeTab).lineEnding));
            globalThis.__npTrace("73508:73560:BinaryExpression", globalThis.__npTrace("73508:73527:PropertyAccessExpression", globalThis.__npTrace("73508:73516:PropertyAccessExpression", globalThis.__npTrace("73508:73512:ThisKeyword", this).dom).sbEncoding).textContent = globalThis.__npTrace("73542:73560:PropertyAccessExpression", globalThis.__npTrace("73542:73551:Identifier", activeTab).encoding));
            // Status bar visibility
            globalThis.__npTrace("73600:73680:BinaryExpression", globalThis.__npTrace("73600:73624:PropertyAccessExpression", globalThis.__npTrace("73600:73618:PropertyAccessExpression", globalThis.__npTrace("73600:73608:PropertyAccessExpression", globalThis.__npTrace("73600:73604:ThisKeyword", this).dom).statusBar).style).display = globalThis.__npTrace("73635:73680:ConditionalExpression", globalThis.__npTrace("73635:73662:PropertyAccessExpression", globalThis.__npTrace("73635:73648:PropertyAccessExpression", globalThis.__npTrace("73635:73639:ThisKeyword", this).settings).showStatusBar) ? globalThis.__npTrace("73665:73671:StringLiteral", 'flex') : globalThis.__npTrace("73674:73680:StringLiteral", 'none')));
            globalThis.__npTrace("73688:73781:BinaryExpression", globalThis.__npTrace("73688:73717:PropertyAccessExpression", globalThis.__npTrace("73688:73711:PropertyAccessExpression", globalThis.__npTrace("73688:73696:PropertyAccessExpression", globalThis.__npTrace("73688:73692:ThisKeyword", this).dom).checkStatusBar).style).visibility = globalThis.__npTrace("73731:73781:ConditionalExpression", globalThis.__npTrace("73731:73758:PropertyAccessExpression", globalThis.__npTrace("73731:73744:PropertyAccessExpression", globalThis.__npTrace("73731:73735:ThisKeyword", this).settings).showStatusBar) ? globalThis.__npTrace("73761:73770:StringLiteral", 'visible') : globalThis.__npTrace("73773:73781:StringLiteral", 'hidden')));
            globalThis.__npTrace("73789:73876:BinaryExpression", globalThis.__npTrace("73789:73817:PropertyAccessExpression", globalThis.__npTrace("73789:73811:PropertyAccessExpression", globalThis.__npTrace("73789:73797:PropertyAccessExpression", globalThis.__npTrace("73789:73793:ThisKeyword", this).dom).checkWordWrap).style).visibility = globalThis.__npTrace("73831:73876:ConditionalExpression", globalThis.__npTrace("73831:73853:PropertyAccessExpression", globalThis.__npTrace("73831:73844:PropertyAccessExpression", globalThis.__npTrace("73831:73835:ThisKeyword", this).settings).wordWrap) ? globalThis.__npTrace("73856:73865:StringLiteral", 'visible') : globalThis.__npTrace("73868:73876:StringLiteral", 'hidden')));
        }
        applyEditorStyles() {
            const editor = globalThis.__npTrace("73932:73947:PropertyAccessExpression", globalThis.__npTrace("73932:73940:PropertyAccessExpression", globalThis.__npTrace("73932:73936:ThisKeyword", this).dom).editor);
            globalThis.__npTrace("73955:74023:BinaryExpression", globalThis.__npTrace("73955:73967:PropertyAccessExpression", globalThis.__npTrace("73955:73961:Identifier", editor).style).fontFamily = globalThis.__npTrace("73981:74023:TemplateExpression", `"${globalThis.__npTrace("73985:74009:PropertyAccessExpression", globalThis.__npTrace("73985:73998:PropertyAccessExpression", globalThis.__npTrace("73985:73989:ThisKeyword", this).settings).fontFamily)}", monospace`));
            globalThis.__npTrace("74031:74123:BinaryExpression", globalThis.__npTrace("74031:74043:PropertyAccessExpression", globalThis.__npTrace("74031:74037:Identifier", editor).style).fontSize = globalThis.__npTrace("74055:74123:TemplateExpression", `${globalThis.__npTrace("74058:74119:BinaryExpression", globalThis.__npTrace("74058:74090:CallExpression", parseInt(globalThis.__npTrace("74067:74089:PropertyAccessExpression", globalThis.__npTrace("74067:74080:PropertyAccessExpression", globalThis.__npTrace("74067:74071:ThisKeyword", this).settings).fontSize))) * globalThis.__npTrace("74093:74119:ParenthesizedExpression", (globalThis.__npTrace("74094:74118:BinaryExpression", globalThis.__npTrace("74094:74112:PropertyAccessExpression", globalThis.__npTrace("74094:74107:PropertyAccessExpression", globalThis.__npTrace("74094:74098:ThisKeyword", this).settings).zoom) / globalThis.__npTrace("74115:74118:FirstLiteralToken", 100)))))}pt`));
            if (globalThis.__npTrace("74136:74176:CallExpression", globalThis.__npTrace("74136:74159:PropertyAccessExpression", globalThis.__npTrace("74136:74149:PropertyAccessExpression", globalThis.__npTrace("74136:74140:ThisKeyword", this).settings).fontStyle).includes(globalThis.__npTrace("74169:74175:StringLiteral", 'Bold')))) {
                globalThis.__npTrace("74188:74219:BinaryExpression", globalThis.__npTrace("74188:74200:PropertyAccessExpression", globalThis.__npTrace("74188:74194:Identifier", editor).style).fontWeight = globalThis.__npTrace("74214:74219:StringLiteral", '700'));
            }
            else {
                globalThis.__npTrace("74244:74275:BinaryExpression", globalThis.__npTrace("74244:74256:PropertyAccessExpression", globalThis.__npTrace("74244:74250:Identifier", editor).style).fontWeight = globalThis.__npTrace("74270:74275:StringLiteral", '400'));
            }
            if (globalThis.__npTrace("74296:74338:CallExpression", globalThis.__npTrace("74296:74319:PropertyAccessExpression", globalThis.__npTrace("74296:74309:PropertyAccessExpression", globalThis.__npTrace("74296:74300:ThisKeyword", this).settings).fontStyle).includes(globalThis.__npTrace("74329:74337:StringLiteral", 'Italic')))) {
                globalThis.__npTrace("74350:74383:BinaryExpression", globalThis.__npTrace("74350:74362:PropertyAccessExpression", globalThis.__npTrace("74350:74356:Identifier", editor).style).fontStyle = globalThis.__npTrace("74375:74383:StringLiteral", 'italic'));
            }
            else {
                globalThis.__npTrace("74408:74441:BinaryExpression", globalThis.__npTrace("74408:74420:PropertyAccessExpression", globalThis.__npTrace("74408:74414:Identifier", editor).style).fontStyle = globalThis.__npTrace("74433:74441:StringLiteral", 'normal'));
            }
            if (globalThis.__npTrace("74462:74484:PropertyAccessExpression", globalThis.__npTrace("74462:74475:PropertyAccessExpression", globalThis.__npTrace("74462:74466:ThisKeyword", this).settings).wordWrap)) {
                globalThis.__npTrace("74496:74537:BinaryExpression", globalThis.__npTrace("74496:74502:Identifier", editor).className = globalThis.__npTrace("74515:74537:StringLiteral", 'editor-textarea wrap'));
            }
            else {
                globalThis.__npTrace("74562:74605:BinaryExpression", globalThis.__npTrace("74562:74568:Identifier", editor).className = globalThis.__npTrace("74581:74605:StringLiteral", 'editor-textarea nowrap'));
            }
            // Update sample preview in Settings
            const preview = globalThis.__npTrace("74681:74727:CallExpression", globalThis.__npTrace("74681:74689:Identifier", document).getElementById(globalThis.__npTrace("74705:74726:StringLiteral", 'font-sample-preview')));
            if (globalThis.__npTrace("74739:74746:Identifier", preview)) {
                globalThis.__npTrace("74758:74827:BinaryExpression", globalThis.__npTrace("74758:74771:PropertyAccessExpression", globalThis.__npTrace("74758:74765:Identifier", preview).style).fontFamily = globalThis.__npTrace("74785:74827:TemplateExpression", `"${globalThis.__npTrace("74789:74813:PropertyAccessExpression", globalThis.__npTrace("74789:74802:PropertyAccessExpression", globalThis.__npTrace("74789:74793:ThisKeyword", this).settings).fontFamily)}", monospace`));
                globalThis.__npTrace("74837:74891:BinaryExpression", globalThis.__npTrace("74837:74850:PropertyAccessExpression", globalThis.__npTrace("74837:74844:Identifier", preview).style).fontSize = globalThis.__npTrace("74862:74891:TemplateExpression", `${globalThis.__npTrace("74865:74887:PropertyAccessExpression", globalThis.__npTrace("74865:74878:PropertyAccessExpression", globalThis.__npTrace("74865:74869:ThisKeyword", this).settings).fontSize)}pt`));
                globalThis.__npTrace("74901:74984:BinaryExpression", globalThis.__npTrace("74901:74914:PropertyAccessExpression", globalThis.__npTrace("74901:74908:Identifier", preview).style).fontWeight = globalThis.__npTrace("74928:74984:ConditionalExpression", globalThis.__npTrace("74928:74968:CallExpression", globalThis.__npTrace("74928:74951:PropertyAccessExpression", globalThis.__npTrace("74928:74941:PropertyAccessExpression", globalThis.__npTrace("74928:74932:ThisKeyword", this).settings).fontStyle).includes(globalThis.__npTrace("74961:74967:StringLiteral", 'Bold'))) ? globalThis.__npTrace("74971:74976:StringLiteral", '700') : globalThis.__npTrace("74979:74984:StringLiteral", '400')));
                globalThis.__npTrace("74994:75084:BinaryExpression", globalThis.__npTrace("74994:75007:PropertyAccessExpression", globalThis.__npTrace("74994:75001:Identifier", preview).style).fontStyle = globalThis.__npTrace("75020:75084:ConditionalExpression", globalThis.__npTrace("75020:75062:CallExpression", globalThis.__npTrace("75020:75043:PropertyAccessExpression", globalThis.__npTrace("75020:75033:PropertyAccessExpression", globalThis.__npTrace("75020:75024:ThisKeyword", this).settings).fontStyle).includes(globalThis.__npTrace("75053:75061:StringLiteral", 'Italic'))) ? globalThis.__npTrace("75065:75073:StringLiteral", 'italic') : globalThis.__npTrace("75076:75084:StringLiteral", 'normal')));
            }
        }
        updateActiveTabContent() {
            const activeTab = globalThis.__npTrace("75156:75175:CallExpression", globalThis.__npTrace("75156:75160:ThisKeyword", this).getActiveTab());
            if (globalThis.__npTrace("75187:75196:Identifier", activeTab)) {
                globalThis.__npTrace("75208:75249:BinaryExpression", globalThis.__npTrace("75208:75223:PropertyAccessExpression", globalThis.__npTrace("75208:75216:PropertyAccessExpression", globalThis.__npTrace("75208:75212:ThisKeyword", this).dom).editor).value = globalThis.__npTrace("75232:75249:PropertyAccessExpression", globalThis.__npTrace("75232:75241:Identifier", activeTab).content));
            }
        }
        // --- Find and Replace System ---
        openFind(showReplace = globalThis.__npTrace("75332:75337:FalseKeyword", false)) {
            globalThis.__npTrace("75347:75364:CallExpression", globalThis.__npTrace("75347:75351:ThisKeyword", this).closeMenus());
            globalThis.__npTrace("75372:75407:BinaryExpression", globalThis.__npTrace("75372:75393:PropertyAccessExpression", globalThis.__npTrace("75372:75376:ThisKeyword", this).findReplaceState).isOpen = globalThis.__npTrace("75403:75407:TrueKeyword", true));
            globalThis.__npTrace("75415:75464:BinaryExpression", globalThis.__npTrace("75415:75436:PropertyAccessExpression", globalThis.__npTrace("75415:75419:ThisKeyword", this).findReplaceState).isReplaceOpen = globalThis.__npTrace("75453:75464:Identifier", showReplace));
            globalThis.__npTrace("75472:75519:CallExpression", globalThis.__npTrace("75472:75507:PropertyAccessExpression", globalThis.__npTrace("75472:75497:PropertyAccessExpression", globalThis.__npTrace("75472:75480:PropertyAccessExpression", globalThis.__npTrace("75472:75476:ThisKeyword", this).dom).findReplacePanel).classList).add(globalThis.__npTrace("75512:75518:StringLiteral", 'open')));
            globalThis.__npTrace("75527:75592:BinaryExpression", globalThis.__npTrace("75527:75552:PropertyAccessExpression", globalThis.__npTrace("75527:75546:PropertyAccessExpression", globalThis.__npTrace("75527:75535:PropertyAccessExpression", globalThis.__npTrace("75527:75531:ThisKeyword", this).dom).replaceRow).style).display = globalThis.__npTrace("75563:75592:ConditionalExpression", globalThis.__npTrace("75563:75574:Identifier", showReplace) ? globalThis.__npTrace("75577:75583:StringLiteral", 'flex') : globalThis.__npTrace("75586:75592:StringLiteral", 'none')));
            // Prepopulate with selected text if available
            const selText = globalThis.__npTrace("75670:75787:CallExpression", globalThis.__npTrace("75670:75691:PropertyAccessExpression", globalThis.__npTrace("75670:75685:PropertyAccessExpression", globalThis.__npTrace("75670:75678:PropertyAccessExpression", globalThis.__npTrace("75670:75674:ThisKeyword", this).dom).editor).value).substring(globalThis.__npTrace("75711:75741:PropertyAccessExpression", globalThis.__npTrace("75711:75726:PropertyAccessExpression", globalThis.__npTrace("75711:75719:PropertyAccessExpression", globalThis.__npTrace("75711:75715:ThisKeyword", this).dom).editor).selectionStart), globalThis.__npTrace("75751:75779:PropertyAccessExpression", globalThis.__npTrace("75751:75766:PropertyAccessExpression", globalThis.__npTrace("75751:75759:PropertyAccessExpression", globalThis.__npTrace("75751:75755:ThisKeyword", this).dom).editor).selectionEnd)));
            if (globalThis.__npTrace("75799:75833:BinaryExpression", globalThis.__npTrace("75799:75806:Identifier", selText) && globalThis.__npTrace("75810:75833:PrefixUnaryExpression", !globalThis.__npTrace("75811:75833:CallExpression", globalThis.__npTrace("75811:75818:Identifier", selText).includes(globalThis.__npTrace("75828:75832:StringLiteral", '\n')))))) {
                globalThis.__npTrace("75845:75884:BinaryExpression", globalThis.__npTrace("75845:75868:PropertyAccessExpression", globalThis.__npTrace("75845:75853:PropertyAccessExpression", globalThis.__npTrace("75845:75849:ThisKeyword", this).dom).findQueryInput).value = globalThis.__npTrace("75877:75884:Identifier", selText));
                globalThis.__npTrace("75894:75931:BinaryExpression", globalThis.__npTrace("75894:75915:PropertyAccessExpression", globalThis.__npTrace("75894:75898:ThisKeyword", this).findReplaceState).query = globalThis.__npTrace("75924:75931:Identifier", selText));
            }
            globalThis.__npTrace("75948:75966:CallExpression", globalThis.__npTrace("75948:75952:ThisKeyword", this).executeFind());
            globalThis.__npTrace("75974:76005:CallExpression", globalThis.__npTrace("75974:75997:PropertyAccessExpression", globalThis.__npTrace("75974:75982:PropertyAccessExpression", globalThis.__npTrace("75974:75978:ThisKeyword", this).dom).findQueryInput).focus());
            globalThis.__npTrace("76013:76045:CallExpression", globalThis.__npTrace("76013:76036:PropertyAccessExpression", globalThis.__npTrace("76013:76021:PropertyAccessExpression", globalThis.__npTrace("76013:76017:ThisKeyword", this).dom).findQueryInput).select());
        }
        closeFind() {
            globalThis.__npTrace("76078:76114:BinaryExpression", globalThis.__npTrace("76078:76099:PropertyAccessExpression", globalThis.__npTrace("76078:76082:ThisKeyword", this).findReplaceState).isOpen = globalThis.__npTrace("76109:76114:FalseKeyword", false));
            globalThis.__npTrace("76122:76172:CallExpression", globalThis.__npTrace("76122:76157:PropertyAccessExpression", globalThis.__npTrace("76122:76147:PropertyAccessExpression", globalThis.__npTrace("76122:76130:PropertyAccessExpression", globalThis.__npTrace("76122:76126:ThisKeyword", this).dom).findReplacePanel).classList).remove(globalThis.__npTrace("76165:76171:StringLiteral", 'open')));
            globalThis.__npTrace("76180:76203:CallExpression", globalThis.__npTrace("76180:76195:PropertyAccessExpression", globalThis.__npTrace("76180:76188:PropertyAccessExpression", globalThis.__npTrace("76180:76184:ThisKeyword", this).dom).editor).focus());
        }
        executeFind() {
            const query = globalThis.__npTrace("76252:76281:PropertyAccessExpression", globalThis.__npTrace("76252:76275:PropertyAccessExpression", globalThis.__npTrace("76252:76260:PropertyAccessExpression", globalThis.__npTrace("76252:76256:ThisKeyword", this).dom).findQueryInput).value);
            globalThis.__npTrace("76289:76324:BinaryExpression", globalThis.__npTrace("76289:76310:PropertyAccessExpression", globalThis.__npTrace("76289:76293:ThisKeyword", this).findReplaceState).query = globalThis.__npTrace("76319:76324:Identifier", query));
            const text = globalThis.__npTrace("76345:76366:PropertyAccessExpression", globalThis.__npTrace("76345:76360:PropertyAccessExpression", globalThis.__npTrace("76345:76353:PropertyAccessExpression", globalThis.__npTrace("76345:76349:ThisKeyword", this).dom).editor).value);
            if (globalThis.__npTrace("76379:76385:PrefixUnaryExpression", !globalThis.__npTrace("76380:76385:Identifier", query))) {
                globalThis.__npTrace("76397:76431:BinaryExpression", globalThis.__npTrace("76397:76418:PropertyAccessExpression", globalThis.__npTrace("76397:76401:ThisKeyword", this).findReplaceState).matches = globalThis.__npTrace("76429:76431:ArrayLiteralExpression", []));
                globalThis.__npTrace("76441:76480:BinaryExpression", globalThis.__npTrace("76441:76462:PropertyAccessExpression", globalThis.__npTrace("76441:76445:ThisKeyword", this).findReplaceState).currentIndex = globalThis.__npTrace("76478:76480:PrefixUnaryExpression", -globalThis.__npTrace("76479:76480:FirstLiteralToken", 1)));
                globalThis.__npTrace("76490:76538:BinaryExpression", globalThis.__npTrace("76490:76515:PropertyAccessExpression", globalThis.__npTrace("76490:76498:PropertyAccessExpression", globalThis.__npTrace("76490:76494:ThisKeyword", this).dom).findMatchCounter).textContent = globalThis.__npTrace("76530:76538:StringLiteral", '0 of 0'));
                return;
            }
            const flags = globalThis.__npTrace("76585:76629:ConditionalExpression", globalThis.__npTrace("76585:76616:PropertyAccessExpression", globalThis.__npTrace("76585:76606:PropertyAccessExpression", globalThis.__npTrace("76585:76589:ThisKeyword", this).findReplaceState).matchCase) ? globalThis.__npTrace("76619:76622:StringLiteral", 'g') : globalThis.__npTrace("76625:76629:StringLiteral", 'gi'));
            const escaped = globalThis.__npTrace("76653:76697:CallExpression", globalThis.__npTrace("76653:76658:Identifier", query).replace(globalThis.__npTrace("76667:76688:RegularExpressionLiteral", /[.*+?^${}()|[\]\\]/g), globalThis.__npTrace("76690:76696:StringLiteral", '\\$&')));
            const regex = globalThis.__npTrace("76719:76745:NewExpression", new RegExp(globalThis.__npTrace("76730:76737:Identifier", escaped), globalThis.__npTrace("76739:76744:Identifier", flags)));
            const matches = globalThis.__npTrace("76769:76771:ArrayLiteralExpression", []);
            let match;
            while (globalThis.__npTrace("76804:76839:BinaryExpression", globalThis.__npTrace("76804:76830:ParenthesizedExpression", (globalThis.__npTrace("76805:76829:BinaryExpression", match = globalThis.__npTrace("76813:76829:CallExpression", globalThis.__npTrace("76813:76818:Identifier", regex).exec(globalThis.__npTrace("76824:76828:Identifier", text)))))) !== globalThis.__npTrace("76835:76839:NullKeyword", null))) {
                globalThis.__npTrace("76851:76920:CallExpression", globalThis.__npTrace("76851:76858:Identifier", matches).push(globalThis.__npTrace("76864:76919:ObjectLiteralExpression", { start: globalThis.__npTrace("76873:76884:PropertyAccessExpression", globalThis.__npTrace("76873:76878:Identifier", match).index), end: globalThis.__npTrace("76891:76917:BinaryExpression", globalThis.__npTrace("76891:76902:PropertyAccessExpression", globalThis.__npTrace("76891:76896:Identifier", match).index) + globalThis.__npTrace("76905:76917:PropertyAccessExpression", globalThis.__npTrace("76905:76910:Identifier", query).length)) })));
                if (globalThis.__npTrace("76934:76965:BinaryExpression", globalThis.__npTrace("76934:76949:PropertyAccessExpression", globalThis.__npTrace("76934:76939:Identifier", regex).lastIndex) === globalThis.__npTrace("76954:76965:PropertyAccessExpression", globalThis.__npTrace("76954:76959:Identifier", match).index)))
                    globalThis.__npTrace("76967:76984:PostfixUnaryExpression", globalThis.__npTrace("76967:76972:Identifier", regex).lastIndex++);
            }
            globalThis.__npTrace("77001:77040:BinaryExpression", globalThis.__npTrace("77001:77022:PropertyAccessExpression", globalThis.__npTrace("77001:77005:ThisKeyword", this).findReplaceState).matches = globalThis.__npTrace("77033:77040:Identifier", matches));
            if (globalThis.__npTrace("77052:77070:BinaryExpression", globalThis.__npTrace("77052:77066:PropertyAccessExpression", globalThis.__npTrace("77052:77059:Identifier", matches).length) > globalThis.__npTrace("77069:77070:FirstLiteralToken", 0))) {
                const curPos = globalThis.__npTrace("77097:77127:PropertyAccessExpression", globalThis.__npTrace("77097:77112:PropertyAccessExpression", globalThis.__npTrace("77097:77105:PropertyAccessExpression", globalThis.__npTrace("77097:77101:ThisKeyword", this).dom).editor).selectionStart);
                let bestIdx = globalThis.__npTrace("77151:77192:CallExpression", globalThis.__npTrace("77151:77158:Identifier", matches).findIndex(m => globalThis.__npTrace("77174:77191:BinaryExpression", globalThis.__npTrace("77174:77181:PropertyAccessExpression", globalThis.__npTrace("77174:77175:Identifier", m).start) >= globalThis.__npTrace("77185:77191:Identifier", curPos))));
                if (globalThis.__npTrace("77206:77220:BinaryExpression", globalThis.__npTrace("77206:77213:Identifier", bestIdx) === globalThis.__npTrace("77218:77220:PrefixUnaryExpression", -globalThis.__npTrace("77219:77220:FirstLiteralToken", 1))))
                    globalThis.__npTrace("77222:77233:BinaryExpression", bestIdx = globalThis.__npTrace("77232:77233:FirstLiteralToken", 0));
                globalThis.__npTrace("77243:77287:BinaryExpression", globalThis.__npTrace("77243:77264:PropertyAccessExpression", globalThis.__npTrace("77243:77247:ThisKeyword", this).findReplaceState).currentIndex = globalThis.__npTrace("77280:77287:Identifier", bestIdx));
                globalThis.__npTrace("77297:77322:CallExpression", globalThis.__npTrace("77297:77301:ThisKeyword", this).selectMatch(globalThis.__npTrace("77314:77321:Identifier", bestIdx)));
            }
            else {
                globalThis.__npTrace("77347:77386:BinaryExpression", globalThis.__npTrace("77347:77368:PropertyAccessExpression", globalThis.__npTrace("77347:77351:ThisKeyword", this).findReplaceState).currentIndex = globalThis.__npTrace("77384:77386:PrefixUnaryExpression", -globalThis.__npTrace("77385:77386:FirstLiteralToken", 1)));
                globalThis.__npTrace("77396:77448:BinaryExpression", globalThis.__npTrace("77396:77421:PropertyAccessExpression", globalThis.__npTrace("77396:77404:PropertyAccessExpression", globalThis.__npTrace("77396:77400:ThisKeyword", this).dom).findMatchCounter).textContent = globalThis.__npTrace("77436:77448:StringLiteral", 'No results'));
            }
        }
        selectMatch(index) {
            const matches = globalThis.__npTrace("77520:77549:PropertyAccessExpression", globalThis.__npTrace("77520:77541:PropertyAccessExpression", globalThis.__npTrace("77520:77524:ThisKeyword", this).findReplaceState).matches);
            if (globalThis.__npTrace("77561:77633:BinaryExpression", globalThis.__npTrace("77561:77606:BinaryExpression", globalThis.__npTrace("77561:77593:BinaryExpression", globalThis.__npTrace("77561:77569:PrefixUnaryExpression", !globalThis.__npTrace("77562:77569:Identifier", matches)) || globalThis.__npTrace("77573:77593:BinaryExpression", globalThis.__npTrace("77573:77587:PropertyAccessExpression", globalThis.__npTrace("77573:77580:Identifier", matches).length) === globalThis.__npTrace("77592:77593:FirstLiteralToken", 0))) || globalThis.__npTrace("77597:77606:BinaryExpression", globalThis.__npTrace("77597:77602:Identifier", index) < globalThis.__npTrace("77605:77606:FirstLiteralToken", 0))) || globalThis.__npTrace("77610:77633:BinaryExpression", globalThis.__npTrace("77610:77615:Identifier", index) >= globalThis.__npTrace("77619:77633:PropertyAccessExpression", globalThis.__npTrace("77619:77626:Identifier", matches).length)))) {
                globalThis.__npTrace("77645:77693:BinaryExpression", globalThis.__npTrace("77645:77670:PropertyAccessExpression", globalThis.__npTrace("77645:77653:PropertyAccessExpression", globalThis.__npTrace("77645:77649:ThisKeyword", this).dom).findMatchCounter).textContent = globalThis.__npTrace("77685:77693:StringLiteral", '0 of 0'));
                return;
            }
            globalThis.__npTrace("77725:77767:BinaryExpression", globalThis.__npTrace("77725:77746:PropertyAccessExpression", globalThis.__npTrace("77725:77729:ThisKeyword", this).findReplaceState).currentIndex = globalThis.__npTrace("77762:77767:Identifier", index));
            const match = globalThis.__npTrace("77789:77803:ElementAccessExpression", globalThis.__npTrace("77789:77796:Identifier", matches)[globalThis.__npTrace("77797:77802:Identifier", index)]);
            globalThis.__npTrace("77811:77868:CallExpression", globalThis.__npTrace("77811:77826:PropertyAccessExpression", globalThis.__npTrace("77811:77819:PropertyAccessExpression", globalThis.__npTrace("77811:77815:ThisKeyword", this).dom).editor).setSelectionRange(globalThis.__npTrace("77845:77856:PropertyAccessExpression", globalThis.__npTrace("77845:77850:Identifier", match).start), globalThis.__npTrace("77858:77867:PropertyAccessExpression", globalThis.__npTrace("77858:77863:Identifier", match).end)));
            globalThis.__npTrace("77876:77951:BinaryExpression", globalThis.__npTrace("77876:77901:PropertyAccessExpression", globalThis.__npTrace("77876:77884:PropertyAccessExpression", globalThis.__npTrace("77876:77880:ThisKeyword", this).dom).findMatchCounter).textContent = globalThis.__npTrace("77916:77951:TemplateExpression", `${globalThis.__npTrace("77919:77928:BinaryExpression", globalThis.__npTrace("77919:77924:Identifier", index) + globalThis.__npTrace("77927:77928:FirstLiteralToken", 1))} of ${globalThis.__npTrace("77935:77949:PropertyAccessExpression", globalThis.__npTrace("77935:77942:Identifier", matches).length)}`));
            globalThis.__npTrace("77959:77981:CallExpression", globalThis.__npTrace("77959:77963:ThisKeyword", this).updateStatusBar());
        }
        findNext() {
            if (globalThis.__npTrace("78017:78059:BinaryExpression", globalThis.__npTrace("78017:78053:PropertyAccessExpression", globalThis.__npTrace("78017:78046:PropertyAccessExpression", globalThis.__npTrace("78017:78038:PropertyAccessExpression", globalThis.__npTrace("78017:78021:ThisKeyword", this).findReplaceState).matches).length) === globalThis.__npTrace("78058:78059:FirstLiteralToken", 0))) {
                globalThis.__npTrace("78071:78089:CallExpression", globalThis.__npTrace("78071:78075:ThisKeyword", this).executeFind());
                return;
            }
            let next = globalThis.__npTrace("78132:78170:BinaryExpression", globalThis.__npTrace("78132:78166:PropertyAccessExpression", globalThis.__npTrace("78132:78153:PropertyAccessExpression", globalThis.__npTrace("78132:78136:ThisKeyword", this).findReplaceState).currentIndex) + globalThis.__npTrace("78169:78170:FirstLiteralToken", 1));
            if (globalThis.__npTrace("78182:78226:BinaryExpression", globalThis.__npTrace("78182:78186:Identifier", next) >= globalThis.__npTrace("78190:78226:PropertyAccessExpression", globalThis.__npTrace("78190:78219:PropertyAccessExpression", globalThis.__npTrace("78190:78211:PropertyAccessExpression", globalThis.__npTrace("78190:78194:ThisKeyword", this).findReplaceState).matches).length))) {
                if (globalThis.__npTrace("78242:78274:PropertyAccessExpression", globalThis.__npTrace("78242:78263:PropertyAccessExpression", globalThis.__npTrace("78242:78246:ThisKeyword", this).findReplaceState).wrapAround))
                    globalThis.__npTrace("78276:78284:BinaryExpression", next = globalThis.__npTrace("78283:78284:FirstLiteralToken", 0));
                else
                    return;
            }
            globalThis.__npTrace("78321:78343:CallExpression", globalThis.__npTrace("78321:78325:ThisKeyword", this).selectMatch(globalThis.__npTrace("78338:78342:Identifier", next)));
        }
        findPrev() {
            if (globalThis.__npTrace("78379:78421:BinaryExpression", globalThis.__npTrace("78379:78415:PropertyAccessExpression", globalThis.__npTrace("78379:78408:PropertyAccessExpression", globalThis.__npTrace("78379:78400:PropertyAccessExpression", globalThis.__npTrace("78379:78383:ThisKeyword", this).findReplaceState).matches).length) === globalThis.__npTrace("78420:78421:FirstLiteralToken", 0))) {
                globalThis.__npTrace("78433:78451:CallExpression", globalThis.__npTrace("78433:78437:ThisKeyword", this).executeFind());
                return;
            }
            let prev = globalThis.__npTrace("78494:78532:BinaryExpression", globalThis.__npTrace("78494:78528:PropertyAccessExpression", globalThis.__npTrace("78494:78515:PropertyAccessExpression", globalThis.__npTrace("78494:78498:ThisKeyword", this).findReplaceState).currentIndex) - globalThis.__npTrace("78531:78532:FirstLiteralToken", 1));
            if (globalThis.__npTrace("78544:78552:BinaryExpression", globalThis.__npTrace("78544:78548:Identifier", prev) < globalThis.__npTrace("78551:78552:FirstLiteralToken", 0))) {
                if (globalThis.__npTrace("78568:78600:PropertyAccessExpression", globalThis.__npTrace("78568:78589:PropertyAccessExpression", globalThis.__npTrace("78568:78572:ThisKeyword", this).findReplaceState).wrapAround))
                    globalThis.__npTrace("78602:78649:BinaryExpression", prev = globalThis.__npTrace("78609:78649:BinaryExpression", globalThis.__npTrace("78609:78645:PropertyAccessExpression", globalThis.__npTrace("78609:78638:PropertyAccessExpression", globalThis.__npTrace("78609:78630:PropertyAccessExpression", globalThis.__npTrace("78609:78613:ThisKeyword", this).findReplaceState).matches).length) - globalThis.__npTrace("78648:78649:FirstLiteralToken", 1)));
                else
                    return;
            }
            globalThis.__npTrace("78686:78708:CallExpression", globalThis.__npTrace("78686:78690:ThisKeyword", this).selectMatch(globalThis.__npTrace("78703:78707:Identifier", prev)));
        }
        replaceCurrent() {
            if (globalThis.__npTrace("78750:78837:BinaryExpression", globalThis.__npTrace("78750:78792:BinaryExpression", globalThis.__npTrace("78750:78786:PropertyAccessExpression", globalThis.__npTrace("78750:78779:PropertyAccessExpression", globalThis.__npTrace("78750:78771:PropertyAccessExpression", globalThis.__npTrace("78750:78754:ThisKeyword", this).findReplaceState).matches).length) === globalThis.__npTrace("78791:78792:FirstLiteralToken", 0)) || globalThis.__npTrace("78796:78837:BinaryExpression", globalThis.__npTrace("78796:78830:PropertyAccessExpression", globalThis.__npTrace("78796:78817:PropertyAccessExpression", globalThis.__npTrace("78796:78800:ThisKeyword", this).findReplaceState).currentIndex) === globalThis.__npTrace("78835:78837:PrefixUnaryExpression", -globalThis.__npTrace("78836:78837:FirstLiteralToken", 1)))))
                return;
            const replaceWith = globalThis.__npTrace("78873:78905:PropertyAccessExpression", globalThis.__npTrace("78873:78899:PropertyAccessExpression", globalThis.__npTrace("78873:78881:PropertyAccessExpression", globalThis.__npTrace("78873:78877:ThisKeyword", this).dom).replaceQueryInput).value);
            const match = globalThis.__npTrace("78927:78992:ElementAccessExpression", globalThis.__npTrace("78927:78956:PropertyAccessExpression", globalThis.__npTrace("78927:78948:PropertyAccessExpression", globalThis.__npTrace("78927:78931:ThisKeyword", this).findReplaceState).matches)[globalThis.__npTrace("78957:78991:PropertyAccessExpression", globalThis.__npTrace("78957:78978:PropertyAccessExpression", globalThis.__npTrace("78957:78961:ThisKeyword", this).findReplaceState).currentIndex)]);
            const textarea = globalThis.__npTrace("79018:79033:PropertyAccessExpression", globalThis.__npTrace("79018:79026:PropertyAccessExpression", globalThis.__npTrace("79018:79022:ThisKeyword", this).dom).editor);
            const val = globalThis.__npTrace("79053:79067:PropertyAccessExpression", globalThis.__npTrace("79053:79061:Identifier", textarea).value);
            globalThis.__npTrace("79075:79162:BinaryExpression", globalThis.__npTrace("79075:79083:Identifier", textarea).value = globalThis.__npTrace("79092:79162:BinaryExpression", globalThis.__npTrace("79092:79135:BinaryExpression", globalThis.__npTrace("79092:79121:CallExpression", globalThis.__npTrace("79092:79095:Identifier", val).substring(globalThis.__npTrace("79106:79107:FirstLiteralToken", 0), globalThis.__npTrace("79109:79120:PropertyAccessExpression", globalThis.__npTrace("79109:79114:Identifier", match).start))) + globalThis.__npTrace("79124:79135:Identifier", replaceWith)) + globalThis.__npTrace("79138:79162:CallExpression", globalThis.__npTrace("79138:79141:Identifier", val).substring(globalThis.__npTrace("79152:79161:PropertyAccessExpression", globalThis.__npTrace("79152:79157:Identifier", match).end)))));
            const activeTab = globalThis.__npTrace("79189:79208:CallExpression", globalThis.__npTrace("79189:79193:ThisKeyword", this).getActiveTab());
            if (globalThis.__npTrace("79220:79229:Identifier", activeTab)) {
                globalThis.__npTrace("79241:79275:BinaryExpression", globalThis.__npTrace("79241:79250:Identifier", activeTab).content = globalThis.__npTrace("79261:79275:PropertyAccessExpression", globalThis.__npTrace("79261:79269:Identifier", textarea).value));
                globalThis.__npTrace("79285:79312:BinaryExpression", globalThis.__npTrace("79285:79294:Identifier", activeTab).isModified = globalThis.__npTrace("79308:79312:TrueKeyword", true));
            }
            globalThis.__npTrace("79328:79345:CallExpression", globalThis.__npTrace("79328:79332:ThisKeyword", this).renderTabs());
            globalThis.__npTrace("79353:79371:CallExpression", globalThis.__npTrace("79353:79357:ThisKeyword", this).executeFind());
        }
        replaceAll() {
            const query = globalThis.__npTrace("79419:79448:PropertyAccessExpression", globalThis.__npTrace("79419:79442:PropertyAccessExpression", globalThis.__npTrace("79419:79427:PropertyAccessExpression", globalThis.__npTrace("79419:79423:ThisKeyword", this).dom).findQueryInput).value);
            if (globalThis.__npTrace("79460:79466:PrefixUnaryExpression", !globalThis.__npTrace("79461:79466:Identifier", query)))
                return;
            const replaceWith = globalThis.__npTrace("79502:79534:PropertyAccessExpression", globalThis.__npTrace("79502:79528:PropertyAccessExpression", globalThis.__npTrace("79502:79510:PropertyAccessExpression", globalThis.__npTrace("79502:79506:ThisKeyword", this).dom).replaceQueryInput).value);
            const flags = globalThis.__npTrace("79556:79600:ConditionalExpression", globalThis.__npTrace("79556:79587:PropertyAccessExpression", globalThis.__npTrace("79556:79577:PropertyAccessExpression", globalThis.__npTrace("79556:79560:ThisKeyword", this).findReplaceState).matchCase) ? globalThis.__npTrace("79590:79593:StringLiteral", 'g') : globalThis.__npTrace("79596:79600:StringLiteral", 'gi'));
            const escaped = globalThis.__npTrace("79624:79668:CallExpression", globalThis.__npTrace("79624:79629:Identifier", query).replace(globalThis.__npTrace("79638:79659:RegularExpressionLiteral", /[.*+?^${}()|[\]\\]/g), globalThis.__npTrace("79661:79667:StringLiteral", '\\$&')));
            const regex = globalThis.__npTrace("79690:79716:NewExpression", new RegExp(globalThis.__npTrace("79701:79708:Identifier", escaped), globalThis.__npTrace("79710:79715:Identifier", flags)));
            const textarea = globalThis.__npTrace("79742:79757:PropertyAccessExpression", globalThis.__npTrace("79742:79750:PropertyAccessExpression", globalThis.__npTrace("79742:79746:ThisKeyword", this).dom).editor);
            globalThis.__npTrace("79765:79824:BinaryExpression", globalThis.__npTrace("79765:79773:Identifier", textarea).value = globalThis.__npTrace("79782:79824:CallExpression", globalThis.__npTrace("79782:79796:PropertyAccessExpression", globalThis.__npTrace("79782:79790:Identifier", textarea).value).replace(globalThis.__npTrace("79805:79810:Identifier", regex), globalThis.__npTrace("79812:79823:Identifier", replaceWith))));
            const activeTab = globalThis.__npTrace("79851:79870:CallExpression", globalThis.__npTrace("79851:79855:ThisKeyword", this).getActiveTab());
            if (globalThis.__npTrace("79882:79891:Identifier", activeTab)) {
                globalThis.__npTrace("79903:79937:BinaryExpression", globalThis.__npTrace("79903:79912:Identifier", activeTab).content = globalThis.__npTrace("79923:79937:PropertyAccessExpression", globalThis.__npTrace("79923:79931:Identifier", textarea).value));
                globalThis.__npTrace("79947:79974:BinaryExpression", globalThis.__npTrace("79947:79956:Identifier", activeTab).isModified = globalThis.__npTrace("79970:79974:TrueKeyword", true));
            }
            globalThis.__npTrace("79990:80007:CallExpression", globalThis.__npTrace("79990:79994:ThisKeyword", this).renderTabs());
            globalThis.__npTrace("80015:80033:CallExpression", globalThis.__npTrace("80015:80019:ThisKeyword", this).executeFind());
        }
        // --- Go To Line Dialog ---
        showGoToDialog() {
            globalThis.__npTrace("80104:80121:CallExpression", globalThis.__npTrace("80104:80108:ThisKeyword", this).closeMenus());
            const current = globalThis.__npTrace("80145:80179:PropertyAccessExpression", globalThis.__npTrace("80145:80174:CallExpression", globalThis.__npTrace("80145:80149:ThisKeyword", this).calculateCursorLineCol()).line);
            globalThis.__npTrace("80187:81073:CallExpression", globalThis.__npTrace("80187:80191:ThisKeyword", this).showModal(globalThis.__npTrace("80202:81072:ObjectLiteralExpression", {
                title: globalThis.__npTrace("80219:80231:StringLiteral", 'Go to line'),
                message: globalThis.__npTrace("80250:80264:StringLiteral", 'Line number:'),
                hasInput: globalThis.__npTrace("80284:80288:TrueKeyword", true),
                inputValue: globalThis.__npTrace("80310:80328:CallExpression", globalThis.__npTrace("80310:80317:Identifier", current).toString()),
                buttons: globalThis.__npTrace("80347:81064:ArrayLiteralExpression", [
                    globalThis.__npTrace("80359:81006:ObjectLiteralExpression", {
                        text: globalThis.__npTrace("80379:80386:StringLiteral", 'Go to'),
                        primary: globalThis.__npTrace("80409:80413:TrueKeyword", true),
                        action: (lineVal) => {
                            const lineNum = globalThis.__npTrace("80480:80507:CallExpression", parseInt(globalThis.__npTrace("80489:80502:BinaryExpression", globalThis.__npTrace("80489:80496:Identifier", lineVal) ?? globalThis.__npTrace("80500:80502:StringLiteral", '')), globalThis.__npTrace("80504:80506:FirstLiteralToken", 10)));
                            if (globalThis.__npTrace("80527:80557:BinaryExpression", globalThis.__npTrace("80527:80542:PrefixUnaryExpression", !globalThis.__npTrace("80528:80542:CallExpression", isNaN(globalThis.__npTrace("80534:80541:Identifier", lineNum)))) && globalThis.__npTrace("80546:80557:BinaryExpression", globalThis.__npTrace("80546:80553:Identifier", lineNum) > globalThis.__npTrace("80556:80557:FirstLiteralToken", 0)))) {
                                const lines = globalThis.__npTrace("80591:80624:CallExpression", globalThis.__npTrace("80591:80612:PropertyAccessExpression", globalThis.__npTrace("80591:80606:PropertyAccessExpression", globalThis.__npTrace("80591:80599:PropertyAccessExpression", globalThis.__npTrace("80591:80595:ThisKeyword", this).dom).editor).value).split(globalThis.__npTrace("80619:80623:StringLiteral", '\n')));
                                let targetPos = globalThis.__npTrace("80658:80659:FirstLiteralToken", 0);
                                for (let i = globalThis.__npTrace("80690:80691:FirstLiteralToken", 0); globalThis.__npTrace("80693:80732:BinaryExpression", globalThis.__npTrace("80693:80694:Identifier", i) < globalThis.__npTrace("80697:80732:CallExpression", globalThis.__npTrace("80697:80701:Identifier", Math).min(globalThis.__npTrace("80706:80717:BinaryExpression", globalThis.__npTrace("80706:80713:Identifier", lineNum) - globalThis.__npTrace("80716:80717:FirstLiteralToken", 1)), globalThis.__npTrace("80719:80731:PropertyAccessExpression", globalThis.__npTrace("80719:80724:Identifier", lines).length)))); globalThis.__npTrace("80734:80737:PostfixUnaryExpression", i++)) {
                                    globalThis.__npTrace("80759:80791:BinaryExpression", targetPos += globalThis.__npTrace("80772:80791:BinaryExpression", globalThis.__npTrace("80772:80787:PropertyAccessExpression", globalThis.__npTrace("80772:80780:ElementAccessExpression", globalThis.__npTrace("80772:80777:Identifier", lines)[globalThis.__npTrace("80778:80779:Identifier", i)]).length) + globalThis.__npTrace("80790:80791:FirstLiteralToken", 1)));
                                }
                                globalThis.__npTrace("80827:80882:CallExpression", globalThis.__npTrace("80827:80842:PropertyAccessExpression", globalThis.__npTrace("80827:80835:PropertyAccessExpression", globalThis.__npTrace("80827:80831:ThisKeyword", this).dom).editor).setSelectionRange(globalThis.__npTrace("80861:80870:Identifier", targetPos), globalThis.__npTrace("80872:80881:Identifier", targetPos)));
                                globalThis.__npTrace("80900:80923:CallExpression", globalThis.__npTrace("80900:80915:PropertyAccessExpression", globalThis.__npTrace("80900:80908:PropertyAccessExpression", globalThis.__npTrace("80900:80904:ThisKeyword", this).dom).editor).focus());
                                globalThis.__npTrace("80941:80963:CallExpression", globalThis.__npTrace("80941:80945:ThisKeyword", this).updateStatusBar());
                            }
                        }
                    }),
                    globalThis.__npTrace("81018:81054:ObjectLiteralExpression", { text: globalThis.__npTrace("81026:81034:StringLiteral", 'Cancel'), action: () => { } })
                ])
            })));
        }
        // --- Modal Dialog System ---
        showModal({ title, message, hasInput = globalThis.__npTrace("81160:81165:FalseKeyword", false), inputValue = globalThis.__npTrace("81180:81182:StringLiteral", ''), buttons = globalThis.__npTrace("81194:81196:ArrayLiteralExpression", []) }) {
            globalThis.__npTrace("81222:81262:BinaryExpression", globalThis.__npTrace("81222:81242:PropertyAccessExpression", globalThis.__npTrace("81222:81230:PropertyAccessExpression", globalThis.__npTrace("81222:81226:ThisKeyword", this).dom).dialogTitle).textContent = globalThis.__npTrace("81257:81262:Identifier", title));
            globalThis.__npTrace("81270:81314:BinaryExpression", globalThis.__npTrace("81270:81292:PropertyAccessExpression", globalThis.__npTrace("81270:81278:PropertyAccessExpression", globalThis.__npTrace("81270:81274:ThisKeyword", this).dom).dialogMessage).textContent = globalThis.__npTrace("81307:81314:Identifier", message));
            globalThis.__npTrace("81322:81362:BinaryExpression", globalThis.__npTrace("81322:81347:PropertyAccessExpression", globalThis.__npTrace("81322:81330:PropertyAccessExpression", globalThis.__npTrace("81322:81326:ThisKeyword", this).dom).dialogCustomBody).innerHTML = globalThis.__npTrace("81360:81362:StringLiteral", ''));
            let inputEl = globalThis.__npTrace("81385:81389:NullKeyword", null);
            if (globalThis.__npTrace("81401:81409:Identifier", hasInput)) {
                globalThis.__npTrace("81421:81462:BinaryExpression", inputEl = globalThis.__npTrace("81431:81462:CallExpression", globalThis.__npTrace("81431:81439:Identifier", document).createElement(globalThis.__npTrace("81454:81461:StringLiteral", 'input'))));
                globalThis.__npTrace("81472:81506:BinaryExpression", globalThis.__npTrace("81472:81479:Identifier", inputEl).className = globalThis.__npTrace("81492:81506:StringLiteral", 'dialog-input'));
                globalThis.__npTrace("81516:81537:BinaryExpression", globalThis.__npTrace("81516:81523:Identifier", inputEl).type = globalThis.__npTrace("81531:81537:StringLiteral", 'text'));
                globalThis.__npTrace("81547:81573:BinaryExpression", globalThis.__npTrace("81547:81554:Identifier", inputEl).value = globalThis.__npTrace("81563:81573:Identifier", inputValue));
                globalThis.__npTrace("81583:81629:CallExpression", globalThis.__npTrace("81583:81608:PropertyAccessExpression", globalThis.__npTrace("81583:81591:PropertyAccessExpression", globalThis.__npTrace("81583:81587:ThisKeyword", this).dom).dialogCustomBody).appendChild(globalThis.__npTrace("81621:81628:Identifier", inputEl)));
            }
            globalThis.__npTrace("81646:81683:BinaryExpression", globalThis.__npTrace("81646:81668:PropertyAccessExpression", globalThis.__npTrace("81646:81654:PropertyAccessExpression", globalThis.__npTrace("81646:81650:ThisKeyword", this).dom).dialogButtons).innerHTML = globalThis.__npTrace("81681:81683:StringLiteral", ''));
            globalThis.__npTrace("81691:82175:CallExpression", globalThis.__npTrace("81691:81698:Identifier", buttons).forEach(btnConfig => {
                const btn = globalThis.__npTrace("81742:81774:CallExpression", globalThis.__npTrace("81742:81750:Identifier", document).createElement(globalThis.__npTrace("81765:81773:StringLiteral", 'button')));
                globalThis.__npTrace("81784:81850:BinaryExpression", globalThis.__npTrace("81784:81787:Identifier", btn).className = globalThis.__npTrace("81800:81850:TemplateExpression", `fluent-btn ${globalThis.__npTrace("81814:81848:ConditionalExpression", globalThis.__npTrace("81814:81831:PropertyAccessExpression", globalThis.__npTrace("81814:81823:Identifier", btnConfig).primary) ? globalThis.__npTrace("81834:81843:StringLiteral", 'primary') : globalThis.__npTrace("81846:81848:StringLiteral", ''))}`));
                globalThis.__npTrace("81860:81892:BinaryExpression", globalThis.__npTrace("81860:81863:Identifier", btn).textContent = globalThis.__npTrace("81878:81892:PropertyAccessExpression", globalThis.__npTrace("81878:81887:Identifier", btnConfig).text));
                globalThis.__npTrace("81902:82116:CallExpression", globalThis.__npTrace("81902:81905:Identifier", btn).addEventListener(globalThis.__npTrace("81923:81930:StringLiteral", 'click'), () => {
                    globalThis.__npTrace("81950:81996:CallExpression", globalThis.__npTrace("81950:81981:PropertyAccessExpression", globalThis.__npTrace("81950:81971:PropertyAccessExpression", globalThis.__npTrace("81950:81958:PropertyAccessExpression", globalThis.__npTrace("81950:81954:ThisKeyword", this).dom).modalOverlay).classList).remove(globalThis.__npTrace("81989:81995:StringLiteral", 'open')));
                    if (globalThis.__npTrace("82012:82028:PropertyAccessExpression", globalThis.__npTrace("82012:82021:Identifier", btnConfig).action)) {
                        globalThis.__npTrace("82044:82092:CallExpression", globalThis.__npTrace("82044:82053:Identifier", btnConfig).action(globalThis.__npTrace("82061:82091:ConditionalExpression", globalThis.__npTrace("82061:82068:Identifier", inputEl) ? globalThis.__npTrace("82071:82084:PropertyAccessExpression", globalThis.__npTrace("82071:82078:Identifier", inputEl).value) : globalThis.__npTrace("82087:82091:NullKeyword", null))));
                    }
                }));
                globalThis.__npTrace("82126:82165:CallExpression", globalThis.__npTrace("82126:82148:PropertyAccessExpression", globalThis.__npTrace("82126:82134:PropertyAccessExpression", globalThis.__npTrace("82126:82130:ThisKeyword", this).dom).dialogButtons).appendChild(globalThis.__npTrace("82161:82164:Identifier", btn)));
            }));
            globalThis.__npTrace("82184:82227:CallExpression", globalThis.__npTrace("82184:82215:PropertyAccessExpression", globalThis.__npTrace("82184:82205:PropertyAccessExpression", globalThis.__npTrace("82184:82192:PropertyAccessExpression", globalThis.__npTrace("82184:82188:ThisKeyword", this).dom).modalOverlay).classList).add(globalThis.__npTrace("82220:82226:StringLiteral", 'open')));
            if (globalThis.__npTrace("82239:82246:Identifier", inputEl)) {
                globalThis.__npTrace("82258:82273:CallExpression", globalThis.__npTrace("82258:82265:Identifier", inputEl).focus());
                globalThis.__npTrace("82283:82299:CallExpression", globalThis.__npTrace("82283:82290:Identifier", inputEl).select());
                globalThis.__npTrace("82309:82692:CallExpression", globalThis.__npTrace("82309:82316:Identifier", inputEl).addEventListener(globalThis.__npTrace("82334:82343:StringLiteral", 'keydown'), (e) => {
                    if (globalThis.__npTrace("82368:82385:BinaryExpression", globalThis.__npTrace("82368:82373:PropertyAccessExpression", globalThis.__npTrace("82368:82369:Identifier", e).key) === globalThis.__npTrace("82378:82385:StringLiteral", 'Enter'))) {
                        const primaryBtn = globalThis.__npTrace("82420:82517:BinaryExpression", globalThis.__npTrace("82420:82479:CallExpression", globalThis.__npTrace("82420:82442:PropertyAccessExpression", globalThis.__npTrace("82420:82428:PropertyAccessExpression", globalThis.__npTrace("82420:82424:ThisKeyword", this).dom).dialogButtons).querySelector(globalThis.__npTrace("82457:82478:StringLiteral", '.fluent-btn.primary'))) || globalThis.__npTrace("82483:82517:ElementAccessExpression", globalThis.__npTrace("82483:82514:PropertyAccessExpression", globalThis.__npTrace("82483:82505:PropertyAccessExpression", globalThis.__npTrace("82483:82491:PropertyAccessExpression", globalThis.__npTrace("82483:82487:ThisKeyword", this).dom).dialogButtons).children)[globalThis.__npTrace("82515:82516:FirstLiteralToken", 0)]));
                        if (globalThis.__npTrace("82535:82545:Identifier", primaryBtn))
                            globalThis.__npTrace("82547:82565:CallExpression", globalThis.__npTrace("82547:82557:Identifier", primaryBtn).click());
                    }
                    else if (globalThis.__npTrace("82588:82606:BinaryExpression", globalThis.__npTrace("82588:82593:PropertyAccessExpression", globalThis.__npTrace("82588:82589:Identifier", e).key) === globalThis.__npTrace("82598:82606:StringLiteral", 'Escape'))) {
                        globalThis.__npTrace("82622:82668:CallExpression", globalThis.__npTrace("82622:82653:PropertyAccessExpression", globalThis.__npTrace("82622:82643:PropertyAccessExpression", globalThis.__npTrace("82622:82630:PropertyAccessExpression", globalThis.__npTrace("82622:82626:ThisKeyword", this).dom).modalOverlay).classList).remove(globalThis.__npTrace("82661:82667:StringLiteral", 'open')));
                    }
                }));
            }
        }
        // --- Settings Synchronization & View ---
        openSettings(scrollToSection = globalThis.__npTrace("82806:82810:NullKeyword", null)) {
            globalThis.__npTrace("82820:82837:CallExpression", globalThis.__npTrace("82820:82824:ThisKeyword", this).closeMenus());
            globalThis.__npTrace("82845:82888:CallExpression", globalThis.__npTrace("82845:82876:PropertyAccessExpression", globalThis.__npTrace("82845:82866:PropertyAccessExpression", globalThis.__npTrace("82845:82853:PropertyAccessExpression", globalThis.__npTrace("82845:82849:ThisKeyword", this).dom).settingsView).classList).add(globalThis.__npTrace("82881:82887:StringLiteral", 'open')));
            if (globalThis.__npTrace("82900:82915:Identifier", scrollToSection)) {
                const target = globalThis.__npTrace("82942:82982:CallExpression", globalThis.__npTrace("82942:82950:Identifier", document).getElementById(globalThis.__npTrace("82966:82981:Identifier", scrollToSection)));
                if (globalThis.__npTrace("82996:83002:Identifier", target)) {
                    globalThis.__npTrace("83016:83048:CallExpression", globalThis.__npTrace("83016:83032:PropertyAccessExpression", globalThis.__npTrace("83016:83022:Identifier", target).classList).add(globalThis.__npTrace("83037:83047:StringLiteral", 'expanded')));
                    globalThis.__npTrace("83060:83105:CallExpression", globalThis.__npTrace("83060:83066:Identifier", target).scrollIntoView(globalThis.__npTrace("83082:83104:ObjectLiteralExpression", { behavior: globalThis.__npTrace("83094:83102:StringLiteral", 'smooth') })));
                }
            }
        }
        closeSettings() {
            globalThis.__npTrace("83160:83206:CallExpression", globalThis.__npTrace("83160:83191:PropertyAccessExpression", globalThis.__npTrace("83160:83181:PropertyAccessExpression", globalThis.__npTrace("83160:83168:PropertyAccessExpression", globalThis.__npTrace("83160:83164:ThisKeyword", this).dom).settingsView).classList).remove(globalThis.__npTrace("83199:83205:StringLiteral", 'open')));
            globalThis.__npTrace("83214:83237:CallExpression", globalThis.__npTrace("83214:83229:PropertyAccessExpression", globalThis.__npTrace("83214:83222:PropertyAccessExpression", globalThis.__npTrace("83214:83218:ThisKeyword", this).dom).editor).focus());
        }
        syncSettingsUI() {
            // Theme
            const themeSelect = globalThis.__npTrace("83310:83357:CallExpression", globalThis.__npTrace("83310:83318:Identifier", document).getElementById(globalThis.__npTrace("83334:83356:StringLiteral", 'setting-theme-select')));
            if (globalThis.__npTrace("83369:83380:Identifier", themeSelect))
                globalThis.__npTrace("83382:83421:BinaryExpression", globalThis.__npTrace("83382:83393:Identifier", themeSelect).value = globalThis.__npTrace("83402:83421:PropertyAccessExpression", globalThis.__npTrace("83402:83415:PropertyAccessExpression", globalThis.__npTrace("83402:83406:ThisKeyword", this).settings).theme));
            // Font
            const fontFam = globalThis.__npTrace("83460:83506:CallExpression", globalThis.__npTrace("83460:83468:Identifier", document).getElementById(globalThis.__npTrace("83484:83505:StringLiteral", 'setting-font-family')));
            if (globalThis.__npTrace("83518:83525:Identifier", fontFam))
                globalThis.__npTrace("83527:83567:BinaryExpression", globalThis.__npTrace("83527:83534:Identifier", fontFam).value = globalThis.__npTrace("83543:83567:PropertyAccessExpression", globalThis.__npTrace("83543:83556:PropertyAccessExpression", globalThis.__npTrace("83543:83547:ThisKeyword", this).settings).fontFamily));
            const fontStyle = globalThis.__npTrace("83593:83638:CallExpression", globalThis.__npTrace("83593:83601:Identifier", document).getElementById(globalThis.__npTrace("83617:83637:StringLiteral", 'setting-font-style')));
            if (globalThis.__npTrace("83650:83659:Identifier", fontStyle))
                globalThis.__npTrace("83661:83702:BinaryExpression", globalThis.__npTrace("83661:83670:Identifier", fontStyle).value = globalThis.__npTrace("83679:83702:PropertyAccessExpression", globalThis.__npTrace("83679:83692:PropertyAccessExpression", globalThis.__npTrace("83679:83683:ThisKeyword", this).settings).fontStyle));
            const fontSize = globalThis.__npTrace("83727:83771:CallExpression", globalThis.__npTrace("83727:83735:Identifier", document).getElementById(globalThis.__npTrace("83751:83770:StringLiteral", 'setting-font-size')));
            if (globalThis.__npTrace("83783:83791:Identifier", fontSize))
                globalThis.__npTrace("83793:83832:BinaryExpression", globalThis.__npTrace("83793:83801:Identifier", fontSize).value = globalThis.__npTrace("83810:83832:PropertyAccessExpression", globalThis.__npTrace("83810:83823:PropertyAccessExpression", globalThis.__npTrace("83810:83814:ThisKeyword", this).settings).fontSize));
            // Opening files
            const openFiles = globalThis.__npTrace("83882:83930:CallExpression", globalThis.__npTrace("83882:83890:Identifier", document).getElementById(globalThis.__npTrace("83906:83929:StringLiteral", 'setting-opening-files')));
            if (globalThis.__npTrace("83942:83951:Identifier", openFiles))
                globalThis.__npTrace("83953:83997:BinaryExpression", globalThis.__npTrace("83953:83962:Identifier", openFiles).value = globalThis.__npTrace("83971:83997:PropertyAccessExpression", globalThis.__npTrace("83971:83984:PropertyAccessExpression", globalThis.__npTrace("83971:83975:ThisKeyword", this).settings).openingFiles));
            // Toggles
            globalThis.__npTrace("84023:84096:CallExpression", globalThis.__npTrace("84023:84027:ThisKeyword", this).updateToggleState(globalThis.__npTrace("84046:84071:StringLiteral", 'toggle-setting-wordwrap'), globalThis.__npTrace("84073:84095:PropertyAccessExpression", globalThis.__npTrace("84073:84086:PropertyAccessExpression", globalThis.__npTrace("84073:84077:ThisKeyword", this).settings).wordWrap)));
            globalThis.__npTrace("84104:84181:CallExpression", globalThis.__npTrace("84104:84108:ThisKeyword", this).updateToggleState(globalThis.__npTrace("84127:84154:StringLiteral", 'toggle-setting-formatting'), globalThis.__npTrace("84156:84180:PropertyAccessExpression", globalThis.__npTrace("84156:84169:PropertyAccessExpression", globalThis.__npTrace("84156:84160:ThisKeyword", this).settings).formatting)));
            globalThis.__npTrace("84189:84276:CallExpression", globalThis.__npTrace("84189:84193:ThisKeyword", this).updateToggleState(globalThis.__npTrace("84212:84241:StringLiteral", 'toggle-setting-recent-files'), globalThis.__npTrace("84243:84275:PropertyAccessExpression", globalThis.__npTrace("84243:84256:PropertyAccessExpression", globalThis.__npTrace("84243:84247:ThisKeyword", this).settings).recentFilesEnabled)));
            globalThis.__npTrace("84284:84361:CallExpression", globalThis.__npTrace("84284:84288:ThisKeyword", this).updateToggleState(globalThis.__npTrace("84307:84334:StringLiteral", 'toggle-setting-spellcheck'), globalThis.__npTrace("84336:84360:PropertyAccessExpression", globalThis.__npTrace("84336:84349:PropertyAccessExpression", globalThis.__npTrace("84336:84340:ThisKeyword", this).settings).spellCheck)));
        }
        updateToggleState(elementId, isChecked) {
            const el = globalThis.__npTrace("84450:84484:CallExpression", globalThis.__npTrace("84450:84458:Identifier", document).getElementById(globalThis.__npTrace("84474:84483:Identifier", elementId)));
            if (globalThis.__npTrace("84496:84499:PrefixUnaryExpression", !globalThis.__npTrace("84497:84499:Identifier", el)))
                return;
            if (globalThis.__npTrace("84519:84528:Identifier", isChecked)) {
                globalThis.__npTrace("84540:84562:CallExpression", globalThis.__npTrace("84540:84552:PropertyAccessExpression", globalThis.__npTrace("84540:84542:Identifier", el).classList).add(globalThis.__npTrace("84557:84561:StringLiteral", 'on')));
                globalThis.__npTrace("84572:84624:BinaryExpression", globalThis.__npTrace("84572:84605:CallExpression", globalThis.__npTrace("84572:84574:Identifier", el).querySelector(globalThis.__npTrace("84589:84604:StringLiteral", '.toggle-label'))).textContent = globalThis.__npTrace("84620:84624:StringLiteral", 'On'));
            }
            else {
                globalThis.__npTrace("84649:84674:CallExpression", globalThis.__npTrace("84649:84661:PropertyAccessExpression", globalThis.__npTrace("84649:84651:Identifier", el).classList).remove(globalThis.__npTrace("84669:84673:StringLiteral", 'on')));
                globalThis.__npTrace("84684:84737:BinaryExpression", globalThis.__npTrace("84684:84717:CallExpression", globalThis.__npTrace("84684:84686:Identifier", el).querySelector(globalThis.__npTrace("84701:84716:StringLiteral", '.toggle-label'))).textContent = globalThis.__npTrace("84732:84737:StringLiteral", 'Off'));
            }
        }
        // --- Menus Management - Seamless Zero-Gap Positioning ---
        toggleMenu(menuName) {
            if (globalThis.__npTrace("84863:84891:BinaryExpression", globalThis.__npTrace("84863:84878:PropertyAccessExpression", globalThis.__npTrace("84863:84867:ThisKeyword", this).activeMenu) === globalThis.__npTrace("84883:84891:Identifier", menuName))) {
                globalThis.__npTrace("84903:84920:CallExpression", globalThis.__npTrace("84903:84907:ThisKeyword", this).closeMenus());
                return;
            }
            globalThis.__npTrace("84952:84969:CallExpression", globalThis.__npTrace("84952:84956:ThisKeyword", this).closeMenus());
            globalThis.__npTrace("84977:85003:BinaryExpression", globalThis.__npTrace("84977:84981:ThisKeyword", this).activeMenu = globalThis.__npTrace("84995:85003:Identifier", menuName));
            let flyout = globalThis.__npTrace("85025:85029:NullKeyword", null);
            let btn = globalThis.__npTrace("85047:85051:NullKeyword", null);
            if (globalThis.__npTrace("85064:85083:BinaryExpression", globalThis.__npTrace("85064:85072:Identifier", menuName) === globalThis.__npTrace("85077:85083:StringLiteral", 'file'))) {
                globalThis.__npTrace("85095:85123:BinaryExpression", flyout = globalThis.__npTrace("85104:85123:PropertyAccessExpression", globalThis.__npTrace("85104:85112:PropertyAccessExpression", globalThis.__npTrace("85104:85108:ThisKeyword", this).dom).flyoutFile));
                globalThis.__npTrace("85133:85159:BinaryExpression", btn = globalThis.__npTrace("85139:85159:PropertyAccessExpression", globalThis.__npTrace("85139:85147:PropertyAccessExpression", globalThis.__npTrace("85139:85143:ThisKeyword", this).dom).menuBtnFile));
            }
            else if (globalThis.__npTrace("85178:85197:BinaryExpression", globalThis.__npTrace("85178:85186:Identifier", menuName) === globalThis.__npTrace("85191:85197:StringLiteral", 'edit'))) {
                globalThis.__npTrace("85209:85237:BinaryExpression", flyout = globalThis.__npTrace("85218:85237:PropertyAccessExpression", globalThis.__npTrace("85218:85226:PropertyAccessExpression", globalThis.__npTrace("85218:85222:ThisKeyword", this).dom).flyoutEdit));
                globalThis.__npTrace("85247:85273:BinaryExpression", btn = globalThis.__npTrace("85253:85273:PropertyAccessExpression", globalThis.__npTrace("85253:85261:PropertyAccessExpression", globalThis.__npTrace("85253:85257:ThisKeyword", this).dom).menuBtnEdit));
            }
            else if (globalThis.__npTrace("85292:85311:BinaryExpression", globalThis.__npTrace("85292:85300:Identifier", menuName) === globalThis.__npTrace("85305:85311:StringLiteral", 'view'))) {
                globalThis.__npTrace("85323:85351:BinaryExpression", flyout = globalThis.__npTrace("85332:85351:PropertyAccessExpression", globalThis.__npTrace("85332:85340:PropertyAccessExpression", globalThis.__npTrace("85332:85336:ThisKeyword", this).dom).flyoutView));
                globalThis.__npTrace("85361:85387:BinaryExpression", btn = globalThis.__npTrace("85367:85387:PropertyAccessExpression", globalThis.__npTrace("85367:85375:PropertyAccessExpression", globalThis.__npTrace("85367:85371:ThisKeyword", this).dom).menuBtnView));
            }
            if (globalThis.__npTrace("85408:85421:BinaryExpression", globalThis.__npTrace("85408:85414:Identifier", flyout) && globalThis.__npTrace("85418:85421:Identifier", btn))) {
                globalThis.__npTrace("85433:85458:CallExpression", globalThis.__npTrace("85433:85446:PropertyAccessExpression", globalThis.__npTrace("85433:85436:Identifier", btn).classList).add(globalThis.__npTrace("85451:85457:StringLiteral", 'open')));
                globalThis.__npTrace("85468:85496:CallExpression", globalThis.__npTrace("85468:85484:PropertyAccessExpression", globalThis.__npTrace("85468:85474:Identifier", flyout).classList).add(globalThis.__npTrace("85489:85495:StringLiteral", 'open')));
                // Align horizontally with menu button and vertically flush with menubar bottom (36px)
                globalThis.__npTrace("85601:85642:BinaryExpression", globalThis.__npTrace("85601:85613:PropertyAccessExpression", globalThis.__npTrace("85601:85607:Identifier", flyout).style).left = globalThis.__npTrace("85621:85642:TemplateExpression", `${globalThis.__npTrace("85624:85638:PropertyAccessExpression", globalThis.__npTrace("85624:85627:Identifier", btn).offsetLeft)}px`));
                globalThis.__npTrace("85652:85677:BinaryExpression", globalThis.__npTrace("85652:85664:PropertyAccessExpression", globalThis.__npTrace("85652:85658:Identifier", flyout).style).top = globalThis.__npTrace("85671:85677:StringLiteral", '36px'));
            }
        }
        closeMenus() {
            globalThis.__npTrace("85719:85741:BinaryExpression", globalThis.__npTrace("85719:85723:ThisKeyword", this).activeMenu = globalThis.__npTrace("85737:85741:NullKeyword", null));
            globalThis.__npTrace("85749:85833:CallExpression", globalThis.__npTrace("85749:85792:CallExpression", globalThis.__npTrace("85749:85757:Identifier", document).querySelectorAll(globalThis.__npTrace("85775:85791:StringLiteral", '.menu-item-btn'))).forEach(b => globalThis.__npTrace("85806:85832:CallExpression", globalThis.__npTrace("85806:85817:PropertyAccessExpression", globalThis.__npTrace("85806:85807:Identifier", b).classList).remove(globalThis.__npTrace("85825:85831:StringLiteral", 'open')))));
            globalThis.__npTrace("85841:85923:CallExpression", globalThis.__npTrace("85841:85882:CallExpression", globalThis.__npTrace("85841:85849:Identifier", document).querySelectorAll(globalThis.__npTrace("85867:85881:StringLiteral", '.flyout-menu'))).forEach(f => globalThis.__npTrace("85896:85922:CallExpression", globalThis.__npTrace("85896:85907:PropertyAccessExpression", globalThis.__npTrace("85896:85897:Identifier", f).classList).remove(globalThis.__npTrace("85915:85921:StringLiteral", 'open')))));
        }
        // --- Event Listeners & Dispatchers ---
        attachGlobalEvents() {
            const editor = globalThis.__npTrace("86025:86040:PropertyAccessExpression", globalThis.__npTrace("86025:86033:PropertyAccessExpression", globalThis.__npTrace("86025:86029:ThisKeyword", this).dom).editor);
            // Text input & modification
            globalThis.__npTrace("86084:86498:CallExpression", globalThis.__npTrace("86084:86090:Identifier", editor).addEventListener(globalThis.__npTrace("86108:86115:StringLiteral", 'input'), () => {
                const activeTab = globalThis.__npTrace("86151:86170:CallExpression", globalThis.__npTrace("86151:86155:ThisKeyword", this).getActiveTab());
                if (globalThis.__npTrace("86184:86193:Identifier", activeTab)) {
                    globalThis.__npTrace("86207:86239:BinaryExpression", globalThis.__npTrace("86207:86216:Identifier", activeTab).content = globalThis.__npTrace("86227:86239:PropertyAccessExpression", globalThis.__npTrace("86227:86233:Identifier", editor).value));
                    if (globalThis.__npTrace("86255:86276:PrefixUnaryExpression", !globalThis.__npTrace("86256:86276:PropertyAccessExpression", globalThis.__npTrace("86256:86265:Identifier", activeTab).isModified))) {
                        globalThis.__npTrace("86292:86319:BinaryExpression", globalThis.__npTrace("86292:86301:Identifier", activeTab).isModified = globalThis.__npTrace("86315:86319:TrueKeyword", true));
                        globalThis.__npTrace("86333:86350:CallExpression", globalThis.__npTrace("86333:86337:ThisKeyword", this).renderTabs());
                    }
                }
                globalThis.__npTrace("86382:86404:CallExpression", globalThis.__npTrace("86382:86386:ThisKeyword", this).updateStatusBar());
                if (globalThis.__npTrace("86418:86446:PropertyAccessExpression", globalThis.__npTrace("86418:86439:PropertyAccessExpression", globalThis.__npTrace("86418:86422:ThisKeyword", this).findReplaceState).isOpen)) {
                    globalThis.__npTrace("86460:86478:CallExpression", globalThis.__npTrace("86460:86464:ThisKeyword", this).executeFind());
                }
            }));
            // Cursor movement
            globalThis.__npTrace("86532:86652:CallExpression", globalThis.__npTrace("86532:86560:ArrayLiteralExpression", [globalThis.__npTrace("86533:86540:StringLiteral", 'keyup'), globalThis.__npTrace("86542:86549:StringLiteral", 'click'), globalThis.__npTrace("86551:86559:StringLiteral", 'select')]).forEach(ev => {
                globalThis.__npTrace("86585:86642:CallExpression", globalThis.__npTrace("86585:86591:Identifier", editor).addEventListener(globalThis.__npTrace("86609:86611:Identifier", ev), () => globalThis.__npTrace("86619:86641:CallExpression", globalThis.__npTrace("86619:86623:ThisKeyword", this).updateStatusBar())));
            }));
            // Tab key indent
            globalThis.__npTrace("86685:87301:CallExpression", globalThis.__npTrace("86685:86691:Identifier", editor).addEventListener(globalThis.__npTrace("86709:86718:StringLiteral", 'keydown'), (e) => {
                if (globalThis.__npTrace("86741:86756:BinaryExpression", globalThis.__npTrace("86741:86746:PropertyAccessExpression", globalThis.__npTrace("86741:86742:Identifier", e).key) === globalThis.__npTrace("86751:86756:StringLiteral", 'Tab'))) {
                    globalThis.__npTrace("86770:86788:CallExpression", globalThis.__npTrace("86770:86771:Identifier", e).preventDefault());
                    const start = globalThis.__npTrace("86814:86835:PropertyAccessExpression", globalThis.__npTrace("86814:86820:Identifier", editor).selectionStart);
                    const end = globalThis.__npTrace("86859:86878:PropertyAccessExpression", globalThis.__npTrace("86859:86865:Identifier", editor).selectionEnd);
                    globalThis.__npTrace("86890:86974:BinaryExpression", globalThis.__npTrace("86890:86896:Identifier", editor).value = globalThis.__npTrace("86905:86974:BinaryExpression", globalThis.__npTrace("86905:86944:BinaryExpression", globalThis.__npTrace("86905:86937:CallExpression", globalThis.__npTrace("86905:86917:PropertyAccessExpression", globalThis.__npTrace("86905:86911:Identifier", editor).value).substring(globalThis.__npTrace("86928:86929:FirstLiteralToken", 0), globalThis.__npTrace("86931:86936:Identifier", start))) + globalThis.__npTrace("86940:86944:StringLiteral", '\t')) + globalThis.__npTrace("86947:86974:CallExpression", globalThis.__npTrace("86947:86959:PropertyAccessExpression", globalThis.__npTrace("86947:86953:Identifier", editor).value).substring(globalThis.__npTrace("86970:86973:Identifier", end)))));
                    globalThis.__npTrace("86986:87041:BinaryExpression", globalThis.__npTrace("86986:86992:Identifier", editor).selectionStart = globalThis.__npTrace("87010:87041:BinaryExpression", globalThis.__npTrace("87010:87016:Identifier", editor).selectionEnd = globalThis.__npTrace("87032:87041:BinaryExpression", globalThis.__npTrace("87032:87037:Identifier", start) + globalThis.__npTrace("87040:87041:FirstLiteralToken", 1))));
                    const activeTab = globalThis.__npTrace("87071:87090:CallExpression", globalThis.__npTrace("87071:87075:ThisKeyword", this).getActiveTab());
                    if (globalThis.__npTrace("87106:87115:Identifier", activeTab)) {
                        globalThis.__npTrace("87131:87163:BinaryExpression", globalThis.__npTrace("87131:87140:Identifier", activeTab).content = globalThis.__npTrace("87151:87163:PropertyAccessExpression", globalThis.__npTrace("87151:87157:Identifier", editor).value));
                        globalThis.__npTrace("87177:87204:BinaryExpression", globalThis.__npTrace("87177:87186:Identifier", activeTab).isModified = globalThis.__npTrace("87200:87204:TrueKeyword", true));
                        globalThis.__npTrace("87218:87235:CallExpression", globalThis.__npTrace("87218:87222:ThisKeyword", this).renderTabs());
                    }
                    globalThis.__npTrace("87259:87281:CallExpression", globalThis.__npTrace("87259:87263:ThisKeyword", this).updateStatusBar());
                }
            }));
            // Window controls
            globalThis.__npTrace("87335:87978:CallExpression", globalThis.__npTrace("87335:87375:CallExpression", globalThis.__npTrace("87335:87343:Identifier", document).getElementById(globalThis.__npTrace("87359:87374:StringLiteral", 'btn-win-close'))).addEventListener(globalThis.__npTrace("87393:87400:StringLiteral", 'click'), () => {
                const hasUnsaved = globalThis.__npTrace("87437:87470:CallExpression", globalThis.__npTrace("87437:87446:PropertyAccessExpression", globalThis.__npTrace("87437:87441:ThisKeyword", this).tabs).some(t => globalThis.__npTrace("87457:87469:PropertyAccessExpression", globalThis.__npTrace("87457:87458:Identifier", t).isModified)));
                if (globalThis.__npTrace("87484:87494:Identifier", hasUnsaved)) {
                    globalThis.__npTrace("87508:87915:CallExpression", globalThis.__npTrace("87508:87512:ThisKeyword", this).showModal(globalThis.__npTrace("87523:87914:ObjectLiteralExpression", {
                        title: globalThis.__npTrace("87544:87553:StringLiteral", 'Notepad'),
                        message: globalThis.__npTrace("87576:87639:StringLiteral", 'You have unsaved changes. Do you want to save before closing?'),
                        buttons: globalThis.__npTrace("87662:87902:ArrayLiteralExpression", [
                            globalThis.__npTrace("87678:87768:ObjectLiteralExpression", { text: globalThis.__npTrace("87686:87696:StringLiteral", 'Save All'), primary: globalThis.__npTrace("87707:87711:TrueKeyword", true), action: () => { globalThis.__npTrace("87729:87747:CallExpression", globalThis.__npTrace("87729:87733:ThisKeyword", this).saveAllTabs()); globalThis.__npTrace("87749:87763:CallExpression", globalThis.__npTrace("87749:87755:Identifier", window).close()); } }),
                            globalThis.__npTrace("87784:87836:ObjectLiteralExpression", { text: globalThis.__npTrace("87792:87804:StringLiteral", "Don't Save"), action: () => globalThis.__npTrace("87820:87834:CallExpression", globalThis.__npTrace("87820:87826:Identifier", window).close()) }),
                            globalThis.__npTrace("87852:87888:ObjectLiteralExpression", { text: globalThis.__npTrace("87860:87868:StringLiteral", 'Cancel'), action: () => { } })
                        ])
                    })));
                }
                else {
                    globalThis.__npTrace("87944:87958:CallExpression", globalThis.__npTrace("87944:87950:Identifier", window).close());
                }
            }));
            globalThis.__npTrace("87987:88263:CallExpression", globalThis.__npTrace("87987:88025:CallExpression", globalThis.__npTrace("87987:87995:Identifier", document).getElementById(globalThis.__npTrace("88011:88024:StringLiteral", 'btn-win-max'))).addEventListener(globalThis.__npTrace("88043:88050:StringLiteral", 'click'), () => {
                if (globalThis.__npTrace("88072:88099:PrefixUnaryExpression", !globalThis.__npTrace("88073:88099:PropertyAccessExpression", globalThis.__npTrace("88073:88081:Identifier", document).fullscreenElement))) {
                    globalThis.__npTrace("88113:88173:CallExpression", globalThis.__npTrace("88113:88157:CallExpression", globalThis.__npTrace("88113:88137:PropertyAccessExpression", globalThis.__npTrace("88113:88121:Identifier", document).documentElement).requestFullscreen()).catch(() => { }));
                }
                else {
                    globalThis.__npTrace("88202:88243:CallExpression", globalThis.__npTrace("88202:88227:CallExpression", globalThis.__npTrace("88202:88210:Identifier", document).exitFullscreen()).catch(() => { }));
                }
            }));
            // Tabs Header button
            globalThis.__npTrace("88300:88385:CallExpression", globalThis.__npTrace("88300:88318:PropertyAccessExpression", globalThis.__npTrace("88300:88308:PropertyAccessExpression", globalThis.__npTrace("88300:88304:ThisKeyword", this).dom).btnAddTab).addEventListener(globalThis.__npTrace("88336:88343:StringLiteral", 'click'), () => globalThis.__npTrace("88351:88384:CallExpression", globalThis.__npTrace("88351:88355:ThisKeyword", this).createNewTab(globalThis.__npTrace("88369:88379:StringLiteral", 'Untitled'), globalThis.__npTrace("88381:88383:StringLiteral", '')))));
            // Menu button click & hover navigation
            const menuPairs = globalThis.__npTrace("88458:88625:ArrayLiteralExpression", [
                globalThis.__npTrace("88468:88511:ObjectLiteralExpression", { name: globalThis.__npTrace("88476:88482:StringLiteral", 'file'), btn: globalThis.__npTrace("88489:88509:PropertyAccessExpression", globalThis.__npTrace("88489:88497:PropertyAccessExpression", globalThis.__npTrace("88489:88493:ThisKeyword", this).dom).menuBtnFile) }),
                globalThis.__npTrace("88521:88564:ObjectLiteralExpression", { name: globalThis.__npTrace("88529:88535:StringLiteral", 'edit'), btn: globalThis.__npTrace("88542:88562:PropertyAccessExpression", globalThis.__npTrace("88542:88550:PropertyAccessExpression", globalThis.__npTrace("88542:88546:ThisKeyword", this).dom).menuBtnEdit) }),
                globalThis.__npTrace("88574:88617:ObjectLiteralExpression", { name: globalThis.__npTrace("88582:88588:StringLiteral", 'view'), btn: globalThis.__npTrace("88595:88615:PropertyAccessExpression", globalThis.__npTrace("88595:88603:PropertyAccessExpression", globalThis.__npTrace("88595:88599:ThisKeyword", this).dom).menuBtnView) })
            ]);
            globalThis.__npTrace("88634:88987:CallExpression", globalThis.__npTrace("88634:88643:Identifier", menuPairs).forEach(({ name, btn }) => {
                globalThis.__npTrace("88681:88806:CallExpression", globalThis.__npTrace("88681:88684:Identifier", btn).addEventListener(globalThis.__npTrace("88702:88709:StringLiteral", 'click'), (e) => {
                    globalThis.__npTrace("88742:88761:CallExpression", globalThis.__npTrace("88742:88743:Identifier", e).stopPropagation());
                    globalThis.__npTrace("88773:88794:CallExpression", globalThis.__npTrace("88773:88777:ThisKeyword", this).toggleMenu(globalThis.__npTrace("88789:88793:Identifier", name)));
                }));
                globalThis.__npTrace("88816:88977:CallExpression", globalThis.__npTrace("88816:88819:Identifier", btn).addEventListener(globalThis.__npTrace("88837:88849:StringLiteral", 'mouseenter'), () => {
                    if (globalThis.__npTrace("88873:88916:BinaryExpression", globalThis.__npTrace("88873:88888:PropertyAccessExpression", globalThis.__npTrace("88873:88877:ThisKeyword", this).activeMenu) && globalThis.__npTrace("88892:88916:BinaryExpression", globalThis.__npTrace("88892:88907:PropertyAccessExpression", globalThis.__npTrace("88892:88896:ThisKeyword", this).activeMenu) !== globalThis.__npTrace("88912:88916:Identifier", name)))) {
                        globalThis.__npTrace("88932:88953:CallExpression", globalThis.__npTrace("88932:88936:ThisKeyword", this).toggleMenu(globalThis.__npTrace("88948:88952:Identifier", name)));
                    }
                }));
            }));
            // Settings toggle
            globalThis.__npTrace("89021:89100:CallExpression", globalThis.__npTrace("89021:89047:PropertyAccessExpression", globalThis.__npTrace("89021:89029:PropertyAccessExpression", globalThis.__npTrace("89021:89025:ThisKeyword", this).dom).btnSettingsToggle).addEventListener(globalThis.__npTrace("89065:89072:StringLiteral", 'click'), () => globalThis.__npTrace("89080:89099:CallExpression", globalThis.__npTrace("89080:89084:ThisKeyword", this).openSettings())));
            globalThis.__npTrace("89108:89186:CallExpression", globalThis.__npTrace("89108:89132:PropertyAccessExpression", globalThis.__npTrace("89108:89116:PropertyAccessExpression", globalThis.__npTrace("89108:89112:ThisKeyword", this).dom).settingsBtnBack).addEventListener(globalThis.__npTrace("89150:89157:StringLiteral", 'click'), () => globalThis.__npTrace("89165:89185:CallExpression", globalThis.__npTrace("89165:89169:ThisKeyword", this).closeSettings())));
            const settingsWinClose = globalThis.__npTrace("89219:89264:CallExpression", globalThis.__npTrace("89219:89227:Identifier", document).getElementById(globalThis.__npTrace("89243:89263:StringLiteral", 'settings-win-close')));
            if (globalThis.__npTrace("89276:89292:Identifier", settingsWinClose))
                globalThis.__npTrace("89294:89364:CallExpression", globalThis.__npTrace("89294:89310:Identifier", settingsWinClose).addEventListener(globalThis.__npTrace("89328:89335:StringLiteral", 'click'), () => globalThis.__npTrace("89343:89363:CallExpression", globalThis.__npTrace("89343:89347:ThisKeyword", this).closeSettings())));
            // Outside click closes menus
            globalThis.__npTrace("89409:89614:CallExpression", globalThis.__npTrace("89409:89415:Identifier", window).addEventListener(globalThis.__npTrace("89433:89440:StringLiteral", 'click'), (e) => {
                if (globalThis.__npTrace("89463:89563:BinaryExpression", globalThis.__npTrace("89463:89513:PrefixUnaryExpression", !globalThis.__npTrace("89464:89513:CallExpression", globalThis.__npTrace("89464:89485:ParenthesizedExpression", (globalThis.__npTrace("89465:89484:AsExpression", globalThis.__npTrace("89465:89473:PropertyAccessExpression", globalThis.__npTrace("89465:89466:Identifier", e).target)))).closest(globalThis.__npTrace("89494:89512:StringLiteral", '.notepad-menubar')))) && globalThis.__npTrace("89517:89563:PrefixUnaryExpression", !globalThis.__npTrace("89518:89563:CallExpression", globalThis.__npTrace("89518:89539:ParenthesizedExpression", (globalThis.__npTrace("89519:89538:AsExpression", globalThis.__npTrace("89519:89527:PropertyAccessExpression", globalThis.__npTrace("89519:89520:Identifier", e).target)))).closest(globalThis.__npTrace("89548:89562:StringLiteral", '.flyout-menu')))))) {
                    globalThis.__npTrace("89577:89594:CallExpression", globalThis.__npTrace("89577:89581:ThisKeyword", this).closeMenus());
                }
            }));
            // Menu Actions Dispatcher
            globalThis.__npTrace("89656:89954:CallExpression", globalThis.__npTrace("89656:89707:CallExpression", globalThis.__npTrace("89656:89664:Identifier", document).querySelectorAll(globalThis.__npTrace("89682:89706:StringLiteral", '.menu-row[data-action]'))).forEach(item => {
                globalThis.__npTrace("89734:89944:CallExpression", globalThis.__npTrace("89734:89738:Identifier", item).addEventListener(globalThis.__npTrace("89756:89763:StringLiteral", 'click'), (e) => {
                    globalThis.__npTrace("89784:89803:CallExpression", globalThis.__npTrace("89784:89785:Identifier", e).stopPropagation());
                    const action = globalThis.__npTrace("89830:89866:PropertyAccessExpression", globalThis.__npTrace("89830:89859:PropertyAccessExpression", globalThis.__npTrace("89830:89851:ParenthesizedExpression", (globalThis.__npTrace("89831:89850:AsExpression", globalThis.__npTrace("89831:89835:Identifier", item)))).dataset).action);
                    globalThis.__npTrace("89878:89895:CallExpression", globalThis.__npTrace("89878:89882:ThisKeyword", this).closeMenus());
                    globalThis.__npTrace("89907:89932:CallExpression", globalThis.__npTrace("89907:89911:ThisKeyword", this).handleAction(globalThis.__npTrace("89925:89931:Identifier", action)));
                }));
            }));
            // Status Bar interactive clicks
            globalThis.__npTrace("90002:90593:CallExpression", globalThis.__npTrace("90002:90023:PropertyAccessExpression", globalThis.__npTrace("90002:90010:PropertyAccessExpression", globalThis.__npTrace("90002:90006:ThisKeyword", this).dom).sbLineEnding).addEventListener(globalThis.__npTrace("90041:90048:StringLiteral", 'click'), () => {
                const tab = globalThis.__npTrace("90078:90097:CallExpression", globalThis.__npTrace("90078:90082:ThisKeyword", this).getActiveTab());
                if (globalThis.__npTrace("90111:90115:PrefixUnaryExpression", !globalThis.__npTrace("90112:90115:Identifier", tab)))
                    return;
                if (globalThis.__npTrace("90137:90167:BinaryExpression", globalThis.__npTrace("90137:90151:PropertyAccessExpression", globalThis.__npTrace("90137:90140:Identifier", tab).lineEnding) === globalThis.__npTrace("90156:90167:StringLiteral", 'Unix (LF)'))) {
                    globalThis.__npTrace("90181:90214:BinaryExpression", globalThis.__npTrace("90181:90184:Identifier", tab).lineEnding = globalThis.__npTrace("90198:90214:StringLiteral", 'Windows (CRLF)'));
                    globalThis.__npTrace("90226:90301:BinaryExpression", globalThis.__npTrace("90226:90241:PropertyAccessExpression", globalThis.__npTrace("90226:90234:PropertyAccessExpression", globalThis.__npTrace("90226:90230:ThisKeyword", this).dom).editor).value = globalThis.__npTrace("90250:90301:CallExpression", globalThis.__npTrace("90250:90271:PropertyAccessExpression", globalThis.__npTrace("90250:90265:PropertyAccessExpression", globalThis.__npTrace("90250:90258:PropertyAccessExpression", globalThis.__npTrace("90250:90254:ThisKeyword", this).dom).editor).value).replace(globalThis.__npTrace("90280:90292:RegularExpressionLiteral", /(?<!\r)\n/g), globalThis.__npTrace("90294:90300:StringLiteral", '\r\n'))));
                }
                else {
                    globalThis.__npTrace("90330:90358:BinaryExpression", globalThis.__npTrace("90330:90333:Identifier", tab).lineEnding = globalThis.__npTrace("90347:90358:StringLiteral", 'Unix (LF)'));
                    globalThis.__npTrace("90370:90438:BinaryExpression", globalThis.__npTrace("90370:90385:PropertyAccessExpression", globalThis.__npTrace("90370:90378:PropertyAccessExpression", globalThis.__npTrace("90370:90374:ThisKeyword", this).dom).editor).value = globalThis.__npTrace("90394:90438:CallExpression", globalThis.__npTrace("90394:90415:PropertyAccessExpression", globalThis.__npTrace("90394:90409:PropertyAccessExpression", globalThis.__npTrace("90394:90402:PropertyAccessExpression", globalThis.__npTrace("90394:90398:ThisKeyword", this).dom).editor).value).replace(globalThis.__npTrace("90424:90431:RegularExpressionLiteral", /\r\n/g), globalThis.__npTrace("90433:90437:StringLiteral", '\n'))));
                }
                globalThis.__npTrace("90458:90493:BinaryExpression", globalThis.__npTrace("90458:90461:Identifier", tab).content = globalThis.__npTrace("90472:90493:PropertyAccessExpression", globalThis.__npTrace("90472:90487:PropertyAccessExpression", globalThis.__npTrace("90472:90480:PropertyAccessExpression", globalThis.__npTrace("90472:90476:ThisKeyword", this).dom).editor).value));
                globalThis.__npTrace("90503:90524:BinaryExpression", globalThis.__npTrace("90503:90506:Identifier", tab).isModified = globalThis.__npTrace("90520:90524:TrueKeyword", true));
                globalThis.__npTrace("90534:90551:CallExpression", globalThis.__npTrace("90534:90538:ThisKeyword", this).renderTabs());
                globalThis.__npTrace("90561:90583:CallExpression", globalThis.__npTrace("90561:90565:ThisKeyword", this).updateStatusBar());
            }));
            globalThis.__npTrace("90602:90765:CallExpression", globalThis.__npTrace("90602:90622:PropertyAccessExpression", globalThis.__npTrace("90602:90610:PropertyAccessExpression", globalThis.__npTrace("90602:90606:ThisKeyword", this).dom).sbZoomLevel).addEventListener(globalThis.__npTrace("90640:90647:StringLiteral", 'click'), () => {
                globalThis.__npTrace("90665:90689:BinaryExpression", globalThis.__npTrace("90665:90678:PropertyAccessExpression", globalThis.__npTrace("90665:90669:ThisKeyword", this).settings).zoom = globalThis.__npTrace("90686:90689:FirstLiteralToken", 100));
                globalThis.__npTrace("90699:90723:CallExpression", globalThis.__npTrace("90699:90703:ThisKeyword", this).applyEditorStyles());
                globalThis.__npTrace("90733:90755:CallExpression", globalThis.__npTrace("90733:90737:ThisKeyword", this).updateStatusBar());
            }));
            // Find & Replace Buttons
            globalThis.__npTrace("90806:90881:CallExpression", globalThis.__npTrace("90806:90829:PropertyAccessExpression", globalThis.__npTrace("90806:90814:PropertyAccessExpression", globalThis.__npTrace("90806:90810:ThisKeyword", this).dom).findQueryInput).addEventListener(globalThis.__npTrace("90847:90854:StringLiteral", 'input'), () => globalThis.__npTrace("90862:90880:CallExpression", globalThis.__npTrace("90862:90866:ThisKeyword", this).executeFind())));
            globalThis.__npTrace("90889:91160:CallExpression", globalThis.__npTrace("90889:90912:PropertyAccessExpression", globalThis.__npTrace("90889:90897:PropertyAccessExpression", globalThis.__npTrace("90889:90893:ThisKeyword", this).dom).findQueryInput).addEventListener(globalThis.__npTrace("90930:90939:StringLiteral", 'keydown'), (e) => {
                if (globalThis.__npTrace("90977:90994:BinaryExpression", globalThis.__npTrace("90977:90982:PropertyAccessExpression", globalThis.__npTrace("90977:90978:Identifier", e).key) === globalThis.__npTrace("90987:90994:StringLiteral", 'Enter'))) {
                    if (globalThis.__npTrace("91012:91022:PropertyAccessExpression", globalThis.__npTrace("91012:91013:Identifier", e).shiftKey))
                        globalThis.__npTrace("91024:91039:CallExpression", globalThis.__npTrace("91024:91028:ThisKeyword", this).findPrev());
                    else
                        globalThis.__npTrace("91056:91071:CallExpression", globalThis.__npTrace("91056:91060:ThisKeyword", this).findNext());
                }
                else if (globalThis.__npTrace("91092:91110:BinaryExpression", globalThis.__npTrace("91092:91097:PropertyAccessExpression", globalThis.__npTrace("91092:91093:Identifier", e).key) === globalThis.__npTrace("91102:91110:StringLiteral", 'Escape'))) {
                    globalThis.__npTrace("91124:91140:CallExpression", globalThis.__npTrace("91124:91128:ThisKeyword", this).closeFind());
                }
            }));
            globalThis.__npTrace("91169:91238:CallExpression", globalThis.__npTrace("91169:91189:PropertyAccessExpression", globalThis.__npTrace("91169:91177:PropertyAccessExpression", globalThis.__npTrace("91169:91173:ThisKeyword", this).dom).findBtnNext).addEventListener(globalThis.__npTrace("91207:91214:StringLiteral", 'click'), () => globalThis.__npTrace("91222:91237:CallExpression", globalThis.__npTrace("91222:91226:ThisKeyword", this).findNext())));
            globalThis.__npTrace("91246:91315:CallExpression", globalThis.__npTrace("91246:91266:PropertyAccessExpression", globalThis.__npTrace("91246:91254:PropertyAccessExpression", globalThis.__npTrace("91246:91250:ThisKeyword", this).dom).findBtnPrev).addEventListener(globalThis.__npTrace("91284:91291:StringLiteral", 'click'), () => globalThis.__npTrace("91299:91314:CallExpression", globalThis.__npTrace("91299:91303:ThisKeyword", this).findPrev())));
            globalThis.__npTrace("91323:91394:CallExpression", globalThis.__npTrace("91323:91344:PropertyAccessExpression", globalThis.__npTrace("91323:91331:PropertyAccessExpression", globalThis.__npTrace("91323:91327:ThisKeyword", this).dom).findBtnClose).addEventListener(globalThis.__npTrace("91362:91369:StringLiteral", 'click'), () => globalThis.__npTrace("91377:91393:CallExpression", globalThis.__npTrace("91377:91381:ThisKeyword", this).closeFind())));
            globalThis.__npTrace("91402:91675:CallExpression", globalThis.__npTrace("91402:91431:PropertyAccessExpression", globalThis.__npTrace("91402:91410:PropertyAccessExpression", globalThis.__npTrace("91402:91406:ThisKeyword", this).dom).findBtnToggleReplace).addEventListener(globalThis.__npTrace("91449:91456:StringLiteral", 'click'), () => {
                const willShow = globalThis.__npTrace("91491:91535:BinaryExpression", globalThis.__npTrace("91491:91524:PropertyAccessExpression", globalThis.__npTrace("91491:91516:PropertyAccessExpression", globalThis.__npTrace("91491:91510:PropertyAccessExpression", globalThis.__npTrace("91491:91499:PropertyAccessExpression", globalThis.__npTrace("91491:91495:ThisKeyword", this).dom).replaceRow).style).display) === globalThis.__npTrace("91529:91535:StringLiteral", 'none'));
                globalThis.__npTrace("91545:91607:BinaryExpression", globalThis.__npTrace("91545:91570:PropertyAccessExpression", globalThis.__npTrace("91545:91564:PropertyAccessExpression", globalThis.__npTrace("91545:91553:PropertyAccessExpression", globalThis.__npTrace("91545:91549:ThisKeyword", this).dom).replaceRow).style).display = globalThis.__npTrace("91581:91607:ConditionalExpression", globalThis.__npTrace("91581:91589:Identifier", willShow) ? globalThis.__npTrace("91592:91598:StringLiteral", 'flex') : globalThis.__npTrace("91601:91607:StringLiteral", 'none')));
                if (globalThis.__npTrace("91621:91629:Identifier", willShow))
                    globalThis.__npTrace("91631:91665:CallExpression", globalThis.__npTrace("91631:91657:PropertyAccessExpression", globalThis.__npTrace("91631:91639:PropertyAccessExpression", globalThis.__npTrace("91631:91635:ThisKeyword", this).dom).replaceQueryInput).focus());
            }));
            globalThis.__npTrace("91684:91941:CallExpression", globalThis.__npTrace("91684:91704:PropertyAccessExpression", globalThis.__npTrace("91684:91692:PropertyAccessExpression", globalThis.__npTrace("91684:91688:ThisKeyword", this).dom).findBtnCase).addEventListener(globalThis.__npTrace("91722:91729:StringLiteral", 'click'), () => {
                globalThis.__npTrace("91747:91813:BinaryExpression", globalThis.__npTrace("91747:91768:PropertyAccessExpression", globalThis.__npTrace("91747:91751:ThisKeyword", this).findReplaceState).matchCase = globalThis.__npTrace("91781:91813:PrefixUnaryExpression", !globalThis.__npTrace("91782:91813:PropertyAccessExpression", globalThis.__npTrace("91782:91803:PropertyAccessExpression", globalThis.__npTrace("91782:91786:ThisKeyword", this).findReplaceState).matchCase)));
                globalThis.__npTrace("91823:91903:CallExpression", globalThis.__npTrace("91823:91853:PropertyAccessExpression", globalThis.__npTrace("91823:91843:PropertyAccessExpression", globalThis.__npTrace("91823:91831:PropertyAccessExpression", globalThis.__npTrace("91823:91827:ThisKeyword", this).dom).findBtnCase).classList).toggle(globalThis.__npTrace("91861:91869:StringLiteral", 'active'), globalThis.__npTrace("91871:91902:PropertyAccessExpression", globalThis.__npTrace("91871:91892:PropertyAccessExpression", globalThis.__npTrace("91871:91875:ThisKeyword", this).findReplaceState).matchCase)));
                globalThis.__npTrace("91913:91931:CallExpression", globalThis.__npTrace("91913:91917:ThisKeyword", this).executeFind());
            }));
            globalThis.__npTrace("91950:92182:CallExpression", globalThis.__npTrace("91950:91970:PropertyAccessExpression", globalThis.__npTrace("91950:91958:PropertyAccessExpression", globalThis.__npTrace("91950:91954:ThisKeyword", this).dom).findBtnWrap).addEventListener(globalThis.__npTrace("91988:91995:StringLiteral", 'click'), () => {
                globalThis.__npTrace("92013:92081:BinaryExpression", globalThis.__npTrace("92013:92034:PropertyAccessExpression", globalThis.__npTrace("92013:92017:ThisKeyword", this).findReplaceState).wrapAround = globalThis.__npTrace("92048:92081:PrefixUnaryExpression", !globalThis.__npTrace("92049:92081:PropertyAccessExpression", globalThis.__npTrace("92049:92070:PropertyAccessExpression", globalThis.__npTrace("92049:92053:ThisKeyword", this).findReplaceState).wrapAround)));
                globalThis.__npTrace("92091:92172:CallExpression", globalThis.__npTrace("92091:92121:PropertyAccessExpression", globalThis.__npTrace("92091:92111:PropertyAccessExpression", globalThis.__npTrace("92091:92099:PropertyAccessExpression", globalThis.__npTrace("92091:92095:ThisKeyword", this).dom).findBtnWrap).classList).toggle(globalThis.__npTrace("92129:92137:StringLiteral", 'active'), globalThis.__npTrace("92139:92171:PropertyAccessExpression", globalThis.__npTrace("92139:92160:PropertyAccessExpression", globalThis.__npTrace("92139:92143:ThisKeyword", this).findReplaceState).wrapAround)));
            }));
            globalThis.__npTrace("92191:92267:CallExpression", globalThis.__npTrace("92191:92212:PropertyAccessExpression", globalThis.__npTrace("92191:92199:PropertyAccessExpression", globalThis.__npTrace("92191:92195:ThisKeyword", this).dom).btnDoReplace).addEventListener(globalThis.__npTrace("92230:92237:StringLiteral", 'click'), () => globalThis.__npTrace("92245:92266:CallExpression", globalThis.__npTrace("92245:92249:ThisKeyword", this).replaceCurrent())));
            globalThis.__npTrace("92275:92350:CallExpression", globalThis.__npTrace("92275:92299:PropertyAccessExpression", globalThis.__npTrace("92275:92283:PropertyAccessExpression", globalThis.__npTrace("92275:92279:ThisKeyword", this).dom).btnDoReplaceAll).addEventListener(globalThis.__npTrace("92317:92324:StringLiteral", 'click'), () => globalThis.__npTrace("92332:92349:CallExpression", globalThis.__npTrace("92332:92336:ThisKeyword", this).replaceAll())));
            // Settings Listeners
            globalThis.__npTrace("92387:92611:CallExpression", globalThis.__npTrace("92387:92434:CallExpression", globalThis.__npTrace("92387:92395:Identifier", document).getElementById(globalThis.__npTrace("92411:92433:StringLiteral", 'setting-theme-select'))).addEventListener(globalThis.__npTrace("92452:92460:StringLiteral", 'change'), (e) => {
                globalThis.__npTrace("92486:92545:BinaryExpression", globalThis.__npTrace("92486:92499:PropertyAccessExpression", globalThis.__npTrace("92486:92490:ThisKeyword", this).settings).theme = globalThis.__npTrace("92508:92545:PropertyAccessExpression", globalThis.__npTrace("92508:92539:ParenthesizedExpression", (globalThis.__npTrace("92509:92538:AsExpression", globalThis.__npTrace("92509:92517:PropertyAccessExpression", globalThis.__npTrace("92509:92510:Identifier", e).target)))).value));
                globalThis.__npTrace("92555:92572:CallExpression", globalThis.__npTrace("92555:92559:ThisKeyword", this).applyTheme());
                globalThis.__npTrace("92582:92601:CallExpression", globalThis.__npTrace("92582:92586:ThisKeyword", this).saveSettings());
            }));
            const updateFontSettings = () => {
                globalThis.__npTrace("92663:92742:BinaryExpression", globalThis.__npTrace("92663:92676:PropertyAccessExpression", globalThis.__npTrace("92663:92667:ThisKeyword", this).settings).fontFamily = globalThis.__npTrace("92690:92742:PropertyAccessExpression", globalThis.__npTrace("92690:92736:CallExpression", globalThis.__npTrace("92690:92698:Identifier", document).getElementById(globalThis.__npTrace("92714:92735:StringLiteral", 'setting-font-family'))).value));
                globalThis.__npTrace("92752:92829:BinaryExpression", globalThis.__npTrace("92752:92765:PropertyAccessExpression", globalThis.__npTrace("92752:92756:ThisKeyword", this).settings).fontStyle = globalThis.__npTrace("92778:92829:PropertyAccessExpression", globalThis.__npTrace("92778:92823:CallExpression", globalThis.__npTrace("92778:92786:Identifier", document).getElementById(globalThis.__npTrace("92802:92822:StringLiteral", 'setting-font-style'))).value));
                globalThis.__npTrace("92839:92914:BinaryExpression", globalThis.__npTrace("92839:92852:PropertyAccessExpression", globalThis.__npTrace("92839:92843:ThisKeyword", this).settings).fontSize = globalThis.__npTrace("92864:92914:PropertyAccessExpression", globalThis.__npTrace("92864:92908:CallExpression", globalThis.__npTrace("92864:92872:Identifier", document).getElementById(globalThis.__npTrace("92888:92907:StringLiteral", 'setting-font-size'))).value));
                globalThis.__npTrace("92924:92948:CallExpression", globalThis.__npTrace("92924:92928:ThisKeyword", this).applyEditorStyles());
                globalThis.__npTrace("92958:92977:CallExpression", globalThis.__npTrace("92958:92962:ThisKeyword", this).saveSettings());
            };
            globalThis.__npTrace("92995:93088:CallExpression", globalThis.__npTrace("92995:93041:CallExpression", globalThis.__npTrace("92995:93003:Identifier", document).getElementById(globalThis.__npTrace("93019:93040:StringLiteral", 'setting-font-family'))).addEventListener(globalThis.__npTrace("93059:93067:StringLiteral", 'change'), globalThis.__npTrace("93069:93087:Identifier", updateFontSettings)));
            globalThis.__npTrace("93096:93188:CallExpression", globalThis.__npTrace("93096:93141:CallExpression", globalThis.__npTrace("93096:93104:Identifier", document).getElementById(globalThis.__npTrace("93120:93140:StringLiteral", 'setting-font-style'))).addEventListener(globalThis.__npTrace("93159:93167:StringLiteral", 'change'), globalThis.__npTrace("93169:93187:Identifier", updateFontSettings)));
            globalThis.__npTrace("93196:93287:CallExpression", globalThis.__npTrace("93196:93240:CallExpression", globalThis.__npTrace("93196:93204:Identifier", document).getElementById(globalThis.__npTrace("93220:93239:StringLiteral", 'setting-font-size'))).addEventListener(globalThis.__npTrace("93258:93266:StringLiteral", 'change'), globalThis.__npTrace("93268:93286:Identifier", updateFontSettings)));
            globalThis.__npTrace("93296:93625:CallExpression", globalThis.__npTrace("93296:93346:CallExpression", globalThis.__npTrace("93296:93304:Identifier", document).getElementById(globalThis.__npTrace("93320:93345:StringLiteral", 'toggle-setting-wordwrap'))).addEventListener(globalThis.__npTrace("93364:93371:StringLiteral", 'click'), () => {
                globalThis.__npTrace("93389:93437:BinaryExpression", globalThis.__npTrace("93389:93402:PropertyAccessExpression", globalThis.__npTrace("93389:93393:ThisKeyword", this).settings).wordWrap = globalThis.__npTrace("93414:93437:PrefixUnaryExpression", !globalThis.__npTrace("93415:93437:PropertyAccessExpression", globalThis.__npTrace("93415:93428:PropertyAccessExpression", globalThis.__npTrace("93415:93419:ThisKeyword", this).settings).wordWrap)));
                globalThis.__npTrace("93447:93520:CallExpression", globalThis.__npTrace("93447:93451:ThisKeyword", this).updateToggleState(globalThis.__npTrace("93470:93495:StringLiteral", 'toggle-setting-wordwrap'), globalThis.__npTrace("93497:93519:PropertyAccessExpression", globalThis.__npTrace("93497:93510:PropertyAccessExpression", globalThis.__npTrace("93497:93501:ThisKeyword", this).settings).wordWrap)));
                globalThis.__npTrace("93530:93554:CallExpression", globalThis.__npTrace("93530:93534:ThisKeyword", this).applyEditorStyles());
                globalThis.__npTrace("93564:93586:CallExpression", globalThis.__npTrace("93564:93568:ThisKeyword", this).updateStatusBar());
                globalThis.__npTrace("93596:93615:CallExpression", globalThis.__npTrace("93596:93600:ThisKeyword", this).saveSettings());
            }));
            globalThis.__npTrace("93634:93907:CallExpression", globalThis.__npTrace("93634:93686:CallExpression", globalThis.__npTrace("93634:93642:Identifier", document).getElementById(globalThis.__npTrace("93658:93685:StringLiteral", 'toggle-setting-formatting'))).addEventListener(globalThis.__npTrace("93704:93711:StringLiteral", 'click'), () => {
                globalThis.__npTrace("93729:93781:BinaryExpression", globalThis.__npTrace("93729:93742:PropertyAccessExpression", globalThis.__npTrace("93729:93733:ThisKeyword", this).settings).formatting = globalThis.__npTrace("93756:93781:PrefixUnaryExpression", !globalThis.__npTrace("93757:93781:PropertyAccessExpression", globalThis.__npTrace("93757:93770:PropertyAccessExpression", globalThis.__npTrace("93757:93761:ThisKeyword", this).settings).formatting)));
                globalThis.__npTrace("93791:93868:CallExpression", globalThis.__npTrace("93791:93795:ThisKeyword", this).updateToggleState(globalThis.__npTrace("93814:93841:StringLiteral", 'toggle-setting-formatting'), globalThis.__npTrace("93843:93867:PropertyAccessExpression", globalThis.__npTrace("93843:93856:PropertyAccessExpression", globalThis.__npTrace("93843:93847:ThisKeyword", this).settings).formatting)));
                globalThis.__npTrace("93878:93897:CallExpression", globalThis.__npTrace("93878:93882:ThisKeyword", this).saveSettings());
            }));
            globalThis.__npTrace("93916:94121:CallExpression", globalThis.__npTrace("93916:93964:CallExpression", globalThis.__npTrace("93916:93924:Identifier", document).getElementById(globalThis.__npTrace("93940:93963:StringLiteral", 'setting-opening-files'))).addEventListener(globalThis.__npTrace("93982:93990:StringLiteral", 'change'), (e) => {
                globalThis.__npTrace("94016:94082:BinaryExpression", globalThis.__npTrace("94016:94029:PropertyAccessExpression", globalThis.__npTrace("94016:94020:ThisKeyword", this).settings).openingFiles = globalThis.__npTrace("94045:94082:PropertyAccessExpression", globalThis.__npTrace("94045:94076:ParenthesizedExpression", (globalThis.__npTrace("94046:94075:AsExpression", globalThis.__npTrace("94046:94054:PropertyAccessExpression", globalThis.__npTrace("94046:94047:Identifier", e).target)))).value));
                globalThis.__npTrace("94092:94111:CallExpression", globalThis.__npTrace("94092:94096:ThisKeyword", this).saveSettings());
            }));
            // Accordion card toggles (Default closed, click header or button to toggle)
            const toggleCardAccordion = (cardId) => {
                const card = globalThis.__npTrace("94284:94315:CallExpression", globalThis.__npTrace("94284:94292:Identifier", document).getElementById(globalThis.__npTrace("94308:94314:Identifier", cardId)));
                if (globalThis.__npTrace("94329:94333:Identifier", card))
                    globalThis.__npTrace("94335:94368:CallExpression", globalThis.__npTrace("94335:94349:PropertyAccessExpression", globalThis.__npTrace("94335:94339:Identifier", card).classList).toggle(globalThis.__npTrace("94357:94367:StringLiteral", 'expanded')));
            };
            globalThis.__npTrace("94386:94506:CallExpression", globalThis.__npTrace("94386:94432:CallExpression", globalThis.__npTrace("94386:94394:Identifier", document).getElementById(globalThis.__npTrace("94410:94431:StringLiteral", 'header-font-setting'))).addEventListener(globalThis.__npTrace("94450:94457:StringLiteral", 'click'), () => globalThis.__npTrace("94465:94505:CallExpression", toggleCardAccordion(globalThis.__npTrace("94485:94504:StringLiteral", 'card-font-setting')))));
            globalThis.__npTrace("94514:94640:CallExpression", globalThis.__npTrace("94514:94563:CallExpression", globalThis.__npTrace("94514:94522:Identifier", document).getElementById(globalThis.__npTrace("94538:94562:StringLiteral", 'header-startup-setting'))).addEventListener(globalThis.__npTrace("94581:94588:StringLiteral", 'click'), () => globalThis.__npTrace("94596:94639:CallExpression", toggleCardAccordion(globalThis.__npTrace("94616:94638:StringLiteral", 'card-startup-setting')))));
            // Startup session radios
            const radioContinue = globalThis.__npTrace("94703:94752:CallExpression", globalThis.__npTrace("94703:94711:Identifier", document).getElementById(globalThis.__npTrace("94727:94751:StringLiteral", 'radio-startup-continue')));
            const radioNew = globalThis.__npTrace("94777:94821:CallExpression", globalThis.__npTrace("94777:94785:Identifier", document).getElementById(globalThis.__npTrace("94801:94820:StringLiteral", 'radio-startup-new')));
            globalThis.__npTrace("94829:95109:CallExpression", globalThis.__npTrace("94829:94842:Identifier", radioContinue).addEventListener(globalThis.__npTrace("94860:94867:StringLiteral", 'click'), (e) => {
                globalThis.__npTrace("94898:94917:CallExpression", globalThis.__npTrace("94898:94899:Identifier", e).stopPropagation());
                globalThis.__npTrace("94927:94974:BinaryExpression", globalThis.__npTrace("94927:94940:PropertyAccessExpression", globalThis.__npTrace("94927:94931:ThisKeyword", this).settings).startupOption = globalThis.__npTrace("94957:94974:StringLiteral", 'continueSession'));
                globalThis.__npTrace("94984:95023:CallExpression", globalThis.__npTrace("94984:95007:PropertyAccessExpression", globalThis.__npTrace("94984:94997:Identifier", radioContinue).classList).add(globalThis.__npTrace("95012:95022:StringLiteral", 'selected')));
                globalThis.__npTrace("95033:95070:CallExpression", globalThis.__npTrace("95033:95051:PropertyAccessExpression", globalThis.__npTrace("95033:95041:Identifier", radioNew).classList).remove(globalThis.__npTrace("95059:95069:StringLiteral", 'selected')));
                globalThis.__npTrace("95080:95099:CallExpression", globalThis.__npTrace("95080:95084:ThisKeyword", this).saveSettings());
            }));
            globalThis.__npTrace("95117:95387:CallExpression", globalThis.__npTrace("95117:95125:Identifier", radioNew).addEventListener(globalThis.__npTrace("95143:95150:StringLiteral", 'click'), (e) => {
                globalThis.__npTrace("95181:95200:CallExpression", globalThis.__npTrace("95181:95182:Identifier", e).stopPropagation());
                globalThis.__npTrace("95210:95252:BinaryExpression", globalThis.__npTrace("95210:95223:PropertyAccessExpression", globalThis.__npTrace("95210:95214:ThisKeyword", this).settings).startupOption = globalThis.__npTrace("95240:95252:StringLiteral", 'newSession'));
                globalThis.__npTrace("95262:95296:CallExpression", globalThis.__npTrace("95262:95280:PropertyAccessExpression", globalThis.__npTrace("95262:95270:Identifier", radioNew).classList).add(globalThis.__npTrace("95285:95295:StringLiteral", 'selected')));
                globalThis.__npTrace("95306:95348:CallExpression", globalThis.__npTrace("95306:95329:PropertyAccessExpression", globalThis.__npTrace("95306:95319:Identifier", radioContinue).classList).remove(globalThis.__npTrace("95337:95347:StringLiteral", 'selected')));
                globalThis.__npTrace("95358:95377:CallExpression", globalThis.__npTrace("95358:95362:ThisKeyword", this).saveSettings());
            }));
            globalThis.__npTrace("95396:95697:CallExpression", globalThis.__npTrace("95396:95450:CallExpression", globalThis.__npTrace("95396:95404:Identifier", document).getElementById(globalThis.__npTrace("95420:95449:StringLiteral", 'toggle-setting-recent-files'))).addEventListener(globalThis.__npTrace("95468:95475:StringLiteral", 'click'), () => {
                globalThis.__npTrace("95493:95561:BinaryExpression", globalThis.__npTrace("95493:95506:PropertyAccessExpression", globalThis.__npTrace("95493:95497:ThisKeyword", this).settings).recentFilesEnabled = globalThis.__npTrace("95528:95561:PrefixUnaryExpression", !globalThis.__npTrace("95529:95561:PropertyAccessExpression", globalThis.__npTrace("95529:95542:PropertyAccessExpression", globalThis.__npTrace("95529:95533:ThisKeyword", this).settings).recentFilesEnabled)));
                globalThis.__npTrace("95571:95658:CallExpression", globalThis.__npTrace("95571:95575:ThisKeyword", this).updateToggleState(globalThis.__npTrace("95594:95623:StringLiteral", 'toggle-setting-recent-files'), globalThis.__npTrace("95625:95657:PropertyAccessExpression", globalThis.__npTrace("95625:95638:PropertyAccessExpression", globalThis.__npTrace("95625:95629:ThisKeyword", this).settings).recentFilesEnabled)));
                globalThis.__npTrace("95668:95687:CallExpression", globalThis.__npTrace("95668:95672:ThisKeyword", this).saveSettings());
            }));
            globalThis.__npTrace("95706:96042:CallExpression", globalThis.__npTrace("95706:95758:CallExpression", globalThis.__npTrace("95706:95714:Identifier", document).getElementById(globalThis.__npTrace("95730:95757:StringLiteral", 'toggle-setting-spellcheck'))).addEventListener(globalThis.__npTrace("95776:95783:StringLiteral", 'click'), () => {
                globalThis.__npTrace("95801:95853:BinaryExpression", globalThis.__npTrace("95801:95814:PropertyAccessExpression", globalThis.__npTrace("95801:95805:ThisKeyword", this).settings).spellCheck = globalThis.__npTrace("95828:95853:PrefixUnaryExpression", !globalThis.__npTrace("95829:95853:PropertyAccessExpression", globalThis.__npTrace("95829:95842:PropertyAccessExpression", globalThis.__npTrace("95829:95833:ThisKeyword", this).settings).spellCheck)));
                globalThis.__npTrace("95863:95940:CallExpression", globalThis.__npTrace("95863:95867:ThisKeyword", this).updateToggleState(globalThis.__npTrace("95886:95913:StringLiteral", 'toggle-setting-spellcheck'), globalThis.__npTrace("95915:95939:PropertyAccessExpression", globalThis.__npTrace("95915:95928:PropertyAccessExpression", globalThis.__npTrace("95915:95919:ThisKeyword", this).settings).spellCheck)));
                globalThis.__npTrace("95950:96003:BinaryExpression", globalThis.__npTrace("95950:95965:PropertyAccessExpression", globalThis.__npTrace("95950:95958:PropertyAccessExpression", globalThis.__npTrace("95950:95954:ThisKeyword", this).dom).editor).spellcheck = globalThis.__npTrace("95979:96003:PropertyAccessExpression", globalThis.__npTrace("95979:95992:PropertyAccessExpression", globalThis.__npTrace("95979:95983:ThisKeyword", this).settings).spellCheck));
                globalThis.__npTrace("96013:96032:CallExpression", globalThis.__npTrace("96013:96017:ThisKeyword", this).saveSettings());
            }));
            // Keyboard Shortcuts Router
            globalThis.__npTrace("96086:98265:CallExpression", globalThis.__npTrace("96086:96092:Identifier", window).addEventListener(globalThis.__npTrace("96110:96119:StringLiteral", 'keydown'), (e) => {
                if (globalThis.__npTrace("96142:96164:BinaryExpression", globalThis.__npTrace("96142:96151:PropertyAccessExpression", globalThis.__npTrace("96142:96143:Identifier", e).ctrlKey) && globalThis.__npTrace("96155:96164:PrefixUnaryExpression", !globalThis.__npTrace("96156:96164:PropertyAccessExpression", globalThis.__npTrace("96156:96157:Identifier", e).altKey)))) {
                    const key = globalThis.__npTrace("96190:96209:CallExpression", globalThis.__npTrace("96190:96195:PropertyAccessExpression", globalThis.__npTrace("96190:96191:Identifier", e).key).toLowerCase());
                    if (globalThis.__npTrace("96225:96236:BinaryExpression", globalThis.__npTrace("96225:96228:Identifier", key) === globalThis.__npTrace("96233:96236:StringLiteral", 'n'))) {
                        globalThis.__npTrace("96252:96270:CallExpression", globalThis.__npTrace("96252:96253:Identifier", e).preventDefault());
                        if (globalThis.__npTrace("96288:96298:PropertyAccessExpression", globalThis.__npTrace("96288:96289:Identifier", e).shiftKey))
                            globalThis.__npTrace("96300:96330:CallExpression", globalThis.__npTrace("96300:96304:ThisKeyword", this).handleAction(globalThis.__npTrace("96318:96329:StringLiteral", 'newWindow')));
                        else
                            globalThis.__npTrace("96349:96376:CallExpression", globalThis.__npTrace("96349:96353:ThisKeyword", this).handleAction(globalThis.__npTrace("96367:96375:StringLiteral", 'newTab')));
                    }
                    else if (globalThis.__npTrace("96399:96410:BinaryExpression", globalThis.__npTrace("96399:96402:Identifier", key) === globalThis.__npTrace("96407:96410:StringLiteral", 'o'))) {
                        globalThis.__npTrace("96426:96444:CallExpression", globalThis.__npTrace("96426:96427:Identifier", e).preventDefault());
                        globalThis.__npTrace("96458:96487:CallExpression", globalThis.__npTrace("96458:96462:ThisKeyword", this).handleAction(globalThis.__npTrace("96476:96486:StringLiteral", 'openFile')));
                    }
                    else if (globalThis.__npTrace("96510:96521:BinaryExpression", globalThis.__npTrace("96510:96513:Identifier", key) === globalThis.__npTrace("96518:96521:StringLiteral", 's'))) {
                        globalThis.__npTrace("96537:96555:CallExpression", globalThis.__npTrace("96537:96538:Identifier", e).preventDefault());
                        if (globalThis.__npTrace("96573:96583:PropertyAccessExpression", globalThis.__npTrace("96573:96574:Identifier", e).shiftKey))
                            globalThis.__npTrace("96585:96612:CallExpression", globalThis.__npTrace("96585:96589:ThisKeyword", this).handleAction(globalThis.__npTrace("96603:96611:StringLiteral", 'saveAs')));
                        else
                            globalThis.__npTrace("96631:96656:CallExpression", globalThis.__npTrace("96631:96635:ThisKeyword", this).handleAction(globalThis.__npTrace("96649:96655:StringLiteral", 'save')));
                    }
                    else if (globalThis.__npTrace("96679:96690:BinaryExpression", globalThis.__npTrace("96679:96682:Identifier", key) === globalThis.__npTrace("96687:96690:StringLiteral", 'w'))) {
                        globalThis.__npTrace("96706:96724:CallExpression", globalThis.__npTrace("96706:96707:Identifier", e).preventDefault());
                        if (globalThis.__npTrace("96742:96752:PropertyAccessExpression", globalThis.__npTrace("96742:96743:Identifier", e).shiftKey))
                            globalThis.__npTrace("96754:96786:CallExpression", globalThis.__npTrace("96754:96758:ThisKeyword", this).handleAction(globalThis.__npTrace("96772:96785:StringLiteral", 'closeWindow')));
                        else
                            globalThis.__npTrace("96805:96834:CallExpression", globalThis.__npTrace("96805:96809:ThisKeyword", this).handleAction(globalThis.__npTrace("96823:96833:StringLiteral", 'closeTab')));
                    }
                    else if (globalThis.__npTrace("96857:96868:BinaryExpression", globalThis.__npTrace("96857:96860:Identifier", key) === globalThis.__npTrace("96865:96868:StringLiteral", 'f'))) {
                        globalThis.__npTrace("96884:96902:CallExpression", globalThis.__npTrace("96884:96885:Identifier", e).preventDefault());
                        globalThis.__npTrace("96916:96936:CallExpression", globalThis.__npTrace("96916:96920:ThisKeyword", this).openFind(globalThis.__npTrace("96930:96935:FalseKeyword", false)));
                    }
                    else if (globalThis.__npTrace("96959:96970:BinaryExpression", globalThis.__npTrace("96959:96962:Identifier", key) === globalThis.__npTrace("96967:96970:StringLiteral", 'h'))) {
                        globalThis.__npTrace("96986:97004:CallExpression", globalThis.__npTrace("96986:96987:Identifier", e).preventDefault());
                        globalThis.__npTrace("97018:97037:CallExpression", globalThis.__npTrace("97018:97022:ThisKeyword", this).openFind(globalThis.__npTrace("97032:97036:TrueKeyword", true)));
                    }
                    else if (globalThis.__npTrace("97060:97071:BinaryExpression", globalThis.__npTrace("97060:97063:Identifier", key) === globalThis.__npTrace("97068:97071:StringLiteral", 'g'))) {
                        globalThis.__npTrace("97087:97105:CallExpression", globalThis.__npTrace("97087:97088:Identifier", e).preventDefault());
                        globalThis.__npTrace("97119:97140:CallExpression", globalThis.__npTrace("97119:97123:ThisKeyword", this).showGoToDialog());
                    }
                    else if (globalThis.__npTrace("97163:97174:BinaryExpression", globalThis.__npTrace("97163:97166:Identifier", key) === globalThis.__npTrace("97171:97174:StringLiteral", 'p'))) {
                        globalThis.__npTrace("97190:97208:CallExpression", globalThis.__npTrace("97190:97191:Identifier", e).preventDefault());
                        globalThis.__npTrace("97222:97248:CallExpression", globalThis.__npTrace("97222:97226:ThisKeyword", this).handleAction(globalThis.__npTrace("97240:97247:StringLiteral", 'print')));
                    }
                    else if (globalThis.__npTrace("97271:97297:BinaryExpression", globalThis.__npTrace("97271:97282:BinaryExpression", globalThis.__npTrace("97271:97274:Identifier", key) === globalThis.__npTrace("97279:97282:StringLiteral", '=')) || globalThis.__npTrace("97286:97297:BinaryExpression", globalThis.__npTrace("97286:97289:Identifier", key) === globalThis.__npTrace("97294:97297:StringLiteral", '+')))) {
                        globalThis.__npTrace("97313:97331:CallExpression", globalThis.__npTrace("97313:97314:Identifier", e).preventDefault());
                        globalThis.__npTrace("97345:97372:CallExpression", globalThis.__npTrace("97345:97349:ThisKeyword", this).handleAction(globalThis.__npTrace("97363:97371:StringLiteral", 'zoomIn')));
                    }
                    else if (globalThis.__npTrace("97395:97406:BinaryExpression", globalThis.__npTrace("97395:97398:Identifier", key) === globalThis.__npTrace("97403:97406:StringLiteral", '-'))) {
                        globalThis.__npTrace("97422:97440:CallExpression", globalThis.__npTrace("97422:97423:Identifier", e).preventDefault());
                        globalThis.__npTrace("97454:97482:CallExpression", globalThis.__npTrace("97454:97458:ThisKeyword", this).handleAction(globalThis.__npTrace("97472:97481:StringLiteral", 'zoomOut')));
                    }
                    else if (globalThis.__npTrace("97505:97516:BinaryExpression", globalThis.__npTrace("97505:97508:Identifier", key) === globalThis.__npTrace("97513:97516:StringLiteral", '0'))) {
                        globalThis.__npTrace("97532:97550:CallExpression", globalThis.__npTrace("97532:97533:Identifier", e).preventDefault());
                        globalThis.__npTrace("97564:97594:CallExpression", globalThis.__npTrace("97564:97568:ThisKeyword", this).handleAction(globalThis.__npTrace("97582:97593:StringLiteral", 'zoomReset')));
                    }
                }
                else if (globalThis.__npTrace("97627:97679:BinaryExpression", globalThis.__npTrace("97627:97648:BinaryExpression", globalThis.__npTrace("97627:97636:PropertyAccessExpression", globalThis.__npTrace("97627:97628:Identifier", e).ctrlKey) && globalThis.__npTrace("97640:97648:PropertyAccessExpression", globalThis.__npTrace("97640:97641:Identifier", e).altKey)) && globalThis.__npTrace("97652:97679:BinaryExpression", globalThis.__npTrace("97652:97671:CallExpression", globalThis.__npTrace("97652:97657:PropertyAccessExpression", globalThis.__npTrace("97652:97653:Identifier", e).key).toLowerCase()) === globalThis.__npTrace("97676:97679:StringLiteral", 's')))) {
                    globalThis.__npTrace("97693:97711:CallExpression", globalThis.__npTrace("97693:97694:Identifier", e).preventDefault());
                    globalThis.__npTrace("97723:97751:CallExpression", globalThis.__npTrace("97723:97727:ThisKeyword", this).handleAction(globalThis.__npTrace("97741:97750:StringLiteral", 'saveAll')));
                }
                else if (globalThis.__npTrace("97772:97786:BinaryExpression", globalThis.__npTrace("97772:97777:PropertyAccessExpression", globalThis.__npTrace("97772:97773:Identifier", e).key) === globalThis.__npTrace("97782:97786:StringLiteral", 'F3'))) {
                    globalThis.__npTrace("97800:97818:CallExpression", globalThis.__npTrace("97800:97801:Identifier", e).preventDefault());
                    if (globalThis.__npTrace("97834:97844:PropertyAccessExpression", globalThis.__npTrace("97834:97835:Identifier", e).shiftKey))
                        globalThis.__npTrace("97846:97861:CallExpression", globalThis.__npTrace("97846:97850:ThisKeyword", this).findPrev());
                    else
                        globalThis.__npTrace("97878:97893:CallExpression", globalThis.__npTrace("97878:97882:ThisKeyword", this).findNext());
                }
                else if (globalThis.__npTrace("97914:97928:BinaryExpression", globalThis.__npTrace("97914:97919:PropertyAccessExpression", globalThis.__npTrace("97914:97915:Identifier", e).key) === globalThis.__npTrace("97924:97928:StringLiteral", 'F5'))) {
                    globalThis.__npTrace("97942:97960:CallExpression", globalThis.__npTrace("97942:97943:Identifier", e).preventDefault());
                    globalThis.__npTrace("97972:98001:CallExpression", globalThis.__npTrace("97972:97976:ThisKeyword", this).handleAction(globalThis.__npTrace("97990:98000:StringLiteral", 'timeDate')));
                }
                else if (globalThis.__npTrace("98022:98040:BinaryExpression", globalThis.__npTrace("98022:98027:PropertyAccessExpression", globalThis.__npTrace("98022:98023:Identifier", e).key) === globalThis.__npTrace("98032:98040:StringLiteral", 'Escape'))) {
                    if (globalThis.__npTrace("98058:98086:PropertyAccessExpression", globalThis.__npTrace("98058:98079:PropertyAccessExpression", globalThis.__npTrace("98058:98062:ThisKeyword", this).findReplaceState).isOpen))
                        globalThis.__npTrace("98088:98104:CallExpression", globalThis.__npTrace("98088:98092:ThisKeyword", this).closeFind());
                    if (globalThis.__npTrace("98120:98168:CallExpression", globalThis.__npTrace("98120:98151:PropertyAccessExpression", globalThis.__npTrace("98120:98141:PropertyAccessExpression", globalThis.__npTrace("98120:98128:PropertyAccessExpression", globalThis.__npTrace("98120:98124:ThisKeyword", this).dom).modalOverlay).classList).contains(globalThis.__npTrace("98161:98167:StringLiteral", 'open'))))
                        globalThis.__npTrace("98170:98216:CallExpression", globalThis.__npTrace("98170:98201:PropertyAccessExpression", globalThis.__npTrace("98170:98191:PropertyAccessExpression", globalThis.__npTrace("98170:98178:PropertyAccessExpression", globalThis.__npTrace("98170:98174:ThisKeyword", this).dom).modalOverlay).classList).remove(globalThis.__npTrace("98209:98215:StringLiteral", 'open')));
                    globalThis.__npTrace("98228:98245:CallExpression", globalThis.__npTrace("98228:98232:ThisKeyword", this).closeMenus());
                }
            }));
        }
        // --- Central Action Handler ---
        handleAction(action) {
            const activeTab = globalThis.__npTrace("98383:98402:CallExpression", globalThis.__npTrace("98383:98387:ThisKeyword", this).getActiveTab());
            const editor = globalThis.__npTrace("98425:98440:PropertyAccessExpression", globalThis.__npTrace("98425:98433:PropertyAccessExpression", globalThis.__npTrace("98425:98429:ThisKeyword", this).dom).editor);
            switch (globalThis.__npTrace("98457:98463:Identifier", action)) {
                case globalThis.__npTrace("98480:98488:StringLiteral", 'newTab'):
                    globalThis.__npTrace("98500:98533:CallExpression", globalThis.__npTrace("98500:98504:ThisKeyword", this).createNewTab(globalThis.__npTrace("98518:98528:StringLiteral", 'Untitled'), globalThis.__npTrace("98530:98532:StringLiteral", '')));
                    break;
                case globalThis.__npTrace("98565:98576:StringLiteral", 'newWindow'):
                    globalThis.__npTrace("98588:98631:CallExpression", globalThis.__npTrace("98588:98594:Identifier", window).open(globalThis.__npTrace("98600:98620:PropertyAccessExpression", globalThis.__npTrace("98600:98615:PropertyAccessExpression", globalThis.__npTrace("98600:98606:Identifier", window).location).href), globalThis.__npTrace("98622:98630:StringLiteral", '_blank')));
                    break;
                case globalThis.__npTrace("98663:98679:StringLiteral", 'newMarkdownTab'):
                    globalThis.__npTrace("98691:98775:CallExpression", globalThis.__npTrace("98691:98695:ThisKeyword", this).createNewTab(globalThis.__npTrace("98709:98722:StringLiteral", 'Untitled.md'), globalThis.__npTrace("98724:98762:StringLiteral", '# Markdown Document\n\nWrite here...'), globalThis.__npTrace("98764:98768:NullKeyword", null), globalThis.__npTrace("98770:98774:TrueKeyword", true)));
                    break;
                case globalThis.__npTrace("98807:98817:StringLiteral", 'openFile'):
                    globalThis.__npTrace("98829:98850:CallExpression", globalThis.__npTrace("98829:98833:ThisKeyword", this).openFileDialog());
                    break;
                case globalThis.__npTrace("98882:98888:StringLiteral", 'save'):
                    globalThis.__npTrace("98900:98930:CallExpression", globalThis.__npTrace("98900:98904:ThisKeyword", this).saveTab(globalThis.__npTrace("98913:98922:Identifier", activeTab), globalThis.__npTrace("98924:98929:FalseKeyword", false)));
                    break;
                case globalThis.__npTrace("98962:98970:StringLiteral", 'saveAs'):
                    globalThis.__npTrace("98982:99011:CallExpression", globalThis.__npTrace("98982:98986:ThisKeyword", this).saveTab(globalThis.__npTrace("98995:99004:Identifier", activeTab), globalThis.__npTrace("99006:99010:TrueKeyword", true)));
                    break;
                case globalThis.__npTrace("99043:99052:StringLiteral", 'saveAll'):
                    globalThis.__npTrace("99064:99082:CallExpression", globalThis.__npTrace("99064:99068:ThisKeyword", this).saveAllTabs());
                    break;
                case globalThis.__npTrace("99114:99125:StringLiteral", 'pageSetup'):
                case globalThis.__npTrace("99140:99147:StringLiteral", 'print'):
                    globalThis.__npTrace("99159:99173:CallExpression", globalThis.__npTrace("99159:99165:Identifier", window).print());
                    break;
                case globalThis.__npTrace("99205:99215:StringLiteral", 'closeTab'):
                    if (globalThis.__npTrace("99231:99240:Identifier", activeTab))
                        globalThis.__npTrace("99242:99275:CallExpression", globalThis.__npTrace("99242:99246:ThisKeyword", this).promptCloseTab(globalThis.__npTrace("99262:99274:PropertyAccessExpression", globalThis.__npTrace("99262:99271:Identifier", activeTab).id)));
                    break;
                case globalThis.__npTrace("99307:99320:StringLiteral", 'closeWindow'):
                case globalThis.__npTrace("99335:99341:StringLiteral", 'exit'):
                    globalThis.__npTrace("99353:99367:CallExpression", globalThis.__npTrace("99353:99359:Identifier", window).close());
                    break;
                case globalThis.__npTrace("99399:99405:StringLiteral", 'undo'):
                    globalThis.__npTrace("99417:99445:CallExpression", globalThis.__npTrace("99417:99425:Identifier", document).execCommand(globalThis.__npTrace("99438:99444:StringLiteral", 'undo')));
                    break;
                case globalThis.__npTrace("99477:99482:StringLiteral", 'cut'):
                    globalThis.__npTrace("99494:99521:CallExpression", globalThis.__npTrace("99494:99502:Identifier", document).execCommand(globalThis.__npTrace("99515:99520:StringLiteral", 'cut')));
                    break;
                case globalThis.__npTrace("99553:99559:StringLiteral", 'copy'):
                    globalThis.__npTrace("99571:99599:CallExpression", globalThis.__npTrace("99571:99579:Identifier", document).execCommand(globalThis.__npTrace("99592:99598:StringLiteral", 'copy')));
                    break;
                case globalThis.__npTrace("99631:99638:StringLiteral", 'paste'):
                    globalThis.__npTrace("99650:100250:CallExpression", globalThis.__npTrace("99650:100180:CallExpression", globalThis.__npTrace("99650:99680:CallExpression", globalThis.__npTrace("99650:99669:PropertyAccessExpression", globalThis.__npTrace("99650:99659:Identifier", navigator).clipboard).readText()).then(clip => {
                        const start = globalThis.__npTrace("99722:99743:PropertyAccessExpression", globalThis.__npTrace("99722:99728:Identifier", editor).selectionStart);
                        const end = globalThis.__npTrace("99769:99788:PropertyAccessExpression", globalThis.__npTrace("99769:99775:Identifier", editor).selectionEnd);
                        globalThis.__npTrace("99802:99886:BinaryExpression", globalThis.__npTrace("99802:99808:Identifier", editor).value = globalThis.__npTrace("99817:99886:BinaryExpression", globalThis.__npTrace("99817:99856:BinaryExpression", globalThis.__npTrace("99817:99849:CallExpression", globalThis.__npTrace("99817:99829:PropertyAccessExpression", globalThis.__npTrace("99817:99823:Identifier", editor).value).substring(globalThis.__npTrace("99840:99841:FirstLiteralToken", 0), globalThis.__npTrace("99843:99848:Identifier", start))) + globalThis.__npTrace("99852:99856:Identifier", clip)) + globalThis.__npTrace("99859:99886:CallExpression", globalThis.__npTrace("99859:99871:PropertyAccessExpression", globalThis.__npTrace("99859:99865:Identifier", editor).value).substring(globalThis.__npTrace("99882:99885:Identifier", end)))));
                        globalThis.__npTrace("99900:99965:BinaryExpression", globalThis.__npTrace("99900:99906:Identifier", editor).selectionStart = globalThis.__npTrace("99924:99965:BinaryExpression", globalThis.__npTrace("99924:99930:Identifier", editor).selectionEnd = globalThis.__npTrace("99946:99965:BinaryExpression", globalThis.__npTrace("99946:99951:Identifier", start) + globalThis.__npTrace("99954:99965:PropertyAccessExpression", globalThis.__npTrace("99954:99958:Identifier", clip).length))));
                        if (globalThis.__npTrace("99983:99992:Identifier", activeTab)) {
                            globalThis.__npTrace("100010:100042:BinaryExpression", globalThis.__npTrace("100010:100019:Identifier", activeTab).content = globalThis.__npTrace("100030:100042:PropertyAccessExpression", globalThis.__npTrace("100030:100036:Identifier", editor).value));
                            globalThis.__npTrace("100058:100085:BinaryExpression", globalThis.__npTrace("100058:100067:Identifier", activeTab).isModified = globalThis.__npTrace("100081:100085:TrueKeyword", true));
                        }
                        globalThis.__npTrace("100113:100130:CallExpression", globalThis.__npTrace("100113:100117:ThisKeyword", this).renderTabs());
                        globalThis.__npTrace("100144:100166:CallExpression", globalThis.__npTrace("100144:100148:ThisKeyword", this).updateStatusBar());
                    })).catch(() => {
                        globalThis.__npTrace("100207:100236:CallExpression", globalThis.__npTrace("100207:100215:Identifier", document).execCommand(globalThis.__npTrace("100228:100235:StringLiteral", 'paste')));
                    }));
                    break;
                case globalThis.__npTrace("100282:100290:StringLiteral", 'delete'):
                    const start = globalThis.__npTrace("100316:100337:PropertyAccessExpression", globalThis.__npTrace("100316:100322:Identifier", editor).selectionStart);
                    const end = globalThis.__npTrace("100361:100380:PropertyAccessExpression", globalThis.__npTrace("100361:100367:Identifier", editor).selectionEnd);
                    if (globalThis.__npTrace("100396:100409:BinaryExpression", globalThis.__npTrace("100396:100401:Identifier", start) === globalThis.__npTrace("100406:100409:Identifier", end))) {
                        globalThis.__npTrace("100425:100508:BinaryExpression", globalThis.__npTrace("100425:100431:Identifier", editor).value = globalThis.__npTrace("100440:100508:BinaryExpression", globalThis.__npTrace("100440:100472:CallExpression", globalThis.__npTrace("100440:100452:PropertyAccessExpression", globalThis.__npTrace("100440:100446:Identifier", editor).value).substring(globalThis.__npTrace("100463:100464:FirstLiteralToken", 0), globalThis.__npTrace("100466:100471:Identifier", start))) + globalThis.__npTrace("100475:100508:CallExpression", globalThis.__npTrace("100475:100487:PropertyAccessExpression", globalThis.__npTrace("100475:100481:Identifier", editor).value).substring(globalThis.__npTrace("100498:100507:BinaryExpression", globalThis.__npTrace("100498:100503:Identifier", start) + globalThis.__npTrace("100506:100507:FirstLiteralToken", 1))))));
                    }
                    else {
                        globalThis.__npTrace("100541:100618:BinaryExpression", globalThis.__npTrace("100541:100547:Identifier", editor).value = globalThis.__npTrace("100556:100618:BinaryExpression", globalThis.__npTrace("100556:100588:CallExpression", globalThis.__npTrace("100556:100568:PropertyAccessExpression", globalThis.__npTrace("100556:100562:Identifier", editor).value).substring(globalThis.__npTrace("100579:100580:FirstLiteralToken", 0), globalThis.__npTrace("100582:100587:Identifier", start))) + globalThis.__npTrace("100591:100618:CallExpression", globalThis.__npTrace("100591:100603:PropertyAccessExpression", globalThis.__npTrace("100591:100597:Identifier", editor).value).substring(globalThis.__npTrace("100614:100617:Identifier", end)))));
                    }
                    globalThis.__npTrace("100642:100693:BinaryExpression", globalThis.__npTrace("100642:100648:Identifier", editor).selectionStart = globalThis.__npTrace("100666:100693:BinaryExpression", globalThis.__npTrace("100666:100672:Identifier", editor).selectionEnd = globalThis.__npTrace("100688:100693:Identifier", start)));
                    if (globalThis.__npTrace("100709:100718:Identifier", activeTab)) {
                        globalThis.__npTrace("100734:100766:BinaryExpression", globalThis.__npTrace("100734:100743:Identifier", activeTab).content = globalThis.__npTrace("100754:100766:PropertyAccessExpression", globalThis.__npTrace("100754:100760:Identifier", editor).value));
                        globalThis.__npTrace("100780:100807:BinaryExpression", globalThis.__npTrace("100780:100789:Identifier", activeTab).isModified = globalThis.__npTrace("100803:100807:TrueKeyword", true));
                    }
                    globalThis.__npTrace("100831:100848:CallExpression", globalThis.__npTrace("100831:100835:ThisKeyword", this).renderTabs());
                    globalThis.__npTrace("100860:100882:CallExpression", globalThis.__npTrace("100860:100864:ThisKeyword", this).updateStatusBar());
                    break;
                case globalThis.__npTrace("100914:100931:StringLiteral", 'clearFormatting'):
                    break;
                case globalThis.__npTrace("100963:100969:StringLiteral", 'find'):
                    globalThis.__npTrace("100981:101001:CallExpression", globalThis.__npTrace("100981:100985:ThisKeyword", this).openFind(globalThis.__npTrace("100995:101000:FalseKeyword", false)));
                    break;
                case globalThis.__npTrace("101033:101043:StringLiteral", 'findNext'):
                    globalThis.__npTrace("101055:101070:CallExpression", globalThis.__npTrace("101055:101059:ThisKeyword", this).findNext());
                    break;
                case globalThis.__npTrace("101102:101116:StringLiteral", 'findPrevious'):
                    globalThis.__npTrace("101128:101143:CallExpression", globalThis.__npTrace("101128:101132:ThisKeyword", this).findPrev());
                    break;
                case globalThis.__npTrace("101175:101184:StringLiteral", 'replace'):
                    globalThis.__npTrace("101196:101215:CallExpression", globalThis.__npTrace("101196:101200:ThisKeyword", this).openFind(globalThis.__npTrace("101210:101214:TrueKeyword", true)));
                    break;
                case globalThis.__npTrace("101247:101253:StringLiteral", 'goTo'):
                    globalThis.__npTrace("101265:101286:CallExpression", globalThis.__npTrace("101265:101269:ThisKeyword", this).showGoToDialog());
                    break;
                case globalThis.__npTrace("101318:101329:StringLiteral", 'selectAll'):
                    globalThis.__npTrace("101341:101356:CallExpression", globalThis.__npTrace("101341:101347:Identifier", editor).select());
                    break;
                case globalThis.__npTrace("101388:101398:StringLiteral", 'timeDate'):
                    const now = globalThis.__npTrace("101422:101432:NewExpression", new Date());
                    const timeStr = globalThis.__npTrace("101460:101526:CallExpression", globalThis.__npTrace("101460:101463:Identifier", now).toLocaleTimeString(globalThis.__npTrace("101483:101485:ArrayLiteralExpression", []), globalThis.__npTrace("101487:101525:ObjectLiteralExpression", { hour: globalThis.__npTrace("101495:101504:StringLiteral", 'numeric'), minute: globalThis.__npTrace("101514:101523:StringLiteral", '2-digit') })));
                    const dateStr = globalThis.__npTrace("101554:101615:TemplateExpression", `${globalThis.__npTrace("101557:101575:BinaryExpression", globalThis.__npTrace("101557:101571:CallExpression", globalThis.__npTrace("101557:101560:Identifier", now).getMonth()) + globalThis.__npTrace("101574:101575:FirstLiteralToken", 1))}/${globalThis.__npTrace("101579:101592:CallExpression", globalThis.__npTrace("101579:101582:Identifier", now).getDate())}/${globalThis.__npTrace("101596:101613:CallExpression", globalThis.__npTrace("101596:101599:Identifier", now).getFullYear())}`);
                    const stamp = globalThis.__npTrace("101641:101664:TemplateExpression", `${globalThis.__npTrace("101644:101651:Identifier", timeStr)} ${globalThis.__npTrace("101655:101662:Identifier", dateStr)}`);
                    const cPos = globalThis.__npTrace("101689:101710:PropertyAccessExpression", globalThis.__npTrace("101689:101695:Identifier", editor).selectionStart);
                    globalThis.__npTrace("101722:101822:BinaryExpression", globalThis.__npTrace("101722:101728:Identifier", editor).value = globalThis.__npTrace("101737:101822:BinaryExpression", globalThis.__npTrace("101737:101776:BinaryExpression", globalThis.__npTrace("101737:101768:CallExpression", globalThis.__npTrace("101737:101749:PropertyAccessExpression", globalThis.__npTrace("101737:101743:Identifier", editor).value).substring(globalThis.__npTrace("101760:101761:FirstLiteralToken", 0), globalThis.__npTrace("101763:101767:Identifier", cPos))) + globalThis.__npTrace("101771:101776:Identifier", stamp)) + globalThis.__npTrace("101779:101822:CallExpression", globalThis.__npTrace("101779:101791:PropertyAccessExpression", globalThis.__npTrace("101779:101785:Identifier", editor).value).substring(globalThis.__npTrace("101802:101821:PropertyAccessExpression", globalThis.__npTrace("101802:101808:Identifier", editor).selectionEnd)))));
                    globalThis.__npTrace("101834:101899:BinaryExpression", globalThis.__npTrace("101834:101840:Identifier", editor).selectionStart = globalThis.__npTrace("101858:101899:BinaryExpression", globalThis.__npTrace("101858:101864:Identifier", editor).selectionEnd = globalThis.__npTrace("101880:101899:BinaryExpression", globalThis.__npTrace("101880:101884:Identifier", cPos) + globalThis.__npTrace("101887:101899:PropertyAccessExpression", globalThis.__npTrace("101887:101892:Identifier", stamp).length))));
                    if (globalThis.__npTrace("101915:101924:Identifier", activeTab)) {
                        globalThis.__npTrace("101940:101972:BinaryExpression", globalThis.__npTrace("101940:101949:Identifier", activeTab).content = globalThis.__npTrace("101960:101972:PropertyAccessExpression", globalThis.__npTrace("101960:101966:Identifier", editor).value));
                        globalThis.__npTrace("101986:102013:BinaryExpression", globalThis.__npTrace("101986:101995:Identifier", activeTab).isModified = globalThis.__npTrace("102009:102013:TrueKeyword", true));
                    }
                    globalThis.__npTrace("102037:102054:CallExpression", globalThis.__npTrace("102037:102041:ThisKeyword", this).renderTabs());
                    globalThis.__npTrace("102066:102088:CallExpression", globalThis.__npTrace("102066:102070:ThisKeyword", this).updateStatusBar());
                    break;
                case globalThis.__npTrace("102120:102138:StringLiteral", 'openFontSettings'):
                    globalThis.__npTrace("102150:102188:CallExpression", globalThis.__npTrace("102150:102154:ThisKeyword", this).openSettings(globalThis.__npTrace("102168:102187:StringLiteral", 'card-font-setting')));
                    break;
                case globalThis.__npTrace("102220:102228:StringLiteral", 'zoomIn'):
                    if (globalThis.__npTrace("102244:102268:BinaryExpression", globalThis.__npTrace("102244:102262:PropertyAccessExpression", globalThis.__npTrace("102244:102257:PropertyAccessExpression", globalThis.__npTrace("102244:102248:ThisKeyword", this).settings).zoom) < globalThis.__npTrace("102265:102268:FirstLiteralToken", 500))) {
                        globalThis.__npTrace("102284:102308:BinaryExpression", globalThis.__npTrace("102284:102297:PropertyAccessExpression", globalThis.__npTrace("102284:102288:ThisKeyword", this).settings).zoom += globalThis.__npTrace("102306:102308:FirstLiteralToken", 10));
                        globalThis.__npTrace("102322:102346:CallExpression", globalThis.__npTrace("102322:102326:ThisKeyword", this).applyEditorStyles());
                        globalThis.__npTrace("102360:102382:CallExpression", globalThis.__npTrace("102360:102364:ThisKeyword", this).updateStatusBar());
                    }
                    break;
                case globalThis.__npTrace("102426:102435:StringLiteral", 'zoomOut'):
                    if (globalThis.__npTrace("102451:102474:BinaryExpression", globalThis.__npTrace("102451:102469:PropertyAccessExpression", globalThis.__npTrace("102451:102464:PropertyAccessExpression", globalThis.__npTrace("102451:102455:ThisKeyword", this).settings).zoom) > globalThis.__npTrace("102472:102474:FirstLiteralToken", 20))) {
                        globalThis.__npTrace("102490:102514:BinaryExpression", globalThis.__npTrace("102490:102503:PropertyAccessExpression", globalThis.__npTrace("102490:102494:ThisKeyword", this).settings).zoom -= globalThis.__npTrace("102512:102514:FirstLiteralToken", 10));
                        globalThis.__npTrace("102528:102552:CallExpression", globalThis.__npTrace("102528:102532:ThisKeyword", this).applyEditorStyles());
                        globalThis.__npTrace("102566:102588:CallExpression", globalThis.__npTrace("102566:102570:ThisKeyword", this).updateStatusBar());
                    }
                    break;
                case globalThis.__npTrace("102632:102643:StringLiteral", 'zoomReset'):
                    globalThis.__npTrace("102655:102679:BinaryExpression", globalThis.__npTrace("102655:102668:PropertyAccessExpression", globalThis.__npTrace("102655:102659:ThisKeyword", this).settings).zoom = globalThis.__npTrace("102676:102679:FirstLiteralToken", 100));
                    globalThis.__npTrace("102691:102715:CallExpression", globalThis.__npTrace("102691:102695:ThisKeyword", this).applyEditorStyles());
                    globalThis.__npTrace("102727:102749:CallExpression", globalThis.__npTrace("102727:102731:ThisKeyword", this).updateStatusBar());
                    break;
                case globalThis.__npTrace("102781:102798:StringLiteral", 'toggleStatusBar'):
                    globalThis.__npTrace("102810:102868:BinaryExpression", globalThis.__npTrace("102810:102823:PropertyAccessExpression", globalThis.__npTrace("102810:102814:ThisKeyword", this).settings).showStatusBar = globalThis.__npTrace("102840:102868:PrefixUnaryExpression", !globalThis.__npTrace("102841:102868:PropertyAccessExpression", globalThis.__npTrace("102841:102854:PropertyAccessExpression", globalThis.__npTrace("102841:102845:ThisKeyword", this).settings).showStatusBar)));
                    globalThis.__npTrace("102880:102899:CallExpression", globalThis.__npTrace("102880:102884:ThisKeyword", this).saveSettings());
                    globalThis.__npTrace("102911:102933:CallExpression", globalThis.__npTrace("102911:102915:ThisKeyword", this).updateStatusBar());
                    break;
                case globalThis.__npTrace("102965:102981:StringLiteral", 'toggleWordWrap'):
                    globalThis.__npTrace("102993:103041:BinaryExpression", globalThis.__npTrace("102993:103006:PropertyAccessExpression", globalThis.__npTrace("102993:102997:ThisKeyword", this).settings).wordWrap = globalThis.__npTrace("103018:103041:PrefixUnaryExpression", !globalThis.__npTrace("103019:103041:PropertyAccessExpression", globalThis.__npTrace("103019:103032:PropertyAccessExpression", globalThis.__npTrace("103019:103023:ThisKeyword", this).settings).wordWrap)));
                    globalThis.__npTrace("103053:103072:CallExpression", globalThis.__npTrace("103053:103057:ThisKeyword", this).saveSettings());
                    globalThis.__npTrace("103084:103108:CallExpression", globalThis.__npTrace("103084:103088:ThisKeyword", this).applyEditorStyles());
                    globalThis.__npTrace("103120:103142:CallExpression", globalThis.__npTrace("103120:103124:ThisKeyword", this).updateStatusBar());
                    globalThis.__npTrace("103154:103227:CallExpression", globalThis.__npTrace("103154:103158:ThisKeyword", this).updateToggleState(globalThis.__npTrace("103177:103202:StringLiteral", 'toggle-setting-wordwrap'), globalThis.__npTrace("103204:103226:PropertyAccessExpression", globalThis.__npTrace("103204:103217:PropertyAccessExpression", globalThis.__npTrace("103204:103208:ThisKeyword", this).settings).wordWrap)));
                    break;
                case globalThis.__npTrace("103259:103282:StringLiteral", 'toggleMarkdownPreview'):
                    globalThis.__npTrace("103294:103320:CallExpression", globalThis.__npTrace("103294:103298:ThisKeyword", this).showMarkdownPreview());
                    break;
            }
        }
        showMarkdownPreview() {
            const activeTab = globalThis.__npTrace("103406:103425:CallExpression", globalThis.__npTrace("103406:103410:ThisKeyword", this).getActiveTab());
            if (globalThis.__npTrace("103437:103447:PrefixUnaryExpression", !globalThis.__npTrace("103438:103447:Identifier", activeTab)))
                return;
            const html = globalThis.__npTrace("103476:103520:CallExpression", globalThis.__npTrace("103476:103480:ThisKeyword", this).simpleMarkdownToHtml(globalThis.__npTrace("103502:103519:PropertyAccessExpression", globalThis.__npTrace("103502:103511:Identifier", activeTab).content)));
            globalThis.__npTrace("103528:103699:CallExpression", globalThis.__npTrace("103528:103532:ThisKeyword", this).showModal(globalThis.__npTrace("103543:103698:ObjectLiteralExpression", {
                title: globalThis.__npTrace("103560:103598:TemplateExpression", `Markdown Preview: ${globalThis.__npTrace("103581:103596:PropertyAccessExpression", globalThis.__npTrace("103581:103590:Identifier", activeTab).title)}`),
                message: globalThis.__npTrace("103617:103619:StringLiteral", ''),
                buttons: globalThis.__npTrace("103638:103690:ArrayLiteralExpression", [globalThis.__npTrace("103639:103689:ObjectLiteralExpression", { text: globalThis.__npTrace("103647:103654:StringLiteral", 'Close'), primary: globalThis.__npTrace("103665:103669:TrueKeyword", true), action: () => { } })])
            })));
            const body = globalThis.__npTrace("103720:103765:CallExpression", globalThis.__npTrace("103720:103728:Identifier", document).getElementById(globalThis.__npTrace("103744:103764:StringLiteral", 'dialog-custom-body')));
            globalThis.__npTrace("103773:103938:BinaryExpression", globalThis.__npTrace("103773:103777:Identifier", body).innerHTML = globalThis.__npTrace("103790:103938:TemplateExpression", `<div style="max-height: 380px; overflow-y: auto; padding: 12px; background: rgba(0,0,0,0.2); border-radius: 6px; user-select: text;">${globalThis.__npTrace("103926:103930:Identifier", html)}</div>`));
        }
        simpleMarkdownToHtml(md) {
            return globalThis.__npTrace("103999:104514:CallExpression", globalThis.__npTrace("103999:104480:CallExpression", globalThis.__npTrace("103999:104347:CallExpression", globalThis.__npTrace("103999:104299:CallExpression", globalThis.__npTrace("103999:104239:CallExpression", globalThis.__npTrace("103999:104190:CallExpression", globalThis.__npTrace("103999:104142:CallExpression", globalThis.__npTrace("103999:104095:CallExpression", globalThis.__npTrace("103999:104064:CallExpression", globalThis.__npTrace("103999:104033:CallExpression", globalThis.__npTrace("103999:104001:Identifier", md).replace(globalThis.__npTrace("104019:104023:RegularExpressionLiteral", /&/g), globalThis.__npTrace("104025:104032:StringLiteral", '&amp;'))).replace(globalThis.__npTrace("104051:104055:RegularExpressionLiteral", /</g), globalThis.__npTrace("104057:104063:StringLiteral", '&lt;'))).replace(globalThis.__npTrace("104082:104086:RegularExpressionLiteral", />/g), globalThis.__npTrace("104088:104094:StringLiteral", '&gt;'))).replace(globalThis.__npTrace("104113:104126:RegularExpressionLiteral", /^# (.*$)/gim), globalThis.__npTrace("104128:104141:StringLiteral", '<h1>$1</h1>'))).replace(globalThis.__npTrace("104160:104174:RegularExpressionLiteral", /^## (.*$)/gim), globalThis.__npTrace("104176:104189:StringLiteral", '<h2>$1</h2>'))).replace(globalThis.__npTrace("104208:104223:RegularExpressionLiteral", /^### (.*$)/gim), globalThis.__npTrace("104225:104238:StringLiteral", '<h3>$1</h3>'))).replace(globalThis.__npTrace("104257:104275:RegularExpressionLiteral", /\*\*(.*?)\*\*/gim), globalThis.__npTrace("104277:104298:StringLiteral", '<strong>$1</strong>'))).replace(globalThis.__npTrace("104317:104331:RegularExpressionLiteral", /\*(.*?)\*/gim), globalThis.__npTrace("104333:104346:StringLiteral", '<em>$1</em>'))).replace(globalThis.__npTrace("104365:104379:RegularExpressionLiteral", /`([^`]+)`/gim), globalThis.__npTrace("104381:104479:StringLiteral", '<code style="background: rgba(255,255,255,0.1); padding: 2px 4px; border-radius: 3px;">$1</code>'))).replace(globalThis.__npTrace("104498:104505:RegularExpressionLiteral", /\n/gim), globalThis.__npTrace("104507:104513:StringLiteral", '<br>')));
        }
        escapeHTML(str) {
            return globalThis.__npTrace("104566:104729:CallExpression", globalThis.__npTrace("104566:104569:Identifier", str).replace(globalThis.__npTrace("104578:104588:RegularExpressionLiteral", /[&<>'"]/g), tag => globalThis.__npTrace("104597:104728:ParenthesizedExpression", (globalThis.__npTrace("104598:104727:BinaryExpression", globalThis.__npTrace("104598:104720:ElementAccessExpression", globalThis.__npTrace("104598:104715:ObjectLiteralExpression", {
                '&': globalThis.__npTrace("104613:104620:StringLiteral", '&amp;'),
                '<': globalThis.__npTrace("104635:104641:StringLiteral", '&lt;'),
                '>': globalThis.__npTrace("104656:104662:StringLiteral", '&gt;'),
                "'": globalThis.__npTrace("104677:104684:StringLiteral", '&#39;'),
                '"': globalThis.__npTrace("104699:104707:StringLiteral", '&quot;')
            })[globalThis.__npTrace("104716:104719:Identifier", tag)]) || globalThis.__npTrace("104724:104727:Identifier", tag))))));
        }
    }
    // Auto-initialize when DOM is ready
    if (globalThis.__npTrace("104787:104820:BinaryExpression", globalThis.__npTrace("104787:104806:PropertyAccessExpression", globalThis.__npTrace("104787:104795:Identifier", document).readyState) === globalThis.__npTrace("104811:104820:StringLiteral", 'loading'))) {
        globalThis.__npTrace("104828:104897:CallExpression", globalThis.__npTrace("104828:104836:Identifier", document).addEventListener(globalThis.__npTrace("104854:104872:StringLiteral", 'DOMContentLoaded'), () => globalThis.__npTrace("104880:104896:NewExpression", new NotepadApp())));
    }
    else {
        globalThis.__npTrace("104914:104930:NewExpression", new NotepadApp());
    }
    // Export for modular usage
    globalThis.__npTrace("104969:104999:BinaryExpression", globalThis.__npTrace("104969:104975:Identifier", window).NotepadApp = globalThis.__npTrace("104989:104999:Identifier", NotepadApp));
})());
