#!/bin/bash

echo
if [ ! "${USER}" = "root" ] || [ ! "${HOME}" = "/root" ] ; then
   echo -e "Type $(tput setaf 1)sudo -H ./install-netbox.sh$(tput sgr0) for installation"
   exit 0 ; fi

exec >  >(tee -a /tmp/install.log)
exec 2> >(tee -a /tmp/install.log >&2)

netbox_ver=""
read -p "Which netbox version? Press [enter] for default v2.4.6 " netbox_ver
if [ -z $netbox_ver ]; then netbox_ver=$(echo "2.4.6"); fi

apt-get update
# Install postgresql and core-dev apps
core_apps=$(echo "build-essential libxml2-dev libxslt1-dev libffi-dev graphviz libpq-dev libssl-dev zlib1g-dev postgresql nginx supervisor")
for a in $core_apps; do
     echo -e $(tput setaf 6)"\nInstalling $a .... Please wait .... "$(tput sgr0)
     sudo apt-get -qq -y install $a
done

echo $(tput setaf 6)
echo "!!-- All core installation have finished --!!"$(tput sgr0)

# make sure all netbox commands are running in Python3
ln -sf /usr/bin/python3.5 /usr/bin/python

# install pip3 version 9.0.1
echo -e $(tput setaf 6)"\nInstalling pip3 .... Please wait ...." $(tput sgr0)
apt-get install -y python3-setuptools
easy_install3 pip
echo $(tput setaf 6)"!!-- End of pip3 installation --!!" $(tput sgr0)

# Download and install latest netbox 
echo -e "$(tput setaf 6)Installing  netbox-v"$netbox_ver".... Please wait .... $(tput sgr0)"

if [ ! -f /tmp/v"$netbox_ver".tar.gz ] ; then
  echo $(tput setaf 6)
  echo "Downloading netbox version-$netbox_ver .... Please wait .... "$(tput sgr0)
  wget -P /tmp https://github.com/digitalocean/netbox/archive/v"$netbox_ver".tar.gz
fi
  sudo tar -xzf /tmp/v"$netbox_ver".tar.gz -C /opt
  sudo ln -sf /opt/netbox-"$netbox_ver"/ /opt/netbox
sleep 2

cd /opt/netbox
echo -e $(tput setaf 6)"\nPip3 installing requirements .... Please wait .... "$(tput sgr0)
sudo pip3 install -r requirements.txt
echo -e $(tput setaf 6)"\nPip3 installing napalm .... Please wait .... "$(tput sgr0)
sudo pip3 install napalm
echo -e $(tput setaf 6)"\nPip3 installing gunicorn .... Please wait .... "$(tput sgr0)
sudo pip3 install gunicorn

echo $(tput setaf 6)
echo "!!-- End of netbox apps installation"
echo $(tput sgr0)

systemctl start postgresql
systemctl enable postgresql

echo $(tput setaf 6)
echo "Create database with following commands: (; at the end)"
echo $(tput setaf 3)
echo "sudo -u postgres psql"
echo "CREATE DATABASE netbox;"
echo "CREATE USER tasadmin WITH PASSWORD '?????';"
echo "GRANT ALL PRIVILEGES ON DATABASE netbox TO tasadmin;"
echo $(tput setaf 6)
echo "Enter \q to quit"
echo "Login database again to confirm"
echo $(tput setaf 3)
echo "psql -U tasadmin -W -h localhost netbox"
echo $(tput sgr0)
