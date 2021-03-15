Configuration DcConfig
{
	[CmdletBinding()]

	Param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[PSCredential]$DomainAdminCredentials,
		[string]$DomainName,
		[string]$NetBiosDomainname

	)

	Import-DscResource -ModuleName PSDscResources
	Import-DscResource -ModuleName ActiveDirectoryDsc

	

	Node 'localhost'
	{             
		LocalConfigurationManager {
			ConfigurationMode    = 'ApplyAndAutoCorrect'
			RebootNodeIfNeeded   = $true
			ActionAfterReboot    = 'ContinueConfiguration'
			AllowModuleOverwrite = $true
		}
		WindowsFeatureSet ADDS_Features
		{
			Name = @('RSAT-DNS-Server','AD-Domain-Services','RSAT-AD-AdminCenter','RSAT-ADDS','RSAT-AD-PowerShell','RSAT-AD-Tools','RSAT-Role-Tools')
			Ensure = 'Present'
		}	
		ADDomain CreateForest { 
			DomainName                    = $DomainName            
			Credential                    = $DomainAdminCredentials
			SafemodeAdministratorPassword = $DomainAdminCredentials
			DomainNetbiosName             = $NetBiosDomainname
			DependsOn                     = '[WindowsFeatureSet]ADDS_Features'
		}

		

	}
}