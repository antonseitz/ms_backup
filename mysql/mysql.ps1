##############################################################
# Backup Skript f. Mysql and Tableau #
##############################################################


$datum=get-date;



# Logfile mit gleichem Namen wie Script in gleichem Ordner ablegen:
$executingScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$logfile = $executingScriptDirectory + $MyInvocation.MyCommand.Name + ".log.txt"
write-output "###### >  START REPORT  BACKUP DAILY " >> $logfile 
Write-Output "$($datum.dayofweek) $($datum.hour)" *>> $logfile 

# Mysql DB Dump  erstellen
Write-Output "Mysql DB Dump erstellen..." *>> $logfile 
pushd "e:\Program Files\MySQL\MySQL Server 5.6\bin"

#./mysqldump -uroot -ppasswd --all-databases --skip-lock-tables > e:\backup\mysql\mysqldumps\$($datum.dayofweek).sql

Write-Output "Mysql DB Dump beendet" *>> $logfile 
 
popd
 

 
  
  
