$solrport = "8005"
$rootFolder = "C:\Solr"
$folder = "install"
$solrfolder = "$rootfolder\$folder"

$time = Measure-Command{
#Stop and Delete Solr Service
sc.exe stop "Solr-$solrport"
sc.exe delete "Solr-$solrport"

start-sleep 2

#Removes Solr Folder
Remove-Item -Path $solrfolder -Recurse -Force -ErrorAction SilentlyContinue
}

$message = "It took {0} minutes and {1} seconds to finish this task." -f $time.Minutes, $time.Seconds
Write-Host $message -ForegroundColor Green