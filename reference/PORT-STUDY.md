# Notepad: PowerShell port study

Studied October 16, 2026. This is a design study and an executable data extraction, not a completed native application. The supplied HTML is the fidelity reference, including its generated HTML, CSS, SVG, and interactive states.

## Conclusion

Use an application-owned retained tree in idiomatic PowerShell, inline PSD1-compatible design data, a retained text model, and direct Windows graphics/input bindings in the QuickPS style. Draw and hit-test from the same arranged geometry. Present completed frames through a buffered surface. Preserve the actual source appearance, including small arrows, insertion carets, state-dependent visibility, subpixel measurements, and clipping.

This is feasible as a staged native implementation, but exact visual parity is an acceptance criterion to demonstrate, not a property obtained by choosing DirectWrite or double buffering. The browser currently supplies layout, text editing, input methods, selection, accessibility, animation, and painting. These services must be replaced deliberately.

## Evidence and delivered files

- `notepad.html`: unchanged reference; 101,175 bytes and 3,095 lines when split on LF.
- Source Git blob: `9786ee25a52ba6ee9dc984e6dbe4809b63bc216e`.
- Source SHA-256: `3f0981401c086bc4eb9d1bb0c8716ac57797c59b1b30e3078c07f820044236e7`.
- QuickPS local commit inspected: `62747ebf088d79fd45e704a09bfcdc5e998f6dfc`.
- Read QuickPS README, WORKORDER, Native, Window, Composition, demonstration composition/presentation flows, and verification constraints. Existing untracked SoundRecorder files were left alone.
- `Notepad.Design.ps1`: executable extraction containing restricted `data { ... }` literal data. Includes ordered stylesheet blocks/declarations, exact raw CSS, SVG strings, the static generated view tree, original view templates, binding expressions, defaults, menu actions, and source method locations.
- `extract-design.cjs`: reproducible extractor for this specific source. It is a study utility, not part of the proposed application runtime or a general HTML/CSS parser.
- `Verify-Design.ps1`: validates restricted data syntax, reference hash, and complete JSON value round-trip.
- `Notepad.Contracts.ts`: proposed interface vocabulary for an optional typed intermediate; not a translated implementation.

Inventory: 156 top-level stylesheet blocks (including one keyframes block), 749 declarations including keyframes, 25 SVG icon entries, 353 static generated view nodes including symbolic SVG references, 72 static IDs, 12 dynamic skeleton expressions, 32 unique menu actions, 42 class methods including the constructor. Runtime tabs, modal controls and Markdown elements are additional instantiated nodes, not included in the static count.

The extraction preserves author CSS and source templates. It does not yet compute CSS, decode all HTML text entities, resolve dynamic expressions, instantiate repeating tabs, or render anything natively. Text nodes in the extracted tree omit formatting whitespace; the original skeleton is also retained verbatim so that omission cannot silently define native whitespace behavior. `ICONS` references become symbolic `svg-ref` nodes. Binding expressions remain descriptions to translate, not code to evaluate in PowerShell.

## What the original contains

| Source lines | Responsibility | PowerShell counterpart |
|---|---|---|
| 1–25 | Document metadata, root, initialization wrapper | Window metadata and root creation |
| 26–1276 | Integrated Fluent stylesheet | Inline restricted design data, resolved against retained state |
| 1278–1314 | Style injection and SVG icon library | One-time design load; cached vector geometry |
| 1317–1434 | Defaults, application state, persistence, initialization | Private application state and startup orchestration |
| 1436–1975 | Generated HTML skeleton and element cache | Declarative retained view structure and node lookup |
| 1978–2090 | Tabs and close prompts | Stable tab IDs, tab collection and transitions |
| 2093–2190 | Browser file adapters | Native file operations with explicit completion outcomes |
| 2193–2261 | Editor and status metrics | Shared text layout, selection state, presentation bindings |
| 2264–2411 | Active text, find, replace | Document edits and match state |
| 2414–2487 | Go To and modal builder | Retained modal subtree and continuation |
| 2490–2579 | Settings synchronization and menus | State bindings, popup layout, dismissal |
| 2582–2887 | Events and keyboard shortcuts | Window/input translation and local action scriptblocks |
| 2890–3080 | Actions and Markdown preview | Application commands and a limited rich-text preview tree |

