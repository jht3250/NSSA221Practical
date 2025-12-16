#===============================================================================
# NSSA221 Lab 06 - Activity 2: DNS Records for Virtual Web Servers
# Run on Windows Server 2022/2025 (Domain Controller with DNS)
#===============================================================================

#-------------------------------------------------------------------------------
# Configuration - MODIFY THESE VALUES FOR YOUR ENVIRONMENT
#-------------------------------------------------------------------------------
$Domain = "yourid.com"                  # Your RIT ID domain (e.g., abc1234.com)
$WebServerHostname = "web01"            # Hostname of your Rocky Linux web server
$WebServerIP = "192.168.10.X"           # IP address of your web server
$VHost1Prefix = "starlord"              # First virtual host prefix
$VHost2Prefix = "gamora"                # Second virtual host prefix

#-------------------------------------------------------------------------------
# Derived variables
#-------------------------------------------------------------------------------
$ZoneName = $Domain
$WebServerFQDN = "$WebServerHostname.$Domain"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NSSA221 Lab 06 - DNS Configuration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Domain: $Domain"
Write-Host "Web Server: $WebServerFQDN ($WebServerIP)"
Write-Host "Virtual Host 1: $VHost1Prefix.$Domain"
Write-Host "Virtual Host 2: $VHost2Prefix.$Domain"
Write-Host ""

#-------------------------------------------------------------------------------
# Step 1: Create A Record for Web Server (if not exists)
#-------------------------------------------------------------------------------
Write-Host "[STEP 1] Creating A record for web server..." -ForegroundColor Yellow

try {
    # Check if A record already exists
    $existingA = Get-DnsServerResourceRecord -ZoneName $ZoneName -Name $WebServerHostname -RRType A -ErrorAction SilentlyContinue
    
    if ($existingA) {
        Write-Host "[INFO] A record for $WebServerHostname already exists" -ForegroundColor Green
    } else {
        Add-DnsServerResourceRecordA -Name $WebServerHostname -ZoneName $ZoneName -IPv4Address $WebServerIP
        Write-Host "[INFO] Created A record: $WebServerHostname -> $WebServerIP" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERROR] Failed to create A record: $_" -ForegroundColor Red
}

#-------------------------------------------------------------------------------
# Step 2: Create CNAME Record for www (default site)
#-------------------------------------------------------------------------------
Write-Host "[STEP 2] Creating CNAME record for www (default site)..." -ForegroundColor Yellow

try {
    $existingWWW = Get-DnsServerResourceRecord -ZoneName $ZoneName -Name "www" -RRType CName -ErrorAction SilentlyContinue
    
    if ($existingWWW) {
        Write-Host "[INFO] CNAME record for www already exists" -ForegroundColor Green
    } else {
        Add-DnsServerResourceRecordCName -Name "www" -ZoneName $ZoneName -HostNameAlias $WebServerFQDN
        Write-Host "[INFO] Created CNAME: www.$Domain -> $WebServerFQDN" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERROR] Failed to create www CNAME: $_" -ForegroundColor Red
}

#-------------------------------------------------------------------------------
# Step 3: Create CNAME Record for Virtual Host 1
#-------------------------------------------------------------------------------
Write-Host "[STEP 3] Creating CNAME record for $VHost1Prefix..." -ForegroundColor Yellow

try {
    $existingVH1 = Get-DnsServerResourceRecord -ZoneName $ZoneName -Name $VHost1Prefix -RRType CName -ErrorAction SilentlyContinue
    
    if ($existingVH1) {
        Write-Host "[INFO] CNAME record for $VHost1Prefix already exists" -ForegroundColor Green
    } else {
        Add-DnsServerResourceRecordCName -Name $VHost1Prefix -ZoneName $ZoneName -HostNameAlias $WebServerFQDN
        Write-Host "[INFO] Created CNAME: $VHost1Prefix.$Domain -> $WebServerFQDN" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERROR] Failed to create $VHost1Prefix CNAME: $_" -ForegroundColor Red
}

#-------------------------------------------------------------------------------
# Step 4: Create CNAME Record for Virtual Host 2
#-------------------------------------------------------------------------------
Write-Host "[STEP 4] Creating CNAME record for $VHost2Prefix..." -ForegroundColor Yellow

try {
    $existingVH2 = Get-DnsServerResourceRecord -ZoneName $ZoneName -Name $VHost2Prefix -RRType CName -ErrorAction SilentlyContinue
    
    if ($existingVH2) {
        Write-Host "[INFO] CNAME record for $VHost2Prefix already exists" -ForegroundColor Green
    } else {
        Add-DnsServerResourceRecordCName -Name $VHost2Prefix -ZoneName $ZoneName -HostNameAlias $WebServerFQDN
        Write-Host "[INFO] Created CNAME: $VHost2Prefix.$Domain -> $WebServerFQDN" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERROR] Failed to create $VHost2Prefix CNAME: $_" -ForegroundColor Red
}

#-------------------------------------------------------------------------------
# Verification
#-------------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DNS Records Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Current DNS Records in zone $ZoneName :" -ForegroundColor Yellow
Write-Host ""

# Show A records
Write-Host "A Records:" -ForegroundColor Green
Get-DnsServerResourceRecord -ZoneName $ZoneName -RRType A | Format-Table -Property HostName, RecordData -AutoSize

# Show CNAME records  
Write-Host "CNAME Records:" -ForegroundColor Green
Get-DnsServerResourceRecord -ZoneName $ZoneName -RRType CName | Format-Table -Property HostName, RecordData -AutoSize

#-------------------------------------------------------------------------------
# Test DNS Resolution
#-------------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing DNS Resolution" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$TestHosts = @("www.$Domain", "$VHost1Prefix.$Domain", "$VHost2Prefix.$Domain")

foreach ($TestHost in $TestHosts) {
    Write-Host "Testing: $TestHost" -ForegroundColor Yellow
    try {
        $result = Resolve-DnsName -Name $TestHost -ErrorAction Stop
        Write-Host "  -> Resolved to: $($result.IPAddress)" -ForegroundColor Green
    } catch {
        Write-Host "  -> FAILED to resolve" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Screenshot Commands (for lab report)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Run these commands for your lab report screenshots:"
Write-Host ""
Write-Host "ipconfig"
Write-Host "nslookup $WebServerHostname.$Domain"
Write-Host "nslookup www.$Domain"
Write-Host "nslookup $VHost1Prefix.$Domain"
Write-Host "nslookup $VHost2Prefix.$Domain"
Write-Host ""
Write-Host "[COMPLETE] DNS configuration finished!" -ForegroundColor Green
