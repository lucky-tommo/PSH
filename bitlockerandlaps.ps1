# Ensure the Active Directory and BitLocker modules are loaded
Import-Module ActiveDirectory
Import-Module BitLocker
# Define an array to store results
$computers = @()
# Get all computers from Active Directory
$adComputers = Get-ADComputer -Filter * -Property *
# Loop through each computer to retrieve LAPS password and BitLocker recovery key
foreach ($computer in $adComputers) {
    $computerName = $computer.Name
    $lapsPassword = $null
    $bitlockerKey = $null
    # Check if LAPS password attribute exists
    if ($computer.Properties.Contains('ms-MCS-AdmPwd')) {
        $lapsPassword = $computer.Properties['ms-MCS-AdmPwd']
    } else {
        Write-Host "No LAPS password found for $computerName"
    }
    # Attempt to retrieve BitLocker recovery key
    try {
        $recoveryKey = Get-BitLockerRecoveryKey -MountPoint "C:" -ErrorAction Stop
        $bitlockerKey = $recoveryKey.RecoveryPassword
    } catch {
        Write-Host "BitLocker recovery key not found or error retrieving for $computerName"
    }
    # Add the result to the array
    $computers += [PSCustomObject]@{
        ComputerName = $computerName
        LapsPassword = $lapsPassword
        BitlockerRecoveryKey = $bitlockerKey
    }
}
# Output the results
$computers | Format-Table -AutoSize
