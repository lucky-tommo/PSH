Get-Process -Name svchost | Select-Object Id, ProcessName, Path | ForEach-Object {
    $services = Get-WmiObject Win32_Service -Filter "ProcessId=$($_.Id)"
    $services | Select-Object @{Name="ProcessId";Expression={$_.ProcessId}}, DisplayName, Name
}
