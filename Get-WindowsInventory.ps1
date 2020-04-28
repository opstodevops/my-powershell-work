Function Get-WinInventory { 
    [CmdletBinding()] 
    Param( 
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)] [string[]]$ComputerName, 
        [Parameter(Mandatory = $false)] [Switch]$ErrorLog, 
        [Parameter(Mandatory = $false)] [String]$LogFile = "$env:TEMP\error.txt" 
    ) 
    Begin { 
     
    } 
 
    Process { 
        foreach ($Computer in $ComputerName) { 
            Try { 
                $Inventory = New-Object psobject -Property <#([ordered]#>@{ 
                    "ServerName"           = $computer; 
                    "OS Name"              = '' 
                    "OS Build"             = '' 
                    "Service Pack"         = '' 
                    "Free Space on C (GB)" = '' 
                    "Last Reboot"          = '' 
                    "Model"                = '' 
                    "Manufacturer"         = '' 
                    "HP FirmWare"          = '' 
                    "HP FirmWare Version"  = '' 
                    "SCOM Agent"           = '' 
                    "Monthly Cumulative"   = '' 
                    "Legacy Update"        = '' 
                 
                }<#)#> 
                             
                $OS = Get-Wmiobject -ComputerName $Computer -Class Win32_OperatingSystem -ErrorAction Stop -ErrorVariable CurrentError 
                $CS = Get-Wmiobject -ComputerName $Computer -Class Win32_ComputerSystem  
                $Disk = Get-WmiObject -ComputerName $Computer -Class Win32_LogicalDisk -Filter "DeviceID='C:'"  
                $Monitor = Get-WMIObject -ComputerName $Computer -Class Win32_Service -Filter "Name='HealthService'"  
                                 
                $Inventory.'OS Name' = $OS.caption 
                $Inventory.'OS Build' = $OS.Buildnumber 
                $Inventory.'Service Pack' = $OS.ServicePackMajorVersion 
                $Inventory.'Free Space on C (GB)' = [math]::Round($Disk.FreeSpace / 1GB, 2) 
                $Inventory.'Last Reboot' = $OS.ConvertToDateTime($OS.LastBootUpTime) 
                $Inventory.Model = $CS.Model 
                $Inventory.Manufacturer = $CS.Manufacturer 
                $Inventory.'SCOM Agent' = $Monitor.Name 
                 
                If ($Monitor.Name -eq 'HealthService') {$Inventory.'SCOM Agent' = 'Monitored'} ELSE {$Inventory.'SCOM Agent' = 'Unknown'} 
                 
                If ($OS.Version -match '5.2' -and $OS.Manufacturer -eq 'Microsoft Corporation') { 
 
                    $LegacyUpdate = Get-EventLog -ComputerName $Computer -LogName system -InstanceId 19 -Newest 3 -EntryType Information |  
                        where {$_.Message -match 'Custom Support'} 
 
                    $LegacyUpdateName = (@($LegacyUpdate | foreach {($_.Message.tostring().split(':')[2]).Trim()}) -join ',') 
                    $Inventory.'Legacy Update' = $LegacyUpdateName 
                                
                } 
                                 
                If ($OS.Version -ge '6.1' -and $OS.Manufacturer -eq 'Microsoft Corporation') { 
 
                    [xml]$xmlFilter = @" 
<QueryList> 
  <Query Id="0" Path="System"> 
    <Select Path="System">*[System[(Level=4 or Level=0) and (EventID=19)]]</Select> 
  </Query> 
</QueryList> 
"@ 
 
                    $Cumulative = Get-WinEvent -FilterXml $xmlFilter -MaxEvents 3 -ComputerName $Computer | where {$_.Message -match 'Quality'} 
                    $CumulativeName = (@($Cumulative | foreach {($_.Message.tostring().split(':')[2]).Trim()}) -join ',') 
                    $Inventory.'Monthly Cumulative' = $CumulativeName 
                                 
                }                 
                 
                If ($CS.Manufacturer -eq 'HP') { 
 
                    $HPFirm = Get-WmiObject -Class HP_SystemROMFirmware -Namespace root\hpq -ComputerName $Computer -Filter 'InstanceID="HPQ:HP_SystemROMFirmware:001"' 
                    $Inventory.'HP FirmWare' = $HPFirm.Name 
                    $Inventory.'HP FirmWare Version' = $HPFirm.VersionString 
                }                 
                 
                $Inventory 
            } 
 
            Catch { 
                Write-warning "Cannot connect to $Computer" 
                If ($ErrorLog) { 
                    [System.TimeZone]::CurrentTimeZone | Out-File $LogFile -Force 
                    Get-Date | Out-File $LogFile -Append 
                    $Computer | Out-File $LogFile -Append 
                    $CurrentError | Out-File $LogFile -Append 
                } 
            } 
        }  
    } 
 
    End { 
        If ($ErrorLog) { 
            If ($CurrentError) { 
                Start-Process notepad $LogFile 
            } 
        } 
     
    } 
 
} 