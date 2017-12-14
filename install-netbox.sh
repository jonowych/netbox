#!/bin/bash

echo
if [ ! "${USER}" = "root" ] ; then
   echo -e "Type $(tput setaf 1)sudo ./install.sh$(tput sgr0) for installation"
   exit 0 ; fi

exec >  >(tee -a /tmp/install.log)
exec 2> >(tee -a /tmp/install.log >&2)

# Install core apps
#
core_apps=$(echo "build-essential libxml2-dev libxslt1-dev libffi-dev graphviz libpq-dev libssl-dev zlib1g-dev")
for a in $core_apps; do
     echo $(tput setaf 6)
     echo "Installing $a .... Please wait .... "$(tput sgr0)
     sudo apt-get -qq -y install $a
done

echo $(tput setaf 6)
echo "!!-- End of core apps installation --!!"$(tput sgr0)

# Download and install latest netbox 
#
netbox_ver=$(echo "2.2.7")
echo -e "$(tput setaf 6)Installing  netbox-v"$netbox_ver".... Please wait .... $(tput sgr0)"

if [ ! -f /tmp/v"$netbox_ver".tar.gz ] ; then
  echo $(tput setaf 6)
  echo "Downloading netbox version-$netbox_ver .... Please wait .... "$(tput sgr0)
  cd /tmp
  wget https://github.com/digitalocean/netbox/archive/v"$netbox_ver".tar.gz
  sudo tar -xzf v"$netbox_ver".tar.gz -C /opt
  sudo ln -s /opt/netbox-"$netbox_ver"/ /opt/netbox
fi
sleep 2

cd /opt/netbox
echo -e $(tput setaf 6)"\nPip3 installing requirements .... Please wait .... "$(tput sgr0)
sudo -H pip3 install -r requirements.txt
echo -e $(tput setaf 6)"\nPip3 installing napalm .... Please wait .... "$(tput sgr0)
sudo -H pip3 install napalm

echo $(tput setaf 6)
echo "!!-- End of netbox apps installation"$(tput sgr0)
sleep 2

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
echo "sudo -H python3 ./manage.py migrate"
echo "sudo -H python3 ./manage.py createsuperuser"
echo "sudo -H python3 ./manage.py collectstatic --no-input"
echo "sudo -H python3 ./manage.py loaddata initial_data"
echo "sudo -H python3 ./manage.py runserver 0.0.0.0:8000 --insecure"
echo $(tput sgr0)
