#!/bin/bash

# Common Library for Server Automation Scripts
# This file contains all shared functions and configurations

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Configuration defaults
readonly DEFAULT_PHP_VERSION="8.3"
readonly DEFAULT_NODE_VERSION="20"
readonly DEFAULT_SSH_PORT=22
readonly DEFAULT_MEMORY_LIMIT="512M"
readonly DEFAULT_UPLOAD_SIZE="100M"
readonly DEFAULT_EXECUTION_TIME=300
readonly LOG_RETENTION_DAYS=30

# Logging functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "${PURPLE}🔄 $1${NC}"; }

# Setup logging for installations
setup_logging() {
    local script_name="$1"
    export SETUP_LOG="/var/log/${script_name}-$(date +%Y%m%d-%H%M%S).log"
    sudo mkdir -p "$(dirname "$SETUP_LOG")"
    log_info "📝 Logging to: $SETUP_LOG"
}

log_to_file() {
    if [ -n "$SETUP_LOG" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$SETUP_LOG" >/dev/null
    fi
}

# Error handling
handle_error() {
    local exit_code=$?
    log_error "Command failed with exit code $exit_code"
    log_to_file "ERROR: Command failed with exit code $exit_code"
    exit $exit_code
}

# Set error handling
set_error_handling() {
    set -e
    trap handle_error ERR
}

# System update function
update_system() {
    log_step "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    log_to_file "System packages updated"
}

# Install packages function
install_packages() {
    local packages="$*"
    log_step "Installing packages: $packages"
    sudo apt install -y $packages
    log_to_file "Installed packages: $packages"
}

# Service management functions
enable_service() {
    local service="$1"
    sudo systemctl enable "$service"
    sudo systemctl start "$service"
    log_success "$service enabled and started"
    log_to_file "Service enabled: $service"
}

restart_service() {
    local service="$1"
    sudo systemctl restart "$service"
    log_success "$service restarted"
    log_to_file "Service restarted: $service"
}

check_service() {
    local service="$1"
    local name="${2:-$service}"
    if systemctl is-active --quiet "$service"; then
        log_success "$name is running"
        return 0
    else
        log_error "$name is not running"
        return 1
    fi
}

# File operations
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        sudo cp "$file" "${file}.backup.$(date +%Y%m%d)"
        log_info "Backed up $file"
    fi
}

create_directory() {
    local dir="$1"
    local owner="${2:-root:root}"
    local permissions="${3:-755}"
    
    sudo mkdir -p "$dir"
    sudo chown "$owner" "$dir"
    sudo chmod "$permissions" "$dir"
    log_info "Created directory: $dir"
}

# Configuration file operations
configure_file() {
    local file="$1"
    local search="$2"
    local replace="$3"
    
    if [ -f "$file" ]; then
        sudo sed -i "s|$search|$replace|g" "$file"
        log_info "Configured $file"
    else
        log_warning "Configuration file $file not found"
    fi
}

# User input with defaults
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    read -rp "$prompt (default: $default): " input
    eval "$var_name=\${input:-$default}"
}

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    
    read -rp "$prompt (y/n, default: $default): " response
    case "${response:-$default}" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

# Component installation wrapper
install_component() {
    local component="$1"
    local script_path="features/install_${component}.sh"
    
    if [ "$component" = "certbot" ]; then
        script_path="features/install_certbot.sh"
    elif [ "$component" = "fail2ban" ]; then
        script_path="features/install_fail2ban.sh"
    elif [ "$component" = "docker" ]; then
        script_path="features/install_docker.sh"
    elif [ "$component" = "logrotate" ]; then
        script_path="features/setup_logrotate.sh"
    fi
    
    if [ -f "$script_path" ]; then
        log_step "Installing $component..."
        log_to_file "Starting installation of $component"
        
        # Show real-time output to terminal AND log it
        bash "$script_path" 2>&1 | sudo tee -a "$SETUP_LOG"
        local exit_code=${PIPESTATUS[0]}
        
        if [ $exit_code -eq 0 ]; then
            log_success "$component installed successfully"
            log_to_file "Successfully installed $component"
        else
            log_error "$component installation failed (exit code: $exit_code)"
            log_to_file "ERROR: Failed to install $component (exit code: $exit_code)"
            return $exit_code
        fi
    else
        log_warning "Installation script for $component not found at $script_path"
        log_to_file "WARNING: Installation script for $component not found"
        return 1
    fi
}

# Security functions
setup_firewall() {
    local ssh_port="${1:-22}"
    
    log_step "Configuring UFW firewall..."
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow "$ssh_port/tcp" comment 'SSH'
    sudo ufw allow 80/tcp comment 'HTTP'
    sudo ufw allow 443/tcp comment 'HTTPS'
    sudo ufw --force enable
    log_success "Firewall configured"
}

