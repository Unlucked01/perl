FROM httpd:2.4

RUN apt-get update && apt-get install -y \
    perl \
    libcgi-pm-perl \
    libdb-file-lock-perl \
    libdigest-sha-perl \
    wget \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/apache2/htdocs/{css,js,img} \
    && mkdir -p /usr/local/apache2/data


COPY conf/httpd.conf /usr/local/apache2/conf/httpd.conf

COPY html/ /usr/local/apache2/htdocs/
COPY cgi-bin/ /usr/local/apache2/cgi-bin/

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/apache2/cgi-bin/*.pl \
    && chown -R www-data:www-data /usr/local/apache2/cgi-bin \
    && chown -R www-data:www-data /usr/local/apache2/data

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["httpd-foreground"]