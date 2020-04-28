param ( 
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] 
    [ValidateScript({Test-path $_})] 
    [System.IO.FileInfo]$fileName='D:\Temp\VMwareWork\snap.csv' 
) 
 
#Import-Module VMware.VimAutomation.Core 
#$Creds=Get-Credential -Credential "$ENV:USERDOMAIN\$ENV:USERNAME" 
$Creds=Get-VICredentialStoreItem -File C:\Users\AppData\Roaming\VMware\credstore\vicredentials.xml 
$vCenterServers = @('VCENTER1.com', 
                    'VCENTER2.com', 
                    'VCENTER3.com', 
                    'VCENTER4.com') 
Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope Session -Confirm:$false -InvalidCertificateAction Ignore | Out-Null 
Connect-VIServer -Server $vCenterServers -User $creds.User -Password $creds.Password 
#Connect-VIServer -Server $vCenterServers -Credential $Creds 
 
$snapMemory = $false 
$snapQuiesce = $false 
 
Import-Csv -Path $fileName -UseCulture |  
Where-Object { ![string]::IsNullOrWhiteSpace($_.snaptime) } |  
    ForEach-Object { 
 
$vm = Get-VM -Name $_.virtualmachine 
foreach ($vCenterServer in $vCenterServers) { 
    if ($vm.Uid -like "*$vCenterServer*") { 
        $SIServer = $vCenterServer 
    } 
} 
$snapTime = $_.snaptime -as [datetime] 
$snapName = $_.snapname 
$snapDescription = $_.Description 
$si = Get-View ServiceInstance -Server $SIServer 
$scheduledTaskManager = Get-View $si.content.ScheduledTaskManager -Server $SIServer 
$spec = New-Object -TypeName VMware.Vim.ScheduledTaskSpec 
$spec.Name = "Snapshot",$vm.Name -join '' 
$spec.Description = $snapDescription 
$spec.Enabled = $true 
$spec.Scheduler = New-Object -TypeName VMware.Vim.OnceTaskScheduler 
$spec.Scheduler.runat = $snapTime 
$spec.Action = New-Object -TypeName VMware.Vim.MethodAction 
$spec.Action.Name = "CreateSnapshot_Task" 
 
($snapName,$snapDescription,$snapMemory,$snapQuiesce) | ForEach-Object { 
 
$arg = New-Object VMware.Vim.MethodActionArgument 
$arg.Value = $_ 
$spec.Action.Argument += $arg 
 
} 
 
$scheduledTaskManager.CreateObjectScheduledTask($vm.ExtensionData.MoRef, $spec) | Out-Null 
Write-Host "Scheduling Snapshot For $vm" 
 
}  
 