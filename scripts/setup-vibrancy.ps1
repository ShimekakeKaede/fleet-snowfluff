# Fleet Snowfluff — install theme extension + Vibrancy overlay + recommended settings.
# Usage: from repo root  .\scripts\setup.ps1
#        (alias)     .\scripts\setup-vibrancy.ps1 [-CopyExtension] [-VsCodeToo]
#
# Deploys vibrancy/* → %APPDATA%\Cursor\User\fleet-snowfluff\
# Links (or copies) this repo as a local Cursor/VS Code extension (no VSIX).
# Merges recommended keys into User\settings.json.

param(
    [switch]$CopyExtension,
    [switch]$VsCodeToo
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$vibrancyRoot = Join-Path $projectRoot 'vibrancy'
$cssSource = Join-Path $vibrancyRoot 'css\opaque-chrome.css'
$jsSource = Join-Path $vibrancyRoot 'js\activity-global-menu.js'
$lineNumbersJsSource = Join-Path $vibrancyRoot 'js\editor-line-numbers.js'
$atmosphereTemplate = Join-Path $vibrancyRoot 'js\editor-atmosphere.template.js'
$mascotTemplate = Join-Path $vibrancyRoot 'templates\titlebar-mascot.css'
$homeWatermarkTemplate = Join-Path $vibrancyRoot 'templates\home-watermark.css'
$assetsDir = Join-Path $projectRoot 'assets'
$aemeathDir = Join-Path $assetsDir 'aemeath'
$dropingsDir = Join-Path $assetsDir 'dropings'
$mascotGlassInlineSource = Join-Path $aemeathDir 'Aemeath_GLASS_inline.gif'
$cursorForwardSource = Join-Path $aemeathDir 'Aemeath_FORWARD.gif'
$jumpSource = Join-Path $aemeathDir 'Aemeath_JUMP.gif'
$patchVanillaPath = Join-Path $projectRoot 'scripts\patches\vibrancy-injectHTML-vanilla.txt'
$patchFleetPath = Join-Path $projectRoot 'scripts\patches\vibrancy-injectHTML-fleet.mjs'
$packageJsonPath = Join-Path $projectRoot 'package.json'

if (-not (Test-Path $cssSource)) { Write-Error "Missing: $cssSource" }
if (-not (Test-Path $jsSource)) { Write-Error "Missing: $jsSource" }
if (-not (Test-Path $lineNumbersJsSource)) { Write-Error "Missing: $lineNumbersJsSource" }
if (-not (Test-Path $atmosphereTemplate)) { Write-Error "Missing: $atmosphereTemplate" }
if (-not (Test-Path $patchVanillaPath)) { Write-Error "Missing: $patchVanillaPath" }
if (-not (Test-Path $patchFleetPath)) { Write-Error "Missing: $patchFleetPath" }
if (-not (Test-Path $packageJsonPath)) { Write-Error "Missing: $packageJsonPath" }

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$maxEmbedBytes = 512000
$fleetThemeLabel = 'Fleet Snowfluff Dark'

$pkg = Get-Content $packageJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$extensionFolderName = ('{0}.{1}-{2}' -f $pkg.publisher, $pkg.name, $pkg.version)

function Get-FleetDataUri {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    $mime = switch ($ext) {
        '.gif' { 'image/gif' }
        '.png' { 'image/png' }
        '.webp' { 'image/webp' }
        default { 'application/octet-stream' }
    }
    return ('data:{0};base64,{1}' -f $mime, [Convert]::ToBase64String($bytes))
}

function Install-FleetThemeExtension {
    param(
        [string]$ExtensionsRoot,
        [string]$Mode
    )
    if (-not (Test-Path $ExtensionsRoot)) {
        New-Item -ItemType Directory -Force -Path $ExtensionsRoot | Out-Null
    }

    Get-ChildItem $ExtensionsRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'fleet-snowfluff.fleet-snowfluff-*' } |
        ForEach-Object { Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }

    $dest = Join-Path $ExtensionsRoot $extensionFolderName

    if ($Mode -eq 'copy') {
        New-Item -ItemType Directory -Force -Path $dest | Out-Null
        Copy-Item -Force $packageJsonPath (Join-Path $dest 'package.json')
        $license = Join-Path $projectRoot 'LICENSE'
        if (Test-Path $license) { Copy-Item -Force $license (Join-Path $dest 'LICENSE') }
        Copy-Item -Force (Join-Path $projectRoot 'themes') (Join-Path $dest 'themes') -Recurse
        Write-Host "Theme extension (copy): $dest"
        return
    }

    if (Test-Path $dest) { Remove-Item $dest -Force -ErrorAction SilentlyContinue }
    try {
        New-Item -ItemType Junction -Path $dest -Target $projectRoot | Out-Null
        Write-Host "Theme extension (junction → repo): $dest"
    } catch {
        Write-Warning "Junction failed ($($_.Exception.Message)); falling back to copy."
        Install-FleetThemeExtension -ExtensionsRoot $ExtensionsRoot -Mode 'copy'
    }
}

