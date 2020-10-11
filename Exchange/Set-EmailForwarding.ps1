<#
.SYNOPSIS
    Script to Convert a Enable Email forwarding in a mailbox
.DESCRIPTION
    This script will enable email forwarding in a mailbox.
.NOTES
    Author: Rafael de Jesus Medeiros <rafael_medeiros94@hotmail.com.br>
    GitHub: https://github.com/RafaelM1994/Powershell-Scripts/
    Creation Date: 02/15/2020
    
#>

$user = "firstname.lastname@company.com"
$ForwardedUserEmail = "firstname.lastname@company.com"

#Exchange credentials
try{
    $IsActiveSession = (Get-Mailbox -ResultSize 1 -WarningAction silentlyContinue ).name.length -gt 0
}catch{

}

if ($IsActiveSession){
    write-host "[INFO]EXO Session OK." -foregroundcolor green
}else{
    clear-host

    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    Install-Module -Name Microsoft.Exchange.Management.ExoPowershellModule -Confirm:$false
    Write-host "Connecting to the Exchange Service, 
    please insert your credentials in the window that can be behind the current one..." -foregroundcolor yellow
    $SesionO365 = New-EXOPSSession
    Import-PSSession $SesionO365 -AllowClobber
}



#Forward the emails from this mailbox to another if needed
Write-Host "Configuring email forwarding from $user to $forwardedUserEmail..." -ForegroundColor Yellow
Set-Mailbox $user  -ForwardingSmtpAddress:$ForwardedUserEmail -Verbose

$forwarding = (Get-Mailbox $user).forwardingSmtpAddress

if ($forwarding -eq "smtp:$forwardedUserEmail"){
    Write-Host "Forwarding rule successfully applied." -ForegroundColor Green
}else{
    write-host "Forwarding rule not applied, please check both mailboxes addresses and try again." -ForegroundColor Red
}