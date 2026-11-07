[CmdletBinding()]
param(
    [string]$Path,[int]$Width=1280,[int]$Height=720,[switch]$NoSession,[int]$RunSeconds=0,[string]$DiagnosticPath,
    [switch]$Compare,[string]$EvidenceDirectory=(Join-Path $PSScriptRoot 'evidence'),
    [switch]$RefreshReal,[switch]$SkipBrowser,[switch]$KeepProbeOpen,
    [switch]$ExtractTypeScript,[switch]$BuildTypeScript,[switch]$BuildDesign,[switch]$VerifyNativeFeatures,[switch]$CatalogIcons,
    [ValidateSet('editor','settings','comparison')][string]$StartPage='editor',
    [ValidateSet('mica','acrylic','reverseMica')][string]$Backdrop,
    [ValidateSet('curved','straight')][string]$CornerStyle,[switch]$NoAnimation
)
if($MyInvocation.InvocationName -eq '.'){throw 'Invoke Notepad.ps1 with &, not dot-sourcing.'}
$ErrorActionPreference='Stop'
if(-not $IsWindows){throw 'This direct Windows implementation requires PowerShell 7 on Windows.'}
if([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA'){throw 'Launch with pwsh -STA -File Notepad.ps1.'}

# Document core: a piece table. The original text is read-only, typed text is appended to an add buffer, and the
# document is a list of pieces referring into the two. Edits split and replace pieces and are recorded in a journal;
# undo and redo walk the journal. Saving streams the pieces out in order. Lowered by PSC; CoreLib only.
class NotepadPiece {
    [int] $Buffer
    [int] $Start
    [int] $Length
    [int] $LineBreaks
    NotepadPiece([int] $buffer, [int] $start, [int] $length, [int] $lineBreaks) {
        $this.Buffer = $buffer
        $this.Start = $start
        $this.Length = $length
        $this.LineBreaks = $lineBreaks
    }
}

class NotepadEdit {
    [int] $Position
    [NotepadPiece[]] $Removed
    [NotepadPiece[]] $Inserted
    NotepadEdit([int] $position, [NotepadPiece[]] $removed, [NotepadPiece[]] $inserted) {
        $this.Position = $position
        $this.Removed = $removed
        $this.Inserted = $inserted
    }
}

class NotepadDocument {
    # Buffer 0 is the original text, buffer 1 the append-only add buffer.
    [char[]] $Original
    [char[]] $Added
    [int] $AddedLength
    [System.Collections.Generic.List[NotepadPiece]] $Pieces
    [System.Collections.Generic.List[NotepadEdit]] $Journal
    [int] $JournalPosition
    [int] $SavedJournalPosition
    [int] $Length
    [int] $Revision
    static [int] $ChunkLength = 65536

    NotepadDocument([string] $text) {
        $this.Original = $text.ToCharArray()
        $this.Added = [char[]]::new(4096)
        $this.AddedLength = 0
        $this.Pieces = [System.Collections.Generic.List[NotepadPiece]]::new()
        $this.Journal = [System.Collections.Generic.List[NotepadEdit]]::new()
        $this.JournalPosition = 0
        $this.SavedJournalPosition = 0
        $this.Revision = 0
        [int] $total = $this.Original.Length
        [int] $at = 0
        while ($at -lt $total) {
            [int] $take = [Math]::Min([NotepadDocument]::ChunkLength, $total - $at)
            $this.Pieces.Add([NotepadPiece]::new(0, $at, $take, $this.CountBreaks(0, $at, $take)))
            $at = $at + $take
        }
        $this.Length = $total
    }

    [char] CharAt([int] $buffer, [int] $index) {
        if ($buffer -eq 0) { return $this.Original[$index] }
        return $this.Added[$index]
    }

    [int] CountBreaks([int] $buffer, [int] $start, [int] $length) {
        [int] $count = 0
        [int] $end = $start + $length
        for ([int] $i = $start; $i -lt $end; $i++) {
            if ($this.CharAt($buffer, $i) -eq [char]10) { $count = $count + 1 }
        }
        return $count
    }

    [int] AppendText([string] $text) {
        [int] $start = $this.AddedLength
        [int] $needed = $start + $text.Length
        if ($needed -gt $this.Added.Length) {
            [int] $capacity = $this.Added.Length
            while ($capacity -lt $needed) { $capacity = $capacity * 2 }
            [char[]] $grown = [char[]]::new($capacity)
            [Array]::Copy($this.Added, $grown, $start)
            $this.Added = $grown
        }
        $text.CopyTo(0, $this.Added, $start, $text.Length)
        $this.AddedLength = $needed
        return $start
    }

    # Ensures a piece boundary at position; returns the index of the first piece at or after it.
    [int] SplitAt([int] $position) {
        [int] $offset = 0
        for ([int] $index = 0; $index -lt $this.Pieces.Count; $index++) {
            [NotepadPiece] $piece = $this.Pieces[$index]
            if ($position -eq $offset) { return $index }
            if ($position -lt $offset + $piece.Length) {
                [int] $leftLength = $position - $offset
                [int] $leftBreaks = $this.CountBreaks($piece.Buffer, $piece.Start, $leftLength)
                [NotepadPiece] $left = [NotepadPiece]::new($piece.Buffer, $piece.Start, $leftLength, $leftBreaks)
                [NotepadPiece] $right = [NotepadPiece]::new($piece.Buffer, $piece.Start + $leftLength, $piece.Length - $leftLength, $piece.LineBreaks - $leftBreaks)
                $this.Pieces[$index] = $left
                $this.Pieces.Insert($index + 1, $right)
                return $index + 1
            }
            $offset = $offset + $piece.Length
        }
        return $this.Pieces.Count
    }

    # Replaces removeLength characters at position with the given pieces; returns the pieces removed.
    [NotepadPiece[]] ReplacePieces([int] $position, [int] $removeLength, [NotepadPiece[]] $insert) {
        if ($position -lt 0 -or $removeLength -lt 0 -or $position + $removeLength -gt $this.Length) { throw [System.ArgumentOutOfRangeException]::new('position') }
        [int] $first = $this.SplitAt($position)
        [int] $last = $this.SplitAt($position + $removeLength)
        [NotepadPiece[]] $removed = $this.Pieces.GetRange($first, $last - $first).ToArray()
        $this.Pieces.RemoveRange($first, $last - $first)
        for ([int] $i = 0; $i -lt $insert.Length; $i++) { $this.Pieces.Insert($first + $i, $insert[$i]) }
        [int] $insertedLength = 0
        for ([int] $i = 0; $i -lt $insert.Length; $i++) { $insertedLength = $insertedLength + $insert[$i].Length }
        $this.Length = $this.Length - $removeLength + $insertedLength
        $this.Revision = $this.Revision + 1
        return $removed
    }

    [void] Record([NotepadEdit] $edit) {
        if ($this.JournalPosition -lt $this.Journal.Count) { $this.Journal.RemoveRange($this.JournalPosition, $this.Journal.Count - $this.JournalPosition) }
        $this.Journal.Add($edit)
        $this.JournalPosition = $this.Journal.Count
    }

    [void] Insert([int] $position, [string] $text) {
        if ($text.Length -eq 0) { return }
        [int] $start = $this.AppendText($text)
        [NotepadPiece[]] $inserted = [NotepadPiece[]]::new(1)
        $inserted[0] = [NotepadPiece]::new(1, $start, $text.Length, $this.CountBreaks(1, $start, $text.Length))
        [NotepadPiece[]] $removed = $this.ReplacePieces($position, 0, $inserted)
        $this.Record([NotepadEdit]::new($position, $removed, $inserted))
    }

    [void] Delete([int] $position, [int] $length) {
        if ($length -eq 0) { return }
        [NotepadPiece[]] $none = [NotepadPiece[]]::new(0)
        [NotepadPiece[]] $removed = $this.ReplacePieces($position, $length, $none)
        $this.Record([NotepadEdit]::new($position, $removed, $none))
    }

    [void] Replace([int] $position, [int] $length, [string] $text) {
        [NotepadPiece[]] $inserted = [NotepadPiece[]]::new(0)
        if ($text.Length -gt 0) {
            [int] $start = $this.AppendText($text)
            $inserted = [NotepadPiece[]]::new(1)
            $inserted[0] = [NotepadPiece]::new(1, $start, $text.Length, $this.CountBreaks(1, $start, $text.Length))
        }
        [NotepadPiece[]] $removed = $this.ReplacePieces($position, $length, $inserted)
        $this.Record([NotepadEdit]::new($position, $removed, $inserted))
    }

    [int] PiecesLength([NotepadPiece[]] $pieces) {
        [int] $total = 0
        for ([int] $i = 0; $i -lt $pieces.Length; $i++) { $total = $total + $pieces[$i].Length }
        return $total
    }

    [bool] Undo() {
        if ($this.JournalPosition -eq 0) { return $false }
        $this.JournalPosition = $this.JournalPosition - 1
        [NotepadEdit] $edit = $this.Journal[$this.JournalPosition]
        [NotepadPiece[]] $ignored = $this.ReplacePieces($edit.Position, $this.PiecesLength($edit.Inserted), $edit.Removed)
        return $true
    }

    [bool] Redo() {
        if ($this.JournalPosition -eq $this.Journal.Count) { return $false }
        [NotepadEdit] $edit = $this.Journal[$this.JournalPosition]
        [NotepadPiece[]] $ignored = $this.ReplacePieces($edit.Position, $this.PiecesLength($edit.Removed), $edit.Inserted)
        $this.JournalPosition = $this.JournalPosition + 1
        return $true
    }

    [bool] Modified() { return $this.JournalPosition -ne $this.SavedJournalPosition }

    [int] LineCount() {
        [int] $breaks = 0
        for ([int] $i = 0; $i -lt $this.Pieces.Count; $i++) { $breaks = $breaks + $this.Pieces[$i].LineBreaks }
        return $breaks + 1
    }

    # Position of the first character of a zero-based line.
    [int] LineStart([int] $line) {
        if ($line -le 0) { return 0 }
        [int] $offset = 0
        [int] $seen = 0
        for ([int] $index = 0; $index -lt $this.Pieces.Count; $index++) {
            [NotepadPiece] $piece = $this.Pieces[$index]
            if ($seen + $piece.LineBreaks -ge $line) {
                [int] $end = $piece.Start + $piece.Length
                for ([int] $i = $piece.Start; $i -lt $end; $i++) {
                    if ($this.CharAt($piece.Buffer, $i) -eq [char]10) {
                        $seen = $seen + 1
                        if ($seen -eq $line) { return $offset + ($i - $piece.Start) + 1 }
                    }
                }
            }
            $seen = $seen + $piece.LineBreaks
            $offset = $offset + $piece.Length
        }
        return $this.Length
    }

    [int] LineOf([int] $position) {
        [int] $offset = 0
        [int] $line = 0
        for ([int] $index = 0; $index -lt $this.Pieces.Count; $index++) {
            [NotepadPiece] $piece = $this.Pieces[$index]
            if ($position -lt $offset + $piece.Length) {
                [int] $end = $piece.Start + ($position - $offset)
                for ([int] $i = $piece.Start; $i -lt $end; $i++) {
                    if ($this.CharAt($piece.Buffer, $i) -eq [char]10) { $line = $line + 1 }
                }
                return $line
            }
            $line = $line + $piece.LineBreaks
            $offset = $offset + $piece.Length
        }
        return $line
    }

    [string] GetText([int] $position, [int] $length) {
        if ($position -lt 0 -or $length -lt 0 -or $position + $length -gt $this.Length) { throw [System.ArgumentOutOfRangeException]::new('position') }
        [char[]] $result = [char[]]::new($length)
        [int] $written = 0
        [int] $offset = 0
        for ([int] $index = 0; $index -lt $this.Pieces.Count; $index++) {
            if ($written -eq $length) { break }
            [NotepadPiece] $piece = $this.Pieces[$index]
            [int] $pieceEnd = $offset + $piece.Length
            if ($pieceEnd -gt $position) {
                [int] $from = [Math]::Max($position, $offset)
                [int] $count = [Math]::Min($pieceEnd, $position + $length) - $from
                [int] $source = $piece.Start + ($from - $offset)
                if ($piece.Buffer -eq 0) { [Array]::Copy($this.Original, $source, $result, $written, $count) }
                else { [Array]::Copy($this.Added, $source, $result, $written, $count) }
                $written = $written + $count
            }
            $offset = $pieceEnd
        }
        return [string]::new($result)
    }

    # Streams the pieces to a temporary file beside the target, then moves it over the target.
    [void] Save([string] $path) {
        [string] $temporary = $path + '.saving'
        [System.IO.StreamWriter] $writer = [System.IO.StreamWriter]::new($temporary, $false, [System.Text.UTF8Encoding]::new($false))
        try {
            for ([int] $index = 0; $index -lt $this.Pieces.Count; $index++) {
                [NotepadPiece] $piece = $this.Pieces[$index]
                if ($piece.Buffer -eq 0) { $writer.Write($this.Original, $piece.Start, $piece.Length) }
                else { $writer.Write($this.Added, $piece.Start, $piece.Length) }
            }
        }
        finally { $writer.Dispose() }
        [System.IO.File]::Move($temporary, $path, $true)
        $this.SavedJournalPosition = $this.JournalPosition
    }
}

function Invoke-NotepadComparison {
param(
    [string] $EvidenceDirectory = (Join-Path $PSScriptRoot 'evidence'),
    [switch] $KeepProbeOpen,
    [switch] $SkipBrowser,
    [switch] $ExtractTypeScript,
    [switch] $BuildTypeScript,
    [switch] $BuildDesign,
    [switch] $RefreshReal, # bypass the validated native UIA/PrintWindow cache
    [switch] $VerifyNativeFeatures,
    [switch] $CatalogIcons
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:NativeModule = $null
$predictions = [ordered]@{
    EditorBackground = 'AllAgree'
    TitlebarBackground = 'AllAgree'
    MenubarBackground = 'AllAgree'
    StatusBackground = 'AllAgree'
    EditorTop = 'AllAgree'
    StatusTop = 'AllAgree'
}
New-Item -ItemType Directory -Path $EvidenceDirectory -Force | Out-Null
[pscustomobject]@{ TimeUtc = [datetime]::UtcNow; Predictions = [pscustomobject]$predictions } |
    Export-Clixml (Join-Path $EvidenceDirectory 'predictions.clixml')

# All native calls use delegates built with Reflection.Emit. This stays in PowerShell:
# no C#, Add-Type, external automation package, or process-wide settings.
function New-NativeDelegateType {
    param([string] $Name, [type] $ReturnType, [type[]] $ParameterTypes)
    if (-not $script:NativeModule) {
        $assemblyName = [Reflection.AssemblyName]::new('NotepadComparisonNative')
        $assembly = [Reflection.Emit.AssemblyBuilder]::DefineDynamicAssembly(
            $assemblyName, [Reflection.Emit.AssemblyBuilderAccess]::Run)
        $script:NativeModule = $assembly.DefineDynamicModule('Interop')
    }
    $builder = $script:NativeModule.DefineType(
        $Name, [Reflection.TypeAttributes]'Public,Sealed,Class', [MulticastDelegate])
    $constructor = $builder.DefineConstructor(
        [Reflection.MethodAttributes]'Public,HideBySig,RTSpecialName',
        [Reflection.CallingConventions]::Standard, [type[]]@([object], [IntPtr]))
    $constructor.SetImplementationFlags([Reflection.MethodImplAttributes]'Runtime,Managed')
    $invoke = $builder.DefineMethod('Invoke',
        [Reflection.MethodAttributes]'Public,HideBySig,NewSlot,Virtual',
        $ReturnType, $ParameterTypes)
    $invoke.SetImplementationFlags([Reflection.MethodImplAttributes]'Runtime,Managed')
    return $builder.CreateType()
}

function Connect-EdgePage {
    param([string] $HtmlPath)
    $edgePath = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
    if (-not (Test-Path $edgePath)) { throw 'Microsoft Edge is unavailable.' }
    $profileDirectory = Join-Path $env:TEMP ('notepad-ps1-edge-' + [guid]::NewGuid().ToString('N'))
    $url = [uri]$HtmlPath
    $edge = Start-Process -FilePath $edgePath -ArgumentList @(
        '--headless=new', '--no-first-run', '--no-default-browser-check',
        '--remote-debugging-port=0', '--window-size=768,478',
        ('--user-data-dir="' + $profileDirectory + '"'), $url.AbsoluteUri
    ) -PassThru
    $portFile = Join-Path $profileDirectory 'DevToolsActivePort'
    for ($attempt = 0; $attempt -lt 100 -and -not (Test-Path $portFile); $attempt++) {
        Start-Sleep -Milliseconds 100
    }
    if (-not (Test-Path $portFile)) { throw 'Edge did not expose its local DevTools port.' }
    $port = [int](Get-Content $portFile -TotalCount 1)
    $target = $null
    for ($attempt = 0; $attempt -lt 50; $attempt++) {
        $targets = Invoke-RestMethod "http://127.0.0.1:$port/json/list"
        $target = $targets | Where-Object { $_.type -eq 'page' -and $_.url -eq $url.AbsoluteUri } | Select-Object -First 1
        if ($target) { break }
        Start-Sleep -Milliseconds 100
    }
    if (-not $target) { throw "Edge did not open $($url.AbsoluteUri)." }
    $socket = [Net.WebSockets.ClientWebSocket]::new()
    [void]$socket.ConnectAsync([uri]$target.webSocketDebuggerUrl, [threading.CancellationToken]::None).GetAwaiter().GetResult()
    return [pscustomobject]@{ Process = $edge; Profile = $profileDirectory; Socket = $socket; Url = $url.AbsoluteUri; NextId = 1 }
}

function Close-EdgePage {
    param($Connection)
    if (-not $Connection) { return }
    if ($Connection.PSObject.Properties['Socket']) { $Connection.Socket.Dispose() }
    if ($Connection.PSObject.Properties['Profile']) {
        $profile = [string]$Connection.Profile
        if ($profile.StartsWith((Join-Path $env:TEMP 'notepad-ps1-edge-'), [StringComparison]::OrdinalIgnoreCase)) {
            $children = @(Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" |
                Where-Object { $_.CommandLine -and $_.CommandLine.Contains($profile, [StringComparison]::OrdinalIgnoreCase) })
            foreach ($child in $children) { Stop-Process -Id $child.ProcessId -Force -ErrorAction SilentlyContinue }
        }
    }
}

function Invoke-Cdp {
    param($Connection, [string] $Method, [hashtable] $Parameters = @{})
    $id = $Connection.NextId++
    $payload = @{ id = $id; method = $Method; params = $Parameters } | ConvertTo-Json -Depth 40 -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
    $segment = [ArraySegment[byte]]::new($bytes)
    [void]$Connection.Socket.SendAsync($segment, [Net.WebSockets.WebSocketMessageType]::Text,
        $true, [threading.CancellationToken]::None).GetAwaiter().GetResult()
    while ($true) {
        $stream = [IO.MemoryStream]::new()
        do {
            $buffer = [byte[]]::new(65536)
            $chunk = [ArraySegment[byte]]::new($buffer)
            $received = $Connection.Socket.ReceiveAsync($chunk, [threading.CancellationToken]::None).GetAwaiter().GetResult()
            if ($received.MessageType -eq [Net.WebSockets.WebSocketMessageType]::Close) { throw 'Edge closed the CDP socket.' }
            $stream.Write($buffer, 0, $received.Count)
        } until ($received.EndOfMessage)
        $message = [Text.Encoding]::UTF8.GetString($stream.ToArray()) | ConvertFrom-Json -Depth 100
        if ($message.PSObject.Properties['id'] -and $message.id -eq $id) {
            if ($message.PSObject.Properties['error']) { throw "CDP $Method failed: $($message.error.message)" }
            return $message.result
        }
    }
}

function Get-CdpValue {
    param($Connection, [string] $Expression)
    $result = Invoke-Cdp $Connection 'Runtime.evaluate' @{
        expression = $Expression; returnByValue = $true; awaitPromise = $true
    }
    if ($result.PSObject.Properties['exceptionDetails']) { throw "Browser evaluation failed: $($result.exceptionDetails | ConvertTo-Json -Depth 10 -Compress)" }
    if ($result.result.PSObject.Properties['value']) { return $result.result.value }
    return $null
}

function Get-BrowserAppState {
    param($Connection)
    $prototype = Invoke-Cdp $Connection 'Runtime.evaluate' @{ expression = 'window.NotepadApp.prototype' }
    if (-not $prototype.result.objectId) { throw 'NotepadApp prototype is unavailable.' }
    $instances = Invoke-Cdp $Connection 'Runtime.queryObjects' @{ prototypeObjectId = $prototype.result.objectId }
    $state = Invoke-Cdp $Connection 'Runtime.callFunctionOn' @{
        objectId = $instances.objects.objectId
        functionDeclaration = @'
function() {
  const app = this[0];
  if (!app) return null;
  const editor = app.dom.editor;
  return JSON.parse(JSON.stringify({
    documents: app.tabs,
    activeTabId: app.activeTabId,
    nextTabId: app.nextTabId,
    editorSnapshot: {
      content: editor.value,
      selectionStart: editor.selectionStart,
      selectionEnd: editor.selectionEnd,
      cursorLine: app.getActiveTab()?.cursorLine ?? null,
      cursorCol: app.getActiveTab()?.cursorCol ?? null
    },
    selection: { anchor: editor.selectionStart, focus: editor.selectionEnd },
    settings: app.settings,
    activeMenu: app.activeMenu,
    findReplace: app.findReplaceState,
    dialogOpen: app.dom.modalOverlay.classList.contains('open'),
    saveRequested: null,
    saveCompleted: null
  }));
}
'@
        returnByValue = $true
    }
    return $state.result.value
}

function Save-BrowserState {
    param($Connection, [string] $Name, [string] $Directory)
    $snapshot = Get-CdpValue $Connection @'
(() => ({
  markup: document.querySelector('#notepad-root')?.outerHTML ?? '',
  stylesheet: document.getElementById('notepad-fluent-styles')?.textContent ?? '',
  theme: document.documentElement.dataset.theme,
  editorValue: document.querySelector('textarea')?.value ?? '',
  selectionStart: document.querySelector('textarea')?.selectionStart ?? null,
  selectionEnd: document.querySelector('textarea')?.selectionEnd ?? null,
  storage: Object.fromEntries(Object.entries(localStorage).sort(([a],[b]) => a.localeCompare(b))),
  devicePixelRatio: devicePixelRatio,
  viewport: [innerWidth, innerHeight]
}))()
'@
    $appState = Get-BrowserAppState $Connection
    $capture = Invoke-Cdp $Connection 'Page.captureScreenshot' @{ format = 'png'; captureBeyondViewport = $false }
    $coverageResult = Invoke-Cdp $Connection 'Profiler.takePreciseCoverage'
    $coverage = @($coverageResult.result | Where-Object { $_.url -like '*notepad*' } |
        ForEach-Object {
            [pscustomobject]@{
                Url = $_.url
                Functions = @($_.functions | ForEach-Object {
                    [pscustomobject]@{ Name=$_.functionName; Ranges=@($_.ranges) }
                })
            }
        })
    $nodeRuntime = $null
    if ($Connection.PSObject.Properties['Trace'] -and $Connection.Trace) {
        $nodeRuntime = Get-CdpValue $Connection @'
(() => { const result = Object.fromEntries(window.__npTraceRecords); window.__npTraceRecords.clear(); return result; })()
'@
    }
    $imagePath = Join-Path $Directory ($Name + '.png')
    [IO.File]::WriteAllBytes($imagePath, [Convert]::FromBase64String($capture.data))
    return [pscustomobject]@{ Name = $Name; DomState = $snapshot; AppState = $appState; Coverage = $coverage; NodeRuntime = $nodeRuntime; Image = $imagePath; ImageSHA256 = (Get-FileHash $imagePath -Algorithm SHA256).Hash }
}

function Start-BrowserCoverage {
    param($Connection)
    $null = Invoke-Cdp $Connection 'Profiler.enable'
    $null = Invoke-Cdp $Connection 'Profiler.startPreciseCoverage' @{
        callCount = $true; detailed = $true; allowTriggeredUpdates = $false
    }
    $null = Invoke-Cdp $Connection 'Page.reload' @{ ignoreCache = $true }
    Start-Sleep -Milliseconds 300
}

function Send-CdpKey {
    param($Connection, [string] $Key, [string] $Code, [int] $VirtualKey, [int] $Modifiers = 0)
    foreach ($kind in @('rawKeyDown', 'keyUp')) {
        $null = Invoke-Cdp $Connection 'Input.dispatchKeyEvent' @{
            type = $kind; key = $Key; code = $Code
            windowsVirtualKeyCode = $VirtualKey; nativeVirtualKeyCode = $VirtualKey
            modifiers = $Modifiers
        }
    }
}

function Click-CdpSelector {
    param($Connection, [string] $Selector)
    $literal = ConvertTo-Json -InputObject $Selector -Compress
    $point = Get-CdpValue $Connection "(() => { const r = document.querySelector($literal).getBoundingClientRect(); return { x: r.x + r.width / 2, y: r.y + r.height / 2 }; })()"
    foreach ($kind in @('mousePressed', 'mouseReleased')) {
        $null = Invoke-Cdp $Connection 'Input.dispatchMouseEvent' @{
            type = $kind; x = $point.x; y = $point.y
            button = 'left'; clickCount = 1
        }
    }
}

function Add-BrowserReplayStates {
    param($Connection, [string] $Prefix, [string] $Directory, $States)
    $commands = @(
        [pscustomobject]@{ Name='selected'; Run={ param($c) Send-CdpKey $c 'a' 'KeyA' 65 2 } },
        [pscustomobject]@{ Name='undo'; Run={ param($c) Send-CdpKey $c 'z' 'KeyZ' 90 2 } },
        [pscustomobject]@{ Name='redo'; Run={ param($c) Send-CdpKey $c 'y' 'KeyY' 89 2 } },
        [pscustomobject]@{ Name='find-open'; Run={ param($c) Send-CdpKey $c 'f' 'KeyF' 70 2 } },
        [pscustomobject]@{ Name='find-query'; Run={ param($c) $null=Invoke-Cdp $c 'Input.insertText' @{ text='sample' } } },
        [pscustomobject]@{ Name='replace-open'; Run={ param($c) Send-CdpKey $c 'h' 'KeyH' 72 2 } },
        [pscustomobject]@{ Name='find-close'; Run={ param($c) Click-CdpSelector $c '#find-btn-close' } },
        [pscustomobject]@{ Name='new-tab'; Run={ param($c) Click-CdpSelector $c '#btn-add-tab' } },
        [pscustomobject]@{ Name='file-menu'; Run={ param($c) Click-CdpSelector $c '#menu-btn-file' } },
        [pscustomobject]@{ Name='settings'; Run={ param($c) Click-CdpSelector $c '#btn-settings-toggle' } },
        [pscustomobject]@{ Name='theme-light'; Run={ param($c)
            Click-CdpSelector $c '#setting-theme-select'
            Send-CdpKey $c 'Home' 'Home' 36
            Send-CdpKey $c 'ArrowDown' 'ArrowDown' 40
            Send-CdpKey $c 'Enter' 'Enter' 13
        } },
        [pscustomobject]@{ Name='settings-close'; Run={ param($c) Click-CdpSelector $c '#settings-btn-back' } },
        [pscustomobject]@{ Name='zoom-in'; Run={ param($c) Send-CdpKey $c '=' 'Equal' 187 2 } }
    )
    foreach ($command in $commands) {
        & $command.Run $Connection
        $null = Get-CdpValue $Connection 'new Promise(resolve => setTimeout(resolve, 200))'
        $States.Add((Save-BrowserState $Connection "$Prefix-$($command.Name)" $Directory))
    }
}

$outPointer = [IntPtr].MakeByRefType()
$script:ComOutType = New-NativeDelegateType 'ComOut' ([int]) ([type[]]@([IntPtr], $outPointer))
$script:ComHandleOutType = New-NativeDelegateType 'ComHandleOut' ([int]) ([type[]]@([IntPtr], [IntPtr], $outPointer))
$script:ComElementOutType = New-NativeDelegateType 'ComElementOut' ([int]) ([type[]]@([IntPtr], [IntPtr], $outPointer))
$script:ComPropertyType = New-NativeDelegateType 'ComProperty' ([int]) ([type[]]@([IntPtr], [int], [IntPtr]))
$script:PrintWindowType = New-NativeDelegateType 'PrintWindowCall' ([bool]) ([type[]]@([IntPtr], [IntPtr], [uint32]))
$script:GetDpiType = New-NativeDelegateType 'GetDpiCall' ([uint32]) ([type[]]@([IntPtr]))
$script:GetDpiSystemType = New-NativeDelegateType 'GetDpiSystemCall' ([uint32]) ([type[]]@())
$script:ComNoArgType = New-NativeDelegateType 'ComNoArg' ([int]) ([type[]]@([IntPtr]))
$script:ComIntOutType = New-NativeDelegateType 'ComIntOut' ([int]) ([type[]]@([IntPtr], [int], $outPointer))
$script:SetForegroundType = New-NativeDelegateType 'SetForegroundCall' ([bool]) ([type[]]@([IntPtr]))
$script:SetCursorType = New-NativeDelegateType 'SetCursorCall' ([bool]) ([type[]]@([int], [int]))
$script:MouseEventType = New-NativeDelegateType 'MouseEventCall' ([void]) ([type[]]@([uint32], [uint32], [uint32], [uint32], [UIntPtr]))
$script:GetCursorType = New-NativeDelegateType 'GetCursorCall' ([bool]) ([type[]]@([IntPtr]))
$script:SystemMetricsType = New-NativeDelegateType 'SystemMetricsCall' ([int]) ([type[]]@([int]))
$script:SendInputType = New-NativeDelegateType 'SendInputCall' ([uint32]) ([type[]]@([uint32], [IntPtr], [int]))
# Virtual-key codes used to drive Windows Notepad during comparison (winuser.h).
$script:VirtualKey = @{ Back = 0x08; Control = 0x11; Escape = 0x1B; D0 = 0x30; A = 0x41; F = 0x46; N = 0x4E; S = 0x53; Y = 0x59; Z = 0x5A; OemPlus = 0xBB }

function Invoke-ComSlot {
    param([IntPtr] $Interface, [int] $Slot, [type] $DelegateType, [object[]] $Arguments)
    $vtable = [Runtime.InteropServices.Marshal]::ReadIntPtr($Interface)
    $address = [Runtime.InteropServices.Marshal]::ReadIntPtr($vtable, $Slot * [IntPtr]::Size)
    $delegate = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($address, $DelegateType)
    $callArguments = [object[]]@($Interface) + $Arguments
    $hresult = $delegate.DynamicInvoke($callArguments)
    if ($hresult -is [int] -and $hresult -lt 0) {
        [Runtime.InteropServices.Marshal]::ThrowExceptionForHR($hresult)
    }
    return $callArguments
}

function Get-ComOut {
    param([IntPtr] $Interface, [int] $Slot)
    $result = Invoke-ComSlot $Interface $Slot $script:ComOutType @([IntPtr]::Zero)
    return [IntPtr]$result[1]
}

function Get-ComElementOut {
    param([IntPtr] $Interface, [int] $Slot, [IntPtr] $Element)
    $result = Invoke-ComSlot $Interface $Slot $script:ComElementOutType @($Element, [IntPtr]::Zero)
    return [IntPtr]$result[2]
}

function Get-UiaProperty {
    param([IntPtr] $Element, [int] $PropertyId)
    $variant = [Runtime.InteropServices.Marshal]::AllocCoTaskMem(24)
    try {
        for ($i = 0; $i -lt 24; $i++) { [Runtime.InteropServices.Marshal]::WriteByte($variant, $i, 0) }
        $null = Invoke-ComSlot $Element 10 $script:ComPropertyType @($PropertyId, $variant)
        return [Runtime.InteropServices.Marshal]::GetObjectForNativeVariant($variant)
    } finally {
        [Runtime.InteropServices.Marshal]::FreeCoTaskMem($variant)
    }
}

function Get-UiaNode {
    param([IntPtr] $Element, [IntPtr] $Walker, [int] $Depth = 0)
    $ids = [ordered]@{
        ControlType = 30003; Name = 30005; AutomationId = 30011
        BoundingRectangle = 30001; IsEnabled = 30010
        IsSelected = 30079; ExpandCollapseState = 30070
        NativeWindowHandle = 30020
    }
    $properties = [ordered]@{}
    foreach ($entry in $ids.GetEnumerator()) {
        try { $properties[$entry.Key] = Get-UiaProperty $Element $entry.Value }
        catch { $properties[$entry.Key] = $null }
    }
    $children = [Collections.Generic.List[object]]::new()
    if ($Depth -lt 40) {
        $child = Get-ComElementOut $Walker 4 $Element
        while ($child -ne [IntPtr]::Zero) {
            try {
                $children.Add((Get-UiaNode $child $Walker ($Depth + 1)))
                $next = Get-ComElementOut $Walker 6 $child
            } finally {
                [void][Runtime.InteropServices.Marshal]::Release($child)
            }
            $child = $next
        }
    }
    return [pscustomobject]@{ Depth = $Depth; Properties = [pscustomobject]$properties; Children = $children.ToArray() }
}

function Find-UiaElement {
    param([IntPtr] $Element, [IntPtr] $Walker, [string] $Name, [int] $ControlType = 0, [int] $Depth = 0)
    if ((Get-UiaProperty $Element 30005) -eq $Name -and
        ($ControlType -eq 0 -or (Get-UiaProperty $Element 30003) -eq $ControlType)) {
        [void][Runtime.InteropServices.Marshal]::AddRef($Element)
        return $Element
    }
    if ($Depth -ge 40) { return [IntPtr]::Zero }
    $child = Get-ComElementOut $Walker 4 $Element
    while ($child -ne [IntPtr]::Zero) {
        try {
            $found = Find-UiaElement $child $Walker $Name $ControlType ($Depth + 1)
            $next = if ($found -eq [IntPtr]::Zero) { Get-ComElementOut $Walker 6 $child } else { [IntPtr]::Zero }
        } finally {
            [void][Runtime.InteropServices.Marshal]::Release($child)
        }
        if ($found -ne [IntPtr]::Zero) { return $found }
        $child = $next
    }
    return [IntPtr]::Zero
}

function Invoke-UiaElementByName {
    param([IntPtr] $Root, [IntPtr] $Walker, [string] $Name, [int] $ControlType = 0)
    $element = Find-UiaElement $Root $Walker $Name $ControlType
    if ($element -eq [IntPtr]::Zero) { throw "UIA element '$Name' was not found." }
    try {
        $result = Invoke-ComSlot $element 16 $script:ComIntOutType @([int]10000, [IntPtr]::Zero)
        $pattern = [IntPtr]$result[2]
        if ($pattern -eq [IntPtr]::Zero) { throw "UIA element '$Name' has no InvokePattern." }
        try { $null = Invoke-ComSlot $pattern 3 $script:ComNoArgType @() }
        finally { [void][Runtime.InteropServices.Marshal]::Release($pattern) }
    } finally {
        [void][Runtime.InteropServices.Marshal]::Release($element)
    }
}

function Expand-UiaElementByName {
    param([IntPtr] $Root, [IntPtr] $Walker, [string] $Name, [int] $ControlType = 0)
    $element = Find-UiaElement $Root $Walker $Name $ControlType
    if ($element -eq [IntPtr]::Zero) { throw "UIA element '$Name' was not found." }
    try {
        $result = Invoke-ComSlot $element 16 $script:ComIntOutType @([int]10005, [IntPtr]::Zero)
        $pattern = [IntPtr]$result[2]
        if ($pattern -eq [IntPtr]::Zero) { throw "UIA element '$Name' has no ExpandCollapsePattern." }
        try { $null = Invoke-ComSlot $pattern 3 $script:ComNoArgType @() }
        finally { [void][Runtime.InteropServices.Marshal]::Release($pattern) }
    } finally {
        [void][Runtime.InteropServices.Marshal]::Release($element)
    }
}

function Click-UiaElementByName {
    param([IntPtr] $Root, [IntPtr] $Walker, [string] $Name, [int] $ControlType = 0)
    $element = Find-UiaElement $Root $Walker $Name $ControlType
    if ($element -eq [IntPtr]::Zero) { throw "UIA element '$Name' was not found." }
    try {
        $rect = Get-UiaProperty $element 30001
        $x = [int]($rect[0] + $rect[2] / 2)
        $y = [int]($rect[1] + $rect[3] / 2)
        $previous = Get-CursorPosition
        $setCursor = Get-NativeFunction 'user32.dll' 'SetCursorPos' $script:SetCursorType
        $mouse = Get-NativeFunction 'user32.dll' 'mouse_event' $script:MouseEventType
        try {
            [void]$setCursor.DynamicInvoke([object[]]@($x, $y))
            [void]$mouse.DynamicInvoke([object[]]@([uint32]2, [uint32]0, [uint32]0, [uint32]0, [UIntPtr]::Zero))
            [void]$mouse.DynamicInvoke([object[]]@([uint32]4, [uint32]0, [uint32]0, [uint32]0, [UIntPtr]::Zero))
        } finally {
            [void]$setCursor.DynamicInvoke([object[]]@($previous.X, $previous.Y))
        }
    } finally {
        [void][Runtime.InteropServices.Marshal]::Release($element)
    }
}

function Capture-RealState {
    param([IntPtr] $Root, [IntPtr] $Walker, [IntPtr] $Window, [string] $Name, [string] $Directory)
    $tree = Get-UiaNode $Root $Walker
    $rect = $tree.Properties.BoundingRectangle
    $width = [int][math]::Ceiling($rect[2])
    $height = [int][math]::Ceiling($rect[3])
    $imagePath = Join-Path $Directory ("real-$Name.png")
    Save-WindowImage $Window $imagePath $width $height
    return [pscustomobject]@{
        Name = $Name; Tree = $tree; Image = $imagePath
        ImageSHA256 = (Get-FileHash $imagePath -Algorithm SHA256).Hash
        Width = $width; Height = $height
    }
}

function Get-NativeAppWindowHandle {
    param([int] $ProcessId)
    $uiaClass = [type]::GetTypeFromCLSID([guid]'ff48dba4-60ef-4201-aa87-54103eef594e')
    $uiaObject = [Activator]::CreateInstance($uiaClass)
    $unknown = [Runtime.InteropServices.Marshal]::GetIUnknownForObject($uiaObject)
    $uia = [IntPtr]::Zero
    $iid = [guid]'30cbe57d-d9d0-452a-ab13-7ac5ac4825ee'
    $hr = [Runtime.InteropServices.Marshal]::QueryInterface($unknown, [ref]$iid, [ref]$uia)
    if ($hr -ne 0) { [Runtime.InteropServices.Marshal]::ThrowExceptionForHR($hr) }
    try {
        $desktop = Get-ComOut $uia 5
        $walker = Get-ComOut $uia 16
        try {
            $child = Get-ComElementOut $walker 4 $desktop
            while ($child -ne [IntPtr]::Zero) {
                try {
                    $pidValue = Get-UiaProperty $child 30002
                    $nameValue = Get-UiaProperty $child 30005
                    if ($pidValue -eq $ProcessId -and $nameValue -eq 'Notepad — PowerShell') {
                        return [IntPtr](Get-UiaProperty $child 30020)
                    }
                    $next = Get-ComElementOut $walker 6 $child
                } finally {
                    [void][Runtime.InteropServices.Marshal]::Release($child)
                }
                $child = $next
            }
        } finally {
            [void][Runtime.InteropServices.Marshal]::Release($walker)
            [void][Runtime.InteropServices.Marshal]::Release($desktop)
        }
    } finally {
        [void][Runtime.InteropServices.Marshal]::Release($uia)
        [void][Runtime.InteropServices.Marshal]::Release($unknown)
    }
    return [IntPtr]::Zero
}

function Get-NativeFunction {
    param([string] $Library, [string] $Name, [type] $DelegateType)
    $module = [Runtime.InteropServices.NativeLibrary]::Load($Library)
    $address = [Runtime.InteropServices.NativeLibrary]::GetExport($module, $Name)
    return [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($address, $DelegateType)
}

function Get-CursorPosition {
    $point = [Runtime.InteropServices.Marshal]::AllocHGlobal(8)
    try {
        $getCursor = Get-NativeFunction 'user32.dll' 'GetCursorPos' $script:GetCursorType
        if (-not $getCursor.DynamicInvoke([object[]]@($point))) { throw 'GetCursorPos failed.' }
        [pscustomobject]@{ X = [Runtime.InteropServices.Marshal]::ReadInt32($point, 0); Y = [Runtime.InteropServices.Marshal]::ReadInt32($point, 4) }
    } finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($point) }
}

function Get-MonitorCount {
    # SM_CMONITORS
    $metrics = Get-NativeFunction 'user32.dll' 'GetSystemMetrics' $script:SystemMetricsType
    [int]$metrics.DynamicInvoke([object[]]@(80))
}

function Send-KeyboardInput {
    # Text is typed as Unicode characters. Chord presses its virtual keys in order and releases them in reverse.
    param([string] $Text, [uint16[]] $Chord)
    $events = [Collections.Generic.List[object]]::new()
    if ($Text) { foreach ($character in $Text.ToCharArray()) { $events.Add(@(0, [int]$character, 0x4)); $events.Add(@(0, [int]$character, 0x6)) } }
    if ($Chord) {
        foreach ($key in $Chord) { $events.Add(@([int]$key, 0, 0x0)) }
        for ($index = $Chord.Length - 1; $index -ge 0; $index--) { $events.Add(@([int]$Chord[$index], 0, 0x2)) }
    }
    if (-not $events.Count) { return }
    # INPUT: a 32-bit type, then the KEYBDINPUT union member at pointer alignment.
    $unionOffset = [IntPtr]::Size
    $recordSize = if ([IntPtr]::Size -eq 8) { 40 } else { 28 }
    $buffer = [Runtime.InteropServices.Marshal]::AllocHGlobal($recordSize * $events.Count)
    try {
        for ($index = 0; $index -lt $events.Count; $index++) {
            $at = $index * $recordSize
            for ($byte = 0; $byte -lt $recordSize; $byte += 4) { [Runtime.InteropServices.Marshal]::WriteInt32($buffer, $at + $byte, 0) }
            [Runtime.InteropServices.Marshal]::WriteInt32($buffer, $at, 1)
            [Runtime.InteropServices.Marshal]::WriteInt16($buffer, $at + $unionOffset, [char]$events[$index][0])
            [Runtime.InteropServices.Marshal]::WriteInt16($buffer, $at + $unionOffset + 2, [char]$events[$index][1])
            [Runtime.InteropServices.Marshal]::WriteInt32($buffer, $at + $unionOffset + 4, [int]$events[$index][2])
        }
        $sendInput = Get-NativeFunction 'user32.dll' 'SendInput' $script:SendInputType
        $sent = [uint32]$sendInput.DynamicInvoke([object[]]@([uint32]$events.Count, $buffer, $recordSize))
        if ($sent -ne $events.Count) { throw "SendInput delivered $sent of $($events.Count) key events." }
    } finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($buffer) }
}

function Save-WindowImage {
    param([IntPtr] $Handle, [string] $Path, [int] $Width, [int] $Height)
    [void][Reflection.Assembly]::Load('System.Drawing.Common')
    $bitmap = [Drawing.Bitmap]::new($Width, $Height)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $dc = $graphics.GetHdc()
    try {
        $printWindow = Get-NativeFunction 'user32.dll' 'PrintWindow' $script:PrintWindowType
        $ok = $printWindow.DynamicInvoke([object[]]@($Handle, $dc, [uint32]2))
        if (-not $ok) { throw 'PrintWindow returned FALSE.' }
    } finally {
        $graphics.ReleaseHdc($dc)
        $graphics.Dispose()
    }
    try { $bitmap.Save($Path, [Drawing.Imaging.ImageFormat]::Png) }
    finally { $bitmap.Dispose() }
}

function Get-ImageMeasurements {
    param([string] $Path)
    [void][Reflection.Assembly]::Load('System.Drawing.Common')
    $bitmap = [Drawing.Bitmap]::new($Path)
    try {
        function HexAt([Drawing.Bitmap] $Bitmap, [int] $X, [int] $Y) {
            $color = $Bitmap.GetPixel($X, $Y)
            return ('#{0:X2}{1:X2}{2:X2}' -f $color.R, $color.G, $color.B)
        }
        $editorColor = HexAt $bitmap 400 120
        $editorTop = 120
        while ($editorTop -gt 30 -and (HexAt $bitmap 400 ($editorTop - 1)) -eq $editorColor) { $editorTop-- }
        $statusColor = HexAt $bitmap 350 460
        $statusTop = 460
        while ($statusTop -gt 350 -and (HexAt $bitmap 350 ($statusTop - 1)) -eq $statusColor) { $statusTop-- }
        return [pscustomobject]@{
            EditorBackground = $editorColor
            TitlebarBackground = (HexAt $bitmap 600 10)
            MenubarBackground = (HexAt $bitmap 200 61)
            StatusBackground = $statusColor
            EditorTop = $editorTop
            StatusTop = $statusTop
        }
    } finally { $bitmap.Dispose() }
}

function Get-CubicGlyphEvidence {
    param($RealEvidence)
    [void][Reflection.Assembly]::Load('PresentationCore')
    $systemFontPath = 'C:\Windows\Fonts\SegoeIcons.ttf'
    $appFontPath = Join-Path (Split-Path $RealEvidence.Metadata.NotepadPath -Parent) 'Assets\NotepadIcons.ttf'
    $systemFont = [Windows.Media.GlyphTypeface]::new([uri]$systemFontPath)
    $appFont = [Windows.Media.GlyphTypeface]::new([uri]$appFontPath)
    $observed = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
    function Visit-GlyphNode($Node, [string] $Parent, [string] $StateName, [string] $Image) {
        $name = [string]$Node.Properties.Name
        if ($name.Length -eq 1 -and [int][char]$name -ge 0xE000) {
            $codePoint = [int][char]$name
            $key = "$Parent|$codePoint"
            if (-not $observed.ContainsKey($key)) {
                $observed[$key] = [pscustomobject]@{
                    Parent = $Parent; Glyph = $name; CodePoint = $codePoint
                    State = $StateName; Image = $Image
                }
            }
        }
        foreach ($child in $Node.Children) {
            Visit-GlyphNode $child $(if ($name) { $name } else { $Parent }) $StateName $Image
        }
    }
    foreach ($state in $RealEvidence.States) { Visit-GlyphNode $state.Tree '' $state.Name $state.Image }
    $icons = [Collections.Generic.List[object]]::new()
    foreach ($observation in $observed.Values) {
        $fontPath = if ($appFont.CharacterToGlyphMap.ContainsKey($observation.CodePoint)) { $appFontPath } else { $systemFontPath }
        $font = if ($fontPath -eq $appFontPath) { $appFont } else { $systemFont }
        $fontHash = (Get-FileHash $fontPath -Algorithm SHA256).Hash
        $glyphIndex = $font.CharacterToGlyphMap[$observation.CodePoint]
        if (-not $glyphIndex) { continue }
        $geometry = $font.GetGlyphOutline($glyphIndex, 16, [Windows.Media.StyleSimulations]::None)
        $curves = [Collections.Generic.List[object]]::new()
        $unknownSegments = [Collections.Generic.List[string]]::new()
        foreach ($figure in $geometry.Figures) {
            $start = $figure.StartPoint
            $current = $start
            foreach ($segment in $figure.Segments) {
                $segmentName = $segment.GetType().Name
                if ($segmentName -eq 'PolyBezierSegment') {
                    for ($i=0; $i -lt $segment.Points.Count; $i+=3) {
                        $p1=$segment.Points[$i]; $p2=$segment.Points[$i+1]; $p3=$segment.Points[$i+2]
                        $curves.Add([pscustomobject]@{ P0=@($current.X,$current.Y); P1=@($p1.X,$p1.Y); P2=@($p2.X,$p2.Y); P3=@($p3.X,$p3.Y) })
                        $current=$p3
                    }
                } elseif ($segmentName -eq 'BezierSegment') {
                    $p1=$segment.Point1; $p2=$segment.Point2; $p3=$segment.Point3
                    $curves.Add([pscustomobject]@{ P0=@($current.X,$current.Y); P1=@($p1.X,$p1.Y); P2=@($p2.X,$p2.Y); P3=@($p3.X,$p3.Y) })
                    $current=$p3
                } elseif ($segmentName -eq 'PolyLineSegment') {
                    foreach ($endpoint in $segment.Points) {
                        $p1=[Windows.Point]::new($current.X+($endpoint.X-$current.X)/3,$current.Y+($endpoint.Y-$current.Y)/3)
                        $p2=[Windows.Point]::new($current.X+2*($endpoint.X-$current.X)/3,$current.Y+2*($endpoint.Y-$current.Y)/3)
                        $curves.Add([pscustomobject]@{ P0=@($current.X,$current.Y); P1=@($p1.X,$p1.Y); P2=@($p2.X,$p2.Y); P3=@($endpoint.X,$endpoint.Y) })
                        $current=$endpoint
                    }
                } elseif ($segmentName -eq 'LineSegment') {
                    $endpoint=$segment.Point
                    $p1=[Windows.Point]::new($current.X+($endpoint.X-$current.X)/3,$current.Y+($endpoint.Y-$current.Y)/3)
                    $p2=[Windows.Point]::new($current.X+2*($endpoint.X-$current.X)/3,$current.Y+2*($endpoint.Y-$current.Y)/3)
                    $curves.Add([pscustomobject]@{ P0=@($current.X,$current.Y); P1=@($p1.X,$p1.Y); P2=@($p2.X,$p2.Y); P3=@($endpoint.X,$endpoint.Y) })
                    $current=$endpoint
                } else {
                    $unknownSegments.Add($segmentName)
                }
            }
            if ($figure.IsClosed -and ($current.X -ne $start.X -or $current.Y -ne $start.Y)) {
                $p1=[Windows.Point]::new($current.X+($start.X-$current.X)/3,$current.Y+($start.Y-$current.Y)/3)
                $p2=[Windows.Point]::new($current.X+2*($start.X-$current.X)/3,$current.Y+2*($start.Y-$current.Y)/3)
                $curves.Add([pscustomobject]@{ P0=@($current.X,$current.Y); P1=@($p1.X,$p1.Y); P2=@($p2.X,$p2.Y); P3=@($start.X,$start.Y) })
            }
        }
        $icons.Add([pscustomobject]@{
            UIAParent = $observation.Parent
            Glyph = $observation.Glyph
            CodePoint = ('U+{0:X4}' -f $observation.CodePoint)
            GlyphIndex = $glyphIndex
            FontPath = $fontPath
            FontSHA256 = $fontHash
            NotepadSHA256 = $RealEvidence.Metadata.NotepadSHA256
            ObservedState = $observation.State
            ObservedImage = $observation.Image
            EmSize = 16
            Bounds = @($geometry.Bounds.X,$geometry.Bounds.Y,$geometry.Bounds.Width,$geometry.Bounds.Height)
            Cubics = $curves.ToArray()
            UnknownSegments = $unknownSegments.ToArray()
        })
    }
    return $icons.ToArray()
}

function Compare-PrimitiveType {
    param([string] $StaticType, $Sample)
    if (-not $StaticType -or -not $Sample -or -not $Sample.PSObject.Properties['type']) { return 'UNKNOWN' }
    $alternatives = $StaticType.Split([string[]]@(' | '), [StringSplitOptions]::None)
    $hasKnownAlternative = $false
    foreach ($alternative in $alternatives) {
        $candidate = $alternative.Trim()
        if ($candidate -in @('any','unknown')) { return 'UNKNOWN' }
        $matches = $false
        switch ($candidate) {
            'string' { $matches = $Sample.type -eq 'string'; $hasKnownAlternative = $true }
            'number' { $matches = $Sample.type -eq 'number'; $hasKnownAlternative = $true }
            'boolean' { $matches = $Sample.type -eq 'boolean'; $hasKnownAlternative = $true }
            'undefined' { $matches = $Sample.type -eq 'undefined'; $hasKnownAlternative = $true }
            'void' { $matches = $Sample.type -eq 'undefined'; $hasKnownAlternative = $true }
            'null' { $matches = $Sample.type -eq 'null'; $hasKnownAlternative = $true }
            'true' { $matches = $Sample.type -eq 'boolean' -and $Sample.value -eq $true; $hasKnownAlternative = $true }
            'false' { $matches = $Sample.type -eq 'boolean' -and $Sample.value -eq $false; $hasKnownAlternative = $true }
            default {
                if ($candidate.StartsWith('"') -and $candidate.EndsWith('"')) {
                    $hasKnownAlternative = $true
                    if ($Sample.type -eq 'string') {
                        try { $matches = ($candidate | ConvertFrom-Json) -ceq $Sample.value } catch {}
                    }
                } elseif ($candidate -match '^[0-9]+$') {
                    $hasKnownAlternative = $true
                    if ($Sample.type -eq 'number') {
                        $matches = [double]::Parse($candidate, [Globalization.CultureInfo]::InvariantCulture) -eq [double]$Sample.value
                    }
                }
            }
        }
        if ($matches) { return 'AGREE' }
    }
    if ($hasKnownAlternative) { return 'DISAGREE' }
    return 'UNKNOWN'
}

if($CatalogIcons){
    $stockType=New-NativeDelegateType 'CatalogStock' ([int]) ([type[]]@([int],[uint32],[IntPtr]))
    $destroyType=New-NativeDelegateType 'CatalogDestroyIcon' ([bool]) ([type[]]@([IntPtr]))
    $loadType=New-NativeDelegateType 'CatalogLoadIcon' ([IntPtr]) ([type[]]@([IntPtr],[IntPtr]))
    $stock=Get-NativeFunction 'shell32.dll' 'SHGetStockIconInfo' $stockType
    $destroy=Get-NativeFunction 'user32.dll' 'DestroyIcon' $destroyType
    $load=Get-NativeFunction 'user32.dll' 'LoadIconW' $loadType
    $icons=[Collections.Generic.List[object]]::new();$glyphs=[Collections.Generic.List[object]]::new()
    foreach($pair in @(@(32512,'Application'),@(32516,'Information'),@(32515,'Warning'),@(32513,'Error'),@(32514,'Question'),@(32517,'Windows'),@(32518,'Shield'))){
        $handle=$load.DynamicInvoke([object[]]@([IntPtr]::Zero,[IntPtr][int]$pair[0]))
        if($handle -ne [IntPtr]::Zero){$icons.Add([pscustomobject]@{Key=('standard:'+$pair[0]);Kind='standard';Id=[int]$pair[0];Name=$pair[1];Provenance='LoadIconW documented system resource'})}
    }
    $header='C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0\um\shellapi.h'
    $names=@{}
    if(Test-Path $header){$source=[IO.File]::ReadAllText($header);foreach($match in [regex]::Matches($source,'SIID_(\w+)\s*=\s*(\d+)')){if($match.Groups[1].Value -ne 'MAX_ICONS'){$names[[int]$match.Groups[2].Value]=$match.Groups[1].Value}}}
    $buffer=[Runtime.InteropServices.Marshal]::AllocHGlobal(544)
    try{
        foreach($id in 0..180){
            [Runtime.InteropServices.Marshal]::WriteInt32($buffer,544)
            $hr=$stock.DynamicInvoke([object[]]@([int]$id,[uint32]0x100,$buffer));if($hr -lt 0){continue}
            $handle=[Runtime.InteropServices.Marshal]::ReadIntPtr($buffer,8)
            try{$path=[Runtime.InteropServices.Marshal]::PtrToStringUni([IntPtr]::Add($buffer,24));$expanded=[Environment]::ExpandEnvironmentVariables($path)
                $icons.Add([pscustomobject]@{Key=('stock:'+$id);Kind='stock';Id=$id;Name=$(if($names.ContainsKey($id)){$names[$id]}else{'Stock '+$id});ResourcePath=$path;ResourceIndex=[Runtime.InteropServices.Marshal]::ReadInt32($buffer,20);SystemImageIndex=[Runtime.InteropServices.Marshal]::ReadInt32($buffer,16);ResourceSHA256=$(if(Test-Path $expanded){(Get-FileHash -LiteralPath $expanded -Algorithm SHA256).Hash}else{$null})})
            }finally{if($handle -ne [IntPtr]::Zero){$null=$destroy.DynamicInvoke([object[]]@($handle))}}
        }
    }finally{[Runtime.InteropServices.Marshal]::FreeHGlobal($buffer)}
    $font=Join-Path $env:WINDIR 'Fonts\SegoeIcons.ttf'
    if(Test-Path $font){[void][Reflection.Assembly]::Load('PresentationCore');$face=[Windows.Media.GlyphTypeface]::new([uri]$font);foreach($entry in $face.CharacterToGlyphMap.GetEnumerator()|Sort-Object Key){$glyphs.Add([pscustomobject]@{CodePoint=('U+{0:X4}' -f $entry.Key);Scalar=[int]$entry.Key;GlyphIndex=[int]$entry.Value;GeometryStatus='Outline available; not yet extracted for this catalog'})}}
    [pscustomobject]@{TimeUtc=[DateTime]::UtcNow;Machine=$env:COMPUTERNAME;WindowsBuild=[Environment]::OSVersion.Version.ToString();Scope='Available documented stock/system icons and installed Segoe Fluent glyphs';SdkHeader=$header;SdkSHA256=$(if(Test-Path $header){(Get-FileHash $header -Algorithm SHA256).Hash}else{$null});FontPath=$font;FontSHA256=$(if(Test-Path $font){(Get-FileHash $font -Algorithm SHA256).Hash}else{$null});CycleIcons=$icons.ToArray();Glyphs=$glyphs.ToArray()} | Export-Clixml (Join-Path $EvidenceDirectory 'windows-icon-catalog.clixml')
    [pscustomobject]@{CycleIcons=$icons.Count;SegoeGlyphs=$glyphs.Count;Evidence='windows-icon-catalog.clixml'}
    return
}
if ($VerifyNativeFeatures) {
    # Tests use a fresh clone and retained hit rectangles, without touching the user's running editor.
    $livePath=Join-Path $EvidenceDirectory 'native-feature-replay-live.json'
    if(Test-Path $livePath){Remove-Item -LiteralPath $livePath}
    $nativeReplay=Start-Process -FilePath (Join-Path $PSHOME 'pwsh.exe') -ArgumentList @('-NoProfile','-STA','-File',('"'+(Join-Path $PSScriptRoot 'Notepad.ps1')+'"'),'-NoSession','-Width','1000','-Height','720','-RunSeconds','120','-DiagnosticPath',('"'+$livePath+'"')) -WindowStyle Hidden -PassThru
    $replayStates=[Collections.Generic.List[object]]::new();$replayChecks=[Collections.Generic.List[object]]::new()
    $replayRoot=[IntPtr]::Zero;$replayWalker=[IntPtr]::Zero;$replayUia=[IntPtr]::Zero;$replayUnknown=[IntPtr]::Zero
    try {
        for($i=0;$i -lt 100 -and -not(Test-Path $livePath);$i++){Start-Sleep -Milliseconds 100}
        if(-not(Test-Path $livePath)){throw 'The native feature replay did not expose its diagnostic state.'}
        # Do not query UIA while the HWND is still moving outside the virtual desktop.
        for($i=0;$i -lt 100;$i++){if((Get-Content -LiteralPath $livePath -Raw|ConvertFrom-Json).EntranceStatus -eq 'Completed'){break};Start-Sleep -Milliseconds 40}
        $replayHandle=Get-NativeAppWindowHandle $nativeReplay.Id
        if($replayHandle -eq [IntPtr]::Zero){throw 'The native feature replay window was not found.'}
        $sendType=New-NativeDelegateType 'NativeReplaySend' ([IntPtr]) ([type[]]@([IntPtr],[uint32],[IntPtr],[IntPtr]))
        $send=Get-NativeFunction 'user32.dll' 'SendMessageW' $sendType
        $uiaObject=[Activator]::CreateInstance([type]::GetTypeFromCLSID([guid]'ff48dba4-60ef-4201-aa87-54103eef594e'))
        $replayUnknown=[Runtime.InteropServices.Marshal]::GetIUnknownForObject($uiaObject)
        $iid=[guid]'30cbe57d-d9d0-452a-ab13-7ac5ac4825ee'
        $hr=[Runtime.InteropServices.Marshal]::QueryInterface($replayUnknown,[ref]$iid,[ref]$replayUia)
        if($hr -lt 0){[Runtime.InteropServices.Marshal]::ThrowExceptionForHR($hr)}
        $result=Invoke-ComSlot $replayUia 6 $script:ComHandleOutType @($replayHandle,[IntPtr]::Zero)
        $replayRoot=[IntPtr]$result[2];$replayWalker=Get-ComOut $replayUia 16
        function Read-Replay { Get-Content -LiteralPath $livePath -Raw | ConvertFrom-Json }
        function Click-Replay([string]$Id,[string]$Value='',[double]$Fraction=0.5,[bool]$Wait=$true) {
            for($scroll=0;$scroll -lt 60;$scroll++){
                $before=Read-Replay
                $nodes=@($before.Nodes | Where-Object { $_.Id -eq $Id -and (-not $Value -or $_.Data.Value -eq $Value) })
                if($nodes.Count -ne 1){throw "Replay hit '$Id' was not unique."}
                $r=$nodes[0].Rect
                if(-not $before.SettingsOpen -or ($r[1] -ge 40 -and $r[1]+$r[3] -le $before.Height-10)){break}
                $delta=if($r[1] -lt 40){120}else{-120}
                $null=$send.DynamicInvoke([object[]]@($replayHandle,[uint32]0x20A,[IntPtr]($delta -shl 16),[IntPtr]::Zero))
                for($j=0;$j -lt 30;$j++){Start-Sleep -Milliseconds 30;if((Read-Replay).ScrollSequence -gt $before.ScrollSequence){break}}
            }
            $r=$nodes[0].Rect;$scale=$before.Dpi/96
            $x=[int](($r[0]+$r[2]*[Math]::Clamp($Fraction,0.001,0.995))*$scale);$y=[int](($r[1]+$r[3]/2)*$scale);$point=[IntPtr](($y -shl 16) -bor ($x -band 0xffff))
            foreach($message in @(0x200,0x201,0x202)){$null=$send.DynamicInvoke([object[]]@($replayHandle,[uint32]$message,[IntPtr]$(if($message -eq 0x201){1}else{0}),$point))}
            if(-not $Wait){return}
            for($j=0;$j -lt 50;$j++){Start-Sleep -Milliseconds 40;if((Read-Replay).ClickSequence -gt $before.ClickSequence){return}}
            throw "The native replay did not repaint after '$Id'."
        }
        function Capture-Replay([string]$Name){
            $tree=Get-UiaNode $replayRoot $replayWalker
            $r=$tree.Properties.BoundingRectangle;$path=Join-Path $EvidenceDirectory ('native-feature-'+$Name+'.png')
            Save-WindowImage $replayHandle $path ([int]$r[2]) ([int]$r[3])
            $replayStates.Add([pscustomobject]@{Name=$Name;Tree=$tree;Application=(Read-Replay);Image=$path;ImageSHA256=(Get-FileHash $path -Algorithm SHA256).Hash})
        }
        function Choose-ReplayColor([string]$Role,[string]$Hex){
            Click-Replay ('color-'+$Role)
            if((Read-Replay).ColorPicker.Role -ne $Role){throw 'The replay selected the wrong color swatch.'}
            Capture-Replay ('picker-'+$Role)
            Click-Replay 'picker-input-hex'
            foreach($character in $Hex.ToCharArray()){$null=$send.DynamicInvoke([object[]]@($replayHandle,[uint32]0x102,[IntPtr][int]$character,[IntPtr]::Zero))}
            for($k=0;$k -lt 60;$k++){Start-Sleep -Milliseconds 30;if((Read-Replay).Settings.colors.$Role -eq $Hex){break}}
            $actual=(Read-Replay).Settings.colors.$Role
            $replayChecks.Add([pscustomobject]@{Property=('Canvas color picker '+$Role);Expected=$Hex;Observed=$actual;Verdict=if($actual -eq $Hex){'TRUE'}else{'FALSE'}})
            if($actual -ne $Hex){throw 'The canvas color picker contradicted the requested hex value.'}
            $null=$send.DynamicInvoke([object[]]@($replayHandle,[uint32]0x100,[IntPtr]27,[IntPtr]::Zero))
            for($k=0;$k -lt 30;$k++){Start-Sleep -Milliseconds 30;if(-not @((Read-Replay).Nodes|Where-Object Id -eq 'picker-background').Count){break}}
        }
        for($i=0;$i -lt 100;$i++){if((Read-Replay).EntranceStatus -eq 'Completed'){break};Start-Sleep -Milliseconds 40}
        $entrance=Read-Replay
        $replayChecks.Add([pscustomobject]@{Property='Painted offscreen fade entrance';Expected='Completed, alpha 0 to 255';Observed=$entrance.EntranceStatus;Verdict=if($entrance.EntranceStatus -eq 'Completed' -and $entrance.Entrance.FromX -gt $entrance.Entrance.ToX -and $entrance.EntranceSamples.Count -ge 2 -and $entrance.EntranceSamples[-1].Alpha -eq 255 -and $entrance.EntranceSamples[-1].X -eq $entrance.Entrance.ToX -and $entrance.EntranceRestore.OriginalStyle -eq $entrance.EntranceRestore.ObservedStyle){'TRUE'}else{'FALSE'}})
        $replayChecks.Add([pscustomobject]@{Property='DWM outline disabled';Expected=-2;Observed=$entrance.Appearance.BorderColor;Verdict=if($entrance.Appearance.BorderColor -eq -2){'TRUE'}else{'FALSE'}})
        Capture-Replay 'editor'
        Click-Replay 'app-icon'
        $iconKey=(Read-Replay).Settings.windowIcon;$nativeIcon=$send.DynamicInvoke([object[]]@($replayHandle,[uint32]0x7F,[IntPtr]1,[IntPtr]::Zero))
        $replayChecks.Add([pscustomobject]@{Property='Top-left icon Easter egg';Expected='Selected system icon and WM_GETICON handle';Observed=$iconKey;Verdict=if($iconKey -ne 'default' -and $nativeIcon -ne [IntPtr]::Zero){'TRUE'}else{'FALSE'}})
        Capture-Replay 'cycled-icon'
        $normal=Read-Replay
        Click-Replay 'btn-win-min'
        for($j=0;$j -lt 50;$j++){Start-Sleep -Milliseconds 30;if((Read-Replay).Minimized){break}}
        $minimized=Read-Replay
        $showType=New-NativeDelegateType 'ReplayRestore' ([bool]) ([type[]]@([IntPtr],[int]))
        $show=Get-NativeFunction 'user32.dll' 'ShowWindowAsync' $showType;$null=$show.DynamicInvoke([object[]]@($replayHandle,9))
        for($j=0;$j -lt 100;$j++){Start-Sleep -Milliseconds 30;if(-not (Read-Replay).Minimized){break}}
        $restored=Read-Replay
        $replayChecks.Add([pscustomobject]@{Property='Minimize and restore retain canvas size';Expected=($normal.Width.ToString()+' x '+$normal.Height);Observed=($restored.Width.ToString()+' x '+$restored.Height);Verdict=if($minimized.Minimized -and -not $restored.Minimized -and $normal.Width -eq $restored.Width -and $normal.Height -eq $restored.Height){'TRUE'}else{'FALSE'}})
        Capture-Replay 'restored'
        $newDocumentMode=(Read-Replay).Session.Tabs[0].LineEnding
        $replayChecks.Add([pscustomobject]@{Property='New document line endings';Expected='Windows (CRLF)';Observed=$newDocumentMode;Verdict=if($newDocumentMode -eq 'Windows (CRLF)'){'TRUE'}else{'FALSE'}})
        $minimum=[Runtime.InteropServices.Marshal]::AllocHGlobal(40)
        try{
            $null=$send.DynamicInvoke([object[]]@($replayHandle,[uint32]0x24,[IntPtr]::Zero,$minimum))
            $minWidth=[Runtime.InteropServices.Marshal]::ReadInt32($minimum,24);$minHeight=[Runtime.InteropServices.Marshal]::ReadInt32($minimum,28)
            $replayChecks.Add([pscustomobject]@{Property='Minimum track size';Expected='768 x 478 at 96 DPI';Observed="$minWidth x $minHeight";Verdict=if($minWidth -ge 768 -and $minHeight -ge 478){'TRUE'}else{'FALSE'}})
        }finally{[Runtime.InteropServices.Marshal]::FreeHGlobal($minimum)}
        Click-Replay 'format-bold'
        foreach($c in 'strong'.ToCharArray()){$null=$send.DynamicInvoke([object[]]@($replayHandle,[uint32]0x102,[IntPtr][int]$c,[IntPtr]::Zero))}
        Start-Sleep -Milliseconds 200
        $typed=(Read-Replay).Session.Tabs[0].Text
        $replayChecks.Add([pscustomobject]@{Property='Bold toolbar edits document';Expected='**strong**';Observed=$typed;Verdict=if($typed -ceq '**strong**'){'TRUE'}else{'FALSE'}})
        Capture-Replay 'bold'
        Click-Replay 'btn-settings-toggle'
        Click-Replay 'setting-background-opacity' '' 0.54
        $opacity=(Read-Replay).Settings.backgroundOpacity
        $replayChecks.Add([pscustomobject]@{Property='Background opacity slider';Expected=54;Observed=$opacity;Verdict=if($opacity -eq 54){'TRUE'}else{'FALSE'}})
        Capture-Replay 'settings'
        foreach($pair in @(@('acrylic',3,1),@('reverseMica',4,2),@('mica',2,0))){
            Click-Replay 'setting-backdrop';Click-Replay ('dropdown-backdrop-chooseSetting-'+$pair[2])
            $d=Read-Replay
            $replayChecks.Add([pscustomobject]@{Property=('DWM '+$pair[0]);Expected=$pair[1];Observed=$d.Appearance.Observed;Verdict=if($d.Settings.backdrop -eq $pair[0] -and $d.Appearance.Observed -eq $pair[1]){'TRUE'}else{'FALSE'}})
            Capture-Replay $pair[0]
        }
        Click-Replay 'setting-cornerStyle';Click-Replay 'dropdown-cornerStyle-chooseSetting-1'
        $d=Read-Replay
        $replayChecks.Add([pscustomobject]@{Property='Straight corner setting';Expected=$false;Observed=$d.Appearance.Curved;Verdict=if(-not $d.Appearance.Curved -and $d.Settings.cornerStyle -eq 'straight'){'TRUE'}else{'FALSE'}})
        Capture-Replay 'straight'
        Click-Replay 'setting-resetIcon'
        $reset=(Read-Replay).Settings.windowIcon
        $replayChecks.Add([pscustomobject]@{Property='Reset icon';Expected='default';Observed=$reset;Verdict=if($reset -eq 'default'){'TRUE'}else{'FALSE'}})
        Click-Replay 'header-card-colors-setting'
        Capture-Replay 'color-grid'
        Choose-ReplayColor 'topLeft' '#1C1B22';Choose-ReplayColor 'topRight' '#3A294D';Choose-ReplayColor 'bottomLeft' '#283647';Choose-ReplayColor 'bottomRight' '#402039'
        Click-Replay 'setting-background-opacity' '' 1.0
        $null=$send.DynamicInvoke([object[]]@($replayHandle,[uint32]0x100,[IntPtr]35,[IntPtr]::Zero))
        for($j=0;$j -lt 30;$j++){Start-Sleep -Milliseconds 30;if((Read-Replay).Settings.backgroundOpacity -eq 100){break}}
        Click-Replay 'settings-btn-back'
        Capture-Replay 'four-corner-gradient'
        $gradientImage=$replayStates[$replayStates.Count-1].Image
        $bitmap=[Drawing.Bitmap]::FromFile($gradientImage)
        try{$pixel=$bitmap.GetPixel([int]($bitmap.Width/2),[int]($bitmap.Height/2));$expected=@(48,39,60);$error=[Math]::Max([Math]::Abs($pixel.R-$expected[0]),[Math]::Max([Math]::Abs($pixel.G-$expected[1]),[Math]::Abs($pixel.B-$expected[2])));$replayChecks.Add([pscustomobject]@{Property='Four-corner bilinear center pixel';Expected='RGB 48,39,60 ±2';Observed=($pixel.R.ToString()+','+$pixel.G+','+$pixel.B);Verdict=if($error -le 2){'TRUE'}else{'FALSE'}})}finally{$bitmap.Dispose()}
        Click-Replay 'btn-settings-toggle'
        Click-Replay 'toggle-setting-copyAsFile'
        $d=Read-Replay
        $replayChecks.Add([pscustomobject]@{Property='Whole-document file mode rocker';Expected=$true;Observed=$d.Settings.copyAsFile;Verdict=if($d.Settings.copyAsFile){'TRUE'}else{'FALSE'}})
        Click-Replay 'settings-btn-back';Click-Replay 'btn-whats-new'
        Capture-Replay 'comparison'
        Click-Replay 'comparison-run'
        for($j=0;$j -lt 300;$j++){Start-Sleep -Milliseconds 150;$d=Read-Replay;if($d.ComparisonStatus -like 'Comparison complete*' -or $d.ComparisonStatus -like 'Comparison failed*'){break}}
        $replayChecks.Add([pscustomobject]@{Property='Integrated asynchronous comparison';Expected='Comparison complete';Observed=$d.ComparisonStatus;Verdict=if($d.ComparisonStatus -like 'Comparison complete*'){'TRUE'}else{'FALSE'}})
        Capture-Replay 'comparison-complete'
        [pscustomobject]@{Machine=$env:COMPUTERNAME;WindowsBuild=[Environment]::OSVersion.Version.ToString();TimeUtc=[DateTime]::UtcNow;SourceSHA256=(Get-FileHash (Join-Path $PSScriptRoot 'Notepad.ps1') -Algorithm SHA256).Hash;States=$replayStates.ToArray();Checks=$replayChecks.ToArray()} | Export-Clixml (Join-Path $EvidenceDirectory 'native-feature-replay.clixml')
        $replayChecks | Format-Table -AutoSize
        if(@($replayChecks|Where-Object Verdict -eq 'FALSE').Count){throw 'The native feature replay found a defect.'}
    }finally{
        [pscustomobject]@{TimeUtc=[DateTime]::UtcNow;SourceSHA256=(Get-FileHash (Join-Path $PSScriptRoot 'Notepad.ps1') -Algorithm SHA256).Hash;States=$replayStates.ToArray();Checks=$replayChecks.ToArray()}|Export-Clixml (Join-Path $EvidenceDirectory 'native-feature-replay-last-attempt.clixml')
        foreach($pointer in @($replayRoot,$replayWalker,$replayUia,$replayUnknown)){if($pointer -ne [IntPtr]::Zero){[void][Runtime.InteropServices.Marshal]::Release($pointer)}}
        $nativeReplay.Refresh();if(-not $nativeReplay.HasExited){$nativeReplay.Kill()}
    }
    return
}
$realCachePath = Join-Path $EvidenceDirectory 'real-notepad.clixml'
$useCachedReal = $false
if (-not $RefreshReal -and (Test-Path $realCachePath)) {
    try {
        $cachedReal = Import-Clixml $realCachePath
        $getSystemDpi = Get-NativeFunction 'user32.dll' 'GetDpiForSystem' $script:GetDpiSystemType
        $systemDpi = [int]$getSystemDpi.DynamicInvoke([object[]]@())
        $cacheContextMatches = $cachedReal.Metadata.Machine -eq $env:COMPUTERNAME -and
            $cachedReal.Metadata.WindowsBuild -eq [Environment]::OSVersion.Version.ToString() -and
            (Test-Path $cachedReal.Metadata.NotepadPath) -and
            $cachedReal.Metadata.NotepadSHA256 -eq (Get-FileHash $cachedReal.Metadata.NotepadPath -Algorithm SHA256).Hash -and
            $cachedReal.Metadata.Dpi -eq $systemDpi -and
            $cachedReal.Metadata.DisplayCount -eq (Get-MonitorCount)
        $cachePairsIntact = $cachedReal.States.Count -ge 15
        if ($cacheContextMatches -and $cachePairsIntact) {
            foreach ($state in $cachedReal.States) {
                if (-not $state.Tree -or -not (Test-Path $state.Image) -or
                    (Get-FileHash $state.Image -Algorithm SHA256).Hash -ne $state.ImageSHA256) {
                    $cachePairsIntact = $false
                    break
                }
            }
        }
        $useCachedReal = $cacheContextMatches -and $cachePairsIntact
    } catch { $useCachedReal = $false }
}
if ($useCachedReal) {
    [pscustomobject]@{ Bearing='real notepad.exe'; Status='CACHED'; CapturedUtc=$cachedReal.Metadata.TimeUtc; PairedStates=$cachedReal.States.Count }
} else {
$probeFile = Join-Path $env:TEMP ('notepad-ps1-probe-' + [guid]::NewGuid().ToString('N') + '.txt')
[IO.File]::WriteAllText($probeFile, '')
$alias = (Get-Command notepad.exe).Source
$broker = Start-Process -FilePath $alias -ArgumentList ('"' + $probeFile + '"') -PassThru
$name = [IO.Path]::GetFileName($probeFile)
$probe = $null
for ($attempt = 0; $attempt -lt 50; $attempt++) {
    Start-Sleep -Milliseconds 100
    $probe = Get-Process Notepad -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowTitle.StartsWith($name) } |
        Select-Object -First 1
    if ($probe) { break }
}
if (-not $probe) { throw "The new Notepad window for $name did not appear." }

try {
    $uiaClass = [type]::GetTypeFromCLSID([guid]'ff48dba4-60ef-4201-aa87-54103eef594e')
    $uiaObject = [Activator]::CreateInstance($uiaClass)
    $unknown = [Runtime.InteropServices.Marshal]::GetIUnknownForObject($uiaObject)
    $uia = [IntPtr]::Zero
    $iid = [guid]'30cbe57d-d9d0-452a-ab13-7ac5ac4825ee'
    $hr = [Runtime.InteropServices.Marshal]::QueryInterface($unknown, [ref]$iid, [ref]$uia)
    if ($hr -ne 0) { [Runtime.InteropServices.Marshal]::ThrowExceptionForHR($hr) }
    try {
        $result = Invoke-ComSlot $uia 6 $script:ComHandleOutType @([IntPtr]$probe.MainWindowHandle, [IntPtr]::Zero)
        $root = [IntPtr]$result[2]
        $walker = Get-ComOut $uia 16
        try {
            $states = [Collections.Generic.List[object]]::new()
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'empty' $EvidenceDirectory))
            $getDpi = Get-NativeFunction 'user32.dll' 'GetDpiForWindow' $script:GetDpiType
            $dpi = $getDpi.DynamicInvoke([object[]]@([IntPtr]$probe.MainWindowHandle))
            $vk = $script:VirtualKey
            $foreground = Get-NativeFunction 'user32.dll' 'SetForegroundWindow' $script:SetForegroundType
            [void]$foreground.DynamicInvoke([object[]]@([IntPtr]$probe.MainWindowHandle))
            $editor = Find-UiaElement $root $walker 'Text editor'
            if ($editor -eq [IntPtr]::Zero) { throw 'The fresh Notepad editor was not found via UIA.' }
            try { $null = Invoke-ComSlot $editor 3 $script:ComNoArgType @() }
            finally { [void][Runtime.InteropServices.Marshal]::Release($editor) }
            $realCommands = @(
                [pscustomobject]@{ Name='typed'; Text='Notepad comparison sample'; Chord=$null },
                [pscustomobject]@{ Name='selected'; Text=$null; Chord=[uint16[]]@($vk.Control, $vk.A) },
                [pscustomobject]@{ Name='undo'; Text=$null; Chord=[uint16[]]@($vk.Control, $vk.Z) },
                [pscustomobject]@{ Name='redo'; Text=$null; Chord=[uint16[]]@($vk.Control, $vk.Y) }
            )
            foreach ($command in $realCommands) {
                Send-KeyboardInput -Text $command.Text -Chord $command.Chord
                Start-Sleep -Milliseconds 150
                $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle $command.Name $EvidenceDirectory))
            }
            Send-KeyboardInput -Chord $vk.Control, $vk.S
            # Saving can move keyboard focus away from the editor in recent Notepad builds.
            [void]$foreground.DynamicInvoke([object[]]@([IntPtr]$probe.MainWindowHandle))
            $editor = Find-UiaElement $root $walker 'Text editor'
            if ($editor -eq [IntPtr]::Zero) { throw 'The probe editor was lost after save.' }
            try { $null = Invoke-ComSlot $editor 3 $script:ComNoArgType @() }
            finally { [void][Runtime.InteropServices.Marshal]::Release($editor) }
            $realDialogCommands = @(
                [pscustomobject]@{ Name='find-open'; Text=$null; Chord=[uint16[]]@($vk.Control, $vk.F) },
                [pscustomobject]@{ Name='find-query'; Text='sample'; Chord=$null }
            )
            foreach ($command in $realDialogCommands) {
                Send-KeyboardInput -Text $command.Text -Chord $command.Chord
                if ($command.Name -eq 'find-open') {
                    Start-Sleep -Milliseconds 120
                    $findButton = Find-UiaElement $root $walker 'Open replace options' 50000
                    if ($findButton -eq [IntPtr]::Zero) {
                        # The shortcut occasionally misses focus after a save. Use the probe's UIA menu.
                        Invoke-UiaElementByName $root $walker 'Edit' 50011
                        Start-Sleep -Milliseconds 100
                        Invoke-UiaElementByName $root $walker 'Find' 50011
                    } else {
                        [void][Runtime.InteropServices.Marshal]::Release($findButton)
                    }
                    Send-KeyboardInput -Chord $vk.Control, $vk.A
                    Send-KeyboardInput -Chord $vk.Back
                }
                Start-Sleep -Milliseconds 180
                $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle $command.Name $EvidenceDirectory))
            }
            Invoke-UiaElementByName $root $walker 'Open replace options' 50000
            Start-Sleep -Milliseconds 150
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'replace-open' $EvidenceDirectory))
            Invoke-UiaElementByName $root $walker 'Exit Find and Replace' 50000
            Start-Sleep -Milliseconds 150
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'find-close' $EvidenceDirectory))
            Send-KeyboardInput -Chord $vk.Control, $vk.N
            Start-Sleep -Milliseconds 150
            $discardOwnProbe = Find-UiaElement $root $walker "Don't save" 50000
            if ($discardOwnProbe -ne [IntPtr]::Zero) {
                [void][Runtime.InteropServices.Marshal]::Release($discardOwnProbe)
                # This prompt is for the fresh, instrument-owned temp file only.
                Invoke-UiaElementByName $root $walker "Don't save" 50000
                Start-Sleep -Milliseconds 150
            }
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'new-tab' $EvidenceDirectory))
            Invoke-UiaElementByName $root $walker 'File' 50011
            Start-Sleep -Milliseconds 150
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'file-menu' $EvidenceDirectory))
            Send-KeyboardInput -Chord $vk.Escape
            Invoke-UiaElementByName $root $walker 'Settings'
            Start-Sleep -Milliseconds 200
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'settings' $EvidenceDirectory))
            $unavailableStates = [Collections.Generic.List[string]]::new()
            Click-UiaElementByName $root $walker 'App theme' 50000
            Start-Sleep -Milliseconds 150
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'theme-options' $EvidenceDirectory))
            $lightOption = Find-UiaElement $root $walker 'Light' 50013
            if ($lightOption -ne [IntPtr]::Zero) {
                [void][Runtime.InteropServices.Marshal]::Release($lightOption)
                Click-UiaElementByName $root $walker 'Light' 50013
                Start-Sleep -Milliseconds 180
                $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'theme-light' $EvidenceDirectory))
                $systemOption = Find-UiaElement $root $walker 'Use system setting' 50013
                if ($systemOption -eq [IntPtr]::Zero) {
                    Click-UiaElementByName $root $walker 'App theme' 50000
                    Start-Sleep -Milliseconds 100
                } else {
                    [void][Runtime.InteropServices.Marshal]::Release($systemOption)
                }
                Click-UiaElementByName $root $walker 'Use system setting' 50013
            } else {
                $unavailableStates.Add('theme-light: App theme options did not open in UIA')
            }
            Start-Sleep -Milliseconds 180
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'theme-restored' $EvidenceDirectory))
            Invoke-UiaElementByName $root $walker 'Back' 50000
            Start-Sleep -Milliseconds 150
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'settings-close' $EvidenceDirectory))
            Send-KeyboardInput -Chord $vk.Control, $vk.OemPlus
            Start-Sleep -Milliseconds 150
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'zoom-in' $EvidenceDirectory))
            Send-KeyboardInput -Chord $vk.Control, $vk.D0
            Start-Sleep -Milliseconds 150
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'zoom-restored' $EvidenceDirectory))
            $exe = $probe.Path
            $observation = [pscustomobject]@{
                Metadata = [pscustomobject]@{
                    Machine = $env:COMPUTERNAME
                    WindowsBuild = [Environment]::OSVersion.Version.ToString()
                    NotepadPath = $exe
                    NotepadVersion = (Get-Item $exe).VersionInfo.FileVersion
                    NotepadSHA256 = (Get-FileHash $exe -Algorithm SHA256).Hash
                    TimeUtc = [datetime]::UtcNow
                    Dpi = $dpi
                    DisplayCount = Get-MonitorCount
                    AvailableDisplayDpi = @($dpi)
                    UnavailableRequestedDpi = @(120,144) | Where-Object { $_ -ne $dpi }
                    ProbeFile = $probeFile
                    UnavailableStates = $unavailableStates.ToArray()
                }
                States = $states.ToArray()
            }
            $observation | Export-Clixml (Join-Path $EvidenceDirectory 'real-notepad.clixml')
            $states | Select-Object Name,Width,Height,ImageSHA256
        } finally {
            if ($walker -ne [IntPtr]::Zero) { [void][Runtime.InteropServices.Marshal]::Release($walker) }
            if ($root -ne [IntPtr]::Zero) { [void][Runtime.InteropServices.Marshal]::Release($root) }
        }
    } finally {
        if ($uia -ne [IntPtr]::Zero) { [void][Runtime.InteropServices.Marshal]::Release($uia) }
        [void][Runtime.InteropServices.Marshal]::Release($unknown)
    }
} finally {
    if (-not $KeepProbeOpen) {
        $probe.Refresh()
        if (-not $probe.HasExited) { $probe.CloseMainWindow() | Out-Null }
        if ($broker -and -not $broker.HasExited) { $broker.CloseMainWindow() | Out-Null }
        # The instrument owns this unique empty file; keep only the captured evidence.
        Remove-Item -LiteralPath $probeFile -Force -ErrorAction SilentlyContinue
    }
}
}

