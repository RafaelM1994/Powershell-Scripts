function Set-JavaHome
{
    param(
        [string]$jrePath,
        [string]$environmentVariable = "JAVA_HOME",
        [bool]$overwriteEnvironmentVariable = $false
    )

    $val = [Environment]::GetEnvironmentVariable($environmentVariable, [EnvironmentVariableTarget]::Machine)

    if([string]::IsNullOrWhiteSpace($val) -or $overwriteEnvironmentVariable)
    {
        [Environment]::SetEnvironmentVariable($environmentVariable, $jrePath, [EnvironmentVariableTarget]::Machine)
		$env:JAVA_HOME = $jrePath
        Write-Host "Updated $environmentVariable to `"$jrePath`""
    }
    else
    {
        Write-Host "Not updating $environmentVariable - existing value `"$val`"" -ForegroundColor Green
    }

	# Add JRE to path
	$path = [Environment]::GetEnvironmentVariable("PATH",[EnvironmentVariableTarget]::Machine)
	if(-not $path.Contains($jrePath) )
	{
		$jreBinPath = Join-Path $jrePath "bin"
		$path = "$path;$jreBinPath"
		[Environment]::SetEnvironmentVariable("PATH", $path, [EnvironmentVariableTarget]::Machine)

		$env:Path = $env:Path + ";" + $jreBinPath

		Write-Host "Updated path to `"$path`"" -ForegroundColor Green
	}
	else
	{
	Write-Host "Not updating path - existing value `"$path`"" -ForegroundColor Yellow
	}
}

function Expand-JREZip
{
	param(
        [string] $jdkZip,
        [string] $workingFolder,
		[string] $jreFolderName = "JRE"
    )
    
    $jreFolderPath = "$workingFolder\$jreFolderName"

    if(!(Test-Path $jreFolderPath))
    {
        Write-Host "Expanding archive for $jdkZip to get $jreFolderName"

        Expand-Archive $jdkZip "$workingFolder\tmp"

        $jreFolder = Get-ChildItem -Path "$workingFolder\tmp" -Directory | select -ExpandProperty FullName

        Move-Item $jreFolder $jreFolderPath
        Remove-Item "$workingFolder\tmp" -Recurse
    }
    else
    {
        Write-Host "No need to extract $jdkZip - Folder $jreFolderName exists" -ForegroundColor Green
    }

    return $jreFolderPath
}

function Expand-Nssm
{
    param(
        [string] $nssmZip,
        [string] $workingFolder,
        [string] $nssmFolderName
    )

    $nssmDirectory = "$workingFolder\$nssmFolderName"

    if(!(Test-Path $nssmDirectory))
    {
        Write-Host "Extracting $nssmZip to $nssmDirectory"

        Expand-Archive $nssmZip $workingFolder

        $expandedFolder = $workingFolder | Get-ChildItem -Filter "nssm-*" | select -ExpandProperty FullName

        $win64Folder = "$expandedFolder\Win64"
        Move-Item $win64Folder $nssmDirectory
        Remove-Item $expandedFolder -Recurse
    }
    else
    {
        Write-Host "No need to extract nssm - it already exists"
    }
}

function Get-ToolPackage
{
    param(
        [string]$toolName,
        [string]$downloadUrl,
        [string]$outputFile,
        [bool]$useBitsTransfer = $true
    )

    if(!(Test-Path -Path $outputFile))
    {
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 + [Net.SecurityProtocolType]::Tls11 + [Net.SecurityProtocolType]::Tls1

        Write-Host "Downloading $toolName..." -ForegroundColor Yellow
        if($useBitsTransfer)
        {
            Start-BitsTransfer -Source $downloadUrl -Destination $outputFile
        }
        else
        {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFile
        }
    }
    else
    {
        Write-Host "No need to download $toolName - it's already present..." -ForegroundColor Green
    }
}

function New-Folder
{
    param(
        [string]$folder
    )

    if(!(Test-Path $folder)){
        Write-Host "Creating folder $folder"
        New-Item $folder -ItemType Directory | Out-Null
    }
    else
    {
        Write-Host "Folder $folder exists" -ForegroundColor Green
    }
}


function Install-Java
{
	param(
		[string]$targetFolder = "C:\Solr",
		[string]$javaRelease = "https://github.com/ojdkbuild/ojdkbuild/releases/download/java-1.8.0-openjdk-1.8.0.222-2.b10/java-1.8.0-openjdk-jre-1.8.0.222-2.b10.ojdkbuild.windows.x86_64.zip",
		[string]$jreFolderName = "Java"
	)

	New-Folder $targetFolder

	$downloadedZipFile = "$targetFolder\jre.zip"

	Get-ToolPackage "OpenJDK" $javaRelease $downloadedZipFile $false
	$jreFolder = Expand-JREZip -jdkZip $downloadedZipFile -workingFolder $targetFolder -jreFolderName $jreFolderName
	Set-JavaHome $jreFolder
    Remove-Item -Path $downloadedZipFile -Force -ErrorAction SilentlyContinue
}

function New-SslCertificate
{
    param(
        [string]$workingFolder,
        [string[]]$hostNames,
        [string]$certFriendlyName,
        [string]$certPassword
    )

    Write-Host "Looking for certificate $certFriendlyName"
    $cert = Get-ChildItem -Path Cert:\LocalMachine\Root | where { $_.FriendlyName -eq $certFriendlyName }

    if( $cert -eq $null )
    {
        $cert = New-SelfSignedCertificate -Subject $certFriendlyName -FriendlyName $certFriendlyName -DnsName $hostNames -CertStoreLocation "cert:\LocalMachine\My" -NotAfter (Get-Date).AddYears(10)
        Write-Host "Created certificate $($cert.Thumbprint)"

        Move-Item "cert:\LocalMachine\my\$($cert.Thumbprint)" "cert:\LocalMachine\Root"
        Write-Host "Moved cert to trusted store"

        $cert = Get-Item "cert:\LocalMachine\Root\$($cert.Thumbprint)"
    }
    else
    {
        Write-Host "Found certificate $($cert.Thumbprint)"
    }

    $certStore = "$workingFolder\solr.keystore.pfx"
    $certPwd = ConvertTo-SecureString -String $certPassword -Force -AsPlainText
    $cert | Export-PfxCertificate -FilePath $certStore -Password $certpwd | Out-Null
    Write-Host "Exported Cert to $certStore"

}

