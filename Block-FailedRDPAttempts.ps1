# Only compatible with Server 2016
# Intended to be run as a recurring scheduled task
# Parses 240 minutes of logs then based on a tolerance for failed login attempts, creates TCP 3389 (RDP) and ICMP block rules.
# This will remove the old rules each time it is run which has the effect of creating a temporary block if this is run as a scheduled task.

#Quantity of failed login attempts required to trigger blocking
$tolerance = 15

$logName = "Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Operational"

#Increase log retention to have enough logs to work with
if((Get-WinEvent -ListLog $logName).MaximumSizeInBytes -lt 20000000){
    $log = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration $logName
    $log.MaximumSizeInBytes=20000000
    $log.SaveChanges()
}

#Filter logs for desired event
$events = Get-WinEvent -ea 0 -FilterHashtable @{ProviderName="Microsoft-Windows-RemoteDesktopServices-RdpCoreTS"; ID=140; StartTime = ((get-date).AddMinutes(-240))}

#IP Address Regex
$regex = [regex] "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"

$list = @()

#Pull lines with IP addresses out of events object
foreach($message in $events.Message){
    $list += (Select-String -InputObject $message -Pattern $regex).Matches.Value
}

#Group objects so that occurances can be counted
$group = $list | Group-Object

$blackList = @()

#Add Addresses with sufficient occurances to blacklist
foreach($entry in $group){
    if($entry.Count -ge $tolerance){
        $blackList += $entry.Name
    }
}

#Clear prior entries from Windows Firewall and implement new entries based on black list
Get-NetFirewallRule -Name "RDP_BlackList_3389" | Remove-NetFirewallRule -ErrorAction SilentlyContinue
New-NetFirewallRule -Name "RDP_BlackList_3389" -DisplayName "RDP_BlackList_3389" -Direction Inbound -LocalPort 3389 -Protocol TCP -Action Block -RemoteAddress $blackList
Get-NetFirewallRule -Name "RDP_BlackList_ICMP" | Remove-NetFirewallRule -ErrorAction SilentlyContinue
New-NetFirewallRule -Name "RDP_BlackList_ICMP" -DisplayName "RDP_BlackList_ICMP" -Direction Inbound -Protocol ICMPv4 -Action Block -RemoteAddress $blackList
