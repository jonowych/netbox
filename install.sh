#!/bin/bash

echo
if [ ! "${USER}" = "root" ] ; then
   echo -e "Type $(tput setaf 1)sudo ./install.sh$(tput sgr0) for installation"
   exit 0 ; fi

exec >  >(tee -a /tmp/install.log)
exec 2> >(tee -a /tmp/install.log >&2)

# Prepare for Install... on User's directory
#

sudo apt-get update 

python_apps=$(echo "python3 python3-dev python3-pip")
prerequisites=$(echo "libxml2-dev libxslt1-dev libffi-dev graphviz libpq-dev libssl-dev zlib1g-dev")

# Install python apps
#
echo && echo -e "$(tput setaf 6)Installing python3 Apps. They will take a few minutes.$(tput sgr0)"

for a in $python_apps; do
     echo -e "$(tput setaf 6)Installing $a .... Please wait .... $(tput sgr0)"
     sudo apt-get -qq -y install $a
     echo $a has been installed
     echo
done
# Change python version to python3 with priority 1
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# --- End of python tools installation

# Install Prerequisites
#
echo && echo -e "$(tput setaf 6)Installing prerequisites. They will take a few minutes.$(tput sgr0)"

for a in $prerequisites; do
     echo -e "$(tput setaf 6)Installing $a .... Please wait .... $(tput sgr0)"
     sudo apt-get -qq -y install $a
     echo $a has been installed
     echo
done
# --- End of Prerequisites installation

# Download latest netbox code
#

netbox_ver=$(echo "2.1.3")
if [ ! -f /tmp/v"$netbox_ver".tar.gz ] ; then 
  cd /tmp
  wget https://github.com/digitalocean/netbox/archive/v"$netbox_ver".tar.gz
  sudo tar -xzf v"$netbox_ver".tar.gz -C /opt
  sudo ln -s netbox-"$netbox_ver"/ /opt/netbox
fi

pip3 install -r requirements.txt

# Configure netbox
#
host=$(cat /etc/hostname)
ip=$(cat /etc/network/interfaces | grep "iface enp0s3" -A 2 \
      | grep address | awk '{ print $2 }')
sed -i 's/python/python3/' /opt/netbox/netbox/generate_secret_key.py
key=$(/opt/netbox/netbox/generate_secret_key.py)

cat /opt/netbox/netbox/netbox/configuration.example.py | \
  sed "s/^ALLOWED_HOSTS = \[/ALLOWED_HOSTS = \['$host', '$ip'/" | \
  sed "s/'USER': '/'USER': 'sydadmin/" | \
  sed "s/'USERNAME': '/'USERNAME': 'sydadmin/" | \
  sed "s/'PASSWORD': '/'PASSWORD': '67\.Epping/" | \
  sed "s/^SECRET_KEY = '/SECRET_KEY = '$key/" >> /tmp/configuration.py

sudo mv -f /tmp/configuration.py /opt/netbox/netbox/netbox/
cat /opt/netbox/netbox/netbox/configuration.py

# pip3 install napalm

# cd /opt/netbox/netbox/
# ./manage.py migrate
# ./manage.py createsuperuser
# ./manage.py collectstatic --no-input
# ./manage.py loaddata initial_data