$realEvidence = Import-Clixml (Join-Path $EvidenceDirectory 'real-notepad.clixml')
$iconEvidence = @(Get-CubicGlyphEvidence $realEvidence)
$iconEvidence | Export-Clixml (Join-Path $EvidenceDirectory 'fluent-glyph-cubics.clixml')
[pscustomobject]@{ Glyphs = $iconEvidence.Count; Cubics = @($iconEvidence | ForEach-Object { $_.Cubics.Count } | Measure-Object -Sum).Sum; FontSHA256 = if ($iconEvidence.Count) { $iconEvidence[0].FontSHA256 } else { $null } }

if (-not $SkipBrowser) {
    $originalPath = Join-Path $PSScriptRoot 'reference\notepad.original.html'
    $browser = Connect-EdgePage $originalPath
    try {
        $null = Invoke-Cdp $browser 'Page.enable'
        $null = Invoke-Cdp $browser 'Runtime.enable'
        $null = Invoke-Cdp $browser 'Emulation.setDeviceMetricsOverride' @{
            width = 768; height = 478; deviceScaleFactor = 1; mobile = $false
        }
        Start-BrowserCoverage $browser
        if ($ExtractTypeScript) {
            if (Test-Path (Join-Path $PSScriptRoot 'reference\notepad.ts')) {
                throw 'The typed TypeScript source already exists; extraction would overwrite it.'
            }
            $scriptText = Get-CdpValue $browser "document.querySelector('script').textContent"
            [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'reference\notepad.ts'), $scriptText, [Text.UTF8Encoding]::new($false))
        }
        if ($BuildTypeScript) {
            $compiler = 'C:\bin\vs\Common7\IDE\CommonExtensions\Microsoft\TSServer\_tsc.js'
            $node = 'C:\bin\node-v26.5.0-win-x64\node.exe'
            $tsSource = Join-Path $PSScriptRoot 'reference\notepad.ts'
            $compiled = Join-Path $PSScriptRoot 'reference\notepad.compiled.js'
            $compileArguments = @('--strict','--target','es2022','--lib','dom,es2022','--sourceMap','--inlineSources','--outFile',$compiled,$tsSource)
            $diagnostics = @(& $node $compiler @compileArguments 2>&1 | ForEach-Object ToString)
            if ($LASTEXITCODE -ne 0) { throw 'Strict TypeScript compilation failed.' }
            $compilation = [pscustomobject]@{
                CompilerVersion = (& $node $compiler --version)
                CompilerSHA256 = (Get-FileHash $compiler -Algorithm SHA256).Hash
                Arguments = $compileArguments
                SourceSHA256 = (Get-FileHash $tsSource -Algorithm SHA256).Hash
                OutputSHA256 = (Get-FileHash $compiled -Algorithm SHA256).Hash
                SourceMapSHA256 = (Get-FileHash ($compiled + '.map') -Algorithm SHA256).Hash
                Diagnostics = $diagnostics
                StrictCheckPassed = $true
                TimeUtc = [datetime]::UtcNow
            }
            $compilation | Export-Clixml (Join-Path $EvidenceDirectory 'typescript-compilation.clixml')
            $semanticProbe = @'
const fs = require('fs');
const ts = require('C:/bin/vs/Common7/IDE/CommonExtensions/Microsoft/TSServer/typescript.js');
const file = process.argv[1];
const options = { strict: true, target: ts.ScriptTarget.ES2022, lib: ['lib.dom.d.ts','lib.es2022.d.ts'], sourceMap: true, inlineSources: true, outFile: process.argv[2] };
const program = ts.createProgram([file], options);
const checker = program.getTypeChecker();
const source = program.getSourceFile(file);
const nodes = [];
const byId = new Map();
const identity = n => `${n.getStart(source)}:${n.end}:${ts.SyntaxKind[n.kind]}`;
function visit(n) {
  const id = identity(n);
  let symbol = null, type = null, declaredType = null, inferredType = null;
  let signature = null, anyType = false, anyOrigin = null;
  try {
    const s = checker.getSymbolAtLocation(n);
    if (s) {
      symbol = checker.symbolToString(s);
      const declaration = s.valueDeclaration || s.declarations?.[0];
      try {
        if (declaration?.type) declaredType = checker.typeToString(checker.getTypeFromTypeNode(declaration.type));
        if (declaration) inferredType = checker.typeToString(checker.getTypeOfSymbolAtLocation(s, declaration));
      } catch {}
    }
    const t = checker.getTypeAtLocation(n);
    if (t) {
      type = checker.typeToString(t); anyType = !!(t.flags & ts.TypeFlags.Any);
      if (anyType) {
        const declarations = s?.declarations || [];
        anyOrigin = n.kind === ts.SyntaxKind.AnyKeyword || declarations.some(d => d.type?.kind === ts.SyntaxKind.AnyKeyword)
          ? 'EXPLICIT' : 'PROPAGATED_OR_INFERRED';
      }
    }
    if (ts.isCallExpression(n) || ts.isNewExpression(n)) {
      const resolved = checker.getResolvedSignature(n);
      if (resolved) signature = checker.signatureToString(resolved);
    }
  } catch {}
  const line = source.getLineAndCharacterOfPosition(n.getStart(source));
  const row = { id, kind: ts.SyntaxKind[n.kind], start: n.getStart(source), end: n.end,
    line: line.line + 1, column: line.character + 1, symbol, type, declaredType,
    inferredType, narrowedType: type, resolvedOverload: signature, anyType, anyOrigin,
    emitted: [], transformations: [], runtime: [] };
  nodes.push(row); byId.set(id, row);
  ts.forEachChild(n, visit);
}
visit(source);
const emitted = [];
const transformer = context => root => {
  function scan(n) {
    const original = ts.getOriginalNode(n);
    let sourceId = null;
    if (original && original.pos >= 0 && original.end >= 0) {
      try { sourceId = identity(original); } catch {}
    }
    emitted.push({ sourceId, kind: ts.SyntaxKind[n.kind], pos: n.pos, end: n.end });
    ts.forEachChild(n, scan);
  }
  scan(root);
  return root;
};
const emitResult = program.emit(undefined, () => {}, undefined, false, { after: [transformer] });
for (const e of emitted) {
  if (e.sourceId && byId.has(e.sourceId)) byId.get(e.sourceId).emitted.push({ kind: e.kind, pos: e.pos, end: e.end });
}
for (const n of nodes) {
  if (n.emitted.length === 0) n.transformations.push('no-emitted-node');
  else if (n.emitted.some(e => e.kind !== n.kind)) n.transformations.push('kind-changed');
  else n.transformations.push('kind-preserved');
}
const sourceMap = JSON.parse(fs.readFileSync(options.outFile + '.map', 'utf8'));
const generatedText = fs.readFileSync(options.outFile, 'utf8');
const lineStarts = text => { const a=[0]; for(let i=0;i<text.length;i++) if(text[i]==='\n') a.push(i+1); return a; };
const generatedLines = lineStarts(generatedText), sourceLines = lineStarts(source.text);
const decode = segment => {
  const values=[]; let value=0, shift=0;
  for(const ch of segment) {
    const digit='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'.indexOf(ch);
    if(digit<0) continue;
    value |= (digit & 31) << shift;
    if(digit & 32) { shift += 5; continue; }
    values.push((value & 1) ? -(value >> 1) : (value >> 1)); value=0; shift=0;
  }
  return values;
};
const generatedBySource = new Map();
let sourceIndex=0, sourceLine=0, sourceColumn=0;
for(const [lineNumber, line] of sourceMap.mappings.split(';').entries()) {
  let generatedColumn=0;
  for(const encoded of line.split(',')) {
    if(!encoded) continue;
    const delta=decode(encoded); generatedColumn += delta[0];
    if(delta.length<4) continue;
    sourceIndex += delta[1]; sourceLine += delta[2]; sourceColumn += delta[3];
    if(sourceIndex!==0 || sourceLine>=sourceLines.length || lineNumber>=generatedLines.length) continue;
    const sourceOffset=sourceLines[sourceLine]+sourceColumn;
    const generatedOffset=generatedLines[lineNumber]+generatedColumn;
    if(!generatedBySource.has(sourceOffset)) generatedBySource.set(sourceOffset, []);
    generatedBySource.get(sourceOffset).push(generatedOffset);
  }
}
for(const n of nodes) n.generatedOffsets = generatedBySource.get(n.start) || [];
const diagnostics = ts.getPreEmitDiagnostics(program).concat(emitResult.diagnostics).map(d => ({ code: d.code, message: ts.flattenDiagnosticMessageText(d.messageText, '\n') }));
process.stdout.write(JSON.stringify({ source: file, nodes, unjoinedEmitted: emitted.filter(e => !e.sourceId || !byId.has(e.sourceId)), diagnostics }));
'@
            $semanticJson = & $node -e $semanticProbe $tsSource $compiled
            if ($LASTEXITCODE -ne 0) { throw 'TypeScript semantic extraction failed.' }
            $semanticLedger = $semanticJson | ConvertFrom-Json -Depth 100
            $semanticLedger | Export-Clixml (Join-Path $EvidenceDirectory 'typescript-node-semantics.clixml')
            $traceCompiler = @'
const ts = require('C:/bin/vs/Common7/IDE/CommonExtensions/Microsoft/TSServer/typescript.js');
const sourcePath = process.argv[1], outputPath = process.argv[2];
const options = { strict: true, target: ts.ScriptTarget.ES2022, lib: ['lib.dom.d.ts','lib.es2022.d.ts'], outFile: outputPath };
const program = ts.createProgram([sourcePath], options);
const source = program.getSourceFile(sourcePath);
const recorded = [];
const assignment = kind => kind >= ts.SyntaxKind.FirstAssignment && kind <= ts.SyntaxKind.LastAssignment;
const transformer = context => root => {
  const f = context.factory;
  function visit(n, parent) {
    if (ts.isTypeNode(n)) return n;
    const result = ts.visitEachChild(n, child => visit(child, n), context);
    if (!ts.isExpressionNode(n) || n.kind === ts.SyntaxKind.SuperKeyword ||
        ts.isArrowFunction(n) || ts.isFunctionExpression(n) || ts.isClassExpression(n) ||
        ts.isAwaitExpression(n) || ts.isYieldExpression(n)) return result;
    if (parent) {
      if (parent.name === n) return result;
      if ((ts.isCallExpression(parent) || ts.isNewExpression(parent) || ts.isTaggedTemplateExpression(parent)) && parent.expression === n) return result;
      if (ts.isBinaryExpression(parent) && parent.left === n && assignment(parent.operatorToken.kind)) return result;
      if ((ts.isPrefixUnaryExpression(parent) || ts.isPostfixUnaryExpression(parent)) && parent.operand === n &&
          [ts.SyntaxKind.PlusPlusToken, ts.SyntaxKind.MinusMinusToken].includes(parent.operator)) return result;
      if (ts.isDeleteExpression(parent) || ts.isTypeOfExpression(parent)) return result;
    }
    const id = `${n.getStart(source)}:${n.end}:${ts.SyntaxKind[n.kind]}`;
    recorded.push(id);
    const call = f.createCallExpression(
      f.createPropertyAccessExpression(f.createIdentifier('globalThis'), '__npTrace'),
      undefined, [f.createStringLiteral(id), result]);
    ts.setOriginalNode(call, n);
    return call;
  }
  return visit(root, null);
};
const emitted = program.emit(undefined, undefined, undefined, false, { before: [transformer] });
const diagnostics = ts.getPreEmitDiagnostics(program).concat(emitted.diagnostics);
if (diagnostics.length) { process.stderr.write(diagnostics.map(d => ts.flattenDiagnosticMessageText(d.messageText,'\n')).join('\n')); process.exit(1); }
process.stdout.write(JSON.stringify({ instrumentedNodeIds: recorded, outputPath }));
'@
            $traceFile = Join-Path $PSScriptRoot 'reference\notepad.trace.js'
            $traceResultJson = & $node -e $traceCompiler $tsSource $traceFile
            if ($LASTEXITCODE -ne 0) { throw 'Expression trace compilation failed.' }
            $traceCompilerResult = $traceResultJson | ConvertFrom-Json -Depth 20
            $traceCompilerResult | Export-Clixml (Join-Path $EvidenceDirectory 'typescript-trace-map.clixml')
            $builtHtml = Get-CdpValue $browser @'
(() => {
  const root = document.documentElement.cloneNode(true);
  root.querySelector('#notepad-fluent-styles')?.remove();
  root.querySelector('#notepad-root').replaceChildren();
  const script = root.querySelector('script');
  script.textContent = '';
  script.src = 'notepad.compiled.js';
  return '<!DOCTYPE html>\n' + root.outerHTML;
})()
'@
            [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'reference\notepad.build.html'), $builtHtml, [Text.UTF8Encoding]::new($false))
            $traceHtml = Get-CdpValue $browser @'
(() => {
  const root = document.documentElement.cloneNode(true);
  root.querySelector('#notepad-fluent-styles')?.remove();
  root.querySelector('#notepad-root').replaceChildren();
  const script = root.querySelector('script');
  script.textContent = '';
  script.src = 'notepad.trace.js';
  const bootstrap = document.createElement('script');
  bootstrap.textContent = `
    window.__npTraceRecords = new Map();
    window.__npTraceObjects = new WeakMap();
    window.__npTraceNextObject = 1;
    globalThis.__npTrace = (id, value) => {
      let record = window.__npTraceRecords.get(id);
      if (!record) {
        record = { count: 0, samples: [] };
        window.__npTraceRecords.set(id, record);
      }
      record.count++;
      const type = value === null ? 'null' : Array.isArray(value) ? 'array' : typeof value;
      let sample = { type };
      if (value === null || type === 'undefined') sample.value = null;
      else if (type === 'object' || type === 'array' || type === 'function') {
        if (!window.__npTraceObjects.has(value)) window.__npTraceObjects.set(value, window.__npTraceNextObject++);
        sample.referenceId = window.__npTraceObjects.get(value);
      } else if (type === 'string' && value.length > 2048) {
        sample.length = value.length;
        sample.prefix = value.slice(0, 128);
        sample.valueStatus = 'DIGEST_ONLY';
      } else sample.value = value;
      if (record.samples.length < 4 && !record.samples.some(x => JSON.stringify(x) === JSON.stringify(sample))) record.samples.push(sample);
      return value;
    };
  `;
  script.before(bootstrap);
  return '<!DOCTYPE html>\n' + root.outerHTML;
})()
'@
            [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'reference\notepad.trace.html'), $traceHtml, [Text.UTF8Encoding]::new($false))
        }
        if ($BuildDesign) {
            $designSource = Join-Path $PSScriptRoot 'reference\notepad.design.ts'
            $designOutput = Join-Path $PSScriptRoot 'reference\notepad.design.js'
            $compiler = 'C:\bin\vs\Common7\IDE\CommonExtensions\Microsoft\TSServer\_tsc.js'
            $node = 'C:\bin\node-v26.5.0-win-x64\node.exe'
            $designDiagnostics = @(& $node $compiler --strict --target es2022 --lib dom,es2022 --sourceMap --inlineSources --outFile $designOutput $designSource 2>&1 | ForEach-Object ToString)
            if ($LASTEXITCODE -ne 0) { throw 'Corrected reference TypeScript compilation failed.' }
            $designCompilation = [pscustomobject]@{
                CompilerVersion = (& $node $compiler --version)
                CompilerSHA256 = (Get-FileHash $compiler -Algorithm SHA256).Hash
                SourceSHA256 = (Get-FileHash $designSource -Algorithm SHA256).Hash
                OutputSHA256 = (Get-FileHash $designOutput -Algorithm SHA256).Hash
                SourceMapSHA256 = (Get-FileHash ($designOutput + '.map') -Algorithm SHA256).Hash
                Diagnostics = $designDiagnostics
                TimeUtc = [datetime]::UtcNow
            }
            $designCompilation | Export-Clixml (Join-Path $EvidenceDirectory 'design-compilation.clixml')
            if ($BuildTypeScript) {
                $designSemanticsJson = & $node -e $semanticProbe $designSource $designOutput
                if ($LASTEXITCODE -ne 0) { throw 'Corrected reference semantic extraction failed.' }
                ($designSemanticsJson | ConvertFrom-Json -Depth 100) |
                    Export-Clixml (Join-Path $EvidenceDirectory 'design-node-semantics.clixml')
            }
            $originalManifest = Import-Clixml (Join-Path $PSScriptRoot 'original-sha256.clixml')
            $originalEntry = $originalManifest | Where-Object RelativePath -eq 'reference\notepad.html'
            $currentReference = Join-Path $PSScriptRoot 'reference\notepad.html'
            $currentHash = (Get-FileHash $currentReference -Algorithm SHA256).Hash
            if ($currentHash -ne $originalEntry.SHA256 -and $currentHash -ne (Get-FileHash (Join-Path $PSScriptRoot 'reference\notepad.html.original') -Algorithm SHA256).Hash) {
                # A previously generated reference may be updated, but an unrecognized edit is preserved.
                $generatedHashFile = Join-Path $EvidenceDirectory 'generated-reference-hash.clixml'
                if (-not (Test-Path $generatedHashFile) -or $currentHash -ne (Import-Clixml $generatedHashFile).SHA256) {
                    throw 'The current reference differs from both the original and the last instrument build.'
                }
            }
            $designHtml = Get-CdpValue $browser @'
(() => {
  const root = document.documentElement.cloneNode(true);
  root.querySelector('#notepad-fluent-styles')?.remove();
  const appRoot = root.querySelector('#notepad-root');
  appRoot.before(document.createComment('MansfieldPlumbing feature additions in the corrected reference: window backdrop, corner style, and whole-document Copy with a text-or-file setting.'));
  appRoot.replaceChildren();
  const script = root.querySelector('script');
  script.textContent = '';
  script.src = 'notepad.design.js';
  return '<!DOCTYPE html>\n' + root.outerHTML;
})()
'@
            [IO.File]::WriteAllText($currentReference, $designHtml, [Text.UTF8Encoding]::new($false))
            [pscustomobject]@{ SHA256 = (Get-FileHash $currentReference -Algorithm SHA256).Hash; TimeUtc = [datetime]::UtcNow } |
                Export-Clixml (Join-Path $EvidenceDirectory 'generated-reference-hash.clixml')
        }
        $states = [Collections.Generic.List[object]]::new()
        $states.Add((Save-BrowserState $browser 'original-empty' $EvidenceDirectory))
        $editorRect = Get-CdpValue $browser @'
