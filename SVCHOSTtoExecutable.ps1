# Prompt the user for a Process ID
$processId = Read-Host -Prompt "Enter the Process ID (PID) for svchost.exe"

# Function to get details of svchost -k command
function Get-SvcHostDetails {
    param (
        [int]$procId
    )
    Write-Output "Retrieving details of svchost -k command for Process ID: $procId..."

    try {
        $svchost = Get-WmiObject -Class Win32_Process -Filter "ProcessId=$procId AND Name='svchost.exe'" -ErrorAction Stop
    } catch {
        Write-Output ("Error retrieving svchost process with ID $procId " + $_.Exception.Message)
        return
    }

    $commandLine = $svchost.CommandLine
    if ($commandLine -match '-k (\w+)') {
        $kValue = $Matches[1]
        Write-Output "`nsvchost -k value: $kValue"
        
        $output = @()

        # Get the list of services running under this svchost instance
        $services = Get-WmiObject -Class Win32_Service | Where-Object { $_.PathName -like "*svchost.exe* -k $kValue*" }

        foreach ($service in $services) {
            Write-Output "Service Display Name: $($service.DisplayName)"

            # Get the list of DLLs/components and executables this service loads
            $registryPath = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$($service.Name)\Parameters"
            $serviceDlls = "N/A"
            $serviceExes = "N/A"
            if (Test-Path $registryPath) {
                try {
                    $serviceDlls = (Get-ItemProperty -Path $registryPath -ErrorAction Stop).ServiceDll
                    $serviceExes = (Get-ItemProperty -Path $registryPath -ErrorAction Stop).ServiceExecutable
                    if ($serviceDlls) {
                        Write-Output "Service DLL(s): $serviceDlls"
                    } else {
                        Write-Output "No Service DLL(s) found"
                    }
                    if ($serviceExes) {
                        Write-Output "Service Executable(s): $serviceExes"
                    } else {
                        Write-Output "No Service Executable(s) found"
                    }
                } catch {
                    Write-Output ("Error retrieving registry details for $($service.Name): " + $_.Exception.Message)
                }
            } else {
                Write-Output "Registry path does not exist for $($service.Name)"
            }

            # Collecting output
            $output += [PSCustomObject]@{
                ProcessId       = $procId
                Svchost_K_Value = $kValue
                DisplayName     = $service.DisplayName
                ServiceDll      = if ($serviceDlls) { $serviceDlls } else { "N/A" }
                ServiceExe      = if ($serviceExes) { $serviceExes } else { "N/A" }
            }
        }

        # Display the output as a table
        $output | Format-Table -AutoSize

        # Save the output to a CSV file
        $csvPath = "C:\Users\Public\SvchostDetails.csv"
        $output | Export-Csv -Path $csvPath -NoTypeInformation
        Write-Output "Output saved to: $csvPath"
    } else {
        Write-Output "No '-k' parameter found in command line for Process ID: $procId"
    }
}

# Execute the function with user input
Get-SvcHostDetails -procId $processId
