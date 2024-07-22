<#############################################################################
Description:
This script will validate an Arc registered machine ready for 
onboarding the SQL Server Extension. It will build up the list
of variables needed to run AzureExtensionForSQLServer.exe using the local
Arc Machine Agent.

Inputs: 
ServicePrincipalID
ServicePrincipalSecret
        
Dependencies:   azcmagent.exe
                AzureExtensionForSQLServer.exe 

##############################################################################>


#############################################################
# Change these variables to parameters for use in RUn Book
#############################################################
$licenseType = "paid"
$serviceprincipalID ="<Service Principal App ID>"
$serviceprincipalsecret ="<Service Principal Secret"


#############################################################
# Get config from azcmagent.exe for the extension
#############################################################

try
{
    $var = & "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" show

    $properties = $var -split "`n" | Where-Object { $_ -match ':' } | ForEach-Object {
        $key, $value = $_ -split ':', 2
        New-Object PSObject -Property @{
            Key = $key.Trim()
            Value = $value.Trim()
        }
    }


    #############################################################
    # Load the Variables
    #############################################################
    $machineName = ($properties | Where-Object { $_.Key -eq 'Resource Name' }).Value
    $SubscriptionID = ($properties | Where-Object { $_.Key -eq 'Subscription ID' }).Value 
    $TenantID = ($properties | Where-Object { $_.Key -eq 'Tenant ID' }).Value 
    $resourceGroup = ($properties | Where-Object { $_.Key -eq 'Resource Group Name' }).Value 
    $location = ($properties | Where-Object { $_.Key -eq 'Location' }).Value  
    $proxy = ($properties | Where-Object { $_.Key -eq 'Using HTTPS Proxy' }).Value  


    <#

    #User to Test
    $machineName
    $SubscriptionID
    $TenantID
    $resourceGroup 
    $location
    $proxy
    $licenseType
    $serviceprincipalID
    $serviceprincipalsecret

    #>


    ############################################################
    # Configure AZMngmnt
    ############################################################

    # Allow Extensions
    & "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" config set extensions.enabled true

    # Allow SQL Agent Extension
    & "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" config set extensions.allowlist "Microsoft.AzureData/WindowsAgent.SqlServer"


    ############################################################
    # Install Extensions
    ############################################################

    & "$env:ProgramW6432\AzureExtensionForSQLServer\AzureExtensionForSQLServer.exe" --subId $SubscriptionID --resourceGroup $resourceGroup  --location $location --tenantid $TenantID --service-principal-app-id $serviceprincipalID --service-principal-secret $serviceprincipalsecret --proxy $proxy --licenseType $licenseType --machineName $machineName


}
catch
{
    Write-Error "An error occurred: $_"
}