function Read-SettingsJson {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return New-Object PSObject }
    $raw = [System.IO.File]::ReadAllText($Path, $utf8NoBom)
    if ([string]::IsNullOrWhiteSpace($raw)) { return New-Object PSObject }
    return ($raw | ConvertFrom-Json)
}

function Set-JsonProperty {
    param($Object, [string]$Name, $Value)
    $existing = $Object.PSObject.Properties[$Name]
    if ($existing) {
        $existing.Value = $Value
    } else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
    }
}

function Merge-FleetSettings {
    param(
        [string]$SettingsPath,
        [string[]]$ImportPaths
    )

    $settings = Read-SettingsJson -Path $SettingsPath
    $settingsDir = Split-Path -Parent $SettingsPath
    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Force -Path $settingsDir | Out-Null
    }

    Set-JsonProperty $settings 'workbench.colorTheme' $fleetThemeLabel
    Set-JsonProperty $settings 'workbench.activityBar.orientation' 'vertical'
    Set-JsonProperty $settings 'window.titleBarStyle' 'custom'
    Set-JsonProperty $settings 'vscode_vibrancy.opacity' 0.7
    Set-JsonProperty $settings 'vscode_vibrancy.backgroundOverride' '#000000'
    Set-JsonProperty $settings 'vscode_vibrancy.enableAutoRefresh' $false
    Set-JsonProperty $settings 'vscode_vibrancy.disableFramelessWindow' $true
    Set-JsonProperty $settings 'vscode_vibrancy.imports' @($ImportPaths)

    $cc = $settings.'workbench.colorCustomizations'
    if (-not $cc) {
        $cc = New-Object PSObject
        Set-JsonProperty $settings 'workbench.colorCustomizations' $cc
    }
    $themeCc = $cc.PSObject.Properties[$fleetThemeLabel]
    if (-not $themeCc) {
        $themeObj = New-Object PSObject
        $themeObj | Add-Member -NotePropertyName 'terminal.background' -NotePropertyValue '#000000B3' -Force
        $themeObj | Add-Member -NotePropertyName 'panel.background' -NotePropertyValue '#000000B3' -Force
        $cc | Add-Member -NotePropertyName $fleetThemeLabel -NotePropertyValue $themeObj -Force
    } else {
        Set-JsonProperty $themeCc.Value 'terminal.background' '#000000B3'
        Set-JsonProperty $themeCc.Value 'panel.background' '#000000B3'
    }

    $json = $settings | ConvertTo-Json -Depth 32
    [System.IO.File]::WriteAllText($SettingsPath, $json, $utf8NoBom)
    Write-Host "Updated settings: $SettingsPath"
}

