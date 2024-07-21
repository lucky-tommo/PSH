$computers = Get-ADComputer -Filter * -Property *

Foreach($machine in $computers)
{
 
    $Bitlocker_Object = Get-ADObject -Filter {objectclass -eq 'msFVE-RecoveryInformation'} -SearchBase $machine.DistinguishedName -Properties 'msFVE-RecoveryPassword'
    
    $Properties = @{'HostName'=$machine.DNSHostName;  'BitLockerInfo'=$Bitlocker_Object}
    $ADObjects += New-Object -TypeName PSObject -Property $Properties 
    
    Write-Host "Computer: "$machine.DNSHostName " -> AD Key Count:" $Bitlocker_Object.'msFVE-RecoveryPassword'.Count " -> Bitlocker Recovery Keys:" $Bitlocker_Object.'msFVE-RecoveryPassword'""
   
    #If multiple keys are present in your environment - use the below to get Key ID
    #Write-Host "Computer: "$machine.DNSHostName " -> Bitlocker Key ID:" $Bitlocker_Object.'msFVE-RecoveryGUID'" --> Bitlocker Recovery Keys:" $Bitlocker_Object.'msFVE-RecoveryPassword'""
}

