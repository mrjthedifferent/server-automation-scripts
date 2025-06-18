#!/bin/bash

# Load common library
source "$(dirname "$0")/lib/common.sh"
init_common

# Advanced menu functions
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

show_main_menu() {
    clear_screen
    draw_header
    
    echo -e "${YELLOW}📋 SERVER COMPONENTS & TOOLS${NC}"
    draw_separator
    echo
    echo -e "${GREEN}  1)${NC} ${GREEN}🔧 INSTALL COMPONENTS${NC}  │ Choose server components to install"
    echo -e "     ${BLUE}└─${NC} Interactive selection of web servers, databases, tools"
    echo
    echo -e "${GREEN}  2)${NC} ${RED}🛡️ SECURITY HARDENING${NC}  │ Secure your server"
    echo -e "     ${BLUE}├─${NC} SSH hardening, Firewall configuration"
    echo -e "     ${BLUE}└─${NC} Fail2Ban, security policies"
    echo
    echo -e "${GREEN}  3)${NC} ${YELLOW}📊 SYSTEM STATUS${NC}       │ View system dashboard"
    echo -e "     ${BLUE}└─${NC} Monitor services, resources, and logs"
    echo
    echo -e "${GREEN}  4)${NC} ${PURPLE}🚀 LARAVEL SITE SETUP${NC}  │ Configure Laravel applications"
    echo -e "     ${BLUE}├─${NC} Nginx virtual hosts, SSL certificates"
    echo -e "     ${BLUE}└─${NC} Queue workers, monitoring, backups"
    echo
    echo -e "${GREEN}  5)${NC} ${CYAN}🔍 VERIFY SETUP${NC}        │ Test system configuration"
    echo -e "     ${BLUE}└─${NC} Check components, compatibility, and functionality"
    echo
    echo -e "${GREEN}  6)${NC} ${BLUE}🐳 DOCKER PLATFORM${NC}     │ Install Docker & Docker Compose"
    echo -e "     ${BLUE}├─${NC} Container runtime and orchestration"
    echo -e "     ${BLUE}└─${NC} User permissions and service setup"
    echo
    echo -e "${GREEN}  7)${NC} ${GREEN}💅 OH MY ZSH${NC}           │ Enhanced shell experience"
    echo -e "     ${BLUE}├─${NC} Zsh shell with Oh My Zsh framework"
    echo -e "     ${BLUE}└─${NC} Laravel aliases and productivity tools"
    echo
    echo -e "${GREEN}  8)${NC} ${CYAN}🗄️  INSTALL PHPMYADMIN${NC} │ Install phpMyAdmin with Nginx"
    echo -e "     ${BLUE}└─${NC} phpMyAdmin web interface for MySQL/MariaDB"
    echo
    echo -e "${GREEN}  9)${NC} ${CYAN}🗄️  INSTALL PGADMIN${NC}   │ Install pgAdmin with Nginx"
    echo -e "     ${BLUE}└─${NC} pgAdmin web interface for PostgreSQL"
    echo
    echo -e "${GREEN}  0)${NC} ${RED}❌ EXIT${NC}             │ Exit setup"
    echo
    draw_separator
    echo
}

