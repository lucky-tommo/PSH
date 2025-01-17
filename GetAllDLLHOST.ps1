# Function to get details of all dllhost.exe processes
function Get-AllDllHostDetails {
    Write-Output "Retrieving details of all dllhost.exe processes..."

    try {
        $dllhostProcesses = Get-WmiObject -Class Win32_Process -Filter "Name='dllhost.exe'" -ErrorAction Stop
    } catch {
        Write-Output ("Error retrieving dllhost processes: " + $_.Exception.Message)
        return
    }

    $output = @()

    foreach ($dllhost in $dllhostProcesses) {
        $details = [PSCustomObject]@{
            ProcessId       = $dllhost.ProcessId
            ProcessName     = $dllhost.Name
            CommandLine     = $dllhost.CommandLine
            MemoryUsage     = $dllhost.WorkingSetSize / 1MB -as [int]
            CreationDate    = $dllhost.CreationDate
            ExecutablePath  = $dllhost.ExecutablePath
        }

        # Collecting output
        $output += $details
    }

    # Display the output as a table
    $output | Format-Table -AutoSize

    
}

# Execute the function
Get-AllDllHostDetails
