[CmdletBinding()]
param([int]$Seconds=2)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$native=& "$root\src\Native.ps1"
$window=$null;$graphics=$null
try{
    $window=& "$root\src\Window.Windows.ps1" -Native $native -Width 960 -Height 540 -Title 'Notepad PS graphics smoke'
    $info=$window.Info()
    $graphics=& "$root\src\Graphics.Windows.ps1" -Native $native -Hwnd $window.Handle() -Width $info.Width -Height $info.Height -Dpi $info.Dpi
    $design=& "$root\src\Design.ps1"
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