(() => { const r = document.querySelector('textarea').getBoundingClientRect(); return { x: r.x + 30, y: r.y + 30 }; })()
'@
        foreach ($eventType in @('mousePressed', 'mouseReleased')) {
            $null = Invoke-Cdp $browser 'Input.dispatchMouseEvent' @{
                type = $eventType; x = $editorRect.x; y = $editorRect.y
                button = 'left'; clickCount = 1
            }
        }
        $null = Invoke-Cdp $browser 'Input.insertText' @{ text = 'Notepad comparison sample' }
        $states.Add((Save-BrowserState $browser 'original-typed' $EvidenceDirectory))
        Add-BrowserReplayStates $browser 'original' $EvidenceDirectory $states
        $browserEvidence = [pscustomobject]@{
            Metadata = [pscustomobject]@{
                EdgeVersion = (Get-Item 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe').VersionInfo.FileVersion
                SourceSHA256 = (Get-FileHash $originalPath -Algorithm SHA256).Hash
                TypeScriptCompilerVersion = (& 'C:\bin\node-v26.5.0-win-x64\node.exe' 'C:\bin\vs\Common7\IDE\CommonExtensions\Microsoft\TSServer\_tsc.js' --version)
                TypeScriptCompilerSHA256 = (Get-FileHash 'C:\bin\vs\Common7\IDE\CommonExtensions\Microsoft\TSServer\_tsc.js' -Algorithm SHA256).Hash
                TimeUtc = [datetime]::UtcNow
            }
            States = $states.ToArray()
        }
        $browserEvidence | Export-Clixml (Join-Path $EvidenceDirectory 'original-edge.clixml')
        $states | Select-Object Name,ImageSHA256,Image
    } finally {
        Close-EdgePage $browser
    }
    if ($BuildTypeScript) {
        $built = Connect-EdgePage (Join-Path $PSScriptRoot 'reference\notepad.build.html')
        try {
            $null = Invoke-Cdp $built 'Page.enable'
            $null = Invoke-Cdp $built 'Runtime.enable'
            $null = Invoke-Cdp $built 'Emulation.setDeviceMetricsOverride' @{
                width = 768; height = 478; deviceScaleFactor = 1; mobile = $false
            }
            Start-BrowserCoverage $built
            $builtStates = [Collections.Generic.List[object]]::new()
            $builtStates.Add((Save-BrowserState $built 'built-empty' $EvidenceDirectory))
            $rect = Get-CdpValue $built @'
(() => { const r = document.querySelector('textarea').getBoundingClientRect(); return { x: r.x + 30, y: r.y + 30 }; })()
'@
            foreach ($eventType in @('mousePressed', 'mouseReleased')) {
                $null = Invoke-Cdp $built 'Input.dispatchMouseEvent' @{
                    type = $eventType; x = $rect.x; y = $rect.y
                    button = 'left'; clickCount = 1
                }
            }
            $null = Invoke-Cdp $built 'Input.insertText' @{ text = 'Notepad comparison sample' }
            $builtStates.Add((Save-BrowserState $built 'built-typed' $EvidenceDirectory))
            Add-BrowserReplayStates $built 'built' $EvidenceDirectory $builtStates
            $builtStates.ToArray() | Export-Clixml (Join-Path $EvidenceDirectory 'built-edge.clixml')
            $originalStates = (Import-Clixml (Join-Path $EvidenceDirectory 'original-edge.clixml')).States
            $equivalenceRows = [Collections.Generic.List[object]]::new()
            for ($i=0; $i -lt $builtStates.Count; $i++) {
                $domEqual = (ConvertTo-Json $originalStates[$i].DomState -Depth 30 -Compress) -ceq
                    (ConvertTo-Json $builtStates[$i].DomState -Depth 30 -Compress)
                $appEqual = (ConvertTo-Json $originalStates[$i].AppState -Depth 30 -Compress) -ceq
                    (ConvertTo-Json $builtStates[$i].AppState -Depth 30 -Compress)
                $row = [pscustomobject]@{
                    Command = $builtStates[$i].Name
                    DomEqual = $domEqual
                    AppStateEqual = $appEqual
                    PixelsEqual = $originalStates[$i].ImageSHA256 -ceq $builtStates[$i].ImageSHA256
                }
                $equivalenceRows.Add($row)
                $row
            }
            $equivalenceRows.ToArray() | Export-Clixml (Join-Path $EvidenceDirectory 'refactor-equivalence.clixml')
            if ($equivalenceRows | Where-Object { -not ($_.DomEqual -and $_.AppStateEqual -and $_.PixelsEqual) }) {
                throw 'The TypeScript build differs from the original browser oracle.'
            }
            $ledger = Import-Clixml (Join-Path $EvidenceDirectory 'typescript-node-semantics.clixml')
            $rangesByStep = @{}
            foreach ($step in $builtStates) {
                $rangesByStep[$step.Name] = @($step.Coverage | ForEach-Object { $_.Functions } | ForEach-Object { $_.Ranges })
            }
            foreach ($nodeRecord in $ledger.nodes) {
                $observations = [Collections.Generic.List[object]]::new()
                foreach ($step in $builtStates) {
                    $ranges = $rangesByStep[$step.Name]
                    $best = $null
                    foreach ($offset in $nodeRecord.generatedOffsets) {
                        foreach ($range in $ranges) {
                            if ($offset -ge $range.startOffset -and $offset -lt $range.endOffset) {
                                if (-not $best -or ($range.endOffset-$range.startOffset) -lt ($best.endOffset-$best.startOffset)) {
                                    $best = $range
                                }
                            }
                        }
                    }
                    $observations.Add([pscustomobject]@{
                        ReplayStep = $step.Name
                        Coverage = if ($nodeRecord.generatedOffsets.Count -eq 0) { 'UNMAPPED' }
                            elseif ($best -and $best.count -gt 0) { 'EXECUTED' }
                            else { 'NOT_EXECUTED' }
                        RuntimeValue = $null
                        RuntimeType = $null
                        ValueStatus = 'UNKNOWN'
                    })
                }
                $nodeRecord.runtime = $observations.ToArray()
            }
            $ledger | Export-Clixml (Join-Path $EvidenceDirectory 'typescript-node-semantics.clixml')
        } finally {
            Close-EdgePage $built
        }
    }
    if ($BuildTypeScript) {
        $traced = Connect-EdgePage (Join-Path $PSScriptRoot 'reference\notepad.trace.html')
        $traced | Add-Member -NotePropertyName Trace -NotePropertyValue $true
        try {
            $null = Invoke-Cdp $traced 'Page.enable'
            $null = Invoke-Cdp $traced 'Runtime.enable'
            $null = Invoke-Cdp $traced 'Emulation.setDeviceMetricsOverride' @{
                width = 768; height = 478; deviceScaleFactor = 1; mobile = $false
            }
            Start-BrowserCoverage $traced
            $traceStates = [Collections.Generic.List[object]]::new()
            $traceStates.Add((Save-BrowserState $traced 'trace-empty' $EvidenceDirectory))
            Click-CdpSelector $traced 'textarea'
            $null = Invoke-Cdp $traced 'Input.insertText' @{ text = 'Notepad comparison sample' }
            $traceStates.Add((Save-BrowserState $traced 'trace-typed' $EvidenceDirectory))
            Add-BrowserReplayStates $traced 'trace' $EvidenceDirectory $traceStates
            $traceStates.ToArray() | Export-Clixml (Join-Path $EvidenceDirectory 'trace-edge.clixml')
            $traceVerdicts = [Collections.Generic.List[object]]::new()
            for ($i=0; $i -lt $traceStates.Count; $i++) {
                $row = [pscustomobject]@{
                    Step = $traceStates[$i].Name
                    DomEqual = (ConvertTo-Json $builtStates[$i].DomState -Depth 30 -Compress) -ceq
                        (ConvertTo-Json $traceStates[$i].DomState -Depth 30 -Compress)
                    AppStateEqual = (ConvertTo-Json $builtStates[$i].AppState -Depth 30 -Compress) -ceq
                        (ConvertTo-Json $traceStates[$i].AppState -Depth 30 -Compress)
                    PixelsEqual = $builtStates[$i].ImageSHA256 -ceq $traceStates[$i].ImageSHA256
                }
                $traceVerdicts.Add($row)
            }
            $traceVerdicts.ToArray() | Export-Clixml (Join-Path $EvidenceDirectory 'trace-equivalence.clixml')
            $traceVerdicts | Format-Table -AutoSize
            $traceTrusted = -not @($traceVerdicts | Where-Object { -not ($_.DomEqual -and $_.AppStateEqual -and $_.PixelsEqual) }).Count
            $ledger = Import-Clixml (Join-Path $EvidenceDirectory 'typescript-node-semantics.clixml')
            for ($i=0; $i -lt $traceStates.Count; $i++) {
                $records = $traceStates[$i].NodeRuntime
                foreach ($nodeRecord in $ledger.nodes) {
                    $property = $records.PSObject.Properties[$nodeRecord.id]
                    if (-not $property) { continue }
                    $observation = $nodeRecord.runtime[$i]
                    $observation | Add-Member -NotePropertyName TraceCount -NotePropertyValue $property.Value.count -Force
                    $observation.RuntimeValue = @($property.Value.samples)
                    $observation.RuntimeType = @($property.Value.samples | ForEach-Object type | Select-Object -Unique)
                    $observation.ValueStatus = if (-not $traceTrusted) { 'UNTRUSTED_TRACE' }
                        elseif (@($property.Value.samples | Where-Object { $_.PSObject.Properties['valueStatus'] -and $_.valueStatus -eq 'DIGEST_ONLY' }).Count) { 'PARTIAL_VALUE' }
                        elseif (@($property.Value.samples | Where-Object { $_.PSObject.Properties['referenceId'] }).Count) { 'IDENTITY_ONLY' }
                        else { 'OBSERVED' }
                }
            }
            foreach ($nodeRecord in $ledger.nodes) {
                $checks = [Collections.Generic.List[string]]::new()
                foreach ($observation in $nodeRecord.runtime) {
                    if ($observation.ValueStatus -ne 'OBSERVED') { continue }
                    foreach ($sample in $observation.RuntimeValue) {
                        $checks.Add((Compare-PrimitiveType $nodeRecord.narrowedType $sample))
                    }
                }
                $verdict = if ($checks.Contains('DISAGREE')) { 'PERCEPT' }
                    elseif ($checks.Count -gt 0 -and -not $checks.Contains('UNKNOWN') -and $nodeRecord.emitted.Count -gt 0) { 'TRUE' }
                    else { 'UNKNOWN' }
                $nodeRecord | Add-Member -NotePropertyName Verdict -NotePropertyValue $verdict -Force
            }
            $ledger | Export-Clixml (Join-Path $EvidenceDirectory 'typescript-node-semantics.clixml')
        } finally {
            Close-EdgePage $traced
        }
    }
    $designHashRecord = Join-Path $EvidenceDirectory 'generated-reference-hash.clixml'
    $designPath = Join-Path $PSScriptRoot 'reference\notepad.html'
    if ((Test-Path $designHashRecord) -and
        (Get-FileHash $designPath -Algorithm SHA256).Hash -eq (Import-Clixml $designHashRecord).SHA256) {
        $designBrowser = Connect-EdgePage $designPath
        try {
            $null = Invoke-Cdp $designBrowser 'Page.enable'
            $null = Invoke-Cdp $designBrowser 'Runtime.enable'
            $null = Invoke-Cdp $designBrowser 'Emulation.setDeviceMetricsOverride' @{
                width = 768; height = 478; deviceScaleFactor = 1; mobile = $false
            }
            Start-BrowserCoverage $designBrowser
            $designStates = [Collections.Generic.List[object]]::new()
            $designStates.Add((Save-BrowserState $designBrowser 'design-empty' $EvidenceDirectory))
            Click-CdpSelector $designBrowser 'textarea'
            $null = Invoke-Cdp $designBrowser 'Input.insertText' @{ text='Notepad comparison sample' }
            $designStates.Add((Save-BrowserState $designBrowser 'design-typed' $EvidenceDirectory))
            Add-BrowserReplayStates $designBrowser 'design' $EvidenceDirectory $designStates
            [pscustomobject]@{
                Metadata = [pscustomobject]@{
                    ReferenceSHA256 = (Get-FileHash $designPath -Algorithm SHA256).Hash
                    SourceSHA256 = (Get-FileHash (Join-Path $PSScriptRoot 'reference\notepad.design.ts') -Algorithm SHA256).Hash
                    TimeUtc = [datetime]::UtcNow
                }
                States = $designStates.ToArray()
            } | Export-Clixml (Join-Path $EvidenceDirectory 'design-edge.clixml')
            $designStates | Select-Object Name,ImageSHA256
            # Feature addition probe: the whole-document Copy action must ignore selection.
            $copyProbe = Get-CdpValue $designBrowser @'
(() => {
  window.__copyProbe = { value: null, calls: 0 };
  Object.defineProperty(navigator, 'clipboard', {
    configurable: true,
    value: { writeText: async value => {
      window.__copyProbe.value = value;
      window.__copyProbe.calls++;
    } }
  });
  const editor = document.querySelector('textarea');
  editor.value = 'Whole document for LLM\nSecond line';
  editor.dispatchEvent(new Event('input', { bubbles: true }));
  editor.setSelectionRange(0, 5);
  return { selected: editor.value.slice(editor.selectionStart, editor.selectionEnd) };
})()
'@
            Click-CdpSelector $designBrowser '#btn-copy-document'
            $copied = Get-CdpValue $designBrowser 'window.__copyProbe'
            $copyTextCapture = Save-BrowserState $designBrowser 'design-copy-text' $EvidenceDirectory
            $copyResult = [pscustomobject]@{
                Scenario = 'Whole active document despite partial selection'
                SelectedText = $copyProbe.selected
                Expected = "Whole document for LLM`nSecond line"
                Actual = $copied.value
                Calls = $copied.calls
                Verdict = if ($copied.calls -eq 1 -and $copied.value -ceq "Whole document for LLM`nSecond line") { 'TRUE' } else { 'FALSE' }
            }
            $copyResult | Export-Clixml (Join-Path $EvidenceDirectory 'design-copy-probe.clixml')
            if ($copyResult.Verdict -ne 'TRUE') { throw 'Whole-document Copy probe failed.' }
            Click-CdpSelector $designBrowser '#btn-settings-toggle'
            $null = Get-CdpValue $designBrowser "document.querySelector('#toggle-setting-copy-mode').scrollIntoView({ block: 'center' })"
            Click-CdpSelector $designBrowser '#toggle-setting-copy-mode'
            $fileModeState = Get-BrowserAppState $designBrowser
            Click-CdpSelector $designBrowser '#settings-btn-back'
            $fileModeButton = Get-CdpValue $designBrowser "document.querySelector('#btn-copy-document').getAttribute('aria-label')"
            Click-CdpSelector $designBrowser '#btn-copy-document'
            $copyFileCapture = Save-BrowserState $designBrowser 'design-copy-file' $EvidenceDirectory
            $fileModeDialog = Get-CdpValue $designBrowser @'
(() => ({
  title: document.querySelector('#dialog-title-text')?.textContent ?? '',
  text: document.querySelector('.fluent-dialog')?.textContent ?? ''
}))()
'@
            $fileModeResult = [pscustomobject]@{
                Scenario = 'Whole-document .txt file mode design contract'
                Mode = $fileModeState.settings.copyMode
                Button = $fileModeButton
                DialogTitle = $fileModeDialog.title
                BrowserPreviewNotice = $fileModeDialog.text
                Verdict = if ($fileModeState.settings.copyMode -eq 'file' -and $fileModeButton -eq 'Copy whole document as .txt file' -and $fileModeDialog.text -like '*native Notepad-PS1 renderer*') { 'TRUE' } else { 'FALSE' }
            }
            $fileModeResult | Export-Clixml (Join-Path $EvidenceDirectory 'design-copy-file-mode-probe.clixml')
            @($copyTextCapture, $copyFileCapture) | Export-Clixml (Join-Path $EvidenceDirectory 'design-copy-captures.clixml')
            if ($fileModeResult.Verdict -ne 'TRUE') { throw 'Whole-document .txt file mode probe failed.' }
        } finally {
            Close-EdgePage $designBrowser
        }
    }
}

