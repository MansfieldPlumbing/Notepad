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
