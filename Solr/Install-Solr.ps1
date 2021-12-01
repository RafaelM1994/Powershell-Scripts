param (

    $domain = "myinstance.local",
    $computername = "solr1",
    $hostname = "$computername.$domain",
    $solrport = "",
    $installservice = $true,
    $rootFolder = "C:\Solr",
    $folder = "install",
    $solrfolder = "$rootfolder\$folder",
    $solrpackage = "https://archive.apache.org/dist/lucene/solr/8.4.0/solr-8.4.0.zip",
    $nssmpackage = "",
    $certname = "",
    $certpwd = "" 
)

. ".\Modules\functions.ps1"

#Enable tls1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Install NSSM to configure Solr Service
Get-ToolPackage "NSSM" $nssmpackage "$rootfolder\NSSM.zip" $false
Expand-Nssm "$rootfolder\NSSM.zip" $rootFolder "NSSM"

#Add Solr Hosts IPs entries to the hosts file if needed
Add-HostEntries -linesToAdd @("#", "127.0.0.1    $hostname")

Install-SolrInstance -targetFolder $rootfolder `
    -installService $installService `
    -solrFolderName $folder `
    -solrHostname $hostname `
    -domain $domain `
    -solrPort $solrport `
    -certificateFile $certname `
    -certificatePassword $certPwd `
    -solrPackage $solrPackage

Write-Host "Starting Solr Service..." -ForegroundColor Green
Start-Service "Solr-$solrport"

Wait-SolrInitialization -solrhost $hostname -solrport $solrport

#Open solr browser page 
#(it will throw an error if you already have the browser opened, you have to close and re-open it)
Start-Process "https://$($hostname):$solrport/solr/#/"

#HTTPS request to make sure that SOLR will respond to https requests
Invoke-WebRequest -Uri "https://$($hostname):$solrport/solr/#/" -Method Get -UseBasicParsing

