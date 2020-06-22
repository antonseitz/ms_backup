param(
[string]$full_diff ,
[switch]$debug ,
[switch]$dryrun
)

if($dryrun){
	$script:dryrun = $true
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

"----------"
"CONFIG: `n"


# DEBUG ?


if($debug) {Set-PSDebug -Trace 1
	"DEBUG: ON"
}
else {Set-PSDebug -Off
	"DEBUG: OFF"
}

"DRYRUN: " + $dryrun
	

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



"-------------------"
" EXECUTE SUBTASKS"
# i.e. Dump DBs

if($subtasks_before_backup){

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



"-------------------"
"TEST AND PREPARE TARGET"

$targetpath="MS_BACKUP\" + $env:computername + "\" +  $full_diff.trim()
$target_full_path= $targetroot + "\" + $targetpath


$password = ConvertTo-SecureString $targetsmbpass -AsPlainText -Force
$cred = new-object System.Management.Automation.PSCredential ($targetsmbuser, $password)
$test=New-PSDrive -name "TEST" -Root $targetroot -Credential $cred -PSProvider filesystem 
if(-not $test){
	write " ERROR while mounting SMB Share!"
	exit
}
$testpath = "TEST:\" + $targetpath
if( -not (test-path $testpath )){
	write "Folder " +$targetpath  + " not here! Creating it.."
	md $testpath

}
Remove-PSDrive -name TEST



if ($targetroot.startswith("\\")) {
	
}
else { 
	$cred_option="" 
}



"-------------------"
"CONFIGURE WB-BACKUP "

$pol=New-WBPolicy 

$wbtarget=New-WBBackupTarget -NetworkPath $target_full_path -Credential $cred 


#"	Target adding:"

Add-WBBackupTarget -Policy $pol -Target $wbtarget 


#"Target added"




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





"	Start WBJOB with these options:"
"`t" + $pol
if ( -not $dryrun ) {

	Start-WBBackup -Policy $pol
	"	EXITCODE: " + $LASTEXITCODE
}
else {"	DRYRUN: skipped!"}


 # https://docs.microsoft.com/en-us/powershell/module/windowsserverbackup/?view=win10-ps



# RESTART services

if ( -not( $cold_services_to_stop -eq $null ) -and ($full_diff -eq "full")){

# reverse order of services:
[array]::Reverse($cold_services_to_stop)
foreach ($service in $cold_services_to_stop){
net start $service
}
}
 


"---------------------"
"`n"
"ROTATE DUMPS"

foreach ($rotate_dir in $diff_files_locations) {

$dest= $rotate_dir + "\" +(get-date -format "yyyy_MM_dd__HH_mm")  
	"`tMOVE \last => " + (get-date -format "yyyy_MM_dd__HH_mm")  
move-item $rotate_dir\last  -destination $dest 
	"`tMOVE done!"
	"`tDELETE date older than $script:rotationdiff_days days"
Get-ChildItem $rotate_dir |Where-Object {((Get-Date) - $_.LastwriteTime).days -gt $script:rotationdiff_days}| Remove-Item -recurse
	"`tDELETE done"

}




# PREPARE LOGS



# SEND MAIL

"----------------------------"
"ENDED"
"----------------------------"