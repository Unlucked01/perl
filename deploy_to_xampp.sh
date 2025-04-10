#!/bin/bash

# Set XAMPP directory for Windows
XAMPP_DIR="C:/xampp"

# Source directories
PROJECT_DIR="$(pwd)"
CGI_DIR="${PROJECT_DIR}/cgi-bin"
HTML_DIR="${PROJECT_DIR}/public_html"

# Create data directory if it doesn't exist
mkdir -p "${XAMPP_DIR}/data"
chmod 777 "${XAMPP_DIR}/data"

# Copy CGI scripts to XAMPP cgi-bin directory
echo "Copying CGI scripts..."
cp -r ${CGI_DIR}/* "${XAMPP_DIR}/cgi-bin/"

# Make sure Perl scripts are executable
echo "Setting script permissions..."
chmod +x "${XAMPP_DIR}/cgi-bin/"*.pl

# Fix line endings for Windows
echo "Converting line endings for Windows compatibility..."
if command -v dos2unix &> /dev/null; then
    dos2unix "${XAMPP_DIR}/cgi-bin/"*.pl
else
    echo "Warning: dos2unix not found. You may need to install Git Bash or manually fix line endings."
    echo "For manual fixing, open each .pl file in a text editor like Notepad++ and convert to Unix (LF) format."
fi

# Copy HTML and other web files
echo "Copying web files..."
cp -r ${HTML_DIR}/* "${XAMPP_DIR}/htdocs/"

# Create img directory if it doesn't exist
mkdir -p "${XAMPP_DIR}/htdocs/img"
chmod 777 "${XAMPP_DIR}/htdocs/img"

# Set Windows-appropriate permissions
echo "Setting Windows permissions..."
chmod -R 755 "${XAMPP_DIR}/cgi-bin"
chmod 777 "${XAMPP_DIR}/cgi-bin"

# Check Apache configuration file location for Windows
HTTPD_CONF="${XAMPP_DIR}/apache/conf/httpd.conf"
if [ -f "$HTTPD_CONF" ]; then
    echo "Checking Apache configuration..."
    if ! grep -q "^LoadModule cgi_module" "$HTTPD_CONF"; then
        echo "Enabling CGI module in Apache config..."
        echo "LoadModule cgi_module modules/mod_cgi.so" >> "$HTTPD_CONF"
    fi
    
    # Ensure CGI execution is enabled
    if ! grep -q "AddHandler cgi-script .pl" "$HTTPD_CONF"; then
        echo "Adding handler for Perl scripts..."
        echo "AddHandler cgi-script .cgi .pl" >> "$HTTPD_CONF"
    fi
else
    echo "Warning: Apache config file not found at $HTTPD_CONF"
    echo "You will need to manually enable CGI in your XAMPP Apache configuration."
fi

echo "Deployment completed! Please restart XAMPP to apply changes."
echo "If you encounter problems with CGI execution:"
echo "1. Open XAMPP Control Panel"
echo "2. Click 'Config' button for Apache"
echo "3. Select 'httpd.conf'"
echo "4. Ensure these lines are uncommented:"
echo "   LoadModule cgi_module modules/mod_cgi.so"
echo "   AddHandler cgi-script .cgi .pl"
echo "5. Ensure the cgi-bin directory has 'Options +ExecCGI' set" 