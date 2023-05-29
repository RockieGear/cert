#!/bin/bash
# Tested Centos 7
# Usage:   wget https://raw.githubusercontent.com/RockieGear/cert/main/set.sh && chmod +x set.sh && bash set.sh <domain.com>

if [ $# -eq 0 ]
then
    echo "Usage: set.sh <domain>"
    exit 1
fi

domain=$1

config_file="/etc/nginx/nginx.conf"
new_certificate="/etc/letsencrypt/live/$domain/fullchain.pem"
new_certificate_key="/etc/letsencrypt/live/$domain/privkey.pem"

yum -y install epel-release

yum -y install snapd

systemctl enable --now snapd.socket

ln -s /var/lib/snapd/snap /snap


max_attempts=10  # Максимальное количество попыток
attempt=1  # Текущая попытка

while ! snap install core; do
  echo "Установка не выполнена успешно. Попытка: $attempt"
  
  if [ $attempt -eq $max_attempts ]; then
    echo "Достигнуто максимальное количество попыток. Скрипт завершает работу."
    exit 1
  fi
  
  attempt=$((attempt + 1))
  sleep 10  # Ожидание перед повторной попыткой
done

echo "Установка выполнена успешно!"


snap refresh core

snap install --classic certbot

ln -s /snap/bin/certbot /usr/bin/certbot
service nginx stop
certbot certonly --standalone --non-interactive --quiet --register-unsafely-without-email --agree-tos --no-redirect -d $domain

cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak


sed -i "s|ssl_certificate\s.*;|ssl_certificate $new_certificate;|g" $config_file
sed -i "s|ssl_certificate_key\s.*;|ssl_certificate_key $new_certificate_key;|g" $config_file

cat /etc/nginx/nginx.conf | grep "ssl_"

service nginx start