show_component_menu() {
    clear_screen
    draw_header
    
    echo -e "${YELLOW}🔧 CUSTOM COMPONENT SELECTION${NC}"
    draw_separator
    echo
    echo -e "${GREEN}Web Servers & Reverse Proxies:${NC}"
    echo -e "  ${BLUE}[${NC} ${RED}nginx${NC}     ${BLUE}]${NC} Nginx web server & reverse proxy"
    echo
    echo -e "${GREEN}Programming Languages & Runtimes:${NC}"
    echo -e "  ${BLUE}[${NC} ${RED}php${NC}       ${BLUE}]${NC} PHP with multiple version support"
    echo -e "  ${BLUE}[${NC} ${RED}node${NC}      ${BLUE}]${NC} Node.js & npm package manager"
    echo
    echo -e "${GREEN}Databases:${NC}"
    echo -e "  ${BLUE}[${NC} ${RED}mysql${NC}     ${BLUE}]${NC} MySQL database server"
    echo -e "  ${BLUE}[${NC} ${RED}pgsql${NC}     ${BLUE}]${NC} PostgreSQL database server"
    echo -e "  ${BLUE}[${NC} ${RED}redis${NC}     ${BLUE}]${NC} Redis cache & session store"
    echo
    echo -e "${GREEN}Package Managers & Tools:${NC}"
    echo -e "  ${BLUE}[${NC} ${RED}composer${NC}  ${BLUE}]${NC} PHP dependency manager"
    echo
    echo -e "${GREEN}Process Management:${NC}"
    echo -e "  ${BLUE}[${NC} ${RED}supervisor${NC}${BLUE}]${NC} Process supervisor for queue workers"
    echo
    echo -e "${GREEN}Security & SSL:${NC}"
    echo -e "  ${BLUE}[${NC} ${RED}fail2ban${NC}  ${BLUE}]${NC} Intrusion prevention system"
    echo -e "  ${BLUE}[${NC} ${RED}certbot${NC}   ${BLUE}]${NC} Let's Encrypt SSL certificates"
    echo
    echo -e "${GREEN}Containerization:${NC}"
    echo -e "  ${BLUE}[${NC} ${RED}docker${NC}    ${BLUE}]${NC} Docker container platform"
    echo
    echo -e "${GREEN}Utilities:${NC}"
    echo -e "  ${BLUE}[${NC} ${RED}logrotate${NC} ${BLUE}]${NC} Log rotation for Laravel applications"
    echo
    draw_separator
    echo
}

prompt_user_choice() {
    echo -ne "${YELLOW}➤ Select option${NC} ${BLUE}[1-9, 0 to exit]${NC}: "
    read -r user_choice
}

show_installation_confirmation() {
    local components="$1"
    
    # Send UI output to stderr so it doesn't interfere with function return value
    clear_screen >&2
    draw_header >&2
    
    echo -e "${YELLOW}📋 INSTALLATION CONFIRMATION${NC}" >&2
    draw_separator >&2
    echo >&2
    echo -e "${GREEN}Components to Install:${NC}" >&2
    
    for component in $components; do
        case $component in
            "nginx") echo -e "  ${BLUE}✓${NC} Nginx Web Server" >&2 ;;
            "php") echo -e "  ${BLUE}✓${NC} PHP (Multiple Versions)" >&2 ;;
            "mysql") echo -e "  ${BLUE}✓${NC} MySQL Database" >&2 ;;
            "pgsql") echo -e "  ${BLUE}✓${NC} PostgreSQL Database" >&2 ;;
            "redis") echo -e "  ${BLUE}✓${NC} Redis Cache Server" >&2 ;;
            "node") echo -e "  ${BLUE}✓${NC} Node.js & npm" >&2 ;;
            "composer") echo -e "  ${BLUE}✓${NC} Composer (PHP)" >&2 ;;
            "supervisor") echo -e "  ${BLUE}✓${NC} Supervisor Process Manager" >&2 ;;
            "fail2ban") echo -e "  ${BLUE}✓${NC} Fail2Ban Security" >&2 ;;
            "certbot") echo -e "  ${BLUE}✓${NC} Certbot SSL Certificates" >&2 ;;
            "logrotate") echo -e "  ${BLUE}✓${NC} Laravel Log Rotation" >&2 ;;
        esac
    done
    
    echo >&2
    draw_separator >&2
    echo >&2
    echo -e "${YELLOW}⚠️  This will install and configure the selected components.${NC}" >&2
    echo -e "${YELLOW}⚠️  Make sure you have proper backups before proceeding.${NC}" >&2
    echo >&2
    echo -ne "${GREEN}Proceed with installation?${NC} ${BLUE}[y/N]${NC}: " >&2
    read -r confirm
    
    # Only output the user's response to stdout for capture
    echo "$confirm"
}

