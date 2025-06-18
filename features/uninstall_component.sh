#!/bin/bash

# Universal Uninstall Script for Server Automation Suite
# Supports: nginx, php, mysql, pgsql, redis, node, composer, supervisor, fail2ban, certbot, logrotate, phpmyadmin, pgadmin, adminer, docker, ohmyzsh

source "$(dirname "$0")/../lib/common.sh"
init_common

COMPONENTS=(
  "nginx"
  "php"
  "mysql"
  "pgsql"
  "redis"
  "node"
  "composer"
  "supervisor"
  "fail2ban"
  "certbot"
  "logrotate"
  "phpmyadmin"
  "pgadmin"
  "adminer"
  "docker"
  "ohmyzsh"
)

COMPONENT_NAMES=(
  "Nginx Web Server"
  "PHP (All Versions)"
  "MySQL Database"
  "PostgreSQL Database"
  "Redis Cache"
  "Node.js & npm"
  "Composer (PHP)"
  "Supervisor Process Manager"
  "Fail2Ban Security"
  "Certbot SSL"
  "Laravel Logrotate"
  "phpMyAdmin"
  "pgAdmin"
  "Adminer"
  "Docker Platform"
  "Oh My Zsh"
)

function show_uninstall_menu() {
  clear_screen
  draw_header
  echo -e "${YELLOW}🗑️  UNINSTALL COMPONENTS & TOOLS${NC}"
  draw_separator
  echo
  for i in "${!COMPONENTS[@]}"; do
    printf "${GREEN}%2d)${NC} %s\n" "$((i+1))" "${COMPONENT_NAMES[$i]}"
  done
  echo -e "${GREEN} 0)${NC} ${RED}Cancel${NC}"
  echo
}

function uninstall_component() {
  local component="$1"
  case "$component" in
    nginx)
      sudo apt remove --purge -y nginx nginx-common nginx-full
      sudo rm -rf /etc/nginx /var/log/nginx
      ;;
    php)
      sudo apt remove --purge -y "php*"
      sudo rm -rf /etc/php /var/log/php*
      ;;
    mysql)
      sudo apt remove --purge -y mysql-server mysql-client mysql-common
      sudo rm -rf /etc/mysql /var/lib/mysql /var/log/mysql
      ;;
    pgsql)
      sudo apt remove --purge -y postgresql postgresql-contrib
      sudo rm -rf /etc/postgresql /var/lib/postgresql /var/log/postgresql
      ;;
    redis)
      sudo apt remove --purge -y redis-server
      sudo rm -rf /etc/redis /var/lib/redis /var/log/redis
      ;;
    node)
      sudo apt remove --purge -y nodejs npm
      ;;
    composer)
      sudo rm -f /usr/local/bin/composer
      ;;
    supervisor)
      sudo apt remove --purge -y supervisor
      sudo rm -rf /etc/supervisor /var/log/supervisor
      ;;
    fail2ban)
      sudo apt remove --purge -y fail2ban
      sudo rm -rf /etc/fail2ban /var/log/fail2ban
      ;;
    certbot)
      sudo apt remove --purge -y certbot python3-certbot-nginx
      ;;
    logrotate)
      sudo apt remove --purge -y logrotate
      ;;
    phpmyadmin)
      sudo apt remove --purge -y phpmyadmin
      sudo rm -f /etc/nginx/snippets/phpmyadmin.conf
      sudo sed -i '/include snippets\/phpmyadmin.conf;/d' /etc/nginx/sites-available/default 2>/dev/null || true
      ;;
    pgadmin)
      sudo apt remove --purge -y pgadmin4 pgadmin4-web
      sudo rm -f /etc/nginx/snippets/pgadmin.conf
      sudo sed -i '/include snippets\/pgadmin.conf;/d' /etc/nginx/sites-available/default 2>/dev/null || true
      sudo rm -f /etc/apt/sources.list.d/pgadmin4.list
      sudo rm -f /usr/share/keyrings/packages-pgadmin-org.gpg
      ;;
    adminer)
      sudo apt remove --purge -y adminer
      sudo rm -f /etc/nginx/snippets/adminer.conf
      sudo sed -i '/include snippets\/adminer.conf;/d' /etc/nginx/sites-available/default 2>/dev/null || true
      ;;
    docker)
      sudo apt remove --purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      sudo rm -rf /var/lib/docker /etc/docker /var/run/docker.sock
      ;;
    ohmyzsh)
      rm -rf ~/.oh-my-zsh
      sed -i '/oh-my-zsh/d' ~/.zshrc 2>/dev/null || true
      chsh -s /bin/bash $USER
      ;;
    *)
      log_warning "Unknown component: $component"
      return 1
      ;;
  esac
  log_success "$component uninstalled successfully!"
}

while true; do
  show_uninstall_menu
  echo -ne "${YELLOW}➤ Select a component to uninstall [1-${#COMPONENTS[@]}, 0 to cancel]: ${NC}"
  read -r choice
  if [[ "$choice" == "0" ]]; then
    echo -e "${YELLOW}Uninstall cancelled.${NC}"
    exit 0
  fi
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#COMPONENTS[@]} )); then
    idx=$((choice-1))
    comp="${COMPONENTS[$idx]}"
    name="${COMPONENT_NAMES[$idx]}"
    if prompt_yes_no "Are you sure you want to uninstall $name?" "n"; then
      uninstall_component "$comp"
      if [[ "$comp" == "nginx" || "$comp" == "phpmyadmin" || "$comp" == "pgadmin" || "$comp" == "adminer" ]]; then
        sudo systemctl restart nginx || true
      fi
      echo -e "${GREEN}Done.${NC}"
    else
      echo -e "${YELLOW}Skipped $name.${NC}"
    fi
    echo -ne "${YELLOW}Press ENTER to continue...${NC}"
    read -r
  else
    echo -e "${RED}Invalid choice. Please select a valid component number.${NC}"
    sleep 1
  fi

done 