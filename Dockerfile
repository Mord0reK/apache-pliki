# Stage 1: Build h5ai assets
FROM node:18-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source and build
COPY . .
RUN NODE_OPTIONS="--openssl-legacy-provider" npm run build

# Stage 2: Runtime with Apache + PHP-FPM on Alpine
FROM alpine:3.18

# Install Apache, PHP and required extensions
RUN apk add --no-cache \
    apache2 \
    php82 \
    php82-apache2 \
    php82-fpm \
    php82-mysqli \
    php82-json \
    php82-gd \
    php82-exif \
    php82-mbstring \
    php82-zip \
    php82-ctype \
    php82-curl \
    php82-iconv \
    php82-xml \
    php82-session \
    && rm -rf /var/cache/apk/*

# Configure Apache for h5ai
RUN echo "LoadModule rewrite_module modules/mod_rewrite.so" >> /etc/apache2/httpd.conf && \
    echo "LoadModule deflate_module modules/mod_deflate.so" >> /etc/apache2/httpd.conf && \
    echo "LoadModule expires_module modules/mod_expires.so" >> /etc/apache2/httpd.conf && \
    echo "LoadModule headers_module modules/mod_headers.so" >> /etc/apache2/httpd.conf && \
    sed -i 's|DirectoryIndex index.html|DirectoryIndex index.html index.php /_h5ai/public/index.php|g' /etc/apache2/httpd.conf && \
    sed -i 's|DocumentRoot "/var/www/localhost/htdocs"|DocumentRoot "/var/www/html"|g' /etc/apache2/httpd.conf && \
    sed -i 's|<Directory "/var/www/localhost/htdocs">|<Directory "/var/www/html">|g' /etc/apache2/httpd.conf && \
    sed -i 's|AllowOverride None|AllowOverride All|g' /etc/apache2/httpd.conf && \
    sed -i 's|User apache|User apache|g' /etc/apache2/httpd.conf && \
    sed -i 's|Group apache|Group apache|g' /etc/apache2/httpd.conf

# Additional Apache configuration (modules already enabled above)
RUN echo "<Directory /var/www/html>" >> /etc/apache2/httpd.conf && \
    echo "    Options Indexes FollowSymLinks" >> /etc/apache2/httpd.conf && \
    echo "    AllowOverride All" >> /etc/apache2/httpd.conf && \
    echo "    Require all granted" >> /etc/apache2/httpd.conf && \
    echo "</Directory>" >> /etc/apache2/httpd.conf && \
    echo "<Directory /var/www/html/files>" >> /etc/apache2/httpd.conf && \
    echo "    Options Indexes FollowSymLinks" >> /etc/apache2/httpd.conf && \
    echo "    AllowOverride All" >> /etc/apache2/httpd.conf && \
    echo "    Require all granted" >> /etc/apache2/httpd.conf && \
    echo "</Directory>" >> /etc/apache2/httpd.conf && \
    echo "Alias /_h5ai /opt/h5ai" >> /etc/apache2/httpd.conf && \
    echo "<Directory /opt/h5ai>" >> /etc/apache2/httpd.conf && \
    echo "    Options FollowSymLinks" >> /etc/apache2/httpd.conf && \
    echo "    AllowOverride None" >> /etc/apache2/httpd.conf && \
    echo "    Require all granted" >> /etc/apache2/httpd.conf && \
    echo "</Directory>" >> /etc/apache2/httpd.conf && \
    echo "<Directory /var/www/html/_h5ai>" >> /etc/apache2/httpd.conf && \
    echo "    Options FollowSymLinks" >> /etc/apache2/httpd.conf && \
    echo "    AllowOverride None" >> /etc/apache2/httpd.conf && \
    echo "    Require all granted" >> /etc/apache2/httpd.conf && \
    echo "</Directory>" >> /etc/apache2/httpd.conf

# Configure PHP-FPM
RUN sed -i 's|user = nobody|user = apache|g' /etc/php82/php-fpm.d/www.conf && \
    sed -i 's|group = nobody|group = apache|g' /etc/php82/php-fpm.d/www.conf && \
    sed -i 's|listen = 127.0.0.1:9000|listen = /var/run/php-fpm82.sock|g' /etc/php82/php-fpm.d/www.conf && \
    sed -i 's|;listen.owner = nobody|listen.owner = apache|g' /etc/php82/php-fpm.d/www.conf && \
    sed -i 's|;listen.group = apache|listen.group = apache|g' /etc/php82/php-fpm.d/www.conf && \
    sed -i 's|;listen.mode = 0660|listen.mode = 0660|g' /etc/php82/php-fpm.d/www.conf

# Copy built h5ai files to temporary location
COPY --from=builder /app/build/_h5ai /opt/h5ai

# Copy custom configurations
COPY docker/apache-h5ai.conf /etc/apache2/conf.d/h5ai.conf
COPY docker/php.ini /etc/php82/php.ini

# Create necessary directories and set permissions
RUN mkdir -p /var/run/php-fpm && \
    chown -R apache:apache /opt/h5ai && \
    chmod -R 755 /opt/h5ai/private/cache && \
    chmod -R 755 /opt/h5ai/public/cache

# Expose port
EXPOSE 80

# Start script
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set proper ownership for h5ai in temporary location
RUN chown -R apache:apache /opt/h5ai

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["httpd", "-D", "FOREGROUND"]