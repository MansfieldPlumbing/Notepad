[CmdletBinding()]
param(
    [string]$Path,
    [int]$Width,
    [int]$Height,
    [switch]$NoSession,
    [switch]$NoAnimation,
    [int]$RunSeconds,
    [string]$DiagnosticPath,
    [string]$StartPage,
    [string]$Backdrop,
    [string]$CornerStyle,
    [switch]$SeparateWindow,
    [string]$DetachedSession,
    [switch]$VerifyModel,
    [switch]$VerifyGraphics,
    [switch]$VerifyWindow,
    [switch]$InteractiveWindowVerification,
    [switch]$Compare,
    [switch]$VerifyNativeFeatures,
    [string]$UIAutomationTestDataDirectory
)

# The source host binds the Win32 declarations to the ordinary PowerShell
# runspace. Only the delegate signatures are emitted into a transient module.
class NotepadSourceCall {
    [string]$Library
    [string]$Export
    [type]$Result
    [type[]]$Parameters
    [bool]$Indirect
    [type]$DelegateType
    [Delegate]$Bound
    [Collections.Generic.Dictionary[IntPtr,Delegate]]$ByAddress = [Collections.Generic.Dictionary[IntPtr,Delegate]]::new()
}

class NotepadSourceNative {
    static [Collections.Generic.List[NotepadSourceCall]]$Calls = [Collections.Generic.List[NotepadSourceCall]]::new()
    hidden static [Reflection.Emit.ModuleBuilder]$Module
    hidden static [Collections.Generic.Dictionary[string,IntPtr]]$Libraries =
        [Collections.Generic.Dictionary[string,IntPtr]]::new([StringComparer]::OrdinalIgnoreCase)

    hidden static [type] GetDelegateType([int]$Index) {
        $call = [NotepadSourceNative]::Calls[$Index]
        if ($call.DelegateType) { return $call.DelegateType }
        if ($null -eq [NotepadSourceNative]::Module) {
            $assembly = [Reflection.Emit.AssemblyBuilder]::DefineDynamicAssembly(
                [Reflection.AssemblyName]::new('Notepad.SourceInterop'), [Reflection.Emit.AssemblyBuilderAccess]::Run)
            [NotepadSourceNative]::Module = $assembly.DefineDynamicModule('Interop')
        }
        $builder = [NotepadSourceNative]::Module.DefineType("NativeCall$Index", 'Public,Sealed,Class', [MulticastDelegate])
        $constructor = $builder.DefineConstructor('Public,HideBySig,RTSpecialName', [Reflection.CallingConventions]::Standard, [type[]]@([object],[IntPtr]))
        $constructor.SetImplementationFlags('Runtime,Managed')
        $invoke = $builder.DefineMethod('Invoke','Public,HideBySig,NewSlot,Virtual',$call.Result,$call.Parameters)
        $invoke.SetImplementationFlags('Runtime,Managed')
        $nativePointer = [Runtime.InteropServices.UnmanagedFunctionPointerAttribute].GetConstructor([type[]]@([Runtime.InteropServices.CallingConvention]))
        $builder.SetCustomAttribute([Reflection.Emit.CustomAttributeBuilder]::new($nativePointer,[object[]]@([Runtime.InteropServices.CallingConvention]::Winapi)))
        $call.DelegateType = $builder.CreateType()
        return $call.DelegateType
    }

    static [object] Invoke([int]$Index,[object[]]$Arguments) {
        $call = [NotepadSourceNative]::Calls[$Index]
        $delegateType = [NotepadSourceNative]::GetDelegateType($Index)
        if ($call.Indirect) {
            $address = [IntPtr]$Arguments[0]
            if (!$call.ByAddress.ContainsKey($address)) {
                $call.ByAddress[$address] = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($address,$delegateType)
            }
            $rest = [object[]]::new($Arguments.Length-1)
            [array]::Copy($Arguments,1,$rest,0,$rest.Length)
            return $call.ByAddress[$address].DynamicInvoke($rest)
        }
        if (!$call.Bound) {
            $loadedLibraries = [NotepadSourceNative]::Libraries
            if (!$loadedLibraries.ContainsKey($call.Library)) {
                $loadedLibraries[$call.Library] = [Runtime.InteropServices.NativeLibrary]::Load($call.Library)
            }
            $address = [Runtime.InteropServices.NativeLibrary]::GetExport($loadedLibraries[$call.Library],$call.Export)
            $call.Bound = [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($address,$delegateType)
        }
        return $call.Bound.DynamicInvoke($Arguments)
    }

    static [IntPtr] Callback([int]$Index,[Reflection.MethodInfo]$Method) {
        $call = [NotepadSourceNative]::Calls[$Index]
        if (!$call.Bound) {
            $call.Bound = [Delegate]::CreateDelegate([NotepadSourceNative]::GetDelegateType($Index),$Method)
        }
        return [Runtime.InteropServices.Marshal]::GetFunctionPointerForDelegate($call.Bound)
    }
}

$ErrorActionPreference = 'Stop'
if (![OperatingSystem]::IsWindows() -or ![Environment]::Is64BitProcess) { throw 'Notepad source launch requires Windows and 64-bit PowerShell 7.' }
if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne [Threading.ApartmentState]::STA) { throw 'Start the source launcher with pwsh -STA.' }
$appParameters = @{}
foreach ($parameter in $PSBoundParameters.GetEnumerator()) { $appParameters[$parameter.Key] = $parameter.Value }
if ($VerifyNativeFeatures) { $appParameters['Compare'] = $true }
$sourcePath = Join-Path $PSScriptRoot 'Notepad.ps1'
$source = [IO.File]::ReadAllText($sourcePath)
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseInput($source,$sourcePath,[ref]$tokens,[ref]$errors)
if ($errors.Count) { throw $errors[0].Message }
$edits = [Collections.Generic.List[object]]::new()
$callbacks = [Collections.Generic.Dictionary[string,int]]::new([StringComparer]::Ordinal)

