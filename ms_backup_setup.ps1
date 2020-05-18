param(
[string]$full_diff ,
[switch]$debug 
#[switch]$dryrun
)
# DEBUG ?
Set-PSDebug -off

if($debug) {Set-PSDebug -Trace 1}
else {Set-PSDebug -Off}



# ARE YOU ADMIN ?

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ( -not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) ){
write "YOU HAVE NO ADMIN RIGHTS: EXITING!"
exit 1
}

# USAGE

if (! $full_diff -or (($full_diff -ne "full") -and ($full_diff -ne "diff"))){ 
write-host("Usage: "  +  $MyInvocation.MyCommand.Name + " -full_diff full|diff ") #[-debug] [-dryrun] ")
write "-debug = a lot of output"
#write "-dryrun = without producing dumps and backup on target"

exit
}

# ARE YOU ADMIN ?

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ( -not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) ){
write "YOU HAVE NO ADMIN RIGHTS: EXITING!"
exit 1
}



# Install Feature "Windows Server Backup" , if not installed 
if ( -not (Get-WindowsFeature | where { $_.Name -eq "Windows-Server-Backup"  -and $_.installstate -eq "installed" })){
Add-WindowsFeature Windows-Server-Backup

}

# DELETE OLD, IF PRESENT

$taskname= "MS_Backup_" + $full_diff 
if( get-scheduledtask -taskname $taskname  )
{
write "Delete OLD ScheduledTask: $taskname"

UnRegister-ScheduledTask  $taskname
}

$user=read-host "Username"
$pass=read-host "Password" -AsSecureString # do not show password 

# convert Securestring to "normal" string
$pass=[Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))

$arg= '-noninteractive -noLogo -noprofile -command "& {c:\ms_backup\ms_backup.ps1 ' + $full_diff  + '; return $LASTEXITCODE  }"  2>&1 > c:\ms_backup\logs\ms_backup.' + $full_diff + '.log'
$arg



if( $full_diff -eq "diff" ) {
$T = New-ScheduledTaskTrigger -Daily -At 7pm
}
if($full_diff -eq "full") {
$T = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Friday -At 9pm
}
$A = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arg



$S = New-ScheduledTaskSettingsSet -Compatibility Win8

$D = New-ScheduledTask -Action $A  -Trigger $T -Settings $S

Register-ScheduledTask $taskname -InputObject $D -taskpath "\Microsoft\Windows\Backup" -user $user -pass $pass