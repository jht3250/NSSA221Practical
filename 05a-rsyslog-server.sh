#!/bin/bash
#===============================================================================
# NSSA221 Lab 06 - Activity 8: Rsyslog Central Log Server Setup
# Run as root on Rocky Linux (designated as log server)
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
# Pre-flight checks
#-------------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

log_info "Configuring this server as a Central Rsyslog Server..."
echo ""

#-------------------------------------------------------------------------------
# Step 1: Verify rsyslog is installed
#-------------------------------------------------------------------------------
log_step "Checking rsyslog installation..."

if rpm -qa rsyslog | grep -q rsyslog; then
    log_info "rsyslog is installed: $(rpm -qa rsyslog)"
else
    log_info "Installing rsyslog..."
    dnf install -y rsyslog
fi

#-------------------------------------------------------------------------------
# Step 2: Backup original configuration
#-------------------------------------------------------------------------------
log_step "Backing up original rsyslog.conf..."

if [[ ! -f /etc/rsyslog.conf.backup ]]; then
    cp /etc/rsyslog.conf /etc/rsyslog.conf.backup
    log_info "Backup created: /etc/rsyslog.conf.backup"
else
    log_warn "Backup already exists"
fi

#-------------------------------------------------------------------------------
# Step 3: Configure rsyslog to receive logs via UDP and TCP
#-------------------------------------------------------------------------------
log_step "Configuring rsyslog for remote log reception..."

# Enable UDP syslog reception
sed -i 's/#module(load="imudp")/module(load="imudp")/' /etc/rsyslog.conf
sed -i 's/#input(type="imudp" port="514")/input(type="imudp" port="514")/' /etc/rsyslog.conf

# Enable TCP syslog reception
sed -i 's/#module(load="imtcp")/module(load="imtcp")/' /etc/rsyslog.conf
sed -i 's/#input(type="imtcp" port="514")/input(type="imtcp" port="514")/' /etc/rsyslog.conf

log_info "Enabled UDP and TCP log reception on port 514"

#-------------------------------------------------------------------------------
# Step 4: Create template for remote logs (optional but useful)
#-------------------------------------------------------------------------------
log_step "Adding remote log template..."

# Check if template already added
if ! grep -q "RemoteLogs" /etc/rsyslog.conf; then
    cat >> /etc/rsyslog.conf << 'EOF'

# Template for remote logs - Added by NSSA221 Lab 06 Script
$template RemoteLogs,"/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& stop
EOF
    log_info "Added remote logs template"
else
    log_warn "Remote logs template already exists"
fi

# Create remote logs directory
mkdir -p /var/log/remote
chmod 755 /var/log/remote

#-------------------------------------------------------------------------------
# Step 5: Configure firewall
#-------------------------------------------------------------------------------
log_step "Configuring firewall for rsyslog..."

# Enable firewall if not running
if ! systemctl is-active --quiet firewalld; then
    systemctl start firewalld
    systemctl enable firewalld
fi

# Add rules for syslog port 514 (UDP and TCP)
firewall-cmd --permanent --add-port=514/udp
firewall-cmd --permanent --add-port=514/tcp
firewall-cmd --reload

log_info "Firewall rules added for port 514 (UDP and TCP)"

#-------------------------------------------------------------------------------
# Step 6: Set SELinux context (if enabled)
#-------------------------------------------------------------------------------
log_step "Configuring SELinux for rsyslog..."

if command -v semanage &> /dev/null; then
    semanage port -a -t syslogd_port_t -p udp 514 2>/dev/null || true
    semanage port -a -t syslogd_port_t -p tcp 514 2>/dev/null || true
    log_info "SELinux port context configured"
else
    log_warn "semanage not found - SELinux may block remote logging"
fi

#-------------------------------------------------------------------------------
# Step 7: Restart rsyslog service
#-------------------------------------------------------------------------------
log_step "Restarting rsyslog service..."

systemctl restart rsyslog
systemctl enable rsyslog

if systemctl is-active --quiet rsyslog; then
    log_info "rsyslog is running"
else
    log_error "rsyslog failed to start"
    journalctl -u rsyslog --no-pager -n 20
    exit 1
fi

#-------------------------------------------------------------------------------
# Step 8: Verify configuration
#-------------------------------------------------------------------------------
log_step "Verifying configuration..."

echo ""
echo "Listening ports:"
ss -tulnp | grep 514

echo ""
echo "rsyslog status:"
systemctl status rsyslog --no-pager

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "Central Log Server Configuration Complete"
echo "=========================================="
echo ""
echo "Server Hostname: $(hostname)"
echo "Server IP: $(hostname -I | awk '{print $1}')"
echo "Listening Port: 514 (UDP and TCP)"
echo ""
echo "Remote logs will be stored in: /var/log/remote/<hostname>/"
echo ""
echo "=========================================="
echo "Client Configuration"
echo "=========================================="
echo ""
echo "Run 05b-rsyslog-client.sh on remote clients"
echo "Or manually add to client's /etc/rsyslog.conf:"
echo ""
echo "  *.* @$(hostname -I | awk '{print $1}'):514    # UDP"
echo "  *.* @@$(hostname -I | awk '{print $1}'):514   # TCP"
echo ""
echo "=========================================="
echo "Testing Commands"
echo "=========================================="
echo ""
echo "Monitor incoming logs:"
echo "  tail -f /var/log/messages"
echo ""
echo "After client configuration, test with:"
echo "  logger -t NSSA221 'Test message from client'"
echo ""
log_info "Central log server setup complete!"
