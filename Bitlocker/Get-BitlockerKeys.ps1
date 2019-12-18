<#
.SYNOPSIS
    Script to retrieve all of the bitlocker keys from the computer accounts.
.DESCRIPTION
    This script will a generate a csv file that contains the name of the computers 
    and their respectives bitlocker keys that were stored in the Active Directory.
.NOTES
    Author: Rafael de Jesus Medeiros <rafael_medeiros94@hotmail.com.br>
    GitHub: https://github.com/RafaelM1994/Powershell-Scripts/
    Creation Date: 12/01/2019
    
#>

$OU = "OU=Computers,OU=CA,DC=contoso,DC=com" 
$computers = Get-ADComputer -Filter * -SearchBase $OU 

$Bitlocker_Object = @()
foreach ($computer in $computers){

    $objComputer = $computer
    $Bitlocker_Object += Get-ADObject -Filter {objectclass -eq 'msFVE-RecoveryInformation'} -SearchBase $objComputer.DistinguishedName -Properties 'msFVE-RecoveryPassword'
    $csv = $Bitlocker_Object | select   @{Name = 'ComputerName';Expression = {($_.DistinguishedName.Split(",")[1]) -replace "CN="}},
                                        @{Name = 'KeyPresent';Expression = {if ($_.'msFVE-RecoveryPassword'){write-output "Yes"}else{Write-Output "No"}} 
}

$CSVPath = "$env:Userprofile\Documents\BitlockerKeys.csv"
$CSV | Export-Csv -Path $CSVPath -NoTypeInformation -Encoding UTF8