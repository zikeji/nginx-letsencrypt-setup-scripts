#!/bin/bash

if [[ $* == *--short* ]] 
then 
	find /etc/nginx/sites-available -maxdepth 1 -type f -printf '%f\n' | grep -v "default" | sort | tr '\n' ' '
else
	echo
	echo "=====[ Current Configs ]====="
	find /etc/nginx/sites-available -maxdepth 1 -type f -printf '%f\n' | grep -v "default" | sort
	echo
fi
