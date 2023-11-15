#!/bin/bash

# Reglages variables php.ini pour la prod
cp -f "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"



# --- configuration pour envoyer des mail
export SMTP_TLS=${SMTP_TLS:="off"}
export SMTP_HOST=${SMTP_HOST:="prada-mailhog"}
export SMTP_PORT=${SMTP_PORT:="1025"}
export SMTP_MAILDOMAIN=${SMTP_MAILDOMAIN:="abes.fr"}
export SMTP_USER=${SMTP_USER:=""}
export SMTP_PASSWORD=${SMTP_PASSWORD:=""}
# utilisation de msmtp pour envoyer de mails depuis php
# la config est placee dans /etc/msmtprc
# cela permet à PHP d'envoyer de mail (mais pour prada, cela fait probablement doublon avec class.send.inc.php)
sed -i 's#;sendmail_path =#sendmail_path = /usr/bin/msmtp -t -i#g' $PHP_INI_DIR/php.ini
if [ "${SMTP_TLS}" = "on" ]; then
  envsubst < /etc/msmtprc.tls.tmpl > /etc/msmtprc
else
  envsubst < /etc/msmtprc.notls.tmpl > /etc/msmtprc
fi


# --- configuration pour se connecter à prada via ldap
export PGPASSWORD="$POSTGRES_PASSWORD"
export LDAP_ADS_PROTOCOL=${LDAP_ADS_PROTOCOL:="ldaps"}
export LDAP_ADS_HOST=${LDAP_ADS_HOST:="ldap-host-to-change"}
export LDAP_ADS_PORT=${LDAP_ADS_PORT:="636"}
export LDAP_ADS_DOMAIN=${LDAP_ADS_DOMAIN:="active-directory-domain-to-change"}
# on injecte ces parametres dans la bdd de prada
# (on attend que prada-db soit prête avant de lancer les requêtes)
/usr/bin/wait-for-it ${POSTGRES_HOST}:5432
echo "UPDATE egw_config SET config_value = '$LDAP_ADS_PROTOCOL' WHERE config_name = 'ads_protocol';" | psql --username=$POSTGRES_USER --host=$POSTGRES_HOST $POSTGRES_DB
echo "UPDATE egw_config SET config_value = '$LDAP_ADS_HOST' WHERE config_name = 'ads_host';" | psql --username=$POSTGRES_USER --host=$POSTGRES_HOST $POSTGRES_DB
echo "UPDATE egw_config SET config_value = '$LDAP_ADS_PORT' WHERE config_name = 'ads_port';" | psql --username=$POSTGRES_USER --host=$POSTGRES_HOST $POSTGRES_DB
echo "UPDATE egw_config SET config_value = '$LDAP_ADS_DOMAIN' WHERE config_name = 'ads_domain';" | psql --username=$POSTGRES_USER --host=$POSTGRES_HOST $POSTGRES_DB



# on s'assure que le répertoire des pieces jointes 
# des tickets Gala et ODM dispose des droits d'ecriture
chmod 777 /var/lib/intranet/default/files/infolog/

# on s'assure des droits d'écriture sur actualites.xml
# ce fichier est modifié en cas de nouvelle actu
# cf https://abes-esr.atlassian.net/browse/PRA-72
touch /var/www/html/egw/news_admin/actualites.xml
chmod 777 /var/www/html/egw/news_admin/actualites.xml

# pour les sessions PHP qui sont montées dans un volume pour être conservées
# cf https://abes-esr.atlassian.net/browse/PRA-79
chmod 777 /tmp/

# start the real entrypoint
exec /usr/local/bin/docker-php-entrypoint $@

