# deploy vm(s) from a selected list of templates
# select vcenter
# select cluster
# 

# connect to vcenter with credentials
$vcenter = Read-Host "Which vCenter?"
$ADcreds = Get-Credential
Connect-VIServer $vcenter -Credential $ADcreds

# give new vm a name
$vmname = Read-Host "Enter the name you wish to give the new VM"

# choose from the list of templates
$templates = Get-Template -Server $vcenter
Write-Host "Choose your template from the list:"
$i = 1
$tempList = @()
foreach ($template in $templates) {
    $tempList += $template.Name
    Write-Host "$i `t $template"
    $i++
}
$templateChoice = Read-Host "Enter the template number"

# choose the datacenter
$dcs = Get-Datacenter -Server $vcenter
Write-Host "Choose your datacenter from the list:"
$i = 1
$dcList = @()
foreach ($dc in $dcs) {
    $dcList += $dc.Name
    Write-Host "$i `t $dc"
    $i++
}
$dcChoice = Read-Host "Enter the datacenter number"

# choose the cluster
$clusters = Get-Cluster -Server $vcenter -Location $dcList[$dcChoice-1]
Write-Host "Choose your cluster from the list:"
$i = 1
$clusterList = @()
foreach ($cluster in $clusters) {
    $clusterList += $cluster.Name
    Write-Host "$i `t $cluster"
    $i++
}
$clusterChoice = Read-Host "Enter the cluster number"

# choose the datastore
$datastores = Get-Datastore -Server $vcenter -Location $dcList[$dcChoice-1] | Select-Object name, @{name="FreeSpaceGB";Expression={[math]::Round($_.freespacegb,0)}}
Write-Host "Choose your datastore from the list:"
Write-Host "`t FreeGB `t Datastore"
$i = 1
$dsList = @()
foreach ($datastore in $datastores) {
    $dsList += $datastore.Name
    Write-Host "$i `t $($datastore.FreeSpaceGB) `t $($datastore.Name)"
    $i++
}
$dsChoice = Read-Host "Enter the datastore number"

# choose the network
$networks = Get-VirtualNetwork -Server $vcenter -Location $dcList[$dcChoice-1]
Write-Host "Choose your network from the list:"
$i = 1
$netList = @()
foreach ($network in $networks) {
    $netList += $network.Name
    Write-Host "$i `t $network"
    $i++
}
$netChoice = Read-Host "Enter the network number"

# choose the folder location
$folders = Get-Folder -Server $vcenter -Location $dcList[$dcChoice-1] -Type VM
Write-Host "Choose your folder from the list:"
$i = 1
$folderList = @()
$ignore = @('vm','network','host','datastore')
foreach ($folder in $folders) {
    if ($ignore -contains $folder) {continue}
    $folderList += $folder.Name
    Write-Host "$i `t $folder"
    $i++
}
$folderChoice = Read-Host "Enter the folder number"

# create new vm 
Write-Host "Creating new VM $vmname from template $($tempList[$templateChoice-1]) in vCenter $vcenter / datacenter $($dcList[$dcChoice-1]) and folder $($folderList[$folderChoice-1])"
New-VM -Server $vcenter -Name $vmname -Template $tempList[$templateChoice-1] -ResourcePool $clusterList[$clusterChoice-1] -Datastore $dsList[$dsChoice-1] -Location $folderList[$folderChoice-1]
# add network
New-NetworkAdapter -Server $vcenter -VM $vmname -StartConnected -NetworkName $netList[$netChoice-1] -Type Vmxnet3

# ask to power on
$answer = Read-Host "Enter 'YES' to power on $vmname"
if ($answer -cne "YES") {return}
else {Start-VM -VM $vmname}