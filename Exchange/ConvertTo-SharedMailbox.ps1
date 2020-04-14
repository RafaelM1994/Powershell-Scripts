<#
.SYNOPSIS
    Script to Convert a Regular Mailbox into a Shared Mailbox
.DESCRIPTION
    This script will convert a default mailbox into a shared mailbox using the ExoPowershellModule.
.NOTES
    Author: Rafael de Jesus Medeiros <rafael_medeiros94@hotmail.com.br>
    GitHub: https://github.com/RafaelM1994/Powershell-Scripts/
    Creation Date: 02/10/2020
    
#>


$user = "firstname.lastname@company.com"

#Exchange credentials
try{
    $IsActiveSession = (Get-Mailbox -ResultSize 1 -WarningAction silentlyContinue ).name.length -gt 0
}catch{

}

if ($IsActiveSession){
    write-host "[INFO]EXO Session OK." -foregroundcolor green
}else{
    clear-host
    Write-host "Connecting to the Exchange Service, 
    please insert your credentials in the window that can be behind the current one..." -foregroundcolor yellow
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    Install-Module -Name Microsoft.Exchange.Management.ExoPowershellModule -Confirm:$false
    $SesionO365 = New-EXOPSSession
    Import-PSSession $SesionO365 -AllowClobber
}

#Convert User mailbox to a shared mailbox
Set-Mailbox $user -Type Shared -Verbose