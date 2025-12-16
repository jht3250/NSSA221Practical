#!/bin/bash
#===============================================================================
# NSSA221 Lab 06 - Activities 3 & 4: Self-Signed Certificate & TLS Configuration
# Run as root on Rocky Linux (web server)
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
WEB_SERVER_HOSTNAME="web01"             # Your web server hostname
WEB_SERVER_FQDN="${WEB_SERVER_HOSTNAME}.${DOMAIN}"

# Certificate details
CERT_COUNTRY="US"
CERT_STATE="New York"
CERT_LOCALITY="Rochester"
CERT_ORG="RIT"
CERT_OU="NSSA221"
CERT_EMAIL="student@rit.edu"

# File locations
KEY_DIR="/etc/pki/tls/private"
CERT_DIR="/etc/pki/tls/certs"
KEY_FILE="${KEY_DIR}/server.key"
CSR_FILE="${KEY_DIR}/server.csr"
CERT_FILE="${CERT_DIR}/server.crt"

# Passphrase for the key (CHANGE THIS!)
KEY_PASSPHRASE="nssa221lab06"

#-------------------------------------------------------------------------------
# Pre-flight checks
#-------------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

if ! systemctl is-active --quiet httpd; then
    log_error "Apache httpd is not running"
    exit 1
fi

log_info "Starting SSL/TLS Configuration for ${WEB_SERVER_FQDN}..."
echo ""

#-------------------------------------------------------------------------------
# Step 1: Install OpenSSL and mod_ssl
#-------------------------------------------------------------------------------
log_step "Installing OpenSSL and mod_ssl..."

dnf install -y openssl mod_ssl

log_info "OpenSSL version: $(openssl version)"

#-------------------------------------------------------------------------------
# Step 2: Create directories if they don't exist
#-------------------------------------------------------------------------------
log_step "Ensuring certificate directories exist..."

mkdir -p "$KEY_DIR"
mkdir -p "$CERT_DIR"

#-------------------------------------------------------------------------------
# Step 3: Generate Private Key
#-------------------------------------------------------------------------------
log_step "Generating RSA private key..."

# Generate key with passphrase
openssl genrsa -aes256 -passout pass:${KEY_PASSPHRASE} -out "${KEY_FILE}" 2048

chmod 600 "${KEY_FILE}"
log_info "Private key created: ${KEY_FILE}"

#-------------------------------------------------------------------------------
# Step 4: Generate Certificate Signing Request (CSR)
#-------------------------------------------------------------------------------
log_step "Generating Certificate Signing Request (CSR)..."

openssl req -new \
    -key "${KEY_FILE}" \
    -passin pass:${KEY_PASSPHRASE} \
    -out "${CSR_FILE}" \
    -subj "/C=${CERT_COUNTRY}/ST=${CERT_STATE}/L=${CERT_LOCALITY}/O=${CERT_ORG}/OU=${CERT_OU}/CN=${WEB_SERVER_FQDN}/emailAddress=${CERT_EMAIL}"

log_info "CSR created: ${CSR_FILE}"

#-------------------------------------------------------------------------------
# Step 5: Generate Self-Signed Certificate
#-------------------------------------------------------------------------------
log_step "Generating self-signed certificate (valid for 365 days)..."

openssl x509 -req \
    -days 365 \
    -in "${CSR_FILE}" \
    -signkey "${KEY_FILE}" \
    -passin pass:${KEY_PASSPHRASE} \
    -out "${CERT_FILE}"

chmod 644 "${CERT_FILE}"
log_info "Certificate created: ${CERT_FILE}"

#-------------------------------------------------------------------------------
# Step 6: Update ssl.conf with certificate locations
#-------------------------------------------------------------------------------
log_step "Updating ssl.conf with certificate paths..."

# Backup original ssl.conf
cp /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.backup

# Update certificate file location
sed -i "s|^SSLCertificateFile.*|SSLCertificateFile ${CERT_FILE}|" /etc/httpd/conf.d/ssl.conf

# Update key file location
sed -i "s|^SSLCertificateKeyFile.*|SSLCertificateKeyFile ${KEY_FILE}|" /etc/httpd/conf.d/ssl.conf

log_info "Updated ssl.conf with new certificate paths"

#-------------------------------------------------------------------------------
# Step 7: Create Secure Virtual Host Configuration
#-------------------------------------------------------------------------------
log_step "Creating secure virtual host configuration..."

cat > "/etc/httpd/conf.d/ssl-vhost.conf" << EOF
# Secure Virtual Host Configuration
# Created by NSSA221 Lab 06 Script

