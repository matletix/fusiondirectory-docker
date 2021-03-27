# Start OpenLDAP
service slapd start

# Inject base schema
/usr/local/bin/fusiondirectory-insert-schema

# Run Apache
apachectl -D FOREGROUND