The external HTML is small because `renderAppSkeleton()` builds hundreds of elements inside a template string. Porting only the outer root would discard most of the application. `header`, `nav`, `main`, `footer`, buttons, textarea, inputs, selects, anchors, title attributes, and hidden file input each have responsibilities. Keep their identity, order, parentage, text, selection policy, focus behavior and activation semantics. Map browser-only infrastructure to Windows services. There need not be an HTML parser in the shipped app.

The source has limited accessibility: many menu rows, tabs, toggles, and radio choices are clickable divs. Record that baseline; a native accessibility provider should expose their actual roles without changing their appearance. Do not assume HTML already provides a complete keyboard menu or accessibility implementation.

## Inline PSD1: keep the full style semantics

`$Design = data { @{ ... } }` inside the PS1 gives literal, restricted data without a separate PSD1 dependency. Keep application callbacks outside it. The supplied `Notepad.Design.ps1` demonstrates this with the entire extracted design.

A selector-keyed hashtable alone loses duplicate rules and declaration order. Use an ordered array of rule records, with ordered declaration records and nested keyframes. Keep CSS values as authored strings in the first representation: `11pt`, `rgba(...)`, `var(...)`, percentages and compound shorthands must not be guessed into integers. Compile those records once into the renderer's measured styles, not repeatedly during every paint.

The native resolver needs this source's bounded feature set: inheritance; custom properties; selector groups; type/class/ID/attribute selectors; descendants; hover, active, focus and focus-within; selection and scrollbar pseudo-elements; specificity and source-order precedence; shorthands; inline overrides; box sizing; visibility versus removal; opacity; SVG fill and currentColor. A general browser engine is not required, but the subset must be explicit and complete for this file.

Some visual values live outside FLUENT_STYLES: editor font overrides, flyout positioning, check visibility, row display, SVG path fills, Markdown preview wrapper styles and inline-code styles. They are part of the same port contract. Browser default styles also matter: heading sizes/weights, strong/em/code typography, native input/select behavior and default SVG sizing are not all declared in CSS.

Examples that should survive unchanged:

- Titlebar 40px, menubar 38px, statusbar 28px; tabs 34px high with 130px minimum and 220px maximum width; window buttons 46px wide.
- Editor padding 14px vertically and 16px horizontally; four-space tab stops; line height 1.45; font starts at 11pt.
- Find popup is anchored 10px below the workspace top and 24px from its right edge. Menu flyouts start at menubar-relative y=36px, despite a 38px menubar.
- Settings uses `1fr 280px`, a 40px gap, maximum width 1080px and outer padding 24px 40px 60px. There are no responsive media queries to invent during porting.
- Toggles have a 40×20 track. The knob changes from 12×12 to 14×14 when on and translates 18px. Accordions rotate their exact chevron path 180 degrees over 200ms.
- Menus fade and translate from y=-2 over 100ms; find uses 120ms; modal uses 150ms. Hover color transitions range from 80ms to 150ms.
- Scrollbars occupy 12px with a transparent 3px thumb border, creating a slimmer visible thumb. Their authored thumb colors remain white even in the light theme.
- The dropdown's encoded chevron has a fixed #9d9d9d fill. Recoloring it to a theme token would change the reference.

Global z-index sorting is insufficient. The menubar creates a stacking context at 100, and its flyout's 1000 is local to that context. Settings at root level 500 still covers that flyout. Modal at 2000 covers settings. Retain stacking contexts, ancestor clipping, transforms, and paint order.

## Retained state and hit regions

Separate three kinds of state with ordinary PowerShell values:

1. Documents/settings: tab ID, title, text, dirty state, source path/encoding/newline policy, Markdown flag, settings and session data.
2. Interaction: focus node, hovered and pressed nodes, pointer capture, active menu, modal continuation, editor selection, find query/matches/index, scrolling, accordion expansion and animation progress.
3. Derived rendering: resolved styles, measured text layouts, arranged rectangles, clips, transforms, cached paths/brushes and paint order.

