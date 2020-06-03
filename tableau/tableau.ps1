##############################################################
# Backup Skript f. Mysql and Tableau #
##############################################################


"TABLEAU: read config "



if( -not (test-path $PSScriptRoot\tableau_config.ps1)){
write "TABLEAU: Config  " +$PSScriptRoot\tableau_config.ps1  + " not here!"
exit 

}
else {
"TABLEAU: read config"
. $PSScriptRoot\tableau_config.ps1
}

if( -not (test-path $tableau_dump_folder)){
write "TABLEAU: Folder " +$tableau_dump_folder  + " not here! Creating it.."
md $tableau_dump_folder

}


$datum=get-date;



# Logfile mit gleichem Namen wie Script in gleichem Ordner ablegen:
#$executingScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
#$logfile = $executingScriptDirectory + "\logs/" + $MyInvocation.MyCommand.Name + ".log.txt"
write-output "###### >  START REPORT  BACKUP DAILY " #>> $logfile 
Write-Output "$($datum.dayofweek) $($datum.hour)" #*>> $logfile 

 

 Write-Output "Tableau Backup erstellen..." #*>> $logfile 
# Tableau Backup erstellen
#$tabpath = "C:\Program Files\Tableau\Tableau Server\10.5\bin\tabadmin.exe"



$tabpath=$env:TABLEAU_SERVER_INSTALL_DIR + "\packages\bin." + $env:TABLEAU_SERVER_DATA_DIR_VERSION

$tabexe = $tabpath + "\tsm.cmd"



#& $tabexe backup c:\backup\tableau\tabbackup.$($datum.dayofweek)_$($datum.hour)  #*>> $logfile
#if ( $LASTEXITCODE -gt 0 ) {
#write $LASTEXITCODE
#exit}

Write-Output "TSM Login " #*>> $logfile 

& $tabexe login --username $tableau_user --password $tableau_pwd #*>> $logfile

Write-Output "TSM Export Settings " #*>> $logfile 
& $tabexe settings export -f $tableau_dump_folder\tabbackup.settings.$($datum.dayofweek)_$($datum.hour).json  # *>> $logfile
 
Write-Output "TSM Backup Data " #*>> $logfile 
$tsbak = "tabbackup.data." + $($datum.dayofweek) + "_" + $($datum.hour) + ".tsbak"
& $tabexe maintenance backup -f $tsbak --override-disk-space-check #*>> $logfile

# nach e: verschieben
Write-Output "...nach tableau_dump_folder verschieben... " #*>> $logfile 
$tsbackup = $env:TABLEAU_SERVER_DATA_DIR + "\data\tabsvc\files\backups\" + $tsbak
move-item $tsbackup $tableau_dump_folder\$tsbak -force
Write-Output "Nach "  + $tableau_dump_folder + "...verschoben" #*>> $logfile 

Write-Output "Tableau Backup beendet" #*>> $logfile 
 
 

& $tabexe logout