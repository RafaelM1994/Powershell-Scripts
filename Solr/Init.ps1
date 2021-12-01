$rootFolder = "C:\Solr"
$folder = "install"
$solrfolder = "$rootfolder\$folder" #Path where Solr will be installed
$domain = "myinstance.local"
$computername = "solr1" 
$hostname = "$computername.$domain" 
$SolrPort = "8000"
$installService = $true
$solrPackage = "https://archive.apache.org/dist/lucene/solr/8.4.0/solr-8.4.0.zip"
$nssmpackage = "https://nssm.cc/release/nssm-2.24.zip"
$certname = "solr.keystore.pfx"
$certpwd = "Test@123"


$time = Measure-Command { 

    .\Setup-Java.ps1 -SolrFolder $rootFolder

    Start-Sleep 5

    .\Install-Solr.ps1 -domain $domain `
        -computername $computername `
        -hostname $hostname `
        -solrport $SolrPort `
        -installservice $installService `
        -rootFolder $rootFolder `
        -folder $folder `
        -solrfolder $solrfolder `
        -solrpackage $solrPackage `
        -nssmpackage $nssmpackage `
        -certname $certname `
        -certpwd $certpwd
}
$message = "It took {0} minutes and {1} seconds to finish this task." -f $time.Minutes, $time.Seconds
Write-Host $message -ForegroundColor Green