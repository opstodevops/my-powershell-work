#begin Script

$DCServers = ([System.Directoryservices.ActiveDirectory.Forest]::GetCurrentForest()).domains | ForEach-Object {$_.DomainControllers} | ForEach-Object {($_.Name).split(".")[0]}

foreach ($DC in $DCServers) {
       Invoke-Command -Credential $creds -ComputerName $DC -ScriptBlock {Get-Content $env:windir\debug\netlogon.log |Select-String "NO_CLIENT" | % {($_.tostring()).split()[-1]} | % {$_.split(".")[0..2] -join '.'} |select -Unique} -AsJob  |Out-Null
       }

Get-Job | Wait-Job |Out-Null

if ((Get-Job -State Failed).count -ne 0){
       $jobfailures=@()
       foreach ($failure in (Get-Job -State Failed)) { 
              $jobfailures += New-object psobject -Property @{
                     "Computer" = $failure.location;
                     "Failure" =  ($failure.ChildJobs.JobStateInfo.reason.transportmessage).split(".")[0]
                     }
              }
       }
$NoClient =  @()
$NoClient += foreach ($Job in Get-Job) {
       Receive-Job $Job -ErrorAction SilentlyContinue
       Remove-Job $Job
       }

$jobfailures
$NoClient |select -Unique |sort 
#end Script