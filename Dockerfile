# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: yhakamaya <yhakamaya@student.42tokyo.      +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2021/02/14 11:56:54 by yhakamaya         #+#    #+#              #
#    Updated: 2021/02/25 16:13:38 by yhakamaya        ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# decide guest OS: debian 10 (buster)
FROM debian:buster

# 0. get prepared for installing packages
# 1. install nginx and mariadb
# 2. install php
# 3. install utils
RUN set -ex; \
	apt-get update && \
	apt-get install -y \
		nginx mariadb-server mariadb-client \
		php-curl php-dom php-mbstring php-mysqli \
		php-imagick php-xml php-zip php-gd php-fpm \
		vim wget curl

# lighten the cache by removing unnecessary files
# see: https://qiita.com/YumaInaura/items/8cff209a4bc49a2c6fe1
RUN set -ex; \
	rm -rf /var/lib/apt/lists/*

# set the valiables decide version of packages
# see: https://www.geeksforgeeks.org/docker-arg-instruction/
ARG entrykit_v="0.4.0"
ARG phpmyadmin_v="5.0.4"

# install Entrykit
# use 'wget' because 'apt-get install' is unavailable for entrykit
# see: https://qiita.com/spesnova/items/bae6406bf69d2dc6f88b
RUN set -ex; \
	wget https://github.com/progrium/entrykit/releases/download/v${entrykit_v}/entrykit_${entrykit_v}_Linux_x86_64.tgz; \
	tar -xvzf entrykit_${entrykit_v}_Linux_x86_64.tgz; \
	rm entrykit_${entrykit_v}_Linux_x86_64.tgz; \
	mv entrykit /bin/entrykit; \
	chmod +x /bin/entrykit; \
	entrykit --symlink

# install wordpress
# use 'wget' because 'apt-get install' is unavailable for wordpress
# see: https://wordpress.org/support/article/how-to-install-wordpress/
RUN set -ex; \
	wget https://wordpress.org/latest.tar.gz; \
	tar xsfv latest.tar.gz; \
	rm latest.tar.gz; \
	mv wordpress/ /var/www/html

# install phpMyAdmin
# ${phpmyadmin_v} is the latest as of Feb 10 2021
# use 'wget' because 'apt-get install' is unavailable for phpMyAdmin
# see: https://www.digitalocean.com/community/tutorials/how-to-install-phpmyadmin-from-source-debian-10
RUN set -ex; \
	wget https://files.phpmyadmin.net/phpMyAdmin/${phpmyadmin_v}/phpMyAdmin-${phpmyadmin_v}-all-languages.tar.gz; \
	tar xsfv phpMyAdmin-${phpmyadmin_v}-all-languages.tar.gz; \
	rm phpMyAdmin-${phpmyadmin_v}-all-languages.tar.gz; \
	mv phpMyAdmin-${phpmyadmin_v}-all-languages phpmyadmin; \
	mv phpmyadmin/ /var/www/html

# copy three files from host OS to debian:buster
COPY ./srcs/default.tmpl /etc/nginx/sites-available/default.tmpl
COPY ./srcs/wp-config.php /var/www/html/wordpress/wp-config.php
COPY ./srcs/getstarted.sh getstarted.sh

# create a self-signed SSL certificate
# see: https://linuxize.com/post/creating-a-self-signed-ssl-certificate/
RUN set -ex; \
	mkdir /etc/nginx/certificate; \
	openssl req \
	-subj '/C=JP/ST=Tokyo/L=Bunkyo/O=42 Tokyo/OU=Student/CN=yhakamay' \
	-x509 -nodes -days 365 -newkey rsa:4096 \
	-keyout /etc/nginx/certificate/server.key \
	-out /etc/nginx/certificate/server.crt; \
	chmod -R 400 /etc/nginx/certificate

# make the user 'www-data' (nginx) can access /var/www
# see: https://unix.stackexchange.com/questions/295483/chown-r-www-datawww-data-sets-ownership-to-root
RUN set -ex; \
	chown -R www-data:www-data /var/www/html/index.nginx-debian.html

# start mysql and grant access of mysql to user 'wp_admin'
# see: https://uxmilk.jp/12323
RUN set -ex; \
	service mysql start; \
	mysql -e "CREATE DATABASE wordpress \
	DEFAULT CHARACTER SET utf8 \
	DEFAULT COLLATE utf8_unicode_ci; \
	GRANT ALL ON wordpress.* TO wp_admin@localhost identified by 'password'"

# expose two ports: 80 and 443
# see: https://www.whitesourcesoftware.com/free-developer-tools/blog/docker-expose-port/
EXPOSE 80
EXPOSE 443

# initialize the container using entrykit
# using entrykit is faster than 'CMD tail -f /dev/null'
# see: https://qiita.com/hihihiroro/items/d7ceaadc9340a4dbeb8f
ENTRYPOINT ["render", "/etc/nginx/sites-available/default", "--", "bash", "./getstarted.sh"]
