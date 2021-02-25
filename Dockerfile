# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: yhakamaya <yhakamaya@student.42tokyo.      +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2021/02/14 11:56:54 by yhakamaya         #+#    #+#              #
#    Updated: 2021/02/14 11:56:56 by yhakamaya        ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

FROM debian:buster

ARG phpmyadmin_v="5.0.4"

RUN apt-get update && \
	apt-get install -y \
		nginx mariadb-server mariadb-client \
		php-curl php-dom php-mbstring php-mysqli \
		php-imagick php-xml php-zip php-gd php-fpm \
		vim wget curl \
	&& rm -rf /var/lib/apt/lists/*

RUN	wget https://wordpress.org/latest.tar.gz \
	&& tar xsfv latest.tar.gz \
	&& rm latest.tar.gz \
	&& mv wordpress/ /var/www/html \
	&& wget https://files.phpmyadmin.net/phpMyAdmin/${phpmyadmin_v}/phpMyAdmin-${phpmyadmin_v}-all-languages.tar.gz \
	&& tar xsfv phpMyAdmin-${phpmyadmin_v}-all-languages.tar.gz \
	&& rm phpMyAdmin-${phpmyadmin_v}-all-languages.tar.gz \
	&& mv phpMyAdmin-${phpmyadmin_v}-all-languages phpmyadmin \
	&& mv phpmyadmin/ /var/www/html

# copy three files from host OS to debian:buster
COPY ./srcs/default.tmpl /etc/nginx/sites-available/default.tmpl
COPY ./srcs/wp-config.php /var/www/html/wordpress/wp-config.php
COPY ./srcs/getstarted.sh getstarted.sh

# create a self-signed SSL certificate
# see: https://linuxize.com/post/creating-a-self-signed-ssl-certificate/
RUN mkdir /etc/nginx/certificate \
	&& openssl req \
	-subj '/C=JP/ST=Tokyo/L=Bunkyo/O=42 Tokyo/OU=Student/CN=yhakamay' \
	-x509 -nodes -days 365 -newkey rsa:4096 \
	-keyout /etc/nginx/certificate/server.key \
	-out /etc/nginx/certificate/server.crt; \
	chmod -R 400 /etc/nginx/certificate

# make the user 'www-data' (nginx) can access /var/www
# see: https://unix.stackexchange.com/questions/295483/chown-r-www-datawww-data-sets-ownership-to-root
RUN chown -R www-data:www-data /var/www

# start mysql and grant access of mysql to user 'wp_admin'
# see: https://uxmilk.jp/12323
RUN service mysql start \
	&& mysql -e "CREATE DATABASE wordpress \
	DEFAULT CHARACTER SET utf8 \
	DEFAULT COLLATE utf8_unicode_ci; \
	GRANT ALL ON wordpress.* TO wp_admin@localhost identified by 'password'"

# expose two ports: 80 and 443
# see: https://www.whitesourcesoftware.com/free-developer-tools/blog/docker-expose-port/
EXPOSE 80 443

CMD	bash getstarted.sh
