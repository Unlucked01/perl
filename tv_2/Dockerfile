FROM httpd:2.4

RUN apt-get update && apt-get install -y \
    perl \
    libdb-dev \
    libdb-file-lock-perl \
    libcgi-pm-perl \
    libpath-tiny-perl \
    && rm -rf /var/lib/apt/lists/*

COPY ./httpd.conf /usr/local/apache2/conf/httpd.conf
COPY ./cgi-bin/ /usr/local/apache2/cgi-bin/
COPY ./public_html/ /usr/local/apache2/htdocs/

# Создаем директорию для данных и устанавливаем права
RUN mkdir -p /usr/local/apache2/data && \
    chmod 777 /usr/local/apache2/data

# Создаем директорию для изображений
RUN mkdir -p /usr/local/apache2/htdocs/img && \
    chmod 777 /usr/local/apache2/htdocs/img

VOLUME ["/usr/local/apache2/data"]

WORKDIR /usr/local/apache2/cgi-bin

RUN chmod +x /usr/local/apache2/cgi-bin/* && \
    chown -R www-data:www-data /usr/local/apache2/htdocs/ && \
    chown -R www-data:www-data /usr/local/apache2/cgi-bin && \
    chown -R www-data:www-data /usr/local/apache2/data && \
    chmod 777 /usr/local/apache2/cgi-bin