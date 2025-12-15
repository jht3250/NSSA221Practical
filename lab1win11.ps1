Rename-Computer -NewName "circuit";

New-NetIPAddress -InterfaceIndex 5 -IPAddress 192.168.10.12 -PrefixLength 24 -DefaultGateway 192.168.10.1;

Set-DnsClientServerAddress -InterfaceIndex 5 -ServerAddresses ("8.8.8.8", "8.8.4.4");

Get-Date; ipconfig /all;