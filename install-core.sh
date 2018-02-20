#!/bin/bash

echo
if [ ! "${USER}" = "root" ] ; then
   echo -e "Type $(tput setaf 1)sudo ./install.sh$(tput sgr0) for installation"
   exit 0 ; fi

exec >  >(tee -a /tmp/install.log)
exec 2> >(tee -a /tmp/install.log >&2)

apt-get update 
ln /usr/bin/python3.5 /usr/local/bin/python

# install pip3 version 9.0.1
echo $(tput setaf 6)
echo "Installing pip3 .... Please wait ...." $(tput sgr0)
apt-get install -y python3-pip
pip3 install --upgrade pip
echo $(tput setaf 6)"!!-- End of pip3 installation --!!" $(tput sgr0)

# Install Postgresql
core_apps=$(echo "libpq-dev postgresql")
for a in $core_apps; do
     echo $(tput setaf 6)
     echo "Installing $a .... Please wait .... "$(tput sgr0)
     sudo apt-get -qq -y install $a
     echo $(tput setaf 6)"!!-- End of $a installation --!!" $(tput sgr0)
done

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