function Get-FleetImportPaths {
    param(
        [string]$FleetDir,
        [bool]$AtmosphereEnabled,
        [bool]$MascotEnabled,
        [bool]$HomeWatermarkEnabled
    )
    $paths = [System.Collections.Generic.List[string]]::new()
    [void]$paths.Add(((Join-Path $FleetDir 'vibrancy-opaque-chrome.css') -replace '\\', '/'))
    [void]$paths.Add(((Join-Path $FleetDir 'fleet-activity-global-menu.js') -replace '\\', '/'))
    [void]$paths.Add(((Join-Path $FleetDir 'fleet-editor-line-numbers.js') -replace '\\', '/'))
    if ($AtmosphereEnabled) {
        [void]$paths.Add(((Join-Path $FleetDir 'fleet-editor-atmosphere.js') -replace '\\', '/'))
    }
    if ($MascotEnabled) {
        [void]$paths.Add(((Join-Path $FleetDir 'fleet-titlebar-mascot.css') -replace '\\', '/'))
    }
    if ($HomeWatermarkEnabled) {
        [void]$paths.Add(((Join-Path $FleetDir 'fleet-home-watermark.css') -replace '\\', '/'))
    }
    return $paths
}

# ── Theme extension ─────────────────────────────────────────────────────────

$extMode = if ($CopyExtension) { 'copy' } else { 'junction' }
$cursorExtRoot = Join-Path $env:USERPROFILE '.cursor\extensions'
Install-FleetThemeExtension -ExtensionsRoot $cursorExtRoot -Mode $extMode

if ($VsCodeToo) {
    $codeExtRoot = Join-Path $env:USERPROFILE '.vscode\extensions'
    Install-FleetThemeExtension -ExtensionsRoot $codeExtRoot -Mode $extMode
}

# ── Vibrancy assets ─────────────────────────────────────────────────────────

$targetDir = Join-Path $env:APPDATA 'Cursor\User\fleet-snowfluff'
$cssTarget = Join-Path $targetDir 'vibrancy-opaque-chrome.css'
$jsTarget = Join-Path $targetDir 'fleet-activity-global-menu.js'
$lineNumbersJsTarget = Join-Path $targetDir 'fleet-editor-line-numbers.js'
$atmosphereJsTarget = Join-Path $targetDir 'fleet-editor-atmosphere.js'
$mascotCssTarget = Join-Path $targetDir 'fleet-titlebar-mascot.css'
$homeWatermarkCssTarget = Join-Path $targetDir 'fleet-home-watermark.css'

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
Copy-Item -Force $cssSource $cssTarget
Copy-Item -Force $jsSource $jsTarget
Copy-Item -Force $lineNumbersJsSource $lineNumbersJsTarget