interactive_component_selection() {
    local selected_components=""
    local component_list=("nginx" "php" "mysql" "pgsql" "redis" "node" "composer" "supervisor" "fail2ban" "certbot" "logrotate")
    local component_names=("Nginx Web Server" "PHP (Multiple Versions)" "MySQL Database" "PostgreSQL Database" "Redis Cache" "Node.js & npm" "Composer" "Supervisor" "Fail2Ban Security" "Certbot SSL" "Laravel Logrotate")
    
    # Send UI output to stderr so it doesn't interfere with function return value
    clear_screen >&2
    draw_header >&2
    echo -e "${YELLOW}🔧 INTERACTIVE COMPONENT SELECTION${NC}" >&2
    draw_separator >&2
    echo >&2
    echo -e "${GREEN}Available Components:${NC}" >&2
    echo >&2
    
    for i in "${!component_list[@]}"; do
        component="${component_list[$i]}"
        name="${component_names[$i]}"
        
        echo -ne "${GREEN}Install ${name}?${NC} ${BLUE}[y/N]${NC}: " >&2
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            selected_components+="$component "
            echo -e "  ${GREEN}✓${NC} ${name} selected" >&2
        else
            echo -e "  ${RED}✗${NC} ${name} skipped" >&2
        fi
        echo >&2
    done
    
    # Only output the result to stdout for capture
    echo "$selected_components"
}

show_installation_progress() {
    local components="$1"
    
    clear_screen
    draw_header
    
    echo -e "${YELLOW}🚀 INSTALLATION IN PROGRESS${NC}"
    draw_separator
    echo
    echo -e "${GREEN}Log File:${NC} ${BLUE}$SETUP_LOG${NC}"
    echo
    echo -e "${YELLOW}Installing components...${NC}"
    echo
}

show_completion_summary() {
    local components="$1"
    local start_time="$2"
    local end_time="$3"
    local duration=$((end_time - start_time))
    
    clear_screen
    draw_header
    
    echo -e "${GREEN}🎉 INSTALLATION COMPLETED SUCCESSFULLY! 🎉${NC}"
    draw_separator
    echo
    echo -e "${GREEN}Duration:${NC} ${BLUE}${duration} seconds${NC}"
    echo -e "${GREEN}Log File:${NC} ${BLUE}$SETUP_LOG${NC}"
    echo
    echo -e "${YELLOW}Installed Components:${NC}"
    
    for component in $components; do
        echo -e "  ${GREEN}✅${NC} $component"
    done
    
    echo
    draw_separator
    echo
    echo -e "${YELLOW}🔧 Next Steps:${NC}"
    echo -e "  ${BLUE}•${NC} Use the main menu ${GREEN}'Laravel Site Setup'${NC} option to configure Laravel sites"
    echo -e "  ${BLUE}•${NC} Use the main menu ${GREEN}'System Status'${NC} option to monitor your server"
    echo -e "  ${BLUE}•${NC} Use the main menu ${GREEN}'Verify Setup'${NC} option to test your configuration"
    echo -e "  ${BLUE}•${NC} Check the log file for detailed installation information"
    echo
    echo -ne "${YELLOW}Press ENTER to continue...${NC}"
    read -r
}

