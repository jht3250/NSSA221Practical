# LAB 2 WINSERV ACTIVE DIRECTORY

$DomainName = "jht3250.com"  
$NetBIOSName = "JHT3250"
$DSRMPassword = ConvertTo-SecureString "Swimmy1s$" -AsPlainText -Force

Install-WindowsFeature -Name AD-Domain-Services, DNS, DHCP -IncludeManagementTools

Install-ADDSForest `
    -DomainName $DomainName `
    -DomainNetbiosName $NetBIOSName `
    -SafeModeAdministratorPassword $DSRMPassword `
    -InstallDns:$true `
    -Force:$true

