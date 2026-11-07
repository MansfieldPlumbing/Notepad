[CmdletBinding()]
param(
    [string]$Path,[int]$Width=1280,[int]$Height=720,[switch]$NoSession,[int]$RunSeconds=0,[string]$DiagnosticPath,
    [switch]$Compare,[string]$EvidenceDirectory=(Join-Path $PSScriptRoot 'evidence'),
    [switch]$RefreshReal,[switch]$SkipBrowser,[switch]$KeepProbeOpen,
    [switch]$ExtractTypeScript,[switch]$BuildTypeScript,[switch]$BuildDesign,[switch]$VerifyNativeFeatures,[switch]$CatalogIcons,
    [ValidateSet('editor','settings','comparison')][string]$StartPage='editor',
    [ValidateSet('mica','acrylic','reverseMica')][string]$Backdrop,
    [ValidateSet('curved','straight')][string]$CornerStyle,[switch]$NoAnimation,
    [switch]$VerifyModel,[switch]$VerifyGraphics
)

# Folded from src\Model.ps1
function Invoke-Model {
[CmdletBinding()]
param([hashtable]$Settings=@{})
if($MyInvocation.InvocationName -eq '.'){throw 'Invoke Model.ps1 with &.'}
New-Module -AsCustomObject -ArgumentList $Settings -ScriptBlock {
    param($Settings)
    $script:state=@{Settings=$Settings;Tabs=[Collections.Generic.List[object]]::new();ActiveId=0;NextId=1;Find=@{Query='';Replacement='';MatchCase=$false;Wrap=$true;Matches=@();Index=-1}}
    function State {$state}
    function Active {foreach($tab in $state.Tabs){if($tab.Id -eq $state.ActiveId){return $tab}}}
    function NewTab([string]$Title='Untitled',[string]$Text='',[string]$Path=$null,[bool]$Markdown=$false){
        # New documents use Windows line endings. Only an opened LF file selects LF mode.
        $lineEnding=if($Path -and $Text.Contains("`n") -and -not $Text.Contains("`r`n")){'Unix (LF)'}else{'Windows (CRLF)'}
        $tab=@{Id=$state.NextId++;Title=$Title;Text=$Text.Replace("`r`n","`n").Replace("`r","`n");Path=$Path;Markdown=$Markdown;LineEnding=$lineEnding;Encoding='UTF-8';Bom=$false;Modified=$false;Revision=0;Anchor=0;Focus=0;ScrollX=0.0;ScrollY=0.0;Undo=[Collections.Generic.Stack[object]]::new();Redo=[Collections.Generic.Stack[object]]::new();LastEdit=[datetime]::MinValue}
        $state.Tabs.Add($tab);$state.ActiveId=$tab.Id
        $tab
    }
    function SwitchTab([int]$Id){if(@($state.Tabs|Where-Object Id -eq $Id).Count){$state.ActiveId=$Id;Find}}
    function CloseTab([int]$Id){
        for($i=0;$i -lt $state.Tabs.Count;$i++){if($state.Tabs[$i].Id -eq $Id){$state.Tabs.RemoveAt($i);if($state.ActiveId -eq $Id -and $state.Tabs.Count){$state.ActiveId=$state.Tabs[[Math]::Max(0,$i-1)].Id};break}}
        if(-not $state.Tabs.Count){$null=NewTab};Find
    }
    function Snapshot($Tab){@{Text=$Tab.Text;Anchor=$Tab.Anchor;Focus=$Tab.Focus}}
    function Select-Range([int]$Anchor,[int]$Focus){$tab=Active;$tab.Anchor=[Math]::Clamp($Anchor,0,$tab.Text.Length);$tab.Focus=[Math]::Clamp($Focus,0,$tab.Text.Length)}
    function Select([int]$Anchor,[int]$Focus){Select-Range $Anchor $Focus}
    function Insert([string]$Text,[bool]$Coalesce=$false){
        $tab=Active;$start=[Math]::Min($tab.Anchor,$tab.Focus);$end=[Math]::Max($tab.Anchor,$tab.Focus)
        if(-not $Coalesce -or ([DateTime]::UtcNow-$tab.LastEdit).TotalMilliseconds -gt 700 -or $start -ne $end){$tab.Undo.Push((Snapshot $tab))}
        $tab.Redo.Clear();$Text=$Text.Replace("`r`n","`n").Replace("`r","`n")
        $tab.Text=$tab.Text.Substring(0,$start)+$Text+$tab.Text.Substring($end)
        $tab.Focus=$start+$Text.Length;$tab.Anchor=$tab.Focus;$tab.Modified=$true;$tab.Revision++;$tab.LastEdit=[DateTime]::UtcNow
        Find
    }
    function Boundary([string]$Text,[int]$Position,[int]$Direction){
        $offsets=[Globalization.StringInfo]::ParseCombiningCharacters($Text)
        if($Direction -lt 0){for($i=$offsets.Length-1;$i -ge 0;$i--){if($offsets[$i] -lt $Position){return $offsets[$i]}};return 0}
        foreach($offset in $offsets){if($offset -gt $Position){return $offset}};$Text.Length
    }
    function Delete([bool]$Backspace){
        $tab=Active
        if($tab.Anchor -eq $tab.Focus){$other=Boundary $tab.Text $tab.Focus $(if($Backspace){-1}else{1});if($other -eq $tab.Focus){return};$tab.Anchor=$other}
        Insert ''
    }
    function Undo([bool]$Redo=$false){
        $tab=Active;$from=$tab.Undo;$to=$tab.Redo;if($Redo){$from=$tab.Redo;$to=$tab.Undo}
        if(-not $from.Count){return};$to.Push((Snapshot $tab));$saved=$from.Pop();$tab.Text=$saved.Text;$tab.Anchor=$saved.Anchor;$tab.Focus=$saved.Focus;$tab.Modified=$true;$tab.Revision++;$tab.LastEdit=[DateTime]::MinValue;Find
    }
    function Move([string]$Direction,[bool]$Extend=$false,[bool]$Word=$false){
        $tab=Active;$pos=$tab.Focus
        if($Direction -eq 'left' -and -not $Extend -and $tab.Anchor -ne $pos){$pos=[Math]::Min($tab.Anchor,$pos)}
        elseif($Direction -eq 'right' -and -not $Extend -and $tab.Anchor -ne $pos){$pos=[Math]::Max($tab.Anchor,$pos)}
        else{switch($Direction){
            'left'{$pos=Boundary $tab.Text $pos -1;if($Word){while($pos -gt 0 -and [char]::IsWhiteSpace($tab.Text[$pos])){$pos=Boundary $tab.Text $pos -1};while($pos -gt 0 -and -not [char]::IsWhiteSpace($tab.Text[$pos-1])){$pos=Boundary $tab.Text $pos -1}}}
            'right'{$pos=Boundary $tab.Text $pos 1;if($Word){while($pos -lt $tab.Text.Length -and -not [char]::IsWhiteSpace($tab.Text[$pos])){$pos=Boundary $tab.Text $pos 1};while($pos -lt $tab.Text.Length -and [char]::IsWhiteSpace($tab.Text[$pos])){$pos=Boundary $tab.Text $pos 1}}}
            'home'{$pos=if($Word){0}else{$tab.Text.LastIndexOf("`n",[Math]::Max(0,$pos-1))+1};if($tab.Focus -eq 0){$pos=0}}
            'end'{$pos=if($Word){$tab.Text.Length}else{$p=$tab.Text.IndexOf("`n",$pos);if($p -lt 0){$tab.Text.Length}else{$p}}}
        }}
        $tab.Focus=$pos;if(-not $Extend){$tab.Anchor=$pos};$tab.LastEdit=[DateTime]::MinValue
    }
    function Status {
        $tab=Active;$start=[Math]::Min($tab.Anchor,$tab.Focus);$before=$tab.Text.Substring(0,$start);$lines=$before.Split("`n")
        @{Line=$lines.Length;Column=$lines[-1].Length+1;Characters=$tab.Text.Length;Selected=[Math]::Abs($tab.Focus-$tab.Anchor)}
    }
    function Find {
        $tab=Active;if(-not $tab){return};$find=$state.Find;$find.Matches=@();$find.Index=-1
        if(-not $find.Query){return}
        $comparison=if($find.MatchCase){[StringComparison]::Ordinal}else{[StringComparison]::OrdinalIgnoreCase}
        $positions=[Collections.Generic.List[object]]::new();$offset=0
        while($offset -le $tab.Text.Length-$find.Query.Length){$index=$tab.Text.IndexOf($find.Query,$offset,$comparison);if($index -lt 0){break};$positions.Add(@{Start=$index;End=$index+$find.Query.Length});$offset=$index+$find.Query.Length}
        $find.Matches=$positions.ToArray()
        if($positions.Count){$find.Index=0;for($i=0;$i -lt $positions.Count;$i++){if($positions[$i].Start -ge [Math]::Min($tab.Anchor,$tab.Focus)){$find.Index=$i;break}}}
    }
    function SelectMatch([int]$Step=0){
        $find=$state.Find;if(-not $find.Matches.Count){Find};if(-not $find.Matches.Count){return}
        $next=$find.Index+$Step
        if($find.Wrap){$next=($next+$find.Matches.Count)%$find.Matches.Count}elseif($next -lt 0 -or $next -ge $find.Matches.Count){return}
        $find.Index=$next;$match=$find.Matches[$next];Select-Range $match.Start $match.End
    }
    function Replace([bool]$All=$false){
        $find=$state.Find;if(-not $find.Query){return}
        if($All){Find;$tab=Active;$text=$tab.Text;for($i=$find.Matches.Count-1;$i -ge 0;$i--){$m=$find.Matches[$i];$text=$text.Substring(0,$m.Start)+$find.Replacement+$text.Substring($m.End)};if($find.Matches.Count){Select-Range 0 $tab.Text.Length;Insert $text}}
        elseif($find.Matches.Count){$m=$find.Matches[$find.Index];Select-Range $m.Start $m.End;Insert $find.Replacement;SelectMatch}
    }
    function Save([int]$Id,[string]$Path){
        $tab=$state.Tabs|Where-Object Id -eq $Id|Select-Object -First 1
        if(-not $tab){throw "Unknown document $Id"}
        $text=$tab.Text;if($tab.LineEnding -eq 'Windows (CRLF)'){$text=$text.Replace("`n","`r`n")}
        $fullPath=[IO.Path]::GetFullPath($Path)
        # Write a sibling temporary file first, then replace the destination. A
        # failed write cannot mark a document clean or truncate the old contents.
        $temporary=Join-Path ([IO.Path]::GetDirectoryName($fullPath)) ('.notepad-'+[Guid]::NewGuid().ToString('N')+'.tmp')
        try{[IO.File]::WriteAllText($temporary,$text,[Text.UTF8Encoding]::new([bool]$tab.Bom));[IO.File]::Move($temporary,$fullPath,$true)}
        finally{if([IO.File]::Exists($temporary)){[IO.File]::Delete($temporary)}}
        $tab.Path=$fullPath;$tab.Title=[IO.Path]::GetFileName($fullPath);$tab.Modified=$false
        @{Outcome='Saved';Id=$tab.Id;Path=$fullPath}
    }
    function Open([string]$Path){
        $bytes=[IO.File]::ReadAllBytes($Path)
        $bom=$bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191
        $utf8=[Text.UTF8Encoding]::new($false,$true);$text=$utf8.GetString($bytes).TrimStart([char]0xFEFF)
        $tab=NewTab ([IO.Path]::GetFileName($Path)) $text ([IO.Path]::GetFullPath($Path)) ($Path -match '\.md$');$tab.Bom=$bom
        $tab
    }
    function ExportSession {
        @{NextId=$state.NextId;ActiveId=$state.ActiveId;Tabs=@(foreach($tab in $state.Tabs){@{Id=$tab.Id;Title=$tab.Title;Text=$tab.Text;Path=$tab.Path;Markdown=$tab.Markdown;LineEnding=$tab.LineEnding;Encoding=$tab.Encoding;Bom=$tab.Bom;Modified=$tab.Modified;Anchor=$tab.Anchor;Focus=$tab.Focus;ScrollX=$tab.ScrollX;ScrollY=$tab.ScrollY}})}
    }
    function ImportSession([hashtable]$Session){
        if(-not $Session.Tabs.Count){return};$state.Tabs.Clear();$ids=[Collections.Generic.HashSet[int]]::new()
        foreach($saved in $Session.Tabs){
            if(-not ($saved.Text -is [string]) -or -not $ids.Add([int]$saved.Id)){throw 'Invalid session document'}
            $tab=NewTab $saved.Title $saved.Text $saved.Path $saved.Markdown
            foreach($key in @('Id','LineEnding','Encoding','Bom','Modified','Anchor','Focus','ScrollX','ScrollY')){if($saved.ContainsKey($key)){$tab[$key]=$saved[$key]}}
            $tab.Focus=[Math]::Clamp([int]$tab.Focus,0,$tab.Text.Length);$tab.Anchor=[Math]::Clamp([int]$tab.Anchor,0,$tab.Text.Length)
        }
        $state.NextId=[Math]::Max([int]$Session.NextId,([int]($state.Tabs.Id|Measure-Object -Maximum).Maximum+1))
        $state.ActiveId=$state.Tabs[0].Id;if($ids.Contains([int]$Session.ActiveId)){$state.ActiveId=[int]$Session.ActiveId}
    }
    Export-ModuleMember -Function State,Active,NewTab,SwitchTab,CloseTab,Select,Insert,Delete,Undo,Move,Status,Find,SelectMatch,Replace,Save,Open,ExportSession,ImportSession
}
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
    $model.Select(0,$second.Text.Length);$model.Insert("A😀e$([char]0x301)`nB",$false)
    Assert ($second.Text.Length -eq 7) 'UTF-16 storage mismatch.'
    $model.Select(3,3);$model.Delete($true)
    Assert ($second.Text -ceq "Ae$([char]0x301)`nB") 'Backspace split a surrogate pair.'
    $model.Undo($false)
    Assert ($second.Text -ceq "A😀e$([char]0x301)`nB") 'Undo failed.'
    $model.Undo($true)
    Assert ($second.Text -ceq "Ae$([char]0x301)`nB") 'Redo failed.'
    $model.Select(3,3);$model.Delete($true)
    Assert ($second.Text -ceq "A`nB") 'Backspace split a combining sequence.'
    $model.Select(0,$second.Text.Length);$model.Insert('one ONE one',$false)
    $state.Find.Query='one';$state.Find.Replacement='$literal';$state.Find.MatchCase=$false;$model.Find()
    Assert ($state.Find.Matches.Count -eq 3) 'Case-insensitive find mismatch.'
    $state.Find.MatchCase=$true;$model.Find();Assert ($state.Find.Matches.Count -eq 2) 'Case-sensitive find mismatch.'
    $model.Replace($true)
    Assert ($second.Text -ceq '$literal ONE $literal') 'Literal replace-all mismatch.'
    $model.Select(0,$second.Text.Length);$model.Insert("α`nβ",$false);$second.LineEnding='Windows (CRLF)';$second.Bom=$true
    $secondPath=Join-Path $testDirectory 'second.txt';$null=$model.Save($second.Id,$secondPath)
    $bytes=[IO.File]::ReadAllBytes($secondPath)
    Assert (($bytes[0..2] -join ',') -eq '239,187,191') 'UTF-8 BOM missing.'
    Assert ([IO.File]::ReadAllText($secondPath) -ceq "α`r`nβ") 'CRLF output mismatch.'
    $third=$model.Open($secondPath);Assert ($third.Text -ceq "α`nβ" -and $third.Bom) 'UTF-8 reopen mismatch.'
    $session=$model.ExportSession()|ConvertTo-Json -Depth 16|ConvertFrom-Json -AsHashtable
    $restored=Invoke-Model;$restored.ImportSession($session)
    Assert ($restored.State().Tabs.Count -eq 3) 'Session lost documents.'
    Assert ($restored.Active().Text -ceq "α`nβ") 'Session active document mismatch.'
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
function Invoke-Window.Windows {
[CmdletBinding()]
param([Parameter(Mandatory)][object]$Native,[int]$Width=1280,[int]$Height=720,[string]$Title='Notepad — PowerShell')
if($MyInvocation.InvocationName -eq '.'){throw 'Invoke Window.Windows.ps1 with &.'}
New-Module -AsCustomObject -ArgumentList $Native,$Width,$Height,$Title -ScriptBlock {
    param($Native,$Width,$Height,$Title)
    $script:n=$Native
    $script:events=[Collections.Generic.Queue[object]]::new()
    $script:callbackError=$null
    $script:hwnd=[IntPtr]::Zero
    $script:alive=$true
    $script:focused=$true
    $script:minimized=$false
    $script:windowIcon=[IntPtr]::Zero;$script:ownsWindowIcon=$false
    function Bind([string]$Name,[Type]$Return,[Type[]]$Types,[string]$Library='user32.dll'){$n.GetExportCall($Library,$Name,$Return,$Types)}
    $script:def=Bind 'DefWindowProcW' ([IntPtr]) @([IntPtr],[uint32],[IntPtr],[IntPtr])
    $script:keyState=Bind 'GetKeyState' ([int16]) @([int])
    $script:validate=Bind 'ValidateRect' ([bool]) @([IntPtr],[IntPtr])
    $script:getClient=Bind 'GetClientRect' ([bool]) @([IntPtr],[IntPtr])
    $script:getDpi=Bind 'GetDpiForWindow' ([uint32]) @([IntPtr])
    $script:getRect=Bind 'GetWindowRect' ([bool]) @([IntPtr],[IntPtr])
    $script:show=Bind 'ShowWindow' ([bool]) @([IntPtr],[int])
    $script:setPosition=Bind 'SetWindowPos' ([bool]) @([IntPtr],[IntPtr],[int],[int],[int],[int],[uint32])
    $script:send=Bind 'SendMessageW' ([IntPtr]) @([IntPtr],[uint32],[IntPtr],[IntPtr])
    $script:setCapture=Bind 'SetCapture' ([IntPtr]) @([IntPtr])
    $script:releaseCapture=Bind 'ReleaseCapture' ([bool]) @()
    $script:loadCursor=Bind 'LoadCursorW' ([IntPtr]) @([IntPtr],[IntPtr])
    $script:setCursor=Bind 'SetCursor' ([IntPtr]) @([IntPtr])
    $script:arrow=$loadCursor.DynamicInvoke([IntPtr]::Zero,[IntPtr]32512)
    $script:ibeam=$loadCursor.DynamicInvoke([IntPtr]::Zero,[IntPtr]32513)
    $script:hand=$loadCursor.DynamicInvoke([IntPtr]::Zero,[IntPtr]32649)
    $script:cursor=$arrow
    $script:scratch=$n.Allocate(128)
    # A non-generic emitted delegate provides a rooted, stdcall WNDPROC. Windows
    # invokes it synchronously on this script's STA/message-pumping thread.
    $callbackType=$def.GetType()
    $callbackBlock={
        param([IntPtr]$Handle,[uint32]$Message,[IntPtr]$WParam,[IntPtr]$LParam)
        try{
            switch($Message){
                0x0083 {return [IntPtr]::Zero} # WM_NCCALCSIZE: full client chrome.
                0x0014 {return [IntPtr]1} # suppress GDI background erase.
                0x0024 { # WM_GETMINMAXINFO: keep the native toolbar and settings usable.
                    $scale=[Math]::Max(96,$getDpi.DynamicInvoke($Handle))/96.0
                    [Runtime.InteropServices.Marshal]::WriteInt32($LParam,24,[int][Math]::Ceiling(768*$scale))
                    [Runtime.InteropServices.Marshal]::WriteInt32($LParam,28,[int][Math]::Ceiling(478*$scale))
                    return [IntPtr]::Zero
                }
                0x000F {$null=$validate.DynamicInvoke($Handle,[IntPtr]::Zero);$events.Enqueue(@{Kind='paint'});return [IntPtr]::Zero}
                0x0010 {$events.Enqueue(@{Kind='close'});return [IntPtr]::Zero}
                0x0002 {$script:alive=$false;return [IntPtr]::Zero}
                0x0005 {
                    $script:minimized=$WParam.ToInt64() -eq 1
                    $events.Enqueue(@{Kind=$(if($minimized){'minimized'}else{'resize'})})
                    return [IntPtr]::Zero
                }
                0x0007 {$script:focused=$true;$events.Enqueue(@{Kind='focus'});return [IntPtr]::Zero}
                0x0008 {$script:focused=$false;$events.Enqueue(@{Kind='blur'});return [IntPtr]::Zero}
                0x0020 {if(($LParam.ToInt64() -band 0xffff) -eq 1){$null=$setCursor.DynamicInvoke($cursor);return [IntPtr]1}}
                0x0084 {
                    $null=$getRect.DynamicInvoke($Handle,$scratch)
                    $screenX=[int]($LParam.ToInt64() -band 0xffff);if($screenX -ge 32768){$screenX-=65536}
                    $screenY=[int](($LParam.ToInt64() -shr 16) -band 0xffff);if($screenY -ge 32768){$screenY-=65536}
                    $left=[Runtime.InteropServices.Marshal]::ReadInt32($scratch);$top=[Runtime.InteropServices.Marshal]::ReadInt32($scratch,4)
                    $right=[Runtime.InteropServices.Marshal]::ReadInt32($scratch,8);$bottom=[Runtime.InteropServices.Marshal]::ReadInt32($scratch,12)
                    $border=[Math]::Max(4,6*$getDpi.DynamicInvoke($Handle)/96)
                    $l=$screenX -lt $left+$border;$r=$screenX -ge $right-$border;$t=$screenY -lt $top+$border;$b=$screenY -ge $bottom-$border
                    if($t -and $l){return [IntPtr]13};if($t -and $r){return [IntPtr]14};if($b -and $l){return [IntPtr]16};if($b -and $r){return [IntPtr]17}
                    if($l){return [IntPtr]10};if($r){return [IntPtr]11};if($t){return [IntPtr]12};if($b){return [IntPtr]15}
                    return [IntPtr]1
                }
                0x02E0 {
                    # WM_DPICHANGED lParam points to an ephemeral suggested RECT.
                    $x=[Runtime.InteropServices.Marshal]::ReadInt32($LParam);$y=[Runtime.InteropServices.Marshal]::ReadInt32($LParam,4)
                    $w=[Runtime.InteropServices.Marshal]::ReadInt32($LParam,8)-$x;$h=[Runtime.InteropServices.Marshal]::ReadInt32($LParam,12)-$y
                    $null=$setPosition.DynamicInvoke($Handle,[IntPtr]::Zero,$x,$y,$w,$h,[uint32]0x14)
                    $events.Enqueue(@{Kind='resize'});return [IntPtr]::Zero
                }
            }
            if($Message -in @(0x0200,0x0201,0x0202,0x0203,0x020A,0x0100,0x0102,0x0104)){
                $ctrl=($keyState.DynamicInvoke(0x11) -band 0x8000) -ne 0
                $shift=($keyState.DynamicInvoke(0x10) -band 0x8000) -ne 0
                $alt=($keyState.DynamicInvoke(0x12) -band 0x8000) -ne 0
                $events.Enqueue(@{Kind='input';Message=$Message;W=$WParam.ToInt64();L=$LParam.ToInt64();Ctrl=$ctrl;Shift=$shift;Alt=$alt})
                return [IntPtr]::Zero
            }
        }catch{$script:callbackError=$_}
        return [IntPtr]($def.DynamicInvoke($Handle,$Message,$WParam,$LParam))
    }
    $script:callback=[Management.Automation.LanguagePrimitives]::ConvertTo($callbackBlock,$callbackType)
    $proc=[Runtime.InteropServices.Marshal]::GetFunctionPointerForDelegate($callback)
    $dpiContext=Bind 'SetThreadDpiAwarenessContext' ([IntPtr]) @([IntPtr])
    $script:previousDpi=$dpiContext.DynamicInvoke([IntPtr](-4))
    $appId=[Runtime.InteropServices.Marshal]::StringToHGlobalUni('MansfieldPlumbing.NotepadPS1')
    try{$setAppId=Bind 'SetCurrentProcessExplicitAppUserModelID' ([int]) @([IntPtr]) 'shell32.dll';$null=$setAppId.DynamicInvoke($appId)}finally{[Runtime.InteropServices.Marshal]::FreeHGlobal($appId)}
    $getModule=Bind 'GetModuleHandleW' ([IntPtr]) @([IntPtr]) 'kernel32.dll'
    $script:hmodule=$getModule.DynamicInvoke([IntPtr]::Zero)
    $script:className='NotepadPS_'+[Guid]::NewGuid().ToString('N')
    $script:classPtr=[Runtime.InteropServices.Marshal]::StringToHGlobalUni($className)
    $titlePtr=[Runtime.InteropServices.Marshal]::StringToHGlobalUni($Title)
    [Runtime.InteropServices.Marshal]::WriteInt32($scratch,0,80)
    [Runtime.InteropServices.Marshal]::WriteInt32($scratch,4,0xB) # redraw + double clicks
    [Runtime.InteropServices.Marshal]::WriteIntPtr($scratch,8,$proc)
    [Runtime.InteropServices.Marshal]::WriteIntPtr($scratch,24,$hmodule)
    [Runtime.InteropServices.Marshal]::WriteIntPtr($scratch,40,$arrow)
    [Runtime.InteropServices.Marshal]::WriteIntPtr($scratch,64,$classPtr)
    $register=Bind 'RegisterClassExW' ([uint16]) @([IntPtr])
    if($register.DynamicInvoke($scratch) -eq 0){throw 'RegisterClassExW failed'}
    $create=Bind 'CreateWindowExW' ([IntPtr]) @([uint32],[IntPtr],[IntPtr],[uint32],[int],[int],[int],[int],[IntPtr],[IntPtr],[IntPtr],[IntPtr])
    # A normal top-level app window with our own caption controls, rather than a popup or duplicate native caption.
    try{$script:hwnd=$create.DynamicInvoke([uint32]0x40000,$classPtr,$titlePtr,[uint32]0x000F0000L,100,80,[Math]::Max(768,$Width),[Math]::Max(478,$Height),[IntPtr]::Zero,[IntPtr]::Zero,$hmodule,[IntPtr]::Zero)}
    finally{[Runtime.InteropServices.Marshal]::FreeHGlobal($titlePtr)}
    if($hwnd -eq [IntPtr]::Zero){throw 'CreateWindowExW failed'}
    function Handle {$hwnd}
    function Info {
        $null=$getClient.DynamicInvoke($hwnd,$scratch)
        @{Hwnd=$hwnd;Width=[Runtime.InteropServices.Marshal]::ReadInt32($scratch,8);Height=[Runtime.InteropServices.Marshal]::ReadInt32($scratch,12);Dpi=[single]$getDpi.DynamicInvoke($hwnd);Alive=$alive;Focused=$focused;Minimized=$minimized}
    }
    function Show {$null=$show.DynamicInvoke($hwnd,5)}
    function Appearance([string]$Material,[bool]$Dark,[bool]$Curved){
        # MansfieldPlumbing feature addition; same DWM mechanism as QuickPS Backdrop.ps1.
        $set=Bind 'DwmSetWindowAttribute' ([int]) @([IntPtr],[uint32],[IntPtr],[uint32]) 'dwmapi.dll'
        $get=Bind 'DwmGetWindowAttribute' ([int]) @([IntPtr],[uint32],[IntPtr],[uint32]) 'dwmapi.dll'
        $extend=Bind 'DwmExtendFrameIntoClientArea' ([int]) @([IntPtr],[IntPtr]) 'dwmapi.dll'
        $value=$n.Allocate(16)
        try{
            $materialValue=switch($Material){'mica'{2};'acrylic'{3};'reverseMica'{4};default{1}}
            [Runtime.InteropServices.Marshal]::WriteInt32($value,$materialValue)
            $hr=$set.DynamicInvoke($hwnd,[uint32]38,$value,[uint32]4)
            if($hr -lt 0){throw "DWM backdrop failed: $hr"}
            $null=$get.DynamicInvoke($hwnd,[uint32]38,$value,[uint32]4)
            $observed=[Runtime.InteropServices.Marshal]::ReadInt32($value)
            if($observed -ne $materialValue){throw 'DWM did not retain the requested backdrop.'}
            [Runtime.InteropServices.Marshal]::WriteInt32($value,[int]$Dark);$null=$set.DynamicInvoke($hwnd,[uint32]20,$value,[uint32]4)
            [Runtime.InteropServices.Marshal]::WriteInt32($value,-2);$null=$set.DynamicInvoke($hwnd,[uint32]34,$value,[uint32]4) # DWMWA_COLOR_NONE: no white outline
            $null=$get.DynamicInvoke($hwnd,[uint32]34,$value,[uint32]4);$borderColor=[Runtime.InteropServices.Marshal]::ReadInt32($value)
            [Runtime.InteropServices.Marshal]::WriteInt32($value,$(if($Curved){2}else{1}));$null=$set.DynamicInvoke($hwnd,[uint32]33,$value,[uint32]4)
            foreach($offset in @(0,4,8,12)){[Runtime.InteropServices.Marshal]::WriteInt32($value,$offset,-1)}
            $hr=$extend.DynamicInvoke($hwnd,$value);if($hr -lt 0){throw "DWM frame extension failed: $hr"}
            @{Material=$Material;Requested=$materialValue;Observed=$observed;Curved=$Curved;Dark=$Dark;BorderColor=$borderColor}
        }finally{$n.Free($value)}
    }
    function BeginEntrance {
        $script:getStyle=Bind 'GetWindowLongPtrW' ([IntPtr]) @([IntPtr],[int])
        $script:setStyle=Bind 'SetWindowLongPtrW' ([IntPtr]) @([IntPtr],[int],[IntPtr])
        $script:setAlpha=Bind 'SetLayeredWindowAttributes' ([bool]) @([IntPtr],[uint32],[byte],[uint32])
        $script:getAlpha=Bind 'GetLayeredWindowAttributes' ([bool]) @([IntPtr],[IntPtr],[IntPtr],[IntPtr])
        $metrics=Bind 'GetSystemMetrics' ([int]) @([int])
        $null=$getRect.DynamicInvoke($hwnd,$scratch)
        $script:entranceX=[Runtime.InteropServices.Marshal]::ReadInt32($scratch,0)
        $script:entranceY=[Runtime.InteropServices.Marshal]::ReadInt32($scratch,4)
        $script:entranceFrom=$metrics.DynamicInvoke(76)+$metrics.DynamicInvoke(78)+24
        $script:entranceStyle=$getStyle.DynamicInvoke($hwnd,-20)
        $null=$setStyle.DynamicInvoke($hwnd,-20,[IntPtr]($entranceStyle.ToInt64() -bor 0x80000))
        if(-not $setAlpha.DynamicInvoke($hwnd,[uint32]0,[byte]0,[uint32]2)){throw 'Could not initialize the window fade.'}
        $null=$setPosition.DynamicInvoke($hwnd,[IntPtr]::Zero,$entranceFrom,$entranceY,0,0,[uint32]0x15)
        @{FromX=$entranceFrom;ToX=$entranceX;Y=$entranceY;DurationMs=320;Curve=@(0.2,0.0,0.0,1.0)}
    }
    function Entrance([double]$Progress){
        $p=[Math]::Clamp($Progress,0.0,1.0);$x=[int][Math]::Round($entranceFrom+($entranceX-$entranceFrom)*$p)
        $null=$setPosition.DynamicInvoke($hwnd,[IntPtr]::Zero,$x,$entranceY,0,0,[uint32]0x15)
        $null=$setAlpha.DynamicInvoke($hwnd,[uint32]0,[byte][Math]::Round(255*$p),[uint32]2)
        $null=$getAlpha.DynamicInvoke($hwnd,[IntPtr]::Add($scratch,32),[IntPtr]::Add($scratch,36),[IntPtr]::Add($scratch,40))
        $alpha=[Runtime.InteropServices.Marshal]::ReadByte($scratch,36)
        $null=$getRect.DynamicInvoke($hwnd,$scratch)
        @{Progress=$p;X=[Runtime.InteropServices.Marshal]::ReadInt32($scratch,0);Alpha=[int]$alpha}
    }
    function EndEntrance {
        $null=Entrance 1
        $null=$setStyle.DynamicInvoke($hwnd,-20,$entranceStyle)
        $foreground=Bind 'SetForegroundWindow' ([bool]) @([IntPtr]);$null=$foreground.DynamicInvoke($hwnd)
        @{OriginalStyle=$entranceStyle.ToInt64();ObservedStyle=$getStyle.DynamicInvoke($hwnd,-20).ToInt64()}
    }
    function SelectIcon([string]$Kind,[int]$Id){
        $owned=$false
        if($Kind -eq 'stock'){
            $info=$n.Allocate(544)
            try{
                [Runtime.InteropServices.Marshal]::WriteInt32($info,544)
                $get=Bind 'SHGetStockIconInfo' ([int]) @([int],[uint32],[IntPtr]) 'shell32.dll'
                $hr=$get.DynamicInvoke($Id,[uint32]0x100,$info);if($hr -lt 0){throw "Stock icon $Id is unavailable."}
                $icon=[Runtime.InteropServices.Marshal]::ReadIntPtr($info,8);$owned=$true
            }finally{$n.Free($info)}
        }else{$load=Bind 'LoadIconW' ([IntPtr]) @([IntPtr],[IntPtr]);$icon=$load.DynamicInvoke([IntPtr]::Zero,[IntPtr]$Id)}
        if($icon -eq [IntPtr]::Zero){throw 'Windows did not supply the selected icon.'}
        $null=$send.DynamicInvoke($hwnd,[uint32]0x80,[IntPtr]0,$icon);$null=$send.DynamicInvoke($hwnd,[uint32]0x80,[IntPtr]1,$icon)
        if($ownsWindowIcon -and $windowIcon -ne [IntPtr]::Zero){$destroy=Bind 'DestroyIcon' ([bool]) @([IntPtr]);$null=$destroy.DynamicInvoke($windowIcon)}
        $script:windowIcon=$icon;$script:ownsWindowIcon=$owned
        $icon
    }
    function Drain {
        $peek=Bind 'PeekMessageW' ([bool]) @([IntPtr],[IntPtr],[uint32],[uint32],[uint32])
        $translate=Bind 'TranslateMessage' ([bool]) @([IntPtr]);$dispatch=Bind 'DispatchMessageW' ([IntPtr]) @([IntPtr])
        while($peek.DynamicInvoke($scratch,[IntPtr]::Zero,[uint32]0,[uint32]0,[uint32]1)){
            $null=$translate.DynamicInvoke($scratch);$null=$dispatch.DynamicInvoke($scratch)
        }
        if($callbackError){throw $callbackError}
        while($events.Count){$events.Dequeue()}
    }
    function Capture([bool]$Value){if($Value){$null=$setCapture.DynamicInvoke($hwnd)}else{$null=$releaseCapture.DynamicInvoke()}}
    function Cursor([string]$Kind){$script:cursor=switch($Kind){'text'{$ibeam};'pointer'{$hand};default{$arrow}};$null=$setCursor.DynamicInvoke($cursor)}
    function Caption([string]$Action){switch($Action){'minimize'{$null=$show.DynamicInvoke($hwnd,6)};'maximize'{$isZoomed=Bind 'IsZoomed' ([bool]) @([IntPtr]);$null=$show.DynamicInvoke($hwnd,$(if($isZoomed.DynamicInvoke($hwnd)){9}else{3}))};'drag'{$null=$releaseCapture.DynamicInvoke();$null=$send.DynamicInvoke($hwnd,[uint32]0xA1,[IntPtr]2,[IntPtr]::Zero)}}}
    function Dispose {
        $destroy=Bind 'DestroyWindow' ([bool]) @([IntPtr]);$null=$destroy.DynamicInvoke($hwnd)
        if($ownsWindowIcon -and $windowIcon -ne [IntPtr]::Zero){$destroyIcon=Bind 'DestroyIcon' ([bool]) @([IntPtr]);$null=$destroyIcon.DynamicInvoke($windowIcon)}
        $unregister=Bind 'UnregisterClassW' ([bool]) @([IntPtr],[IntPtr]);$null=$unregister.DynamicInvoke($classPtr,$hmodule)
        [Runtime.InteropServices.Marshal]::FreeHGlobal($classPtr)
        $n.Free($scratch);$null=$dpiContext.DynamicInvoke($previousDpi)
    }
    Export-ModuleMember -Function Handle,Info,Show,Appearance,BeginEntrance,Entrance,EndEntrance,SelectIcon,Drain,Capture,Cursor,Caption,Dispose
}
}

# Folded from src\Graphics.Windows.ps1
function Invoke-Graphics.Windows {
[CmdletBinding()]
param([Parameter(Mandatory)][object]$Native, [Parameter(Mandatory)][IntPtr]$Hwnd, [int]$Width, [int]$Height, [single]$Dpi = 96)
if ($MyInvocation.InvocationName -eq '.') { throw 'Invoke Graphics.Windows.ps1 with &.' }

# Direct2D and DirectWrite ABI: slots checked against Windows SDK 10.0.26100.0.
# Every COM object and temporary allocation has an explicit owner. This module
# returns ordinary PowerShell methods; no compiled bridge or UI framework.
New-Module -AsCustomObject -ArgumentList $Native,$Hwnd,$Width,$Height,$Dpi -ScriptBlock {
    param($Native,$Hwnd,$Width,$Height,$Dpi)
    $script:n = $Native
    $script:scratch = $n.Allocate(4096)
    $script:brushes = @{}
    $script:formats = @{}
    $script:geometries = @{}
    $script:bitmaps = @{}
    $script:gradientBrushes = @{}
    $script:layouts = [Collections.Generic.HashSet[IntPtr]]::new()
    $script:factory = [IntPtr]::Zero
    $script:writeFactory = [IntPtr]::Zero
    $script:target = [IntPtr]::Zero
    $script:wicFactory=[IntPtr]::Zero
    $script:curved = $true
    function Com($Object,[int]$Slot,[Type]$Return,[Type[]]$Types,[object[]]$Values) {
        if($env:NOTEPAD_TRACE){[IO.File]::AppendAllText($env:NOTEPAD_TRACE,"COM $Object slot $Slot`n")}
        if($Return -eq [void]){$null=$n.InvokeCom($Object,$Slot,$Return,$Types,$Values)}
        else{$n.InvokeCom($Object,$Slot,$Return,$Types,$Values)}
    }
    function Check([int]$Result) { if ($Result -lt 0) { throw ('Native graphics HRESULT 0x{0:X8}' -f ($Result -band 0xffffffffL)) } }
    function Floats([single[]]$Values,[int]$Offset=0) { [Runtime.InteropServices.Marshal]::Copy($Values,0,[IntPtr]::Add($scratch,$Offset),$Values.Length) }
    function Read-Float([int]$Offset) { [BitConverter]::Int32BitsToSingle([Runtime.InteropServices.Marshal]::ReadInt32($scratch,$Offset)) }
    function Point([single]$X,[single]$Y) { [BitConverter]::ToUInt64(([BitConverter]::GetBytes($X)+[BitConverter]::GetBytes($Y)),0) }
    function New-Factory([string]$Dll,[string]$Export,[string]$Iid) {
        [Runtime.InteropServices.Marshal]::Copy(([Guid]$Iid).ToByteArray(),0,$scratch,16)
        $outPointer = [IntPtr]::Add($scratch,32)
        if ($Export -eq 'D2D1CreateFactory') {
            $call = $n.GetExportCall($Dll,$Export,[int],[Type[]]@([int],[IntPtr],[IntPtr],[IntPtr]))
            Check ($call.DynamicInvoke(0,$scratch,[IntPtr]::Zero,$outPointer))
        } else {
            $call = $n.GetExportCall($Dll,$Export,[int],[Type[]]@([int],[IntPtr],[IntPtr]))
            Check ($call.DynamicInvoke(0,$scratch,$outPointer))
        }
        [Runtime.InteropServices.Marshal]::ReadIntPtr($outPointer)
    }
    $script:factory = New-Factory 'd2d1.dll' 'D2D1CreateFactory' '06152247-6f50-465a-9245-118bfd3b6007'
    $script:writeFactory = New-Factory 'dwrite.dll' 'DWriteCreateFactory' 'b859ee5a-d838-4b5b-a2e8-1adc7d93db48'
    # D2D1_RENDER_TARGET_PROPERTIES is 28 bytes. D2D1_HWND_RENDER_TARGET_PROPERTIES
    # is 24 bytes on x64: HWND, SIZE_U, present options, alignment padding.
    for ($i=0;$i -lt 128;$i++) { [Runtime.InteropServices.Marshal]::WriteByte($scratch,$i,0) }
    [Runtime.InteropServices.Marshal]::WriteInt32($scratch,0,1)
    [Runtime.InteropServices.Marshal]::WriteInt32($scratch,4,87) # BGRA8
    [Runtime.InteropServices.Marshal]::WriteInt32($scratch,8,1) # premultiplied alpha exposes the DWM material
    Floats @($Dpi,$Dpi) 12
    [Runtime.InteropServices.Marshal]::WriteIntPtr($scratch,32,$Hwnd)
    [Runtime.InteropServices.Marshal]::WriteInt32($scratch,40,$Width)
    [Runtime.InteropServices.Marshal]::WriteInt32($scratch,44,$Height)
    Check (Com $factory 14 ([int]) @([IntPtr],[IntPtr],[IntPtr]) @($scratch,[IntPtr]::Add($scratch,32),[IntPtr]::Add($scratch,64)))
    $script:target = [Runtime.InteropServices.Marshal]::ReadIntPtr($scratch,64)
    # Grayscale text AA matches CSS antialiased more closely than ClearType.
    Com $target 34 ([void]) @([int]) @(2)

    function Brush([string]$Color) {
        if ($brushes.ContainsKey($Color)) { return $brushes[$Color] }
        $rgba = [single[]]@(0,0,0,1)
        if ($Color.StartsWith('#')) {
            $hex = $Color.Substring(1)
            if ($hex.Length -eq 3) { $hex = -join ($hex.ToCharArray() | ForEach-Object {"$_$_"}) }
            $rgba[0] = [Convert]::ToInt32($hex.Substring(0,2),16)/255.0
            $rgba[1] = [Convert]::ToInt32($hex.Substring(2,2),16)/255.0
            $rgba[2] = [Convert]::ToInt32($hex.Substring(4,2),16)/255.0
        } elseif ($Color -match '^rgba?\((.+)\)$') {
            $parts=$Matches[1].Split(','); for($i=0;$i -lt 3;$i++){$rgba[$i]=[single]::Parse($parts[$i],[Globalization.CultureInfo]::InvariantCulture)/255}
            if($parts.Count -eq 4){$rgba[3]=[single]::Parse($parts[3],[Globalization.CultureInfo]::InvariantCulture)}
        } elseif ($Color -eq 'transparent') { $rgba[3]=0 }
        Floats $rgba
        Check (Com $target 8 ([int]) @([IntPtr],[IntPtr],[IntPtr]) @($scratch,[IntPtr]::Zero,[IntPtr]::Add($scratch,32)))
        $brush = [Runtime.InteropServices.Marshal]::ReadIntPtr($scratch,32)
        $brushes[$Color]=$brush
        $brush
    }
    function Begin([string]$Color,[single]$Opacity=1) {
        Com $target 48 ([void]) @() @()
        # Clear requires a color pointer; brushes are not interchangeable.
        $null=Brush $Color
        $hex=$Color.TrimStart('#')
        Floats @(([Convert]::ToInt32($hex.Substring(0,2),16)/255.0),([Convert]::ToInt32($hex.Substring(2,2),16)/255.0),([Convert]::ToInt32($hex.Substring(4,2),16)/255.0),$Opacity)
        Com $target 47 ([void]) @([IntPtr]) @($scratch)
    }
    function End {
        $result=Com $target 49 ([int]) @([IntPtr],[IntPtr]) @([IntPtr]::Zero,[IntPtr]::Zero)
        Check $result
    }
    function Resize([int]$Width,[int]$Height,[single]$Dpi) {
        [Runtime.InteropServices.Marshal]::WriteInt32($scratch,0,[Math]::Max(1,$Width))
        [Runtime.InteropServices.Marshal]::WriteInt32($scratch,4,[Math]::Max(1,$Height))
        Check (Com $target 58 ([int]) @([IntPtr]) @($scratch))
        Com $target 51 ([void]) @([single],[single]) @($Dpi,$Dpi)
    }
    function Fill([single]$X,[single]$Y,[single]$W,[single]$H,[string]$Color,[single]$Radius=0) {
        if($W -le 0 -or $H -le 0){return}
        if(-not $curved -and $Radius -lt 9){$Radius=0}
        $brush=Brush $Color
        Floats @($X,$Y,($X+$W),($Y+$H),$Radius,$Radius)
        if($Radius -gt 0){Com $target 19 ([void]) @([IntPtr],[IntPtr]) @($scratch,$brush)}
        else{Com $target 17 ([void]) @([IntPtr],[IntPtr]) @($scratch,$brush)}
    }
    function Stroke([single]$X,[single]$Y,[single]$W,[single]$H,[string]$Color,[single]$Radius=0,[single]$Thickness=1) {
        if(-not $curved -and $Radius -lt 9){$Radius=0}
        $brush=Brush $Color
        Floats @(($X+$Thickness/2),($Y+$Thickness/2),($X+$W-$Thickness/2),($Y+$H-$Thickness/2),$Radius,$Radius)
        $slot=if($Radius -gt 0){18}else{16}
        Com $target $slot ([void]) @([IntPtr],[IntPtr],[single],[IntPtr]) @($scratch,$brush,$Thickness,[IntPtr]::Zero)
    }
    function Clip([single]$X,[single]$Y,[single]$W,[single]$H) {
        Floats @($X,$Y,($X+$W),($Y+$H)); Com $target 45 ([void]) @([IntPtr],[int]) @($scratch,0)
    }
    function Unclip { Com $target 46 ([void]) @() @() }
    function FourCorner([single]$X,[single]$Y,[single]$W,[single]$H,[string[]]$Colors,[single]$Opacity=1){
        if($W -le 0 -or $H -le 0){return}
        $key=($Colors -join '|')+'|'+$Opacity.ToString([Globalization.CultureInfo]::InvariantCulture)
        if(-not $bitmaps.ContainsKey($key)){
            # Four texel centers are the four corners. Linear sampling performs bilinear interpolation.
            $bytes=[byte[]]::new(16)
            for($i=0;$i -lt 4;$i++){$hex=$Colors[$i].TrimStart('#');$offset=$i*4
                $bytes[$offset]=[byte][Math]::Round([Convert]::ToInt32($hex.Substring(4,2),16)*$Opacity)
                $bytes[$offset+1]=[byte][Math]::Round([Convert]::ToInt32($hex.Substring(2,2),16)*$Opacity)
                $bytes[$offset+2]=[byte][Math]::Round([Convert]::ToInt32($hex.Substring(0,2),16)*$Opacity)
                $bytes[$offset+3]=[byte][Math]::Round(255*$Opacity)
            }
            [Runtime.InteropServices.Marshal]::Copy($bytes,0,$scratch,16)
            [Runtime.InteropServices.Marshal]::WriteInt32($scratch,32,87);[Runtime.InteropServices.Marshal]::WriteInt32($scratch,36,1);Floats @(96,96) 40
            Check (Com $target 4 ([int]) @([uint64],[IntPtr],[uint32],[IntPtr],[IntPtr]) @([uint64]8589934594,$scratch,[uint32]8,[IntPtr]::Add($scratch,32),[IntPtr]::Add($scratch,56)))
            $bitmaps[$key]=[Runtime.InteropServices.Marshal]::ReadIntPtr($scratch,56)
        }
        Floats @($X,$Y,($X+$W),($Y+$H)) 64;Floats @(0.5,0.5,1.5,1.5) 80
        Com $target 26 ([void]) @([IntPtr],[IntPtr],[single],[int],[IntPtr]) @($bitmaps[$key],[IntPtr]::Add($scratch,64),[single]1,1,[IntPtr]::Add($scratch,80))
    }
    function NativeIcon([IntPtr]$Handle,[string]$Key,[single]$X,[single]$Y,[single]$Size){
        $cacheKey='icon:'+$Key
        if(-not $bitmaps.ContainsKey($cacheKey)){
            if($wicFactory -eq [IntPtr]::Zero){
                [Runtime.InteropServices.Marshal]::Copy(([guid]'cacaf262-9370-4615-a13b-9f5539da4c0a').ToByteArray(),0,$scratch,16)
                [Runtime.InteropServices.Marshal]::Copy(([guid]'ec5ec8a9-c395-4314-9c77-54d7a935ff70').ToByteArray(),0,[IntPtr]::Add($scratch,16),16)
                $create=$n.GetExportCall('ole32.dll','CoCreateInstance',[int],[type[]]@([IntPtr],[IntPtr],[uint32],[IntPtr],[IntPtr]))
                Check ($create.DynamicInvoke($scratch,[IntPtr]::Zero,[uint32]1,[IntPtr]::Add($scratch,16),[IntPtr]::Add($scratch,40)))
                $script:wicFactory=[Runtime.InteropServices.Marshal]::ReadIntPtr($scratch,40)
            }
            Check (Com $wicFactory 22 ([int]) @([IntPtr],[IntPtr]) @($Handle,$scratch))
            $source=[Runtime.InteropServices.Marshal]::ReadIntPtr($scratch)
            $converter=[IntPtr]::Zero
            try{
                Check (Com $wicFactory 10 ([int]) @([IntPtr]) @($scratch));$converter=[Runtime.InteropServices.Marshal]::ReadIntPtr($scratch)
                [Runtime.InteropServices.Marshal]::Copy(([guid]'6fddc324-4e03-4bfe-b185-3d77768dc910').ToByteArray(),0,$scratch,16)
                Check (Com $converter 8 ([int]) @([IntPtr],[IntPtr],[int],[IntPtr],[double],[int]) @($source,$scratch,0,[IntPtr]::Zero,[double]0,0))
                Check (Com $target 5 ([int]) @([IntPtr],[IntPtr],[IntPtr]) @($converter,[IntPtr]::Zero,[IntPtr]::Add($scratch,32)))
                $bitmaps[$cacheKey]=[Runtime.InteropServices.Marshal]::ReadIntPtr($scratch,32)
            }finally{if($converter -ne [IntPtr]::Zero){$null=$n.ReleaseCom($converter)};$null=$n.ReleaseCom($source)}
        }
        Floats @($X,$Y,($X+$Size),($Y+$Size))
        Com $target 26 ([void]) @([IntPtr],[IntPtr],[single],[int],[IntPtr]) @($bitmaps[$cacheKey],$scratch,[single]1,1,[IntPtr]::Zero)
    }
    function Gradient-Brush([string]$Key,[single[]]$Stops){
        if($gradientBrushes.ContainsKey($Key)){return $gradientBrushes[$Key]}
        Floats $Stops
        Check (Com $target 9 ([int]) @([IntPtr],[uint32],[int],[int],[IntPtr]) @($scratch,[uint32]($Stops.Length/5),0,0,[IntPtr]::Add($scratch,2048)))
        $collection=[Runtime.InteropServices.Marshal]::ReadIntPtr($scratch,2048)
        try{Floats @(0,0,1,1);Check (Com $target 10 ([int]) @([IntPtr],[IntPtr],[IntPtr],[IntPtr]) @($scratch,[IntPtr]::Zero,$collection,[IntPtr]::Add($scratch,2048)));$gradientBrushes[$Key]=[Runtime.InteropServices.Marshal]::ReadIntPtr($scratch,2048)}finally{$null=$n.ReleaseCom($collection)}
        $gradientBrushes[$Key]
    }
    function ColorSpectrum([single]$X,[single]$Y,[single]$Size){
        $hue=Gradient-Brush 'picker-hue' ([single[]]@(0,1,0,0,1,(1/6),1,1,0,1,(2/6),0,1,0,1,0.5,0,1,1,1,(4/6),0,0,1,1,(5/6),1,0,1,1,1,1,0,0,1))
        $white=Gradient-Brush 'picker-saturation' ([single[]]@(0,1,1,1,0,1,1,1,1,1))
        Com $hue 8 ([void]) @([uint64]) @((Point $X $Y));Com $hue 9 ([void]) @([uint64]) @((Point ($X+$Size) $Y))
        Com $white 8 ([void]) @([uint64]) @((Point $X $Y));Com $white 9 ([void]) @([uint64]) @((Point $X ($Y+$Size)))
        Floats @($X,$Y,($X+$Size),($Y+$Size),4,4);Com $target 19 ([void]) @([IntPtr],[IntPtr]) @($scratch,$hue);Com $target 19 ([void]) @([IntPtr],[IntPtr]) @($scratch,$white)
    }
    function Circle([single]$X,[single]$Y,[single]$Radius,[string]$Color,[single]$Thickness=0){
        $brush=Brush $Color;Floats @($X,$Y,$Radius,$Radius)
        if($Thickness -gt 0){Com $target 20 ([void]) @([IntPtr],[IntPtr],[single],[IntPtr]) @($scratch,$brush,$Thickness,[IntPtr]::Zero)}else{Com $target 21 ([void]) @([IntPtr],[IntPtr]) @($scratch,$brush)}
    }

    function Layout([string]$Text,[string]$Family,[single]$Size,[single]$Width,[bool]$Wrap=$false,[int]$Weight=400,[bool]$Italic=$false,[single]$LineHeight=0) {
        $key="$Family|$Size|$Wrap|$Weight|$Italic|$LineHeight"
        if(-not $formats.ContainsKey($key)) {
            $familyPtr=[Runtime.InteropServices.Marshal]::StringToHGlobalUni($Family)
            $localePtr=[Runtime.InteropServices.Marshal]::StringToHGlobalUni('en-us')
            try {
                Check (Com $writeFactory 15 ([int]) @([IntPtr],[IntPtr],[int],[int],[int],[single],[IntPtr],[IntPtr]) @($familyPtr,[IntPtr]::Zero,$Weight,([int]$Italic*2),5,$Size,$localePtr,$scratch))
                $format=[Runtime.InteropServices.Marshal]::ReadIntPtr($scratch)
                Check (Com $format 5 ([int]) @([int]) @($(if($Wrap){0}else{1})))
                if($LineHeight -gt 0){Check (Com $format 10 ([int]) @([int],[single],[single]) @(1,$LineHeight,($Size*0.95)))}
                Check (Com $format 8 ([int]) @([single]) @(($Size*0.55*4)))
                $formats[$key]=$format
            }finally{[Runtime.InteropServices.Marshal]::FreeHGlobal($familyPtr);[Runtime.InteropServices.Marshal]::FreeHGlobal($localePtr)}
        }
        $textPtr=[Runtime.InteropServices.Marshal]::StringToHGlobalUni($Text)
        try {
            Check (Com $writeFactory 18 ([int]) @([IntPtr],[uint32],[IntPtr],[single],[single],[IntPtr]) @($textPtr,[uint32]$Text.Length,$formats[$key],[single][Math]::Max(1,$Width),[single]1000000,$scratch))
            $layout=[Runtime.InteropServices.Marshal]::ReadIntPtr($scratch)
            $null=$layouts.Add($layout)
            $layout
        }finally{[Runtime.InteropServices.Marshal]::FreeHGlobal($textPtr)}
    }
    function ReleaseLayout([IntPtr]$Layout) { if($layouts.Remove($Layout)){$null=$n.ReleaseCom($Layout)} }
    function DrawLayout([IntPtr]$Layout,[single]$X,[single]$Y,[string]$Color) {
        $brush=Brush $Color
        Com $target 28 ([void]) @([uint64],[IntPtr],[IntPtr],[int]) @((Point $X $Y),$Layout,$brush,4)
    }
    function Metrics([IntPtr]$Layout) {
        Check (Com $Layout 60 ([int]) @([IntPtr]) @($scratch))
        @{Width=(Read-Float 8);TrailingWidth=(Read-Float 12);Height=(Read-Float 16);Lines=[Runtime.InteropServices.Marshal]::ReadInt32($scratch,32)}
    }
    function Caret([IntPtr]$Layout,[uint32]$Position,[bool]$Trailing=$false) {
        Check (Com $Layout 65 ([int]) @([uint32],[int],[IntPtr],[IntPtr],[IntPtr]) @($Position,[int]$Trailing,$scratch,[IntPtr]::Add($scratch,4),[IntPtr]::Add($scratch,16)))
        @{X=(Read-Float 0);Y=(Read-Float 4);Width=(Read-Float 32);Height=(Read-Float 36)}
    }
    function HitText([IntPtr]$Layout,[single]$X,[single]$Y) {
        Check (Com $Layout 64 ([int]) @([single],[single],[IntPtr],[IntPtr],[IntPtr]) @($X,$Y,$scratch,[IntPtr]::Add($scratch,4),[IntPtr]::Add($scratch,16)))
        $start=[Runtime.InteropServices.Marshal]::ReadInt32($scratch,16)
        $length=[Runtime.InteropServices.Marshal]::ReadInt32($scratch,20)
        $trailing=[Runtime.InteropServices.Marshal]::ReadInt32($scratch) -ne 0
        @{Position=($start+$(if($trailing){$length}else{0}));Trailing=$trailing;ClusterStart=$start}
    }
    function Selection([IntPtr]$Layout,[int]$Start,[int]$Length) {
        if($Length -le 0){return @()}
        $countPtr=$n.Allocate(4)
        try {
            $result=Com $Layout 66 ([int]) @([uint32],[uint32],[single],[single],[IntPtr],[uint32],[IntPtr]) @([uint32]$Start,[uint32]$Length,[single]0,[single]0,[IntPtr]::Zero,[uint32]0,$countPtr)
            $count=[Runtime.InteropServices.Marshal]::ReadInt32($countPtr)
            if($count -eq 0){Check $result;return @()}
            $memory=$n.Allocate($count*36)
            try {
                Check (Com $Layout 66 ([int]) @([uint32],[uint32],[single],[single],[IntPtr],[uint32],[IntPtr]) @([uint32]$Start,[uint32]$Length,[single]0,[single]0,$memory,[uint32]$count,$countPtr))
                for($i=0;$i -lt $count;$i++) {
                    $values=[single[]]::new(4);[Runtime.InteropServices.Marshal]::Copy([IntPtr]::Add($memory,$i*36+8),$values,0,4)
                    @{X=$values[0];Y=$values[1];Width=$values[2];Height=$values[3]}
                }
            }finally{$n.Free($memory)}
        }finally{$n.Free($countPtr)}
    }
    function Text([string]$Text,[single]$X,[single]$Y,[single]$W,[string]$Color,[single]$Size=13,[string]$Family='Segoe UI',[int]$Weight=400) {
        $layout=Layout $Text $Family $Size $W $false $Weight
        try{DrawLayout $layout $X $Y $Color}finally{ReleaseLayout $layout}
    }

    # SVG endpoint arcs map directly to D2D1_ARC_SEGMENT; no raster fallback.
    function Path([string]$Data) {
        if($geometries.ContainsKey($Data)){return $geometries[$Data]}
        Check (Com $factory 10 ([int]) @([IntPtr]) @($scratch))
        $geometry=[Runtime.InteropServices.Marshal]::ReadIntPtr($scratch)
        Check (Com $geometry 17 ([int]) @([IntPtr]) @($scratch))
        $sink=[Runtime.InteropServices.Marshal]::ReadIntPtr($scratch)
        $items=[regex]::Matches($Data,'[a-zA-Z]|[-+]?(?:\d*\.\d+|\d+\.?\d*)(?:[eE][-+]?\d+)?')
        $index=0;$command='';$x=0.0;$y=0.0;$sx=0.0;$sy=0.0;$cx=0.0;$cy=0.0;$previous='';$figure=$false
        try{
            # SVG nonzero is D2D1_FILL_MODE_WINDING.
            Com $sink 3 ([void]) @([int]) @(1)
            while($index -lt $items.Count){
                if($items[$index].Value -cmatch '^[a-zA-Z]$'){$command=$items[$index++].Value}
                $upper=$command.ToUpperInvariant();$relative=$command -cmatch '^[a-z]$'
                if($upper -eq 'Z'){
                    if($figure){Com $sink 8 ([void]) @([int]) @(1);$figure=$false};$x=$sx;$y=$sy;$previous='Z';continue
                }
                $arity=switch($upper){'M'{2};'L'{2};'H'{1};'V'{1};'C'{6};'S'{4};'Q'{4};'T'{2};'A'{7};default{throw "Unsupported SVG command $command"}}
                if($index+$arity -gt $items.Count){throw 'Incomplete SVG path'}
                $v=[double[]]::new($arity)
                for($i=0;$i -lt $arity;$i++){$v[$i]=[double]::Parse($items[$index++].Value,[Globalization.CultureInfo]::InvariantCulture)}
                $baseX=if($relative){$x}else{0};$baseY=if($relative){$y}else{0}
                switch($upper){
                    'M'{if($figure){Com $sink 8 ([void]) @([int]) @(0)};$x=$v[0]+$baseX;$y=$v[1]+$baseY;$sx=$x;$sy=$y;Com $sink 5 ([void]) @([uint64],[int]) @((Point $x $y),0);$figure=$true;$command=if($relative){'l'}else{'L'}}
                    'L'{$x=$v[0]+$baseX;$y=$v[1]+$baseY;Com $sink 10 ([void]) @([uint64]) @((Point $x $y))}
                    'H'{$x=$v[0]+$baseX;Com $sink 10 ([void]) @([uint64]) @((Point $x $y))}
                    'V'{$y=$v[0]+$baseY;Com $sink 10 ([void]) @([uint64]) @((Point $x $y))}
                    'C'{Floats @(($v[0]+$baseX),($v[1]+$baseY),($v[2]+$baseX),($v[3]+$baseY),($v[4]+$baseX),($v[5]+$baseY));Com $sink 11 ([void]) @([IntPtr]) @($scratch);$cx=$v[2]+$baseX;$cy=$v[3]+$baseY;$x=$v[4]+$baseX;$y=$v[5]+$baseY}
                    'S'{$c1x=$x;$c1y=$y;if($previous -in @('C','S')){$c1x=2*$x-$cx;$c1y=2*$y-$cy};Floats @($c1x,$c1y,($v[0]+$baseX),($v[1]+$baseY),($v[2]+$baseX),($v[3]+$baseY));Com $sink 11 ([void]) @([IntPtr]) @($scratch);$cx=$v[0]+$baseX;$cy=$v[1]+$baseY;$x=$v[2]+$baseX;$y=$v[3]+$baseY}
                    'Q'{$cx=$v[0]+$baseX;$cy=$v[1]+$baseY;$x=$v[2]+$baseX;$y=$v[3]+$baseY;Floats @($cx,$cy,$x,$y);Com $sink 12 ([void]) @([IntPtr]) @($scratch)}
                    'T'{$qx=$x;$qy=$y;if($previous -in @('Q','T')){$qx=2*$x-$cx;$qy=2*$y-$cy};$x=$v[0]+$baseX;$y=$v[1]+$baseY;Floats @($qx,$qy,$x,$y);Com $sink 12 ([void]) @([IntPtr]) @($scratch);$cx=$qx;$cy=$qy}
                    'A'{$x=$v[5]+$baseX;$y=$v[6]+$baseY;if($v[0] -eq 0 -or $v[1] -eq 0){Com $sink 10 ([void]) @([uint64]) @((Point $x $y))}else{Floats @($x,$y,[Math]::Abs($v[0]),[Math]::Abs($v[1]),$v[2]);[Runtime.InteropServices.Marshal]::WriteInt32($scratch,20,[int]$v[4]);[Runtime.InteropServices.Marshal]::WriteInt32($scratch,24,[int]$v[3]);Com $sink 14 ([void]) @([IntPtr]) @($scratch)}}
                }
                $previous=$upper
            }
            if($figure){Com $sink 8 ([void]) @([int]) @(0)}
            Check (Com $sink 9 ([int]) @() @())
            $geometries[$Data]=$geometry
            $geometry
        }catch{$null=$n.ReleaseCom($geometry);throw}finally{$null=$n.ReleaseCom($sink)}
    }
    function Icon([string]$Svg,[single]$X,[single]$Y,[single]$Size,[string]$Color,[double]$Rotation=0) {
        [xml]$xml=$Svg
        $view=[double[]]($xml.svg.viewBox.Split(' ',[StringSplitOptions]::RemoveEmptyEntries))
        $scale=$Size/$view[2]
        foreach($element in $xml.svg.path){
            $geometry=Path $element.d
            if($geometry -is [array]){throw "Path returned multiple values: $($geometry | ForEach-Object { $_.GetType().Name+':'+$_ })"}
            $fill=$Color;if($element.HasAttribute('fill')){$fill=$element.GetAttribute('fill')}
            $brush=Brush $fill
            $opacity=1.0;if($element.HasAttribute('opacity')){$opacity=[double]::Parse($element.GetAttribute('opacity'),[Globalization.CultureInfo]::InvariantCulture)}
            Com $brush 4 ([void]) @([single]) @([single]$opacity)
            if($Rotation -eq 180){Floats @(-$scale,0,0,-$scale,($X+$Size),($Y+$Size))}else{Floats @($scale,0,0,$scale,$X,$Y)}
            Com $target 30 ([void]) @([IntPtr]) @($scratch)
            Com $target 23 ([void]) @([IntPtr],[IntPtr],[IntPtr]) @($geometry,$brush,[IntPtr]::Zero)
            Com $brush 4 ([void]) @([single]) @([single]1)
        }
        Floats @(1,0,0,1,0,0);Com $target 30 ([void]) @([IntPtr]) @($scratch)
    }
    function Dispose {
        foreach($layout in @($layouts)){$null=$n.ReleaseCom($layout)};$layouts.Clear()
        foreach($item in $geometries.Values){$null=$n.ReleaseCom($item)}
        foreach($item in $bitmaps.Values){$null=$n.ReleaseCom($item)}
        foreach($item in $gradientBrushes.Values){$null=$n.ReleaseCom($item)}
        foreach($item in $formats.Values){$null=$n.ReleaseCom($item)}
        foreach($item in $brushes.Values){$null=$n.ReleaseCom($item)}
        foreach($item in @($target,$writeFactory,$factory,$wicFactory)){if($item -ne [IntPtr]::Zero){$null=$n.ReleaseCom($item)}}
        $n.Free($scratch)
    }
    function CornerStyle([bool]$Curved){$script:curved=$Curved}
    Export-ModuleMember -Function Begin,End,Resize,Fill,Stroke,Clip,Unclip,FourCorner,NativeIcon,ColorSpectrum,Circle,Layout,ReleaseLayout,DrawLayout,Metrics,Caret,HitText,Selection,Text,Icon,CornerStyle,Dispose
}
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
    $window=Invoke-Window.Windows -Native $native -Width 960 -Height 540 -Title 'Notepad PS graphics smoke'
    $info=$window.Info()
    $graphics=Invoke-Graphics.Windows -Native $native -Hwnd $window.Handle() -Width $info.Width -Height $info.Height -Dpi $info.Dpi
    $design=Invoke-Design
    $window.Show()
    $graphics.Begin('#1f1f1f')
    $graphics.Fill(0,78,960,434,'#282828',0)
    $graphics.Text('Notepad • direct PowerShell',40,12,500,'#ffffff',13,'Segoe UI',400)
    $i=0
    foreach($svg in $design.Icons.Values){$graphics.Icon($svg,(20+($i%12)*52),(100+[Math]::Floor($i/12)*52),20,'#ffffff',0);$i++}
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
    'PASS: native window, Direct2D, DirectWrite, SVG paths, caret/hit-test and selection.'
}finally{if($graphics){$graphics.Dispose()};if($window){$window.Dispose()};$native.Dispose()}
}

