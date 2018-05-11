#!/bin/bash

display_usage() { 
	echo "This script must be run with super-user privileges." 
	echo "Usage:"
	echo "./deploy.sh [domain] [host] (template)"
	echo
}

if [ $# -le 1 ]; then 
	display_usage
	exit 1
fi
 
if [[ $EUID -ne 0 ]]; then 
	echo "This script must be run as root!" 
	exit 1
fi

EMAIL="YOUR_EMAIL_HERE"
DOMAIN="$1"
HOST="$2"
TEMPLATE="$3"
CONFIG="/etc/nginx/sites-available/$DOMAIN"

if [ -f "$CONFIG" ]; then
	echo
	read -p "NGINX config file exists, run deploy.sh anyway? [y/n] " -n 1 -r
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		echo
	else
		echo
		echo
		exit 1
	fi
fi

if [[ -z "${TEMPLATE// }" ]]; then
	TEMPLATE="default"
fi

echo
read -p "Generate certificate? [y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
	LOOP=TRUE
	while [[ $LOOP == "TRUE" ]]; do
		echo
		read -p "Run live certificate generation? [y/n] " -n 1 -r
		echo
		echo
		LIVE=FALSE
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			LIVE=TRUE
			certbot certonly --webroot --agree-tos --no-eff-email --email $EMAIL -w /var/www/letsencrypt -d $DOMAIN
		else
			certbot certonly --webroot --agree-tos --no-eff-email --email $EMAIL -w /var/www/letsencrypt -d $DOMAIN --staging			
		fi

		RESPONSE="$?"
		if [[ $RESPONSE != "0" ]]; then
			echo
	                read -p "Certification generation failed. Try again? [y/n] " -n 1 -r
        	        echo
                	if [[ $REPLY =~ ^[Yy]$ ]]; then
				echo
        	        else
				echo
				exit 1
        	        fi
		else
			echo
			echo Certification generation succeeded.
			echo
			if [[ $LIVE != "TRUE" ]]; then
				read -p "You ran this generation on staging, do you want to go back and run live? [y/n] " -n 1 -r
				if [[ $REPLY =~ ^[Yy]$ ]]; then
					echo
				else
					LOOP=FALSE
				fi
			else
				LOOP=FALSE
			fi
		fi
	done
fi

cp "templates/$TEMPLATE" "$CONFIG"
if [ ! -f "/etc/nginx/sites-enabled/$DOMAIN" ]; then
	ln -s "$CONFIG" "/etc/nginx/sites-enabled/$DOMAIN"
fi

sed -i -e "s|\[DOMAIN\]|$DOMAIN|g" "$CONFIG"
sed -i -e "s|\[HOST\]|$HOST|g" "$CONFIG"

EXTRA=""
echo
echo "NGINX configuration options."

echo
read -p "Pass header \`Host\` to backend? [y/n] " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
	EXTRA="$EXTRA\n"'		proxy_set_header Host $host;'
fi

echo
read -p "Pass header \`X-Forward-Proto\` to backend? [y/n] " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
	EXTRA="$EXTRA\n"'		proxy_set_header X-Forwarded-Proto $scheme;'
fi

echo
read -p "Pass header \`X-Real-IP\` to backend? [y/n] " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
	EXTRA="$EXTRA\n"'		proxy_set_header X-Real-IP $remote_addr;'
fi

echo
read -p "Pass header \`X-Forwarded-For\` to backend? [y/n] " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
	EXTRA="$EXTRA\n"'		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;'
fi

sed -i -e "s|\[EXTRA\]|$EXTRA|g" "$CONFIG"
echo

echo
read -p "NGINX configuration generated, open config in nano? [y/n] " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
	nano "$CONFIG"
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
echo "./deploy.sh completed, new config located at $CONFIG"
