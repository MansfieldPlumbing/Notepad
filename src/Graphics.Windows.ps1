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