# Folded from src\Services.Windows.ps1
function Invoke-Services.Windows {
[CmdletBinding()]
param([Parameter(Mandatory)][object]$Native,[Parameter(Mandatory)][IntPtr]$Hwnd)
if($MyInvocation.InvocationName -eq '.'){throw 'Invoke Services.Windows.ps1 with &.'}
New-Module -AsCustomObject -ArgumentList $Native,$Hwnd -ScriptBlock {
    param($Native,$Hwnd)
    $script:n=$Native;$script:hwnd=$Hwnd
    function Bind($Dll,$Name,$Return,$Types){$n.GetExportCall($Dll,$Name,$Return,[Type[]]$Types)}
    function FileDialog([bool]$Save,[string]$Suggested='Untitled.txt'){
        # OPENFILENAMEW x64 layout, commdlg.h. All buffers outlive the modal call.
        $memory=$n.Allocate(152);$file=$n.Allocate(65536)
        $filter=[Runtime.InteropServices.Marshal]::StringToHGlobalUni("Text documents (*.txt;*.md)`0*.txt;*.md`0All files (*.*)`0*.*`0`0")
        $extension=[Runtime.InteropServices.Marshal]::StringToHGlobalUni('txt')
        try{
            if($Save){$chars=([Text.Encoding]::Unicode.GetBytes($Suggested+[char]0));[Runtime.InteropServices.Marshal]::Copy($chars,0,$file,[Math]::Min($chars.Length,65534))}
            [Runtime.InteropServices.Marshal]::WriteInt32($memory,0,152)
            [Runtime.InteropServices.Marshal]::WriteIntPtr($memory,8,$hwnd)
            [Runtime.InteropServices.Marshal]::WriteIntPtr($memory,24,$filter)
            [Runtime.InteropServices.Marshal]::WriteInt32($memory,44,1)
            [Runtime.InteropServices.Marshal]::WriteIntPtr($memory,48,$file)
            [Runtime.InteropServices.Marshal]::WriteInt32($memory,56,32768)
            [Runtime.InteropServices.Marshal]::WriteInt32($memory,96,$(if($Save){0x8080A}else{0x81808}))
            [Runtime.InteropServices.Marshal]::WriteIntPtr($memory,104,$extension)
            $call=Bind 'comdlg32.dll' $(if($Save){'GetSaveFileNameW'}else{'GetOpenFileNameW'}) ([bool]) @([IntPtr])
            if($call.DynamicInvoke($memory)){return [Runtime.InteropServices.Marshal]::PtrToStringUni($file)}
            $errorCall=Bind 'comdlg32.dll' 'CommDlgExtendedError' ([uint32]) @()
            $code=$errorCall.DynamicInvoke();if($code){throw "File dialog failed: $code"}
            $null
        }finally{$n.Free($memory);$n.Free($file);[Runtime.InteropServices.Marshal]::FreeHGlobal($filter);[Runtime.InteropServices.Marshal]::FreeHGlobal($extension)}
    }
    function ReadClipboard {
        $open=Bind 'user32.dll' 'OpenClipboard' ([bool]) @([IntPtr]);$close=Bind 'user32.dll' 'CloseClipboard' ([bool]) @()
        if(-not $open.DynamicInvoke($hwnd)){throw 'Clipboard is busy'}
        try{
            $get=Bind 'user32.dll' 'GetClipboardData' ([IntPtr]) @([uint32]);$handle=$get.DynamicInvoke([uint32]13)
            if($handle -eq [IntPtr]::Zero){return ''}
            $lock=Bind 'kernel32.dll' 'GlobalLock' ([IntPtr]) @([IntPtr]);$unlock=Bind 'kernel32.dll' 'GlobalUnlock' ([bool]) @([IntPtr]);$ptr=$lock.DynamicInvoke($handle)
            if($ptr -eq [IntPtr]::Zero){throw 'Clipboard lock failed'}
            try{[Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)}finally{$null=$unlock.DynamicInvoke($handle)}
        }finally{$null=$close.DynamicInvoke()}
    }
    function WriteClipboard([string]$Text){
        $open=Bind 'user32.dll' 'OpenClipboard' ([bool]) @([IntPtr]);$close=Bind 'user32.dll' 'CloseClipboard' ([bool]) @()
        $allocate=Bind 'kernel32.dll' 'GlobalAlloc' ([IntPtr]) @([uint32],[UIntPtr]);$lock=Bind 'kernel32.dll' 'GlobalLock' ([IntPtr]) @([IntPtr]);$unlock=Bind 'kernel32.dll' 'GlobalUnlock' ([bool]) @([IntPtr]);$free=Bind 'kernel32.dll' 'GlobalFree' ([IntPtr]) @([IntPtr])
        $bytes=[Text.Encoding]::Unicode.GetBytes($Text+[char]0);$handle=$allocate.DynamicInvoke([uint32]2,[UIntPtr]$bytes.Length);$owned=$true
        if($handle -eq [IntPtr]::Zero){throw 'Clipboard allocation failed'}
        try{
            $ptr=$lock.DynamicInvoke($handle);if($ptr -eq [IntPtr]::Zero){throw 'Clipboard lock failed'}
            try{[Runtime.InteropServices.Marshal]::Copy($bytes,0,$ptr,$bytes.Length)}finally{$null=$unlock.DynamicInvoke($handle)}
            if(-not $open.DynamicInvoke($hwnd)){throw 'Clipboard is busy'}
            try{
                $empty=Bind 'user32.dll' 'EmptyClipboard' ([bool]) @();if(-not $empty.DynamicInvoke()){throw 'Cannot clear clipboard'}
                $set=Bind 'user32.dll' 'SetClipboardData' ([IntPtr]) @([uint32],[IntPtr]);if($set.DynamicInvoke([uint32]13,$handle) -eq [IntPtr]::Zero){throw 'Clipboard transfer failed'};$owned=$false
            }finally{$null=$close.DynamicInvoke()}
        }finally{if($owned){$null=$free.DynamicInvoke($handle)}}
    }
    function WriteClipboardFile([string]$Text,[string]$Title){
        # MansfieldPlumbing feature addition: CF_HDROP owns a path to a durable UTF-8 snapshot.
        $folder=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) ('NotepadPS1\Clipboard\'+[guid]::NewGuid().ToString('N'))
        $null=[IO.Directory]::CreateDirectory($folder)
        $name=[IO.Path]::GetFileNameWithoutExtension($Title)
        foreach($invalid in [IO.Path]::GetInvalidFileNameChars()){$name=$name.Replace([string]$invalid,'_')}
        if(-not $name){$name='Untitled'}
        $file=Join-Path $folder ($name+'.txt');[IO.File]::WriteAllText($file,$Text,[Text.UTF8Encoding]::new($false))
        $paths=[Text.Encoding]::Unicode.GetBytes($file+[char]0+[char]0)
        $allocate=Bind 'kernel32.dll' 'GlobalAlloc' ([IntPtr]) @([uint32],[UIntPtr]);$lock=Bind 'kernel32.dll' 'GlobalLock' ([IntPtr]) @([IntPtr]);$unlock=Bind 'kernel32.dll' 'GlobalUnlock' ([bool]) @([IntPtr]);$free=Bind 'kernel32.dll' 'GlobalFree' ([IntPtr]) @([IntPtr])
        $handle=$allocate.DynamicInvoke([uint32]0x42,[UIntPtr](20+$paths.Length));$owned=$true
        if($handle -eq [IntPtr]::Zero){throw 'File clipboard allocation failed'}
        try{
            $ptr=$lock.DynamicInvoke($handle);if($ptr -eq [IntPtr]::Zero){throw 'File clipboard lock failed'}
            try{[Runtime.InteropServices.Marshal]::WriteInt32($ptr,0,20);[Runtime.InteropServices.Marshal]::WriteInt32($ptr,16,1);[Runtime.InteropServices.Marshal]::Copy($paths,0,[IntPtr]::Add($ptr,20),$paths.Length)}finally{$null=$unlock.DynamicInvoke($handle)}
            $open=Bind 'user32.dll' 'OpenClipboard' ([bool]) @([IntPtr]);$close=Bind 'user32.dll' 'CloseClipboard' ([bool]) @()
            if(-not $open.DynamicInvoke($hwnd)){throw 'Clipboard is busy'}
            try{
                $empty=Bind 'user32.dll' 'EmptyClipboard' ([bool]) @();if(-not $empty.DynamicInvoke()){throw 'Cannot clear clipboard'}
                $set=Bind 'user32.dll' 'SetClipboardData' ([IntPtr]) @([uint32],[IntPtr]);if($set.DynamicInvoke([uint32]15,$handle) -eq [IntPtr]::Zero){throw 'File clipboard transfer failed'};$owned=$false
            }finally{$null=$close.DynamicInvoke()}
        }finally{if($owned){$null=$free.DynamicInvoke($handle)}}
    }
    
    Export-ModuleMember -Function FileDialog,ReadClipboard,WriteClipboard,WriteClipboardFile
}
}

