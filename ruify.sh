#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
echo "==> Repo: $ROOT"

# 0) Kontroller
[ -f composer.json ] || { echo "❌ composer.json yok. VPNMarket kök dizininde değilsin."; exit 1; }
[ -d lang ] || { echo "❌ lang/ klasörü yok."; exit 1; }

echo "==> 1) lang/ içinde mevcut diller:"
ls -la lang || true

# 1) RU klasörünü oluştur (öncelik: en -> ru, yoksa fa -> ru)
if [ -d "lang/ru" ]; then
  echo "==> lang/ru zaten var. Yeniden oluşturmayacağım."
else
  if [ -d "lang/en" ]; then
    echo "==> 2) lang/en -> lang/ru kopyalanıyor (önerilen temel)."
    cp -a lang/en lang/ru
  elif [ -d "lang/fa" ]; then
    echo "==> 2) lang/fa -> lang/ru kopyalanıyor (en yok, temel olarak fa kullanılıyor)."
    cp -a lang/fa lang/ru
  else
    echo "❌ lang/en veya lang/fa bulunamadı. lang/ altında hangi klasörler var, onu paylaş."
    exit 1
  fi
fi

# 2) Laravel locale ayarla (config/app.php)
if [ -f config/app.php ]; then
  echo "==> 3) config/app.php içinde locale=ru, fallback_locale=en ayarlanıyor (güvenli)."
  php -r 
