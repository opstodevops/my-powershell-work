# This script will recursively remove log files that haven't been modified in the last 30 days 
 
$ComputerName  = "server.contoso.com" 
$daysBack      = (Get-Date).AddDays(-31) 
$digitalDir    = "\IBLogs\DIGITAL.contoso.com" 
$secureDir     = "\IBLogs\SECURE.contoso.com" 
$Directories   = $digitalDir,$secureDir 
 
foreach ($directory in $Directories) { 
    $filePath = Join-Path "\\$ComputerName" -ChildPath "$directory" 
    foreach ($file in Get-ChildItem $filePath -Recurse -File -Force) { 
        if ($file.CreationTime -lt $daysBack) { 
            Write-Output "removing $file created on $($file.CreationTime)" 
            #$file.Delete() 
        } 
    } 
} 
 