function Expand-SolrArchive
{
    param(
        [string] $solrArchive,
        [string] $workingFolder,
        [string] $solrFolderName
    )

    $solrDirectory = "$workingFolder\$solrFolderName"

    if(!(Test-Path $solrDirectory))
    {
        Write-Host "Extracting $solrArchive to $solrDirectory"

        Expand-Archive $solrArchive $workingFolder -Force

        $createdFolder = $workingFolder | Get-ChildItem -Filter "solr-*" | select -ExpandProperty FullName

        Rename-Item $createdFolder $solrFolderName -Force
    }
    else
    {
        Write-Host "No need to extract Solr - it already exists"
    }

    return $solrDirectory
}

function Set-SolrConfig
{
    param(
        [string]$solrFolder,
        [string]$certFile,
        [string]$certPassword,
        [string]$solrHost,
        [string]$solrPort
    )

    # write config changes
    if(!(Test-Path -Path "$solrFolder\bin\solr.in.cmd.old"))
    {
        Write-Host "Rewriting solr config for instance $solrInstance"
 
        $cfg = Get-Content "$solrFolder\bin\solr.in.cmd"
        Rename-Item "$solrFolder\bin\solr.in.cmd" "$solrFolder\bin\solr.in.cmd.old"
        $newCfg = $cfg | % { $_ -replace "REM set SOLR_SSL_KEY_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_KEY_STORE=etc/$certFile" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_KEY_STORE_PASSWORD=secret", "set SOLR_SSL_KEY_STORE_PASSWORD=$certPassword" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_TRUST_STORE=etc/$certFile" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE_PASSWORD=secret", "set SOLR_SSL_TRUST_STORE_PASSWORD=$certPassword" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_HOST=192.168.1.1", "set SOLR_HOST=$solrHost" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_PORT=8983", "set SOLR_PORT=$solrPort" }
        $newCfg | Set-Content "$solrFolder\bin\solr.in.cmd"
    }
    else
    {
        Write-Host "Solr config is already modified" -ForegroundColor Green
    }
}

function New-SolrService
{
    param(
        [string]$nssmFolder,
        [string]$solrFolder,
        [string]$solrServiceName
    )

    $svc = Get-Service "$solrServiceName" -ErrorAction SilentlyContinue
    if(!($svc))
    {
        Write-Host "Installing Solr service $solrServiceName"

        $nssmCommand = "$nssmFolder\nssm.exe"
        $solrCommand = "$solrFolder\bin\solr.cmd"

        & $nssmCommand install $solrServiceName $solrCommand "-f -c"
    }
    else
    {
        Write-Host "Solr service $solrServiceName already exists."
    }
}


function Install-SolrInstance
{
	param(
		[string]$targetFolder = "C:\SolrCloud",
		[string]$solrPackage = "",
		[string]$solrFolderName = "SOLR",
		[string]$certificateFile = "folder\solr.keystore.pfx",
		[string]$certificatePassword = "secret",
		[string]$solrHostname = "solr",
        [string]$domain,
		[string]$solrPort = "9999",
		[bool]$installService = $false
	)

	$downloadedZipFile = "$targetFolder\solr.zip"

	Get-ToolPackage "Solr" $solrPackage $downloadedZipFile
	$solrFolder = Expand-SolrArchive $downloadedZipFile $targetFolder $solrFolderName

	Set-SolrConfig $solrFolder $certificateFile $certificatePassword $solrHostname $solrPort

    New-SslCertificate -workingfolder $solrFolder `
                    -hostnames $solrhostname `
                    -certFriendlyName "$domain - Solr SSL Certificate" `
                    -certPassword $certificatePassword

    Move-Item "$solrFolder\solr.keystore.pfx"  "$solrfolder\server\etc\solr.keystore.pfx"

	if($installService)
	{
		New-SolrService "$targetFolder\NSSM" $solrFolder "Solr-$solrPort"
	}
}

function Wait-SolrInitialization
{
    param(
        [string]$solrHost,
        [int]$solrPort
    )

	Write-Host "Waiting for Solr to start on https://$($solrHost):$solrPort"
    $done = $false
    while(!$done)
    {
        try
        {
            Invoke-WebRequest "https://$($solrHost):$($solrPort)/solr" -UseBasicParsing | Out-Null
            $done = $true
        }
        catch
        {
        }
    }
	Write-Host "Solr is up and running!" -ForegroundColor Green
}


function Add-HostEntries
{
	param(
		[string]$hostFileName = "c:\windows\system32\drivers\etc\hosts",
		[string[]]$linesToAdd
	)
    
    $hostFile = [System.Io.File]::ReadAllText($hostFileName)
    
	$text = ""
	foreach($lineToAdd in $linesToAdd)
	{
		if( -not ($hostFile -like "*$lineToAdd*") )
		{
			$text = "$text`r`n$lineToAdd"
		}
	}
	if($text.Length -gt 0)
	{
		Write-Host "Updating host file at `"$hostFileName`""
		$text | Add-Content $hostFileName 
	}
	else
	{
		Write-Host "No changes required to host file."
	}
}
