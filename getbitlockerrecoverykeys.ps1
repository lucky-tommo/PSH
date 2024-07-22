#Powershell Script to query all machine objects in Active Directory
#Check for presence of Bitlocker Recovery information
#and Grab the plain text Bitlocker Recovery password. 
#Outputs to CSV on Desktop. 

#This script has been lab tested on DC - Windows server 2019, and Windows 10 Workstations only. YMMV. 
#Has not been tested against Entra ID or Hybrid Environments
 

$Results=@()
$Results += "Hostname" + "," + "Bitlocker Password"
$computers = Get-ADComputer -Filter * -Property *

Foreach($machine in $computers)
{
 
    $Bitlocker_Object = Get-ADObject -Filter {objectclass -eq 'msFVE-RecoveryInformation'} -SearchBase $machine.DistinguishedName -Properties 'msFVE-RecoveryPassword'
    
    $Properties = @{'HostName'=$machine.Name;  'BitLockerInfo'=$Bitlocker_Object}
    $ADObjects += New-Object -TypeName PSObject -Property $Properties 
    
    Write-Host "Computer: "$machine.Name " -> AD Key Count:" $Bitlocker_Object.'msFVE-RecoveryPassword'.Count " -> Bitlocker Recovery Keys:" $Bitlocker_Object.'msFVE-RecoveryPassword'""
    $Results += $machine.Name + "," + $Bitlocker_Object.'msFVE-RecoveryPassword'}
    
    
    #If multiple keys are present in your environment - use the below to get Key ID
    #Write-Host "Computer: "$machine.Name " -> Bitlocker Key ID:" $Bitlocker_Object.'msFVE-RecoveryGUID'" --> Bitlocker Recovery Keys:" $Bitlocker_Object.'msFVE-RecoveryPassword'""
    #$Results += $machine.Name + "," + $Bitlocker_Object.'msFVE-RecoveryPassword' + "," + $bitlocker_Object.'msFVE-RecoveryGUID'

#Output to CSV
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$DesktopPath = $DesktopPath.toString() + "\BitlockerPasswords.csv"

write-output $Results > $DesktopPath
