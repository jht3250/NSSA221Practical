#===============================================================================
# NSSA221 Lab 06 - Activity 5: Email Server Prerequisites & DNS Configuration
# Run on Windows Server 2022 (designated mail server)
#===============================================================================

#-------------------------------------------------------------------------------
# Configuration - MODIFY THESE VALUES FOR YOUR ENVIRONMENT
#-------------------------------------------------------------------------------
$Domain = "yourid.com"                  # Your RIT ID domain (e.g., abc1234.com)
$MailServerHostname = "mail01"          # Hostname for mail server
$MailServerIP = "192.168.10.X"          # Static IP for mail server

# DNS Server (Domain Controller) - only needed if running on different server
$DNSServer = "192.168.10.X"             # IP of your DNS server/DC

#-------------------------------------------------------------------------------
# Derived variables
#-------------------------------------------------------------------------------
$MailServerFQDN = "$MailServerHostname.$Domain"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NSSA221 Lab 06 - Email Server Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Domain: $Domain"
Write-Host "Mail Server: $MailServerFQDN ($MailServerIP)"
Write-Host ""

#-------------------------------------------------------------------------------
# Step 1: Set Hostname (if not already set)
#-------------------------------------------------------------------------------
Write-Host "[STEP 1] Checking hostname..." -ForegroundColor Yellow

$currentHostname = $env:COMPUTERNAME
if ($currentHostname -ne $MailServerHostname) {
    Write-Host "[INFO] Current hostname: $currentHostname" -ForegroundColor Yellow
    Write-Host "[INFO] Renaming computer to: $MailServerHostname" -ForegroundColor Yellow
    
    $response = Read-Host "Do you want to rename this computer? (Y/N)"
    if ($response -eq "Y") {
        Rename-Computer -NewName $MailServerHostname -Force
        Write-Host "[WARN] Computer will need to be restarted for hostname change" -ForegroundColor Yellow
    }
} else {
    Write-Host "[INFO] Hostname is already set to $MailServerHostname" -ForegroundColor Green
}

#-------------------------------------------------------------------------------
# Step 2: Install IIS (Web Server) - Required for MailEnable
#-------------------------------------------------------------------------------
Write-Host ""
Write-Host "[STEP 2] Installing IIS Web Server (MailEnable prerequisite)..." -ForegroundColor Yellow

try {
    $iisFeature = Get-WindowsFeature -Name Web-Server
    
    if ($iisFeature.Installed) {
        Write-Host "[INFO] IIS is already installed" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Installing IIS with default features..." -ForegroundColor Yellow
        Install-WindowsFeature -Name Web-Server -IncludeManagementTools
        Write-Host "[INFO] IIS installed successfully" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERROR] Failed to install IIS: $_" -ForegroundColor Red
}

#-------------------------------------------------------------------------------
# Step 3: Configure DNS Records for Email
#-------------------------------------------------------------------------------
Write-Host ""
Write-Host "[STEP 3] Configuring DNS records for email..." -ForegroundColor Yellow

# Check if DNS module is available (running on DC)
if (Get-Module -ListAvailable -Name DnsServer) {
    
    # Create A record for mail server
    Write-Host "[INFO] Creating A record for mail server..." -ForegroundColor Yellow
    try {
        $existingA = Get-DnsServerResourceRecord -ZoneName $Domain -Name $MailServerHostname -RRType A -ErrorAction SilentlyContinue
        if (-not $existingA) {
            Add-DnsServerResourceRecordA -Name $MailServerHostname -ZoneName $Domain -IPv4Address $MailServerIP
            Write-Host "[INFO] Created A record: $MailServerHostname -> $MailServerIP" -ForegroundColor Green
        } else {
            Write-Host "[INFO] A record for $MailServerHostname already exists" -ForegroundColor Green
        }
    } catch {
        Write-Host "[ERROR] Failed to create A record: $_" -ForegroundColor Red
    }
    
    # Create MX record
    Write-Host "[INFO] Creating MX record..." -ForegroundColor Yellow
    try {
        $existingMX = Get-DnsServerResourceRecord -ZoneName $Domain -RRType MX -ErrorAction SilentlyContinue
        if (-not $existingMX) {
            Add-DnsServerResourceRecordMX -Name "." -ZoneName $Domain -MailExchange $MailServerFQDN -Preference 10
            Write-Host "[INFO] Created MX record: $Domain -> $MailServerFQDN (priority 10)" -ForegroundColor Green
        } else {
            Write-Host "[INFO] MX record already exists" -ForegroundColor Green
        }
    } catch {
        Write-Host "[ERROR] Failed to create MX record: $_" -ForegroundColor Red
    }
    
    # Verify DNS records
    Write-Host ""
    Write-Host "DNS Records for $Domain :" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "A Records:" -ForegroundColor Green
    Get-DnsServerResourceRecord -ZoneName $Domain -RRType A | Where-Object {$_.HostName -eq $MailServerHostname} | Format-Table
    Write-Host "MX Records:" -ForegroundColor Green
    Get-DnsServerResourceRecord -ZoneName $Domain -RRType MX | Format-Table
    
} else {
    Write-Host "[WARN] DNS Server module not found. Run this on the Domain Controller," -ForegroundColor Yellow
    Write-Host "       or manually create the following DNS records:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "       A Record:  $MailServerHostname -> $MailServerIP" -ForegroundColor White
    Write-Host "       MX Record: $Domain -> $MailServerFQDN (Priority: 10)" -ForegroundColor White
}

