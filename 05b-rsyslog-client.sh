#!/bin/bash
#===============================================================================
# NSSA221 Lab 06 - Activity 8: Rsyslog Client Configuration
# Run as root on Rocky Linux (client to send logs to central server)
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
LOG_SERVER_IP="192.168.10.X"            # IP of your central log server
LOG_SERVER_PORT="514"

#-------------------------------------------------------------------------------
# Pre-flight checks
#-------------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

if [[ "$LOG_SERVER_IP" == "192.168.10.X" ]]; then
    log_error "Please edit this script and set LOG_SERVER_IP to your log server's IP"
    exit 1
fi

log_info "Configuring rsyslog client to send logs to ${LOG_SERVER_IP}..."
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
# Step 3: Configure rsyslog to forward logs
#-------------------------------------------------------------------------------
log_step "Configuring rsyslog to forward logs to ${LOG_SERVER_IP}..."

# Remove any existing forwarding rules
sed -i '/# NSSA221 Remote Logging/d' /etc/rsyslog.conf
sed -i '/\*\.\* @@\?[0-9]/d' /etc/rsyslog.conf

# Add forwarding rule at the end of the file
# Using @@ for TCP (more reliable) - use @ for UDP
cat >> /etc/rsyslog.conf << EOF

# NSSA221 Remote Logging - Forward all logs to central server
*.* @@${LOG_SERVER_IP}:${LOG_SERVER_PORT}
EOF

log_info "Added log forwarding rule to rsyslog.conf"

#-------------------------------------------------------------------------------
# Step 4: Restart rsyslog service
#-------------------------------------------------------------------------------
log_step "Restarting rsyslog service..."

systemctl restart rsyslog

if systemctl is-active --quiet rsyslog; then
    log_info "rsyslog is running"
else
    log_error "rsyslog failed to start"
    journalctl -u rsyslog --no-pager -n 20
    exit 1
fi

#-------------------------------------------------------------------------------
# Step 5: Test connectivity to log server
#-------------------------------------------------------------------------------
log_step "Testing connectivity to log server..."

echo -n "  Ping test: "
if ping -c 2 ${LOG_SERVER_IP} > /dev/null 2>&1; then
    echo -e "${GREEN}SUCCESS${NC}"
else
    echo -e "${RED}FAILED${NC}"
    log_warn "Cannot ping log server - check network configuration"
fi

echo -n "  Port test (TCP 514): "
if nc -z -w2 ${LOG_SERVER_IP} ${LOG_SERVER_PORT} 2>/dev/null; then
    echo -e "${GREEN}OPEN${NC}"
else
    echo -e "${RED}CLOSED${NC}"
    log_warn "Port 514 is not reachable - check firewall on log server"
fi

#-------------------------------------------------------------------------------
# Step 6: Send test message
#-------------------------------------------------------------------------------
log_step "Sending test message to central log server..."

TEST_MESSAGE="NSSA221-Lab06-Test from $(hostname) at $(date '+%Y-%m-%d %H:%M:%S')"
logger -t NSSA221 "${TEST_MESSAGE}"

log_info "Test message sent: ${TEST_MESSAGE}"

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "Rsyslog Client Configuration Complete"
echo "=========================================="
echo ""
echo "Client Hostname: $(hostname)"
echo "Client IP: $(hostname -I | awk '{print $1}')"
echo "Log Server: ${LOG_SERVER_IP}:${LOG_SERVER_PORT}"
echo ""
echo "=========================================="
echo "Verification Steps"
echo "=========================================="
echo ""
echo "On the LOG SERVER (${LOG_SERVER_IP}), run:"
echo "  tail -f /var/log/messages"
echo ""
echo "On THIS CLIENT, send a test message:"
echo "  logger -t NSSA221 'Hello from $(hostname)'"
echo ""
echo "=========================================="
echo "Screenshot Commands (for lab report)"
echo "=========================================="
echo ""
echo "# Figure 12 - Rsyslog Message Verification:"
echo "# Run on LOG SERVER:"
echo "tail -f /var/log/messages | grep NSSA221"
echo ""
echo "# Figure 14 - Wireshark capture:"
echo "# Filter: syslog or port 514"
echo ""
log_info "Rsyslog client configuration complete!"
