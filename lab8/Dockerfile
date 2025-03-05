FROM httpd:2.4

RUN apt-get update && apt-get install -y \
    perl \
    libdb-dev \
    libdb-file-lock-perl \
    libcgi-pm-perl \
    && rm -rf /var/lib/apt/lists/*

COPY ./httpd.conf /usr/local/apache2/conf/httpd.conf
COPY ./cgi-bin/ /usr/local/apache2/cgi-bin/
COPY ./public_html/ /usr/local/apache2/htdocs/

WORKDIR /usr/local/apache2/cgi-bin

RUN chmod +x /usr/local/apache2/cgi-bin/* && \
    chown -R www-data:www-data /usr/local/apache2/htdocs/ && \
    chown www-data:www-data /usr/local/apache2/cgi-bin && \
    rm -f dictionary.db translations.txt && \
    perl create_dict.pl && \
    chown www-data:www-data dictionary.db && \
    chmod 666 dictionary.db && \
    touch translations.txt && \
    chown www-data:www-data translations.txt && \
    chmod 666 translations.txt

EXPOSE 8080
CMD ["httpd-foreground"]
