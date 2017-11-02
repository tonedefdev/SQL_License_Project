function Get-SQLVersion {
[CmdletBinding()]
param(
    [string[]]$Computer
)
$ComputerManagementNamespace = 
    (Get-WmiObject -ComputerName $Computer -Namespace "root\microsoft\sqlserver" -Class "__NAMESPACE" |
        Where-Object {$_.Name -like "ComputerManagement*"} |
        Select-Object Name |
        Sort-Object Name -Descending |
        Select-Object -First 1).Name

if ($ComputerManagementNamespace -eq $null) {
    Write-Error "ComputerManagement namespace not found"
}
else {
    $ComputerManagementNamespace = "root\microsoft\sqlserver\" + $ComputerManagementNamespace
} 
$SQLGrab = Get-WmiObject -ComputerName $Computer -Namespace $ComputerManagementNamespace -Class "SqlServiceAdvancedProperty" | where {$_.PropertyName -eq "VERSION"}
$SQLVersion = $SQLGrab.PropertyStrValue -replace "[^0-9]\d{1,5}"
    Switch ($SQLVersion) {
        9 {$SQLVersion = "SQL Server 2005"}
        10 {$SQLVersion = "SQL Server 2008"}
        11 {$SQLVersion = "SQL Server 2012"}
        12 {$SQLVersion = "SQL Server 2014"}
        13 {$SQLVersion = "SQL Server 2016"}
        Default {$SQLVersion = "No instance of SQL installed on this server."}
    }

$SKU = Get-WmiObject -ComputerName $Computer -Namespace $ComputerManagementNamespace -Class "SqlServiceAdvancedProperty" | where {$_.PropertyName -eq "SKUNAME"}

    $ObjectHT = @{
        SQLVersion = ($SQLVersion + " " + ($SKU.PropertyStrValue | Get-Unique))
    }
    $Object = New-Object PSObject -Property $ObjectHT 
    $Object | Select-Object -ExpandProperty SQLVersion

}