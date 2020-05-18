param(
[string]$full_diff ,
[switch]$debug ,
[switch]$dryrun
)

# DEBUG ?
Set-PSDebug -off

if($debug) {Set-PSDebug -Trace 1
"DEBUG: ON"}
else {Set-PSDebug -Off;
"DEBUG: OFF"}


# ARE YOU ADMIN ?

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ( -not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) ){
write "YOU HAVE NO ADMIN RIGHTS: EXITING!"
exit 1
}

# USAGE

if (! $full_diff -or (($full_diff -ne "full") -and ($full_diff -ne "diff"))){ 
write-host("Usage: "  +  $MyInvocation.MyCommand.Name + " -full_diff full|diff [-debug] [-dryrun] ")
write "-debug = a lot of output"
write "-dryrun = without producing dumps and backup on target"

exit
}



# Install Feature "Windows Server Backup" , if not installed 

if ( -not (Get-WindowsFeature | where { $_.Name -eq "Windows-Server-Backup"  -and $_.installstate -eq "installed" })){
"INSTALLING WindowsFeature Windows-Server-Backup"
Add-WindowsFeature Windows-Server-Backup

}




"MS_BACKUP CONFIG "

if( -not (test-path $PSScriptRoot\config\ms_backup_config.ps1)){
write "MS_BACKUP: Config  " +$PSScriptRoot\config\ms_backup_config.ps1  + " not here!"
exit 

}
else {

. $PSScriptRoot\config\ms_backup_config.ps1

}


# Stop Services
if ( -not ( $cold_services_to_stop -eq $null ) -and ($full_diff -eq "full")){
if($services_to_stop){
foreach ($service in $services_to_stop){
net stop $service
}}
}




" EXECUTE SUBTASKS"
# i.e. Dump DBs

if($subtasks_before_backup){

foreach ($subtask in $subtasks_before_backup){


if( -not (test-path $PSScriptRoot\$subtask\$subtask.ps1 )){
Write "SUBTASK: $PSScriptRoot$subtask\$subtask.ps1 not found ! EXITING!" 
exit 1

}
elseif( -not $dryrun ) {
"START Executing $subtask .."
. $PSScriptRoot\$subtask\$subtask.ps1
"STOP ...Executing $subtask"
}else{
"DRYRUN: $PSScriptRoot$subtask.ps1 SKIPPED"
}
}}



"TEST TARGET - PREPARE TARGET"

$targetpath="MS_BACKUP\" + $env:computername + "\" +  $full_diff.trim()
$target_full_path= $targetroot + "\" + $targetpath


$password = ConvertTo-SecureString $targetsmbpass -AsPlainText -Force
$cred = new-object System.Management.Automation.PSCredential ($targetsmbuser, $password)
$test=New-PSDrive -name "TEST" -Root $targetroot -Credential $cred -PSProvider filesystem 
if(-not $test){
write " ERROR while mounting SMB Share!"
exit}
$testpath = "TEST:\" + $targetpath
if( -not (test-path $testpath )){
write "Folder " +$targetpath  + " not here! Creating it.."
md $testpath

}
Remove-PSDrive -name TEST



if ($targetroot.startswith("\\")) {
$cred_option="-user:" + $targetsmbuser + " -password:" + $targetsmbpass
}
else { $cred_option="" }




"DO BACKUP : Call via PS"

$pol=New-WBPolicy 

$wbtarget=New-WBBackupTarget -NetworkPath $target_full_path -Credential $cred 


"Target adding:"

Add-WBBackupTarget -Policy $pol -Target $wbtarget 


"Target added"


# FULL

if($full_diff.trim() -eq "full"){

Add-WBBareMetalRecovery -Policy $pol
Add-WBSystemState -Policy $pol
Add-WBVolume -Policy $pol -Volume (Get-WBVolume -CriticalVolumes)      

"FULL: Bare and Systate added"

}


# DIFF

if($full_diff.trim() -eq "diff"){


Add-WBSystemState -Policy $pol
Add-WBFileSpec -Policy $pol $diff_files_locations 

"DIFF: Adding Folders: "
$diff_files_locations 

}


"VOLUMES"
#$vols = Get-WBVolume -AllVolumes

#Add-WBVolume -Policy $pol -Volume $vols


Set-WBPerformanceConfiguration -OverallPerformanceSetting alwaysincremental

Set-WBVssBackupOption -pol $pol -VssFullBackup

      
            
#get-wbvolume -policy $pol
"POlICY COMPLETE: "





#Add-WBVolume -Volume $vols -policy $pol
#get-wbvolume -policy $pol
if ( -not $dryrun ) {
"Start WBJOB with these options:"
$pol
Start-WBBackup -Policy $pol
}



 # https://docs.microsoft.com/en-us/powershell/module/windowsserverbackup/?view=win10-ps



# RESTART services

if ( -not( $cold_services_to_stop -eq $null ) -and ($full_diff -eq "full")){

# reverse order of services:
[array]::Reverse($cold_services_to_stop)
foreach ($service in $cold_services_to_stop){
net start $service
}
}



# PREPARE LOGS



# SEND MAIL
