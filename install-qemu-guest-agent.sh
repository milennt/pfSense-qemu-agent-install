#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

# Function to display messages
log() {
    echo "[`date '+%Y-%m-%d %H:%M:%S'`] $1"
}

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    log "This script must be run as root."
    exit 1
fi

log "Starting qemu-guest-agent installation and configuration..."

# Update the package repository to ensure the latest package list
log "Updating package repository..."
pkg update -f > /dev/null

# Install qemu-guest-agent package silently
log "Installing qemu-guest-agent package..."
pkg install -y qemu-guest-agent > /dev/null
log "qemu-guest-agent package installed successfully."

# Backup existing rc.conf.local if it exists
RC_CONF_LOCAL="/etc/rc.conf.local"
if [ -f "$RC_CONF_LOCAL" ]; then
    log "Backing up existing $RC_CONF_LOCAL to ${RC_CONF_LOCAL}.bak"
    cp "$RC_CONF_LOCAL" "${RC_CONF_LOCAL}.bak"
fi

# Configure qemu-guest-agent in rc.conf.local
log "Configuring qemu-guest-agent in $RC_CONF_LOCAL..."
cat >> "$RC_CONF_LOCAL" << EOF

# Enable QEMU Guest Agent
qemu_guest_agent_enable="YES"
qemu_guest_agent_flags="-d -v -l /var/log/qemu-ga.log"
# Uncomment the following line to enable virtio console
# virtio_console_load="YES"
EOF
log "Configuration added to $RC_CONF_LOCAL."

# Define the qemu-agent startup script path
AGENT_SCRIPT="/usr/local/etc/rc.d/qemu-agent.sh"

# Create or overwrite the qemu-agent startup script
log "Creating startup script at $AGENT_SCRIPT..."
cat > "$AGENT_SCRIPT" << EOF
#!/bin/sh
#
# PROVIDE: qemu-agent
# REQUIRE: NETWORKING
# BEFORE: LOGIN
# KEYWORD: shutdown

. /etc/rc.subr

name="qemu-agent"
rcvar="qemu_guest_agent_enable"

command="/usr/local/sbin/qemu-ga"
command_args="-d -v -l /var/log/qemu-ga.log"

load_rc_config \$name
run_rc_command "\$1"
EOF

# Make the startup script executable
chmod +x "$AGENT_SCRIPT"
log "Startup script $AGENT_SCRIPT is executable."

# Enable qemu-guest-agent service to start on boot
log "Enabling qemu-guest-agent service..."
service qemu-guest-agent enable

# Start the qemu-guest-agent service
log "Starting qemu-guest-agent service..."
service qemu-guest-agent start
log "qemu-guest-agent service started successfully."

log "qemu-guest-agent installation and configuration completed."
