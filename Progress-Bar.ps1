Set-StrictMode -Version 1.0

# Pull in objects to iterate over
$files = @(Get-Content C:\Windows)

# For loop iterating over the total number of files
$itemarray = @()
foreach ($file in $files) {
    $i = $i + 1
    Write-Progress -Activity "Checking files" -Id 1 -Status "Processing $i/$(files.count) files" -PercentComplete ($i/$files.count * 100)
    $itemarray += $file.name
    Start-Sleep -Milliseconds 30
}

for ($item=0; item -le $itemarray.count; item++) {
    Write-Progress -Activity "Adding files to array" -Id 2 -ParentId 1 -PercentComplete ($item/$itemarray.count * 100)
    Start-Sleep -Milliseconds 30
}


