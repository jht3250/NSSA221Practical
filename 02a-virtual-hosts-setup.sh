#!/bin/bash
#===============================================================================
# NSSA221 Lab 06 - Activity 2: Virtual Web Servers Setup
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
DOMAIN="yourid.com"                     # Your RIT ID domain (e.g., abc1234.com)
VHOST1_PREFIX="starlord"                # First virtual host prefix
VHOST2_PREFIX="gamora"                  # Second virtual host prefix
VHOSTS_BASE_DIR="/www/virtualhosts"     # Base directory for virtual hosts
WEB_SERVER_IP="192.168.10.X"            # IP of your web server (for /etc/hosts)

# Derived variables
VHOST1_FQDN="${VHOST1_PREFIX}.${DOMAIN}"
VHOST2_FQDN="${VHOST2_PREFIX}.${DOMAIN}"
DEFAULT_FQDN="www.${DOMAIN}"

#-------------------------------------------------------------------------------
# Pre-flight checks
#-------------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

if ! systemctl is-active --quiet httpd; then
    log_error "Apache httpd is not running. Run 01-apache-basic-setup.sh first"
    exit 1
fi

log_info "Starting Virtual Web Servers configuration..."
echo "Domain: $DOMAIN"
echo "Virtual Host 1: $VHOST1_FQDN"
echo "Virtual Host 2: $VHOST2_FQDN"
echo "Default Site: $DEFAULT_FQDN"
echo ""

#-------------------------------------------------------------------------------
# Step 1: Create directory structure for virtual hosts
#-------------------------------------------------------------------------------
log_step "Creating directory structure..."

mkdir -p "${VHOSTS_BASE_DIR}/${VHOST1_FQDN}"
mkdir -p "${VHOSTS_BASE_DIR}/${VHOST2_FQDN}"

# Set proper ownership
chown -R apache:apache "${VHOSTS_BASE_DIR}"
chmod -R 755 "${VHOSTS_BASE_DIR}"

log_info "Created directories:"
echo "  - ${VHOSTS_BASE_DIR}/${VHOST1_FQDN}"
echo "  - ${VHOSTS_BASE_DIR}/${VHOST2_FQDN}"

#-------------------------------------------------------------------------------
# Step 2: Add Directory directive to httpd.conf
#-------------------------------------------------------------------------------
log_step "Adding Directory directive to httpd.conf..."

# Check if directive already exists
if ! grep -q "${VHOSTS_BASE_DIR}" /etc/httpd/conf/httpd.conf; then
    cat >> /etc/httpd/conf/httpd.conf << EOF

# Virtual Hosts Directory - Added by NSSA221 Lab 06 Script
<Directory "${VHOSTS_BASE_DIR}">
    AllowOverride None
    Require all granted
</Directory>
EOF
    log_info "Added Directory directive to httpd.conf"
else
    log_warn "Directory directive already exists in httpd.conf"
fi

#-------------------------------------------------------------------------------
# Step 3: Create Virtual Host 1 configuration
#-------------------------------------------------------------------------------
log_step "Creating configuration for ${VHOST1_FQDN}..."

cat > "/etc/httpd/conf.d/${VHOST1_FQDN}.conf" << EOF
# Virtual Host Configuration for ${VHOST1_FQDN}
# Created by NSSA221 Lab 06 Script

<VirtualHost *:80>
    ServerName ${VHOST1_FQDN}
    ServerAlias ${VHOST1_PREFIX}
    DocumentRoot ${VHOSTS_BASE_DIR}/${VHOST1_FQDN}
    
    ErrorLog /var/log/httpd/${VHOST1_PREFIX}_error.log
    CustomLog /var/log/httpd/${VHOST1_PREFIX}_access.log combined
    
    <Directory "${VHOSTS_BASE_DIR}/${VHOST1_FQDN}">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

log_info "Created /etc/httpd/conf.d/${VHOST1_FQDN}.conf"

#-------------------------------------------------------------------------------
# Step 4: Create Virtual Host 2 configuration
#-------------------------------------------------------------------------------
log_step "Creating configuration for ${VHOST2_FQDN}..."

cat > "/etc/httpd/conf.d/${VHOST2_FQDN}.conf" << EOF
# Virtual Host Configuration for ${VHOST2_FQDN}
# Created by NSSA221 Lab 06 Script

<VirtualHost *:80>
    ServerName ${VHOST2_FQDN}
    ServerAlias ${VHOST2_PREFIX}
    DocumentRoot ${VHOSTS_BASE_DIR}/${VHOST2_FQDN}
    
    ErrorLog /var/log/httpd/${VHOST2_PREFIX}_error.log
    CustomLog /var/log/httpd/${VHOST2_PREFIX}_access.log combined
    
    <Directory "${VHOSTS_BASE_DIR}/${VHOST2_FQDN}">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

log_info "Created /etc/httpd/conf.d/${VHOST2_FQDN}.conf"

#-------------------------------------------------------------------------------
# Step 5: Create Default Site configuration
#-------------------------------------------------------------------------------
log_step "Creating default site configuration..."

cat > "/etc/httpd/conf.d/_default_.conf" << EOF
# Default Virtual Host Configuration
# Created by NSSA221 Lab 06 Script
# This catches all requests that don't match other virtual hosts

