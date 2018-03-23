#!/bin/bash

echo
if [ ! "${USER}" = "root" ] ; then
   echo -e "Type $(tput setaf 1)sudo ./install.sh$(tput sgr0) for installation"
   exit 0 ; fi

exec >  >(tee -a /tmp/install.log)
exec 2> >(tee -a /tmp/install.log >&2)

read -p "Enter password for netbox user "sysadmin": " -s password
echo -e "\nEnter password again: "
read -s user

if [ -z $password ] || [ -z $user ] || [ $password != $user ]
    then echo $(tput setaf 1)"!! Exit -- password entry error !!"$(tput sgr0)
    exit 1; fi

# Configure netbox
user="sysadmin"
intf=$(ifconfig | grep -m1 ^e | awk '{print $1}')
syshost=$(hostname)
sysip=$(ifconfig | grep $intf -A 1 | grep inet | awk '{print $2}' \
    | awk -F: '{print $2}')

key=$(/opt/netbox/netbox/generate_secret_key.py)

# Escape special characters [/\&] to be used in sed
password=$(echo $password | sed -e 's-\/-\\\/g; s-\\-\\\\-g; s-\&-\\\&-g')
key=$(echo $key | sed -e 's-\/-\\\/g; s-\\-\\\\-g; s-\&-\\\&-g')

cp /opt/netbox/netbox/netbox/configuration.example.py /tmp/configuration.py
sed -e "s/^ALLOWED_HOSTS = \[\]$/ALLOWED_HOSTS = \['$syshost', '$sysip'\]/" \
    -e "s/'USER': '/'USER': '$user/" \
    -e "s/'USERNAME': '/'USERNAME': '$user/" \
    -e "s/'PASSWORD': '/'PASSWORD': '$password/" \
    -e "s/^SECRET_KEY = '/SECRET_KEY = '$key/" -i /tmp/configuration.py

sudo mv -f /tmp/configuration.py /opt/netbox/netbox/netbox/

echo $(tput setaf 3)
sed -e "/^#.*$/d" -e "/^$/d" /opt/netbox/netbox/netbox/configuration.py
echo $(tput sgr0)

echo "Run Database migration with following commands:"
echo $(tput setaf 6)
echo "cd /opt/netbox/netbox/"
echo "python ./manage.py migrate"
echo "python ./manage.py createsuperuser"
echo "sudo python ./manage.py collectstatic --no-input"
echo "python ./manage.py loaddata initial_data"
echo "python ./manage.py runserver 0.0.0.0:8000 --insecure"
echo $(tput sgr0)
