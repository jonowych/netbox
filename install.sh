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

core_apps=$(echo "postgresql python3 python3-dev python3-pip")
dev_tools=$(echo "libxml2-dev libxslt1-dev libffi-dev graphviz libpq-dev libssl-dev zlib1g-dev")

# Install core apps
#
echo && echo -e "$(tput setaf 6)Installing python3 Apps. They will take a few minutes.$(tput sgr0)"
for a in $core_apps; do
     echo -e "$(tput setaf 6)Installing $a .... Please wait .... $(tput sgr0)"
     sudo apt-get -qq -y install $a
     echo $a has been installed
     echo
done
echo && echo -e "$(tput setaf 6)-- End of core apps installation --$(tput sgr0)"

# Install development tools
#
echo && echo -e "$(tput setaf 6)Installing development tools. They will take a few minutes.$(tput sgr0)"
for a in $prerequisites; do
     echo -e "$(tput setaf 6)Installing $a .... Please wait .... $(tput sgr0)"
     sudo apt-get -qq -y install $a
     echo $a has been installed
     echo
done
echo && echo -e "$(tput setaf 6)-- End of development tools installation --$(tput sgr0)"

# Download latest netbox code
#
netbox_ver=$(echo "2.2.6")
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
sed -i 's/python$/python3/' /opt/netbox/netbox/generate_secret_key.py
key=$(/opt/netbox/netbox/generate_secret_key.py)

cat /opt/netbox/netbox/netbox/configuration.example.py | \
  sed "s/^ALLOWED_HOSTS = \[\]$/ALLOWED_HOSTS = \['$host', '$ip'\]/" | \
  sed "s/'USER': '/'USER': 'sydadmin/" | \
  sed "s/'USERNAME': '/'USERNAME': 'sysadmin/" | \
  sed "s/'PASSWORD': '/'PASSWORD': '67\.Epping/" | \
  sed "s/^SECRET_KEY = '/SECRET_KEY = '$key/" >> /tmp/configuration.py

sudo mv -f /tmp/configuration.py /opt/netbox/netbox/netbox/
cat /opt/netbox/netbox/netbox/configuration.py

pip3 install napalm

# cd /opt/netbox/netbox/
# python3 ./manage.py migrate
# python3 ./manage.py createsuperuser
# python3 ./manage.py collectstatic --no-input
# python3 ./manage.py loaddata initial_data
