function Convert-Hashtable([Parameter(Mandatory=$true)][psobject]$Object){
  [hashtable]$i=@{}
  $Object.PSObject.Properties|?{![string]::IsNullOrEmpty($_.Value)}|%{
    $i[($_.Name -replace '\s','_' -replace '\W',$null)]=$_.Value
  }
  $i
}
function Convert-Json([Parameter(Mandatory=$true)][string]$String){
  if($PSVersionTable.PSVersion.ToString() -lt 3.0){
    $Serializer.DeserializeObject($String)
  }else{
    $Object=$String|ConvertFrom-Json
    if($Object){Convert-Hashtable $Object}
  }
}

if($args[0]){$Param=Convert-Json $args[0]}
  if(!$Param.ProcID){
    $Message=(@('ProcID')|%{"Required argument not found: $_"}) -join "`n"
    throw $Message

$procId = $args[0]
# # Check if a -procId argument is provided
# param (
#     [int]$procId
# )

# if (-not $procId) {
#     # Prompt the user for a Process ID if no argument is given
#     $procId = Read-Host -Prompt "Enter the Process ID (PID) for dllhost.exe"
# }

# Function to get details of a specific dllhost.exe process
function Get-DllHostDetails {
    param (
        [int]$processId
    )
    Write-Output "Retrieving details of dllhost.exe process for Process ID $processId"

    try {
        $dllhost = Get-WmiObject -Class Win32_Process -Filter "ProcessId=$processId AND Name='dllhost.exe'" -ErrorAction Stop
    } catch {
        Write-Output "Error retrieving dllhost process with ID $processId" + $_.Exception.Message
        return
    }

    $commandLine = $dllhost.CommandLine
    if ($commandLine -match '/ProcessID:\{([0-9a-fA-F-]+)\}') {
        $guid = $Matches[1]
        Write-Output "`ndllhost.exe Process ID: $($dllhost.ProcessId)"
        Write-Output "Command Line: $commandLine"
        Write-Output "GUID: $guid"

        # Query the registry for the executable path and AppId details
        $clsidRegistryPath = "Registry::HKEY_CLASSES_ROOT\CLSID\{$guid}"
        $appidRegistryPath = "Registry::HKEY_CLASSES_ROOT\AppId\{$guid}"
        $exePath = "N/A"
        $serviceName = "N/A"
        $appidDetails = @{}

        if (Test-Path $clsidRegistryPath) {
            try {
                $localServer32Path = "$clsidRegistryPath\LocalServer32"
                $inProcServer32Path = "$clsidRegistryPath\InProcServer32"

                if (Test-Path $localServer32Path) {
                    $exePath = (Get-ItemProperty -Path $localServer32Path -ErrorAction Stop).'(default)'
                } elseif (Test-Path $inProcServer32Path) {
                    $exePath = (Get-ItemProperty -Path $inProcServer32Path -ErrorAction Stop).'(default)'
                }

                Write-Output "Executable Path: $exePath"

                # Search all services for the executable name
                $services = Get-WmiObject -Class Win32_Service -ErrorAction Stop
                foreach ($service in $services) {
                    if ($service.PathName -like "*$exePath*") {
                        $serviceName = $service.DisplayName
                        break
                    }
                }

                Write-Output "Service Display Name: $serviceName"

                # Query the AppId registry for relevant information
                if (Test-Path $appidRegistryPath) {
                    $appidDetails = Get-ItemProperty -Path $appidRegistryPath -ErrorAction Stop | Select-Object -Property *
                    Write-Output "AppId Details: $appidDetails"
                } else {
                    Write-Output "AppId registry path does not exist for GUID $guid"
                }
            } catch {
                Write-Output "Error retrieving registry details for GUID $guid" + $_.Exception.Message
            }
        } else {
            Write-Output "CLSID registry path does not exist for GUID $guid"
        }

        # Collecting output
        $output = [PSCustomObject]@{
            ProcessId       = $dllhost.ProcessId
            CommandLine     = $commandLine
            GUID            = $guid
            ExecutablePath  = $exePath
            ServiceName     = $serviceName
            AppIdDetails    = $appidDetails
        }

        # Display the output as a table
        $output | Format-Table -AutoSize

        # Save the output to a CSV file
        $csvPath = "C:\Temp\DllhostDetails.csv"
        $output | Export-Csv -Path $csvPath -NoTypeInformation
        Write-Output "Output saved to $csvPath"
    } else {
        Write-Output "No /ProcessID found in command line for Process ID $processId"
    }
}

# Execute the function with the provided or prompted Process ID
Get-DllHostDetails -processId $procId