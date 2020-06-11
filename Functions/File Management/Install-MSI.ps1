Function Install-MSI{

    param(
        [System.IO.FileInfo[]]$MsiFile
    )

    $FileExists = Test-Path $msifile -IsValid
    $DataStamp = get-date -Format yyyyMMddTHHmmss
    $logFile = '{0}-{1}.log' -f $msifile.fullname,$DataStamp

    $MSIArguments = @(
        "/i"
        ('"{0}"' -f $msifile.fullname)
        "/qn"
        "/norestart"
        "/L*v"
        $logFile
    )

    If ($FileExists -eq $True){
        Start-Process "msiexec.exe" -ArgumentList $MSIArguments -passthru | wait-process
        write-host "The MSI has been successfully installed. " -ForegroundColor Green
    
    }Else{

        Write-Host "File doesn't exists" -ForegroundColor Red
        }
    }

    Install-MSI -msifile $msifile