$nativeProcess = Start-Process -FilePath 'C:\bin\pwsh\pwsh.exe' -ArgumentList @(
    '-NoProfile', '-STA', '-File', ('"' + (Join-Path $PSScriptRoot 'Notepad.ps1') + '"'),
    '-NoSession', '-NoAnimation', '-RunSeconds', '15', '-Width', '768', '-Height', '478'
) -PassThru
try {
    $nativeHandle = [IntPtr]::Zero
    for ($attempt = 0; $attempt -lt 100; $attempt++) {
        Start-Sleep -Milliseconds 100
        $nativeProcess.Refresh()
        if ($nativeProcess.HasExited) { throw "Notepad.ps1 exited with $($nativeProcess.ExitCode)." }
        $nativeHandle = Get-NativeAppWindowHandle $nativeProcess.Id
        if ($nativeHandle -ne [IntPtr]::Zero) { break }
    }
    if ($nativeHandle -eq [IntPtr]::Zero) { throw 'Notepad.ps1 did not expose its native app window through UIA.' }
    $nativeImage = Join-Path $EvidenceDirectory 'ps1-empty.png'
    Save-WindowImage $nativeHandle $nativeImage 768 478
    $nativeEvidence = [pscustomobject]@{
        Metadata = [pscustomobject]@{
            SourceSHA256 = (Get-FileHash (Join-Path $PSScriptRoot 'Notepad.ps1') -Algorithm SHA256).Hash
            TimeUtc = [datetime]::UtcNow
            WidthRequested = 768
            HeightRequested = 478
            NoSession = $true
        }
        States = @([pscustomobject]@{
            Name = 'empty'
            Image = $nativeImage
            ImageSHA256 = (Get-FileHash $nativeImage -Algorithm SHA256).Hash
        })
    }
    $nativeEvidence | Export-Clixml (Join-Path $EvidenceDirectory 'ps1-render.clixml')
    $nativeEvidence.States | Select-Object Name,ImageSHA256,Image
} finally {
    $nativeProcess.Refresh()
    if (-not $nativeProcess.HasExited) { $nativeProcess.Kill() }
}

