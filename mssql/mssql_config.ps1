
# per DB or per INSTANCE ?
# if not defined, from all DBs will be made backups


#$dbs=@( , @("LINEAR\LINEAR2017EXP", "ICOM"))
$dbs=$null

# if not defined, intance "localhost" will be used
$whole_instances=@("LINEAR\LINEAR2017EXP")


$backuppath="E:\MSSQL_BAK"