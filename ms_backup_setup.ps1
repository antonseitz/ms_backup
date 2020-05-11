# ist feature installed ?
if ( -not (Get-WindowsFeature | where { $_.Name -eq "Windows-Server-Backup"  -and $_.installstate -eq "installed" })){

Add-WindowsFeature Windows-Server-Backup

}



Set-PSDebug -off

write "Delete OLD ScheduledTask ?"
UnRegister-ScheduledTask  MS_Backup_Daily_test 
$A = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-noninteractive -noLogo -noprofile -command '& {c:\ms_backup\ms_backup.ps1 full ; return $LASTEXITCODE  }'  2>&1 > c:\ms_backup\ms_backup.log"
$T = New-ScheduledTaskTrigger -Daily -At 9pm
#$P = New-ScheduledTaskPrincipal "museumsbund\backup" -logontype Password

$S = New-ScheduledTaskSettingsSet -Compatibility Win8
#$D = New-ScheduledTask -Action $A -Principal $P -Trigger $T -Settings $S
$D = New-ScheduledTask -Action $A  -Trigger $T -Settings $S
Register-ScheduledTask MS_Backup_Daily_test -InputObject $D -taskpath "\Microsoft\Windows\Backup" -user "museumsbund\backup" -pass "backup7%"