# Notepad PS1 — native prototype

A direct Windows/PowerShell port in progress of MansfieldPlumbing/JS2PS's
`experiments/notepad.html`, guided by QuickPS. The application is PowerShell;
it does not embed a browser, JavaScript runtime, compiled custom bridge, WPF,
or Windows Forms. The original HTML is included as a fidelity reference.

## Run

Requires Windows x64 and PowerShell 7. Tested here on PowerShell 7.6.6.
Extract the entire ZIP, then double-click **Start Notepad.cmd**.

For a visible error console:

```powershell
pwsh -NoProfile -STA -File .\Notepad.ps1
```

Open a file:

```powershell
pwsh -NoProfile -STA -File .\Notepad.ps1 -Path C:\example\notes.txt
```

Use `-NoSession` to avoid loading or writing application preferences/session
data. Normally they live in `%LOCALAPPDATA%\NotepadPS1`.

Open **Settings → Compare with Windows Notepad** to run the comparison inside
the application and inspect the Windows/reference/PowerShell verdict table.
The work runs in a separate process while the editor stays available. The
Windows baseline is reused when its machine, build, executable hash, DPI and
paired screenshot hashes still match. **Refresh baseline** captures it again.

The same instrument is inline in `Notepad.ps1` and can print its table directly:

```powershell
pwsh -NoProfile -STA -File .\Notepad.ps1 -Compare
pwsh -NoProfile -STA -File .\Notepad.ps1 -Compare -RefreshReal
```

`Compare-Notepad.ps1` forwards to that entry point for compatibility. Logs and
typed evidence remain in `evidence`. Original files and the SHA-256 manifests
are retained beside the edits for review. UNKNOWN properties remain unverified.

**Settings → Appearance** includes Mica, Acrylic and Reverse Mica (DWM MicaAlt),
plus curved/straight corners. The window has a minimum track size of 768 × 478
device-independent pixels. The formatting toolbar provides headings, lists,
bold, italic, strikethrough, links and more options. These actions edit Markdown
source; the editor does not yet provide Windows Notepad's full styled Markdown
presentation. **Copy** in the ribbon copies the whole active document. Its settings
rocker switches between Unicode text and a UTF-8 `.txt` snapshot on the Windows
file clipboard; those snapshots remain in `%LOCALAPPDATA%\NotepadPS1\Clipboard`
so pasting still works after the app closes.

Startup paints a complete frame while hidden, then slides in from beyond the
right edge of the virtual desktop while fading over 320 ms. DWM's border color
is disabled. The ordinary window style and selected material are restored after
the entrance. `-NoAnimation` skips the entrance for stable comparison captures.

## Implemented

- Retained application state, stable view IDs and hit regions published after painting.
- Inline PSD1-compatible design data preserving the reference CSS and SVGs.
- Direct Win32 window and input loop, Direct2D drawing, DirectWrite text layout.
- Original SVG path geometry, including endpoint arcs and chevron rotation.
- Custom editor drawing, caret and selection from shared DirectWrite measurements.
- Text entry, grapheme-aware left/right/backspace/delete, mouse selection,
  word selection, clipboard, undo/redo, wrapping, scrolling and zoom.
- Tabs, menus, settings, theme/font choices, find/replace, Go To, status bar,
  close prompts, UTF-8 file opening/saving and session persistence.
- DWM material and corner controls, formatting toolbar, whole-document clipboard
  modes, and an integrated comparison page with cached native evidence.
- Save operations target each document's own buffer. Cancelled/failed saves
  do not close documents or mark them saved.

## Current limits — do not mistake this for completed parity

This is the initial native prototype. Exact visual/behavioral parity has
**not** been established. Rendering currently maps the source layout into
explicit native drawing routines; a complete CSS cascade/layout engine is
not implemented. The extracted HTML tree is included in the design contract;
the native view is constructed by the application routines.

Remaining work includes source-accurate blur/shadows and timed transitions,
complete clipping/overflow and keyboard menu behavior, text caret geometry
calibration across font/DPI combinations, IME/TSF composition, UI Automation
accessibility, spell-check, native printing/page setup, and a complete rich
Markdown preview. The current Markdown preview supports heading sizes but
does not yet reproduce inline emphasis/code styles. Literal replace-all uses
.NET ordinal matching and literal replacement, so some JavaScript Unicode
case/replacement-token behavior differs. Editor tab stops and baseline are
initial measurements requiring browser comparison. Long-tab scrolling,
dragging scrollbars, context menus, input-field pointer placement and
selection affinity at bidi/wrap boundaries need further work.

Printing/Page setup display an explicit unimplemented message. Recent files and
opening-files preference are shown/stored but native open currently
creates a tab. Session save/restore and close safety intentionally improve
some source behaviors. Only UTF-8 file decoding is currently supported.

The first surface uses a software Direct2D HWND render target for portability;
the final effects/presentation path is still to be selected and verified.

## Validation

```powershell
pwsh -NoProfile -File .\tests\Model.Verify.ps1
pwsh -NoProfile -STA -File .\tests\Graphics.Smoke.ps1
pwsh -NoProfile -STA -File .\Notepad.ps1 -NoSession -RunSeconds 2
pwsh -NoProfile -STA -File .\Notepad.ps1 -Compare -VerifyNativeFeatures
```

The graphics smoke exercises all 25 icons, native window creation, Direct2D,
DirectWrite, text metrics, caret/hit-test round trips and selection rectangles.
The model checks include saving an inactive document, Unicode edits, undo,
find/replace, UTF-8/BOM/CRLF and session restoration. These checks do not
establish screenshot equality or complete input-method support.

## Files

- `Notepad.ps1`: application state orchestration, retained views, input and rendering.
- `src/Design.ps1`: inline restricted design data, CSS, generated HTML tree and SVGs.
- `src/Graphics.Windows.ps1`: direct Direct2D/DirectWrite operations.
- `src/Window.Windows.ps1`: native window, DPI, input queue and message pump.
- `src/Services.Windows.ps1`: Windows file dialogs and clipboard.
- `src/Model.ps1`: document/edit/find/persistence operations.
- `src/Native.ps1`: QuickPS-derived native delegate binder with PSObject unwrapping
  and explicit native numeric argument conversion fixes in this project copy.
- `reference/notepad.html`: unchanged original design.
- `reference/PORT-STUDY.md`: detailed initial source study.
- `QuickPS-LICENSE`: attribution/license for the copied binder.

Your existing QuickPS repository was not changed. No package downloads or
Node.js/TypeScript installation are required to run this application.
