#

# SUBTASKS
# i.e. Skripts to dump DBs 
$subtasks_before_backup=@( 'tableau')

# $subtasks_before_backup=@('subtask', )
# Scripts must be placed in path "subtask\subtask.ps1"


# COLD BACKUP
# for full/cold backups: which services should we stop before (and start after backup was completed) ?
#$services_to_stop=@("tableau","yellowfin","mysql56")
#$full_services_to_stop=@("mysql56","2")


# INCLUDE
# Welche Laufwerke noch ?
$local:include=""
#$include=" -include:e: "


# ROTATION

# keep last x full backups
$rotationfull=2
# keep last x diff backups
$rotationdiff=7


# TARGET 
# target of backupfiles

#$target="E:\folder"  # Lokal HDD
$local:targetroot="\\10.10.10.10\backup"   # SMB Share 

# credentials for smb share:
$targettmp="T:"  # Letter for temp smb mount
$targetsmbuser="admin"  
$targetsmbpass="admin"