if($MyInvocation.InvocationName -eq '.'){throw 'Invoke Notepad.ps1 with &, not dot-sourcing.'}
$ErrorActionPreference='Stop'
if(-not $IsWindows){throw 'This direct Windows implementation requires PowerShell 7 on Windows.'}
# Notepad's own conformance checks: the document model, and the native window, Direct2D and DirectWrite.
if($VerifyModel){Invoke-Model.Verify;return}
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
            # The corrected reference page is generated beside the original (reference\notepad.html), never over it.
            $currentReference = Join-Path $PSScriptRoot 'reference\notepad.design.html'
            if (Test-Path $currentReference) {
                # A previously generated reference may be updated, but an unrecognized edit is preserved.
                $currentHash = (Get-FileHash $currentReference -Algorithm SHA256).Hash
                $generatedHashFile = Join-Path $EvidenceDirectory 'generated-reference-hash.clixml'
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
$design=Invoke-Design
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
$model=Invoke-Model -Settings $settings
$state=$model.State()
if(-not $NoSession -and $settings.startupOption -eq 'continueSession' -and (Test-Path "$store\session.json")){
    try{$model.ImportSession((Get-Content "$store\session.json" -Raw|ConvertFrom-Json -AsHashtable))}catch{Write-Warning 'Saved session could not be restored.'}
}
if(-not $state.Tabs.Count){$null=$model.NewTab()}
if($Path){$null=$model.Open($Path);if($state.Tabs[0].Text -eq '' -and $state.Tabs.Count -eq 2){$model.CloseTab($state.Tabs[0].Id)}}
$native=Invoke-Native
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
    $window=Invoke-Window.Windows -Native $native -Width $Width -Height $Height
    $info=$window.Info();$ui.Dpi=$info.Dpi;$ui.Width=$info.Width*96/$info.Dpi;$ui.Height=$info.Height*96/$info.Dpi
    $graphics=Invoke-Graphics.Windows -Native $native -Hwnd $window.Handle() -Width $info.Width -Height $info.Height -Dpi $info.Dpi
    $services=Invoke-Services.Windows -Native $native -Hwnd $window.Handle()
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
