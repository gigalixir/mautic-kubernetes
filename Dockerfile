FROM mautic/mautic

RUN apt-get update && apt-get install -y vim

COPY mautic-php-timezone-pst.ini /usr/local/etc/php/conf.d/
RUN chmod 755 /usr/local/etc/php/conf.d/mautic-php-timezone-pst.ini 

COPY secrets/crontab /etc/cron.d/mautic
RUN chmod 644 /etc/cron.d/mautic

RUN a2enmod ssl
RUN mkdir -p /etc/apache2/ssl
COPY secrets/apache.key /etc/apache2/ssl/
COPY secrets/apache.crt /etc/apache2/ssl/

COPY default-ssl.conf /etc/apache2/sites-available/
RUN chmod 644 /etc/apache2/sites-available/default-ssl.conf
RUN a2ensite default-ssl
