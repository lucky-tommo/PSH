#----PSH Script to grab all Plain text LAPS managed Local Admin Acocunts----
#---Outputs to Console
#---Outputs CSV and TXT to Desktop
#---Run As Domain Admin (needs to be able to decrypt LAPS passwords)
#---Run on Domain Controller
#---Script will omit machines with no stored LAPS password. 

#---This script has been tested on: DC - Windows Server 2019, Workstations: 2x Windows 10 only. YMMV.
#---Has not been tested against Entra ID or Hybrid Environments. 




$Results=@()
$Results += "Hostname" + "," + "Local Admin Account" + "," + "Local Admin Password"
$output=@()
$computers = Get-ADComputer -Filter {msLAPS-EncryptedPassword -notlike '<not set>'} -Property *

Foreach($machine in $computers){
    
    $hostname=$machine.DNShostname
    $laps=Get-LapsADPassword -Identity $hostname -AsPlainText | select-object ComputerName, Account, Password
    $Results +=$laps.ComputerName +","+ $laps.Account +","+ $laps.Password
    $output += $laps

  }
  
write-output $output
$DesktopPathRaw = [Environment]::GetFolderPath("Desktop")
$DesktopPathCSV = $DesktopPathRaw.toString() + "\LocalAdminCreds.csv"
$DesktopPathTXT= $DesktopPathRaw.toString() + "\LocalAdminCreds.txt"
write-output $Results > $DesktopPathCSV
write-output $output > $DesktopPathTXT
