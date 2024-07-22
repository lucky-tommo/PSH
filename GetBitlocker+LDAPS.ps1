$Results=@()
$Results += "Hostname" + "," + "Bitlocker Password" + "," + "Local Admin Account" + "," + "Local Admin Password"
$computers = Get-ADComputer -Filter * -Property *

Foreach($machine in $computers)
{
 
    $Bitlocker_Object = Get-ADObject -Filter {objectclass -eq 'msFVE-RecoveryInformation'} -SearchBase $machine.DistinguishedName -Properties 'msFVE-RecoveryPassword'
    $laps_creds = Get-LapsADPassword $machine -AsPlainText | select-object ComputerName, Account, Password
    
    $Properties = @{'HostName'=$machine.Name;  'BitLockerInfo'=$Bitlocker_Object}
    
    
    Write-Host "Computer: "$machine.Name " -> AD Key Count:" $Bitlocker_Object.'msFVE-RecoveryPassword'.Count " -> Bitlocker Recovery Keys:" $Bitlocker_Object.'msFVE-RecoveryPassword'" -> Local Admin Account:" $laps_creds.Account" -> Local Admin Password:" $laps_creds.Password""
    $Results += $machine.Name + "," + $Bitlocker_Object.'msFVE-RecoveryPassword' + "," + $laps_creds.Account + "," + $laps_creds.Password }
    #If multiple keys are present in your environment - use the below to get Key ID
    #Write-Host "Computer: "$machine.DNSHostName " -> Bitlocker Key ID:" $Bitlocker_Object.'msFVE-RecoveryGUID'" --> Bitlocker Recovery Keys:" $Bitlocker_Object.'msFVE-RecoveryPassword'""


#Output to CSV
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$DesktopPath = $DesktopPath.toString() + "\BitlockerPasswords.csv"

write-output $Results > $DesktopPath
