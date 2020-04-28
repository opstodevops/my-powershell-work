IF (!(Get-Module "ActiveDirecory")) {Import-module ActiveDirectory}  
 
[psobject]$JobFailures = @() 
[psobject]$SMBStatus = @() 
 
$ADComputerProperties = @('Name','OperatingSystem', 'OperatingSystemVersion') 
$ListOfServers = Get-ADComputer -Filter {Name -like '*NY*' -and OperatingSystemVersion -like '6.3*'} -SearchBase  'OU=Servers,OU=NY,DC=contoso,DC=com' -Properties $ADComputerProperties |  
    Select -Property $ADComputerProperties 
 
foreach ($Server in $ListOfServers.Name) { 
    ICM -ComputerName $Server -ScriptBlock{Get-SmbServerConfiguration | Select EnableSMB2Protocol} -AsJob | Out-Null 
} 
 
Get-Job | Wait-Job | Out-Null 
 
IF ((Get-Job -State Failed).count -ne 0) { 
    foreach ($Failure in (Get-Job -State Failed)) { 
        $JobFailures += New-Object psobject -Property @{ 
            'Server' = $Failure.Location 
            'Failure' = ($Failure.ChildJobs.JobStateInfo.Reason.Transportmessage) 
        } 
    } 
 
} 
 
$SMBStatus += foreach ($Job in Get-Job) { 
    Receive-Job $Job -ErrorAction SilentlyContinue 
    Remove-Job $Job 
    } 
 
#Clear-Host 
IF ($JobFailures) { 
    Write-Host `n'Check the failures below....'`n -ForegroundColor Red 
    $JobFailures | ft -AutoSize 
}  
 
$SMBStatus | select @{Name='Server';Expression='PSComputerName'}, @{Name='SMBv2Status';Expression='EnableSMB2Protocol'} | ft -AutoSize 
$ListOfServers.Clear() 
 
 
######################################################################################## 
 
foreach ($Server in $serverList.Name) { 
    ICM -ComputerName $Server -ScriptBlock{Get-SmbServerConfiguration | Select EnableSMB2Protocol} -AsJob | Out-Null 
} 
 
Get-Job | Wait-Job | Out-Null 
 
IF ((Get-Job -State Failed).count -ne 0) { 
    foreach ($Failure in (Get-Job -State Failed)) { 
        $JobFailures += New-Object psobject -Property @{ 
            'Server' = $Failure.Location 
            'Failure' = ($Failure.ChildJobs.JobStateInfo.Reason.Transportmessage) 
        } 
    } 
 
} 
 
$SMBStatus += foreach ($Job in Get-Job) { 
    Receive-Job $Job -ErrorAction SilentlyContinue 
    Remove-Job $Job 
    } 
 
#Clear-Host 
IF ($JobFailures) { 
    Write-Host `n'Check the failures below....'`n -ForegroundColor Red 
    $JobFailures | ft -AutoSize 
}  
 
$SMBStatus 
 
############################################################## 
 
$ADProperties = @('Name', 'OperatingSystem', 'OperatingSystemVersion') 
#$listOf2012 = Get-ADComputer -Filter {Name -like '*NY*' -and OperatingSystemVersion -like '6.3*'} -SearchBase 'OU=Servers,OU=NY,DC=contoso,DC=com' -Properties $ADProperties | select $ADProperties 
$listOf2008 = Get-ADComputer -Filter {Name -like '*NY*' -and OperatingSystemVersion -like '6.0*'} -SearchBase 'OU=Servers,OU=NY,DC=contosotest,DC=com' -Properties $ADProperties | select $ADProperties 
$listOf2008R2 = Get-ADComputer -Filter {Name -like '*NY*' -and OperatingSystemVersion -like '6.1*'} -SearchBase 'OU=Servers,OU=NY,DC=contosotest,DC=com' -Properties $ADProperties | select $ADProperties 
 
 
 
Get-ADComputer -Filter {Name -like '*NY*' -and OperatingSystemVersion -like '6.0*' -or OperatingSystemVersion -like '6.1*'} -SearchBase 'OU=Backup,OU=Servers,OU=NY,DC=contoso,DC=com' -Properties $ADProperties | select $ADProperties 
 
  10 $s = New-PSSession -ComputerName rmpnz002akl0002 
  15 Import-PSSession -Session $s -Module smbshare 
  17 Get-SmbServerConfiguration | Select EnableSMB2Protocol 
  18 Get-SmbServerConfiguration | ft EnableSMB2Protocol -AutoSize 
  19 Get-SmbServerConfiguration | ft EnableSMB1Protocol -AutoSize 
  20 Get-SmbServerConfiguration | ft EnableSMB2Protocol -AutoSize 
 
 
$dcSession = New-PSSession –ComputerName DC1 
Invoke-Command –Session $dcSession –ScriptBlock {Import-Module ActiveDir*} 
Import-PSSession –Session $dcSession –Module ActiveDir* 
 