<VirtualHost *:443>
    ServerName ${WEB_SERVER_FQDN}
    ServerAlias www.${DOMAIN}
    DocumentRoot /var/www/html
    
    # SSL Configuration
    SSLEngine on
    SSLCertificateFile ${CERT_FILE}
    SSLCertificateKeyFile ${KEY_FILE}
    
    # SSL Protocol Settings (disable older protocols)
    SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite HIGH:!aNULL:!MD5
    
    # Logging
    ErrorLog /var/log/httpd/ssl_error.log
    CustomLog /var/log/httpd/ssl_access.log combined
    
    <Directory "/var/www/html">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

log_info "Created /etc/httpd/conf.d/ssl-vhost.conf"

#-------------------------------------------------------------------------------
# Step 8: Update default index.html with HTTPS indicator
#-------------------------------------------------------------------------------
log_step "Updating default index.html for HTTPS..."

cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NSSA221 - Secure Apache Site</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
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
        h1 { color: #11998e; margin-bottom: 10px; }
        p { color: #666; }
        .secure-badge {
            background: #11998e;
            color: white;
            padding: 10px 20px;
            border-radius: 25px;
            display: inline-block;
            margin-top: 15px;
        }
        .lock-icon { font-size: 48px; margin-bottom: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="lock-icon">🔒</div>
        <h1>Secure Web Server</h1>
        <p>NSSA221 Systems Administration I - Lab 06</p>
        <p>TLS/SSL Encryption Active</p>
        <span class="secure-badge">HTTPS Enabled</span>
    </div>
</body>
</html>
EOF

#-------------------------------------------------------------------------------
# Step 9: Configure firewall for HTTPS
#-------------------------------------------------------------------------------
log_step "Configuring firewall for HTTPS traffic..."

firewall-cmd --permanent --add-service=https
firewall-cmd --reload

log_info "Firewall updated to allow HTTPS (port 443)"

#-------------------------------------------------------------------------------
# Step 10: Create systemd override for passphrase
#-------------------------------------------------------------------------------
log_step "Creating passphrase script for Apache startup..."

# Create a script to provide the passphrase
cat > /etc/httpd/conf.d/ssl-passphrase.sh << EOF
#!/bin/bash
echo "${KEY_PASSPHRASE}"
EOF

chmod 700 /etc/httpd/conf.d/ssl-passphrase.sh

# Update ssl.conf to use the passphrase script
if ! grep -q "SSLPassPhraseDialog" /etc/httpd/conf.d/ssl.conf; then
    sed -i '1i SSLPassPhraseDialog exec:/etc/httpd/conf.d/ssl-passphrase.sh' /etc/httpd/conf.d/ssl.conf
fi

log_info "Passphrase automation configured"

#-------------------------------------------------------------------------------
# Step 11: Test Apache configuration and restart
#-------------------------------------------------------------------------------
log_step "Testing Apache configuration..."

if apachectl configtest 2>&1 | grep -q "Syntax OK"; then
    log_info "Apache configuration syntax is OK"
    
    log_step "Restarting Apache (passphrase will be provided automatically)..."
    systemctl restart httpd
    
    # Check if Apache started successfully
    sleep 2
    if systemctl is-active --quiet httpd; then
        log_info "Apache restarted successfully with SSL"
    else
        log_error "Apache failed to start. Check logs: journalctl -u httpd"
        exit 1
    fi
else
    log_error "Apache configuration has errors!"
    apachectl configtest
    exit 1
fi

#-------------------------------------------------------------------------------
# Display certificate information
#-------------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "Certificate Information"
echo "=========================================="
echo ""
openssl x509 -text -noout -in "${CERT_FILE}" | head -30

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "SSL/TLS Configuration Summary"
echo "=========================================="
echo ""
echo "Private Key:    ${KEY_FILE}"
echo "CSR File:       ${CSR_FILE}"
echo "Certificate:    ${CERT_FILE}"
echo "Passphrase:     ${KEY_PASSPHRASE}"
echo ""
echo "SSL Config:     /etc/httpd/conf.d/ssl.conf"
echo "VHost Config:   /etc/httpd/conf.d/ssl-vhost.conf"
echo ""
echo "Test URLs:"
echo "  Local:  https://localhost"
echo "  FQDN:   https://${WEB_SERVER_FQDN}"
echo ""
echo "=========================================="
echo "Screenshot Commands (for lab report)"
echo "=========================================="
echo ""
echo "# Figure 6 - Certificate Verification:"
echo "date; hostname; openssl x509 -text -noout -in ${CERT_FILE}"
echo ""
echo "# Figure 8 - SSL Virtual Host File:"
echo "hostname; hostname -I; ls -l /etc/httpd/conf.d/ssl-vhost.conf"
echo "cat /etc/httpd/conf.d/ssl-vhost.conf"
echo ""
log_info "SSL/TLS configuration complete!"
log_warn "Note: Browser will show security warning for self-signed certificate - this is expected"
