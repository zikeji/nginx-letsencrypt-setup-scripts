#!/bin/bash

display_usage() { 
	echo "This script must be run with super-user privileges." 
	echo "Usage:"
	echo "./undeploy.sh [domain]"
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
	echo "#!/usr/bin/env" > /etc/bash_completion.d/zikeji_nginx_undeploy
	echo 'complete -W "`'"$PWD"'/list.sh --short`" ./undeploy.sh' >> /etc/bash_completion.d/zikeji_nginx_undeploy
exit 0
fi

DOMAIN="$1"
CONFIG="/etc/nginx/sites-available/$DOMAIN"
ARCHIVE="/etc/letsencrypt/archive/$DOMAIN"
LIVE="/etc/letsencrypt/live/$DOMAIN"
RENEWAL="/etc/letsencrypt/renewal/$DOMAIN.conf"

if [[ $DOMAIN == "." ]] || [[ $DOMAIN == ".." ]] || [[ $DOMAIN == "" ]]; then
	echo "Invalid domain \`$DOMAIN\` specified, abort!"
	echo
	exit 1
fi

echo
read -p "This will delete the nginx config and LE certs, are you sure you want to continue? [y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
	if [ -f "$CONFIG" ]; then
		rm "$CONFIG"
		echo "Removed config at \`$CONFIG\`"
	else
		echo "NGINX configuration does not exist at \`$CONFIG\`, skipping."
	fi
	if [ -d "$ARCHIVE" ]; then
		rm -rf "$ARCHIVE"
		echo "Removed archive at \`$ARCHIVE\`"
	else
		echo "Lets Encrypt achive does not exist at \`$ARCHIVE\`, skipping."
	fi
	if [ -d "$LIVE" ]; then
		rm -rf "$LIVE"
		echo "Removed live certs at \`$LIVE\`"
	else
		echo "Lets Encrypt live certs do not exist at \`$LIVE\`, skipping."
	fi
	if [ -f "$RENEWAL" ]; then
		rm "$RENEWAL"
		echo "Removed renewal config at \`$RENEWAL\`"
	else
		echo "Lets Encrypt renewal config does not exist at \`$RENEWAL\`, skipping."
	fi
	echo
else
	echo
	exit 1
fi

echo
nginx -t
RESPONSE="$?"
echo
if [[ $RESPONSE != "0" ]]; then
	echo
	echo NGINX test failed, skipping reload.
	echo
else
	echo
	read -p "NGINX test succeeded, reload nginx? [y/n] " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		systemctl reload nginx
	fi
fi

echo
echo "./undeploy.sh completed"
