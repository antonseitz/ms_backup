
import-module sqlserver



. $PSScriptRoot\mssql_config.ps1


if (-not $Whole_instances ){

$instances=@("localhost")

}

if ($dbs) {
$dbs.gettype()
foreach ($db in $dbs){
 $db[0] +  $db[1]
 Backup-SqlDatabase -serverinstance $db[0] -database $db[1]  -backupcontainer $backuppath -verbose
 
 
}


}
if ($whole_instances) {

write "\n Backing up whole instances \n"

foreach ($instance in $whole_instances){


$dbs=Get-ChildItem SQLSERVER:\SQL\$instance\Databases -force   | Where { $_.Name -ne 'tempdb' } 
$full_dbs=Get-ChildItem SQLSERVER:\SQL\$instance\Databases -force |  where {$_.Recoverymodel -eq "FULL"}


# Database Backup:
$dbs | Backup-SqlDatabase -backupaction database -backupcontainer $backuppath -verbose



}

# T-LOG Backup:
$full_dbs | Backup-SqlDatabase -backupaction log -backupcontainer $backuppath -verbose





}




