# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: yhakamaya <yhakamaya@student.42tokyo.      +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2021/02/14 11:56:54 by yhakamaya         #+#    #+#              #
#    Updated: 2021/02/25 16:19:01 by yhakamaya        ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

FROM	debian:buster

ARG	entrykit_v="0.4.0"
ARG	phpmyadmin_v="5.0.4"

RUN	apt-get update && \
	apt-get install -y \
		nginx mariadb-server mariadb-client \
		php-curl php-dom php-mbstring php-mysqli \
		php-imagick php-xml php-zip php-gd php-fpm \
		vim wget curl \
	&& rm -rf /var/lib/apt/lists/* \
	&& wget https://github.com/progrium/entrykit/releases/download/v${entrykit_v}/entrykit_${entrykit_v}_Linux_x86_64.tgz \
	&& tar -xvzf entrykit_${entrykit_v}_Linux_x86_64.tgz \
	&& rm entrykit_${entrykit_v}_Linux_x86_64.tgz \
	&& mv entrykit /bin/entrykit \
	&& chmod +x /bin/entrykit \
	&& entrykit --symlink \
	&& wget https://wordpress.org/latest.tar.gz \
	&& tar xsfv latest.tar.gz \
	&& rm latest.tar.gz \
	&& mv wordpress/ /var/www/html \
	&& wget https://files.phpmyadmin.net/phpMyAdmin/${phpmyadmin_v}/phpMyAdmin-${phpmyadmin_v}-all-languages.tar.gz \
	&& tar xsfv phpMyAdmin-${phpmyadmin_v}-all-languages.tar.gz \
	&& rm phpMyAdmin-${phpmyadmin_v}-all-languages.tar.gz \
	&& mv phpMyAdmin-${phpmyadmin_v}-all-languages phpmyadmin \
	&& mv phpmyadmin/ /var/www/html

COPY	./srcs/default.tmpl /etc/nginx/sites-available/default.tmpl
COPY	./srcs/wp-config.php /var/www/html/wordpress/wp-config.php
COPY	./srcs/getstarted.sh getstarted.sh

RUN	mkdir /etc/nginx/certificate \
	&& openssl req \
	-subj '/C=JP/ST=Tokyo/L=Bunkyo/O=42 Tokyo/OU=Student/CN=yhakamay' \
	-x509 -nodes -days 365 -newkey rsa:4096 \
	-keyout /etc/nginx/certificate/server.key \
	-out /etc/nginx/certificate/server.crt \
	&& chmod -R 400 /etc/nginx/certificate \
	&& chown www-data:www-data /var/www/html/index.nginx-debian.html \
	&& service mysql start \
	&& mysql -e "CREATE DATABASE wordpress \
	DEFAULT CHARACTER SET utf8 \
	DEFAULT COLLATE utf8_unicode_ci; \
	GRANT ALL ON wordpress.* TO wp_admin@localhost identified by 'password'"

EXPOSE 80 443

ENTRYPOINT ["render", "/etc/nginx/sites-available/default", "--", "bash", "./getstarted.sh"]
