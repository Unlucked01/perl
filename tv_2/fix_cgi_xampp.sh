#!/bin/bash

# Set XAMPP directory for Windows
XAMPP_DIR="C:/xampp"

echo "Fixing CGI execution issues in XAMPP..."

# 1. Check if Perl is installed
if [ ! -f "${XAMPP_DIR}/perl/bin/perl.exe" ]; then
    echo "ERROR: Perl not found in XAMPP. Please install Perl for Windows."
    echo "You can download it from https://strawberryperl.com/"
    exit 1
fi

# 2. Fix permissions on CGI scripts
echo "Setting correct permissions on CGI scripts..."
find "${XAMPP_DIR}/cgi-bin" -name "*.pl" -exec chmod 755 {} \;

# 3. Fix line endings (convert CRLF to LF)
echo "Converting script line endings to Unix format..."
if command -v dos2unix &> /dev/null; then
    find "${XAMPP_DIR}/cgi-bin" -name "*.pl" -exec dos2unix {} \;
else
    echo "WARNING: dos2unix not found. Please install Git Bash or manually fix line endings."
    echo "For manual fixing, open each .pl file in Notepad++ and convert to Unix (LF) format."
fi

# 4. Check script headers
echo "Checking script headers..."
for script in "${XAMPP_DIR}"/cgi-bin/*.pl; do
    if [ -f "$script" ]; then
        first_line=$(head -n 1 "$script")
        if [[ ! "$first_line" == *"perl"* ]]; then
            echo "WARNING: $script may have incorrect shebang line: $first_line"
            echo "  The first line should be: #!C:/xampp/perl/bin/perl.exe"
        fi
    fi
done

# 5. Configure Apache for CGI
echo "Configuring Apache for CGI execution..."
HTTPD_CONF="${XAMPP_DIR}/apache/conf/httpd.conf"

if [ -f "$HTTPD_CONF" ]; then
    # Backup config
    cp "$HTTPD_CONF" "${HTTPD_CONF}.bak.$(date +%Y%m%d_%H%M%S)"
    
    # Ensure CGI module is loaded
    sed -i 's/#LoadModule cgi_module/LoadModule cgi_module/g' "$HTTPD_CONF"
    
    # Add CGI handler
    if ! grep -q "AddHandler cgi-script .pl" "$HTTPD_CONF"; then
        echo "AddHandler cgi-script .cgi .pl" >> "$HTTPD_CONF"
    fi
    
    # Setup CGI directory
    echo "Updating CGI directory configuration..."
    cat << EOF > temp_cgi_config
<Directory "${XAMPP_DIR}/cgi-bin">
    AllowOverride None
    Options +ExecCGI
    Require all granted
    AddHandler cgi-script .cgi .pl
</Directory>
EOF
    
    # Replace existing Directory block or add if not exists
    if grep -q "<Directory \".*cgi-bin\">" "$HTTPD_CONF"; then
        # Use sed to replace the existing block
        sed -i '/<Directory ".*cgi-bin">/,/<\/Directory>/c\'"$(cat temp_cgi_config)" "$HTTPD_CONF"
    else
        # Add the new block if it doesn't exist
        echo "$(cat temp_cgi_config)" >> "$HTTPD_CONF"
    fi
    rm temp_cgi_config
else
    echo "ERROR: Apache config file not found at $HTTPD_CONF"
fi

echo "Done! Please restart Apache via XAMPP Control Panel"
echo "If you continue to see errors, check the Apache error log at:"
echo "${XAMPP_DIR}/apache/logs/error.log" 