Use stable view keys such as `tab:17/close`; retain objects when text or hover changes. Keep a case-sensitive dictionary for source IDs and class names. A `[pscustomobject]` or hashtable is sufficient for app state; helper functions and scriptblocks can remain private in the invoked script. No class framework or global dispatcher is required. An app-local command table is useful for sharing menu/shortcut behavior and does not make QuickPS own application policy.

Each frame is derived through `state → styles → measure → arrange → paint`. Store final hit regions from arranged geometry. Hit testing walks the presented tree in reverse paint order and honors ancestor clips, scroll transforms, modal boundaries and pointer-events. A disabled menu item must not activate. A child close-button action must stop before the tab-switch action. A hidden checkmark still occupies layout space; display:none does not.

On pointer movement, recompute the hovered ancestry so descendant hover and focus-within selectors behave correctly. Hover alone cannot move selection or keyboard focus. Pointer capture supports selection beyond the editor bounds and release outside the window. Route local handlers before ancestor/global handlers in the same order as the reference, including stop-propagation behavior.

## Buffering and invalidation

Recommend Direct2D/DirectWrite on a D3D11-backed DXGI surface, with composition/effects as needed. It is a proposal requiring new bindings. QuickPS currently has D3D12 and DXGI presentation, but no complete Direct2D/DirectWrite or D3D11 binding; a D3D12 swapchain is not a drop-in Direct2D target. Choosing D3D12 would add explicit interop work. A basic HWND render target could prove text and shapes early, but the final surface must also support the reference's blur/effects and SVG requirements.

Keep the last presented layout and hit regions together with a generation number. Paint the next frame into the back surface and publish its layout/hit regions when presentation succeeds. A pointer event must not hit new geometry while the user is still seeing the previous frame. Buffer count and model retention are independent: two presentation buffers do not require cloning all application state.

Start with full-frame repaint on invalidation, then measure before adding dirty rectangles. Hover and caret blink can invalidate small areas; edits invalidate text layout and downstream status; theme changes invalidate brushes and appearance; font/wrap/zoom/resize changes invalidate text measurement. Blur and shadow can expand dirty regions far beyond a control's rectangle. Flip-model buffers must be fully valid after rotation; do not patch an arbitrary old back buffer and assume unchanged pixels survived.

Retain text layouts and vector geometry. Avoid per-glyph PowerShell/COM calls, recomputing every style per frame, or a mandatory busy render loop. Render on input, resize, animation ticks and caret ticks. UI-thread serialization, coalesced invalidations, and explicit resource disposal fit QuickPS's app-owned loop.

## Exact text caret and chevrons

Preserve the SVG path data, viewBox, inherited fill, explicit fill, opacity and transforms. The small menu arrows and accordion chevrons should be vector paths, not replacement font glyphs. The app icon, window controls, find arrows and tab-close icon also have distinct sizes and inherited styles. SVG currentColor must resolve at each instance.

The insertion caret belongs to the text system. Its x/y, height and affinity must come from the same shaped layout used to draw text and selection. Use DirectWrite HitTestTextPosition for position-to-geometry, HitTestPoint for geometry-to-position, and HitTestTextRange for selection rectangles. Carry leading/trailing cluster affinity, wrapping-edge affinity, preferred x for vertical navigation, and selection direction. UTF-16 offsets match JS/.NET storage but are not sufficient for navigating combining marks, surrogate pairs, ligatures or bidirectional text.

The source sets caret color to the accent: #0090f1 dark and #005fb8 light. It does not specify caret width, blink cadence, overwrite behavior or baseline geometry; those are supplied by the browser/platform. Measure those on the chosen reference environment before fixing native defaults. Calling CreateCaret alone does not establish color or pixel parity. A custom painted caret can share the frame, while system caret location/accessibility and IME composition positioning must remain synchronized.

CSS px map to logical 96-DPI units; physical pixels follow the current window DPI. Font points convert with 96/72, so the default editor size is 14.6667 logical pixels and its nominal line height is 21.2667. Keep fractional layout and only apply reference-compatible snapping at the raster boundary. Browser font fallback and rasterization can still differ from a native renderer and must be compared.

