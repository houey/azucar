﻿#Plugin extract policies from Azure AD
#https://msdn.microsoft.com/en-us/library/azure/ad/graph/api/policy-operations
[cmdletbinding()]
    Param (
            [Parameter(HelpMessage="Background Runspace ID")]
            [int]
            $bgRunspaceID,

            [Parameter(HelpMessage="Not used in this version")]
            [HashTable]
            $SyncServer,

            [Parameter(HelpMessage="Azure Object with valuable data")]
            [Object]
            $AzureObject,

            [Parameter(HelpMessage="Object to return data")]
            [Object]
            $ReturnPluginObject,

            [Parameter(HelpMessage="Verbosity Options")]
            [System.Collections.Hashtable]
            $Verbosity,

            [Parameter(Mandatory=$false, HelpMessage="Save exception in log file")]
	        [Bool] $WriteLog

        )
    Begin{
        #Import Azure API
        $LocalPath = $AzureObject.LocalPath
        $API = $AzureObject.AzureAPI
        $Utils = $AzureObject.Utils
        . $API
        . $Utils

        #Import Localized data
        $LocalizedDataParams = $AzureObject.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        #Import Global vars
        $LogPath = $AzureObject.LogPath
        Set-Variable LogPath -Value $LogPath -Scope Global
    }
    Process{
        $PluginName = $AzureObject.PluginName
        $AADConfig = $AzureObject.AzureConfig.AzureActiveDirectory
        $Section = $AzureObject.AzureSection
        Write-AzucarMessage -WriteLog $WriteLog -Message ($message.AzucarADPoliciesTaskMessage -f $bgRunspaceID, $PluginName, $AzureObject.TenantID) `
                                -Plugin $PluginName -IsHost -Color Green
        #Retrieve instance
        $Instance = $AzureObject.Instance
        #Retrieve Azure Active Directory Auth
        $AADAuth = $AzureObject.AzureConnections.ActiveDirectory
        #Get policies
        $URI = ("{0}myorganization/policies?api-version={1}" -f $Instance.Graph, $AADConfig.APIVersion)
        $AllPolicies = Get-AzSecAADObject -OwnQuery $URI -Manual -Authentication $AADAuth `
                                          -Verbosity $Verbosity -WriteLog $WriteLog
        #Convert definition and key credentials
        if($AllPolicies){
            foreach ($policy in $AllPolicies){
                if($policy.definition){
                    $policy.definition = (@($policy.definition) -join ',')
                }
                if($policy.keyCredentials){
                    $policy.keyCredentials = (@($policy.keyCredentials) -join ',')
                }
            }
        }
    }
    End{
        if($AllPolicies){
            #Work with SyncHash
            $SyncServer.$($PluginName)=$AllPolicies
            $AllPolicies.PSObject.TypeNames.Insert(0,'AzureAAD.NCCGroup.Policies')
            #Create custom object for store data
            $AllAADPolicies = New-Object -TypeName PSCustomObject
            $AllAADPolicies | Add-Member -type NoteProperty -name Section -value $Section
            $AllAADPolicies | Add-Member -type NoteProperty -name Data -value $AllPolicies
            #Add Users data to object
            if($AllPolicies){
                $ReturnPluginObject | Add-Member -type NoteProperty -name azure_domain_policies -value $AllAADPolicies
            }
        }
        else{
            Write-AzucarMessage -WriteLog $WriteLog -Message ($message.AzureADPoliciesQueryEmptyMessage -f $AzureObject.TenantID) `
                                -Plugin $PluginName -Verbosity $Verbosity -IsWarning
        }
    }