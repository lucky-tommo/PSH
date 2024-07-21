Get-ADComputer -Identity <ComputerName> -Properties ms-Mcs-AdmPwd | Select-Object Name, @{Name="LAPS_Password"; Expression={[System.Text.Encoding]::UTF8.GetString($_.'ms-Mcs-AdmPwd')}}
