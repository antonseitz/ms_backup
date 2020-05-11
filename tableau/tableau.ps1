##############################################################
# Backup Skript f. Mysql and Tableau #
##############################################################


$datum=get-date;



# Logfile mit gleichem Namen wie Script in gleichem Ordner ablegen:
$executingScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$logfile = $executingScriptDirectory + $MyInvocation.MyCommand.Name + ".log.txt"
write-output "###### >  START REPORT  BACKUP DAILY " >> $logfile 
Write-Output "$($datum.dayofweek) $($datum.hour)" *>> $logfile 

 

 Write-Output "Tableau Backup erstellen..." *>> $logfile 
# Tableau Backup erstellen
#$tabpath = "C:\Program Files\Tableau\Tableau Server\10.5\bin\tabadmin.exe"



$tabpath=$env:TABLEAU_SERVER_INSTALL_DIR + "\packages\bin." + $env:TABLEAU_SERVER_DATA_DIR_VERSION

$tabexe = $tabpath + "\tsm.cmd"



& $tabpath backup c:\backup\tableau\tabbackup.$($datum.dayofweek)_$($datum.hour)  *>> $logfile
if ( $LASTEXITCODE -gt 0 ) {
write $LASTEXITCODE
exit}
Write-Output "TSM Login " *>> $logfile 

& $tabexe login --username administrator --password "passwd," *>> $logfile

Write-Output "TSM Export Settings " *>> $logfile 
& $tabexe settings export -f c:\backup\tableau\tabbackup.settings.$($datum.dayofweek)_$($datum.hour).json   *>> $logfile
 
Write-Output "TSM Backup Data " *>> $logfile 
& $tabexe maintenance backup -f tabbackup.data.tsbak --override-disk-space-check *>> $logfile

# nach e: verschieben
Write-Output "...nach E: verschieben... " *>> $logfile 
$tsbackup = $env:TABLEAU_SERVER_DATA_DIR + "\data\tabsvc\files\backups\tabbackup.data.tsbak"
move-item $tsbackup c:\backup\tableau\tabbackup.data.$($datum.dayofweek)_$($datum.hour).tsbak -force
Write-Output "...verschoben" *>> $logfile 

Write-Output "Tableau Backup beendet" *>> $logfile 
 
 

& $tabexe logout