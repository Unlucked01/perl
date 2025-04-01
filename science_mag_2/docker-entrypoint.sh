#!/bin/bash
set -e

mkdir -p /usr/local/apache2/data

chown -R www-data:www-data /usr/local/apache2/data
chmod 755 /usr/local/apache2/data

su -s /bin/bash -c "perl /usr/local/apache2/cgi-bin/init_db.pl" www-data

exec "$@" 