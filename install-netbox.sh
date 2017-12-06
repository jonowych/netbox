#!/bin/bash

echo
if [ ! "${USER}" = "root" ] ; then
   echo -e "Type $(tput setaf 1)sudo ./install.sh$(tput sgr0) for installation"
   exit 0 ; fi

exec >  >(tee -a /tmp/install.log)
exec 2> >(tee -a /tmp/install.log >&2)

# Prepare for Install... on User's directory
#

# install pip3 9.0.1

apt-get install python3-pip
/usr/bin/pip3 install --upgrade pip
/usr/bin/pip3 install --upgrade virtualenv 

core_apps=$(echo "python3-dev python3-setuptools build-essential libxml2-dev libxslt1-dev libffi-dev graphviz libpq-dev libssl-dev zlib1g-dev")

# Install core apps
#
for a in $core_apps; do
     echo -e "$(tput setaf 6)Installing $a .... Please wait .... $(tput sgr0)"
     sudo apt-get -qq -y install $a
     echo $a has been installed
     echo
done

echo && echo -e $(tput setaf 6)"!!-- End of Python3 and development apps installation."$(tput sgr0)

# Download latest netbox code
#
netbox_ver=$(echo "2.2.6")
if [ ! -f /tmp/v"$netbox_ver".tar.gz ] ; then
  cd /tmp
  wget https://github.com/digitalocean/netbox/archive/v"$netbox_ver".tar.gz
  sudo tar -xzf v"$netbox_ver".tar.gz -C /opt
  sudo ln -s netbox-"$netbox_ver"/ /opt/netbox
fi

cd /opt/netbox
sudo -H pip3 install -r requirements.txt
sudo -H pip3 install napalm

echo && echo -e $(tput setaf 6)"!!-- End of netbox apps installation"$(tput sgr0)

# Configure netbox
#
user="sysadmin"
password="67\.Epping"
intf=$(ifconfig | grep -m1 ^e | awk '{print $1}')
syshost=$(hostname)
sysip=$(ifconfig | grep $intf -A 1 | grep inet | awk '{print $2}' \
    | awk -F: '{print $2}')

sed -i 's/python$/python3/' /opt/netbox/netbox/generate_secret_key.py
key=$(/opt/netbox/netbox/generate_secret_key.py)

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

echo $(tput setaf 6)
echo "Run Database migration with following commands:"
echo "cd /opt/netbox/netbox/"
echo "python3 ./manage.py migrate"
echo "python3 ./manage.py createsuperuser"
echo "python3 ./manage.py collectstatic --no-input"
echo "python3 ./manage.py loaddata initial_data"
echo "python3 ./manage.py runserver 0.0.0.0:8000 --insecure"
echo $(tput sgr0)
