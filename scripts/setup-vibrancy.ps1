# Install Fleet Snowfluff Vibrancy assets into the Cursor user directory (stable paths).
# Usage: from repo root  .\scripts\setup-vibrancy.ps1
#
# Copies themes/* sources → %APPDATA%\Cursor\User\fleet-snowfluff\
# Generates: fleet-editor-atmosphere.js, fleet-titlebar-mascot.css, fleet-home-watermark.css
# Patches: Vibrancy Continued runtime (JS imports run inline under Cursor CSP)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$cssSource = Join-Path $projectRoot 'themes\vibrancy-opaque-chrome.css'
$jsSource = Join-Path $projectRoot 'themes\fleet-activity-global-menu.js'
$lineNumbersJsSource = Join-Path $projectRoot 'themes\fleet-editor-line-numbers.js'
$atmosphereTemplate = Join-Path $projectRoot 'themes\fleet-editor-atmosphere.template.js'
$mascotTemplate = Join-Path $projectRoot 'themes\fleet-titlebar-mascot.template.css'
$homeWatermarkTemplate = Join-Path $projectRoot 'themes\fleet-home-watermark.template.css'
$assetsDir = Join-Path $projectRoot 'assets'
$aemeathDir = Join-Path $assetsDir 'aemeath'
$dropingsDir = Join-Path $assetsDir 'dropings'
$mascotGlassSource = Join-Path $aemeathDir 'Aemeath_GLASS.gif'
$mascotGlassTitlebarSource = Join-Path $aemeathDir 'Aemeath_GLASS_titlebar.gif'
$mascotFlySource = Join-Path $aemeathDir 'Aemeath_FLY.gif'
$cursorInlineSource = Join-Path $aemeathDir 'Aemeath_FLY_inline.gif'
$jumpSource = Join-Path $aemeathDir 'Aemeath_JUMP.gif'
$optimizeScript = Join-Path $projectRoot 'scripts\optimize-titlebar-gif.py'
$patchVanillaPath = Join-Path $projectRoot 'scripts\patches\vibrancy-injectHTML-vanilla.txt'
$patchFleetPath = Join-Path $projectRoot 'scripts\patches\vibrancy-injectHTML-fleet.mjs'

if (-not (Test-Path $cssSource)) { Write-Error "Missing: $cssSource" }
if (-not (Test-Path $jsSource)) { Write-Error "Missing: $jsSource" }
if (-not (Test-Path $lineNumbersJsSource)) { Write-Error "Missing: $lineNumbersJsSource" }
if (-not (Test-Path $atmosphereTemplate)) { Write-Error "Missing: $atmosphereTemplate" }
if (-not (Test-Path $patchVanillaPath)) { Write-Error "Missing: $patchVanillaPath" }
if (-not (Test-Path $patchFleetPath)) { Write-Error "Missing: $patchFleetPath" }

$targetDir = Join-Path $env:APPDATA 'Cursor\User\fleet-snowfluff'
$cssTarget = Join-Path $targetDir 'vibrancy-opaque-chrome.css'
$jsTarget = Join-Path $targetDir 'fleet-activity-global-menu.js'
$lineNumbersJsTarget = Join-Path $targetDir 'fleet-editor-line-numbers.js'
$atmosphereJsTarget = Join-Path $targetDir 'fleet-editor-atmosphere.js'
$mascotCssTarget = Join-Path $targetDir 'fleet-titlebar-mascot.css'
$homeWatermarkCssTarget = Join-Path $targetDir 'fleet-home-watermark.css'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$maxEmbedBytes = 512000

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

Copy-Item -Force $cssSource $cssTarget
Copy-Item -Force $jsSource $jsTarget
Copy-Item -Force $lineNumbersJsSource $lineNumbersJsTarget

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

