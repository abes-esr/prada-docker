FROM php:5.6.40-apache
COPY ./sources.list /etc/apt/sources.list

# pour avoir un client SMTP dans le conteneur (msmtp)
# gettext-base: pour disposer de la commande envsubst (systeme de template)
# libldap2-dev libldb-dev: pour l'extension php LDAP
# libpng-dev : pour l'extension php GD
# libpq-dev : pour l'extension php postgresql
# libxml2-dev : pour l'extension php soap (pour les web services de bodet)
# wait-for-it : pour pouvoir attendre que la base de données est UP avant de lancer prada-web
RUN set -x \
    && DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y vim \
    && apt-get install -y msmtp gettext-base \
    && apt-get install -y libldap2-dev libldb-dev \
    && apt-get install -y libpng-dev \
    && apt-get install -y libpq-dev \
    && apt-get install -y libxml2-dev \
    && apt-get install -y wait-for-it

# client postgresql pour le système de configuration depuis docker vers la table egw_config
# cf https://stackoverflow.com/a/52655008
RUN set -x \
    && mkdir -p /usr/share/man/man1 \
    && mkdir -p /usr/share/man/man7 \
    && apt-get install -y postgresql-client || true

# pour le système d'envoi de mail
COPY ./msmtprc.tls.tmpl /etc/
COPY ./msmtprc.notls.tmpl /etc/

RUN docker-php-ext-install gd
RUN docker-php-ext-install pgsql pdo pdo_pgsql
RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/
RUN docker-php-ext-install ldap
RUN docker-php-ext-install soap
RUN a2enmod rewrite expires

COPY ./php-prada.ini /usr/local/etc/php/conf.d/php-prada.ini
COPY ./apache-prada.conf /etc/apache2/sites-available/apache-prada.conf
RUN a2dissite 000-default && a2ensite apache-prada

# code source de prada (en lecture seule)
COPY ./src/egw/ /var/www/html/egw/
RUN find /var/www/html/egw/ -type f -exec chmod a+r {} \;
RUN find /var/www/html/egw/ -type f -exec chmod a-wx {} \;
RUN find /var/www/html/egw/ -type d -exec chmod a-w {} \;
RUN find /var/www/html/egw/ -type d -exec chmod a+rx {} \;
# repertoire en rw nécessaire quand on ajoute/modifie une actualité (actualites.xml)
VOLUME /var/www/html/egw/news_admin/
RUN chmod 777 /var/www/html/egw/news_admin/

COPY ./docker-entrypoint.overload.sh /
ENTRYPOINT ["/docker-entrypoint.overload.sh"]
CMD ["apache2-foreground"]
