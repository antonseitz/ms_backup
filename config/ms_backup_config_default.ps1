# DEFAULT CONFIG FILE
# COPY it to /config and modify it for your purpose


# DBs to dump

$dbs=@('tableau', 'mysql', 'mssql')

# target of backupfiles

#$target="E:\folder"  # Lokal HDD
$target="\\SERVER\SHARE"   # SMB Share 

# credentials for smb share:
$targettmp="T:"  # Letter for temp smb mount
$targetsmbuser="smbuser"  
$targetsmbpass="password"

# for full/cold backups: which services should we stop before (and start after backup was completed) ?
#$services_to_stop=@("tableau","yellowfin","mysql56")
$cold_services_to_stop=@("mysql56","tableau")

# keep last x full backups
$rotationfull=2
# keep last x diff backups
$rotationdiff=7



