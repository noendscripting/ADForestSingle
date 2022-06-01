param(
    $resourceGroup,
    $vNetResourceGroupName,
    $vnetName,
    $dcName

)
$dnsArray=@()
    
$nicConfigurationData = Get-AzNetworkInterface -ResourceId (get-azvm -ResourceGroupName $resourceGroup -Name $dcName).NetworkProfile.NetworkInterfaces.id
$nicConfigurationData.IpConfigurations[0].PrivateIpAllocationMethod = "Static"
Set-AzNetworkInterface -NetworkInterface $nicConfigurationData
$dnsArray += $nicConfigurationData.IpConfigurations[0].PrivateIpAddress
$ErrorActionPreference = 'Stop'
$vnetData = Get-AzVirtualNetwork -ResourceGroupName $vNetResourceGroupName -Name $vnetName
$vnetdata.DhcpOptions.DnsServers = $dnsArray
$vnetData | Set-AzVirtualNetwork