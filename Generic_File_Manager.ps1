# Generic File Manager V1.0
# Manual cleanup using the current user's file permissions.
$ErrorActionPreference = 'Stop'
$cfg = @{ Folder=''; Limit=10; From=$null; To=$null; Extension='*'; Recursive=$false; Mode='RecycleBin' }
function Pause-Menu { [void](Read-Host 'Press Enter to continue') }
function Get-Candidates {
    if (-not $cfg.Folder -or -not (Test-Path -LiteralPath $cfg.Folder -PathType Container)) { throw 'Choose an existing folder first.' }
    @(Get-ChildItem -LiteralPath $cfg.Folder -File -Recurse:$cfg.Recursive -ErrorAction Stop |
        Where-Object { ($cfg.Extension -eq '*' -or $_.Extension -ieq $cfg.Extension) -and
            ($null -eq $cfg.From -or $_.LastWriteTime.Date -ge $cfg.From.Date) -and
            ($null -eq $cfg.To -or $_.LastWriteTime.Date -le $cfg.To.Date) } |
        Sort-Object LastWriteTime, FullName | Select-Object -First $cfg.Limit)
}
function Read-DateFilter([string]$label) {
    $s = Read-Host "$label (YYYY-MM-DD, blank = no limit)"
    if ([string]::IsNullOrWhiteSpace($s)) { return $null }
    $d = [datetime]::MinValue
    if (-not [datetime]::TryParseExact($s,'yyyy-MM-dd',[cultureinfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$d)) { throw 'Invalid date format.' }
    $d
}
try {
    while ($true) {
        Clear-Host
        Write-Host '========== GENERIC FILE MANAGER V1.0 ==========' -ForegroundColor Cyan
        Write-Host "Folder: $($cfg.Folder)"
        Write-Host "Limit: $($cfg.Limit) | Extension: $($cfg.Extension) | Subfolders: $($cfg.Recursive)"
        Write-Host "Modified from: $($cfg.From) | through: $($cfg.To)"
        Write-Host "Deletion mode: $($cfg.Mode)"
        Write-Host '1. Choose folder'
        Write-Host '2. Configure filters and limit'
        Write-Host '3. Preview matching files'
        Write-Host '4. Delete matching files (confirmation required)'
        Write-Host '5. Set deletion mode (Recycle Bin / Permanent)'
        Write-Host '6. Exit'
        $choice = Read-Host 'Choose 1-6'
        try {
            switch ($choice) {
                '1' {
                    $p = (Read-Host 'Enter full folder path').Trim('"')
                    if (-not (Test-Path -LiteralPath $p -PathType Container)) { throw 'Folder does not exist.' }
                    $cfg.Folder = (Resolve-Path -LiteralPath $p).Path
                    Write-Host 'Folder selected.' -ForegroundColor Green; Pause-Menu
                }
                '2' {
                    $n = Read-Host 'Maximum files to select (1-1000)'
                    $num = 0
                    if (-not [int]::TryParse($n,[ref]$num) -or $num -lt 1 -or $num -gt 1000) { throw 'Enter a number from 1 to 1000.' }
                    $from = Read-DateFilter 'Earliest modified date'
                    $to = Read-DateFilter 'Latest modified date'
                    if ($from -and $to -and $from -gt $to) { throw 'Earliest date cannot be after latest date.' }
                    $ext = (Read-Host 'Extension (.log, .txt, etc.; * for all)').Trim()
                    if ($ext -ne '*' -and $ext -notmatch '^\.[a-zA-Z0-9_-]+$') { throw 'Use * or a single extension such as .log.' }
                    $rec = Read-Host 'Include subfolders? (Y/N)'
                    if ($rec -notmatch '^[YyNn]$') { throw 'Enter Y or N.' }
                    $cfg.Limit=$num; $cfg.From=$from; $cfg.To=$to; $cfg.Extension=$ext; $cfg.Recursive=($rec -match '^[Yy]$')
                    Write-Host 'Settings saved for this session.' -ForegroundColor Green; Pause-Menu
                }
                '3' {
                    $items = @(Get-Candidates)
                    if ($items.Count) { $items | Select-Object LastWriteTime,Length,FullName | Format-Table -Wrap -AutoSize | Out-Host }
                    else { Write-Host 'No matching files.' }
                    Write-Host "Selected $($items.Count) file(s)."; Pause-Menu
                }
                '4' {
                    $items = @(Get-Candidates)
                    if (-not $items.Count) { Write-Host 'No matching files.'; Pause-Menu; break }
                    $items | Select-Object LastWriteTime,Length,FullName | Format-Table -Wrap -AutoSize | Out-Host
                    Write-Host "About to process $($items.Count) file(s) using $($cfg.Mode) mode." -ForegroundColor Yellow
                    if ((Read-Host 'Type DELETE to proceed') -cne 'DELETE') { Write-Host 'Cancelled.'; Pause-Menu; break }
                    $ok=0; $fail=0
                    foreach ($f in $items) {
                        try {
                            if ($cfg.Mode -eq 'RecycleBin') {
                                if ($f.FullName.StartsWith('\')) { throw 'Recycle Bin mode does not support network paths.' }
                                Add-Type -AssemblyName Microsoft.VisualBasic
                                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($f.FullName, 'OnlyErrorDialogs', 'SendToRecycleBin')
                            } else { Remove-Item -LiteralPath $f.FullName -ErrorAction Stop }
                            $ok++
                        } catch { $fail++; Write-Host "FAILED: $($f.FullName) - $($_.Exception.Message)" -ForegroundColor Red }
                    }
                    Write-Host "Finished. Processed: $ok | Failed: $fail"; Pause-Menu
                }
                '5' {
                    $mode = Read-Host 'Type R for Recycle Bin or P for permanent deletion'
                    if ($mode -eq 'R') { $cfg.Mode='RecycleBin' }
                    elseif ($mode -eq 'P') { $cfg.Mode='Permanent' }
                    else { throw 'Enter R or P.' }
                    Write-Host "Mode set to $($cfg.Mode)."; Pause-Menu
                }
                '6' { return }
                default { Write-Host 'Choose 1-6.'; Pause-Menu }
            }
        } catch { Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red; Pause-Menu }
    }
} catch { Write-Host "Unexpected error: $($_.Exception.Message)" -ForegroundColor Red; Pause-Menu }
