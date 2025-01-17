# Function to get details of all svchost.exe processes
function Get-AllSvcHostDetails {
    Write-Output "Retrieving details of all svchost.exe processes..."

    try {
        $svchostProcesses = Get-WmiObject -Class Win32_Process -Filter "Name='svchost.exe'" -ErrorAction Stop
    } catch {
        Write-Output ("Error retrieving svchost processes: " + $_.Exception.Message)
        return
    }

    $output = @()

    foreach ($svchost in $svchostProcesses) {
        $details = [PSCustomObject]@{
            ProcessId       = $svchost.ProcessId
            ProcessName     = $svchost.Name
            CommandLine     = $svchost.CommandLine
            MemoryUsage     = $svchost.WorkingSetSize / 1MB -as [int]
            CreationDate    = $svchost.CreationDate
            ExecutablePath  = $svchost.ExecutablePath
            ParentProcessID = $svchost.ParentProcessId
        }

        # Collecting output
        $output += $details
    }

    # Display the output as a table
    $output | Format-Table -AutoSize

    
}

# Execute the function
Get-AllSvcHostDetails