$atmosphereEnabled = $false
if ((Test-Path $atmosphereTemplate) -and (Test-Path $cursorInlineSource)) {
    $cursorUri = Get-FleetDataUri $cursorInlineSource
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
    if ($dropParts.Count -eq 0) {
        $dropJson = '[]'
    } else {
        $dropJson = '[' + ($dropParts -join ',') + ']'
    }
    $atmosphereJs = [System.IO.File]::ReadAllText($atmosphereTemplate, [System.Text.Encoding]::UTF8)
    $atmosphereJs = $atmosphereJs.Replace('__FLEET_CURSOR_GIF_DATA_URI__', $cursorUri)
    $atmosphereJs = $atmosphereJs.Replace('__FLEET_DROPING_SPRITES_JSON__', $dropJson)
    [System.IO.File]::WriteAllText($atmosphereJsTarget, $atmosphereJs, $utf8NoBom)
    $atmosphereEnabled = $true
    Write-Host "Atmosphere JS: cursor Aemeath_FLY_inline.gif, droppings $($dropUris.Count)"
} else {
    Write-Host 'Atmosphere JS skipped (missing template or assets/aemeath/Aemeath_FLY_inline.gif).'
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
        Write-Warning 'Vibrancy Continued not found. Install the extension, then re-run this script.'
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
$mascotImportPath = $null
$embedName = $null

if (Test-Path $mascotTemplate) {
    if (-not (Test-Path $mascotGlassTitlebarSource) -and (Test-Path $optimizeScript) -and (Test-Path $mascotGlassSource)) {
        $python = Get-Command python -ErrorAction SilentlyContinue
        if ($python) {
            Write-Host 'Generating Aemeath_GLASS_titlebar.gif...'
            & $python.Source $optimizeScript
        }
    }

    $embedSource = $null
    if (Test-Path $mascotFlySource) {
        $embedSource = $mascotFlySource
        $embedName = 'Aemeath_FLY.gif'
    }
    if (Test-Path $mascotGlassTitlebarSource) {
        $embedSource = $mascotGlassTitlebarSource
        $embedName = 'Aemeath_GLASS_titlebar.gif'
    } elseif (Test-Path $mascotGlassSource) {
        $glassSize = (Get-Item $mascotGlassSource).Length
        if ($glassSize -le $maxEmbedBytes) {
            $embedSource = $mascotGlassSource
            $embedName = 'Aemeath_GLASS.gif'
        }
    }

    if ($embedSource) {
        $gifBytes = [System.IO.File]::ReadAllBytes($embedSource)
        $gifBase64 = [Convert]::ToBase64String($gifBytes)
        $dataUri = 'url("data:image/gif;base64,' + $gifBase64 + '")'
        $mascotCss = [System.IO.File]::ReadAllText($mascotTemplate, [System.Text.Encoding]::UTF8)
        $mascotCss = $mascotCss.Replace('__FLEET_MASCOT_DATA_URI__', $dataUri)
        [System.IO.File]::WriteAllText($mascotCssTarget, $mascotCss, $utf8NoBom)
        $mascotEnabled = $true
        $mascotImportPath = ($mascotCssTarget -replace '\\', '/')
    } else {
        Write-Host 'Title bar mascot skipped (no GIF under assets/aemeath/).'
    }
}

$homeWatermarkEnabled = $false
$homeWatermarkImportPath = $null

if ((Test-Path $homeWatermarkTemplate) -and (Test-Path $jumpSource)) {
    $jumpBytes = [System.IO.File]::ReadAllBytes($jumpSource)
    if ($jumpBytes.Length -gt $maxEmbedBytes) {
        Write-Warning "Aemeath_JUMP.gif exceeds ${maxEmbedBytes} bytes; home watermark skipped."
    } else {
        $jumpBase64 = [Convert]::ToBase64String($jumpBytes)
        $jumpDataUri = 'url("data:image/gif;base64,' + $jumpBase64 + '")'
        $homeWatermarkCss = [System.IO.File]::ReadAllText($homeWatermarkTemplate, [System.Text.Encoding]::UTF8)
        $homeWatermarkCss = $homeWatermarkCss.Replace('__FLEET_HOME_WATERMARK_DATA_URI__', $jumpDataUri)
        [System.IO.File]::WriteAllText($homeWatermarkCssTarget, $homeWatermarkCss, $utf8NoBom)
        $homeWatermarkEnabled = $true
        $homeWatermarkImportPath = ($homeWatermarkCssTarget -replace '\\', '/')
    }
} elseif (Test-Path $homeWatermarkTemplate) {
    Write-Host 'Home watermark skipped (missing assets/aemeath/Aemeath_JUMP.gif).'
}

$cssImportPath = ($cssTarget -replace '\\', '/')
$jsImportPath = ($jsTarget -replace '\\', '/')
$lineNumbersJsImportPath = ($lineNumbersJsTarget -replace '\\', '/')
$atmosphereJsImportPath = ($atmosphereJsTarget -replace '\\', '/')

$settingsPath = Join-Path $env:APPDATA 'Cursor\User\settings.json'
if (Test-Path $settingsPath) {
    try {
        $settingsRaw = [System.IO.File]::ReadAllText($settingsPath, [System.Text.Encoding]::UTF8)
        $settings = $settingsRaw | ConvertFrom-Json
        $imports = @($settings.'vscode_vibrancy.imports')
        $desired = [System.Collections.Generic.List[string]]::new()
        [void]$desired.Add($cssImportPath)
        [void]$desired.Add($jsImportPath)
        [void]$desired.Add($lineNumbersJsImportPath)
        if ($atmosphereEnabled) { [void]$desired.Add($atmosphereJsImportPath) }
        if ($mascotEnabled) { [void]$desired.Add($mascotImportPath) }
        if ($homeWatermarkEnabled) { [void]$desired.Add($homeWatermarkImportPath) }

        $needsUpdate = $false
        foreach ($path in $desired) {
            if ($imports -notcontains $path) {
                $needsUpdate = $true
                break
            }
        }

        if ($needsUpdate) {
            $merged = [System.Collections.Generic.List[string]]::new()
            foreach ($path in $desired) {
                if (-not $merged.Contains($path)) { [void]$merged.Add($path) }
            }
            foreach ($path in $imports) {
                if ($path -and (-not $merged.Contains($path))) {
                    [void]$merged.Add($path)
                }
            }
            $settings.'vscode_vibrancy.imports' = @($merged)
            $updatedJson = $settings | ConvertTo-Json -Depth 20
            [System.IO.File]::WriteAllText($settingsPath, $updatedJson, $utf8NoBom)
            Write-Host 'Updated vscode_vibrancy.imports in settings.json.'
        }
    } catch {
        Write-Warning "Could not update settings.json: $_"
    }
}

Write-Host ''
Write-Host 'Installed:'
Write-Host "  CSS:  $cssTarget"
Write-Host "  JS:   $jsTarget"
Write-Host "  Line numbers JS: $lineNumbersJsTarget"
if ($atmosphereEnabled) {
    Write-Host "  Atmosphere JS: $atmosphereJsTarget"
}
if ($mascotEnabled) {
    Write-Host "  Mascot CSS ($embedName): $mascotCssTarget"
}
if ($homeWatermarkEnabled) {
    Write-Host "  Home watermark CSS (Aemeath_JUMP.gif): $homeWatermarkCssTarget"
}
Write-Host ''
Write-Host 'Add to vscode_vibrancy.imports (forward slashes on Windows):'
Write-Host ''
Write-Host '  "vscode_vibrancy.imports": ['
$importLines = [System.Collections.Generic.List[string]]::new()
[void]$importLines.Add($cssImportPath)
[void]$importLines.Add($jsImportPath)
[void]$importLines.Add($lineNumbersJsImportPath)
if ($atmosphereEnabled) { [void]$importLines.Add($atmosphereJsImportPath) }
if ($mascotEnabled) { [void]$importLines.Add($mascotImportPath) }
if ($homeWatermarkEnabled) { [void]$importLines.Add($homeWatermarkImportPath) }
for ($i = 0; $i -lt $importLines.Count; $i++) {
    $comma = if ($i -lt $importLines.Count - 1) { ',' } else { '' }
    Write-Host ('    "' + $importLines[$i] + '"' + $comma)
}
Write-Host '  ]'
Write-Host ''
Write-Host 'Then: Vibrancy Reload, then fully quit and restart Cursor.'
