

# per DB or per INSTANCE ?
# if not defined, from all DBs will be made backups

#$dbs=@( , @("LINEAR\LINEAR2017EXP", "ICOM"))
$dbs=$null

# if not defined, intance "localhost" will be used
$whole_instances=@("LINEAR\LINEAR2017EXP")

#Dump folder
$mssql_dump_folder="E:\MSSQL_BAK\"

# Location for WBackup
$diff_files_locations+=$mssql_dump_folder


#include this directory to rotation
$rotate_dirs+=$mssql_dump_folder