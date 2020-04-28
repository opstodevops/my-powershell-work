function Create-Snapshots { 
    [cmdletbinding()] 
    param ( 
     
        [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] 
        [ValidateScript({Test-path $_})] 
        [System.IO.FileInfo]$fileName='C:\Temp\snap.csv' 
    ) 
     
    Begin { 
     
    Import-Module VMware.VimAutomation.Core 
    $Creds=Get-Credential -Credential "$ENV:USERDOMAIN\$ENV:USERNAME" 
    $vCenterServers = @('VCENTER1.com',  
                        'VCENTER2.com',  
                        'VCENTER3.com',  
                        'VCENTER4.com') 
    Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope Session -Confirm:$false | Out-Null 
    Connect-VIServer -Server $vCenterServers -Credential $Creds 
    #$env:USERDOMAIN+""+$env:USERNAME 
     
        } 
     
    Process { 
        $snapMemory = $false 
        $snapQuiesce = $false 
        #$fileName = 'C:\Temp\snap.csv' 
     
        Import-Csv -Path $fileName -UseCulture |  
        Where-Object { ![string]::IsNullOrWhiteSpace($_.snaptime) } |  
            ForEach-Object { 
         
        $vm = Get-VM -Name $_.virtualmachine 
        $snapTime = $_.snaptime -as [datetime] 
        $snapName = $_.snapname 
        $snapDescription = $_.Description 
        $si = Get-View ServiceInstance 
        $scheduledTaskManager = Get-View $si.content.ScheduledTaskManager 
        $spec = New-Object -TypeName VMware.Vim.ScheduledTaskSpec 
        $spec.Name = "Snapshot",$vm.Name -join '' 
        $spec.Description = $snapDescription 
        $spec.Enabled = $true 
        $spec.Scheduler = New-Object -TypeName VMware.Vim.OnceTaskScheduler 
        $spec.Scheduler.runat = $snapTime 
        $spec.Action = New-Object -TypeName VMware.Vim.MethodAction 
        $spec.Action.Name = "CreateSnapshot_Task" 
     
       @($snapName,$snapDescription,$snapMemory,$snapQuiesce) | ForEach-Object { 
     
        $arg = New-Object VMware.Vim.MethodActionArgument 
        $arg.Value = $_ 
        $spec.Action.Argument += $arg 
         
        } 
     
        $scheduledTaskManager.CreateObjectScheduledTask($vm.ExtensionData.MoRef, $spec) | Out-Null 
        Write-Host "Creating Snapshot For $vm" 
     
            }  
        } 
         
    End {} 
     
    }