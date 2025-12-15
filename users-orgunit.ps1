# LAB 2 WINSERV USERS AND ORGANIZATIONAL UNITS

$Domain = "DC=jht3250,DC=com"  
$Password = ConvertTo-SecureString "MeowRIT$" -AsPlainText -Force

New-ADUser -Name "John Treon" `
    -GivenName "John" -Surname "Treon" `
    -SamAccountName "jtreon" `
    -UserPrincipalName "jtreon@jht3250.com" `
    -AccountPassword $Password `
    -PasswordNeverExpires $true `
    -CannotChangePassword $true `
    -Enabled $true

Add-ADGroupMember -Identity "Domain Admins" -Members "jtreon"

New-ADOrganizationalUnit -Name "Ramones" -Path $Domain
New-ADOrganizationalUnit -Name "Weezer" -Path $Domain

$RamonesUsers = @(
    @{First="Joey"; Last="Ramone"; Title="Lead Singer"; Office="12-1789 x3456"},
    @{First="Johnny"; Last="Ramone"; Title="Guitarist"; Office="34-1797 x3456"},
    @{First="Marky"; Last="Ramone"; Title="Drummer"; Office="23-1801 x5675"},
    @{First="Tommy"; Last="Ramone"; Title="Drummer"; Office="Bldg. 34 Office 1809 x5678"}
)

foreach ($user in $RamonesUsers) {
    $sam = ($user.First + $user.Last).ToLower()
    New-ADUser -Name "$($user.First) $($user.Last)" `
        -GivenName $user.First -Surname $user.Last `
        -SamAccountName $sam `
        -UserPrincipalName "$sam@jht3250.com" `
        -Title $user.Title -Office $user.Office `
        -Path "OU=Ramones,$Domain" `
        -AccountPassword $Password `
        -Enabled $true
}
