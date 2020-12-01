<#
.SYNOPSIS
    Script to disable Email forwarding rule in a mailbox
.DESCRIPTION
    This script will disable email forwarding in a mailbox.
.NOTES
    Author: Rafael de Jesus Medeiros <rafael_medeiros94@hotmail.com.br>
    GitHub: https://github.com/RafaelM1994/Powershell-Scripts/
    Creation Date: 10/11/2020
    
#>

$user = "firstname.lastname@company.com"
$ForwardedUserEmail = "firstname.lastname@company.com"

#Exchange credentials
try {
    $IsActiveSession = (Get-Mailbox -ResultSize 1 -WarningAction silentlyContinue ).name.length -gt 0
}
catch {

}

#If the section is active, just print a message, if not, install the exo module to manage exchange as admin
if ($IsActiveSession) {

    write-host "[INFO]EXO Session OK." -foregroundcolor green
}
else {

    clear-host
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-Module -Name Microsoft.Exchange.Management.ExoPowershellModule -Confirm:$false
    Write-host "Connecting to the Exchange Service, 
    please insert your credentials in the window that can be behind the current one..." -foregroundcolor yellow
    $SesionO365 = New-EXOPSSession
    Import-PSSession $SesionO365 -AllowClobber
}


#Forward the emails from this mailbox to another
Write-Host "Configuring email forwarding from $user to $forwardedUserEmail..." -ForegroundColor Yellow
Set-Mailbox $user -ForwardingAddress $NULL -ForwardingSmtpAddress $NULL

#Checking if the rule has been applied successfully
$forwarding = (Get-Mailbox $user).forwardingSmtpAddress

if ($forwarding -eq "smtp:$forwardedUserEmail") {
    Write-Host "Forwarding rule successfully applied." -ForegroundColor Green
}
else {
    write-host "Forwarding rule not applied, please check both mailboxes addresses and try again." -ForegroundColor Red
}
