<#
.SYNOPSIS
    Script to Generate a Health Report.
.DESCRIPTION
    This script will a generate a report of the cluster Health and its virtual machines, and then send it via email.
    The information will be retrieved from the Virtual Machine Manager.

.NOTES
    Author: Rafael de Jesus Medeiros <rafael_medeiros94@hotmail.com.br>
    GitHub: 
    Creation Date: 11/09/2019

    In order to get the information from the cluster, you need to have the System Center Virtual Machine Manager installed.
    Tested in System Center Virtual Machine Manager 2016
    
#>

#Function to convert the values retrieved from VMM
function Convert-Size {            
    [cmdletbinding()]            
    param(            
        [validateset("Bytes","KB","MB","GB","TB")]            
        [string]$From,            
        [validateset("Bytes","KB","MB","GB","TB")]            
        [string]$To,            
        [Parameter(Mandatory=$true,ValueFromPipeline)]         
        [Double]$Value,            
        [int]$Precision = 4            
    )            
    switch($From) {            
        "Bytes" {$value = $Value }            
        "KB" {$value = $Value * 1024 }            
        "MB" {$value = $Value * 1024 * 1024}            
        "GB" {$value = $Value * 1024 * 1024 * 1024}            
        "TB" {$value = $Value * 1024 * 1024 * 1024 * 1024}            
    }            
                
    switch ($To) {            
        "Bytes" {return $value}            
        "KB" {$Value = $Value/1KB}            
        "MB" {$Value = $Value/1MB}            
        "GB" {$Value = $Value/1GB}            
        "TB" {$Value = $Value/1TB}            
                
    }            
                
    return [Math]::Round($value,$Precision,[MidPointRounding]::AwayFromZero)            
                
}   

$PageTitle   = "Cluster Health Report"
$ClusterName = "CLUSTERNAME"

#Name of the Nodes in the cluster
$PhysicalServers = @("server01","server02", "server03")

