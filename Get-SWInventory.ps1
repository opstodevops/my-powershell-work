Function Get-SWInventory { 
    [CmdletBinding()] 
    param ( 
        [Parameter(Mandatory = $true,  
        ValueFromPipeline = $true,  
        ValueFromPipelineByPropertyName = $true)] [String[]]$ComputerName 
    ) 
     
        Begin 
        { 
            $LocalMachineKey = "Software\Microsoft\Windows\CurrentVersion\Uninstall","SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" 
            $LocalMachineType = [Microsoft.Win32.RegistryHive]::LocalMachine 
            $CurrentUserKey = "Software\Microsoft\Windows\CurrentVersion\Uninstall" 
            $CurrentUserType = [Microsoft.Win32.RegistryHive]::CurrentUser 
             
        } 
        Process 
        { 
            ForEach($Computer in $ComputerName) { 
            Try { 
                $Result = @() 
                $CurrentUserReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($CurrentUserType,$Computer) 
                $LocalMachineReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($LocalMachineType,$Computer) 
                ForEach($Key in $LocalMachineKey) 
                { 
                    $RegKey = $LocalMachineReg.OpenSubkey($Key) 
                    If($RegKey -ne $null) 
                    { 
                        ForEach($subName in $RegKey.getsubkeynames()) 
                        { 
                            ForEach($sub in $RegKey.opensubkey($subName)) 
                            { 
                                $Result += (New-Object PSObject -Property @{ 
                                "ComputerName" = $Computer 
                                "Name" = $sub.getvalue("displayname") 
                                "SystemComponent" = $sub.getvalue("systemcomponent") 
                                "ParentKeyName" = $sub.getvalue("parentkeyname") 
                                "Version" = $sub.getvalue("DisplayVersion") 
                                }) 
                            } 
                        } 
                    } 
                } 
                ForEach($Key in $CurrentUserKey) 
                { 
                    $RegKey = $CurrentUserReg.OpenSubkey($Key) 
                    If($RegKey -ne $null) 
                    { 
                        ForEach($subName in $RegKey.getsubkeynames()) 
                        { 
                            ForEach($sub in $RegKey.opensubkey($subName)) 
                            { 
                                $Result += (New-Object PSObject -Property @{ 
                                "ComputerName" = $Computer 
                                "Name" = $sub.getvalue("displayname") 
                                "SystemComponent" = $sub.getvalue("systemcomponent") 
                                "ParentKeyName" = $sub.getvalue("parentkeyname") 
                                "Version" = $sub.getvalue("DisplayVersion") 
                                }) 
                            } 
                        } 
                    } 
                } 
                #$Result = ($Result | Where {$_.Name -ne $Null -AND $_.SystemComponent -ne "1" -AND $_.ParentKeyName -eq $Null} | select Name,Version,ComputerName | sort Name) 
                $Result = ($Result | Where {($_.Name -match 'Java' -or $_.Name -match 'Adobe') -AND $_.SystemComponent -ne "1" -AND $_.ParentKeyName -eq $Null} | select ComputerName, Name, Version | sort Name) 
                $Result 
                }  
            Catch { 
                Write-Warning "Cannot Connect to $Computer" 
                } 
            } 
        } 
        End {} 
    }