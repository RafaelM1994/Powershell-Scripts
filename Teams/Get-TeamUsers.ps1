#Module name: Get-TeamUsers.ps1
#Modified By: Rafael de Jesus Medeiros 
#Date: 08/07/2020
#Purpose: Get users and their roles from a Team on Teams and add them to a CSV file.
#Output:
#   email                          | role
#   firstname.lastname@valtech.com | Owner
#   firstname.lastname@valtech.com | Member
   
function Get-TeamUsersToCSV {
    param (
        [string]$TeamGroupName,
        [string]$OutputPath
    )
    
    
    if (-not (get-module -ListAvailable | Where-Object { $_.Name -eq "MicrosoftTeams" })) {
        Install-Module MicrosoftTeams -Force
    }

    write-host "Enter your Admin Credentials (Prompt Screen might be behind this one):" -foregroundcolor yellow
    Connect-MicrosoftTeams 

    
    $groupid = (Get-Team -DisplayName $TeamGroupName).GroupId

    #$channels = (Get-TeamChannel -GroupId $groupid).DisplayName

    #Get users and their roles on this Team
    Get-TeamUser -GroupId $groupid | 
    Select-Object @{name='email' ; Expression={$_.user}},role |
    export-csv -path $OutputPath -NoTypeInformation -Encoding UTF8

}

$TeamGroupName = "Group.Name"
$FilePath = "C:\Temp\$TeamGroupName.csv"

Get-TeamUsersToCSV -TeamGroupName $TeamGroupName -OutputPath $FilePath