#-------------------------------------------------------------------------------
# Step 4: Configure Firewall for Email Protocols
#-------------------------------------------------------------------------------
Write-Host ""
Write-Host "[STEP 4] Configuring firewall for email protocols..." -ForegroundColor Yellow

$firewallRules = @(
    @{Name="SMTP"; Port=25; Protocol="TCP"},
    @{Name="SMTP-Submission"; Port=587; Protocol="TCP"},
    @{Name="IMAP"; Port=143; Protocol="TCP"},
    @{Name="IMAPS"; Port=993; Protocol="TCP"},
    @{Name="POP3"; Port=110; Protocol="TCP"},
    @{Name="POP3S"; Port=995; Protocol="TCP"}
)

foreach ($rule in $firewallRules) {
    $existingRule = Get-NetFirewallRule -DisplayName "MailEnable-$($rule.Name)" -ErrorAction SilentlyContinue
    if (-not $existingRule) {
        New-NetFirewallRule -DisplayName "MailEnable-$($rule.Name)" `
            -Direction Inbound `
            -Protocol $rule.Protocol `
            -LocalPort $rule.Port `
            -Action Allow | Out-Null
        Write-Host "[INFO] Created firewall rule: $($rule.Name) (Port $($rule.Port))" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Firewall rule already exists: $($rule.Name)" -ForegroundColor Green
    }
}

#-------------------------------------------------------------------------------
# Summary and Next Steps
#-------------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Email Server Prerequisites Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Completed:"
Write-Host "  [X] IIS Web Server installed"
Write-Host "  [X] DNS records configured (A and MX)"
Write-Host "  [X] Firewall rules created"
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NEXT STEPS - Manual MailEnable Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Download MailEnable Standard (Free) from:"
Write-Host "   https://www.mailenable.com/download.asp" -ForegroundColor White
Write-Host ""
Write-Host "2. During installation, use these settings:"
Write-Host "   - Post Office Name: $Domain" -ForegroundColor White
Write-Host "   - Accept default SMTP connector settings" -ForegroundColor White
Write-Host "   - Enable Webmail with default IIS site" -ForegroundColor White
Write-Host ""
Write-Host "3. After installation, create mailboxes:"
Write-Host "   - Open MailEnable Management"
Write-Host "   - Expand Messaging Manager > Post Offices > $Domain"
Write-Host "   - Right-click Mailboxes > Create Mailbox"
Write-Host "   - Create at least 2 mailboxes (e.g., starlord, gamora)"
Write-Host ""
Write-Host "4. Test email functionality from clients"
Write-Host ""

# Create a summary file
$summaryPath = "C:\MailEnable-Setup-Info.txt"
@"
NSSA221 Lab 06 - Email Server Configuration Summary
====================================================
Generated: $(Get-Date)

Domain: $Domain
Mail Server: $MailServerFQDN
IP Address: $MailServerIP

DNS Records Required:
- A Record: $MailServerHostname -> $MailServerIP
- MX Record: $Domain -> $MailServerFQDN (Priority 10)

Email Ports Opened:
- SMTP: 25
- SMTP Submission: 587
- IMAP: 143
- IMAPS: 993
- POP3: 110
- POP3S: 995

MailEnable Download:
https://www.mailenable.com/download.asp
"@ | Out-File -FilePath $summaryPath -Encoding UTF8

Write-Host "[INFO] Configuration summary saved to: $summaryPath" -ForegroundColor Green
