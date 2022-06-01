[CmdletBinding()]
  
Param(
  [string]$region = 'eastus',
  [Parameter(
    Mandatory = $true,
    HelpMessage = "Enter name of the Resource Group where lab is going to be deployed'nIf you enter existing name contents of resoucre group may be overwritten."
  )
  ]
  [string]$RG,
  [Parameter(
    Mandatory = $true,
    HelpMessage = "Enter path to the deployment template"
  )
  ]
  [string]$templatefile,
  [string]$timeZone = 'Eastern Standard Time',
  [string]$shutDownTime = '01:00',
  [string]$containerName = "storageartifacts",
  [string]$VirtualMachinename= "DC1",
  [string]$WindowsOSVersion = "2016-Datacenter",
  [string]$AdminUserName = "mtadmin",
  [string]$AdminPassword = "Test@2017",
  [string]$VirtualNetworkName ,
  [string]$virtualMachineSize= 'Standard_B2s',
  [string]$subnetName ,
  [string]$virtualNetResourceGroupName,
  [string]$domainName = "contosoad.com",
  [string]$NetBiosDomainname = "contosoad",
  [bool]$addUsers = $true

)

Write-Host "Creating Resource Group $($RG)"
New-AzResourceGroup -Name $RG -Location $region -Force
$randomprefix = get-random -Minimum 1000 -Maximum 10000000
Write-Host "Generated random prefix $($randomprefix)"
#create storage account
$storageAccountName = 'adforest' + $randomprefix
Write-Host "Creating storage account name $($storageAccountName)"
$storageAccount = New-AzStorageAccount -ResourceGroupName $RG -Name $storageAccountName -Location $region -type Standard_LRS


#create container and generate SAS tokens to copy files from source to newly created storage account
Write-Host "Creating container $($containerName) for artifact data"
New-AzStorageContainer -Name $containerName -Context $storageAccount.context  | Out-Null
$destcontext = $storageAccount.context
Write-Host "Obtaining SAS token for arctifact container $($containerName)"
$destSASToken = New-AzStorageContainerSASToken -Context $destcontext -ExpiryTime (get-date).AddHours(4).ToUniversalTime() -Name $containerName -Permission racwdl
$artifactSASTokenSecure = ConvertTo-SecureString -String $destSASToken -AsPlainText -Force 
$artifactLocation = "$($destcontext.BlobEndPoint)$($containerName)"
Write-Verbose "Destination SAA $($destSAStoken)"
#endregion
#region publishing DSC package data

$DSConfigPath = "$($PSScriptRoot)\DSC\DCConfig.ps1"
Write-Host "Publishing DConfig DSC package"
$DSConfigURI = Publish-AzVMDscConfiguration -ResourceGroupName $RG -ConfigurationPath $DSConfigPath -StorageAccountName $storageAccountName -ContainerName $containerName -Force
$DSConfigFile = $DSConfigURI.Split("/")[-1]
Write-Host "Succcessfully published DSC config file $($DSConfigFile)"
#endregion
#region uplaoding custom script extension artifacts
Write-Verbose "Artifacts location $($ArtifactLocation)"
Write-Host "Copying custom script artifacts"
Get-ChildItem .\CustomScripts | ForEach-Object {
  Write-Host "Copying file $($_.Name)"
  Set-AzStorageBlobContent -File $_.FullName -Blob $_.FullName.Substring((Get-Item $PSScriptRoot).FullName.Length + 1) -Context $destcontext -Container $containerName -Force | Out-Null

}
#$templatefile = '.\azuredeploy.json'



$DeployParameters = @{
  "Name"                       = "DCLAB_$(get-date -UFormat %Y_%m_%d-%I-%M-%S%p)"
  "ResourceGroupName"          = $RG
  "TemplateFile"               = $templatefile
  "timeZone"           = $timeZone
  "_artifactsLocation"         = $ArtifactLocation
  "_artifactsLocationSasToken" = $artifactSASTokenSecure
  "VirtualMachinename" = $VirtualMachinename
  "AdminUserName" = $AdminUserName
  "AdminPassword" = $AdminPassword | ConvertTo-SecureString -AsPlainText -Force
  "VirtualNetworkName" = $VirtualNetworkName
  "virtualMachineSize" = $virtualMachineSize
  "WindowsOSVersion" = $WindowsOSVersion
  "DSCArchiveFileName" = $DSConfigFile
  "subnetName" = $subnetName
  "virtualNetResourceGroupName" = $virtualNetResourceGroupName
  "domainName" = $domainName
  "NetBiosDomainname" = $NetBiosDomainname
  "addUsers" = $addUsers


}


New-AzResourceGroupDeployment @DeployParameters