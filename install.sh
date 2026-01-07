#!/usr/bin/env bash
set -e

echo "========================================="
echo "?? Установка проекта VPNMarket (RU)"
echo "========================================="

read -p "?? Домен (оставьте пустым для IP): " DOMAIN

APP_DIR="/opt/VPNMarket-RU"
DB_NAME="vpnmarket"
DB_USER="vpnmarket"
DB_PASS="$(openssl rand -hex 12)"

echo "?? Обновление системы..."
apt update -y

echo "?? Установка зависимостей..."
apt install -y software-properties-common curl zip unzip git nginx mariadb-server

add-apt-repository ppa:ondrej/php -y
apt update -y
apt install -y php8.2 php8.2-fpm php8.2-cli php8.2-mbstring php8.2-xml php8.2-curl php8.2-mysql php8.2-zip php8.2-bcmath composer

echo "??️ Настройка базы данных..."
mysql <<MYSQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
MYSQL

echo "?? Клонирование проекта..."
rm -rf ${APP_DIR}
git clone https://github.com/marazban1tm-droid/VPNMarket-RU.git ${APP_DIR}
cd ${APP_DIR}

echo "?? Установка composer зависимостей..."
composer install --no-dev --optimize-autoloader

echo "⚙️ Настройка .env"
cp .env.example .env

sed -i "s|APP_ENV=.*|APP_ENV=production|" .env
sed -i "s|APP_DEBUG=.*|APP_DEBUG=false|" .env
sed -i "s|APP_URL=.*|APP_URL=http://${DOMAIN:-$(curl -s ifconfig.me)}|" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|" .env

php artisan key:generate

echo "?? Миграции базы данных..."
php artisan migrate --force
php artisan db:seed --force

echo "?? Очистка кеша..."
php artisan optimize:clear

echo "?? Настройка Nginx..."
cat > /etc/nginx/sites-available/vpnmarket <<NGINX
server {
    listen 80;
    server_name ${DOMAIN:-_};

    root ${APP_DIR}/public;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/vpnmarket /etc/nginx/sites-enabled/vpnmarket
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo "========================================="
echo "✅ УСТАНОВКА ЗАВЕРШЕНА"
echo "?? Панель: http://${DOMAIN:-$(curl -s ifconfig.me)}/admin"
echo "?? Создать администратора:"
echo "   cd ${APP_DIR} && php artisan make:filament-user"
echo "??️ БД: ${DB_NAME}"
echo "?? Пользователь БД: ${DB_USER}"
echo "?? Пароль БД: ${DB_PASS}"
echo "========================================="
