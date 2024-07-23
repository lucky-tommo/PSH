#----PSH Script to grab all Plain text LAPS managed Local Admin Acocunts and Bitlocker recover keys----
#---Outputs to Console
#---Outputs CSV to Desktop
#---Run As Domain Admin (needs to be able to decrypt LAPS passwords)
#---Run on Domain Controller


#---This script has been tested on: DC - Windows Server 2019, Workstations: 2x Windows 10 only. YMMV.
#---Has not been tested against Entra ID or Hybrid Environments. 

$Results=@()
$Results += "Hostname" + "," + "Bitlocker Password" + "," + "Local Admin Account" + "," + "Local Admin Password"
$computers = Get-ADComputer -Filter * -Property *

Foreach($machine in $computers)
{
 
    $Bitlocker_Object = Get-ADObject -Filter {objectclass -eq 'msFVE-RecoveryInformation'} -SearchBase $machine.DistinguishedName -Properties 'msFVE-RecoveryPassword'
    $laps_creds = Get-LapsADPassword $machine -AsPlainText | select-object ComputerName, Account, Password
    
    $Properties = @{'HostName'=$machine.Name;  'BitLockerInfo'=$Bitlocker_Object}
    
    #Moved to $machine.Name to get just hostname for easier queries in NGSIEM lookup file - if you need FQDN - use $machine.DnsHostName
    Write-Host "Computer: "$machine.Name " -> AD Key Count:" $Bitlocker_Object.'msFVE-RecoveryPassword'.Count " -> Bitlocker Recovery Keys:" $Bitlocker_Object.'msFVE-RecoveryPassword'" -> Local Admin Account:" $laps_creds.Account" -> Local Admin Password:" $laps_creds.Password""
    $Results += $machine.Name + "," + $Bitlocker_Object.'msFVE-RecoveryPassword' + "," + $laps_creds.Account + "," + $laps_creds.Password }
    #If multiple keys are present in your environment - use the below to get Key ID
    #Write-Host "Computer: "$machine.DNSHostName " -> Bitlocker Key ID:" $Bitlocker_Object.'msFVE-RecoveryGUID'" --> Bitlocker Recovery Keys:" $Bitlocker_Object.'msFVE-RecoveryPassword'""


#Output to CSV
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$DesktopPath = $DesktopPath.toString() + "\BitlockerLAPSPasswords.csv"

write-output $Results > $DesktopPath
