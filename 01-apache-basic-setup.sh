#!/bin/bash
#===============================================================================
# NSSA221 Lab 06 - Activity 1: Basic Apache Web Server Setup
# Run as root on Rocky Linux
#===============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }


DOMAIN="jht3250.com"
WEB_SERVER_HOSTNAME="web01"            


if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

log_info "Starting Apache web server installation..."


log_info "Setting SELinux to permissive mode..."
setenforce 0 2>/dev/null || true
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

log_info "Installing Apache httpd..."
dnf install -y httpd

#-------------------------------------------------------------------------------
# Start and enable httpd service
#-------------------------------------------------------------------------------
log_info "Starting and enabling httpd service..."
systemctl start httpd
systemctl enable httpd


log_info "Configuring firewall for HTTP traffic..."
firewall-cmd --permanent --add-service=http
firewall-cmd --reload


log_info "Creating default index.html..."
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NSSA221 - Default Apache Site</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
        h1 { color: #333; margin-bottom: 10px; }
        p { color: #666; }
        .server-info {
            background: #f5f5f5;
            padding: 15px;
            border-radius: 5px;
            margin-top: 20px;
            font-family: monospace;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1> Apache Web Server</h1>
        <p>NSSA221 Systems Administration I - Lab 06</p>
        <div class="server-info">
            <p><strong>Default Site Successfully Configured!</strong></p>
        </div>
    </div>
</body>
</html>
EOF

log_info "Verifying Apache installation..."
echo ""
echo "=========================================="
echo "Apache Installation Summary"
echo "=========================================="
echo "Hostname: $(hostname)"
echo "IP Address(es): $(hostname -I)"
echo "httpd Status: $(systemctl is-active httpd)"
echo "httpd Enabled: $(systemctl is-enabled httpd)"
echo ""

# Test if Apache responds
if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
    log_info "Apache is responding correctly on localhost"
else
    log_warn "Apache may not be responding - check configuration"
fi

echo ""
log_info "Basic Apache setup complete!"
log_info "Open a browser and navigate to http://localhost to verify"
echo ""
echo "=========================================="
echo "Screenshot Commands (for lab report):"
echo "=========================================="
echo "hostname; hostname -I"
echo "Then open browser to http://localhost"