# Main menu loop
main_menu() {
    while true; do
        show_main_menu
        prompt_user_choice
        
        case $user_choice in
            1)
                COMPONENTS=$(interactive_component_selection)
                if [ -z "$COMPONENTS" ]; then
                    echo -e "${RED}No components selected. Returning to main menu.${NC}"
                    sleep 2
                    continue
                fi
                ;;
            2)
                clear_screen
                draw_header
                echo -e "${YELLOW}🛡️ SECURITY HARDENING${NC}"
                draw_separator
                echo
                if ! check_root; then
                    echo -ne "${YELLOW}Press ENTER to continue...${NC}"
                    read -r
                    continue
                fi
                bash features/setup_security.sh
                echo
                echo -ne "${YELLOW}Press ENTER to continue...${NC}"
                read -r
                continue
                ;;
            3)
                clear_screen
                bash system_status.sh
                echo
                echo -ne "${YELLOW}Press ENTER to continue...${NC}"
                read -r
                continue
                ;;
            4)
                clear_screen
                draw_header
                echo -e "${YELLOW}🚀 LARAVEL SITE SETUP${NC}"
                draw_separator
                echo
                if ! check_root; then
                    echo -ne "${YELLOW}Press ENTER to continue...${NC}"
                    read -r
                    continue
                fi
                bash laravel_site_enable.sh
                echo
                echo -ne "${YELLOW}Press ENTER to continue...${NC}"
                read -r
                continue
                ;;
            5)
                clear_screen
                draw_header
                echo -e "${YELLOW}🔍 SETUP VERIFICATION${NC}"
                draw_separator
                echo
                bash verify_setup.sh
                echo
                echo -ne "${YELLOW}Press ENTER to continue...${NC}"
                read -r
                continue
                ;;
            6)
                clear_screen
                draw_header
                echo -e "${YELLOW}🐳 DOCKER PLATFORM INSTALLATION${NC}"
                draw_separator
                echo
                if ! check_root; then
                    echo -ne "${YELLOW}Press ENTER to continue...${NC}"
                    read -r
                    continue
                fi
                bash features/install_docker.sh
                echo
                echo -ne "${YELLOW}Press ENTER to continue...${NC}"
                read -r
                continue
                ;;
            7)
                clear_screen
                draw_header
                echo -e "${YELLOW}💅 OH MY ZSH INSTALLATION${NC}"
                draw_separator
                echo
                echo -e "${YELLOW}Note: This can be run without root privileges${NC}"
                echo
                bash features/install_ohmyzsh.sh
                echo
                echo -ne "${YELLOW}Press ENTER to continue...${NC}"
                read -r
                continue
                ;;
            8)
                clear_screen
                draw_header
                echo -e "${YELLOW}🗄️  PHPMYADMIN INSTALLATION${NC}"
                draw_separator
                echo
                if ! check_root; then
                    echo -ne "${YELLOW}Press ENTER to continue...${NC}"
                    read -r
                    continue
                fi
                bash features/install_phpmyadmin.sh
                echo
                echo -ne "${YELLOW}Press ENTER to continue...${NC}"
                read -r
                continue
                ;;
            9)
                clear_screen
                draw_header
                echo -e "${YELLOW}🗄️  PGADMIN INSTALLATION${NC}"
                draw_separator
                echo
                if ! check_root; then
                    echo -ne "${YELLOW}Press ENTER to continue...${NC}"
                    read -r
                    continue
                fi
                bash features/install_pgadmin.sh
                echo
                echo -ne "${YELLOW}Press ENTER to continue...${NC}"
                read -r
                continue
                ;;
            0)
                clear_screen
                echo -e "${GREEN}Thank you for using Server Automation Suite! 👋${NC}"
                echo
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please select 1-9 or 0 to exit.${NC}"
                sleep 1
                continue
                ;;
        esac
        
        # Show confirmation
        confirm=$(show_installation_confirmation "$COMPONENTS")
        
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Installation cancelled. Returning to main menu.${NC}"
            sleep 2
            continue
        fi
        
        # Check for root before installation
        if ! check_root; then
            echo -e "${YELLOW}Installation cancelled. Root privileges required for component installation.${NC}"
            sleep 2
            continue
        fi
        
        # Start installation
        setup_logging "server-setup"
        log_to_file "Starting component installation"
        
        show_installation_progress "$COMPONENTS"
        
        start_time=$(date +%s)
        
        # Install components
        for component in $COMPONENTS; do
            echo -e "${BLUE}Installing $component...${NC}"
            if ! install_component "$component"; then
                log_error "Failed to install $component. Check log file: $SETUP_LOG"
                echo -ne "${YELLOW}Continue with remaining components?${NC} ${BLUE}[y/N]${NC}: "
                read -r continue_choice
                if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
                    log_error "Installation cancelled by user"
                    exit 1
                fi
            fi
        done
        
        # Optional security hardening
        echo
        echo -ne "${YELLOW}Setup additional security hardening?${NC} ${BLUE}[y/N]${NC}: "
        read -r security_choice
        if [[ "$security_choice" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Setting up security hardening...${NC}"
            bash features/setup_security.sh
        fi
        
        end_time=$(date +%s)
        
        log_success "All selected server components installed!"
        log_to_file "Installation completed successfully"
        
        show_completion_summary "$COMPONENTS" "$start_time" "$end_time"
        
        break
    done
}

# Start the application
clear_screen
echo -e "${GREEN}Initializing Server Automation Suite...${NC}"
sleep 1

main_menu