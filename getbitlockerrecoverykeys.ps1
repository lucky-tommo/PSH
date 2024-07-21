#Reference
#https://www.top-password.com/blog/tag/get-bitlocker-recovery-key-from-ad-powershell/
#https://docs.microsoft.com/en-us/powershell/module/addsadministration/get-adcomputer?view=win10-ps
#https://stackoverflow.com/questions/18877580/powershell-and-the-contains-operator

#Author: Matthew Olan aka molan
#Date: Nov 5 2019

cls
#this script will search AD for windows based machines. Lookup their Bitlocker recovery Keys and then attempt to contact all machines to verify their local bitlocker info is backed up in AD
#Results are writen out to a CSV file Bitlockerinfo.csv on the desktop
#at completion of the data lookup The user will be asked if they would like the script to attempt to backup any local keys not in AD to AD
#Results are writen out to a CSV file BitlockerBackupAttempt.csv on the desktop
#in order to successfully complete for a computer the device must be online and remotely accessable by this script 
#this script required administrative access

#Get a list of Windows based computers and servers from Active Directory
$CompList = @()
$CompList = Get-ADComputer -Filter 'operatingSystem -like "Windows" -and Enabled -eq "True"'

$ADObjects = @()

#for each AD computer and server lookup if it has Bitlocker Recovery Keys Stored and Retrive them

Write-Host "Query AD and look for Bitlocker Keys" -forgroundColor Green

Foreach($CL in $CompList)
{
    
    $Bitlocker_Object = Get-ADObject -Filter {objectclass -eq 'msFVE-RecoveryInformation'} -SearchBase $CL.DistinguishedName -Properties 'msFVE-RecoveryPassword'
    
    $Properties = @{'HostName'=$CL.DNSHostName; 'Enabled'=$CL.Enabled; 'BitLockerInfo'=$Bitlocker_Object}
    $ADObjects += New-Object -TypeName PSObject -Property $Properties 
    
    Write-Host "Computer: "$CL.DNSHostName " -> AD Key Count:" $Bitlocker_Object.'msFVE-RecoveryPassword'.Count
   
}


#Collect machine info from queried machiens
#to collect machine Name, Drive Letter, Encryption State, Key ID
$PropertiesPCDISK = @{VolumeLetter=$null;DiskSize=$null;BitLockerVersion=$null;ConverstionStatus=$null;PercentEncrypted=$null;EncryptMethod=$null;ProtectionStatus=$null;LockStatus=$null;KeyID=$null;'KeyBackedUpinAD'=$null}
$Disk = New-Object PSObject -Property  $PropertiesPCDISK
$PropertiesPC = @{'HostName'=$null; 'Online_Offline'=$null; 'Disk'=$null; 'ADKeyIDInfo'=$null}
$QueriedPCList = @()
$ListPCOffline = ""

