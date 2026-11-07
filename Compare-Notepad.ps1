# Compatibility entry point. The comparison engine is inline in Notepad.ps1.
[CmdletBinding()]
param(
    [string]$EvidenceDirectory=(Join-Path $PSScriptRoot 'evidence'),
    [switch]$KeepProbeOpen,[switch]$SkipBrowser,[switch]$ExtractTypeScript,
    [switch]$BuildTypeScript,[switch]$BuildDesign,[switch]$RefreshReal,[switch]$VerifyNativeFeatures,[switch]$CatalogIcons
)
& (Join-Path $PSScriptRoot 'Notepad.ps1') -Compare @PSBoundParameters
