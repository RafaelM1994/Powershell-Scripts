param (
    $SolrFolder = "C:\Solr"
)
$ErrorActionPreference = "Stop"

#Enable tls1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#install NuGet And Trust PsGallery
if(-not((Get-PackageProvider).name -contains "NuGet")){
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
}
if (-not((Get-PSRepository -name "PSGallery").InstallationPolicy -eq "Trusted")){
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
}
if (-not((Get-Module -name "7Zip4Powershell" -ListAvailable))){
    Install-Module  "7Zip4Powershell" -Force -SkipPublisherCheck
}

. ".\Modules\functions.ps1"

Install-Java -targetFolder $SolrFolder -jreFolderName "Java"