foreach($ADO in $ADObjects)
{
        #Get Bitlocker Password ID for all computers
        write-Host $ADO.HostName  " AD Key Count: " $ADO.BitLockerInfo.Count

        #ping PC to see if it is online
        $Timeout = 100
        $Ping = New-Object System.Net.NetworkInformation.Ping
            
        $Response = ""
        $ResponseError = ""

        try
        {
            #If the ping is successfull the $Response variable becomes an object with the responce data
            #if the ping fails the $Response variable remains a string
            $Response = $Ping.Send($ADO.HostName.Trim(),$Timeout)
            Write-Host "Ping: " $Response.Status -ForegroundColor Yellow
            if($Response.Status -eq "TimedOut")
            {
                $ResponseError =  "TimedOut"
            }
        }
        Catch
        {
            $ResponseError =  "TimedOut"
        }
            
        $QueriedPCListSingle = New-Object PSObject -Property $PropertiesPC

        #Check if Host is online based on Ping Status
        #If the ping is successfull the $Response variable becomes an object with the responce data
        #if the ping fails the $Response variable remains a string
        if($Response.Status -eq "Success")
        {
                #Query the PC for its local Bitlocker Info
                $BDE_Status =  ""
                try
                {
                    Write-Host "Host Online, attempting to get local Bitlocker Info" -ForegroundColor Green
                    $BDE_Status = manage-bde -computername $ADO.HostName -Status #manage-bde returns an array of strings
                }
                catch
                {
                    Write-Host "Host Online, Error getting local Bitlocker Info" -ForgroundColor Red
                }
                
                $QueriedPCListSingle.HostName = $ADO.HostName
                $QueriedPCListSingle.Online_Offline = "Online"
                
                #combine AD INfo with Search Results
                #Loop through AD info and add it to final PSObject
                $ADKeysList = @()
                foreach($t1 in $ADO.BitLockerInfo)
                {
                    #This Value is the Bitlocker Password
                    #Write-Host "PW: " $b.'msFVE-RecoveryPassword' 
                    $Var = $t1.ToString()
                    #This Value is the Password ID
                    Write-Host "AD Key ID: " $Var.Substring($Var.IndexOf("{")+1, $Var.IndexOf("}") - $Var.IndexOf("{") - 1 ) -ForegroundColor DarkYellow
                    $ADKeysList += $Var.Substring($Var.IndexOf("{")+1, $Var.IndexOf("}") - $Var.IndexOf("{") - 1 )
                }

                $QueriedPCListSingle.ADKeyIDInfo += $ADKeysList

                $DiskResults = New-Object -TypeName PSObject -Property  $PropertiesPCDISK
                $DiskResultsArray = @()
                 
                $LoopCounter = 0
                $IsEncrypted = "False"
                #Loop through Local Machine Bitlocker info and add it to the Final PSObject
                #manage-bde returns an array of strings
                foreach($e in $bde_Status)
                {
                      $LoopCounter += 1
                     
                      #Check if Bitlocker is enabled
                      if($e.Length -gt 0)
                      {
                          if($e.ToString() -Match "Percentage Encrypted: 100.0%")
                          {
                            $IsEncrypted = "True"
                          }
                          if($e.ToString() -Match "Volume")
                          { 
                            if($e.ToString() -Match ":")
                            {
                                $DiskResults.VolumeLetter = $e.Substring(7,2).Trim()
                            }
                          }

                          if($e.ToString() -Match "Size:")
                          { 
                            $DiskResults.DiskSize = $e.ToString()
                          }

                          if($e.ToString() -Match "BitLocker Version:")
                          { 
                            $DiskResults.BitLockerVersion = $e.ToString()
                          }

                          if($e.ToString() -Match "Conversion Status:")
                          { 
                            $DiskResults.ConverstionStatus = $e.ToString()
                          }

                          if($e.ToString() -Match "Percentage Encrypted:")
                          { 
                            $DiskResults.PercentEncrypted = $e.ToString()
                          }

                          if($e.ToString() -Match "Encryption Method:")
                          { 
                            $DiskResults.EncryptMethod = $e.ToString()
                          }

                          if($e.ToString() -Match "Protection Status:")
                          {
                            $DiskResults.ProtectionStatus = $e.ToString()
                          }

                          if($e.ToString() -Match "Lock Status:")
                          { 
                            $DiskResults.LockStatus = $e.ToString()
                          }
                          
                      }
                      
                      #$LoopCounter
                      #https://www.codecademy.com/forum_questions/52dd862f9c4e9d6378000bd9
                      #Use Modulos operate to check if a number is evenly divisable by itself after subtracting 16
                      #subtract 16 becuase the first result in the array contains an extra 4 lines of info
                      #all follow up lines appear to be 12 lines each
                      #I hope MS doesn't change this or my script will break..... Badly!
                      #This is the most dodgy and difficult part of this script!!
                      $V1 = $LoopCounter - 16
                      $V2 = $V1 % 12
                      if($V2 -eq 0 -and $V1 -ge 0)
                      {
                        #Query for ID
                        if($IsEncrypted -eq "True")
                        {
                            Write-Host "Query for Protectors on :" $ADO.HostName ": '" $DiskResults.VolumeLetter.Trim() "'" -ForegroundColor Green
                            $BLProtectors = manage-bde -computername $ADO.HostName -protectors -get $DiskResults.VolumeLetter.Trim()

                            Write-Host "Protector Data Lines Found: " $BLProtectors.count -ForegroundColor Red 

                            $IDCount = 0
                            foreach($BLP in $BlProtectors)
                            {
                                if($BLP -match "ID: {")
                                {
                                    $IDCount += 1
                                    If($IDCount -eq 2) #take the 2nd ID for the password. not the first ID for the TPM
                                    {
                                        $DiskResults.KeyID =  $BLP.Substring($BLP.IndexOf("{")+1, $BLP.IndexOf("}") - $BLP.IndexOf("{") - 1 )
                                        Write-Host "Found The Key!: " $DiskResults.KeyID -ForegroundColor Yellow
                                        
                                        #Check if any Keys Found backed up In AD 
                                        foreach($Q1 in $ADO.BitLockerInfo)
                                        {
                                            $Var = $Q1.ToString()
                                            #This Value is the Password ID
                                            $ADOKey = $Var.Substring($Var.IndexOf("{")+1, $Var.IndexOf("}") - $Var.IndexOf("{") - 1 )

                                            Write-Host "Check Key Backed up"
                                            Write-Host "PC Key ID: " $DiskResults.KeyID 
                                            Write-Host "AD Key ID: " $ADOKey

                                            if($DiskResults.KeyID -eq $ADOKey)
                                            {
                                                Write-Host $DiskResults.KeyID " Key is backed Up Correctly" -ForegroundColor Green
                                                $DiskResults.KeyBackedUpinAD = "Yes"
                                                
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        
                        Write-host "Save Results" -ForegroundColor Yellow
                        $DiskResults

                        #Save Successfull Results to the final PSObject 
                        $DiskResultsArray += $DiskResults
                        $DiskResults = New-Object -TypeName PSObject -Property  $PropertiesPCDISK
                        $IsEncrypted = "False"
                      }
                }
               
                $QueriedPCListSingle.Disk = $DiskResultsArray
                $QueriedPCList += $QueriedPCListSingle
                
            }
        elseif($ResponseError -eq "TimedOut")
        {
            Write-Host "Host Offline: Skipped" -ForegroundColor Red
            #Save Error Results to the final PSObject     
            $QueriedPCListSingle = New-Object PSObject -Property $PropertiesPC
            $QueriedPCListSingle.HostName = $ADO.HostName
            $QueriedPCListSingle.Online_Offline = "Offline"

            $QueriedPCList += $QueriedPCListSingle
        }
        write-host "`r`n"
}

#Searching Complete
#Begin Outputs
Write-host "Number of Computers Queried: " $QueriedPCList.Count

#Final Output
write-host "---------------------------------------------------------------"
Write-host "Total Host Objects Found in Active Directory: "$ADObjects.Count -ForegroundColor Green 
write-host "---------------------------------------------------------------"

#Format data for nice output to CSV
$FinalResult =@()
$FinalResult += "HostName," + "Online?," + "Drive Letter," + "Disk Size," + "Bit Locker Version," + "Conversion Status," + "% Encrypted," + "Encryption Method," + "Protection Status," + "Lock Status," + "KeyID," + "Key Backed Up in AD," + "AD Key Info -->"
foreach($q1 in $QueriedPCList)
{
    #Add hosts with discovered disks to the output
    foreach($q2 in $q1.Disk)
    {
        $KeyInfo = ""
        foreach($q3 in $q1.ADKeyIDInfo)
        {
            $KeyInfo += $q3 + ", "
        }
        $FinalResult += $q1.HostName + "," + $q1.Online_Offline + "," + $q2.VolumeLetter + "," + $q2.DiskSize + "," + $q2.BitLockerVersion + "," + $q2.ConverstionStatus + "," + $q2.PercentEncrypted + "," + $q2.EncryptMethod + "," + $q2.ProtectionStatus + "," + $q2.LockStatus + "," + $q2.KeyID + "," + $q2.KeyBackedUpinAD + "," + $KeyInfo
    }
    #Add hosts that failed to pass the ping test or that returned no disk results
    if($q1.Disk.Count -lt 1)
    {
        $KeyInfo = ""
        foreach($q3 in $q1.ADKeyIDInfo)
        {
            $KeyInfo += $q3 + ", "
        }
        $FinalResult += $q1.HostName + "," + $q1.Online_Offline + ","  + ","  + ","  + "," +  "," + ","  + "," +  "," + "," + ","  + ","  + $KeyInfo
    }
}


$DesktopPath = [Environment]::GetFolderPath("Desktop")
$DesktopPath = $DesktopPath.toString() + "\BitlockerInfo.csv"

#Check if the Path Exists
if(Test-Path $DesktopPath)
{
    #If it exists Randomize the name by appending date time to the end
    $DesktopPath = [Environment]::GetFolderPath("Desktop")  + "\BitlockerInfo_" + (Get-Date -Format "yyyyMMddHHmmssff") + ".csv"
}

$FinalResult | Out-File -FilePath $DesktopPath

Write-host "Final results written to: " $DesktopPath  -ForegroundColor Green

###
### Prompt User to attempt to backup the BitLocker Keys to AD?
###

$Prompt = Read-Host "Would you like to backup the discovered Bitlocker Keys to AD? (y\n)"
$Output = @()
$Output +="HostName, Disk, KeyID, Message"

if($Prompt.ToLower().Trim() -eq 'y')
{
    #Read each stored Host
    foreach($q1 in $QueriedPCList)
    {
        #check each discovered disk for each stored host
        foreach($d in $q1.Disk)
        {
            #Check if the host has a Key to backup. Only backup if it isn't already backed up
            if($d.KeyID.Length -gt 1 -and $d.KeyBackedUpinAD -ne 'yes')
            {
                #Backup Bitlock Key
                Write-Host "Attempting to backup Key for: " $q1.HostName -ForegroundColor Green

                $KI = "{" + $d.KeyID + "}"
                Write-Host "manage-bde -computername" $q1.HostName "-protectors -adbackup" $d.VolumeLetter "-id" $KI
                
                $BackupAttempt = ""
                $BackupAttempt = manage-bde -computername $q1.HostName -protectors -adbackup $d.VolumeLetter -id $KI
                
                foreach($ba in $BackupAttempt)
                {
                    write-host $ba

                    if($ba -match 'successfully')
                    {
                        $Output +=  $q1.HostName + ", " + $d.VolumeLetter + "," +  $d.KeyId + ", " + $ba
                    }
                    
                    if($ba -match 'ERROR')
                    {
                        $Output +=  $q1.HostName + ", " + $d.VolumeLetter + "," +  $d.KeyId + ", " + $ba
                    }
                }
            }
        }
    }
   
    $DesktopPath = [Environment]::GetFolderPath("Desktop")
    $DesktopPath = $DesktopPath.toString() + "\BitlockerBackupAttempt.csv"

    #Check if the Path Exists
    if(Test-Path $DesktopPath)
    {
        #If it exists Randomize the name by appending date time to the end
        $DesktopPath = [Environment]::GetFolderPath("Desktop")  + "\BitlockerBackupAttempt_" + (Get-Date -Format "yyyyMMddHHmmssff") + ".csv"
    }

    $Output | Out-File -FilePath $DesktopPath

    Write-host "Backup Attempt results written to: " $DesktopPath  -ForegroundColor Green
}

Write-Host "Script Compelete - Review output before hitting any key to close" -ForegroundColor Green
Pause
