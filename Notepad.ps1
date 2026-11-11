[CmdletBinding()]
[SingleThreadedApartment()]
[ApplicationIcon('Notepad.ico')]
param(
    [string]$Path,[int]$Width=1280,[int]$Height=720,[switch]$NoSession,[int]$RunSeconds=0,[string]$DiagnosticPath,
    [switch]$Compare,[string]$UIAutomationTestDataDirectory,
    [switch]$RefreshReal,[switch]$SkipBrowser,[switch]$KeepProbeOpen,
    [switch]$ExtractTypeScript,[switch]$BuildTypeScript,[switch]$BuildDesign,[switch]$VerifyNativeFeatures,[switch]$CatalogIcons,
    [ValidateSet('editor','settings')][string]$StartPage='editor',
    [ValidateSet('solid','mica','acrylic','reverseMica')][string]$Backdrop,
    [ValidateSet('curved','straight')][string]$CornerStyle,[switch]$NoAnimation,
    [switch]$VerifyModel,[switch]$VerifyGraphics,[switch]$VerifyWindow
)

# Folded from src\Model.ps1
# The editor model. A document's text, selection and history; the find state; the open documents.
class NotepadTab {
    [int]$Id
    [string]$Title
    # The text as a piece table: the text as opened, an append-only buffer of additions, and a journal of edits.
    [NotepadDocument]$Document
    [string]$Path
    [bool]$Markdown
    [string]$LineEnding
    [string]$Encoding = 'UTF-8'
    [bool]$Bom
    [bool]$Modified
    [int]$Revision
    [int]$Anchor
    [int]$Focus
    [double]$ScrollX
    [double]$ScrollY
    [datetime]$LastEdit = [datetime]::MinValue
    # Where the last typed text ended: typing joins the previous undo group only when it continues from there.
    [int]$LastEditEnd = -1
    # Modified is measured against the document's journal position at the last open or save, and the line ending
    # then. SavedKnown is false when that saved state is unknown: a file tab restored modified from a session, or an
    # untitled tab created with text.
    [string]$SavedLineEnding = 'Windows (CRLF)'
    [bool]$SavedKnown = $true

    [int] Length() { return $this.Document.Length }
    [string] Slice([int]$start, [int]$count) { return $this.Document.GetText($start, $count) }
    [string] Content() { return $this.Document.GetText(0, $this.Document.Length) }
    [char] At([int]$position) { return $this.Document.At($position) }

    # Modified when the journal or line ending differs from the last open or save. An untitled tab with no text is
    # never modified.
    [void] RefreshModified() {
        if (-not $this.Path -and $this.Document.Length -eq 0) { $this.Modified = $false; return }
        $this.Modified = -not $this.SavedKnown -or $this.Document.Modified() -or $this.LineEnding -cne $this.SavedLineEnding
    }

    # The title the tab shows: its file name once it has a file; before that the first line with text (looked for in
    # the first 400 characters), up to 40 characters, as Windows Notepad shows it; the stored title ("Untitled") while
    # there is none.
    [string] Caption() {
        if ($this.Path) { return $this.Title }
        $head = $this.Slice(0, [Math]::Min($this.Document.Length, 400))
        $start = 0
        while ($start -lt $head.Length -and [char]::IsWhiteSpace($head[$start])) { $start++ }
        if ($start -ge $head.Length) { return $this.Title }
        $end = $head.IndexOf([char]10, $start)
        if ($end -lt 0) { $end = $head.Length }
        return $head.Substring($start, [Math]::Min($end - $start, 40)).TrimEnd()
    }
}

class NotepadMatch {
    [int]$Start
    [int]$End
}

class NotepadFind {
    [string]$Query = ''
    [string]$Replacement = ''
    [bool]$MatchCase = $false
    [bool]$Wrap = $true
    [NotepadMatch[]]$Matches = [NotepadMatch[]]::new(0)
    [int]$Index = -1
    # Matches are kept current while the Find bar is open; after an edit with it closed they are stale until the next
    # search needs them, so typing never searches the whole document.
    [bool]$Open = $false
    [bool]$Stale = $false
}

class NotepadModelState {
    [NotepadSettings]$Settings
    [Collections.Generic.List[NotepadTab]]$Tabs = [Collections.Generic.List[NotepadTab]]::new()
    [int]$ActiveId = 0
    [int]$NextId = 1
    [NotepadFind]$Find = [NotepadFind]::new()
}

class NotepadStatus {
    [int]$Line
    [int]$Column
    [int]$Characters
    [int]$Selected
}

class NotepadSaved {
    [string]$Outcome
    [int]$Id
    [string]$Path
}

class NotepadModel {
    hidden [NotepadModelState]$modelState

    NotepadModel([NotepadSettings]$Settings) { $this.modelState = [NotepadModelState]::new(); $this.modelState.Settings = $Settings }

    [NotepadModelState] State() { return $this.modelState }

    [NotepadTab] Active() {
        foreach ($tab in $this.modelState.Tabs) { if ($tab.Id -eq $this.modelState.ActiveId) { return $tab } }
        return $null
    }

    [NotepadTab] NewTab() { return $this.NewTab('Untitled', '', '', $false) }
    [NotepadTab] NewTab([string]$Title) { return $this.NewTab($Title, '', '', $false) }
    [NotepadTab] NewTab([string]$Title, [string]$Text) { return $this.NewTab($Title, $Text, '', $false) }
    [NotepadTab] NewTab([string]$Title, [string]$Text, [string]$Path) { return $this.NewTab($Title, $Text, $Path, $false) }
    [NotepadTab] NewTab([string]$Title, [string]$Text, [string]$Path, [bool]$Markdown) {
        # New documents use Windows line endings. Only an opened LF file selects LF mode.
        $lineEnding = 'Windows (CRLF)'
        if ($Path -and $Text.Contains("`n") -and -not $Text.Contains("`r`n")) { $lineEnding = 'Unix (LF)' }
        $tab = [NotepadTab]::new()
        $tab.Id = $this.modelState.NextId
        $this.modelState.NextId = $this.modelState.NextId + 1
        $tab.Title = $Title
        $tab.Document = [NotepadDocument]::new($Text.Replace("`r`n", "`n").Replace("`r", "`n"))
        $tab.Path = $Path
        $tab.Markdown = $Markdown
        $tab.LineEnding = $lineEnding
        # An opened file starts unmodified; an untitled tab created with text has never been saved.
        if (-not $Path -and $tab.Document.Length -gt 0) { $tab.SavedKnown = $false }
        $tab.SavedLineEnding = $lineEnding
        $tab.RefreshModified()
        $this.modelState.Tabs.Add($tab)
        $this.modelState.ActiveId = $tab.Id
        return $tab
    }

    hidden [NotepadTab] Tab([int]$Id) {
        foreach ($tab in $this.modelState.Tabs) { if ($tab.Id -eq $Id) { return $tab } }
        return $null
    }

    [void] SwitchTab([int]$Id) {
        if ($null -ne $this.Tab($Id)) { $this.modelState.ActiveId = $Id; $this.Find() }
    }

    [void] CloseTab([int]$Id) {
        for ($i = 0; $i -lt $this.modelState.Tabs.Count; $i++) {
            if ($this.modelState.Tabs[$i].Id -eq $Id) {
                $this.modelState.Tabs.RemoveAt($i)
                if ($this.modelState.ActiveId -eq $Id -and $this.modelState.Tabs.Count) { $this.modelState.ActiveId = $this.modelState.Tabs[[Math]::Max(0, $i - 1)].Id }
                break
            }
        }
        if (-not $this.modelState.Tabs.Count) { $null = $this.NewTab() }
        $this.Find()
    }

    [void] Select([int]$Anchor, [int]$Focus) {
        $tab = $this.Active()
        $tab.Anchor = [Math]::Clamp($Anchor, 0, $tab.Document.Length)
        $tab.Focus = [Math]::Clamp($Focus, 0, $tab.Document.Length)
    }

    # Replaces the selection with text as one edit in the document's journal. Typing within 700 ms of the last edit
    # with nothing selected joins the same undo group.
    [void] Insert([string]$Text) { $this.Insert($Text, $false) }
    [void] Insert([string]$Text, [bool]$Coalesce) {
        $tab = $this.Active()
        $start = [Math]::Min($tab.Anchor, $tab.Focus)
        $end = [Math]::Max($tab.Anchor, $tab.Focus)
        $Text = $Text.Replace("`r`n", "`n").Replace("`r", "`n")
        if ($Text.Length -eq 0 -and $start -eq $end) { return }
        # A new undo group unless this continues typing: within 700 ms, nothing selected, and right where the last
        # typed text ended (a click elsewhere starts a new group).
        if (-not $Coalesce -or ([DateTime]::UtcNow - $tab.LastEdit).TotalMilliseconds -gt 700 -or $start -ne $end -or $start -ne $tab.LastEditEnd) { $tab.Document.BeginGroup() }
        $tab.Document.Replace($start, $end - $start, $Text)
        $tab.Focus = $start + $Text.Length
        $tab.Anchor = $tab.Focus
        $tab.LastEditEnd = $tab.Focus
        $tab.RefreshModified()
        $tab.Revision = $tab.Revision + 1
        $tab.LastEdit = [DateTime]::UtcNow
        $this.RefreshFind()
    }

    # After an edit: search again while the Find bar is open; otherwise mark the matches stale for the next search.
    hidden [void] RefreshFind() {
        if ($this.modelState.Find.Open) { $this.Find() } else { $this.modelState.Find.Stale = $true }
    }

    # The next grapheme boundary before or after a position, read from a window of 32 characters on each side of it
    # rather than the whole text.
    hidden [int] Boundary([NotepadTab]$Tab, [int]$Position, [int]$Direction) {
        $from = [Math]::Max(0, $Position - 32)
        $to = [Math]::Min($Tab.Document.Length, $Position + 32)
        $local = $Position - $from
        $offsets = [Globalization.StringInfo]::ParseCombiningCharacters($Tab.Slice($from, $to - $from))
        if ($Direction -lt 0) {
            for ($i = $offsets.Length - 1; $i -ge 0; $i--) { if ($offsets[$i] -lt $local) { return $from + $offsets[$i] } }
            return $from
        }
        foreach ($offset in $offsets) { if ($offset -gt $local) { return $from + $offset } }
        return $to
    }

    [void] Delete([bool]$Backspace) {
        $tab = $this.Active()
        if ($tab.Anchor -eq $tab.Focus) {
            $direction = 1
            if ($Backspace) { $direction = -1 }
            $other = $this.Boundary($tab, $tab.Focus, $direction)
            if ($other -eq $tab.Focus) { return }
            $tab.Anchor = $other
        }
        $this.Insert('')
    }

    [void] Undo() { $this.Undo($false) }
    # Undo or redo walks the document's journal one group at a time; the caret lands after the restored text.
    [void] Undo([bool]$Redo) {
        $tab = $this.Active()
        $caret = -1
        if ($Redo) { $caret = $tab.Document.Redo() } else { $caret = $tab.Document.Undo() }
        if ($caret -lt 0) { return }
        $tab.Anchor = $caret
        $tab.Focus = $caret
        $tab.LastEditEnd = -1
        $tab.RefreshModified()
        $tab.Revision = $tab.Revision + 1
        $tab.LastEdit = [DateTime]::MinValue
        $this.RefreshFind()
    }

    [void] Move([string]$Direction) { $this.Move($Direction, $false, $false) }
    [void] Move([string]$Direction, [bool]$Extend) { $this.Move($Direction, $Extend, $false) }
    [void] Move([string]$Direction, [bool]$Extend, [bool]$Word) {
        $tab = $this.Active()
        $pos = $tab.Focus
        if ($Direction -eq 'left' -and -not $Extend -and $tab.Anchor -ne $pos) { $pos = [Math]::Min($tab.Anchor, $pos) }
        elseif ($Direction -eq 'right' -and -not $Extend -and $tab.Anchor -ne $pos) { $pos = [Math]::Max($tab.Anchor, $pos) }
        else {
            switch ($Direction) {
                'left' {
                    $pos = $this.Boundary($tab, $pos, -1)
                    if ($Word) {
                        while ($pos -gt 0 -and $pos -lt $tab.Document.Length -and [char]::IsWhiteSpace($tab.At($pos))) { $pos = $this.Boundary($tab, $pos, -1) }
                        while ($pos -gt 0 -and -not [char]::IsWhiteSpace($tab.At($pos - 1))) { $pos = $this.Boundary($tab, $pos, -1) }
                    }
                }
                'right' {
                    $pos = $this.Boundary($tab, $pos, 1)
                    if ($Word) {
                        while ($pos -lt $tab.Document.Length -and -not [char]::IsWhiteSpace($tab.At($pos))) { $pos = $this.Boundary($tab, $pos, 1) }
                        while ($pos -lt $tab.Document.Length -and [char]::IsWhiteSpace($tab.At($pos))) { $pos = $this.Boundary($tab, $pos, 1) }
                    }
                }
                'home' {
                    if ($Word) { $pos = 0 } else { $pos = $tab.Document.LineStart($tab.Document.LineOf($pos)) }
                    if ($tab.Focus -eq 0) { $pos = 0 }
                }
                'end' {
                    if ($Word) { $pos = $tab.Document.Length }
                    else {
                        $line = $tab.Document.LineOf($pos)
                        if ($line + 1 -ge $tab.Document.LineCount()) { $pos = $tab.Document.Length } else { $pos = $tab.Document.LineStart($line + 1) - 1 }
                    }
                }
            }
        }
        $tab.Focus = $pos
        if (-not $Extend) { $tab.Anchor = $pos }
        $tab.LastEdit = [DateTime]::MinValue
    }

    [NotepadStatus] Status() {
        $tab = $this.Active()
        $start = [Math]::Min($tab.Anchor, $tab.Focus)
        # Line and column from the document's line index, not by splitting the text.
        $line = $tab.Document.LineOf($start)
        $status = [NotepadStatus]::new()
        $status.Line = $line + 1
        $status.Column = $start - $tab.Document.LineStart($line) + 1
        $status.Characters = $tab.Document.Length
        $status.Selected = [Math]::Abs($tab.Focus - $tab.Anchor)
        return $status
    }

    [void] Find() {
        $tab = $this.Active()
        if ($null -eq $tab) { return }
        $find = $this.modelState.Find
        $find.Matches = [NotepadMatch[]]::new(0)
        $find.Index = -1
        $find.Stale = $false
        if (-not $find.Query) { return }
        $comparison = [StringComparison]::OrdinalIgnoreCase
        if ($find.MatchCase) { $comparison = [StringComparison]::Ordinal }
        $positions = [Collections.Generic.List[NotepadMatch]]::new()
        $content = $tab.Content()
        $offset = 0
        while ($offset -le $content.Length - $find.Query.Length) {
            $index = $content.IndexOf($find.Query, $offset, $comparison)
            if ($index -lt 0) { break }
            $match = [NotepadMatch]::new()
            $match.Start = $index
            $match.End = $index + $find.Query.Length
            $positions.Add($match)
            $offset = $index + $find.Query.Length
        }
        $find.Matches = $positions.ToArray()
        if ($positions.Count) {
            $find.Index = 0
            for ($i = 0; $i -lt $positions.Count; $i++) { if ($positions[$i].Start -ge [Math]::Min($tab.Anchor, $tab.Focus)) { $find.Index = $i; break } }
        }
    }

    [void] SelectMatch() { $this.SelectMatch(0) }
    [void] SelectMatch([int]$Step) {
        $find = $this.modelState.Find
        if ($find.Stale -or -not $find.Matches.Count) { $this.Find() }
        if (-not $find.Matches.Count) { return }
        $next = $find.Index + $Step
        if ($find.Wrap) { $next = ($next + $find.Matches.Count) % $find.Matches.Count }
        elseif ($next -lt 0 -or $next -ge $find.Matches.Count) { return }
        $find.Index = $next
        $match = $find.Matches[$next]
        $this.Select($match.Start, $match.End)
    }

    [void] Replace() { $this.Replace($false) }
    [void] Replace([bool]$All) {
        $find = $this.modelState.Find
        if (-not $find.Query) { return }
        if ($All) {
            $this.Find()
            $tab = $this.Active()
            $text = $tab.Content()
            for ($i = $find.Matches.Count - 1; $i -ge 0; $i--) {
                $m = $find.Matches[$i]
                $text = $text.Substring(0, $m.Start) + $find.Replacement + $text.Substring($m.End)
            }
            if ($find.Matches.Count) { $this.Select(0, $tab.Document.Length); $this.Insert($text) }
        }
        elseif ($find.Matches.Count) {
            $m = $find.Matches[$find.Index]
            $this.Select($m.Start, $m.End)
            $this.Insert($find.Replacement)
            $this.SelectMatch()
        }
    }

    [NotepadSaved] Save([int]$Id, [string]$Path) {
        $tab = $this.Tab($Id)
        if ($null -eq $tab) { throw ('Unknown document ' + $Id) }
        $text = $tab.Content()
        if ($tab.LineEnding -eq 'Windows (CRLF)') { $text = $text.Replace("`n", "`r`n") }
        $fullPath = [IO.Path]::GetFullPath($Path)
        # Write a sibling temporary file first, then replace the destination. A
        # failed write cannot mark a document clean or truncate the old contents.
        $temporary = [IO.Path]::Combine([IO.Path]::GetDirectoryName($fullPath), '.notepad-' + [Guid]::NewGuid().ToString('N') + '.tmp')
        try { [IO.File]::WriteAllText($temporary, $text, [Text.UTF8Encoding]::new($tab.Bom)); [IO.File]::Move($temporary, $fullPath, $true) }
        finally { if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) } }
        $tab.Path = $fullPath
        $tab.Title = [IO.Path]::GetFileName($fullPath)
        $tab.Document.SavedJournalPosition = $tab.Document.JournalPosition
        $tab.SavedLineEnding = $tab.LineEnding
        $tab.SavedKnown = $true
        $tab.RefreshModified()
        $saved = [NotepadSaved]::new()
        $saved.Outcome = 'Saved'
        $saved.Id = $tab.Id
        $saved.Path = $fullPath
        return $saved
    }

    [NotepadTab] Open([string]$Path) {
        $bytes = [IO.File]::ReadAllBytes($Path)
        $bom = $bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191
        $utf8 = [Text.UTF8Encoding]::new($false, $true)
        $text = $utf8.GetString($bytes).TrimStart([char]0xFEFF)
        $tab = $this.NewTab([IO.Path]::GetFileName($Path), $text, [IO.Path]::GetFullPath($Path), $Path.EndsWith('.md', [StringComparison]::OrdinalIgnoreCase))
        $tab.Bom = $bom
        return $tab
    }

    [hashtable] ExportSession() {
        $tabs = [Collections.Generic.List[object]]::new()
        foreach ($tab in $this.modelState.Tabs) {
            $tabs.Add(@{Id=$tab.Id;Title=$tab.Title;Text=$tab.Content();Path=$tab.Path;Markdown=$tab.Markdown;LineEnding=$tab.LineEnding;Encoding=$tab.Encoding;Bom=$tab.Bom;Modified=$tab.Modified;Anchor=$tab.Anchor;Focus=$tab.Focus;ScrollX=$tab.ScrollX;ScrollY=$tab.ScrollY})
        }
        return @{NextId=$this.modelState.NextId;ActiveId=$this.modelState.ActiveId;Tabs=$tabs.ToArray()}
    }

    # The session in binary: a version, the next and active tab ids, then each tab's fields. Text is
    # written as BinaryWriter writes strings (UTF-8, length first); a string that may be $null is preceded by whether
    # it is present. Without tabs, only the header is written.
    [void] WriteSession([IO.BinaryWriter]$Writer, [bool]$WithTabs) {
        $Writer.Write([int]1)
        $Writer.Write([int]$this.modelState.NextId)
        $Writer.Write([int]$this.modelState.ActiveId)
        if (-not $WithTabs) { $Writer.Write([int]0); return }
        $Writer.Write([int]$this.modelState.Tabs.Count)
        foreach ($tab in $this.modelState.Tabs) {
            $Writer.Write([int]$tab.Id)
            [NotepadModel]::WriteText($Writer, $tab.Title)
            [NotepadModel]::WriteText($Writer, $tab.Content())
            [NotepadModel]::WriteText($Writer, $tab.Path)
            $Writer.Write([bool]$tab.Markdown)
            [NotepadModel]::WriteText($Writer, $tab.LineEnding)
            [NotepadModel]::WriteText($Writer, $tab.Encoding)
            $Writer.Write([bool]$tab.Bom)
            $Writer.Write([bool]$tab.Modified)
            $Writer.Write([int]$tab.Anchor)
            $Writer.Write([int]$tab.Focus)
            $Writer.Write([double]$tab.ScrollX)
            $Writer.Write([double]$tab.ScrollY)
        }
    }

    static [void] WriteText([IO.BinaryWriter]$Writer, [string]$Value) {
        $Writer.Write($null -ne $Value)
        if ($null -ne $Value) { $Writer.Write($Value) }
    }

    static [string] ReadText([IO.BinaryReader]$Reader) {
        if (-not $Reader.ReadBoolean()) { return $null }
        return $Reader.ReadString()
    }

    # Restores a session WriteSession wrote. A session without tabs leaves the open tabs as they are. A tab
    # without text or with a repeated id makes the session invalid; carets are clamped to the text.
    [void] ReadSession([IO.BinaryReader]$Reader) {
        if ($Reader.ReadInt32() -ne 1) { throw 'Invalid session document' }
        $nextId = $Reader.ReadInt32()
        $activeId = $Reader.ReadInt32()
        $count = $Reader.ReadInt32()
        if ($count -le 0) { return }
        $this.modelState.Tabs.Clear()
        $ids = [Collections.Generic.HashSet[int]]::new()
        for ($i = 0; $i -lt $count; $i++) {
            $id = $Reader.ReadInt32()
            $title = [NotepadModel]::ReadText($Reader)
            $text = [NotepadModel]::ReadText($Reader)
            $path = [NotepadModel]::ReadText($Reader)
            $markdown = $Reader.ReadBoolean()
            if ($null -eq $text -or -not $ids.Add($id)) { throw 'Invalid session document' }
            $tab = $this.NewTab($title, $text, $path, $markdown)
            $tab.Id = $id
            $tab.LineEnding = [NotepadModel]::ReadText($Reader)
            $tab.Encoding = [NotepadModel]::ReadText($Reader)
            $tab.Bom = $Reader.ReadBoolean()
            # An untitled tab is measured against no text; a file tab saved unmodified against its restored text;
            # a file tab saved modified stays modified, since what its file held is not in the session.
            $restoredModified = $Reader.ReadBoolean()
            $tab.SavedLineEnding = $tab.LineEnding
            if ($path -and $restoredModified) { $tab.SavedKnown = $false }
            $tab.RefreshModified()
            $tab.Anchor = $Reader.ReadInt32()
            $tab.Focus = $Reader.ReadInt32()
            $tab.ScrollX = $Reader.ReadDouble()
            $tab.ScrollY = $Reader.ReadDouble()
            $tab.Focus = [Math]::Clamp($tab.Focus, 0, $tab.Document.Length)
            $tab.Anchor = [Math]::Clamp($tab.Anchor, 0, $tab.Document.Length)
        }
        $highest = 0
        foreach ($tab in $this.modelState.Tabs) { $highest = [Math]::Max($highest, $tab.Id) }
        $this.modelState.NextId = [Math]::Max($nextId, $highest + 1)
        $this.modelState.ActiveId = $this.modelState.Tabs[0].Id
        if ($ids.Contains($activeId)) { $this.modelState.ActiveId = $activeId }
    }
}

function Invoke-Model {
[CmdletBinding()]
param([NotepadSettings]$Settings=$null)
if($MyInvocation.InvocationName -eq '.'){throw 'Invoke Model.ps1 with &.'}
[NotepadModel]::new($Settings)
}

# Folded from tests\Model.Verify.ps1
function Invoke-Model.Verify {
[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$root=Split-Path $(Join-Path $PSScriptRoot 'tests')
$model=Invoke-Model
$state=$model.State()
function Assert([bool]$Value,[string]$Message){if(-not $Value){throw $Message}}
$first=$model.NewTab('first.txt','first buffer',$null,$false)
$second=$model.NewTab('second.txt','second buffer',$null,$false)
$testDirectory=Join-Path ([IO.Path]::GetTempPath()) ('notepad-model-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testDirectory|Out-Null
try{
    $defaults=Invoke-Model
    $newDocument=$defaults.NewTab()
    Assert ($newDocument.LineEnding -eq 'Windows (CRLF)') 'New document did not default to Windows CRLF.'
    $defaults.Insert("first`nsecond",$false)
    $defaultPath=Join-Path $testDirectory 'new-default.txt';$null=$defaults.Save($newDocument.Id,$defaultPath)
    Assert ([IO.File]::ReadAllText($defaultPath) -ceq "first`r`nsecond") 'Default save did not write CRLF bytes.'
    $lfPath=Join-Path $testDirectory 'lf-preserved.txt';[IO.File]::WriteAllText($lfPath,"first`nsecond",[Text.UTF8Encoding]::new($false))
    $lfDocument=$defaults.Open($lfPath)
    Assert ($lfDocument.LineEnding -eq 'Unix (LF)') 'Opening an LF file changed its line-ending mode.'
    $null=$defaults.Save($lfDocument.Id,$lfPath)
    Assert ([IO.File]::ReadAllText($lfPath) -ceq "first`nsecond") 'Saving an opened LF file changed its line endings.'
    $firstPath=Join-Path $testDirectory 'first.txt'
    $null=$model.Save($first.Id,$firstPath)
    Assert ([IO.File]::ReadAllText($firstPath) -ceq 'first buffer') 'Inactive save used active document text.'
    Assert ($model.Active().Id -eq $second.Id) 'Save changed active tab.'
    $model.Select(0,$second.Length());$model.Insert("A😀e$([char]0x301)`nB",$false)
    Assert ($second.Length() -eq 7) 'UTF-16 storage mismatch.'
    $model.Select(3,3);$model.Delete($true)
    Assert ($second.Content() -ceq "Ae$([char]0x301)`nB") 'Backspace split a surrogate pair.'
    $model.Undo($false)
    Assert ($second.Content() -ceq "A😀e$([char]0x301)`nB") 'Undo failed.'
    $model.Undo($true)
    Assert ($second.Content() -ceq "Ae$([char]0x301)`nB") 'Redo failed.'
    $model.Select(3,3);$model.Delete($true)
    Assert ($second.Content() -ceq "A`nB") 'Backspace split a combining sequence.'
    $model.Select(0,$second.Length());$model.Insert('one ONE one',$false)
    $state.Find.Query='one';$state.Find.Replacement='$literal';$state.Find.MatchCase=$false;$model.Find()
    Assert ($state.Find.Matches.Count -eq 3) 'Case-insensitive find mismatch.'
    $state.Find.MatchCase=$true;$model.Find();Assert ($state.Find.Matches.Count -eq 2) 'Case-sensitive find mismatch.'
    $model.Replace($true)
    Assert ($second.Content() -ceq '$literal ONE $literal') 'Literal replace-all mismatch.'
    $model.Select(0,$second.Length());$model.Insert("α`nβ",$false);$second.LineEnding='Windows (CRLF)';$second.Bom=$true
    $secondPath=Join-Path $testDirectory 'second.txt';$null=$model.Save($second.Id,$secondPath)
    $bytes=[IO.File]::ReadAllBytes($secondPath)
    Assert (($bytes[0..2] -join ',') -eq '239,187,191') 'UTF-8 BOM missing.'
    Assert ([IO.File]::ReadAllText($secondPath) -ceq "α`r`nβ") 'CRLF output mismatch.'
    $third=$model.Open($secondPath);Assert ($third.Content() -ceq "α`nβ" -and $third.Bom) 'UTF-8 reopen mismatch.'
    $buffer=[IO.MemoryStream]::new();$sessionWriter=[IO.BinaryWriter]::new($buffer);$model.WriteSession($sessionWriter,$true);$sessionWriter.Flush();$buffer.Position=0
    $restored=Invoke-Model;$restored.ReadSession([IO.BinaryReader]::new($buffer))
    $before=foreach($tab in $model.State().Tabs){$tab.Content()+'|'+$tab.Path+'|'+$tab.LineEnding+'|'+$tab.Encoding+'|'+$tab.Bom+'|'+$tab.Modified+'|'+$tab.Anchor+'|'+$tab.Focus}
    $after=foreach($tab in $restored.State().Tabs){$tab.Content()+'|'+$tab.Path+'|'+$tab.LineEnding+'|'+$tab.Encoding+'|'+$tab.Bom+'|'+$tab.Modified+'|'+$tab.Anchor+'|'+$tab.Focus}
    Assert (($before -join "`n") -ceq ($after -join "`n")) 'Session round trip changed a document.'
    Assert ($restored.State().Tabs.Count -eq 3) 'Session lost documents.'
    Assert ($restored.Active().Content() -ceq "α`nβ") 'Session active document mismatch.'
    $lastId=$restored.Active().Id;$restored.CloseTab($lastId);Assert ($restored.State().Tabs.Count -eq 2) 'Close-tab failed.'
    'PASS: inactive saves, Unicode editing, undo/redo, find/replace, UTF-8/BOM/CRLF and session restoration.'
}finally{
    # Only exact known temporary files are removed; no recursive directory deletion.
    foreach($name in @('first.txt','second.txt','new-default.txt','lf-preserved.txt')){ $file=Join-Path $testDirectory $name;if(Test-Path -LiteralPath $file){Remove-Item -LiteralPath $file} }
    Remove-Item -LiteralPath $testDirectory
}
}

# Folded from src\Native.ps1
function Invoke-Native {
[CmdletBinding()]
param()

if ($MyInvocation.InvocationName -eq '.') {
    throw 'Native.ps1 must be invoked with &, not dot-sourced.'
}

$Native = & {
    $assembly = [Reflection.Emit.AssemblyBuilder]::DefineDynamicAssembly(
        [Reflection.AssemblyName]::new('QuickPS.Native.' + [Guid]::NewGuid().ToString('N')),
        [Reflection.Emit.AssemblyBuilderAccess]::Run)
    $module = $assembly.DefineDynamicModule('Native')
    $types = [Collections.Generic.Dictionary[string, Type]]::new()
    $calls = [Collections.Generic.Dictionary[string, Delegate]]::new()
    $libraries = [Collections.Generic.Dictionary[string, IntPtr]]::new(
        [StringComparer]::OrdinalIgnoreCase)

    $instance = [PSCustomObject]@{
        PSTypeName = 'QuickPS.Native'
        Module = $module
        DelegateTypes = $types
        Calls = $calls
        Libraries = $libraries
    }

    $instance | Add-Member ScriptMethod LoadLibrary ({
        param([string] $Name)
        if (-not $this.Libraries.ContainsKey($Name)) {
            $this.Libraries[$Name] = [Runtime.InteropServices.NativeLibrary]::Load($Name)
        }
        $this.Libraries[$Name]
    }.GetNewClosure())

    $instance | Add-Member ScriptMethod GetExport ({
        param([IntPtr] $Library, [string] $Name)
        [Runtime.InteropServices.NativeLibrary]::GetExport($Library, $Name)
    }.GetNewClosure())

    $instance | Add-Member ScriptMethod GetCall ({
        param([IntPtr] $Address, [Type] $ReturnType, [Type[]] $ParameterTypes)
        if ($Address -eq [IntPtr]::Zero) { throw 'Cannot bind a null native address.' }
        $signature = $ReturnType.FullName + ':' + (($ParameterTypes | ForEach-Object FullName) -join ',')
        if (-not $this.DelegateTypes.ContainsKey($signature)) {
            $builder = $this.Module.DefineType(
                'Call_' + [Guid]::NewGuid().ToString('N'),
                'Class,Public,Sealed',
                [MulticastDelegate])
            $constructor = $builder.DefineConstructor(
                'Public,HideBySig,RTSpecialName',
                [Reflection.CallingConventions]::Standard,
                @([object], [IntPtr]))
            $constructor.SetImplementationFlags('Runtime,Managed')
            $invoke = $builder.DefineMethod(
                'Invoke', 'Public,HideBySig,NewSlot,Virtual',
                $ReturnType, $ParameterTypes)
            $invoke.SetImplementationFlags('Runtime,Managed')
            $attribute = [Reflection.Emit.CustomAttributeBuilder]::new(
                [Runtime.InteropServices.UnmanagedFunctionPointerAttribute].GetConstructor(
                    @([Runtime.InteropServices.CallingConvention])),
                @([Runtime.InteropServices.CallingConvention]::StdCall))
            $builder.SetCustomAttribute($attribute)
            $this.DelegateTypes[$signature] = $builder.CreateType()
        }
        $key = $Address.ToInt64().ToString() + ':' + $signature
        if (-not $this.Calls.ContainsKey($key)) {
            $this.Calls[$key] = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
                $Address, $this.DelegateTypes[$signature])
        }
        $this.Calls[$key]
    }.GetNewClosure())

    $instance | Add-Member ScriptMethod GetExportCall ({
        param([string] $Library, [string] $Name, [Type] $ReturnType, [Type[]] $ParameterTypes)
        $handle = $this.LoadLibrary($Library)
        $address = $this.GetExport($handle, $Name)
        $this.GetCall($address, $ReturnType, $ParameterTypes)
    }.GetNewClosure())

    $instance | Add-Member ScriptMethod GetComCall ({
        param([IntPtr] $Object, [int] $Slot, [Type] $ReturnType, [Type[]] $ParameterTypes)
        if ($Object -eq [IntPtr]::Zero) { throw 'Cannot bind a null COM interface.' }
        $vtable = [Runtime.InteropServices.Marshal]::ReadIntPtr($Object)
        $address = [Runtime.InteropServices.Marshal]::ReadIntPtr(
            $vtable, $Slot * [IntPtr]::Size)
        $this.GetCall($address, $ReturnType, (@([IntPtr]) + $ParameterTypes))
    }.GetNewClosure())

    $instance | Add-Member ScriptMethod InvokeCom ({
        param(
            [IntPtr] $Object,
            [int] $Slot,
            [Type] $ReturnType,
            [Type[]] $ParameterTypes,
            [object[]] $Arguments
        )
        $call = $this.GetComCall($Object, $Slot, $ReturnType, $ParameterTypes)
        $invokeArguments = [object[]]::new(1 + $Arguments.Count)
        $invokeArguments[0] = [IntPtr]$Object
        for ($index = 0; $index -lt $Arguments.Count; $index++) {
            $argument = $Arguments[$index]
            if ($argument -is [Management.Automation.PSObject]) {
                $argument = $argument.PSObject.BaseObject
            }
            # DynamicInvoke does not coerce boxed Double/Int32 to native Single/
            # UInt32. Convert to the declared ABI type after unwrapping PSObject.
            $invokeArguments[$index + 1] = [Management.Automation.LanguagePrimitives]::ConvertTo(
                $argument, $ParameterTypes[$index])
        }
        $call.DynamicInvoke($invokeArguments)
    }.GetNewClosure())

    $instance | Add-Member ScriptMethod Allocate ({
        param([int] $Bytes)
        if ($Bytes -lt 1) { throw 'Allocation size must be positive.' }
        $pointer = [Runtime.InteropServices.Marshal]::AllocHGlobal($Bytes)
        for ($index = 0; $index -lt $Bytes; $index++) {
            [Runtime.InteropServices.Marshal]::WriteByte($pointer, $index, 0)
        }
        $pointer
    }.GetNewClosure())

    $instance | Add-Member ScriptMethod Free ({
        param([IntPtr] $Pointer)
        if ($Pointer -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::FreeHGlobal($Pointer)
        }
    }.GetNewClosure())

    $instance | Add-Member ScriptMethod ReleaseCom ({
        param([IntPtr] $Object)
        if ($Object -eq [IntPtr]::Zero) { return [uint32]0 }
        [uint32]$this.InvokeCom($Object, 2, ([uint32]), @(), @())
    }.GetNewClosure())

    $instance | Add-Member ScriptMethod Dispose ({
        foreach ($library in $this.Libraries.Values) {
            if ($library -ne [IntPtr]::Zero) {
                [Runtime.InteropServices.NativeLibrary]::Free($library)
            }
        }
        $this.Libraries.Clear()
        $this.Calls.Clear()
        $this.DelegateTypes.Clear()
    }.GetNewClosure())

    $instance
}

$Native
}

# Folded from src\Window.Windows.ps1
class NotepadWindowEvent {
    [string]$Kind
    [uint]$Message
    [long]$W
    [long]$L
    [bool]$Ctrl
    [bool]$Shift
    [bool]$Alt
}

class NotepadWindowInfo {
    [IntPtr]$Hwnd
    [int]$Width
    [int]$Height
    [single]$Dpi
    [bool]$Alive
    [bool]$Focused
    [bool]$Minimized
}

class NotepadAppearance {
    [string]$Material
    [int]$Requested
    [int]$Observed
    [bool]$Curved
    [bool]$Dark
    [int]$BorderColor
}

class NotepadEntrance {
    [int]$FromX
    [int]$ToX
    [int]$Y
    [int]$DurationMs
    [double[]]$Curve
}

class NotepadEntranceSample {
    [double]$Progress
    [int]$X
    [int]$Alpha
    [double]$ElapsedMs
    [double]$TimeProgress
}

class NotepadEntranceRestore {
    [long]$OriginalStyle
    [long]$ObservedStyle
}

# Where the window was left: its restored rectangle in workspace coordinates (physical pixels, at the DPI of the
# monitor it was on) and whether it was maximized. Kept in window.bin beside the session.
class NotepadPlacement {
    [int]$Left
    [int]$Top
    [int]$Right
    [int]$Bottom
    [bool]$Maximized

    [void] Write([IO.BinaryWriter]$Writer) {
        $Writer.Write([int]1)
        $Writer.Write($this.Left); $Writer.Write($this.Top); $Writer.Write($this.Right); $Writer.Write($this.Bottom)
        $Writer.Write($this.Maximized)
    }

    # A placement Write wrote; one with no area is invalid.
    static [NotepadPlacement] Read([IO.BinaryReader]$Reader) {
        if ($Reader.ReadInt32() -ne 1) { throw 'Invalid window placement' }
        $placement = [NotepadPlacement]::new()
        $placement.Left = $Reader.ReadInt32(); $placement.Top = $Reader.ReadInt32(); $placement.Right = $Reader.ReadInt32(); $placement.Bottom = $Reader.ReadInt32()
        $placement.Maximized = $Reader.ReadBoolean()
        if ($placement.Right -le $placement.Left -or $placement.Bottom -le $placement.Top) { throw 'Invalid window placement' }
        return $placement
    }
}

# A top-level window with Notepad's own caption: its window procedure, its message queue as events, its backdrop and
# its entrance. Win32 BOOL results are [int].
class NotepadWindow {
    # The window lives on a thread of its own: that thread creates it, pumps its messages and runs the window
    # procedure, and is the one held inside Windows' own loop while the user drags an edge or the caption. The app's
    # thread keeps handling events and painting from the queue meanwhile, so resizing repaints live.
    static [NotepadWindow]$Current
    hidden [Collections.Concurrent.ConcurrentQueue[NotepadWindowEvent]]$events = [Collections.Concurrent.ConcurrentQueue[NotepadWindowEvent]]::new()
    hidden [Exception]$callbackError
    # Set by the window thread once the window exists (or creating it failed), and when the thread ends.
    hidden [Threading.ManualResetEventSlim]$ready = [Threading.ManualResetEventSlim]::new($false)
    hidden [Threading.ManualResetEventSlim]$exited = [Threading.ManualResetEventSlim]::new($false)
    # The window thread's own buffers: its MSG and the window procedure's scratch, apart from the app thread's.
    hidden [IntPtr]$pumpMessage
    hidden [IntPtr]$procedureScratch
    hidden [int]$requestedWidth
    hidden [int]$requestedHeight
    hidden [string]$requestedTitle
    hidden [IntPtr]$hwnd
    hidden [bool]$alive = $true
    hidden [bool]$focused = $true
    hidden [bool]$minimized = $false
    hidden [IntPtr]$windowIcon
    hidden [bool]$ownsWindowIcon = $false
    hidden [IntPtr]$arrow
    hidden [IntPtr]$ibeam
    hidden [IntPtr]$hand
    hidden [IntPtr]$currentCursor
    hidden [IntPtr]$scratch
    hidden [IntPtr]$previousDpi
    hidden [IntPtr]$hmodule
    hidden [IntPtr]$classPtr
    hidden [int]$entranceX
    hidden [int]$entranceY
    hidden [int]$entranceFrom
    hidden [IntPtr]$entranceStyle
    # Set while Place moves the window to where it was saved, so the DPI change that move causes keeps the saved size.
    hidden [bool]$placing = $false
    hidden [bool]$maximizeOnShow = $false

    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [IntPtr] DefWindowProcW([IntPtr]$hwnd, [uint]$message, [IntPtr]$w, [IntPtr]$l) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [short] GetKeyState([int]$key) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] ValidateRect([IntPtr]$hwnd, [IntPtr]$rect) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] GetClientRect([IntPtr]$hwnd, [IntPtr]$rect) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [uint] GetDpiForWindow([IntPtr]$hwnd) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] GetWindowRect([IntPtr]$hwnd, [IntPtr]$rect) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] ShowWindow([IntPtr]$hwnd, [int]$command) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] SetWindowPos([IntPtr]$hwnd, [IntPtr]$after, [int]$x, [int]$y, [int]$width, [int]$height, [uint]$flags) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [IntPtr] SendMessageW([IntPtr]$hwnd, [uint]$message, [IntPtr]$w, [IntPtr]$l) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [IntPtr] SetCapture([IntPtr]$hwnd) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] ReleaseCapture() { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [IntPtr] LoadCursorW([IntPtr]$instance, [IntPtr]$name) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [IntPtr] SetCursor([IntPtr]$cursor) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [IntPtr] SetThreadDpiAwarenessContext([IntPtr]$context) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('shell32.dll')]
    static [int] SetCurrentProcessExplicitAppUserModelID([IntPtr]$id) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('kernel32.dll')]
    static [IntPtr] GetModuleHandleW([IntPtr]$name) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [ushort] RegisterClassExW([IntPtr]$class) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [IntPtr] CreateWindowExW([uint]$exStyle, [IntPtr]$class, [IntPtr]$title, [uint]$style, [int]$x, [int]$y, [int]$width, [int]$height, [IntPtr]$parent, [IntPtr]$menu, [IntPtr]$instance, [IntPtr]$parameter) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('dwmapi.dll')]
    static [int] DwmSetWindowAttribute([IntPtr]$hwnd, [uint]$attribute, [IntPtr]$value, [uint]$size) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('dwmapi.dll')]
    static [int] DwmGetWindowAttribute([IntPtr]$hwnd, [uint]$attribute, [IntPtr]$value, [uint]$size) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('dwmapi.dll')]
    static [int] DwmExtendFrameIntoClientArea([IntPtr]$hwnd, [IntPtr]$margins) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [IntPtr] GetWindowLongPtrW([IntPtr]$hwnd, [int]$index) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [IntPtr] SetWindowLongPtrW([IntPtr]$hwnd, [int]$index, [IntPtr]$value) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] SetLayeredWindowAttributes([IntPtr]$hwnd, [uint]$key, [byte]$alpha, [uint]$flags) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] GetLayeredWindowAttributes([IntPtr]$hwnd, [IntPtr]$key, [IntPtr]$alpha, [IntPtr]$flags) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] GetSystemMetrics([int]$index) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] SetForegroundWindow([IntPtr]$hwnd) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('shell32.dll')]
    static [int] SHGetStockIconInfo([int]$id, [uint]$flags, [IntPtr]$info) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [IntPtr] LoadIconW([IntPtr]$instance, [IntPtr]$name) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [IntPtr] LoadImageW([IntPtr]$instance, [IntPtr]$name, [uint]$type, [int]$width, [int]$height, [uint]$load) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] DestroyIcon([IntPtr]$icon) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] PeekMessageW([IntPtr]$message, [IntPtr]$hwnd, [uint]$first, [uint]$last, [uint]$remove) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] GetMessageW([IntPtr]$message, [IntPtr]$hwnd, [uint]$first, [uint]$last) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] PostMessageW([IntPtr]$hwnd, [uint]$message, [IntPtr]$w, [IntPtr]$l) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [void] PostQuitMessage([int]$exitCode) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('kernel32.dll')]
    static [IntPtr] CreateThread([IntPtr]$attributes, [IntPtr]$stackSize, [IntPtr]$start, [IntPtr]$parameter, [uint]$flags, [IntPtr]$threadId) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] TranslateMessage([IntPtr]$message) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [IntPtr] DispatchMessageW([IntPtr]$message) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] IsZoomed([IntPtr]$hwnd) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] DestroyWindow([IntPtr]$hwnd) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] UnregisterClassW([IntPtr]$class, [IntPtr]$instance) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] GetWindowPlacement([IntPtr]$hwnd, [IntPtr]$placement) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] SetWindowPlacement([IntPtr]$hwnd, [IntPtr]$placement) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('advapi32.dll')]
    static [int] RegGetValueW([IntPtr]$key, [IntPtr]$subKey, [IntPtr]$value, [uint]$flags, [IntPtr]$type, [IntPtr]$data, [IntPtr]$size) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('kernel32.dll')]
    static [int] CreateProcessW([IntPtr]$application, [IntPtr]$commandLine, [IntPtr]$processAttributes, [IntPtr]$threadAttributes, [int]$inheritHandles, [uint]$flags, [IntPtr]$environment, [IntPtr]$directory, [IntPtr]$startupInfo, [IntPtr]$processInformation) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('kernel32.dll')]
    static [int] CloseHandle([IntPtr]$handle) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('shell32.dll')]
    static [IntPtr] ShellExecuteW([IntPtr]$hwnd, [IntPtr]$operation, [IntPtr]$file, [IntPtr]$fileArguments, [IntPtr]$directory, [int]$show) { throw 'native' }

    # Whether Windows asks apps for the light theme: HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize
    # AppsUseLightTheme is 1. A value that cannot be read is not 1.
    static [bool] AppsUseLightTheme() {
        $subKey = [Runtime.InteropServices.Marshal]::StringToHGlobalUni('Software\Microsoft\Windows\CurrentVersion\Themes\Personalize')
        $name = [Runtime.InteropServices.Marshal]::StringToHGlobalUni('AppsUseLightTheme')
        $data = [Runtime.InteropServices.Marshal]::AllocHGlobal(8)
        try {
            [Runtime.InteropServices.Marshal]::WriteInt32($data, 0, 0)
            [Runtime.InteropServices.Marshal]::WriteInt32($data, 4, 4)
            # HKEY_CURRENT_USER is 0x80000001 sign-extended; RRF_RT_REG_DWORD is 0x10.
            $status = [NotepadWindow]::RegGetValueW([IntPtr][long]-2147483647, $subKey, $name, [uint]0x10, [IntPtr]::Zero, $data, [IntPtr]::Add($data, 4))
            return $status -eq 0 -and [Runtime.InteropServices.Marshal]::ReadInt32($data, 0) -eq 1
        }
        finally {
            [Runtime.InteropServices.Marshal]::FreeHGlobal($data)
            [Runtime.InteropServices.Marshal]::FreeHGlobal($name)
            [Runtime.InteropServices.Marshal]::FreeHGlobal($subKey)
        }
    }

    # Windows' text size setting (Settings > Accessibility > Text size) as a factor: HKCU\Software\Microsoft\Accessibility
    # TextScaleFactor, a percentage from 100 to 225, as WinUI applies it to interface text. 1 when it is not set or
    # cannot be read.
    static [double] TextScaleFactor() {
        $subKey = [Runtime.InteropServices.Marshal]::StringToHGlobalUni('Software\Microsoft\Accessibility')
        $name = [Runtime.InteropServices.Marshal]::StringToHGlobalUni('TextScaleFactor')
        $data = [Runtime.InteropServices.Marshal]::AllocHGlobal(8)
        try {
            [Runtime.InteropServices.Marshal]::WriteInt32($data, 0, 100)
            [Runtime.InteropServices.Marshal]::WriteInt32($data, 4, 4)
            # HKEY_CURRENT_USER is 0x80000001 sign-extended; RRF_RT_REG_DWORD is 0x10.
            $status = [NotepadWindow]::RegGetValueW([IntPtr][long]-2147483647, $subKey, $name, [uint]0x10, [IntPtr]::Zero, $data, [IntPtr]::Add($data, 4))
            if ($status -ne 0) { return 1.0 }
            return [Math]::Clamp([Runtime.InteropServices.Marshal]::ReadInt32($data, 0), 100, 225) / 100.0
        }
        finally {
            [Runtime.InteropServices.Marshal]::FreeHGlobal($data)
            [Runtime.InteropServices.Marshal]::FreeHGlobal($name)
            [Runtime.InteropServices.Marshal]::FreeHGlobal($subKey)
        }
    }

    # Windows' accent family: HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent AccentPalette, eight
    # 4-byte RGBA entries of which the first seven are Light3, Light2, Light1, the accent, Dark1, Dark2 and Dark3.
    # Empty when the value cannot be read.
    static [FluentColor[]] AccentPalette() {
        $subKey = [Runtime.InteropServices.Marshal]::StringToHGlobalUni('Software\Microsoft\Windows\CurrentVersion\Explorer\Accent')
        $name = [Runtime.InteropServices.Marshal]::StringToHGlobalUni('AccentPalette')
        $data = [Runtime.InteropServices.Marshal]::AllocHGlobal(40)
        try {
            [Runtime.InteropServices.Marshal]::WriteInt32($data, 36, 32)
            # RRF_RT_REG_BINARY is 0x08.
            $status = [NotepadWindow]::RegGetValueW([IntPtr][long]-2147483647, $subKey, $name, [uint]0x08, [IntPtr]::Zero, $data, [IntPtr]::Add($data, 36))
            if ($status -ne 0 -or [Runtime.InteropServices.Marshal]::ReadInt32($data, 36) -lt 28) { return [FluentColor[]]@() }
            $shades = [FluentColor[]]::new(7)
            for ($i = 0; $i -lt 7; $i++) { $shades[$i] = [FluentColor]::new([Runtime.InteropServices.Marshal]::ReadByte($data, 4 * $i), [Runtime.InteropServices.Marshal]::ReadByte($data, 4 * $i + 1), [Runtime.InteropServices.Marshal]::ReadByte($data, 4 * $i + 2)) }
            return $shades
        }
        finally {
            [Runtime.InteropServices.Marshal]::FreeHGlobal($data)
            [Runtime.InteropServices.Marshal]::FreeHGlobal($name)
            [Runtime.InteropServices.Marshal]::FreeHGlobal($subKey)
        }
    }

    # Starts a program from its command line (its quoted path first, then its arguments), without waiting for it.
    static [void] StartProgram([string]$CommandLine) {
        # STARTUPINFOW is 104 bytes and PROCESS_INFORMATION 24 on a 64-bit process.
        $startup = [Runtime.InteropServices.Marshal]::AllocHGlobal(104)
        $process = [Runtime.InteropServices.Marshal]::AllocHGlobal(24)
        $line = [Runtime.InteropServices.Marshal]::StringToHGlobalUni($CommandLine)
        try {
            for ($i = 0; $i -lt 104; $i++) { [Runtime.InteropServices.Marshal]::WriteByte($startup, $i, 0) }
            [Runtime.InteropServices.Marshal]::WriteInt32($startup, 0, 104)
            if ([NotepadWindow]::CreateProcessW([IntPtr]::Zero, $line, [IntPtr]::Zero, [IntPtr]::Zero, 0, [uint]0, [IntPtr]::Zero, [IntPtr]::Zero, $startup, $process) -eq 0) { throw ('Could not start ' + $CommandLine) }
            $null = [NotepadWindow]::CloseHandle([Runtime.InteropServices.Marshal]::ReadIntPtr($process, 0))
            $null = [NotepadWindow]::CloseHandle([Runtime.InteropServices.Marshal]::ReadIntPtr($process, 8))
        }
        finally {
            [Runtime.InteropServices.Marshal]::FreeHGlobal($line)
            [Runtime.InteropServices.Marshal]::FreeHGlobal($process)
            [Runtime.InteropServices.Marshal]::FreeHGlobal($startup)
        }
    }

    # A new activity of this program: the compiled program again, or, run as a script, pwsh running this script.
    static [void] StartActivity() {
        $program = [Environment]::ProcessPath
        $line = if ([IO.Path]::GetFileNameWithoutExtension($program) -eq 'pwsh') { '"' + $program + '" -NoProfile -STA -File "' + $PSScriptRoot + '\Notepad.ps1"' } else { '"' + $program + '"' }
        [NotepadWindow]::StartProgram($line)
    }

    # An address opened by the system's own handler for it, as the shell's "open" does (the browser, for https).
    static [void] OpenLink([string]$Address) {
        $operation = [Runtime.InteropServices.Marshal]::StringToHGlobalUni('open')
        $file = [Runtime.InteropServices.Marshal]::StringToHGlobalUni($Address)
        try {
            # SW_SHOWNORMAL is 1; a result of 32 or less is an error.
            if ([NotepadWindow]::ShellExecuteW([IntPtr]::Zero, $operation, $file, [IntPtr]::Zero, [IntPtr]::Zero, 1).ToInt64() -le 32) { throw ('Could not open ' + $Address) }
        }
        finally {
            [Runtime.InteropServices.Marshal]::FreeHGlobal($file)
            [Runtime.InteropServices.Marshal]::FreeHGlobal($operation)
        }
    }

    [System.Runtime.InteropServices.UnmanagedCallersOnly(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [IntPtr] WndProc([IntPtr]$Handle, [uint]$Message, [IntPtr]$WParam, [IntPtr]$LParam) {
        return [NotepadWindow]::Current.Procedure($Handle, $Message, $WParam, $LParam)
    }

    # The window thread's entry, started by CreateThread.
    [System.Runtime.InteropServices.UnmanagedCallersOnly(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [uint] WindowThread([IntPtr]$ThreadArgument) {
        return [NotepadWindow]::Current.Pump()
    }

    # On the window thread: register the class, create the window, signal the app thread, then pump messages until
    # WM_QUIT. Any failure is kept in callbackError for the app thread.
    hidden [uint] Pump() {
        try {
            $null = [NotepadWindow]::SetThreadDpiAwarenessContext([IntPtr](-4))
            $proc = [NotepadWindow].GetMethod('WndProc').MethodHandle.GetFunctionPointer()
            $titlePtr = [Runtime.InteropServices.Marshal]::StringToHGlobalUni($this.requestedTitle)
            $class = [Runtime.InteropServices.Marshal]::AllocHGlobal(80)
            try {
                for ($i = 0; $i -lt 80; $i++) { [Runtime.InteropServices.Marshal]::WriteByte($class, $i, 0) }
                [Runtime.InteropServices.Marshal]::WriteInt32($class, 0, 80)
                [Runtime.InteropServices.Marshal]::WriteInt32($class, 4, 0xB) # redraw + double clicks
                [Runtime.InteropServices.Marshal]::WriteIntPtr($class, 8, $proc)
                [Runtime.InteropServices.Marshal]::WriteIntPtr($class, 24, $this.hmodule)
                [Runtime.InteropServices.Marshal]::WriteIntPtr($class, 40, $this.arrow)
                [Runtime.InteropServices.Marshal]::WriteIntPtr($class, 64, $this.classPtr)
                if ([NotepadWindow]::RegisterClassExW($class) -eq 0) { throw 'RegisterClassExW failed' }
                # A normal top-level app window with our own caption controls, rather than a popup or duplicate native caption.
                $this.hwnd = [NotepadWindow]::CreateWindowExW([uint]0x40000, $this.classPtr, $titlePtr, [uint]0x000F0000L, 100, 80, [Math]::Max(768, $this.requestedWidth), [Math]::Max(478, $this.requestedHeight), [IntPtr]::Zero, [IntPtr]::Zero, $this.hmodule, [IntPtr]::Zero)
            }
            finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($class); [Runtime.InteropServices.Marshal]::FreeHGlobal($titlePtr) }
            if ($this.hwnd -eq [IntPtr]::Zero) { throw 'CreateWindowExW failed' }
            $this.ready.Set()
            while ([NotepadWindow]::GetMessageW($this.pumpMessage, [IntPtr]::Zero, [uint]0, [uint]0) -gt 0) {
                $null = [NotepadWindow]::TranslateMessage($this.pumpMessage); $null = [NotepadWindow]::DispatchMessageW($this.pumpMessage)
            }
        }
        catch { $this.callbackError = $_.Exception; $this.alive = $false }
        finally { $this.ready.Set(); $this.exited.Set() }
        return [uint]0
    }

    hidden [void] Enqueue([string]$Kind) {
        $event = [NotepadWindowEvent]::new()
        $event.Kind = $Kind
        $this.events.Enqueue($event)
    }

    hidden [IntPtr] Procedure([IntPtr]$Handle, [uint]$Message, [IntPtr]$WParam, [IntPtr]$LParam) {
        try {
            # Requests the app thread posts, done here because they must run on the window's own thread: WM_APP + 1
            # sets (wParam 1) or releases mouse capture; WM_APP + 2 destroys the window and ends the pump.
            if ($Message -eq 0x8001) { if ($WParam.ToInt64() -ne 0) { $null = [NotepadWindow]::SetCapture($Handle) } else { $null = [NotepadWindow]::ReleaseCapture() }; return [IntPtr]::Zero }
            if ($Message -eq 0x8002) { $null = [NotepadWindow]::DestroyWindow($Handle); [NotepadWindow]::PostQuitMessage(0); return [IntPtr]::Zero }
            if ($Message -eq 0x0083) { return [IntPtr]::Zero } # WM_NCCALCSIZE: full client chrome.
            if ($Message -eq 0x001A) { $this.Enqueue('settingChange') } # WM_SETTINGCHANGE: text size or theme may have changed.
            if ($Message -eq 0x0014) { return [IntPtr]1 } # suppress GDI background erase.
            if ($Message -eq 0x0024) { # WM_GETMINMAXINFO: keep the native toolbar and settings usable.
                $scale = [Math]::Max(96, [NotepadWindow]::GetDpiForWindow($Handle)) / 96.0
                [Runtime.InteropServices.Marshal]::WriteInt32($LParam, 24, [int][Math]::Ceiling(768 * $scale))
                [Runtime.InteropServices.Marshal]::WriteInt32($LParam, 28, [int][Math]::Ceiling(478 * $scale))
                return [IntPtr]::Zero
            }
            if ($Message -eq 0x000F) { $null = [NotepadWindow]::ValidateRect($Handle, [IntPtr]::Zero); $this.Enqueue('paint'); return [IntPtr]::Zero }
            if ($Message -eq 0x0010) { $this.Enqueue('close'); return [IntPtr]::Zero }
            if ($Message -eq 0x0002) { $this.alive = $false; return [IntPtr]::Zero }
            if ($Message -eq 0x0005) {
                $this.minimized = $WParam.ToInt64() -eq 1
                if ($this.minimized) { $this.Enqueue('minimized') } else { $this.Enqueue('resize') }
                return [IntPtr]::Zero
            }
            if ($Message -eq 0x0007) { $this.focused = $true; $this.Enqueue('focus'); return [IntPtr]::Zero }
            if ($Message -eq 0x0008) { $this.focused = $false; $this.Enqueue('blur'); return [IntPtr]::Zero }
            if ($Message -eq 0x0020 -and ($LParam.ToInt64() -band 0xffff) -eq 1) { $null = [NotepadWindow]::SetCursor($this.currentCursor); return [IntPtr]1 }
            if ($Message -eq 0x0084) {
                $null = [NotepadWindow]::GetWindowRect($Handle, $this.procedureScratch)
                [int] $screenX = [int]($LParam.ToInt64() -band 0xffff)
                if ($screenX -ge 32768) { $screenX -= 65536 }
                [int] $screenY = [int](($LParam.ToInt64() -shr 16) -band 0xffff)
                if ($screenY -ge 32768) { $screenY -= 65536 }
                $left = [Runtime.InteropServices.Marshal]::ReadInt32($this.procedureScratch); $top = [Runtime.InteropServices.Marshal]::ReadInt32($this.procedureScratch, 4)
                $right = [Runtime.InteropServices.Marshal]::ReadInt32($this.procedureScratch, 8); $bottom = [Runtime.InteropServices.Marshal]::ReadInt32($this.procedureScratch, 12)
                $border = [Math]::Max(4, 6 * [NotepadWindow]::GetDpiForWindow($Handle) / 96)
                $l = $screenX -lt $left + $border; $r = $screenX -ge $right - $border; $t = $screenY -lt $top + $border; $b = $screenY -ge $bottom - $border
                if ($t -and $l) { return [IntPtr]13 }
                if ($t -and $r) { return [IntPtr]14 }
                if ($b -and $l) { return [IntPtr]16 }
                if ($b -and $r) { return [IntPtr]17 }
                if ($l) { return [IntPtr]10 }
                if ($r) { return [IntPtr]11 }
                if ($t) { return [IntPtr]12 }
                if ($b) { return [IntPtr]15 }
                return [IntPtr]1
            }
            if ($Message -eq 0x02E0) {
                # WM_DPICHANGED lParam points to an ephemeral suggested RECT. A saved placement was measured at its
                # own monitor's DPI, so while Place puts it back the suggested (rescaled) rectangle is not taken.
                if ($this.placing) { $this.Enqueue('resize'); return [IntPtr]::Zero }
                $x =[Runtime.InteropServices.Marshal]::ReadInt32($LParam); $y = [Runtime.InteropServices.Marshal]::ReadInt32($LParam, 4)
                $w = [Runtime.InteropServices.Marshal]::ReadInt32($LParam, 8) - $x; $h = [Runtime.InteropServices.Marshal]::ReadInt32($LParam, 12) - $y
                $null = [NotepadWindow]::SetWindowPos($Handle, [IntPtr]::Zero, $x, $y, $w, $h, [uint]0x14)
                $this.Enqueue('resize'); return [IntPtr]::Zero
            }
            if ($Message -eq 0x0200 -or $Message -eq 0x0201 -or $Message -eq 0x0202 -or $Message -eq 0x0203 -or $Message -eq 0x0204 -or $Message -eq 0x0205 -or $Message -eq 0x020A -or $Message -eq 0x0100 -or $Message -eq 0x0102 -or $Message -eq 0x0104) {
                $event = [NotepadWindowEvent]::new()
                $event.Kind = 'input'; $event.Message = $Message; $event.W = $WParam.ToInt64(); $event.L = $LParam.ToInt64()
                $event.Ctrl = ([NotepadWindow]::GetKeyState(0x11) -band 0x8000) -ne 0
                $event.Shift = ([NotepadWindow]::GetKeyState(0x10) -band 0x8000) -ne 0
                $event.Alt = ([NotepadWindow]::GetKeyState(0x12) -band 0x8000) -ne 0
                $this.events.Enqueue($event)
                return [IntPtr]::Zero
            }
        }
        catch { $this.callbackError = $_.Exception }
        return [NotepadWindow]::DefWindowProcW($Handle, $Message, $WParam, $LParam)
    }

    NotepadWindow([int]$Width, [int]$Height, [string]$Title) {
        [NotepadWindow]::Current = $this
        $this.arrow = [NotepadWindow]::LoadCursorW([IntPtr]::Zero, [IntPtr]32512)
        $this.ibeam = [NotepadWindow]::LoadCursorW([IntPtr]::Zero, [IntPtr]32513)
        $this.hand = [NotepadWindow]::LoadCursorW([IntPtr]::Zero, [IntPtr]32649)
        $this.currentCursor = $this.arrow
        $this.scratch = [Runtime.InteropServices.Marshal]::AllocHGlobal(128)
        for ($i = 0; $i -lt 128; $i++) { [Runtime.InteropServices.Marshal]::WriteByte($this.scratch, $i, 0) }
        $this.pumpMessage = [Runtime.InteropServices.Marshal]::AllocHGlobal(64)
        $this.procedureScratch = [Runtime.InteropServices.Marshal]::AllocHGlobal(64)
        # The app thread is per-monitor aware too, so window sizes and DPI read from it are physical pixels.
        $this.previousDpi = [NotepadWindow]::SetThreadDpiAwarenessContext([IntPtr](-4))
        $appId = [Runtime.InteropServices.Marshal]::StringToHGlobalUni('MansfieldPlumbing.NotepadPS1')
        try { $null = [NotepadWindow]::SetCurrentProcessExplicitAppUserModelID($appId) } finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($appId) }
        $this.hmodule = [NotepadWindow]::GetModuleHandleW([IntPtr]::Zero)
        $this.classPtr = [Runtime.InteropServices.Marshal]::StringToHGlobalUni('NotepadPS_' + [Guid]::NewGuid().ToString('N'))
        $this.requestedWidth = $Width; $this.requestedHeight = $Height; $this.requestedTitle = $Title
        $start = [NotepadWindow].GetMethod('WindowThread').MethodHandle.GetFunctionPointer()
        $thread = [NotepadWindow]::CreateThread([IntPtr]::Zero, [IntPtr]::Zero, $start, [IntPtr]::Zero, [uint]0, [IntPtr]::Zero)
        if ($thread -eq [IntPtr]::Zero) { throw 'CreateThread failed' }
        $null = [NotepadWindow]::CloseHandle($thread)
        $this.ready.Wait()
        if ($null -ne $this.callbackError) { throw $this.callbackError }
        if ($this.hwnd -eq [IntPtr]::Zero) { throw 'CreateWindowExW failed' }
    }

    [IntPtr] Handle() { return $this.hwnd }
    [NotepadWindowInfo] Info() {
        $null = [NotepadWindow]::GetClientRect($this.hwnd, $this.scratch)
        $info = [NotepadWindowInfo]::new()
        $info.Hwnd = $this.hwnd
        $info.Width = [Runtime.InteropServices.Marshal]::ReadInt32($this.scratch, 8)
        $info.Height = [Runtime.InteropServices.Marshal]::ReadInt32($this.scratch, 12)
        $info.Dpi = [single][NotepadWindow]::GetDpiForWindow($this.hwnd)
        $info.Alive = $this.alive; $info.Focused = $this.focused; $info.Minimized = $this.minimized
        return $info
    }
    # Shown maximized when the placement Place restored was maximized.
    [void] Show() { $null = [NotepadWindow]::ShowWindow($this.hwnd, $(if ($this.maximizeOnShow) { 3 } else { 5 })) }
    # Where the window is: GetWindowPlacement's restored rectangle (workspace coordinates, physical pixels) and whether
    # it is maximized, or was maximized before it was minimized (WPF_RESTORETOMAXIMIZED).
    [NotepadPlacement] Placement() {
        for ($i = 0; $i -lt 44; $i++) { [Runtime.InteropServices.Marshal]::WriteByte($this.scratch, $i, 0) }
        [Runtime.InteropServices.Marshal]::WriteInt32($this.scratch, 0, 44)
        if ([NotepadWindow]::GetWindowPlacement($this.hwnd, $this.scratch) -eq 0) { throw 'GetWindowPlacement failed' }
        $show = [Runtime.InteropServices.Marshal]::ReadInt32($this.scratch, 8)
        $flags = [Runtime.InteropServices.Marshal]::ReadInt32($this.scratch, 4)
        $placement = [NotepadPlacement]::new()
        $placement.Left = [Runtime.InteropServices.Marshal]::ReadInt32($this.scratch, 28); $placement.Top = [Runtime.InteropServices.Marshal]::ReadInt32($this.scratch, 32)
        $placement.Right = [Runtime.InteropServices.Marshal]::ReadInt32($this.scratch, 36); $placement.Bottom = [Runtime.InteropServices.Marshal]::ReadInt32($this.scratch, 40)
        $placement.Maximized = $show -eq 3 -or ($show -eq 2 -and ($flags -band 2) -ne 0)
        return $placement
    }
    # Puts the still hidden window where -Stored says (SW_HIDE, so nothing shows before the first frame); Show then
    # maximizes it if it was maximized. SetWindowPlacement moves a rectangle that would be entirely off every monitor
    # back onto one, so a placement saved on a monitor since removed still opens visible.
    [void] Place([NotepadPlacement]$Stored) {
        for ($i = 0; $i -lt 44; $i++) { [Runtime.InteropServices.Marshal]::WriteByte($this.scratch, $i, 0) }
        [Runtime.InteropServices.Marshal]::WriteInt32($this.scratch, 0, 44)
        [Runtime.InteropServices.Marshal]::WriteInt32($this.scratch, 28, $Stored.Left); [Runtime.InteropServices.Marshal]::WriteInt32($this.scratch, 32, $Stored.Top)
        [Runtime.InteropServices.Marshal]::WriteInt32($this.scratch, 36, $Stored.Right); [Runtime.InteropServices.Marshal]::WriteInt32($this.scratch, 40, $Stored.Bottom)
        $this.placing = $true
        try { if ([NotepadWindow]::SetWindowPlacement($this.hwnd, $this.scratch) -eq 0) { throw 'SetWindowPlacement failed' } }
        finally { $this.placing = $false }
        $this.maximizeOnShow = $Stored.Maximized
    }
    [NotepadAppearance] Appearance([string]$Material, [bool]$Dark, [bool]$Curved) {
        # MansfieldPlumbing feature addition; same DWM mechanism as QuickPS Backdrop.ps1.
        $value = [Runtime.InteropServices.Marshal]::AllocHGlobal(16)
        for ($i = 0; $i -lt 16; $i++) { [Runtime.InteropServices.Marshal]::WriteByte($value, $i, 0) }
        try {
            $materialValue = 1
            switch ($Material) { 'mica' { $materialValue = 2 } 'acrylic' { $materialValue = 3 } 'reverseMica' { $materialValue = 4 } }
            [Runtime.InteropServices.Marshal]::WriteInt32($value, $materialValue)
            $hr = [NotepadWindow]::DwmSetWindowAttribute($this.hwnd, [uint]38, $value, [uint]4)
            if ($hr -lt 0) { throw ('DWM backdrop failed: ' + $hr) }
            $null = [NotepadWindow]::DwmGetWindowAttribute($this.hwnd, [uint]38, $value, [uint]4)
            $observed = [Runtime.InteropServices.Marshal]::ReadInt32($value)
            if ($observed -ne $materialValue) { throw 'DWM did not retain the requested backdrop.' }
            [Runtime.InteropServices.Marshal]::WriteInt32($value, [int]$Dark); $null = [NotepadWindow]::DwmSetWindowAttribute($this.hwnd, [uint]20, $value, [uint]4)
            [Runtime.InteropServices.Marshal]::WriteInt32($value, -2); $null = [NotepadWindow]::DwmSetWindowAttribute($this.hwnd, [uint]34, $value, [uint]4) # DWMWA_COLOR_NONE: no white outline
            $null = [NotepadWindow]::DwmGetWindowAttribute($this.hwnd, [uint]34, $value, [uint]4); $borderColor = [Runtime.InteropServices.Marshal]::ReadInt32($value)
            $corner = 1
            if ($Curved) { $corner = 2 }
            [Runtime.InteropServices.Marshal]::WriteInt32($value, $corner); $null = [NotepadWindow]::DwmSetWindowAttribute($this.hwnd, [uint]33, $value, [uint]4)
            foreach ($offset in [int[]]@(0, 4, 8, 12)) { [Runtime.InteropServices.Marshal]::WriteInt32($value, $offset, -1) }
            $hr = [NotepadWindow]::DwmExtendFrameIntoClientArea($this.hwnd, $value)
            if ($hr -lt 0) { throw ('DWM frame extension failed: ' + $hr) }
            $appearance = [NotepadAppearance]::new()
            $appearance.Material = $Material; $appearance.Requested = $materialValue; $appearance.Observed = $observed
            $appearance.Curved = $Curved; $appearance.Dark = $Dark; $appearance.BorderColor = $borderColor
            return $appearance
        }
        finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($value) }
    }
    # Starts the entrance: a fade in place, or with -Slide a fade while the window slides in from beyond the right edge
    # of the screen.
    [NotepadEntrance] BeginEntrance([bool]$Slide) {
        $null = [NotepadWindow]::GetWindowRect($this.hwnd, $this.scratch)
        $this.entranceX = [Runtime.InteropServices.Marshal]::ReadInt32($this.scratch, 0)
        $this.entranceY = [Runtime.InteropServices.Marshal]::ReadInt32($this.scratch, 4)
        $this.entranceFrom = $this.entranceX
        if ($Slide) { $this.entranceFrom = [NotepadWindow]::GetSystemMetrics(76) + [NotepadWindow]::GetSystemMetrics(78) + 24 }
        $this.entranceStyle = [NotepadWindow]::GetWindowLongPtrW($this.hwnd, -20)
        $null = [NotepadWindow]::SetWindowLongPtrW($this.hwnd, -20, [IntPtr]($this.entranceStyle.ToInt64() -bor 0x80000))
        if ([NotepadWindow]::SetLayeredWindowAttributes($this.hwnd, [uint]0, [byte]0, [uint]2) -eq 0) { throw 'Could not initialize the window fade.' }
        $null = [NotepadWindow]::SetWindowPos($this.hwnd, [IntPtr]::Zero, $this.entranceFrom, $this.entranceY, 0, 0, [uint]0x15)
        $entrance = [NotepadEntrance]::new()
        $entrance.FromX = $this.entranceFrom; $entrance.ToX = $this.entranceX; $entrance.Y = $this.entranceY; $entrance.DurationMs = 320
        $entrance.Curve = [double[]]@(0.2, 0.0, 0.0, 1.0)
        return $entrance
    }
    [NotepadEntranceSample] Entrance([double]$Progress) {
        $p = [Math]::Clamp($Progress, 0.0, 1.0)
        $x = [int][Math]::Round($this.entranceFrom + ($this.entranceX - $this.entranceFrom) * $p)
        $null = [NotepadWindow]::SetWindowPos($this.hwnd, [IntPtr]::Zero, $x, $this.entranceY, 0, 0, [uint]0x15)
        $null = [NotepadWindow]::SetLayeredWindowAttributes($this.hwnd, [uint]0, [byte][Math]::Round(255 * $p), [uint]2)
        $null = [NotepadWindow]::GetLayeredWindowAttributes($this.hwnd, [IntPtr]::Add($this.scratch, 32), [IntPtr]::Add($this.scratch, 36), [IntPtr]::Add($this.scratch, 40))
        $alpha = [Runtime.InteropServices.Marshal]::ReadByte($this.scratch, 36)
        $null = [NotepadWindow]::GetWindowRect($this.hwnd, $this.scratch)
        $sample = [NotepadEntranceSample]::new()
        $sample.Progress = $p; $sample.X = [Runtime.InteropServices.Marshal]::ReadInt32($this.scratch, 0); $sample.Alpha = [int]$alpha
        return $sample
    }
    [NotepadEntranceRestore] EndEntrance() {
        $null = $this.Entrance(1)
        $null = [NotepadWindow]::SetWindowLongPtrW($this.hwnd, -20, $this.entranceStyle)
        $null = [NotepadWindow]::SetForegroundWindow($this.hwnd)
        $restore = [NotepadEntranceRestore]::new()
        $restore.OriginalStyle = $this.entranceStyle.ToInt64(); $restore.ObservedStyle = [NotepadWindow]::GetWindowLongPtrW($this.hwnd, -20).ToInt64()
        return $restore
    }
    [IntPtr] SelectIcon([string]$Kind, [int]$Id) {
        $owned = $false
        $icon = [IntPtr]::Zero
        $small = [IntPtr]::Zero
        if ($Kind -eq 'application') {
            # The program's own icon group (resource ID $Id; PSC embeds [ApplicationIcon()] as 1) at the large and
            # small icon sizes. Loaded shared, so Windows owns the handles.
            $icon = [NotepadWindow]::LoadImageW($this.hmodule, [IntPtr]$Id, [uint]1, [NotepadWindow]::GetSystemMetrics(11), [NotepadWindow]::GetSystemMetrics(12), [uint]0x8000)
            $small = [NotepadWindow]::LoadImageW($this.hmodule, [IntPtr]$Id, [uint]1, [NotepadWindow]::GetSystemMetrics(49), [NotepadWindow]::GetSystemMetrics(50), [uint]0x8000)
        }
        elseif ($Kind -eq 'stock') {
            $info = [Runtime.InteropServices.Marshal]::AllocHGlobal(544)
            for ($i = 0; $i -lt 544; $i++) { [Runtime.InteropServices.Marshal]::WriteByte($info, $i, 0) }
            try {
                [Runtime.InteropServices.Marshal]::WriteInt32($info, 544)
                $hr = [NotepadWindow]::SHGetStockIconInfo($Id, [uint]0x100, $info)
                if ($hr -lt 0) { throw ('Stock icon ' + $Id + ' is unavailable.') }
                $icon = [Runtime.InteropServices.Marshal]::ReadIntPtr($info, 8); $owned = $true
            }
            finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($info) }
        }
        else { $icon = [NotepadWindow]::LoadIconW([IntPtr]::Zero, [IntPtr]$Id) }
        if ($icon -eq [IntPtr]::Zero) { throw 'Windows did not supply the selected icon.' }
        if ($small -eq [IntPtr]::Zero) { $small = $icon }
        $null = [NotepadWindow]::SendMessageW($this.hwnd, [uint]0x80, [IntPtr]0, $small); $null = [NotepadWindow]::SendMessageW($this.hwnd, [uint]0x80, [IntPtr]1, $icon)
        if ($this.ownsWindowIcon -and $this.windowIcon -ne [IntPtr]::Zero) { $null = [NotepadWindow]::DestroyIcon($this.windowIcon) }
        $this.windowIcon = $icon; $this.ownsWindowIcon = $owned
        return $icon
    }
    # The events the window thread queued since the last call; the window thread pumps messages on its own.
    [NotepadWindowEvent[]] Drain() {
        if ($null -ne $this.callbackError) { throw $this.callbackError }
        $drained = [Collections.Generic.List[NotepadWindowEvent]]::new()
        [NotepadWindowEvent] $next = $null
        while ($this.events.TryDequeue([ref] $next)) { $drained.Add($next) }
        return $drained.ToArray()
    }
    # Mouse capture belongs to the window's thread, so the request is posted to it.
    [void] Capture([bool]$Value) {
        $null = [NotepadWindow]::PostMessageW($this.hwnd, [uint]0x8001, [IntPtr]([int]$Value), [IntPtr]::Zero)
    }
    [void] Cursor([string]$Kind) {
        $this.currentCursor = $this.arrow
        if ($Kind -eq 'text') { $this.currentCursor = $this.ibeam } elseif ($Kind -eq 'pointer') { $this.currentCursor = $this.hand }
        $null = [NotepadWindow]::SetCursor($this.currentCursor)
    }
    [void] Caption([FluentWindowDecoration]$Decoration) {
        if ($Decoration -eq [FluentWindowDecoration]::Minimize) { $null = [NotepadWindow]::ShowWindow($this.hwnd, 6) }
        elseif ($Decoration -eq [FluentWindowDecoration]::Maximize) {
            $show = 3
            if ([NotepadWindow]::IsZoomed($this.hwnd) -ne 0) { $show = 9 }
            $null = [NotepadWindow]::ShowWindow($this.hwnd, $show)
        }
        # Posted, not sent: the window thread runs Windows' move loop while the app thread keeps painting.
        elseif ($Decoration -eq [FluentWindowDecoration]::Drag) { $null = [NotepadWindow]::PostMessageW($this.hwnd, [uint]0x8001, [IntPtr]::Zero, [IntPtr]::Zero); $null = [NotepadWindow]::PostMessageW($this.hwnd, [uint]0xA1, [IntPtr]2, [IntPtr]::Zero) }
    }
    # The window is destroyed on its own thread (WM_APP + 2), which then ends; the class and buffers go after that.
    [void] Dispose() {
        if ($this.alive) { $null = [NotepadWindow]::PostMessageW($this.hwnd, [uint]0x8002, [IntPtr]::Zero, [IntPtr]::Zero) }
        $null = $this.exited.Wait(5000)
        if ($this.ownsWindowIcon -and $this.windowIcon -ne [IntPtr]::Zero) { $null = [NotepadWindow]::DestroyIcon($this.windowIcon) }
        $null = [NotepadWindow]::UnregisterClassW($this.classPtr, $this.hmodule)
        [Runtime.InteropServices.Marshal]::FreeHGlobal($this.classPtr)
        [Runtime.InteropServices.Marshal]::FreeHGlobal($this.scratch)
        [Runtime.InteropServices.Marshal]::FreeHGlobal($this.pumpMessage)
        [Runtime.InteropServices.Marshal]::FreeHGlobal($this.procedureScratch)
        $null = [NotepadWindow]::SetThreadDpiAwarenessContext($this.previousDpi)
    }
}

# The Windows clipboard: Unicode text (CF_UNICODETEXT) and a file list (CF_HDROP), owned by a window.
class Win32Clipboard {
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] OpenClipboard([IntPtr]$owner) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] CloseClipboard() { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [int] EmptyClipboard() { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [IntPtr] GetClipboardData([uint]$format) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('user32.dll')]
    static [IntPtr] SetClipboardData([uint]$format, [IntPtr]$memory) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('kernel32.dll')]
    static [IntPtr] GlobalAlloc([uint]$flags, [UIntPtr]$bytes) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('kernel32.dll')]
    static [IntPtr] GlobalLock([IntPtr]$memory) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('kernel32.dll')]
    static [int] GlobalUnlock([IntPtr]$memory) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('kernel32.dll')]
    static [IntPtr] GlobalFree([IntPtr]$memory) { throw 'native' }

    # The clipboard's text; '' when it holds none.
    static [string] ReadText([IntPtr]$Owner) {
        if ([Win32Clipboard]::OpenClipboard($Owner) -eq 0) { throw [InvalidOperationException]::new('Clipboard is busy') }
        try {
            # CF_UNICODETEXT is 13.
            $handle = [Win32Clipboard]::GetClipboardData([uint]13)
            if ($handle -eq [IntPtr]::Zero) { return '' }
            $pointer = [Win32Clipboard]::GlobalLock($handle)
            if ($pointer -eq [IntPtr]::Zero) { throw [InvalidOperationException]::new('Clipboard lock failed') }
            try { return [Runtime.InteropServices.Marshal]::PtrToStringUni($pointer) }
            finally { $null = [Win32Clipboard]::GlobalUnlock($handle) }
        }
        finally { $null = [Win32Clipboard]::CloseClipboard() }
    }

    static [void] WriteText([IntPtr]$Owner, [string]$Text) {
        [byte[]]$bytes = [Text.Encoding]::Unicode.GetBytes($Text + [char]0)
        # GMEM_MOVEABLE is 2; CF_UNICODETEXT is 13.
        [Win32Clipboard]::Transfer($Owner, [uint]13, [Win32Clipboard]::Fill([uint]2, $bytes, 0))
    }

    # A file holding Text, named for Title, as a file list: a durable UTF-8 snapshot the clipboard points at.
    static [void] WriteFile([IntPtr]$Owner, [string]$Text, [string]$Title) {
        [string]$folder = [IO.Path]::Join([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData), 'NotepadPS1', 'Clipboard', [guid]::NewGuid().ToString('N'))
        $null = [IO.Directory]::CreateDirectory($folder)
        [string]$name = [IO.Path]::GetFileNameWithoutExtension($Title)
        foreach ($invalid in [IO.Path]::GetInvalidFileNameChars()) { $name = $name.Replace($invalid, [char]'_') }
        if ($name.Length -eq 0) { $name = 'Untitled' }
        [string]$file = [IO.Path]::Join($folder, $name + '.txt')
        [IO.File]::WriteAllText($file, $Text, [Text.UTF8Encoding]::new($false))
        # DROPFILES: pFiles (the list's offset, 20) at 0 and fWide (1) at 16, then the paths, double-null-terminated.
        # GHND (GMEM_MOVEABLE | GMEM_ZEROINIT) is 0x42; CF_HDROP is 15.
        [byte[]]$paths = [Text.Encoding]::Unicode.GetBytes($file + [char]0 + [char]0)
        $handle = [Win32Clipboard]::Fill([uint]0x42, $paths, 20)
        $pointer = [Win32Clipboard]::GlobalLock($handle)
        [Runtime.InteropServices.Marshal]::WriteInt32($pointer, 0, 20)
        [Runtime.InteropServices.Marshal]::WriteInt32($pointer, 16, 1)
        $null = [Win32Clipboard]::GlobalUnlock($handle)
        [Win32Clipboard]::Transfer($Owner, [uint]15, $handle)
    }

    # Global memory of Offset bytes followed by Bytes.
    hidden static [IntPtr] Fill([uint]$Flags, [byte[]]$Bytes, [int]$Offset) {
        $handle = [Win32Clipboard]::GlobalAlloc($Flags, [UIntPtr][uint]($Offset + $Bytes.Length))
        if ($handle -eq [IntPtr]::Zero) { throw [InvalidOperationException]::new('Clipboard allocation failed') }
        $pointer = [Win32Clipboard]::GlobalLock($handle)
        if ($pointer -eq [IntPtr]::Zero) { $null = [Win32Clipboard]::GlobalFree($handle); throw [InvalidOperationException]::new('Clipboard lock failed') }
        try { [Runtime.InteropServices.Marshal]::Copy($Bytes, 0, [IntPtr]::Add($pointer, $Offset), $Bytes.Length) }
        finally { $null = [Win32Clipboard]::GlobalUnlock($handle) }
        return $handle
    }

    # Hands the memory to the clipboard, which owns it once SetClipboardData succeeds; until then it is freed here.
    hidden static [void] Transfer([IntPtr]$Owner, [uint]$Format, [IntPtr]$Handle) {
        [bool]$owned = $true
        try {
            if ([Win32Clipboard]::OpenClipboard($Owner) -eq 0) { throw [InvalidOperationException]::new('Clipboard is busy') }
            try {
                if ([Win32Clipboard]::EmptyClipboard() -eq 0) { throw [InvalidOperationException]::new('Cannot clear clipboard') }
                if ([Win32Clipboard]::SetClipboardData($Format, $Handle) -eq [IntPtr]::Zero) { throw [InvalidOperationException]::new('Clipboard transfer failed') }
                $owned = $false
            }
            finally { $null = [Win32Clipboard]::CloseClipboard() }
        }
        finally { if ($owned) { $null = [Win32Clipboard]::GlobalFree($Handle) } }
    }
}

# The common file dialog (GetOpenFileNameW, GetSaveFileNameW) for text documents.
class Win32FileDialog {
    [System.Runtime.InteropServices.LibraryImport('comdlg32.dll')]
    static [int] GetOpenFileNameW([IntPtr]$dialog) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('comdlg32.dll')]
    static [int] GetSaveFileNameW([IntPtr]$dialog) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('comdlg32.dll')]
    static [uint] CommDlgExtendedError() { throw 'native' }

    # The chosen path; $null when the dialog is cancelled. Suggested is the save dialog's starting name.
    static [string] Choose([IntPtr]$Owner, [bool]$Save, [string]$Suggested) {
        # OPENFILENAMEW x64 layout, commdlg.h. All buffers outlive the modal call.
        $dialog = [Runtime.InteropServices.Marshal]::AllocHGlobal(152)
        $file = [Runtime.InteropServices.Marshal]::AllocHGlobal(65536)
        $filter = [Runtime.InteropServices.Marshal]::StringToHGlobalUni('Text documents (*.txt;*.md)' + [char]0 + '*.txt;*.md' + [char]0 + 'All files (*.*)' + [char]0 + '*.*' + [char]0 + [char]0)
        $extension = [Runtime.InteropServices.Marshal]::StringToHGlobalUni('txt')
        try {
            [byte[]]$zero = [byte[]]::new(152)
            [Runtime.InteropServices.Marshal]::Copy($zero, 0, $dialog, 152)
            [Runtime.InteropServices.Marshal]::WriteInt16($file, 0, [short]0)
            if ($Save) {
                [byte[]]$chars = [Text.Encoding]::Unicode.GetBytes($Suggested + [char]0)
                [Runtime.InteropServices.Marshal]::Copy($chars, 0, $file, [Math]::Min($chars.Length, 65534))
            }
            [Runtime.InteropServices.Marshal]::WriteInt32($dialog, 0, 152)
            [Runtime.InteropServices.Marshal]::WriteIntPtr($dialog, 8, $Owner)
            [Runtime.InteropServices.Marshal]::WriteIntPtr($dialog, 24, $filter)
            [Runtime.InteropServices.Marshal]::WriteInt32($dialog, 44, 1)
            [Runtime.InteropServices.Marshal]::WriteIntPtr($dialog, 48, $file)
            [Runtime.InteropServices.Marshal]::WriteInt32($dialog, 56, 32768)
            # OFN_EXPLORER 0x80000 | OFN_PATHMUSTEXIST 0x800 | OFN_NOCHANGEDIR 0x8, with OFN_FILEMUSTEXIST 0x1000 to open
            # or OFN_OVERWRITEPROMPT 0x2 to save.
            [int]$flags = 0x81808
            if ($Save) { $flags = 0x8080A }
            [Runtime.InteropServices.Marshal]::WriteInt32($dialog, 96, $flags)
            [Runtime.InteropServices.Marshal]::WriteIntPtr($dialog, 104, $extension)
            [int]$chosen = 0
            if ($Save) { $chosen = [Win32FileDialog]::GetSaveFileNameW($dialog) } else { $chosen = [Win32FileDialog]::GetOpenFileNameW($dialog) }
            if ($chosen -ne 0) { return [Runtime.InteropServices.Marshal]::PtrToStringUni($file) }
            [uint]$code = [Win32FileDialog]::CommDlgExtendedError()
            if ($code -ne 0) { throw [InvalidOperationException]::new('File dialog failed: ' + $code) }
            return $null
        }
        finally {
            [Runtime.InteropServices.Marshal]::FreeHGlobal($dialog)
            [Runtime.InteropServices.Marshal]::FreeHGlobal($file)
            [Runtime.InteropServices.Marshal]::FreeHGlobal($filter)
            [Runtime.InteropServices.Marshal]::FreeHGlobal($extension)
        }
    }
}

function Invoke-Window.Windows {
[CmdletBinding()]
param([int]$Width=1280,[int]$Height=720,[string]$Title='Notepad — PowerShell')
if($MyInvocation.InvocationName -eq '.'){throw 'Invoke Window.Windows.ps1 with &.'}
[NotepadWindow]::new($Width, $Height, $Title)
}

# Folded from src\Graphics.Windows.ps1
class NotepadTextMetrics {
    [single]$Width
    [single]$TrailingWidth
    [single]$Height
    [int]$Lines
}

class NotepadCaret {
    [single]$X
    [single]$Y
    [single]$Width
    [single]$Height
}

class NotepadHit {
    [int]$Position
    [bool]$Trailing
    [int]$ClusterStart
}

class NotepadRect {
    [single]$X
    [single]$Y
    [single]$Width
    [single]$Height
}

# Typed vector geometry, drawn by NotepadGraphics. A segment continues a figure from where the last one ended, in
# absolute coordinates: a line to (X, Y); a cubic Bézier through (X1, Y1) and (X2, Y2) to (X, Y); a quadratic
# Bézier through (X1, Y1) to (X, Y); an elliptical arc to (X, Y) with radii (X1, Y1), rotated by Rotation degrees,
# the large arc or the small, clockwise or not.
enum NotepadSegmentKind { Line; Cubic; Quadratic; Arc }
class NotepadSegment {
    [NotepadSegmentKind]$Kind
    [single]$X1
    [single]$Y1
    [single]$X2
    [single]$Y2
    [single]$X
    [single]$Y
    [single]$Rotation
    [bool]$Large
    [bool]$Clockwise
    static [NotepadSegment] Line([single]$X, [single]$Y) {
        $segment = [NotepadSegment]::new(); $segment.Kind = [NotepadSegmentKind]::Line; $segment.X = $X; $segment.Y = $Y
        return $segment
    }
    static [NotepadSegment] Cubic([single]$X1, [single]$Y1, [single]$X2, [single]$Y2, [single]$X, [single]$Y) {
        $segment = [NotepadSegment]::new(); $segment.Kind = [NotepadSegmentKind]::Cubic
        $segment.X1 = $X1; $segment.Y1 = $Y1; $segment.X2 = $X2; $segment.Y2 = $Y2; $segment.X = $X; $segment.Y = $Y
        return $segment
    }
    static [NotepadSegment] Quadratic([single]$X1, [single]$Y1, [single]$X, [single]$Y) {
        $segment = [NotepadSegment]::new(); $segment.Kind = [NotepadSegmentKind]::Quadratic
        $segment.X1 = $X1; $segment.Y1 = $Y1; $segment.X = $X; $segment.Y = $Y
        return $segment
    }
    static [NotepadSegment] Arc([single]$X, [single]$Y, [single]$RadiusX, [single]$RadiusY, [single]$Rotation, [bool]$Large, [bool]$Clockwise) {
        $segment = [NotepadSegment]::new(); $segment.Kind = [NotepadSegmentKind]::Arc
        $segment.X = $X; $segment.Y = $Y; $segment.X1 = $RadiusX; $segment.Y1 = $RadiusY
        $segment.Rotation = $Rotation; $segment.Large = $Large; $segment.Clockwise = $Clockwise
        return $segment
    }
}
# A figure: a start point and the segments that follow it, closed back to the start or left open.
class NotepadFigure {
    [single]$StartX
    [single]$StartY
    [bool]$Closed
    [NotepadSegment[]]$Segments
    NotepadFigure([single]$StartX, [single]$StartY, [bool]$Closed, [NotepadSegment[]]$Segments) {
        $this.StartX = $StartX; $this.StartY = $StartY; $this.Closed = $Closed; $this.Segments = $Segments
    }
}
# A filled shape: its figures, filled nonzero; its colour ('' for the colour it is drawn in) and opacity.
class NotepadShape {
    [string]$Fill
    [single]$Opacity
    [NotepadFigure[]]$Figures
    NotepadShape([string]$Fill, [single]$Opacity, [NotepadFigure[]]$Figures) { $this.Fill = $Fill; $this.Opacity = $Opacity; $this.Figures = $Figures }
}
# An icon: the size its shapes are drawn in, scaled to the size asked for.
class NotepadIcon {
    [single]$Width
    [single]$Height
    [NotepadShape[]]$Shapes
    NotepadIcon([single]$Width, [single]$Height, [NotepadShape[]]$Shapes) { $this.Width = $Width; $this.Height = $Height; $this.Shapes = $Shapes }
}
# Notepad's icons as typed geometry: each a size and filled shapes of figures in absolute coordinates. Converted once
# from the design's SVG path data by the path interpretation NotepadGraphics used (relative coordinates, H, V, S, T
# and degenerate arcs resolved as it resolved them); a shape's empty fill takes the colour the icon is drawn in.
class NotepadIcons {
    static [Collections.Generic.Dictionary[string,NotepadIcon]] All() {
        $icons = [Collections.Generic.Dictionary[string,NotepadIcon]]::new([StringComparer]::Ordinal)
        $icons['app'] = [NotepadIcon]::new(24, 24, [NotepadShape[]]@(
            [NotepadShape]::new('#0078d4', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(4, 2.5, $true, [NotepadSegment[]]@([NotepadSegment]::Cubic(4, 1.67, 4.67, 1, 5.5, 1), [NotepadSegment]::Line(18.5, 1), [NotepadSegment]::Cubic(19.33, 1, 20, 1.67, 20, 2.5), [NotepadSegment]::Line(20, 21.5), [NotepadSegment]::Cubic(20, 22.33, 19.33, 23, 18.5, 23), [NotepadSegment]::Line(5.5, 23), [NotepadSegment]::Cubic(4.67, 23, 4, 22.33, 4, 21.5), [NotepadSegment]::Line(4, 2.5))))),
            [NotepadShape]::new('#60cdff', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(7, 6, $true, [NotepadSegment[]]@([NotepadSegment]::Line(17, 6), [NotepadSegment]::Line(17, 8), [NotepadSegment]::Line(7, 8))),
                [NotepadFigure]::new(7, 10, $true, [NotepadSegment[]]@([NotepadSegment]::Line(17, 10), [NotepadSegment]::Line(17, 12), [NotepadSegment]::Line(7, 12))),
                [NotepadFigure]::new(7, 14, $true, [NotepadSegment[]]@([NotepadSegment]::Line(13, 14), [NotepadSegment]::Line(13, 16), [NotepadSegment]::Line(7, 16))))),
            [NotepadShape]::new('#ffffff', 0.8, [NotepadFigure[]]@(
                [NotepadFigure]::new(7, 18, $true, [NotepadSegment[]]@([NotepadSegment]::Line(17, 18), [NotepadSegment]::Line(17, 19.5), [NotepadSegment]::Line(7, 19.5)))))))
        $icons['minimize'] = [NotepadIcon]::new(10, 10, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(0, 5, $true, [NotepadSegment[]]@([NotepadSegment]::Line(10, 5), [NotepadSegment]::Line(10, 6), [NotepadSegment]::Line(0, 6)))))))
        $icons['maximize'] = [NotepadIcon]::new(10, 10, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(1, 1, $true, [NotepadSegment[]]@([NotepadSegment]::Line(9, 1), [NotepadSegment]::Line(9, 9), [NotepadSegment]::Line(1, 9), [NotepadSegment]::Line(1, 1))),
                [NotepadFigure]::new(2, 2, $true, [NotepadSegment[]]@([NotepadSegment]::Line(2, 8), [NotepadSegment]::Line(8, 8), [NotepadSegment]::Line(8, 2), [NotepadSegment]::Line(2, 2)))))))
        $icons['restore'] = [NotepadIcon]::new(10, 10, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(3, 1, $true, [NotepadSegment[]]@([NotepadSegment]::Line(9, 1), [NotepadSegment]::Line(9, 7), [NotepadSegment]::Line(8, 7), [NotepadSegment]::Line(8, 2), [NotepadSegment]::Line(3, 2), [NotepadSegment]::Line(3, 1))),
                [NotepadFigure]::new(1, 3, $true, [NotepadSegment[]]@([NotepadSegment]::Line(7, 3), [NotepadSegment]::Line(7, 9), [NotepadSegment]::Line(1, 9), [NotepadSegment]::Line(1, 3))),
                [NotepadFigure]::new(2, 4, $true, [NotepadSegment[]]@([NotepadSegment]::Line(2, 8), [NotepadSegment]::Line(6, 8), [NotepadSegment]::Line(6, 4), [NotepadSegment]::Line(2, 4)))))))
        $icons['close'] = [NotepadIcon]::new(10, 10, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(1.4, 0.7, $true, [NotepadSegment[]]@([NotepadSegment]::Line(5, 4.3), [NotepadSegment]::Line(8.6, 0.7), [NotepadSegment]::Line(9.3, 1.4), [NotepadSegment]::Line(5.7, 5), [NotepadSegment]::Line(9.3, 8.6), [NotepadSegment]::Line(8.6, 9.3), [NotepadSegment]::Line(5, 5.7), [NotepadSegment]::Line(1.4, 9.3), [NotepadSegment]::Line(0.7, 8.6), [NotepadSegment]::Line(4.3, 5), [NotepadSegment]::Line(0.7, 1.4)))))))
        $icons['plus'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(8, 2, $true, [NotepadSegment[]]@([NotepadSegment]::Arc(8.75, 2.75, 0.75, 0.75, 0, $False, $True), [NotepadSegment]::Line(8.75, 7.25), [NotepadSegment]::Line(13.25, 7.25), [NotepadSegment]::Arc(13.25, 8.75, 0.75, 0.75, 0, $False, $True), [NotepadSegment]::Line(8.75, 8.75), [NotepadSegment]::Line(8.75, 13.25), [NotepadSegment]::Arc(7.25, 13.25, 0.75, 0.75, 0, $False, $True), [NotepadSegment]::Line(7.25, 8.75), [NotepadSegment]::Line(2.75, 8.75), [NotepadSegment]::Arc(2.75, 7.25, 0.75, 0.75, 0, $False, $True), [NotepadSegment]::Line(7.25, 7.25), [NotepadSegment]::Line(7.25, 2.75), [NotepadSegment]::Arc(8, 2, 0.75, 0.75, 0, $False, $True)))))))
        $icons['back'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(13.5, 7.25, $true, [NotepadSegment[]]@([NotepadSegment]::Line(4.86, 7.25), [NotepadSegment]::Line(8.83, 3.28), [NotepadSegment]::Arc(7.77, 2.2199999999999998, 0.75, 0.75, 0, $False, $False), [NotepadSegment]::Line(2.5199999999999996, 7.47), [NotepadSegment]::Arc(2.5199999999999996, 8.53, 0.75, 0.75, 0, $False, $False), [NotepadSegment]::Line(7.77, 13.78), [NotepadSegment]::Arc(8.83, 12.719999999999999, 0.75, 0.75, 0, $True, $False), [NotepadSegment]::Line(4.86, 8.75), [NotepadSegment]::Line(13.5, 8.75), [NotepadSegment]::Arc(13.5, 7.25, 0.75, 0.75, 0, $False, $False)))))))
        $icons['gear'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(7.07, 1, $true, [NotepadSegment[]]@([NotepadSegment]::Arc(6.09, 1.8, 1, 1, 0, $False, $False), [NotepadSegment]::Line(5.82, 3.14), [NotepadSegment]::Arc(4.54, 3.67, 5.03, 5.03, 0, $False, $False), [NotepadSegment]::Line(3.31, 3.05), [NotepadSegment]::Arc(2.0700000000000003, 3.36, 1, 1, 0, $False, $False), [NotepadSegment]::Line(1.13, 5.01), [NotepadSegment]::Arc(1.2799999999999998, 6.279999999999999, 1, 1, 0, $False, $False), [NotepadSegment]::Line(2.32, 7.159999999999999), [NotepadSegment]::Cubic(2.28, 7.4399999999999995, 2.25, 7.719999999999999, 2.25, 7.999999999999999), [NotepadSegment]::Cubic(2.25, 8.28, 2.28, 8.559999999999999, 2.32, 8.84), [NotepadSegment]::Line(1.2799999999999998, 9.72), [NotepadSegment]::Arc(1.13, 10.99, 1, 1, 0, $False, $False), [NotepadSegment]::Line(2.37, 12.64), [NotepadSegment]::Arc(3.6100000000000003, 12.950000000000001, 1, 1, 0, $False, $False), [NotepadSegment]::Line(4.84, 12.330000000000002), [NotepadSegment]::Cubic(5.24, 12.560000000000002, 5.67, 12.740000000000002, 6.12, 12.860000000000001), [NotepadSegment]::Line(6.390000000000001, 14.200000000000001), [NotepadSegment]::Arc(7.370000000000001, 15.000000000000002, 1, 1, 0, $False, $False), [NotepadSegment]::Line(9.430000000000001, 15.000000000000002), [NotepadSegment]::Arc(10.410000000000002, 14.200000000000001, 1, 1, 0, $False, $False), [NotepadSegment]::Line(10.680000000000001, 12.860000000000001), [NotepadSegment]::Cubic(11.13, 12.740000000000002, 11.560000000000002, 12.56, 11.96, 12.330000000000002), [NotepadSegment]::Line(13.190000000000001, 12.950000000000001), [NotepadSegment]::Arc(14.430000000000001, 12.64, 1, 1, 0, $False, $False), [NotepadSegment]::Line(15.670000000000002, 10.99), [NotepadSegment]::Arc(15.520000000000001, 9.72, 1, 1, 0, $False, $False), [NotepadSegment]::Line(14.48, 8.84), [NotepadSegment]::Cubic(14.52, 8.56, 14.55, 8.28, 14.55, 8), [NotepadSegment]::Cubic(14.55, 7.720000000000001, 14.520000000000001, 7.4399999999999995, 14.48, 7.16), [NotepadSegment]::Line(15.52, 6.28), [NotepadSegment]::Arc(15.67, 5.01, 1, 1, 0, $False, $False), [NotepadSegment]::Line(13.87, 3.36), [NotepadSegment]::Arc(12.629999999999999, 3.05, 1, 1, 0, $False, $False), [NotepadSegment]::Line(11.399999999999999, 3.67), [NotepadSegment]::Arc(10.12, 3.1399999999999997, 5.03, 5.03, 0, $False, $False), [NotepadSegment]::Line(9.85, 1.7999999999999996), [NotepadSegment]::Arc(8.87, 0.9999999999999996, 1, 1, 0, $False, $False), [NotepadSegment]::Line(7.07, 0.9999999999999996))),
                [NotepadFigure]::new(8, 5.5, $true, [NotepadSegment[]]@([NotepadSegment]::Arc(8, 10.5, 2.5, 2.5, 0, $True, $True), [NotepadSegment]::Arc(8, 5.5, 2.5, 2.5, 0, $False, $True)))))))
        $icons['megaphone'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(13, 2.5, $true, [NotepadSegment[]]@([NotepadSegment]::Arc(11.94, 1.8199999999999998, 0.75, 0.75, 0, $False, $False), [NotepadSegment]::Line(4.62, 5.08), [NotepadSegment]::Arc(2, 7.75, 2.75, 2.75, 0, $False, $False), [NotepadSegment]::Line(2, 8.25), [NotepadSegment]::Cubic(2, 9.45, 2.7800000000000002, 10.47, 3.88, 10.83), [NotepadSegment]::Line(3.25, 13.030000000000001), [NotepadSegment]::Arc(4.2, 13.96, 0.75, 0.75, 0, $False, $False), [NotepadSegment]::Line(7.07, 13), [NotepadSegment]::Line(7.550000000000001, 12.84), [NotepadSegment]::Arc(8.020000000000001, 12.39, 0.75, 0.75, 0, $False, $False), [NotepadSegment]::Line(8.650000000000002, 10.5), [NotepadSegment]::Line(11.940000000000001, 10.5), [NotepadSegment]::Line(12.000000000000002, 10.51), [NotepadSegment]::Arc(12.800000000000002, 9.85, 0.75, 0.75, 0, $False, $False), [NotepadSegment]::Line(13.000000000000002, 8.459999999999999), [NotepadSegment]::Arc(15, 5.5, 2.99, 2.99, 0, $False, $False), [NotepadSegment]::Line(15, 5), [NotepadSegment]::Arc(13, 2.5, 2.5, 2.5, 0, $False, $False))),
                [NotepadFigure]::new(14, 5.5, $true, [NotepadSegment[]]@([NotepadSegment]::Cubic(14, 6.33, 13.33, 7, 12.5, 7), [NotepadSegment]::Line(12, 7), [NotepadSegment]::Line(12, 4), [NotepadSegment]::Line(12.5, 4), [NotepadSegment]::Cubic(13.33, 4, 14, 4.67, 14, 5.5)))))))
        $icons['check'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(13.78, 4.22, $true, [NotepadSegment[]]@([NotepadSegment]::Arc(13.78, 5.279999999999999, 0.75, 0.75, 0, $False, $True), [NotepadSegment]::Line(6.529999999999999, 12.53), [NotepadSegment]::Arc(5.469999999999999, 12.53, 0.75, 0.75, 0, $False, $True), [NotepadSegment]::Line(2.22, 9.28), [NotepadSegment]::Arc(3.2800000000000002, 8.219999999999999, 0.75, 0.75, 0, $False, $True), [NotepadSegment]::Line(6, 10.94), [NotepadSegment]::Line(12.719999999999999, 4.22), [NotepadSegment]::Arc(13.78, 4.22, 0.75, 0.75, 0, $False, $True)))))))
        $icons['chevronDown'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(3.2, 5.2, $true, [NotepadSegment[]]@([NotepadSegment]::Arc(4.26, 5.2, 0.75, 0.75, 0, $False, $True), [NotepadSegment]::Line(8, 8.94), [NotepadSegment]::Line(11.74, 5.199999999999999), [NotepadSegment]::Arc(12.8, 6.26, 0.75, 0.75, 0, $True, $True), [NotepadSegment]::Line(8.530000000000001, 10.53), [NotepadSegment]::Arc(7.470000000000001, 10.53, 0.75, 0.75, 0, $False, $True), [NotepadSegment]::Line(3.2, 6.26), [NotepadSegment]::Arc(3.2, 5.199999999999999, 0.75, 0.75, 0, $False, $True)))))))
        $icons['chevronRight'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(5.2, 3.2, $true, [NotepadSegment[]]@([NotepadSegment]::Arc(6.26, 3.2, 0.75, 0.75, 0, $False, $True), [NotepadSegment]::Line(10.53, 7.47), [NotepadSegment]::Arc(10.53, 8.53, 0.75, 0.75, 0, $False, $True), [NotepadSegment]::Line(6.26, 12.799999999999999), [NotepadSegment]::Arc(5.199999999999999, 11.739999999999998, 0.75, 0.75, 0, $False, $True), [NotepadSegment]::Line(8.94, 8), [NotepadSegment]::Line(5.2, 4.26), [NotepadSegment]::Arc(5.2, 3.1999999999999997, 0.75, 0.75, 0, $False, $True)))))))
        $icons['theme'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(8, 1, $true, [NotepadSegment[]]@([NotepadSegment]::Arc(8, 15, 7, 7, 0, $True, $False), [NotepadSegment]::Arc(8, 1, 7, 7, 0, $False, $False))),
                [NotepadFigure]::new(8, 2.5, $true, [NotepadSegment[]]@([NotepadSegment]::Arc(8, 13.5, 5.5, 5.5, 0, $True, $True), [NotepadSegment]::Arc(8, 2.5, 5.5, 5.5, 0, $False, $True))),
                [NotepadFigure]::new(7.25, 4.5, $true, [NotepadSegment[]]@([NotepadSegment]::Line(7.25, 8.5), [NotepadSegment]::Cubic(7.25, 8.7, 7.33, 8.89, 7.47, 9.03), [NotepadSegment]::Line(9.969999999999999, 11.53), [NotepadSegment]::Line(11.03, 10.469999999999999), [NotepadSegment]::Line(8.75, 8.19), [NotepadSegment]::Line(8.75, 4.5), [NotepadSegment]::Line(7.25, 4.5)))))))
        $icons['font'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(3.5, 13, $true, [NotepadSegment[]]@([NotepadSegment]::Line(5.3, 13), [NotepadSegment]::Line(6.4, 10), [NotepadSegment]::Line(9.600000000000001, 10), [NotepadSegment]::Line(10.700000000000001, 13), [NotepadSegment]::Line(12.500000000000002, 13), [NotepadSegment]::Line(8.8, 2.5), [NotepadSegment]::Line(7.2, 2.5), [NotepadSegment]::Line(3.5, 13))),
                [NotepadFigure]::new(6.9, 8.5, $true, [NotepadSegment[]]@([NotepadSegment]::Line(8, 5.3), [NotepadSegment]::Line(9.1, 8.5), [NotepadSegment]::Line(6.9, 8.5)))))))
        $icons['wordWrap'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(2, 3.5, $true, [NotepadSegment[]]@([NotepadSegment]::Line(14, 3.5), [NotepadSegment]::Line(14, 5), [NotepadSegment]::Line(2, 5), [NotepadSegment]::Line(2, 3.5))),
                [NotepadFigure]::new(2, 7.5, $true, [NotepadSegment[]]@([NotepadSegment]::Line(11, 7.5), [NotepadSegment]::Arc(11, 12.5, 2.5, 2.5, 0, $True, $True), [NotepadSegment]::Line(8.5, 12.5), [NotepadSegment]::Line(8.5, 11), [NotepadSegment]::Line(11, 11), [NotepadSegment]::Arc(11, 9, 1, 1, 0, $True, $False), [NotepadSegment]::Line(2, 9), [NotepadSegment]::Line(2, 7.5))),
                [NotepadFigure]::new(2, 11.5, $true, [NotepadSegment[]]@([NotepadSegment]::Line(6.5, 11.5), [NotepadSegment]::Line(6.5, 13), [NotepadSegment]::Line(2, 13), [NotepadSegment]::Line(2, 11.5))))),
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(8, 10.5, $true, [NotepadSegment[]]@([NotepadSegment]::Line(5.5, 12.5), [NotepadSegment]::Line(8, 14.5), [NotepadSegment]::Line(8, 10.5)))))))
        $icons['formatting'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(12.8, 1.2, $true, [NotepadSegment[]]@([NotepadSegment]::Arc(11.4, 1.2, 1, 1, 0, $False, $False), [NotepadSegment]::Line(7.5, 5.1), [NotepadSegment]::Line(10.9, 8.5), [NotepadSegment]::Line(14.8, 4.6), [NotepadSegment]::Arc(14.8, 3.1999999999999997, 1, 1, 0, $False, $False), [NotepadSegment]::Line(12.8, 1.1999999999999997))),
                [NotepadFigure]::new(6.8, 5.8, $true, [NotepadSegment[]]@([NotepadSegment]::Line(2.2, 10.4), [NotepadSegment]::Cubic(2, 10.6, 1.9000000000000001, 10.9, 1.9000000000000001, 11.200000000000001), [NotepadSegment]::Line(1.9000000000000001, 13.5), [NotepadSegment]::Cubic(1.9000000000000001, 13.8, 2.1, 14, 2.4000000000000004, 14), [NotepadSegment]::Line(4.7, 14), [NotepadSegment]::Cubic(5, 14, 5.3, 13.9, 5.5, 13.7), [NotepadSegment]::Line(10.1, 9.1), [NotepadSegment]::Line(6.8999999999999995, 5.8)))))))
        $icons['openFiles'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(3, 2, $true, [NotepadSegment[]]@([NotepadSegment]::Arc(1, 4, 2, 2, 0, $False, $False), [NotepadSegment]::Line(1, 12), [NotepadSegment]::Arc(3, 14, 2, 2, 0, $False, $False), [NotepadSegment]::Line(11, 14), [NotepadSegment]::Arc(13, 12, 2, 2, 0, $False, $False), [NotepadSegment]::Line(13, 9.5), [NotepadSegment]::Line(11.5, 9.5), [NotepadSegment]::Line(11.5, 12), [NotepadSegment]::Arc(11, 12.5, 0.5, 0.5, 0, $False, $True), [NotepadSegment]::Line(3, 12.5), [NotepadSegment]::Arc(2.5, 12, 0.5, 0.5, 0, $False, $True), [NotepadSegment]::Line(2.5, 4), [NotepadSegment]::Arc(3, 3.5, 0.5, 0.5, 0, $False, $True), [NotepadSegment]::Line(5.5, 3.5), [NotepadSegment]::Line(5.5, 2), [NotepadSegment]::Line(3, 2))),
                [NotepadFigure]::new(10, 2, $true, [NotepadSegment[]]@([NotepadSegment]::Line(10, 3.5), [NotepadSegment]::Line(12.44, 3.5), [NotepadSegment]::Line(6.72, 9.22), [NotepadSegment]::Line(7.779999999999999, 10.280000000000001), [NotepadSegment]::Line(13.5, 4.56), [NotepadSegment]::Line(13.5, 7), [NotepadSegment]::Line(15, 7), [NotepadSegment]::Line(15, 2), [NotepadSegment]::Line(10, 2)))))))
        $icons['tabsApp'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(2, 3, $true, [NotepadSegment[]]@([NotepadSegment]::Arc(1, 4, 1, 1, 0, $False, $False), [NotepadSegment]::Line(1, 12), [NotepadSegment]::Arc(2, 13, 1, 1, 0, $False, $False), [NotepadSegment]::Line(14, 13), [NotepadSegment]::Arc(15, 12, 1, 1, 0, $False, $False), [NotepadSegment]::Line(15, 4), [NotepadSegment]::Arc(14, 3, 1, 1, 0, $False, $False), [NotepadSegment]::Line(2, 3))),
                [NotepadFigure]::new(2, 4.5, $true, [NotepadSegment[]]@([NotepadSegment]::Line(14, 4.5), [NotepadSegment]::Line(14, 5.5), [NotepadSegment]::Line(2, 5.5), [NotepadSegment]::Line(2, 4.5))),
                [NotepadFigure]::new(2, 7, $true, [NotepadSegment[]]@([NotepadSegment]::Line(14, 7), [NotepadSegment]::Line(14, 13), [NotepadSegment]::Line(2, 13), [NotepadSegment]::Line(2, 7)))))))
        $icons['recentFiles'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(8, 1, $true, [NotepadSegment[]]@([NotepadSegment]::Arc(8, 15, 7, 7, 0, $True, $False), [NotepadSegment]::Arc(8, 1, 7, 7, 0, $False, $False))),
                [NotepadFigure]::new(8, 2.5, $true, [NotepadSegment[]]@([NotepadSegment]::Arc(8, 13.5, 5.5, 5.5, 0, $True, $True), [NotepadSegment]::Arc(8, 2.5, 5.5, 5.5, 0, $False, $True))),
                [NotepadFigure]::new(7.25, 4.5, $true, [NotepadSegment[]]@([NotepadSegment]::Line(7.25, 8.5), [NotepadSegment]::Cubic(7.25, 8.7, 7.33, 8.89, 7.47, 9.03), [NotepadSegment]::Line(9.969999999999999, 11.53), [NotepadSegment]::Line(11.03, 10.469999999999999), [NotepadSegment]::Line(8.75, 8.19), [NotepadSegment]::Line(8.75, 4.5), [NotepadSegment]::Line(7.25, 4.5)))))))
        $icons['spellCheck'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(2.5, 9, $true, [NotepadSegment[]]@([NotepadSegment]::Line(3.6, 9), [NotepadSegment]::Line(4.2, 7.2), [NotepadSegment]::Line(6.2, 7.2), [NotepadSegment]::Line(6.8, 9), [NotepadSegment]::Line(7.9, 9), [NotepadSegment]::Line(5.6, 2.5), [NotepadSegment]::Line(4.3, 2.5), [NotepadSegment]::Line(2.5, 9))),
                [NotepadFigure]::new(4.5, 6.3, $true, [NotepadSegment[]]@([NotepadSegment]::Line(5.2, 4.199999999999999), [NotepadSegment]::Line(5.9, 6.299999999999999), [NotepadSegment]::Line(4.5, 6.299999999999999))),
                [NotepadFigure]::new(10.7, 9, $true, [NotepadSegment[]]@([NotepadSegment]::Line(12.299999999999999, 9), [NotepadSegment]::Cubic(13.399999999999999, 9, 14.1, 8.3, 14.1, 7.3), [NotepadSegment]::Cubic(14.1, 6.7, 13.799999999999999, 6.199999999999999, 13.2, 6), [NotepadSegment]::Cubic(13.6, 5.8, 13.899999999999999, 5.4, 13.899999999999999, 4.8), [NotepadSegment]::Cubic(13.899999999999999, 3.9, 13.2, 3.1999999999999997, 12.2, 3.1999999999999997), [NotepadSegment]::Line(10.7, 3.1999999999999997), [NotepadSegment]::Line(10.7, 9))),
                [NotepadFigure]::new(11.7, 3.4000000000000004, $true, [NotepadSegment[]]@([NotepadSegment]::Line(12.299999999999999, 3.4000000000000004), [NotepadSegment]::Cubic(12.7, 3.4000000000000004, 12.999999999999998, 3.7, 12.999999999999998, 4.1000000000000005), [NotepadSegment]::Cubic(12.999999999999998, 4.500000000000001, 12.699999999999998, 4.800000000000001, 12.299999999999999, 4.800000000000001), [NotepadSegment]::Line(11.7, 4.800000000000001), [NotepadSegment]::Line(11.7, 3.4))),
                [NotepadFigure]::new(11.7, 5.7, $true, [NotepadSegment[]]@([NotepadSegment]::Line(12.399999999999999, 5.7), [NotepadSegment]::Cubic(12.899999999999999, 5.7, 13.2, 6, 13.2, 6.5), [NotepadSegment]::Cubic(13.2, 7, 12.899999999999999, 7.3, 12.399999999999999, 7.3), [NotepadSegment]::Line(11.7, 7.3), [NotepadSegment]::Line(11.7, 5.7))),
                [NotepadFigure]::new(10.8, 11.2, $true, [NotepadSegment[]]@([NotepadSegment]::Line(8.200000000000001, 13.799999999999999), [NotepadSegment]::Line(7.100000000000001, 12.7), [NotepadSegment]::Line(6.400000000000001, 13.399999999999999), [NotepadSegment]::Line(8.200000000000001, 15.2), [NotepadSegment]::Line(11.5, 11.899999999999999), [NotepadSegment]::Line(10.8, 11.2)))))))
        $icons['search'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(11.74, 10.68, $true, [NotepadSegment[]]@([NotepadSegment]::Arc(10.68, 11.74, 6, 6, 0, $True, $False), [NotepadSegment]::Line(14.15, 15.21), [NotepadSegment]::Arc(15.21, 14.15, 0.75, 0.75, 0, $False, $False), [NotepadSegment]::Line(11.74, 10.68))),
                [NotepadFigure]::new(11, 6.5, $true, [NotepadSegment[]]@([NotepadSegment]::Arc(2, 6.5, 4.5, 4.5, 0, $True, $True), [NotepadSegment]::Arc(11, 6.5, 4.5, 4.5, 0, $False, $True)))))))
        $icons['arrowUp'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(8, 3.2, $true, [NotepadSegment[]]@([NotepadSegment]::Line(12.27, 7.47), [NotepadSegment]::Arc(11.209999999999999, 8.53, 0.75, 0.75, 0, $False, $True), [NotepadSegment]::Line(8, 5.31), [NotepadSegment]::Line(4.79, 8.53), [NotepadSegment]::Arc(3.73, 7.469999999999999, 0.75, 0.75, 0, $True, $True), [NotepadSegment]::Line(8, 3.2)))))))
        $icons['arrowDown'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(8, 12.8, $true, [NotepadSegment[]]@([NotepadSegment]::Line(3.73, 8.53), [NotepadSegment]::Arc(4.79, 7.469999999999999, 0.75, 0.75, 0, $False, $True), [NotepadSegment]::Line(8, 10.69), [NotepadSegment]::Line(11.21, 7.469999999999999), [NotepadSegment]::Arc(12.270000000000001, 8.53, 0.75, 0.75, 0, $True, $True), [NotepadSegment]::Line(8, 12.8)))))))
        $icons['caseSensitive'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(3.2, 11.5, $true, [NotepadSegment[]]@([NotepadSegment]::Line(4.5, 11.5), [NotepadSegment]::Line(5.3, 9.3), [NotepadSegment]::Line(7.699999999999999, 9.3), [NotepadSegment]::Line(8.5, 11.5), [NotepadSegment]::Line(9.8, 11.5), [NotepadSegment]::Line(6.8, 3.5), [NotepadSegment]::Line(5.2, 3.5), [NotepadSegment]::Line(3.2, 11.5))),
                [NotepadFigure]::new(5.7, 8.2, $true, [NotepadSegment[]]@([NotepadSegment]::Line(6.5, 5.8999999999999995), [NotepadSegment]::Line(7.3, 8.2), [NotepadSegment]::Line(5.7, 8.2))),
                [NotepadFigure]::new(12.5, 11.5, $true, [NotepadSegment[]]@([NotepadSegment]::Line(13.7, 11.5), [NotepadSegment]::Line(13.7, 7), [NotepadSegment]::Cubic(13.7, 6.1, 13.1, 5.5, 12.2, 5.5), [NotepadSegment]::Cubic(11.299999999999999, 5.5, 10.7, 6.1, 10.7, 7), [NotepadSegment]::Line(10.7, 11.5), [NotepadSegment]::Line(11.899999999999999, 11.5), [NotepadSegment]::Line(11.899999999999999, 10.4), [NotepadSegment]::Cubic(12.099999999999998, 10.8, 12.499999999999998, 11, 12.899999999999999, 11), [NotepadSegment]::Cubic(13.599999999999998, 11, 13.999999999999998, 10.6, 13.999999999999998, 9.9), [NotepadSegment]::Line(13.999999999999998, 7.5), [NotepadSegment]::Line(12.499999999999998, 7.5), [NotepadSegment]::Line(12.499999999999998, 9.9), [NotepadSegment]::Cubic(12.499999999999998, 10.200000000000001, 12.699999999999998, 10.4, 12.999999999999998, 10.4), [NotepadSegment]::Cubic(13.299999999999999, 10.4, 13.499999999999998, 10.200000000000001, 13.499999999999998, 9.9), [NotepadSegment]::Line(13.499999999999998, 8.5), [NotepadSegment]::Line(12.299999999999999, 8.5), [NotepadSegment]::Line(12.299999999999999, 7), [NotepadSegment]::Cubic(12.299999999999999, 6.7, 12.499999999999998, 6.5, 12.799999999999999, 6.5), [NotepadSegment]::Cubic(13.1, 6.5, 13.299999999999999, 6.7, 13.299999999999999, 7), [NotepadSegment]::Line(13.299999999999999, 11.5)))))))
        $icons['wrapAround'] = [NotepadIcon]::new(16, 16, [NotepadShape[]]@(
            [NotepadShape]::new('', 1, [NotepadFigure[]]@(
                [NotepadFigure]::new(2.5, 8.5, $true, [NotepadSegment[]]@([NotepadSegment]::Arc(4.1, 4.6, 5.5, 5.5, 0, $True, $False), [NotepadSegment]::Line(2, 4.6), [NotepadSegment]::Line(2, 3), [NotepadSegment]::Line(6, 3), [NotepadSegment]::Line(6, 7), [NotepadSegment]::Line(4.5, 7), [NotepadSegment]::Line(4.5, 5.5), [NotepadSegment]::Arc(3.3, 8.3, 4, 4, 0, $True, $True), [NotepadSegment]::Line(2, 8.3), [NotepadSegment]::Line(2, 8.5)))))))
        return $icons
    }
}

# Direct2D and DirectWrite through their COM interfaces: slots checked against Windows SDK 10.0.26100.0. Each COM
# method is a pointer stub called with the slot's address and the object; each export is a library import. Every COM
# object and temporary allocation has an explicit owner.
class NotepadGraphics {
    hidden [IntPtr]$scratch
    hidden [Collections.Generic.Dictionary[string,IntPtr]]$brushes = [Collections.Generic.Dictionary[string,IntPtr]]::new([StringComparer]::OrdinalIgnoreCase)
    hidden [Collections.Generic.Dictionary[string,IntPtr]]$formats = [Collections.Generic.Dictionary[string,IntPtr]]::new([StringComparer]::OrdinalIgnoreCase)
    hidden [Collections.Generic.Dictionary[NotepadShape,IntPtr]]$geometries = [Collections.Generic.Dictionary[NotepadShape,IntPtr]]::new()
    hidden [Collections.Generic.Dictionary[string,IntPtr]]$bitmaps = [Collections.Generic.Dictionary[string,IntPtr]]::new([StringComparer]::OrdinalIgnoreCase)
    hidden [Collections.Generic.Dictionary[string,IntPtr]]$gradientBrushes = [Collections.Generic.Dictionary[string,IntPtr]]::new([StringComparer]::OrdinalIgnoreCase)
    hidden [Collections.Generic.HashSet[IntPtr]]$layouts = [Collections.Generic.HashSet[IntPtr]]::new()
    hidden [IntPtr]$factory
    hidden [IntPtr]$writeFactory
    hidden [IntPtr]$target
    hidden [IntPtr]$wicFactory
    hidden [bool]$curved = $true

    [System.Runtime.InteropServices.LibraryImport('d2d1.dll')]
    static [int] D2D1CreateFactory([int]$type, [IntPtr]$iid, [IntPtr]$options, [IntPtr]$factory) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('dwrite.dll')]
    static [int] DWriteCreateFactory([int]$type, [IntPtr]$iid, [IntPtr]$factory) { throw 'native' }
    [System.Runtime.InteropServices.LibraryImport('ole32.dll')]
    static [int] CoCreateInstance([IntPtr]$clsid, [IntPtr]$outer, [uint]$context, [IntPtr]$iid, [IntPtr]$instance) { throw 'native' }

    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [uint] Release([IntPtr]$method, [IntPtr]$object) { throw 'native' }
    # ID2D1Factory
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] CreatePathGeometry([IntPtr]$method, [IntPtr]$object, [IntPtr]$geometry) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] CreateHwndRenderTarget([IntPtr]$method, [IntPtr]$object, [IntPtr]$properties, [IntPtr]$hwndProperties, [IntPtr]$target) { throw 'native' }
    # ID2D1RenderTarget
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] CreateBitmap([IntPtr]$method, [IntPtr]$object, [ulong]$size, [IntPtr]$source, [uint]$pitch, [IntPtr]$properties, [IntPtr]$bitmap) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] CreateBitmapFromWicBitmap([IntPtr]$method, [IntPtr]$object, [IntPtr]$source, [IntPtr]$properties, [IntPtr]$bitmap) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] CreateSolidColorBrush([IntPtr]$method, [IntPtr]$object, [IntPtr]$color, [IntPtr]$properties, [IntPtr]$brush) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] CreateGradientStopCollection([IntPtr]$method, [IntPtr]$object, [IntPtr]$stops, [uint]$count, [int]$gamma, [int]$extend, [IntPtr]$collection) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] CreateLinearGradientBrush([IntPtr]$method, [IntPtr]$object, [IntPtr]$gradient, [IntPtr]$properties, [IntPtr]$collection, [IntPtr]$brush) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] DrawRectangle([IntPtr]$method, [IntPtr]$object, [IntPtr]$rect, [IntPtr]$brush, [single]$width, [IntPtr]$style) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] FillRectangle([IntPtr]$method, [IntPtr]$object, [IntPtr]$rect, [IntPtr]$brush) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] DrawRoundedRectangle([IntPtr]$method, [IntPtr]$object, [IntPtr]$rect, [IntPtr]$brush, [single]$width, [IntPtr]$style) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] FillRoundedRectangle([IntPtr]$method, [IntPtr]$object, [IntPtr]$rect, [IntPtr]$brush) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] DrawEllipse([IntPtr]$method, [IntPtr]$object, [IntPtr]$ellipse, [IntPtr]$brush, [single]$width, [IntPtr]$style) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] FillEllipse([IntPtr]$method, [IntPtr]$object, [IntPtr]$ellipse, [IntPtr]$brush) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] FillGeometry([IntPtr]$method, [IntPtr]$object, [IntPtr]$geometry, [IntPtr]$brush, [IntPtr]$opacityBrush) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] DrawBitmap([IntPtr]$method, [IntPtr]$object, [IntPtr]$bitmap, [IntPtr]$destination, [single]$opacity, [int]$interpolation, [IntPtr]$source) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] DrawTextLayout([IntPtr]$method, [IntPtr]$object, [ulong]$origin, [IntPtr]$layout, [IntPtr]$brush, [int]$options) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] SetTransform([IntPtr]$method, [IntPtr]$object, [IntPtr]$transform) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] SetTextAntialiasMode([IntPtr]$method, [IntPtr]$object, [int]$mode) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] PushAxisAlignedClip([IntPtr]$method, [IntPtr]$object, [IntPtr]$rect, [int]$mode) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] PopAxisAlignedClip([IntPtr]$method, [IntPtr]$object) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] Clear([IntPtr]$method, [IntPtr]$object, [IntPtr]$color) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] BeginDraw([IntPtr]$method, [IntPtr]$object) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] EndDraw([IntPtr]$method, [IntPtr]$object, [IntPtr]$tag1, [IntPtr]$tag2) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] SetDpi([IntPtr]$method, [IntPtr]$object, [single]$x, [single]$y) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] ResizeTarget([IntPtr]$method, [IntPtr]$object, [IntPtr]$size) { throw 'native' }
    # ID2D1Brush, ID2D1LinearGradientBrush
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] SetOpacity([IntPtr]$method, [IntPtr]$object, [single]$opacity) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] SetPoint([IntPtr]$method, [IntPtr]$object, [ulong]$point) { throw 'native' }
    # ID2D1PathGeometry, ID2D1GeometrySink
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] OpenSink([IntPtr]$method, [IntPtr]$object, [IntPtr]$sink) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] SetFillMode([IntPtr]$method, [IntPtr]$object, [int]$mode) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] BeginFigure([IntPtr]$method, [IntPtr]$object, [ulong]$start, [int]$begin) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] EndFigure([IntPtr]$method, [IntPtr]$object, [int]$end) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] CloseSink([IntPtr]$method, [IntPtr]$object) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] AddLine([IntPtr]$method, [IntPtr]$object, [ulong]$point) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [void] AddSegment([IntPtr]$method, [IntPtr]$object, [IntPtr]$segment) { throw 'native' }
    # IDWriteFactory, IDWriteTextFormat, IDWriteTextLayout
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] CreateTextFormat([IntPtr]$method, [IntPtr]$object, [IntPtr]$family, [IntPtr]$collection, [int]$weight, [int]$style, [int]$stretch, [single]$size, [IntPtr]$locale, [IntPtr]$format) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] CreateTextLayout([IntPtr]$method, [IntPtr]$object, [IntPtr]$text, [uint]$length, [IntPtr]$format, [single]$width, [single]$height, [IntPtr]$layout) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] SetFormatInteger([IntPtr]$method, [IntPtr]$object, [int]$value) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] SetFormatSingle([IntPtr]$method, [IntPtr]$object, [single]$value) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] SetLineSpacing([IntPtr]$method, [IntPtr]$object, [int]$spacing, [single]$lineSpacing, [single]$baseline) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] GetMetrics([IntPtr]$method, [IntPtr]$object, [IntPtr]$metrics) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] HitTestPoint([IntPtr]$method, [IntPtr]$object, [single]$x, [single]$y, [IntPtr]$trailing, [IntPtr]$inside, [IntPtr]$metrics) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] HitTestTextPosition([IntPtr]$method, [IntPtr]$object, [uint]$position, [int]$trailing, [IntPtr]$x, [IntPtr]$y, [IntPtr]$metrics) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] HitTestTextRange([IntPtr]$method, [IntPtr]$object, [uint]$start, [uint]$length, [single]$x, [single]$y, [IntPtr]$metrics, [uint]$capacity, [IntPtr]$count) { throw 'native' }
    # IWICImagingFactory, IWICFormatConverter
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] CreateFormatConverter([IntPtr]$method, [IntPtr]$object, [IntPtr]$converter) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] CreateBitmapFromHICON([IntPtr]$method, [IntPtr]$object, [IntPtr]$icon, [IntPtr]$bitmap) { throw 'native' }
    [System.Runtime.InteropServices.UnmanagedCallConv(CallConvs = [System.Runtime.CompilerServices.CallConvStdcall])]
    static [int] InitializeConverter([IntPtr]$method, [IntPtr]$object, [IntPtr]$source, [IntPtr]$format, [int]$dither, [IntPtr]$palette, [double]$alpha, [int]$paletteType) { throw 'native' }

    # The address of a COM method: the slot of the object's vtable.
    hidden static [IntPtr] Slot([IntPtr]$object, [int]$slot) {
        return [Runtime.InteropServices.Marshal]::ReadIntPtr([Runtime.InteropServices.Marshal]::ReadIntPtr($object), $slot * [IntPtr]::Size)
    }
    hidden static [void] ReleaseCom([IntPtr]$object) {
        if ($object -ne [IntPtr]::Zero) { $null = [NotepadGraphics]::Release([NotepadGraphics]::Slot($object, 2), $object) }
    }
    hidden static [void] Check([int]$Result) {
        if ($Result -lt 0) { throw ('Native graphics HRESULT 0x{0:X8}' -f ($Result -band 0xffffffffL)) }
    }
    hidden [void] Floats([single[]]$Values) { $this.Floats($Values, 0) }
    hidden [void] Floats([single[]]$Values, [int]$Offset) { [Runtime.InteropServices.Marshal]::Copy($Values, 0, [IntPtr]::Add($this.scratch, $Offset), $Values.Length) }
    hidden [single] ReadFloat([int]$Offset) { return [BitConverter]::Int32BitsToSingle([Runtime.InteropServices.Marshal]::ReadInt32($this.scratch, $Offset)) }
    # A D2D1_POINT_2F passed by value: X in the low 32 bits, Y in the high.
    hidden static [ulong] Point([single]$X, [single]$Y) {
        return ([ulong][BitConverter]::SingleToUInt32Bits($Y) -shl 32) -bor [ulong][BitConverter]::SingleToUInt32Bits($X)
    }
    hidden [void] Guid([string]$Value, [int]$Offset) {
        [Runtime.InteropServices.Marshal]::Copy(([Guid]$Value).ToByteArray(), 0, [IntPtr]::Add($this.scratch, $Offset), 16)
    }

    NotepadGraphics([IntPtr]$Hwnd, [int]$Width, [int]$Height, [single]$Dpi) {
        $this.scratch = [Runtime.InteropServices.Marshal]::AllocHGlobal(4096)
        for ($i = 0; $i -lt 4096; $i++) { [Runtime.InteropServices.Marshal]::WriteByte($this.scratch, $i, 0) }
        $out = [IntPtr]::Add($this.scratch, 32)
        $this.Guid('06152247-6f50-465a-9245-118bfd3b6007', 0)
        [NotepadGraphics]::Check([NotepadGraphics]::D2D1CreateFactory(0, $this.scratch, [IntPtr]::Zero, $out))
        $this.factory = [Runtime.InteropServices.Marshal]::ReadIntPtr($out)
        $this.Guid('b859ee5a-d838-4b5b-a2e8-1adc7d93db48', 0)
        [NotepadGraphics]::Check([NotepadGraphics]::DWriteCreateFactory(0, $this.scratch, $out))
        $this.writeFactory = [Runtime.InteropServices.Marshal]::ReadIntPtr($out)
        # D2D1_RENDER_TARGET_PROPERTIES is 28 bytes. D2D1_HWND_RENDER_TARGET_PROPERTIES
        # is 24 bytes on x64: HWND, SIZE_U, present options, alignment padding.
        for ($i = 0; $i -lt 128; $i++) { [Runtime.InteropServices.Marshal]::WriteByte($this.scratch, $i, 0) }
        [Runtime.InteropServices.Marshal]::WriteInt32($this.scratch, 0, 1)
        [Runtime.InteropServices.Marshal]::WriteInt32($this.scratch, 4, 87) # BGRA8
        [Runtime.InteropServices.Marshal]::WriteInt32($this.scratch, 8, 1) # premultiplied alpha exposes the DWM material
        $this.Floats([single[]]@($Dpi, $Dpi), 12)
        [Runtime.InteropServices.Marshal]::WriteIntPtr($this.scratch, 32, $Hwnd)
        [Runtime.InteropServices.Marshal]::WriteInt32($this.scratch, 40, $Width)
        [Runtime.InteropServices.Marshal]::WriteInt32($this.scratch, 44, $Height)
        [NotepadGraphics]::Check([NotepadGraphics]::CreateHwndRenderTarget([NotepadGraphics]::Slot($this.factory, 14), $this.factory, $this.scratch, [IntPtr]::Add($this.scratch, 32), [IntPtr]::Add($this.scratch, 64)))
        $this.target = [Runtime.InteropServices.Marshal]::ReadIntPtr($this.scratch, 64)
        # Grayscale text AA matches CSS antialiased more closely than ClearType.
        [NotepadGraphics]::SetTextAntialiasMode([NotepadGraphics]::Slot($this.target, 34), $this.target, 2)
    }

    hidden [IntPtr] Brush([string]$Color) {
        $cached = [IntPtr]::Zero
        if ($this.brushes.TryGetValue($Color, [ref]$cached)) { return $cached }
        $rgba = [single[]]@(0, 0, 0, 1)
        # rgb(...) or rgba(...): the text between the parentheses, at least one character and no line break.
        [string]$channels = ''
        $open = 0
        if ($Color.StartsWith('rgba(', [StringComparison]::Ordinal)) { $open = 5 } elseif ($Color.StartsWith('rgb(', [StringComparison]::Ordinal)) { $open = 4 }
        if ($open -gt 0 -and $Color.Length -gt $open + 1 -and $Color.EndsWith(')', [StringComparison]::Ordinal)) {
            $channels = $Color.Substring($open, $Color.Length - $open - 1)
            if ($channels.Contains("`n")) { $channels = '' }
        }
        if ($Color.StartsWith('#')) {
            $hex = $Color.Substring(1)
            if ($hex.Length -eq 3) { $hex = [string]::new([char[]]@($hex[0], $hex[0], $hex[1], $hex[1], $hex[2], $hex[2])) }
            $rgba[0] = [Convert]::ToInt32($hex.Substring(0, 2), 16) / 255.0
            $rgba[1] = [Convert]::ToInt32($hex.Substring(2, 2), 16) / 255.0
            $rgba[2] = [Convert]::ToInt32($hex.Substring(4, 2), 16) / 255.0
        }
        elseif ($channels.Length -gt 0) {
            $parts = $channels.Split(',')
            for ($i = 0; $i -lt 3; $i++) { $rgba[$i] = [single]::Parse($parts[$i], [Globalization.CultureInfo]::InvariantCulture) / 255 }
            if ($parts.Count -eq 4) { $rgba[3] = [single]::Parse($parts[3], [Globalization.CultureInfo]::InvariantCulture) }
        }
        elseif ($Color -eq 'transparent') { $rgba[3] = 0 }
        $this.Floats($rgba)
        [NotepadGraphics]::Check([NotepadGraphics]::CreateSolidColorBrush([NotepadGraphics]::Slot($this.target, 8), $this.target, $this.scratch, [IntPtr]::Zero, [IntPtr]::Add($this.scratch, 32)))
        $brush = [Runtime.InteropServices.Marshal]::ReadIntPtr($this.scratch, 32)
        $this.brushes[$Color] = $brush
        return $brush
    }

    [void] Begin([string]$Color) { $this.Begin($Color, 1) }
    [void] Begin([string]$Color, [single]$Opacity) {
        [NotepadGraphics]::BeginDraw([NotepadGraphics]::Slot($this.target, 48), $this.target)
        # Clear requires a color pointer; brushes are not interchangeable.
        $null = $this.Brush($Color)
        $hex = $Color.TrimStart('#')
        $this.Floats([single[]]@(([Convert]::ToInt32($hex.Substring(0, 2), 16) / 255.0), ([Convert]::ToInt32($hex.Substring(2, 2), 16) / 255.0), ([Convert]::ToInt32($hex.Substring(4, 2), 16) / 255.0), $Opacity))
        [NotepadGraphics]::Clear([NotepadGraphics]::Slot($this.target, 47), $this.target, $this.scratch)
    }
    [void] End() {
        [NotepadGraphics]::Check([NotepadGraphics]::EndDraw([NotepadGraphics]::Slot($this.target, 49), $this.target, [IntPtr]::Zero, [IntPtr]::Zero))
    }
    [void] Resize([int]$Width, [int]$Height, [single]$Dpi) {
        [Runtime.InteropServices.Marshal]::WriteInt32($this.scratch, 0, [Math]::Max(1, $Width))
        [Runtime.InteropServices.Marshal]::WriteInt32($this.scratch, 4, [Math]::Max(1, $Height))
        [NotepadGraphics]::Check([NotepadGraphics]::ResizeTarget([NotepadGraphics]::Slot($this.target, 58), $this.target, $this.scratch))
        [NotepadGraphics]::SetDpi([NotepadGraphics]::Slot($this.target, 51), $this.target, $Dpi, $Dpi)
    }
    [void] Fill([single]$X, [single]$Y, [single]$W, [single]$H, [string]$Color) { $this.Fill($X, $Y, $W, $H, $Color, 0) }
    [void] Fill([single]$X, [single]$Y, [single]$W, [single]$H, [string]$Color, [single]$Radius) {
        if ($W -le 0 -or $H -le 0) { return }
        if (-not $this.curved -and $Radius -lt 9) { $Radius = 0 }
        $brush = $this.Brush($Color)
        $this.Floats([single[]]@($X, $Y, ($X + $W), ($Y + $H), $Radius, $Radius))
        if ($Radius -gt 0) { [NotepadGraphics]::FillRoundedRectangle([NotepadGraphics]::Slot($this.target, 19), $this.target, $this.scratch, $brush) }
        else { [NotepadGraphics]::FillRectangle([NotepadGraphics]::Slot($this.target, 17), $this.target, $this.scratch, $brush) }
    }
    [void] Stroke([single]$X, [single]$Y, [single]$W, [single]$H, [string]$Color) { $this.Stroke($X, $Y, $W, $H, $Color, 0, 1) }
    [void] Stroke([single]$X, [single]$Y, [single]$W, [single]$H, [string]$Color, [single]$Radius) { $this.Stroke($X, $Y, $W, $H, $Color, $Radius, 1) }
    [void] Stroke([single]$X, [single]$Y, [single]$W, [single]$H, [string]$Color, [single]$Radius, [single]$Thickness) {
        if (-not $this.curved -and $Radius -lt 9) { $Radius = 0 }
        $brush = $this.Brush($Color)
        $this.Floats([single[]]@(($X + $Thickness / 2), ($Y + $Thickness / 2), ($X + $W - $Thickness / 2), ($Y + $H - $Thickness / 2), $Radius, $Radius))
        if ($Radius -gt 0) { [NotepadGraphics]::DrawRoundedRectangle([NotepadGraphics]::Slot($this.target, 18), $this.target, $this.scratch, $brush, $Thickness, [IntPtr]::Zero) }
        else { [NotepadGraphics]::DrawRectangle([NotepadGraphics]::Slot($this.target, 16), $this.target, $this.scratch, $brush, $Thickness, [IntPtr]::Zero) }
    }
    [void] Clip([single]$X, [single]$Y, [single]$W, [single]$H) {
        $this.Floats([single[]]@($X, $Y, ($X + $W), ($Y + $H)))
        [NotepadGraphics]::PushAxisAlignedClip([NotepadGraphics]::Slot($this.target, 45), $this.target, $this.scratch, 0)
    }
    [void] Unclip() { [NotepadGraphics]::PopAxisAlignedClip([NotepadGraphics]::Slot($this.target, 46), $this.target) }
    [void] FourCorner([single]$X, [single]$Y, [single]$W, [single]$H, [string[]]$Colors) { $this.FourCorner($X, $Y, $W, $H, $Colors, 1) }
    [void] FourCorner([single]$X, [single]$Y, [single]$W, [single]$H, [string[]]$Colors, [single]$Opacity) {
        if ($W -le 0 -or $H -le 0) { return }
        $key = [string]::Join('|', $Colors) + '|' + $Opacity.ToString([Globalization.CultureInfo]::InvariantCulture)
        if (-not $this.bitmaps.ContainsKey($key)) {
            # Four texel centers are the four corners. Linear sampling performs bilinear interpolation.
            $bytes = [byte[]]::new(16)
            for ($i = 0; $i -lt 4; $i++) {
                $hex = $Colors[$i].TrimStart('#'); $offset = $i * 4
                $bytes[$offset] = [byte][Math]::Round([Convert]::ToInt32($hex.Substring(4, 2), 16) * $Opacity)
                $bytes[$offset + 1] = [byte][Math]::Round([Convert]::ToInt32($hex.Substring(2, 2), 16) * $Opacity)
                $bytes[$offset + 2] = [byte][Math]::Round([Convert]::ToInt32($hex.Substring(0, 2), 16) * $Opacity)
                $bytes[$offset + 3] = [byte][Math]::Round(255 * $Opacity)
            }
            [Runtime.InteropServices.Marshal]::Copy($bytes, 0, $this.scratch, 16)
            [Runtime.InteropServices.Marshal]::WriteInt32($this.scratch, 32, 87); [Runtime.InteropServices.Marshal]::WriteInt32($this.scratch, 36, 1); $this.Floats([single[]]@(96, 96), 40)
            [NotepadGraphics]::Check([NotepadGraphics]::CreateBitmap([NotepadGraphics]::Slot($this.target, 4), $this.target, [ulong]8589934594, $this.scratch, [uint]8, [IntPtr]::Add($this.scratch, 32), [IntPtr]::Add($this.scratch, 56)))
            $this.bitmaps[$key] = [Runtime.InteropServices.Marshal]::ReadIntPtr($this.scratch, 56)
        }
        $this.Floats([single[]]@($X, $Y, ($X + $W), ($Y + $H)), 64); $this.Floats([single[]]@(0.5, 0.5, 1.5, 1.5), 80)
        [NotepadGraphics]::DrawBitmap([NotepadGraphics]::Slot($this.target, 26), $this.target, $this.bitmaps[$key], [IntPtr]::Add($this.scratch, 64), [single]1, 1, [IntPtr]::Add($this.scratch, 80))
    }
    [void] NativeIcon([IntPtr]$Handle, [string]$Key, [single]$X, [single]$Y, [single]$Size) {
        $cacheKey = 'icon:' + $Key
        if (-not $this.bitmaps.ContainsKey($cacheKey)) {
            if ($this.wicFactory -eq [IntPtr]::Zero) {
                $this.Guid('cacaf262-9370-4615-a13b-9f5539da4c0a', 0)
                $this.Guid('ec5ec8a9-c395-4314-9c77-54d7a935ff70', 16)
                [NotepadGraphics]::Check([NotepadGraphics]::CoCreateInstance($this.scratch, [IntPtr]::Zero, [uint]1, [IntPtr]::Add($this.scratch, 16), [IntPtr]::Add($this.scratch, 40)))
                $this.wicFactory = [Runtime.InteropServices.Marshal]::ReadIntPtr($this.scratch, 40)
            }
            [NotepadGraphics]::Check([NotepadGraphics]::CreateBitmapFromHICON([NotepadGraphics]::Slot($this.wicFactory, 22), $this.wicFactory, $Handle, $this.scratch))
            $source = [Runtime.InteropServices.Marshal]::ReadIntPtr($this.scratch)
            $converter = [IntPtr]::Zero
            try {
                [NotepadGraphics]::Check([NotepadGraphics]::CreateFormatConverter([NotepadGraphics]::Slot($this.wicFactory, 10), $this.wicFactory, $this.scratch)); $converter = [Runtime.InteropServices.Marshal]::ReadIntPtr($this.scratch)
                $this.Guid('6fddc324-4e03-4bfe-b185-3d77768dc910', 0)
                [NotepadGraphics]::Check([NotepadGraphics]::InitializeConverter([NotepadGraphics]::Slot($converter, 8), $converter, $source, $this.scratch, 0, [IntPtr]::Zero, [double]0, 0))
                [NotepadGraphics]::Check([NotepadGraphics]::CreateBitmapFromWicBitmap([NotepadGraphics]::Slot($this.target, 5), $this.target, $converter, [IntPtr]::Zero, [IntPtr]::Add($this.scratch, 32)))
                $this.bitmaps[$cacheKey] = [Runtime.InteropServices.Marshal]::ReadIntPtr($this.scratch, 32)
            }
            finally { [NotepadGraphics]::ReleaseCom($converter); [NotepadGraphics]::ReleaseCom($source) }
        }
        $this.Floats([single[]]@($X, $Y, ($X + $Size), ($Y + $Size)))
        [NotepadGraphics]::DrawBitmap([NotepadGraphics]::Slot($this.target, 26), $this.target, $this.bitmaps[$cacheKey], $this.scratch, [single]1, 1, [IntPtr]::Zero)
    }
    hidden [IntPtr] GradientBrush([string]$Key, [single[]]$Stops) {
        $cached = [IntPtr]::Zero
        if ($this.gradientBrushes.TryGetValue($Key, [ref]$cached)) { return $cached }
        $this.Floats($Stops)
        [NotepadGraphics]::Check([NotepadGraphics]::CreateGradientStopCollection([NotepadGraphics]::Slot($this.target, 9), $this.target, $this.scratch, [uint]($Stops.Length / 5), 0, 0, [IntPtr]::Add($this.scratch, 2048)))
        $collection = [Runtime.InteropServices.Marshal]::ReadIntPtr($this.scratch, 2048)
        try {
            $this.Floats([single[]]@(0, 0, 1, 1))
            [NotepadGraphics]::Check([NotepadGraphics]::CreateLinearGradientBrush([NotepadGraphics]::Slot($this.target, 10), $this.target, $this.scratch, [IntPtr]::Zero, $collection, [IntPtr]::Add($this.scratch, 2048)))
            $this.gradientBrushes[$Key] = [Runtime.InteropServices.Marshal]::ReadIntPtr($this.scratch, 2048)
        }
        finally { [NotepadGraphics]::ReleaseCom($collection) }
        return $this.gradientBrushes[$Key]
    }
    [void] ColorSpectrum([single]$X, [single]$Y, [single]$Size) {
        $hue = $this.GradientBrush('picker-hue', [single[]]@(0, 1, 0, 0, 1, (1 / 6), 1, 1, 0, 1, (2 / 6), 0, 1, 0, 1, 0.5, 0, 1, 1, 1, (4 / 6), 0, 0, 1, 1, (5 / 6), 1, 0, 1, 1, 1, 1, 0, 0, 1))
        $white = $this.GradientBrush('picker-saturation', [single[]]@(0, 1, 1, 1, 0, 1, 1, 1, 1, 1))
        [NotepadGraphics]::SetPoint([NotepadGraphics]::Slot($hue, 8), $hue, [NotepadGraphics]::Point($X, $Y)); [NotepadGraphics]::SetPoint([NotepadGraphics]::Slot($hue, 9), $hue, [NotepadGraphics]::Point(($X + $Size), $Y))
        [NotepadGraphics]::SetPoint([NotepadGraphics]::Slot($white, 8), $white, [NotepadGraphics]::Point($X, $Y)); [NotepadGraphics]::SetPoint([NotepadGraphics]::Slot($white, 9), $white, [NotepadGraphics]::Point($X, ($Y + $Size)))
        $this.Floats([single[]]@($X, $Y, ($X + $Size), ($Y + $Size), 4, 4))
        [NotepadGraphics]::FillRoundedRectangle([NotepadGraphics]::Slot($this.target, 19), $this.target, $this.scratch, $hue)
        [NotepadGraphics]::FillRoundedRectangle([NotepadGraphics]::Slot($this.target, 19), $this.target, $this.scratch, $white)
    }
    [void] Circle([single]$X, [single]$Y, [single]$Radius, [string]$Color) { $this.Circle($X, $Y, $Radius, $Color, 0) }
    [void] Circle([single]$X, [single]$Y, [single]$Radius, [string]$Color, [single]$Thickness) {
        $brush = $this.Brush($Color); $this.Floats([single[]]@($X, $Y, $Radius, $Radius))
        if ($Thickness -gt 0) { [NotepadGraphics]::DrawEllipse([NotepadGraphics]::Slot($this.target, 20), $this.target, $this.scratch, $brush, $Thickness, [IntPtr]::Zero) }
        else { [NotepadGraphics]::FillEllipse([NotepadGraphics]::Slot($this.target, 21), $this.target, $this.scratch, $brush) }
    }

    [IntPtr] Layout([string]$Text, [string]$Family, [single]$Size, [single]$Width) { return $this.Layout($Text, $Family, $Size, $Width, $false, 400, $false, 0) }
    [IntPtr] Layout([string]$Text, [string]$Family, [single]$Size, [single]$Width, [bool]$Wrap) { return $this.Layout($Text, $Family, $Size, $Width, $Wrap, 400, $false, 0) }
    [IntPtr] Layout([string]$Text, [string]$Family, [single]$Size, [single]$Width, [bool]$Wrap, [int]$Weight) { return $this.Layout($Text, $Family, $Size, $Width, $Wrap, $Weight, $false, 0) }
    [IntPtr] Layout([string]$Text, [string]$Family, [single]$Size, [single]$Width, [bool]$Wrap, [int]$Weight, [bool]$Italic) { return $this.Layout($Text, $Family, $Size, $Width, $Wrap, $Weight, $Italic, 0) }
    [IntPtr] Layout([string]$Text, [string]$Family, [single]$Size, [single]$Width, [bool]$Wrap, [int]$Weight, [bool]$Italic, [single]$LineHeight) {
        $key = $Family + '|' + $Size + '|' + $Wrap + '|' + $Weight + '|' + $Italic + '|' + $LineHeight
        if (-not $this.formats.ContainsKey($key)) {
            $familyPtr = [Runtime.InteropServices.Marshal]::StringToHGlobalUni($Family)
            $localePtr = [Runtime.InteropServices.Marshal]::StringToHGlobalUni('en-us')
            try {
                [NotepadGraphics]::Check([NotepadGraphics]::CreateTextFormat([NotepadGraphics]::Slot($this.writeFactory, 15), $this.writeFactory, $familyPtr, [IntPtr]::Zero, $Weight, ([int]$Italic * 2), 5, $Size, $localePtr, $this.scratch))
                $format = [Runtime.InteropServices.Marshal]::ReadIntPtr($this.scratch)
                $wrapping = 1
                if ($Wrap) { $wrapping = 0 }
                [NotepadGraphics]::Check([NotepadGraphics]::SetFormatInteger([NotepadGraphics]::Slot($format, 5), $format, $wrapping))
                if ($LineHeight -gt 0) { [NotepadGraphics]::Check([NotepadGraphics]::SetLineSpacing([NotepadGraphics]::Slot($format, 10), $format, 1, $LineHeight, ($Size * 0.95))) }
                [NotepadGraphics]::Check([NotepadGraphics]::SetFormatSingle([NotepadGraphics]::Slot($format, 8), $format, ($Size * 0.55 * 4)))
                $this.formats[$key] = $format
            }
            finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($familyPtr); [Runtime.InteropServices.Marshal]::FreeHGlobal($localePtr) }
        }
        $textPtr = [Runtime.InteropServices.Marshal]::StringToHGlobalUni($Text)
        try {
            [NotepadGraphics]::Check([NotepadGraphics]::CreateTextLayout([NotepadGraphics]::Slot($this.writeFactory, 18), $this.writeFactory, $textPtr, [uint]$Text.Length, $this.formats[$key], [single][Math]::Max(1, $Width), [single]1000000, $this.scratch))
            $layout = [Runtime.InteropServices.Marshal]::ReadIntPtr($this.scratch)
            $null = $this.layouts.Add($layout)
            return $layout
        }
        finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($textPtr) }
    }
    [void] ReleaseLayout([IntPtr]$Layout) { if ($this.layouts.Remove($Layout)) { [NotepadGraphics]::ReleaseCom($Layout) } }
    [void] DrawLayout([IntPtr]$Layout, [single]$X, [single]$Y, [string]$Color) {
        $brush = $this.Brush($Color)
        [NotepadGraphics]::DrawTextLayout([NotepadGraphics]::Slot($this.target, 28), $this.target, [NotepadGraphics]::Point($X, $Y), $Layout, $brush, 4)
    }
    [NotepadTextMetrics] Metrics([IntPtr]$Layout) {
        [NotepadGraphics]::Check([NotepadGraphics]::GetMetrics([NotepadGraphics]::Slot($Layout, 60), $Layout, $this.scratch))
        $metrics = [NotepadTextMetrics]::new()
        $metrics.Width = $this.ReadFloat(8); $metrics.TrailingWidth = $this.ReadFloat(12); $metrics.Height = $this.ReadFloat(16)
        $metrics.Lines = [Runtime.InteropServices.Marshal]::ReadInt32($this.scratch, 32)
        return $metrics
    }
    [NotepadCaret] Caret([IntPtr]$Layout, [uint]$Position) { return $this.Caret($Layout, $Position, $false) }
    [NotepadCaret] Caret([IntPtr]$Layout, [uint]$Position, [bool]$Trailing) {
        [NotepadGraphics]::Check([NotepadGraphics]::HitTestTextPosition([NotepadGraphics]::Slot($Layout, 65), $Layout, $Position, [int]$Trailing, $this.scratch, [IntPtr]::Add($this.scratch, 4), [IntPtr]::Add($this.scratch, 16)))
        $caret = [NotepadCaret]::new()
        $caret.X = $this.ReadFloat(0); $caret.Y = $this.ReadFloat(4); $caret.Width = $this.ReadFloat(32); $caret.Height = $this.ReadFloat(36)
        return $caret
    }
    [NotepadHit] HitText([IntPtr]$Layout, [single]$X, [single]$Y) {
        [NotepadGraphics]::Check([NotepadGraphics]::HitTestPoint([NotepadGraphics]::Slot($Layout, 64), $Layout, $X, $Y, $this.scratch, [IntPtr]::Add($this.scratch, 4), [IntPtr]::Add($this.scratch, 16)))
        $start = [Runtime.InteropServices.Marshal]::ReadInt32($this.scratch, 16)
        $length = [Runtime.InteropServices.Marshal]::ReadInt32($this.scratch, 20)
        $hit = [NotepadHit]::new()
        $hit.Trailing = [Runtime.InteropServices.Marshal]::ReadInt32($this.scratch) -ne 0
        $hit.Position = $start
        if ($hit.Trailing) { $hit.Position = $start + $length }
        $hit.ClusterStart = $start
        return $hit
    }
    [NotepadRect[]] Selection([IntPtr]$Layout, [int]$Start, [int]$Length) {
        if ($Length -le 0) { return [NotepadRect[]]::new(0) }
        $countPtr = [Runtime.InteropServices.Marshal]::AllocHGlobal(4)
        [Runtime.InteropServices.Marshal]::WriteInt32($countPtr, 0)
        try {
            $result = [NotepadGraphics]::HitTestTextRange([NotepadGraphics]::Slot($Layout, 66), $Layout, [uint]$Start, [uint]$Length, [single]0, [single]0, [IntPtr]::Zero, [uint]0, $countPtr)
            $count = [Runtime.InteropServices.Marshal]::ReadInt32($countPtr)
            if ($count -eq 0) { [NotepadGraphics]::Check($result); return [NotepadRect[]]::new(0) }
            $memory = [Runtime.InteropServices.Marshal]::AllocHGlobal($count * 36)
            try {
                [NotepadGraphics]::Check([NotepadGraphics]::HitTestTextRange([NotepadGraphics]::Slot($Layout, 66), $Layout, [uint]$Start, [uint]$Length, [single]0, [single]0, $memory, [uint]$count, $countPtr))
                $rects = [NotepadRect[]]::new($count)
                for ($i = 0; $i -lt $count; $i++) {
                    $values = [single[]]::new(4); [Runtime.InteropServices.Marshal]::Copy([IntPtr]::Add($memory, $i * 36 + 8), $values, 0, 4)
                    $rect = [NotepadRect]::new(); $rect.X = $values[0]; $rect.Y = $values[1]; $rect.Width = $values[2]; $rect.Height = $values[3]
                    $rects[$i] = $rect
                }
                return $rects
            }
            finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($memory) }
        }
        finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($countPtr) }
    }
    [void] Text([string]$Text, [single]$X, [single]$Y, [single]$W, [string]$Color) { $this.Text($Text, $X, $Y, $W, $Color, 13, 'Segoe UI', 400) }
    [void] Text([string]$Text, [single]$X, [single]$Y, [single]$W, [string]$Color, [single]$Size) { $this.Text($Text, $X, $Y, $W, $Color, $Size, 'Segoe UI', 400) }
    [void] Text([string]$Text, [single]$X, [single]$Y, [single]$W, [string]$Color, [single]$Size, [string]$Family) { $this.Text($Text, $X, $Y, $W, $Color, $Size, $Family, 400) }
    [void] Text([string]$Text, [single]$X, [single]$Y, [single]$W, [string]$Color, [single]$Size, [string]$Family, [int]$Weight) {
        $layout = $this.Layout($Text, $Family, $Size, $W, $false, $Weight)
        try { $this.DrawLayout($layout, $X, $Y, $Color) } finally { $this.ReleaseLayout($layout) }
    }

    # SVG endpoint arcs map directly to D2D1_ARC_SEGMENT; no raster fallback.
    # A shape's Direct2D path geometry, built once per shape: its figures filled nonzero (D2D1_FILL_MODE_WINDING),
    # each begun filled and ended closed or open.
    hidden [IntPtr] Geometry([NotepadShape]$Shape) {
        $cached = [IntPtr]::Zero
        if ($this.geometries.TryGetValue($Shape, [ref]$cached)) { return $cached }
        [NotepadGraphics]::Check([NotepadGraphics]::CreatePathGeometry([NotepadGraphics]::Slot($this.factory, 10), $this.factory, $this.scratch))
        $geometry = [Runtime.InteropServices.Marshal]::ReadIntPtr($this.scratch)
        [NotepadGraphics]::Check([NotepadGraphics]::OpenSink([NotepadGraphics]::Slot($geometry, 17), $geometry, $this.scratch))
        $sink = [Runtime.InteropServices.Marshal]::ReadIntPtr($this.scratch)
        $line = [NotepadGraphics]::Slot($sink, 10)
        try {
            [NotepadGraphics]::SetFillMode([NotepadGraphics]::Slot($sink, 3), $sink, 1)
            foreach ($figure in $Shape.Figures) {
                [NotepadGraphics]::BeginFigure([NotepadGraphics]::Slot($sink, 5), $sink, [NotepadGraphics]::Point($figure.StartX, $figure.StartY), 0)
                foreach ($segment in $figure.Segments) {
                    if ($segment.Kind -eq [NotepadSegmentKind]::Line) { [NotepadGraphics]::AddLine($line, $sink, [NotepadGraphics]::Point($segment.X, $segment.Y)) }
                    elseif ($segment.Kind -eq [NotepadSegmentKind]::Cubic) {
                        $this.Floats([single[]]@($segment.X1, $segment.Y1, $segment.X2, $segment.Y2, $segment.X, $segment.Y))
                        [NotepadGraphics]::AddSegment([NotepadGraphics]::Slot($sink, 11), $sink, $this.scratch)
                    }
                    elseif ($segment.Kind -eq [NotepadSegmentKind]::Quadratic) {
                        $this.Floats([single[]]@($segment.X1, $segment.Y1, $segment.X, $segment.Y))
                        [NotepadGraphics]::AddSegment([NotepadGraphics]::Slot($sink, 12), $sink, $this.scratch)
                    }
                    else {
                        # D2D1_ARC_SEGMENT: point, size, rotation, then the sweep direction and the arc size.
                        $this.Floats([single[]]@($segment.X, $segment.Y, $segment.X1, $segment.Y1, $segment.Rotation))
                        [Runtime.InteropServices.Marshal]::WriteInt32($this.scratch, 20, $(if ($segment.Clockwise) { 1 } else { 0 }))
                        [Runtime.InteropServices.Marshal]::WriteInt32($this.scratch, 24, $(if ($segment.Large) { 1 } else { 0 }))
                        [NotepadGraphics]::AddSegment([NotepadGraphics]::Slot($sink, 14), $sink, $this.scratch)
                    }
                }
                [NotepadGraphics]::EndFigure([NotepadGraphics]::Slot($sink, 8), $sink, $(if ($figure.Closed) { 1 } else { 0 }))
            }
            [NotepadGraphics]::Check([NotepadGraphics]::CloseSink([NotepadGraphics]::Slot($sink, 9), $sink))
            $this.geometries[$Shape] = $geometry
            return $geometry
        }
        catch { [NotepadGraphics]::ReleaseCom($geometry); throw }
        finally { [NotepadGraphics]::ReleaseCom($sink) }
    }
    [void] Icon([NotepadIcon]$Icon, [single]$X, [single]$Y, [single]$Size, [string]$Color) { $this.Icon($Icon, $X, $Y, $Size, $Color, 0) }
    # Draws an icon at (X, Y), Size wide, its shapes without a colour of their own in Color; turned 180 degrees when
    # asked.
    [void] Icon([NotepadIcon]$Icon, [single]$X, [single]$Y, [single]$Size, [string]$Color, [double]$Rotation) {
        $scale = $Size / $Icon.Width
        foreach ($shape in $Icon.Shapes) {
            $geometry = $this.Geometry($shape)
            $fill = $Color
            if ($shape.Fill.Length -gt 0) { $fill = $shape.Fill }
            $brush = $this.Brush($fill)
            [NotepadGraphics]::SetOpacity([NotepadGraphics]::Slot($brush, 4), $brush, $shape.Opacity)
            if ($Rotation -eq 180) { $this.Floats([single[]]@(-$scale, 0, 0, -$scale, ($X + $Size), ($Y + $Size))) } else { $this.Floats([single[]]@($scale, 0, 0, $scale, $X, $Y)) }
            [NotepadGraphics]::SetTransform([NotepadGraphics]::Slot($this.target, 30), $this.target, $this.scratch)
            [NotepadGraphics]::FillGeometry([NotepadGraphics]::Slot($this.target, 23), $this.target, $geometry, $brush, [IntPtr]::Zero)
            [NotepadGraphics]::SetOpacity([NotepadGraphics]::Slot($brush, 4), $brush, [single]1)
        }
        $this.Floats([single[]]@(1, 0, 0, 1, 0, 0)); [NotepadGraphics]::SetTransform([NotepadGraphics]::Slot($this.target, 30), $this.target, $this.scratch)
    }
    [void] CornerStyle([bool]$Curved) { $this.curved = $Curved }
    [void] Dispose() {
        foreach ($layout in [IntPtr[]]@($this.layouts)) { [NotepadGraphics]::ReleaseCom($layout) }; $this.layouts.Clear()
        foreach ($item in $this.geometries.Values) { [NotepadGraphics]::ReleaseCom($item) }
        foreach ($item in $this.bitmaps.Values) { [NotepadGraphics]::ReleaseCom($item) }
        foreach ($item in $this.gradientBrushes.Values) { [NotepadGraphics]::ReleaseCom($item) }
        foreach ($item in $this.formats.Values) { [NotepadGraphics]::ReleaseCom($item) }
        foreach ($item in $this.brushes.Values) { [NotepadGraphics]::ReleaseCom($item) }
        foreach ($item in [IntPtr[]]@($this.target, $this.writeFactory, $this.factory, $this.wicFactory)) { [NotepadGraphics]::ReleaseCom($item) }
        [Runtime.InteropServices.Marshal]::FreeHGlobal($this.scratch)
    }
}

function Invoke-Graphics.Windows {
[CmdletBinding()]
param([Parameter(Mandatory)][IntPtr]$Hwnd, [int]$Width, [int]$Height, [single]$Dpi = 96)
if ($MyInvocation.InvocationName -eq '.') { throw 'Invoke Graphics.Windows.ps1 with &.' }
[NotepadGraphics]::new($Hwnd, $Width, $Height, $Dpi)
}

# Folded from src\Design.ps1
function Invoke-Design {
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
}

# Folded from tests\Graphics.Smoke.ps1
function Invoke-Graphics.Smoke {
[CmdletBinding()]
param([int]$Seconds=2)
$ErrorActionPreference='Stop'
$root=Split-Path $(Join-Path $PSScriptRoot 'tests')
$native=Invoke-Native
$window=$null;$graphics=$null
try{
    $window=Invoke-Window.Windows -Width 960 -Height 540 -Title 'Notepad PS graphics smoke'
    $info=$window.Info()
    $graphics=Invoke-Graphics.Windows -Hwnd $window.Handle() -Width $info.Width -Height $info.Height -Dpi $info.Dpi
    $window.Show()
    $graphics.Begin('#1f1f1f')
    $graphics.Fill(0,78,960,434,'#282828',0)
    $graphics.Text('Notepad • direct PowerShell',40,12,500,'#ffffff',13,'Segoe UI',400)
    $i=0
    foreach($icon in [NotepadIcons]::All().Values){$graphics.Icon($icon,(20+($i%12)*52),(100+[Math]::Floor($i/12)*52),20,'#ffffff',0);$i++}
    $layout=$graphics.Layout("Alpha`tβeta`nSecond line 😀",'Consolas',([single](11*96/72)),500,$true,400,$false,([single](11*96/72*1.45)))
    $metrics=$graphics.Metrics($layout)
    $graphics.DrawLayout($layout,20,300,'#ffffff')
    $caret=$graphics.Caret($layout,5,$false)
    $graphics.Fill((20+$caret.X),(300+$caret.Y),1,$caret.Height,'#0090f1',0)
    $selection=@($graphics.Selection($layout,1,6))
    $hit=$graphics.HitText($layout,$caret.X,$caret.Y)
    $graphics.End()
    if($metrics.Lines -ne 2){throw 'Text line metrics mismatch'}
    if($hit.Position -ne 5){throw "Caret hit-test round-trip mismatch: $($hit.Position)"}
    if($selection.Count -lt 1){throw 'Missing selection rectangles'}
    @{Metrics=$metrics;Caret=$caret;Hit=$hit;Selection=$selection;IconCount=$i}|ConvertTo-Json -Depth 8|Set-Content "$root\artifacts\graphics-smoke.json"
    $until=[DateTime]::UtcNow.AddSeconds($Seconds)
    while([DateTime]::UtcNow -lt $until){$null=@($window.Drain());Start-Sleep -Milliseconds 15}
    'PASS: native window, Direct2D, DirectWrite, vector icons, caret/hit-test and selection.'
}finally{if($graphics){$graphics.Dispose()};if($window){$window.Dispose()};$native.Dispose()}
}

# Window behaviour Windows 11 provides to every top-level window, observed on Notepad running as its own process and
# driven from outside as Windows and a person drive it: each backdrop as DWM reports it; the title bar and caption
# buttons following the edge during a live resize; the minimum size under a drag; the maximize button as Snap Layouts
# finds it; maximize filling the work area; restore and minimize returning the window; Win+Left, Win+Up and Win+Down.
# The mouse is moved and pressed during the resize. Keys are sent only while Notepad is the foreground window.
function Invoke-Window.Verify {
[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$root=Split-Path $(Join-Path $PSScriptRoot 'tests')
$native=Invoke-Native
$records=[Collections.Generic.List[object]]::new()
function Bind([string]$Name,[Type]$Return,[Type[]]$Types,[string]$Library='user32.dll'){$native.GetExportCall($Library,$Name,$Return,$Types)}
function Record([string]$Check,[object]$Expected,[object]$Observed,[object]$Holds){$records.Add([pscustomobject]@{Check=$Check;Expected=$Expected;Observed=$Observed;Holds=$Holds})}
$dpiContext=Bind 'SetThreadDpiAwarenessContext' ([IntPtr]) @([IntPtr]);$previousDpi=$dpiContext.DynamicInvoke([IntPtr](-4))
$getRect=Bind 'GetWindowRect' ([bool]) @([IntPtr],[IntPtr])
$getDpi=Bind 'GetDpiForWindow' ([uint32]) @([IntPtr])
$show=Bind 'ShowWindow' ([bool]) @([IntPtr],[int])
$isZoomed=Bind 'IsZoomed' ([bool]) @([IntPtr])
$isIconic=Bind 'IsIconic' ([bool]) @([IntPtr])
$send=Bind 'SendMessageW' ([IntPtr]) @([IntPtr],[uint32],[IntPtr],[IntPtr])
$post=Bind 'PostMessageW' ([bool]) @([IntPtr],[uint32],[IntPtr],[IntPtr])
$foreground=Bind 'GetForegroundWindow' ([IntPtr]) @()
$setCursor=Bind 'SetCursorPos' ([bool]) @([int],[int])
$mouse=Bind 'mouse_event' ([void]) @([uint32],[int],[int],[uint32],[IntPtr])
$key=Bind 'keybd_event' ([void]) @([byte],[byte],[uint32],[IntPtr])
$monitorFrom=Bind 'MonitorFromWindow' ([IntPtr]) @([IntPtr],[uint32])
$monitorInfo=Bind 'GetMonitorInfoW' ([bool]) @([IntPtr],[IntPtr])
$dwmGet=Bind 'DwmGetWindowAttribute' ([int]) @([IntPtr],[uint32],[IntPtr],[uint32]) 'dwmapi.dll'
$getDC=Bind 'GetDC' ([IntPtr]) @([IntPtr]);$releaseDC=Bind 'ReleaseDC' ([int]) @([IntPtr],[IntPtr])
$compatibleDC=Bind 'CreateCompatibleDC' ([IntPtr]) @([IntPtr]) 'gdi32.dll';$deleteDC=Bind 'DeleteDC' ([bool]) @([IntPtr]) 'gdi32.dll'
$compatibleBitmap=Bind 'CreateCompatibleBitmap' ([IntPtr]) @([IntPtr],[int],[int]) 'gdi32.dll';$select=Bind 'SelectObject' ([IntPtr]) @([IntPtr],[IntPtr]) 'gdi32.dll'
$deleteObject=Bind 'DeleteObject' ([bool]) @([IntPtr]) 'gdi32.dll';$bitBlt=Bind 'BitBlt' ([bool]) @([IntPtr],[int],[int],[int],[int],[IntPtr],[int],[int],[uint32]) 'gdi32.dll'
$getBits=Bind 'GetDIBits' ([int]) @([IntPtr],[IntPtr],[uint32],[uint32],[IntPtr],[IntPtr],[uint32]) 'gdi32.dll'
$scratch=$native.Allocate(256)
function Rect([IntPtr]$Hwnd){$null=$getRect.DynamicInvoke($Hwnd,$scratch);[int[]]@(0,4,8,12|ForEach-Object{[Runtime.InteropServices.Marshal]::ReadInt32($scratch,$_)})}
function Frame([IntPtr]$Hwnd){$null=$dwmGet.DynamicInvoke($Hwnd,[uint32]9,$scratch,[uint32]16);[int[]]@(0,4,8,12|ForEach-Object{[Runtime.InteropServices.Marshal]::ReadInt32($scratch,$_)})}
function WorkArea([IntPtr]$Hwnd){[Runtime.InteropServices.Marshal]::WriteInt32($scratch,40,40);$null=$monitorInfo.DynamicInvoke($monitorFrom.DynamicInvoke($Hwnd,[uint32]2),[IntPtr]::Add($scratch,40));[int[]]@(60,64,68,72|ForEach-Object{[Runtime.InteropServices.Marshal]::ReadInt32($scratch,$_)})}
function Near([int[]]$A,[int[]]$B,[int]$Tolerance=2){if($A.Length -ne $B.Length){return $false};for($i=0;$i -lt $A.Length;$i++){if([Math]::Abs($A[$i]-$B[$i]) -gt $Tolerance){return $false}};$true}
function Pixels([int]$X,[int]$Y,[int]$W,[int]$H){
    $screen=$getDC.DynamicInvoke([IntPtr]::Zero);$memory=$compatibleDC.DynamicInvoke($screen);$bitmap=$compatibleBitmap.DynamicInvoke($screen,$W,$H);$old=$select.DynamicInvoke($memory,$bitmap)
    $info=$native.Allocate(44);$buffer=$native.Allocate($W*$H*4)
    try{
        $null=$bitBlt.DynamicInvoke($memory,0,0,$W,$H,$screen,$X,$Y,[uint32]0x40CC0020)
        [Runtime.InteropServices.Marshal]::WriteInt32($info,0,40);[Runtime.InteropServices.Marshal]::WriteInt32($info,4,$W);[Runtime.InteropServices.Marshal]::WriteInt32($info,8,-$H)
        [Runtime.InteropServices.Marshal]::WriteInt16($info,12,1);[Runtime.InteropServices.Marshal]::WriteInt16($info,14,32)
        $null=$select.DynamicInvoke($memory,$old)
        $null=$getBits.DynamicInvoke($memory,$bitmap,[uint32]0,[uint32]$H,$buffer,$info,[uint32]0)
        $bytes=[byte[]]::new($W*$H*4);[Runtime.InteropServices.Marshal]::Copy($buffer,$bytes,0,$bytes.Length);,$bytes
    }finally{$native.Free($buffer);$native.Free($info);$null=$deleteObject.DynamicInvoke($bitmap);$null=$deleteDC.DynamicInvoke($memory);$null=$releaseDC.DynamicInvoke([IntPtr]::Zero,$screen)}
}
function Difference([byte[]]$A,[byte[]]$B){$sum=0L;for($i=0;$i -lt $A.Length;$i++){$sum+=[Math]::Abs([int]$A[$i]-[int]$B[$i])};[Math]::Round($sum/$A.Length,2)}
function Chord([byte[]]$Keys){foreach($k in $Keys){$key.DynamicInvoke($k,[byte]0,[uint32]0,[IntPtr]::Zero)};[array]::Reverse($Keys);foreach($k in $Keys){$key.DynamicInvoke($k,[byte]0,[uint32]2,[IntPtr]::Zero)};Start-Sleep -Milliseconds 700}
$expectedBackdrop=@{mica=2;acrylic=3;reverseMica=4}
try{
    foreach($material in 'mica','acrylic','reverseMica'){
        $process=Start-Process -FilePath ([Environment]::ProcessPath) -ArgumentList @('-NoProfile','-STA','-File',$PSCommandPath,'-NoSession','-NoAnimation','-RunSeconds','90','-Backdrop',$material) -PassThru
        try{
            $until=[DateTime]::UtcNow.AddSeconds(90)
            while($process.MainWindowHandle -eq [IntPtr]::Zero -and -not $process.HasExited -and [DateTime]::UtcNow -lt $until){Start-Sleep -Milliseconds 250;$process.Refresh()}
            if($process.MainWindowHandle -eq [IntPtr]::Zero){Record "$material window" 'a window' 'none' $false;continue}
            $hwnd=$process.MainWindowHandle;Start-Sleep -Milliseconds 1500
            $null=$dwmGet.DynamicInvoke($hwnd,[uint32]38,$scratch,[uint32]4);$observed=[Runtime.InteropServices.Marshal]::ReadInt32($scratch)
            Record "backdrop $material" $expectedBackdrop[$material] $observed ($observed -eq $expectedBackdrop[$material])
            if($material -ne 'mica'){continue}
            $scale=$getDpi.DynamicInvoke($hwnd)/96.0
            $minimum=[int[]]@([int][Math]::Ceiling(768*$scale),[int][Math]::Ceiling(478*$scale))
            # Live resize: the close button stays at the top-right corner while the right edge is dragged.
            $start=Rect $hwnd;$button=[int[]]@([int](46*$scale),[int](40*$scale))
            $reference=Pixels ($start[2]-$button[0]) $start[1] $button[0] $button[1]
            $y=[int](($start[1]+$start[3])/2);$null=$setCursor.DynamicInvoke($start[2]-2,$y);Start-Sleep -Milliseconds 150
            $mouse.DynamicInvoke([uint32]2,0,0,[uint32]0,[IntPtr]::Zero);Start-Sleep -Milliseconds 150
            $differences=[Collections.Generic.List[double]]::new()
            foreach($step in 1..8){
                $null=$setCursor.DynamicInvoke($start[2]-2-40*$step,$y);Start-Sleep -Milliseconds 120
                $now=Rect $hwnd;$differences.Add((Difference $reference (Pixels ($now[2]-$button[0]) $now[1] $button[0] $button[1])))
            }
            $null=$setCursor.DynamicInvoke($start[2]-4000,$y);Start-Sleep -Milliseconds 300
            $smallest=Rect $hwnd
            $mouse.DynamicInvoke([uint32]4,0,0,[uint32]0,[IntPtr]::Zero);Start-Sleep -Milliseconds 400
            $worst=($differences|Measure-Object -Maximum).Maximum
            Record 'caption buttons follow the edge during a live resize (mean byte difference per step)' '< 12 at every step' ($differences -join ', ') ($worst -lt 12)
            Record 'minimum width under a drag' $minimum[0] ($smallest[2]-$smallest[0]) (($smallest[2]-$smallest[0]) -eq $minimum[0])
            $null=$show.DynamicInvoke($hwnd,9);Start-Sleep -Milliseconds 400
            # Snap Layouts appears over the maximize button only when the window reports it there.
            $rect=Rect $hwnd;$x=$rect[2]-[int](69*$scale);$top=$rect[1]+[int](20*$scale)
            $hit=$send.DynamicInvoke($hwnd,[uint32]0x84,[IntPtr]::Zero,[IntPtr](($top -shl 16) -bor ($x -band 0xffff))).ToInt64()
            Record 'maximize button hit test (Snap Layouts)' 9 $hit ($hit -eq 9)
            # Maximize fills the work area; restore returns the window.
            $before=Rect $hwnd
            $null=$show.DynamicInvoke($hwnd,3);Start-Sleep -Milliseconds 600
            $work=WorkArea $hwnd;$frame=Frame $hwnd
            Record 'maximized' $true $isZoomed.DynamicInvoke($hwnd) ($isZoomed.DynamicInvoke($hwnd) -eq $true)
            Record 'maximized frame equals the work area' ($work -join ',') ($frame -join ',') (Near $frame $work)
            $null=$show.DynamicInvoke($hwnd,9);Start-Sleep -Milliseconds 600
            $after=Rect $hwnd;Record 'restore after maximize returns the window' ($before -join ',') ($after -join ',') (Near $after $before)
            $null=$show.DynamicInvoke($hwnd,6);Start-Sleep -Milliseconds 600
            Record 'minimized' $true $isIconic.DynamicInvoke($hwnd) ($isIconic.DynamicInvoke($hwnd) -eq $true)
            $null=$show.DynamicInvoke($hwnd,9);Start-Sleep -Milliseconds 600
            $after=Rect $hwnd;Record 'restore after minimize returns the window' ($before -join ',') ($after -join ',') ((-not $isIconic.DynamicInvoke($hwnd)) -and (Near $after $before))
            # Snap with the keyboard, only while Notepad is the foreground window.
            if($foreground.DynamicInvoke() -ne $hwnd){Record 'Win+Left, Win+Up, Win+Down' 'Notepad in the foreground' 'another window was in the foreground; no keys sent' $null}
            else{
                $before=Rect $hwnd
                Chord @(0x5B,0x25)
                $work=WorkArea $hwnd;$frame=Frame $hwnd;$half=[int[]]@($work[0],$work[1],[int]($work[0]+($work[2]-$work[0])/2),$work[3])
                Record 'Win+Left snaps to the left half of the work area' ($half -join ',') ($frame -join ',') (Near $frame $half 3)
                # Snap Assist offers other windows for the other half and takes the foreground; Escape dismisses it.
                if($foreground.DynamicInvoke() -ne $hwnd){Chord @(0x1B)}
                if($foreground.DynamicInvoke() -eq $hwnd){
                    Chord @(0x5B,0x26);Record 'Win+Up maximizes the snapped window' $true $isZoomed.DynamicInvoke($hwnd) ($isZoomed.DynamicInvoke($hwnd) -eq $true)
                    Chord @(0x5B,0x28);Chord @(0x5B,0x28)
                    $after=Rect $hwnd;Record 'Win+Down twice returns the window from snap' ($before -join ',') ($after -join ',') (Near $after $before)
                }else{Record 'Win+Up, Win+Down' 'Notepad in the foreground' 'another window was in the foreground after Snap Assist; no keys sent' $null}
            }
        }finally{
            if(-not $process.HasExited){$null=$post.DynamicInvoke($process.MainWindowHandle,[uint32]0x10,[IntPtr]::Zero,[IntPtr]::Zero);if(-not $process.WaitForExit(10000)){$process.Kill()}}
        }
    }
    $records|ConvertTo-Json -Depth 4|Set-Content "$root\artifacts\window-checks.json"
    $records
}finally{$native.Free($scratch);$null=$dpiContext.DynamicInvoke($previousDpi);$native.Dispose()}
}

# Folded from src\Services.Windows.ps1


if($MyInvocation.InvocationName -eq '.'){throw 'Invoke Notepad.ps1 with &, not dot-sourcing.'}
$ErrorActionPreference='Stop'
if(-not $IsWindows){throw 'This direct Windows implementation requires PowerShell 7 on Windows.'}
# Notepad's own conformance checks: the document model, and the native window, Direct2D and DirectWrite.
if($VerifyModel){Invoke-Model.Verify;return}
if($VerifyWindow){Invoke-Window.Verify;return}
if([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA'){throw 'Launch with pwsh -STA -File Notepad.ps1.'}
if($VerifyGraphics){if($RunSeconds -gt 0){Invoke-Graphics.Smoke -Seconds $RunSeconds}else{Invoke-Graphics.Smoke};return}

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
    # Edits sharing a group undo and redo together (a burst of typing).
    [int] $Group
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
    # The group the next recorded edit joins; BeginGroup starts a new one.
    [int] $Group
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
        $this.Group = 0
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

    # The next line break in a buffer at or after start and before end; -1 when there is none. Uses the runtime's
    # vectorized search over the buffer rather than reading one character at a time.
    [int] NextBreak([int] $buffer, [int] $start, [int] $end) {
        if ($start -ge $end) { return -1 }
        if ($buffer -eq 0) { return [Array]::IndexOf($this.Original, [char]10, $start, $end - $start) }
        return [Array]::IndexOf($this.Added, [char]10, $start, $end - $start)
    }

    [int] CountBreaks([int] $buffer, [int] $start, [int] $length) {
        [int] $count = 0
        [int] $end = $start + $length
        [int] $at = $this.NextBreak($buffer, $start, $end)
        while ($at -ge 0) { $count = $count + 1; $at = $this.NextBreak($buffer, $at + 1, $end) }
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
        $edit.Group = $this.Group
        $this.Journal.Add($edit)
        $this.JournalPosition = $this.Journal.Count
    }

    [void] BeginGroup() { $this.Group = $this.Group + 1 }

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

    # Undoes the last group of edits; returns where the caret goes (after the restored text), or -1 when there is
    # nothing to undo.
    [int] Undo() {
        if ($this.JournalPosition -eq 0) { return -1 }
        [int] $undoing = $this.Journal[$this.JournalPosition - 1].Group
        while ($this.JournalPosition -gt 0 -and $this.Journal[$this.JournalPosition - 1].Group -eq $undoing) {
            $this.JournalPosition = $this.JournalPosition - 1
            [NotepadEdit] $edit = $this.Journal[$this.JournalPosition]
            [NotepadPiece[]] $ignored = $this.ReplacePieces($edit.Position, $this.PiecesLength($edit.Inserted), $edit.Removed)
        }
        # The group's first edit, now at the journal position, holds where the restored text ends.
        [NotepadEdit] $earliest = $this.Journal[$this.JournalPosition]
        return $earliest.Position + $this.PiecesLength($earliest.Removed)
    }

    # Redoes the next group of edits; returns where the caret goes (after the inserted text), or -1 when there is
    # nothing to redo.
    [int] Redo() {
        if ($this.JournalPosition -eq $this.Journal.Count) { return -1 }
        [int] $redoing = $this.Journal[$this.JournalPosition].Group
        while ($this.JournalPosition -lt $this.Journal.Count -and $this.Journal[$this.JournalPosition].Group -eq $redoing) {
            [NotepadEdit] $edit = $this.Journal[$this.JournalPosition]
            [NotepadPiece[]] $ignored = $this.ReplacePieces($edit.Position, $this.PiecesLength($edit.Removed), $edit.Inserted)
            $this.JournalPosition = $this.JournalPosition + 1
        }
        # The group's last edit, just before the journal position, holds where the inserted text ends.
        [NotepadEdit] $latest = $this.Journal[$this.JournalPosition - 1]
        return $latest.Position + $this.PiecesLength($latest.Inserted)
    }

    # The character at a position in the document.
    [char] At([int] $position) {
        [int] $offset = 0
        for ([int] $index = 0; $index -lt $this.Pieces.Count; $index++) {
            [NotepadPiece] $piece = $this.Pieces[$index]
            if ($position -lt $offset + $piece.Length) { return $this.CharAt($piece.Buffer, $piece.Start + ($position - $offset)) }
            $offset = $offset + $piece.Length
        }
        throw [System.ArgumentOutOfRangeException]::new('position')
    }

    # The position where each line starts, in order; pieces without a line break are skipped whole.
    [int[]] LineStarts() {
        [System.Collections.Generic.List[int]] $starts = [System.Collections.Generic.List[int]]::new()
        $starts.Add(0)
        [int] $offset = 0
        for ([int] $index = 0; $index -lt $this.Pieces.Count; $index++) {
            [NotepadPiece] $piece = $this.Pieces[$index]
            if ($piece.LineBreaks -gt 0) {
                [int] $end = $piece.Start + $piece.Length
                [int] $at = $this.NextBreak($piece.Buffer, $piece.Start, $end)
                while ($at -ge 0) { $starts.Add($offset + ($at - $piece.Start) + 1); $at = $this.NextBreak($piece.Buffer, $at + 1, $end) }
            }
            $offset = $offset + $piece.Length
        }
        return $starts.ToArray()
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
                [int] $at = $this.NextBreak($piece.Buffer, $piece.Start, $end)
                while ($at -ge 0) {
                    $seen = $seen + 1
                    if ($seen -eq $line) { return $offset + ($at - $piece.Start) + 1 }
                    $at = $this.NextBreak($piece.Buffer, $at + 1, $end)
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
                return $line + $this.CountBreaks($piece.Buffer, $piece.Start, $end - $piece.Start)
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
    [string] $UIAutomationTestDataDirectory = (Join-Path $PSScriptRoot 'UIAutomation-TestData'),
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
New-Item -ItemType Directory -Path $UIAutomationTestDataDirectory -Force | Out-Null
[pscustomobject]@{ TimeUtc = [datetime]::UtcNow; Predictions = [pscustomobject]$predictions } |
    Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'predictions.clixml')

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
    [pscustomobject]@{TimeUtc=[DateTime]::UtcNow;Machine=$env:COMPUTERNAME;WindowsBuild=[Environment]::OSVersion.Version.ToString();Scope='Available documented stock/system icons and installed Segoe Fluent glyphs';SdkHeader=$header;SdkSHA256=$(if(Test-Path $header){(Get-FileHash $header -Algorithm SHA256).Hash}else{$null});FontPath=$font;FontSHA256=$(if(Test-Path $font){(Get-FileHash $font -Algorithm SHA256).Hash}else{$null});CycleIcons=$icons.ToArray();Glyphs=$glyphs.ToArray()} | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'windows-icon-catalog.clixml')
    [pscustomobject]@{CycleIcons=$icons.Count;SegoeGlyphs=$glyphs.Count;Evidence='windows-icon-catalog.clixml'}
    return
}
if ($VerifyNativeFeatures) {
    # Tests use a fresh clone and retained hit rectangles, without touching the user's running editor.
    $livePath=Join-Path $UIAutomationTestDataDirectory 'native-feature-replay-live.json'
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
            $r=$tree.Properties.BoundingRectangle;$path=Join-Path $UIAutomationTestDataDirectory ('native-feature-'+$Name+'.png')
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
        $replayChecks.Add([pscustomobject]@{Property='Painted offscreen fade entrance';Expected='Completed, alpha 0 to 255';Observed=$entrance.EntranceStatus;Verdict=if($entrance.EntranceStatus -eq 'Completed' -and $(if($entrance.Settings.entranceAnimation -eq 'slide'){$entrance.Entrance.FromX -gt $entrance.Entrance.ToX}else{$entrance.Entrance.FromX -eq $entrance.Entrance.ToX}) -and $entrance.EntranceSamples.Count -ge 2 -and $entrance.EntranceSamples[-1].Alpha -eq 255 -and $entrance.EntranceSamples[-1].X -eq $entrance.Entrance.ToX -and $entrance.EntranceRestore.OriginalStyle -eq $entrance.EntranceRestore.ObservedStyle){'TRUE'}else{'FALSE'}})
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
        Click-Replay 'settings-btn-back'
        [pscustomobject]@{Machine=$env:COMPUTERNAME;WindowsBuild=[Environment]::OSVersion.Version.ToString();TimeUtc=[DateTime]::UtcNow;SourceSHA256=(Get-FileHash (Join-Path $PSScriptRoot 'Notepad.ps1') -Algorithm SHA256).Hash;States=$replayStates.ToArray();Checks=$replayChecks.ToArray()} | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'native-feature-replay.clixml')
        $replayChecks | Format-Table -AutoSize
        if(@($replayChecks|Where-Object Verdict -eq 'FALSE').Count){throw 'The native feature replay found a defect.'}
    }finally{
        [pscustomobject]@{TimeUtc=[DateTime]::UtcNow;SourceSHA256=(Get-FileHash (Join-Path $PSScriptRoot 'Notepad.ps1') -Algorithm SHA256).Hash;States=$replayStates.ToArray();Checks=$replayChecks.ToArray()}|Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'native-feature-replay-last-attempt.clixml')
        foreach($pointer in @($replayRoot,$replayWalker,$replayUia,$replayUnknown)){if($pointer -ne [IntPtr]::Zero){[void][Runtime.InteropServices.Marshal]::Release($pointer)}}
        $nativeReplay.Refresh();if(-not $nativeReplay.HasExited){$nativeReplay.Kill()}
    }
    return
}
$realCachePath = Join-Path $UIAutomationTestDataDirectory 'real-notepad.clixml'
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
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'empty' $UIAutomationTestDataDirectory))
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
                $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle $command.Name $UIAutomationTestDataDirectory))
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
                $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle $command.Name $UIAutomationTestDataDirectory))
            }
            Invoke-UiaElementByName $root $walker 'Open replace options' 50000
            Start-Sleep -Milliseconds 150
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'replace-open' $UIAutomationTestDataDirectory))
            Invoke-UiaElementByName $root $walker 'Exit Find and Replace' 50000
            Start-Sleep -Milliseconds 150
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'find-close' $UIAutomationTestDataDirectory))
            Send-KeyboardInput -Chord $vk.Control, $vk.N
            Start-Sleep -Milliseconds 150
            $discardOwnProbe = Find-UiaElement $root $walker "Don't save" 50000
            if ($discardOwnProbe -ne [IntPtr]::Zero) {
                [void][Runtime.InteropServices.Marshal]::Release($discardOwnProbe)
                # This prompt is for the fresh, instrument-owned temp file only.
                Invoke-UiaElementByName $root $walker "Don't save" 50000
                Start-Sleep -Milliseconds 150
            }
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'new-tab' $UIAutomationTestDataDirectory))
            Invoke-UiaElementByName $root $walker 'File' 50011
            Start-Sleep -Milliseconds 150
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'file-menu' $UIAutomationTestDataDirectory))
            Send-KeyboardInput -Chord $vk.Escape
            Invoke-UiaElementByName $root $walker 'Settings'
            Start-Sleep -Milliseconds 200
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'settings' $UIAutomationTestDataDirectory))
            $unavailableStates = [Collections.Generic.List[string]]::new()
            Click-UiaElementByName $root $walker 'App theme' 50000
            Start-Sleep -Milliseconds 150
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'theme-options' $UIAutomationTestDataDirectory))
            $lightOption = Find-UiaElement $root $walker 'Light' 50013
            if ($lightOption -ne [IntPtr]::Zero) {
                [void][Runtime.InteropServices.Marshal]::Release($lightOption)
                Click-UiaElementByName $root $walker 'Light' 50013
                Start-Sleep -Milliseconds 180
                $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'theme-light' $UIAutomationTestDataDirectory))
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
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'theme-restored' $UIAutomationTestDataDirectory))
            Invoke-UiaElementByName $root $walker 'Back' 50000
            Start-Sleep -Milliseconds 150
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'settings-close' $UIAutomationTestDataDirectory))
            Send-KeyboardInput -Chord $vk.Control, $vk.OemPlus
            Start-Sleep -Milliseconds 150
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'zoom-in' $UIAutomationTestDataDirectory))
            Send-KeyboardInput -Chord $vk.Control, $vk.D0
            Start-Sleep -Milliseconds 150
            $states.Add((Capture-RealState $root $walker $probe.MainWindowHandle 'zoom-restored' $UIAutomationTestDataDirectory))
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
            $observation | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'real-notepad.clixml')
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

$realEvidence = Import-Clixml (Join-Path $UIAutomationTestDataDirectory 'real-notepad.clixml')
$iconEvidence = @(Get-CubicGlyphEvidence $realEvidence)
$iconEvidence | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'fluent-glyph-cubics.clixml')
[pscustomobject]@{ Glyphs = $iconEvidence.Count; Cubics = @($iconEvidence | ForEach-Object { $_.Cubics.Count } | Measure-Object -Sum).Sum; FontSHA256 = if ($iconEvidence.Count) { $iconEvidence[0].FontSHA256 } else { $null } }

if (-not $SkipBrowser) {
    $originalPath = Join-Path $PSScriptRoot 'reference\notepad.html'
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
            $compilation | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'typescript-compilation.clixml')
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
            $semanticLedger | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'typescript-node-semantics.clixml')
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
            $traceCompilerResult | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'typescript-trace-map.clixml')
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
            $designCompilation | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'design-compilation.clixml')
            if ($BuildTypeScript) {
                $designSemanticsJson = & $node -e $semanticProbe $designSource $designOutput
                if ($LASTEXITCODE -ne 0) { throw 'Corrected reference semantic extraction failed.' }
                ($designSemanticsJson | ConvertFrom-Json -Depth 100) |
                    Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'design-node-semantics.clixml')
            }
            # The corrected reference page is generated beside the original (reference\notepad.html), never over it.
            $currentReference = Join-Path $PSScriptRoot 'reference\notepad.design.html'
            if (Test-Path $currentReference) {
                # A previously generated reference may be updated, but an unrecognized edit is preserved.
                $currentHash = (Get-FileHash $currentReference -Algorithm SHA256).Hash
                $generatedHashFile = Join-Path $UIAutomationTestDataDirectory 'generated-reference-hash.clixml'
                if (-not (Test-Path $generatedHashFile) -or $currentHash -ne (Import-Clixml $generatedHashFile).SHA256) {
                    throw 'The corrected reference page differs from the last instrument build.'
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
                Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'generated-reference-hash.clixml')
        }
        $states = [Collections.Generic.List[object]]::new()
        $states.Add((Save-BrowserState $browser 'original-empty' $UIAutomationTestDataDirectory))
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
        $states.Add((Save-BrowserState $browser 'original-typed' $UIAutomationTestDataDirectory))
        Add-BrowserReplayStates $browser 'original' $UIAutomationTestDataDirectory $states
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
        $browserEvidence | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'original-edge.clixml')
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
            $builtStates.Add((Save-BrowserState $built 'built-empty' $UIAutomationTestDataDirectory))
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
            $builtStates.Add((Save-BrowserState $built 'built-typed' $UIAutomationTestDataDirectory))
            Add-BrowserReplayStates $built 'built' $UIAutomationTestDataDirectory $builtStates
            $builtStates.ToArray() | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'built-edge.clixml')
            $originalStates = (Import-Clixml (Join-Path $UIAutomationTestDataDirectory 'original-edge.clixml')).States
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
            $equivalenceRows.ToArray() | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'refactor-equivalence.clixml')
            if ($equivalenceRows | Where-Object { -not ($_.DomEqual -and $_.AppStateEqual -and $_.PixelsEqual) }) {
                throw 'The TypeScript build differs from the original browser oracle.'
            }
            $ledger = Import-Clixml (Join-Path $UIAutomationTestDataDirectory 'typescript-node-semantics.clixml')
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
            $ledger | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'typescript-node-semantics.clixml')
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
            $traceStates.Add((Save-BrowserState $traced 'trace-empty' $UIAutomationTestDataDirectory))
            Click-CdpSelector $traced 'textarea'
            $null = Invoke-Cdp $traced 'Input.insertText' @{ text = 'Notepad comparison sample' }
            $traceStates.Add((Save-BrowserState $traced 'trace-typed' $UIAutomationTestDataDirectory))
            Add-BrowserReplayStates $traced 'trace' $UIAutomationTestDataDirectory $traceStates
            $traceStates.ToArray() | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'trace-edge.clixml')
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
            $traceVerdicts.ToArray() | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'trace-equivalence.clixml')
            $traceVerdicts | Format-Table -AutoSize
            $traceTrusted = -not @($traceVerdicts | Where-Object { -not ($_.DomEqual -and $_.AppStateEqual -and $_.PixelsEqual) }).Count
            $ledger = Import-Clixml (Join-Path $UIAutomationTestDataDirectory 'typescript-node-semantics.clixml')
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
            $ledger | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'typescript-node-semantics.clixml')
        } finally {
            Close-EdgePage $traced
        }
    }
    $designHashRecord = Join-Path $UIAutomationTestDataDirectory 'generated-reference-hash.clixml'
    $designPath = Join-Path $PSScriptRoot 'reference\notepad.design.html'
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
            $designStates.Add((Save-BrowserState $designBrowser 'design-empty' $UIAutomationTestDataDirectory))
            Click-CdpSelector $designBrowser 'textarea'
            $null = Invoke-Cdp $designBrowser 'Input.insertText' @{ text='Notepad comparison sample' }
            $designStates.Add((Save-BrowserState $designBrowser 'design-typed' $UIAutomationTestDataDirectory))
            Add-BrowserReplayStates $designBrowser 'design' $UIAutomationTestDataDirectory $designStates
            [pscustomobject]@{
                Metadata = [pscustomobject]@{
                    ReferenceSHA256 = (Get-FileHash $designPath -Algorithm SHA256).Hash
                    SourceSHA256 = (Get-FileHash (Join-Path $PSScriptRoot 'reference\notepad.design.ts') -Algorithm SHA256).Hash
                    TimeUtc = [datetime]::UtcNow
                }
                States = $designStates.ToArray()
            } | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'design-edge.clixml')
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
            $copyTextCapture = Save-BrowserState $designBrowser 'design-copy-text' $UIAutomationTestDataDirectory
            $copyResult = [pscustomobject]@{
                Scenario = 'Whole active document despite partial selection'
                SelectedText = $copyProbe.selected
                Expected = "Whole document for LLM`nSecond line"
                Actual = $copied.value
                Calls = $copied.calls
                Verdict = if ($copied.calls -eq 1 -and $copied.value -ceq "Whole document for LLM`nSecond line") { 'TRUE' } else { 'FALSE' }
            }
            $copyResult | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'design-copy-probe.clixml')
            if ($copyResult.Verdict -ne 'TRUE') { throw 'Whole-document Copy probe failed.' }
            Click-CdpSelector $designBrowser '#btn-settings-toggle'
            $null = Get-CdpValue $designBrowser "document.querySelector('#toggle-setting-copy-mode').scrollIntoView({ block: 'center' })"
            Click-CdpSelector $designBrowser '#toggle-setting-copy-mode'
            $fileModeState = Get-BrowserAppState $designBrowser
            Click-CdpSelector $designBrowser '#settings-btn-back'
            $fileModeButton = Get-CdpValue $designBrowser "document.querySelector('#btn-copy-document').getAttribute('aria-label')"
            Click-CdpSelector $designBrowser '#btn-copy-document'
            $copyFileCapture = Save-BrowserState $designBrowser 'design-copy-file' $UIAutomationTestDataDirectory
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
            $fileModeResult | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'design-copy-file-mode-probe.clixml')
            @($copyTextCapture, $copyFileCapture) | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'design-copy-captures.clixml')
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
    $nativeImage = Join-Path $UIAutomationTestDataDirectory 'ps1-empty.png'
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
    $nativeEvidence | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'ps1-render.clixml')
    $nativeEvidence.States | Select-Object Name,ImageSHA256,Image
} finally {
    $nativeProcess.Refresh()
    if (-not $nativeProcess.HasExited) { $nativeProcess.Kill() }
}

$paths = [ordered]@{
    Real = Join-Path $UIAutomationTestDataDirectory 'real-empty.png'
    Reference = Join-Path $UIAutomationTestDataDirectory $(if (Test-Path (Join-Path $UIAutomationTestDataDirectory 'design-edge.clixml')) { 'design-empty.png' } else { 'original-empty.png' })
    PS1 = Join-Path $UIAutomationTestDataDirectory 'ps1-empty.png'
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
$rows.ToArray() | Export-Clixml (Join-Path $UIAutomationTestDataDirectory 'comparison-table.clixml')
$rows | Format-Table -AutoSize

}
if ($Compare) {
    if ([string]::IsNullOrEmpty($UIAutomationTestDataDirectory)) { $UIAutomationTestDataDirectory = Join-Path $PSScriptRoot 'UIAutomation-TestData' }
    Invoke-NotepadComparison -UIAutomationTestDataDirectory $UIAutomationTestDataDirectory -RefreshReal:$RefreshReal -SkipBrowser:$SkipBrowser -KeepProbeOpen:$KeepProbeOpen -ExtractTypeScript:$ExtractTypeScript -BuildTypeScript:$BuildTypeScript -BuildDesign:$BuildDesign -VerifyNativeFeatures:$VerifyNativeFeatures -CatalogIcons:$CatalogIcons
    return
}
# The user's settings, one typed property per setting, named as the saved JSON names them. Get and Set reach a
# setting by a name known only at run time (a toggle, a dropdown, the saved file), case-insensitively as the
# hashtable did; Set converts the value to the setting's type, as an assignment to the property does.
# What a person can ask the application to do: a menu row, a button, a key or a hit region names one. None, the
# default, asks for nothing.
enum FluentAction {
    None
    NewTab
    NewMarkdownTab
    NewActivity
    SwitchTab
    CloseTab
    CloseSpecific
    CloseWindow
    Exit
    Save
    SaveAs
    SaveAll
    OpenFile
    Undo
    Redo
    SelectAll
    Copy
    CopyDocument
    EditColor
    EditAnsi
    CycleIcon
    ResetIcon
    ResetColors
    FormatBold
    FormatItalic
    FormatStrike
    FormatHeading
    FormatList
    FormatLink
    InsertLink
    Cut
    Paste
    Delete
    TimeDate
    Find
    Replace
    CloseFind
    FindNext
    FindPrevious
    FindCase
    FindWrap
    ToggleReplace
    DoReplace
    DoReplaceAll
    GoTo
    GotoConfirm
    ZoomIn
    ZoomOut
    ZoomReset
    ToggleStatusBar
    ToggleWordWrap
    LineEnding
    OpenSettings
    OpenFontSettings
    Back
    Accordion
    ToggleSetting
    Startup
    SettingSelect
    ChooseSetting
    PickerMode
    ToggleMenu
    Submenu
    Minimize
    Maximize
    Drag
    FocusInput
    DiscardTab
    SaveCloseTab
    DiscardWindow
    SaveCloseWindow
    Dismiss
    ToggleMarkdownPreview
    Link
    ClearFormatting
    PageSetup
    Print
    Editor
    Scrollbar
    OpacitySlider
    ModalAction
    PickerSpectrum
    PickerValue
}

# What a window's own decoration does when used: minimize, maximize or restore, and move the window by dragging.
enum FluentWindowDecoration {
    Minimize
    Maximize
    Drag
}

# A colour: red, green and blue channels and an opacity from 0 to 1.
class FluentColor {
    [byte]$Red
    [byte]$Green
    [byte]$Blue
    [double]$Alpha

    FluentColor([byte]$Red, [byte]$Green, [byte]$Blue) { $this.Red = $Red; $this.Green = $Green; $this.Blue = $Blue; $this.Alpha = 1.0 }
    FluentColor([byte]$Red, [byte]$Green, [byte]$Blue, [double]$Opacity) { $this.Red = $Red; $this.Green = $Green; $this.Blue = $Blue; $this.Alpha = $Opacity }

    # This colour moved -Portion (0 to 1) of the way to -Goal, opaque.
    [FluentColor] Toward([FluentColor]$Goal, [double]$Portion) {
        return [FluentColor]::new([byte][Math]::Round($this.Red + ($Goal.Red - $this.Red) * $Portion), [byte][Math]::Round($this.Green + ($Goal.Green - $this.Green) * $Portion), [byte][Math]::Round($this.Blue + ($Goal.Blue - $this.Blue) * $Portion))
    }

    # As CSS writes it: #rrggbb when opaque, rgba(r, g, b, a) otherwise.
    [string] CssText() {
        $culture = [Globalization.CultureInfo]::InvariantCulture
        if ($this.Alpha -eq 1.0) { return [string]::Format($culture, '#{0:x2}{1:x2}{2:x2}', $this.Red, $this.Green, $this.Blue) }
        return [string]::Format($culture, 'rgba({0}, {1}, {2}, {3})', [object[]]@($this.Red, $this.Green, $this.Blue, $this.Alpha))
    }
}

# Fluent's colour theme: one colour per role. A new theme holds the design's base values, which are dark; Dark() and
# Light() are the two themes as the design draws them.
class FluentTheme {
    [FluentColor]$BgWindow = [FluentColor]::new(0x1f, 0x1f, 0x1f)
    [FluentColor]$BgTitlebar = [FluentColor]::new(0x1f, 0x1f, 0x1f)
    [FluentColor]$BgMenubar = [FluentColor]::new(0x1f, 0x1f, 0x1f)
    [FluentColor]$BgEditor = [FluentColor]::new(0x28, 0x28, 0x28)
    [FluentColor]$BgTabActive = [FluentColor]::new(0x2c, 0x2c, 0x2c)
    [FluentColor]$BgTabHover = [FluentColor]::new(0x26, 0x26, 0x26)
    [FluentColor]$BgCard = [FluentColor]::new(0x2d, 0x2d, 0x2d)
    [FluentColor]$BgCardHover = [FluentColor]::new(0x32, 0x32, 0x32)
    [FluentColor]$BgFlyout = [FluentColor]::new(0x2c, 0x2c, 0x2c)
    [FluentColor]$BgFlyoutItemHover = [FluentColor]::new(0x38, 0x38, 0x38)
    [FluentColor]$BgControl = [FluentColor]::new(0x32, 0x32, 0x32)
    [FluentColor]$BgControlHover = [FluentColor]::new(0x3c, 0x3c, 0x3c)
    [FluentColor]$BgControlActive = [FluentColor]::new(0x2a, 0x2a, 0x2a)
    [FluentColor]$BgStatusbar = [FluentColor]::new(0x1f, 0x1f, 0x1f)
    [FluentColor]$BgDialog = [FluentColor]::new(0x2c, 0x2c, 0x2c)
    [FluentColor]$TextPrimary = [FluentColor]::new(0xff, 0xff, 0xff)
    [FluentColor]$TextSecondary = [FluentColor]::new(0x9d, 0x9d, 0x9d)
    [FluentColor]$TextDisabled = [FluentColor]::new(0x60, 0x60, 0x60)
    [FluentColor]$TextLink = [FluentColor]::new(0x60, 0xcd, 0xff)
    [FluentColor]$BorderSubtle = [FluentColor]::new(255, 255, 255, 0.06)
    [FluentColor]$BorderControl = [FluentColor]::new(255, 255, 255, 0.09)
    [FluentColor]$BorderActive = [FluentColor]::new(0x60, 0xcd, 0xff)
    [FluentColor]$AccentColor = [FluentColor]::new(0x00, 0x90, 0xf1)
    [FluentColor]$AccentHover = [FluentColor]::new(0x1a, 0xa0, 0xff)
    [FluentColor]$AccentActive = [FluentColor]::new(0x00, 0x78, 0xd4)
    [FluentColor]$SelectionBg = [FluentColor]::new(0x00, 0x5f, 0xb8)
    [FluentColor]$SelectionText = [FluentColor]::new(0xff, 0xff, 0xff)

    static [FluentTheme] Dark() {
        $theme = [FluentTheme]::new()
        $theme.BgWindow = [FluentColor]::new(0x20, 0x20, 0x20)
        $theme.BgTitlebar = [FluentColor]::new(0x20, 0x20, 0x20)
        $theme.BgMenubar = [FluentColor]::new(0x2c, 0x2c, 0x2c)
        $theme.BgEditor = [FluentColor]::new(0x27, 0x27, 0x27)
        $theme.BgStatusbar = [FluentColor]::new(0x2c, 0x2c, 0x2c)
        return $theme
    }

    static [FluentTheme] Light() {
        $theme = [FluentTheme]::new()
        $theme.BgWindow = [FluentColor]::new(0xf3, 0xf3, 0xf3)
        $theme.BgTitlebar = [FluentColor]::new(0xf3, 0xf3, 0xf3)
        $theme.BgMenubar = [FluentColor]::new(0xf3, 0xf3, 0xf3)
        $theme.BgEditor = [FluentColor]::new(0xff, 0xff, 0xff)
        $theme.BgTabActive = [FluentColor]::new(0xff, 0xff, 0xff)
        $theme.BgTabHover = [FluentColor]::new(0xea, 0xea, 0xea)
        $theme.BgCard = [FluentColor]::new(0xff, 0xff, 0xff)
        $theme.BgCardHover = [FluentColor]::new(0xf9, 0xf9, 0xf9)
        $theme.BgFlyout = [FluentColor]::new(0xff, 0xff, 0xff)
        $theme.BgFlyoutItemHover = [FluentColor]::new(0xf0, 0xf0, 0xf0)
        $theme.BgControl = [FluentColor]::new(0xfb, 0xfb, 0xfb)
        $theme.BgControlHover = [FluentColor]::new(0xf5, 0xf5, 0xf5)
        $theme.BgControlActive = [FluentColor]::new(0xeb, 0xeb, 0xeb)
        $theme.BgStatusbar = [FluentColor]::new(0xf3, 0xf3, 0xf3)
        $theme.BgDialog = [FluentColor]::new(0xff, 0xff, 0xff)
        $theme.TextPrimary = [FluentColor]::new(0x1b, 0x1b, 0x1b)
        $theme.TextSecondary = [FluentColor]::new(0x61, 0x61, 0x61)
        $theme.TextDisabled = [FluentColor]::new(0xa0, 0xa0, 0xa0)
        $theme.TextLink = [FluentColor]::new(0x00, 0x5f, 0xb8)
        $theme.BorderSubtle = [FluentColor]::new(0, 0, 0, 0.06)
        $theme.BorderControl = [FluentColor]::new(0, 0, 0, 0.12)
        $theme.BorderActive = [FluentColor]::new(0x00, 0x5f, 0xb8)
        $theme.AccentColor = [FluentColor]::new(0x00, 0x5f, 0xb8)
        $theme.AccentHover = [FluentColor]::new(0x10, 0x6e, 0xbe)
        $theme.AccentActive = [FluentColor]::new(0x00, 0x45, 0x78)
        $theme.SelectionBg = [FluentColor]::new(0x99, 0xc9, 0xff)
        $theme.SelectionText = [FluentColor]::new(0x00, 0x00, 0x00)
        return $theme
    }

    # Takes the accent, its hover and pressed states, the selection, links and the focus border from Windows' accent
    # family (-Family: Light3, Light2, Light1, accent, Dark1, Dark2, Dark3). A dark theme draws on the light shades and
    # a light theme on the dark ones, so the accent keeps its contrast with the surface. No shades: unchanged.
    [void] UseAccent([FluentColor[]]$Family, [bool]$Light) {
        if ($Family.Length -lt 7) { return }
        if ($Light) {
            $this.AccentColor = $Family[4]; $this.AccentHover = $Family[4].Toward($Family[3], 0.5); $this.AccentActive = $Family[5]
            $this.SelectionBg = $Family[0]; $this.TextLink = $Family[4]; $this.BorderActive = $Family[4]
        }
        else {
            $this.AccentColor = $Family[2]; $this.AccentHover = $Family[2].Toward($Family[1], 0.2); $this.AccentActive = $Family[3]
            $this.SelectionBg = $Family[4]; $this.TextLink = $Family[1]; $this.BorderActive = $Family[1]
        }
    }

    # The colours by CSS custom property name, as CSS text; case-insensitive keys.
    [Collections.Generic.Dictionary[string,string]] Tokens() {
        $tokens = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
        $tokens['--bg-window'] = $this.BgWindow.CssText()
        $tokens['--bg-titlebar'] = $this.BgTitlebar.CssText()
        $tokens['--bg-menubar'] = $this.BgMenubar.CssText()
        $tokens['--bg-editor'] = $this.BgEditor.CssText()
        $tokens['--bg-tab-active'] = $this.BgTabActive.CssText()
        $tokens['--bg-tab-hover'] = $this.BgTabHover.CssText()
        $tokens['--bg-card'] = $this.BgCard.CssText()
        $tokens['--bg-card-hover'] = $this.BgCardHover.CssText()
        $tokens['--bg-flyout'] = $this.BgFlyout.CssText()
        $tokens['--bg-flyout-item-hover'] = $this.BgFlyoutItemHover.CssText()
        $tokens['--bg-control'] = $this.BgControl.CssText()
        $tokens['--bg-control-hover'] = $this.BgControlHover.CssText()
        $tokens['--bg-control-active'] = $this.BgControlActive.CssText()
        $tokens['--bg-statusbar'] = $this.BgStatusbar.CssText()
        $tokens['--bg-dialog'] = $this.BgDialog.CssText()
        $tokens['--text-primary'] = $this.TextPrimary.CssText()
        $tokens['--text-secondary'] = $this.TextSecondary.CssText()
        $tokens['--text-disabled'] = $this.TextDisabled.CssText()
        $tokens['--text-link'] = $this.TextLink.CssText()
        $tokens['--border-subtle'] = $this.BorderSubtle.CssText()
        $tokens['--border-control'] = $this.BorderControl.CssText()
        $tokens['--border-active'] = $this.BorderActive.CssText()
        $tokens['--accent-color'] = $this.AccentColor.CssText()
        $tokens['--accent-hover'] = $this.AccentHover.CssText()
        $tokens['--accent-active'] = $this.AccentActive.CssText()
        $tokens['--selection-bg'] = $this.SelectionBg.CssText()
        $tokens['--selection-text'] = $this.SelectionText.CssText()
        return $tokens
    }
}

class NotepadSettings {
    [string]$theme
    [string]$fontFamily
    [string]$fontStyle
    [string]$fontSize
    [bool]$wordWrap
    [bool]$formatting
    [string]$openingFiles
    [string]$startupOption
    [bool]$recentFilesEnabled
    [bool]$spellCheck
    [bool]$showStatusBar
    [int]$zoom
    [string]$backdrop
    [string]$cornerStyle
    [bool]$copyAsFile
    [int]$backgroundOpacity
    [bool]$gradientEnabled
    # How strongly the four-corner gradient shows, 0 to 100, on every backdrop.
    [int]$gradientStrength
    [Collections.Generic.Dictionary[string,string]]$colors
    [string[]]$ansiColors
    [string]$windowIcon
    [string]$entranceAnimation

    # A colour table keyed by role, case-insensitively, from any dictionary of role to colour text.
    static [Collections.Generic.Dictionary[string,string]] ColorTable([Collections.IDictionary]$Source) {
        $table = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($role in $Source.Keys) { $table[[string]$role] = [string]$Source[$role] }
        return $table
    }

    [string[]] SettingNames() {
        return [string[]]@('theme','fontFamily','fontStyle','fontSize','wordWrap','formatting','openingFiles','startupOption','recentFilesEnabled','spellCheck','showStatusBar','zoom','backdrop','cornerStyle','copyAsFile','backgroundOpacity','gradientEnabled','gradientStrength','colors','ansiColors','windowIcon','entranceAnimation')
    }

    [object] Get([string]$Name) {
        switch ($Name) {
            'theme' { return $this.theme }
            'fontFamily' { return $this.fontFamily }
            'fontStyle' { return $this.fontStyle }
            'fontSize' { return $this.fontSize }
            'wordWrap' { return $this.wordWrap }
            'formatting' { return $this.formatting }
            'openingFiles' { return $this.openingFiles }
            'startupOption' { return $this.startupOption }
            'recentFilesEnabled' { return $this.recentFilesEnabled }
            'spellCheck' { return $this.spellCheck }
            'showStatusBar' { return $this.showStatusBar }
            'zoom' { return $this.zoom }
            'backdrop' { return $this.backdrop }
            'cornerStyle' { return $this.cornerStyle }
            'copyAsFile' { return $this.copyAsFile }
            'backgroundOpacity' { return $this.backgroundOpacity }
            'gradientEnabled' { return $this.gradientEnabled }
            'gradientStrength' { return $this.gradientStrength }
            'colors' { return $this.colors }
            'ansiColors' { return $this.ansiColors }
            'windowIcon' { return $this.windowIcon }
            'entranceAnimation' { return $this.entranceAnimation }
        }
        throw [ArgumentException]::new("No setting is named '$Name'.")
    }

    [void] Set([string]$Name, [object]$Value) {
        switch ($Name) {
            'theme' { $this.theme = $Value; return }
            'fontFamily' { $this.fontFamily = $Value; return }
            'fontStyle' { $this.fontStyle = $Value; return }
            'fontSize' { $this.fontSize = $Value; return }
            'wordWrap' { $this.wordWrap = $Value; return }
            'formatting' { $this.formatting = $Value; return }
            'openingFiles' { $this.openingFiles = $Value; return }
            'startupOption' { $this.startupOption = $Value; return }
            'recentFilesEnabled' { $this.recentFilesEnabled = $Value; return }
            'spellCheck' { $this.spellCheck = $Value; return }
            'showStatusBar' { $this.showStatusBar = $Value; return }
            'zoom' { $this.zoom = $Value; return }
            'backdrop' { $this.backdrop = $Value; return }
            'cornerStyle' { $this.cornerStyle = $Value; return }
            'copyAsFile' { $this.copyAsFile = $Value; return }
            'backgroundOpacity' { $this.backgroundOpacity = $Value; return }
            'gradientEnabled' { $this.gradientEnabled = $Value; return }
            'gradientStrength' { $this.gradientStrength = $Value; return }
            'colors' { $this.colors = [NotepadSettings]::ColorTable($Value); return }
            'ansiColors' { $this.ansiColors = $Value; return }
            'windowIcon' { $this.windowIcon = $Value; return }
            'entranceAnimation' { $this.entranceAnimation = $Value; return }
        }
        throw [ArgumentException]::new("No setting is named '$Name'.")
    }

    # An independent copy: the colour table and the ANSI colours are copied, not shared.
    [NotepadSettings] Copy() {
        $copy = [NotepadSettings]::new()
        foreach ($name in $this.SettingNames()) {
            $value = $this.Get($name)
            if ($value -is [string[]]) { $value = ([string[]]$value).Clone() }
            $copy.Set($name, $value)
        }
        return $copy
    }

    # The colour roles in the order the Settings page lists them; config.ini writes them in this order.
    static [string[]] ColorRoles() {
        return [string[]]@('foreground','tabs','cursor','selectionBackground','topLeft','topRight','bottomLeft','bottomRight')
    }

    # A setting's value as config.ini writes it: true/false, invariant integers, text as it is.
    static [string] IniText([object]$Value) {
        if ($Value -is [bool]) { return $(if ($Value) { 'true' } else { 'false' }) }
        if ($Value -is [int]) { return ([int]$Value).ToString([Globalization.CultureInfo]::InvariantCulture) }
        return [string]$Value
    }

    # Writes config.ini: every setting, the ones that differ from -Defaults as key=value and the rest commented out
    # as ;key=value, so the file shows every setting while only changes take effect. The colour table and the ANSI
    # colours have sections of their own, entry by entry.
    [void] WriteIni([IO.TextWriter]$Writer, [NotepadSettings]$Defaults) {
        $Writer.WriteLine('; Notepad settings. Lines starting with ; are defaults; remove the ; to change one.')
        $Writer.WriteLine('[Notepad]')
        foreach ($name in $this.SettingNames()) {
            if ($name -in 'colors', 'ansiColors') { continue }
            $value = [NotepadSettings]::IniText($this.Get($name))
            $prefix = if ([string]::Equals($value, [NotepadSettings]::IniText($Defaults.Get($name)), [StringComparison]::Ordinal)) { ';' } else { '' }
            $Writer.WriteLine($prefix + $name + '=' + $value)
        }
        $Writer.WriteLine()
        $Writer.WriteLine('[Colors]')
        # The Settings page's roles in its order, then any other role the table holds (one added by hand), by name.
        $roles = [Collections.Generic.List[string]]::new()
        foreach ($role in [NotepadSettings]::ColorRoles()) { if ($this.colors.ContainsKey($role)) { $roles.Add($role) } }
        $others = [Collections.Generic.List[string]]::new()
        foreach ($role in $this.colors.Keys) { if ($role -notin [NotepadSettings]::ColorRoles()) { $others.Add($role) } }
        $others.Sort([StringComparer]::OrdinalIgnoreCase)
        $roles.AddRange($others)
        foreach ($role in $roles) {
            [string]$default = ''
            $same = $Defaults.colors.TryGetValue($role, [ref]$default) -and [string]::Equals($this.colors[$role], $default, [StringComparison]::Ordinal)
            $Writer.WriteLine($(if ($same) { ';' } else { '' }) + $role + '=' + $this.colors[$role])
        }
        $Writer.WriteLine()
        $Writer.WriteLine('[AnsiColors]')
        for ($i = 0; $i -lt $this.ansiColors.Length; $i++) {
            $same = $i -lt $Defaults.ansiColors.Length -and [string]::Equals($this.ansiColors[$i], $Defaults.ansiColors[$i], [StringComparison]::Ordinal)
            $Writer.WriteLine($(if ($same) { ';' } else { '' }) + $i.ToString([Globalization.CultureInfo]::InvariantCulture) + '=' + $this.ansiColors[$i])
        }
    }

    # Applies config.ini over the current values. Blank lines and lines starting with ; or # are skipped; a section or
    # key this build does not know is skipped. A value is read as its setting's type ([bool]::Parse, an invariant
    # integer, text as it is), and one that does not read as that type throws.
    [void] ReadIni([IO.TextReader]$Reader) {
        $section = ''
        $culture = [Globalization.CultureInfo]::InvariantCulture
        for ($line = $Reader.ReadLine(); $null -ne $line; $line = $Reader.ReadLine()) {
            $line = $line.Trim()
            if ($line.Length -eq 0 -or $line.StartsWith(';') -or $line.StartsWith('#')) { continue }
            if ($line.StartsWith('[') -and $line.EndsWith(']')) { $section = $line.Substring(1, $line.Length - 2).Trim(); continue }
            $equals = $line.IndexOf('=')
            if ($equals -le 0) { continue }
            $key = $line.Substring(0, $equals).Trim()
            $value = $line.Substring($equals + 1).Trim()
            if ($section -eq 'Colors') { $this.colors[$key] = $value; continue }
            if ($section -eq 'AnsiColors') {
                $index = [int]::Parse($key, [Globalization.NumberStyles]::None, $culture)
                if ($index -lt $this.ansiColors.Length) { $this.ansiColors[$index] = $value }
                continue
            }
            if ($section -ne 'Notepad' -or $key -notin $this.SettingNames() -or $key -in 'colors', 'ansiColors') { continue }
            $current = $this.Get($key)
            if ($current -is [bool]) { $this.Set($key, [bool]::Parse($value)) }
            elseif ($current -is [int]) { $this.Set($key, [int]::Parse($value, [Globalization.NumberStyles]::AllowLeadingSign, $culture)) }
            else { $this.Set($key, $value) }
        }
    }
}
# Notepad's icons, typed geometry built once.
[Collections.Generic.Dictionary[string,NotepadIcon]]$icons=[NotepadIcons]::All()
[NotepadSettings]$settings=[NotepadSettings]::new()
$settings.theme='dark';$settings.fontFamily='Consolas';$settings.fontStyle='Regular';$settings.fontSize='11';$settings.wordWrap=$true;$settings.formatting=$true
$settings.openingFiles='newTab';$settings.startupOption='continueSession';$settings.recentFilesEnabled=$false;$settings.spellCheck=$true;$settings.showStatusBar=$true;$settings.zoom=100
$settings.backdrop='solid';$settings.entranceAnimation='fade';$settings.cornerStyle='curved';$settings.copyAsFile=$false
$settings.backgroundOpacity=85;$settings.gradientEnabled=$false;$settings.gradientStrength=30
$settings.colors=[NotepadSettings]::ColorTable(@{foreground='';tabs='';cursor='';selectionBackground='';topLeft='#272727';topRight='#272727';bottomLeft='#272727';bottomRight='#272727'})
$settings.ansiColors=@('#0C0C0C','#C50F1F','#13A10E','#C19C00','#0037DA','#881798','#3A96DD','#CCCCCC','#767676','#E74856','#16C60C','#F9F1A5','#3B78FF','#B4009E','#61D6D6','#F2F2F2')
$settings.windowIcon='default'
$store=[IO.Path]::Join([Environment]::GetFolderPath('LocalApplicationData'),'NotepadPS1')
# Settings live in config.ini beside the program; the open tabs in session.bin in the user's application data.
[NotepadSettings]$defaultSettings=$settings.Copy()
[string]$configPath=[IO.Path]::Join($PSScriptRoot,'config.ini')
$sessionPath=[IO.Path]::Join($store,'session.bin')
# Where the window was left, beside the session.
$placementPath=[IO.Path]::Join($store,'window.bin')
[NotepadPlacement]$placement=$null
if(-not $NoSession -and [IO.Path]::Exists($placementPath)){
    try{$placementReader=[IO.BinaryReader]::new([IO.File]::OpenRead($placementPath));try{$placement=[NotepadPlacement]::Read($placementReader)}finally{$placementReader.Dispose()}}catch{}
}
if(-not $NoSession -and [IO.Path]::Exists($configPath)){
    try{$configReader=[IO.StreamReader]::new($configPath);try{$settings.ReadIni($configReader)}finally{$configReader.Dispose()}}catch{}
}
if($Backdrop){$settings.backdrop=$Backdrop};if($CornerStyle){$settings.cornerStyle=$CornerStyle}
[NotepadModel]$model=Invoke-Model -Settings $settings
[NotepadModelState]$state=$model.State()
if(-not $NoSession -and $settings.startupOption -eq 'continueSession' -and [IO.Path]::Exists($sessionPath)){
    try{$sessionReader=[IO.BinaryReader]::new([IO.File]::OpenRead($sessionPath));try{$model.ReadSession($sessionReader)}finally{$sessionReader.Dispose()}}catch{}
}
if(-not $state.Tabs.Count){$null=$model.NewTab()}
if($Path){$null=$model.Open($Path);if($state.Tabs[0].Document.Length -eq 0 -and $state.Tabs.Count -eq 2){$model.CloseTab($state.Tabs[0].Id)}}
[NotepadWindow]$window=$null;[NotepadGraphics]$graphics=$null
# A choice in a dropdown: the text shown and the setting value it stands for.
class NotepadOption {
    [string]$Text
    [string]$Value
}
# A choice made in a dropdown: the setting it is for and the value chosen.
class NotepadSettingChoice {
    [string]$Key
    [string]$Value
}
# An open dropdown: the setting it chooses, its choices, and the control it hangs from.
class NotepadDropdown {
    [string]$Key
    [NotepadOption[]]$Options
    [double[]]$Rect
    [string]$Id
}
# A modal dialog button: the command it runs and that command's data (a tab id, or none).
class NotepadModalButton {
    [string]$Text
    [FluentAction]$Action
    [Nullable[int]]$Data
    [bool]$Primary
}
# A modal dialog. Markdown is $null unless the dialog previews a document.
class NotepadModal {
    [string]$Title
    [string]$Message
    [NotepadModalButton[]]$Buttons
    [bool]$Input
    [string]$Value
    [string]$Markdown
}
# The canvas color picker: the color in HSV and RGB, the text in its inputs, and where it is drawn.
class NotepadColorPicker {
    [string]$Role
    [int]$Ansi
    [double]$H
    [double]$S
    [double]$V
    [string]$Hex
    [int]$R
    [int]$G
    [int]$B
    [string]$Mode
    [Collections.Generic.Dictionary[string,string]]$Inputs
    [double[]]$Anchor
    [double]$Scroll
    [string]$Invalid
    [DateTime]$OpenedUtc
    [double[]]$PanelRect
    [double[]]$SpectrumRect
    [double[]]$ValueRect
    [double[]]$ModeRect
    [double]$VisibleHeight
}
# A hit-test node: a rectangle drawn this frame, the command it runs and that command's data, the cursor over it, the
# frame that drew it, and the clip it was drawn under ($null when unclipped).
class NotepadHitNode {
    [string]$Id
    [double[]]$Rect
    [FluentAction]$Action
    [object]$Data
    [string]$Cursor
    [int]$Generation
    [double[]]$Clip
    # A shallow copy: the copy shares Rect, Clip and Data with this node.
    [NotepadHitNode] Copy() {
        return [NotepadHitNode]@{Id=$this.Id;Rect=$this.Rect;Action=$this.Action;Data=$this.Data;Cursor=$this.Cursor;Generation=$this.Generation;Clip=$this.Clip}
    }
}
# An icon the window can show: a Windows system icon (standard, LoadIconW) or shell stock icon (stock), and its key.
class NotepadIconChoice {
    [string]$Key
    [string]$Kind
    [int]$Id
    NotepadIconChoice([string]$Kind, [int]$Id) { $this.Kind = $Kind; $this.Id = $Id; $this.Key = $Kind + ':' + $Id }
}
# A menu row: a command (Action, with its Data) shown as Text with its Shortcut; or a separator; or a submenu, which
# Submenu names and Rows fills. Checked is $null on a row that shows no check mark.
class NotepadMenuRow {
    [string]$Text
    [FluentAction]$Action
    [object]$Data
    [string]$Shortcut
    [string]$Submenu
    [NotepadMenuRow[]]$Rows
    [Nullable[bool]]$Checked
    [bool]$Disabled
    [bool]$Separator
}
# A card on the Settings page: a section heading, or a setting shown with a toggle, a choice, a button, the opacity
# slider or an accordion that opens more below it.
class NotepadSettingCard {
    [string]$Section
    [string]$Title
    [string]$Subtitle
    [string]$Icon
    [string]$Key
    [bool]$Toggle
    [NotepadOption[]]$Select
    [double]$SelectWidth
    [string]$Accordion
    [FluentAction]$Button
    [string]$ButtonText
    [bool]$Slider
}
# A font setting's row in the Font accordion: its label, the setting, the choices and the dropdown's width.
class NotepadFontRow {
    [string]$Label
    [string]$Key
    [string[]]$Options
    [double]$Width
}
# A status-bar item: its hit-test id, text, width and the command it runs ('none' for none).
class NotepadStatusItem {
    [string]$Id
    [string]$Text
    [double]$Width
    [FluentAction]$Action
}
# A button on the find bar: its hit region's id, its icon and the action it asks for.
class NotepadFindButton {
    [string]$Id
    [string]$Icon
    [FluentAction]$Action
}
# A menu-bar button: the menu it opens, its text and width.
class NotepadMenuEntry {
    [string]$Name
    [string]$Text
    [double]$Width
}
# One line of the document as the editor's gate drew it this frame: its line number, where it starts in the text,
# its length without the line break, its top in window coordinates, its laid-out height and its text layout.
class NotepadGateLine {
    [int]$Line
    [int]$Start
    [int]$Length
    [double]$Top
    [double]$Height
    [IntPtr]$Layout
}

# The interface state. A value-type member that starts unset is Nullable: it reads $null until first set.
class NotepadUi {
    [bool]$Dirty
    [bool]$Running
    [string]$Hover
    [string]$Pressed
    [string]$Focus
    [string]$Menu
    [string]$Submenu
    [bool]$Settings
    [Collections.Generic.HashSet[string]]$Expanded
    [double]$SettingsScroll
    [bool]$Find
    [bool]$Replace
    [NotepadModal]$Modal
    [NotepadDropdown]$Dropdown
    [bool]$Drag
    [bool]$Blink
    [datetime]$LastBlink
    [datetime]$LastSession
    [double]$Width
    [double]$Height
    [double]$Dpi
    [int]$Generation
    [Collections.Generic.Dictionary[string,NotepadHitNode]]$Nodes
    [Collections.Generic.List[NotepadHitNode]]$Hits
    [Collections.Generic.List[NotepadHitNode]]$NextHits
    [Collections.Generic.Dictionary[string,IntPtr]]$TextCache
    [IntPtr]$EditorLayout
    [string]$EditorKey
    [double[]]$EditorOrigin
    [double[]]$EditorRect
    [NotepadTextMetrics]$EditorMetrics
    [bool]$EnsureCaret
    [int]$InputAnchor
    [int]$InputFocus
    [hashtable]$InputBuffers
    [string]$PendingHigh
    [bool]$Focused
    [Nullable[int]]$ClickSequence
    [Nullable[int]]$ScrollSequence
    [string]$EntranceStatus
    [Collections.Generic.List[NotepadEntranceSample]]$EntranceSamples
    [Nullable[datetime]]$HoverSince
    [Nullable[bool]]$TooltipShown
    [Nullable[bool]]$Minimized
    [Nullable[bool]]$SliderDrag
    # The settings slider being dragged or focused (its setting's key), and each slider's track as last painted.
    [string]$SliderKey = 'backgroundOpacity'
    [Collections.Generic.Dictionary[string,double[]]]$SliderTracks
    # The editor scrollbar while it is dragged: the pointer's offset into the thumb, and the track as last painted
    # (top, length, thumb length, largest scroll offset), empty when there is no scrollbar.
    [bool]$ScrollDrag
    [double]$ScrollGrab
    [double[]]$ScrollTrack
    # The editor's gate: where each line of the active text starts (rebuilt when LineStartsKey changes), each
    # line's layout keyed by its format and text with the keys used this frame, and the lines the last frame drew.
    [string]$LineStartsKey
    [int[]]$LineStarts
    [Collections.Generic.Dictionary[string,IntPtr]]$LineLayouts
    [Collections.Generic.HashSet[string]]$LineLayoutsUsed
    [Collections.Generic.List[NotepadGateLine]]$GateLines
    # A selection drag: the pointer's last position and the time of the last kinetic scroll step.
    [double]$DragX
    [double]$DragY
    [datetime]$DragTick
    # Windows' text size as a factor on interface text (not the editor's own font), read at start and when Windows
    # reports a setting change.
    [double]$TextScale = 1.0
    [NotepadColorPicker]$ColorPicker
    [string]$ColorDrag
    [string]$Theme
    [NotepadAppearance]$Appearance
    [string]$AppearanceError
    # Why config.ini could not be written, shown on the Settings page; '' when it was.
    [string]$PersistError
    [NotepadEntrance]$Entrance
    [NotepadEntranceRestore]$EntranceRestore
    [Nullable[bool]]$BackdropActive
    [NotepadIconChoice[]]$IconCatalog
    [Nullable[IntPtr]]$WindowIconHandle
    [double[]]$OpacityTrack
    [double[]]$HitClip
    [Nullable[int]]$SettingsExtent
    [Nullable[datetime]]$EntranceStart
}
[NotepadUi]$ui=@{Dirty=$true;Running=$true;Hover='';Pressed='';Focus='editor-area';Menu='';Submenu='';Settings=$false;Expanded=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase);SettingsScroll=0.0;Find=$false;Replace=$false;Modal=$null;Dropdown=$null;Drag=$false;Blink=$true;LastBlink=[DateTime]::UtcNow;LastSession=[DateTime]::UtcNow;Width=0.0;Height=0.0;Dpi=96.0;Generation=0;Nodes=[Collections.Generic.Dictionary[string,NotepadHitNode]]::new([StringComparer]::Ordinal);Hits=[Collections.Generic.List[NotepadHitNode]]::new();NextHits=$null;TextCache=[Collections.Generic.Dictionary[string,IntPtr]]::new([StringComparer]::OrdinalIgnoreCase);EditorLayout=[IntPtr]::Zero;EditorKey='';EditorOrigin=@(16.0,92.0);EditorRect=@(0,78,1280,614);EnsureCaret=$true;InputAnchor=0;InputFocus=0;InputBuffers=@{};PendingHigh='';Focused=$true}
# The theme's colours by CSS custom property, as the design's declarations give them (all text); case-insensitive keys,
# as the hashtable's were. A property the theme does not declare reads $null.
[Collections.Generic.Dictionary[string,string]]$palette=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
$ui.ClickSequence=0
$ui.ScrollSequence=0
$ui.EntranceStatus='Pending';$ui.EntranceSamples=[Collections.Generic.List[NotepadEntranceSample]]::new()
$ui.HoverSince=[DateTime]::UtcNow;$ui.TooltipShown=$false
$ui.Minimized=$false
$ui.SliderDrag=$false
$ui.ColorPicker=$null;$ui.ColorDrag=''
if($StartPage -ne 'editor'){$ui.Settings=$true;$ui.Focus='settings'}
function Write-ApplicationDiagnostic {
    if(-not $DiagnosticPath){return}
    $snapshot=@{Generation=$ui.Generation;ClickSequence=$ui.ClickSequence;Width=$ui.Width;Height=$ui.Height;Dpi=$ui.Dpi;Theme=$ui.Theme;Focus=$ui.Focus;Settings=$settings;SettingsOpen=$ui.Settings;Appearance=$ui.Appearance;AppearanceError=$ui.AppearanceError;EditorMetrics=$ui.EditorMetrics;Status=$model.Status();Nodes=@($ui.Hits|ForEach-Object{@{Id=$_.Id;Rect=$_.Rect;Action=$_.Action;Data=$_.Data;Generation=$_.Generation}});Session=$model.ExportSession()}
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
    if($theme -eq 'system'){$theme=if([NotepadWindow]::AppsUseLightTheme()){'light'}else{'dark'}}
    [bool]$lightTheme=$theme -eq 'light'
    [FluentTheme]$themeColors=if($lightTheme){[FluentTheme]::Light()}elseif($theme -eq 'dark'){[FluentTheme]::Dark()}else{[FluentTheme]::new()}
    $themeColors.UseAccent([NotepadWindow]::AccentPalette(),$lightTheme)
    $script:palette=$themeColors.Tokens()
    $ui.Theme=$theme;$ui.Dirty=$true
}
function Apply-WindowAppearance {
    if(-not $window -or -not $graphics){return}
    try{
        $ui.Appearance=$window.Appearance($settings.backdrop,($ui.Theme -eq 'dark'),($settings.cornerStyle -eq 'curved'))
        # A solid window has no material behind it, so everything is painted opaque.
        $ui.BackdropActive=$settings.backdrop -ne 'solid';$ui.AppearanceError=''
    }catch{$ui.BackdropActive=$false;$ui.AppearanceError=$_.Exception.Message}
    $graphics.CornerStyle(($settings.cornerStyle -eq 'curved'));Invalidate
}
function Initialize-IconCatalog {
    if($ui.IconCatalog){return}
    # Windows' seven documented system icons (LoadIconW), then its shell stock icons SIID 0 to 180, in that order: the
    # catalog the comparison tooling recorded for this machine, built here instead of read from its evidence.
    $choices=[Collections.Generic.List[NotepadIconChoice]]::new()
    foreach($id in [int[]]@(32512,32516,32515,32513,32514,32517,32518)){$choices.Add([NotepadIconChoice]::new('standard',$id))}
    for($id=0;$id -le 180;$id++){$choices.Add([NotepadIconChoice]::new('stock',$id))}
    $ui.IconCatalog=$choices.ToArray()
}
function Apply-WindowIcon {
    if(-not $window -or -not $graphics){return}
    $ui.WindowIconHandle=[IntPtr]::Zero
    # The default is the program's own embedded icon; a program without one (run under pwsh) gets Windows' application icon.
    if($settings.windowIcon -eq 'default'){try{$ui.WindowIconHandle=$window.SelectIcon('application',1)}catch{$null=$window.SelectIcon('standard',32512)};return}
    Initialize-IconCatalog
    [NotepadIconChoice]$entry=$null;foreach($choice in $ui.IconCatalog){if($choice.Key -eq $settings.windowIcon){$entry=$choice;break}}
    if($entry){$ui.WindowIconHandle=$window.SelectIcon($entry.Kind,$entry.Id)}
    else{$settings.windowIcon='default';$null=$window.SelectIcon('standard',32512)}
}
function Paint-AppIcon([string]$Id,[double]$X,[double]$Y,[double]$Size){
    if($ui.WindowIconHandle -and $ui.WindowIconHandle -ne [IntPtr]::Zero){$graphics.NativeIcon([IntPtr]$ui.WindowIconHandle,$settings.windowIcon,$X,$Y,$Size)}else{Icon 'app' $X $Y $Size}
    Node $Id ($X-5) ($Y-5) ($Size+10) ($Size+10) ([FluentAction]::CycleIcon) $settings.windowIcon
}
function Color([string]$Name){$palette['--'+$Name]}
function Role-Color([string]$Role){
    if($settings.colors[$Role]){return $settings.colors[$Role]}
    switch($Role){'foreground'{Color 'text-primary'};'tabs'{Color 'bg-tab-active'};'cursor'{Color 'text-primary'};'selectionBackground'{Color 'selection-bg'};default{'#272727'}}
}
function Surface-Color([string]$Name,[double]$Opacity=-1){return Surface-Hex (Color $Name) $Opacity}

# A #RRGGBB colour as a surface over the window's material: opaque on a solid window; with a backdrop, at the given
# opacity, or the background opacity setting when none is given.
function Surface-Hex([string]$Color,[double]$Opacity=-1){
    if(-not $ui.BackdropActive){return $Color}
    if($Opacity -lt 0){$Opacity=[int]$settings.backgroundOpacity/100.0}
    $hex=$Color.TrimStart('#');if($hex.Length -ne 6){return $Color}
    $alpha=[Math]::Clamp($Opacity,0.0,1.0).ToString('0.###',[Globalization.CultureInfo]::InvariantCulture)
    'rgba('+[Convert]::ToInt32($hex.Substring(0,2),16)+','+[Convert]::ToInt32($hex.Substring(2,2),16)+','+[Convert]::ToInt32($hex.Substring(4,2),16)+','+$alpha+')'
}
function Set-ScrollFromPoint([double]$Y){
    if(-not $ui.ScrollTrack){return}
    $scrollTrack=$ui.ScrollTrack;$tab=$model.Active()
    $tab.ScrollY=[Math]::Clamp(($Y-$ui.ScrollGrab-$scrollTrack[0])/[Math]::Max(1,$scrollTrack[1]-$scrollTrack[2])*$scrollTrack[3],0,$scrollTrack[3]);$ui.EnsureCaret=$false
    Invalidate
}
# Sets the slider's setting ($ui.SliderKey) from a point on its track as last painted.
function Set-SliderFromPoint([double]$X){
    if($null -eq $ui.SliderTracks -or -not $ui.SliderTracks.ContainsKey($ui.SliderKey)){return}
    $track=$ui.SliderTracks[$ui.SliderKey]
    $settings.Set($ui.SliderKey,[int][Math]::Clamp([Math]::Round(($X-$track[0])/$track[2]*100),0,100))
    Invalidate
}
# The window icon -Step places along the icon catalog (1 forward, -1 back), wrapping at either end; an icon not in the
# catalog steps to its first or last entry. Saved at once.
function Step-WindowIcon([int]$Step){
    Initialize-IconCatalog;$count=$ui.IconCatalog.Count;$index=-1
    for($i=0;$i -lt $count;$i++){if($ui.IconCatalog[$i].Key -eq $settings.windowIcon){$index=$i;break}}
    $next=if($index -lt 0){if($Step -gt 0){0}else{$count-1}}else{(($index+$Step)%$count+$count)%$count}
    $settings.windowIcon=$ui.IconCatalog[$next].Key;Apply-WindowIcon;Persist;Invalidate
}
function Persist {
    if($NoSession){return}
    if($window -and $window.Info().Alive){
        $null=[IO.Directory]::CreateDirectory($store)
        $temporary=$placementPath+'.tmp'
        $placementWriter=[IO.BinaryWriter]::new([IO.File]::Create($temporary))
        try{$window.Placement().Write($placementWriter)}finally{$placementWriter.Dispose()}
        [IO.File]::Move($temporary,$placementPath,$true)
    }
    # Each file is written beside its destination and moved over it, so a reader never sees half a file.
    $temporary=$configPath+'.tmp'
    try{
        $configWriter=[IO.StreamWriter]::new($temporary,$false,[Text.UTF8Encoding]::new($false))
        try{$settings.WriteIni($configWriter,$defaultSettings)}finally{$configWriter.Dispose()}
        [IO.File]::Move($temporary,$configPath,$true)
        $ui.PersistError=''
    }catch [UnauthorizedAccessException] {$ui.PersistError='config.ini cannot be written beside the program: '+$_.Exception.Message;$ui.Dirty=$true}
    $null=[IO.Directory]::CreateDirectory($store)
    $temporary=$sessionPath+'.tmp'
    $sessionWriter=[IO.BinaryWriter]::new([IO.File]::Create($temporary))
    try{$model.WriteSession($sessionWriter,($settings.startupOption -eq 'continueSession'))}finally{$sessionWriter.Dispose()}
    [IO.File]::Move($temporary,$sessionPath,$true)
}
function Invalidate([bool]$Caret=$false){$ui.Dirty=$true;if($Caret){$ui.EnsureCaret=$true;$ui.Blink=$true;$ui.LastBlink=[DateTime]::UtcNow}}
function Node([string]$Id,[double]$X,[double]$Y,[double]$W,[double]$H,[FluentAction]$Action,[object]$Data=$null,[string]$Cursor='pointer'){
    if(-not $ui.Nodes.ContainsKey($Id)){$ui.Nodes[$Id]=[NotepadHitNode]@{Id=$Id}}
    $node=$ui.Nodes[$Id];$node.Rect=@($X,$Y,$W,$H);$node.Action=$Action;$node.Data=$Data;$node.Cursor=$Cursor;$node.Generation=$ui.Generation+1;$node.Clip=$ui.HitClip
    $ui.NextHits.Add($node.Copy())
}
# The width a label's text takes at a base size, scaled by Windows' text size as Label scales it.
function Measure-LabelWidth([string]$Text,[double]$Size=13){
    $scaled=$Size*$ui.TextScale;$key="measure|$Text|$scaled"
    if(-not $ui.TextCache.ContainsKey($key)){$ui.TextCache[$key]=$graphics.Layout($Text,'Segoe UI',[single]$scaled,[single]1000,$false,400,$false,0)}
    return [double]$graphics.Metrics($ui.TextCache[$key]).Width
}

function Label([string]$Text,[double]$X,[double]$Y,[double]$W,[string]$Color,[double]$Size=13,[string]$Family='Segoe UI',[int]$Weight=400){
    # Interface text follows Windows' text size, as WinUI's does. Text grown by the setting moves up by half its added
    # line height (about 1.33 of the size), so it stays centred on the place laid out for the base size.
    $grown=$Size*($ui.TextScale-1);$Size=$Size+$grown;$Y=$Y-$grown*0.665
    $key="$Text|$W|$Size|$Family|$Weight"
    if(-not $ui.TextCache.ContainsKey($key)){$ui.TextCache[$key]=$graphics.Layout($Text,$Family,[single]$Size,[single][Math]::Max(1,$W),$false,$Weight,$false,0)}
    $graphics.DrawLayout($ui.TextCache[$key],[single]$X,[single]$Y,$Color)
}
function Icon([string]$Name,[double]$X,[double]$Y,[double]$Size,[string]$Fill='',[double]$Rotation=0){if(-not $Fill){$Fill=Color 'text-primary'};$graphics.Icon($icons[$Name],[single]$X,[single]$Y,[single]$Size,$Fill,$Rotation)}
function Button([string]$Id,[double]$X,[double]$Y,[double]$W,[double]$H,[FluentAction]$Action,[string]$Text='',[string]$Icon='',[object]$Data=$null,[bool]$Primary=$false,[bool]$Border=$false,[double]$IconSize=16){
    Node $Id $X $Y $W $H $Action $Data
    $hover=$ui.Hover -eq $Id;$pressed=$ui.Pressed -eq $Id
    $bg=if($Primary){Color $(if($hover){'accent-hover'}else{'accent-color'})}elseif($pressed){Color 'bg-control-active'}elseif($hover){Color 'bg-control-hover'}elseif($Border){Surface-Color 'bg-control' 0.18}else{'transparent'}
    $fg=Color 'text-primary'
    if($Id -in @('btn-win-close','settings-win-close') -and $hover){$bg='#c42b1c';$fg='#ffffff'}
    if($Primary){$fg='#ffffff'}
    if($bg -ne 'transparent'){$graphics.Fill($X,$Y,$W,$H,$bg,4)}
    if($Border -and -not $Primary){$graphics.Stroke($X,$Y,$W,$H,(Color 'border-control'),4,1)}
    if($Icon){Icon $Icon ($X+($W-$IconSize)/2) ($Y+($H-$IconSize)/2) $IconSize $fg}
    if($Text){$layout=$graphics.Layout($Text,'Segoe UI',(13*$ui.TextScale),$W,$false,400,$false,0);try{$m=$graphics.Metrics($layout);$graphics.DrawLayout($layout,($X+($W-$m.Width)/2),($Y+($H-$m.Height)/2),$fg)}finally{$graphics.ReleaseLayout($layout)}}
}
function InputBox([string]$Id,[string]$Value,[double]$X,[double]$Y,[double]$W,[string]$Placeholder='',[double]$H=30,[double]$FontSize=13){
    Node $Id $X $Y $W $H ([FluentAction]::FocusInput) $Id 'text'
    $graphics.Fill($X,$Y,$W,$H,(Surface-Color 'bg-window' 0.25),4);$graphics.Stroke($X,$Y,$W,$H,(Color 'border-control'),4,1)
    $focused=$ui.Focus -eq $Id
    if($focused){$graphics.Fill(($X+1),($Y+$H-2),($W-2),2,(Color 'accent-color'),0)}
    $graphics.Clip(($X+7),($Y+2),($W-14),($H-4))
    $layout=$graphics.Layout($Value,'Segoe UI',($FontSize*$ui.TextScale),100000,$false,400,$false,0)
    try{
        $metrics=$graphics.Metrics($layout);$originY=$Y+($H-$metrics.Height)/2
        $offset=0.0
        if($focused){
            $focus=[Math]::Clamp([int]$ui.InputFocus,0,$Value.Length);$anchor=[Math]::Clamp([int]$ui.InputAnchor,0,$Value.Length)
            $caret=$graphics.Caret($layout,$focus,$false);$offset=[Math]::Max(0,$caret.X-($W-22))
            foreach($rect in [NotepadRect[]]@($graphics.Selection($layout,[Math]::Min($focus,$anchor),[Math]::Abs($focus-$anchor)))){$graphics.Fill(($X+8+$rect.X-$offset),($originY+$rect.Y),$rect.Width,$rect.Height,(Color 'selection-bg'),0)}
            if($ui.Blink){$graphics.Fill(($X+8+$caret.X-$offset),($originY+$caret.Y),1,$caret.Height,(Color 'text-primary'),0)}
        }
        if($Value){$graphics.DrawLayout($layout,($X+8-$offset),$originY,(Color 'text-primary'))}else{Label $Placeholder ($X+8) $originY ($W-16) (Color 'text-secondary') 13}
    }finally{$graphics.ReleaseLayout($layout);$graphics.Unclip()}
}
function Open-Modal([string]$Title,[string]$Message,[NotepadModalButton[]]$Buttons,[bool]$HasInput=$false,[string]$Value=''){
    $ui.ColorPicker=$null
    $ui.Menu='';$ui.Dropdown=$null;$ui.Modal=[NotepadModal]@{Title=$Title;Message=$Message;Buttons=$Buttons;Input=$HasInput;Value=$Value}
    if($HasInput){$ui.Focus='dialog-input';$ui.InputAnchor=0;$ui.InputFocus=$Value.Length}else{$ui.Focus='modal'}
    Invalidate
}
function Save-Document([NotepadTab]$Tab,[bool]$SaveAs=$false){
    try{
        $destination=$Tab.Path
        if($SaveAs -or -not $destination){$suggested=$Tab.Title;if(-not [IO.Path]::GetExtension($suggested)){$suggested+='.txt'};$destination=[Win32FileDialog]::Choose($window.Handle(),$true,$suggested)}
        if(-not $destination){return $false}
        $null=$model.Save($Tab.Id,$destination);Persist;Invalidate;return $true
    }catch{Open-Modal 'Notepad' $_.Exception.Message @(@{Text='Close';Action=[FluentAction]::Dismiss;Primary=$true});return $false}
}
function Test-AnyModified{foreach($candidate in $state.Tabs){if($candidate.Modified){return $true}};return $false}
function Request-Close([int]$TabId=0){
    if($TabId){[NotepadTab]$tab=$null;foreach($candidate in $state.Tabs){if($candidate.Id -eq $TabId){$tab=$candidate;break}};if(-not $tab.Modified){$model.CloseTab($TabId);Invalidate $true;return};Open-Modal 'Notepad' "Do you want to save changes to $($tab.Caption())?" @(@{Text='Save';Action=[FluentAction]::SaveCloseTab;Data=$TabId;Primary=$true},@{Text="Don't Save";Action=[FluentAction]::DiscardTab;Data=$TabId},@{Text='Cancel';Action=[FluentAction]::Dismiss})}
    elseif(Test-AnyModified){Open-Modal 'Notepad' 'You have unsaved changes. Do you want to save before closing?' @(@{Text='Save All';Action=[FluentAction]::SaveCloseWindow;Primary=$true},@{Text="Don't Save";Action=[FluentAction]::DiscardWindow},@{Text='Cancel';Action=[FluentAction]::Dismiss})}
    else{$ui.Running=$false}
}
function Command([FluentAction]$Action,[object]$Data=$null){
    $tab=$model.Active()
    switch($Action){
        ([FluentAction]::NewTab){$null=$model.NewTab();$ui.Focus='editor-area'}
        ([FluentAction]::NewMarkdownTab){$null=$model.NewTab('Untitled.md',"# Markdown Document`n`nWrite here...",$null,$true);$ui.Focus='editor-area'}
        ([FluentAction]::NewActivity){[NotepadWindow]::StartActivity()}
        ([FluentAction]::SwitchTab){$model.SwitchTab([int]$Data);$ui.Focus='editor-area'}
        ([FluentAction]::CloseTab){Request-Close $tab.Id}
        ([FluentAction]::CloseSpecific){Request-Close ([int]$Data)}
        ([FluentAction]::CloseWindow){Request-Close}
        ([FluentAction]::Exit){Request-Close}
        ([FluentAction]::Save){$null=Save-Document $tab}
        ([FluentAction]::SaveAs){$null=Save-Document $tab $true}
        ([FluentAction]::SaveAll){foreach($document in $state.Tabs){if($document.Modified -and -not (Save-Document $document)){break}}}
        ([FluentAction]::OpenFile){try{$file=[Win32FileDialog]::Choose($window.Handle(),$false,'');if($file){$null=$model.Open($file);$ui.Focus='editor-area'}}catch{Open-Modal 'Open file' $_.Exception.Message @(@{Text='Close';Action=[FluentAction]::Dismiss;Primary=$true})}}
        ([FluentAction]::Undo){$model.Undo($false)}
        ([FluentAction]::Redo){$model.Undo($true)}
        ([FluentAction]::SelectAll){$model.Select(0,$tab.Document.Length)}
        ([FluentAction]::Copy){$start=[Math]::Min($tab.Anchor,$tab.Focus);$length=[Math]::Abs($tab.Focus-$tab.Anchor);if($length){[Win32Clipboard]::WriteText($window.Handle(),$tab.Slice($start,$length))}}
        ([FluentAction]::CopyDocument){try{if($settings.copyAsFile){[Win32Clipboard]::WriteFile($window.Handle(),$tab.Content(),$tab.Title)}else{[Win32Clipboard]::WriteText($window.Handle(),$tab.Content())}}catch{Open-Modal 'Copy document' $_.Exception.Message @(@{Text='Close';Action=[FluentAction]::Dismiss;Primary=$true})}}
        ([FluentAction]::EditColor){Open-CanvasColorPicker $Data -1}
        ([FluentAction]::EditAnsi){Open-CanvasColorPicker '' ([int]$Data)}
        ([FluentAction]::CycleIcon){Step-WindowIcon 1}
        ([FluentAction]::ResetIcon){$settings.windowIcon='default';Apply-WindowIcon}
        ([FluentAction]::ResetColors){$settings.colors=[NotepadSettings]::ColorTable(@{foreground='';tabs='';cursor='';selectionBackground='';topLeft='#272727';topRight='#272727';bottomLeft='#272727';bottomRight='#272727'});$settings.gradientEnabled=$false}
        ([FluentAction]::FormatBold){Format-Selection '**'}
        ([FluentAction]::FormatItalic){Format-Selection '_'}
        ([FluentAction]::FormatStrike){Format-Selection '~~'}
        ([FluentAction]::FormatHeading){Format-Lines ([string]$Data)}
        ([FluentAction]::FormatList){Format-Lines ([string]$Data)}
        ([FluentAction]::FormatLink){Open-Modal 'Insert link' 'Address:' @(@{Text='Insert';Action=[FluentAction]::InsertLink;Primary=$true},@{Text='Cancel';Action=[FluentAction]::Dismiss}) $true 'https://'}
        ([FluentAction]::InsertLink){$start=[Math]::Min($tab.Anchor,$tab.Focus);$length=[Math]::Abs($tab.Focus-$tab.Anchor);$text=if($length){$tab.Slice($start,$length)}else{'link text'};$model.Insert(('['+$text+']('+[string]$Data+')'),$false);$tab.Markdown=$true;$ui.Focus='editor-area'}
        ([FluentAction]::Cut){$start=[Math]::Min($tab.Anchor,$tab.Focus);$length=[Math]::Abs($tab.Focus-$tab.Anchor);if($length){[Win32Clipboard]::WriteText($window.Handle(),$tab.Slice($start,$length));$model.Insert('',$false)}}
        ([FluentAction]::Paste){$model.Insert([Win32Clipboard]::ReadText($window.Handle()),$false)}
        ([FluentAction]::Delete){$model.Delete($false)}
        ([FluentAction]::TimeDate){$now=[DateTime]::Now;$model.Insert(($now.ToString('t')+' '+$now.ToString('M/d/yyyy',[Globalization.CultureInfo]::InvariantCulture)),$false)}
        ([FluentAction]::Find) {Open-Find $false}
        ([FluentAction]::Replace){Open-Find $true}
        ([FluentAction]::CloseFind){$ui.Find=$false;$state.Find.Open=$false;$ui.Focus='editor-area'}
        ([FluentAction]::FindNext){$model.SelectMatch(1)}
        ([FluentAction]::FindPrevious){$model.SelectMatch(-1)}
        ([FluentAction]::FindCase){$state.Find.MatchCase=-not $state.Find.MatchCase;$model.Find();$model.SelectMatch(0)}
        ([FluentAction]::FindWrap){$state.Find.Wrap=-not $state.Find.Wrap}
        ([FluentAction]::ToggleReplace){$ui.Replace=-not $ui.Replace;if($ui.Replace){Focus-Input 'replace-query-input'}}
        ([FluentAction]::DoReplace){$model.Replace($false)}
        ([FluentAction]::DoReplaceAll){$model.Replace($true)}
        ([FluentAction]::GoTo){$s=$model.Status();Open-Modal 'Go to line' 'Line number:' @(@{Text='Go to';Action=[FluentAction]::GotoConfirm;Primary=$true},@{Text='Cancel';Action=[FluentAction]::Dismiss}) $true ([string]$s.Line)}
        ([FluentAction]::GotoConfirm){$line=0;if([int]::TryParse([string]$Data,[ref]$line) -and $line -gt 0){$pos=$tab.Document.LineStart([Math]::Min($line-1,$tab.Document.LineCount()-1));$model.Select($pos,$pos)};$ui.Focus='editor-area'}
        ([FluentAction]::ZoomIn){$settings.zoom=[Math]::Min(500,[int]$settings.zoom+10)}
        ([FluentAction]::ZoomOut){$settings.zoom=[Math]::Max(20,[int]$settings.zoom-10)}
        ([FluentAction]::ZoomReset){$settings.zoom=100}
        ([FluentAction]::ToggleStatusBar){$settings.showStatusBar=-not $settings.showStatusBar}
        ([FluentAction]::ToggleWordWrap){$settings.wordWrap=-not $settings.wordWrap}
        ([FluentAction]::LineEnding){$tab.LineEnding=if($tab.LineEnding -eq 'Unix (LF)'){'Windows (CRLF)'}else{'Unix (LF)'};$tab.RefreshModified()}
        ([FluentAction]::OpenSettings){$ui.Settings=$true;$ui.Menu='';$ui.Focus='settings'}
        ([FluentAction]::OpenFontSettings){$ui.Settings=$true;$null=$ui.Expanded.Add('card-font-setting');$ui.SettingsScroll=0;$ui.Focus='settings'}
        ([FluentAction]::Back){$ui.Settings=$false;$ui.Dropdown=$null;$ui.Focus='editor-area'}
        ([FluentAction]::Accordion){if(-not $ui.Expanded.Remove([string]$Data)){$null=$ui.Expanded.Add([string]$Data)}}
        ([FluentAction]::ToggleSetting){$settings.Set($Data,(-not $settings.Get($Data)))}
        ([FluentAction]::Startup){$settings.startupOption=$Data}
        ([FluentAction]::SettingSelect){$ui.Dropdown=[NotepadDropdown]@{Key=$Data.Key;Options=$Data.Options;Rect=$Data.Rect;Id=$Data.Id}}
        ([FluentAction]::ChooseSetting){[NotepadSettingChoice]$choice=$Data;if($choice.Key -eq 'pickerMode'){$ui.ColorPicker.Mode=$choice.Value;$ui.Focus='color-picker';Sync-ColorPickerInputs}else{$settings.Set($choice.Key,$choice.Value)};$ui.Dropdown=$null;if($choice.Key -eq 'theme'){Resolve-Theme};if($choice.Key -in @('theme','backdrop','cornerStyle')){Apply-WindowAppearance}}
        ([FluentAction]::PickerMode){$ui.Dropdown=[NotepadDropdown]@{Key='pickerMode';Options=[NotepadOption[]]@(@{Text='RGB';Value='RGB'},@{Text='HSV';Value='HSV'});Rect=$ui.ColorPicker.ModeRect;Id='picker-mode'}}
        ([FluentAction]::ToggleMenu){[string]$menu=$Data;$ui.Menu=if($ui.Menu -eq $menu){''}else{$menu};$ui.Submenu=''}
        ([FluentAction]::Submenu){$ui.Submenu=$Data}
        ([FluentAction]::Minimize){$window.Caption([FluentWindowDecoration]::Minimize)}
        ([FluentAction]::Maximize){$window.Caption([FluentWindowDecoration]::Maximize)}
        ([FluentAction]::Drag){$window.Caption([FluentWindowDecoration]::Drag)}
        ([FluentAction]::FocusInput){Focus-Input $Data}
        ([FluentAction]::DiscardTab){$model.CloseTab([int]$Data);$ui.Focus='editor-area'}
        ([FluentAction]::SaveCloseTab){[int]$closeId=$Data;[NotepadTab]$document=$null;foreach($candidate in $state.Tabs){if($candidate.Id -eq $closeId){$document=$candidate;break}};if(Save-Document $document){$model.CloseTab($closeId);$ui.Focus='editor-area'}}
        ([FluentAction]::DiscardWindow){$ui.Running=$false}
        ([FluentAction]::SaveCloseWindow){$success=$true;foreach($document in $state.Tabs){if($document.Modified -and -not(Save-Document $document)){$success=$false;break}};if($success){$ui.Running=$false}}
        ([FluentAction]::Dismiss){$ui.Focus='editor-area'}
        ([FluentAction]::ToggleMarkdownPreview){Open-Modal ('Markdown Preview: '+$tab.Title) '' @(@{Text='Close';Action=[FluentAction]::Dismiss;Primary=$true});$ui.Modal.Markdown=$tab.Content()}
        ([FluentAction]::Link){[string]$address=$Data;if($address.StartsWith('https://',[StringComparison]::Ordinal)){[NotepadWindow]::OpenLink($address)}}
        ([FluentAction]::ClearFormatting){$start=[Math]::Min($tab.Anchor,$tab.Focus);$end=[Math]::Max($tab.Anchor,$tab.Focus);if($start -ne $end){$text=$tab.Slice($start,$end-$start);foreach($marker in @('**','~~','_')){$text=$text.Replace($marker,'')};$model.Insert($text,$false)}}
        ([FluentAction]::PageSetup){Open-Modal 'Page setup' 'Native print layout is not implemented in this build.' @(@{Text='Close';Action=[FluentAction]::Dismiss;Primary=$true})}
        ([FluentAction]::Print){Open-Modal 'Print' 'Native printing is not implemented in this build.' @(@{Text='Close';Action=[FluentAction]::Dismiss;Primary=$true})}
    }
    Invalidate $true
}
function Convert-HsvToHex([double]$Hue,[double]$Saturation,[double]$Value){
    $h=($Hue%360+360)%360;$c=$Value*$Saturation;$x=$c*(1-[Math]::Abs(($h/60)%2-1));$m=$Value-$c
    [double[]]$rgb=switch([int][Math]::Floor($h/60)){0{@($c,$x,0)};1{@($x,$c,0)};2{@(0,$c,$x)};3{@(0,$x,$c)};4{@($x,0,$c)};default{@($c,0,$x)}}
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
    [string[]]$values=if($p.Mode -eq 'HSV'){@([string][int][Math]::Round($p.H),[string][int][Math]::Round($p.S*100),[string][int][Math]::Round($p.V*100))}else{@([string]$p.R,[string]$p.G,[string]$p.B)}
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
    $ui.ColorPicker=[NotepadColorPicker]@{Role=$Role;Ansi=$Ansi;H=0.0;S=0.0;V=1.0;Hex=$hex;R=0;G=0;B=0;Mode='RGB';Inputs=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase);Anchor=$anchor;Scroll=0.0;Invalid='';OpenedUtc=[DateTime]::UtcNow}
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
    $tab=$model.Active();$start=[Math]::Min($tab.Anchor,$tab.Focus);$length=[Math]::Abs($tab.Anchor-$tab.Focus);$text=$tab.Slice($start,$length)
    if($length -ge 2*$Marker.Length -and $text.StartsWith($Marker) -and $text.EndsWith($Marker)){$text=$text.Substring($Marker.Length,$text.Length-2*$Marker.Length);$model.Insert($text,$false);$model.Select($start,($start+$text.Length))}
    else{$model.Insert(($Marker+$text+$Marker),$false);$model.Select(($start+$Marker.Length),($start+$Marker.Length+$text.Length))}
    $tab.Markdown=$true;$ui.Focus='editor-area'
}
function Format-Lines([string]$Prefix){
    $tab=$model.Active();$start=[Math]::Min($tab.Anchor,$tab.Focus);$end=[Math]::Max($tab.Anchor,$tab.Focus)
    # From the start of the first selected line to the end of the last, by the document's line index.
    $lineStart=$tab.Document.LineStart($tab.Document.LineOf($start))
    $lastLine=$tab.Document.LineOf($end);$lineEnd=if($lastLine+1 -ge $tab.Document.LineCount()){$tab.Document.Length}else{$tab.Document.LineStart($lastLine+1)-1}
    $lines=$tab.Slice($lineStart,$lineEnd-$lineStart).Split("`n")
    $formatted=[Collections.Generic.List[string]]::new()
    foreach($line in $lines){if($Prefix -and $line.StartsWith($Prefix)){$formatted.Add($line.Substring($Prefix.Length))}else{$formatted.Add($Prefix+$line)}}
    $text=[string]::Join("`n",$formatted)
    $model.Select($lineStart,$lineEnd);$model.Insert($text,$false);$model.Select($lineStart,($lineStart+$text.Length));$tab.Markdown=$true;$ui.Focus='editor-area'
}
function Open-Find([bool]$Replace){
    $ui.Find=$true;$state.Find.Open=$true;$ui.Replace=$Replace;$ui.Menu='';$tab=$model.Active();$selected=$tab.Slice([Math]::Min($tab.Anchor,$tab.Focus),[Math]::Abs($tab.Focus-$tab.Anchor))
    if($selected -and -not $selected.Contains("`n")){$state.Find.Query=$selected}
    $model.Find();$model.SelectMatch(0);Focus-Input 'find-query-input'
}
function Input-Value([string]$Id){if($ui.ColorPicker -and $Id.StartsWith('picker-input-')){return $ui.ColorPicker.Inputs[$Id.Substring(13)]};switch($Id){'find-query-input'{$state.Find.Query};'replace-query-input'{$state.Find.Replacement};'dialog-input'{$ui.Modal.Value};default{''}}}
function Set-InputValue([string]$Id,[string]$Value){if($ui.ColorPicker -and $Id.StartsWith('picker-input-')){Set-ColorPickerText $Id.Substring(13) $Value;return};switch($Id){'find-query-input'{$state.Find.Query=$Value;$model.Find();$model.SelectMatch(0)};'replace-query-input'{$state.Find.Replacement=$Value};'dialog-input'{$ui.Modal.Value=$Value}}}
function Focus-Input([string]$Id){$ui.Focus=$Id;$value=Input-Value $Id;$ui.InputAnchor=0;$ui.InputFocus=$value.Length}
function Input-Insert([string]$Text){$value=Input-Value $ui.Focus;$start=[Math]::Min($ui.InputAnchor,$ui.InputFocus);$end=[Math]::Max($ui.InputAnchor,$ui.InputFocus);Set-InputValue $ui.Focus ($value.Substring(0,$start)+$Text+$value.Substring($end));$ui.InputFocus=$start+$Text.Length;$ui.InputAnchor=$ui.InputFocus}

# The editor gate. The text is a strip of lines; the gate shows whole lines from the top line ($tab.ScrollY, a line
# number) down until it is full, and only those lines are laid out and drawn. Scrolling advances the strip by whole
# lines, so the heights of the lines above the gate never need computing, with or without word wrap.

# Where each line of the tab's text starts, rebuilt only when the text changes.
function Update-LineStarts([NotepadTab]$Tab){
    $key="$($Tab.Id)|$($Tab.Revision)|$($Tab.Document.Length)"
    if($key -eq $ui.LineStartsKey){return}
    $ui.LineStarts=$Tab.Document.LineStarts();$ui.LineStartsKey=$key
}

# The line holding a position in the active text (Update-LineStarts first).
function Get-LineIndex([int]$Position){
    $starts=$ui.LineStarts;$low=0;$high=$starts.Length-1
    while($low -lt $high){$middle=[int][Math]::Floor(($low+$high+1)/2);if($starts[$middle] -le $Position){$low=$middle}else{$high=$middle-1}}
    return $low
}

# A line of the active text without its line break (Update-LineStarts first).
function Get-LineText([int]$LineNumber){
    $active=$model.Active();$starts=$ui.LineStarts
    $end=if($LineNumber+1 -lt $starts.Length){$starts[$LineNumber+1]-1}else{$active.Document.Length}
    return $active.Slice($starts[$LineNumber],$end-$starts[$LineNumber])
}

# The layout of one line in the editor's format, reused while the same text is drawn in the same format. Layouts
# not used by a frame are released at the end of Paint-Editor.
function Get-LineLayout([string]$Text){
    if($null -eq $ui.LineLayouts){$ui.LineLayouts=[Collections.Generic.Dictionary[string,IntPtr]]::new();$ui.LineLayoutsUsed=[Collections.Generic.HashSet[string]]::new()}
    $fontSize=[int]$settings.fontSize*96/72*([int]$settings.zoom/100)
    $weight=if($settings.fontStyle.Contains('Bold')){700}else{400};$italic=$settings.fontStyle.Contains('Italic')
    $available=[Math]::Max(1,$ui.Width-32-12)
    $key="$fontSize|$($settings.fontFamily)|$($settings.fontStyle)|$($settings.wordWrap)|$available|$Text"
    if(-not $ui.LineLayouts.ContainsKey($key)){$ui.LineLayouts[$key]=$graphics.Layout($Text,$settings.fontFamily,$fontSize,$available,[bool]$settings.wordWrap,$weight,$italic,($fontSize*1.45))}
    $null=$ui.LineLayoutsUsed.Add($key)
    return $ui.LineLayouts[$key]
}

function Paint-Editor {
    $tab=$model.Active();$bottom=if($settings.showStatusBar){37}else{0};$h=[Math]::Max(1,$ui.Height-80-$bottom)
    $ui.EditorRect=@(0.0,80.0,$ui.Width,$h)
    if(-not $settings.gradientEnabled){$graphics.Fill(0,80,$ui.Width,$h,(Surface-Color 'bg-editor'),0)}
    Node 'editor-area' 0 80 $ui.Width $h ([FluentAction]::Editor) $null 'text'
    $available=[Math]::Max(1,$ui.Width-32-12);$view=$h-28
    Update-LineStarts $tab
    if($null -ne $ui.LineLayoutsUsed){$ui.LineLayoutsUsed.Clear()}
    $starts=$ui.LineStarts;$lineCount=$starts.Length
    $caretLine=Get-LineIndex $tab.Focus
    if($ui.EnsureCaret){
        # Above the gate: the caret line becomes the top. Below it: the top moves down until the caret line ends
        # inside the gate.
        if($caretLine -lt [int]$tab.ScrollY){$tab.ScrollY=$caretLine}
        else{
            $sum=0.0;$first=$caretLine
            while($first -ge [int]$tab.ScrollY){$sum+=$graphics.Metrics((Get-LineLayout (Get-LineText $first))).Height;if($sum -gt $view){break};$first--}
            if($sum -gt $view){$tab.ScrollY=[Math]::Min($caretLine,$first+1)}
        }
        if(-not $settings.wordWrap){
            $caretAt=$graphics.Caret((Get-LineLayout (Get-LineText $caretLine)),[uint32]($tab.Focus-$starts[$caretLine]),$false)
            if($caretAt.X -lt $tab.ScrollX){$tab.ScrollX=$caretAt.X};if($caretAt.X -gt $tab.ScrollX+$available-2){$tab.ScrollX=$caretAt.X-$available+2}
        }else{$tab.ScrollX=0.0}
        $ui.EnsureCaret=$false
    }
    # The position keeps any fraction of a line (small touchpad steps add up); the gate starts at its whole line.
    $tab.ScrollY=[Math]::Clamp([double]$tab.ScrollY,0,[Math]::Max(0,$lineCount-1));$top=[int][Math]::Floor($tab.ScrollY)
    $ox=16-$tab.ScrollX;$y=94.0;$ui.EditorOrigin=@($ox,$y)
    $graphics.Clip(0,80,($ui.Width-12),$h)
    $selStart=[Math]::Min($tab.Anchor,$tab.Focus);$selEnd=[Math]::Max($tab.Anchor,$tab.Focus)
    $foreground=Role-Color 'foreground';$selectionBack=Role-Color 'selectionBackground';$selectionFore=Color 'selection-text'
    $gate=[Collections.Generic.List[NotepadGateLine]]::new()
    for($line=$top;$line -lt $lineCount -and $y -lt 80+$h;$line++){
        $start=$starts[$line];$end=if($line+1 -lt $lineCount){$starts[$line+1]-1}else{$tab.Document.Length}
        $layout=Get-LineLayout $tab.Slice($start,$end-$start)
        $gateLine=[NotepadGateLine]::new();$gateLine.Line=$line;$gateLine.Start=$start;$gateLine.Length=$end-$start;$gateLine.Top=$y;$gateLine.Height=$graphics.Metrics($layout).Height;$gateLine.Layout=$layout
        $gate.Add($gateLine)
        # This line's share of the selection, plus a sliver for its line break when the selection runs past it.
        $from=[Math]::Max($selStart,$start);$to=[Math]::Min($selEnd,$end)
        [NotepadRect[]]$rects=[NotepadRect[]]::new(0)
        if($to -gt $from){$rects=@($graphics.Selection($layout,($from-$start),($to-$from)))}
        foreach($rect in $rects){$graphics.Fill(($ox+$rect.X),($y+$rect.Y),[Math]::Max(1,$rect.Width),$rect.Height,$selectionBack,0)}
        if($selStart -le $end -and $selEnd -gt $end -and $line+1 -lt $lineCount){
            $breakAt=$graphics.Caret($layout,[uint32]($end-$start),$false);$graphics.Fill(($ox+$breakAt.X),($y+$breakAt.Y),6,$breakAt.Height,$selectionBack,0)
        }
        $graphics.DrawLayout($layout,$ox,$y,$foreground)
        foreach($rect in $rects){$graphics.Clip(($ox+$rect.X),($y+$rect.Y),[Math]::Max(1,$rect.Width),$rect.Height);$graphics.DrawLayout($layout,$ox,$y,$selectionFore);$graphics.Unclip()}
        if($line -eq $caretLine -and $ui.Focus -eq 'editor-area' -and $ui.Focused -and $ui.Blink -and -not $ui.Modal -and -not $ui.Settings){
            $caretAt=$graphics.Caret($layout,[uint32]($tab.Focus-$start),$false);$graphics.Fill(($ox+$caretAt.X),($y+$caretAt.Y),1,$caretAt.Height,(Role-Color 'cursor'),0)
        }
        $y+=$gateLine.Height
    }
    $graphics.Unclip()
    $ui.GateLines=$gate
    $metrics=[NotepadTextMetrics]::new();$metrics.Lines=$lineCount;$metrics.Height=[single]($y-94);$ui.EditorMetrics=$metrics
    # Layouts no line used this frame are released.
    if($null -ne $ui.LineLayouts){
        $stale=[Collections.Generic.List[string]]::new()
        foreach($layoutKey in $ui.LineLayouts.Keys){if(-not $ui.LineLayoutsUsed.Contains($layoutKey)){$stale.Add($layoutKey)}}
        foreach($layoutKey in $stale){$graphics.ReleaseLayout($ui.LineLayouts[$layoutKey]);$null=$ui.LineLayouts.Remove($layoutKey)}
    }
    # The scrollbar measures in lines: the thumb's share of the track is the gate's share of the lines.
    $ui.ScrollTrack=$null
    if($top -gt 0 -or $top+$gate.Count -lt $lineCount){
        $maxTop=[double][Math]::Max(1,$lineCount-1)
        $track=$h-6;$thumb=[Math]::Max(24,$track*[Math]::Min(1.0,$gate.Count/[double]$lineCount));$ty=81+($track-$thumb)*$top/$maxTop
        $ui.ScrollTrack=@(81.0,[double]$track,[double]$thumb,$maxTop)
        $graphics.Fill(($ui.Width-9),$ty,6,$thumb,'rgba(255,255,255,0.2)',3)
        Node 'editor-scrollbar' ($ui.Width-12) 80 12 $h ([FluentAction]::Scrollbar) $null 'default'
    }
}
function Paint-Chrome {
    $w=$ui.Width;$tab=$model.Active()
    if(-not $settings.gradientEnabled){$graphics.Fill(0,0,$w,42,(Surface-Color 'bg-titlebar'),0)}
    Node 'titlebar-drag' 0 0 $w 42 ([FluentAction]::Drag) $null 'default';Paint-AppIcon 'app-icon' 24 13 14
    $x=54.0;$right=$w-138
    $graphics.Clip(40,0,[Math]::Max(0,$right-76),40)
    foreach($document in $state.Tabs){
        $id='tab-'+$document.Id;$active=$document.Id -eq $state.ActiveId;$hover=$ui.Hover.StartsWith($id)
        $tw=240
        # Every tab is translucent: the active one is a surface over the material like the ribbon it sits on, the
        # others a darker film (22% black) over whatever is beneath, solid or material. One shape per tab, rounded at
        # the top and cut square at the bottom by a clip, so a translucent fill never overlaps itself.
        $bg=if($active){Surface-Hex (Role-Color 'tabs')}elseif($hover){Surface-Color 'bg-tab-hover'}else{'rgba(0,0,0,0.22)'}
        $graphics.Clip($x,5.2,$tw,34);$graphics.Fill($x,5.2,$tw,41,$bg,7);$graphics.Unclip()
        if($active){$graphics.Stroke($x,5.2,$tw,34,(Color 'border-subtle'),7,0.8)}
        Node $id $x 5.2 $tw 34 ([FluentAction]::SwitchTab) $document.Id
        $graphics.Clip(($x+12),8,($tw-44),28);Label $document.Caption() ($x+12) 14 ($tw-44) (Color $(if($active -or $hover){'text-primary'}else{'text-secondary'})) 12;$graphics.Unclip()
        # One slot at the tab's right end: the modified dot (a 6 px circle) unless the tab is hovered, otherwise the
        # close button on the active or hovered tab.
        $cx=$x+$tw-28
        if($document.Modified -and -not $hover){$graphics.Fill(($cx+7),19.2,6,6,(Color 'text-secondary'),3)}
        elseif($active -or $hover){
            Node ($id+'-close') $cx 12.2 20 20 ([FluentAction]::CloseSpecific) $document.Id
            if($ui.Hover -eq $id+'-close'){$graphics.Fill($cx,12.2,20,20,(Color 'bg-control-hover'),4)}
            Icon 'close' ($cx+4) 16 12 (Color 'text-primary')
        }
        $x+=$tw+2
    }
    $graphics.Unclip();$x=[Math]::Min($x+4,$right-36)
    Button 'btn-add-tab' $x 6 32 32 ([FluentAction]::NewTab) '' 'plus' $null $false $false 14
    Button 'btn-win-min' ($w-138) 0 46 40 ([FluentAction]::Minimize) '' 'minimize' $null $false $false 10
    Button 'btn-win-max' ($w-92) 0 46 40 ([FluentAction]::Maximize) '' 'maximize' $null $false $false 10
    Button 'btn-win-close' ($w-46) 0 46 40 ([FluentAction]::CloseWindow) '' 'close' $null $false $false 10
    if(-not $settings.gradientEnabled){$graphics.Fill(0,42,$w,38,(Surface-Color 'bg-menubar'),0)}
    $mx=8.0
    foreach($entry in [NotepadMenuEntry[]]@(@{Name='file';Text='File';Width=44},@{Name='edit';Text='Edit';Width=44},@{Name='view';Text='View';Width=48})){
        if($ui.Menu -eq $entry.Name){$graphics.Fill($mx,44,($entry.Width),28,(Color 'bg-control-hover'),4)}
        Button ('menu-btn-'+$entry.Name) $mx 44 $entry.Width 28 ([FluentAction]::ToggleMenu) $entry.Text '' $entry.Name
        $mx+=$entry.Width+2
    }
    if($settings.formatting){
        $fx=($w-280)/2
        Button 'format-headings' $fx 45 42 30 ([FluentAction]::ToggleMenu) 'H1' '' 'headings'
        Icon 'chevronDown' ($fx+32) 56 8
        Button 'format-lists' ($fx+44) 45 38 30 ([FluentAction]::ToggleMenu) '' '' 'lists';Label ([string][char]0xE8FD) ($fx+51) 52 22 (Color 'text-primary') 16 'Segoe Fluent Icons'
        Button 'format-bold' ($fx+84) 45 30 30 ([FluentAction]::FormatBold);Label 'B' ($fx+94) 51 20 (Color 'text-primary') 16 'Segoe UI' 700
        Button 'format-italic' ($fx+116) 45 30 30 ([FluentAction]::FormatItalic);Label ([string][char]0xE8DB) ($fx+123) 52 20 (Color 'text-primary') 16 'Segoe Fluent Icons'
        Button 'format-strike' ($fx+148) 45 30 30 ([FluentAction]::FormatStrike);Label ([string][char]0xEDE0) ($fx+155) 52 20 (Color 'text-primary') 16 'Segoe Fluent Icons'
        Button 'format-link' ($fx+180) 45 30 30 ([FluentAction]::FormatLink);Label ([string][char]0xE71B) ($fx+187) 52 20 (Color 'text-primary') 16 'Segoe Fluent Icons'
        Button 'format-more' ($fx+212) 45 30 30 ([FluentAction]::ToggleMenu) '' '' 'formatMore';Label ([string][char]0xE712) ($fx+219) 52 20 (Color 'text-primary') 16 'Segoe Fluent Icons'
    }
    # One copy button, in the centre ribbon after the formatting buttons, or alone in the centre when formatting is off.
    $copyX=if($settings.formatting){($w-280)/2+244}else{($w-32)/2}
    Button 'btn-copy-document' $copyX 45 32 30 ([FluentAction]::CopyDocument)
    Label ([string][char]0xE8C8) ($copyX+8) 52 20 (Color 'text-primary') 16 'Segoe Fluent Icons'
    Button 'btn-writing-tools' ($w-80) 45 28 30 ([FluentAction]::ToggleMenu) '✧' '' 'writing'
    Button 'btn-settings-toggle' ($w-40) 43 32 32 ([FluentAction]::OpenSettings) '' 'gear'
    if($settings.showStatusBar){
        $y=$ui.Height-37;if(-not $settings.gradientEnabled){$graphics.Fill(0,$y,$w,37,(Surface-Color 'bg-statusbar'),0)}
        $status=$model.Status();$cursor="Ln $($status.Line), Col $($status.Column)";$count=if($status.Selected){"$($status.Selected) selected"}else{"$($status.Characters) characters"}
        Label $cursor 26 ($y+6) 170 (Color 'text-secondary') 12
        $graphics.Fill(126,($y+7),0.8,14,(Color 'border-subtle'),0);Label $count 137 ($y+6) 200 (Color 'text-secondary') 12
        [NotepadStatusItem[]]$items=@(@{Id='sb-doc-type';Text=$(if($tab.Markdown){'Markdown'}else{'Plain text'});Width=100;Action=[FluentAction]::None},@{Id='sb-zoom-level';Text=([string]$settings.zoom+'%');Width=70;Action=[FluentAction]::ZoomReset},@{Id='sb-line-ending';Text=$tab.LineEnding;Width=114;Action=[FluentAction]::LineEnding},@{Id='sb-encoding';Text=$tab.Encoding;Width=74;Action=[FluentAction]::None})
        # Each item is at least its base width and wide enough for its text at Windows' text size; the row ends 16 px
        # from the right edge.
        foreach($item in $items){$item.Width=[Math]::Max($item.Width,(Measure-LabelWidth $item.Text 12)+20)}
        $itemsWidth=0.0;foreach($item in $items){$itemsWidth+=$item.Width}
        $sx=$w-16-$itemsWidth
        foreach($item in $items){Node $item.Id $sx $y $item.Width 28 $item.Action;if($ui.Hover -eq $item.Id){$graphics.Fill($sx,$y,$item.Width,28,(Color 'bg-control-hover'),0)};Label $item.Text ($sx+10) ($y+6) ($item.Width-20) (Color 'text-secondary') 12;$sx+=$item.Width;$graphics.Fill($sx,($y+7),0.8,14,(Color 'border-subtle'),0)}
    }
}
function Paint-Find {
    if(-not $ui.Find){return}
    $w=460.0;$x=$ui.Width-24-$w;$y=88.0;$h=if($ui.Replace){88}else{48}
    $graphics.Fill($x,$y,$w,$h,(Surface-Color 'bg-flyout' 0.35),8);$graphics.Stroke($x,$y,$w,$h,(Color 'border-control'),8,1)
    Node 'find-replace-panel' $x $y $w $h ([FluentAction]::None)
    InputBox 'find-query-input' $state.Find.Query ($x+10) ($y+9) 228 'Find' 28
    $count=if(-not $state.Find.Query){'0 of 0'}elseif(-not $state.Find.Matches.Count){'No results'}else{"$($state.Find.Index+1) of $($state.Find.Matches.Count)"}
    Label $count ($x+174) ($y+16) 62 (Color 'text-secondary') 12
    $bx=$x+244
    foreach($button in [NotepadFindButton[]]@(@{Id='prev';Icon='arrowUp';Action=[FluentAction]::FindPrevious},@{Id='next';Icon='arrowDown';Action=[FluentAction]::FindNext},@{Id='case';Icon='caseSensitive';Action=[FluentAction]::FindCase},@{Id='wrap';Icon='wrapAround';Action=[FluentAction]::FindWrap},@{Id='replace';Icon='chevronDown';Action=[FluentAction]::ToggleReplace},@{Id='close';Icon='close';Action=[FluentAction]::CloseFind})){
        if(($button.Action -eq [FluentAction]::FindCase -and $state.Find.MatchCase) -or ($button.Action -eq [FluentAction]::FindWrap -and $state.Find.Wrap)){$graphics.Fill($bx,($y+9),28,28,(Color 'bg-control-active'),4)}
        Button ('find-btn-'+$button.Id) $bx ($y+9) 28 28 $button.Action '' $button.Icon $null $false $false 14;$bx+=34
    }
    if($ui.Replace){InputBox 'replace-query-input' $state.Find.Replacement ($x+10) ($y+47) 253 'Replace with' 28;Button 'btn-do-replace' ($x+269) ($y+47) 74 28 ([FluentAction]::DoReplace) 'Replace' '' $null $false $true;Button 'btn-do-replace-all' ($x+349) ($y+47) 100 28 ([FluentAction]::DoReplaceAll) 'Replace all' '' $null $false $true}
}
function Paint-MenuRows([NotepadMenuRow[]]$Rows,[double]$X,[double]$Y,[double]$W,[string]$Prefix){
    $h=8.0;foreach($row in $Rows){$h+=$(if($row.Separator){7}else{28})}
    # Opaque: a flyout covers what is under it (acrylic needs the composition renderer, not a translucent fill).
    $graphics.Fill($X,$Y,$W,$h,(Color 'bg-flyout'),8);$graphics.Stroke($X,$Y,$W,$h,(Color 'border-control'),8,1)
    Node ($Prefix+'-background') $X $Y $W $h ([FluentAction]::None)
    $ry=$Y+4;$rowIndex=0
    foreach($row in $Rows){
        if($row.Separator){$graphics.Fill(($X+10),($ry+3),($W-20),1,(Color 'border-subtle'),0);$ry+=7;continue}
        $id=$Prefix+'-'+$rowIndex;$rowIndex++
        if(-not $row.Disabled){Node $id ($X+4) $ry ($W-8) 28 $row.Action $row.Data}
        if($ui.Hover -eq $id -and -not $row.Disabled){$graphics.Fill(($X+4),$ry,($W-8),28,(Color 'bg-flyout-item-hover'),4)}
        $tx=$X+14
        if($null -ne $row.Checked){if($row.Checked){Icon 'check' $tx ($ry+8) 12};$tx+=22}
        Label $row.Text $tx ($ry+5) ($W-28) (Color $(if($row.Disabled){'text-disabled'}else{'text-primary'})) 13
        if($row.Shortcut){Label $row.Shortcut ($X+$W-113) ($ry+6) 96 (Color 'text-secondary') 12}
        if($row.Submenu){Icon 'chevronRight' ($X+$W-24) ($ry+9) 10 (Color 'text-secondary');if($ui.Submenu -eq $row.Submenu){Paint-MenuRows $row.Rows ($X+$W-1) ($ry-4) 220 ($Prefix+'-sub')}}
        $ry+=28
    }
}
function Paint-Menus {
    if(-not $ui.Menu){return}
    [NotepadMenuRow[]]$rows=switch($ui.Menu){
        'file'{[NotepadMenuRow[]]@(@{Text='New tab';Action=[FluentAction]::NewTab;Shortcut='Ctrl+N'},@{Text='New window';Action=[FluentAction]::NewActivity;Shortcut='Ctrl+Shift+N'},@{Text='New Markdown tab';Action=[FluentAction]::NewMarkdownTab},@{Text='Open';Action=[FluentAction]::OpenFile;Shortcut='Ctrl+O'},@{Text='Recent';Action=[FluentAction]::Submenu;Data='recent';Submenu='recent';Rows=@(@{Text='No recent files';Action=[FluentAction]::None;Disabled=$true})},@{Text='Save';Action=[FluentAction]::Save;Shortcut='Ctrl+S'},@{Text='Save as';Action=[FluentAction]::SaveAs;Shortcut='Ctrl+Shift+S'},@{Text='Save all';Action=[FluentAction]::SaveAll;Shortcut='Ctrl+Alt+S'},@{Separator=$true},@{Text='Page setup';Action=[FluentAction]::PageSetup},@{Text='Print';Action=[FluentAction]::Print;Shortcut='Ctrl+P'},@{Separator=$true},@{Text='Close tab';Action=[FluentAction]::CloseTab;Shortcut='Ctrl+W'},@{Text='Close window';Action=[FluentAction]::CloseWindow;Shortcut='Ctrl+Shift+W'},@{Text='Exit';Action=[FluentAction]::Exit})}
        'edit'{[NotepadMenuRow[]]@(@{Text='Undo';Action=[FluentAction]::Undo;Shortcut='Ctrl+Z'},@{Separator=$true},@{Text='Cut';Action=[FluentAction]::Cut;Shortcut='Ctrl+X'},@{Text='Copy';Action=[FluentAction]::Copy;Shortcut='Ctrl+C'},@{Text='Paste';Action=[FluentAction]::Paste;Shortcut='Ctrl+V'},@{Text='Delete';Action=[FluentAction]::Delete;Shortcut='Del'},@{Separator=$true},@{Text='Clear formatting';Action=[FluentAction]::ClearFormatting},@{Text='Find';Action=[FluentAction]::Find;Shortcut='Ctrl+F'},@{Text='Find next';Action=[FluentAction]::FindNext;Shortcut='F3'},@{Text='Find previous';Action=[FluentAction]::FindPrevious;Shortcut='Shift+F3'},@{Text='Replace';Action=[FluentAction]::Replace;Shortcut='Ctrl+H'},@{Text='Go to';Action=[FluentAction]::GoTo;Shortcut='Ctrl+G'},@{Separator=$true},@{Text='Select all';Action=[FluentAction]::SelectAll;Shortcut='Ctrl+A'},@{Text='Time/Date';Action=[FluentAction]::TimeDate;Shortcut='F5'},@{Separator=$true},@{Text='Font';Action=[FluentAction]::OpenFontSettings})}
        'view'{[NotepadMenuRow[]]@(@{Text='Zoom';Action=[FluentAction]::Submenu;Data='zoom';Submenu='zoom';Rows=@(@{Text='Zoom in';Action=[FluentAction]::ZoomIn;Shortcut='Ctrl+Plus'},@{Text='Zoom out';Action=[FluentAction]::ZoomOut;Shortcut='Ctrl+Minus'},@{Text='Restore default zoom';Action=[FluentAction]::ZoomReset;Shortcut='Ctrl+0'})},@{Text='Status bar';Action=[FluentAction]::ToggleStatusBar;Checked=[bool]$settings.showStatusBar},@{Text='Word wrap';Action=[FluentAction]::ToggleWordWrap;Checked=[bool]$settings.wordWrap},@{Text='Markdown';Action=[FluentAction]::Submenu;Data='markdown';Submenu='markdown';Rows=@(@{Text='Preview Markdown';Action=[FluentAction]::ToggleMarkdownPreview})})}
        'headings'{[NotepadMenuRow[]]@(@{Text='Heading 1';Action=[FluentAction]::FormatHeading;Data='# '},@{Text='Heading 2';Action=[FluentAction]::FormatHeading;Data='## '},@{Text='Heading 3';Action=[FluentAction]::FormatHeading;Data='### '},@{Text='Paragraph';Action=[FluentAction]::FormatHeading;Data=''})}
        'lists'{[NotepadMenuRow[]]@(@{Text='Bulleted list';Action=[FluentAction]::FormatList;Data='- '},@{Text='Numbered list';Action=[FluentAction]::FormatList;Data='1. '},@{Text='Checklist';Action=[FluentAction]::FormatList;Data='- [ ] '})}
        'formatMore'{[NotepadMenuRow[]]@(@{Text='Bold';Action=[FluentAction]::FormatBold;Shortcut='Ctrl+B'},@{Text='Italic';Action=[FluentAction]::FormatItalic;Shortcut='Ctrl+I'},@{Text='Strikethrough';Action=[FluentAction]::FormatStrike;Shortcut='Ctrl+Shift+X'},@{Text='Insert link';Action=[FluentAction]::FormatLink;Shortcut='Ctrl+K'},@{Separator=$true},@{Text='Clear formatting';Action=[FluentAction]::ClearFormatting},@{Text='Preview Markdown';Action=[FluentAction]::ToggleMarkdownPreview})}
        'writing'{[NotepadMenuRow[]]@(@{Text='Copy format settings';Action=[FluentAction]::OpenSettings})}
    }
    $x=switch($ui.Menu){'file'{8};'edit'{54};'view'{100};'headings'{($ui.Width-280)/2};'lists'{($ui.Width-280)/2+44};'formatMore'{($ui.Width-280)/2+212};'writing'{$ui.Width-268}}
    $x=[Math]::Clamp([double]$x,8,[Math]::Max(8,$ui.Width-268))
    Paint-MenuRows $rows $x 80 260 ('flyout-'+$ui.Menu)
}
function Select-Control([string]$Id,[string]$Key,[NotepadOption[]]$Options,[double]$X,[double]$Y,[double]$W){
    $text=[string]$settings.Get($Key);foreach($option in $Options){if($option.Value -eq [string]$settings.Get($Key)){$text=$option.Text;break}}
    $data=@{Id=$Id;Key=$Key;Options=$Options;Rect=@($X,$Y,$W,32)}
    Button $Id $X $Y $W 32 ([FluentAction]::SettingSelect) '' '' $data $false $true
    Label $text ($X+12) ($Y+7) ($W-36) (Color 'text-primary') 13
    Icon 'chevronDown' ($X+$W-22) ($Y+10) 12 '#9d9d9d'
}
function Toggle-Control([string]$Key,[double]$X,[double]$Y){
    $on=[bool]$settings.Get($Key);$id='toggle-setting-'+$Key
    Node $id $X $Y 78 24 ([FluentAction]::ToggleSetting) $Key
    $track=if($on){Color 'accent-color'}elseif($ui.Theme -eq 'light'){'#e0e0e0'}else{'#333333'}
    $border=if($on){Color 'accent-color'}elseif($ui.Theme -eq 'light'){'#999999'}else{'#777777'}
    $graphics.Fill($X,($Y+2),40,20,$track,10);$graphics.Stroke($X,($Y+2),40,20,$border,10,1)
    $knob=if($on){'#ffffff'}elseif($ui.Theme -eq 'light'){'#555555'}else{'#cecece'}
    $graphics.Fill(($X+3+$(if($on){18}else{0})),($Y+$(if($on){5}else{6})),($(if($on){14}else{12})),($(if($on){14}else{12})),$knob,7)
    Label $(if($on){'On'}else{'Off'}) ($X+50) ($Y+4) 28 (Color 'text-primary') 13
}
function Paint-ColorControls([double]$X,[double]$Y,[double]$W){
    [string[]]$names=@('Black','Red','Green','Yellow','Blue','Purple','Cyan','White')
    [string[][]]$roles=@(@('foreground','Foreground'),@('tabs','Tabs'),@('cursor','Cursor color'),@('selectionBackground','Selection background'),@('topLeft','Top left'),@('topRight','Top right'),@('bottomLeft','Bottom left'),@('bottomRight','Bottom right'))
    for($i=0;$i -lt 8;$i++){
        $rowY=$Y+$i*40
        Label $names[$i] ($X+24) ($rowY+8) 72 (Color 'text-primary') 14
        foreach($bright in [int[]]@(0,1)){$index=$i+8*$bright;$sx=$X+112+42*$bright;Node ('palette-'+$index) $sx $rowY 32 32 ([FluentAction]::EditAnsi) $index;$graphics.Fill($sx,$rowY,32,32,$settings.ansiColors[$index],4);$graphics.Stroke($sx,$rowY,32,32,(Color 'border-control'),4,1)}
        Label $roles[$i][1] ($X+$W/2) ($rowY+8) ($W/2-66) (Color 'text-primary') 14
        $cx=$X+$W-56;Node ('color-'+$roles[$i][0]) $cx $rowY 32 32 ([FluentAction]::EditColor) $roles[$i][0]
        $graphics.Fill($cx,$rowY,32,32,(Role-Color $roles[$i][0]),4);$graphics.Stroke($cx,$rowY,32,32,(Color 'border-control'),4,1)
    }
    Button 'reset-colors' ($X+24) ($Y+330) 130 32 ([FluentAction]::ResetColors) 'Reset colors' '' $null $false $true
}
function Paint-Settings {
    if(-not $ui.Settings){return}
    $w=$ui.Width;$h=$ui.Height;if(-not $settings.gradientEnabled){$graphics.Fill(0,0,$w,$h,(Surface-Color 'bg-window'),0)};Node 'settings-view' 0 0 $w $h ([FluentAction]::None) $null 'default'
    $graphics.Fill(0,39.2,$w,0.8,(Color 'border-subtle'),0)
    # The title bar drags the window, as on the editor page; the buttons drawn after it take their own clicks.
    Node 'titlebar-drag' 0 0 $w 40 ([FluentAction]::Drag) $null 'default'
    Button 'settings-btn-back' 8 4 32 32 ([FluentAction]::Back) '' 'back';Paint-AppIcon 'settings-app-icon' 48 11 18;Label 'Notepad' 88 12 200 (Color 'text-primary') 12
    Button 'settings-win-min' ($w-138) 0 46 40 ([FluentAction]::Minimize) '' 'minimize' $null $false $false 10
    Button 'settings-win-max' ($w-92) 0 46 40 ([FluentAction]::Maximize) '' 'maximize' $null $false $false 10
    Button 'settings-win-close' ($w-46) 0 46 40 ([FluentAction]::CloseWindow) '' 'close' $null $false $false 10
    $col=[Math]::Min(650,$w-118);$left=($w-$col)/2;$right=$left
    $y=74-$ui.SettingsScroll
    $graphics.Clip(0,40,($w-12),($h-40));$ui.HitClip=@(0,40,($w-12),($h-40))
    Label 'Settings' $left $y $col (Color 'text-primary') 28 'Segoe UI' 600
    $y+=91
    Label 'Appearance' $left $y $col (Color 'text-primary') 14 'Segoe UI' 600;$y+=24
    [NotepadSettingCard[]]$cards=@(
        @{Title='App theme';Subtitle='Select which app theme to display';Icon='theme';Key='theme';Select=@(@{Text='Dark';Value='dark'},@{Text='Light';Value='light'},@{Text='Use system setting';Value='system'});SelectWidth=170}
        # MansfieldPlumbing additions: native DWM material, geometry and whole-document clipboard.
        @{Title='Window backdrop';Subtitle='Choose the material behind the window';Icon='theme';Key='backdrop';Select=@(@{Text='Solid';Value='solid'},@{Text='Mica';Value='mica'},@{Text='Acrylic';Value='acrylic'},@{Text='Reverse Mica';Value='reverseMica'});SelectWidth=170}
        @{Title='Opening animation';Subtitle='How the window appears when Notepad starts';Icon='theme';Key='entranceAnimation';Select=@(@{Text='Fade in';Value='fade'},@{Text='Slide in';Value='slide'});SelectWidth=170}
        @{Title='Background opacity';Subtitle='100% is opaque. Reduce to reveal the material.';Icon='theme';Key='backgroundOpacity';Slider=$true}
        @{Title='Four-corner gradient';Subtitle='Blend the four corner colors across the background';Icon='theme';Key='gradientEnabled';Toggle=$true}
        @{Title='Gradient strength';Subtitle='How strongly the four corner colors show, on any backdrop';Icon='theme';Key='gradientStrength';Slider=$true}
        @{Title='Colors';Icon='theme';Accordion='card-colors-setting'}
        @{Title='Corners';Subtitle='Choose curved or straight window and control corners';Icon='tabsApp';Key='cornerStyle';Select=@(@{Text='Curved';Value='curved'},@{Text='Straight';Value='straight'});SelectWidth=170}
        @{Title='Window icon';Subtitle='Click the top-left icon to cycle system icons';Icon='app';Button=[FluentAction]::ResetIcon;ButtonText='Reset icon'}
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
        $expanded=$card.Accordion -and $ui.Expanded.Contains([string]$card.Accordion)
        if($card.Accordion){$height=51.6;if($expanded){$height=switch($card.Accordion){'card-font-setting'{296.125};'card-colors-setting'{438};default{147.6}}}}
        $graphics.Fill($left,$y,$col,$height,(Surface-Color 'bg-card' 0.12),8);$graphics.Stroke($left,$y,$col,$height,(Color 'border-subtle'),8,0.8)
        $headerHeight=if($card.Subtitle){68}else{51.6};Icon $card.Icon ($left+17) ($y+($headerHeight-18)/2) 18
        Label $card.Title ($left+52) ($y+$(if($card.Subtitle){14}else{16})) ($col-230) (Color 'text-primary') 14
        if($card.Subtitle){Label $card.Subtitle ($left+52) ($y+36) ($col-230) (Color 'text-secondary') 12}
        if($card.Select){Select-Control ('setting-'+$card.Key) $card.Key $card.Select ($left+$col-$card.SelectWidth-16) ($y+($height-32)/2) $card.SelectWidth}
        if($card.Toggle){Toggle-Control $card.Key ($left+$col-94) ($y+($height-24)/2)}
        if($card.Button){Button ('setting-'+$card.Button) ($left+$col-146) ($y+18) 130 32 $card.Button $card.ButtonText '' $null $false $true}
        if($card.Slider){
            # A slider for the card's setting (0 to 100). Its node id is the key spelled with hyphens
            # (backgroundOpacity is setting-background-opacity) and carries the key for the input handlers.
            $sx=$left+$col-230;$sy=$y+34;$sw=170;$sliderValue=[int]$settings.Get($card.Key);$amount=$sliderValue/100.0
            if($null -eq $ui.SliderTracks){$ui.SliderTracks=[Collections.Generic.Dictionary[string,double[]]]::new()}
            $ui.SliderTracks[$card.Key]=@($sx,$sy,$sw,4)
            $sliderId=[Text.StringBuilder]::new('setting-');foreach($letter in $card.Key.ToCharArray()){if([char]::IsUpper($letter)){$null=$sliderId.Append('-').Append([char]::ToLowerInvariant($letter))}else{$null=$sliderId.Append($letter)}}
            Node $sliderId.ToString() $sx ($sy-12) $sw 28 ([FluentAction]::OpacitySlider) $card.Key
            $graphics.Fill($sx,$sy,$sw,4,(Color 'border-control'),2);$graphics.Fill($sx,$sy,($sw*$amount),4,(Color 'accent-color'),2)
            $graphics.Fill(($sx+$sw*$amount-8),($sy-6),16,16,(Color 'bg-control'),8);$graphics.Fill(($sx+$sw*$amount-4),($sy-2),8,8,(Color 'accent-color'),4)
            Label ([string]$sliderValue+'%') ($sx+$sw+10) ($sy-8) 48 (Color 'text-primary') 13
        }
        if($card.Accordion){
            Node ('header-'+$card.Accordion) $left $y $col 51.6 ([FluentAction]::Accordion) $card.Accordion
            Icon 'chevronDown' ($left+$col-34) ($y+18.8) 14 (Color 'text-secondary') $(if($expanded){180}else{0})
            if($expanded){
                $graphics.Fill(($left+16),($y+51.6),($col-32),0.8,(Color 'border-subtle'),0)
                if($card.Accordion -eq 'card-font-setting'){
                    $fy=$y+68
                    [NotepadFontRow[]]$fontOptions=@(@{Label='Family';Key='fontFamily';Options=@('Consolas','Cascadia Code','Segoe UI','Courier New');Width=130},@{Label='Style';Key='fontStyle';Options=@('Regular','Bold','Italic','Bold Italic');Width=112},@{Label='Size';Key='fontSize';Options=@('8','9','10','11','12','14','16','18','20','24','28','36');Width=68})
                    foreach($row in $fontOptions){Label $row.Label ($left+24) ($fy+7) 150 (Color 'text-primary') 13;$options=[Collections.Generic.List[NotepadOption]]::new();foreach($choice in $row.Options){$options.Add([NotepadOption]@{Text=$choice;Value=$choice})};Select-Control ('setting-'+$row.Key) $row.Key $options.ToArray() ($left+$col-24-$row.Width) $fy $row.Width;$fy+=46}
                    $fy+=5;$graphics.Fill(($left+16),$fy,($col-32),70.125,$(if($ui.Theme -eq 'light'){'#f7f7f7'}else{'#202020'}),6);$graphics.Stroke(($left+16),$fy,($col-32),70.125,(Color 'border-subtle'),6,0.8)
                    $layout=$graphics.Layout('The sound of ocean waves calms my soul.',$settings.fontFamily,([int]$settings.fontSize*96/72),($col-64),$false,$(if($settings.fontStyle.Contains('Bold')){700}else{400}),$settings.fontStyle.Contains('Italic'),0)
                    try{$m=$graphics.Metrics($layout);$graphics.DrawLayout($layout,($left+($col-$m.Width)/2),($fy+(70.125-$m.Height)/2),(Color 'text-primary'))}finally{$graphics.ReleaseLayout($layout)}
                }elseif($card.Accordion -eq 'card-colors-setting'){
                    Paint-ColorControls $left ($y+66) $col
                }else{
                    $ry=$y+73
                    foreach($radio in [string[][]]@(@('continueSession','Continue previous session'),@('newSession','Start new session and discard unsaved changes'))){
                        Node ('radio-'+$radio[0]) ($left+24) $ry ($col-48) 26 ([FluentAction]::Startup) $radio[0]
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
    foreach($link in [string[][]]@(@('MansfieldPlumbing / JS2PS','https://github.com/MansfieldPlumbing/JS2PS'),@('MansfieldPlumbing / QuickPS','https://github.com/MansfieldPlumbing/QuickPS'))){Label $link[0] $left $y $col (Color 'text-link') 13;Node ('link-'+$y) $left $y $col 20 ([FluentAction]::Link) $link[1];$y+=27}
    $y+=24
    if($ui.AppearanceError){Label $ui.AppearanceError $left $y $col '#e57a88' 12;$y+=40}
    if($ui.PersistError){Label $ui.PersistError $left $y $col '#e57a88' 12;$y+=40}
    $ui.SettingsExtent=$y+60+$ui.SettingsScroll-40
    $graphics.Unclip();$ui.HitClip=$null
    if($ui.SettingsExtent -gt $h-40){$track=$h-46;$thumb=[Math]::Max(24,$track*($h-40)/$ui.SettingsExtent);$ty=43+($track-$thumb)*$ui.SettingsScroll/[Math]::Max(1,$ui.SettingsExtent-$h+40);$graphics.Fill(($w-9),$ty,6,$thumb,'rgba(255,255,255,0.2)',3)}
}
function Paint-Dropdown {
    if(-not $ui.Dropdown){return}
    $drop=$ui.Dropdown;$r=$drop.Rect;$height=$drop.Options.Count*28+8;$y=$r[1]+$r[3]+2
    if($y+$height -gt $ui.Height-8){$y=[Math]::Max(42,$r[1]-$height-2)}
    [string]$current=if($drop.Key -eq 'pickerMode'){$ui.ColorPicker.Mode}else{$settings.Get($drop.Key)}
    $rows=[Collections.Generic.List[NotepadMenuRow]]::new()
    foreach($option in $drop.Options){$rows.Add([NotepadMenuRow]@{Text=$option.Text;Action=[FluentAction]::ChooseSetting;Data=[NotepadSettingChoice]@{Key=$drop.Key;Value=$option.Value};Checked=($current -eq $option.Value)})}
    Paint-MenuRows $rows.ToArray() $r[0] $y ([Math]::Max(160,$r[2])) ('dropdown-'+$drop.Key)
}
function Paint-Modal {
    if(-not $ui.Modal){return}
    $m=$ui.Modal;$width=[Math]::Min(440,$ui.Width*0.9);$bodyWidth=$width-48
    $messageLayout=$graphics.Layout($m.Message,'Segoe UI',(13*$ui.TextScale),$bodyWidth,$true,400,$false,(19.5*$ui.TextScale))
    try{$messageHeight=if($m.Message){($graphics.Metrics($messageLayout)).Height}else{0}
        $height=24+25.2+16+$messageHeight+16+34+24+8
        if($m.Input){$height+=54};if($null -ne $m.Markdown){$height+=[Math]::Min(380,[Math]::Max(60,($m.Markdown.Split("`n").Count*23+24)))}
        $height=[Math]::Min($height,$ui.Height-40);$x=($ui.Width-$width)/2;$y=($ui.Height-$height)/2
        $graphics.Fill(0,0,$ui.Width,$ui.Height,'rgba(0,0,0,0.5)',0);Node 'notepad-modal' 0 0 $ui.Width $ui.Height ([FluentAction]::None) $null 'default'
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
                # A heading: one to three # and a space, then its text.
                $hashes=0;while($hashes -lt $line.Length -and $line[$hashes] -eq '#'){$hashes++}
                if($hashes -ge 1 -and $hashes -le 3 -and $hashes -lt $line.Length -and $line[$hashes] -eq ' '){$size=switch($hashes){1{28};2{21};3{16.38}};$weight=700;$content=$line.Substring($hashes+1)}
                Label $content ($x+36) $my ($bodyWidth-24) (Color 'text-primary') $size 'Segoe UI' $weight;$my+=$size*1.4
            }
            $graphics.Unclip()
        }
        $total=0;foreach($button in $m.Buttons){$total+=[Math]::Max(66,$button.Text.Length*7+32)+8}
        $bx=$x+$width-24-$total+8;$buttonIndex=0
        foreach($button in $m.Buttons){$bw=[Math]::Max(66,$button.Text.Length*7+32);Button ('modal-button-'+$buttonIndex) $bx ($y+$height-58) $bw 34 ([FluentAction]::ModalAction) $button.Text '' $button ([bool]$button.Primary) $true;$bx+=$bw+8;$buttonIndex++}
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
    Node 'picker-background' $x $y $width $height ([FluentAction]::None) $null 'default'
    $oldClip=$ui.HitClip;$ui.HitClip=@($x,$y,$width,$height);$graphics.Clip($x,$y,$width,$height)
    $oy=$y-$p.Scroll;$sx=$x+16;$sy=$oy+16;$size=256.0
    $p.SpectrumRect=@($sx,$sy,$size,$size)
    $graphics.ColorSpectrum($sx,$sy,$size);Node 'picker-spectrum' $sx $sy $size $size ([FluentAction]::PickerSpectrum)
    $graphics.Fill(($sx+$size+12),$sy,44,$size,$p.Hex,4)
    $mx=$sx+$p.H/360*$size;$my=$sy+(1-$p.S)*$size
    $graphics.Circle($mx,$my,7,'#ffffff',2);$graphics.Circle($mx,$my,8,'rgba(0,0,0,0.65)',1)
    $vx=$x+16;$vy=$oy+300;$vw=$width-32;$p.ValueRect=@($vx,$vy,$vw,16)
    $pure=Convert-HsvToHex $p.H $p.S 1
    $graphics.FourCorner($vx,$vy,$vw,12,[string[]]@('#000000',$pure,'#000000',$pure),1)
    Node 'picker-value' $vx ($vy-6) $vw 26 ([FluentAction]::PickerValue)
    $graphics.Circle(($vx+$vw*$p.V),($vy+6),7,(Color 'bg-control'),0);$graphics.Circle(($vx+$vw*$p.V),($vy+6),5,'#ffffff',0)
    $p.ModeRect=@(($x+16),($oy+328),120,36);Button 'picker-mode' ($x+16) ($oy+328) 120 36 ([FluentAction]::PickerMode) '' '' $null $false $true
    Label $p.Mode ($x+28) ($oy+337) 80 (Color 'text-primary') 16;Icon 'chevronDown' ($x+112) ($oy+341) 10
    InputBox 'picker-input-hex' $p.Inputs['hex']($x+196) ($oy+328) 132 '' 36 16
    [string[]]$labels=if($p.Mode -eq 'RGB'){@('Red','Green','Blue')}else{@('Hue','Saturation','Value')}
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
    $ui.NextHits=[Collections.Generic.List[NotepadHitNode]]::new()
    $graphics.Begin((Color 'bg-window'),$(if($ui.BackdropActive){[single]0}else{[single]1}))
    if($settings.gradientEnabled){$graphics.FourCorner(0,0,$ui.Width,$ui.Height,[string[]]@($settings.colors.topLeft,$settings.colors.topRight,$settings.colors.bottomLeft,$settings.colors.bottomRight),[single]([int]$settings.gradientStrength/100.0))}
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
# Kinetic selection: while a selection drag holds the pointer past the gate's top or bottom edge, the text keeps
# scrolling, 4 lines a second at the edge and faster the further past it (about 40 at 100 px), and the selection
# follows to the edge line. Called every pass of the main loop, since a still pointer sends no messages.
function Step-DragScroll([datetime]$Instant){
    $edgeTop=$ui.EditorRect[1];$edgeBottom=$edgeTop+$ui.EditorRect[3]
    $past=if($ui.DragY -lt $edgeTop){$ui.DragY-$edgeTop}elseif($ui.DragY -gt $edgeBottom){$ui.DragY-$edgeBottom}else{0.0}
    $stepSeconds=[Math]::Min(0.1,($Instant-$ui.DragTick).TotalSeconds);$ui.DragTick=$Instant
    if($past -eq 0){return}
    $tab=$model.Active();$tab.ScrollY=[Math]::Max(0,$tab.ScrollY+[Math]::Sign($past)*(4+[Math]::Abs($past)*0.36)*$stepSeconds)
    Editor-Hit $ui.DragX ([Math]::Clamp($ui.DragY,$edgeTop+1,$edgeBottom-1)) $true
    $ui.EnsureCaret=$false
}

# A point in the editor to a text position, through the line of the last frame's gate under it (the last line when
# the point is below them all).
function Editor-Hit([double]$X,[double]$Y,[bool]$Extend=$false){
    $tab=$model.Active();$position=$tab.Focus
    if($null -ne $ui.GateLines -and $ui.GateLines.Count){
        [NotepadGateLine]$under=$ui.GateLines[$ui.GateLines.Count-1]
        foreach($gateLine in $ui.GateLines){if($Y -lt $gateLine.Top+$gateLine.Height){$under=$gateLine;break}}
        $hit=$graphics.HitText($under.Layout,($X-$ui.EditorOrigin[0]),[Math]::Max(0,$Y-$under.Top))
        $position=$under.Start+[Math]::Min($hit.Position,$under.Length)
    }
    $anchor=if($Extend){$tab.Anchor}else{$position};$model.Select($anchor,$position);$ui.Focus='editor-area';Invalidate $true
}
function Key-Input([NotepadWindowEvent]$Event){
    $key=[int]$Event.W;$ctrl=$Event.Ctrl;$shift=$Event.Shift
    if($key -eq 27){if($ui.Dropdown){$ui.Dropdown=$null}elseif($ui.ColorPicker){$ui.ColorPicker=$null;$ui.Focus='settings';Persist}elseif($ui.Modal){$ui.Modal=$null;$ui.Focus='editor-area'}elseif($ui.Menu){$ui.Menu='';$ui.Submenu=''}elseif($ui.Find){$ui.Find=$false;$state.Find.Open=$false;$ui.Focus='editor-area'}elseif($ui.Settings){$ui.Settings=$false;$ui.Focus='editor-area'};Invalidate;return}
    if($ui.ColorPicker -and $key -eq 9){$fields=@('picker-input-hex','picker-input-c0','picker-input-c1','picker-input-c2');$index=[array]::IndexOf($fields,$ui.Focus);$index=($index+$(if($shift){3}else{1}))%4;Focus-Input $fields[$index];Invalidate;return}
    if($ui.Focus -eq 'opacity-slider' -and $key -in @(37,39,36,35,33,34)){
        # The focused slider's setting: Home 0, End 100, arrows by 1, Page Up and Down by 10.
        $sliderValue=[int]$settings.Get($ui.SliderKey)
        $settings.Set($ui.SliderKey,[int]$(switch($key){36{0};35{100};37{[Math]::Max(0,$sliderValue-1)};39{[Math]::Min(100,$sliderValue+1)};33{[Math]::Min(100,$sliderValue+10)};34{[Math]::Max(0,$sliderValue-10)}}))
        Persist;Invalidate;return
    }
    if($ui.Modal -and $ui.Focus -ne 'dialog-input'){
        if($key -eq 13){$button=$null;foreach($candidate in $ui.Modal.Buttons){if($candidate.Primary){$button=$candidate;break}};if(-not $button){$button=$ui.Modal.Buttons[0]};$ui.Modal=$null;Command $button.Action $button.Data};return
    }
    if($ui.Focus -in @('find-query-input','replace-query-input','dialog-input') -or ($ui.ColorPicker -and $ui.Focus.StartsWith('picker-input-'))){
        $value=Input-Value $ui.Focus
        if($ctrl -and $key -eq 65){$ui.InputAnchor=0;$ui.InputFocus=$value.Length}
        elseif($ctrl -and $key -eq 86){Input-Insert ([Win32Clipboard]::ReadText($window.Handle()))}
        elseif($ctrl -and $key -in @(67,88)){$start=[Math]::Min($ui.InputAnchor,$ui.InputFocus);$len=[Math]::Abs($ui.InputFocus-$ui.InputAnchor);[Win32Clipboard]::WriteText($window.Handle(),$value.Substring($start,$len));if($key -eq 88){Input-Insert ''}}
        elseif($key -in @(8,46)){
            if($ui.InputAnchor -eq $ui.InputFocus){if($key -eq 8 -and $ui.InputFocus -gt 0){$ui.InputAnchor--}elseif($key -eq 46 -and $ui.InputFocus -lt $value.Length){$ui.InputAnchor++}}
            Input-Insert ''
        }elseif($key -in @(37,39,36,35)){
            $pos=switch($key){37{[Math]::Max(0,$ui.InputFocus-1)};39{[Math]::Min($value.Length,$ui.InputFocus+1)};36{0};35{$value.Length}};$ui.InputFocus=$pos;if(-not $shift){$ui.InputAnchor=$pos}
        }elseif($key -eq 13){if($ui.ColorPicker){if(-not $ui.ColorPicker.Invalid){$ui.ColorPicker=$null;$ui.Focus='settings';Persist}}elseif($ui.Focus -eq 'dialog-input'){$m=$ui.Modal;$ui.Modal=$null;$button=$null;foreach($candidate in $m.Buttons){if($candidate.Primary){$button=$candidate;break}};Command $button.Action $m.Value}elseif($shift){$model.SelectMatch(-1)}else{$model.SelectMatch(1)}}
        elseif($key -eq 9){if($ui.Focus -eq 'find-query-input' -and $ui.Replace){Focus-Input 'replace-query-input'}else{$ui.Focus='editor-area'}}
        Invalidate $true;return
    }
    if($ctrl){
        if($settings.formatting -and $key -in @(66,73,75) -or ($ctrl -and $shift -and $key -eq 88)){$action=switch($key){66{[FluentAction]::FormatBold};73{[FluentAction]::FormatItalic};75{[FluentAction]::FormatLink};88{[FluentAction]::FormatStrike}};Command $action;return}
        $action=switch($key){78{if($shift){[FluentAction]::NewActivity}else{[FluentAction]::NewTab}};79{[FluentAction]::OpenFile};83{if($Event.Alt){[FluentAction]::SaveAll}elseif($shift){[FluentAction]::SaveAs}else{[FluentAction]::Save}};87{if($shift){[FluentAction]::CloseWindow}else{[FluentAction]::CloseTab}};70{[FluentAction]::Find};72{[FluentAction]::Replace};71{[FluentAction]::GoTo};80{[FluentAction]::Print};65{[FluentAction]::SelectAll};67{[FluentAction]::Copy};88{[FluentAction]::Cut};86{[FluentAction]::Paste};90{if($shift){[FluentAction]::Redo}else{[FluentAction]::Undo}};89{[FluentAction]::Redo};187{[FluentAction]::ZoomIn};107{[FluentAction]::ZoomIn};189{[FluentAction]::ZoomOut};109{[FluentAction]::ZoomOut};48{[FluentAction]::ZoomReset}}
        if($action){Command $action;return}
    }
    if($key -eq 114){Command $(if($shift){[FluentAction]::FindPrevious}else{[FluentAction]::FindNext});return}
    if($key -eq 116){Command ([FluentAction]::TimeDate);return}
    if($ui.Focus -ne 'editor-area' -or $ui.Settings){return}
    switch($key){
        8{$model.Delete($true)};46{$model.Delete($false)}
        37{$model.Move('left',$shift,$ctrl)};39{$model.Move('right',$shift,$ctrl)}
        36{$model.Move('home',$shift,$ctrl)};35{$model.Move('end',$shift,$ctrl)}
        {$_ -in @(38,40,33,34)}{
            # Up and Down move a wrapped row within the line, then into the neighbouring line; Page Up and Down move
            # the caret and the gate by the gate's height in lines. Each lays out only the lines it touches.
            $tab=$model.Active();Update-LineStarts $tab;$starts=$ui.LineStarts
            $line=Get-LineIndex $tab.Focus;$layout=Get-LineLayout (Get-LineText $line)
            $caret=$graphics.Caret($layout,[uint32]($tab.Focus-$starts[$line]),$false);$position=$tab.Focus
            if($key -in @(33,34)){
                $step=[Math]::Max(1,$(if($null -ne $ui.GateLines){$ui.GateLines.Count}else{1})-1);if($key -eq 33){$step=-$step}
                $target=[Math]::Clamp($line+$step,0,$starts.Length-1);$tab.ScrollY=[Math]::Clamp($tab.ScrollY+$step,0,$starts.Length-1)
                $hit=$graphics.HitText((Get-LineLayout (Get-LineText $target)),$caret.X,1);$position=$starts[$target]+$hit.Position
            }else{
                $rowY=$caret.Y+$caret.Height/2+$(if($key -eq 38){-$caret.Height}else{$caret.Height})
                if($rowY -ge 0 -and $rowY -lt $graphics.Metrics($layout).Height){$hit=$graphics.HitText($layout,$caret.X,$rowY);$position=$starts[$line]+$hit.Position}
                elseif($key -eq 38 -and $line -gt 0){$above=Get-LineLayout (Get-LineText ($line-1));$hit=$graphics.HitText($above,$caret.X,($graphics.Metrics($above).Height-1));$position=$starts[$line-1]+$hit.Position}
                elseif($key -eq 40 -and $line+1 -lt $starts.Length){$hit=$graphics.HitText((Get-LineLayout (Get-LineText ($line+1))),$caret.X,1);$position=$starts[$line+1]+$hit.Position}
            }
            $model.Select($(if($shift){$tab.Anchor}else{$position}),$position)
        }
    }
    # Only a key that edits or moves the caret brings the caret into view; Shift, Ctrl, Alt and the like only repaint.
    Invalidate ($key -in @(8,46,37,39,36,35,38,40,33,34))
}
function Handle-Event([NotepadWindowEvent]$Event){
    if($Event.Kind -eq 'minimized'){$ui.Minimized=$true;Write-ApplicationDiagnostic;return}
    if($Event.Kind -eq 'close'){Request-Close;return}
    if($Event.Kind -eq 'paint'){Invalidate;return}
    if($Event.Kind -eq 'settingChange'){$ui.TextScale=[NotepadWindow]::TextScaleFactor();Resolve-Theme;Apply-WindowAppearance;Invalidate;return}
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
        elseif($Event.Ctrl){Command $(if($delta -gt 0){[FluentAction]::ZoomIn}else{[FluentAction]::ZoomOut})}
        elseif($ui.Settings){$ui.SettingsScroll=[Math]::Clamp($ui.SettingsScroll-$delta/120*72,0,[Math]::Max(0,$ui.SettingsExtent-$ui.Height+40));Invalidate}
        elseif(-not $ui.Modal){$tab=$model.Active();$tab.ScrollY=[Math]::Max(0,$tab.ScrollY-$delta/120*3);$ui.EnsureCaret=$false;Invalidate}
        $ui.ScrollSequence++;Invalidate;return
    }
    [NotepadHitNode]$hit=Hit $x $y;$id=if($hit){$hit.Id}else{''}
    # The right button acts on release: on the window icon it steps the icon back.
    if($msg -eq 0x204){return}
    if($msg -eq 0x205){if($hit -and $hit.Action -eq [FluentAction]::CycleIcon){Step-WindowIcon -1};return}
    if($msg -eq 0x200){
        if($ui.ColorDrag){Set-ColorPickerPoint $ui.ColorDrag $x $y;return}
        if($ui.ScrollDrag){Set-ScrollFromPoint $y;return}
        if($ui.SliderDrag){Set-SliderFromPoint $x;return}
        if($ui.Hover -ne $id){$ui.Hover=$id;$ui.HoverSince=[DateTime]::UtcNow;$ui.TooltipShown=$false;Invalidate
            if($hit -and $hit.Action -eq [FluentAction]::Submenu){$ui.Submenu=$hit.Data;Invalidate}
            if($ui.Menu -and $id.StartsWith('menu-btn-')){$ui.Menu=$hit.Data;$ui.Submenu='';Invalidate}
        }
        $window.Cursor($(if($hit){$hit.Cursor}else{'default'}))
        if($ui.Drag){$ui.DragX=$x;$ui.DragY=$y;Editor-Hit $x $y $true}
        return
    }
    if($msg -in @(0x201,0x203)){
        if($ui.ColorPicker -and -not $id.StartsWith('picker-') -and -not $id.StartsWith('dropdown-pickerMode')){$ui.ColorPicker=$null;$ui.Dropdown=$null;$ui.Focus='settings';Invalidate;return}
        if($ui.Dropdown -and -not $id.StartsWith('dropdown-')){$ui.Dropdown=$null;Invalidate;return}
        if($ui.Menu -and -not $id.StartsWith('flyout-') -and -not $id.StartsWith('menu-btn-')){$ui.Menu='';$ui.Submenu='';Invalidate}
        $ui.Pressed=$id;Invalidate
        if($hit -and $hit.Action -in @([FluentAction]::PickerSpectrum,[FluentAction]::PickerValue)){$ui.ColorDrag=if($hit.Action -eq [FluentAction]::PickerSpectrum){'spectrum'}else{'value'};$window.Capture($true);Set-ColorPickerPoint $ui.ColorDrag $x $y;return}
        if($hit -and $hit.Action -eq [FluentAction]::Scrollbar -and $ui.ScrollTrack){
            $scrollTrack=$ui.ScrollTrack;$thumbTop=$scrollTrack[0]+($scrollTrack[1]-$scrollTrack[2])*$model.Active().ScrollY/$scrollTrack[3]
            $ui.ScrollGrab=if($y -ge $thumbTop -and $y -lt $thumbTop+$scrollTrack[2]){$y-$thumbTop}else{$scrollTrack[2]/2}
            $ui.ScrollDrag=$true;$window.Capture($true);Set-ScrollFromPoint $y;return
        }
        if($hit -and $hit.Action -eq [FluentAction]::OpacitySlider){$ui.SliderDrag=$true;$ui.SliderKey=[string]$hit.Data;$ui.Focus='opacity-slider';$window.Capture($true);Set-SliderFromPoint $x;return}
        if($hit -and $hit.Action -eq [FluentAction]::Editor){
            Editor-Hit $x $y $Event.Shift
            if($msg -eq 0x203){$tab=$model.Active();$pos=$tab.Focus;$start=$pos;$end=$pos;while($start -gt 0 -and -not [char]::IsWhiteSpace($tab.At($start-1))){$start--};while($end -lt $tab.Document.Length -and -not [char]::IsWhiteSpace($tab.At($end))){$end++};$model.Select($start,$end)}
            $ui.Drag=$true;$ui.DragX=$x;$ui.DragY=$y;$ui.DragTick=[DateTime]::UtcNow;$window.Capture($true)
        }elseif($hit -and $hit.Action -eq [FluentAction]::Drag){
            # A double-click on the title bar maximizes or restores, as on any Windows title bar; a single press drags.
            if($msg -eq 0x203){$window.Caption([FluentWindowDecoration]::Maximize)}else{$window.Caption([FluentWindowDecoration]::Drag)}
        }
        return
    }
    if($msg -eq 0x202){
        if($ui.ColorDrag){Set-ColorPickerPoint $ui.ColorDrag $x $y;$ui.ColorDrag='';$ui.Pressed='';$window.Capture($false);$ui.ClickSequence++;Persist;Invalidate;return}
        if($ui.ScrollDrag){$ui.ScrollDrag=$false;$ui.Pressed='';$window.Capture($false);Invalidate;return}
        if($ui.SliderDrag){Set-SliderFromPoint $x;$ui.SliderDrag=$false;$ui.Pressed='';$window.Capture($false);$ui.ClickSequence++;Persist;Invalidate;return}
        if($ui.Drag){$ui.Drag=$false;$window.Capture($false)}
        if($hit -and $id -eq $ui.Pressed -and $hit.Action -notin @([FluentAction]::Editor,[FluentAction]::Drag)){
            if($hit.Action -eq [FluentAction]::ModalAction){[NotepadModalButton]$button=$hit.Data;$value=$ui.Modal.Value;$ui.Modal=$null;Command $button.Action $(if($button.Action -in @([FluentAction]::GotoConfirm,[FluentAction]::InsertLink)){$value}else{$button.Data})}
            else{if($id.StartsWith('flyout-') -and $hit.Action -ne [FluentAction]::Submenu){$ui.Menu='';$ui.Submenu=''};Command $hit.Action $hit.Data}
        }
        $ui.Pressed='';$ui.ClickSequence++;Invalidate
    }
}

Resolve-Theme
try{
    $window=Invoke-Window.Windows -Width $Width -Height $Height
    if($placement){$window.Place($placement)}
    # A window opening maximized fills its monitor at once; the entrance moves a restored window.
    [bool]$animateEntrance=-not $NoAnimation -and -not ($placement -and $placement.Maximized)
    $info=$window.Info();$ui.Dpi=$info.Dpi;$ui.Width=$info.Width*96/$info.Dpi;$ui.Height=$info.Height*96/$info.Dpi;$ui.TextScale=[NotepadWindow]::TextScaleFactor()
    $graphics=Invoke-Graphics.Windows -Hwnd $window.Handle() -Width $info.Width -Height $info.Height -Dpi $info.Dpi
    
    Apply-WindowAppearance
    Apply-WindowIcon
    if($animateEntrance){$ui.BackdropActive=$false}
    if($animateEntrance){$ui.Entrance=$window.BeginEntrance(($settings.entranceAnimation -eq 'slide'));$initialEntrance=$window.Entrance(0);$null=Entrance-Easing 0.5}
    # Paint the entire first frame before the HWND becomes visible.
    Paint
    # A hidden PowerShell host can override the first ShowWindow call through STARTUPINFO.
    $window.Show();$window.Show();$start=[DateTime]::UtcNow
    foreach($event in @($window.Drain())){Handle-Event $event}
    if($animateEntrance){$ui.EntranceStatus='Animating';$ui.EntranceStart=[DateTime]::UtcNow;$initialEntrance.ElapsedMs=0;$initialEntrance.TimeProgress=0;$ui.EntranceSamples.Add($initialEntrance)}
    else{$ui.EntranceStatus='Skipped'}
    while($ui.Running -and $window.Info().Alive){
        foreach($event in @($window.Drain())){Handle-Event $event}
        $now=[DateTime]::UtcNow
        if($ui.Drag -and $ui.EditorRect){Step-DragScroll $now}
        if($ui.Hover -eq 'btn-copy-document' -and -not $ui.TooltipShown -and ($now-$ui.HoverSince).TotalMilliseconds -ge 450){$ui.TooltipShown=$true;Invalidate}
        if($ui.EntranceStatus -eq 'Animating'){
          [double]$elapsed=($now-$ui.EntranceStart).TotalMilliseconds;[double]$progress=[Math]::Clamp($elapsed/$ui.Entrance.DurationMs,0.0,1.0)
            $eased=if($progress -ge 1){1.0}else{Entrance-Easing $progress}
            $sample=$window.Entrance($eased);$sample.ElapsedMs=$elapsed;$sample.TimeProgress=$progress
            $ui.EntranceSamples.Add($sample)
            if($progress -ge 1){$ui.EntranceRestore=$window.EndEntrance();Apply-WindowAppearance;$ui.EntranceStatus='Completed';Invalidate}
        }
        if(($now-$ui.LastBlink).TotalMilliseconds -ge 530){$ui.Blink=-not $ui.Blink;$ui.LastBlink=$now;if($ui.Focus -in @('editor-area','find-query-input','replace-query-input','dialog-input')){Invalidate}}
        if($ui.Dirty -and -not $ui.Minimized -and $ui.Width -gt 0 -and $ui.Height -gt 0 -and $ui.EntranceStatus -ne 'Animating'){Paint}
        if(($now-$ui.LastSession).TotalSeconds -ge 2){Persist;$ui.LastSession=$now}
        if($RunSeconds -gt 0 -and ($now-$start).TotalSeconds -ge $RunSeconds){$ui.Running=$false}
        [Threading.Thread]::Sleep(8)
    }
    Persist
}catch{
    throw
}finally{
    Write-ApplicationDiagnostic
    if($graphics){$graphics.Dispose()};if($window){$window.Dispose()}
}
