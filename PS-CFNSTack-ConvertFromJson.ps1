# ConvertFrom-Json example using AWS Tools for PowerShell
if (!(Get-Module -Name AWSPowerShell.NetCore)) {Import-Module -Name AWSPowerShell.NetCore}
$TemplateBody = Get-CFNTemplate -StackName samplestack1
$TemplateBody | ConvertFrom-Json
$TemplateObject = $TemplateBody | ConvertFrom-Json
$TemplateObject
$TemplateObject.Resources.MYS3Bucket
$TemplateObject = $TemplateObject | Add-Member -MemberType NoteProperty -Name Description -Value 'This is a test template for cloudformation' -PassThru
$TemplateObject
$TemplateObject.Description
New-CFNStack -Region us-east-1 -StackName samplestack2 -TemplateBody (ConvertTo-Json -InputObject $TemplateObject -Depth 3)