# LAB 2 DHCP Config on WinServ

$ScopeName = "LAN Scope"
$StartRange = "192.168.10.11"
$EndRange = "192.168.10.254"
$SubnetMask = "255.255.255.0"
$Gateway = "192.168.10.1"
$DNSServer = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*"}).IPAddress

Add-DhcpServerInDC

Add-DhcpServerv4Scope -Name $ScopeName -StartRange $StartRange -EndRange $EndRange -SubnetMask $SubnetMask -State Active

Set-DhcpServerv4OptionValue -Router $Gateway -DnsServer $DNSServer, "8.8.8.8"

Add-DhcpServerv4ExclusionRange -ScopeId "192.168.10.0" -StartRange "192.168.10.2" -EndRange "192.168.10.10"
Add-DhcpServerv4ExclusionRange -ScopeId "192.168.10.0" -StartRange "192.168.10.1" -EndRange "192.168.10.1"