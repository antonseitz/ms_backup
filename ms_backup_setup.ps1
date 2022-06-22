# ist feature installed ?
if ( -not (Get-WindowsFeature | where { $_.Name -eq "Windows-Server-Backup"  -and $_.installstate -eq "installed" })){

Add-WindowsFeature Windows-Server-Backup

}



Set-PSDebug -off
"
##### Create MS_Backup_Daily_Diff ####
"


if (get-ScheduledTask  MS_Backup_Daily_Diff) {
" 
 OLD ScheduledTask found !
 "

$choice = Read-Host "Delete OLD ScheduledTask (n to skip) ?"

if ($choice -ne "n" ) {
UnRegister-ScheduledTask  MS_Backup_Daily_Diff
	
}}

$A = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-noninteractive -noLogo -noprofile -command '& {c:\ms_backup\ms_backup.ps1 diff ; return $LASTEXITCODE  }'  2>&1 > c:\ms_backup\ms_backup.diff.log"
$T = New-ScheduledTaskTrigger -Daily -At 9pm

$choice = Read-Host "Do you want to enter cred for backup task  ? (n to skip)" 
if ($choice -ne "n" ) {
	$user=read-host "Enter Username"
$P = New-ScheduledTaskPrincipal -userid $user -logontype Password

}
$S = New-ScheduledTaskSettingsSet -Compatibility Win8

if ($choice -ne "y" ) {
$D = New-ScheduledTask -Action $A -Principal $P -Trigger $T -Settings $S
}
$D = New-ScheduledTask -Action $A  -Trigger $T -Settings $S
Register-ScheduledTask MS_Backup_Daily_Diff -InputObject $D -taskpath "\Microsoft\Windows\Backup" 


"
#### Create MS_Backup_Weekly_Full ####
"

if (get-ScheduledTask  MS_Backup_Weekly_Full) {
" 
 OLD ScheduledTask found!
 "
$choice = Read-Host "Delete OLD ScheduledTask (n to skip ) ?"

if ($choice -ne "y" ) {
	
UnRegister-ScheduledTask  MS_Backup_Weekly_Full
	
}
}
$A = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-noninteractive -noLogo -noprofile -command '& {c:\ms_backup\ms_backup.ps1 full ; return $LASTEXITCODE  }'  2>&1 > c:\ms_backup\ms_backup.full.log"
" 
When should weekly full backup run? 0=sunday;6=saturday
" 
$T = New-ScheduledTaskTrigger -Weekly -At 10pm

$choice = Read-Host "Do you want to enter cred for backup task  ? (n to skip )" 
if ($choice -ne "y" ) {
	$user=read-host "Enter Username"
$P = New-ScheduledTaskPrincipal -userid $user -logontype Password

}
$S = New-ScheduledTaskSettingsSet -Compatibility Win8

if ($choice -ne "y" ) {
$D = New-ScheduledTask -Action $A -Principal $P -Trigger $T -Settings $S
}
$D = New-ScheduledTask -Action $A  -Trigger $T -Settings $S
Register-ScheduledTask MS_Backup_Weekly_Full -InputObject $D -taskpath "\Microsoft\Windows\Backup" 