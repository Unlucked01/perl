FROM httpd:2.4

# Install Perl and required modules
RUN apt-get update && apt-get install -y \
    perl \
    libcgi-pm-perl \
    libdb-file-lock-perl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /usr/local/apache2/htdocs/static/css \
    && mkdir -p /usr/local/apache2/htdocs/static/js

# Copy configuration
COPY conf/httpd.conf /usr/local/apache2/conf/httpd.conf

# Copy web content
COPY html/ /usr/local/apache2/htdocs/
COPY cgi-bin/ /usr/local/apache2/cgi-bin/

# Set proper permissions
RUN chmod +x /usr/local/apache2/cgi-bin/*.pl \
    && chown -R www-data:www-data /usr/local/apache2/cgi-bin

# Create data directory and set permissions
RUN mkdir -p /usr/local/apache2/data \
    && chown -R www-data:www-data /usr/local/apache2/data

# Initialize database on container start
RUN touch /usr/local/apache2/data/users.db \
    && chown www-data:www-data /usr/local/apache2/data/users.db

EXPOSE 80