# NEW SCRIPT  
function Enable-SMBv2 { 
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters\" 
$Name = "SMB2" 
$Value = "1" 
$SMBKey = Get-Item -Path $registryPath 
    IF($SMBKey.GetValue("SMB2") -eq $null) { 
    New-ItemProperty -Path $registryPath -Name $Name -Value $Value -PropertyType DWORD -Force | Out-Null 
    } ELSE { 
    Set-ItemProperty -Path $registryPath -Name $Name -Value $Value -Force | Out-Null 
    } 
} 
 
FOREACH ($s in @('server01', 'server02', 'server03')) { 
    Invoke-Command -ComputerName $s -ScriptBlock ${Function:Enable-SMBv2} -AsJob | Out-Null 
} 
 
Get-Job | Wait-Job | Out-Null 
 
[psobject]$JobFailures = @() 
[psobject]$SMBStatus = @() 
 
IF ((Get-Job -State Failed).count -ne 0) { 
    foreach ($Failure in (Get-Job -State Failed)) { 
        $JobFailures += New-Object psobject -Property @{ 
            'Server' = $Failure.Location 
            'Failure' = ($Failure.ChildJobs.JobStateInfo.Reason.Transportmessage) 
        } 
    } 
 
} 
 
$SMBStatus += foreach ($Job in Get-Job) { 
    Receive-Job $Job -ErrorAction SilentlyContinue 
    Remove-Job $Job 
    } 
 
 
IF ($JobFailures) { 
    Write-Host `n'Check the failures below....'`n -ForegroundColor Red 
    $JobFailures | ft -AutoSize 
}  
 
$SMBStatus 
 
#NEW SCRIPT 
$ADComputerProperties = @('Name','OperatingSystem', 'OperatingSystemVersion') 
$ListOfServers = Get-ADComputer -Filter {(Name -like '*NY*' -and OperatingSystemVersion -like '6.3*') -OR (Name -like '*NY*' -and OperatingSystemVersion -like '6.1*') -OR (Name -like '*NY*' -and OperatingSystemVersion -like '6.0*')} -SearchBase 'OU=Servers,OU=NY,DC=contosotest,DC=com' -Properties $ADComputerProperties | Select -Property $ADComputerProperties 
 
$main = "Localmachine" 
$path = "SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters\" 
$key = "SMB2" 
#$servers = @('server01', 'server02', 'server03') 
 
$SMBKeyCheck=@() 
foreach ($Server in $ListOfServers.Name)  
{ 
$SMBKeyCheck += New-Object psobject -Property ([ordered]@{ 
    'ServerName' = $Server 
    'ParentKey' = $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($main, $Server) 
    'Key' = $regKey= $reg.OpenSubKey($path) 
    'Value' = $Value = $regkey.GetValue($key) 
  
   }) 
} 
 
$SMBKeyCheck | select ServerName, Value 
 
# NEW SCRIPT 
$ADComputerProperties = @('Name','OperatingSystem', 'OperatingSystemVersion') 
$ListOfServers = @() 
$ListOfServers += Get-ADComputer -Filter {(Name -like '*NY*' -and OperatingSystemVersion -like '6.3*') -OR (Name -like '*NY*' -and OperatingSystemVersion -like '6.1*') -OR (Name -like '*NY*' -and OperatingSystemVersion -like '6.0*')} -SearchBase 'OU=Servers,OU=NY,DC=contosotest,DC=com' -Properties $ADComputerProperties | Select -Property $ADComputerProperties 
 
function Enable-SMBv2 { 
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters\" 
$Name = "SMB2" 
$Value = "1" 
$SMBKey = Get-Item -Path $registryPath 
    IF($SMBKey.GetValue("SMB2") -eq $null) { 
    return "KEY NOT PRESENT $ENV:COMPUTERNAME" 
    #New-ItemProperty -Path $registryPath -Name $Name -Value $Value -PropertyType DWORD -Force | Out-Null 
    } ELSE { 
    Set-ItemProperty -Path $registryPath -Name $Name -Value $Value -Force | Out-Null 
    } 
} 
 
$servers = @('server01', 'server02', 'server03') 
#FOREACH ($s in (ipcsv D:\Temp\listofservers.csv).Name)  
FOREACH ($s in $servers) { 
    Invoke-Command -ComputerName $s -ScriptBlock ${Function:Enable-SMBv2} -AsJob | Out-Null 
} 
 
Get-Job | Wait-Job | Out-Null 
 
[psobject]$JobFailures = @() 
[psobject]$JobStatus = @() 
 
IF ((Get-Job -State Failed).count -ne 0) { 
    foreach ($Failure in (Get-Job -State Failed)) { 
        $JobFailures += New-Object psobject -Property @{ 
            'Server' = $Failure.Location 
            'Failure' = ($Failure.ChildJobs.JobStateInfo.Reason.Transportmessage).Split('.')[0] 
        } 
    } 
 
} 
 
$JobStatus += foreach ($Job in Get-Job) { 
    Receive-Job $Job -ErrorAction SilentlyContinue 
    Remove-Job $Job 
} 
 
 
IF ($JobFailures) { 
    Write-Host `n'Check the failures below....'`n -ForegroundColor Red 
    $JobFailures | ft -AutoSize 
}  
 
$JobStatus 
$ListOfServers.Clear()