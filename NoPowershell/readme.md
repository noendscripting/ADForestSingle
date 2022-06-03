# Deploying Single DC Without Powershell

## Requirements

* Virtual Network must already exist  in the same Subscription. Can be in a same or difffirent Resource Group
* Deployment account must have Owner or User Access Administrator roles at the Subscription level

>[!WARNING]
>This deployment will change DNS of Virtual Network to Custom with value of the Domain Controller's IP. if you use Azure Private DNS to manage name resolution in your subscripotion make sure that DC forest Domain does not match your Azure Pirvate DNS domain and use Windows DNS on the DC to create conditional forwarders for your Azure Private DNS domain

## Deployment structure

* Deploying consists of two templates, parent 'azuredeploy-nopowershell.json' template and child 'roleassigniment-template.json' template.
* Parent template deploys all nesseseray components
  - User Assigned Managed Identity for the CustomDNS script
  - VM NIC no Public IP
  - DSC Extension to build VM into DC
  - Optional Custom Scripot extension to add users and groups
  - Deployment script resource to set VMs current Ipv4 to static and configure Custom DNS on virtual network
  - Deployment resource to set Network Contributor role to the Resource Group of Virtual Network for User Assigned Managed Identity to enable Deployment script resource to set Custom DNS on Virtual Network
  - Deployment Resource to set Virtual Machine Contributor role to resource group of newly deployed Virtual Machine for User Assigned Managed Identity to enable Deployment script resource to set static IPv4 on the Virtual Machine

* Child template sets up role assigmnets for Resource Groups

## Deployment

* The deploymemt process is like any other ARM template. You cna use either Azure RESt API, Az Powershell or  AZ CLI
Example with Az Powershell - local parent template, no users added, verbose display

        New-AzResourceGroupDeployment -ResourceGroupName <your resource group name>  -RG -templatefile <path to your template file> -VirtualMachinename DC1 -VirtualNetworkName <name of your VNET>  -virtualNetResourceGroupName <Name of the Resource Group of your VNET> -subnetName <name of the subnet where VM is going to be placed> -addUsers $false  -Verbose -virtualMachineSize 'Standard_B2s' -timeZone  'Eastern Standard Time' -WindowsOSVersion "2016-Datacenter" -domainName "contosoad.com" -NetBiosDomainname "contosoad" -AdminUserName vadmin -DSCArchiveFileName DCConfig.zip

>[!NOTE]
> All location of support files such as child template or DSC configurtaion is set to my GitHub repo if you are going to use your own repo please update Template parameters as needed

>[!IMPORTANT]
> After succesfull deployment clear User Assigned Manged Identity from Network Contributor role in the Virtual Network Resource Group and from Virtual Machine Contributor role in the Virtual Machine Resource Group. After that delete the identity itself. This is needed in case you want to do a 'clean' redeployement. If identity clean up is not perfomed new deployment will fail at role assignment step

>[!WARNING]
> if you delete this VM make sure to update Custom DNS configuration in your Virtual Network
