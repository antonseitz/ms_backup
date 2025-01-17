param(
[string]$full_diff ,
[switch]$debug ,
[switch]$skip_subtasks,
[switch]$skip_backup,
[switch]$dryrun
)


$starttime=get-date;
get-date -Format "yyyy-MM-dd__HH:mm:ss"
$Wochentag=$starttime.DayOfWeek
#$DatumTag=$starttime.tostring("hhmm")
$datumuhrzeit=$starttime.tostring("yyyyMMdd_HHmm")

if($skip_dumps){
	$script:skip_dumps = $true
}


if($skip_backup){
	$script:skip_backup = $true
}
Set-PSDebug -Off
if( $debug ) {
	$script:debug=$true
}


# ARE YOU ADMIN ?

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ( -not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) ){
	write "YOU HAVE NO ADMIN RIGHTS: EXITING!"
exit 1
}

# USAGE

if (! $full_diff -or (($full_diff -ne "full") -and ($full_diff -ne "diff"))){ 
	write-host("Usage: "  +  $MyInvocation.MyCommand.Name + " -full_diff full|diff [-debug] [-skip_dump | -skip_backup] ")
	write "-debug = a lot of output"
	write "-skip_dumps = without producing dumps "
	write "-skip_backup= without producing backup on target"

	exit
}



# Install Feature "Windows Server Backup" , if not installed 

if ( -not (Get-WindowsFeature | where { $_.Name -eq "Windows-Server-Backup"  -and $_.installstate -eq "installed" })){
	"INSTALLING WindowsFeature Windows-Server-Backup"
	Add-WindowsFeature Windows-Server-Backup

}

"---------- STEP 1 from 8 ------"
"CONFIG: `n"


# DEBUG ?


if($debug) {Set-PSDebug -Trace 1
	"DEBUG: ON"
}
else {Set-PSDebug -Off
	"DEBUG: OFF"
}


	
"---------- STEP 2 from 8 ------"
"MS_BACKUP CONFIG "

if( -not (test-path $PSScriptRoot\config\ms_backup_config.ps1)){
	write "MS_BACKUP: Config  " +$PSScriptRoot\config\ms_backup_config.ps1  + " not here!"
	exit 

}
else {

	. $PSScriptRoot\config\ms_backup_config.ps1
	"`nSUBTASKS: "
	$subtasks_before_backup
	
}

"----------"


# Stop Services
if ( -not ( $cold_services_to_stop -eq $null ) -and ($full_diff -eq "full")){
	if($services_to_stop){
		foreach ($service in $services_to_stop){
			net stop $service
		}
	}
}



"---------- STEP 3 from 8 ------"
" EXECUTE SUBTASKS"
# i.e. Dump DBs

if($subtasks_before_backup -and ($skip_subtasks -ne $true)){

	foreach ($subtask in $subtasks_before_backup){


		if( -not (test-path $PSScriptRoot\$subtask\$subtask.ps1 )){
		Write "SUBTASK: $PSScriptRoot$subtask\$subtask.ps1 not found ! EXITING!" 
		exit 1

		}

	"START Executing $subtask .."
	. $PSScriptRoot\$subtask\$subtask.ps1
	"STOP ...Executing $subtask"
	}
}



"---------- STEP 4 from 8 ------"
"TEST AND PREPARE TARGET"
get-date -Format "yyyy-MM-dd__HH:mm:ss"


$targetpath="MS_BACKUP\" + $env:computername + "\" +  $full_diff.trim()

if( $full_diff.trim() -eq "diff" ) {

$targetpath= $targetpath + "\" + $Wochentag

}

$target_full_path= $targetroot + "\" + $targetpath








$password = ConvertTo-SecureString $targetsmbpass -AsPlainText -Force
$cred = new-object System.Management.Automation.PSCredential ($targetsmbuser, $password)
#$test=New-PSDrive -name "TEST" -Root $targetroot  -PSProvider filesystem -Credential $cred



