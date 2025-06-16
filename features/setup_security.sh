#!/bin/bash

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Initialize
init_common
log_info "🔒 Security Hardening Script"
setup_logging "setup-security"

# Update system
log_step "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install security tools
log_step "Installing security tools..."
sudo apt install -y ufw fail2ban unattended-upgrades apt-listchanges

# Configure automatic security updates
log_step "Configuring automatic security updates..."
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

# Configure SSH security
log_step "Hardening SSH configuration..."
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

echo ""
echo "🔐 SSH Security Configuration"
echo "────────────────────────────"

read -rp "Enter new SSH port (default: $DEFAULT_SSH_PORT): " SSH_PORT
SSH_PORT=${SSH_PORT:-$DEFAULT_SSH_PORT}

echo ""
echo "⚠️  Root Login Security:"
echo "   Disabling root login improves security but requires a sudo user"
echo "   Make sure you have a non-root user with sudo privileges!"
echo ""
read -rp "Disable root login? [y/N]: " DISABLE_ROOT_INPUT
case "${DISABLE_ROOT_INPUT,,}" in
    y|yes) DISABLE_ROOT_LOGIN=true ;;
    *) DISABLE_ROOT_LOGIN=false ;;
esac

sudo tee /etc/ssh/sshd_config > /dev/null <<EOF
# SSH Configuration - Security Hardened
Port $SSH_PORT
Protocol 2

# Authentication
PermitRootLogin $([ "$DISABLE_ROOT_LOGIN" = true ] && echo "no" || echo "yes")
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Security settings
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server

# Timeout and limits
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 10
LoginGraceTime 60

# Host-based authentication
HostbasedAuthentication no
IgnoreRhosts yes

# Logging
LogLevel VERBOSE
SyslogFacility AUTH
EOF

# Configure UFW firewall
log_step "Configuring UFW firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH on custom port
sudo ufw allow $SSH_PORT/tcp comment 'SSH'

# Allow common web ports
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Enable UFW
sudo ufw --force enable

# Configure Fail2Ban
log_step "Configuring Fail2Ban..."
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3
bantime = 3600

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 3
bantime = 3600

[php-url-fopen]
enabled = true
filter = php-url-fopen
logpath = /var/log/nginx/access.log
maxretry = 3
bantime = 3600
EOF

# Configure system limits
log_step "Setting system security limits..."
sudo tee /etc/security/limits.conf > /dev/null <<EOF
# System security limits
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
root soft nofile 65535
root hard nofile 65535
EOF

# Disable unnecessary services
log_step "Disabling unnecessary services..."
SERVICES_TO_DISABLE="avahi-daemon bluetooth cups"
for service in $SERVICES_TO_DISABLE; do
    if systemctl is-enabled $service &>/dev/null; then
        sudo systemctl disable $service
        sudo systemctl stop $service
        log_info "Disabled $service"
    fi
done

# Set up log monitoring
log_step "Setting up log monitoring..."
sudo tee /usr/local/bin/security-monitor > /dev/null <<EOF
#!/bin/bash
# Security monitoring script

LOG_FILE="/var/log/security-monitor.log"

# Check for failed SSH attempts
FAILED_SSH=\$(grep "Failed password" /var/log/auth.log | wc -l)
if [ \$FAILED_SSH -gt 10 ]; then
    echo "\$(date): High number of failed SSH attempts: \$FAILED_SSH" >> \$LOG_FILE
fi

# Check for new users
NEW_USERS=\$(grep "new user" /var/log/auth.log | tail -5)
if [ ! -z "\$NEW_USERS" ]; then
    echo "\$(date): New user accounts detected:" >> \$LOG_FILE
    echo "\$NEW_USERS" >> \$LOG_FILE
fi

# Check disk usage
DISK_USAGE=\$(df / | tail -1 | awk '{print \$5}' | sed 's/%//')
if [ \$DISK_USAGE -gt 90 ]; then
    echo "\$(date): Critical disk usage: \${DISK_USAGE}%" >> \$LOG_FILE
fi

# Check for unauthorized cron jobs
CRON_CHANGES=\$(find /var/spool/cron -newer /tmp/last_cron_check 2>/dev/null)
if [ ! -z "\$CRON_CHANGES" ]; then
    echo "\$(date): Cron changes detected: \$CRON_CHANGES" >> \$LOG_FILE
fi
touch /tmp/last_cron_check
EOF

sudo chmod +x /usr/local/bin/security-monitor

# Add to crontab
(crontab -l 2>/dev/null; echo "0 */6 * * * /usr/local/bin/security-monitor") | crontab -

# Restart services
log_step "Restarting security services..."
sudo systemctl restart ssh
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban

log_success "Security hardening completed!"

echo ""
echo "🔒 Security Summary:"
echo "SSH Port: $SSH_PORT"
echo "Root Login: $([ "$DISABLE_ROOT_LOGIN" = true ] && echo "Disabled" || echo "Enabled")"
echo "UFW Firewall: Enabled"
echo "Fail2Ban: Enabled"
echo "Auto Updates: Enabled"
echo "Security Monitoring: Enabled"
echo ""
log_warning "IMPORTANT: SSH is now on port $SSH_PORT"
log_warning "Make sure you can connect before closing this session!" 