#!/bin/bash
#===============================================================================
# NSSA221 Lab 06 - Activity 6: Linux Email Client (Thunderbird) Setup
# Run as root on Rocky Linux
#===============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

#-------------------------------------------------------------------------------
# Configuration - MODIFY THESE VALUES FOR YOUR ENVIRONMENT
#-------------------------------------------------------------------------------
DOMAIN="yourid.com"                     # Your RIT ID domain
MAIL_SERVER_HOSTNAME="mail01"           # Hostname of your mail server
MAIL_SERVER_FQDN="${MAIL_SERVER_HOSTNAME}.${DOMAIN}"

# Email account to configure (optional - can be done in GUI)
EMAIL_USER="starlord"                   # Username for email account
EMAIL_ADDRESS="${EMAIL_USER}@${DOMAIN}"

#-------------------------------------------------------------------------------
# Pre-flight checks
#-------------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

log_info "Starting Thunderbird email client setup..."
echo ""

#-------------------------------------------------------------------------------
# Step 1: Install Thunderbird
#-------------------------------------------------------------------------------
log_step "Installing Thunderbird email client..."

dnf install -y thunderbird

log_info "Thunderbird installed successfully"

#-------------------------------------------------------------------------------
# Step 2: Verify mail server connectivity
#-------------------------------------------------------------------------------
log_step "Verifying mail server connectivity..."

echo ""
echo "Testing DNS resolution for mail server..."
if nslookup ${MAIL_SERVER_FQDN} > /dev/null 2>&1; then
    log_info "DNS resolution successful for ${MAIL_SERVER_FQDN}"
    nslookup ${MAIL_SERVER_FQDN}
else
    log_warn "DNS resolution failed for ${MAIL_SERVER_FQDN}"
    log_warn "Make sure DNS is configured correctly"
fi

echo ""
echo "Testing MX record for domain..."
if nslookup -type=MX ${DOMAIN} > /dev/null 2>&1; then
    log_info "MX record found for ${DOMAIN}"
    nslookup -type=MX ${DOMAIN}
else
    log_warn "No MX record found for ${DOMAIN}"
fi

echo ""
echo "Testing connectivity to mail server..."
if ping -c 2 ${MAIL_SERVER_FQDN} > /dev/null 2>&1; then
    log_info "Mail server is reachable"
else
    log_warn "Cannot ping mail server - check network configuration"
fi

#-------------------------------------------------------------------------------
# Step 3: Test SMTP and IMAP ports
#-------------------------------------------------------------------------------
log_step "Testing email ports..."

# Test SMTP (port 25)
echo -n "  SMTP (25):  "
if nc -z -w2 ${MAIL_SERVER_FQDN} 25 2>/dev/null; then
    echo -e "${GREEN}OPEN${NC}"
else
    echo -e "${RED}CLOSED${NC}"
fi

# Test IMAP (port 143)
echo -n "  IMAP (143): "
if nc -z -w2 ${MAIL_SERVER_FQDN} 143 2>/dev/null; then
    echo -e "${GREEN}OPEN${NC}"
else
    echo -e "${RED}CLOSED${NC}"
fi

# Test POP3 (port 110)
echo -n "  POP3 (110): "
if nc -z -w2 ${MAIL_SERVER_FQDN} 110 2>/dev/null; then
    echo -e "${GREEN}OPEN${NC}"
else
    echo -e "${RED}CLOSED${NC}"
fi

#-------------------------------------------------------------------------------
# Step 4: Create account configuration reference
#-------------------------------------------------------------------------------
log_step "Creating account configuration reference..."

THUNDERBIRD_CONFIG="/home/student/thunderbird-setup.txt"

cat > ${THUNDERBIRD_CONFIG} << EOF
===============================================================================
NSSA221 Lab 06 - Thunderbird Email Configuration
===============================================================================

MAIL SERVER SETTINGS
--------------------
Incoming Server (IMAP):
  Server:   ${MAIL_SERVER_FQDN}
  Port:     143
  Security: None (or STARTTLS if available)
  Auth:     Normal password

Outgoing Server (SMTP):
  Server:   ${MAIL_SERVER_FQDN}
  Port:     25
  Security: None (or STARTTLS if available)
  Auth:     Normal password

ACCOUNT SETUP STEPS
-------------------
1. Launch Thunderbird from Applications menu
2. If setup wizard doesn't appear:
   - Right-click "Local Folders" > Settings
   - Click "Account Actions" > "Add Mail Account"
3. Enter your information:
   - Your name: (e.g., Star Lord)
   - Email address: ${EMAIL_ADDRESS}
   - Password: (the password set in MailEnable)
4. Thunderbird should auto-detect settings
5. If not, click "Manual Config" and enter:
   - Incoming: IMAP, ${MAIL_SERVER_FQDN}, 143
   - Outgoing: SMTP, ${MAIL_SERVER_FQDN}, 25
6. Accept security warning (no TLS configured)
7. Click "Done" to complete setup

TROUBLESHOOTING
---------------
If connection fails:
1. Verify DNS: nslookup ${MAIL_SERVER_FQDN}
2. Test ping: ping ${MAIL_SERVER_FQDN}
3. Check ports: nc -zv ${MAIL_SERVER_FQDN} 25
                nc -zv ${MAIL_SERVER_FQDN} 143
4. Check firewall on mail server
5. Verify account exists in MailEnable

Generated: $(date)
EOF

chown student:student ${THUNDERBIRD_CONFIG}
log_info "Configuration reference saved to: ${THUNDERBIRD_CONFIG}"

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "Thunderbird Installation Complete"
echo "=========================================="
echo ""
echo "Mail Server: ${MAIL_SERVER_FQDN}"
echo "Domain: ${DOMAIN}"
echo ""
echo "Configuration reference: ${THUNDERBIRD_CONFIG}"
echo ""
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Log in as 'student' user"
echo "2. Launch Thunderbird: Activities > Thunderbird"
echo "3. Follow the setup wizard to add email account"
echo "4. Use settings from: ${THUNDERBIRD_CONFIG}"
echo ""
echo "=========================================="
echo "Screenshot Info (for lab report)"
echo "=========================================="
echo ""
echo "Figure 9 - Received Email on Linux Client:"
echo "  - Show Thunderbird with received email visible"
echo "  - Email should be from another account (e.g., gamora@${DOMAIN})"
echo ""
log_info "Thunderbird setup complete!"