Text input cannot be reduced to WM_KEYDOWN and single characters. A custom text surface needs IME/TSF composition, candidate-window placement, surrogate handling, clipboard, undo/redo, selection, word movement, pointer dragging, scrolling and accessibility. QuickPS currently demonstrates outgoing native/COM calls; implementing incoming TSF/UIA COM interfaces and safe callbacks in PowerShell is an additional engineering problem. Prove the UI-thread/runspace callback mechanism early. A standard EDIT/RichEdit control is a useful behavioral comparison, but accepting its default wrapping/caret/scrollbar rendering would not prove visual parity.

## Browser observations

Rendered the unchanged file locally and inspected dark default, modified text, settings, expanded font accordion, light theme and Edit menu. Observed viewport 1280×720 CSS pixels at devicePixelRatio 1.25. Default geometry: titlebar y=0 h=40, menubar y=40 h=38, editor y=78 h=614, statusbar y=692 h=28. Computed editor font 14.6667px, line height 21.2667px; caret colors agree with the palette.

An active modified tab with no hover shows BOTH its dirty dot and close button: the later `.unsaved .tab-dot` rule wins. That was confirmed from computed styles. A later hover rule hides the dot. Do not simplify this into a mutually exclusive indicator unless deliberately changing the visual specification. The tab-close SVG also inherits black fill in this reference because no rule assigns it currentColor; the screenshot and computed fill confirm that detail. The chevron/close icon seen in the source should not be silently replaced by a more conventional Fluent icon.

At the inspected size, the expanded settings grid measured 1080px wide, with tracks 760px and 280px and a 40px gap. Its left edge was x=94 because the scrolling area also reserves scrollbar space. Preserve measured layout and scrollbar-reserved space rather than infer centered coordinates from the outer window alone. Individual coordinates can be fractional at this DPI. At smaller widths, intrinsic minimum sizes and the absence of media queries must be measured before deciding whether the source clips or overflows.

Only source extraction and selected browser states have been verified. There is no native screenshot comparison, native performance result, IME validation, or evidence of complete caret parity yet.

## Source behavior to preserve or explicitly adjudicate

Appearance is fixed by the user's requirement. Existing behavioral defects should be recorded separately; do not silently turn corrections into alleged source parity.

| Source behavior | Consequence for implementation |
|---|---|
| `saveTab(tab)` always assigns editor.value to that tab | Save All can overwrite other tabs' buffers. Native save must receive the target document's text; document the intentional correction. |
| Save All uses async operations without awaiting the group | Native save/close should use explicit Saved/Cancelled/Failed results and await completion before closing. |
| Close-tab Save closes after saveTab returns even on cancellation | Cancellation must not be mistaken for successful persistence. |
| Titlebar close checks dirty tabs, menu close/exit bypass that path | Define one native close policy and record any divergence. |
| Open picker discards its file handle; save retains one later | First Save after Open may ask for another location in the reference. A native path-based policy changes this behavior. |
| Browser textarea normalizes newlines | The CRLF status toggle is not proof that CRLF bytes are written. Keep logical text and output newline policy separately. |
| Cursor line/column fields are recorded but not restored on tab switch | A native per-tab caret/selection/scroll restore is useful but differs from current behavior. |
| Session saves on certain tab/save operations, not every input | Continuous crash recovery would be an extension; native persistence needs an explicit policy. |
| File handles are included in JSON session data | They do not serialize into working writable handles. Persist only data and re-establish file identity explicitly. |
| Formatting toggle stores a preference; Clear formatting is empty | Do not claim an existing rich-text editor. |
| Recent-files toggle is persisted but Recent stays a disabled placeholder | Do not claim a working recent-file list. |
| Opening-files preference is saved but ignored by openFileDialog | New-window opening requires an intentional behavior decision. |
| What's new, Help, Feedback and some caption/status controls lack handlers | Preserve appearance, inventory missing behavior, implement only as a documented addition. |
| Markdown supports headings, emphasis and inline code via replacements | Preserve that limited grammar and typography; adopting full CommonMark changes output. |
| Replace-current splices literal text; Replace-all uses JS replacement tokens | PowerShell `-replace` is not automatically equivalent, especially $$, $&, prefix and suffix substitutions and case folding. |
| Query matching uses escaped JS regex with g/gi | OrdinalIgnoreCase or .NET default regex may differ on Unicode; compare fixtures before substituting. |
| Global shortcuts remain active over settings/modals | Modal keyboard confinement is an interaction correction, not established source behavior. |

