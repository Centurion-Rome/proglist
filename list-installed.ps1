$outFile = Join-Path $PSScriptRoot "installedprogs.md"

$md = "# Installed Programs`n`n"
$md += "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_`n`n"

# --- Installed Programs ---
$progs = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
                          HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
                          HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
                          HKCU:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* 2>$null |
    Where-Object { $_.DisplayName } |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation |
    Sort-Object DisplayName -Unique

$md += "## Installed Programs`n`n"
$md += "| Program | Version | Publisher | Date |`n"
$md += "| --- | --- | --- | --- |`n"
foreach ($p in $progs) {
    $md += "| $($p.DisplayName) | $($p.DisplayVersion) | $($p.Publisher) | $($p.InstallDate) |`n"
}

# --- Startup Programs ---
$md += "`n## Startup Programs`n`n"

$md += "### Registry (HKCU)`n`n"
$md += "| Name | Path |`n| --- | --- |`n"
$regHKCU = Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run 2>$null
$regHKCU.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
    $md += "| $($_.Name) | $($_.Value) |`n"
}

$md += "`n### Registry (HKLM)`n`n"
$md += "| Name | Path |`n| --- | --- |`n"
$regHKLM = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Run 2>$null
$regHKLM.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
    $md += "| $($_.Name) | $($_.Value) |`n"
}

$md += "`n### Startup Folder`n`n"
$md += "| Name | Path |`n| --- | --- |`n"
$startupPaths = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
)
foreach ($sp in $startupPaths) {
    Get-ChildItem $sp -File -ErrorAction SilentlyContinue | ForEach-Object {
        $md += "| $($_.Name) | $($_.FullName) |`n"
    }
}

# --- License Keys ---
$md += "`n## License Information`n`n"

$os = Get-WmiObject Win32_OperatingSystem
$md += "| Item | Value |`n| --- | --- |`n"
$md += "| Windows Name | $($os.Caption) |`n"
$md += "| Serial Number | $($os.SerialNumber) |`n"
$md += "| OS Version | $($os.Version) |`n"
$md += "| Build | $($os.BuildNumber) |`n"

$license = Get-WmiObject -Query "SELECT Name, Description, PartialProductKey, LicenseStatus FROM SoftwareLicensingProduct WHERE PartialProductKey IS NOT NULL" 2>$null
if ($license) {
    foreach ($l in $license) {
        $status = switch ($l.LicenseStatus) {
            0 { "Unlicensed" }
            1 { "Licensed" }
            2 { "OOBGrace" }
            3 { "OOTGrace" }
            4 { "NonGenuineGrace" }
            5 { "Notification" }
            6 { "ExtendedGrace" }
            default { "Unknown" }
        }
        $md += "| $($l.Name) | Status: $status, Key: $($l.PartialProductKey) |`n"
    }
}

# --- Portable Apps ---
$md += "`n## Portable Apps`n`n"
$md += "_Detected from common portable locations (F:\Programs, E:\Programs)_`n`n"

$portableRoots = @("F:\Programs", "E:\Programs") | Where-Object { Test-Path $_ }
$md += "| Name | Path |`n| --- | --- |`n"
foreach ($root in $portableRoots) {
    Get-ChildItem $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $exe = Get-ChildItem $_.FullName -Filter "*.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($exe) {
            $md += "| $($_.Name) | $($exe.FullName) |`n"
        }
    }
}

# --- Available Updates ---
$md += "`n## Available Updates`n`n"
$md += "_Checked via `winget upgrade`_`n`n"

$wingetOut = winget upgrade 2>$null
$updates = @()
$inTable = $false
foreach ($line in $wingetOut) {
    if ($line -match '^-{5,}') { $inTable = $true; continue }
    if ($inTable -and $line.Trim()) {
        $parts = $line -split '\s{2,}'
        if ($parts.Count -ge 4) {
            $updates += [PSCustomObject]@{
                Name    = $parts[0]
                ID      = $parts[1]
                Current = $parts[2]
                Version = $parts[3]
                Source  = if ($parts.Count -ge 5) { $parts[4] } else { "" }
            }
        }
    }
}

if ($updates.Count -gt 0) {
    $md += "| Program | ID | Installed | Available | Source |`n"
    $md += "| --- | --- | --- | --- | --- |`n"
    foreach ($u in $updates) {
        $md += "| $($u.Name) | $($u.ID) | $($u.Current) | $($u.Version) | $($u.Source) |`n"
    }
    $md += "`n_$($updates.Count) update(s) available_`n"
} else {
    $md += "_No updates available or winget not found._`n"
}

$md | Out-File -Encoding UTF8 $outFile
Write-Host "Saved to $outFile" -ForegroundColor Green
