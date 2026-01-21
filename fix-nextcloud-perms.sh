#!/bin/bash
# Script om permissies te herstellen voor de Nextcloud Docker container
CONTAINER="nextcloud-app"

echo "Stap 1: Eigenaarschap herstellen naar www-data (UID 33)..."
docker exec -u root $CONTAINER chown -R www-data:www-data /var/www/html

echo "Stap 2: Map-permissies instellen (750)..."
docker exec -u root $CONTAINER find /var/www/html/ -type d -exec chmod 750 {} \;

echo "Stap 3: Bestands-permissies instellen (640)..."
docker exec -u root $CONTAINER find /var/www/html/ -type f -exec chmod 640 {} \;

echo "Stap 4: .ocdata controlebestand verifiëren..."
docker exec -u www-data $CONTAINER touch /var/www/html/data/.ocdata

echo "Stap 5: Container herstarten om wijzigingen te activeren..."
docker restart $CONTAINER

echo "Klaar! Controleer je browser op [https://nextcloud.piselfhosting.com](https://nextcloud.piselfhosting.com)"