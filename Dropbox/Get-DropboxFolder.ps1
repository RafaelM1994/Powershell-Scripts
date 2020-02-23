function Get-DropboxFolder {

    [CmdletBinding()]
    Param(
        [string]$DropboxFolder, 
        [string]$OutputFolder,
        [string]$FolderPath
    )
    $body = '{"path":"/'+$DropboxFolder+'"}'

    $AuthToken = 'lsUMntF6jMAAARTYUGDWmFJQybaT5G-XzUY_9sQ9AqXDRyZoFT0jhBeTMvXzQ'
    $token = "Bearer $AuthToken" 
    
    #The file will be downloaded as ZIP to the Temp folder of the user
    $Tempfolder = "$env:temp\Downloaded_File.zip"

    if (!(Test-Path $FolderPath)){
        Write-Verbose "Downloading the folder..."
        Invoke-RestMethod `
                -Method POST `
                -Uri "https://content.dropboxapi.com/2/files/download_zip" `
                -Headers @{ "Authorization" = $token; "Dropbox-API-Arg" = $body} `
                -OutFile $Tempfolder -ContentType ""
        
        #The file will be extracted and then removed from the temp 
        write-verbose "Extracting the folder..."
        Expand-Archive -LiteralPath $Tempfolder -DestinationPath $OutputFolder -Force
        Remove-Item $Tempfolder -Force
        Write-Verbose "The folder has been downloaded."
    }else{
        Write-Verbose "Folder Exists."
    }

}

$DropboxFolder    = "Finance/software/Software01"
$OutputFolder  = "$env:HOMEDRIVE\Softwares"
$FolderPath    = "$OutputFolder\Software01"

Get-DropboxFolder -DropboxFolder $DropboxFolder -OutputFolder $OutputFolder -FolderPath $FolderPath -verbose