# This script is for pulling Windows Error Reporting for Apps.

Get-WinEvent -FilterHashtable `
@{'providername' = 'Windows Error Reporting';starttime=(Get-Date).AddDays(-7);Id=1001} |
Select-Object -Property TimeCreated, @{name='App';expression={$_.Properties[5].value}} |
Group-Object -Property App |
Select-Object -Property Name,Count |
Sort-Object -Property Count -Descending