#if(-not $test){
	#write " ERROR while mounting SMB Share!"
	#exit
#}
#$testpath = "TEST:\" + $targetpath
#if( -not (test-path $target_full_path )){
#	write "Folder " +$target_full_path  + " not here! Creating it.."
#	md $target_full_path

#}
#Remove-PSDrive -name TEST



if ($targetroot.startswith("\\")) {
	
}
else { 
	$cred_option="" 
}


"---------- STEP 5 from 8 ------"
"-------------------"
"CONFIGURE WB-BACKUP "
get-date -Format "yyyy-MM-dd__HH:mm:ss"


$pol=New-WBPolicy 

$wbtarget=New-WBBackupTarget -NetworkPath $target_full_path -Credential $cred 


#"	Target adding:"

Add-WBBackupTarget -Policy $pol -Target $wbtarget 


#"Target added"



"---------- STEP 6 from 8 ------"
if($full_diff.trim() -eq "full"){

	"`n		DO FULL BACKUP"
	Add-WBBareMetalRecovery -Policy $pol
	Add-WBSystemState -Policy $pol
	Add-WBVolume -Policy $pol -Volume (Get-WBVolume -CriticalVolumes)      
	$filespecs= new-wbfilespec -filespec $diff_files_locations
		Add-WBFileSpec -Policy $pol $filespecs
	"	FULL: Bare and System State added"

}




if($full_diff.trim() -eq "diff"){
	"`n	DO DIFF BACKUP"
	if($diff_files_locations){
	#	Add-WBSystemState -Policy $pol
		$filespecs= new-wbfilespec -filespec $diff_files_locations
		Add-WBFileSpec -Policy $pol $filespecs

		"DIFF: Adding Folders: "
		"	" + $diff_files_locations 
	}
	else {
		"No DIFF DIRS defined! EXITING!"
		exit
	}
}


#"VOLUMES"
#$vols = Get-WBVolume -AllVolumes

#Add-WBVolume -Policy $pol -Volume $vols


Set-WBPerformanceConfiguration -OverallPerformanceSetting alwaysincremental

Set-WBVssBackupOption -pol $pol -VssFullBackup

      
            
#get-wbvolume -policy $pol
"`nPOLICY COMPLETE "



"---------- STEP 7 from 8 ------"

"	Start WBJOB with these options:"
"`t" + $pol
if ( -not $skip_backup ) {
	get-date -Format "yyyy-MM-dd__HH:mm:ss"
	$exit= Start-WBBackup -Policy $pol
	
	"	EXITCODE PS: " + $? + "; EXITCODE WIN: " + $LASTEXITCODE
	get-date -Format "yyyy-MM-dd__HH:mm:ss"
}
else {"	BACKUP: skipped!"}


 # https://docs.microsoft.com/en-us/powershell/module/windowsserverbackup/?view=win10-ps



# RESTART services

if ( -not( $cold_services_to_stop -eq $null ) -and ($full_diff -eq "full")){

# reverse order of services:
[array]::Reverse($cold_services_to_stop)
foreach ($service in $cold_services_to_stop){
net start $service
}
}
 

"---------- STEP 8 from 8  ------"
"---------------------"
"`n"
"ROTATE DUMPS"

foreach ($rotate_dir in $rotate_dirs) {

$dest= $rotate_dir.tostring() + "\" +$datumuhrzeit
	"`tMOVE \last => " +  $datumuhrzeit
move-item $rotate_dir\last  -destination $dest 
	"`tMOVE done!"

if ($rotationdiff_days){
	"`tDELETE date older than $rotationdiff_days days "
Get-ChildItem $rotate_dir |Where-Object {((Get-Date) - $_.LastwriteTime).days -gt $rotationdiff_days}| Remove-Item -recurse
	"`tDELETE done"
}
}




# PREPARE LOGS



# SEND MAIL

"----------------------------"
"ENDED"
get-date -Format "yyyy-MM-dd__HH:mm:ss"
"----------------------------"