$paths = [ordered]@{
    Real = Join-Path $EvidenceDirectory 'real-empty.png'
    Reference = Join-Path $EvidenceDirectory $(if (Test-Path (Join-Path $EvidenceDirectory 'design-edge.clixml')) { 'design-empty.png' } else { 'original-empty.png' })
    PS1 = Join-Path $EvidenceDirectory 'ps1-empty.png'
}
$measures = [ordered]@{}
foreach ($bearing in $paths.Keys) {
    if (Test-Path $paths[$bearing]) { $measures[$bearing] = Get-ImageMeasurements $paths[$bearing] }
}
$rows = [Collections.Generic.List[object]]::new()
foreach ($property in $predictions.Keys) {
    $values = @($paths.Keys | ForEach-Object { if ($measures.Contains($_)) { $measures[$_].$property } })
    $verdict = if ($values.Count -ne 3) { 'UNKNOWN' }
        elseif (@($values | Select-Object -Unique).Count -eq 1) { 'TRUE' }
        elseif (@($values | Select-Object -Unique).Count -eq 2) { 'CONTESTED' }
        else { 'FALSE' }
    $rows.Add([pscustomobject]@{
        Property = $property
        Prediction = $predictions[$property]
        Real = if ($measures.Contains('Real')) { $measures.Real.$property } else { $null }
        Reference = if ($measures.Contains('Reference')) { $measures.Reference.$property } else { $null }
        PS1 = if ($measures.Contains('PS1')) { $measures.PS1.$property } else { $null }
        Verdict = $verdict
    })
}
foreach ($property in @('TypeScale','IconGeometry','CornerRadii','Elevation','MotionTiming','Mica','Acrylic','ReverseMica')) {
    $rows.Add([pscustomobject]@{ Property=$property; Prediction='Unmeasured'; Real=$null; Reference=$null; PS1=$null; Verdict='UNKNOWN' })
}
$rows.ToArray() | Export-Clixml (Join-Path $EvidenceDirectory 'comparison-table.clixml')
$rows | Format-Table -AutoSize

}
if ($Compare) {
    Invoke-NotepadComparison -EvidenceDirectory $EvidenceDirectory -RefreshReal:$RefreshReal -SkipBrowser:$SkipBrowser -KeepProbeOpen:$KeepProbeOpen -ExtractTypeScript:$ExtractTypeScript -BuildTypeScript:$BuildTypeScript -BuildDesign:$BuildDesign -VerifyNativeFeatures:$VerifyNativeFeatures -CatalogIcons:$CatalogIcons
    return
}
$design=& "$PSScriptRoot\src\Design.ps1"
$settings=$design.DefaultSettings.Clone()
$settings.backdrop='mica';$settings.cornerStyle='curved';$settings.copyAsFile=$false
$settings.backgroundOpacity=85;$settings.gradientEnabled=$false
$settings.colors=@{foreground='';tabs='';cursor='';selectionBackground='';topLeft='#272727';topRight='#272727';bottomLeft='#272727';bottomRight='#272727'}
$settings.ansiColors=@('#0C0C0C','#C50F1F','#13A10E','#C19C00','#0037DA','#881798','#3A96DD','#CCCCCC','#767676','#E74856','#16C60C','#F9F1A5','#3B78FF','#B4009E','#61D6D6','#F2F2F2')
$settings.windowIcon='default'
$store=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'NotepadPS1'
if(-not $NoSession -and (Test-Path "$store\settings.json")){
    try{$saved=Get-Content "$store\settings.json" -Raw|ConvertFrom-Json -AsHashtable;foreach($key in $settings.Keys.Clone()){if($saved.ContainsKey($key)){$settings[$key]=$saved[$key]}}}catch{Write-Warning 'Saved settings could not be loaded; using defaults.'}
}
if($Backdrop){$settings.backdrop=$Backdrop};if($CornerStyle){$settings.cornerStyle=$CornerStyle}
$model=& "$PSScriptRoot\src\Model.ps1" -Settings $settings
$state=$model.State()
if(-not $NoSession -and $settings.startupOption -eq 'continueSession' -and (Test-Path "$store\session.json")){
    try{$model.ImportSession((Get-Content "$store\session.json" -Raw|ConvertFrom-Json -AsHashtable))}catch{Write-Warning 'Saved session could not be restored.'}
}
if(-not $state.Tabs.Count){$null=$model.NewTab()}
if($Path){$null=$model.Open($Path);if($state.Tabs[0].Text -eq '' -and $state.Tabs.Count -eq 2){$model.CloseTab($state.Tabs[0].Id)}}
$native=& "$PSScriptRoot\src\Native.ps1"
$window=$null;$graphics=$null;$services=$null
$ui=@{Dirty=$true;Running=$true;Hover='';Pressed='';Focus='editor-area';Menu='';Submenu='';Settings=$false;Expanded=@{};SettingsScroll=0.0;Find=$false;Replace=$false;Modal=$null;Dropdown=$null;Drag=$false;Blink=$true;LastBlink=[DateTime]::UtcNow;LastSession=[DateTime]::UtcNow;Width=0.0;Height=0.0;Dpi=96.0;Generation=0;Nodes=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal);Hits=[Collections.Generic.List[object]]::new();NextHits=$null;TextCache=@{};EditorLayout=[IntPtr]::Zero;EditorKey='';EditorOrigin=@(16.0,92.0);EditorRect=@(0,78,1280,614);EditorMetrics=@{};EnsureCaret=$true;InputAnchor=0;InputFocus=0;InputBuffers=@{};PendingHigh='';Focused=$true}
$palette=@{}
$ui.ComparisonView=$false;$ui.ComparisonScroll=0.0;$ui.ComparisonProcess=$null
$ui.ComparisonRows=@();$ui.ComparisonStatus='Ready';$ui.ComparisonLastPoll=[DateTime]::MinValue
$ui.ClickSequence=0
$ui.ScrollSequence=0
$ui.EntranceStatus='Pending';$ui.EntranceSamples=[Collections.Generic.List[object]]::new()
$ui.HoverSince=[DateTime]::UtcNow;$ui.TooltipShown=$false
$ui.Minimized=$false
$ui.SliderDrag=$false
$ui.ColorPicker=$null;$ui.ColorDrag=''
if($StartPage -ne 'editor'){$ui.Settings=$true;$ui.Focus='settings';$ui.ComparisonView=$StartPage -eq 'comparison'}
function Load-ComparisonResults {
    $file=Join-Path $EvidenceDirectory 'comparison-table.clixml'
    if(Test-Path -LiteralPath $file){try{$ui.ComparisonRows=@(Import-Clixml -LiteralPath $file)}catch{$ui.ComparisonStatus='The saved comparison could not be read.'}}
}
function Start-Comparison([bool]$Refresh=$false){
    if($ui.ComparisonProcess -and -not $ui.ComparisonProcess.HasExited){return}
    New-Item -ItemType Directory -Path $EvidenceDirectory -Force|Out-Null
    $runId=[DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8)
    $ui.ComparisonLog=Join-Path $EvidenceDirectory ($runId+'-comparison.log')
    $ui.ComparisonError=Join-Path $EvidenceDirectory ($runId+'-comparison-error.log')
    $arguments=@('-NoProfile','-STA','-File',('"'+$PSCommandPath+'"'),'-Compare','-EvidenceDirectory',('"'+$EvidenceDirectory+'"'))
    if($Refresh){$arguments+='-RefreshReal'}
    try{
        $ui.ComparisonProcess=Start-Process -FilePath (Join-Path $PSHOME 'pwsh.exe') -ArgumentList $arguments -WindowStyle Hidden -RedirectStandardOutput $ui.ComparisonLog -RedirectStandardError $ui.ComparisonError -PassThru
        $ui.ComparisonStatus=if($Refresh){'Capturing a fresh Windows Notepad baseline...'}else{'Comparing with the saved Windows Notepad baseline...'}
    }catch{$ui.ComparisonStatus='Could not start comparison: '+$_.Exception.Message}
    Invalidate
}
function Update-Comparison {
    if(-not $ui.ComparisonProcess -or ([DateTime]::UtcNow-$ui.ComparisonLastPoll).TotalMilliseconds -lt 250){return}
    $ui.ComparisonLastPoll=[DateTime]::UtcNow;$ui.ComparisonProcess.Refresh()
    if(-not $ui.ComparisonProcess.HasExited){return}
    $exitCode=$ui.ComparisonProcess.ExitCode;$ui.ComparisonProcess.Dispose();$ui.ComparisonProcess=$null
    if($exitCode -eq 0){Load-ComparisonResults;$ui.ComparisonStatus='Comparison complete. Results are measured from the saved evidence.'}
    else{$ui.ComparisonStatus='Comparison failed. The previous results remain visible; see '+[IO.Path]::GetFileName($ui.ComparisonError)}
    Invalidate
}
function Write-ApplicationDiagnostic {
    if(-not $DiagnosticPath){return}
    $snapshot=@{Generation=$ui.Generation;ClickSequence=$ui.ClickSequence;Width=$ui.Width;Height=$ui.Height;Dpi=$ui.Dpi;Theme=$ui.Theme;Focus=$ui.Focus;Settings=$settings;SettingsOpen=$ui.Settings;ComparisonOpen=$ui.ComparisonView;ComparisonStatus=$ui.ComparisonStatus;Appearance=$ui.Appearance;AppearanceError=$ui.AppearanceError;EditorMetrics=$ui.EditorMetrics;Status=$model.Status();Nodes=@($ui.Hits|ForEach-Object{@{Id=$_.Id;Rect=$_.Rect;Action=$_.Action;Data=$_.Data;Generation=$_.Generation}});Session=$model.ExportSession()}
    $snapshot.Entrance=$ui.Entrance;$snapshot.EntranceStatus=$ui.EntranceStatus;$snapshot.EntranceSamples=$ui.EntranceSamples.ToArray()
    $snapshot.EntranceRestore=$ui.EntranceRestore
    $snapshot.Minimized=$ui.Minimized
    $snapshot.ScrollSequence=$ui.ScrollSequence
    $snapshot.ColorPicker=$ui.ColorPicker
    $temporary=$DiagnosticPath+'.'+$PID+'.tmp'
    try{[IO.File]::WriteAllText($temporary,($snapshot|ConvertTo-Json -Depth 32),[Text.UTF8Encoding]::new($false));[IO.File]::Move($temporary,$DiagnosticPath,$true)}
    catch [IO.IOException] {return} catch [UnauthorizedAccessException] {return}
}
function Cubic-Value([double]$A,[double]$B,[double]$C,[double]$D,[double]$T){
    $u=1-$T;return $u*$u*$u*$A+3*$u*$u*$T*$B+3*$u*$T*$T*$C+$T*$T*$T*$D
}
function Entrance-Easing([double]$Progress){
    $lo=0.0;$hi=1.0
    for($i=0;$i -lt 20;$i++){$mid=($lo+$hi)/2;if((Cubic-Value 0 0.2 0 1 $mid) -lt $Progress){$lo=$mid}else{$hi=$mid}}
    Cubic-Value 0 0 1 1 (($lo+$hi)/2)
}
function Resolve-Theme {
    $theme=$settings.theme
    if($theme -eq 'system'){$value=Get-ItemPropertyValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -ErrorAction SilentlyContinue;$theme=if($value -eq 1){'light'}else{'dark'}}
    $script:palette=@{}
    foreach($rule in $design.Styles.Rules){if($rule.Header -eq ':root' -or ($theme -eq 'light' -and $rule.Header -eq '[data-theme="light"]')){foreach($declaration in $rule.Declarations){$palette[$declaration.Property]=$declaration.Value}}}
    if($theme -eq 'dark'){$palette['--bg-window']='#202020';$palette['--bg-titlebar']='#202020';$palette['--bg-menubar']='#2c2c2c';$palette['--bg-editor']='#272727';$palette['--bg-statusbar']='#2c2c2c'}
    $ui.Theme=$theme;$ui.Dirty=$true
}
function Apply-WindowAppearance {
    if(-not $window -or -not $graphics){return}
    try{
        $ui.Appearance=$window.Appearance($settings.backdrop,($ui.Theme -eq 'dark'),($settings.cornerStyle -eq 'curved'))
        $ui.BackdropActive=$true;$ui.AppearanceError=''
    }catch{$ui.BackdropActive=$false;$ui.AppearanceError=$_.Exception.Message}
    $graphics.CornerStyle(($settings.cornerStyle -eq 'curved'));Invalidate
}
function Initialize-IconCatalog {
    if($ui.IconCatalog){return}
    $path=Join-Path $EvidenceDirectory 'windows-icon-catalog.clixml'
    if(Test-Path -LiteralPath $path){try{$ui.IconCatalog=@((Import-Clixml -LiteralPath $path).CycleIcons)}catch{$ui.IconCatalog=@()}}
    if(-not $ui.IconCatalog){$ui.IconCatalog=@(foreach($id in @(32512,32516,32515,32513,32514,32517,32518)){[pscustomobject]@{Key=('standard:'+$id);Kind='standard';Id=$id}})}
}
function Apply-WindowIcon {
    if(-not $window -or -not $graphics){return}
    $ui.WindowIconHandle=[IntPtr]::Zero
    if($settings.windowIcon -eq 'default'){$null=$window.SelectIcon('standard',32512);return}
    Initialize-IconCatalog
    $entry=$ui.IconCatalog|Where-Object Key -eq $settings.windowIcon|Select-Object -First 1
    if($entry){$ui.WindowIconHandle=$window.SelectIcon($entry.Kind,[int]$entry.Id)}
    else{$settings.windowIcon='default';$null=$window.SelectIcon('standard',32512)}
}
function Paint-AppIcon([string]$Id,[double]$X,[double]$Y,[double]$Size){
    if($ui.WindowIconHandle -and $ui.WindowIconHandle -ne [IntPtr]::Zero -and $settings.windowIcon -ne 'default'){$graphics.NativeIcon($ui.WindowIconHandle,$settings.windowIcon,$X,$Y,$Size)}else{Icon 'app' $X $Y $Size}
    Node $Id ($X-5) ($Y-5) ($Size+10) ($Size+10) 'cycleIcon' $settings.windowIcon
}
function Color([string]$Name){$palette['--'+$Name]}
function Role-Color([string]$Role){
    if($settings.colors[$Role]){return $settings.colors[$Role]}
    switch($Role){'foreground'{Color 'text-primary'};'tabs'{Color 'bg-tab-active'};'cursor'{Color 'text-primary'};'selectionBackground'{Color 'selection-bg'};default{'#272727'}}
}
function Surface-Color([string]$Name,[double]$Opacity=-1){
    $color=Color $Name
    if(-not $ui.BackdropActive){return $color}
    if($Opacity -lt 0){$Opacity=[int]$settings.backgroundOpacity/100.0}
    $hex=$color.TrimStart('#');if($hex.Length -ne 6){return $color}
    $alpha=[Math]::Clamp($Opacity,0.0,1.0).ToString('0.###',[Globalization.CultureInfo]::InvariantCulture)
    'rgba('+[Convert]::ToInt32($hex.Substring(0,2),16)+','+[Convert]::ToInt32($hex.Substring(2,2),16)+','+[Convert]::ToInt32($hex.Substring(4,2),16)+','+$alpha+')'
}
function Set-OpacityFromPoint([double]$X){
    if(-not $ui.OpacityTrack){return}
    $settings.backgroundOpacity=[int][Math]::Clamp([Math]::Round(($X-$ui.OpacityTrack[0])/$ui.OpacityTrack[2]*100),0,100)
    Invalidate
}
function Persist {
    if($NoSession){return}
    New-Item -ItemType Directory -Path $store -Force|Out-Null
    foreach($item in @(@{Name='settings';Value=$settings},@{Name='session';Value=$(if($settings.startupOption -eq 'continueSession'){$model.ExportSession()}else{@{Tabs=@()}})})){
        $temporary=Join-Path $store ($item.Name+'.tmp');$destination=Join-Path $store ($item.Name+'.json')
        [IO.File]::WriteAllText($temporary,($item.Value|ConvertTo-Json -Depth 32),[Text.UTF8Encoding]::new($false));[IO.File]::Move($temporary,$destination,$true)
    }
}
function Invalidate([bool]$Caret=$false){$ui.Dirty=$true;if($Caret){$ui.EnsureCaret=$true;$ui.Blink=$true;$ui.LastBlink=[DateTime]::UtcNow}}
function Node([string]$Id,[double]$X,[double]$Y,[double]$W,[double]$H,[string]$Action,[object]$Data=$null,[string]$Cursor='pointer'){
    if(-not $ui.Nodes.ContainsKey($Id)){$ui.Nodes[$Id]=@{Id=$Id}}
    $node=$ui.Nodes[$Id];$node.Rect=@($X,$Y,$W,$H);$node.Action=$Action;$node.Data=$Data;$node.Cursor=$Cursor;$node.Generation=$ui.Generation+1;$node.Clip=$ui.HitClip
    $ui.NextHits.Add($node.Clone())
}
function Label([string]$Text,[double]$X,[double]$Y,[double]$W,[string]$Color,[double]$Size=13,[string]$Family='Segoe UI',[int]$Weight=400){
    $key="$Text|$W|$Size|$Family|$Weight"
    if(-not $ui.TextCache.ContainsKey($key)){$ui.TextCache[$key]=$graphics.Layout($Text,$Family,[single]$Size,[single][Math]::Max(1,$W),$false,$Weight,$false,0)}
    $graphics.DrawLayout($ui.TextCache[$key],[single]$X,[single]$Y,$Color)
}
function Icon([string]$Name,[double]$X,[double]$Y,[double]$Size,[string]$Fill='',[double]$Rotation=0){if(-not $Fill){$Fill=Color 'text-primary'};$graphics.Icon($design.Icons[$Name],[single]$X,[single]$Y,[single]$Size,$Fill,$Rotation)}
function Button([string]$Id,[double]$X,[double]$Y,[double]$W,[double]$H,[string]$Action,[string]$Text='',[string]$Icon='',[object]$Data=$null,[bool]$Primary=$false,[bool]$Border=$false,[double]$IconSize=16){
    Node $Id $X $Y $W $H $Action $Data
    $hover=$ui.Hover -eq $Id;$pressed=$ui.Pressed -eq $Id
    $bg=if($Primary){Color $(if($hover){'accent-hover'}else{'accent-color'})}elseif($pressed){Color 'bg-control-active'}elseif($hover){Color 'bg-control-hover'}elseif($Border){Surface-Color 'bg-control' 0.18}else{'transparent'}
    $fg=Color 'text-primary'
    if($Id -in @('btn-win-close','settings-win-close') -and $hover){$bg='#c42b1c';$fg='#ffffff'}
    if($Primary){$fg='#ffffff'}
    if($bg -ne 'transparent'){$graphics.Fill($X,$Y,$W,$H,$bg,4)}
    if($Border -and -not $Primary){$graphics.Stroke($X,$Y,$W,$H,(Color 'border-control'),4,1)}
    if($Icon){Icon $Icon ($X+($W-$IconSize)/2) ($Y+($H-$IconSize)/2) $IconSize $fg}
    if($Text){$layout=$graphics.Layout($Text,'Segoe UI',13,$W,$false,400,$false,0);try{$m=$graphics.Metrics($layout);$graphics.DrawLayout($layout,($X+($W-$m.Width)/2),($Y+($H-$m.Height)/2),$fg)}finally{$graphics.ReleaseLayout($layout)}}
}
function InputBox([string]$Id,[string]$Value,[double]$X,[double]$Y,[double]$W,[string]$Placeholder='',[double]$H=30,[double]$FontSize=13){
    Node $Id $X $Y $W $H 'focusInput' $Id 'text'
    $graphics.Fill($X,$Y,$W,$H,(Surface-Color 'bg-window' 0.25),4);$graphics.Stroke($X,$Y,$W,$H,(Color 'border-control'),4,1)
    $focused=$ui.Focus -eq $Id
    if($focused){$graphics.Fill(($X+1),($Y+$H-2),($W-2),2,(Color 'accent-color'),0)}
    $graphics.Clip(($X+7),($Y+2),($W-14),($H-4))
    $layout=$graphics.Layout($Value,'Segoe UI',$FontSize,100000,$false,400,$false,0)
    try{
        $metrics=$graphics.Metrics($layout);$originY=$Y+($H-$metrics.Height)/2
        $offset=0.0
        if($focused){
            $focus=[Math]::Clamp([int]$ui.InputFocus,0,$Value.Length);$anchor=[Math]::Clamp([int]$ui.InputAnchor,0,$Value.Length)
            $caret=$graphics.Caret($layout,$focus,$false);$offset=[Math]::Max(0,$caret.X-($W-22))
            foreach($rect in @($graphics.Selection($layout,[Math]::Min($focus,$anchor),[Math]::Abs($focus-$anchor)))){$graphics.Fill(($X+8+$rect.X-$offset),($originY+$rect.Y),$rect.Width,$rect.Height,(Color 'selection-bg'),0)}
            if($ui.Blink){$graphics.Fill(($X+8+$caret.X-$offset),($originY+$caret.Y),1,$caret.Height,(Color 'text-primary'),0)}
        }
        if($Value){$graphics.DrawLayout($layout,($X+8-$offset),$originY,(Color 'text-primary'))}else{Label $Placeholder ($X+8) $originY ($W-16) (Color 'text-secondary') 13}
    }finally{$graphics.ReleaseLayout($layout);$graphics.Unclip()}
}
function Open-Modal([string]$Title,[string]$Message,[object[]]$Buttons,[bool]$Input=$false,[string]$Value=''){
    $ui.ColorPicker=$null
    $ui.Menu='';$ui.Dropdown=$null;$ui.Modal=@{Title=$Title;Message=$Message;Buttons=$Buttons;Input=$Input;Value=$Value;Markdown=$null}
    if($Input){$ui.Focus='dialog-input';$ui.InputAnchor=0;$ui.InputFocus=$Value.Length}else{$ui.Focus='modal'}
    Invalidate
}
function Save-Document([object]$Tab,[bool]$SaveAs=$false){
    try{
        $destination=$Tab.Path
        if($SaveAs -or -not $destination){$suggested=$Tab.Title;if(-not [IO.Path]::GetExtension($suggested)){$suggested+='.txt'};$destination=$services.FileDialog($true,$suggested)}
        if(-not $destination){return $false}
        $null=$model.Save($Tab.Id,$destination);Persist;Invalidate;return $true
    }catch{Open-Modal 'Notepad' $_.Exception.Message @(@{Text='Close';Action='dismiss';Primary=$true});return $false}
}
function Request-Close([int]$TabId=0){
    if($TabId){$tab=$state.Tabs|Where-Object Id -eq $TabId|Select-Object -First 1;if(-not $tab.Modified){$model.CloseTab($TabId);Invalidate $true;return};Open-Modal 'Notepad' "Do you want to save changes to $($tab.Title)?" @(@{Text='Save';Action='saveCloseTab';Data=$TabId;Primary=$true},@{Text="Don't Save";Action='discardTab';Data=$TabId},@{Text='Cancel';Action='dismiss'})}
    elseif(@($state.Tabs|Where-Object Modified).Count){Open-Modal 'Notepad' 'You have unsaved changes. Do you want to save before closing?' @(@{Text='Save All';Action='saveCloseWindow';Primary=$true},@{Text="Don't Save";Action='discardWindow'},@{Text='Cancel';Action='dismiss'})}
    else{$ui.Running=$false}
}
function Command([string]$Action,[object]$Data=$null){
    $tab=$model.Active()
    switch($Action){
        'newTab'{$null=$model.NewTab();$ui.Focus='editor-area'}
        'newMarkdownTab'{$null=$model.NewTab('Untitled.md',"# Markdown Document`n`nWrite here...",$null,$true);$ui.Focus='editor-area'}
        'newWindow'{$start=[Diagnostics.ProcessStartInfo]::new('pwsh');foreach($a in @('-NoProfile','-STA','-File',"$PSScriptRoot\Notepad.ps1")){$start.ArgumentList.Add($a)};$start.UseShellExecute=$true;$null=[Diagnostics.Process]::Start($start)}
        'switchTab'{$model.SwitchTab([int]$Data);$ui.Focus='editor-area'}
        'closeTab'{Request-Close $tab.Id}
        'closeSpecific'{Request-Close ([int]$Data)}
        'closeWindow'{Request-Close}
        'exit'{Request-Close}
        'save'{$null=Save-Document $tab}
        'saveAs'{$null=Save-Document $tab $true}
        'saveAll'{foreach($document in $state.Tabs){if($document.Modified -and -not (Save-Document $document)){break}}}
        'openFile'{try{$file=$services.FileDialog($false,'');if($file){$null=$model.Open($file);$ui.Focus='editor-area'}}catch{Open-Modal 'Open file' $_.Exception.Message @(@{Text='Close';Action='dismiss';Primary=$true})}}
        'undo'{$model.Undo($false)}
        'redo'{$model.Undo($true)}
        'selectAll'{$model.Select(0,$tab.Text.Length)}
        'copy'{$start=[Math]::Min($tab.Anchor,$tab.Focus);$length=[Math]::Abs($tab.Focus-$tab.Anchor);if($length){$services.WriteClipboard($tab.Text.Substring($start,$length))}}
        'copyDocument'{try{if($settings.copyAsFile){$services.WriteClipboardFile($tab.Text,$tab.Title)}else{$services.WriteClipboard($tab.Text)}}catch{Open-Modal 'Copy document' $_.Exception.Message @(@{Text='Close';Action='dismiss';Primary=$true})}}
        'editColor'{Open-CanvasColorPicker $Data -1}
        'editAnsi'{Open-CanvasColorPicker '' ([int]$Data)}
        'cycleIcon'{Initialize-IconCatalog;$index=[array]::IndexOf(@($ui.IconCatalog|ForEach-Object Key),$settings.windowIcon);$settings.windowIcon=$ui.IconCatalog[($index+1)%$ui.IconCatalog.Count].Key;Apply-WindowIcon}
        'resetIcon'{$settings.windowIcon='default';Apply-WindowIcon}
        'resetColors'{$settings.colors=@{foreground='';tabs='';cursor='';selectionBackground='';topLeft='#272727';topRight='#272727';bottomLeft='#272727';bottomRight='#272727'};$settings.gradientEnabled=$false}
        'formatBold'{Format-Selection '**'}
        'formatItalic'{Format-Selection '_'}
        'formatStrike'{Format-Selection '~~'}
        'formatHeading'{Format-Lines ([string]$Data)}
        'formatList'{Format-Lines ([string]$Data)}
        'formatLink'{Open-Modal 'Insert link' 'Address:' @(@{Text='Insert';Action='insertLink';Primary=$true},@{Text='Cancel';Action='dismiss'}) $true 'https://'}
        'insertLink'{$start=[Math]::Min($tab.Anchor,$tab.Focus);$length=[Math]::Abs($tab.Focus-$tab.Anchor);$text=if($length){$tab.Text.Substring($start,$length)}else{'link text'};$model.Insert(('['+$text+']('+[string]$Data+')'),$false);$tab.Markdown=$true;$ui.Focus='editor-area'}
        'cut'{$start=[Math]::Min($tab.Anchor,$tab.Focus);$length=[Math]::Abs($tab.Focus-$tab.Anchor);if($length){$services.WriteClipboard($tab.Text.Substring($start,$length));$model.Insert('',$false)}}
        'paste'{$model.Insert($services.ReadClipboard(),$false)}
        'delete'{$model.Delete($false)}
        'timeDate'{$now=[DateTime]::Now;$model.Insert(($now.ToString('t')+' '+$now.ToString('M/d/yyyy',[Globalization.CultureInfo]::InvariantCulture)),$false)}
        'find' {Open-Find $false}
        'replace'{Open-Find $true}
        'closeFind'{$ui.Find=$false;$ui.Focus='editor-area'}
        'findNext'{$model.SelectMatch(1)}
        'findPrevious'{$model.SelectMatch(-1)}
        'findCase'{$state.Find.MatchCase=-not $state.Find.MatchCase;$model.Find();$model.SelectMatch(0)}
        'findWrap'{$state.Find.Wrap=-not $state.Find.Wrap}
        'toggleReplace'{$ui.Replace=-not $ui.Replace;if($ui.Replace){Focus-Input 'replace-query-input'}}
        'doReplace'{$model.Replace($false)}
        'doReplaceAll'{$model.Replace($true)}
        'goTo'{$s=$model.Status();Open-Modal 'Go to line' 'Line number:' @(@{Text='Go to';Action='gotoConfirm';Primary=$true},@{Text='Cancel';Action='dismiss'}) $true ([string]$s.Line)}
        'gotoConfirm'{$line=0;if([int]::TryParse([string]$Data,[ref]$line) -and $line -gt 0){$lines=$tab.Text.Split("`n");$pos=0;for($i=0;$i -lt [Math]::Min($line-1,$lines.Length);$i++){$pos+=$lines[$i].Length+1};$model.Select([Math]::Min($pos,$tab.Text.Length),[Math]::Min($pos,$tab.Text.Length))};$ui.Focus='editor-area'}
        'zoomIn'{$settings.zoom=[Math]::Min(500,[int]$settings.zoom+10)}
        'zoomOut'{$settings.zoom=[Math]::Max(20,[int]$settings.zoom-10)}
        'zoomReset'{$settings.zoom=100}
        'toggleStatusBar'{$settings.showStatusBar=-not $settings.showStatusBar}
        'toggleWordWrap'{$settings.wordWrap=-not $settings.wordWrap}
        'lineEnding'{$tab.LineEnding=if($tab.LineEnding -eq 'Unix (LF)'){'Windows (CRLF)'}else{'Unix (LF)'};$tab.Modified=$true}
        'openSettings'{$ui.Settings=$true;$ui.Menu='';$ui.Focus='settings'}
        'openComparison'{$ui.Settings=$true;$ui.ComparisonView=$true;$ui.ComparisonScroll=0;Load-ComparisonResults;$ui.Focus='comparison'}
        'runComparison'{Start-Comparison}
        'refreshComparison'{Start-Comparison $true}
        'openFontSettings'{$ui.Settings=$true;$ui.Expanded['card-font-setting']=$true;$ui.SettingsScroll=0;$ui.Focus='settings'}
        'back'{if($ui.ComparisonView){$ui.ComparisonView=$false;$ui.Focus='settings'}else{$ui.Settings=$false;$ui.Dropdown=$null;$ui.Focus='editor-area'}}
        'accordion'{$ui.Expanded[$Data]=-not $ui.Expanded[$Data]}
        'toggleSetting'{$settings[$Data]=-not $settings[$Data]}
        'startup'{$settings.startupOption=$Data}
        'settingSelect'{$ui.Dropdown=@{Key=$Data.Key;Options=$Data.Options;Rect=$Data.Rect;Id=$Data.Id}}
        'chooseSetting'{if($Data.Key -eq 'pickerMode'){$ui.ColorPicker.Mode=$Data.Value;$ui.Focus='color-picker';Sync-ColorPickerInputs}else{$settings[$Data.Key]=$Data.Value};$ui.Dropdown=$null;if($Data.Key -eq 'theme'){Resolve-Theme};if($Data.Key -in @('theme','backdrop','cornerStyle')){Apply-WindowAppearance}}
        'pickerMode'{$ui.Dropdown=@{Key='pickerMode';Options=@(@{Text='RGB';Value='RGB'},@{Text='HSV';Value='HSV'});Rect=$ui.ColorPicker.ModeRect;Id='picker-mode'}}
        'toggleMenu'{$ui.Menu=if($ui.Menu -eq $Data){''}else{$Data};$ui.Submenu=''}
        'submenu'{$ui.Submenu=$Data}
        'minimize'{$window.Caption('minimize')}
        'maximize'{$window.Caption('maximize')}
        'drag'{$window.Caption('drag')}
        'focusInput'{Focus-Input $Data}
        'discardTab'{$model.CloseTab([int]$Data);$ui.Focus='editor-area'}
        'saveCloseTab'{$document=$state.Tabs|Where-Object Id -eq $Data|Select-Object -First 1;if(Save-Document $document){$model.CloseTab([int]$Data);$ui.Focus='editor-area'}}
        'discardWindow'{$ui.Running=$false}
        'saveCloseWindow'{$success=$true;foreach($document in $state.Tabs){if($document.Modified -and -not(Save-Document $document)){$success=$false;break}};if($success){$ui.Running=$false}}
        'dismiss'{$ui.Focus='editor-area'}
        'toggleMarkdownPreview'{Open-Modal ('Markdown Preview: '+$tab.Title) '' @(@{Text='Close';Action='dismiss';Primary=$true});$ui.Modal.Markdown=$tab.Text}
        'link'{if($Data -match '^https://'){$start=[Diagnostics.ProcessStartInfo]::new($Data);$start.UseShellExecute=$true;$null=[Diagnostics.Process]::Start($start)}}
        'clearFormatting'{$start=[Math]::Min($tab.Anchor,$tab.Focus);$end=[Math]::Max($tab.Anchor,$tab.Focus);if($start -ne $end){$text=$tab.Text.Substring($start,$end-$start);foreach($marker in @('**','~~','_')){$text=$text.Replace($marker,'')};$model.Insert($text,$false)}}
        'pageSetup'{Open-Modal 'Page setup' 'Native print layout is not implemented in this build.' @(@{Text='Close';Action='dismiss';Primary=$true})}
        'print'{Open-Modal 'Print' 'Native printing is not implemented in this build.' @(@{Text='Close';Action='dismiss';Primary=$true})}
    }
    Invalidate $true
}
function Convert-HsvToHex([double]$Hue,[double]$Saturation,[double]$Value){
    $h=($Hue%360+360)%360;$c=$Value*$Saturation;$x=$c*(1-[Math]::Abs(($h/60)%2-1));$m=$Value-$c
    $rgb=switch([int][Math]::Floor($h/60)){0{@($c,$x,0)};1{@($x,$c,0)};2{@(0,$c,$x)};3{@(0,$x,$c)};4{@($x,0,$c)};default{@($c,0,$x)}}
    '#{0:X2}{1:X2}{2:X2}' -f ([int][Math]::Round(255*($rgb[0]+$m))),([int][Math]::Round(255*($rgb[1]+$m))),([int][Math]::Round(255*($rgb[2]+$m)))
}
function Set-ColorPickerHex([string]$Hex){
    $p=$ui.ColorPicker;$p.Hex=$Hex.ToUpperInvariant();$p.R=[Convert]::ToInt32($Hex.Substring(1,2),16);$p.G=[Convert]::ToInt32($Hex.Substring(3,2),16);$p.B=[Convert]::ToInt32($Hex.Substring(5,2),16)
    $r=$p.R/255.0;$g=$p.G/255.0;$b=$p.B/255.0;$maximum=[Math]::Max($r,[Math]::Max($g,$b));$minimum=[Math]::Min($r,[Math]::Min($g,$b));$delta=$maximum-$minimum
    $p.V=$maximum;$p.S=if($maximum -eq 0){0.0}else{$delta/$maximum}
    if($delta -gt 0){$h=if($maximum -eq $r){60*(($g-$b)/$delta%6)}elseif($maximum -eq $g){60*(($b-$r)/$delta+2)}else{60*(($r-$g)/$delta+4)};$p.H=($h+360)%360}
}
function Sync-ColorPickerInputs {
    $p=$ui.ColorPicker;if(-not $p){return}
    $values=if($p.Mode -eq 'HSV'){@([string][int][Math]::Round($p.H),[string][int][Math]::Round($p.S*100),[string][int][Math]::Round($p.V*100))}else{@([string]$p.R,[string]$p.G,[string]$p.B)}
    $all=@{hex=$p.Hex;c0=$values[0];c1=$values[1];c2=$values[2]}
    foreach($key in $all.Keys){if($ui.Focus -ne 'picker-input-'+$key){$p.Inputs[$key]=$all[$key]}}
}
function Commit-ColorPicker {
    $p=$ui.ColorPicker;if(-not $p){return}
    if($p.Ansi -ge 0){$settings.ansiColors[$p.Ansi]=$p.Hex}
    else{$settings.colors[$p.Role]=$p.Hex;if($p.Role -in @('topLeft','topRight','bottomLeft','bottomRight')){$settings.gradientEnabled=$true}}
    $p.Invalid='';Sync-ColorPickerInputs;Invalidate
}
function Open-CanvasColorPicker([string]$Role,[int]$Ansi=-1){
    $anchor=if($ui.Nodes.ContainsKey($ui.Pressed)){$ui.Nodes[$ui.Pressed].Rect}else{@(($ui.Width-60),80,32,32)}
    $hex=if($Ansi -ge 0){$settings.ansiColors[$Ansi]}else{Role-Color $Role}
    $ui.ColorPicker=@{Role=$Role;Ansi=$Ansi;H=0.0;S=0.0;V=1.0;Hex=$hex;R=0;G=0;B=0;Mode='RGB';Inputs=@{};Anchor=$anchor;Scroll=0.0;Invalid='';OpenedUtc=[DateTime]::UtcNow}
    $ui.Focus='color-picker';$ui.Dropdown=$null;Set-ColorPickerHex $hex;Sync-ColorPickerInputs;Invalidate
}
function Set-ColorPickerText([string]$Key,[string]$Value){
    $p=$ui.ColorPicker;if(-not $p){return};$p.Inputs[$Key]=$Value;$p.Invalid=$Key
    if($Key -eq 'hex'){
        $hex=$Value.Trim();if($hex.Length -eq 6){$hex='#'+$hex}
        if($hex -cmatch '^#[0-9A-Fa-f]{6}$'){Set-ColorPickerHex $hex;Commit-ColorPicker}
    }elseif($Key -in @('c0','c1','c2')){
        $number=0.0;if(-not [double]::TryParse($Value,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$number)){return}
        $index=[int]$Key.Substring(1)
        if($p.Mode -eq 'RGB'){
            if($number -lt 0 -or $number -gt 255){return};$rgb=@($p.R,$p.G,$p.B);$rgb[$index]=[int][Math]::Round($number);Set-ColorPickerHex ('#{0:X2}{1:X2}{2:X2}' -f $rgb[0],$rgb[1],$rgb[2]);Commit-ColorPicker
        }else{
            $maximum=if($index -eq 0){360}else{100};if($number -lt 0 -or $number -gt $maximum){return}
            switch($index){0{$p.H=$number};1{$p.S=$number/100};2{$p.V=$number/100}}
            Set-ColorPickerHex (Convert-HsvToHex $p.H $p.S $p.V);Commit-ColorPicker
        }
    }
}
function Set-ColorPickerPoint([string]$Part,[double]$X,[double]$Y){
    $p=$ui.ColorPicker;if(-not $p){return};$ui.Focus='color-picker'
    if($Part -eq 'spectrum'){$r=$p.SpectrumRect;$p.H=360*[Math]::Clamp(($X-$r[0])/$r[2],0,0.999999);$p.S=1-[Math]::Clamp(($Y-$r[1])/$r[3],0,1)}
    else{$r=$p.ValueRect;$p.V=[Math]::Clamp(($X-$r[0])/$r[2],0,1)}
    $h=$p.H;$s=$p.S;$v=$p.V;Set-ColorPickerHex (Convert-HsvToHex $h $s $v);$p.H=$h;$p.S=$s;$p.V=$v;Commit-ColorPicker
}
function Format-Selection([string]$Marker){
    $tab=$model.Active();$start=[Math]::Min($tab.Anchor,$tab.Focus);$length=[Math]::Abs($tab.Anchor-$tab.Focus);$text=$tab.Text.Substring($start,$length)
    if($length -ge 2*$Marker.Length -and $text.StartsWith($Marker) -and $text.EndsWith($Marker)){$text=$text.Substring($Marker.Length,$text.Length-2*$Marker.Length);$model.Insert($text,$false);$model.Select($start,($start+$text.Length))}
    else{$model.Insert(($Marker+$text+$Marker),$false);$model.Select(($start+$Marker.Length),($start+$Marker.Length+$text.Length))}
    $tab.Markdown=$true;$ui.Focus='editor-area'
}
function Format-Lines([string]$Prefix){
    $tab=$model.Active();$start=[Math]::Min($tab.Anchor,$tab.Focus);$end=[Math]::Max($tab.Anchor,$tab.Focus)
    $lineStart=if($start -gt 0){$tab.Text.LastIndexOf("`n",$start-1)+1}else{0}
    $lineEnd=$tab.Text.IndexOf("`n",$end);if($lineEnd -lt 0){$lineEnd=$tab.Text.Length}
    $lines=$tab.Text.Substring($lineStart,$lineEnd-$lineStart).Split("`n")
    $text=(@($lines|ForEach-Object {if($Prefix -and $_.StartsWith($Prefix)){$_.Substring($Prefix.Length)}else{$Prefix+$_}}) -join "`n")
    $model.Select($lineStart,$lineEnd);$model.Insert($text,$false);$model.Select($lineStart,($lineStart+$text.Length));$tab.Markdown=$true;$ui.Focus='editor-area'
}
function Open-Find([bool]$Replace){
    $ui.Find=$true;$ui.Replace=$Replace;$ui.Menu='';$tab=$model.Active();$selected=$tab.Text.Substring([Math]::Min($tab.Anchor,$tab.Focus),[Math]::Abs($tab.Focus-$tab.Anchor))
    if($selected -and -not $selected.Contains("`n")){$state.Find.Query=$selected}
    $model.Find();$model.SelectMatch(0);Focus-Input 'find-query-input'
}
function Input-Value([string]$Id){if($ui.ColorPicker -and $Id.StartsWith('picker-input-')){return $ui.ColorPicker.Inputs[$Id.Substring(13)]};switch($Id){'find-query-input'{$state.Find.Query};'replace-query-input'{$state.Find.Replacement};'dialog-input'{$ui.Modal.Value};default{''}}}
function Set-InputValue([string]$Id,[string]$Value){if($ui.ColorPicker -and $Id.StartsWith('picker-input-')){Set-ColorPickerText $Id.Substring(13) $Value;return};switch($Id){'find-query-input'{$state.Find.Query=$Value;$model.Find();$model.SelectMatch(0)};'replace-query-input'{$state.Find.Replacement=$Value};'dialog-input'{$ui.Modal.Value=$Value}}}
function Focus-Input([string]$Id){$ui.Focus=$Id;$value=Input-Value $Id;$ui.InputAnchor=0;$ui.InputFocus=$value.Length}
function Input-Insert([string]$Text){$value=Input-Value $ui.Focus;$start=[Math]::Min($ui.InputAnchor,$ui.InputFocus);$end=[Math]::Max($ui.InputAnchor,$ui.InputFocus);Set-InputValue $ui.Focus ($value.Substring(0,$start)+$Text+$value.Substring($end));$ui.InputFocus=$start+$Text.Length;$ui.InputAnchor=$ui.InputFocus}

