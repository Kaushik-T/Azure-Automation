 
workflow RebootcloudServices
{
  
	
		
		try
		{
             $ConnectionAssetName = "AzureClassicRunAsConnection"
            # Get the connection
            $connection = Get-AutomationConnection -Name $connectionAssetName        

            # Authenticate to Azure with certificate
            Write-Verbose "Get connection asset: $ConnectionAssetName" -Verbose
            $Conn = Get-AutomationConnection -Name $ConnectionAssetName
            if ($Conn -eq $null)
            {
            throw "Could not retrieve connection asset: $ConnectionAssetName. Assure that this asset exists in the Automation account."
            }

            $CertificateAssetName = $Conn.CertificateAssetName
            Write-Verbose "Getting the certificate: $CertificateAssetName" -Verbose
            $AzureCert = Get-AutomationCertificate -Name $CertificateAssetName
            if ($AzureCert -eq $null)
            {
            throw "Could not retrieve certificate asset: $CertificateAssetName. Assure that this asset exists in the Automation account."
            }

            Write-Verbose "Authenticating to Azure with certificate." -Verbose
            Set-AzureSubscription -SubscriptionName $Conn.SubscriptionName -SubscriptionId $Conn.SubscriptionID -Certificate $AzureCert
            Select-AzureSubscription -SubscriptionId $Conn.SubscriptionID

       
 
                            
    $CloudServices =@("Resource-group(cloudServiceName)")
                        
                    
  				# Stop each of the started VMs
    				foreach -parallel ($CloudService in $CloudServices)
    				{
                		$cloudServiceName =$CloudService
                                
                                # Retrieve all role instances for the cloud service	
                                $roleInstances = Get-AzureRole -ServiceName $cloudServiceName -Slot Production -InstanceDetails
                                Write-Output "Retrieved all role instances for cloud service: $cloudServiceName. Number of instances: " + $roleInstances.Count
                                
                                # Group instances per update domain
                                $roleInstanceGroups = $roleInstances | Group-Object -AsHashTable -AsString -Property InstanceUpgradeDomain
                                Write-Output "Number of update domains found: " + $roleInstanceGroups.Keys.Count
                                
                                # Visit each update domain
                                foreach ($key in $roleInstanceGroups.Keys)
                                {
                                    $count = $perDomainInstances.Count;
                                    Write-Output "Rebooting $count instances in domain $key"	
                                    
                                    $perDomainInstances = $roleInstanceGroups.Get_Item($key)
                                    
                                
                                    foreach ($instance in $perDomainInstances)
                                        {
                                             $instanceName = $instance.InstanceName

                                                    $anonUser = "account"
                                                    $anonPass = ConvertTo-SecureString "SecureString@1234" -AsPlainText -Force
                                                    $anonCred = New-Object System.Management.Automation.PSCredential($anonUser, $anonPass)      
                                                    Send-MailMessage -To "kaushik.thakkar@g.com" -Subject "UAT restart started for $cloudServiceName  and $instanceName " -Body "Started  $instanceName Rebooting" -From "Restart@g.com" -Credential $anonCred -SmtpServer "smtp.sendgrid.net"

                                                    Write-Output "Rebooting instance $instanceName"
                                                                
                                                    Reset-AzureRoleInstance -ServiceName $cloudServiceName -Slot Production -InstanceName $instanceName -Reboot -ErrorAction Stop
                                                        
                                                    Start-Sleep 5    
                                                    Send-MailMessage -To "kaushik.thakkar@g.com" -Subject "Restart completed for $cloudServiceName Cloud Service and  $instanceName  insatnce" -Body "completed $instanceName Reboot" -From "Restart@g.com" -Credential $anonCred -SmtpServer "smtp.sendgrid.net"

                                        } 
                                }
                                
                                   
                                   
                         }

                            Start-Sleep 10
                            $anonUser = "account"
                            $anonPass = ConvertTo-SecureString "SecureString@1234" -AsPlainText -Force
                            $anonCred = New-Object System.Management.Automation.PSCredential($anonUser, $anonPass)    
                            Send-MailMessage -To "kaushik.thakkar@g.com" -Subject "RESTART DONE" -Body "Completely Done " -From "RestartCloudService@g.com" -Credential $anonCred -SmtpServer "smtp.sendgrid.net"


		
        }
        catch
		{
             
        $ErrorMessage = $_.Exception.Message
		
		    $anonUser = "account"
            $anonPass = ConvertTo-SecureString "SecureString@1234" -AsPlainText -Force
            $anonCred = New-Object System.Management.Automation.PSCredential($anonUser, $anonPass)
            Send-MailMessage -To "kaushik.thakkar@g.com" -Subject "restart completed with error" -Body "Error Message :- $ErrorMessage" -From "RestartCloudService@g.com" -Credential $anonCred -SmtpServer "smtp.sendgrid.net"
		
 
        }
     
}