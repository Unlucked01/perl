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

RUN chmod +x /usr/local/apache2/cgi-bin/*.pl && \
    chmod +x /usr/local/apache2/cgi-bin/lib/*.pm && \
    chown -R www-data:www-data /usr/local/apache2/htdocs/ && \
    chown -R www-data:www-data /usr/local/apache2/cgi-bin && \
    mkdir -p /usr/local/apache2/data && \
    chown www-data:www-data /usr/local/apache2/data && \
    chmod 777 /usr/local/apache2/data && \
    perl create_dict.pl

ENV PERL_UNICODE=SDA

EXPOSE 8080
CMD ["httpd-foreground"]
