# Notepad

Windows 11 Notepad, rebuilt in PowerShell 7 from an HTML/JS simulacrum, as one script, `Notepad.ps1`.
It embeds no browser, JavaScript runtime, compiled bridge, WPF or Windows Forms. It is on its way,
through PSC, to a single NativeAOT executable; that executable does not exist yet.

## How it was made

1. **The simulacrum.** `reference/notepad.html` is an HTML/CSS/JS imitation of Windows 11 Notepad,
   written in a web container: MansfieldPlumbing/JS2PS `experiments/notepad.html`, 101,175 bytes,
   SHA-256 `3f0981401c086bc4eb9d1bb0c8716ac57797c59b1b30e3078c07f820044236e7`.
2. **Extraction.** `-ExtractTypeScript` drives a browser over the DevTools protocol and pulls the page's
   script out as `reference/notepad.ts`; `-BuildTypeScript` and `-BuildDesign` compile it with `tsc`
   under Node (`notepad.compiled.js`, `notepad.design.ts`/`.js`, a trace build). What came out is the
   design data inline in `Notepad.ps1`: a PSD1-compatible `data` block holding the original CSS, the
   generated HTML tree and the SVGs. Node and TypeScript were needed to port, not to run.
3. **The native port.** A direct Win32 window and input loop, Direct2D drawing and DirectWrite text, a
   QuickPS-derived native delegate binder, retained application state with stable view IDs and hit
   regions, and a piece-table document. Layout is mapped into explicit drawing routines; there is no CSS
   cascade engine.
4. **Measured against its sources.** `-Compare` runs real Windows Notepad, the reference page and this
   port, and judges each property in a Windows/reference/PowerShell verdict table.
5. **One script.** The port began as `Notepad.ps1` running six scripts from `src` and two tests. PSC
   (`Invoke-PSC.ps1 -Mode Consolidate`) folded each into `Notepad.ps1` as a function; the checks the
   tests held are its `-VerifyModel` and `-VerifyGraphics` switches.
6. **NativeAOT, in progress.** PSC lowers PowerShell to IL and links a NativeAOT executable. Of
   `Notepad.ps1`'s 89 members, 23 lower today: the piece-table document core and two functions. What
   remains is by category: member access on dynamically typed values, cmdlets and pipelines, the folded
   scripts' dynamic modules, catches that read `$_`, and a few single constructs. When it builds, its
   resource use will be compared with the simulacrum in a browser and with Windows Notepad.

Nothing here uses WinForms or WPF, so an Android port replaces the window, graphics and services
layers with a JNI canvas rather than rewriting the application.

## Run

Requires Windows x64 and PowerShell 7. Double-click **Start Notepad.cmd**, or:

```powershell
pwsh -NoProfile -STA -File .\Notepad.ps1
pwsh -NoProfile -STA -File .\Notepad.ps1 -Path C:\example\notes.txt
```

`-NoSession` neither loads nor writes preferences and session data (normally in
`%LOCALAPPDATA%\NotepadPS1`). `-NoAnimation` skips the entrance animation.

## Checks

```powershell
pwsh -NoProfile -File .\Notepad.ps1 -VerifyModel
pwsh -NoProfile -STA -File .\Notepad.ps1 -VerifyGraphics
pwsh -NoProfile -STA -File .\Notepad.ps1 -NoSession -RunSeconds 2
pwsh -NoProfile -STA -File .\Notepad.ps1 -Compare -VerifyNativeFeatures
```

`-VerifyModel` checks saving an inactive document, Unicode edits, undo/redo, find/replace,
UTF-8/BOM/CRLF and session restoration. `-VerifyGraphics` checks all 25 icons, native window creation,
Direct2D, DirectWrite, text metrics, caret/hit-test round trips and selection rectangles. `-Compare`
writes its typed evidence to `evidence`; **Settings → Compare with Windows Notepad** runs it inside the
application. None of these establishes screenshot equality or complete input-method support.

## Implemented

- Text entry, grapheme-aware cursor and deletion, mouse and word selection, clipboard, undo/redo,
  wrapping, scrolling and zoom.
- Tabs, menus, settings, theme and font choices, find/replace, Go To, status bar, close prompts, UTF-8
  file opening and saving, and session persistence.
- DWM materials (Mica, Acrylic, Reverse Mica) and curved or straight corners; a formatting toolbar
  that edits Markdown source; whole-document Copy as text or as a UTF-8 file.
- Saves target each document's own buffer; a cancelled or failed save neither closes a document nor
  marks it saved.

## Not yet

Parity with Windows Notepad is not established. Still to do: source-accurate blur, shadows and timed
transitions; clipping and overflow; keyboard menu behaviour; caret geometry across fonts and DPI;
IME/TSF composition; UI Automation; spell-check; printing and page setup (they show an unimplemented
message); a rich Markdown preview (headings only today); movable tabs; kinetic scrolling; scrollbar
dragging; context menus; non-UTF-8 decoding. Literal replace-all uses .NET ordinal matching, so some
JavaScript Unicode case and replacement-token behaviour differs. Drawing uses a software Direct2D HWND
render target; the final presentation path is not chosen.

## Files

- `Notepad.ps1`: the whole application, its design data and its checks.
- `Start Notepad.cmd`: starts it.
- `reference/notepad.html`: the original simulacrum.
- `reference/notepad.design.html`: the corrected reference page `-BuildDesign` generates, loading
  `notepad.design.js`.
- `reference/notepad.ts`, `reference/notepad.design.ts`: the TypeScript extracted from it, with their
  compiled JavaScript, source maps, trace build and `design-intent.clixml`.
- `reference/PORT-STUDY.md`: the initial study of the source.
- `QuickPS-LICENSE`: attribution and license for the native binder.
