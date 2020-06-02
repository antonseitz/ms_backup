# MS Backup for MS Servers


## TODO:
setup:
Run without User logged in




Requires:

Backup User must be in local Admin-Group









wbadmin mit PS Starten/Configurireren ?
https://docs.microsoft.com/en-us/powershell/module/windowsserverbackup/?view=win10-ps


fullexclude


rotationfull=n
rotationdiff=n





* ms_backup full=bmr|diff
* full/diff => different targets on share/disk
* make schedule


* ms_backup.py >> logfile 
* rotating dumps
* rotating backups
* rotating logs
* email notification ?
https://vladtalkstech.com/2016/03/send-email-from-powershell-in-office-365.html

* Failure - notice check_mk
* Failure - write in event log
