#!/bin/bash

# Load common library
source "$(dirname "$0")/lib/common.sh"

# Initialize with user mode allowed for system monitoring
init_common --allow-user

# Advanced dashboard functions
clear_screen() {
    clear
    echo
}

draw_dashboard_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                              ║${NC}"
    echo -e "${CYAN}║${YELLOW}                     📊 SYSTEM STATUS DASHBOARD 📊                         ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                                              ║${NC}"
    echo -e "${CYAN}║${GREEN}                    Real-time Server Monitoring & Analytics                 ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                                              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

draw_section_header() {
    local title="$1"
    local icon="$2"
    echo -e "${BLUE}┌─ ${icon} ${YELLOW}${title}${NC} ${BLUE}$(printf '─%.0s' $(seq 1 $((75 - ${#title}))))${NC}"
}

draw_section_footer() {
    echo -e "${BLUE}└$(printf '─%.0s' $(seq 1 78))${NC}"
    echo
}

draw_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

status_indicator() {
    local status="$1"
    local service="$2"
    if [ "$status" = "active" ]; then
        echo -e "  ${GREEN}●${NC} ${service} ${GREEN}[RUNNING]${NC}"
    else
        echo -e "  ${RED}●${NC} ${service} ${RED}[STOPPED]${NC}"
    fi
}

show_progress_bar() {
    local percentage="$1"
    local width=40
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    
    printf "  ["
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %3d%%\n" $percentage
}

# System Information with beautiful formatting
show_system_info() {
    draw_section_header "SYSTEM OVERVIEW" "🖥️"
    
    local hostname=$(hostname)
    local kernel=$(uname -r)
    local os_info=""
    local uptime_info=""
    local load_avg=""
    
    # Detect OS and use appropriate commands
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        os_info=$(sw_vers -productName 2>/dev/null || echo "macOS")
        uptime_info=$(uptime | sed 's/.*up \([^,]*\).*/\1/' 2>/dev/null || echo "Unknown")
        load_avg=$(uptime | awk -F'load averages:' '{print $2}' | xargs 2>/dev/null || echo "Unknown")
    else
        # Linux
        os_info=$(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo "Unknown Linux")
        uptime_info=$(uptime -p 2>/dev/null || echo "Unknown")
        load_avg=$(uptime | awk -F'load average:' '{print $2}' | xargs 2>/dev/null || echo "Unknown")
    fi
    
    echo -e "  ${BLUE}│${NC} ${CYAN}Hostname:${NC}     ${GREEN}$hostname${NC}"
    echo -e "  ${BLUE}│${NC} ${CYAN}OS:${NC}           ${GREEN}$os_info${NC}"
    echo -e "  ${BLUE}│${NC} ${CYAN}Kernel:${NC}       ${GREEN}$kernel${NC}"
    echo -e "  ${BLUE}│${NC} ${CYAN}Uptime:${NC}       ${GREEN}$uptime_info${NC}"
    echo -e "  ${BLUE}│${NC} ${CYAN}Load Average:${NC} ${YELLOW}$load_avg${NC}"
    
    draw_section_footer
}

