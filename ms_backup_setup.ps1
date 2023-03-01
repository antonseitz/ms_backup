# ist feature installed ?
if ( -not (Get-WindowsFeature | where { $_.Name -eq "Windows-Server-Backup"  -and $_.installstate -eq "installed" })){

Add-WindowsFeature Windows-Server-Backup

}

Set-PSDebug -off
"
##### Create MS_Backup_Daily_Diff ####
"



$creds = Read-Host "Do you want to enter cred for your backup task  ? (y to confirm)" 
if ($creds -eq "y" ) {
	$user=read-host "Enter Username"

$SecurePassword = $Password = Read-Host -AsSecureString "Password: "

$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $user, $SecurePassword

# Das PWD wieder entschlüsseln, damit wir es plain verwednen können: 
$Password = $Credentials.GetNetworkCredential().Password 

}


if (get-ScheduledTask  MS_Backup_Daily_Diff) {
" 
 OLD ScheduledTask found !
 "

$del_diff = Read-Host "Delete OLD ScheduledTask  MS_Backup_Daily_Diff (y to confirm) ?"

if ($del_diff -eq "y" ) {

UnRegister-ScheduledTask  MS_Backup_Daily_Diff
	
}}

$A = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-noninteractive -noLogo -noprofile -command `"& {c:\ms_backup\ms_backup.ps1 diff ; return $LASTEXITCODE  }`"  2>&1 >> c:\ms_backup\logs\ms_backup.diff.log"
$T = New-ScheduledTaskTrigger -Daily -At 9pm
$S = New-ScheduledTaskSettingsSet -Compatibility Win8

$D = New-ScheduledTask -Action $A  -Trigger $T -Settings $S #}

if ($creds -eq "y" ) {
    $D | Register-ScheduledTask MS_Backup_Daily_Diff  -User $user -Password $password -taskpath "\Microsoft\Windows\Backup" 
}
else 
    {
    $D | Register-ScheduledTask MS_Backup_Daily_Diff    -taskpath "\Microsoft\Windows\Backup"  
}



"
#### Create MS_Backup_Weekly_Full ####
"

if (get-ScheduledTask  MS_Backup_Weekly_Full) {
" 
 OLD ScheduledTask found!
 "
$del_full = Read-Host "Delete OLD ScheduledTask MS_Backup_Weekly_Full (y to confirm) ?"

if ( $del_full -eq "y" ) {
	
UnRegister-ScheduledTask  MS_Backup_Weekly_Full
	
}
}
$A = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-noninteractive -noLogo -noprofile -command `"& {c:\ms_backup\ms_backup.ps1 full ; return $LASTEXITCODE  }`"  2>&1 >> c:\ms_backup\logs\ms_backup.full.log"



" 
When should weekly full backup run? 0=sunday;6=saturday
" 

$dayofweek = read-host  "Enter 0-6 for day of week: "

$T = New-ScheduledTaskTrigger -Weekly -At 10pm -DaysOfWeek $dayofweek


$S = New-ScheduledTaskSettingsSet -Compatibility Win8



$D = New-ScheduledTask -Action $A  -Trigger $T -Settings $S 


if ($creds -eq "y" ) { 
    $D | Register-ScheduledTask MS_Backup_Weekly_Full  -User $user -Password $password -taskpath "\Microsoft\Windows\Backup" 

    }
    else {
    $D | Register-ScheduledTask MS_Backup_Weekly_Full -taskpath "\Microsoft\Windows\Backup" 
    }