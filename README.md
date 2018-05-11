These are the scripts I created and use for adding new reverse proxy configs to my proxy server. This repo is more here for my personal reference, but feel free to use and even make suggestions!

### Requirements

These scripts are designed for a Debian based distro (such as Ubuntu). The way nginx has it's default configuration on RHL isn't compatible with these scripts.

### Usage

There are 4 scripts.

* deploy.sh [domain] [host] (template)
  * The first parameter is the domain you're deploying - this needs to have it's DNS records set already if you want to generate a ceritificate.
  * The second parameter is the backend host you want to reverse proxy to. This needs to include the scheme and the port.
  * The final parameter is optional and lets you specify the template. Templates are located in the `templates` folder. The default template is there. This script uses basic string replacement on characters to inject our information such as domain, hostname, extras, etc.
* edit.sh [domain]
  * opens up the specified config in nano
* list.sh
  * prints out a list of all the configs in sites-enabled aside from `default`
* undeploy.sh [domain]
  * removes the config (and LE certs) for the specified [domain].

Unfortunately at this time this script does not handle the LE generation of multiple domains. Simply run LE manually and then run this script, skipping the option to generate a cert. You'll have to edit the config to add your other domains but that's expected.

### Prerequisites

Here are some basic instructions that cover everything you need to get up and running on a fresh install of Ubuntu / Debian.

##### Install nginx & git.

```bash
sudo apt install nginx git
```

##### Generate your dhparam file.

```bash
sudo openssl dhparam -out /etc/nginx/ssl/dhparam.pem 4096
```

##### Generate a self signed certificate for use on your default configuration.

```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt
```

##### Add the repo for certbot and install certbot.

```bash
sudo add-apt-repository ppa:certbot/certbot
sudo apt update && apt install nginx python-certbot-nginx
```

##### Add certbot to your crontab for automatic renewals.

```bash
sudo crontab -e
```

###### Add:

```
20 3 * * * certbot renew --quiet
```

##### Add a deploy hook to LE to reload nginx on cert update.

```bash
sudo mkdir -p /etc/letsencrypt/renew-hooks/deploy
sudo nano /etc/letsencrypt/renew-hooks/deploy/nginx
```

###### Contents:

```bash
#!/usr/bin/env bash

systemctl reload nginx
```

### Installation (sorta)

You can place these scripts anywhere on your machine. I personally keep them in `/root/nginx`. Go ahead and clone this repo where you want the scripts. Notice the "YOUR_DIRECTORY_HERE" line.
```bash
git clone https://github.com/zikeji/nginx-letsencrypt-setup-scripts YOUR_DIRECTORY_HERE
cd YOUR_DIRECTORY
```

##### Create the webdir for LE to use during verification

```bash
sudo mkdir -p /var/www/letsencrypt/.well-known/acme-challenge
```

##### Add snippets to your nginx config.


```bash
sudo mkdir /etc/nginx/snippets
sudo cp etc/nginx/snippets/* /etc/nginx/snippets/
```

##### Add default nginx configuration

This deploys a configuration that'll let LE correctly identify you as owning the server and generate the certificate.

```bash
sudo cp etc/nginx/sites-available/default /etc/nginx/sites-available/default
```

##### Change admin email in `deploy.sh`

Update the email you want to receive certificate notifications for. It's at line 20 in `deploy.sh`.

##### Finished

At this point everything should be setup. Review the usage section for an idea of how to proceed.