setup_monitoring() {
    local domain="$1"
    local log_dir="/var/log/laravel/$domain"
    
    create_directory "$log_dir" "www-data:www-data" "755"
    
    # Create monitoring script
    sudo tee "/usr/local/bin/monitor-$domain" > /dev/null <<EOF
#!/bin/bash
SITE_URL="https://$domain"
LOG_FILE="$log_dir/monitoring.log"

if curl -f -s -o /dev/null "\$SITE_URL"; then
    echo "\$(date): Site is UP" >> "\$LOG_FILE"
else
    echo "\$(date): Site is DOWN - Alert!" >> "\$LOG_FILE"
fi

DISK_USAGE=\$(df / | tail -1 | awk '{print \$5}' | sed 's/%//')
if [ "\$DISK_USAGE" -gt 80 ]; then
    echo "\$(date): Disk usage is \${DISK_USAGE}% - Warning!" >> "\$LOG_FILE"
fi
EOF

    sudo chmod +x "/usr/local/bin/monitor-$domain"
    (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/monitor-$domain") | crontab -
    log_success "Monitoring configured for $domain"
}

setup_backups() {
    local domain="$1"
    local laravel_path="$2"
    local backup_dir="/var/backups/laravel/$domain"
    
    create_directory "$backup_dir" "root:root" "755"
    
    sudo tee "/usr/local/bin/backup-$domain" > /dev/null <<EOF
#!/bin/bash
BACKUP_DIR="$backup_dir"
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)

tar -czf "\$BACKUP_DIR/files_\$TIMESTAMP.tar.gz" -C "$laravel_path" .

if [ -f "$laravel_path/.env" ]; then
    DB_NAME=\$(grep DB_DATABASE "$laravel_path/.env" | cut -d '=' -f2)
    DB_USER=\$(grep DB_USERNAME "$laravel_path/.env" | cut -d '=' -f2)
    DB_PASS=\$(grep DB_PASSWORD "$laravel_path/.env" | cut -d '=' -f2)
    
    if [ ! -z "\$DB_NAME" ]; then
        mysqldump -u\$DB_USER -p\$DB_PASS \$DB_NAME | gzip > "\$BACKUP_DIR/database_\$TIMESTAMP.sql.gz"
    fi
fi

find "\$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
find "\$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete
EOF

    sudo chmod +x "/usr/local/bin/backup-$domain"
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup-$domain") | crontab -
    log_success "Automated backups configured for $domain"
}

# Nginx configuration generator
generate_nginx_config() {
    local domain="$1"
    local laravel_path="$2"
    local php_version="${3:-$DEFAULT_PHP_VERSION}"
    
    cat <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    root $laravel_path/public;
    index index.php;
    charset utf-8;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { 
        access_log off; 
        log_not_found off; 
        expires 1y;
    }
    
    location = /robots.txt { 
        access_log off; 
        log_not_found off; 
    }

    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    error_page 404 /index.php;

    location ~ ^/index\.php(/|$) {
        fastcgi_pass unix:/var/run/php/php$php_version-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
}

# Supervisor configuration generator
generate_supervisor_config() {
    local domain="$1"
    local laravel_path="$2"
    local log_dir="/var/log/laravel/$domain"
    
    cat <<EOF
[program:${domain//./_}_queue]
process_name=%(program_name)s_%(process_num)02d
command=php $laravel_path/artisan queue:work --sleep=3 --tries=3 --timeout=90
autostart=true
autorestart=true
user=www-data
numprocs=1
redirect_stderr=true
stdout_logfile=$log_dir/queue.log
stopwaitsecs=3600
EOF
}

# Validation functions
validate_laravel_path() {
    local path="$1"
    
    if [ ! -d "$path" ]; then
        log_error "Directory $path does not exist"
        return 1
    fi
    
    if [ ! -d "$path/public" ]; then
        log_error "$path/public does not exist"
        return 1
    fi
    
    if [ ! -f "$path/artisan" ]; then
        log_error "$path/artisan does not exist - not a Laravel project?"
        return 1
    fi
    
    return 0
}

# System information functions
get_system_info() {
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime -p)"
    echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Memory: $(free -h | awk 'NR==2{printf "%.1f%% (%s/%s)", $3*100/$2, $3, $2}')"
    echo "Disk: $(df -h / | awk 'NR==2{printf "%s (%s available)", $5, $4}')"
}

# Initialize common environment
init_common() {
    local allow_user=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --allow-user)
                allow_user=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # Set error handling (but only check root if not allowing user)
    set -e
    trap handle_error ERR
    
    # Check root privileges unless --allow-user is specified
    if [ "$allow_user" = false ] && [[ $EUID -ne 0 ]] && [ "${SETUP_LOG:-}" != "" ]; then
        log_warning "Some operations may require root privileges"
    fi
    
    # Source this library in other scripts
    export COMMON_LIB_LOADED=1
}

# Check if root is required for installation operations
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This operation requires root privileges (use sudo)"
        return 1
    fi
    return 0
}

# Export functions for use in other scripts
export -f log_info log_success log_warning log_error log_step
export -f setup_logging log_to_file handle_error set_error_handling
export -f update_system install_packages enable_service restart_service check_service
export -f backup_file create_directory configure_file
export -f prompt_with_default prompt_yes_no
export -f install_component
export -f setup_firewall setup_monitoring setup_backups
export -f generate_nginx_config generate_supervisor_config
export -f validate_laravel_path get_system_info init_common

# Utility UI functions (moved from server_setup.sh)
clear_screen() {
    clear
    echo
}

draw_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                              ║${NC}"
    echo -e "${CYAN}║${YELLOW}                     🚀 SERVER AUTOMATION SUITE 🚀                          ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                                              ║${NC}"
    echo -e "${CYAN}║${GREEN}                   Professional Server Setup & Management                   ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                                              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

draw_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
} 