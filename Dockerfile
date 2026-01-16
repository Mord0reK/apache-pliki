FROM node:18-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
# Required for webpack 4/OpenSSL 3 compatibility during the build.
RUN NODE_OPTIONS=--openssl-legacy-provider npm run build

FROM alpine:3.14

ENV PUID=911 \
    PGID=911 \
    TZ=UTC \
    HTPASSWD=false

RUN apk add --no-cache \
        nginx \
        supervisor \
        php8 \
        php8-fpm \
        php8-opcache \
        php8-session \
        php8-json \
        php8-ctype \
        php8-curl \
        php8-gd \
        php8-exif \
        php8-zip \
        php8-zlib \
        php8-fileinfo \
        php8-mbstring \
        php8-dom \
        php8-simplexml \
        php8-xml \
        php8-iconv \
        php8-openssl \
        php8-phar \
        tzdata \
        apache2-utils \
        ffmpeg \
        imagemagick \
        zip \
        unzip \
        tar \
    && mkdir -p /run/nginx /run/php /config/nginx /config/h5ai /defaults/nginx /defaults/h5ai /h5ai \
    && sed -i 's/^user = .*/user = nginx/' /etc/php8/php-fpm.d/www.conf \
    && sed -i 's/^group = .*/group = nginx/' /etc/php8/php-fpm.d/www.conf \
    && sed -i 's|^listen = .*|listen = 127.0.0.1:9000|' /etc/php8/php-fpm.d/www.conf \
    && sed -i 's/^;clear_env = no/clear_env = no/' /etc/php8/php-fpm.d/www.conf

COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/site.conf /defaults/nginx/site.conf
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/php-opcache-jit.ini /etc/php8/conf.d/99-opcache-jit.ini
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY --from=build /app/build/_h5ai /defaults/h5ai

EXPOSE 80
VOLUME ["/h5ai", "/config"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
