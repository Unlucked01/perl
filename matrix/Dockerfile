FROM httpd:2.4

RUN apt-get update && apt-get install -y \
    perl \
    libcgi-pm-perl \
    libjson-perl \
    && rm -rf /var/lib/apt/lists/*

COPY ./httpd.conf /usr/local/apache2/conf/httpd.conf
COPY ./cgi-bin/ /usr/local/apache2/cgi-bin/
COPY ./public_html/ /usr/local/apache2/htdocs/

WORKDIR /usr/local/apache2/cgi-bin

RUN chmod +x /usr/local/apache2/cgi-bin/* && \
    chown -R www-data:www-data /usr/local/apache2/htdocs/ && \
    chown -R www-data:www-data /usr/local/apache2/cgi-bin

EXPOSE 8083
CMD ["httpd-foreground"] 