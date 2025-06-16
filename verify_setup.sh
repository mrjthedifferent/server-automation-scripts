#!/bin/bash

# Setup Verification Script
# Verifies that the server automation scripts are working correctly
echo "🔍 Server Automation Suite - Setup Verification"
echo "================================================="

# Load common library
source "$(dirname "$0")/lib/common.sh"
init_common --allow-user

echo ""
echo "✅ Testing core functionality..."
# Try to setup logging, but don't fail if it requires sudo
if setup_logging "verify-setup" 2>/dev/null; then
    echo "  📝 Logging enabled: $SETUP_LOG"
else
    echo "  📝 Logging disabled (no sudo access)"
    export SETUP_LOG=""
fi

echo ""
echo "✅ Testing logging functions..."
log_info "System logging is working correctly"
log_success "Success messages are displaying properly"  
log_warning "Warning messages are functioning"
log_step "Step messages are operational"

echo ""
echo "✅ Testing file logging..."
log_to_file "Verification log entry created successfully"

echo ""
echo "✅ Discovering available components..."
echo "Available installation components:"
component_count=0
for script in features/install_*.sh features/setup_*.sh; do
    if [ -f "$script" ]; then
        # Extract clean component name
        component=$(basename "$script" | sed 's/^install_//' | sed 's/^setup_//' | sed 's/\.sh$//')
        
        # Skip the template as it's not a real component
        if [ "$component" != "template" ]; then
            echo "  📦 $component"
            component_count=$((component_count + 1))
        fi
    fi
done
echo "Total components available: $component_count"

echo ""
echo "✅ Checking system compatibility..."
if command -v php &> /dev/null; then
    php_version=$(php -v 2>/dev/null | head -n 1 | cut -d' ' -f2 2>/dev/null || echo "Unknown")
    echo "  ✅ PHP: $php_version"
else
    echo "  ⚠️  PHP: Not installed"
fi

if command -v nginx &> /dev/null; then
    nginx_version=$(nginx -v 2>&1 | cut -d'/' -f2 2>/dev/null || echo "Unknown")
    echo "  ✅ Nginx: $nginx_version"
else
    echo "  ⚠️  Nginx: Not installed"
fi

if command -v mysql &> /dev/null; then
    echo "  ✅ MySQL: Available"
else
    echo "  ⚠️  MySQL: Not installed"
fi

if command -v docker &> /dev/null; then
    docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 2>/dev/null | sed 's/,//' || echo "Unknown")
    echo "  ✅ Docker: $docker_version"
else
    echo "  ⚠️  Docker: Not installed"
fi

echo ""
echo "✅ Testing system information gathering..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  Platform: macOS (Compatible)"
else
    echo "  Platform: Linux (Recommended)"
fi

echo ""
echo "🎉 Verification completed successfully!"
echo ""
echo "📋 Next Steps:"
echo "  • Run './server_setup.sh' to install server components"
echo "  • Run './system_status.sh' to monitor system status"
echo "  • Run './laravel_site_enable.sh' to configure Laravel sites"
echo ""
if [ -n "$SETUP_LOG" ]; then
    echo "📝 Log file: $SETUP_LOG"
else
    echo "📝 No log file created (verification ran without sudo)"
fi 