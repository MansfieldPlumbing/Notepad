# Notepad

Windows 11 Notepad, rebuilt in PowerShell 7 from an HTML/JS simulacrum, as one script, `Notepad.ps1`.
It embeds no browser, JavaScript runtime, compiled bridge, WPF or Windows Forms. The native executable
is built with [PSC](https://github.com/MansfieldPlumbing/PSC). Native builds have been verified during
development. A verified executable release for this revision is still pending.

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
6. **Native realization.** PSC lowers typed PowerShell to IL and links a NativeAOT executable.
   Verify the application and native artifact against the corresponding PSC revision.

Nothing here uses WinForms or WPF, so an Android port replaces the window, graphics and services
layers with a JNI canvas rather than rewriting the application.

## Run

Double-click **Start Notepad.cmd** to launch the Windows x64 NativeAOT build at `build\Notepad.exe`.
If the executable is absent, the launcher runs the source in PowerShell 7.
Double-click **Start Notepad from Source.cmd** to use PowerShell 7 even when a build is present.
You can also start that executable directly:

```powershell
.\build\Notepad.exe
.\build\Notepad.exe -Path C:\example\notes.txt
```

`-NoSession` neither loads nor writes preferences and session data (normally in
`%LOCALAPPDATA%\NotepadPS1`). `-NoAnimation` skips the entrance animation.

When you customize the icon, Notepad maintains **Notepad (custom icon).lnk** next to the running app.
The shortcut follows the icon selected in the title bar and can be pinned separately.

## Checks

```powershell
pwsh -NoProfile -STA -File '.\Start Notepad from Source.ps1' -VerifyModel
pwsh -NoProfile -STA -File '.\Start Notepad from Source.ps1' -VerifyGraphics
pwsh -NoProfile -STA -File '.\Start Notepad from Source.ps1' -NoSession -RunSeconds 2
pwsh -NoProfile -STA -File '.\Start Notepad from Source.ps1' -VerifyNativeFeatures
```

`-VerifyWindow` checks caption hit tests, window bounds, and maximize and restore without moving the
pointer or sending keyboard shortcuts. It may still show test windows. Add
`-InteractiveWindowVerification` to exercise physical drag, Snap hover, and keyboard snapping on
a desktop reserved for testing.

`-VerifyModel` checks saving an inactive document, Unicode edits, undo/redo, find/replace,
UTF-8/BOM/CRLF and session restoration. `-VerifyGraphics` checks all 25 icons, native window creation,
Direct2D, DirectWrite, text metrics, caret/hit-test round trips and selection rectangles.
`-VerifyNativeFeatures` writes replay evidence to `UIAutomation-TestData`.

## Implemented

- Text entry, grapheme-aware cursor and deletion, mouse and word selection, clipboard, undo/redo,
  wrapping, scrolling and zoom.
- Right-click or press Shift+F10 in the editor for editing commands, Markdown table insertion and
  Unicode tools. The display options change reading order and mark control characters in the
  editor without changing the file.
- Tabs, menus, settings, theme and font choices, find/replace, Go To, status bar, close prompts, UTF-8
  and BOM-marked UTF-16 LE/BE file opening and saving, and session persistence.
- Drag a tab along its strip to reorder it. Drop it on another Notepad tab strip to dock it there,
  or release it outside the windows to open it in a new window. A move between windows preserves
  the text, file association, encoding, and selection. Use Ctrl+Tab or Ctrl+Shift+Tab to switch
  tabs, or use the arrows when the tab strip fills up.
- Enable Recent Files in Settings to keep a list of recently opened or saved documents. The Opening Files
  preference applies to File → Open and File → Recent.
- Mica, Acrylic, Reverse Mica and Clear backdrops with curved or straight corners. The four-corner
  gradient has its own strength setting.
- The **</>** toolbar switch toggles between Markdown source and formatted editing. Format view
  renders inline bold, italic, and strikethrough and supports editing cells in pipe-delimited
  tables with a header separator. Use Tab and Shift+Tab to move between cells. The table menu
  adds and removes rows and columns. Tables over 128 source rows and uneven tables remain in
  text form. A cell copies as visible text. A whole table copies as Markdown.
- The copy-document button copies the complete document as text or as a UTF-8 file.
- C and PowerShell source highlighting uses the configurable color palette. Windows spelling
  providers can mark misspellings in text and Markdown when the current UI language is available.
- Saves target each document's own buffer; a cancelled or failed save neither closes a document nor
  marks it saved.
- Click the title-bar notepad icon to cycle through 19 colors. Right-click to step back. Hold for
  about two-thirds of a second and release over the icon to switch to the Windows icon catalog.
  Repeat the hold to return to the color palette.
- **View → PowerShell** runs commands in a persistent installed `pwsh.exe` session found on PATH.
  The dialog shows recent output from the command session. Close the dialog to return to your
  document, or choose **End session** to stop the process. The session uses redirected streams and
  supports noninteractive commands. Interactive terminal programs need a terminal host.

## Not yet

Parity with Windows Notepad is not established. Still to do: source-accurate blur, shadows and timed
transitions; clipping and overflow; keyboard menu behaviour; caret geometry across fonts and DPI;
IME/TSF composition; UI Automation; spelling suggestions and dictionary commands; printing and page setup; a rich Markdown
preview; encoding selection for new files. Moving a tab between windows starts a new undo history.
Literal replace-all uses .NET ordinal matching, so some
JavaScript Unicode case and replacement-token behaviour differs. Drawing uses a software Direct2D HWND
render target; the final presentation path is not chosen.

## Upstream PSC integration

The [PSC integration roadmap](https://github.com/MansfieldPlumbing/PSC#integration-roadmap) uses Notepad as an application-level verification target (A1) and identifies reusable presentation and document mechanisms (H2/F4).

- `NotepadDocument`, `NotepadPiece` and the grouped edit journal supplied the prior art for PSC's revision-checked document editing. Application-specific selection and view state remain here.
- The current single-replace path can use cached match offsets without checking the active document revision; creating a new tab also changes active identity without refreshing matches. Treat this as an open defect, not a behavior to preserve when acquiring mechanisms.
- Window, graphics, hit testing and input remain concrete application proofs for shared presentation and native interop. Verify current Windows model, graphics and native realization before replacing local implementations.

## Files

- `Notepad.ps1`: the whole application, its design data and its checks.
- `Start Notepad.cmd`: starts it.
- `Start Notepad from Source.cmd` and its PowerShell launcher: start the app from source.
- `reference/notepad.html`: the original simulacrum.
- `reference/notepad.design.html`: the corrected reference page `-BuildDesign` generates, loading
  `notepad.design.js`.
- `reference/notepad.ts`, `reference/notepad.design.ts`: the TypeScript extracted from it, with their
  compiled JavaScript, source maps, trace build and `design-intent.clixml`.
- `reference/PORT-STUDY.md`: the initial study of the source.
- `QuickPS-LICENSE`: attribution and license for the native binder.
