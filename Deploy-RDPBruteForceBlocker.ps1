# Deploys Block-FailedRDPAttempts.ps1 as a scheduled task in a consistent and repeatable way

param(
    [Parameter(Mandatory=$false)][string]$taskName = "RDPBruteForceBlocker",
    [Parameter(Mandatory=$false)][string]$scriptDirectory = 'C:\Program Files\WindowsPowerShell\Scripts\',
    [Parameter(Mandatory=$false)][string]$scriptName = 'Block-FailedRDPAttempts.ps1',
    #[Parameter(Mandatory=$false)][SecureString] $creds = (Get-Credential),
    [Parameter(Mandatory=$false)]$repeat = (New-TimeSpan -Minutes 60)
)

$ErrorActionPreference = "Stop"

#Create event log source if it doesn't exist
if([System.Diagnostics.EventLog]::SourceExists("RDPBruteForceBlocker") -eq $False){
    New-EventLog -LogName "RDPBruteForceBlocker" -Source "RDPBruteForceBlocker"
    }

# Create directory if it doesn't exist
if(!(Test-Path $scriptDirectory)){
    New-Item -ItemType Directory -Path $scriptDirectory
    }

# Deploy scripts
Copy-Item (".\" + $scriptName) -Destination $scriptDirectory -Force

#Deploy Schedule Task
$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument ('-executionpolicy bypass -NoProfile -file "' + $scriptDirectory + $scriptName + '"')

#Set trigger to repeat on interval
$dt= ([DateTime]::Now)
$duration = $dt.AddYears(25) -$dt;

$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval $repeat -RepetitionDuration $duration

#Remove existing task to avoid conflict
Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

#Register scheduled task
Register-ScheduledTask `
    -Action $action `
    -Trigger $trigger `
    -TaskName $taskName `
    -Description $taskName `
    -RunLevel Highest

#Run To Validate
Get-ScheduledTask -TaskName $taskName | Start-ScheduledTask

do{
$taskInfo = Get-ScheduledTaskInfo -TaskName $taskName
Start-Sleep 3
} while ($taskInfo.LastTaskResult -eq 267009)

if($taskInfo.LastTaskResult -eq 0){
    Write-EventLog -LogName "RDPBruteForceBlocker" -Source "RDPBruteForceBlocker" -EventId 1010 -EntryType SuccessAudit -Message "Scheduled task deployment succeeded for: $taskName"
    }else{
    Write-EventLog -LogName "RDPBruteForceBlocker" -Source "RDPBruteForceBlocker" -EventId 1011 -EntryType Error -Message "Scheduled task deployment failed for: $taskName"
}
