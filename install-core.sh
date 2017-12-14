#!/bin/bash

echo
if [ ! "${USER}" = "root" ] ; then
   echo -e "Type $(tput setaf 1)sudo ./install.sh$(tput sgr0) for installation"
   exit 0 ; fi

exec >  >(tee -a /tmp/install.log)
exec 2> >(tee -a /tmp/install.log >&2)

sudo apt-get update 

# install pip3 version 9.0.1
#
echo -e $(tput setaf 6)"\nInstalling pip3 .... Please wait ...." $(tput sgr0)
apt-get install -y python3-pip

# Upgrade pip components
#
pip3_apps=$(echo "pip virtualenv")
for a in $pip3_apps; do
     echo $(tput setaf 6)
     echo "Upgrading $a .... Please wait .... "$(tput sgr0)
     sudo -H /usr/bin/pip3 install --upgrade $a
done

echo $(tput setaf 6)
echo "!!-- End of pip3 installation --!!"$(tput sgr0)

# Install core apps
#
core_apps=$(echo "libpq-dev postgresql")
for a in $core_apps; do
     echo $(tput setaf 6)
     echo "Installing $a .... Please wait .... "$(tput sgr0)
     sudo apt-get -qq -y install $a
done

echo $(tput setaf 6)
echo "!!-- End of core apps installation --!!"$(tput sgr0)

systemctl start postgresql
systemctl enable postgresql

echo $(tput setaf 6)
echo "Create database with following commands: (; at the end)"
echo "sudo -u postgres psql"
echo "CREATE DATABASE netbox;"
echo "CREATE USER sysadmin WITH PASSWORD '67.Epping';"
echo "GRANT ALL PRIVILEGES ON DATABASE netbox TO sysadmin;"
echo "Enter \q to quit"
echo "Login database again to confirm"
echo "psql -U sysadmin -W -h localhost netbox"
echo $(tput sgr0)