function Add-InteropEdit([Management.Automation.Language.IScriptExtent]$Extent,[string]$Replacement) {
    $edits.Add(@{Start=$Extent.StartOffset;Length=$Extent.EndOffset-$Extent.StartOffset;Text=$Replacement})
}

foreach ($attribute in $ast.ParamBlock.Attributes) {
    if ($attribute.TypeName.Name -in @('SingleThreadedApartment','ApplicationIcon')) { Add-InteropEdit $attribute.Extent '' }
}
foreach ($member in $ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionMemberAst]},$true)) {
    foreach ($attribute in $member.Attributes) {
        $kind = $attribute.TypeName.FullName.Split('.')[-1]
        if ($kind -notin @('LibraryImport','UnmanagedCallConv','UnmanagedCallersOnly')) { continue }
        $call = [NotepadSourceCall]::new()
        $call.Result = if ($member.ReturnType) { $member.ReturnType.TypeName.GetReflectionType() } else { [void] }
        $call.Indirect = $kind -eq 'UnmanagedCallConv'
        $arguments = @($member.Parameters | ForEach-Object { '$' + $_.Name.VariablePath.UserPath })
        $parameterTypes = @($member.Parameters | ForEach-Object { $_.StaticType })
        $call.Parameters = [type[]]@($parameterTypes | Select-Object -Skip ([int]$call.Indirect))
        if ($kind -eq 'LibraryImport') {
            $call.Library = $attribute.PositionalArguments[0].Value
            $call.Export = $member.Name
            foreach ($named in $attribute.NamedArguments) {
                if ($named.ArgumentName -ne 'EntryPoint') { throw ('Unsupported source interop option ' + $named.ArgumentName) }
                $call.Export = $named.Argument.Value
            }
        }
        $index = [NotepadSourceNative]::Calls.Count
        [NotepadSourceNative]::Calls.Add($call)
        Add-InteropEdit $attribute.Extent ''
        if ($kind -eq 'UnmanagedCallersOnly') {
            $callbacks.Add(($member.Parent.Name+'.'+$member.Name),$index)
        } else {
            $result = if ($call.Result -eq [void]) {'$null = '} else {'return '}
            $body = '{ ' + $result + '[NotepadSourceNative]::Invoke(' + $index + ', [object[]]@(' + ($arguments -join ', ') + ')) }'
            Add-InteropEdit $member.Body.Extent $body
        }
    }
}

foreach ($method in $ast.FindAll({param($node) $node -is [Management.Automation.Language.InvokeMemberExpressionAst] -and $node.Member.Extent.Text -ceq 'GetFunctionPointer'},$true)) {
    $handle = $method.Expression
    if ($handle -isnot [Management.Automation.Language.MemberExpressionAst] -or $handle.Member.Extent.Text -cne 'MethodHandle') { continue }
    $lookup = $handle.Expression
    if ($lookup -isnot [Management.Automation.Language.InvokeMemberExpressionAst] -or $lookup.Member.Extent.Text -cne 'GetMethod' -or
        $lookup.Expression -isnot [Management.Automation.Language.TypeExpressionAst] -or $lookup.Arguments.Count -ne 1) { continue }
    $key = $lookup.Expression.TypeName.FullName + '.' + $lookup.Arguments[0].Value
    if ($callbacks.ContainsKey($key)) {
        Add-InteropEdit $method.Extent ('[NotepadSourceNative]::Callback(' + $callbacks[$key] + ', ' + $lookup.Extent.Text + ')')
    }
}
foreach ($edit in ($edits | Sort-Object Start -Descending)) {
    $source = $source.Remove($edit.Start,$edit.Length).Insert($edit.Start,$edit.Text)
}
$ast = [Management.Automation.Language.Parser]::ParseInput($source,$sourcePath,[ref]$tokens,[ref]$errors)
if ($errors.Count) { throw $errors[0].Message }
& $ast.GetScriptBlock() @appParameters
