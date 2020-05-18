param(
[string]$full_diff 
#[switch]$debug ,
#[switch]$dryrun
)

Set-PSDebug -off

if (! $full_diff -or (($full_diff -ne "full") -and ($full_diff -ne "diff"))){ 
write-host("Usage: "  +  $MyInvocation.MyCommand.Name + " -full_diff full|diff ") #[-debug] [-dryrun] ")
#write "-debug = a lot of output"
#write "-dryrun = without producing dumps and backup on target"

exit
}


# ist feature installed ?
if ( -not (Get-WindowsFeature | where { $_.Name -eq "Windows-Server-Backup"  -and $_.installstate -eq "installed" })){

Add-WindowsFeature Windows-Server-Backup

}




write "Delete OLD ScheduledTask "
$taskname= "MS_Backup_" + $full_diff 
UnRegister-ScheduledTask  $taskname

$user=read-host "Username"
$pass=read-host "Password" -AsSecureString # do not show password 

# convert Securestring to "normal" string
$pass=[Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))


$A = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-noninteractive -noLogo -noprofile -command ""& {c:\ms_backup\ms_backup.ps1 $full_diff ; return $LASTEXITCODE  }""  2>&1 > c:\ms_backup\logs\ms_backup.$full_diff.log"
$T = New-ScheduledTaskTrigger -Daily -At 9pm
#$P = New-ScheduledTaskPrincipal "domain|computer\backup" -logontype Password

$S = New-ScheduledTaskSettingsSet -Compatibility Win8
#$D = New-ScheduledTask -Action $A -Principal $P -Trigger $T -Settings $S
$D = New-ScheduledTask -Action $A  -Trigger $T -Settings $S

Register-ScheduledTask $taskname -InputObject $D -taskpath "\Microsoft\Windows\Backup" -user $user -pass $pass