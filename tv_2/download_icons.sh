#!/bin/bash

# Create directories
mkdir -p public_html/img

# Download some free icons as examples
# Channel icons
curl -o public_html/img/default_channel.png "https://img.icons8.com/color/96/tv.png"
curl -o public_html/img/channel1.png "https://img.icons8.com/color/96/1tv.png"
curl -o public_html/img/channel2.png "https://img.icons8.com/color/96/russia-2.png"
curl -o public_html/img/channel3.png "https://img.icons8.com/color/96/ntv.png"
curl -o public_html/img/channel4.png "https://img.icons8.com/color/96/tnt.png"
curl -o public_html/img/channel5.png "https://img.icons8.com/color/96/sts.png"

# Category icons
curl -o public_html/img/default_category.png "https://img.icons8.com/color/96/category.png"
curl -o public_html/img/category_film.png "https://img.icons8.com/color/96/cinema-.png"
curl -o public_html/img/category_series.png "https://img.icons8.com/color/96/movie.png"
curl -o public_html/img/category_news.png "https://img.icons8.com/color/96/news.png"
curl -o public_html/img/category_sport.png "https://img.icons8.com/color/96/sport.png"
curl -o public_html/img/category_kids.png "https://img.icons8.com/color/96/children.png"
curl -o public_html/img/category_entertainment.png "https://img.icons8.com/color/96/theatre-mask.png"

# Navigation icons
curl -o public_html/img/channels.png "https://img.icons8.com/color/96/tv.png"
curl -o public_html/img/schedule.png "https://img.icons8.com/color/96/timetable.png"
curl -o public_html/img/categories.png "https://img.icons8.com/color/96/categorize.png"
curl -o public_html/img/time.png "https://img.icons8.com/color/96/time.png"

# Additional images
curl -o public_html/img/about.jpg "https://picsum.photos/500/300"
curl -o public_html/img/team1.jpg "https://picsum.photos/100/100?random=1"
curl -o public_html/img/team2.jpg "https://picsum.photos/100/100?random=2"
curl -o public_html/img/team3.jpg "https://picsum.photos/100/100?random=3"
curl -o public_html/img/background.jpg "https://picsum.photos/1920/1080"

echo "Downloaded sample images to public_html/img/"
echo "Note: These are placeholder images. Replace them with your actual images."
echo "Attribution may be required for some of these images." 