$atmosphereEnabled = $false
if ((Test-Path $atmosphereTemplate) -and (Test-Path $cursorForwardSource)) {
    $cursorUri = Get-FleetDataUri $cursorForwardSource
    $dropUris = [System.Collections.Generic.List[string]]::new()
    if (Test-Path $dropingsDir) {
        Get-ChildItem $dropingsDir -File |
            Where-Object { $_.Extension -match '^\.(png|gif|webp)$' } |
            Sort-Object Name |
            ForEach-Object { [void]$dropUris.Add((Get-FleetDataUri $_.FullName)) }
    }
    $dropParts = [System.Collections.Generic.List[string]]::new()
    foreach ($uri in $dropUris) {
        $escaped = $uri.Replace('\', '\\').Replace('"', '\"')
        [void]$dropParts.Add('"' + $escaped + '"')
    }
    $dropJson = if ($dropParts.Count -eq 0) { '[]' } else { '[' + ($dropParts -join ',') + ']' }
    $atmosphereJs = [System.IO.File]::ReadAllText($atmosphereTemplate, [System.Text.Encoding]::UTF8)
    $atmosphereJs = $atmosphereJs.Replace('__FLEET_CURSOR_GIF_DATA_URI__', $cursorUri)
    $atmosphereJs = $atmosphereJs.Replace('__FLEET_DROPING_SPRITES_JSON__', $dropJson)
    [System.IO.File]::WriteAllText($atmosphereJsTarget, $atmosphereJs, $utf8NoBom)
    $atmosphereEnabled = $true
    Write-Host "Atmosphere JS: cursor Aemeath_FORWARD.gif, droppings $($dropUris.Count)"
} else {
    Write-Host 'Atmosphere JS skipped — add assets/aemeath/Aemeath_FORWARD.gif for GIF cursor (see MAINTENANCE.md).'
}

function Patch-VibrancyScriptExecution {
    $extRoots = @(
        (Join-Path $env:USERPROFILE '.cursor\extensions'),
        (Join-Path $env:USERPROFILE '.vscode\extensions')
    )

    $extDir = $null
    foreach ($root in $extRoots) {
        if (-not (Test-Path $root)) { continue }
        $match = Get-ChildItem $root -Filter 'illixion.vscode-vibrancy-continued-*' -Directory -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            Select-Object -First 1
        if ($match) {
            $extDir = $match.FullName
            break
        }
    }

    if (-not $extDir) {
        Write-Warning 'Vibrancy Continued not found. Install it from the marketplace, then re-run setup.'
        return $false
    }

    $vanillaBlock = ([System.IO.File]::ReadAllText($patchVanillaPath, [System.Text.Encoding]::UTF8) -replace "`r`n", "`n").TrimEnd()
    $fleetBlock = ([System.IO.File]::ReadAllText($patchFleetPath, [System.Text.Encoding]::UTF8) -replace "`r`n", "`n").TrimEnd()

    $patchedAny = $false
    foreach ($runtime in @('runtime/index.mjs', 'runtime-pre-esm/index.cjs')) {
        $path = Join-Path $extDir $runtime
        if (-not (Test-Path $path)) { continue }

        $content = ([System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8) -replace "`r`n", "`n")
        if ($content -match 'function extractImportScripts') {
            Write-Host "Vibrancy runtime already patched (skip): $path"
            $patchedAny = $true
            continue
        }

        if (-not $content.Contains($vanillaBlock)) {
            Write-Warning "Unexpected Vibrancy runtime format; manual patch may be needed: $path"
            continue
        }

        $content = $content.Replace($vanillaBlock, $fleetBlock)
        [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
        Write-Host "Patched Vibrancy runtime: $path"
        $patchedAny = $true
    }

    if ($patchedAny) {
        Write-Host 'Fleet patch applied: JS imports run inline inside Vibrancy executeJavaScript.'
    }
    return $patchedAny
}

Patch-VibrancyScriptExecution | Out-Null

$mascotEnabled = $false

if ((Test-Path $mascotTemplate) -and (Test-Path $mascotGlassInlineSource)) {
    $gifBytes = [System.IO.File]::ReadAllBytes($mascotGlassInlineSource)
    if ($gifBytes.Length -gt $maxEmbedBytes) {
        Write-Warning "Aemeath_GLASS_inline.gif exceeds ${maxEmbedBytes} bytes; title bar mascot skipped."
    } else {
        $dataUri = 'url("data:image/gif;base64,' + [Convert]::ToBase64String($gifBytes) + '")'
        $mascotCss = [System.IO.File]::ReadAllText($mascotTemplate, [System.Text.Encoding]::UTF8)
        $mascotCss = $mascotCss.Replace('__FLEET_MASCOT_DATA_URI__', $dataUri)
        [System.IO.File]::WriteAllText($mascotCssTarget, $mascotCss, $utf8NoBom)
        $mascotEnabled = $true
        Write-Host 'Mascot CSS (Aemeath_GLASS_inline.gif)'
    }
} elseif (Test-Path $mascotTemplate) {
    Write-Host 'Title bar mascot skipped — optional assets/aemeath/Aemeath_GLASS_inline.gif.'
}

$homeWatermarkEnabled = $false

if ((Test-Path $homeWatermarkTemplate) -and (Test-Path $jumpSource)) {
    $jumpBytes = [System.IO.File]::ReadAllBytes($jumpSource)
    if ($jumpBytes.Length -gt $maxEmbedBytes) {
        Write-Warning "Aemeath_JUMP.gif exceeds ${maxEmbedBytes} bytes; home watermark skipped."
    } else {
        $jumpDataUri = 'url("data:image/gif;base64,' + [Convert]::ToBase64String($jumpBytes) + '")'
        $homeWatermarkCss = [System.IO.File]::ReadAllText($homeWatermarkTemplate, [System.Text.Encoding]::UTF8)
        $homeWatermarkCss = $homeWatermarkCss.Replace('__FLEET_HOME_WATERMARK_DATA_URI__', $jumpDataUri)
        [System.IO.File]::WriteAllText($homeWatermarkCssTarget, $homeWatermarkCss, $utf8NoBom)
        $homeWatermarkEnabled = $true
        Write-Host 'Home watermark CSS (Aemeath_JUMP.gif)'
    }
} elseif (Test-Path $homeWatermarkTemplate) {
    Write-Host 'Home watermark skipped — optional assets/aemeath/Aemeath_JUMP.gif.'
}

$importPaths = Get-FleetImportPaths `
    -FleetDir $targetDir `
    -AtmosphereEnabled $atmosphereEnabled `
    -MascotEnabled $mascotEnabled `
    -HomeWatermarkEnabled $homeWatermarkEnabled

$cursorSettings = Join-Path $env:APPDATA 'Cursor\User\settings.json'
try {
    Merge-FleetSettings -SettingsPath $cursorSettings -ImportPaths $importPaths
} catch {
    Write-Warning "Could not update Cursor settings.json: $_"
}

if ($VsCodeToo) {
    $codeSettings = Join-Path $env:APPDATA 'Code\User\settings.json'
    $codeFleetDir = Join-Path $env:APPDATA 'Code\User\fleet-snowfluff'
    if (-not (Test-Path $codeFleetDir)) { New-Item -ItemType Directory -Force -Path $codeFleetDir | Out-Null }
    Copy-Item -Force $cssTarget (Join-Path $codeFleetDir 'vibrancy-opaque-chrome.css')
    Copy-Item -Force $jsTarget (Join-Path $codeFleetDir 'fleet-activity-global-menu.js')
    Copy-Item -Force $lineNumbersJsTarget (Join-Path $codeFleetDir 'fleet-editor-line-numbers.js')
    if ($atmosphereEnabled) { Copy-Item -Force $atmosphereJsTarget (Join-Path $codeFleetDir 'fleet-editor-atmosphere.js') }
    if ($mascotEnabled) { Copy-Item -Force $mascotCssTarget (Join-Path $codeFleetDir 'fleet-titlebar-mascot.css') }
    if ($homeWatermarkEnabled) { Copy-Item -Force $homeWatermarkCssTarget (Join-Path $codeFleetDir 'fleet-home-watermark.css') }
    $codeImports = Get-FleetImportPaths -FleetDir $codeFleetDir -AtmosphereEnabled $atmosphereEnabled -MascotEnabled $mascotEnabled -HomeWatermarkEnabled $homeWatermarkEnabled
    try {
        Merge-FleetSettings -SettingsPath $codeSettings -ImportPaths $codeImports
    } catch {
        Write-Warning "Could not update VS Code settings.json: $_"
    }
}

# ── Summary ─────────────────────────────────────────────────────────────────

Write-Host ''
Write-Host '=== Fleet Snowfluff installed ==='
Write-Host ''
Write-Host 'Deployed overlay:'
Write-Host "  $targetDir"
Write-Host ''
Write-Host 'Next steps (first time):'
Write-Host '  1. Command Palette → Vibrancy: Enable'
Write-Host '  2. Command Palette → Vibrancy: Reload'
Write-Host '  3. Fully quit Cursor (tray icon too), then start again'
Write-Host ''
Write-Host 'After git pull / local edits:'
Write-Host '  Re-run .\scripts\setup.ps1 → Vibrancy: Reload → cold start'
Write-Host '  (Theme junction points at this repo; Reload Window picks up theme JSON changes.)'
Write-Host ''
if (-not $atmosphereEnabled) {
    Write-Host 'Optional: add GIF assets per MAINTENANCE.md, then re-run setup for cursor / mascot / watermark.'
    Write-Host ''
}
