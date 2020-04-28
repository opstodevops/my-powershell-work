function Get-CertificateInfo { 
    [cmdletbinding()] 
    param ( 
      [Parameter(Mandatory=$False, ValueFromPipeLine=$True, Position=0)] [string]$ComputerName=$ENV:COMPUTERNAME, 
      [Parameter(Mandatory=$True)] [int]$Days 
    ) 
   
    Begin{} 
   
    Process{ 
       
        foreach ($Computer in $ComputerName) { 
          try { 
              # change the store if you want to check a different location, by default local computer is being checked 
            $CertificateCollection = Invoke-Command -ComputerName $ComputerName -ScriptBlock { param ($Days) Get-ChildItem -Path Cert:\LocalMachine\My -Recurse <#-ExpiringInDays $Days#> |  
              Where-Object {$_.HasPrivateKey -eq $True -and $_.NotAfter -le (Get-Date).AddDays($Days) } } -ArgumentList $Days -ErrorAction Stop 
           
            if ($CertificateCollection -eq $null) { 
              Write-Host "#################### No Certificate Expiring in $Days on $ComputerName ####################" -ForegroundColor Yellow 
                }  
                ELSE { 
                $CertificateInfo=@() 
                foreach ($Certificate in $CertificateCollection) { 
                  $CertificateInfo += New-Object psobject -Property @{ 
                      "Computer"     = $Certificate.PSComputerName; 
                      "FriendlyName" = $Certificate.FriendlyName; 
                      "Thumbprint"   = $Certificate.Thumbprint; 
                      "Issuer"       = $Certificate.Issuer; 
                      "Expiring"     = $Certificate.NotAfter; 
                      "Subject"      = $Certificate.Subject  
                      } 
                  } 
              } $CertificateInfo 
          }  
           
          catch { 
              Write-Warning "#################### Cannot Connect to $ComputerName ####################" 
              Write-Warning "#################### Check Connectivity, OS or Authorization ####################" 
          } 
        } 
      } 
       
    End {     
    } 
  } 