## Where TypeScript helps

Use a typed intermediate if it makes document identity, editor snapshots, selection affinity, effect completion, view state and native-facing interfaces explicit. Keep the current HTML/CSS as the visual oracle. First isolate state transitions and host adapters in the original JS, annotate/check it or port that small boundary to TS, then replay the same commands in PS1. Do not rewrite the entire DOM application in TS merely to translate syntax a second time.

`Notepad.Contracts.ts` sketches those boundaries. It deliberately distinguishes persisted document state from native handles, an editor snapshot from the whole application, paint geometry from hit regions, and a requested save from a completed save. These distinctions address concrete problems in the source. The final PS1 can express the same concepts with private functions, scriptblocks, hashtables and explicitly typed native arguments. TypeScript need not ship with it.

## Implementation sequence and acceptance

1. Freeze the source and extract design data (done here). Capture the full browser state matrix before replacing any rendering behavior.
2. Prove an invoked PS1 creating a native window, receiving input safely on its UI thread, and rendering DirectWrite text plus the exact icon paths. Match one caret's geometry and one wrapped selection before building the rest of the application. This is the first feasibility gate.
3. Implement this file's layout/style subset and retained state. Match empty dark/light views, tabs, flyouts, settings and dialogs at multiple sizes and DPI values. Keep measure/arrange and hit testing deterministic and independently inspectable.
4. Port document/edit/find transitions, add correct target-document save outcomes, and replay fixtures against the browser/typed reference. Clearly mark source defects corrected by the native app.
5. Complete text input services, clipboard, undo, IME, accessibility, file dialogs, persistence and printing. Bind missing OS mechanisms directly as QuickPS components; keep app policy in Notepad.ps1.
6. Demonstrate fidelity through screenshots, text metrics and interaction traces. Only then optimize repaint area or buffering.

The verification matrix should include: dark/light/system theme; hovered/pressed/disabled states; active/inactive clean/dirty tabs; long titles and tab overflow; all menus/submenus; find empty/no-result/multiple matches with case/wrap; replace; Go To; cancel/save/discard prompts; both accordions; all font families/styles/sizes; 20/100/500% zoom; word wrap; statusbar visibility; light scrollbars; Markdown preview; resize and scrolling.

Caret tests need insertion at beginning/end, empty lines, tabs at different columns, trailing spaces, wrap boundaries, scroll offsets, RTL/mixed-direction text, emoji, combining marks, font fallback, selection forward/backward, click/drag/double-click/keyboard movement, focus loss, and IME composition. Compare the caret position and selection rectangles, not just document contents. Record browser build, OS fonts, DPI, viewport, locale, clock and animation phase. Use stable-phase screenshots plus temporal captures for blinking and transitions.

QuickPS source additions must keep independent invocation, dot-source rejection, ABI comments and explicit disposal, and run its source ratchet. DirectWrite (`dwrite.dll`), shell dialogs or text-input services may require narrowly justified additions to the ratchet's current DLL allowlist. Its existing geometric/image gates do not establish UI fidelity. No QuickPS source changes were made for this study.

## Primary references

- Original: https://github.com/MansfieldPlumbing/JS2PS/blob/main/experiments/notepad.html
- Guide: https://github.com/MansfieldPlumbing/QuickPS
- Text drawing and hit testing: https://learn.microsoft.com/en-us/windows/win32/direct2d/direct2d-and-directwrite
- Selection geometry: https://learn.microsoft.com/en-us/windows/win32/api/dwrite/nf-dwrite-idwritetextlayout-hittesttextrange
- Text-services integration: https://learn.microsoft.com/en-us/windows/win32/tsf/text-stores

The native architecture is an engineering recommendation based on those APIs and the inspected repositories. It has not been validated as a pixel-equivalent renderer.
