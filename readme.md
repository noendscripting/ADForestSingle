# Deploy Active Directory Forest with PowerShell

This repository contains an automated deployment solution for creating a single Active Directory Domain Controller in Azure using PowerShell and ARM templates.

## Overview

The `Deploy.ps1` script automates the deployment of an Active Directory forest by:
- Creating a Resource Group
- Setting up a Storage Account with network security rules
- Publishing DSC (Desired State Configuration) packages
- Uploading custom scripts for AD configuration
- Deploying a Domain Controller VM using ARM templates

## Prerequisites
- [Clone of repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) in your local directory
- Azure PowerShell module installed (`Install-Module -Name Az`)
- Azure subscription with appropriate permissions
- Existing Virtual Network with a subnet and Azure.Storage ServiceEndpoints configured
- Authenticated Azure session (`Connect-AzAccount`)


## Required Parameters

The script requires the following mandatory parameters:

### `-RG` (Mandatory)
Resource Group name where the lab will be deployed. If the Resource Group exists, its contents may be overwritten.

**Example:** `"AD-Lab-RG"`

### `-templatefile` (Mandatory)
Path to the ARM deployment template file.

**Example:** `".\azuredeploy.json"`

### Additional Required Parameters (if not using defaults)

- **`-VirtualNetworkName`**: Name of the existing Virtual Network
- **`-subnetName`**: Name of the subnet where the VM will be placed
- **`-virtualNetResourceGroupName`**: Resource Group name of the Virtual Network

## Optional Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| `-region` | `'centralus'` | Azure region for deployment |
| `-VirtualMachinename` | `'DC1'` | Name of the Domain Controller VM |
| `-WindowsOSVersion` | `'2022-Datacenter'` | Windows Server version |
| `-AdminUserName` | `'vadmin'` | Administrator username |
| `-AdminPassword` | `'Test@2016'` | Administrator password (change in production!) |
| `-virtualMachineSize` | `'Standard_B2s'` | Azure VM size |
| `-domainName` | `'contosoad.com'` | Active Directory domain name |
| `-NetBiosDomainname` | `'contosoad'` | NetBIOS domain name |
| `-addUsers` | `$true` | Whether to add users from CSV files |
| `-timeZone` | `'Eastern Standard Time'` | VM timezone |
| `-shutDownTime` | `'01:00'` | Auto-shutdown time |
| `-containerName` | `'storageartifacts'` | Storage container name |

## Usage Examples

### Basic Deployment

```powershell
.\Deploy.ps1 `
  -RG "AD-Lab-RG" `
  -templatefile ".\azuredeploy.json" `
  -VirtualNetworkName "MyVNet" `
  -subnetName "default" `
  -virtualNetResourceGroupName "Network-RG"
```

### Custom Configuration

```powershell
.\Deploy.ps1 `
  -RG "Production-AD-RG" `
  -templatefile ".\azuredeploy.json" `
  -region "eastus" `
  -VirtualMachinename "DC-PROD01" `
  -WindowsOSVersion "2019-Datacenter" `
  -AdminUserName "administrator" `
  -AdminPassword "SecureP@ssw0rd123!" `
  -VirtualNetworkName "Corp-VNet" `
  -virtualMachineSize "Standard_D2s_v3" `
  -subnetName "AD-Subnet" `
  -virtualNetResourceGroupName "Corporate-Network-RG" `
  -domainName "corp.contoso.com" `
  -NetBiosDomainname "CORP" `
  -addUsers $true `
  -timeZone "Pacific Standard Time"
```

### Deployment Without Custom Users

```powershell
.\Deploy.ps1 `
  -RG "Test-AD-RG" `
  -templatefile ".\azuredeploy.json" `
  -VirtualNetworkName "Test-VNet" `
  -subnetName "subnet-1" `
  -virtualNetResourceGroupName "TestNetwork-RG" `
  -addUsers $false
```

## Deployment Process

The script performs the following steps:

1. **Resource Group Creation**: Creates or uses an existing Resource Group
2. **Random Prefix Generation**: Generates a unique identifier for resources
3. **Subnet Resolution**: Retrieves the subnet resource ID from the existing VNet
4. **Public IP Detection**: Determines your current public IP for storage firewall rules
5. **Storage Account Setup**: 
   - Creates a storage account with network security rules
   - Allows access only from your IP and the specified subnet
6. **SAS Token Generation**: Creates temporary access tokens for artifact upload
7. **DSC Package Publishing**: Uploads and publishes the Domain Controller configuration
8. **Custom Scripts Upload**: Copies CSV files and PowerShell scripts for AD customization
9. **ARM Template Deployment**: Deploys the VM and configures it as a Domain Controller

## Custom User/Group Configuration

If `-addUsers` is set to `$true`, the script uploads CSV files from the `CustomScripts` folder:

- **`Users.csv`**: User account definitions
- **`Groups.csv`**: Group definitions
- **`Members.csv`**: Group membership mappings
- **`OUs.csv`**: Organizational Unit structure

## Important Notes

### Security Considerations

⚠️ **WARNING**: The default password (`Test@2016`) is insecure and should only be used for testing. Always use strong passwords in production environments.

### Storage Account Access

The script automatically configures the storage account firewall to:
- Allow your current public IP address
- Allow the VM subnet
- Deny all other traffic

### Network Requirements

The Virtual Network must exist before running this script. The script does not create the VNet.

### Time Zone Values

Common time zone values:
- `'Eastern Standard Time'`
- `'Central Standard Time'`
- `'Mountain Standard Time'`
- `'Pacific Standard Time'`
- `'UTC'`

For a complete list, run: `[System.TimeZoneInfo]::GetSystemTimeZones()`

## Troubleshooting

### Common Issues

**Authentication Error**
```
Connect-AzAccount
```

**Subnet Not Found**
Verify the Virtual Network and subnet names are correct:
```powershell
Get-AzVirtualNetwork | Select-Object Name, ResourceGroupName, @{Name="Subnets";Expression={$_.Subnets.Name}}
```

**Storage Account Creation Fails**
Ensure you have sufficient permissions and the storage account name is unique across Azure.

**Template Deployment Fails**
Use `-Verbose` flag to see detailed deployment information:
```powershell
.\Deploy.ps1 -RG "MyRG" -templatefile ".\azuredeploy.json" ... -Verbose
```

## Files and Folder Structure

```
├── Deploy.ps1                    # Main deployment script
├── azuredeploy.json              # ARM template
├── azuredeploy.parameters.json   # Template parameters
├── CustomScripts/                # AD customization scripts
│   ├── CustomScript.ps1
│   ├── Groups.csv
│   ├── Members.csv
│   ├── OUs.csv
│   ├── Users.csv
│   └── set-customdns.ps1
├── DSC/                          # Desired State Configuration
│   ├── DCConfig.ps1
│   └── DCConfig.psd1
└── NoPowershell/                 # Alternative deployment method
    ├── azuredeploy-nopowershell.json
    ├── readme.md
    └── roleassignment-template.json
```

## Alternative Deployment Method

For deployments without PowerShell orchestration, see the `NoPowershell` folder for ARM template-only deployment options.

## Clean Up

To remove all deployed resources:

```powershell
Remove-AzResourceGroup -Name <your resource group name> -Force
```

## Support

For issues or questions, please refer to the repository documentation or create an issue in the GitHub repository.
