#!/bin/bash

display_usage() { 
	echo "This script must be run with super-user privileges." 
	echo "Usage:"
	echo "./edit.sh [domain]"
	echo
}

if [ $# -le 0 ]; then 
	display_usage
	exit 1
fi
 
if [[ $EUID -ne 0 ]]; then 
	echo "This script must be run as root!" 
	exit 1
fi

# Install autocomplete script for command
if [[ $* == *--install-autocomplete* ]]; then
	echo
	echo Installing bash autocomplete for local directory. 
	echo
	echo "#!/usr/bin/env" > /etc/bash_completion.d/zikeji_nginx_edit
	echo 'complete -W "`'"$PWD"'/list.sh --short`" ./edit.sh' >> /etc/bash_completion.d/zikeji_nginx_edit
exit 0
fi

DOMAIN="$1"
CONFIG="/etc/nginx/sites-available/$DOMAIN"

if [ -f "$CONFIG" ]; then
	nano "$CONFIG"
else
	echo "NGINX configuration does not exist at \`$CONFIG\`, skipping."
	exit 1
fi

echo
nginx -t
RESPONSE="$?"
if [[ $RESPONSE != "0" ]]; then
	echo
	echo "NGINX test failed, skipping reload"
	echo
else
	echo
	echo "NGINX test succeeded, reloading nginx"
	systemctl reload nginx
fi

echo
echo "./edit.sh completed"
