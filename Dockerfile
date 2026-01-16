FROM node:18-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
# Required for webpack 4/OpenSSL 3 compatibility during the build.
RUN NODE_OPTIONS=--openssl-legacy-provider npm run build

FROM php:8.2-apache
ENV APACHE_DOCUMENT_ROOT=/var/www/h5ai/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

COPY --from=build --chown=www-data:www-data /app/build/_h5ai /var/www/h5ai
