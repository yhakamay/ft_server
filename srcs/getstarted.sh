#!/bin/bash
service mysql start
# service --status-all なぜか[-] php7.3-fpm。stopはさむといける。
service php7.3-fpm stop
service php7.3-fpm start
service nginx start
tail -f /dev/null
