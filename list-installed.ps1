$progs = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
                          HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
                          HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
                          HKCU:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* 2>$null |
    Where-Object { $_.DisplayName } |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
    Sort-Object DisplayName -Unique

$md = "| Program | Version | Publisher | Date |`n"
$md += "| --- | --- | --- | --- |`n"
foreach ($p in $progs) {
    $md += "| $($p.DisplayName) | $($p.DisplayVersion) | $($p.Publisher) | $($p.InstallDate) |`n"
}

$md | Out-File -Encoding UTF8 installedprogs.md
