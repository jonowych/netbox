#!/bin/bash

echo
if [ ! "${USER}" = "root" ] ; then
   echo -e "Type $(tput setaf 1)sudo ./install.sh$(tput sgr0) for installation"
   exit 0 ; fi

exec >  >(tee -a /tmp/install.log)
exec 2> >(tee -a /tmp/install.log >&2)

# Configure netbox
user="sysadmin"
password="67E&&!ng"
intf=$(ifconfig | grep -m1 ^e | awk '{print $1}')
syshost=$(hostname)
sysip=$(ifconfig | grep $intf -A 1 | grep inet | awk '{print $2}' \
    | awk -F: '{print $2}')

key=$(/opt/netbox/netbox/generate_secret_key.py)
echo $key

cat /opt/netbox/netbox/netbox/configuration.example.py | \
  sed "s/^ALLOWED_HOSTS = \[\]$/ALLOWED_HOSTS = \['$syshost', '$sysip'\]/" | \
  sed "s/'USER': '/'USER': '$user/" | \
  sed "s/'USERNAME': '/'USERNAME': '$user/" | \
  sed "s/'PASSWORD': '/'PASSWORD': '$password/" | \
  sed "s/^SECRET_KEY = '/SECRET_KEY = '$key/" >> /tmp/configuration.py

sudo -H mv -f /tmp/configuration.py /opt/netbox/netbox/netbox/

echo $(tput setaf 3)
cat /opt/netbox/netbox/netbox/configuration.py
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
