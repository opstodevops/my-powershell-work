# Function will check for SMB value in registry
function Enable-SMBv2 {
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
$Name = "SMB2"
$Value = "1"
$SMBKey = Get-Item -Path $registryPath
    if($SMBKey.GetValue("SMB2") -eq $null) {
        New-ItemProperty -Path $registryPath -Name $Name -Value $Value -PropertyType DWORD -Force | Out-Null
    } else {
        Set-ItemProperty -Path $registryPath -Name $Name -Value -Force | Out-Null
    }
}

# This part will run the Enable-SMBv2 function using PowerShell background jobs & return failure
foreach ($server in @('server01', 'server02', 'server03')) { # Shown as example, there are plenty of other ways to pull in servers
    Invoke-Command -ComputerName $server -ScriptBlock ${Function:Enable-SMBv2} -AsJob | Out-Null
}

Get-Job | Wait-Job | Out-Null

[psobjectect]$failedjobs = @()
[psobjectect]$SMBstatus = @()

IF ((Get-Job -State Failed).count -ne 0) {
    foreach ($failure in (Get-Job -State Failed)) {
        $failedjobs += New-Object psobject -Property @{
            'Server' = $failure.Location
            'Failure' = ($Failure.ChildJobs.JobStateInfo.Reason.Transportmessage)
            }
        }
    }

$SMBstatus += foreach ($Job in Get-Job) {
    Receive-Job $Job -ErrorAction SilentlyContinue
    Remove-Job $Job
}

$SMBstatus

if ($failedjobs) {
    Write-Output `n'Check the failures below...'`n
    $failedjobs | Format-Table -AutoSize
}

