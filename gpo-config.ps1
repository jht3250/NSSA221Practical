# LAB 2 WINSERV GPOs

Import-Module GroupPolicy

$GPO1 = New-GPO -Name "DenyControlPanel"
Set-GPRegistryValue -Name "DenyControlPanel" `
    -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -ValueName "NoControlPanel" -Type DWord -Value 1

New-GPLink -Name "DenyControlPanel" -Target "DC=abc1234,DC=com"

$GPO2 = New-GPO -Name "StandardWallpaper"

Set-GPRegistryValue -Name "StandardWallpaper" `
    -Key "HKCU\Control Panel\Desktop" `
    -ValueName "Wallpaper" -Type String -Value "\\server\share\wallpaper.jpg"

New-GPLink -Name "StandardWallpaper" -Target "OU=Ramones,DC=abc1234,DC=com"

Get-GPOReport -Name "DenyControlPanel" -ReportType Html -Path "C:\GPOReports\DenyControlPanel.html"
Get-GPOReport -Name "StandardWallpaper" -ReportType Html -Path "C:\GPOReports\StandardWallpaper.html"