#Adding some style in the report table
$Header = @"
<style>
h1, h5, th { text-align: center; }
table { margin: auto; font-family: Segoe UI; box-shadow: 10px 10px 5px #888; border: thin ridge grey; }
th { background: #434c5c; color: #fff; max-width: 400px; padding: 5px 10px; }
td { font-size: 12px; padding: 5px 25px; color: #000; }
tr { background: #b8d1f3; }
tr:nth-child(even) { background: #dae5f4; }
tr:nth-child(odd) { background: #b8d1f3; }
</style>
"@

#------------------------------------------------------------------------
# Generating report from the VMs
#------------------------------------------------------------------------

#Get the Vms and store the information in the Vms variable
Write-Host "Retrieving information about the vms..." -ForegroundColor Yellow
$Vms     = Get-SCVirtualMachine

#Get the Cluster information and store the information in the Cluster variable
Write-Host "Retrieving information about the cluster..." -ForegroundColor Yellow
$Cluster = Get-SCVMHostCluster

#Create one array for each physical server
$server01 = @()
$server02 = @()
$server03 = @()

#Retrieving the memory, CPU, total space and space available of the cluster

$memory = @()
$CPU    = @()
Write-Host "Retrieving the memory, CPU, Total Space and space available..." -ForegroundColor Yellow
foreach ($node in $Cluster.Nodes){

    $memory        += ([math]::Round($node.TotalMemory /1gb)).tostring()
    $CPU           += (($node.LogicalCPUCount).tostring())
    $TotalSpace     = [math]::Round(($Cluster.Nodes[0].TotalStorageCapacity)/1tb)
    $SpaceAvailable = [math]::Round(($Cluster.Nodes[0].AvailableStorageCapacity)/1tb)
}

#Sorting the objects to put in ascending order by name
$memory = $memory | Sort-Object
$CPU    = $CPU    | Sort-Object

#----------------------------------------------------------------------
#HTML Part
#----------------------------------------------------------------------
Write-Host "Creating the HTML page..." -ForegroundColor Yellow
#Creating the table of information from the cluster itself
$Clusterhtml = ""
$Clusterhtml += "<center><h2>$ClusterName</h2></center><tr><th>Name</th><th>Memory</th><th>Logical Processors"
$Clusterhtml += "</th><th>Space Available</th><th>Total Space</th></tr>"

#Creating the table with the information from all of the vms splitted by physical node
$n = 0
foreach ($node in ($Cluster.nodes.name | Sort-Object)){ 

    $Clusterhtml += "<tr><td><b>$($(($node).split('.')[0]).ToUpper())</b></td>"
    $Clusterhtml += "<td>"+ $memory[$n] + " GB <br></td>"
    $Clusterhtml += "<td>"+ $CPU[$n] + "<br></td>"
    $Clusterhtml += "<td>"+ $spaceAvailable + " TB (All Cluster)<br></td>"
    $Clusterhtml += "<td>"+ $TotalSpace + " TB (All Cluster)<br></td></tr>"
    $n++
}

#Put the title on the page
$date = Get-Date -format "dd-MMM-yyyy"
$htmlhv = ConvertTo-HTML -Title "$PageTitle" -PreContent "<Center><h1>$PageTitle ($date)</h1></center>"

#Put the cluster memory on the page
$htmlhv += ConvertTo-Html -Body "<table><center>$Clusterhtml</center></table>"

#put each vm to the server array that this vm belongs to 
foreach ($vm in $Vms) {

    if($vm.VMHost.ComputerName -eq $PhysicalServers[0]){
        
        $server01 += @($vm)

    }elseif ($vm.VMHost.ComputerName -eq $PhysicalServers[1]) {

        $server02 += @($vm)

    }else{

        $server03 += @($vm)
    } 
}

$servers = $server01, $server02, $server03

$n = 0
foreach ($PhysicalServer in $servers){
    
    #Get the VMStatus, TotalMemory, MemoryDemand, MemoryStatus, DiskSize, OperatingSystem and Domain of the vm
    $html = $PhysicalServer | Sort-Object -Property Name | Select-Object name,@{ Name = 'VMStatus'; Expression = {  $_.VirtualMachineState }},
                                                    @{Name = 'TotalMemory';Expression = {((Convert-Size -From MB -To KB -Value ($_.memoryassignedmb).tostring() `
                                                    | Convert-Size -from KB -to GB -Precision 1)).tostring() + ' GB'}},
                                                    @{Name = 'MemoryDemand';Expression = {((Convert-Size -From MB -To KB -Value ($_.DynamicMemoryDemandMB).tostring() `
                                                    | Convert-Size -from KB -to GB -Precision 1)).tostring() + ' GB'}},
                                                    @{Name = 'MemoryStatus';Expression = {$_.DynamicMemoryStatus}},
                                                    @{Name = 'DiskSize';Expression = {([math]::Round($_.totalsize /1gb)).tostring() + ' GB'}},           
                                                    @{Name = 'OperatingSystem';Expression = {$_.OperatingSystem}},
                                                    @{Name = 'Domain';Expression = {$_.Tag}}

    #Convert the previous result in html
    $htmlhv += $html | ConvertTo-HTML -PreContent "<Center><h2>$($PhysicalServers[$n].ToUpper())</h2></Center>"

    #The steps below are to change the font color for the VM Status and Memory Status in the HTML code
    $htmlhv = $htmlhv | ForEach-Object {
        $_ -replace "<td>Running</td>","<td style=`"color: green`">Running</td>"
    }
    $htmlhv = $htmlhv | ForEach-Object {
        $_ -replace "<td>PowerOff</td>","<td style=`"color: red`">PowerOff</td>"
    }

    $htmlhv = $htmlhv | ForEach-Object {
        $_ -replace "<td>OK</td>","<td style=`"color: green`">OK</td>"
    }
    $htmlhv = $htmlhv | ForEach-Object {
        $_ -replace "<td>Low</td>","<td style=`"color: yellow`">Low</td>"
    }
    $htmlhv = $htmlhv | ForEach-Object {
        $_ -replace "<td>Warning</td>","<td style=`"color: red`">Warning</td>"
    }
    $n++
}

#gets the htmlhv html code, put the header stored in $Header and save into an html file
ConvertTo-HTML -body "$htmlhv" -Head $Header  | Set-Content ".\vmsreportedbyserver.html"

Write-Host "Starting a web page to see the results..." -ForegroundColor Yellow
Start-Process .\vmsreportedbyserver.html

$SMTPServer    = 'company.mail.protection.outlook.com'
$MailSender    = "Cluster Bot <bot@company.com>"
$Subject       = "Cluster Health Report"
$touser        = "firstname.lastname@company.com"

$body = Get-Content ".\vmsreportedbyserver.html" -Raw
Write-Host "Sending the Report via e-mail..." -ForegroundColor Yellow
Send-MailMessage -To $toUser -From $MailSender -SmtpServer $SMTPServer -Subject $Subject -Body $Body  -BodyAsHtml 

Write-Host "Script finished" -ForegroundColor Green       