function Paint-Editor {
    $tab=$model.Active();$bottom=if($settings.showStatusBar){37}else{0};$h=[Math]::Max(1,$ui.Height-80-$bottom)
    $ui.EditorRect=@(0.0,80.0,$ui.Width,$h)
    if(-not $settings.gradientEnabled){$graphics.Fill(0,80,$ui.Width,$h,(Surface-Color 'bg-editor'),0)}
    Node 'editor-area' 0 80 $ui.Width $h 'editor' $null 'text'
    $fontSize=[int]$settings.fontSize*96/72*([int]$settings.zoom/100)
    $lineHeight=$fontSize*1.45;$weight=if($settings.fontStyle.Contains('Bold')){700}else{400};$italic=$settings.fontStyle.Contains('Italic')
    $available=[Math]::Max(1,$ui.Width-32-12)
    $key="$($tab.Id)|$($tab.Revision)|$available|$fontSize|$($settings.fontFamily)|$($settings.fontStyle)|$($settings.wordWrap)"
    if($key -ne $ui.EditorKey){
        if($ui.EditorLayout -ne [IntPtr]::Zero){$graphics.ReleaseLayout($ui.EditorLayout)}
        $ui.EditorLayout=$graphics.Layout($tab.Text,$settings.fontFamily,$fontSize,$available,[bool]$settings.wordWrap,$weight,$italic,$lineHeight)
        $ui.EditorKey=$key;$ui.EditorMetrics=$graphics.Metrics($ui.EditorLayout)
    }
    $layout=$ui.EditorLayout;$caret=$graphics.Caret($layout,[uint32]$tab.Focus,$false)
    if($ui.EnsureCaret){
        if($caret.Y -lt $tab.ScrollY){$tab.ScrollY=$caret.Y}
        if($caret.Y+$caret.Height -gt $tab.ScrollY+$h-28){$tab.ScrollY=$caret.Y+$caret.Height-$h+28}
        if(-not $settings.wordWrap){if($caret.X -lt $tab.ScrollX){$tab.ScrollX=$caret.X};if($caret.X -gt $tab.ScrollX+$available-2){$tab.ScrollX=$caret.X-$available+2}}else{$tab.ScrollX=0}
        $ui.EnsureCaret=$false
    }
    $tab.ScrollY=[Math]::Clamp([double]$tab.ScrollY,0,[Math]::Max(0,$ui.EditorMetrics.Height-$h+28))
    $ox=16-$tab.ScrollX;$oy=94-$tab.ScrollY;$ui.EditorOrigin=@($ox,$oy)
    $graphics.Clip(0,80,($ui.Width-12),$h)
    $start=[Math]::Min($tab.Anchor,$tab.Focus);$length=[Math]::Abs($tab.Focus-$tab.Anchor)
    $rects=@($graphics.Selection($layout,$start,$length))
    foreach($rect in $rects){$graphics.Fill(($ox+$rect.X),($oy+$rect.Y),[Math]::Max(1,$rect.Width),$rect.Height,(Role-Color 'selectionBackground'),0)}
    $graphics.DrawLayout($layout,$ox,$oy,(Role-Color 'foreground'))
    # Repaint selected glyphs through each selection clip, using selection-text.
    foreach($rect in $rects){$graphics.Clip(($ox+$rect.X),($oy+$rect.Y),[Math]::Max(1,$rect.Width),$rect.Height);$graphics.DrawLayout($layout,$ox,$oy,(Color 'selection-text'));$graphics.Unclip()}
    if($ui.Focus -eq 'editor-area' -and $ui.Focused -and $ui.Blink -and -not $ui.Modal -and -not $ui.Settings){$graphics.Fill(($ox+$caret.X),($oy+$caret.Y),1,$caret.Height,(Role-Color 'cursor'),0)}
    $graphics.Unclip()
    if($ui.EditorMetrics.Height -gt $h-28){
        $track=$h-6;$thumb=[Math]::Max(24,$track*($h-28)/$ui.EditorMetrics.Height);$ty=81+($track-$thumb)*$tab.ScrollY/[Math]::Max(1,($ui.EditorMetrics.Height-$h+28))
        $graphics.Fill(($ui.Width-9),$ty,6,$thumb,'rgba(255,255,255,0.2)',3)
        Node 'editor-scrollbar' ($ui.Width-12) 80 12 $h 'scrollbar' $null 'default'
    }
}
function Paint-Chrome {
    $w=$ui.Width;$tab=$model.Active()
    if(-not $settings.gradientEnabled){$graphics.Fill(0,0,$w,42,(Surface-Color 'bg-titlebar'),0)}
    Node 'titlebar-drag' 0 0 $w 42 'drag' $null 'default';Paint-AppIcon 'app-icon' 24 13 14
    $x=54.0;$right=$w-138
    $graphics.Clip(40,0,[Math]::Max(0,$right-76),40)
    foreach($document in $state.Tabs){
        $id='tab-'+$document.Id;$active=$document.Id -eq $state.ActiveId;$hover=$ui.Hover.StartsWith($id)
        $tw=240
        $bg=if($active){Role-Color 'tabs'}elseif($hover){Surface-Color 'bg-tab-hover'}else{'transparent'}
        if($bg -ne 'transparent'){$graphics.Fill($x,5.2,$tw,34,$bg,7);$graphics.Fill($x,32,($tw),7.2,$bg,0)}
        if($active){$graphics.Stroke($x,5.2,$tw,34,(Color 'border-subtle'),7,0.8)}
        Node $id $x 5.2 $tw 34 'switchTab' $document.Id
        $graphics.Clip(($x+12),8,($tw-44),28);Label $document.Title ($x+12) 14 ($tw-44) (Color $(if($active -or $hover){'text-primary'}else{'text-secondary'})) 12;$graphics.Unclip()
        if($active -or $hover){
            if($document.Modified -and -not $hover){$graphics.Fill(($x+$tw-32),19.5,4.6,6,(Color 'text-secondary'),3)}
            $cx=$x+$tw-28
            Node ($id+'-close') $cx 12.2 20 20 'closeSpecific' $document.Id
            if($ui.Hover -eq $id+'-close'){$graphics.Fill($cx,12.2,20,20,(Color 'bg-control-hover'),4)}
            Icon 'close' ($cx+4) 16 12 (Color 'text-primary')
        }elseif($document.Modified){$graphics.Fill(($x+$tw-21),19.5,6,6,(Color 'text-secondary'),3)}
        $x+=$tw+2
    }
    $graphics.Unclip();$x=[Math]::Min($x+4,$right-36)
    Button 'btn-add-tab' $x 6 32 32 'newTab' '' 'plus' $null $false $false 14
    Button 'btn-win-min' ($w-138) 0 46 40 'minimize' '' 'minimize' $null $false $false 10
    Button 'btn-win-max' ($w-92) 0 46 40 'maximize' '' 'maximize' $null $false $false 10
    Button 'btn-win-close' ($w-46) 0 46 40 'closeWindow' '' 'close' $null $false $false 10
    if(-not $settings.gradientEnabled){$graphics.Fill(0,42,$w,38,(Surface-Color 'bg-menubar'),0)}
    $mx=8.0
    foreach($entry in @(@('file','File',44),@('edit','Edit',44),@('view','View',48))){
        if($ui.Menu -eq $entry[0]){$graphics.Fill($mx,44,($entry[2]),28,(Color 'bg-control-hover'),4)}
        Button ('menu-btn-'+$entry[0]) $mx 44 $entry[2] 28 'toggleMenu' $entry[1] '' $entry[0]
        $mx+=$entry[2]+2
    }
    if($settings.formatting){
        $fx=($w-248)/2
        Button 'format-headings' $fx 45 42 30 'toggleMenu' 'H1' '' 'headings'
        Icon 'chevronDown' ($fx+32) 56 8
        Button 'format-lists' ($fx+44) 45 38 30 'toggleMenu' '' '' 'lists';Label ([string][char]0xE8FD) ($fx+51) 52 22 (Color 'text-primary') 16 'Segoe Fluent Icons'
        Button 'format-bold' ($fx+84) 45 30 30 'formatBold';Label 'B' ($fx+94) 51 20 (Color 'text-primary') 16 'Segoe UI' 700
        Button 'format-italic' ($fx+116) 45 30 30 'formatItalic';Label ([string][char]0xE8DB) ($fx+123) 52 20 (Color 'text-primary') 16 'Segoe Fluent Icons'
        Button 'format-strike' ($fx+148) 45 30 30 'formatStrike';Label ([string][char]0xEDE0) ($fx+155) 52 20 (Color 'text-primary') 16 'Segoe Fluent Icons'
        Button 'format-link' ($fx+180) 45 30 30 'formatLink';Label ([string][char]0xE71B) ($fx+187) 52 20 (Color 'text-primary') 16 'Segoe Fluent Icons'
        Button 'format-more' ($fx+212) 45 30 30 'toggleMenu' '' '' 'formatMore';Label ([string][char]0xE712) ($fx+219) 52 20 (Color 'text-primary') 16 'Segoe Fluent Icons'
    }
    Button 'btn-copy-document' ($w-188) 45 32 30 'copyDocument'
    Label ([string][char]0xE8C8) ($w-180) 52 20 (Color 'text-primary') 16 'Segoe Fluent Icons'
    Button 'btn-writing-tools' ($w-152) 45 28 30 'toggleMenu' '✧' '' 'writing'
    Button 'btn-whats-new' ($w-120) 43 32 32 'openComparison' '' 'megaphone'
    Button 'btn-person' ($w-84) 43 32 32 'openSettings';Label ([string][char]0xE77B) ($w-77) 52 20 (Color 'text-primary') 16 'Segoe Fluent Icons'
    Button 'btn-settings-toggle' ($w-40) 43 32 32 'openSettings' '' 'gear'
    if($settings.showStatusBar){
        $y=$ui.Height-37;if(-not $settings.gradientEnabled){$graphics.Fill(0,$y,$w,37,(Surface-Color 'bg-statusbar'),0)}
        $status=$model.Status();$cursor="Ln $($status.Line), Col $($status.Column)";$count=if($status.Selected){"$($status.Selected) selected"}else{"$($status.Characters) characters"}
        Label $cursor 26 ($y+6) 170 (Color 'text-secondary') 12
        $graphics.Fill(126,($y+7),0.8,14,(Color 'border-subtle'),0);Label $count 137 ($y+6) 200 (Color 'text-secondary') 12
        $items=@(@{Id='sb-doc-type';Text=$(if($tab.Markdown){'Markdown'}else{'Plain text'});Width=100;Action='none'},@{Id='sb-zoom-level';Text=([string]$settings.zoom+'%');Width=70;Action='zoomReset'},@{Id='sb-line-ending';Text=$tab.LineEnding;Width=114;Action='lineEnding'},@{Id='sb-encoding';Text=$tab.Encoding;Width=74;Action='none'})
        $sx=$w-374
        foreach($item in $items){Node $item.Id $sx $y $item.Width 28 $item.Action;if($ui.Hover -eq $item.Id){$graphics.Fill($sx,$y,$item.Width,28,(Color 'bg-control-hover'),0)};Label $item.Text ($sx+10) ($y+6) ($item.Width-20) (Color 'text-secondary') 12;$sx+=$item.Width;$graphics.Fill($sx,($y+7),0.8,14,(Color 'border-subtle'),0)}
    }
}
function Paint-Find {
    if(-not $ui.Find){return}
    $w=460.0;$x=$ui.Width-24-$w;$y=88.0;$h=if($ui.Replace){88}else{48}
    $graphics.Fill($x,$y,$w,$h,(Surface-Color 'bg-flyout' 0.35),8);$graphics.Stroke($x,$y,$w,$h,(Color 'border-control'),8,1)
    Node 'find-replace-panel' $x $y $w $h 'none'
    InputBox 'find-query-input' $state.Find.Query ($x+10) ($y+9) 228 'Find' 28
    $count=if(-not $state.Find.Query){'0 of 0'}elseif(-not $state.Find.Matches.Count){'No results'}else{"$($state.Find.Index+1) of $($state.Find.Matches.Count)"}
    Label $count ($x+174) ($y+16) 62 (Color 'text-secondary') 12
    $bx=$x+244
    foreach($button in @(@('prev','arrowUp','findPrevious'),@('next','arrowDown','findNext'),@('case','caseSensitive','findCase'),@('wrap','wrapAround','findWrap'),@('replace','chevronDown','toggleReplace'),@('close','close','closeFind'))){
        if(($button[0] -eq 'case' -and $state.Find.MatchCase) -or ($button[0] -eq 'wrap' -and $state.Find.Wrap)){$graphics.Fill($bx,($y+9),28,28,(Color 'bg-control-active'),4)}
        Button ('find-btn-'+$button[0]) $bx ($y+9) 28 28 $button[2] '' $button[1] $null $false $false 14;$bx+=34
    }
    if($ui.Replace){InputBox 'replace-query-input' $state.Find.Replacement ($x+10) ($y+47) 253 'Replace with' 28;Button 'btn-do-replace' ($x+269) ($y+47) 74 28 'doReplace' 'Replace' '' $null $false $true;Button 'btn-do-replace-all' ($x+349) ($y+47) 100 28 'doReplaceAll' 'Replace all' '' $null $false $true}
}
function Paint-MenuRows([object[]]$Rows,[double]$X,[double]$Y,[double]$W,[string]$Prefix){
    $h=8.0;foreach($row in $Rows){$h+=$(if($row.Separator){7}else{28})}
    $graphics.Fill($X,$Y,$W,$h,(Surface-Color 'bg-flyout' 0.35),8);$graphics.Stroke($X,$Y,$W,$h,(Color 'border-control'),8,1)
    Node ($Prefix+'-background') $X $Y $W $h 'none'
    $ry=$Y+4;$rowIndex=0
    foreach($row in $Rows){
        if($row.Separator){$graphics.Fill(($X+10),($ry+3),($W-20),1,(Color 'border-subtle'),0);$ry+=7;continue}
        $id=$Prefix+'-'+$row.Action+'-'+$rowIndex;$rowIndex++
        if(-not $row.Disabled){Node $id ($X+4) $ry ($W-8) 28 $row.Action $row.Data}
        if($ui.Hover -eq $id -and -not $row.Disabled){$graphics.Fill(($X+4),$ry,($W-8),28,(Color 'bg-flyout-item-hover'),4)}
        $tx=$X+14
        if($row.ContainsKey('Checked')){if($row.Checked){Icon 'check' $tx ($ry+8) 12};$tx+=22}
        Label $row.Text $tx ($ry+5) ($W-28) (Color $(if($row.Disabled){'text-disabled'}else{'text-primary'})) 13
        if($row.Shortcut){Label $row.Shortcut ($X+$W-113) ($ry+6) 96 (Color 'text-secondary') 12}
        if($row.Submenu){Icon 'chevronRight' ($X+$W-24) ($ry+9) 10 (Color 'text-secondary');if($ui.Submenu -eq $row.Submenu){Paint-MenuRows $row.Rows ($X+$W-1) ($ry-4) 220 ($Prefix+'-sub')}}
        $ry+=28
    }
}
function Paint-Menus {
    if(-not $ui.Menu){return}
    $rows=switch($ui.Menu){
        'file'{@(@{Text='New tab';Action='newTab';Shortcut='Ctrl+N'},@{Text='New window';Action='newWindow';Shortcut='Ctrl+Shift+N'},@{Text='New Markdown tab';Action='newMarkdownTab'},@{Text='Open';Action='openFile';Shortcut='Ctrl+O'},@{Text='Recent';Action='submenu';Data='recent';Submenu='recent';Rows=@(@{Text='No recent files';Action='none';Disabled=$true})},@{Text='Save';Action='save';Shortcut='Ctrl+S'},@{Text='Save as';Action='saveAs';Shortcut='Ctrl+Shift+S'},@{Text='Save all';Action='saveAll';Shortcut='Ctrl+Alt+S'},@{Separator=$true},@{Text='Page setup';Action='pageSetup'},@{Text='Print';Action='print';Shortcut='Ctrl+P'},@{Separator=$true},@{Text='Close tab';Action='closeTab';Shortcut='Ctrl+W'},@{Text='Close window';Action='closeWindow';Shortcut='Ctrl+Shift+W'},@{Text='Exit';Action='exit'})}
        'edit'{@(@{Text='Undo';Action='undo';Shortcut='Ctrl+Z'},@{Separator=$true},@{Text='Cut';Action='cut';Shortcut='Ctrl+X'},@{Text='Copy';Action='copy';Shortcut='Ctrl+C'},@{Text='Paste';Action='paste';Shortcut='Ctrl+V'},@{Text='Delete';Action='delete';Shortcut='Del'},@{Separator=$true},@{Text='Clear formatting';Action='clearFormatting'},@{Text='Find';Action='find';Shortcut='Ctrl+F'},@{Text='Find next';Action='findNext';Shortcut='F3'},@{Text='Find previous';Action='findPrevious';Shortcut='Shift+F3'},@{Text='Replace';Action='replace';Shortcut='Ctrl+H'},@{Text='Go to';Action='goTo';Shortcut='Ctrl+G'},@{Separator=$true},@{Text='Select all';Action='selectAll';Shortcut='Ctrl+A'},@{Text='Time/Date';Action='timeDate';Shortcut='F5'},@{Separator=$true},@{Text='Font';Action='openFontSettings'})}
        'view'{@(@{Text='Zoom';Action='submenu';Data='zoom';Submenu='zoom';Rows=@(@{Text='Zoom in';Action='zoomIn';Shortcut='Ctrl+Plus'},@{Text='Zoom out';Action='zoomOut';Shortcut='Ctrl+Minus'},@{Text='Restore default zoom';Action='zoomReset';Shortcut='Ctrl+0'})},@{Text='Status bar';Action='toggleStatusBar';Checked=[bool]$settings.showStatusBar},@{Text='Word wrap';Action='toggleWordWrap';Checked=[bool]$settings.wordWrap},@{Text='Markdown';Action='submenu';Data='markdown';Submenu='markdown';Rows=@(@{Text='Preview Markdown';Action='toggleMarkdownPreview'})})}
        'headings'{@(@{Text='Heading 1';Action='formatHeading';Data='# '},@{Text='Heading 2';Action='formatHeading';Data='## '},@{Text='Heading 3';Action='formatHeading';Data='### '},@{Text='Paragraph';Action='formatHeading';Data=''})}
        'lists'{@(@{Text='Bulleted list';Action='formatList';Data='- '},@{Text='Numbered list';Action='formatList';Data='1. '},@{Text='Checklist';Action='formatList';Data='- [ ] '})}
        'formatMore'{@(@{Text='Bold';Action='formatBold';Shortcut='Ctrl+B'},@{Text='Italic';Action='formatItalic';Shortcut='Ctrl+I'},@{Text='Strikethrough';Action='formatStrike';Shortcut='Ctrl+Shift+X'},@{Text='Insert link';Action='formatLink';Shortcut='Ctrl+K'},@{Separator=$true},@{Text='Clear formatting';Action='clearFormatting'},@{Text='Preview Markdown';Action='toggleMarkdownPreview'})}
        'writing'{@(@{Text='Copy whole document';Action='copyDocument'},@{Text='Copy format settings';Action='openSettings'})}
    }
    $x=switch($ui.Menu){'file'{8};'edit'{54};'view'{100};'headings'{($ui.Width-248)/2};'lists'{($ui.Width-248)/2+44};'formatMore'{($ui.Width-248)/2+212};'writing'{$ui.Width-268}}
    $x=[Math]::Clamp([double]$x,8,[Math]::Max(8,$ui.Width-268))
    Paint-MenuRows $rows $x 80 260 ('flyout-'+$ui.Menu)
}
function Select-Control([string]$Id,[string]$Key,[object[]]$Options,[double]$X,[double]$Y,[double]$W){
    $text=[string]$settings[$Key];foreach($option in $Options){if($option.Value -eq $settings[$Key]){$text=$option.Text;break}}
    $data=@{Id=$Id;Key=$Key;Options=$Options;Rect=@($X,$Y,$W,32)}
    Button $Id $X $Y $W 32 'settingSelect' '' '' $data $false $true
    Label $text ($X+12) ($Y+7) ($W-36) (Color 'text-primary') 13
    Icon 'chevronDown' ($X+$W-22) ($Y+10) 12 '#9d9d9d'
}
function Toggle-Control([string]$Key,[double]$X,[double]$Y){
    $on=[bool]$settings[$Key];$id='toggle-setting-'+$Key
    Node $id $X $Y 78 24 'toggleSetting' $Key
    $track=if($on){Color 'accent-color'}elseif($ui.Theme -eq 'light'){'#e0e0e0'}else{'#333333'}
    $border=if($on){Color 'accent-color'}elseif($ui.Theme -eq 'light'){'#999999'}else{'#777777'}
    $graphics.Fill($X,($Y+2),40,20,$track,10);$graphics.Stroke($X,($Y+2),40,20,$border,10,1)
    $knob=if($on){'#ffffff'}elseif($ui.Theme -eq 'light'){'#555555'}else{'#cecece'}
    $graphics.Fill(($X+3+$(if($on){18}else{0})),($Y+$(if($on){5}else{6})),($(if($on){14}else{12})),($(if($on){14}else{12})),$knob,7)
    Label $(if($on){'On'}else{'Off'}) ($X+50) ($Y+4) 28 (Color 'text-primary') 13
}
function Paint-Comparison {
    $w=$ui.Width;$h=$ui.Height
    $graphics.Fill(0,0,$w,$h,(Surface-Color 'bg-window'),0);Node 'comparison-view' 0 0 $w $h 'none' $null 'default'
    Button 'comparison-back' 8 4 32 32 'back' '' 'back'
    Label 'Notepad-PS1' 52 12 220 (Color 'text-primary') 12
    Button 'comparison-minimize' ($w-138) 0 46 40 'minimize' '' 'minimize' $null $false $false 10
    Button 'comparison-maximize' ($w-92) 0 46 40 'maximize' '' 'maximize' $null $false $false 10
    Button 'comparison-close' ($w-46) 0 46 40 'back' '' 'close' $null $false $false 10
    Label 'Compare with Windows Notepad' 32 59 ([Math]::Max(280,$w-380)) (Color 'text-primary') 24 'Segoe UI' 600
    $running=$null -ne $ui.ComparisonProcess
    Button 'comparison-run' ($w-334) 58 142 34 'runComparison' $(if($running){'Running...'}else{'Run comparison'}) '' $null $true $true
    Button 'comparison-refresh' ($w-180) 58 148 34 'refreshComparison' 'Refresh baseline' '' $null $false $true
    Label $ui.ComparisonStatus 32 105 ($w-64) (Color 'text-secondary') 12
    $left=32;$total=$w-64;$positions=@(0.0,0.29,0.44,0.59,0.74);$widths=@(0.29,0.15,0.15,0.15,0.26)
    $headers=@('Property','Windows','Reference','PowerShell','Verdict')
    for($i=0;$i -lt $headers.Count;$i++){Label $headers[$i] ($left+$total*$positions[$i]) 140 ($total*$widths[$i]-8) (Color 'text-primary') 13 'Segoe UI' 600}
    $graphics.Fill(32,164,$total,1,(Color 'border-subtle'),0)
    $bodyHeight=[Math]::Max(1,$h-215);$ui.ComparisonExtent=$ui.ComparisonRows.Count*32
    $graphics.Clip(24,170,($w-48),$bodyHeight);$ui.HitClip=@(24,170,($w-48),$bodyHeight)
    $y=174-$ui.ComparisonScroll
    foreach($row in $ui.ComparisonRows){
        $values=@($row.Property,$row.Real,$row.Reference,$row.PS1,$row.Verdict)
        for($i=0;$i -lt $values.Count;$i++){
            $color=if($i -eq 4){switch($row.Verdict){'TRUE'{'#4caa3d'};'FALSE'{'#e57a88'};'CONTESTED'{'#cda023'};default{Color 'text-secondary'}}}else{Color 'text-primary'}
            $value=if($null -eq $values[$i]){'—'}else{[string]$values[$i]}
            Label $value ($left+$total*$positions[$i]) $y ($total*$widths[$i]-8) $color 13
        }
        $y+=32
    }
    if(-not $ui.ComparisonRows.Count){Label 'Run a comparison to collect the three bearings.' 32 $y ($w-64) (Color 'text-secondary') 14}
    $graphics.Unclip();$ui.HitClip=$null
    Label 'UNKNOWN means unmeasured. Refresh baseline opens an instrument-owned Windows Notepad window.' 32 ($h-31) ($w-64) (Color 'text-secondary') 12
}
function Paint-ColorControls([double]$X,[double]$Y,[double]$W){
    $names=@('Black','Red','Green','Yellow','Blue','Purple','Cyan','White')
    $roles=@(@('foreground','Foreground'),@('tabs','Tabs'),@('cursor','Cursor color'),@('selectionBackground','Selection background'),@('topLeft','Top left'),@('topRight','Top right'),@('bottomLeft','Bottom left'),@('bottomRight','Bottom right'))
    for($i=0;$i -lt 8;$i++){
        $rowY=$Y+$i*40
        Label $names[$i] ($X+24) ($rowY+8) 72 (Color 'text-primary') 14
        foreach($bright in @(0,1)){$index=$i+8*$bright;$sx=$X+112+42*$bright;Node ('palette-'+$index) $sx $rowY 32 32 'editAnsi' $index;$graphics.Fill($sx,$rowY,32,32,$settings.ansiColors[$index],4);$graphics.Stroke($sx,$rowY,32,32,(Color 'border-control'),4,1)}
        Label $roles[$i][1] ($X+$W/2) ($rowY+8) ($W/2-66) (Color 'text-primary') 14
        $cx=$X+$W-56;Node ('color-'+$roles[$i][0]) $cx $rowY 32 32 'editColor' $roles[$i][0]
        $graphics.Fill($cx,$rowY,32,32,(Role-Color $roles[$i][0]),4);$graphics.Stroke($cx,$rowY,32,32,(Color 'border-control'),4,1)
    }
    Button 'reset-colors' ($X+24) ($Y+330) 130 32 'resetColors' 'Reset colors' '' $null $false $true
}
function Paint-Settings {
    if(-not $ui.Settings){return}
    if($ui.ComparisonView){Paint-Comparison;return}
    $w=$ui.Width;$h=$ui.Height;if(-not $settings.gradientEnabled){$graphics.Fill(0,0,$w,$h,(Surface-Color 'bg-window'),0)};Node 'settings-view' 0 0 $w $h 'none' $null 'default'
    $graphics.Fill(0,39.2,$w,0.8,(Color 'border-subtle'),0)
    Button 'settings-btn-back' 8 4 32 32 'back' '' 'back';Paint-AppIcon 'settings-app-icon' 48 11 18;Label 'Notepad' 88 12 200 (Color 'text-primary') 12
    Button 'settings-win-min' ($w-138) 0 46 40 'none' '' 'minimize' $null $false $false 10
    Button 'settings-win-max' ($w-92) 0 46 40 'none' '' 'maximize' $null $false $false 10
    Button 'settings-win-close' ($w-46) 0 46 40 'back' '' 'close' $null $false $false 10
    $col=[Math]::Min(650,$w-118);$left=($w-$col)/2;$right=$left
    $y=74-$ui.SettingsScroll
    $graphics.Clip(0,40,($w-12),($h-40));$ui.HitClip=@(0,40,($w-12),($h-40))
    Label 'Settings' $left $y $col (Color 'text-primary') 28 'Segoe UI' 600
    $y+=91
    Label 'Appearance' $left $y $col (Color 'text-primary') 14 'Segoe UI' 600;$y+=24
    $cards=@(
        @{Title='App theme';Subtitle='Select which app theme to display';Icon='theme';Key='theme';Select=@(@{Text='Dark';Value='dark'},@{Text='Light';Value='light'},@{Text='Use system setting';Value='system'});SelectWidth=170}
        # MansfieldPlumbing additions: native DWM material, geometry and whole-document clipboard.
        @{Title='Window backdrop';Subtitle='Choose the material behind the window';Icon='theme';Key='backdrop';Select=@(@{Text='Mica';Value='mica'},@{Text='Acrylic';Value='acrylic'},@{Text='Reverse Mica';Value='reverseMica'});SelectWidth=170}
        @{Title='Background opacity';Subtitle='100% is opaque. Reduce to reveal the material.';Icon='theme';Slider=$true}
        @{Title='Four-corner gradient';Subtitle='Blend the four corner colors across the background';Icon='theme';Key='gradientEnabled';Toggle=$true}
        @{Title='Colors';Icon='theme';Accordion='card-colors-setting'}
        @{Title='Corners';Subtitle='Choose curved or straight window and control corners';Icon='tabsApp';Key='cornerStyle';Select=@(@{Text='Curved';Value='curved'},@{Text='Straight';Value='straight'});SelectWidth=170}
        @{Title='Window icon';Subtitle='Click the top-left icon to cycle system icons';Icon='app';Button='resetIcon';ButtonText='Reset icon'}
        @{Section='Copy'}
        @{Title='Copy document as .txt file';Subtitle='Off copies text. Both modes use the whole active document.';Icon='openFiles';Key='copyAsFile';Toggle=$true}
        @{Section='Text Formatting'}
        @{Title='Font';Icon='font';Accordion='card-font-setting'}
        @{Title='Word wrap';Subtitle='Fit text within window by default';Icon='wordWrap';Key='wordWrap';Toggle=$true}
        @{Title='Formatting';Icon='formatting';Key='formatting';Toggle=$true}
        @{Section='Opening Notepad'}
        @{Title='Opening files';Subtitle='Choose where your files are opened';Icon='openFiles';Key='openingFiles';Select=@(@{Text='Open in a new tab';Value='newTab'},@{Text='Open in a new window';Value='newWindow'});SelectWidth=184}
        @{Title='When Notepad starts';Icon='tabsApp';Accordion='card-startup-setting'}
        @{Title='Recent Files';Icon='recentFiles';Key='recentFilesEnabled';Toggle=$true}
        @{Section='Spelling'}
        @{Title='Spell check';Icon='spellCheck';Key='spellCheck';Toggle=$true}
    )
    foreach($card in $cards){
        if($card.Section){$y+=24;Label $card.Section $left $y $col (Color 'text-primary') 14 'Segoe UI' 600;$y+=28;continue}
        $height=if($card.Subtitle){68.0}else{49.6}
        $expanded=$card.Accordion -and $ui.Expanded[$card.Accordion]
        if($card.Accordion){$height=51.6;if($expanded){$height=switch($card.Accordion){'card-font-setting'{296.125};'card-colors-setting'{438};default{147.6}}}}
        $graphics.Fill($left,$y,$col,$height,(Surface-Color 'bg-card' 0.12),8);$graphics.Stroke($left,$y,$col,$height,(Color 'border-subtle'),8,0.8)
        $headerHeight=if($card.Subtitle){68}else{51.6};Icon $card.Icon ($left+17) ($y+($headerHeight-18)/2) 18
        Label $card.Title ($left+52) ($y+$(if($card.Subtitle){14}else{16})) ($col-230) (Color 'text-primary') 14
        if($card.Subtitle){Label $card.Subtitle ($left+52) ($y+36) ($col-230) (Color 'text-secondary') 12}
        if($card.Select){Select-Control ('setting-'+$card.Key) $card.Key $card.Select ($left+$col-$card.SelectWidth-16) ($y+($height-32)/2) $card.SelectWidth}
        if($card.Toggle){Toggle-Control $card.Key ($left+$col-94) ($y+($height-24)/2)}
        if($card.Button){Button ('setting-'+$card.Button) ($left+$col-146) ($y+18) 130 32 $card.Button $card.ButtonText '' $null $false $true}
        if($card.Slider){
            $sx=$left+$col-230;$sy=$y+34;$sw=170;$amount=[int]$settings.backgroundOpacity/100.0
            $ui.OpacityTrack=@($sx,$sy,$sw,4);Node 'setting-background-opacity' $sx ($sy-12) $sw 28 'opacitySlider'
            $graphics.Fill($sx,$sy,$sw,4,(Color 'border-control'),2);$graphics.Fill($sx,$sy,($sw*$amount),4,(Color 'accent-color'),2)
            $graphics.Fill(($sx+$sw*$amount-8),($sy-6),16,16,(Color 'bg-control'),8);$graphics.Fill(($sx+$sw*$amount-4),($sy-2),8,8,(Color 'accent-color'),4)
            Label ([string]$settings.backgroundOpacity+'%') ($sx+$sw+10) ($sy-8) 48 (Color 'text-primary') 13
        }
        if($card.Accordion){
            Node ('header-'+$card.Accordion) $left $y $col 51.6 'accordion' $card.Accordion
            Icon 'chevronDown' ($left+$col-34) ($y+18.8) 14 (Color 'text-secondary') $(if($expanded){180}else{0})
            if($expanded){
                $graphics.Fill(($left+16),($y+51.6),($col-32),0.8,(Color 'border-subtle'),0)
                if($card.Accordion -eq 'card-font-setting'){
                    $fy=$y+68
                    $fontOptions=@(@{Label='Family';Key='fontFamily';Options=@('Consolas','Cascadia Code','Segoe UI','Courier New');Width=130},@{Label='Style';Key='fontStyle';Options=@('Regular','Bold','Italic','Bold Italic');Width=112},@{Label='Size';Key='fontSize';Options=@('8','9','10','11','12','14','16','18','20','24','28','36');Width=68})
                    foreach($row in $fontOptions){Label $row.Label ($left+24) ($fy+7) 150 (Color 'text-primary') 13;$options=@($row.Options|ForEach-Object{@{Text=$_;Value=$_}});Select-Control ('setting-'+$row.Key) $row.Key $options ($left+$col-24-$row.Width) $fy $row.Width;$fy+=46}
                    $fy+=5;$graphics.Fill(($left+16),$fy,($col-32),70.125,$(if($ui.Theme -eq 'light'){'#f7f7f7'}else{'#202020'}),6);$graphics.Stroke(($left+16),$fy,($col-32),70.125,(Color 'border-subtle'),6,0.8)
                    $layout=$graphics.Layout('The sound of ocean waves calms my soul.',$settings.fontFamily,([int]$settings.fontSize*96/72),($col-64),$false,$(if($settings.fontStyle.Contains('Bold')){700}else{400}),$settings.fontStyle.Contains('Italic'),0)
                    try{$m=$graphics.Metrics($layout);$graphics.DrawLayout($layout,($left+($col-$m.Width)/2),($fy+(70.125-$m.Height)/2),(Color 'text-primary'))}finally{$graphics.ReleaseLayout($layout)}
                }elseif($card.Accordion -eq 'card-colors-setting'){
                    Paint-ColorControls $left ($y+66) $col
                }else{
                    $ry=$y+73
                    foreach($radio in @(@('continueSession','Continue previous session'),@('newSession','Start new session and discard unsaved changes'))){
                        Node ('radio-'+$radio[0]) ($left+24) $ry ($col-48) 26 'startup' $radio[0]
                        $selected=$settings.startupOption -eq $radio[0];$graphics.Stroke(($left+24),($ry+2),18,18,$(if($selected){Color 'accent-color'}else{'#888888'}),9,$(if($selected){2}else{1}));if($selected){$graphics.Fill(($left+28),($ry+6),10,10,(Color 'accent-color'),5)}
                        Label $radio[1] ($left+54) ($ry+2) ($col-80) (Color 'text-primary') 13;$ry+=33
                    }
                }
            }
        }
        $y+=$height+4
    }
    $y+=28
    Label 'About this app' $left $y $col (Color 'text-primary') 14 'Segoe UI' 600
    Label 'Notepad-PS1 by MansfieldPlumbing' $left ($y+30) $col (Color 'text-primary') 13
    Label 'Built by MansfieldPlumbing · 2026' $left ($y+53) $col (Color 'text-secondary') 12
    $y+=86
    foreach($link in @(@('MansfieldPlumbing / JS2PS','https://github.com/MansfieldPlumbing/JS2PS'),@('MansfieldPlumbing / QuickPS','https://github.com/MansfieldPlumbing/QuickPS'))){Label $link[0] $left $y $col (Color 'text-link') 13;Node ('link-'+$y) $left $y $col 20 'link' $link[1];$y+=27}
    $y+=24;Label 'Conformance' $left $y $col (Color 'text-primary') 14 'Segoe UI' 600
    Label 'Compare the three renderings and inspect the evidence.' $left ($y+27) $col (Color 'text-secondary') 12
    Button 'btn-open-comparison' $left ($y+55) 238 34 'openComparison' 'Compare with Windows Notepad' '' $null $false $true
    $y+=100
    if($ui.AppearanceError){Label $ui.AppearanceError $left $y $col '#e57a88' 12;$y+=40}
    $ui.SettingsExtent=$y+60+$ui.SettingsScroll-40
    $graphics.Unclip();$ui.HitClip=$null
    if($ui.SettingsExtent -gt $h-40){$track=$h-46;$thumb=[Math]::Max(24,$track*($h-40)/$ui.SettingsExtent);$ty=43+($track-$thumb)*$ui.SettingsScroll/[Math]::Max(1,$ui.SettingsExtent-$h+40);$graphics.Fill(($w-9),$ty,6,$thumb,'rgba(255,255,255,0.2)',3)}
}
function Paint-Dropdown {
    if(-not $ui.Dropdown){return}
    $drop=$ui.Dropdown;$r=$drop.Rect;$height=$drop.Options.Count*28+8;$y=$r[1]+$r[3]+2
    if($y+$height -gt $ui.Height-8){$y=[Math]::Max(42,$r[1]-$height-2)}
    $current=if($drop.Key -eq 'pickerMode'){$ui.ColorPicker.Mode}else{$settings[$drop.Key]}
    $rows=@(foreach($option in $drop.Options){@{Text=$option.Text;Action='chooseSetting';Data=@{Key=$drop.Key;Value=$option.Value};Checked=($current -eq $option.Value)}})
    Paint-MenuRows $rows $r[0] $y ([Math]::Max(160,$r[2])) ('dropdown-'+$drop.Key)
}
function Paint-Modal {
    if(-not $ui.Modal){return}
    $m=$ui.Modal;$width=[Math]::Min(440,$ui.Width*0.9);$bodyWidth=$width-48
    $messageLayout=$graphics.Layout($m.Message,'Segoe UI',13,$bodyWidth,$true,400,$false,19.5)
    try{$messageHeight=if($m.Message){($graphics.Metrics($messageLayout)).Height}else{0}
        $height=24+25.2+16+$messageHeight+16+34+24+8
        if($m.Input){$height+=54};if($null -ne $m.Markdown){$height+=[Math]::Min(380,[Math]::Max(60,($m.Markdown.Split("`n").Count*23+24)))}
        $height=[Math]::Min($height,$ui.Height-40);$x=($ui.Width-$width)/2;$y=($ui.Height-$height)/2
        $graphics.Fill(0,0,$ui.Width,$ui.Height,'rgba(0,0,0,0.5)',0);Node 'notepad-modal' 0 0 $ui.Width $ui.Height 'none' $null 'default'
        $graphics.Fill($x,$y,$width,$height,(Color 'bg-dialog'),8);$graphics.Stroke($x,$y,$width,$height,(Color 'border-control'),8,1)
        Label $m.Title ($x+24) ($y+24) $bodyWidth (Color 'text-primary') 18 'Segoe UI' 600
        $by=$y+65.2
        if($m.Message){$graphics.DrawLayout($messageLayout,($x+24),$by,(Color 'text-secondary'));$by+=$messageHeight+16}
        if($m.Input){InputBox 'dialog-input' $m.Value ($x+24) $by $bodyWidth '' 36;$by+=54}
        if($null -ne $m.Markdown){
            $previewHeight=[Math]::Max(20,$height-($by-$y)-74)
            $graphics.Fill(($x+24),$by,$bodyWidth,$previewHeight,'rgba(0,0,0,0.2)',6);$graphics.Clip(($x+24),$by,$bodyWidth,$previewHeight)
            $my=$by+12
            foreach($line in $m.Markdown.Split("`n")){
                $size=14;$weight=400;$content=$line
                if($line -match '^(#{1,3}) (.*)$'){$size=switch($Matches[1].Length){1{28};2{21};3{16.38}};$weight=700;$content=$Matches[2]}
                Label $content ($x+36) $my ($bodyWidth-24) (Color 'text-primary') $size 'Segoe UI' $weight;$my+=$size*1.4
            }
            $graphics.Unclip()
        }
        $total=0;foreach($button in $m.Buttons){$total+=[Math]::Max(66,$button.Text.Length*7+32)+8}
        $bx=$x+$width-24-$total+8;$buttonIndex=0
        foreach($button in $m.Buttons){$bw=[Math]::Max(66,$button.Text.Length*7+32);Button ('modal-button-'+$buttonIndex) $bx ($y+$height-58) $bw 34 'modalAction' $button.Text '' $button ([bool]$button.Primary) $true;$bx+=$bw+8;$buttonIndex++}
    }finally{$graphics.ReleaseLayout($messageLayout)}
}
function Paint-CanvasColorPicker {
    $p=$ui.ColorPicker;if(-not $p){return}
    # WinUI content minimum 312 DIPs + 16-DIP flyout padding on each side.
    $width=344.0;$naturalHeight=528.0;$height=[Math]::Min($naturalHeight,$ui.Height-16)
    $x=[Math]::Clamp(($p.Anchor[0]+$p.Anchor[2]-$width),8,[Math]::Max(8,$ui.Width-$width-8))
    $y=[Math]::Clamp(($p.Anchor[1]+$p.Anchor[3]+8),8,[Math]::Max(8,$ui.Height-$height-8))
    $p.PanelRect=@($x,$y,$width,$height);$p.VisibleHeight=$height;$p.Scroll=[Math]::Clamp($p.Scroll,0,[Math]::Max(0,$naturalHeight-$height))
    $graphics.Fill(($x-2),($y+4),($width+4),($height+4),'rgba(0,0,0,0.22)',9)
    $graphics.Fill($x,$y,$width,$height,(Color 'bg-flyout'),8);$graphics.Stroke($x,$y,$width,$height,(Color 'border-control'),8,1)
    Node 'picker-background' $x $y $width $height 'none' $null 'default'
    $oldClip=$ui.HitClip;$ui.HitClip=@($x,$y,$width,$height);$graphics.Clip($x,$y,$width,$height)
    $oy=$y-$p.Scroll;$sx=$x+16;$sy=$oy+16;$size=256.0
    $p.SpectrumRect=@($sx,$sy,$size,$size)
    $graphics.ColorSpectrum($sx,$sy,$size);Node 'picker-spectrum' $sx $sy $size $size 'pickerSpectrum'
    $graphics.Fill(($sx+$size+12),$sy,44,$size,$p.Hex,4)
    $mx=$sx+$p.H/360*$size;$my=$sy+(1-$p.S)*$size
    $graphics.Circle($mx,$my,7,'#ffffff',2);$graphics.Circle($mx,$my,8,'rgba(0,0,0,0.65)',1)
    $vx=$x+16;$vy=$oy+300;$vw=$width-32;$p.ValueRect=@($vx,$vy,$vw,16)
    $pure=Convert-HsvToHex $p.H $p.S 1
    $graphics.FourCorner($vx,$vy,$vw,12,[string[]]@('#000000',$pure,'#000000',$pure),1)
    Node 'picker-value' $vx ($vy-6) $vw 26 'pickerValue'
    $graphics.Circle(($vx+$vw*$p.V),($vy+6),7,(Color 'bg-control'),0);$graphics.Circle(($vx+$vw*$p.V),($vy+6),5,'#ffffff',0)
    $p.ModeRect=@(($x+16),($oy+328),120,36);Button 'picker-mode' ($x+16) ($oy+328) 120 36 'pickerMode' '' '' $null $false $true
    Label $p.Mode ($x+28) ($oy+337) 80 (Color 'text-primary') 16;Icon 'chevronDown' ($x+112) ($oy+341) 10
    InputBox 'picker-input-hex' $p.Inputs.hex ($x+196) ($oy+328) 132 '' 36 16
    $labels=if($p.Mode -eq 'RGB'){@('Red','Green','Blue')}else{@('Hue','Saturation','Value')}
    for($i=0;$i -lt 3;$i++){$iy=$oy+376+$i*48;InputBox ('picker-input-c'+$i) $p.Inputs['c'+$i] ($x+16) $iy 120 '' 36 16;Label $labels[$i] ($x+144) ($iy+8) 170 (Color 'text-primary') 16}
    $graphics.Unclip();$ui.HitClip=$oldClip
    if($height -lt $naturalHeight){$track=$height-16;$thumb=$track*$height/$naturalHeight;$ty=$y+8+($track-$thumb)*$p.Scroll/($naturalHeight-$height);$graphics.Fill(($x+$width-7),$ty,4,$thumb,'rgba(255,255,255,0.3)',2)}
}
function Paint-Tooltip {
    if(-not $ui.TooltipShown -or $ui.Hover -ne 'btn-copy-document' -or $ui.Settings -or $ui.Modal){return}
    $r=$ui.Nodes['btn-copy-document'].Rect;$width=if($settings.copyAsFile){228}else{164}
    $x=[Math]::Clamp(($r[0]+$r[2]/2-$width/2),8,[Math]::Max(8,$ui.Width-$width-8));$y=$r[1]+$r[3]+7
    $graphics.Fill(($x+1),($y+3),$width,32,'rgba(0,0,0,0.2)',4)
    $graphics.Fill($x,$y,$width,30,(Color 'bg-flyout'),4);$graphics.Stroke($x,$y,$width,30,(Color 'border-control'),4,1)
    Label $(if($settings.copyAsFile){'Copy whole document as .txt file'}else{'Copy whole document'}) ($x+10) ($y+7) ($width-20) (Color 'text-primary') 12
}
function Paint {
    $ui.NextHits=[Collections.Generic.List[object]]::new()
    $graphics.Begin((Color 'bg-window'),$(if($ui.BackdropActive){[single]0}else{[single]1}))
    if($settings.gradientEnabled){$graphics.FourCorner(0,0,$ui.Width,$ui.Height,[string[]]@($settings.colors.topLeft,$settings.colors.topRight,$settings.colors.bottomLeft,$settings.colors.bottomRight),[single]$(if($ui.BackdropActive){[int]$settings.backgroundOpacity/100.0}else{1.0}))}
    if($ui.Settings){Paint-Settings}else{Paint-Editor;Paint-Chrome;Paint-Find;Paint-Menus}
    Paint-CanvasColorPicker;Paint-Dropdown;Paint-Tooltip;Paint-Modal
    $graphics.End()
    $ui.Generation++;$ui.Hits=$ui.NextHits;$ui.Dirty=$false
    Write-ApplicationDiagnostic
    if($ui.TextCache.Count -gt 1000){foreach($layout in $ui.TextCache.Values){$graphics.ReleaseLayout($layout)};$ui.TextCache.Clear()}
}
function Hit([double]$X,[double]$Y){
    for($i=$ui.Hits.Count-1;$i -ge 0;$i--){$node=$ui.Hits[$i];$r=$node.Rect;if($node.Clip){$c=$node.Clip;if($X -lt $c[0] -or $Y -lt $c[1] -or $X -ge $c[0]+$c[2] -or $Y -ge $c[1]+$c[3]){continue}};if($X -ge $r[0] -and $Y -ge $r[1] -and $X -lt $r[0]+$r[2] -and $Y -lt $r[1]+$r[3]){return $node}}
}
function Editor-Hit([double]$X,[double]$Y,[bool]$Extend=$false){
    $hit=$graphics.HitText($ui.EditorLayout,($X-$ui.EditorOrigin[0]),($Y-$ui.EditorOrigin[1]));$tab=$model.Active()
    $anchor=if($Extend){$tab.Anchor}else{$hit.Position};$model.Select($anchor,$hit.Position);$ui.Focus='editor-area';Invalidate $true
}
function Key-Input($Event){
    $key=[int]$Event.W;$ctrl=$Event.Ctrl;$shift=$Event.Shift
    if($key -eq 27){if($ui.Dropdown){$ui.Dropdown=$null}elseif($ui.ColorPicker){$ui.ColorPicker=$null;$ui.Focus='settings';Persist}elseif($ui.Modal){$ui.Modal=$null;$ui.Focus='editor-area'}elseif($ui.ComparisonView){$ui.ComparisonView=$false;$ui.Focus='settings'}elseif($ui.Menu){$ui.Menu='';$ui.Submenu=''}elseif($ui.Find){$ui.Find=$false;$ui.Focus='editor-area'}elseif($ui.Settings){$ui.Settings=$false;$ui.Focus='editor-area'};Invalidate;return}
    if($ui.ColorPicker -and $key -eq 9){$fields=@('picker-input-hex','picker-input-c0','picker-input-c1','picker-input-c2');$index=[array]::IndexOf($fields,$ui.Focus);$index=($index+$(if($shift){3}else{1}))%4;Focus-Input $fields[$index];Invalidate;return}
    if($ui.ComparisonView){
        if($key -eq 116){Start-Comparison}
        elseif($key -in @(33,34,38,40)){$step=if($key -in @(33,34)){240}else{32};if($key -in @(33,38)){$step=-$step};$ui.ComparisonScroll=[Math]::Clamp($ui.ComparisonScroll+$step,0,[Math]::Max(0,$ui.ComparisonExtent-($ui.Height-215)));Invalidate}
        return
    }
    if($ui.Focus -eq 'opacity-slider' -and $key -in @(37,39,36,35,33,34)){
        $settings.backgroundOpacity=switch($key){36{0};35{100};37{[Math]::Max(0,[int]$settings.backgroundOpacity-1)};39{[Math]::Min(100,[int]$settings.backgroundOpacity+1)};33{[Math]::Min(100,[int]$settings.backgroundOpacity+10)};34{[Math]::Max(0,[int]$settings.backgroundOpacity-10)}}
        Persist;Invalidate;return
    }
    if($ui.Modal -and $ui.Focus -ne 'dialog-input'){
        if($key -eq 13){$button=$ui.Modal.Buttons|Where-Object Primary|Select-Object -First 1;if(-not $button){$button=$ui.Modal.Buttons[0]};$ui.Modal=$null;Command $button.Action $button.Data};return
    }
    if($ui.Focus -in @('find-query-input','replace-query-input','dialog-input') -or ($ui.ColorPicker -and $ui.Focus.StartsWith('picker-input-'))){
        $value=Input-Value $ui.Focus
        if($ctrl -and $key -eq 65){$ui.InputAnchor=0;$ui.InputFocus=$value.Length}
        elseif($ctrl -and $key -eq 86){Input-Insert $services.ReadClipboard()}
        elseif($ctrl -and $key -in @(67,88)){$start=[Math]::Min($ui.InputAnchor,$ui.InputFocus);$len=[Math]::Abs($ui.InputFocus-$ui.InputAnchor);$services.WriteClipboard($value.Substring($start,$len));if($key -eq 88){Input-Insert ''}}
        elseif($key -in @(8,46)){
            if($ui.InputAnchor -eq $ui.InputFocus){if($key -eq 8 -and $ui.InputFocus -gt 0){$ui.InputAnchor--}elseif($key -eq 46 -and $ui.InputFocus -lt $value.Length){$ui.InputAnchor++}}
            Input-Insert ''
        }elseif($key -in @(37,39,36,35)){
            $pos=switch($key){37{[Math]::Max(0,$ui.InputFocus-1)};39{[Math]::Min($value.Length,$ui.InputFocus+1)};36{0};35{$value.Length}};$ui.InputFocus=$pos;if(-not $shift){$ui.InputAnchor=$pos}
        }elseif($key -eq 13){if($ui.ColorPicker){if(-not $ui.ColorPicker.Invalid){$ui.ColorPicker=$null;$ui.Focus='settings';Persist}}elseif($ui.Focus -eq 'dialog-input'){$m=$ui.Modal;$ui.Modal=$null;$button=$m.Buttons|Where-Object Primary|Select-Object -First 1;Command $button.Action $m.Value}elseif($shift){$model.SelectMatch(-1)}else{$model.SelectMatch(1)}}
        elseif($key -eq 9){if($ui.Focus -eq 'find-query-input' -and $ui.Replace){Focus-Input 'replace-query-input'}else{$ui.Focus='editor-area'}}
        Invalidate $true;return
    }
    if($ctrl){
        if($settings.formatting -and $key -in @(66,73,75) -or ($ctrl -and $shift -and $key -eq 88)){$action=switch($key){66{'formatBold'};73{'formatItalic'};75{'formatLink'};88{'formatStrike'}};Command $action;return}
        $action=switch($key){78{if($shift){'newWindow'}else{'newTab'}};79{'openFile'};83{if($Event.Alt){'saveAll'}elseif($shift){'saveAs'}else{'save'}};87{if($shift){'closeWindow'}else{'closeTab'}};70{'find'};72{'replace'};71{'goTo'};80{'print'};65{'selectAll'};67{'copy'};88{'cut'};86{'paste'};90{if($shift){'redo'}else{'undo'}};89{'redo'};187{'zoomIn'};107{'zoomIn'};189{'zoomOut'};109{'zoomOut'};48{'zoomReset'}}
        if($action){Command $action;return}
    }
    if($key -eq 114){Command $(if($shift){'findPrevious'}else{'findNext'});return}
    if($key -eq 116){Command 'timeDate';return}
    if($ui.Focus -ne 'editor-area' -or $ui.Settings){return}
    switch($key){
        8{$model.Delete($true)};46{$model.Delete($false)}
        37{$model.Move('left',$shift,$ctrl)};39{$model.Move('right',$shift,$ctrl)}
        36{$model.Move('home',$shift,$ctrl)};35{$model.Move('end',$shift,$ctrl)}
        {$_ -in @(38,40,33,34)}{
            $tab=$model.Active();$caret=$graphics.Caret($ui.EditorLayout,$tab.Focus,$false);$distance=if($key -in @(33,34)){$ui.EditorRect[3]-28}else{$caret.Height};$dy=if($key -in @(38,33)){-$distance}else{$distance}
            $hit=$graphics.HitText($ui.EditorLayout,$caret.X,($caret.Y+$caret.Height/2+$dy));$model.Select($(if($shift){$tab.Anchor}else{$hit.Position}),$hit.Position)
        }
    }
    Invalidate $true
}
function Handle-Event($Event){
    if($Event.Kind -eq 'minimized'){$ui.Minimized=$true;Write-ApplicationDiagnostic;return}
    if($Event.Kind -eq 'close'){Request-Close;return}
    if($Event.Kind -eq 'paint'){Invalidate;return}
    if($Event.Kind -in @('focus','blur')){$ui.Focused=$Event.Kind -eq 'focus';Invalidate;return}
    if($Event.Kind -eq 'resize'){
        $info=$window.Info()
        if($info.Minimized){$ui.Minimized=$true;return}
        $wasMinimized=$ui.Minimized;$ui.Minimized=$false
        if($info.Dpi -eq $ui.Dpi -and $info.Width -eq [int][Math]::Round($ui.Width*$ui.Dpi/96) -and $info.Height -eq [int][Math]::Round($ui.Height*$ui.Dpi/96)){if($wasMinimized){Invalidate};return}
        $ui.Dpi=$info.Dpi;$ui.Width=$info.Width*96/$info.Dpi;$ui.Height=$info.Height*96/$info.Dpi
        $graphics.Resize($info.Width,$info.Height,$info.Dpi);Invalidate $true;return
    }
    if($Event.Kind -ne 'input'){return}
    $msg=$Event.Message
    if($msg -in @(0x100,0x104)){Key-Input $Event;return}
    if($msg -eq 0x102){
        if(($Event.Ctrl -or $Event.Alt) -and $Event.W -lt 32){return};$char=[char]$Event.W
        if($Event.W -in @(8,27) -or ($Event.W -lt 32 -and $Event.W -notin @(9,13))){return}
        if([char]::IsHighSurrogate($char)){$ui.PendingHigh=[string]$char;return}
        $text=[string]$char;if([char]::IsLowSurrogate($char) -and $ui.PendingHigh){$text=$ui.PendingHigh+$text};$ui.PendingHigh=''
        if($ui.Focus -eq 'editor-area' -and -not $ui.Modal -and -not $ui.Settings){if($Event.W -eq 13){$text="`n"};$model.Insert($text,($text -ne "`n" -and $text -ne "`t"))}
        elseif(($ui.Focus -in @('find-query-input','replace-query-input','dialog-input') -or ($ui.ColorPicker -and $ui.Focus.StartsWith('picker-input-'))) -and $Event.W -ge 32){Input-Insert $text}
        Invalidate $true;return
    }
    $px=[int]($Event.L -band 0xffff);if($px -ge 32768){$px-=65536};$py=[int](($Event.L -shr 16)-band 0xffff);if($py -ge 32768){$py-=65536}
    $x=$px*96/$ui.Dpi;$y=$py*96/$ui.Dpi
    if($msg -eq 0x20A){
        $delta=[int](($Event.W -shr 16)-band 0xffff);if($delta -ge 32768){$delta-=65536}
        if($ui.ColorPicker){$ui.ColorPicker.Scroll=[Math]::Clamp($ui.ColorPicker.Scroll-$delta/120*48,0,[Math]::Max(0,528-$ui.ColorPicker.VisibleHeight));Invalidate}
        elseif($Event.Ctrl -and $Event.Shift){$settings.backgroundOpacity=[Math]::Clamp([int]$settings.backgroundOpacity+$(if($delta -gt 0){5}else{-5}),0,100);Persist;Invalidate}
        elseif($Event.Ctrl){Command $(if($delta -gt 0){'zoomIn'}else{'zoomOut'})}
        elseif($ui.ComparisonView){$ui.ComparisonScroll=[Math]::Clamp($ui.ComparisonScroll-$delta/120*72,0,[Math]::Max(0,$ui.ComparisonExtent-($ui.Height-215)));Invalidate}
        elseif($ui.Settings){$ui.SettingsScroll=[Math]::Clamp($ui.SettingsScroll-$delta/120*72,0,[Math]::Max(0,$ui.SettingsExtent-$ui.Height+40));Invalidate}
        elseif(-not $ui.Modal){$tab=$model.Active();$tab.ScrollY=[Math]::Max(0,$tab.ScrollY-$delta/120*64);$ui.EnsureCaret=$false;Invalidate}
        $ui.ScrollSequence++;Invalidate;return
    }
    $hit=Hit $x $y;$id=if($hit){$hit.Id}else{''}
    if($msg -eq 0x200){
        if($ui.ColorDrag){Set-ColorPickerPoint $ui.ColorDrag $x $y;return}
        if($ui.SliderDrag){Set-OpacityFromPoint $x;return}
        if($ui.Hover -ne $id){$ui.Hover=$id;$ui.HoverSince=[DateTime]::UtcNow;$ui.TooltipShown=$false;Invalidate
            if($hit -and $hit.Action -eq 'submenu'){$ui.Submenu=$hit.Data;Invalidate}
            if($ui.Menu -and $id.StartsWith('menu-btn-')){$ui.Menu=$hit.Data;$ui.Submenu='';Invalidate}
        }
        $window.Cursor($(if($hit){$hit.Cursor}else{'default'}))
        if($ui.Drag){Editor-Hit $x $y $true}
        return
    }
    if($msg -in @(0x201,0x203)){
        if($ui.ColorPicker -and -not $id.StartsWith('picker-') -and -not $id.StartsWith('dropdown-pickerMode')){$ui.ColorPicker=$null;$ui.Dropdown=$null;$ui.Focus='settings';Invalidate;return}
        if($ui.Dropdown -and -not $id.StartsWith('dropdown-')){$ui.Dropdown=$null;Invalidate;return}
        if($ui.Menu -and -not $id.StartsWith('flyout-') -and -not $id.StartsWith('menu-btn-')){$ui.Menu='';$ui.Submenu='';Invalidate}
        $ui.Pressed=$id;Invalidate
        if($hit -and $hit.Action -in @('pickerSpectrum','pickerValue')){$ui.ColorDrag=if($hit.Action -eq 'pickerSpectrum'){'spectrum'}else{'value'};$window.Capture($true);Set-ColorPickerPoint $ui.ColorDrag $x $y;return}
        if($hit -and $hit.Action -eq 'opacitySlider'){$ui.SliderDrag=$true;$ui.Focus='opacity-slider';$window.Capture($true);Set-OpacityFromPoint $x;return}
        if($hit -and $hit.Action -eq 'editor'){
            Editor-Hit $x $y $Event.Shift
            if($msg -eq 0x203){$tab=$model.Active();$pos=$tab.Focus;$start=$pos;$end=$pos;while($start -gt 0 -and -not [char]::IsWhiteSpace($tab.Text[$start-1])){$start--};while($end -lt $tab.Text.Length -and -not [char]::IsWhiteSpace($tab.Text[$end])){$end++};$model.Select($start,$end)}
            $ui.Drag=$true;$window.Capture($true)
        }elseif($hit -and $hit.Action -eq 'drag'){$window.Caption('drag')}
        return
    }
    if($msg -eq 0x202){
        if($ui.ColorDrag){Set-ColorPickerPoint $ui.ColorDrag $x $y;$ui.ColorDrag='';$ui.Pressed='';$window.Capture($false);$ui.ClickSequence++;Persist;Invalidate;return}
        if($ui.SliderDrag){Set-OpacityFromPoint $x;$ui.SliderDrag=$false;$ui.Pressed='';$window.Capture($false);$ui.ClickSequence++;Persist;Invalidate;return}
        if($ui.Drag){$ui.Drag=$false;$window.Capture($false)}
        if($hit -and $id -eq $ui.Pressed -and $hit.Action -notin @('editor','drag')){
            if($hit.Action -eq 'modalAction'){$button=$hit.Data;$value=$ui.Modal.Value;$ui.Modal=$null;Command $button.Action $(if($button.Action -in @('gotoConfirm','insertLink')){$value}else{$button.Data})}
            else{if($id.StartsWith('flyout-') -and $hit.Action -ne 'submenu'){$ui.Menu='';$ui.Submenu=''};Command $hit.Action $hit.Data}
        }
        $ui.Pressed='';$ui.ClickSequence++;Invalidate
    }
}

