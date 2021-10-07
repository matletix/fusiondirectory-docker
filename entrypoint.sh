# Start OpenLDAP
service slapd start

# Inject base schema
/usr/local/bin/fusiondirectory-insert-schema

# Update cache
/usr/local/bin/fusiondirectory-setup --set-fd_home=/usr/local/share/fusiondirectory --update-cache --update-locales --write-vars

# Run Apache
apachectl -D FOREGROUND
