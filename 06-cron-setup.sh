#!/bin/bash
#===============================================================================
# NSSA221 Lab 06 - Activity 9: Cron Service Setup
# Run as root on Rocky Linux (the rsyslog client)
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
# Configuration
#-------------------------------------------------------------------------------
CRON_MESSAGE="NSSA221-Lab06-CronJob from $(hostname)"

#-------------------------------------------------------------------------------
# Pre-flight checks
#-------------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

log_info "Setting up Cron job for remote logging..."
echo ""

#-------------------------------------------------------------------------------
# Step 1: Verify crond service is running
#-------------------------------------------------------------------------------
log_step "Checking crond service..."

if systemctl is-active --quiet crond; then
    log_info "crond is already running"
else
    log_info "Starting crond service..."
    systemctl start crond
    systemctl enable crond
fi

#-------------------------------------------------------------------------------
# Step 2: Create the cron job
#-------------------------------------------------------------------------------
log_step "Creating cron job to send log message every minute..."

# Create a temporary crontab file
CRON_ENTRY="* * * * * /usr/bin/logger -t NSSA221-CRON '${CRON_MESSAGE}'"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "NSSA221-CRON"; then
    log_warn "NSSA221 cron job already exists"
    log_info "Current crontab:"
    crontab -l
else
    # Add the cron job
    (crontab -l 2>/dev/null; echo "${CRON_ENTRY}") | crontab -
    log_info "Cron job added successfully"
fi

#-------------------------------------------------------------------------------
# Step 3: Verify cron job
#-------------------------------------------------------------------------------
log_step "Verifying cron job..."

echo ""
echo "Current crontab for root:"
echo "----------------------------------------"
crontab -l
echo "----------------------------------------"

#-------------------------------------------------------------------------------
# Step 4: Display cron job format explanation
#-------------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "Cron Job Format Reference"
echo "=========================================="
echo ""
echo "  * * * * * command"
echo "  │ │ │ │ │"
echo "  │ │ │ │ └─── Day of week (0-7, Sun=0 or 7)"
echo "  │ │ │ └───── Month (1-12)"
echo "  │ │ └─────── Day of month (1-31)"
echo "  │ └───────── Hour (0-23)"
echo "  └─────────── Minute (0-59)"
echo ""
echo "Your cron job:"
echo "  ${CRON_ENTRY}"
echo ""
echo "This runs every minute (* in all fields)"
echo ""

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------
echo "=========================================="
echo "Cron Job Setup Complete"
echo "=========================================="
echo ""
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo "Cron Job: Runs every minute"
echo "Message: ${CRON_MESSAGE}"
echo ""
echo "=========================================="
echo "Verification Steps"
echo "=========================================="
echo ""
echo "1. Wait 2-3 minutes for messages to be sent"
echo ""
echo "2. On the LOG SERVER, verify messages received:"
echo "   tail -f /var/log/messages | grep NSSA221-CRON"
echo ""
echo "=========================================="
echo "Screenshot Commands (for lab report)"
echo "=========================================="
echo ""
echo "# Figure 13 - Cronjob List Validation:"
echo "hostname; whoami; crontab -l"
echo ""
echo "# Figure 14 - Cronjob Message Verification (on LOG SERVER):"
echo "# Wait at least 2 minutes, then run:"
echo "tail -f /var/log/messages | grep NSSA221-CRON"
echo "# Should show messages with 1-minute intervals"
echo ""

#-------------------------------------------------------------------------------
# Create helper script for cleanup
#-------------------------------------------------------------------------------
cat > /root/remove-nssa221-cron.sh << 'EOF'
#!/bin/bash
# Remove NSSA221 cron job
crontab -l | grep -v "NSSA221-CRON" | crontab -
echo "NSSA221 cron job removed"
crontab -l
EOF
chmod +x /root/remove-nssa221-cron.sh

log_info "Cleanup script created: /root/remove-nssa221-cron.sh"
log_info "Run it when you're done with the lab to remove the cron job"
echo ""
log_info "Cron job setup complete!"
