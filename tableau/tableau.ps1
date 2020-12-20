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

if( -not (test-path ( $tableau_dump_folder_last ))){
write "TABLEAU: Folder " +$tableau_dump_folder  + " not here! Creating it.."
md $tableau_dump_folder
md $tableau_dump_folder\last

}






# Logfile mit gleichem Namen wie Script in gleichem Ordner ablegen:
#$executingScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
#$logfile = $executingScriptDirectory + "\logs/" + $MyInvocation.MyCommand.Name + ".log.txt"
write-output "###### >  START TABLEAU  BACKUP  " #>> $logfile 
Write-Output "$Wochentag $Uhrzeit" #*>> $logfile 

 

 Write-Output "Tableau Backup erstellen..." #*>> $logfile 
# Tableau Backup erstellen
#$tabpath = "C:\Program Files\Tableau\Tableau Server\10.5\bin\tabadmin.exe"



$tabpath=$env:TABLEAU_SERVER_INSTALL_DIR + "\packages\bin." + $env:TABLEAU_SERVER_DATA_DIR_VERSION

$tabexe = $tabpath + "\tsm.cmd"



#if ( $LASTEXITCODE -gt 0 ) {
#write $LASTEXITCODE
#exit}

Write-Output "TSM Login " #*>> $logfile 
if ( -not $dryrun ) {

& $tabexe login --username $tableau_user --password $tableau_pwd #*>> $logfile

}else {
"DRYRUN: skipped"
}

Write-Output "TSM Export Settings " #*>> $logfile 

$tssettings = "tabbackup.settings." + $datumuhrzeit + ".json" 
$tspath = $tableau_dump_folder_last + "\" + $tssettings
if ( -not $dryrun ) {
& $tabexe settings export -f $tspath # *>> $logfile
 }
 else{ "DRYRUN: skipped"}



Write-Output "TSM Backup Data " #*>> $logfile 
$tsbak = "tabbackup.data." + $datumuhrzeit + ".tsbak"
if ( -not $dryrun ) {

& $tabexe maintenance backup -f $tsbak --override-disk-space-check #*>> $logfile

}
 else{ "DRYRUN: skipped"}

# nach e: verschieben
Write-Output "...nach tableau_dump_folder verschieben... " #*>> $logfile 
$tsbackup = $env:TABLEAU_SERVER_DATA_DIR + "\data\tabsvc\files\backups\" + $tsbak
move-item $tsbackup $tableau_dump_folder_last\$tsbak -force
Write-Output "Nach "  + $tableau_dump_folder_last + "...verschoben" #*>> $logfile 

Write-Output "Tableau Backup beendet" #*>> $logfile 
 
 if ( -not $dryrun ) {

& $tabexe logout
}
 else{ "DRYRUN: skipped"}

