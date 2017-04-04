#Written by Brendan Evans

#This script is still a work in progress, at this stage it's a proof of concept.
#Plans are to turn it into a functional module.


#Required on Tech PC - Restart not required
#Add-WindowsFeature RSAT-AD-PowerShell
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Import-Module ActiveDirectory
} else {
    Write-Host "Active Directory Module not found.  Script cannot be run without it."
    break
}

#Variables required
$PCName = RemotePC #Destination for the Printer
$DriverLocation = "\\Fileserver\Full\Path\To\Drivers"
$Server = Fileserver #Server if the Drivers are on a shared network drive
$PrinterDriver = "Toshiba Universal PS3" #Driver Name
$PrinterIP = "192.168.1.1" #IP Address of the printer
$PrinterPort = $PrinterIP + "_1"
$PrinterName = "Toshiba Printer"



$ComputerName = Get-ADComputer -Identity $PCName
$Server = Get-ADComputer -Identity $Server

Set-ADComputer -Identity $Server -PrincipalsAllowedToDelegateToAccount $ComputerName

$Credentials = Get-Credential

Invoke-Command -ComputerName $ComputerName.Name -Credential $Credentials -ScriptBlock {
    Copy-Item -Recurse $Using:DriverLocation -Destination "$env:TEMP\drivers"
}
Invoke-Command -ComputerName $ComputerName.Name -ScriptBlock {pnputil.exe -i -a "$env:TEMP\drivers\*.inf"}

Add-PrinterDriver -ComputerName $ComputerName.Name -Name $PrinterDriver
Add-PrinterPort -ComputerName $ComputerName.Name -Name $PrinterPort -PrinterHostAddress $PrinterIP
Add-Printer -ComputerName $ComputerName.Name -Name $PrinterName -DriverName $PrinterDriver -PortName $PrinterPort

Set-ADComputer -Identity $Server -PrincipalsAllowedToDelegateToAccount $null