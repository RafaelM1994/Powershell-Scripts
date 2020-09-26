
#Path to your CSV file
$csv = Import-Csv "C:\temp\azDatabases.csv"

##TODO
$bin = "$binpath\SqlPackage.exe"
$binpath = "C:\Program Files\Microsoft SQL Server\150\DAC\bin"

#If SQLPackage is not installed, download and install it.
if (Test-Path $bin) {
    write-host "SQL Package is installed" -ForegroundColor Green
    set-location $binpath
}
else {
        
    $sqlPackage = "https://download.microsoft.com/download/d/d/d/ddd3efcd-d5af-4a3f-947f-07520676e54f/x64/DacFramework.msi"
    $Filename = $sqlPackage.Split("/")[-1]
    write-host "SQL Package not found on your computer. Downloading it..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $sqlPackage -UseBasicParsing -OutFile "$env:TEMP\$Filename" 
        
    Write-Host "Installing SQL Package, please wait... " -ForegroundColor Yellow 
        
    $file = "$env:TEMP\$Filename" 
    $arguments = "/i `"$file`" /quiet"
    Start-Process msiexec.exe -ArgumentList $arguments -Wait

    Write-Host "SqlPackage installed." -ForegroundColor Green

    Set-Location $binpath
}     

foreach ($db in $csv){

#Creating a firewall exception to allow your ip to connect to the SQL server.
$myip = (wget ("ipconfig.me")).content

$fwrules = Get-AzSqlServerFirewallRule -ResourceGroupName $rg -ServerName $server
foreach ($fwrule in $fwrules) {
    if ($fwrule.startIpAddress -eq $myip) {
        write-host "The firewall rule already exists for your ip." -ForegroundColor Green
        $ruleexists = $true
        break
    }
    else {}
}

if (-not($ruleexists)) {
    Write-Host "Creating a Firewall exception for $myip..." -ForegroundColor Yellow
    Set-AzSqlServerFirewallRule -ResourceGroupName $rg -ServerName $server -FirewallRuleName "MyIP" -StartIpAddress $myip -EndIpAddress $myip
} 


    #Export the bacpac
    Write-Host "Exporting the bacpac to $($db.outputpath)"
    .\SqlPackage.exe /a:Export /tf:"$($db.outputpath)\$($db.name).bacpac" `
    /scs:"Data Source=$($db.server).database.windows.net,1433;User ID=$($db.sqluser);Password=$($db.sqlpasswd);Initial Catalog=$($db.name);"
}