Resolve-Theme
if($ui.ComparisonView){Load-ComparisonResults}
try{
    $window=& "$PSScriptRoot\src\Window.Windows.ps1" -Native $native -Width $Width -Height $Height
    $info=$window.Info();$ui.Dpi=$info.Dpi;$ui.Width=$info.Width*96/$info.Dpi;$ui.Height=$info.Height*96/$info.Dpi
    $graphics=& "$PSScriptRoot\src\Graphics.Windows.ps1" -Native $native -Hwnd $window.Handle() -Width $info.Width -Height $info.Height -Dpi $info.Dpi
    $services=& "$PSScriptRoot\src\Services.Windows.ps1" -Native $native -Hwnd $window.Handle()
    Apply-WindowAppearance
    Apply-WindowIcon
    if(-not $NoAnimation){$ui.BackdropActive=$false}
    if(-not $NoAnimation){$ui.Entrance=$window.BeginEntrance();$initialEntrance=$window.Entrance(0);$null=Entrance-Easing 0.5}
    # Paint the entire first frame before the HWND becomes visible.
    Paint
    # A hidden PowerShell host can override the first ShowWindow call through STARTUPINFO.
    $window.Show();$window.Show();$start=[DateTime]::UtcNow
    foreach($event in @($window.Drain())){Handle-Event $event}
    if(-not $NoAnimation){$ui.EntranceStatus='Animating';$ui.EntranceStart=[DateTime]::UtcNow;$initialEntrance.ElapsedMs=0;$initialEntrance.TimeProgress=0;$ui.EntranceSamples.Add($initialEntrance)}
    else{$ui.EntranceStatus='Skipped'}
    while($ui.Running -and $window.Info().Alive){
        foreach($event in @($window.Drain())){Handle-Event $event}
        Update-Comparison
        $now=[DateTime]::UtcNow
        if($ui.Hover -eq 'btn-copy-document' -and -not $ui.TooltipShown -and ($now-$ui.HoverSince).TotalMilliseconds -ge 450){$ui.TooltipShown=$true;Invalidate}
        if($ui.EntranceStatus -eq 'Animating'){
            $elapsed=($now-$ui.EntranceStart).TotalMilliseconds;$progress=[Math]::Clamp($elapsed/$ui.Entrance.DurationMs,0.0,1.0)
            $eased=if($progress -ge 1){1.0}else{Entrance-Easing $progress}
            $sample=$window.Entrance($eased);$sample.ElapsedMs=$elapsed;$sample.TimeProgress=$progress
            $ui.EntranceSamples.Add($sample)
            if($progress -ge 1){$ui.EntranceRestore=$window.EndEntrance();Apply-WindowAppearance;$ui.EntranceStatus='Completed';Invalidate}
        }
        if(($now-$ui.LastBlink).TotalMilliseconds -ge 530){$ui.Blink=-not $ui.Blink;$ui.LastBlink=$now;if($ui.Focus -in @('editor-area','find-query-input','replace-query-input','dialog-input')){Invalidate}}
        if($ui.Dirty -and -not $ui.Minimized -and $ui.Width -gt 0 -and $ui.Height -gt 0 -and $ui.EntranceStatus -ne 'Animating'){Paint}
        if(($now-$ui.LastSession).TotalSeconds -ge 2){Persist;$ui.LastSession=$now}
        if($RunSeconds -gt 0 -and ($now-$start).TotalSeconds -ge $RunSeconds){$ui.Running=$false}
        Start-Sleep -Milliseconds 8
    }
    Persist
}catch{
    $_|Out-String|Set-Content (Join-Path $PSScriptRoot 'artifacts\last-error.txt');throw
}finally{
    Write-ApplicationDiagnostic
    if($graphics){$graphics.Dispose()};if($window){$window.Dispose()};$native.Dispose()
}
