# ConvertTo-Json example using AWS Tools for PowerShell
if (!(Get-Module -Name AWSPowerShell.NetCore)) {Import-Module -Name AWSPowerShell.NetCore}
New-CFNStack -Region us-east-1 -StackName samplestack1 -TemplateBody ($CFNTemplate | ConvertTo-Json -Depth 5)

$CFNTemplate = @{
    Resources = @{
        MYS3Bucket = @{
            Type = 'AWS::S3::Bucket'
            Properties = @{
                AccessControl = 'Private'
            }
        }
    }
}

$CFNTemplate | ConvertTo-Json -Depth 5

