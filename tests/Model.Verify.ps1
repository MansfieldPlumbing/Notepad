[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$model=& "$root\src\Model.ps1"
$state=$model.State()
function Assert([bool]$Value,[string]$Message){if(-not $Value){throw $Message}}
$first=$model.NewTab('first.txt','first buffer',$null,$false)
$second=$model.NewTab('second.txt','second buffer',$null,$false)
$testDirectory=Join-Path ([IO.Path]::GetTempPath()) ('notepad-model-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testDirectory|Out-Null
try{
    $defaults=& "$root\src\Model.ps1"
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
    $restored=& "$root\src\Model.ps1";$restored.ImportSession($session)
    Assert ($restored.State().Tabs.Count -eq 3) 'Session lost documents.'
    Assert ($restored.Active().Text -ceq "α`nβ") 'Session active document mismatch.'
    $lastId=$restored.Active().Id;$restored.CloseTab($lastId);Assert ($restored.State().Tabs.Count -eq 2) 'Close-tab failed.'
    'PASS: inactive saves, Unicode editing, undo/redo, find/replace, UTF-8/BOM/CRLF and session restoration.'
}finally{
    # Only exact known temporary files are removed; no recursive directory deletion.
    foreach($name in @('first.txt','second.txt','new-default.txt','lf-preserved.txt')){ $file=Join-Path $testDirectory $name;if(Test-Path -LiteralPath $file){Remove-Item -LiteralPath $file} }
    Remove-Item -LiteralPath $testDirectory
}
