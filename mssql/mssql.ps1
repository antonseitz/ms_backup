"MSSQL: START"
import-module sqlserver

 if($script:debug) {$verbose = " -verbose "}
 else {$verbose = $null}

if( -not (test-path $PSScriptRoot\mssql_config.ps1)){
write "MSSQL: Config  " +$PSScriptRoot\mssql_config.ps1  + " not here!"
exit 

}
else {
. $PSScriptRoot\mssql_config.ps1
}
if( -not (test-path $mssql_dump_folder\last)){
write "Folder " +$mssql_dump_folder\last  + " not here! Creating it.."
md $mssql_dump_folder\last

}



if (-not $Whole_instances ){

$instances=@("localhost")

}

if ($dbs) {
$dbs.gettype()
foreach ($db in $dbs){
 $db[0] +  $db[1]
 Backup-SqlDatabase -serverinstance $db[0] -database $db[1]  -backupcontainer $mssql_dump_folder -verbose
 
 
}


}
if ($whole_instances) {

write " Backing up whole instances "

foreach ($instance in $whole_instances){

"MSSQL DO Backup of " + $instance
$dbs=Get-ChildItem SQLSERVER:\SQL\$instance\Databases -force   | Where { $_.Name -ne 'tempdb' } 
$full_dbs=Get-ChildItem SQLSERVER:\SQL\$instance\Databases -force |  where {$_.Recoverymodel -eq "FULL"}


"MSSQL:  Database Backup:"
if( -not $script:dryrun){
$dbs | Backup-SqlDatabase -backupaction database -backupcontainer $mssql_dump_folder\last $verbose
} else { "DRYRUN: skipped!"}

"MSSQL: Make T-LOG Backup"
if( -not $script:dryrun){
$full_dbs | Backup-SqlDatabase -backupaction log -backupcontainer $mssql_dump_folder\last $verbose
} else { "DRYRUN: skipped!"}

}
"MSSQL Backup of " +  $instance + "  done"



}

"MSSQL: DONE!"




