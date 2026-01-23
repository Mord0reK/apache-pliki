#!/bin/sh

# Entry point script for h5ai Docker container
# This script initializes the environment and starts Apache + PHP-FPM

set -e

echo "Starting h5ai Docker container..."

# Create necessary directories
mkdir -p /var/log/php82
mkdir -p /var/run/php-fpm

# Set proper ownership and permissions
chown -R apache:apache /var/log/php82
chown -R apache:apache /var/run/php-fpm

# Ensure cache directories are writable
mkdir -p /var/www/html/_h5ai/private/cache
mkdir -p /var/www/html/_h5ai/public/cache
chmod -R 755 /var/www/html/_h5ai/private/cache
chmod -R 755 /var/www/html/_h5ai/public/cache

# Don't change ownership of mounted volumes (they have their own permissions)
echo "Skipping ownership change for mounted volumes..."

# Check if custom configuration exists and copy if needed
if [ -d "/var/www/html/_h5ai/private/conf" ]; then
    echo "Custom h5ai configuration found in /var/www/html/_h5ai/private/conf"
else
    echo "Using default h5ai configuration"
fi

# Ensure h5ai directory is available in web root
echo "Ensuring h5ai files are available in web root..."
mkdir -p /var/www/html/_h5ai
cp -r /opt/h5ai/* /var/www/html/_h5ai/ 2>/dev/null && echo "h5ai files copied to /var/www/html/_h5ai" || echo "Failed to copy h5ai files"

# Copy h5ai index.php to web root if no index.php exists
if [ ! -f "/var/www/html/index.php" ]; then
    cp /opt/h5ai/public/index.php /var/www/html/index.php 2>/dev/null && echo "h5ai index.php copied to web root" || echo "Failed to copy h5ai index.php"
fi

# Create a basic index.html in web root if no files exist and no index.html exists
if [ ! -f "/var/www/html/index.html" ] && [ ! -f "/var/www/html/index.php" ] && [ "$(find /var/www/html -maxdepth 1 -type f | wc -l)" -eq 0 ]; then
    echo "<h1>Welcome to h5ai</h1><p>Your files will appear here. Add files to the ./data directory.</p>" > /var/www/html/index.html
    echo "Created default index.html in web root"
fi

# Check if PHP-FPM is running and start it if not
echo "Starting PHP-FPM..."
php-fpm82 --daemonize

# Wait a moment for PHP-FPM to start
sleep 2

# Check if PHP-FPM started successfully
if ! pgrep php-fpm82 > /dev/null; then
    echo "ERROR: PHP-FPM failed to start"
    exit 1
fi

echo "PHP-FPM started successfully"

# Check Apache configuration
echo "Checking Apache configuration..."
if ! httpd -t; then
    echo "ERROR: Apache configuration test failed"
    exit 1
fi

echo "Apache configuration is valid"

# Display container information
echo "=== Container Information ==="
echo "h5ai Version: $(cat /var/www/html/_h5ai/version.txt 2>/dev/null || echo 'unknown')"
echo "PHP Version: $(php -v | head -n 1)"
echo "Apache Version: $(httpd -v | head -n 1)"
echo "Document Root: /var/www/html"
echo "Files Directory: /var/www/html/files"
echo "h5ai Installation: /var/www/html/_h5ai"
echo "=========================="

# Display useful URLs
echo ""
echo "=== Useful URLs ==="
echo "Main h5ai interface: http://localhost:8080/_h5ai/public/index.php"
echo "Files listing: http://localhost:8080/files/"
echo "Root directory: http://localhost:8080/"
echo "=================="

# Handle signals gracefully
trap 'echo "Stopping services..."; killall php-fpm82 2>/dev/null || true; exit 0' TERM INT

# Start Apache in foreground
echo "Starting Apache..."
exec "$@"