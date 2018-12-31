# RDPBruteForceBlocker
Simple powershell to defend against RDP brute force attacks on Windows Server 2016

Do you have RDP open to internet? Of course you do. Re-archtecture is hard. "Fix" it with this ad hoc PowerShell do-thingy.

When used as a scheduled task this creates and mantains Windows Firewall block rules to block TCP 3389 and ICMP from IP addresses with multiple failed attempts in the last 240 minutes. The result is a temporary block that should make your server unappetizing to brute force attackers but that also doesn't require as much intervention because false positives will eventually resolve themselves.

This is intended to be run as a scheduled task on Windows Server 2016. It is not compatible with earlier versions because the event doesn't exist. Unfortunately in 2012 and 2012r2 the addition of NLA makes using a similar mechanism difficult.

Just copy the directory onto your server, then from an elevated command prompt run .\Deploy-RDPBruteForceBlocker.ps1