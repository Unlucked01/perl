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

# Добавляем заглушки для изображений
RUN echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="#3498db"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">Канал</text></svg>' > /usr/local/apache2/htdocs/img/default_channel.png && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="#2ecc71"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">Категория</text></svg>' > /usr/local/apache2/htdocs/img/default_category.png && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="#3498db"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">Первый канал</text></svg>' > /usr/local/apache2/htdocs/img/channel1.png && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="#e74c3c"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">Россия 1</text></svg>' > /usr/local/apache2/htdocs/img/channel2.png && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="#9b59b6"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">НТВ</text></svg>' > /usr/local/apache2/htdocs/img/channel3.png && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="#f1c40f"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">ТНТ</text></svg>' > /usr/local/apache2/htdocs/img/channel4.png && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="#1abc9c"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">СТС</text></svg>' > /usr/local/apache2/htdocs/img/channel5.png && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="#e74c3c"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">Фильмы</text></svg>' > /usr/local/apache2/htdocs/img/category_film.png && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="#9b59b6"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">Сериалы</text></svg>' > /usr/local/apache2/htdocs/img/category_series.png && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="#3498db"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">Новости</text></svg>' > /usr/local/apache2/htdocs/img/category_news.png && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="#2ecc71"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">Спорт</text></svg>' > /usr/local/apache2/htdocs/img/category_sport.png && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="#f1c40f"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">Детские</text></svg>' > /usr/local/apache2/htdocs/img/category_kids.png && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="#e67e22"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">Развлекательные</text></svg>' > /usr/local/apache2/htdocs/img/category_entertainment.png && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="#3498db"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">Каналы</text></svg>' > /usr/local/apache2/htdocs/img/channels.png && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="#2ecc71"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">Расписание</text></svg>' > /usr/local/apache2/htdocs/img/schedule.png && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="#9b59b6"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">Категории</text></svg>' > /usr/local/apache2/htdocs/img/categories.png && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><rect width="100" height="100" fill="#e74c3c"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">Время</text></svg>' > /usr/local/apache2/htdocs/img/time.png && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="500" height="300" viewBox="0 0 500 300"><rect width="500" height="300" fill="#34495e"/><text x="250" y="150" font-family="Arial" font-size="24" fill="white" text-anchor="middle" dominant-baseline="middle">О проекте ТВ Программа</text></svg>' > /usr/local/apache2/htdocs/img/about.jpg && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><circle cx="50" cy="50" r="40" fill="#3498db"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">Разработчик</text></svg>' > /usr/local/apache2/htdocs/img/team1.jpg && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><circle cx="50" cy="50" r="40" fill="#e74c3c"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">Дизайнер</text></svg>' > /usr/local/apache2/htdocs/img/team2.jpg && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100"><circle cx="50" cy="50" r="40" fill="#2ecc71"/><text x="50" y="50" font-family="Arial" font-size="12" fill="white" text-anchor="middle" dominant-baseline="middle">Контент</text></svg>' > /usr/local/apache2/htdocs/img/team3.jpg && \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080"><rect width="1920" height="1080" fill="#34495e"/><pattern id="pattern" patternUnits="userSpaceOnUse" width="30" height="30" patternTransform="rotate(45)"><rect width="15" height="15" fill="#2c3e50"/></pattern><rect width="1920" height="1080" fill="url(#pattern)"/></svg>' > /usr/local/apache2/htdocs/img/background.jpg

WORKDIR /usr/local/apache2/cgi-bin

RUN chmod +x /usr/local/apache2/cgi-bin/* && \
    chown -R www-data:www-data /usr/local/apache2/htdocs/ && \
    chown -R www-data:www-data /usr/local/apache2/cgi-bin && \
    chown -R www-data:www-data /usr/local