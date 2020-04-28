param ( 
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] 
    [ValidateScript({Test-path $_})] 
    [System.IO.FileInfo]$fileName='C:\Temp\removesnap.csv' 
) 
 
Import-Module VMware.VimAutomation.Core 
#$Creds=Get-Credential -Credential "$ENV:USERDOMAIN\$ENV:USERNAME" 
$Creds = Get-VICredentialStoreItem -File C:\Users\AppData\Roaming\VMware\credstore\vicredentials.xml 
$vCenterServers = @('VCENTER1.com', 
                    'VCENTER2.com', 
                    'VCENTER3.com', 
                    'VCENTER4.com', 
                    'VCENTER5.com') 
Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope Session -Confirm:$false -InvalidCertificateAction Ignore | Out-Null 
Connect-VIServer -Server $vCenterServers -User $creds.User -Password $creds.Password 
#Connect-VIServer -Server $vCenterServers -Credential $Creds 
$TimeStamp = Get-Date 
$Hours = "48" 
#Connect-VIServer $creds.Host -User $creds.User -Password $creds.Password 
#Write-Host "Script will only delete snapshots created in last 48 hours" -ForegroundColor Yellow 
 
Import-Csv -Path $fileName -UseCulture |  
    ForEach-Object { 
    $VM = Get-VM -Name $_.virtualmachine 
    $SnapShots = Get-Snapshot -VM $VM | Where {$_.Created -lt (Get-Date).AddHours($Hours)} 
    #$SnapCounts = $SnapShots | measure 
    #$SnapCounts = $SnapCounts.Count 
    #If ($SnapCounts -ne 0) { 
    #Write-Host "$VM has $SnapCounts Snapshots" 
    #$Message = "$TimeStamp : Removing $SnapShots Snapshot for $VM" 
    #Write-Host $Message 
    $SnapShots | select VM, SizeMB, @{Name="Age";Expression={((Get-Date)-$_.Created).Hours}} | Out-File C:\Temp\DeletedSnapshots.txt -Append 
    $SnapShots | Remove-Snapshot -Confirm:$false | Out-Null 
    #} 
    <#ELSE { 
    Write-Host "$VM has $SnapCounts Snapshots" 
    $Message = "$TimeStamp : No Action for $VM" 
    Write-Host $Message 
    }#> 
    Start-Sleep -Seconds 30 
}  
Disconnect-VIServer -Server * -Confirm:$false | Out-Null 