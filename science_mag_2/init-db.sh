#!/bin/bash

# Stop on errors
set -e

echo "Creating data directory with proper permissions..."
docker-compose exec web mkdir -p /usr/local/apache2/data
docker-compose exec web chown www-data:www-data /usr/local/apache2/data
docker-compose exec web chmod 777 /usr/local/apache2/data

echo "Creating empty database files..."
docker-compose exec web touch /usr/local/apache2/data/users.db
docker-compose exec web touch /usr/local/apache2/data/orders.db
docker-compose exec web touch /usr/local/apache2/data/articles.db
docker-compose exec web touch /usr/local/apache2/data/issues.db

echo "Setting permissions for database files..."
docker-compose exec web chown www-data:www-data /usr/local/apache2/data/users.db
docker-compose exec web chown www-data:www-data /usr/local/apache2/data/orders.db
docker-compose exec web chown www-data:www-data /usr/local/apache2/data/articles.db
docker-compose exec web chown www-data:www-data /usr/local/apache2/data/issues.db

docker-compose exec web chmod 666 /usr/local/apache2/data/users.db
docker-compose exec web chmod 666 /usr/local/apache2/data/orders.db
docker-compose exec web chmod 666 /usr/local/apache2/data/articles.db
docker-compose exec web chmod 666 /usr/local/apache2/data/issues.db

echo "Running database initialization script..."
docker-compose exec -u www-data web perl /usr/local/apache2/cgi-bin/init_db.pl

echo "Verifying database files..."
docker-compose exec web ls -la /usr/local/apache2/data/

echo "Database initialization complete. You can now access the web application." 