# Resource usage with progress bars
show_resource_usage() {
    draw_section_header "RESOURCE USAGE" "📈"
    
    # Memory usage - different commands for different OS
    local mem_total=0
    local mem_used=0
    local mem_percentage=0
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS memory calculation
        if command -v vm_stat &> /dev/null; then
            local page_size=$(vm_stat | grep "page size" | awk '{print $8}' | sed 's/\.//' || echo "4096")
            local mem_free=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//' || echo "0")
            local mem_inactive=$(vm_stat | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//' || echo "0")
            local mem_active=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//' || echo "0")
            local mem_wired=$(vm_stat | grep "Pages wired down" | awk '{print $4}' | sed 's/\.//' || echo "0")
            
            mem_total=$(((mem_free + mem_inactive + mem_active + mem_wired) * page_size / 1024 / 1024))
            mem_used=$(((mem_active + mem_wired) * page_size / 1024 / 1024))
        else
            # Fallback for macOS
            mem_total=8192  # Assume 8GB
            mem_used=4096   # Assume 4GB used
        fi
    else
        # Linux memory calculation
        if command -v free &> /dev/null; then
            local mem_info=$(free | grep Mem)
            mem_total=$(echo $mem_info | awk '{print $2}' || echo "1024")
            mem_used=$(echo $mem_info | awk '{print $3}' || echo "512")
            mem_total=$((mem_total / 1024))  # Convert to MB
            mem_used=$((mem_used / 1024))    # Convert to MB
        else
            mem_total=1024
            mem_used=512
        fi
    fi
    
    # Avoid division by zero
    if [ $mem_total -gt 0 ]; then
        mem_percentage=$((mem_used * 100 / mem_total))
    else
        mem_percentage=0
    fi
    
    echo -e "  ${BLUE}│${NC} ${CYAN}Memory Usage:${NC}"
    show_progress_bar $mem_percentage
    echo -e "  ${BLUE}│${NC} ${GREEN}${mem_used}MB${NC} / ${BLUE}${mem_total}MB${NC} used"
    echo -e "  ${BLUE}│${NC}"
    
    # Disk usage
    local disk_info=$(df / 2>/dev/null | tail -1)
    if [ -n "$disk_info" ]; then
        local disk_percentage=$(echo $disk_info | awk '{print $5}' | sed 's/%//' || echo "0")
        local disk_used=$(echo $disk_info | awk '{print $3}')
        local disk_total=$(echo $disk_info | awk '{print $2}')
        
        echo -e "  ${BLUE}│${NC} ${CYAN}Disk Usage (/)${NC}"
        show_progress_bar $disk_percentage
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS df output is in 512-byte blocks
            echo -e "  ${BLUE}│${NC} ${GREEN}$((disk_used / 2048))GB${NC} / ${BLUE}$((disk_total / 2048))GB${NC} used"
        else
            # Linux df output is in 1K blocks
            echo -e "  ${BLUE}│${NC} ${GREEN}$((disk_used / 1024 / 1024))GB${NC} / ${BLUE}$((disk_total / 1024 / 1024))GB${NC} used"
        fi
    else
        echo -e "  ${BLUE}│${NC} ${CYAN}Disk Usage:${NC} ${YELLOW}Unable to determine${NC}"
    fi
    
    draw_section_footer
}

# Service status with beautiful indicators
show_service_status() {
    draw_section_header "SERVICE STATUS" "⚙️"
    
    local services=("nginx:Nginx Web Server" "mysql:MySQL Database" "postgresql:PostgreSQL" "redis-server:Redis Cache" "supervisor:Process Supervisor" "fail2ban:Security Monitor")
    
    for service_info in "${services[@]}"; do
        local service_name=$(echo $service_info | cut -d: -f1)
        local display_name=$(echo $service_info | cut -d: -f2)
        
        if systemctl is-active --quiet $service_name 2>/dev/null; then
            status_indicator "active" "$display_name"
        else
            status_indicator "inactive" "$display_name"
        fi
    done
    
    draw_section_footer
}

# PHP Status with enhanced display
show_php_status() {
    draw_section_header "PHP STATUS" "🐘"
    
    if command -v php &> /dev/null; then
        local php_version=$(php -v 2>/dev/null | head -n 1 | awk '{print $2}' 2>/dev/null || echo "Unknown")
        echo -e "  ${BLUE}│${NC} ${CYAN}Active Version:${NC} ${GREEN}PHP $php_version${NC}"
        echo -e "  ${BLUE}│${NC}"
        
        # Available PHP versions
        echo -e "  ${BLUE}│${NC} ${CYAN}Installed Versions:${NC}"
        local php_found=false
        for php_bin in /usr/bin/php?.?; do
            if [ -f "$php_bin" ]; then
                php_found=true
                local version=$(basename "$php_bin" | sed 's/php//')
                echo -e "  ${BLUE}│${NC}   ${GREEN}●${NC} PHP $version"
            fi
        done
        
        if [ "$php_found" = false ]; then
            echo -e "  ${BLUE}│${NC}   ${YELLOW}●${NC} Only system PHP available"
        fi
        
        echo -e "  ${BLUE}│${NC}"
        
        # PHP-FPM Status
        echo -e "  ${BLUE}│${NC} ${CYAN}FPM Services:${NC}"
        local fpm_found=false
        if command -v systemctl &> /dev/null; then
            for version in $(ls /usr/bin/php?.? 2>/dev/null | sed 's/.*php//' || echo ""); do
                if [ -n "$version" ] && systemctl list-units --type=service --state=loaded 2>/dev/null | grep -q "php$version-fpm"; then
                    fpm_found=true
                    if systemctl is-active --quiet "php$version-fpm" 2>/dev/null; then
                        echo -e "  ${BLUE}│${NC}   ${GREEN}●${NC} PHP $version-FPM ${GREEN}[RUNNING]${NC}"
                    else
                        echo -e "  ${BLUE}│${NC}   ${RED}●${NC} PHP $version-FPM ${RED}[STOPPED]${NC}"
                    fi
                fi
            done
        fi
        
        if [ "$fpm_found" = false ]; then
            echo -e "  ${BLUE}│${NC}   ${YELLOW}●${NC} No FPM services configured"
        fi
    else
        echo -e "  ${BLUE}│${NC} ${RED}●${NC} PHP is not installed"
    fi
    
    draw_section_footer
}

# Network Information with enhanced display
show_network_info() {
    draw_section_header "NETWORK STATUS" "🌐"
    
    # Public IP
    local public_ip=$(timeout 5 curl -s --max-time 3 ifconfig.me 2>/dev/null || echo "Unable to fetch")
    echo -e "  ${BLUE}│${NC} ${CYAN}Public IP:${NC}     ${GREEN}$public_ip${NC}"
    echo -e "  ${BLUE}│${NC}"
    
    # Listening ports
    echo -e "  ${BLUE}│${NC} ${CYAN}Active Ports:${NC}"
    if command -v netstat &> /dev/null; then
        netstat -tlnp 2>/dev/null | grep LISTEN | awk '{print $4"\t"$7}' | head -8 | while read port process; do
            local port_num=$(echo "$port" | sed 's/.*://')
            local process_name=$(echo "$process" | cut -d'/' -f2 | cut -c1-15)
            echo -e "  ${BLUE}│${NC}   ${GREEN}●${NC} Port ${YELLOW}$port_num${NC} → ${GREEN}$process_name${NC}"
        done
    else
        echo -e "  ${BLUE}│${NC}   ${YELLOW}●${NC} netstat not available"
    fi
    
    draw_section_footer
}

# SSL Certificates with enhanced display
show_ssl_status() {
    draw_section_header "SSL CERTIFICATES" "🔒"
    
    if command -v certbot &> /dev/null; then
        local cert_info=$(sudo certbot certificates 2>/dev/null)
        if [ ! -z "$cert_info" ]; then
            echo "$cert_info" | grep -E "(Certificate Name|Domains|Expiry Date)" | while read line; do
                if [[ $line == *"Certificate Name"* ]]; then
                    local cert_name=$(echo $line | cut -d: -f2 | xargs)
                    echo -e "  ${BLUE}│${NC} ${GREEN}●${NC} ${CYAN}$cert_name${NC}"
                elif [[ $line == *"Domains"* ]]; then
                    local domains=$(echo $line | cut -d: -f2 | xargs)
                    echo -e "  ${BLUE}│${NC}   ${YELLOW}Domains:${NC} $domains"
                elif [[ $line == *"Expiry Date"* ]]; then
                    local expiry=$(echo $line | cut -d: -f2- | xargs)
                    echo -e "  ${BLUE}│${NC}   ${YELLOW}Expires:${NC} $expiry"
                    echo -e "  ${BLUE}│${NC}"
                fi
            done
        else
            echo -e "  ${BLUE}│${NC} ${YELLOW}●${NC} No SSL certificates found"
        fi
    else
        echo -e "  ${BLUE}│${NC} ${RED}●${NC} Certbot is not installed"
    fi
    
    draw_section_footer
}

# Security Status with enhanced display
show_security_status() {
    draw_section_header "SECURITY STATUS" "🛡️"
    
    # UFW Firewall
    if systemctl is-active --quiet ufw 2>/dev/null; then
        echo -e "  ${BLUE}│${NC} ${GREEN}●${NC} ${CYAN}UFW Firewall${NC} ${GREEN}[ACTIVE]${NC}"
        echo -e "  ${BLUE}│${NC}   ${YELLOW}Active Rules:${NC}"
        sudo ufw status numbered 2>/dev/null | grep -E "^\[" | head -4 | while read rule; do
            echo -e "  ${BLUE}│${NC}     ${GREEN}•${NC} $rule"
        done
    else
        echo -e "  ${BLUE}│${NC} ${RED}●${NC} ${CYAN}UFW Firewall${NC} ${RED}[INACTIVE]${NC}"
    fi
    
    echo -e "  ${BLUE}│${NC}"
    
    # Fail2Ban
    if systemctl is-active --quiet fail2ban 2>/dev/null; then
        echo -e "  ${BLUE}│${NC} ${GREEN}●${NC} ${CYAN}Fail2Ban${NC} ${GREEN}[ACTIVE]${NC}"
        local banned_count=$(sudo fail2ban-client status 2>/dev/null | grep -c "IP list" || echo "0")
        echo -e "  ${BLUE}│${NC}   ${YELLOW}Banned IPs:${NC} $banned_count active bans"
    else
        echo -e "  ${BLUE}│${NC} ${RED}●${NC} ${CYAN}Fail2Ban${NC} ${RED}[INACTIVE]${NC}"
    fi
    
    echo -e "  ${BLUE}│${NC}"
    
    # Recent Security Events
    echo -e "  ${BLUE}│${NC} ${CYAN}Recent Failed Logins:${NC}"
    local failed_logins=$(grep "Failed password" /var/log/auth.log 2>/dev/null | tail -3)
    if [ ! -z "$failed_logins" ]; then
        echo "$failed_logins" | while read line; do
            local time=$(echo $line | awk '{print $1" "$2" "$3}')
            local ip=$(echo $line | awk '{print $11}')
            echo -e "  ${BLUE}│${NC}   ${RED}●${NC} $time from ${YELLOW}$ip${NC}"
        done
    else
        echo -e "  ${BLUE}│${NC}   ${GREEN}●${NC} No recent failed attempts"
    fi
    
    draw_section_footer
}

# Process Information with enhanced display
show_process_info() {
    draw_section_header "PROCESS INFORMATION" "⚡"
    
    echo -e "  ${BLUE}│${NC} ${CYAN}Top CPU Consumers:${NC}"
    ps aux --sort=-%cpu | head -6 | tail -5 | while read line; do
        local user=$(echo $line | awk '{print $1}')
        local cpu=$(echo $line | awk '{print $3}')
        local process=$(echo $line | awk '{print $11}' | cut -c1-25)
        echo -e "  ${BLUE}│${NC}   ${GREEN}●${NC} ${YELLOW}$cpu%${NC} ${GREEN}$user${NC} → $process"
    done
    
    echo -e "  ${BLUE}│${NC}"
    echo -e "  ${BLUE}│${NC} ${CYAN}Top Memory Consumers:${NC}"
    ps aux --sort=-%mem | head -6 | tail -5 | while read line; do
        local user=$(echo $line | awk '{print $1}')
        local mem=$(echo $line | awk '{print $4}')
        local process=$(echo $line | awk '{print $11}' | cut -c1-25)
        echo -e "  ${BLUE}│${NC}   ${GREEN}●${NC} ${YELLOW}$mem%${NC} ${GREEN}$user${NC} → $process"
    done
    
    draw_section_footer
}

# Storage Information with enhanced display
show_storage_info() {
    draw_section_header "STORAGE ANALYSIS" "💾"
    
    echo -e "  ${BLUE}│${NC} ${CYAN}Directory Usage:${NC}"
    du -sh /var/log /var/www /home /tmp /var/lib/mysql 2>/dev/null | sort -hr | head -5 | while read size path; do
        echo -e "  ${BLUE}│${NC}   ${GREEN}●${NC} ${YELLOW}$size${NC} → $path"
    done
    
    echo -e "  ${BLUE}│${NC}"
    echo -e "  ${BLUE}│${NC} ${CYAN}Mount Points:${NC}"
    df -h | grep -E "^/dev" | while read filesystem size used avail percent mount; do
        echo -e "  ${BLUE}│${NC}   ${GREEN}●${NC} $mount ${YELLOW}$percent${NC} used (${GREEN}$avail${NC} free)"
    done
    
    draw_section_footer
}

# Laravel Queue Status with enhanced display
show_laravel_status() {
    draw_section_header "LARAVEL STATUS" "🔄"
    
    # Queue Workers
    if pgrep -f "queue:work" > /dev/null; then
        local queue_count=$(pgrep -f "queue:work" | wc -l)
        echo -e "  ${BLUE}│${NC} ${GREEN}●${NC} ${CYAN}Queue Workers${NC} ${GREEN}[$queue_count RUNNING]${NC}"
        ps aux | grep "queue:work" | grep -v grep | head -3 | while read line; do
            local user=$(echo $line | awk '{print $1}')
            local cmd=$(echo $line | awk '{print $11" "$12" "$13}')
            echo -e "  ${BLUE}│${NC}   ${GREEN}•${NC} ${GREEN}$user${NC} → $cmd"
        done
    else
        echo -e "  ${BLUE}│${NC} ${YELLOW}●${NC} ${CYAN}Queue Workers${NC} ${YELLOW}[STOPPED]${NC}"
    fi
    
    echo -e "  ${BLUE}│${NC}"
    
    # Laravel Applications
    echo -e "  ${BLUE}│${NC} ${CYAN}Applications:${NC}"
    if [ -d "/var/www" ]; then
        find /var/www -name "artisan" -type f 2>/dev/null | while read artisan_file; do
            local app_path=$(dirname "$artisan_file")
            local app_name=$(basename "$app_path")
            echo -e "  ${BLUE}│${NC}   ${GREEN}●${NC} $app_name → $app_path"
        done
    else
        echo -e "  ${BLUE}│${NC}   ${YELLOW}●${NC} No Laravel applications found"
    fi
    
    draw_section_footer
}

# System Maintenance with enhanced display
show_maintenance_status() {
    draw_section_header "MAINTENANCE STATUS" "🔧"
    
    # System Updates
    if command -v apt &> /dev/null; then
        local updates=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
        if [ $updates -gt 0 ]; then
            echo -e "  ${BLUE}│${NC} ${YELLOW}●${NC} ${CYAN}System Updates${NC} ${YELLOW}[$updates AVAILABLE]${NC}"
        else
            echo -e "  ${BLUE}│${NC} ${GREEN}●${NC} ${CYAN}System Updates${NC} ${GREEN}[UP TO DATE]${NC}"
        fi
    fi
    
    echo -e "  ${BLUE}│${NC}"
    
    # Backup Status
    echo -e "  ${BLUE}│${NC} ${CYAN}Backup Status:${NC}"
    if [ -d "/var/backups/laravel" ]; then
        local latest_backup=$(find /var/backups/laravel -name "*.tar.gz" -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
        if [ ! -z "$latest_backup" ]; then
            local backup_date=$(stat -c %y "$latest_backup" 2>/dev/null | cut -d' ' -f1)
            echo -e "  ${BLUE}│${NC}   ${GREEN}●${NC} Latest backup: ${GREEN}$backup_date${NC}"
        else
            echo -e "  ${BLUE}│${NC}   ${YELLOW}●${NC} No backups found"
        fi
    else
        echo -e "  ${BLUE}│${NC}   ${YELLOW}●${NC} Backup directory not configured"
    fi
    
    echo -e "  ${BLUE}│${NC}"
    
    # Log Rotation
    echo -e "  ${BLUE}│${NC} ${CYAN}Log Files:${NC}"
    local log_size=$(du -sh /var/log 2>/dev/null | awk '{print $1}')
    echo -e "  ${BLUE}│${NC}   ${GREEN}●${NC} Total log size: ${YELLOW}$log_size${NC}"
    
    draw_section_footer
}

# Main dashboard function
show_dashboard() {
    clear_screen
    draw_dashboard_header
    
    # Show timestamp
    echo -e "${BLUE}📅 Generated: ${YELLOW}$(date '+%Y-%m-%d %H:%M:%S')${NC} │ ${BLUE}Refresh: ${YELLOW}./system_status.sh${NC}"
    draw_separator
    echo
    
    # Display all sections
    show_system_info
    show_resource_usage
    show_service_status
    show_php_status
    show_network_info
    show_ssl_status
    show_security_status
    show_process_info
    show_storage_info
    show_laravel_status
    show_maintenance_status
    
    # Footer with management options
    draw_separator
    echo -e "${CYAN}🔧 Management Commands:${NC}"
    echo -e "  ${GREEN}./system_status.sh --restart-all${NC}     Restart all services"
    echo -e "  ${GREEN}./system_status.sh --update-system${NC}   Update system packages"
    echo -e "  ${GREEN}./system_status.sh --tail-logs${NC}       Monitor logs in real-time"
    echo -e "  ${GREEN}./system_status.sh --security-scan${NC}   Run security analysis"
    echo
}

# Enhanced management functions
show_help() {
    clear_screen
    draw_dashboard_header
    echo -e "${YELLOW}📖 SYSTEM STATUS DASHBOARD - HELP${NC}"
    draw_separator
    echo
    echo -e "${CYAN}Usage:${NC}"
    echo -e "  ${GREEN}./system_status.sh${NC}                 Show complete dashboard"
    echo -e "  ${GREEN}./system_status.sh --help${NC}          Show this help message"
    echo
    echo -e "${CYAN}Management Commands:${NC}"
    echo -e "  ${GREEN}./system_status.sh --restart-all${NC}   Restart all system services"
    echo -e "  ${GREEN}./system_status.sh --update-system${NC} Update system packages"
    echo -e "  ${GREEN}./system_status.sh --tail-logs${NC}     Monitor logs in real-time"
    echo -e "  ${GREEN}./system_status.sh --security-scan${NC} Run security analysis"
    echo
    echo -e "${CYAN}Quick Status:${NC}"
    echo -e "  ${GREEN}./system_status.sh --services${NC}      Show only service status"
    echo -e "  ${GREEN}./system_status.sh --resources${NC}     Show only resource usage"
    echo -e "  ${GREEN}./system_status.sh --security${NC}      Show only security status"
    echo
}

restart_all_services() {
    clear_screen
    draw_dashboard_header
    echo -e "${YELLOW}🔄 RESTARTING ALL SERVICES${NC}"
    draw_separator
    echo
    
    local services=("nginx" "mysql" "redis-server" "supervisor" "fail2ban" "php8.3-fpm")
    
    for service in "${services[@]}"; do
        if systemctl is-enabled $service &>/dev/null; then
            echo -e "${BLUE}Restarting $service...${NC}"
            sudo systemctl restart $service
            if systemctl is-active --quiet $service; then
                echo -e "  ${GREEN}✅ $service restarted successfully${NC}"
            else
                echo -e "  ${RED}❌ Failed to restart $service${NC}"
            fi
        else
            echo -e "  ${YELLOW}⚠️  $service is not installed or enabled${NC}"
        fi
        echo
    done
    
    echo -e "${GREEN}🎉 Service restart completed!${NC}"
    echo
}

update_system_packages() {
    clear_screen
    draw_dashboard_header
    echo -e "${YELLOW}📦 UPDATING SYSTEM PACKAGES${NC}"
    draw_separator
    echo
    
    echo -e "${BLUE}Updating package lists...${NC}"
    sudo apt update
    echo
    
    echo -e "${BLUE}Upgrading packages...${NC}"
    sudo apt upgrade -y
    echo
    
    echo -e "${BLUE}Cleaning up...${NC}"
    sudo apt autoremove -y
    sudo apt autoclean
    echo
    
    echo -e "${GREEN}🎉 System update completed!${NC}"
    echo
}

tail_system_logs() {
    clear_screen
    draw_dashboard_header
    echo -e "${YELLOW}📋 REAL-TIME LOG MONITORING${NC}"
    draw_separator
    echo
    echo -e "${CYAN}Monitoring multiple log files...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
    echo
    
    local log_files=(
        "/var/log/nginx/error.log"
        "/var/log/mysql/error.log"
        "/var/log/fail2ban.log"
        "/var/log/auth.log"
        "/var/log/laravel/*/laravel.log"
    )
    
    # Find existing log files
    local existing_logs=""
    for log_pattern in "${log_files[@]}"; do
        for log_file in $log_pattern; do
            if [ -f "$log_file" ]; then
                existing_logs+="$log_file "
            fi
        done
    done
    
    if [ ! -z "$existing_logs" ]; then
        sudo tail -f $existing_logs
    else
        echo -e "${RED}No log files found to monitor${NC}"
    fi
}

security_scan() {
    clear_screen
    draw_dashboard_header
    echo -e "${YELLOW}🔍 SECURITY ANALYSIS${NC}"
    draw_separator
    echo
    
    echo -e "${CYAN}Running security checks...${NC}"
    echo
    
    # Check for open ports
    echo -e "${BLUE}Open Ports Analysis:${NC}"
    netstat -tuln | grep LISTEN | while read line; do
        local port=$(echo $line | awk '{print $4}' | sed 's/.*://')
        echo -e "  ${GREEN}●${NC} Port $port is listening"
    done
    echo
    
    # Check failed login attempts
    echo -e "${BLUE}Security Events (Last 24 hours):${NC}"
    local failed_logins=$(grep "Failed password" /var/log/auth.log 2>/dev/null | grep "$(date '+%b %d')" | wc -l)
    echo -e "  ${GREEN}●${NC} Failed login attempts: ${YELLOW}$failed_logins${NC}"
    
    # Check firewall status
    if systemctl is-active --quiet ufw; then
        echo -e "  ${GREEN}●${NC} UFW Firewall: ${GREEN}Active${NC}"
    else
        echo -e "  ${RED}●${NC} UFW Firewall: ${RED}Inactive${NC}"
    fi
    
    # Check fail2ban status
    if systemctl is-active --quiet fail2ban; then
        local banned_ips=$(sudo fail2ban-client status 2>/dev/null | grep -c "IP list" || echo "0")
        echo -e "  ${GREEN}●${NC} Fail2Ban: ${GREEN}Active${NC} (${YELLOW}$banned_ips${NC} banned IPs)"
    else
        echo -e "  ${RED}●${NC} Fail2Ban: ${RED}Inactive${NC}"
    fi
    
    echo
    echo -e "${GREEN}🔒 Security scan completed!${NC}"
    echo
}

# Main execution logic
case "${1:-}" in
    "--help"|"-h")
        show_help
        ;;
    "--restart-all")
        restart_all_services
        ;;
    "--update-system")
        update_system_packages
        ;;
    "--tail-logs")
        tail_system_logs
        ;;
    "--security-scan")
        security_scan
        ;;
    "--services")
        clear_screen
        draw_dashboard_header
        show_service_status
        ;;
    "--resources")
        clear_screen
        draw_dashboard_header
        show_resource_usage
        ;;
    "--security")
        clear_screen
        draw_dashboard_header
        show_security_status
        ;;
    *)
        show_dashboard
        ;;
esac