<VirtualHost _default_:80>
    ServerName ${DEFAULT_FQDN}
    ServerAlias www
    DocumentRoot /var/www/html
    
    ErrorLog /var/log/httpd/default_error.log
    CustomLog /var/log/httpd/default_access.log combined
</VirtualHost>
EOF

log_info "Created /etc/httpd/conf.d/_default_.conf"

#-------------------------------------------------------------------------------
# Step 6: Create index.html for Virtual Host 1
#-------------------------------------------------------------------------------
log_step "Creating index.html for ${VHOST1_FQDN}..."

cat > "${VHOSTS_BASE_DIR}/${VHOST1_FQDN}/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${VHOST1_PREFIX^} - Virtual Host</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            margin: 0;
        }
        .container {
            background: white;
            padding: 40px 60px;
            border-radius: 10px;
            box-shadow: 0 15px 35px rgba(0,0,0,0.2);
            text-align: center;
        }
        h1 { color: #d63384; margin-bottom: 10px; }
        p { color: #666; }
        .badge {
            background: #f093fb;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            display: inline-block;
            margin-top: 15px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌟 ${VHOST1_PREFIX^}</h1>
        <p>Virtual Host Site - NSSA221 Lab 06</p>
        <p><strong>URL:</strong> ${VHOST1_FQDN}</p>
        <span class="badge">Virtual Host #1</span>
    </div>
</body>
</html>
EOF

#-------------------------------------------------------------------------------
# Step 7: Create index.html for Virtual Host 2
#-------------------------------------------------------------------------------
log_step "Creating index.html for ${VHOST2_FQDN}..."

cat > "${VHOSTS_BASE_DIR}/${VHOST2_FQDN}/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${VHOST2_PREFIX^} - Virtual Host</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            margin: 0;
        }
        .container {
            background: white;
            padding: 40px 60px;
            border-radius: 10px;
            box-shadow: 0 15px 35px rgba(0,0,0,0.2);
            text-align: center;
        }
        h1 { color: #0d6efd; margin-bottom: 10px; }
        p { color: #666; }
        .badge {
            background: #4facfe;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            display: inline-block;
            margin-top: 15px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌌 ${VHOST2_PREFIX^}</h1>
        <p>Virtual Host Site - NSSA221 Lab 06</p>
        <p><strong>URL:</strong> ${VHOST2_FQDN}</p>
        <span class="badge">Virtual Host #2</span>
    </div>
</body>
</html>
EOF

#-------------------------------------------------------------------------------
# Step 8: Set permissions
#-------------------------------------------------------------------------------
log_step "Setting proper permissions..."
chown -R apache:apache "${VHOSTS_BASE_DIR}"
chmod -R 755 "${VHOSTS_BASE_DIR}"

#-------------------------------------------------------------------------------
# Step 9: Update /etc/hosts for local testing
#-------------------------------------------------------------------------------
log_step "Updating /etc/hosts for local testing..."

# Remove old entries if they exist
sed -i "/${DOMAIN}/d" /etc/hosts

# Add new entries
cat >> /etc/hosts << EOF

# NSSA221 Lab 06 - Virtual Hosts (local testing)
127.0.0.1   ${DEFAULT_FQDN} www
127.0.0.1   ${VHOST1_FQDN} ${VHOST1_PREFIX}
127.0.0.1   ${VHOST2_FQDN} ${VHOST2_PREFIX}
EOF

log_info "Updated /etc/hosts"

#-------------------------------------------------------------------------------
# Step 10: Test Apache configuration and restart
#-------------------------------------------------------------------------------
log_step "Testing Apache configuration..."

if apachectl configtest 2>&1 | grep -q "Syntax OK"; then
    log_info "Apache configuration syntax is OK"
    
    log_step "Restarting Apache..."
    systemctl restart httpd
    log_info "Apache restarted successfully"
else
    log_error "Apache configuration has errors!"
    apachectl configtest
    exit 1
fi

#-------------------------------------------------------------------------------
# Summary and verification
#-------------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "Virtual Web Servers Configuration Summary"
echo "=========================================="
echo ""
echo "Configuration Files Created:"
echo "  - /etc/httpd/conf.d/${VHOST1_FQDN}.conf"
echo "  - /etc/httpd/conf.d/${VHOST2_FQDN}.conf"
echo "  - /etc/httpd/conf.d/_default_.conf"
echo ""
echo "Document Roots:"
echo "  - Default:  /var/www/html"
echo "  - VHost 1:  ${VHOSTS_BASE_DIR}/${VHOST1_FQDN}"
echo "  - VHost 2:  ${VHOSTS_BASE_DIR}/${VHOST2_FQDN}"
echo ""
echo "Local Testing URLs:"
echo "  - http://${DEFAULT_FQDN}"
echo "  - http://${VHOST1_FQDN}"
echo "  - http://${VHOST2_FQDN}"
echo ""
echo "=========================================="
echo "IMPORTANT: DNS Configuration Required!"
echo "=========================================="
echo ""
echo "Run the following PowerShell script on Windows Server"
echo "to create the required DNS records:"
echo ""
echo "  02b-dns-records.ps1"
echo ""
log_info "Virtual web servers setup complete!"
